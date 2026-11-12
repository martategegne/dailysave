import { query, withTransaction } from '../config/database.js';

export const savingsRepository = {
  /**
   * Retrieves overall savings metrics, growth progression, and reserves.
   */
  async getSavingsSummary(userId) {
    const totalsSql = `
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0)::bigint AS total_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0)::bigint AS total_expense,
        COALESCE(SUM(CASE WHEN type = 'savingsDeposit' THEN amount_cents ELSE 0 END), 0)::bigint AS total_deposits,
        COALESCE(SUM(CASE WHEN type = 'savingsWithdrawal' THEN amount_cents ELSE 0 END), 0)::bigint AS total_withdrawals
      FROM transactions
      WHERE user_id = $1 AND deleted_at IS NULL;
    `;

    // Monthly savings growth trajectory over past 12 months
    const growthSql = `
      SELECT
        TO_CHAR(date, 'YYYY-MM') AS month_label,
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0)::bigint AS monthly_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0)::bigint AS monthly_expense,
        COALESCE(SUM(CASE WHEN type = 'savingsDeposit' THEN amount_cents ELSE 0 END), 0)::bigint AS monthly_deposits,
        COALESCE(SUM(CASE WHEN type = 'savingsWithdrawal' THEN amount_cents ELSE 0 END), 0)::bigint AS monthly_withdrawals
      FROM transactions
      WHERE user_id = $1 AND deleted_at IS NULL
      GROUP BY TO_CHAR(date, 'YYYY-MM')
      ORDER BY month_label ASC
      LIMIT 12;
    `;

    const [totalsRes, growthRes] = await Promise.all([
      query(totalsSql, [userId]),
      query(growthSql, [userId]),
    ]);

    const row = totalsRes.rows[0];
    const income = Number(row.total_income);
    const expense = Number(row.total_expense);
    const deposits = Number(row.total_deposits);
    const withdrawals = Number(row.total_withdrawals);

    const calculatedNetSavings = income - expense;
    const actualSavingsReserve = deposits - withdrawals;
    const savingsRate = income > 0 ? Number(((calculatedNetSavings / income) * 100).toFixed(1)) : 0.0;

    let cumulativeReserve = 0;
    const growthHistory = growthRes.rows.map((r) => {
      const mIncome = Number(r.monthly_income);
      const mExpense = Number(r.monthly_expense);
      const mDeposits = Number(r.monthly_deposits);
      const mWithdrawals = Number(r.monthly_withdrawals);
      const mNet = mIncome - mExpense;
      cumulativeReserve += (mDeposits - mWithdrawals);

      return {
        month: r.month_label,
        incomeCents: mIncome,
        expenseCents: mExpense,
        netSavingsCents: mNet,
        depositedCents: mDeposits,
        withdrawnCents: mWithdrawals,
        cumulativeReserveCents: cumulativeReserve,
      };
    });

    return {
      calculatedNetSavingsCents: calculatedNetSavings,
      actualSavingsReserveCents: actualSavingsReserve,
      totalIncomeCents: income,
      totalExpenseCents: expense,
      totalDepositedCents: deposits,
      totalWithdrawnCents: withdrawals,
      savingsRate,
      growthHistory,
    };
  },

  /**
   * Retrieves transaction history specifically for savings deposits and withdrawals.
   */
  async getSavingsHistory(userId, { limit = 50, offset = 0 } = {}) {
    const sql = `
      SELECT 
        id, amount_cents, type, currency, category, description,
        date, payment_method, account, notes, created_at
      FROM transactions
      WHERE user_id = $1 AND type IN ('savingsDeposit', 'savingsWithdrawal') AND deleted_at IS NULL
      ORDER BY date DESC, created_at DESC
      LIMIT $2 OFFSET $3;
    `;

    const countSql = `
      SELECT COUNT(*)::int AS total
      FROM transactions
      WHERE user_id = $1 AND type IN ('savingsDeposit', 'savingsWithdrawal') AND deleted_at IS NULL;
    `;

    const [rowsRes, countRes] = await Promise.all([
      query(sql, [userId, limit, offset]),
      query(countSql, [userId]),
    ]);

    return {
      items: rowsRes.rows,
      total: countRes.rows[0]?.total || 0,
    };
  },

  /**
   * Performs a savings deposit operation.
   */
  async deposit(userId, { amountCents, account = 'Cash Wallet', notes = '', date = new Date() }) {
    const sql = `
      INSERT INTO transactions (
        user_id, amount_cents, type, currency, category,
        description, date, payment_method, account, notes, sync_status
      )
      VALUES ($1, $2, 'savingsDeposit', 'ETB', 'Savings Deposit', 'Transfer into savings reserve', $3, 'Account Transfer', $4, $5, 'synced')
      RETURNING *;
    `;
    const res = await query(sql, [userId, amountCents, date, account, notes]);
    return res.rows[0];
  },

  /**
   * Performs a savings withdrawal operation.
   */
  async withdraw(userId, { amountCents, account = 'Cash Wallet', notes = '', date = new Date() }) {
    const sql = `
      INSERT INTO transactions (
        user_id, amount_cents, type, currency, category,
        description, date, payment_method, account, notes, sync_status
      )
      VALUES ($1, $2, 'savingsWithdrawal', 'ETB', 'Savings Withdrawal', 'Withdrawal from savings reserve', $3, 'Account Transfer', $4, $5, 'synced')
      RETURNING *;
    `;
    const res = await query(sql, [userId, amountCents, date, account, notes]);
    return res.rows[0];
  },
};
