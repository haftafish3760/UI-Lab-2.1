import test, { after } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { BackupAllowanceLedger } from '../backup_allowance_ledger.mjs';
import { BackupObjectStore } from '../backup_object_store.mjs';
import { digest } from '../backup_contract.mjs';

// Refuse production before constructing an Admin client, even if credentials
// happen to exist on this machine. Only synthetic data in the demo emulators.
if (!/^127\.0\.0\.1:\d+$/.test(process.env.FIRESTORE_EMULATOR_HOST ?? '') ||
    !/^127\.0\.0\.1:\d+$/.test(process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '')) {
  throw new Error('Both loopback emulators are required. No cloud fallback.');
}
const projectId = 'demo-ui-lab-backup';
const app = initializeApp({ projectId, storageBucket: `${projectId}.appspot.com` });
const db = getFirestore(app), bucket = getStorage(app).bucket();
const ledger = new BackupAllowanceLedger(db);
const objects = new BackupObjectStore(bucket, ledger);
after(async () => { await db.terminate(); await deleteApp(app); });
const errorCode = code => error => error.code === code;
const spec = body => ({ byteCount: body.length, contentType: 'image/jpeg', sha256: digest(body) });

async function fixture(allowance = 100) {
  const companyId = randomUUID(), actor = { uid: randomUUID(), email_verified: true };
  const root = db.doc(`backupWorkspaces/${companyId}`);
  await root.set({ active: true });
  await root.collection('members').doc(digest(actor.uid)).set({ active: true,
    canUploadBackup: true, canReadBackup: true, canManageBackup: true });
  await root.collection('allowance').doc('current').set({ grantedBytes: allowance,
    usedBytes: 0, reservedBytes: 0, openAttempts: 0 });
  return { companyId, actor, root };
}
async function approval(f, subjectKey = digest(randomUUID()), kind = 'trial') {
  const id = randomUUID();
  await db.doc(`backupApprovals/${id}`).set({ companyId: f.companyId, uid: f.actor.uid,
    approved: true, subjectKey, kind, bytes: 25, policyVersion: 'synthetic-test', expiresAt: Date.now() + 60_000 });
  return id;
}

test('concurrent uploads cannot overspend a shared business allowance', async () => {
  const f = await fixture(100), body = Buffer.alloc(60);
  const results = await Promise.allSettled(['one', 'two'].map(id => ledger.reserve(f.actor, f.companyId, id, spec(body))));
  assert.equal(results.filter(r => r.status === 'fulfilled').length, 1);
  assert.equal(results.find(r => r.status === 'rejected').reason.code, 'backup_allowance_exhausted');
  assert.equal((await ledger.usage(f.actor, f.companyId)).reservedBytes, 60);
});

test('same-attempt retries reserve once, while payload changes are rejected', async () => {
  const f = await fixture(), body = Buffer.alloc(30);
  await Promise.all(Array.from({ length: 6 }, () => ledger.reserve(f.actor, f.companyId, 'same', spec(body))));
  assert.equal((await ledger.usage(f.actor, f.companyId)).reservedBytes, 30);
  await assert.rejects(ledger.reserve(f.actor, f.companyId, 'same', spec(Buffer.alloc(31))), errorCode('attempt_payload_conflict'));
});

test('actual stored bytes are charged once and remain downloadable when quota is exhausted', async () => {
  const f = await fixture(40), body = Buffer.alloc(40, 7);
  await ledger.reserve(f.actor, f.companyId, 'photo', spec(body));
  await objects.upload(f.actor, f.companyId, 'photo', 'image/jpeg', body);
  await objects.upload(f.actor, f.companyId, 'photo', 'image/jpeg', body);
  const usage = await ledger.usage(f.actor, f.companyId);
  assert.equal(usage.usedBytes, 40); assert.equal(usage.reservedBytes, 0);
  assert.equal(usage.remainingBytes, 0);
  assert.deepEqual((await objects.download(f.actor, f.companyId, 'photo')).body, body);
  await assert.rejects(ledger.reserve(f.actor, f.companyId, 'extra', spec(Buffer.from('x'))), errorCode('backup_allowance_exhausted'));
});

