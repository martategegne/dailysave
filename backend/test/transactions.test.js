import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer, buildRouter, stopServer } from '../src/server.js';
import { pool } from '../src/config/database.js';

describe('DailySave Transactions & Money Calculation Suite', () => {
  let server;
  let baseUrl;
  const user1Email = `user1_${Date.now()}@dailysave.org`;
  const user2Email = `user2_${Date.now()}@dailysave.org`;
  let user1Token = '';
  let user2Token = '';
  let user1TxId = '';

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

    // Register User 1
    const res1 = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: user1Email,
        password: 'Password123!',
        fullName: 'User One',
      }),
    });
    const d1 = await res1.json();
    user1Token = d1.data.tokens.accessToken;

    // Register User 2
    const res2 = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: user2Email,
        password: 'Password123!',
        fullName: 'User Two',
      }),
    });
    const d2 = await res2.json();
    user2Token = d2.data.tokens.accessToken;
  });

  after(async () => {
    await pool.query('DELETE FROM users WHERE email IN ($1, $2);', [user1Email, user2Email]);
    await stopServer(server);
  });

  it('1. Create Income of 1,000 ETB (100,000 minor cents) for User 1', async () => {
    const res = await fetch(`${baseUrl}/api/v1/transactions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user1Token}`,
      },
      body: JSON.stringify({
        amountCents: 100000,
        type: 'income',
        category: 'Salary',
        description: 'Monthly Salary',
        date: new Date().toISOString(),
        paymentMethod: 'Bank Transfer',
        account: 'Cash Wallet',
        idempotencyKey: 'idem-salary-user1',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.transaction.amount_cents, '100000');
    user1TxId = body.data.transaction.id;
  });

  it('2. Create Expense of 400 ETB (40,000 minor cents) for User 1', async () => {
    const res = await fetch(`${baseUrl}/api/v1/transactions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${user1Token}`,
      },
      body: JSON.stringify({
        amountCents: 40000,
        type: 'expense',
        category: 'Food',
        description: 'Groceries',
        date: new Date().toISOString(),
        paymentMethod: 'Cash',
        account: 'Cash Wallet',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.transaction.amount_cents, '40000');
  });

  it('3. GET /api/v1/dashboard/summary should compute exact net savings (600 ETB = 60,000 cents)', async () => {
    const res = await fetch(`${baseUrl}/api/v1/dashboard/summary`, {
      headers: { Authorization: `Bearer ${user1Token}` },
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.summary.totalIncomeCents, 100000);
    assert.equal(body.data.summary.totalExpenseCents, 40000);
    assert.equal(body.data.summary.accumulatedNetSavingsCents, 60000); // 1,000 - 400 = 600 ETB
    assert.equal(body.data.summary.savingsRate, 60.0);
  });

  it('4. Data Isolation: User 2 should NOT see User 1 transactions', async () => {
    const res = await fetch(`${baseUrl}/api/v1/transactions`, {
      headers: { Authorization: `Bearer ${user2Token}` },
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.transactions.length, 0);

    // User 2 cannot access User 1 transaction by ID
    const getRes = await fetch(`${baseUrl}/api/v1/transactions/${user1TxId}`, {
      headers: { Authorization: `Bearer ${user2Token}` },
    });
    assert.equal(getRes.status, 404);
  });

  it('5. Soft deletion produces tombstone and updates summaries', async () => {
    const deleteRes = await fetch(`${baseUrl}/api/v1/transactions/${user1TxId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${user1Token}` },
    });

    const delData = await deleteRes.json();
    assert.equal(deleteRes.status, 200);
    assert.ok(delData.data.deletedAt);

    // After deleting income, net savings should now be negative expense (-40,000 cents)
    const summaryRes = await fetch(`${baseUrl}/api/v1/dashboard/summary`, {
      headers: { Authorization: `Bearer ${user1Token}` },
    });
    const summaryBody = await summaryRes.json();
    assert.equal(summaryBody.data.summary.totalIncomeCents, 0);
    assert.equal(summaryBody.data.summary.totalExpenseCents, 40000);
    assert.equal(summaryBody.data.summary.accumulatedNetSavingsCents, -40000);
  });
});
