import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { recurringRepository } from '../repositories/recurring.repository.js';

export const recurringController = {
  /**
   * GET /api/v1/recurring-transactions
   */
  async getRecurring(req, res) {
    const { isActive } = req.query;
    const activeBool = isActive !== undefined ? isActive === 'true' : undefined;

    const items = await recurringRepository.getRecurringTransactions(req.user.id, {
      isActive: activeBool,
    });

    sendJson(res, 200, { recurringTransactions: items });
  },

  /**
   * GET /api/v1/recurring-transactions/:id
   */
  async getRecurringById(req, res) {
    const { id } = req.params;
    const item = await recurringRepository.getRecurringById(req.user.id, id);

    if (!item) {
      return sendError(res, 404, 'Recurring transaction schedule not found.');
    }

    sendJson(res, 200, { recurringTransaction: item });
  },

  /**
   * POST /api/v1/recurring-transactions
   */
  async createRecurring(req, res) {
    const {
      amountCents,
      type,
      category,
      description,
      recurrenceInterval,
      nextExecutionDate,
      account,
      requiresReview,
      isActive,
    } = req.body;

    validateSchema(
      { amountCents, category, recurrenceInterval, nextExecutionDate },
      {
        amountCents: {
          required: true,
          validator: validator.isPositiveInteger,
          message: 'amountCents must be a positive integer in minor units (cents).',
        },
        category: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Category is required.',
        },
        recurrenceInterval: {
          required: true,
          validator: (val) => ['daily', 'weekly', 'monthly', 'annual'].includes(val),
          message: 'recurrenceInterval must be daily, weekly, monthly, or annual.',
        },
        nextExecutionDate: {
          required: true,
          validator: validator.isIsoDate,
          message: 'A valid ISO date string is required for nextExecutionDate.',
        },
      }
    );

    const created = await recurringRepository.createRecurring(req.user.id, {
      amountCents,
      type: type || 'expense',
      category: category.trim(),
      description: description || '',
      recurrenceInterval,
      nextExecutionDate: new Date(nextExecutionDate),
      account: account || 'Cash Wallet',
      requiresReview: requiresReview !== undefined ? Boolean(requiresReview) : true,
      isActive: isActive !== undefined ? Boolean(isActive) : true,
    });

    sendJson(res, 201, {
      message: 'Recurring transaction schedule created successfully.',
      recurringTransaction: created,
    });
  },

  /**
   * PATCH /api/v1/recurring-transactions/:id
   */
  async updateRecurring(req, res) {
    const { id } = req.params;
    const {
      amountCents,
      type,
      category,
      description,
      recurrenceInterval,
      nextExecutionDate,
      account,
      requiresReview,
      isActive,
    } = req.body;

    const updated = await recurringRepository.updateRecurring(req.user.id, id, {
      amountCents,
      type,
      category,
      description,
      recurrenceInterval,
      nextExecutionDate: nextExecutionDate ? new Date(nextExecutionDate) : undefined,
      account,
      requiresReview: requiresReview !== undefined ? Boolean(requiresReview) : undefined,
      isActive: isActive !== undefined ? Boolean(isActive) : undefined,
    });

    if (!updated) {
      return sendError(res, 404, 'Recurring transaction not found.');
    }

    sendJson(res, 200, {
      message: 'Recurring transaction updated successfully.',
      recurringTransaction: updated,
    });
  },

  /**
   * DELETE /api/v1/recurring-transactions/:id
   */
  async deleteRecurring(req, res) {
    const { id } = req.params;
    const deleted = await recurringRepository.deleteRecurring(req.user.id, id);

    if (!deleted) {
      return sendError(res, 404, 'Recurring transaction not found.');
    }

    sendJson(res, 200, {
      message: 'Recurring transaction schedule deleted.',
      id: deleted.id,
    });
  },

  /**
   * POST /api/v1/recurring-transactions/:id/generate
   * Generates a concrete transaction for this schedule with duplicate prevention.
   */
  async generateTransaction(req, res) {
    const { id } = req.params;
    const { executionDate } = req.body || {};

    const result = await recurringRepository.generateTransaction(req.user.id, id, {
      executionDate: executionDate ? new Date(executionDate) : new Date(),
    });

    if (result.error === 'not_found') {
      return sendError(res, 404, 'Recurring transaction schedule not found.');
    }

    if (result.isDuplicate) {
      return sendJson(res, 200, {
        message: 'Transaction for this period was already generated (duplicate prevented).',
        isDuplicate: true,
        nextExecutionDate: result.nextExecutionDate,
      });
    }

    sendJson(res, 201, {
      message: 'Transaction generated successfully from recurring schedule.',
      transaction: result.transaction,
      nextExecutionDate: result.nextExecutionDate,
    });
  },
};
