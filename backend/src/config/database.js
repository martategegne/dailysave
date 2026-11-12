import pg from 'pg';
import { env } from './env.js';

const { Pool } = pg;

export const pool = new Pool({
  host: env.database.host,
  port: env.database.port,
  database: env.database.database,
  user: env.database.user,
  password: env.database.password,
  ssl: env.database.ssl ? { rejectUnauthorized: false } : false,
  max: env.database.maxConnections,
  idleTimeoutMillis: env.database.idleTimeoutMs,
  connectionTimeoutMillis: env.database.connectionTimeoutMs,
});

pool.on('error', (err) => {
  console.error('[PostgreSQL Pool Unexpected Error]:', err);
});

/**
 * Executes a parameterized SQL query safely against the connection pool.
 * Parameterized queries ($1, $2, etc.) prevent SQL injection.
 * 
 * @param {string} text - SQL query text with parameter placeholders
 * @param {Array<any>} [params] - Query parameter values
 * @returns {Promise<pg.QueryResult>}
 */
export async function query(text, params = []) {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    if (env.server.nodeEnv === 'development' && duration > 200) {
      console.warn(`[Slow Query Alert] (${duration}ms):`, text.replace(/\s+/g, ' ').trim());
    }
    return res;
  } catch (error) {
    console.error('[Database Query Error]:', {
      query: text.replace(/\s+/g, ' ').trim(),
      message: error.message,
    });
    throw error;
  }
}

/**
 * Executes a callback within a managed ACID database transaction.
 * Automatically issues 'BEGIN', commits on success, or rolls back on any error.
 * 
 * @template T
 * @param {(client: pg.PoolClient) => Promise<T>} callback
 * @returns {Promise<T>}
 */
export async function withTransaction(callback) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Performs an active connection health-check.
 * @returns {Promise<{ ok: boolean, version?: string, error?: string }>}
 */
export async function testConnection() {
  try {
    const res = await pool.query('SELECT version();');
    return { ok: true, version: res.rows[0].version };
  } catch (error) {
    return { ok: false, error: error.message };
  }
}

/**
 * Gracefully terminates all pool connections on application shutdown.
 */
export async function closePool() {
  await pool.end();
}
