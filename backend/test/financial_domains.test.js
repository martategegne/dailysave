import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer, buildRouter, stopServer } from '../src/server.js';
import { pool } from '../src/config/database.js';

describe('DailySave Financial Domains (Accounts, Budgets, Goals, Debts)', () => {
  let server;
  let baseUrl;
  const testEmail = `domain_${Date.now()}@dailysave.org`;
  let token = '';
  let accountId = '';
  let budgetId = '';
  let goalId = '';
  let debtId = '';

  before(async () => {
    const router = buildRouter();
    server = createServer(router);
    await new Promise((resolve) => {
      server.listen(0, () => {
        const port = server.address().port;
        baseUrl = `http://127.0.0.1:${port}`;
        resolve();
      });
    });

    const res = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: 'Password123!',
        fullName: 'Domains Tester',
      }),
    });
    const d = await res.json();
    token = d.data.tokens.accessToken;
  });

  after(async () => {
    await pool.query('DELETE FROM users WHERE email = $1;', [testEmail]);
    await stopServer(server);
  });

  // --- ACCOUNTS ---
  it('1. Create CBE Bank Account with 500 ETB (50,000 cents) initial balance', async () => {
    const res = await fetch(`${baseUrl}/api/v1/accounts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        name: 'Commercial Bank of Ethiopia',
        accountType: 'bank',
        currency: 'ETB',
        initialBalanceCents: 50000,
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.account.name, 'Commercial Bank of Ethiopia');
    assert.equal(body.data.account.current_balance_cents, 50000);
    accountId = body.data.account.id;
  });

  it('2. List Accounts and verify computed balance', async () => {
    const res = await fetch(`${baseUrl}/api/v1/accounts`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    // User already gets "Cash Wallet" seeded on register, plus CBE account
    assert.ok(body.data.accounts.length >= 2);
  });

  // --- BUDGETS ---
  it('3. Create Monthly Food Budget of 3,000 ETB (300,000 cents)', async () => {
    const res = await fetch(`${baseUrl}/api/v1/budgets`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        name: 'Monthly Food & Groceries',
        amountCents: 300000,
        period: 'monthly',
        category: 'Food',
        startDate: new Date().toISOString(),
        warningThresholdPercent: 75,
        dangerThresholdPercent: 90,
        criticalThresholdPercent: 100,
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.budget.amountCents, 300000);
    assert.equal(body.data.budget.spentCents, 0);
    assert.equal(body.data.budget.status, 'normal');
    budgetId = body.data.budget.id;
  });

  // --- GOALS ---
  it('4. Create Goal "Buy Laptop" target 50,000 ETB (5,000,000 cents)', async () => {
    const res = await fetch(`${baseUrl}/api/v1/goals`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        name: 'Buy Laptop',
        targetAmountCents: 5000000,
        deadline: new Date(Date.now() + 90 * 86400000).toISOString(),
        description: 'M3 MacBook for software engineering',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.goal.targetAmountCents, 5000000);
    assert.equal(body.data.goal.currentAmountCents, 0);
    goalId = body.data.goal.id;
  });

  it('5. Contribute 10,000 ETB (1,000,000 cents) to Goal and verify atomic balance', async () => {
    const res = await fetch(`${baseUrl}/api/v1/goals/${goalId}/contribute`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        amountCents: 1000000,
        notes: 'Freelance project milestone bonus',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.newTotalCents, 1000000);
    assert.equal(body.data.isCompleted, false);

    // Verify GET /goals/:id includes contribution
    const getRes = await fetch(`${baseUrl}/api/v1/goals/${goalId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const getBody = await getRes.json();
    assert.equal(getBody.data.goal.currentAmountCents, 1000000);
    assert.equal(getBody.data.goal.progressPercent, 20.0);
    assert.equal(getBody.data.goal.contributions.length, 1);
  });

  // --- DEBTS ---
  it('6. Create Debt: Borrowed 2,000 ETB (200,000 cents) from Abebe', async () => {
    const res = await fetch(`${baseUrl}/api/v1/debts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        personName: 'Abebe Kebede',
        debtType: 'borrowed',
        initialAmountCents: 200000,
        dueDate: new Date(Date.now() + 30 * 86400000).toISOString(),
        description: 'Emergency car maintenance loan',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.debt.initial_amount_cents, 200000);
    assert.equal(body.data.debt.remaining_amount_cents, 200000);
    assert.equal(body.data.debt.is_settled, false);
    debtId = body.data.debt.id;
  });

  it('7. Repay 1,500 ETB (150,000 cents) towards debt and verify isolated payment', async () => {
    const res = await fetch(`${baseUrl}/api/v1/debts/${debtId}/payments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        amountCents: 150000,
        paymentMethod: 'Bank Transfer',
        notes: 'First installment repaid',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.remainingAmountCents, 50000); // 200,000 - 150,000 = 50,000
    assert.equal(body.data.isSettled, false);

    // Final settlement of remaining 500 ETB (50,000 cents)
    const settleRes = await fetch(`${baseUrl}/api/v1/debts/${debtId}/payments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        amountCents: 50000,
        notes: 'Final repayment installment',
      }),
    });
    const settleBody = await settleRes.json();
    assert.equal(settleBody.data.remainingAmountCents, 0);
    assert.equal(settleBody.data.isSettled, true);
  });
});
