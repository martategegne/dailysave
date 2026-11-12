import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { communityRepository } from '../repositories/community.repository.js';

export const communityController = {
  /**
   * GET /api/v1/community/groups
   */
  async getGroups(req, res) {
    const groups = await communityRepository.getUserGroups(req.user.id);
    sendJson(res, 200, { groups });
  },

  /**
   * GET /api/v1/community/groups/:id
   */
  async getGroupById(req, res) {
    const { id } = req.params;
    const group = await communityRepository.getGroupById(req.user.id, id);

    if (!group) {
      return sendError(res, 404, 'Community group not found or you are not a member.');
    }

    sendJson(res, 200, { group });
  },

  /**
   * POST /api/v1/community/groups
   */
  async createGroup(req, res) {
    const { name, description, currency, targetAmountCents, contributionFrequency } = req.body;

    validateSchema(
      { name },
      {
        name: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Group name is required.',
        },
      }
    );

    const group = await communityRepository.createGroup(req.user.id, {
      name: name.trim(),
      description: description || '',
      currency: currency || req.user.currency || 'ETB',
      targetAmountCents: targetAmountCents ? parseInt(targetAmountCents, 10) : 0,
      contributionFrequency: contributionFrequency || 'monthly',
    });

    sendJson(res, 201, {
      message: 'Community savings group created successfully.',
      group,
    });
  },

  /**
   * POST /api/v1/community/groups/:id/invite
   */
  async inviteMember(req, res) {
    const { id } = req.params;
    const { targetEmail, role } = req.body;

    validateSchema(
      { targetEmail },
      {
        targetEmail: {
          required: true,
          validator: validator.isEmail,
          message: 'A valid email address is required to invite a member.',
        },
      }
    );

    const result = await communityRepository.inviteMember(req.user.id, id, {
      targetEmail,
      role: role || 'member',
    });

    if (result.error === 'forbidden') {
      return sendError(res, 403, 'Only the group creator or admin can invite members.');
    }

    if (result.error === 'user_not_found') {
      return sendError(res, 404, `No DailySave user registered with email "${targetEmail}".`);
    }

    if (result.error === 'already_member') {
      return sendError(res, 409, 'User is already a member of this community group.');
    }

    sendJson(res, 200, {
      message: `User ${targetEmail} added to the group successfully.`,
      member: result.member,
    });
  },

  /**
   * POST /api/v1/community/groups/:id/contributions
   */
  async addContribution(req, res) {
    const { id } = req.params;
    const { amountCents, notes, date } = req.body;

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

    const result = await communityRepository.addContribution(req.user.id, id, {
      amountCents,
      notes: notes || '',
      date: date ? new Date(date) : new Date(),
    });

    if (result.error === 'not_a_member') {
      return sendError(res, 403, 'You are not a member of this community group.');
    }

    sendJson(res, 201, {
      message: 'Contribution recorded into community savings pool.',
      contribution: result.contribution,
    });
  },

  /**
   * POST /api/v1/community/groups/:id/expenses
   */
  async addExpense(req, res) {
    const { id } = req.params;
    const { amountCents, category, description, date } = req.body;

    validateSchema(
      { amountCents, category },
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
      }
    );

    const result = await communityRepository.addExpense(req.user.id, id, {
      amountCents,
      category: category.trim(),
      description: description || '',
      date: date ? new Date(date) : new Date(),
    });

    if (result.error === 'forbidden') {
      return sendError(res, 403, 'Only creators, admins, or treasurers can record group expenses.');
    }

    sendJson(res, 201, {
      message: 'Group expense recorded successfully.',
      expense: result.expense,
    });
  },

  /**
   * GET /api/v1/community/groups/:id/report
   */
  async getGroupReport(req, res) {
    const { id } = req.params;
    const group = await communityRepository.getGroupById(req.user.id, id);

    if (!group) {
      return sendError(res, 404, 'Community group not found or you are not a member.');
    }

    sendJson(res, 200, {
      report: {
        groupId: group.id,
        groupName: group.name,
        currency: group.currency,
        targetAmountCents: group.targetAmountCents,
        totalContributionsCents: group.totalContributionsCents,
        totalExpensesCents: group.totalExpensesCents,
        netPoolCents: group.netPoolCents,
        memberCount: group.members.length,
        contributionsCount: group.contributions.length,
        expensesCount: group.expenses.length,
      },
    });
  },
};
