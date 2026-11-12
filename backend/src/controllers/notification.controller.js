import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { notificationRepository } from '../repositories/notification.repository.js';

export const notificationController = {
  /**
   * GET /api/v1/notifications
   */
  async getNotifications(req, res) {
    const unreadOnly = req.query.unreadOnly === 'true';
    const limit = req.query.limit ? parseInt(req.query.limit, 10) : 50;
    const offset = req.query.offset ? parseInt(req.query.offset, 10) : 0;

    const result = await notificationRepository.getNotifications(req.user.id, {
      unreadOnly,
      limit,
      offset,
    });

    sendJson(res, 200, result);
  },

  /**
   * POST /api/v1/notifications
   * (Allows system triggers or users to create reminders)
   */
  async createNotification(req, res) {
    const { title, message, type, metadata } = req.body;

    validateSchema(
      { title, message },
      {
        title: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Notification title is required.',
        },
        message: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Notification message is required.',
        },
      }
    );

    const notification = await notificationRepository.createNotification(req.user.id, {
      title: title.trim(),
      message: message.trim(),
      type: type || 'info',
      metadata: metadata || null,
    });

    sendJson(res, 201, {
      message: 'Notification created successfully.',
      notification,
    });
  },

  /**
   * PATCH /api/v1/notifications/:id/read
   */
  async markAsRead(req, res) {
    const { id } = req.params;
    const notification = await notificationRepository.markAsRead(req.user.id, id);

    if (!notification) {
      return sendError(res, 404, 'Notification not found.');
    }

    sendJson(res, 200, {
      message: 'Notification marked as read.',
      notification,
    });
  },

  /**
   * POST /api/v1/notifications/mark-all-read
   */
  async markAllAsRead(req, res) {
    const result = await notificationRepository.markAllAsRead(req.user.id);
    sendJson(res, 200, {
      message: 'All notifications marked as read.',
      updatedCount: result.updatedCount,
    });
  },

  /**
   * DELETE /api/v1/notifications/:id
   */
  async deleteNotification(req, res) {
    const { id } = req.params;
    const deleted = await notificationRepository.deleteNotification(req.user.id, id);

    if (!deleted) {
      return sendError(res, 404, 'Notification not found.');
    }

    sendJson(res, 200, {
      message: 'Notification deleted.',
      id: deleted.id,
    });
  },
};
