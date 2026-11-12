import { query } from '../config/database.js';

export const transactionRepository = {
  /**
   * Retrieves transactions for a user with pagination and predicate filtering.
   */
  async getTransactions(userId, { type, category, startDate, endDate, search, limit = 50, offset = 0 }) {
    const conditions = ['user_id = $1', 'deleted_at IS NULL'];
    const params = [userId];

    if (type) {
      params.push(type);
      conditions.push(`type = $${params.length}`);
    }

    if (category) {
      params.push(category);
      conditions.push(`category = $${params.length}`);
    }

    if (startDate) {
      params.push(new Date(startDate));
      conditions.push(`date >= $${params.length}`);
    }

    if (endDate) {
      params.push(new Date(endDate));
      conditions.push(`date <= $${params.length}`);
    }

    if (search) {
      params.push(`%${search.trim()}%`);
      conditions.push(
        `(description ILIKE $${params.length} OR category ILIKE $${params.length})`
      );
    }

    params.push(Number(limit));
    const limitPlaceholder = `$${params.length}`;
    params.push(Number(offset));
    const offsetPlaceholder = `$${params.length}`;

    const sql = `
      SELECT 
        id, 
        amount_cents, 
        type, 
        currency, 
        category, 
        description, 
        date, 
        payment_method, 
        account, 
        notes, 
        receipt_path, 
        sync_status, 
        idempotency_key, 
        created_at, 
        updated_at
      FROM transactions
      WHERE ${conditions.join(' AND ')}
      ORDER BY date DESC, created_at DESC
      LIMIT ${limitPlaceholder} OFFSET ${offsetPlaceholder};
    `;

    const countSql = `
      SELECT COUNT(*)::int AS total
      FROM transactions
      WHERE ${conditions.join(' AND ')};
    `;

    const [rowsRes, countRes] = await Promise.all([
      query(sql, params),
      query(countSql, params.slice(0, -2)),
    ]);

    return {
      items: rowsRes.rows,
      total: countRes.rows[0]?.total || 0,
      limit: Number(limit),
      offset: Number(offset),
    };
  },

  async getTransactionById(userId, id) {
    const sql = `
      SELECT * FROM transactions
      WHERE user_id = $1 AND id = $2 AND deleted_at IS NULL;
    `;
    const res = await query(sql, [userId, id]);
    return res.rows[0] || null;
  },

  async createTransaction(userId, data) {
    const sql = `
      INSERT INTO transactions (
        id,
        user_id,
        amount_cents,
        type,
        currency,
        category,
        description,
        date,
        payment_method,
        account,
        notes,
        receipt_path,
        sync_status,
        idempotency_key,
        created_at,
        updated_at
      )
      VALUES (
        COALESCE($1, gen_random_uuid()),
        $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
        COALESCE($15, CURRENT_TIMESTAMP),
        CURRENT_TIMESTAMP
      )
      ON CONFLICT (idempotency_key) DO UPDATE
      SET updated_at = CURRENT_TIMESTAMP
      RETURNING *;
    `;

    const res = await query(sql, [
      data.id || null,
      userId,
      data.amountCents,
      data.type,
      data.currency || 'ETB',
      data.category,
      data.description || '',
      data.date,
      data.paymentMethod || 'Cash',
      data.account || 'Cash Wallet',
      data.notes || '',
      data.receiptPath || null,
      data.syncStatus || 'synced',
      data.idempotencyKey || null,
      data.createdAt || null,
    ]);

    return res.rows[0];
  },

  async updateTransaction(userId, id, data) {
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
    if (data.date !== undefined) {
      params.push(data.date);
      fields.push(`date = $${params.length}`);
    }
    if (data.paymentMethod !== undefined) {
      params.push(data.paymentMethod);
      fields.push(`payment_method = $${params.length}`);
    }
    if (data.account !== undefined) {
      params.push(data.account);
      fields.push(`account = $${params.length}`);
    }
    if (data.notes !== undefined) {
      params.push(data.notes);
      fields.push(`notes = $${params.length}`);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);

    const sql = `
      UPDATE transactions
      SET ${fields.join(', ')}
      WHERE user_id = $1 AND id = $2 AND deleted_at IS NULL
      RETURNING *;
    `;

    const res = await query(sql, params);
    return res.rows[0] || null;
  },

  async deleteTransaction(userId, id) {
    // Soft-deletion with timestamp preserves tombstone for offline sync conflict resolution
    const sql = `
      UPDATE transactions
      SET deleted_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $1 AND id = $2 AND deleted_at IS NULL
      RETURNING id, deleted_at;
    `;
    const res = await query(sql, [userId, id]);
    return res.rows[0] || null;
  },

  /**
   * Calculates overall lifetime financial summary in minor units (cents).
   */
  async getSummary(userId) {
    const sql = `
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0)::bigint AS total_income_cents,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0)::bigint AS total_expense_cents,
        COALESCE(SUM(CASE WHEN type = 'savingsDeposit' THEN amount_cents ELSE 0 END), 0)::bigint AS actual_savings_deposits,
        COALESCE(SUM(CASE WHEN type = 'savingsWithdrawal' THEN amount_cents ELSE 0 END), 0)::bigint AS actual_savings_withdrawals
      FROM transactions
      WHERE user_id = $1 AND deleted_at IS NULL;
    `;
    const res = await query(sql, [userId]);
    const row = res.rows[0];

    const income = Number(row.total_income_cents);
    const expense = Number(row.total_expense_cents);
    const netSavings = income - expense;
    const actualSavingsReserve =
      Number(row.actual_savings_deposits) - Number(row.actual_savings_withdrawals);

    const savingsRate =
      income > 0 ? Number(((netSavings / income) * 100).toFixed(1)) : 0.0;

    return {
      totalIncomeCents: income,
      totalExpenseCents: expense,
      accumulatedNetSavingsCents: netSavings,
      actualSavingsReserveCents: actualSavingsReserve,
      savingsRate,
    };
  },

  /**
   * Calculates daily financial metrics for a specific calendar day.
   */
  async getDailySummary(userId, targetDate) {
    const d = new Date(targetDate);
    const start = new Date(d.getFullYear(), d.getMonth(), d.getDate());
    const end = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);

    const sql = `
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0)::bigint AS daily_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0)::bigint AS daily_expense
      FROM transactions
      WHERE user_id = $1 AND deleted_at IS NULL AND date >= $2 AND date <= $3;
    `;
    const res = await query(sql, [userId, start, end]);
    const inc = Number(res.rows[0].daily_income);
    const exp = Number(res.rows[0].daily_expense);

    return {
      date: start.toISOString().split('T')[0],
      dailyIncomeCents: inc,
      dailyExpenseCents: exp,
      dailySavingsCents: inc - exp,
    };
  },

  /**
   * Calculates monthly summary including category spending breakdown.
   */
  async getMonthlySummary(userId, year, month) {
    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 0, 23, 59, 59, 999);

    const totalsSql = `
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0)::bigint AS monthly_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0)::bigint AS monthly_expense
      FROM transactions
      WHERE user_id = $1 AND deleted_at IS NULL AND date >= $2 AND date <= $3;
    `;

    const categorySql = `
      SELECT category, SUM(amount_cents)::bigint AS amount_cents
      FROM transactions
      WHERE user_id = $1 AND type = 'expense' AND deleted_at IS NULL AND date >= $2 AND date <= $3
      GROUP BY category
      ORDER BY amount_cents DESC;
    `;

    const [totalsRes, categoryRes] = await Promise.all([
      query(totalsSql, [userId, start, end]),
      query(categorySql, [userId, start, end]),
    ]);

    const income = Number(totalsRes.rows[0].monthly_income);
    const expense = Number(totalsRes.rows[0].monthly_expense);

    return {
      year,
      month,
      monthlyIncomeCents: income,
      monthlyExpenseCents: expense,
      monthlyNetSavingsCents: income - expense,
      categoryBreakdown: categoryRes.rows.map((r) => ({
        category: r.category,
        amountCents: Number(r.amount_cents),
      })),
    };
  },
};
