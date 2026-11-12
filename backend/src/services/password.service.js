import argon2 from 'argon2';

/**
 * Service for Argon2id cryptographic password hashing and verification.
 * Adheres strictly to OWASP cryptographic storage standards.
 */
export const passwordService = {
  /**
   * Hashes a plaintext password using Argon2id.
   * @param {string} plainPassword
   * @returns {Promise<string>}
   */
  async hash(plainPassword) {
    return argon2.hash(plainPassword, {
      type: argon2.argon2id,
      memoryCost: 65536, // 64 MB memory requirement
      timeCost: 3,       // 3 iterations
      parallelism: 1,
    });
  },

  /**
   * Verifies a plaintext password against an Argon2id hash.
   * @param {string} hash
   * @param {string} plainPassword
   * @returns {Promise<boolean>}
   */
  async verify(hash, plainPassword) {
    try {
      return await argon2.verify(hash, plainPassword);
    } catch (err) {
      return false;
    }
  },
};
