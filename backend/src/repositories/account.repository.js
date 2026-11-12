import { query } from '../config/database.js';

export const accountRepository = {
  /**
   * Retrieves all accounts for the user, computing the live balance in integer cents.
   */
  async getAccounts(userId, { includeArchived = false } = {}) {
    const archiveClause = includeArchived ? '' : 'AND a.is_archived = FALSE';

    const sql = `
      SELECT 
        a.id,
        a.name,
        a.account_type,
        a.currency,
        a.initial_balance_cents,
        a.is_archived,
        a.created_at,
        a.updated_at,
        (
          a.initial_balance_cents +
          COALESCE(SUM(
            CASE 
              WHEN t.type = 'income' OR t.type = 'savingsWithdrawal' THEN t.amount_cents
              WHEN t.type = 'expense' OR t.type = 'savingsDeposit' THEN -t.amount_cents
              ELSE 0
            END
          ), 0)
        )::bigint AS current_balance_cents
      FROM accounts a
      LEFT JOIN transactions t 
        ON t.user_id = a.user_id 
        AND t.account = a.name 
        AND t.deleted_at IS NULL
      WHERE a.user_id = $1 ${archiveClause}
      GROUP BY a.id
      ORDER BY a.created_at ASC;
    `;

    const res = await query(sql, [userId]);
    return res.rows.map((row) => ({
      ...row,
      initial_balance_cents: Number(row.initial_balance_cents),
      current_balance_cents: Number(row.current_balance_cents),
    }));
  },

  async getAccountById(userId, id) {
    const sql = `
      SELECT 
        a.id,
        a.name,
        a.account_type,
        a.currency,
        a.initial_balance_cents,
        a.is_archived,
        a.created_at,
        a.updated_at,
        (
          a.initial_balance_cents +
          COALESCE(SUM(
            CASE 
              WHEN t.type = 'income' OR t.type = 'savingsWithdrawal' THEN t.amount_cents
              WHEN t.type = 'expense' OR t.type = 'savingsDeposit' THEN -t.amount_cents
              ELSE 0
            END
          ), 0)
        )::bigint AS current_balance_cents
      FROM accounts a
      LEFT JOIN transactions t 
        ON t.user_id = a.user_id 
        AND t.account = a.name 
        AND t.deleted_at IS NULL
      WHERE a.user_id = $1 AND a.id = $2
      GROUP BY a.id;
    `;
    const res = await query(sql, [userId, id]);
    if (!res.rows[0]) return null;

    const row = res.rows[0];
    return {
      ...row,
      initial_balance_cents: Number(row.initial_balance_cents),
      current_balance_cents: Number(row.current_balance_cents),
    };
  },

  async createAccount(userId, { name, accountType = 'cash', currency = 'ETB', initialBalanceCents = 0 }) {
    const sql = `
      INSERT INTO accounts (user_id, name, account_type, currency, initial_balance_cents)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
    `;
    const res = await query(sql, [userId, name, accountType, currency, initialBalanceCents]);
    const created = res.rows[0];
    return {
      ...created,
      initial_balance_cents: Number(created.initial_balance_cents),
      current_balance_cents: Number(created.initial_balance_cents),
    };
  },

  async updateAccount(userId, id, { name, accountType, isArchived }) {
    const fields = [];
    const params = [userId, id];

    if (name !== undefined) {
      params.push(name);
      fields.push(`name = $${params.length}`);
    }
    if (accountType !== undefined) {
      params.push(accountType);
      fields.push(`account_type = $${params.length}`);
    }
    if (isArchived !== undefined) {
      params.push(isArchived);
      fields.push(`is_archived = $${params.length}`);
    }

    if (fields.length === 0) {
      return this.getAccountById(userId, id);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);

    const sql = `
      UPDATE accounts
      SET ${fields.join(', ')}
      WHERE user_id = $1 AND id = $2
      RETURNING *;
    `;

    const res = await query(sql, params);
    if (!res.rows[0]) return null;
    return this.getAccountById(userId, id);
  },

  async deleteAccount(userId, id) {
    const sql = `
      DELETE FROM accounts
      WHERE user_id = $1 AND id = $2
      RETURNING id, name;
    `;
    const res = await query(sql, [userId, id]);
    return res.rows[0] || null;
  },
};
