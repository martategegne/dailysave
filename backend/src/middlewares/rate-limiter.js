import { env } from '../config/env.js';
import { sendError } from '../core/response.js';

class SlidingWindowRateLimiter {
  constructor(windowMs = 15 * 60 * 1000, maxRequests = 100) {
    this.windowMs = windowMs;
    this.maxRequests = maxRequests;
    this.hits = new Map(); // ip -> array of request timestamps

    // Garbage collection every 5 minutes to prevent memory leaks
    setInterval(() => this.cleanup(), 5 * 60 * 1000).unref();
  }

  cleanup() {
    const now = Date.now();
    const threshold = now - this.windowMs;
    for (const [ip, timestamps] of this.hits.entries()) {
      const active = timestamps.filter((t) => t > threshold);
      if (active.length === 0) {
        this.hits.delete(ip);
      } else {
        this.hits.set(ip, active);
      }
    }
  }

  /**
   * Evaluates request against rate limit thresholds.
   * @param {import('node:http').IncomingMessage} req
   * @param {import('node:http').ServerResponse} res
   * @returns {boolean} Returns true if request is blocked, false if permitted.
   */
  checkLimit(req, res) {
    const ip =
      req.headers['x-forwarded-for']?.split(',')[0].trim() ||
      req.socket.remoteAddress ||
      'unknown';

    const now = Date.now();
    const windowStart = now - this.windowMs;

    const timestamps = this.hits.get(ip) || [];
    const recent = timestamps.filter((t) => t > windowStart);

    if (recent.length >= this.maxRequests) {
      const oldest = recent[0];
      const resetTimeSeconds = Math.ceil((oldest + this.windowMs - now) / 1000);

      res.setHeader('Retry-After', resetTimeSeconds);
      res.setHeader('X-RateLimit-Limit', this.maxRequests);
      res.setHeader('X-RateLimit-Remaining', 0);
      res.setHeader('X-RateLimit-Reset', resetTimeSeconds);

      sendError(
        res,
        429,
        'Too many requests from this IP. Please wait before retrying.',
        { retryAfterSeconds: resetTimeSeconds }
      );
      return true; // Blocked
    }

    recent.push(now);
    this.hits.set(ip, recent);

    res.setHeader('X-RateLimit-Limit', this.maxRequests);
    res.setHeader('X-RateLimit-Remaining', Math.max(0, this.maxRequests - recent.length));
    return false; // Permitted
  }
}

export const rateLimiter = new SlidingWindowRateLimiter(
  env.rateLimit.windowMs,
  env.rateLimit.maxRequests
);
