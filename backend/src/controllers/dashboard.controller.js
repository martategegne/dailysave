import { sendJson, sendError } from '../core/response.js';
import { transactionRepository } from '../repositories/transaction.repository.js';

export const dashboardController = {
  /**
   * GET /api/v1/dashboard/summary
   * Returns lifetime income, expense, net savings, reserve, and savings rate.
   */
  async getSummary(req, res) {
    const summary = await transactionRepository.getSummary(req.user.id);
    sendJson(res, 200, {
      summary,
    });
  },

  /**
   * GET /api/v1/dashboard/daily?date=YYYY-MM-DD
   * Defaults to today's date if not provided.
   */
  async getDaily(req, res) {
    const targetDate = req.query.date ? new Date(req.query.date) : new Date();

    if (isNaN(targetDate.getTime())) {
      return sendError(res, 400, 'Invalid date query format. Expected YYYY-MM-DD.');
    }

    const dailySummary = await transactionRepository.getDailySummary(
      req.user.id,
      targetDate
    );

    sendJson(res, 200, {
      dailySummary,
    });
  },

  /**
   * GET /api/v1/dashboard/monthly?year=YYYY&month=MM
   * Defaults to current calendar year and month.
   */
  async getMonthly(req, res) {
    const now = new Date();
    const year = req.query.year ? parseInt(req.query.year, 10) : now.getFullYear();
    const month = req.query.month ? parseInt(req.query.month, 10) : now.getMonth() + 1;

    if (isNaN(year) || isNaN(month) || month < 1 || month > 12) {
      return sendError(res, 400, 'Invalid year or month query parameter.');
    }

    const monthlySummary = await transactionRepository.getMonthlySummary(
      req.user.id,
      year,
      month
    );

    sendJson(res, 200, {
      monthlySummary,
    });
  },
};
