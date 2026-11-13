import { query } from '../config/database.js';

export const workspaceRepository = {
  /**
   * Creates a new workspace and automatically assigns the creator as the owner and member.
   */
  async createWorkspace({ ownerId, name, type = 'personal', currency = 'ETB', description = '', defaultRole }) {
    const wsRes = await query(
      `
      INSERT INTO workspaces (owner_id, name, type, currency, description)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
      `,
      [ownerId, name, type, currency, description]
    );

    const workspace = wsRes.rows[0];

    // Map workspace type to appropriate owner role
    let role = defaultRole;
    if (!role) {
      switch (type) {
        case 'family':
          role = 'family_owner';
          break;
        case 'business':
          role = 'business_owner';
          break;
        case 'community':
          role = 'community_treasurer';
          break;
        default:
          role = 'individual_user';
      }
    }

    await query(
      `
      INSERT INTO workspace_members (workspace_id, user_id, role)
      VALUES ($1, $2, $3);
      `,
      [workspace.id, ownerId, role]
    );

    // Create free subscription record for this workspace
    await query(
      `
      INSERT INTO subscriptions (user_id, workspace_id, plan, status)
      VALUES ($1, $2, 'FREE', 'active')
      ON CONFLICT (user_id, workspace_id) DO NOTHING;
      `,
      [ownerId, workspace.id]
    );

    return { ...workspace, userRole: role };
  },

  /**
   * Lists all workspaces where the user is an active member.
   */
  async getUserWorkspaces(userId) {
    const res = await query(
      `
      SELECT w.id, w.name, w.type, w.currency, w.description, w.owner_id, 
             wm.role AS user_role, wm.joined_at, w.created_at,
             (SELECT count(*)::int FROM workspace_members WHERE workspace_id = w.id) AS member_count
      FROM workspaces w
      JOIN workspace_members wm ON wm.workspace_id = w.id
      WHERE wm.user_id = $1 AND w.deleted_at IS NULL
      ORDER BY w.created_at ASC;
      `,
      [userId]
    );
    return res.rows;
  },

  /**
   * Gets workspace by ID.
   */
  async getById(workspaceId) {
    const res = await query(
      `SELECT * FROM workspaces WHERE id = $1 AND deleted_at IS NULL;`,
      [workspaceId]
    );
    return res.rows[0] || null;
  },

  /**
   * Gets workspace members with user profile details.
   */
  async getMembers(workspaceId) {
    const res = await query(
      `
      SELECT wm.id, wm.workspace_id, wm.user_id, wm.role, wm.permissions, wm.joined_at,
             u.email, p.full_name, p.avatar_url
      FROM workspace_members wm
      JOIN users u ON u.id = wm.user_id
      LEFT JOIN user_profiles p ON p.user_id = u.id
      WHERE wm.workspace_id = $1
      ORDER BY wm.joined_at ASC;
      `,
      [workspaceId]
    );
    return res.rows;
  },

  /**
   * Creates an invitation token.
   */
  async createInvitation({ workspaceId, invitedBy, email, role, expiresInHours = 72 }) {
    const token = `inv_${Math.random().toString(36).substring(2, 15)}_${Date.now()}`;
    const expiresAt = new Date(Date.now() + expiresInHours * 60 * 60 * 1000);

    const res = await query(
      `
      INSERT INTO workspace_invitations (workspace_id, invited_by, email, role, token, expires_at)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *;
      `,
      [workspaceId, invitedBy, email.toLowerCase().trim(), role, token, expiresAt]
    );
    return res.rows[0];
  },

  /**
   * Accepts invitation and adds user to workspace.
   */
  async acceptInvitation(token, userId) {
    const invRes = await query(
      `SELECT * FROM workspace_invitations WHERE token = $1 AND status = 'pending' AND expires_at > CURRENT_TIMESTAMP;`,
      [token]
    );

    if (invRes.rows.length === 0) {
      return null;
    }

    const invitation = invRes.rows[0];

    // Add user as member
    await query(
      `
      INSERT INTO workspace_members (workspace_id, user_id, role)
      VALUES ($1, $2, $3)
      ON CONFLICT (workspace_id, user_id) DO UPDATE SET role = EXCLUDED.role;
      `,
      [invitation.workspace_id, userId, invitation.role]
    );

    // Update invitation status
    await query(
      `UPDATE workspace_invitations SET status = 'accepted' WHERE id = $1;`,
      [invitation.id]
    );

    return invitation;
  },

  /**
   * Updates a member's role.
   */
  async updateMemberRole(workspaceId, memberUserId, newRole) {
    const res = await query(
      `
      UPDATE workspace_members
      SET role = $1, updated_at = CURRENT_TIMESTAMP
      WHERE workspace_id = $2 AND user_id = $3
      RETURNING *;
      `,
      [newRole, workspaceId, memberUserId]
    );
    return res.rows[0] || null;
  },

  /**
   * Removes a member from workspace.
   */
  async removeMember(workspaceId, memberUserId) {
    const res = await query(
      `DELETE FROM workspace_members WHERE workspace_id = $1 AND user_id = $2 RETURNING id;`,
      [workspaceId, memberUserId]
    );
    return res.rowCount > 0;
  },

  /**
   * Transfers workspace ownership.
   */
  async transferOwnership(workspaceId, currentOwnerId, newOwnerId, newOwnerRole) {
    await query('BEGIN');
    try {
      await query(
        `UPDATE workspaces SET owner_id = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND owner_id = $3;`,
        [newOwnerId, workspaceId, currentOwnerId]
      );

      if (newOwnerRole) {
        await query(
          `UPDATE workspace_members SET role = $1 WHERE workspace_id = $2 AND user_id = $3;`,
          [newOwnerRole, workspaceId, newOwnerId]
        );
      }

      await query('COMMIT');
      return true;
    } catch (err) {
      await query('ROLLBACK');
      throw err;
    }
  },

  /**
   * Soft deletes a workspace.
   */
  async softDelete(workspaceId, ownerId) {
    const res = await query(
      `UPDATE workspaces SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1 AND owner_id = $2 RETURNING id;`,
      [workspaceId, ownerId]
    );
    return res.rowCount > 0;
  },
};
