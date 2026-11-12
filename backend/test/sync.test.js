import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer, buildRouter, stopServer } from '../src/server.js';
import { pool } from '../src/config/database.js';

describe('DailySave Offline Synchronization Engine Suite', () => {
  let server;
  let baseUrl;
  const testEmail = `sync_${Date.now()}@dailysave.org`;
  let token = '';
  const testMutationId = `mut_${Date.now()}`;
  const testTxId = 'a0000000-0000-0000-0000-000000000001';

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
        fullName: 'Sync Tester',
      }),
    });
    const d = await res.json();
    token = d.data.tokens.accessToken;
  });

  after(async () => {
    await pool.query('DELETE FROM users WHERE email = $1;', [testEmail]);
    await stopServer(server);
  });

  it('1. POST /api/v1/sync/push should apply offline client mutations', async () => {
    const res = await fetch(`${baseUrl}/api/v1/sync/push`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        mutations: [
          {
            clientMutationId: testMutationId,
            entityType: 'transaction',
            entityId: testTxId,
            operationType: 'insert',
            clientTimestamp: new Date().toISOString(),
            payload: {
              amountCents: 85000,
              type: 'income',
              category: 'Freelancing',
              description: 'Flutter UI contract',
              date: new Date().toISOString(),
              account: 'Cash Wallet',
            },
          },
        ],
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.results.length, 1);
    assert.equal(body.data.results[0].status, 'applied');
    assert.ok(body.data.serverSyncTimestamp);
  });

  it('2. POST /api/v1/sync/push with duplicate clientMutationId should be idempotent', async () => {
    const res = await fetch(`${baseUrl}/api/v1/sync/push`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        mutations: [
          {
            clientMutationId: testMutationId,
            entityType: 'transaction',
            entityId: testTxId,
            operationType: 'insert',
            clientTimestamp: new Date().toISOString(),
            payload: {},
          },
        ],
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.results.length, 1);
    assert.equal(body.data.results[0].status, 'applied');
    assert.ok(body.data.results[0].note.includes('idempotent duplicate'));
  });

  it('3. GET /api/v1/sync/pull should return changed transactions', async () => {
    const past = new Date(Date.now() - 60000).toISOString();
    const res = await fetch(`${baseUrl}/api/v1/sync/pull?since=${past}`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.ok(body.data.changes.transactions.length >= 1);
    const pulledTx = body.data.changes.transactions.find((t) => t.id === testTxId);
    assert.ok(pulledTx);
    assert.equal(pulledTx.description, 'Flutter UI contract');
  });
});
