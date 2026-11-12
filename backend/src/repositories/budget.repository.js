import { query } from '../config/database.js';

export const budgetRepository = {
  /**
   * Retrieves all budgets for a user along with current actual spend and threshold status.
   */
  async getBudgets(userId) {
    const sql = `
      SELECT
        b.id,
        b.name,
        b.amount_cents,
        b.period,
        b.category,
        b.start_date,
        b.end_date,
        b.warning_threshold_percent,
        b.danger_threshold_percent,
        b.critical_threshold_percent,
        b.created_at,
        b.updated_at,
        COALESCE(SUM(t.amount_cents), 0)::bigint AS spent_cents
      FROM budgets b
      LEFT JOIN transactions t
        ON t.user_id = b.user_id
        AND t.type = 'expense'
        AND t.deleted_at IS NULL
        AND t.date >= b.start_date
        AND (b.end_date IS NULL OR t.date <= b.end_date)
        AND (b.category IS NULL OR t.category = b.category)
      WHERE b.user_id = $1
      GROUP BY b.id
      ORDER BY b.created_at DESC;
    `;

    const res = await query(sql, [userId]);
    return res.rows.map((row) => {
      const budgetAmount = Number(row.amount_cents);
      const spent = Number(row.spent_cents);
      const remaining = budgetAmount - spent;
      const percentageUsed = budgetAmount > 0 ? Number(((spent / budgetAmount) * 100).toFixed(1)) : 0;

      let status = 'normal';
      if (percentageUsed >= row.critical_threshold_percent) {
        status = 'critical';
      } else if (percentageUsed >= row.danger_threshold_percent) {
        status = 'danger';
      } else if (percentageUsed >= row.warning_threshold_percent) {
        status = 'warning';
      }

      return {
        id: row.id,
        name: row.name,
        amountCents: budgetAmount,
        spentCents: spent,
        remainingCents: remaining,
        percentageUsed,
        status,
        period: row.period,
        category: row.category,
        startDate: row.start_date,
        endDate: row.end_date,
        thresholds: {
          warning: row.warning_threshold_percent,
          danger: row.danger_threshold_percent,
          critical: row.critical_threshold_percent,
        },
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      };
    });
  },

  async getBudgetById(userId, id) {
    const budgets = await this.getBudgets(userId);
    return budgets.find((b) => b.id === id) || null;
  },

  async createBudget(userId, data) {
    const sql = `
      INSERT INTO budgets (
        user_id,
        name,
        amount_cents,
        period,
        category,
        start_date,
        end_date,
        warning_threshold_percent,
        danger_threshold_percent,
        critical_threshold_percent
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING id;
    `;

    const res = await query(sql, [
      userId,
      data.name,
      data.amountCents,
      data.period || 'monthly',
      data.category || null,
      data.startDate,
      data.endDate || null,
      data.warningThresholdPercent || 75,
      data.dangerThresholdPercent || 90,
      data.criticalThresholdPercent || 100,
    ]);

    return this.getBudgetById(userId, res.rows[0].id);
  },

  async updateBudget(userId, id, data) {
    const fields = [];
    const params = [userId, id];

    if (data.name !== undefined) {
      params.push(data.name);
      fields.push(`name = $${params.length}`);
    }
    if (data.amountCents !== undefined) {
      params.push(data.amountCents);
      fields.push(`amount_cents = $${params.length}`);
    }
    if (data.period !== undefined) {
      params.push(data.period);
      fields.push(`period = $${params.length}`);
    }
    if (data.category !== undefined) {
      params.push(data.category);
      fields.push(`category = $${params.length}`);
    }
    if (data.startDate !== undefined) {
      params.push(data.startDate);
      fields.push(`start_date = $${params.length}`);
    }
    if (data.endDate !== undefined) {
      params.push(data.endDate);
      fields.push(`end_date = $${params.length}`);
    }
    if (data.warningThresholdPercent !== undefined) {
      params.push(data.warningThresholdPercent);
      fields.push(`warning_threshold_percent = $${params.length}`);
    }
    if (data.dangerThresholdPercent !== undefined) {
      params.push(data.dangerThresholdPercent);
      fields.push(`danger_threshold_percent = $${params.length}`);
    }
    if (data.criticalThresholdPercent !== undefined) {
      params.push(data.criticalThresholdPercent);
      fields.push(`critical_threshold_percent = $${params.length}`);
    }

    if (fields.length === 0) {
      return this.getBudgetById(userId, id);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);

    const sql = `
      UPDATE budgets
      SET ${fields.join(', ')}
      WHERE user_id = $1 AND id = $2
      RETURNING id;
    `;

    const res = await query(sql, params);
    if (!res.rows[0]) return null;
    return this.getBudgetById(userId, id);
  },

  async deleteBudget(userId, id) {
    const sql = `
      DELETE FROM budgets
      WHERE user_id = $1 AND id = $2
      RETURNING id, name;
    `;
    const res = await query(sql, [userId, id]);
    return res.rows[0] || null;
  },
};
