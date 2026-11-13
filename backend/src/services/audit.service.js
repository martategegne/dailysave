import { query } from '../config/database.js';

export const auditService = {
  /**
   * Records a security or compliance audit event.
   */
  async log({ userId, workspaceId = null, action, entityType = null, entityId = null, payload = {}, ipAddress = null }) {
    try {
      await query(
        `
        INSERT INTO audit_logs (user_id, workspace_id, action, entity_type, entity_id, payload_json, ip_address)
        VALUES ($1, $2, $3, $4, $5, $6, $7);
        `,
        [userId, workspaceId, action, entityType, entityId ? String(entityId) : null, JSON.stringify(payload), ipAddress]
      );
    } catch (err) {
      console.error('[Audit Log Error]: Failed to write audit event:', err.message);
    }
  },

  /**
   * Retrieves audit logs for a workspace or user (Admin / Auditing only).
   */
  async getWorkspaceLogs(workspaceId, limit = 50) {
    const res = await query(
      `
      SELECT id, user_id, action, entity_type, entity_id, payload_json, ip_address, created_at
      FROM audit_logs
      WHERE workspace_id = $1
      ORDER BY created_at DESC
      LIMIT $2;
      `,
      [workspaceId, limit]
    );
    return res.rows;
  },
};
