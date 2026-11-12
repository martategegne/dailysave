import { query } from '../config/database.js';

export const aiAssistantService = {
  /**
   * Checks whether the user has explicitly consented to AI analysis.
   */
  async getConsentStatus(userId) {
    const res = await query(
      `SELECT ai_consent_enabled FROM user_preferences WHERE user_id = $1;`,
      [userId]
    );
    return res.rows[0]?.ai_consent_enabled === true;
  },

  /**
   * Sets user AI consent state.
   */
  async setConsentStatus(userId, isConsentGiven) {
    const res = await query(
      `
      UPDATE user_preferences
      SET ai_consent_enabled = $1, updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $2
      RETURNING ai_consent_enabled;
      `,
      [Boolean(isConsentGiven), userId]
    );
    return res.rows[0]?.ai_consent_enabled === true;
  },

  /**
   * Generates grounded financial insights and anomaly detection.
   * Grounded strictly in authoritative database records; never invents data.
   */
  async generateInsights(userId) {
    const hasConsent = await this.getConsentStatus(userId);
    if (!hasConsent) {
      return {
        consentRequired: true,
        message: 'Explicit user consent is required before enabling AI spending insights.',
      };
    }

    // 1. Fetch current month vs previous month spending breakdown
    const now = new Date();
    const currentMonthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const prevMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const prevMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);

    const [currentTotalsRes, prevTotalsRes, categoryRes] = await Promise.all([
      query(
        `SELECT 
           COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0)::bigint AS income,
           COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0)::bigint AS expense
         FROM transactions 
         WHERE user_id = $1 AND deleted_at IS NULL AND date >= $2;`,
        [userId, currentMonthStart]
      ),
      query(
        `SELECT 
           COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0)::bigint AS expense
         FROM transactions 
         WHERE user_id = $1 AND deleted_at IS NULL AND date >= $2 AND date <= $3;`,
        [userId, prevMonthStart, prevMonthEnd]
      ),
      query(
        `SELECT category, SUM(amount_cents)::bigint AS amount_cents
         FROM transactions 
         WHERE user_id = $1 AND type = 'expense' AND deleted_at IS NULL AND date >= $2
         GROUP BY category
         ORDER BY amount_cents DESC;`,
        [userId, currentMonthStart]
      ),
    ]);

    const income = Number(currentTotalsRes.rows[0].income);
    const expense = Number(currentTotalsRes.rows[0].expense);
    const prevExpense = Number(prevTotalsRes.rows[0].expense);
    const netSavings = income - expense;
    const savingsRate = income > 0 ? Number(((netSavings / income) * 100).toFixed(1)) : 0;

    const insights = [];

    // Trend 1: Overall savings rate evaluation
    if (income > 0) {
      if (savingsRate >= 20) {
        insights.push({
          type: 'positive',
          title: 'Strong Savings Habit',
          message: `You are currently saving ${savingsRate}% of your income this month. Keep it up!`,
        });
      } else if (savingsRate > 0) {
        insights.push({
          type: 'suggestion',
          title: 'Opportunity to Grow Savings',
          message: `Your savings rate is ${savingsRate}%. Aiming for 20% would build your financial cushion faster.`,
        });
      } else {
        insights.push({
          type: 'warning',
          title: 'Deficit Alert',
          message: `Your monthly expenses exceed your income by ${Math.abs(netSavings / 100)} ETB. Review non-essential spending.`,
        });
      }
    }

    // Trend 2: Month-over-month comparison
    if (prevExpense > 0) {
      const diffPercent = Math.round(((expense - prevExpense) / prevExpense) * 100);
      if (diffPercent > 15) {
        insights.push({
          type: 'warning',
          title: 'Increased Spending',
          message: `Total spending is ${diffPercent}% higher compared to last month at this time.`,
        });
      }
    }

    // Trend 3: Top spending category
    if (categoryRes.rows.length > 0) {
      const top = categoryRes.rows[0];
      const topAmount = Number(top.amount_cents);
      const topPercent = expense > 0 ? Math.round((topAmount / expense) * 100) : 0;
      insights.push({
        type: 'info',
        title: `Top Category: ${top.category}`,
        message: `${top.category} represents ${topPercent}% (${topAmount / 100} ETB) of your total expenses this month.`,
      });
    }

    return {
      consentRequired: false,
      insights,
      metrics: {
        incomeCents: income,
        expenseCents: expense,
        netSavingsCents: netSavings,
        savingsRate,
      },
      disclaimer: 'AI-generated recommendations are informational suggestions and do not replace professional financial advice.',
    };
  },
};
