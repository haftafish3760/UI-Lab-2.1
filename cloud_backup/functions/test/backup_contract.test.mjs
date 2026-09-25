import test from 'node:test';
import assert from 'node:assert/strict';
import { BackupError, bytes, counters, digest, recognitionSubject, token, uploadSpec } from '../backup_contract.mjs';
import { backupRequestHandler } from '../backup_request_handler.mjs';

test('hostile byte counts and path identities cannot reach persistence', () => {
  for (const value of [NaN, Infinity, -1, 0, 1.5, '25', null, 2 ** 53]) assert.throws(() => bytes(value), BackupError);
  for (const value of ['../other', 'a/b', '', 'a'.repeat(81), null]) assert.throws(() => token(value), BackupError);
  assert.throws(() => uploadSpec({ byteCount: 2, sha256: digest('ab'), contentType: 'text/html' }), BackupError);
  assert.throws(() => counters({ grantedBytes: 10, usedBytes: 9, reservedBytes: 2, openAttempts: 1 }), BackupError);
});

test('recognition keys are purpose-keyed pseudonyms, not raw device evidence', () => {
  const key = Buffer.alloc(32, 7);
  const value = recognitionSubject(key, 'reviewed', 'synthetic-enrollment');
  assert.match(value, /^[a-f0-9]{64}$/);
  assert.equal(value, recognitionSubject(key, 'reviewed', 'synthetic-enrollment'));
  assert.notEqual(value, recognitionSubject(Buffer.alloc(32, 8), 'reviewed', 'synthetic-enrollment'));
  assert.throws(() => recognitionSubject(Buffer.alloc(1), 'reviewed', 'subject'), BackupError);
});

function response() {
  return { code: 200, headers: {}, set(k, v) { this.headers[k] = v; return this; },
    status(code) { this.code = code; return this; }, json(value) { this.body = value; return this; } };
}
const request = () => ({ method: 'POST', path: '/usage', rawBody: Buffer.from('{}'),
  body: { companyId: 'company' }, is: () => true, get: () => undefined });

test('disabled rollout and failed authentication never call the ledger', async () => {
  let calls = 0;
  const ledger = { usage: () => { calls++; } };
  let res = response();
  await backupRequestHandler({ enabled: () => false, ledger })(request(), res);
  assert.equal(res.code, 503);
  res = response();
  await backupRequestHandler({ enabled: () => true, ledger,
    authenticate: async () => { throw new BackupError(401, 'authentication_required'); } })(request(), res);
  assert.equal(res.code, 401);
  assert.equal(calls, 0);
});

test('raw provider errors and secrets are not returned in responses', async () => {
  const res = response();
  await backupRequestHandler({ enabled: () => true,
    authenticate: async () => { throw new Error('private-token-and-receipt-content'); } })(request(), res);
  assert.deepEqual(res.body, { error: 'backup_temporarily_unavailable' });
});

test('unknown routes and oversized control requests fail before authentication', async () => {
  let calls = 0;
  const handler = backupRequestHandler({ enabled: () => true, authenticate: () => { calls++; } });
  for (const req of [{ ...request(), path: '/setAllowance' }, { ...request(), rawBody: Buffer.alloc(4097) }]) {
    const res = response();
    await handler(req, res);
    assert.ok([404, 413].includes(res.code));
  }
  assert.equal(calls, 0);
});
