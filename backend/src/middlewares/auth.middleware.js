import { sendError } from '../core/response.js';
import { tokenService } from '../services/token.service.js';
import { authRepository } from '../repositories/auth.repository.js';

/**
 * Middleware enforcing JWT Bearer token authentication on protected endpoints.
 * Populates `req.user` with the active user record.
 * 
 * @param {import('node:http').IncomingMessage} req
 * @param {import('node:http').ServerResponse} res
 * @param {Function} next
 */
export async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return sendError(
      res,
      401,
      'Access denied. Missing or invalid Authorization Bearer header.'
    );
  }

  const token = authHeader.substring(7).trim();

  try {
    const payload = tokenService.verifyAccessToken(token);
    const user = await authRepository.findUserById(payload.sub);

    if (!user) {
      return sendError(res, 401, 'User associated with this token no longer exists.');
    }

    if (!user.is_active) {
      return sendError(res, 403, 'Account is disabled. Please contact support.');
    }

    req.user = user;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return sendError(
        res,
        401,
        'Access token expired. Please refresh your session.',
        { tokenExpired: true }
      );
    }
    return sendError(res, 401, 'Invalid authentication token.');
  }
}
