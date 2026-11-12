import test from 'node:test';
import assert from 'node:assert';
import http from 'node:http';
import { Router } from '../src/core/router.js';
import { sendJson } from '../src/core/response.js';
import { validateSchema, validator, ValidationError } from '../src/core/validator.js';

test('Native Router: Correctly matches static and parametric routes', async () => {
  const router = new Router();

  router.get('/api/v1/health', (req, res) => {
    sendJson(res, 200, { status: 'healthy' });
  });

  router.get('/api/v1/transactions/:id', (req, res) => {
    sendJson(res, 200, { transactionId: req.params.id });
  });

  const server = http.createServer((req, res) => router.handle(req, res));
  await new Promise((resolve) => server.listen(0, resolve));
  const port = server.address().port;

  try {
    // 1. Test Static Route
    const res1 = await fetch(`http://localhost:${port}/api/v1/health`);
    assert.strictEqual(res1.status, 200);
    const body1 = await res1.json();
    assert.strictEqual(body1.data.status, 'healthy');

    // 2. Test Parametric Route
    const res2 = await fetch(`http://localhost:${port}/api/v1/transactions/tx_abc_123`);
    assert.strictEqual(res2.status, 200);
    const body2 = await res2.json();
    assert.strictEqual(body2.data.transactionId, 'tx_abc_123');

    // 3. Test 404 Route
    const res3 = await fetch(`http://localhost:${port}/api/v1/nonexistent`);
    assert.strictEqual(res3.status, 404);
  } finally {
    server.close();
  }
});

test('Native Validator: Validates input schema correctly', () => {
  const schema = {
    email: {
      required: true,
      validator: validator.isEmail,
      message: 'Valid email is required',
    },
    amount: {
      required: true,
      validator: validator.isPositiveInteger,
      message: 'Positive integer amount is required',
    },
  };

  // Valid Data
  assert.doesNotThrow(() => {
    validateSchema({ email: 'test@dailysave.et', amount: 5000 }, schema);
  });

  // Invalid Data
  assert.throws(
    () => {
      validateSchema({ email: 'invalid-email', amount: -100 }, schema);
    },
    (err) => Boolean(err instanceof ValidationError && err.errors.email && err.errors.amount)
  );
});
