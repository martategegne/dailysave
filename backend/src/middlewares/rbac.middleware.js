import { query } from '../config/database.js';
import { sendError } from '../core/response.js';
import { hasPermission, PERMISSIONS } from '../core/permissions.js';
import { auditService } from '../services/audit.service.js';

/**
 * Middleware factory enforcing workspace membership and specific RBAC permission.
 * Validates ownership and workspace boundaries on every request.
 */
export function requirePermission(requiredPermission) {
  return async (req, res, next) => {
    const userId = req.user?.id;
    if (!userId) {
      return sendError(res, 401, 'Authentication required before accessing workspace.');
    }

    // Resolve workspace ID from Header, Query, or Body
    const workspaceId =
      req.headers['x-workspace-id'] ||
      req.query?.workspaceId ||
      req.body?.workspaceId ||
      req.params?.workspaceId;

    if (!workspaceId) {
      // Fallback: If no workspace is specified, check if user has a default personal workspace
      const defaultWsRes = await query(
        `SELECT id FROM workspaces WHERE owner_id = $1 AND type = 'personal' LIMIT 1;`,
        [userId]
      );

      if (defaultWsRes.rows.length === 0) {
        return sendError(res, 400, 'Workspace context is required. Provide X-Workspace-ID header.');
      }

      req.resolvedWorkspaceId = defaultWsRes.rows[0].id;
    } else {
      req.resolvedWorkspaceId = workspaceId;
    }

    // 1. Verify Platform Support / Admin Boundary
    // Platform support/admin agents MUST NOT have automatic access to private financial records.
    if (req.user?.platformRole === 'platform_support' && requiredPermission === PERMISSIONS.VIEW_FINANCIAL_INFO) {
      await auditService.log({
        userId,
        workspaceId: req.resolvedWorkspaceId,
        action: 'DENIED_PLATFORM_SUPPORT_FINANCIAL_ACCESS',
        entityType: 'workspace',
        entityId: req.resolvedWorkspaceId,
        ipAddress: req.socket?.remoteAddress,
      });
      return sendError(
        res,
        403,
        'Access Denied: Platform support agents are prohibited from viewing private customer financial records.'
      );
    }

    // 2. Fetch membership record for this user and workspace
    const memberRes = await query(
      `
      SELECT wm.id, wm.workspace_id, wm.user_id, wm.role, wm.permissions, w.owner_id, w.type AS workspace_type, w.name AS workspace_name
      FROM workspace_members wm
      JOIN workspaces w ON w.id = wm.workspace_id
      WHERE wm.workspace_id = $1 AND wm.user_id = $2 AND w.deleted_at IS NULL;
      `,
      [req.resolvedWorkspaceId, userId]
    );

    if (memberRes.rows.length === 0) {
      await auditService.log({
        userId,
        workspaceId: req.resolvedWorkspaceId,
        action: 'UNAUTHORIZED_WORKSPACE_ACCESS_ATTEMPT',
        entityType: 'workspace',
        entityId: req.resolvedWorkspaceId,
        ipAddress: req.socket?.remoteAddress,
      });
      return sendError(res, 403, 'Forbidden: You are not a member of this workspace.');
    }

    const membership = memberRes.rows[0];

    // 3. Permission Evaluation
    const permitted = hasPermission(membership.role, requiredPermission, membership.permissions || []);
    if (!permitted) {
      await auditService.log({
        userId,
        workspaceId: req.resolvedWorkspaceId,
        action: 'PERMISSION_DENIED',
        entityType: 'permission',
        entityId: requiredPermission,
        payload: { role: membership.role },
        ipAddress: req.socket?.remoteAddress,
      });
      return sendError(
        res,
        403,
        `Forbidden: Role '${membership.role}' lacks permission '${requiredPermission}' in this workspace.`
      );
    }

    // Attach verified membership context to request
    req.workspaceMember = {
      id: membership.id,
      workspaceId: membership.workspace_id,
      role: membership.role,
      permissions: membership.permissions,
      isOwner: membership.owner_id === userId,
      workspaceType: membership.workspace_type,
      workspaceName: membership.workspace_name,
    };

    if (next) next();
  };
}

/**
 * Middleware requiring specific workspace role (e.g. ['family_owner', 'business_owner']).
 */
export function requireWorkspaceRole(allowedRoles = []) {
  return async (req, res, next) => {
    await requirePermission(PERMISSIONS.VIEW_FINANCIAL_INFO)(req, res, async () => {
      if (!allowedRoles.includes(req.workspaceMember.role)) {
        return sendError(
          res,
          403,
          `Forbidden: Action requires one of the following roles: [${allowedRoles.join(', ')}].`
        );
      }
      if (next) next();
    });
  };
}
