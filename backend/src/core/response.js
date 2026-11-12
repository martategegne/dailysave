/**
 * Standardized HTTP response helpers and security header enforcer.
 */

const DEFAULT_SECURITY_HEADERS = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'Content-Type': 'application/json; charset=utf-8',
};

/**
 * Sends a successful JSON response.
 * @param {import('node:http').ServerResponse} res
 * @param {number} statusCode
 * @param {any} data
 * @param {Record<string, string>} [extraHeaders]
 */
export function sendJson(res, statusCode, data, extraHeaders = {}) {
  const payload = JSON.stringify({
    success: true,
    data,
    timestamp: new Date().toISOString(),
  });

  res.writeHead(statusCode, {
    ...DEFAULT_SECURITY_HEADERS,
    ...extraHeaders,
    'Content-Length': Buffer.byteLength(payload),
  });
  res.end(payload);
}

/**
 * Sends a structured error response.
 * @param {import('node:http').ServerResponse} res
 * @param {number} statusCode
 * @param {string} message
 * @param {any} [details=null]
 * @param {Record<string, string>} [extraHeaders]
 */
export function sendError(res, statusCode, message, details = null, extraHeaders = {}) {
  const payload = JSON.stringify({
    success: false,
    error: {
      code: statusCode,
      message,
      details,
    },
    timestamp: new Date().toISOString(),
  });

  res.writeHead(statusCode, {
    ...DEFAULT_SECURITY_HEADERS,
    ...extraHeaders,
    'Content-Length': Buffer.byteLength(payload),
  });
  res.end(payload);
}
