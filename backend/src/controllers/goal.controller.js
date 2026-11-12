import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { goalRepository } from '../repositories/goal.repository.js';

export const goalController = {
  /**
   * GET /api/v1/goals
   */
  async getGoals(req, res) {
    const goals = await goalRepository.getGoals(req.user.id);
    sendJson(res, 200, { goals });
  },

  /**
   * GET /api/v1/goals/:id
   */
  async getGoalById(req, res) {
    const { id } = req.params;
    const goal = await goalRepository.getGoalById(req.user.id, id);

    if (!goal) {
      return sendError(res, 404, 'Savings goal not found.');
    }

    sendJson(res, 200, { goal });
  },

  /**
   * POST /api/v1/goals
   */
  async createGoal(req, res) {
    const { name, targetAmountCents, deadline, description, currency } = req.body;

    validateSchema(
      { name, targetAmountCents, deadline },
      {
        name: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Goal name is required.',
        },
        targetAmountCents: {
          required: true,
          validator: validator.isPositiveInteger,
          message: 'targetAmountCents must be a positive integer in minor units (cents).',
        },
        deadline: {
          required: true,
          validator: validator.isIsoDate,
          message: 'A valid ISO deadline date is required.',
        },
      }
    );

    const goal = await goalRepository.createGoal(req.user.id, {
      name: name.trim(),
      targetAmountCents,
      deadline: new Date(deadline),
      description: description || '',
      currency: currency || req.user.currency || 'ETB',
    });

    sendJson(res, 201, {
      message: 'Savings goal created successfully.',
      goal,
    });
  },

  /**
   * PATCH /api/v1/goals/:id
   */
  async updateGoal(req, res) {
    const { id } = req.params;
    const { name, targetAmountCents, deadline, description, isCompleted } = req.body;

    if (targetAmountCents !== undefined && (!Number.isInteger(targetAmountCents) || targetAmountCents <= 0)) {
      return sendError(res, 400, 'targetAmountCents must be a positive integer.');
    }

    const goal = await goalRepository.updateGoal(req.user.id, id, {
      name: name ? name.trim() : undefined,
      targetAmountCents,
      deadline: deadline ? new Date(deadline) : undefined,
      description,
      isCompleted: isCompleted !== undefined ? Boolean(isCompleted) : undefined,
    });

    if (!goal) {
      return sendError(res, 404, 'Savings goal not found.');
    }

    sendJson(res, 200, {
      message: 'Savings goal updated successfully.',
      goal,
    });
  },

  /**
   * DELETE /api/v1/goals/:id
   */
  async deleteGoal(req, res) {
    const { id } = req.params;
    const deleted = await goalRepository.deleteGoal(req.user.id, id);

    if (!deleted) {
      return sendError(res, 404, 'Savings goal not found.');
    }

    sendJson(res, 200, {
      message: 'Savings goal deleted successfully.',
      id: deleted.id,
      name: deleted.name,
    });
  },

  /**
   * POST /api/v1/goals/:id/contribute
   */
  async contribute(req, res) {
    const { id } = req.params;
    const { amountCents, date, notes, sourceAccount } = req.body;

    validateSchema(
      { amountCents },
      {
        amountCents: {
          required: true,
          validator: validator.isPositiveInteger,
          message: 'amountCents must be a positive integer in minor units (cents).',
        },
      }
    );

    const result = await goalRepository.addContribution(req.user.id, id, {
      amountCents,
      date: date ? new Date(date) : new Date(),
      notes: notes || '',
      sourceAccount: sourceAccount || 'Cash Wallet',
    });

    if (!result) {
      return sendError(res, 404, 'Savings goal not found.');
    }

    sendJson(res, 200, {
      message: 'Contribution recorded successfully.',
      contribution: result.contribution,
      newTotalCents: result.newTotalCents,
      isCompleted: result.isCompleted,
    });
  },
};
