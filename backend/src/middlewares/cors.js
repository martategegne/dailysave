import { env } from '../config/env.js';

const ALLOWED_METHODS = 'GET, POST, PATCH, PUT, DELETE, OPTIONS';
const ALLOWED_HEADERS = 'Content-Type, Authorization, X-Requested-With, X-Idempotency-Key';

/**
 * Handles Cross-Origin Resource Sharing (CORS) for web clients like Flutter Web.
 * 
 * @param {import('node:http').IncomingMessage} req
 * @param {import('node:http').ServerResponse} res
 * @returns {boolean} Returns true if request was handled (e.g. OPTIONS preflight), false to continue.
 */
export function handleCors(req, res) {
  const origin = req.headers.origin;

  // In development, allow localhost/file/web origins; in production, check whitelist
  if (origin) {
    if (!env.server.isProduction || env.cors.allowedOrigins.includes(origin)) {
      res.setHeader('Access-Control-Allow-Origin', origin);
      res.setHeader('Access-Control-Allow-Methods', ALLOWED_METHODS);
      res.setHeader('Access-Control-Allow-Headers', ALLOWED_HEADERS);
      res.setHeader('Access-Control-Allow-Credentials', 'true');
      res.setHeader('Access-Control-Max-Age', '86400'); // 24 hours preflight cache
    }
  }

  // Handle pre-flight request
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return true;
  }

  return false;
}
