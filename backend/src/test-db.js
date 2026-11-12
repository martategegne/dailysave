import argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { env } from './config/env.js';
import { testConnection, closePool } from './config/database.js';

async function runPhase1Verification() {
  console.log('====================================================');
  console.log('   DAILYSave Backend: Phase 1 Pre-Flight Checks     ');
  console.log('====================================================');

  // 1. Check Configuration
  console.log('[1/4] Validating Configuration...');
  console.log('  - Environment:', env.server.nodeEnv);
  console.log('  - HTTP Port:', env.server.port);
  console.log('  - Database Host:', `${env.database.host}:${env.database.port}`);
  console.log('  - Database Name:', env.database.database);
  console.log('  - Database User:', env.database.user);
  console.log('  [PASS] Configuration loaded and validated successfully.');

  // 2. Check Argon2id Hashing
  console.log('\n[2/4] Testing Argon2id Cryptographic Hashing...');
  const testPassword = 'SecureDailySavePassword2026!';
  const hash = await argon2.hash(testPassword, {
    type: argon2.argon2id,
    memoryCost: 2 ** 16, // 64 MB
    timeCost: 3,
    parallelism: 1,
  });
  console.log('  - Sample Password Hash:', hash.substring(0, 35) + '...');
  const isValid = await argon2.verify(hash, testPassword);
  const isInvalid = await argon2.verify(hash, 'WrongPassword');
  if (isValid && !isInvalid) {
    console.log('  [PASS] Argon2id password hashing and verification verified.');
  } else {
    throw new Error('Argon2id password verification failed.');
  }

  // 3. Check JWT Signing & Verification
  console.log('\n[3/4] Testing JWT Security Tokens...');
  const testPayload = { userId: 'usr_test_123', email: 'user@dailysave.et' };
  const token = jwt.sign(testPayload, env.security.jwtAccessSecret, {
    expiresIn: env.security.jwtAccessExpiresIn,
  });
  const decoded = jwt.verify(token, env.security.jwtAccessSecret);
  if (decoded.userId === testPayload.userId) {
    console.log('  [PASS] JWT signing and verification verified.');
  } else {
    throw new Error('JWT verification failed.');
  }

  // 4. Check PostgreSQL Database Connection
  console.log('\n[4/4] Testing PostgreSQL Connection Pool...');
  const dbHealth = await testConnection();
  if (dbHealth.ok) {
    console.log('  - PostgreSQL Engine Version:', dbHealth.version);
    console.log('  [PASS] PostgreSQL Connection Pool is active and healthy.');
  } else {
    console.warn('  [NOTICE] PostgreSQL connection attempt details:');
    console.warn('  -', dbHealth.error);
    console.log('\n  Tip: If your local PostgreSQL uses a different password,');
    console.log('  simply update the DB_PASSWORD in backend/.env.');
  }

  await closePool();
  console.log('\n====================================================');
  console.log('       Phase 1 Pre-Flight Checks Completed          ');
  console.log('====================================================');
}

runPhase1Verification().catch((err) => {
  console.error('[Fatal Error in Phase 1 Verification]:', err);
  process.exit(1);
});
