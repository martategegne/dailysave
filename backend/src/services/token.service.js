import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

export const tokenService = {
  /**
   * Hashes a raw token string using SHA-256 for secure storage.
   * Prevents raw token exposure if database tables are ever leaked.
   * @param {string} token
   * @returns {string}
   */
  hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
  },

  /**
   * Generates a short-lived access token and a cryptographically random refresh token.
   * @param {{ id: string, email: string }} user
   * @returns {{ accessToken: string, refreshToken: string, expiresIn: number }}
   */
  generateTokens(user) {
    const payload = {
      sub: user.id,
      email: user.email,
    };

    const accessToken = jwt.sign(payload, env.security.jwtAccessSecret, {
      expiresIn: env.security.jwtAccessExpiresIn,
    });

    // Generate 64-byte cryptographically secure random token string
    const rawRefreshToken = crypto.randomBytes(48).toString('base64url');

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      expiresIn: env.security.jwtAccessExpiresIn,
    };
  },

  /**
   * Verifies an access token and returns decoded payload.
   * @param {string} token
   * @returns {{ sub: string, email: string }}
   */
  verifyAccessToken(token) {
    return jwt.verify(token, env.security.jwtAccessSecret);
  },
};
