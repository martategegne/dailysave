/**
 * Asynchronous stream body parser with strict size limits to prevent DoS memory exhaustion.
 */

const MAX_BODY_BYTES = 1024 * 1024; // 1 Megabyte maximum payload

export class BodyParserError extends Error {
  constructor(message, statusCode = 400) {
    super(message);
    this.name = 'BodyParserError';
    this.statusCode = statusCode;
  }
}

/**
 * Reads and parses the JSON request body stream.
 * @param {import('node:http').IncomingMessage} req
 * @returns {Promise<any>}
 */
export async function parseJsonBody(req) {
  // If method has no body, return empty object
  if (req.method === 'GET' || req.method === 'HEAD' || req.method === 'OPTIONS') {
    return {};
  }

  const contentType = req.headers['content-type'] || '';
  if (!contentType.includes('application/json')) {
    // If empty body sent with no content type
    if (!req.headers['content-length'] || req.headers['content-length'] === '0') {
      return {};
    }
  }

  return new Promise((resolve, reject) => {
    const chunks = [];
    let receivedBytes = 0;

    req.on('data', (chunk) => {
      receivedBytes += chunk.length;
      if (receivedBytes > MAX_BODY_BYTES) {
        req.destroy(); // Terminate abusive stream
        return reject(
          new BodyParserError('Payload too large. Maximum allowed size is 1MB.', 413)
        );
      }
      chunks.push(chunk);
    });

    req.on('end', () => {
      if (chunks.length === 0) {
        return resolve({});
      }

      const bodyString = Buffer.concat(chunks).toString('utf-8').trim();
      if (!bodyString) {
        return resolve({});
      }

      try {
        const parsed = JSON.parse(bodyString);
        resolve(parsed);
      } catch (err) {
        reject(
          new BodyParserError('Malformed JSON payload. Please verify syntax.', 400)
        );
      }
    });

    req.on('error', (err) => {
      reject(new BodyParserError(`Stream transmission error: ${err.message}`, 500));
    });
  });
}
