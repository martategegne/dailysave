import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { transactionRepository } from '../repositories/transaction.repository.js';

export const transactionController = {
  /**
   * GET /api/v1/transactions
   * Query params: type, category, startDate, endDate, search, limit, offset
   */
  async getTransactions(req, res) {
    const { type, category, startDate, endDate, search, limit, offset } = req.query;

    const result = await transactionRepository.getTransactions(req.user.id, {
      type,
      category,
      startDate,
      endDate,
      search,
      limit: limit ? parseInt(limit, 10) : 50,
      offset: offset ? parseInt(offset, 10) : 0,
    });

    sendJson(res, 200, {
      transactions: result.items,
      pagination: {
        total: result.total,
        limit: result.limit,
        offset: result.offset,
        hasMore: result.offset + result.items.length < result.total,
      },
    });
  },

  /**
   * GET /api/v1/transactions/:id
   */
  async getTransactionById(req, res) {
    const { id } = req.params;
    const tx = await transactionRepository.getTransactionById(req.user.id, id);

    if (!tx) {
      return sendError(res, 404, 'Transaction not found.');
    }

    sendJson(res, 200, { transaction: tx });
  },

  /**
   * POST /api/v1/transactions
   */
  async createTransaction(req, res) {
    const {
      id,
      amountCents,
      type,
      currency,
      category,
      description,
      date,
      paymentMethod,
      account,
      notes,
      receiptPath,
      syncStatus,
      idempotencyKey,
      createdAt,
    } = req.body;

    validateSchema(
      { amountCents, type, category, date },
      {
        amountCents: {
          required: true,
          validator: validator.isPositiveInteger,
          message: 'amountCents must be a positive integer in minor units (cents).',
        },
        type: {
          required: true,
          validator: (val) =>
            ['income', 'expense', 'savingsDeposit', 'savingsWithdrawal'].includes(val),
          message:
            'Type must be one of: income, expense, savingsDeposit, savingsWithdrawal.',
        },
        category: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Category is required.',
        },
        date: {
          required: true,
          validator: validator.isIsoDate,
          message: 'A valid ISO date string is required.',
        },
      }
    );

    const created = await transactionRepository.createTransaction(req.user.id, {
      id,
      amountCents,
      type,
      currency: currency || req.user.currency || 'ETB',
      category,
      description: description || '',
      date: new Date(date),
      paymentMethod: paymentMethod || 'Cash',
      account: account || 'Cash Wallet',
      notes: notes || '',
      receiptPath: receiptPath || null,
      syncStatus: syncStatus || 'synced',
      idempotencyKey: idempotencyKey || null,
      createdAt: createdAt ? new Date(createdAt) : null,
    });

    sendJson(res, 201, {
      message: 'Transaction recorded successfully.',
      transaction: created,
    });
  },

  /**
   * PATCH /api/v1/transactions/:id
   */
  async updateTransaction(req, res) {
    const { id } = req.params;
    const {
      amountCents,
      type,
      category,
      description,
      date,
      paymentMethod,
      account,
      notes,
    } = req.body;

    if (amountCents !== undefined && (!Number.isInteger(amountCents) || amountCents <= 0)) {
      return sendError(res, 400, 'amountCents must be a positive integer.');
    }

    if (type !== undefined && !['income', 'expense', 'savingsDeposit', 'savingsWithdrawal'].includes(type)) {
      return sendError(res, 400, 'Invalid transaction type.');
    }

    const updated = await transactionRepository.updateTransaction(req.user.id, id, {
      amountCents,
      type,
      category,
      description,
      date: date ? new Date(date) : undefined,
      paymentMethod,
      account,
      notes,
    });

    if (!updated) {
      return sendError(res, 404, 'Transaction not found or already deleted.');
    }

    sendJson(res, 200, {
      message: 'Transaction updated successfully.',
      transaction: updated,
    });
  },

  /**
   * DELETE /api/v1/transactions/:id
   */
  async deleteTransaction(req, res) {
    const { id } = req.params;
    const deleted = await transactionRepository.deleteTransaction(req.user.id, id);

    if (!deleted) {
      return sendError(res, 404, 'Transaction not found or already deleted.');
    }

    sendJson(res, 200, {
      message: 'Transaction deleted successfully (tombstone preserved for sync).',
      id: deleted.id,
      deletedAt: deleted.deleted_at,
    });
  },
};
