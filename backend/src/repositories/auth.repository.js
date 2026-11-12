import { query, withTransaction } from '../config/database.js';

export const authRepository = {
  async findUserByEmail(email) {
    const sql = `
      SELECT 
        u.id, 
        u.email, 
        u.password_hash, 
        u.is_active, 
        u.email_verified, 
        u.created_at,
        p.full_name,
        p.phone_number,
        p.avatar_url,
        pref.default_currency,
        pref.language,
        pref.theme_mode
      FROM users u
      LEFT JOIN user_profiles p ON p.user_id = u.id
      LEFT JOIN user_preferences pref ON pref.user_id = u.id
      WHERE LOWER(u.email) = LOWER($1);
    `;
    const res = await query(sql, [email.trim()]);
    return res.rows[0] || null;
  },

  async findUserById(id) {
    const sql = `
      SELECT 
        u.id, 
        u.email, 
        u.is_active, 
        u.email_verified, 
        u.created_at,
        p.full_name,
        p.phone_number,
        p.avatar_url,
        pref.default_currency,
        pref.language,
        pref.theme_mode
      FROM users u
      LEFT JOIN user_profiles p ON p.user_id = u.id
      LEFT JOIN user_preferences pref ON pref.user_id = u.id
      WHERE u.id = $1;
    `;
    const res = await query(sql, [id]);
    return res.rows[0] || null;
  },

  /**
   * Creates a user, their initial profile, default preferences, and a starter Cash Wallet
   * inside an atomic ACID database transaction.
   */
  async createUserWithProfile({
    email,
    passwordHash,
    fullName,
    defaultCurrency = 'ETB',
    language = 'en',
  }) {
    return withTransaction(async (client) => {
      // 1. Insert user
      const userRes = await client.query(
        `INSERT INTO users (email, password_hash)
         VALUES ($1, $2)
         RETURNING id, email, is_active, created_at;`,
        [email.toLowerCase().trim(), passwordHash]
      );
      const user = userRes.rows[0];

      // 2. Insert profile
      await client.query(
        `INSERT INTO user_profiles (user_id, full_name)
         VALUES ($1, $2);`,
        [user.id, fullName.trim()]
      );

      // 3. Insert preferences
      await client.query(
        `INSERT INTO user_preferences (user_id, default_currency, language)
         VALUES ($1, $2, $3);`,
        [user.id, defaultCurrency, language]
      );

      // 4. Pre-seed default Cash Wallet account
      await client.query(
        `INSERT INTO accounts (user_id, name, account_type, currency, initial_balance_cents)
         VALUES ($1, 'Cash Wallet', 'cash', $2, 0);`,
        [user.id, defaultCurrency]
      );

      return {
        id: user.id,
        email: user.email,
        fullName: fullName.trim(),
        defaultCurrency,
        language,
        createdAt: user.created_at,
      };
    });
  },

  async storeRefreshToken({ userId, tokenHash, expiresAt, ipAddress, userAgent }) {
    const sql = `
      INSERT INTO refresh_tokens (user_id, token_hash, expires_at, ip_address, user_agent)
      VALUES ($1, $2, $3, $4, $5);
    `;
    await query(sql, [userId, tokenHash, expiresAt, ipAddress, userAgent]);
  },

  async findRefreshToken(tokenHash) {
    const sql = `
      SELECT id, user_id, token_hash, expires_at, is_revoked, replaced_by_token
      FROM refresh_tokens
      WHERE token_hash = $1;
    `;
    const res = await query(sql, [tokenHash]);
    return res.rows[0] || null;
  },

  async revokeRefreshToken(tokenHash, replacedByToken = null) {
    const sql = `
      UPDATE refresh_tokens
      SET is_revoked = TRUE, replaced_by_token = $2
      WHERE token_hash = $1;
    `;
    await query(sql, [tokenHash, replacedByToken]);
  },

  async revokeAllUserTokens(userId) {
    const sql = `
      UPDATE refresh_tokens
      SET is_revoked = TRUE
      WHERE user_id = $1 AND is_revoked = FALSE;
    `;
    await query(sql, [userId]);
  },

  async recordAuditLog({ userId, action, entityType, entityId, payload, ipAddress }) {
    const sql = `
      INSERT INTO audit_logs (user_id, action, entity_type, entity_id, payload_json, ip_address)
      VALUES ($1, $2, $3, $4, $5, $6);
    `;
    await query(sql, [
      userId || null,
      action,
      entityType || null,
      entityId || null,
      payload ? JSON.stringify(payload) : null,
      ipAddress || null,
    ]);
  },

  /**
   * Completely purges a user's account and all associated financial records.
   */
  async deleteUserAccount(userId) {
    const sql = `DELETE FROM users WHERE id = $1;`;
    await query(sql, [userId]);
  },

  /**
   * Generates a complete GDPR/privacy data export of the user's data.
   */
  async exportUserData(userId) {
    const user = await this.findUserById(userId);
    const txs = await query(
      `SELECT * FROM transactions WHERE user_id = $1 ORDER BY date DESC;`,
      [userId]
    );
    const accs = await query(
      `SELECT * FROM accounts WHERE user_id = $1;`,
      [userId]
    );
    const budgets = await query(
      `SELECT * FROM budgets WHERE user_id = $1;`,
      [userId]
    );
    const goals = await query(
      `SELECT * FROM savings_goals WHERE user_id = $1;`,
      [userId]
    );
    const debts = await query(
      `SELECT * FROM debts WHERE user_id = $1;`,
      [userId]
    );

    return {
      profile: user,
      accounts: accs.rows,
      transactions: txs.rows,
      budgets: budgets.rows,
      goals: goals.rows,
      debts: debts.rows,
      exportedAt: new Date().toISOString(),
    };
  },
};
