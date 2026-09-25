import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { BackupObjectStore } from '../backup_object_store.mjs';
import { digest } from '../backup_contract.mjs';

// SDK contract double, NOT evidence of Cloud Storage/emulator preconditions.
// Enforces expected create-only arguments and preserves the winning object.
function fixture() {
  const body = Buffer.from('synthetic receipt bytes');
  let saved, generation = 0, charges = 0, refunds = 0;
  let attempt = { state: 'uploading', uid: 'user', companyId: 'company', attemptId: 'attempt',
    byteCount: body.length, sha256: digest(body), contentType: 'image/jpeg' };
  const file = {
    async save(bytes, options) {
      assert.equal(options.preconditionOpts.ifGenerationMatch, 0);
      assert.equal(options.resumable, false);
      if (saved) throw Object.assign(new Error('exists'), { code: 412 });
      saved = { body: bytes, metadata: { ...options.metadata, size: String(bytes.length),
        generation: String(++generation), md5Hash: createHash('md5').update(bytes).digest('base64') } };
    },
    async getMetadata() { return [saved.metadata]; },
    async download() { return [saved.body]; },
  };
  const ledger = {
    async ownedAttempt() { return attempt; },
    async beginUpload() { return attempt; },
    async commitVerifiedUpload() { charges++; attempt = { ...attempt, state: 'committed' }; return attempt; },
    async cancelWithVerifiedTombstone() { refunds++; attempt = { ...attempt, state: 'cancelled' }; return attempt; },
  };
  const store = new BackupObjectStore({ file: () => file }, ledger, { allowInFlightCancellation: true });
  return { body, file, store, charges: () => charges, refunds: () => refunds };
}

test('verified create-only cancellation prevents a delayed object write', async () => {
  const f = fixture();
  assert.equal((await f.store.cancel({ uid: 'user' }, 'company', 'attempt')).state, 'cancelled');
  assert.equal(f.refunds(), 1); assert.equal(f.charges(), 0);
  await assert.rejects(f.file.save(f.body, { resumable: false, preconditionOpts: { ifGenerationMatch: 0 } }),
    error => error.code === 412);
  assert.equal((await f.file.getMetadata())[0].size, '0');
});

test('if data wins cancellation race, preserve it and charge rather than refund', async () => {
  const f = fixture();
  await f.file.save(f.body, { resumable: false, preconditionOpts: { ifGenerationMatch: 0 },
    metadata: { contentType: 'image/jpeg', metadata: { companyId: 'company', attemptId: 'attempt', sha256: digest(f.body) } } });
  assert.equal((await f.store.cancel({ uid: 'user' }, 'company', 'attempt')).state, 'committed');
  assert.equal(f.charges(), 1); assert.equal(f.refunds(), 0);
  assert.deepEqual((await f.file.download())[0], f.body);
});
