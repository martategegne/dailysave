import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { debtRepository } from '../repositories/debt.repository.js';

export const debtController = {
  /**
   * GET /api/v1/debts
   */
  async getDebts(req, res) {
    const { debtType, isSettled } = req.query;
    const settledBool = isSettled !== undefined ? isSettled === 'true' : undefined;

    const debts = await debtRepository.getDebts(req.user.id, {
      debtType,
      isSettled: settledBool,
    });

    sendJson(res, 200, { debts });
  },

  /**
   * GET /api/v1/debts/:id
   */
  async getDebtById(req, res) {
    const { id } = req.params;
    const debt = await debtRepository.getDebtById(req.user.id, id);

    if (!debt) {
      return sendError(res, 404, 'Debt record not found.');
    }

    sendJson(res, 200, { debt });
  },

  /**
   * POST /api/v1/debts
   */
  async createDebt(req, res) {
    const { personName, debtType, initialAmountCents, dueDate, description, currency } = req.body;

    validateSchema(
      { personName, debtType, initialAmountCents },
      {
        personName: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'personName is required.',
        },
        debtType: {
          required: true,
          validator: (val) => ['borrowed', 'lent'].includes(val),
          message: 'debtType must be either "borrowed" or "lent".',
        },
        initialAmountCents: {
          required: true,
          validator: validator.isPositiveInteger,
          message: 'initialAmountCents must be a positive integer in minor units (cents).',
        },
      }
    );

    const debt = await debtRepository.createDebt(req.user.id, {
      personName: personName.trim(),
      debtType,
      initialAmountCents,
      dueDate: dueDate ? new Date(dueDate) : null,
      description: description || '',
      currency: currency || req.user.currency || 'ETB',
    });

    sendJson(res, 201, {
      message: 'Debt record created successfully.',
      debt,
    });
  },

  /**
   * PATCH /api/v1/debts/:id
   */
  async updateDebt(req, res) {
    const { id } = req.params;
    const { personName, dueDate, description, isSettled } = req.body;

    const debt = await debtRepository.updateDebt(req.user.id, id, {
      personName: personName ? personName.trim() : undefined,
      dueDate: dueDate ? new Date(dueDate) : undefined,
      description,
      isSettled: isSettled !== undefined ? Boolean(isSettled) : undefined,
    });

    if (!debt) {
      return sendError(res, 404, 'Debt record not found.');
    }

    sendJson(res, 200, {
      message: 'Debt record updated successfully.',
      debt,
    });
  },

  /**
   * DELETE /api/v1/debts/:id
   */
  async deleteDebt(req, res) {
    const { id } = req.params;
    const deleted = await debtRepository.deleteDebt(req.user.id, id);

    if (!deleted) {
      return sendError(res, 404, 'Debt record not found.');
    }

    sendJson(res, 200, {
      message: 'Debt record deleted successfully.',
      id: deleted.id,
      personName: deleted.person_name,
    });
  },

  /**
   * POST /api/v1/debts/:id/payments
   */
  async recordPayment(req, res) {
    const { id } = req.params;
    const { amountCents, paymentDate, paymentMethod, notes } = req.body;

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

    const result = await debtRepository.recordPayment(req.user.id, id, {
      amountCents,
      paymentDate: paymentDate ? new Date(paymentDate) : new Date(),
      paymentMethod: paymentMethod || 'Cash',
      notes: notes || '',
    });

    if (!result) {
      return sendError(res, 404, 'Debt record not found.');
    }

    sendJson(res, 200, {
      message: 'Debt payment recorded successfully.',
      payment: result.payment,
      remainingAmountCents: result.remainingAmountCents,
      isSettled: result.isSettled,
    });
  },
};
