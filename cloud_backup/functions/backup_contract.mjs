import { createHash, createHmac } from 'node:crypto';

export class BackupError extends Error {
  constructor(status, code) { super(code); this.status = status; this.code = code; }
}
export const reject = (status, code) => { throw new BackupError(status, code); };
export const digest = value => createHash('sha256').update(value).digest('hex');
export const MAX_OBJECT_BYTES = 8 * 1024 * 1024;
export const MAX_ALLOWANCE_BYTES = 1024 ** 4;
export const MEDIA_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'application/pdf']);
export function token(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,80}$/.test(value)) reject(400, 'invalid_identity');
  return value;
}
export function bytes(value, maximum = MAX_OBJECT_BYTES) {
  if (!Number.isSafeInteger(value) || value < 1 || value > maximum) reject(400, 'invalid_byte_count');
  return value;
}
export function hash(value) {
  if (typeof value !== 'string' || !/^[a-f0-9]{64}$/.test(value)) reject(400, 'invalid_digest');
  return value;
}
export function uploadSpec(value) {
  if (!value || !MEDIA_TYPES.has(value.contentType)) reject(400, 'unsupported_backup_type');
  return { byteCount: bytes(value.byteCount), sha256: hash(value.sha256), contentType: value.contentType };
}
export function counters(value) {
  const result = value ?? { grantedBytes: 0, usedBytes: 0, reservedBytes: 0, openAttempts: 0 };
  for (const key of ['grantedBytes', 'usedBytes', 'reservedBytes', 'openAttempts']) {
    if (!Number.isSafeInteger(result[key]) || result[key] < 0 || result[key] > MAX_ALLOWANCE_BYTES) {
      reject(503, 'invalid_allowance_state');
    }
  }
  if (result.usedBytes + result.reservedBytes > result.grantedBytes) reject(503, 'invalid_allowance_state');
  return { grantedBytes: result.grantedBytes, usedBytes: result.usedBytes,
    reservedBytes: result.reservedBytes, openAttempts: result.openAttempts };
}
export function publicUsage(value) {
  const c = counters(value);
  return { ...c, remainingBytes: c.grantedBytes - c.usedBytes - c.reservedBytes };
}
export function sameUpload(attempt, uid, spec) {
  if (attempt.uid !== uid || ['byteCount', 'sha256', 'contentType'].some(key => attempt[key] !== spec[key])) {
    reject(409, 'attempt_payload_conflict');
  }
}
export function publicAttempt(value) {
  return { state: value.state, byteCount: value.byteCount, attemptId: value.attemptId };
}

// TRUSTED eligibility-adapter utility, never a client fingerprint endpoint.
// Input must be evidence already validated by a provider or reviewed operator.
// No raw device/advertising identifiers, receipt data or emails are persisted.
export function recognitionSubject(secret, provider, verifiedSubject) {
  if (!Buffer.isBuffer(secret) || secret.length < 32 ||
      !['apple', 'google', 'reviewed'].includes(provider) ||
      typeof verifiedSubject !== 'string' || !verifiedSubject || verifiedSubject.length > 512) {
    reject(503, 'invalid_recognition_evidence');
  }
  return createHmac('sha256', secret).update(JSON.stringify([provider, verifiedSubject])).digest('hex');
}
