import http from 'node:http';
import { env } from './config/env.js';
import { closePool, testConnection } from './config/database.js';
import { Router } from './core/router.js';
import { sendJson } from './core/response.js';
import { handleCors } from './middlewares/cors.js';
import { rateLimiter } from './middlewares/rate-limiter.js';
import { authenticateToken } from './middlewares/auth.middleware.js';

import { authController } from './controllers/auth.controller.js';
import { transactionController } from './controllers/transaction.controller.js';
import { dashboardController } from './controllers/dashboard.controller.js';
import { savingsController } from './controllers/savings.controller.js';
import { accountController } from './controllers/account.controller.js';
import { budgetController } from './controllers/budget.controller.js';
import { goalController } from './controllers/goal.controller.js';
import { debtController } from './controllers/debt.controller.js';
import { syncController } from './controllers/sync.controller.js';
import { recurringController } from './controllers/recurring.controller.js';
import { communityController } from './controllers/community.controller.js';
import { notificationController } from './controllers/notification.controller.js';

/**
 * Creates and registers all application routes on the native Router.
 */
export function buildRouter() {
  const router = new Router();
  const prefix = env.server.apiPrefix; // e.g. '/api/v1'

  // Healthcheck & diagnostics
  router.get('/health', (req, res) => {
    sendJson(res, 200, {
      status: 'ok',
      service: 'dailysave-backend',
      version: '1.0.0',
      uptimeSeconds: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
    });
  });

  // --- Authentication Routes (Public) ---
  router.post(`${prefix}/auth/register`, authController.register);
  router.post(`${prefix}/auth/login`, authController.login);
  router.post(`${prefix}/auth/refresh`, authController.refresh);

  // --- Authentication Routes (Protected) ---
  router.post(`${prefix}/auth/logout`, authenticateToken, authController.logout);
  router.get(`${prefix}/auth/me`, authenticateToken, authController.getMe);
  router.get(`${prefix}/auth/export`, authenticateToken, authController.exportData);
  router.delete(`${prefix}/auth/me`, authenticateToken, authController.deleteAccount);

  // --- Transactions Routes ---
  router.get(`${prefix}/transactions`, authenticateToken, transactionController.getTransactions);
  router.post(`${prefix}/transactions`, authenticateToken, transactionController.createTransaction);
  router.get(`${prefix}/transactions/:id`, authenticateToken, transactionController.getTransactionById);
  router.patch(`${prefix}/transactions/:id`, authenticateToken, transactionController.updateTransaction);
  router.delete(`${prefix}/transactions/:id`, authenticateToken, transactionController.deleteTransaction);

  // --- Dashboard Routes ---
  router.get(`${prefix}/dashboard/summary`, authenticateToken, dashboardController.getSummary);
  router.get(`${prefix}/dashboard/daily`, authenticateToken, dashboardController.getDaily);
  router.get(`${prefix}/dashboard/monthly`, authenticateToken, dashboardController.getMonthly);

  // --- Savings Management Routes ---
  router.get(`${prefix}/savings/summary`, authenticateToken, savingsController.getSummary);
  router.get(`${prefix}/savings/history`, authenticateToken, savingsController.getHistory);
  router.post(`${prefix}/savings/deposit`, authenticateToken, savingsController.deposit);
  router.post(`${prefix}/savings/withdraw`, authenticateToken, savingsController.withdraw);

  // --- Accounts Routes ---
  router.get(`${prefix}/accounts`, authenticateToken, accountController.getAccounts);
  router.post(`${prefix}/accounts`, authenticateToken, accountController.createAccount);
  router.patch(`${prefix}/accounts/:id`, authenticateToken, accountController.updateAccount);
  router.delete(`${prefix}/accounts/:id`, authenticateToken, accountController.deleteAccount);

  // --- Budgets Routes ---
  router.get(`${prefix}/budgets`, authenticateToken, budgetController.getBudgets);
  router.post(`${prefix}/budgets`, authenticateToken, budgetController.createBudget);
  router.get(`${prefix}/budgets/:id`, authenticateToken, budgetController.getBudgetById);
  router.patch(`${prefix}/budgets/:id`, authenticateToken, budgetController.updateBudget);
  router.delete(`${prefix}/budgets/:id`, authenticateToken, budgetController.deleteBudget);

  // --- Goals Routes ---
  router.get(`${prefix}/goals`, authenticateToken, goalController.getGoals);
  router.post(`${prefix}/goals`, authenticateToken, goalController.createGoal);
  router.get(`${prefix}/goals/:id`, authenticateToken, goalController.getGoalById);
  router.patch(`${prefix}/goals/:id`, authenticateToken, goalController.updateGoal);
  router.delete(`${prefix}/goals/:id`, authenticateToken, goalController.deleteGoal);
  router.post(`${prefix}/goals/:id/contribute`, authenticateToken, goalController.contribute);

  // --- Debts Routes ---
  router.get(`${prefix}/debts`, authenticateToken, debtController.getDebts);
  router.post(`${prefix}/debts`, authenticateToken, debtController.createDebt);
  router.get(`${prefix}/debts/:id`, authenticateToken, debtController.getDebtById);
  router.patch(`${prefix}/debts/:id`, authenticateToken, debtController.updateDebt);
  router.delete(`${prefix}/debts/:id`, authenticateToken, debtController.deleteDebt);
  router.post(`${prefix}/debts/:id/payments`, authenticateToken, debtController.recordPayment);

  // --- Recurring Transactions Routes ---
  router.get(`${prefix}/recurring-transactions`, authenticateToken, recurringController.getRecurring);
  router.post(`${prefix}/recurring-transactions`, authenticateToken, recurringController.createRecurring);
  router.get(`${prefix}/recurring-transactions/:id`, authenticateToken, recurringController.getRecurringById);
  router.patch(`${prefix}/recurring-transactions/:id`, authenticateToken, recurringController.updateRecurring);
  router.delete(`${prefix}/recurring-transactions/:id`, authenticateToken, recurringController.deleteRecurring);
  router.post(`${prefix}/recurring-transactions/:id/generate`, authenticateToken, recurringController.generateTransaction);

  // --- Community Savings Groups Routes (Equb / Circles) ---
  router.get(`${prefix}/community/groups`, authenticateToken, communityController.getGroups);
  router.post(`${prefix}/community/groups`, authenticateToken, communityController.createGroup);
  router.get(`${prefix}/community/groups/:id`, authenticateToken, communityController.getGroupById);
  router.post(`${prefix}/community/groups/:id/invite`, authenticateToken, communityController.inviteMember);
  router.post(`${prefix}/community/groups/:id/contributions`, authenticateToken, communityController.addContribution);
  router.post(`${prefix}/community/groups/:id/expenses`, authenticateToken, communityController.addExpense);
  router.get(`${prefix}/community/groups/:id/report`, authenticateToken, communityController.getGroupReport);

  // --- Notifications & Reminders Routes ---
  router.get(`${prefix}/notifications`, authenticateToken, notificationController.getNotifications);
  router.post(`${prefix}/notifications`, authenticateToken, notificationController.createNotification);
  router.patch(`${prefix}/notifications/:id/read`, authenticateToken, notificationController.markAsRead);
  router.post(`${prefix}/notifications/mark-all-read`, authenticateToken, notificationController.markAllAsRead);
  router.delete(`${prefix}/notifications/:id`, authenticateToken, notificationController.deleteNotification);

  // --- Offline Synchronization Routes ---
  router.post(`${prefix}/sync/push`, authenticateToken, syncController.push);
  router.get(`${prefix}/sync/pull`, authenticateToken, syncController.pull);

  return router;
}

