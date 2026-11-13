import { query } from '../config/database.js';
import { PLANS, PLAN_CONFIG, isEntitled } from '../core/entitlements.js';
import { auditService } from './audit.service.js';

export const subscriptionService = {
  /**
   * Retrieves active subscription for user and workspace.
   */
  async getSubscription(userId, workspaceId) {
    const res = await query(
      `
      SELECT id, user_id, workspace_id, plan, status, billing_cycle,
             current_period_start, current_period_end, cancel_at_period_end,
             grace_period_end, created_at, updated_at
      FROM subscriptions
      WHERE user_id = $1 AND (workspace_id = $2 OR workspace_id IS NULL)
      ORDER BY updated_at DESC
      LIMIT 1;
      `,
      [userId, workspaceId]
    );

    if (res.rows.length === 0) {
      // Default to Free
      return {
        plan: PLANS.FREE,
        status: 'active',
        billing_cycle: 'monthly',
        entitlements: PLAN_CONFIG[PLANS.FREE].entitlements,
      };
    }

    const sub = res.rows[0];
    const planConfig = PLAN_CONFIG[sub.plan] || PLAN_CONFIG[PLANS.FREE];
    return {
      ...sub,
      planName: planConfig.name,
      entitlements: planConfig.entitlements,
    };
  },

  /**
   * Lists all available subscription plans with pricing.
   */
  listPlans() {
    return Object.entries(PLAN_CONFIG).map(([key, config]) => ({
      code: key,
      name: config.name,
      monthlyPriceETB: config.monthlyPriceCents / 100,
      annualPriceETB: config.annualPriceCents / 100,
      monthlyPriceCents: config.monthlyPriceCents,
      annualPriceCents: config.annualPriceCents,
      entitlements: config.entitlements,
    }));
  },

  /**
   * Upgrades or downgrades a workspace subscription.
   * Generates a simulated invoice record without charging real credentials.
   */
  async changePlan({ userId, workspaceId, newPlan, billingCycle = 'monthly' }) {
    if (!PLANS[newPlan]) {
      throw new Error(`Invalid plan '${newPlan}'. Allowed: ${Object.keys(PLANS).join(', ')}`);
    }

    const planConfig = PLAN_CONFIG[newPlan];
    const amountCents =
      billingCycle === 'annual' ? planConfig.annualPriceCents : planConfig.monthlyPriceCents;

    const periodDays = billingCycle === 'annual' ? 365 : 30;
    const periodEnd = new Date(Date.now() + periodDays * 24 * 60 * 60 * 1000);

    const subRes = await query(
      `
      INSERT INTO subscriptions (user_id, workspace_id, plan, status, billing_cycle, current_period_end, cancel_at_period_end, updated_at)
      VALUES ($1, $2, $3, 'active', $4, $5, FALSE, CURRENT_TIMESTAMP)
      ON CONFLICT (user_id, workspace_id)
      DO UPDATE SET plan = EXCLUDED.plan,
                    status = 'active',
                    billing_cycle = EXCLUDED.billing_cycle,
                    current_period_end = EXCLUDED.current_period_end,
                    cancel_at_period_end = FALSE,
                    updated_at = CURRENT_TIMESTAMP
      RETURNING *;
      `,
      [userId, workspaceId, newPlan, billingCycle, periodEnd]
    );

    const subscription = subRes.rows[0];

    // Generate an invoice record
    const invoiceRes = await query(
      `
      INSERT INTO billing_invoices (subscription_id, user_id, amount_cents, currency, status, payment_provider, provider_transaction_id, paid_at)
      VALUES ($1, $2, $3, 'ETB', 'paid', 'plan_change_eval', $4, CURRENT_TIMESTAMP)
      RETURNING *;
      `,
      [subscription.id, userId, amountCents, `tx_${Date.now()}`]
    );

    await auditService.log({
      userId,
      workspaceId,
      action: 'SUBSCRIPTION_PLAN_CHANGED',
      entityType: 'subscription',
      entityId: subscription.id,
      payload: { newPlan, billingCycle, amountCents },
    });

    return {
      subscription,
      invoice: invoiceRes.rows[0],
    };
  },

  /**
   * Cancels subscription at period end.
   */
  async cancelSubscription({ userId, workspaceId }) {
    const res = await query(
      `
      UPDATE subscriptions
      SET cancel_at_period_end = TRUE, updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $1 AND workspace_id = $2
      RETURNING *;
      `,
      [userId, workspaceId]
    );

    if (res.rows.length === 0) {
      throw new Error('No active subscription found to cancel.');
    }

    await auditService.log({
      userId,
      workspaceId,
      action: 'SUBSCRIPTION_CANCEL_SCHEDULED',
      entityType: 'subscription',
      entityId: res.rows[0].id,
    });

    return res.rows[0];
  },

  /**
   * Lists past billing invoices for user.
   */
  async listInvoices(userId) {
    const res = await query(
      `
      SELECT id, subscription_id, amount_cents, currency, status, payment_provider,
             provider_transaction_id, paid_at, created_at
      FROM billing_invoices
      WHERE user_id = $1
      ORDER BY created_at DESC;
      `,
      [userId]
    );
    return res.rows;
  },
};
