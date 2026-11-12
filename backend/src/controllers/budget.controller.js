import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { budgetRepository } from '../repositories/budget.repository.js';

export const budgetController = {
  /**
   * GET /api/v1/budgets
   */
  async getBudgets(req, res) {
    const budgets = await budgetRepository.getBudgets(req.user.id);
    sendJson(res, 200, { budgets });
  },

  /**
   * GET /api/v1/budgets/:id
   */
  async getBudgetById(req, res) {
    const { id } = req.params;
    const budget = await budgetRepository.getBudgetById(req.user.id, id);

    if (!budget) {
      return sendError(res, 404, 'Budget not found.');
    }

    sendJson(res, 200, { budget });
  },

  /**
   * POST /api/v1/budgets
   */
  async createBudget(req, res) {
    const {
      name,
      amountCents,
      period,
      category,
      startDate,
      endDate,
      warningThresholdPercent,
      dangerThresholdPercent,
      criticalThresholdPercent,
    } = req.body;

    validateSchema(
      { name, amountCents, startDate },
      {
        name: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Budget name is required.',
        },
        amountCents: {
          required: true,
          validator: validator.isPositiveInteger,
          message: 'amountCents must be a positive integer in minor units (cents).',
        },
        startDate: {
          required: true,
          validator: validator.isIsoDate,
          message: 'A valid ISO start date is required.',
        },
      }
    );

    const budget = await budgetRepository.createBudget(req.user.id, {
      name: name.trim(),
      amountCents,
      period: period || 'monthly',
      category: category || null,
      startDate: new Date(startDate),
      endDate: endDate ? new Date(endDate) : null,
      warningThresholdPercent,
      dangerThresholdPercent,
      criticalThresholdPercent,
    });

    sendJson(res, 201, {
      message: 'Budget created successfully.',
      budget,
    });
  },

  /**
   * PATCH /api/v1/budgets/:id
   */
  async updateBudget(req, res) {
    const { id } = req.params;
    const {
      name,
      amountCents,
      period,
      category,
      startDate,
      endDate,
      warningThresholdPercent,
      dangerThresholdPercent,
      criticalThresholdPercent,
    } = req.body;

    if (amountCents !== undefined && (!Number.isInteger(amountCents) || amountCents <= 0)) {
      return sendError(res, 400, 'amountCents must be a positive integer.');
    }

    const budget = await budgetRepository.updateBudget(req.user.id, id, {
      name: name ? name.trim() : undefined,
      amountCents,
      period,
      category,
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined,
      warningThresholdPercent,
      dangerThresholdPercent,
      criticalThresholdPercent,
    });

    if (!budget) {
      return sendError(res, 404, 'Budget not found.');
    }

    sendJson(res, 200, {
      message: 'Budget updated successfully.',
      budget,
    });
  },

  /**
   * DELETE /api/v1/budgets/:id
   */
  async deleteBudget(req, res) {
    const { id } = req.params;
    const deleted = await budgetRepository.deleteBudget(req.user.id, id);

    if (!deleted) {
      return sendError(res, 404, 'Budget not found.');
    }

    sendJson(res, 200, {
      message: 'Budget deleted successfully.',
      id: deleted.id,
      name: deleted.name,
    });
  },
};
