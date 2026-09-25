import { createHash } from 'node:crypto';
import { digest, MAX_OBJECT_BYTES, publicAttempt, reject, token, uploadSpec } from './backup_contract.mjs';

export class BackupObjectStore {
  constructor(bucket, ledger, { allowInFlightCancellation = false } = {}) {
    this.bucket = bucket; this.ledger = ledger;
    this.allowInFlightCancellation = allowInFlightCancellation;
  }
  path(companyId, attemptId) { return `ui-lab-backups/${token(companyId)}/${token(attemptId)}`; }
  async upload(actor, companyId, attemptId, contentType, body) {
    if (!Buffer.isBuffer(body) || body.length === 0 || body.length > MAX_OBJECT_BYTES) {
      reject(413, 'backup_body_too_large');
    }
    const spec = uploadSpec({ byteCount: body.length, contentType, sha256: digest(body) });
    const attempt = await this.ledger.beginUpload(actor, companyId, attemptId, spec);
    const file = this.bucket.file(this.path(companyId, attemptId));
    const md5Hash = createHash('md5').update(body).digest('base64');
    if (attempt.state !== 'committed') {
      try {
        await file.save(body, {
          resumable: false, validation: 'crc32c', preconditionOpts: { ifGenerationMatch: 0 },
          metadata: { contentType, cacheControl: 'private, no-store',
            metadata: { companyId, attemptId, sha256: spec.sha256 } },
        });
      } catch (error) {
        // An earlier successful write may have lost its response. Existing bytes
        // are never overwritten; validate the immutable object before charging.
        if (Number(error.code) !== 412) throw error;
      }
    }
    const [metadata] = await file.getMetadata();
    if (Number(metadata.size) !== body.length || metadata.md5Hash !== md5Hash ||
        metadata.contentType !== contentType || metadata.metadata?.sha256 !== spec.sha256 ||
        metadata.metadata?.companyId !== companyId || metadata.metadata?.attemptId !== attemptId) {
      reject(409, 'backup_object_conflict');
    }
    return this.ledger.commitVerifiedUpload(actor, companyId, attemptId, spec, String(metadata.generation));
  }
  async download(actor, companyId, attemptId) {
    const attempt = await this.ledger.readable(actor, companyId, attemptId);
    uploadSpec(attempt);
    // Fetch the exact charged generation, not whatever a later privileged writer
    // might place at the same path. No public or long-lived bearer download URL.
    const file = this.bucket.file(this.path(companyId, attemptId), { generation: attempt.generation });
    const [metadata] = await file.getMetadata();
    if (Number(metadata.size) !== attempt.byteCount) reject(503, 'backup_integrity_failed');
    const [body] = await file.download({ validation: 'crc32c' });
    if (body.length !== attempt.byteCount || digest(body) !== attempt.sha256) reject(503, 'backup_integrity_failed');
    return { body, contentType: attempt.contentType };
  }
  async recover(actor, companyId, attemptId) {
    const attempt = await this.ledger.ownedAttempt(actor, companyId, attemptId);
    if (['committed', 'cancelled'].includes(attempt.state)) return publicAttempt(attempt);
    const file = this.bucket.file(this.path(companyId, attemptId));
    let metadata;
    try { [metadata] = await file.getMetadata(); }
    catch (error) {
      if (Number(error.code) === 404) reject(409, 'backup_not_received_retry_or_cancel');
      throw error;
    }
    if (metadata.metadata?.cancelled === 'true' && Number(metadata.size) === 0 &&
        metadata.metadata?.companyId === companyId && metadata.metadata?.attemptId === attemptId) {
      return this.ledger.cancelWithVerifiedTombstone(actor, companyId, attemptId, String(metadata.generation));
    }
    if (Number(metadata.size) !== attempt.byteCount || Number(metadata.size) > MAX_OBJECT_BYTES ||
        metadata.contentType !== attempt.contentType || metadata.metadata?.companyId !== companyId ||
        metadata.metadata?.attemptId !== attemptId || metadata.metadata?.sha256 !== attempt.sha256) {
      reject(409, 'backup_object_conflict');
    }
    const [body] = await this.bucket.file(this.path(companyId, attemptId),
      { generation: metadata.generation }).download({ validation: 'crc32c' });
    if (body.length !== attempt.byteCount || digest(body) !== attempt.sha256) reject(409, 'backup_object_conflict');
    return this.ledger.commitVerifiedUpload(actor, companyId, attemptId, uploadSpec(attempt), String(metadata.generation));
  }
  async cancel(actor, companyId, attemptId) {
    const attempt = await this.ledger.ownedAttempt(actor, companyId, attemptId);
    if (['cancelled', 'committed'].includes(attempt.state)) return publicAttempt(attempt);
    if (attempt.state === 'reserved') {
      try { return await this.ledger.cancel(actor, companyId, attemptId); }
      catch (error) { if (error.code !== 'backup_requires_reconciliation') throw error; }
    }
    // Enable only after create-only behavior is independently verified against
    // the selected bucket. The local Firebase Storage emulator does not enforce
    // this precondition. Recovery and retry remain available while disabled.
    if (!this.allowInFlightCancellation) reject(409, 'backup_requires_reconciliation');
    // A create-only zero-byte marker wins atomically against a delayed upload.
    // Once present, every late upload's generation=0 precondition fails. Do NOT
    // delete this marker or expire it via bucket lifecycle rules.
    const file = this.bucket.file(this.path(companyId, attemptId));
    try {
      await file.save(Buffer.alloc(0), { resumable: false, preconditionOpts: { ifGenerationMatch: 0 },
        metadata: { contentType: 'application/octet-stream', cacheControl: 'private, no-store',
          metadata: { companyId, attemptId, cancelled: 'true' } } });
    } catch (error) { if (Number(error.code) !== 412) throw error; }
    // If actual data won the race, preserve and account for it instead of
    // deleting it or refunding its lifetime allocation.
    return this.recover(actor, companyId, attemptId);
  }
}
