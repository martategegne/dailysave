import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { accountRepository } from '../repositories/account.repository.js';

export const accountController = {
  /**
   * GET /api/v1/accounts
   */
  async getAccounts(req, res) {
    const includeArchived = req.query.includeArchived === 'true';
    const accounts = await accountRepository.getAccounts(req.user.id, { includeArchived });
    sendJson(res, 200, { accounts });
  },

  /**
   * POST /api/v1/accounts
   */
  async createAccount(req, res) {
    const { name, accountType, currency, initialBalanceCents } = req.body;

    validateSchema(
      { name, accountType },
      {
        name: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Account name is required.',
        },
        accountType: {
          required: true,
          validator: (val) =>
            ['cash', 'bank', 'mobile_money', 'savings', 'custom'].includes(val),
          message:
            'accountType must be one of: cash, bank, mobile_money, savings, custom.',
        },
      }
    );

    try {
      const account = await accountRepository.createAccount(req.user.id, {
        name: name.trim(),
        accountType,
        currency: currency || req.user.currency || 'ETB',
        initialBalanceCents: initialBalanceCents ? parseInt(initialBalanceCents, 10) : 0,
      });

      sendJson(res, 201, {
        message: 'Account created successfully.',
        account,
      });
    } catch (err) {
      if (err.code === '23505') {
        // Unique violation uq_user_account_name
        return sendError(res, 409, `An account named "${name}" already exists.`);
      }
      throw err;
    }
  },

  /**
   * PATCH /api/v1/accounts/:id
   */
  async updateAccount(req, res) {
    const { id } = req.params;
    const { name, accountType, isArchived } = req.body;

    const account = await accountRepository.updateAccount(req.user.id, id, {
      name: name ? name.trim() : undefined,
      accountType,
      isArchived: isArchived !== undefined ? Boolean(isArchived) : undefined,
    });

    if (!account) {
      return sendError(res, 404, 'Account not found.');
    }

    sendJson(res, 200, {
      message: 'Account updated successfully.',
      account,
    });
  },

  /**
   * DELETE /api/v1/accounts/:id
   */
  async deleteAccount(req, res) {
    const { id } = req.params;
    const deleted = await accountRepository.deleteAccount(req.user.id, id);

    if (!deleted) {
      return sendError(res, 404, 'Account not found.');
    }

    sendJson(res, 200, {
      message: 'Account deleted successfully.',
      id: deleted.id,
      name: deleted.name,
    });
  },
};
