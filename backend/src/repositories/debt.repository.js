import { query, withTransaction } from '../config/database.js';

export const debtRepository = {
  /**
   * Retrieves all debts for a user with optional type and settled status filtering.
   */
  async getDebts(userId, { debtType, isSettled } = {}) {
    const conditions = ['user_id = $1'];
    const params = [userId];

    if (debtType) {
      params.push(debtType);
      conditions.push(`debt_type = $${params.length}`);
    }

    if (isSettled !== undefined) {
      params.push(isSettled);
      conditions.push(`is_settled = $${params.length}`);
    }

    const sql = `
      SELECT
        id,
        person_name,
        debt_type,
        initial_amount_cents,
        remaining_amount_cents,
        currency,
        due_date,
        description,
        is_settled,
        created_at,
        updated_at
      FROM debts
      WHERE ${conditions.join(' AND ')}
      ORDER BY is_settled ASC, due_date ASC NULLS LAST, created_at DESC;
    `;

    const res = await query(sql, params);
    return res.rows.map((row) => ({
      ...row,
      initial_amount_cents: Number(row.initial_amount_cents),
      remaining_amount_cents: Number(row.remaining_amount_cents),
    }));
  },

  /**
   * Retrieves a specific debt by ID along with its payment history.
   */
  async getDebtById(userId, id) {
    const debtSql = `
      SELECT * FROM debts
      WHERE user_id = $1 AND id = $2;
    `;

    const paymentsSql = `
      SELECT id, debt_id, amount_cents, payment_date, payment_method, notes, created_at
      FROM debt_payments
      WHERE user_id = $1 AND debt_id = $2
      ORDER BY payment_date DESC, created_at DESC;
    `;

    const [debtRes, paymentsRes] = await Promise.all([
      query(debtSql, [userId, id]),
      query(paymentsSql, [userId, id]),
    ]);

    if (!debtRes.rows[0]) return null;

    const row = debtRes.rows[0];
    return {
      ...row,
      initial_amount_cents: Number(row.initial_amount_cents),
      remaining_amount_cents: Number(row.remaining_amount_cents),
      payments: paymentsRes.rows.map((p) => ({
        ...p,
        amount_cents: Number(p.amount_cents),
      })),
    };
  },

  async createDebt(userId, data) {
    const sql = `
      INSERT INTO debts (
        user_id,
        person_name,
        debt_type,
        initial_amount_cents,
        remaining_amount_cents,
        currency,
        due_date,
        description
      )
      VALUES ($1, $2, $3, $4, $4, $5, $6, $7)
      RETURNING id;
    `;

    const res = await query(sql, [
      userId,
      data.personName,
      data.debtType,
      data.initialAmountCents,
      data.currency || 'ETB',
      data.dueDate || null,
      data.description || '',
    ]);

    return this.getDebtById(userId, res.rows[0].id);
  },

  async updateDebt(userId, id, data) {
    const fields = [];
    const params = [userId, id];

    if (data.personName !== undefined) {
      params.push(data.personName);
      fields.push(`person_name = $${params.length}`);
    }
    if (data.dueDate !== undefined) {
      params.push(data.dueDate);
      fields.push(`due_date = $${params.length}`);
    }
    if (data.description !== undefined) {
      params.push(data.description);
      fields.push(`description = $${params.length}`);
    }
    if (data.isSettled !== undefined) {
      params.push(data.isSettled);
      fields.push(`is_settled = $${params.length}`);
    }

    if (fields.length === 0) {
      return this.getDebtById(userId, id);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);

    const sql = `
      UPDATE debts
      SET ${fields.join(', ')}
      WHERE user_id = $1 AND id = $2
      RETURNING id;
    `;

    const res = await query(sql, params);
    if (!res.rows[0]) return null;
    return this.getDebtById(userId, id);
  },

  async deleteDebt(userId, id) {
    const sql = `
      DELETE FROM debts
      WHERE user_id = $1 AND id = $2
      RETURNING id, person_name;
    `;
    const res = await query(sql, [userId, id]);
    return res.rows[0] || null;
  },

  /**
   * Records a repayment and reduces outstanding balance atomically.
   */
  async recordPayment(userId, debtId, { amountCents, paymentDate = new Date(), paymentMethod = 'Cash', notes = '' }) {
    return withTransaction(async (client) => {
      const debtRes = await client.query(
        'SELECT * FROM debts WHERE user_id = $1 AND id = $2 FOR UPDATE;',
        [userId, debtId]
      );

      if (!debtRes.rows[0]) {
        return null;
      }

      const debt = debtRes.rows[0];
      const newRemaining = Math.max(0, Number(debt.remaining_amount_cents) - Number(amountCents));
      const isSettled = newRemaining === 0;

      // 1. Insert payment record
      const paymentRes = await client.query(
        `
        INSERT INTO debt_payments (
          debt_id, user_id, amount_cents, payment_date, payment_method, notes
        )
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *;
        `,
        [debtId, userId, amountCents, paymentDate, paymentMethod, notes]
      );

      // 2. Update debt remaining amount and settled status
      await client.query(
        `
        UPDATE debts
        SET remaining_amount_cents = $1,
            is_settled = $2,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $3;
        `,
        [newRemaining, isSettled, debtId]
      );

      return {
        payment: {
          ...paymentRes.rows[0],
          amount_cents: Number(paymentRes.rows[0].amount_cents),
        },
        remainingAmountCents: newRemaining,
        isSettled,
      };
    });
  },
};
