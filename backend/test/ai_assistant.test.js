import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer, buildRouter, stopServer } from '../src/server.js';
import { pool } from '../src/config/database.js';

describe('DailySave Privacy-Gated AI Financial Assistant Suite', () => {
  let server;
  let baseUrl;
  const testEmail = `ai_user_${Date.now()}@dailysave.org`;
  let token = '';

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
        fullName: 'AI Tester',
      }),
    });
    const d = await res.json();
    token = d.data.tokens.accessToken;
  });

  after(async () => {
    await pool.query('DELETE FROM users WHERE email = $1;', [testEmail]);
    await stopServer(server);
  });

  it('1. GET /api/v1/ai/insights before granting consent returns 403 Forbidden with consentRequired', async () => {
    const res = await fetch(`${baseUrl}/api/v1/ai/insights`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const body = await res.json();
    assert.equal(res.status, 403);
    assert.equal(body.error.details.consentRequired, true);
    assert.ok(body.error.message.includes('consent is required'));
  });

  it('2. POST /api/v1/ai/consent enables explicit user opt-in', async () => {
    const res = await fetch(`${baseUrl}/api/v1/ai/consent`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ consent: true }),
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.isConsentGiven, true);
  });

  it('3. GET /api/v1/ai/insights after consent returns grounded analysis and disclaimer', async () => {
    const res = await fetch(`${baseUrl}/api/v1/ai/insights`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.consentRequired, false);
    assert.ok(Array.isArray(body.data.insights));
    assert.ok(body.data.disclaimer.includes('informational suggestions'));
  });
});
