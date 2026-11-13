import { subscriptionService } from '../services/subscription.service.js';
import { sendJson, sendError } from '../core/response.js';

export const subscriptionController = {
  /**
   * GET /api/v1/subscriptions/current
   */
  async getCurrent(req, res) {
    const userId = req.user.id;
    const workspaceId = req.headers['x-workspace-id'] || req.query?.workspaceId || null;

    const sub = await subscriptionService.getSubscription(userId, workspaceId);
    return sendJson(res, 200, sub);
  },

  /**
   * GET /api/v1/subscriptions/plans
   */
  async listPlans(req, res) {
    const plans = subscriptionService.listPlans();
    return sendJson(res, 200, { plans });
  },

  /**
   * POST /api/v1/subscriptions/change-plan
   */
  async changePlan(req, res) {
    const userId = req.user.id;
    const { workspaceId, plan, billingCycle = 'monthly' } = req.body || {};

    if (!workspaceId) {
      return sendError(res, 400, 'Target workspaceId is required.');
    }

    if (!plan) {
      return sendError(res, 400, 'Target plan is required.');
    }

    try {
      const result = await subscriptionService.changePlan({
        userId,
        workspaceId,
        newPlan: plan,
        billingCycle,
      });

      return sendJson(res, 200, {
        message: `Subscription successfully updated to ${plan}.`,
        subscription: result.subscription,
        invoice: result.invoice,
      });
    } catch (err) {
      return sendError(res, 400, err.message);
    }
  },

  /**
   * POST /api/v1/subscriptions/cancel
   */
  async cancel(req, res) {
    const userId = req.user.id;
    const { workspaceId } = req.body || {};

    if (!workspaceId) {
      return sendError(res, 400, 'Target workspaceId is required.');
    }

    try {
      const sub = await subscriptionService.cancelSubscription({ userId, workspaceId });
      return sendJson(res, 200, {
        message: 'Subscription will be canceled at the end of the billing period.',
        subscription: sub,
      });
    } catch (err) {
      return sendError(res, 400, err.message);
    }
  },

  /**
   * GET /api/v1/subscriptions/invoices
   */
  async listInvoices(req, res) {
    const userId = req.user.id;
    const invoices = await subscriptionService.listInvoices(userId);
    return sendJson(res, 200, invoices);
  },
};
