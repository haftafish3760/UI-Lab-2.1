import { createHash, randomBytes } from 'node:crypto';

export class ReviewError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
const fail = (message) => { throw new ReviewError(400, message); };
export const digest = (value) => createHash('sha256').update(value).digest('hex');
export const newToken = () => randomBytes(32).toString('base64url');
export function tokenKey(token) {
  if (typeof token !== 'string' || !/^[A-Za-z0-9_-]{43}$/.test(token)) {
    throw new ReviewError(404, 'This review link is unavailable.');
  }
  return digest(token);
}
const text = (v, limit, optional = false) => {
  if (typeof v !== 'string' || v.length > limit || (!optional && !v.trim())) fail('The document information is incomplete.');
  return v.trim();
};
const cents = (v) => {
  if (!Number.isSafeInteger(v) || v < 0 || v > 1_000_000_000_000) fail('The document amount is invalid.');
  return v;
};
export function publicSnapshot(input) {
  // Explicit allowlist: private notes, internal costs and employee data never pass.
  const d = { kind: text(input.kind, 20), number: text(input.number, 100),
    title: text(input.title, 500), description: text(input.description ?? '', 10000, true), company: text(input.company, 200),
    companyDetails: text(input.companyDetails, 2000, true),
    customer: text(input.customer, 200), customerDetails: text(input.customerDetails, 2000, true),
    date: text(input.date, 30), reference: text(input.reference ?? '', 100, true),
    currency: text(input.currency, 3), terms: text(input.terms, 20000),
    templateId: text(input.templateId, 100), revision: input.revision,
    totalCents: cents(input.totalCents), discountCents: cents(input.discountCents), taxCents: cents(input.taxCents) };
  if (!['Estimate', 'Quote', 'Invoice'].includes(d.kind) || !/^[A-Z]{3}$/.test(d.currency) ||
      !Number.isSafeInteger(d.revision) || d.revision < 1) fail('The document type or revision is invalid.');
  d.validUntil = input.validUntil ?? null;
  if (d.validUntil !== null && (typeof d.validUntil !== 'string' || !Number.isFinite(Date.parse(d.validUntil)))) fail('The expiry date is invalid.');
  if (!Number.isFinite(Date.parse(d.date))) fail('The document date is invalid.');
  if (!Array.isArray(input.items) || input.items.length < 1 || input.items.length > 500) fail('Review the document items.');
  d.items = input.items.map((i) => {
    if (!Number.isFinite(i.quantity) || i.quantity <= 0 || i.quantity > 1e9) fail('Review item quantities.');
    return { name: text(i.name, 300), description: text(i.description ?? '', 2000, true),
      quantity: i.quantity, unit: text(i.unit ?? '', 50, true), unitPriceCents: cents(i.unitPriceCents), totalCents: cents(i.totalCents) };
  });
  const subtotal = d.items.reduce((sum, i) => sum + i.totalCents, 0);
  if (subtotal - d.discountCents + d.taxCents !== d.totalCents) fail('Document totals do not agree.');
  return d;
}
export function requireOpen(review, now = Date.now()) {
  if (!review || review.revokedAt || review.expiresAt <= now) {
    throw new ReviewError(410, 'This review link has expired or is no longer available. Ask the company for a current copy.');
  }
}
export function decisionFor(review, input, now = Date.now()) {
  requireOpen(review, now);
  if (input.digest !== review.digest) throw new ReviewError(409, 'The document changed. Reload and review it again.');
  if (!['approved', 'declined'].includes(input.action)) fail('Choose approve or decline.');
  if (!['Estimate', 'Quote'].includes(review.snapshot.kind)) throw new ReviewError(409, 'Approval is available for estimates and quotes only.');
  const name = text(input.name, 200);
  if (input.action === 'approved' && input.reviewed !== true) fail('Confirm that you reviewed the work and terms.');
  if (review.decision) {
    if (review.decision.action === input.action && review.decision.name === name) return review.decision;
    throw new ReviewError(409, 'A response is already recorded. Contact the company to discuss a change.');
  }
  return { action: input.action, name, at: now, digest: review.digest,
    revision: review.snapshot.revision, verification: 'possession-of-private-link' };
}
