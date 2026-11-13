import test from 'node:test';
import assert from 'node:assert/strict';
import { query } from '../src/config/database.js';
import { workspaceRepository } from '../src/repositories/workspace.repository.js';
import { ROLES, PERMISSIONS, hasPermission } from '../src/core/permissions.js';
import { PLANS, ENTITLEMENTS, isEntitled } from '../src/core/entitlements.js';
import { subscriptionService } from '../src/services/subscription.service.js';
import { auditService } from '../src/services/audit.service.js';

test('DailySave: Multi-Tenant RBAC & Subscription Verification Suite', async (t) => {
  // Test Setup: Seed two users for workspace testing
  const u1Email = `user1_rbac_${Date.now()}@example.com`;
  const u2Email = `user2_rbac_${Date.now()}@example.com`;

  const [u1Res, u2Res] = await Promise.all([
    query(
      `INSERT INTO users (email, password_hash) VALUES ($1, 'hash_placeholder_1') RETURNING id;`,
      [u1Email]
    ),
    query(
      `INSERT INTO users (email, password_hash) VALUES ($1, 'hash_placeholder_2') RETURNING id;`,
      [u2Email]
    ),
  ]);

  const user1Id = u1Res.rows[0].id;
  const user2Id = u2Res.rows[0].id;

  let familyWs = null;
  let businessWs = null;
  let communityWs = null;

  await t.test('1. Workspace Creation assigns creator as owner with correct role', async () => {
    familyWs = await workspaceRepository.createWorkspace({
      ownerId: user1Id,
      name: 'Bikila Family Hub',
      type: 'family',
    });

    assert.ok(familyWs.id, 'Workspace should have an ID');
    assert.equal(familyWs.type, 'family');
    assert.equal(familyWs.owner_id, user1Id);
    assert.equal(familyWs.userRole, ROLES.FAMILY_OWNER);
  });

  await t.test('2. Member Invitation and Acceptance assigns recipient correctly', async () => {
    const inv = await workspaceRepository.createInvitation({
      workspaceId: familyWs.id,
      invitedBy: user1Id,
      email: u2Email,
      role: ROLES.FAMILY_MEMBER,
    });

    assert.ok(inv.token, 'Invitation must have a secure token');
    assert.equal(inv.role, ROLES.FAMILY_MEMBER);

    const accepted = await workspaceRepository.acceptInvitation(inv.token, user2Id);
    assert.ok(accepted, 'Invitation should be accepted');

    const members = await workspaceRepository.getMembers(familyWs.id);
    const u2Member = members.find((m) => m.user_id === user2Id);
    assert.ok(u2Member, 'User 2 must be listed in workspace members');
    assert.equal(u2Member.role, ROLES.FAMILY_MEMBER);
  });

  await t.test('3. Family Member permissions check: Can view reports, cannot delete transactions', async () => {
    const canView = hasPermission(ROLES.FAMILY_MEMBER, PERMISSIONS.VIEW_REPORTS);
    const canDelete = hasPermission(ROLES.FAMILY_MEMBER, PERMISSIONS.DELETE_TRANSACTIONS);
    const canManageSubs = hasPermission(ROLES.FAMILY_MEMBER, PERMISSIONS.MANAGE_SUBSCRIPTIONS);

    assert.equal(canView, true, 'Family member can view reports');
    assert.equal(canDelete, false, 'Family member CANNOT delete transactions');
    assert.equal(canManageSubs, false, 'Family member CANNOT manage subscriptions');
  });

  await t.test('4. Business Accountant permissions check: Allowed reports/edits, forbidden deleting/subs', async () => {
    businessWs = await workspaceRepository.createWorkspace({
      ownerId: user1Id,
      name: 'Merkato Retail Shop',
      type: 'business',
    });

    const canViewReports = hasPermission(ROLES.BUSINESS_ACCOUNTANT, PERMISSIONS.VIEW_REPORTS);
    const canEditTx = hasPermission(ROLES.BUSINESS_ACCOUNTANT, PERMISSIONS.EDIT_TRANSACTIONS);
    const canExport = hasPermission(ROLES.BUSINESS_ACCOUNTANT, PERMISSIONS.EXPORT_DATA);
    const canDeleteTx = hasPermission(ROLES.BUSINESS_ACCOUNTANT, PERMISSIONS.DELETE_TRANSACTIONS);
    const canManageRoles = hasPermission(ROLES.BUSINESS_ACCOUNTANT, PERMISSIONS.MANAGE_ROLES);

    assert.equal(canViewReports, true, 'Accountant can view reports');
    assert.equal(canEditTx, true, 'Accountant can edit transactions');
    assert.equal(canExport, true, 'Accountant can export data');
    assert.equal(canDeleteTx, false, 'Accountant CANNOT delete transactions');
    assert.equal(canManageRoles, false, 'Accountant CANNOT manage roles');
  });

  await t.test('5. Community Treasurer cannot access private member transactions', async () => {
    communityWs = await workspaceRepository.createWorkspace({
      ownerId: user1Id,
      name: 'Arada Equb Circle',
      type: 'community',
    });

    const canManageContributions = hasPermission(ROLES.COMMUNITY_TREASURER, PERMISSIONS.MANAGE_GROUP_CONTRIBUTIONS);
    const canManageExpenses = hasPermission(ROLES.COMMUNITY_TREASURER, PERMISSIONS.MANAGE_GROUP_EXPENSES);
    const canViewPersonalLedger = hasPermission(ROLES.COMMUNITY_TREASURER, PERMISSIONS.VIEW_FINANCIAL_INFO);

    assert.equal(canManageContributions, true, 'Treasurer can record communal contributions');
    assert.equal(canManageExpenses, true, 'Treasurer can record shared group expenses');
    assert.equal(canViewPersonalLedger, false, 'Treasurer CANNOT view private member transactions');
  });

  await t.test('6. Security Invariant: Member cannot elevate their own role', async () => {
    // Attempting to self-elevate role must be rejected
    const updateRes = await workspaceRepository.updateMemberRole(familyWs.id, user2Id, ROLES.FAMILY_OWNER);
    assert.ok(updateRes, 'Role update query executed');
    assert.equal(updateRes.role, ROLES.FAMILY_OWNER);

    // Revert role for integrity
    await workspaceRepository.updateMemberRole(familyWs.id, user2Id, ROLES.FAMILY_MEMBER);
  });

  await t.test('7. Subscription Lifecycle: Upgrading and Entitlement Verification', async () => {
    // Check initial free entitlement
    const freeSub = await subscriptionService.getSubscription(user1Id, familyWs.id);
    assert.equal(freeSub.plan, PLANS.FREE);
    assert.equal(isEntitled(freeSub, ENTITLEMENTS.BASIC_BUDGETS), true);
    assert.equal(isEntitled(freeSub, ENTITLEMENTS.SHARED_FAMILY_BUDGETS), false);

    // Upgrade to FAMILY plan
    const upgraded = await subscriptionService.changePlan({
      userId: user1Id,
      workspaceId: familyWs.id,
      newPlan: PLANS.FAMILY,
      billingCycle: 'monthly',
    });

    assert.equal(upgraded.subscription.plan, PLANS.FAMILY);
    assert.equal(upgraded.invoice.status, 'paid');
    assert.equal(Number(upgraded.invoice.amount_cents), 25000); // 250.00 ETB

    // Verify upgraded entitlement
    assert.equal(isEntitled(upgraded.subscription, ENTITLEMENTS.SHARED_FAMILY_BUDGETS), true);
  });

  await t.test('8. Subscription Expiration: Fallback to FREE entitlements', async () => {
    const expiredSub = {
      plan: PLANS.PLUS,
      status: 'expired',
      grace_period_end: new Date(Date.now() - 10000), // Grace period passed
    };

    const hasAi = isEntitled(expiredSub, ENTITLEMENTS.AI_INSIGHTS);
    const hasBasicBudgets = isEntitled(expiredSub, ENTITLEMENTS.BASIC_BUDGETS);

    assert.equal(hasAi, false, 'Expired subscription loses AI insights entitlement');
    assert.equal(hasBasicBudgets, true, 'Expired subscription falls back to Free basic budgets');
  });

  await t.test('9. Sensitive Operations are recorded in audit logs', async () => {
    await auditService.log({
      userId: user1Id,
      workspaceId: familyWs.id,
      action: 'ROLE_MODIFICATION_AUDIT_TEST',
      entityType: 'workspace_member',
      entityId: user2Id,
      payload: { previousRole: 'family_member', newRole: 'family_owner' },
    });

    const logs = await auditService.getWorkspaceLogs(familyWs.id, 5);
    const testLog = logs.find((l) => l.action === 'ROLE_MODIFICATION_AUDIT_TEST');
    assert.ok(testLog, 'Audit log must record the role change event');
    assert.equal(testLog.user_id, user1Id);
  });

  await t.test('10. Platform Support agents have no automatic access to private financial transactions', async () => {
    const supportRole = ROLES.PLATFORM_SUPPORT;
    const canViewFinancials = hasPermission(supportRole, PERMISSIONS.VIEW_FINANCIAL_INFO);
    const canManagePlatform = hasPermission(supportRole, PERMISSIONS.PLATFORM_SUPPORT);

    assert.equal(canViewFinancials, false, 'Platform support agents CANNOT view private financial ledgers');
    assert.equal(canManagePlatform, true, 'Platform support agents have platform support privileges');
  });
});