test('pending cancellation refunds a reservation but never a completed upload', async () => {
  const f = await fixture(), body = Buffer.alloc(20);
  await ledger.reserve(f.actor, f.companyId, 'pending', spec(body));
  await objects.cancel(f.actor, f.companyId, 'pending');
  await objects.cancel(f.actor, f.companyId, 'pending');
  assert.equal((await ledger.usage(f.actor, f.companyId)).remainingBytes, 100);
  await assert.rejects(objects.upload(f.actor, f.companyId, 'pending', 'image/jpeg', body), errorCode('attempt_cancelled'));
  await ledger.reserve(f.actor, f.companyId, 'done', spec(body));
  await objects.upload(f.actor, f.companyId, 'done', 'image/jpeg', body);
  assert.equal((await objects.cancel(f.actor, f.companyId, 'done')).state, 'committed');
  assert.equal((await ledger.usage(f.actor, f.companyId)).usedBytes, 20);
});

test('unverified storage preconditions cannot release in-flight reservations', async () => {
  const f = await fixture(), body = Buffer.alloc(20);
  await ledger.reserve(f.actor, f.companyId, 'flight', spec(body));
  await ledger.beginUpload(f.actor, f.companyId, 'flight', spec(body));
  await assert.rejects(objects.cancel(f.actor, f.companyId, 'flight'), errorCode('backup_requires_reconciliation'));
  assert.equal((await ledger.usage(f.actor, f.companyId)).remainingBytes, 80);
  await objects.upload(f.actor, f.companyId, 'flight', 'image/jpeg', body);
  assert.equal((await ledger.usage(f.actor, f.companyId)).usedBytes, 20);
});

test('stored bytes survive confirmation failure and recovery charges exactly once', async () => {
  const f = await fixture(), body = Buffer.alloc(20, 5);
  await ledger.reserve(f.actor, f.companyId, 'recover', spec(body));
  const unreliableLedger = new Proxy(ledger, { get(target, key) {
    if (key === 'commitVerifiedUpload') return async () => { throw new Error('synthetic connection loss'); };
    return typeof target[key] === 'function' ? target[key].bind(target) : target[key];
  } });
  await assert.rejects(new BackupObjectStore(bucket, unreliableLedger).upload(f.actor, f.companyId, 'recover', 'image/jpeg', body));
  assert.equal((await ledger.usage(f.actor, f.companyId)).reservedBytes, 20);
  await objects.recover(f.actor, f.companyId, 'recover');
  await objects.recover(f.actor, f.companyId, 'recover');
  assert.equal((await ledger.usage(f.actor, f.companyId)).usedBytes, 20);
});

test('fresh membership revocation blocks uploads, downloads and grant claims', async () => {
  const f = await fixture(), body = Buffer.alloc(20), grant = await approval(f);
  await ledger.reserve(f.actor, f.companyId, 'revoked', spec(body));
  await f.root.collection('members').doc(digest(f.actor.uid)).update({ active: false });
  await Promise.all([
    () => objects.upload(f.actor, f.companyId, 'revoked', 'image/jpeg', body),
    () => objects.download(f.actor, f.companyId, 'revoked'),
    () => ledger.claim(f.actor, f.companyId, grant),
  ].map(operation => assert.rejects(operation, errorCode('backup_membership_required'))));
});

test('cross-company and unverified accounts cannot spend another business allowance', async () => {
  const f = await fixture(), other = await fixture();
  await assert.rejects(ledger.usage(other.actor, f.companyId), errorCode('backup_membership_required'));
  await assert.rejects(ledger.usage({ ...f.actor, email_verified: false }, f.companyId), errorCode('verified_account_required'));
});

test('wrong upload bytes cannot consume or replace the reserved receipt', async () => {
  const f = await fixture(), body = Buffer.alloc(20, 1);
  await ledger.reserve(f.actor, f.companyId, 'immutable', spec(body));
  await assert.rejects(objects.upload(f.actor, f.companyId, 'immutable', 'image/jpeg', Buffer.alloc(20, 2)),
    errorCode('attempt_payload_conflict'));
  assert.equal((await ledger.usage(f.actor, f.companyId)).usedBytes, 0);
  await objects.upload(f.actor, f.companyId, 'immutable', 'image/jpeg', body);
  await assert.rejects(objects.upload(f.actor, f.companyId, 'immutable', 'image/jpeg', Buffer.alloc(20, 2)),
    errorCode('attempt_payload_conflict'));
  assert.deepEqual((await objects.download(f.actor, f.companyId, 'immutable')).body, body);
});

test('no more than eight uncompleted uploads may hold business reservations', async () => {
  const f = await fixture();
  for (let i = 0; i < 8; i++) await ledger.reserve(f.actor, f.companyId, `pending${i}`, spec(Buffer.from('x')));
  await assert.rejects(ledger.reserve(f.actor, f.companyId, 'ninth', spec(Buffer.from('x'))), errorCode('too_many_pending_backups'));
});

