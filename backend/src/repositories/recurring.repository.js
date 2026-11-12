import { query, withTransaction } from '../config/database.js';

export const recurringRepository = {
  /**
   * Retrieves recurring transaction schedules for a user.
   */
  async getRecurringTransactions(userId, { isActive } = {}) {
    const conditions = ['user_id = $1'];
    const params = [userId];

    if (isActive !== undefined) {
      params.push(Boolean(isActive));
      conditions.push(`is_active = $${params.length}`);
    }

    const sql = `
      SELECT
        id,
        amount_cents,
        type,
        currency,
        category,
        description,
        recurrence_interval,
        next_execution_date,
        account,
        last_executed_date,
        requires_review,
        is_active,
        created_at,
        updated_at
      FROM recurring_transactions
      WHERE ${conditions.join(' AND ')}
      ORDER BY next_execution_date ASC, created_at DESC;
    `;

    const res = await query(sql, params);
    return res.rows.map((r) => ({
      ...r,
      amount_cents: Number(r.amount_cents),
    }));
  },

  async getRecurringById(userId, id) {
    const sql = `
      SELECT * FROM recurring_transactions
      WHERE user_id = $1 AND id = $2;
    `;
    const res = await query(sql, [userId, id]);
    if (!res.rows[0]) return null;
    return {
      ...res.rows[0],
      amount_cents: Number(res.rows[0].amount_cents),
    };
  },

  async createRecurring(userId, data) {
    const sql = `
      INSERT INTO recurring_transactions (
        user_id,
        amount_cents,
        type,
        currency,
        category,
        description,
        recurrence_interval,
        next_execution_date,
        account,
        requires_review,
        is_active
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *;
    `;

    const res = await query(sql, [
      userId,
      data.amountCents,
      data.type || 'expense',
      data.currency || 'ETB',
      data.category,
      data.description || '',
      data.recurrenceInterval || 'monthly',
      data.nextExecutionDate,
      data.account || 'Cash Wallet',
      data.requiresReview !== undefined ? data.requiresReview : true,
      data.isActive !== undefined ? data.isActive : true,
    ]);

    return {
      ...res.rows[0],
      amount_cents: Number(res.rows[0].amount_cents),
    };
  },

  async updateRecurring(userId, id, data) {
    const fields = [];
    const params = [userId, id];

    if (data.amountCents !== undefined) {
      params.push(data.amountCents);
      fields.push(`amount_cents = $${params.length}`);
    }
    if (data.type !== undefined) {
      params.push(data.type);
      fields.push(`type = $${params.length}`);
    }
    if (data.category !== undefined) {
      params.push(data.category);
      fields.push(`category = $${params.length}`);
    }
    if (data.description !== undefined) {
      params.push(data.description);
      fields.push(`description = $${params.length}`);
    }
    if (data.recurrenceInterval !== undefined) {
      params.push(data.recurrenceInterval);
      fields.push(`recurrence_interval = $${params.length}`);
    }
    if (data.nextExecutionDate !== undefined) {
      params.push(data.nextExecutionDate);
      fields.push(`next_execution_date = $${params.length}`);
    }
    if (data.account !== undefined) {
      params.push(data.account);
      fields.push(`account = $${params.length}`);
    }
    if (data.requiresReview !== undefined) {
      params.push(data.requiresReview);
      fields.push(`requires_review = $${params.length}`);
    }
    if (data.isActive !== undefined) {
      params.push(data.isActive);
      fields.push(`is_active = $${params.length}`);
    }

    if (fields.length === 0) {
      return this.getRecurringById(userId, id);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);

    const sql = `
      UPDATE recurring_transactions
      SET ${fields.join(', ')}
      WHERE user_id = $1 AND id = $2
      RETURNING *;
    `;

    const res = await query(sql, params);
    if (!res.rows[0]) return null;
    return {
      ...res.rows[0],
      amount_cents: Number(res.rows[0].amount_cents),
    };
  },

  async deleteRecurring(userId, id) {
    const sql = `
      DELETE FROM recurring_transactions
      WHERE user_id = $1 AND id = $2
      RETURNING id, description;
    `;
    const res = await query(sql, [userId, id]);
    return res.rows[0] || null;
  },

  /**
   * Generates a concrete transaction from this recurring schedule.
   * Guarantees duplicate prevention using deterministic idempotency key.
   */
  async generateTransaction(userId, id, { executionDate = new Date() } = {}) {
    return withTransaction(async (client) => {
      const recRes = await client.query(
        'SELECT * FROM recurring_transactions WHERE user_id = $1 AND id = $2 FOR UPDATE;',
        [userId, id]
      );

      if (!recRes.rows[0]) {
        return { error: 'not_found' };
      }

      const rec = recRes.rows[0];
      const execDate = new Date(executionDate);
      const dateStr = execDate.toISOString().split('T')[0];
      const idempotencyKey = `rec_${rec.id}_${dateStr}`;

      // 1. Insert transaction with ON CONFLICT DO NOTHING to prevent duplicates
      const txRes = await client.query(
        `
        INSERT INTO transactions (
          user_id, amount_cents, type, currency, category, description,
          date, payment_method, account, notes, sync_status, idempotency_key
        )
        VALUES (
          $1, $2, $3, $4, $5, $6,
          $7, 'Scheduled Bill', $8, $9, 'synced', $10
        )
        ON CONFLICT (idempotency_key) DO NOTHING
        RETURNING *;
        `,
        [
          userId,
          rec.amount_cents,
          rec.type,
          rec.currency,
          rec.category,
          rec.description,
          execDate,
          rec.account,
          `Generated from recurring rule (${rec.recurrence_interval})`,
          idempotencyKey,
        ]
      );

      const isDuplicate = !txRes.rows[0];

      // 2. Calculate next execution date based on interval
      let nextDate = new Date(execDate);
      if (rec.recurrence_interval === 'daily') {
        nextDate.setDate(nextDate.getDate() + 1);
      } else if (rec.recurrence_interval === 'weekly') {
        nextDate.setDate(nextDate.getDate() + 7);
      } else if (rec.recurrence_interval === 'annual') {
        nextDate.setFullYear(nextDate.getFullYear() + 1);
      } else {
        // default monthly
        nextDate.setMonth(nextDate.getMonth() + 1);
      }

      await client.query(
        `
        UPDATE recurring_transactions
        SET next_execution_date = $1,
            last_executed_date = $2,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $3;
        `,
        [nextDate.toISOString().split('T')[0], dateStr, rec.id]
      );

      return {
        transaction: txRes.rows[0] ? { ...txRes.rows[0], amount_cents: Number(txRes.rows[0].amount_cents) } : null,
        isDuplicate,
        nextExecutionDate: nextDate.toISOString().split('T')[0],
      };
    });
  },
};
