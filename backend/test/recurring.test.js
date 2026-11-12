import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer, buildRouter, stopServer } from '../src/server.js';
import { pool } from '../src/config/database.js';

describe('DailySave Recurring Transactions & Duplicate Prevention Suite', () => {
  let server;
  let baseUrl;
  const testEmail = `recurring_${Date.now()}@dailysave.org`;
  let token = '';
  let recurringId = '';

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
        fullName: 'Recurring User',
      }),
    });
    const d = await res.json();
    token = d.data.tokens.accessToken;
  });

  after(async () => {
    await pool.query('DELETE FROM users WHERE email = $1;', [testEmail]);
    await stopServer(server);
  });

  it('1. Create Recurring monthly internet bill of 1,200 ETB (120,000 cents)', async () => {
    const res = await fetch(`${baseUrl}/api/v1/recurring-transactions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        amountCents: 120000,
        type: 'expense',
        category: 'Internet',
        description: 'Ethio Telecom Fiber Monthly',
        recurrenceInterval: 'monthly',
        nextExecutionDate: new Date().toISOString(),
        account: 'Cash Wallet',
        requiresReview: true,
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.recurringTransaction.amount_cents, 120000);
    assert.equal(body.data.recurringTransaction.recurrence_interval, 'monthly');
    recurringId = body.data.recurringTransaction.id;
  });

  it('2. Generate transaction from recurring schedule', async () => {
    const res = await fetch(`${baseUrl}/api/v1/recurring-transactions/${recurringId}/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        executionDate: new Date().toISOString(),
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.ok(body.data.transaction);
    assert.equal(body.data.transaction.amount_cents, 120000);
    assert.equal(body.data.transaction.category, 'Internet');
  });

  it('3. Duplicate prevention: Generating again for the same date does NOT create duplicate transaction', async () => {
    const res = await fetch(`${baseUrl}/api/v1/recurring-transactions/${recurringId}/generate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        executionDate: new Date().toISOString(),
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.isDuplicate, true);
    assert.ok(body.data.message.includes('duplicate prevented'));
  });
});
