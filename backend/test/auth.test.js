import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer, buildRouter, stopServer } from '../src/server.js';
import { pool } from '../src/config/database.js';

describe('DailySave Auth & Security Suite', () => {
  let server;
  let baseUrl;
  const testEmail = `test_${Date.now()}@dailysave.org`;
  const testPassword = 'Password123!';
  let accessToken = '';
  let refreshToken = '';

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
  });

  after(async () => {
    if (testEmail) {
      await pool.query('DELETE FROM users WHERE email = $1;', [testEmail]);
    }
    await stopServer(server);
  });

  it('1. GET /health should return 200 and ok status', async () => {
    const res = await fetch(`${baseUrl}/health`);
    const body = await res.json();

    assert.equal(res.status, 200);
    assert.equal(body.data.status, 'ok');
    assert.equal(body.data.service, 'dailysave-backend');
  });

  it('2. POST /api/v1/auth/register should create user and return tokens', async () => {
    const res = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
        fullName: 'Test Automation User',
        defaultCurrency: 'ETB',
        language: 'en',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.user.email, testEmail);
    assert.ok(body.data.tokens.accessToken);
    assert.ok(body.data.tokens.refreshToken);

    accessToken = body.data.tokens.accessToken;
    refreshToken = body.data.tokens.refreshToken;
  });

  it('3. POST /api/v1/auth/register with duplicate email should return 409 Conflict', async () => {
    const res = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
        fullName: 'Duplicate User',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 409);
    assert.ok(body.error.message.includes('already exists'));
  });

  it('4. POST /api/v1/auth/login should authenticate and return fresh tokens', async () => {
    const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.ok(body.data.tokens.accessToken);
    assert.ok(body.data.tokens.refreshToken);

    accessToken = body.data.tokens.accessToken;
    refreshToken = body.data.tokens.refreshToken;
  });

  it('5. POST /api/v1/auth/login with invalid password should return 401', async () => {
    const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: 'WrongPassword!',
      }),
    });

    assert.equal(res.status, 401);
  });

  it('6. GET /api/v1/auth/me should return current user profile', async () => {
    const res = await fetch(`${baseUrl}/api/v1/auth/me`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.user.email, testEmail);
    assert.equal(body.data.user.fullName, 'Test Automation User');
  });

  it('7. POST /api/v1/auth/refresh should rotate refresh token', async () => {
    const oldRefreshToken = refreshToken;

    const res = await fetch(`${baseUrl}/api/v1/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: oldRefreshToken }),
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.ok(body.data.tokens.accessToken);
    assert.ok(body.data.tokens.refreshToken);
    assert.notEqual(body.data.tokens.refreshToken, oldRefreshToken);

    // Reuse of rotated token should trigger theft detection and be rejected
    const reuseRes = await fetch(`${baseUrl}/api/v1/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: oldRefreshToken }),
    });

    assert.equal(reuseRes.status, 403);
  });
});
