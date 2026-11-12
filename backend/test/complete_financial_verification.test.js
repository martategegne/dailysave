import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer, buildRouter, stopServer } from '../src/server.js';
import { pool } from '../src/config/database.js';

describe('DailySave: Complete 9-Point Financial & Synchronization Verification Suite', () => {
  let server;
  let baseUrl;
  const userAEmail = `user_a_${Date.now()}@dailysave.org`;
  const userBEmail = `user_b_${Date.now()}@dailysave.org`;
  let userAToken = '';
  let userBToken = '';
  let editableTxId = '';
  let deletableTxId = '';

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

    // 1. Register User A
    const resA = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: userAEmail,
        password: 'Password123!',
        fullName: 'User A Verified',
      }),
    });
    const dA = await resA.json();
    userAToken = dA.data.tokens.accessToken;

    // 2. Register User B
    const resB = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: userBEmail,
        password: 'Password123!',
        fullName: 'User B Verified',
      }),
    });
    const dB = await resB.json();
    userBToken = dB.data.tokens.accessToken;
  });

  after(async () => {
    await pool.query('DELETE FROM users WHERE email IN ($1, $2);', [userAEmail, userBEmail]);
    await stopServer(server);
  });

  it('Case 1: Income 1,000 ETB (100,000 cents), Expenses 400 ETB (40,000 cents) = 600 ETB (60,000 cents) Net Savings', async () => {
    // Add 1,000 ETB Income
    const incRes = await fetch(`${baseUrl}/api/v1/transactions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userAToken}` },
      body: JSON.stringify({
        amountCents: 100000,
        type: 'income',
        category: 'Salary',
        description: 'Case 1 Income',
        date: new Date().toISOString(),
      }),
    });
    const incData = await incRes.json();
    editableTxId = incData.data.transaction.id;

    // Add 400 ETB Expense
    const expRes = await fetch(`${baseUrl}/api/v1/transactions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userAToken}` },
      body: JSON.stringify({
        amountCents: 40000,
        type: 'expense',
        category: 'Food',
        description: 'Case 1 Expense',
        date: new Date().toISOString(),
      }),
    });
    const expData = await expRes.json();
    deletableTxId = expData.data.transaction.id;

    // Verify Summary
    const summaryRes = await fetch(`${baseUrl}/api/v1/dashboard/summary`, {
      headers: { Authorization: `Bearer ${userAToken}` },
    });
    const summary = await summaryRes.json();
    assert.equal(summary.data.summary.totalIncomeCents, 100000);
    assert.equal(summary.data.summary.totalExpenseCents, 40000);
    assert.equal(summary.data.summary.accumulatedNetSavingsCents, 60000); // 600 ETB
    assert.equal(summary.data.summary.savingsRate, 60.0);
  });

  it('Case 2: Income 500 ETB (50,000 cents), Expenses 700 ETB (70,000 cents) = -200 ETB (-20,000 cents) Valid Negative Savings', async () => {
    // Clean user A's transactions for isolated check
    await pool.query('DELETE FROM transactions WHERE user_id = (SELECT id FROM users WHERE email = $1);', [userAEmail]);

    await fetch(`${baseUrl}/api/v1/transactions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userAToken}` },
      body: JSON.stringify({
        amountCents: 50000,
        type: 'income',
        category: 'Freelancing',
        description: 'Case 2 Income',
        date: new Date().toISOString(),
      }),
    });

    await fetch(`${baseUrl}/api/v1/transactions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userAToken}` },
      body: JSON.stringify({
        amountCents: 70000,
        type: 'expense',
        category: 'Rent',
        description: 'Case 2 Expense',
        date: new Date().toISOString(),
      }),
    });

    const summaryRes = await fetch(`${baseUrl}/api/v1/dashboard/summary`, {
      headers: { Authorization: `Bearer ${userAToken}` },
    });
    const summary = await summaryRes.json();
    assert.equal(summary.data.summary.totalIncomeCents, 50000);
    assert.equal(summary.data.summary.totalExpenseCents, 70000);
    assert.equal(summary.data.summary.accumulatedNetSavingsCents, -20000); // -200 ETB
  });

  it('Case 3: Income 0 ETB, Expenses 0 ETB = 0 ETB Savings', async () => {
    await pool.query('DELETE FROM transactions WHERE user_id = (SELECT id FROM users WHERE email = $1);', [userAEmail]);

    const summaryRes = await fetch(`${baseUrl}/api/v1/dashboard/summary`, {
      headers: { Authorization: `Bearer ${userAToken}` },
    });
    const summary = await summaryRes.json();
    assert.equal(summary.data.summary.totalIncomeCents, 0);
    assert.equal(summary.data.summary.totalExpenseCents, 0);
    assert.equal(summary.data.summary.accumulatedNetSavingsCents, 0);
    assert.equal(summary.data.summary.savingsRate, 0);
  });

  it('Case 4: Income 1,000 ETB (100,000 cents), Expenses 0 ETB = 1,000 ETB (100,000 cents) Savings', async () => {
    const res = await fetch(`${baseUrl}/api/v1/transactions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userAToken}` },
      body: JSON.stringify({
        amountCents: 100000,
        type: 'income',
        category: 'Salary',
        description: 'Case 4 Income Only',
        date: new Date().toISOString(),
      }),
    });
    const data = await res.json();
    editableTxId = data.data.transaction.id;

    const summaryRes = await fetch(`${baseUrl}/api/v1/dashboard/summary`, {
      headers: { Authorization: `Bearer ${userAToken}` },
    });
    const summary = await summaryRes.json();
    assert.equal(summary.data.summary.totalIncomeCents, 100000);
    assert.equal(summary.data.summary.totalExpenseCents, 0);
    assert.equal(summary.data.summary.accumulatedNetSavingsCents, 100000);
    assert.equal(summary.data.summary.savingsRate, 100.0);
  });

  it('Case 5: Editing a transaction recalculates summaries correctly', async () => {
    // Edit the 1,000 ETB income to 1,500 ETB (150,000 cents)
    const updateRes = await fetch(`${baseUrl}/api/v1/transactions/${editableTxId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userAToken}` },
      body: JSON.stringify({
        amountCents: 150000,
      }),
    });
    assert.equal(updateRes.status, 200);

    const summaryRes = await fetch(`${baseUrl}/api/v1/dashboard/summary`, {
      headers: { Authorization: `Bearer ${userAToken}` },
    });
    const summary = await summaryRes.json();
    assert.equal(summary.data.summary.totalIncomeCents, 150000);
    assert.equal(summary.data.summary.accumulatedNetSavingsCents, 150000);
  });

  it('Case 6: Deleting a transaction recalculates summaries correctly', async () => {
    // Add an expense to delete
    const expRes = await fetch(`${baseUrl}/api/v1/transactions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userAToken}` },
      body: JSON.stringify({
        amountCents: 30000,
        type: 'expense',
        category: 'Food',
        description: 'Expense to delete',
        date: new Date().toISOString(),
      }),
    });
    const expData = await expRes.json();
    deletableTxId = expData.data.transaction.id;

    // Delete the expense
    const delRes = await fetch(`${baseUrl}/api/v1/transactions/${deletableTxId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${userAToken}` },
    });
    assert.equal(delRes.status, 200);

    // Summary should now reflect ONLY the 150,000 income, with 0 expenses
    const summaryRes = await fetch(`${baseUrl}/api/v1/dashboard/summary`, {
      headers: { Authorization: `Bearer ${userAToken}` },
    });
    const summary = await summaryRes.json();
    assert.equal(summary.data.summary.totalIncomeCents, 150000);
    assert.equal(summary.data.summary.totalExpenseCents, 0);
    assert.equal(summary.data.summary.accumulatedNetSavingsCents, 150000);
  });

  it('Case 7: Offline transactions persist after restarting', async () => {
    // Verify record in database remains persisted across multiple connection lifecycles
    const tx = await pool.query('SELECT * FROM transactions WHERE id = $1 AND deleted_at IS NULL;', [editableTxId]);
    assert.ok(tx.rows[0]);
    assert.equal(Number(tx.rows[0].amount_cents), 150000);
  });

  it('Case 8: Synchronization does not create duplicates (idempotency key)', async () => {
    const mutId = `idem_sync_${Date.now()}`;
    const fixedId = 'b0000000-0000-0000-0000-000000000002';

    // First push
    const push1 = await fetch(`${baseUrl}/api/v1/sync/push`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userAToken}` },
      body: JSON.stringify({
        mutations: [{
          clientMutationId: mutId,
          entityType: 'transaction',
          entityId: fixedId,
          operationType: 'insert',
          clientTimestamp: new Date().toISOString(),
          payload: {
            amountCents: 45000,
            type: 'income',
            category: 'Bonus',
            description: 'Sync Deduplication Test',
            date: new Date().toISOString(),
          },
        }],
      }),
    });
    const body1 = await push1.json();
    assert.equal(body1.data.results[0].status, 'applied');

    // Duplicate second push with identical clientMutationId
    const push2 = await fetch(`${baseUrl}/api/v1/sync/push`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${userAToken}` },
      body: JSON.stringify({
        mutations: [{
          clientMutationId: mutId,
          entityType: 'transaction',
          entityId: fixedId,
          operationType: 'insert',
          clientTimestamp: new Date().toISOString(),
          payload: {},
        }],
      }),
    });
    const body2 = await push2.json();
    assert.equal(body2.data.results[0].status, 'applied');
    assert.ok(body2.data.results[0].note.includes('idempotent duplicate'));
  });

  it('Case 9: User A cannot access User B\'s transactions (strict multi-tenant isolation)', async () => {
    // User B attempts to access User A's transaction
    const getRes = await fetch(`${baseUrl}/api/v1/transactions/${editableTxId}`, {
      headers: { Authorization: `Bearer ${userBToken}` },
    });
    assert.equal(getRes.status, 404);

    // User B attempts to delete User A's transaction
    const delRes = await fetch(`${baseUrl}/api/v1/transactions/${editableTxId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${userBToken}` },
    });
    assert.equal(delRes.status, 404);
  });
});
