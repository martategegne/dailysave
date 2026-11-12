import dotenv from 'dotenv';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Explicitly resolve the root .env file
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

function getEnvString(key, defaultValue) {
  const value = process.env[key] ?? defaultValue;
  if (value === undefined) {
    throw new Error(`[Configuration Error]: Missing required environment variable "${key}"`);
  }
  return value.trim();
}

function getEnvNumber(key, defaultValue) {
  const raw = process.env[key];
  if (raw === undefined && defaultValue !== undefined) {
    return defaultValue;
  }
  const parsed = Number.parseInt(raw, 10);
  if (Number.isNaN(parsed)) {
    throw new Error(
      `[Configuration Error]: Environment variable "${key}" must be an integer, received: "${raw}"`
    );
  }
  return parsed;
}

function getEnvBoolean(key, defaultValue = false) {
  const raw = process.env[key];
  if (raw === undefined) return defaultValue;
  return raw.toLowerCase() === 'true' || raw === '1';
}

function getEnvArray(key, defaultValue = []) {
  const raw = process.env[key];
  if (!raw) return defaultValue;
  return raw.split(',').map((item) => item.trim()).filter(Boolean);
}

export const env = Object.freeze({
  server: {
    port: getEnvNumber('PORT', 4000),
    nodeEnv: getEnvString('NODE_ENV', 'development'),
    apiPrefix: getEnvString('API_PREFIX', '/api/v1'),
    isProduction: getEnvString('NODE_ENV', 'development') === 'production',
  },
  database: {
    host: getEnvString('DB_HOST', 'localhost'),
    port: getEnvNumber('DB_PORT', 5432),
    database: getEnvString('DB_NAME', 'dailysave_db'),
    user: getEnvString('DB_USER', 'postgres'),
    password: getEnvString('DB_PASSWORD', 'postgres'),
    ssl: getEnvBoolean('DB_SSL', false),
    maxConnections: getEnvNumber('DB_MAX_CONNECTIONS', 20),
    idleTimeoutMs: getEnvNumber('DB_IDLE_TIMEOUT_MS', 30000),
    connectionTimeoutMs: getEnvNumber('DB_CONNECTION_TIMEOUT_MS', 5000),
  },
  security: {
    jwtAccessSecret: getEnvString(
      'JWT_ACCESS_SECRET',
      'dailysave_dev_jwt_access_super_secret_key_change_in_production_987654321'
    ),
    jwtRefreshSecret: getEnvString(
      'JWT_REFRESH_SECRET',
      'dailysave_dev_jwt_refresh_super_secret_key_change_in_production_123456789'
    ),
    jwtAccessExpiresIn: getEnvNumber('JWT_ACCESS_EXPIRES_IN', 900), // 15 minutes (seconds)
    jwtRefreshExpiresIn: getEnvNumber('JWT_REFRESH_EXPIRES_IN', 2592000), // 30 days (seconds)
  },
  cors: {
    allowedOrigins: getEnvArray('ALLOWED_ORIGINS', [
      'http://localhost:3000',
      'http://localhost:8080',
      'http://127.0.0.1:8080',
      'http://localhost:5000',
    ]),
  },
  rateLimit: {
    windowMs: getEnvNumber('RATE_LIMIT_WINDOW_MS', 15 * 60 * 1000), // 15 mins
    maxRequests: getEnvNumber('RATE_LIMIT_MAX_REQUESTS', 100),
  },
});
