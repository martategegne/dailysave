/**
 * DailySave Subscription Plans & Feature Entitlements Matrix
 * Configurable product tiers; integer pricing in Ethiopian Birr cents (ETB).
 */

export const PLANS = {
  FREE: 'FREE',
  PLUS: 'PLUS',
  FAMILY: 'FAMILY',
  BUSINESS: 'BUSINESS',
  COMMUNITY: 'COMMUNITY',
};

export const ENTITLEMENTS = {
  OFFLINE_TRACKING: 'offline_tracking',
  BASIC_BUDGETS: 'basic_budgets',
  BASIC_REPORTS: 'basic_reports',
  ADVANCED_ANALYTICS: 'advanced_analytics',
  ADVANCED_REPORTS: 'advanced_reports',
  UNLIMITED_GOALS: 'unlimited_goals',
  ENHANCED_SYNC: 'enhanced_sync',
  AI_INSIGHTS: 'ai_insights',
  SHARED_FAMILY_BUDGETS: 'shared_family_budgets',
  FAMILY_PERMISSION_MANAGEMENT: 'family_permission_management',
  MULTIPLE_BUSINESS_ACCOUNTS: 'multiple_business_accounts',
  STAFF_PERMISSIONS: 'staff_permissions',
  ACCOUNTANT_ACCESS: 'accountant_access',
  BUSINESS_CASHFLOW: 'business_cashflow',
  GROUP_SAVINGS: 'group_savings',
  CONTRIBUTION_SCHEDULES: 'contribution_schedules',
  TREASURER_MANAGEMENT: 'treasurer_management',
};

export const PLAN_CONFIG = {
  [PLANS.FREE]: {
    name: 'Individual Free',
    monthlyPriceCents: 0,
    annualPriceCents: 0,
    entitlements: [
      ENTITLEMENTS.OFFLINE_TRACKING,
      ENTITLEMENTS.BASIC_BUDGETS,
      ENTITLEMENTS.BASIC_REPORTS,
    ],
  },
  [PLANS.PLUS]: {
    name: 'DailySave Plus',
    monthlyPriceCents: 15000, // 150.00 ETB / month
    annualPriceCents: 150000, // 1,500.00 ETB / year (2 months free)
    entitlements: [
      ENTITLEMENTS.OFFLINE_TRACKING,
      ENTITLEMENTS.BASIC_BUDGETS,
      ENTITLEMENTS.BASIC_REPORTS,
      ENTITLEMENTS.ADVANCED_ANALYTICS,
      ENTITLEMENTS.ADVANCED_REPORTS,
      ENTITLEMENTS.UNLIMITED_GOALS,
      ENTITLEMENTS.ENHANCED_SYNC,
      ENTITLEMENTS.AI_INSIGHTS,
    ],
  },
  [PLANS.FAMILY]: {
    name: 'Family Financial Circle',
    monthlyPriceCents: 25000, // 250.00 ETB / month
    annualPriceCents: 250000, // 2,500.00 ETB / year
    entitlements: [
      ENTITLEMENTS.OFFLINE_TRACKING,
      ENTITLEMENTS.BASIC_BUDGETS,
      ENTITLEMENTS.BASIC_REPORTS,
      ENTITLEMENTS.ADVANCED_ANALYTICS,
      ENTITLEMENTS.SHARED_FAMILY_BUDGETS,
      ENTITLEMENTS.FAMILY_PERMISSION_MANAGEMENT,
      ENTITLEMENTS.ENHANCED_SYNC,
    ],
  },
  [PLANS.BUSINESS]: {
    name: 'Small Business & Merchant',
    monthlyPriceCents: 50000, // 500.00 ETB / month
    annualPriceCents: 500000, // 5,000.00 ETB / year
    entitlements: [
      ENTITLEMENTS.OFFLINE_TRACKING,
      ENTITLEMENTS.BASIC_BUDGETS,
      ENTITLEMENTS.BASIC_REPORTS,
      ENTITLEMENTS.ADVANCED_ANALYTICS,
      ENTITLEMENTS.ADVANCED_REPORTS,
      ENTITLEMENTS.MULTIPLE_BUSINESS_ACCOUNTS,
      ENTITLEMENTS.STAFF_PERMISSIONS,
      ENTITLEMENTS.ACCOUNTANT_ACCESS,
      ENTITLEMENTS.BUSINESS_CASHFLOW,
      ENTITLEMENTS.ENHANCED_SYNC,
    ],
  },
  [PLANS.COMMUNITY]: {
    name: 'Community Equb Organizer',
    monthlyPriceCents: 35000, // 350.00 ETB / month
    annualPriceCents: 350000, // 3,500.00 ETB / year
    entitlements: [
      ENTITLEMENTS.OFFLINE_TRACKING,
      ENTITLEMENTS.BASIC_BUDGETS,
      ENTITLEMENTS.BASIC_REPORTS,
      ENTITLEMENTS.GROUP_SAVINGS,
      ENTITLEMENTS.CONTRIBUTION_SCHEDULES,
      ENTITLEMENTS.TREASURER_MANAGEMENT,
      ENTITLEMENTS.ENHANCED_SYNC,
    ],
  },
};

/**
 * Checks whether a given subscription allows a specific feature entitlement.
 * Handles active, trialing, and 7-day grace periods.
 */
export function isEntitled(subscription, requiredEntitlement) {
  if (!subscription) return false;

  // Active or Trialing has immediate access
  const isGoodStanding =
    subscription.status === 'active' ||
    subscription.status === 'trialing';

  // Check 7-day grace period for past_due
  const isGracePeriod =
    subscription.status === 'past_due' &&
    subscription.grace_period_end &&
    new Date(subscription.grace_period_end) > new Date();

  if (!isGoodStanding && !isGracePeriod) {
    // Expired or canceled past end of period -> fallback to FREE entitlements
    const freePlan = PLAN_CONFIG[PLANS.FREE];
    return freePlan.entitlements.includes(requiredEntitlement);
  }

  const planConfig = PLAN_CONFIG[subscription.plan] || PLAN_CONFIG[PLANS.FREE];
  return planConfig.entitlements.includes(requiredEntitlement);
}
