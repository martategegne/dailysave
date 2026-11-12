import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createServer, buildRouter, stopServer } from '../src/server.js';
import { pool } from '../src/config/database.js';

describe('DailySave Community Savings Groups (Privacy-Enforced) Suite', () => {
  let server;
  let baseUrl;
  const ownerEmail = `comm_owner_${Date.now()}@dailysave.org`;
  const memberEmail = `comm_member_${Date.now()}@dailysave.org`;
  let ownerToken = '';
  let memberToken = '';
  let groupId = '';

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

    // 1. Register Owner
    const res1 = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: ownerEmail,
        password: 'Password123!',
        fullName: 'Group Creator',
      }),
    });
    const d1 = await res1.json();
    ownerToken = d1.data.tokens.accessToken;

    // 2. Register Member
    const res2 = await fetch(`${baseUrl}/api/v1/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: memberEmail,
        password: 'Password123!',
        fullName: 'Invited Member',
      }),
    });
    const d2 = await res2.json();
    memberToken = d2.data.tokens.accessToken;
  });

  after(async () => {
    await pool.query('DELETE FROM users WHERE email IN ($1, $2);', [ownerEmail, memberEmail]);
    await stopServer(server);
  });

  it('1. Create Community Savings Group (Addis Tech Equb)', async () => {
    const res = await fetch(`${baseUrl}/api/v1/community/groups`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ownerToken}`,
      },
      body: JSON.stringify({
        name: 'Addis Tech Equb',
        description: 'Monthly developer savings circle',
        targetAmountCents: 10000000, // 100,000 ETB
        contributionFrequency: 'monthly',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.group.name, 'Addis Tech Equb');
    assert.equal(body.data.group.target_amount_cents, 10000000);
    groupId = body.data.group.id;
  });

  it('2. Invite member to the community group', async () => {
    const res = await fetch(`${baseUrl}/api/v1/community/groups/${groupId}/invite`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ownerToken}`,
      },
      body: JSON.stringify({
        targetEmail: memberEmail,
        role: 'member',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.member.role, 'member');
  });

  it('3. Member views group and contributes 5,000 ETB (500,000 cents)', async () => {
    const res = await fetch(`${baseUrl}/api/v1/community/groups/${groupId}/contributions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${memberToken}`,
      },
      body: JSON.stringify({
        amountCents: 500000,
        notes: 'November round contribution',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.contribution.amount_cents, 500000);
  });

  it('4. Treasurer/Creator records shared group expense (1,000 ETB = 100,000 cents)', async () => {
    const res = await fetch(`${baseUrl}/api/v1/community/groups/${groupId}/expenses`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ownerToken}`,
      },
      body: JSON.stringify({
        amountCents: 100000,
        category: 'Administrative',
        description: 'Ledger printing and meeting hall reservation',
      }),
    });

    const body = await res.json();
    assert.equal(res.status, 201);
    assert.equal(body.data.expense.amount_cents, 100000);
  });

  it('5. GET /community/groups/:id/report verifies net pool (5,000 - 1,000 = 4,000 ETB / 400,000 cents)', async () => {
    const res = await fetch(`${baseUrl}/api/v1/community/groups/${groupId}/report`, {
      headers: { Authorization: `Bearer ${memberToken}` },
    });

    const body = await res.json();
    assert.equal(res.status, 200);
    assert.equal(body.data.report.totalContributionsCents, 500000);
    assert.equal(body.data.report.totalExpensesCents, 100000);
    assert.equal(body.data.report.netPoolCents, 400000);
    assert.equal(body.data.report.memberCount, 2);
  });
});
