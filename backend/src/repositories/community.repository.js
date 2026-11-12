import { query, withTransaction } from '../config/database.js';

export const communityRepository = {
  /**
   * Creates a community savings group and sets the creator as initial admin/creator.
   */
  async createGroup(userId, { name, description = '', currency = 'ETB', targetAmountCents = 0, contributionFrequency = 'monthly' }) {
    return withTransaction(async (client) => {
      // 1. Create group
      const groupRes = await client.query(
        `
        INSERT INTO community_groups (
          name, description, currency, target_amount_cents, contribution_frequency, creator_id
        )
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *;
        `,
        [name, description, currency, targetAmountCents, contributionFrequency, userId]
      );

      const group = groupRes.rows[0];

      // 2. Add creator as 'creator' member
      await client.query(
        `
        INSERT INTO community_members (group_id, user_id, role)
        VALUES ($1, $2, 'creator');
        `,
        [group.id, userId]
      );

      return {
        ...group,
        target_amount_cents: Number(group.target_amount_cents),
      };
    });
  },

  /**
   * Retrieves all groups the user belongs to, along with aggregate group totals.
   * Privacy guarantee: Never exposes members' private individual transactions.
   */
  async getUserGroups(userId) {
    const sql = `
      SELECT
        g.id,
        g.name,
        g.description,
        g.currency,
        g.target_amount_cents,
        g.contribution_frequency,
        g.creator_id,
        g.is_archived,
        g.created_at,
        cm.role AS user_role,
        (
          SELECT COUNT(*)::int FROM community_members WHERE group_id = g.id
        ) AS member_count,
        COALESCE(
          (SELECT SUM(amount_cents) FROM community_contributions WHERE group_id = g.id), 0
        )::bigint AS total_contributions_cents,
        COALESCE(
          (SELECT SUM(amount_cents) FROM community_expenses WHERE group_id = g.id), 0
        )::bigint AS total_expenses_cents
      FROM community_groups g
      JOIN community_members cm ON cm.group_id = g.id AND cm.user_id = $1
      WHERE g.is_archived = FALSE
      ORDER BY g.created_at DESC;
    `;

    const res = await query(sql, [userId]);
    return res.rows.map((r) => {
      const target = Number(r.target_amount_cents);
      const contrib = Number(r.total_contributions_cents);
      const exp = Number(r.total_expenses_cents);
      const net = contrib - exp;

      return {
        id: r.id,
        name: r.name,
        description: r.description,
        currency: r.currency,
        targetAmountCents: target,
        contributionFrequency: r.contribution_frequency,
        userRole: r.user_role,
        memberCount: r.member_count,
        totalContributionsCents: contrib,
        totalExpensesCents: exp,
        netPoolCents: net,
        progressPercent: target > 0 ? Number(((contrib / target) * 100).toFixed(1)) : 0,
        createdAt: r.created_at,
      };
    });
  },

  /**
   * Retrieves detailed group view including members, collective contributions, and expenses.
   * Enforces group membership check.
   */
  async getGroupById(userId, groupId) {
    // 1. Verify user is a member of the group
    const membershipRes = await query(
      'SELECT role FROM community_members WHERE group_id = $1 AND user_id = $2;',
      [groupId, userId]
    );

    if (!membershipRes.rows[0]) {
      return null;
    }

    const [groupRes, membersRes, contributionsRes, expensesRes] = await Promise.all([
      query('SELECT * FROM community_groups WHERE id = $1;', [groupId]),
      query(
        `
        SELECT cm.id, cm.role, cm.joined_at, u.id AS user_id, u.email, p.full_name
        FROM community_members cm
        JOIN users u ON u.id = cm.user_id
        LEFT JOIN user_profiles p ON p.user_id = u.id
        WHERE cm.group_id = $1
        ORDER BY cm.joined_at ASC;
        `,
        [groupId]
      ),
      query(
        `
        SELECT cc.id, cc.amount_cents, cc.date, cc.notes, cc.created_at, p.full_name, u.email
        FROM community_contributions cc
        JOIN users u ON u.id = cc.user_id
        LEFT JOIN user_profiles p ON p.user_id = u.id
        WHERE cc.group_id = $1
        ORDER BY cc.date DESC;
        `,
        [groupId]
      ),
      query(
        `
        SELECT ce.id, ce.amount_cents, ce.category, ce.description, ce.date, ce.created_at, p.full_name
        FROM community_expenses ce
        JOIN users u ON u.id = ce.user_id
        LEFT JOIN user_profiles p ON p.user_id = u.id
        WHERE ce.group_id = $1
        ORDER BY ce.date DESC;
        `,
        [groupId]
      ),
    ]);

    if (!groupRes.rows[0]) return null;

    const g = groupRes.rows[0];
    const target = Number(g.target_amount_cents);
    const contributions = contributionsRes.rows.map((c) => ({
      ...c,
      amount_cents: Number(c.amount_cents),
    }));
    const expenses = expensesRes.rows.map((e) => ({
      ...e,
      amount_cents: Number(e.amount_cents),
    }));

    const totalContrib = contributions.reduce((acc, c) => acc + c.amount_cents, 0);
    const totalExp = expenses.reduce((acc, e) => acc + e.amount_cents, 0);

    return {
      id: g.id,
      name: g.name,
      description: g.description,
      currency: g.currency,
      targetAmountCents: target,
      contributionFrequency: g.contribution_frequency,
      creatorId: g.creator_id,
      totalContributionsCents: totalContrib,
      totalExpensesCents: totalExp,
      netPoolCents: totalContrib - totalExp,
      members: membersRes.rows.map((m) => ({
        userId: m.user_id,
        email: m.email,
        fullName: m.full_name || m.email.split('@')[0],
        role: m.role,
        joinedAt: m.joined_at,
      })),
      contributions,
      expenses,
      createdAt: g.created_at,
    };
  },

  /**
   * Invites a registered user to the group by email.
   * Requires requester to have 'creator' or 'admin' role.
   */
  async inviteMember(requesterId, groupId, { targetEmail, role = 'member' }) {
    // Check permission
    const requesterRes = await query(
      'SELECT role FROM community_members WHERE group_id = $1 AND user_id = $2;',
      [groupId, requesterId]
    );

    const requesterRole = requesterRes.rows[0]?.role;
    if (!['creator', 'admin'].includes(requesterRole)) {
      return { error: 'forbidden' };
    }

    // Find target user by email
    const targetUserRes = await query(
      'SELECT id, email FROM users WHERE LOWER(email) = LOWER($1);',
      [targetEmail.trim()]
    );

    if (!targetUserRes.rows[0]) {
      return { error: 'user_not_found' };
    }

    const targetUser = targetUserRes.rows[0];

    try {
      const insertRes = await query(
        `
        INSERT INTO community_members (group_id, user_id, role)
        VALUES ($1, $2, $3)
        RETURNING *;
        `,
        [groupId, targetUser.id, role]
      );
      return { member: insertRes.rows[0] };
    } catch (err) {
      if (err.code === '23505') {
        return { error: 'already_member' };
      }
      throw err;
    }
  },

  /**
   * Records a member contribution to the group savings pool.
   */
  async addContribution(userId, groupId, { amountCents, notes = '', date = new Date() }) {
    // Check membership
    const memberRes = await query(
      'SELECT role FROM community_members WHERE group_id = $1 AND user_id = $2;',
      [groupId, userId]
    );

    if (!memberRes.rows[0]) {
      return { error: 'not_a_member' };
    }

    const res = await query(
      `
      INSERT INTO community_contributions (group_id, user_id, amount_cents, date, notes)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
      `,
      [groupId, userId, amountCents, date, notes]
    );

    return {
      contribution: {
        ...res.rows[0],
        amount_cents: Number(res.rows[0].amount_cents),
      },
    };
  },

  /**
   * Records a shared group expense.
   * Requires member to be 'creator', 'admin', or 'treasurer'.
   */
  async addExpense(userId, groupId, { amountCents, category, description = '', date = new Date() }) {
    const memberRes = await query(
      'SELECT role FROM community_members WHERE group_id = $1 AND user_id = $2;',
      [groupId, userId]
    );

    const role = memberRes.rows[0]?.role;
    if (!['creator', 'admin', 'treasurer'].includes(role)) {
      return { error: 'forbidden' };
    }

    const res = await query(
      `
      INSERT INTO community_expenses (group_id, user_id, amount_cents, category, description, date)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *;
      `,
      [groupId, userId, amountCents, category, description, date]
    );

    return {
      expense: {
        ...res.rows[0],
        amount_cents: Number(res.rows[0].amount_cents),
      },
    };
  },
};
