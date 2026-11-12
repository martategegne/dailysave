import { env } from '../config/env.js';
import { sendJson, sendError } from '../core/response.js';
import { validateSchema, validator } from '../core/validator.js';
import { passwordService } from '../services/password.service.js';
import { tokenService } from '../services/token.service.js';
import { authRepository } from '../repositories/auth.repository.js';

export const authController = {
  /**
   * POST /api/v1/auth/register
   */
  async register(req, res) {
    const { email, password, fullName, defaultCurrency, language } = req.body;

    validateSchema(
      { email, password, fullName },
      {
        email: {
          required: true,
          validator: validator.isEmail,
          message: 'A valid email address is required.',
        },
        password: {
          required: true,
          validator: validator.isStrongPassword,
          message:
            'Password must be at least 8 characters and contain both letters and digits.',
        },
        fullName: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Full name is required.',
        },
      }
    );

    const existingUser = await authRepository.findUserByEmail(email);
    if (existingUser) {
      return sendError(
        res,
        409,
        'An account with this email address already exists.'
      );
    }

    const passwordHash = await passwordService.hash(password);

    const user = await authRepository.createUserWithProfile({
      email,
      passwordHash,
      fullName,
      defaultCurrency: defaultCurrency || 'ETB',
      language: language || 'en',
    });

    const tokens = tokenService.generateTokens(user);
    const tokenHash = tokenService.hashToken(tokens.refreshToken);
    const expiresAt = new Date(
      Date.now() + env.security.jwtRefreshExpiresIn * 1000
    );

    const ipAddress =
      req.headers['x-forwarded-for']?.split(',')[0].trim() ||
      req.socket.remoteAddress;

    await authRepository.storeRefreshToken({
      userId: user.id,
      tokenHash,
      expiresAt,
      ipAddress,
      userAgent: req.headers['user-agent'] || 'unknown',
    });

    await authRepository.recordAuditLog({
      userId: user.id,
      action: 'USER_REGISTER',
      entityType: 'users',
      entityId: user.id,
      ipAddress,
    });

    sendJson(
      res,
      201,
      {
        user: {
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          defaultCurrency: user.defaultCurrency,
          language: user.language,
          createdAt: user.createdAt,
        },
        tokens,
      },
      { Location: `/api/v1/users/${user.id}` }
    );
  },

  /**
   * POST /api/v1/auth/login
   */
  async login(req, res) {
    const { email, password } = req.body;

    validateSchema(
      { email, password },
      {
        email: {
          required: true,
          validator: validator.isEmail,
          message: 'Email is required.',
        },
        password: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Password is required.',
        },
      }
    );

    const user = await authRepository.findUserByEmail(email);
    if (!user) {
      return sendError(res, 401, 'Invalid email or password.');
    }

    if (!user.is_active) {
      return sendError(res, 403, 'Account is disabled. Please contact support.');
    }

    const isValidPassword = await passwordService.verify(
      user.password_hash,
      password
    );
    if (!isValidPassword) {
      return sendError(res, 401, 'Invalid email or password.');
    }

    const tokens = tokenService.generateTokens(user);
    const tokenHash = tokenService.hashToken(tokens.refreshToken);
    const expiresAt = new Date(
      Date.now() + env.security.jwtRefreshExpiresIn * 1000
    );

    const ipAddress =
      req.headers['x-forwarded-for']?.split(',')[0].trim() ||
      req.socket.remoteAddress;

    await authRepository.storeRefreshToken({
      userId: user.id,
      tokenHash,
      expiresAt,
      ipAddress,
      userAgent: req.headers['user-agent'] || 'unknown',
    });

    await authRepository.recordAuditLog({
      userId: user.id,
      action: 'USER_LOGIN',
      entityType: 'users',
      entityId: user.id,
      ipAddress,
    });

    sendJson(res, 200, {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.full_name,
        defaultCurrency: user.default_currency,
        language: user.language,
        themeMode: user.theme_mode,
        createdAt: user.created_at,
      },
      tokens,
    });
  },

  /**
   * POST /api/v1/auth/refresh (Implements Refresh Token Rotation)
   */
  async refresh(req, res) {
    const { refreshToken } = req.body;

    validateSchema(
      { refreshToken },
      {
        refreshToken: {
          required: true,
          validator: validator.isNonEmptyString,
          message: 'Refresh token is required.',
        },
      }
    );

    const tokenHash = tokenService.hashToken(refreshToken);
    const tokenRecord = await authRepository.findRefreshToken(tokenHash);

    if (!tokenRecord) {
      return sendError(res, 401, 'Invalid or unrecognized refresh token.');
    }

    // Refresh Token Reuse Detection (Security Alert)
    if (tokenRecord.is_revoked) {
      // Automatic session revocation across all devices if token reuse is detected
      await authRepository.revokeAllUserTokens(tokenRecord.user_id);
      return sendError(
        res,
        403,
        'Suspicious session token reuse detected. All sessions have been revoked for your protection.'
      );
    }

    if (new Date() > new Date(tokenRecord.expires_at)) {
      return sendError(
        res,
        401,
        'Refresh token has expired. Please sign in again.'
      );
    }

    const user = await authRepository.findUserById(tokenRecord.user_id);
    if (!user || !user.is_active) {
      return sendError(res, 401, 'User account no longer active.');
    }

    // Rotate Tokens: generate new pair, mark old token as revoked
    const newTokens = tokenService.generateTokens(user);
    const newTokenHash = tokenService.hashToken(newTokens.refreshToken);
    const expiresAt = new Date(
      Date.now() + env.security.jwtRefreshExpiresIn * 1000
    );

    const ipAddress =
      req.headers['x-forwarded-for']?.split(',')[0].trim() ||
      req.socket.remoteAddress;

    await authRepository.revokeRefreshToken(tokenHash, newTokenHash);
    await authRepository.storeRefreshToken({
      userId: user.id,
      tokenHash: newTokenHash,
      expiresAt,
      ipAddress,
      userAgent: req.headers['user-agent'] || 'unknown',
    });

    sendJson(res, 200, {
      tokens: newTokens,
    });
  },

  /**
   * POST /api/v1/auth/logout
   */
  async logout(req, res) {
    const { refreshToken } = req.body;
    if (refreshToken) {
      const tokenHash = tokenService.hashToken(refreshToken);
      await authRepository.revokeRefreshToken(tokenHash);
    }

    if (req.user) {
      const ipAddress =
        req.headers['x-forwarded-for']?.split(',')[0].trim() ||
        req.socket.remoteAddress;

      await authRepository.recordAuditLog({
        userId: req.user.id,
        action: 'USER_LOGOUT',
        entityType: 'users',
        entityId: req.user.id,
        ipAddress,
      });
    }

    sendJson(res, 200, { message: 'Successfully logged out.' });
  },

  /**
   * GET /api/v1/auth/me
   */
  async getMe(req, res) {
    sendJson(res, 200, {
      user: {
        id: req.user.id,
        email: req.user.email,
        fullName: req.user.full_name,
        defaultCurrency: req.user.default_currency,
        language: req.user.language,
        themeMode: req.user.theme_mode,
        createdAt: req.user.created_at,
      },
    });
  },

  /**
   * GET /api/v1/auth/export (Privacy & GDPR compliance)
   */
  async exportData(req, res) {
    const data = await authRepository.exportUserData(req.user.id);
    sendJson(res, 200, data);
  },

  /**
   * DELETE /api/v1/auth/account (Self-service account deletion)
   */
  async deleteAccount(req, res) {
    await authRepository.deleteUserAccount(req.user.id);
    sendJson(res, 200, {
      message: 'Your account and all associated financial data have been permanently deleted.',
    });
  },
};
