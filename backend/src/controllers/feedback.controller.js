import { query } from '../config/database.js';
import { sendJson, sendError } from '../core/response.js';
import { auditService } from '../services/audit.service.js';

export const feedbackController = {
  /**
   * POST /api/v1/feedback - Submits a bug report, user feedback, or satisfaction survey.
   * Publicly accessible or authenticated.
   */
  async submitFeedback(req, res) {
    const userId = req.user?.id || null;
    const { type = 'feedback', category = 'general', rating = null, message, metadata = {} } =
      req.body || {};

    if (!message || message.trim().length === 0) {
      return sendError(res, 400, 'Feedback message is required.');
    }

    const validTypes = ['bug_report', 'feedback', 'satisfaction_survey'];
    if (!validTypes.includes(type)) {
      return sendError(res, 400, `Invalid feedback type. Allowed: ${validTypes.join(', ')}`);
    }

    const resDb = await query(
      `
      INSERT INTO beta_feedback (user_id, type, category, rating, message, metadata)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, type, category, rating, status, created_at;
      `,
      [userId, type, category, rating, message.trim(), JSON.stringify(metadata)]
    );

    if (userId) {
      await auditService.log({
        userId,
        action: 'FEEDBACK_SUBMITTED',
        entityType: 'feedback',
        entityId: resDb.rows[0].id,
        payload: { type, category, rating },
        ipAddress: req.socket?.remoteAddress,
      });
    }

    return sendJson(res, 201, {
      message: 'Thank you for your valuable feedback. Our engineering team reviews every submission.',
      feedback: resDb.rows[0],
    });
  },

  /**
   * GET /api/v1/feedback - Lists feedback entries for platform administrators.
   */
  async listFeedback(req, res) {
    const user = req.user;

    const adminCheckRes = await query(
      `SELECT platform_role FROM users WHERE id = $1;`,
      [user.id]
    );

    if (adminCheckRes.rows[0]?.platform_role !== 'platform_admin') {
      return sendError(res, 403, 'Forbidden: Viewing user feedback requires platform admin privileges.');
    }

    const { type, limit = 50 } = req.query || {};

    let sql = `SELECT * FROM beta_feedback`;
    const params = [];

    if (type) {
      params.push(type);
      sql += ` WHERE type = $1`;
    }

    sql += ` ORDER BY created_at DESC LIMIT $${params.length + 1};`;
    params.push(parseInt(limit, 10));

    const result = await query(sql, params);
    return sendJson(res, 200, result.rows);
  },
};
