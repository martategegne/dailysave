/**
 * DailySave Production Deployment Verification Suite
 * Validates backend health, database connectivity, migration state,
 * static website assets, and privacy guardrails.
 */

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { createRequire } from 'node:module';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');
const require = createRequire(path.join(ROOT_DIR, 'backend', 'package.json'));
const pg = require('pg');

const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = parseInt(process.env.DB_PORT || '5432', 10);
const DB_NAME = process.env.DB_NAME || 'dailysave_db';
const DB_USER = process.env.DB_USER || 'postgres';
const DB_PASSWORD = process.env.DB_PASSWORD || 'postgres';
const API_PORT = parseInt(process.env.PORT || '4000', 10);

const results = [];

function recordResult(checkName, passed, details = '') {
  results.push({ checkName, passed, details });
  const symbol = passed ? '✔ PASS' : '✖ FAIL';
  console.log(`[${symbol}] ${checkName} ${details ? '(' + details + ')' : ''}`);
}

async function verifyDatabase() {
  const pool = new pg.Pool({
    host: DB_HOST,
    port: DB_PORT,
    database: DB_NAME,
    user: DB_USER,
    password: DB_PASSWORD,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  });

  try {
    const res = await pool.query('SELECT NOW() as current_time, current_database() as db;');
    recordResult('Database Connectivity', true, `Connected to ${res.rows[0].db} at ${res.rows[0].current_time}`);

    const migrations = await pool.query('SELECT id, migration_name FROM schema_migrations ORDER BY id ASC;');
    recordResult('Schema Migrations', migrations.rows.length >= 6, `${migrations.rows.length} versioned migrations active`);

    const tables = await pool.query(
      `SELECT count(*)::int as count FROM information_schema.tables WHERE table_schema = 'public';`
    );
    recordResult('Table Verification', tables.rows[0].count >= 16, `${tables.rows[0].count} public domain tables present`);
  } catch (err) {
    recordResult('Database Connectivity', false, err.message);
  } finally {
    await pool.end();
  }
}

async function verifyHttpHealthCheck() {
  const serverModuleUrl = pathToFileURL(path.join(ROOT_DIR, 'backend', 'src', 'server.js')).href;
  const { startServer, stopServer } = await import(serverModuleUrl);
  let serverInstance = null;
  const testPort = 4099;

  try {
    serverInstance = await startServer(testPort);

    await new Promise((resolve) => {
      const req = http.get(`http://localhost:${testPort}/health`, (res) => {
        let body = '';
        res.on('data', (c) => (body += c));
        res.on('end', () => {
          try {
            const json = JSON.parse(body);
            const data = json.data || json;
            const passed = res.statusCode === 200 && data.status === 'ok';
            recordResult('HTTP Health Check: /health', passed, `Status ${res.statusCode}, Service: ${data.service}`);
          } catch {
            recordResult('HTTP Health Check: /health', false, 'Invalid JSON body');
          }
          resolve();
        });
      });
      req.on('error', (err) => {
        recordResult('HTTP Health Check: /health', false, err.message);
        resolve();
      });
    });
  } catch (err) {
    recordResult('HTTP Server Spin-up', false, err.message);
  } finally {
    if (serverInstance) {
      await stopServer(serverInstance);
    }
  }
}

function verifyWebsiteStaticAssets() {
  const websiteDir = path.join(ROOT_DIR, 'website');
  const requiredFiles = [
    'index.html',
    'about.html',
    'features.html',
    'personal-finance.html',
    'student-finance.html',
    'family-finance.html',
    'business-finance.html',
    'community-savings.html',
    'pricing.html',
    'faq.html',
    'help.html',
    'contact.html',
    'privacy.html',
    'terms.html',
    'sitemap.xml',
    'robots.txt',
    'css/styles.css',
    'js/site.js',
    'blog/managing-daily-expenses-in-ethiopia.html',
    'blog/equb-guide-community-savings.html',
    'blog/student-budgeting-ethiopian-birr.html',
  ];

  let allExist = true;
  for (const file of requiredFiles) {
    const filePath = path.join(websiteDir, file);
    if (!fs.existsSync(filePath)) {
      allExist = false;
      recordResult(`Static File Check: ${file}`, false, 'Missing');
    }
  }

  if (allExist) {
    recordResult('Static Marketing Website Integrity', true, `All ${requiredFiles.length} pages and assets verified`);
  }
}

function verifyWebRobotsGuardrail() {
  const appRobotsPath = path.join(ROOT_DIR, 'web', 'robots.txt');
  if (fs.existsSync(appRobotsPath)) {
    const content = fs.readFileSync(appRobotsPath, 'utf8');
    const isProtected = content.includes('Disallow: /');
    recordResult('App Dashboard Privacy Guardrail (noindex)', isProtected, 'Disallow: / verified in web/robots.txt');
  } else {
    recordResult('App Dashboard Privacy Guardrail (noindex)', false, 'web/robots.txt missing');
  }
}

async function run() {
  console.log('====================================================');
  console.log('DailySave Production Deployment Verification Suite');
  console.log('====================================================\n');

  verifyWebsiteStaticAssets();
  verifyWebRobotsGuardrail();
  await verifyDatabase();
  await verifyHttpHealthCheck();

  console.log('\n====================================================');
  const total = results.length;
  const passed = results.filter((r) => r.passed).length;
  const failed = total - passed;
  console.log(`Summary: ${passed}/${total} Passed (${failed} Failed)`);
  console.log('====================================================');

  if (failed > 0) {
    process.exit(1);
  }
}

run();
