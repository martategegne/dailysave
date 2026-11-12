import { query, withTransaction } from '../config/database.js';

export const goalRepository = {
  /**
   * Retrieves all goals with calculated progress and remaining amounts.
   */
  async getGoals(userId) {
    const sql = `
      SELECT
        id,
        name,
        target_amount_cents,
        current_amount_cents,
        currency,
        deadline,
        description,
        is_completed,
        created_at,
        updated_at
      FROM savings_goals
      WHERE user_id = $1
      ORDER BY deadline ASC, created_at DESC;
    `;

    const res = await query(sql, [userId]);
    return res.rows.map((row) => {
      const target = Number(row.target_amount_cents);
      const current = Number(row.current_amount_cents);
      const remaining = Math.max(0, target - current);
      const progressPercent = target > 0 ? Number(((current / target) * 100).toFixed(1)) : 0;

      return {
        id: row.id,
        name: row.name,
        targetAmountCents: target,
        currentAmountCents: current,
        remainingAmountCents: remaining,
        progressPercent,
        currency: row.currency,
        deadline: row.deadline,
        description: row.description,
        isCompleted: row.is_completed || current >= target,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      };
    });
  },

  /**
   * Retrieves single goal along with full contribution history.
   */
  async getGoalById(userId, id) {
    const goalSql = `
      SELECT * FROM savings_goals
      WHERE user_id = $1 AND id = $2;
    `;

    const contributionsSql = `
      SELECT id, goal_id, amount_cents, date, notes, source_account, created_at
      FROM savings_contributions
      WHERE user_id = $1 AND goal_id = $2
      ORDER BY date DESC, created_at DESC;
    `;

    const [goalRes, contribRes] = await Promise.all([
      query(goalSql, [userId, id]),
      query(contributionsSql, [userId, id]),
    ]);

    if (!goalRes.rows[0]) return null;

    const row = goalRes.rows[0];
    const target = Number(row.target_amount_cents);
    const current = Number(row.current_amount_cents);
    const remaining = Math.max(0, target - current);
    const progressPercent = target > 0 ? Number(((current / target) * 100).toFixed(1)) : 0;

    return {
      id: row.id,
      name: row.name,
      targetAmountCents: target,
      currentAmountCents: current,
      remainingAmountCents: remaining,
      progressPercent,
      currency: row.currency,
      deadline: row.deadline,
      description: row.description,
      isCompleted: row.is_completed || current >= target,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      contributions: contribRes.rows.map((c) => ({
        id: c.id,
        amountCents: Number(c.amount_cents),
        date: c.date,
        notes: c.notes,
        sourceAccount: c.source_account,
        createdAt: c.created_at,
      })),
    };
  },

  async createGoal(userId, data) {
    const sql = `
      INSERT INTO savings_goals (
        user_id,
        name,
        target_amount_cents,
        current_amount_cents,
        currency,
        deadline,
        description
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING id;
    `;

    const res = await query(sql, [
      userId,
      data.name,
      data.targetAmountCents,
      data.currentAmountCents || 0,
      data.currency || 'ETB',
      data.deadline,
      data.description || '',
    ]);

    return this.getGoalById(userId, res.rows[0].id);
  },

  async updateGoal(userId, id, data) {
    const fields = [];
    const params = [userId, id];

    if (data.name !== undefined) {
      params.push(data.name);
      fields.push(`name = $${params.length}`);
    }
    if (data.targetAmountCents !== undefined) {
      params.push(data.targetAmountCents);
      fields.push(`target_amount_cents = $${params.length}`);
    }
    if (data.deadline !== undefined) {
      params.push(data.deadline);
      fields.push(`deadline = $${params.length}`);
    }
    if (data.description !== undefined) {
      params.push(data.description);
      fields.push(`description = $${params.length}`);
    }
    if (data.isCompleted !== undefined) {
      params.push(data.isCompleted);
      fields.push(`is_completed = $${params.length}`);
    }

    if (fields.length === 0) {
      return this.getGoalById(userId, id);
    }

    fields.push(`updated_at = CURRENT_TIMESTAMP`);

    const sql = `
      UPDATE savings_goals
      SET ${fields.join(', ')}
      WHERE user_id = $1 AND id = $2
      RETURNING id;
    `;

    const res = await query(sql, params);
    if (!res.rows[0]) return null;
    return this.getGoalById(userId, id);
  },

  async deleteGoal(userId, id) {
    const sql = `
      DELETE FROM savings_goals
      WHERE user_id = $1 AND id = $2
      RETURNING id, name;
    `;
    const res = await query(sql, [userId, id]);
    return res.rows[0] || null;
  },

  /**
   * Records a goal contribution and updates goal balance atomically inside an ACID transaction.
   */
  async addContribution(userId, goalId, { amountCents, date = new Date(), notes = '', sourceAccount = 'Cash Wallet' }) {
    return withTransaction(async (client) => {
      // 1. Verify goal existence and ownership
      const goalRes = await client.query(
        'SELECT * FROM savings_goals WHERE user_id = $1 AND id = $2 FOR UPDATE;',
        [userId, goalId]
      );

      if (!goalRes.rows[0]) {
        return null;
      }

      const goal = goalRes.rows[0];
      const newTotal = Number(goal.current_amount_cents) + Number(amountCents);
      const isCompleted = newTotal >= Number(goal.target_amount_cents);

      // 2. Insert contribution record
      const contribRes = await client.query(
        `
        INSERT INTO savings_contributions (
          goal_id, user_id, amount_cents, date, notes, source_account
        )
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *;
        `,
        [goalId, userId, amountCents, date, notes, sourceAccount]
      );

      // 3. Update goal current amount and completion state
      await client.query(
        `
        UPDATE savings_goals
        SET current_amount_cents = $1,
            is_completed = $2,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $3;
        `,
        [newTotal, isCompleted, goalId]
      );

      return {
        contribution: {
          ...contribRes.rows[0],
          amount_cents: Number(contribRes.rows[0].amount_cents),
        },
        newTotalCents: newTotal,
        isCompleted,
      };
    });
  },
};
