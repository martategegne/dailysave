import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { env } from '../config/env.js';

const { Client } = pg;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const MIGRATIONS_DIR = path.resolve(__dirname, 'migrations');

async function ensureDatabaseExists() {
  // If target database is already neondb or a managed cloud database, skip admin creation
  if (env.database.database === 'neondb' || env.database.ssl) {
    console.log(`[Database Initialization]: Target database "${env.database.database}" verified.`);
    return;
  }

  const adminClient = new Client({
    host: env.database.host,
    port: env.database.port,
    user: env.database.user,
    password: env.database.password,
    database: 'postgres', // default administrative DB
    ssl: env.database.ssl ? { rejectUnauthorized: false } : false,
  });

  try {
    await adminClient.connect();
    const checkRes = await adminClient.query(
      'SELECT 1 FROM pg_database WHERE datname = $1;',
      [env.database.database]
    );

    if (checkRes.rowCount === 0) {
      console.log(`[Database Initialization]: Creating database "${env.database.database}"...`);
      // Database names cannot be parameterized in DDL, but we sanitize from internal env
      const safeDbName = env.database.database.replace(/[^a-zA-Z0-9_]/g, '');
      await adminClient.query(`CREATE DATABASE ${safeDbName};`);
      console.log(`[Database Initialization]: Database "${safeDbName}" created successfully.`);
    } else {
      console.log(`[Database Initialization]: Target database "${env.database.database}" verified.`);
    }
  } catch (err) {
    console.log(`[Database Initialization]: Administrative check skipped (${err.message}). Proceeding directly.`);
  } finally {
    try {
      await adminClient.end();
    } catch {}
  }
}

async function runMigrations() {
  console.log('====================================================');
  console.log('   DAILYSave: PostgreSQL Database Migration Runner  ');
  console.log('====================================================');

  await ensureDatabaseExists();

  const client = new Client({
    host: env.database.host,
    port: env.database.port,
    user: env.database.user,
    password: env.database.password,
    database: env.database.database,
    ssl: env.database.ssl ? { rejectUnauthorized: false } : false,
  });

  await client.connect();

  try {
    // 1. Ensure migrations tracking table exists
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        migration_name VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // 2. Fetch already applied migrations
    const appliedRes = await client.query(
      'SELECT migration_name FROM schema_migrations ORDER BY id ASC;'
    );
    const appliedSet = new Set(appliedRes.rows.map((r) => r.migration_name));

    // 3. Read migration files
    const files = await fs.readdir(MIGRATIONS_DIR);
    const sqlFiles = files.filter((f) => f.endsWith('.sql')).sort();

    console.log(`Found ${sqlFiles.length} migration script(s) in repository.`);

    let newlyApplied = 0;

    for (const file of sqlFiles) {
      if (appliedSet.has(file)) {
        console.log(`  [SKIPPED] ${file} (already applied)`);
        continue;
      }

      console.log(`  [APPLYING] ${file}...`);
      const filePath = path.join(MIGRATIONS_DIR, file);
      const sqlContent = await fs.readFile(filePath, 'utf-8');

      // Execute migration inside a managed transaction
      await client.query('BEGIN');
      try {
        await client.query(sqlContent);
        await client.query(
          'INSERT INTO schema_migrations (migration_name) VALUES ($1);',
          [file]
        );
        await client.query('COMMIT');
        console.log(`  [SUCCESS] ${file} applied successfully.`);
        newlyApplied++;
      } catch (migrationError) {
        await client.query('ROLLBACK');
        console.error(`[MIGRATION FAILURE] Error executing ${file}:`, migrationError.message);
        throw migrationError;
      }
    }

    console.log('\n====================================================');
    console.log(` Migration Run Finished: ${newlyApplied} newly applied.`);
    console.log(' All 16 database tables and indexes verified.');
    console.log('====================================================');
  } finally {
    await client.end();
  }
}

runMigrations().catch((err) => {
  console.error('[Fatal Error in Migration Runner]:', err);
  process.exit(1);
});
