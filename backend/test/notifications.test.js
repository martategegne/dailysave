import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer, buildRouter, stopServer } from '../src/server.js';
import { pool } from '../src/config/database.js';

describe('DailySave Notifications & Financial Reminders Suite', () => {
  let server;
  let baseUrl;
  const testEmail = `notify_${Date.now()}@dailysave.org`;
  let token = '';
  let notificationId = '';

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
        fullName: 'Notify Tester',
      }),
    });
    const d = await res.json();
    token = d.data.tokens.accessToken;
  });

  after(async () => {
    await pool.query('DELETE FROM users WHERE email = $1;', [testEmail]);
    await stopServer(server);
  });

  it('1. Create budget warning notification (90% danger threshold reached)', async () => {
    const res = await fetch(`${baseUrl}/api/v1/notifications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        title: 'Budget Alert: Food Category',
        message: 'You have used 92% of your monthly food budget.',
        type: 'budget_warning',
        metadata: {
          category: 'Food',
          percentage: 92.0,
        },
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.notification.title, 'Budget Alert: Food Category');
    assert.equal(body.data.notification.is_read, false);
    notificationId = body.data.notification.id;
  });

  it('2. List notifications and verify unreadCount = 1', async () => {
    const res = await fetch(`${baseUrl}/api/v1/notifications`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.unreadCount, 1);
    assert.equal(body.data.notifications.length, 1);
  });

  it('3. Mark notification as read and verify unreadCount = 0', async () => {
    const res = await fetch(`${baseUrl}/api/v1/notifications/${notificationId}/read`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${token}` },
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.notification.is_read, true);

    const checkRes = await fetch(`${baseUrl}/api/v1/notifications?unreadOnly=true`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const checkBody = await checkRes.json();
    assert.equal(checkBody.data.notifications.length, 0);
  });
});
