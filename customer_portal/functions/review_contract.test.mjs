import { test } from 'node:test';
import assert from 'node:assert/strict';
import { publicSnapshot, decisionFor, requireOpen, newToken, tokenKey } from './review_contract.mjs';

export const sample = {
  kind: 'Estimate', number: 'Estimate 1040', title: 'Replace kitchen faucet',
  company: 'Blue Ridge Service Company', companyDetails: '555-0100',
  customer: 'Maya Thompson', customerDetails: 'Service address',
  date: '2026-09-14', currency: 'USD', terms: 'Changes require customer approval.',
  templateId: 'plumbing-v1', revision: 1, totalCents: 25000,
  discountCents: 0, taxCents: 0,
  items: [{ name: 'Installation', quantity: 2, unit: 'Hours', unitPriceCents: 12500, totalCents: 25000 }],
};
const review = () => ({ snapshot: publicSnapshot(sample), digest: 'current', expiresAt: 2000 });
test('public snapshot excludes employee information, costs, and private notes', () => {
  const value = publicSnapshot({ ...sample, privateNotes: 'secret', employee: 'private',
    items: [{ ...sample.items[0], internalCost: 10 }] });
  assert.equal(JSON.stringify(value).includes('private'), false);
  assert.equal(value.items[0].internalCost, undefined);
  assert.throws(() => publicSnapshot({ ...sample, totalCents: 24999 }));
  assert.throws(() => publicSnapshot({ ...sample, revision: 0 }));
  assert.throws(() => publicSnapshot({ ...sample, date: 'invalid' }));
});
test('expired, revoked, and missing links cannot be used', () => {
  for (const value of [null, { ...review(), revokedAt: 1 }, review()]) {
    assert.throws(() => requireOpen(value, 2000));
  }
  const token = newToken(); assert.equal(token.length, 43);
  assert.notEqual(tokenKey(token), token); assert.throws(() => tokenKey('bad'));
});
test('approval requires current content, named consent, and is retry safe', () => {
  const input = { action: 'approved', name: 'Maya Thompson', reviewed: true, digest: 'current' };
  const row = review();
  assert.throws(() => decisionFor(row, { ...input, digest: 'old' }, 1000));
  assert.throws(() => decisionFor(row, { ...input, reviewed: false }, 1000));
  assert.throws(() => decisionFor(row, { ...input, name: ' ' }, 1000));
  row.decision = decisionFor(row, input, 1000);
  assert.deepEqual(decisionFor(row, input, 1100), row.decision);
  assert.throws(() => decisionFor(row, { ...input, action: 'declined' }, 1100));
  assert.equal(decisionFor({ ...review(), snapshot: { ...sample, kind: 'Quote' } }, input, 1000).action, 'approved');
  assert.throws(() => decisionFor({ ...review(), snapshot: { ...sample, kind: 'Invoice' } }, input, 1000));
});