test('expired approval and corrupt counters fail closed without grants or writes', async () => {
  const f = await fixture(), id = await approval(f);
  await db.doc(`backupApprovals/${id}`).update({ expiresAt: 1 });
  await assert.rejects(ledger.claim(f.actor, f.companyId, id), errorCode('approval_expired'));
  await f.root.collection('allowance').doc('current').update({ reservedBytes: -1 });
  await assert.rejects(ledger.reserve(f.actor, f.companyId, 'bad', spec(Buffer.from('x'))), errorCode('invalid_allowance_state'));
  assert.equal((await f.root.collection('attempts').doc('bad').get()).exists, false);
});

test('approved grants are idempotent and the same recognized subject cannot claim through a new account', async () => {
  const f = await fixture(0), other = await fixture(0), subject = digest('shared-synthetic-device');
  const first = await approval(f, subject), second = await approval(other, subject);
  await Promise.all([ledger.claim(f.actor, f.companyId, first), ledger.claim(f.actor, f.companyId, first)]);
  assert.equal((await ledger.usage(f.actor, f.companyId)).grantedBytes, 25);
  await assert.rejects(ledger.claim(other.actor, other.companyId, second), errorCode('eligibility_already_used'));
  await assert.rejects(ledger.claim(other.actor, other.companyId, 'unapproved'), errorCode('trusted_approval_required'));
});

test('adding another member or reusing an eligible seat does not mint a second grant', async () => {
  const f = await fixture(0), first = await approval(f);
  await ledger.claim(f.actor, f.companyId, first);
  const second = { ...f, actor: { uid: randomUUID(), email_verified: true } };
  await f.root.collection('members').doc(digest(second.actor.uid)).set({ active: true, canUploadBackup: true, canManageBackup: true });
  await assert.rejects(ledger.claim(second.actor, f.companyId, await approval(second)), errorCode('workspace_trial_already_used'));
  const seat = digest('synthetic-seat'), seatGrant = await approval(f, seat, 'paidSeat');
  await ledger.claim(f.actor, f.companyId, seatGrant);
  await assert.rejects(ledger.claim(f.actor, f.companyId, await approval(f, seat, 'paidSeat')), errorCode('eligibility_already_used'));
});

test('rate limits apply across repeated reserve/cancel cycles', async () => {
  const f = await fixture(), controlled = new BackupAllowanceLedger(db, () => 1_000_000);
  for (let i = 0; i < 20; i++) {
    await controlled.reserve(f.actor, f.companyId, `attempt${i}`, spec(Buffer.from('x')));
    await controlled.cancel(f.actor, f.companyId, `attempt${i}`);
  }
  await assert.rejects(controlled.reserve(f.actor, f.companyId, 'overflow', spec(Buffer.from('x'))), errorCode('backup_request_rate'));
});

test('retries cannot turn uncharged uploads into unlimited network traffic', async () => {
  const f = await fixture(), clock = new BackupAllowanceLedger(db, () => 1_000_000);
  for (let i = 0; i < 8; i++) await clock.admitRequest(f.actor, f.companyId, 'upload', 8 * 1024 * 1024, 'retry');
  await assert.rejects(clock.admitRequest(f.actor, f.companyId, 'upload', 1, 'retry'), errorCode('backup_traffic_rate'));
  assert.equal((await ledger.usage(f.actor, f.companyId)).usedBytes, 0);
  const later = new BackupAllowanceLedger(db, () => 1_300_001);
  await later.admitRequest(f.actor, f.companyId, 'upload', 1, 'retry');
});

test('request rate limits also cover repeated small control requests', async () => {
  const f = await fixture(), clock = new BackupAllowanceLedger(db, () => 1_000_000);
  for (let i = 0; i < 60; i++) await clock.admitRequest(f.actor, f.companyId, 'usage', 2);
  await assert.rejects(clock.admitRequest(f.actor, f.companyId, 'usage', 2), errorCode('backup_traffic_rate'));
});

test('direct unauthenticated writes cannot create approvals or receipt objects', async () => {
  const fs = await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${projectId}/databases/(default)/documents/backupApprovals?documentId=forged`, {
    method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ fields: { approved: { booleanValue: true } } }),
  });
  assert.equal(fs.status, 403);
  const storage = await fetch(`http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}/v0/b/${projectId}.appspot.com/o?name=ui-lab-backups/forged/photo`, {
    method: 'POST', headers: { 'content-type': 'image/jpeg' }, body: 'forged',
  });
  assert.ok([401, 403].includes(storage.status));
});
