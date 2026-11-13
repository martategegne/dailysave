import { workspaceRepository } from '../repositories/workspace.repository.js';
import { auditService } from '../services/audit.service.js';
import { sendJson, sendError } from '../core/response.js';
import { ROLES, PERMISSIONS } from '../core/permissions.js';

export const workspaceController = {
  /**
   * POST /api/v1/workspaces - Creates a new workspace.
   */
  async createWorkspace(req, res) {
    const userId = req.user.id;
    const { name, type = 'personal', currency = 'ETB', description = '' } = req.body || {};

    if (!name || name.trim().length === 0) {
      return sendError(res, 400, 'Workspace name is required.');
    }

    const validTypes = ['personal', 'family', 'business', 'community'];
    if (!validTypes.includes(type)) {
      return sendError(res, 400, `Invalid workspace type. Allowed: ${validTypes.join(', ')}`);
    }

    const workspace = await workspaceRepository.createWorkspace({
      ownerId: userId,
      name: name.trim(),
      type,
      currency,
      description,
    });

    await auditService.log({
      userId,
      workspaceId: workspace.id,
      action: 'WORKSPACE_CREATED',
      entityType: 'workspace',
      entityId: workspace.id,
      payload: { name: workspace.name, type: workspace.type },
      ipAddress: req.socket?.remoteAddress,
    });

    return sendJson(res, 201, workspace);
  },

  /**
   * GET /api/v1/workspaces - Lists user's workspaces.
   */
  async listWorkspaces(req, res) {
    const userId = req.user.id;
    const workspaces = await workspaceRepository.getUserWorkspaces(userId);
    return sendJson(res, 200, workspaces);
  },

  /**
   * GET /api/v1/workspaces/:id - Retrieves workspace details and members.
   */
  async getWorkspace(req, res) {
    const workspaceId = req.params.id;
    const workspace = await workspaceRepository.getById(workspaceId);

    if (!workspace) {
      return sendError(res, 404, 'Workspace not found.');
    }

    const members = await workspaceRepository.getMembers(workspaceId);
    return sendJson(res, 200, { ...workspace, members });
  },

  /**
   * POST /api/v1/workspaces/:id/invitations - Invites a new member.
   */
  async inviteMember(req, res) {
    const workspaceId = req.params.id;
    const userId = req.user.id;
    const { email, role } = req.body || {};

    if (!email || !email.includes('@')) {
      return sendError(res, 400, 'A valid recipient email address is required.');
    }

    const validRoles = Object.values(ROLES);
    if (!role || !validRoles.includes(role)) {
      return sendError(res, 400, `Valid role is required. Allowed: ${validRoles.join(', ')}`);
    }

    const invitation = await workspaceRepository.createInvitation({
      workspaceId,
      invitedBy: userId,
      email,
      role,
    });

    await auditService.log({
      userId,
      workspaceId,
      action: 'MEMBER_INVITED',
      entityType: 'workspace_invitation',
      entityId: invitation.id,
      payload: { email, role },
      ipAddress: req.socket?.remoteAddress,
    });

    return sendJson(res, 201, {
      message: `Invitation generated for ${email}`,
      invitation,
    });
  },

  /**
   * POST /api/v1/workspaces/invitations/:token/accept - Accepts an invitation.
   */
  async acceptInvitation(req, res) {
    const token = req.params.token;
    const userId = req.user.id;

    const accepted = await workspaceRepository.acceptInvitation(token, userId);
    if (!accepted) {
      return sendError(res, 404, 'Invalid, expired, or already accepted invitation token.');
    }

    await auditService.log({
      userId,
      workspaceId: accepted.workspace_id,
      action: 'MEMBER_JOINED',
      entityType: 'workspace_member',
      entityId: userId,
      payload: { role: accepted.role },
      ipAddress: req.socket?.remoteAddress,
    });

    return sendJson(res, 200, {
      message: 'Successfully joined workspace.',
      workspaceId: accepted.workspace_id,
      role: accepted.role,
    });
  },

  /**
   * PATCH /api/v1/workspaces/:id/members/:memberUserId - Updates a member's role.
   */
  async updateMemberRole(req, res) {
    const workspaceId = req.params.id;
    const memberUserId = req.params.memberUserId;
    const adminUserId = req.user.id;
    const { role: newRole } = req.body || {};

    // Security invariant: Member cannot assign themselves a privileged role
    if (adminUserId === memberUserId) {
      return sendError(res, 400, 'Security Policy: You cannot modify your own workspace role.');
    }

    const validRoles = Object.values(ROLES);
    if (!newRole || !validRoles.includes(newRole)) {
      return sendError(res, 400, `Invalid role. Allowed: ${validRoles.join(', ')}`);
    }

    const updated = await workspaceRepository.updateMemberRole(workspaceId, memberUserId, newRole);
    if (!updated) {
      return sendError(res, 404, 'Workspace member not found.');
    }

    await auditService.log({
      userId: adminUserId,
      workspaceId,
      action: 'MEMBER_ROLE_CHANGED',
      entityType: 'workspace_member',
      entityId: memberUserId,
      payload: { newRole },
      ipAddress: req.socket?.remoteAddress,
    });

    return sendJson(res, 200, {
      message: `Role updated to ${newRole}`,
      member: updated,
    });
  },

  /**
   * DELETE /api/v1/workspaces/:id/members/:memberUserId - Removes a member.
   */
  async removeMember(req, res) {
    const workspaceId = req.params.id;
    const memberUserId = req.params.memberUserId;
    const adminUserId = req.user.id;

    // Check if member is workspace owner
    const ws = await workspaceRepository.getById(workspaceId);
    if (ws && ws.owner_id === memberUserId) {
      return sendError(res, 400, 'Cannot remove the primary workspace owner. Transfer ownership first.');
    }

    const removed = await workspaceRepository.removeMember(workspaceId, memberUserId);
    if (!removed) {
      return sendError(res, 404, 'Workspace member not found.');
    }

    await auditService.log({
      userId: adminUserId,
      workspaceId,
      action: 'MEMBER_REMOVED',
      entityType: 'workspace_member',
      entityId: memberUserId,
      ipAddress: req.socket?.remoteAddress,
    });

    return sendJson(res, 200, { message: 'Member successfully removed from workspace.' });
  },

  /**
   * POST /api/v1/workspaces/:id/transfer-ownership - Transfers workspace ownership.
   */
  async transferOwnership(req, res) {
    const workspaceId = req.params.id;
    const currentOwnerId = req.user.id;
    const { newOwnerId, newOwnerRole } = req.body || {};

    if (!newOwnerId) {
      return sendError(res, 400, 'New owner user ID is required.');
    }

    const ws = await workspaceRepository.getById(workspaceId);
    if (!ws || ws.owner_id !== currentOwnerId) {
      return sendError(res, 403, 'Forbidden: Only the workspace owner can transfer ownership.');
    }

    await workspaceRepository.transferOwnership(workspaceId, currentOwnerId, newOwnerId, newOwnerRole);

    await auditService.log({
      userId: currentOwnerId,
      workspaceId,
      action: 'WORKSPACE_OWNERSHIP_TRANSFERRED',
      entityType: 'workspace',
      entityId: workspaceId,
      payload: { previousOwner: currentOwnerId, newOwner: newOwnerId },
      ipAddress: req.socket?.remoteAddress,
    });

    return sendJson(res, 200, { message: 'Ownership transferred successfully.' });
  },

  /**
   * DELETE /api/v1/workspaces/:id - Soft deletes a workspace.
   */
  async deleteWorkspace(req, res) {
    const workspaceId = req.params.id;
    const ownerId = req.user.id;

    const ws = await workspaceRepository.getById(workspaceId);
    if (!ws || ws.owner_id !== ownerId) {
      return sendError(res, 403, 'Forbidden: Only the primary workspace owner can delete the workspace.');
    }

    if (ws.type === 'personal') {
      return sendError(res, 400, 'Primary personal workspace cannot be deleted.');
    }

    await workspaceRepository.softDelete(workspaceId, ownerId);

    await auditService.log({
      userId: ownerId,
      workspaceId,
      action: 'WORKSPACE_DELETED',
      entityType: 'workspace',
      entityId: workspaceId,
      payload: { name: ws.name },
      ipAddress: req.socket?.remoteAddress,
    });

    return sendJson(res, 200, { message: 'Workspace deleted successfully.' });
  },
};
