import { query } from '../config/database.js';
import { sendJson, sendError } from '../core/response.js';
import { PLAN_CONFIG } from '../core/entitlements.js';
import { auditService } from '../services/audit.service.js';

export const businessDashboardController = {
  /**
   * GET /api/v1/business/analytics
   * Internal aggregated business intelligence metrics for platform administrators.
   * Uses strictly privacy-conscious aggregate sums; never exposes private transaction logs.
   */
  async getMetrics(req, res) {
    const user = req.user;

    // Security Guardrail: Only users with verified platform_admin role can access business analytics
    const adminCheckRes = await query(
      `SELECT platform_role FROM users WHERE id = $1;`,
      [user.id]
    );

    const platformRole = adminCheckRes.rows[0]?.platform_role;
    if (platformRole !== 'platform_admin') {
      return sendError(
        res,
        403,
        'Forbidden: Internal business metrics require platform administrator privileges.'
      );
    }

    // 1. User Population Totals
    const userStatsRes = await query(`
      SELECT 
        COUNT(*)::int AS total_registered,
        COUNT(CASE WHEN is_active = TRUE THEN 1 END)::int AS active_users,
        COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END)::int AS new_users_30d
      FROM users;
    `);

    // 2. Subscription Stats & Plan Distribution
    const subStatsRes = await query(`
      SELECT 
        plan,
        COUNT(*)::int AS subscriber_count,
        COUNT(CASE WHEN status = 'active' THEN 1 END)::int AS active_count,
        COUNT(CASE WHEN status = 'canceled' OR status = 'expired' THEN 1 END)::int AS churned_count
      FROM subscriptions
      GROUP BY plan;
    `);

    const totalUsers = userStatsRes.rows[0].total_registered || 1;
    const activeUsers = userStatsRes.rows[0].active_users || 0;
    const newUsers30d = userStatsRes.rows[0].new_users_30d || 0;

    let totalPaidSubscriptions = 0;
    let totalChurned = 0;
    let monthlyRecurringRevenueCents = 0;
    const planBreakdown = {};

    for (const row of subStatsRes.rows) {
      const planCode = row.plan;
      const count = row.subscriber_count;
      const activeCount = row.active_count;
      const churnedCount = row.churned_count;

      totalChurned += churnedCount;

      if (planCode !== 'FREE') {
        totalPaidSubscriptions += activeCount;
        const config = PLAN_CONFIG[planCode];
        if (config) {
          monthlyRecurringRevenueCents += config.monthlyPriceCents * activeCount;
        }
      }

      planBreakdown[planCode] = {
        total: count,
        active: activeCount,
        churned: churnedCount,
      };
    }

    const conversionRatePercent = Number(((totalPaidSubscriptions / totalUsers) * 100).toFixed(2));
    const retentionRatePercent =
      totalPaidSubscriptions + totalChurned > 0
        ? Number(((totalPaidSubscriptions / (totalPaidSubscriptions + totalChurned)) * 100).toFixed(2))
        : 100.0;

    await auditService.log({
      userId: user.id,
      action: 'PLATFORM_ANALYTICS_VIEWED',
      entityType: 'platform_analytics',
      ipAddress: req.socket?.remoteAddress,
    });

    return sendJson(res, 200, {
      timestamp: new Date().toISOString(),
      userMetrics: {
        totalRegistered: totalUsers,
        activeUsers,
        newUsersLast30Days: newUsers30d,
      },
      revenueMetrics: {
        totalPaidSubscriptions,
        monthlyRecurringRevenueCents,
        monthlyRecurringRevenueETB: monthlyRecurringRevenueCents / 100,
        annualRecurringRevenueCents: monthlyRecurringRevenueCents * 12,
        annualRecurringRevenueETB: (monthlyRecurringRevenueCents * 12) / 100,
        currency: 'ETB',
      },
      conversionMetrics: {
        conversionRatePercent,
        retentionRatePercent,
        totalChurned,
      },
      planDistribution: planBreakdown,
      monetizationTiers: [
        'Individual Subscriptions (Plus)',
        'Family Subscriptions',
        'Small Business & Merchant Plans',
        'Community Equb Organizer Licenses',
        'Institutional & Educational Partnerships',
        'White-Label Licensing (Microfinance / Credit Unions)',
      ],
    });
  },
};
