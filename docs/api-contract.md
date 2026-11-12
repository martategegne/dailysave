# DailySave REST API Contract

All API endpoints are prefixed with `/api/v1` and communicate via JSON payloads formatted with standard response envelopes.

---

## 1. Response Envelopes

### Successful Response (2xx)
```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2026-11-13T00:00:00.000Z"
}
```

### Error Response (4xx / 5xx)
```json
{
  "success": false,
  "error": {
    "code": 400,
    "message": "Human-readable error explanation",
    "details": null
  },
  "timestamp": "2026-11-13T00:00:00.000Z"
}
```

---

## 2. API Endpoints

### Authentication
- `POST /api/v1/auth/register`: Create user account and profile.
- `POST /api/v1/auth/login`: Authenticate and receive access + refresh tokens.
- `POST /api/v1/auth/refresh`: Rotate refresh token and get fresh access token.
- `POST /api/v1/auth/logout`: Revoke active refresh token.
- `GET /api/v1/auth/me`: Retrieve active user profile and preferences.
- `GET /api/v1/auth/export`: Export all user data in JSON format (GDPR compliant).
- `DELETE /api/v1/auth/me`: Permanently delete account and all associated records.

### Transactions
- `GET /api/v1/transactions`: Filter by `type`, `category`, `startDate`, `endDate`, `search`, with pagination (`limit`, `offset`).
- `POST /api/v1/transactions`: Record new income, expense, or savings transfer.
- `GET /api/v1/transactions/:id`: Retrieve single transaction details.
- `PATCH /api/v1/transactions/:id`: Update existing transaction.
- `DELETE /api/v1/transactions/:id`: Soft delete with tombstone.

### Dashboard & Analytics
- `GET /api/v1/dashboard/summary`: Lifetime income, expenses, net savings, reserve, and savings rate.
- `GET /api/v1/dashboard/daily`: Date-bound daily income, expenses, and savings.
- `GET /api/v1/dashboard/monthly`: Monthly totals + category spending breakdown.

### Savings & Reserves
- `GET /api/v1/savings/summary`: Calculated net savings vs actual savings reserve growth.
- `GET /api/v1/savings/history`: History of savings deposits and withdrawals.
- `POST /api/v1/savings/deposit`: Deposit money into savings reserve.
- `POST /api/v1/savings/withdraw`: Withdraw money from savings reserve.

### Budgets
- `GET /api/v1/budgets`: Budgets with spent amount and threshold status (`normal`, `warning`, `danger`, `critical`).
- `POST /api/v1/budgets`: Create budget with custom warning thresholds.
- `GET /api/v1/budgets/:id`: Get budget by ID.
- `PATCH /api/v1/budgets/:id`: Update budget parameters.
- `DELETE /api/v1/budgets/:id`: Remove budget.

### Goals & Contributions
- `GET /api/v1/goals`: Goals with progress percentage and remaining amounts.
- `POST /api/v1/goals`: Create financial goal.
- `GET /api/v1/goals/:id`: Goal with full contribution history.
- `POST /api/v1/goals/:id/contribute`: Record goal contribution atomically.
- `PATCH /api/v1/goals/:id`: Update goal target or deadline.
- `DELETE /api/v1/goals/:id`: Remove goal.

### Debts & Repayments
- `GET /api/v1/debts`: List borrowed and lent debts.
- `POST /api/v1/debts`: Create debt record.
- `GET /api/v1/debts/:id`: Debt details with payment ledger.
- `POST /api/v1/debts/:id/payments`: Record isolated loan repayment.

### Recurring Transactions
- `GET /api/v1/recurring-transactions`: Schedules with next execution date.
- `POST /api/v1/recurring-transactions`: Create recurring bill or income rule.
- `POST /api/v1/recurring-transactions/:id/generate`: Generate concrete transaction with duplicate prevention.
- `PATCH /api/v1/recurring-transactions/:id`: Update rule.
- `DELETE /api/v1/recurring-transactions/:id`: Remove rule.

### Community Savings Groups
- `GET /api/v1/community/groups`: User's groups with pooled balances.
- `POST /api/v1/community/groups`: Create new Equb / savings circle.
- `GET /api/v1/community/groups/:id`: View members, collective contributions, and expenses.
- `POST /api/v1/community/groups/:id/invite`: Invite registered user by email.
- `POST /api/v1/community/groups/:id/contributions`: Contribute to group pool.
- `POST /api/v1/community/groups/:id/expenses`: Record group operational expenditure.
- `GET /api/v1/community/groups/:id/report`: Aggregated group financial report.

### Notifications
- `GET /api/v1/notifications`: In-app notifications with unread count.
- `POST /api/v1/notifications`: Create notification / reminder.
- `PATCH /api/v1/notifications/:id/read`: Mark notification as read.
- `POST /api/v1/notifications/mark-all-read`: Mark all notifications as read.
- `DELETE /api/v1/notifications/:id`: Delete notification.

### AI Financial Assistant (Privacy-Gated)
- `GET /api/v1/ai/consent`: Read current consent status.
- `POST /api/v1/ai/consent`: Explicit opt-in toggle (`{"consent": true}`).
- `GET /api/v1/ai/insights`: Grounded pattern analysis and category trends.

### Offline-Cloud Synchronization
- `POST /api/v1/sync/push`: Batch push mutations with idempotency keys.
- `GET /api/v1/sync/pull?since=ISO_TIMESTAMP`: Delta synchronization of records updated after timestamp.
