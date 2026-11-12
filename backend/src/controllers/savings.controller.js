import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { savingsRepository } from '../repositories/savings.repository.js';

export const savingsController = {
  /**
   * GET /api/v1/savings/summary
   */
  async getSummary(req, res) {
    const summary = await savingsRepository.getSavingsSummary(req.user.id);
    sendJson(res, 200, { summary });
  },

  /**
   * GET /api/v1/savings/history
   */
  async getHistory(req, res) {
    const limit = req.query.limit ? parseInt(req.query.limit, 10) : 50;
    const offset = req.query.offset ? parseInt(req.query.offset, 10) : 0;

    const result = await savingsRepository.getSavingsHistory(req.user.id, { limit, offset });
    sendJson(res, 200, {
      items: result.items,
      pagination: {
        total: result.total,
        limit,
        offset,
        hasMore: offset + result.items.length < result.total,
      },
    });
  },

  /**
   * POST /api/v1/savings/deposit
   */
  async deposit(req, res) {
    const { amountCents, account, notes, date } = req.body;

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

    const transaction = await savingsRepository.deposit(req.user.id, {
      amountCents,
      account: account || 'Cash Wallet',
      notes: notes || '',
      date: date ? new Date(date) : new Date(),
    });

    sendJson(res, 201, {
      message: 'Savings deposit recorded successfully.',
      transaction,
    });
  },

  /**
   * POST /api/v1/savings/withdraw
   */
  async withdraw(req, res) {
    const { amountCents, account, notes, date } = req.body;

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

    const transaction = await savingsRepository.withdraw(req.user.id, {
      amountCents,
      account: account || 'Cash Wallet',
      notes: notes || '',
      date: date ? new Date(date) : new Date(),
    });

    sendJson(res, 201, {
      message: 'Savings withdrawal recorded successfully.',
      transaction,
    });
  },
};
