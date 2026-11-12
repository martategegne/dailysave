import { query } from '../config/database.js';

export const notificationRepository = {
  /**
   * Retrieves in-app notifications for a user with unread count and pagination.
   */
  async getNotifications(userId, { unreadOnly = false, limit = 50, offset = 0 } = {}) {
    const conditions = ['user_id = $1'];
    const params = [userId];

    if (unreadOnly) {
      conditions.push('is_read = FALSE');
    }

    params.push(Number(limit));
    const limitPlaceholder = `$${params.length}`;
    params.push(Number(offset));
    const offsetPlaceholder = `$${params.length}`;

    const sql = `
      SELECT id, title, message, type, is_read, metadata_json, created_at
      FROM notifications
      WHERE ${conditions.join(' AND ')}
      ORDER BY created_at DESC
      LIMIT ${limitPlaceholder} OFFSET ${offsetPlaceholder};
    `;

    const countSql = `
      SELECT 
        COUNT(*)::int AS total,
        COUNT(CASE WHEN is_read = FALSE THEN 1 END)::int AS unread_count
      FROM notifications
      WHERE user_id = $1;
    `;

    const [rowsRes, countRes] = await Promise.all([
      query(sql, params),
      query(countSql, [userId]),
    ]);

    return {
      notifications: rowsRes.rows,
      total: countRes.rows[0]?.total || 0,
      unreadCount: countRes.rows[0]?.unread_count || 0,
      limit: Number(limit),
      offset: Number(offset),
    };
  },

  async createNotification(userId, { title, message, type = 'info', metadata = null }) {
    const sql = `
      INSERT INTO notifications (user_id, title, message, type, metadata_json)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *;
    `;
    const res = await query(sql, [
      userId,
      title,
      message,
      type,
      metadata ? JSON.stringify(metadata) : null,
    ]);
    return res.rows[0];
  },

  async markAsRead(userId, id) {
    const sql = `
      UPDATE notifications
      SET is_read = TRUE
      WHERE user_id = $1 AND id = $2
      RETURNING *;
    `;
    const res = await query(sql, [userId, id]);
    return res.rows[0] || null;
  },

  async markAllAsRead(userId) {
    const sql = `
      UPDATE notifications
      SET is_read = TRUE
      WHERE user_id = $1 AND is_read = FALSE
      RETURNING id;
    `;
    const res = await query(sql, [userId]);
    return { updatedCount: res.rowCount };
  },

  async deleteNotification(userId, id) {
    const sql = `
      DELETE FROM notifications
      WHERE user_id = $1 AND id = $2
      RETURNING id;
    `;
    const res = await query(sql, [userId, id]);
    return res.rows[0] || null;
  },
};