/**
 * Creates the native Node.js HTTP server configured with CORS, Rate Limiting, and Routing.
 */
export function createServer(router = buildRouter()) {
  return http.createServer(async (req, res) => {
    // 1. Cross-Origin Resource Sharing (CORS)
    if (handleCors(req, res)) {
      return;
    }

    // 2. Sliding Window Rate Limiting
    if (rateLimiter.checkLimit(req, res)) {
      return;
    }

    // 3. Dispatch to Router
    await router.handle(req, res);
  });
}

/**
 * Main application entrypoint.
 */
export async function startServer(port = env.server.port) {
  // Test database connection before binding port
  await testConnection();

  const server = createServer();

  return new Promise((resolve) => {
    server.listen(port, () => {
      console.log(`\n========================================`);
      console.log(` DailySave Native Node.js Server Running`);
      console.log(`========================================`);
      console.log(` Port:        http://localhost:${port}`);
      console.log(` Environment: ${env.server.nodeEnv}`);
      console.log(` API Prefix:  ${env.server.apiPrefix}`);
      console.log(` Database:    ${env.database.database} on ${env.database.host}:${env.database.port}`);
      console.log(`========================================\n`);
      resolve(server);
    });
  });
}

// Graceful shutdown handling
export async function stopServer(server) {
  return new Promise((resolve) => {
    if (server) {
      server.close(async () => {
        await closePool();
        resolve();
      });
    } else {
      resolve();
    }
  });
}

// Auto-start when executed directly via `node src/server.js`
if (process.argv[1] && process.argv[1].endsWith('server.js')) {
  startServer().catch((err) => {
    console.error('[Server Startup Failure]:', err);
    process.exit(1);
  });

  const handleTermination = async (signal) => {
    console.log(`\n[${signal}] Initiating graceful shutdown...`);
    await closePool();
    process.exit(0);
  };

  process.on('SIGINT', () => handleTermination('SIGINT'));
  process.on('SIGTERM', () => handleTermination('SIGTERM'));
}
