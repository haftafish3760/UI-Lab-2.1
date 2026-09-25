import { bytes, counters, digest, hash, MAX_ALLOWANCE_BYTES, publicAttempt,
  publicUsage, reject, sameUpload, token, uploadSpec } from './backup_contract.mjs';

// All mutations are Firestore transactions, including fresh membership checks.
// These namespaces deliberately do not read or mutate the reference app's orgs.
export class BackupAllowanceLedger {
  constructor(db, clock = () => Date.now()) { this.db = db; this.clock = clock; }
  root(companyId) { return `backupWorkspaces/${token(companyId)}`; }
  attemptRef(companyId, attemptId) {
    return this.db.doc(`${this.root(companyId)}/attempts/${token(attemptId)}`);
  }
  async context(tx, actor, companyId, permission = 'canUploadBackup') {
    if (!actor || typeof actor.uid !== 'string' || !actor.uid || actor.email_verified !== true) {
      reject(401, 'verified_account_required');
    }
    const root = this.root(companyId);
    const [workspace, member, ledger] = await Promise.all([
      tx.get(this.db.doc(root)), tx.get(this.db.doc(`${root}/members/${digest(actor.uid)}`)),
      tx.get(this.db.doc(`${root}/allowance/current`)),
    ]);
    if (workspace.data()?.active !== true || member.data()?.active !== true ||
        member.data()?.[permission] !== true) reject(403, 'backup_membership_required');
    return { root, ledgerRef: ledger.ref, usage: counters(ledger.data()), workspace: workspace.data() };
  }
  async usage(actor, companyId) {
    return this.db.runTransaction(async tx => publicUsage((await this.context(tx, actor, companyId)).usage));
  }
  async admitRequest(actor, companyId, action, requestBytes, attemptId) {
    // Retries are free in the lifetime allowance, not unlimited network traffic.
    if (!Number.isSafeInteger(requestBytes) || requestBytes < 0) reject(400, 'invalid_byte_count');
    return this.db.runTransaction(async tx => {
      const permission = action === 'download' ? 'canReadBackup' : action === 'claim' ? 'canManageBackup' : 'canUploadBackup';
      const c = await this.context(tx, actor, companyId, permission);
      let transferBytes = requestBytes;
      if (action === 'download') {
        const attempt = (await tx.get(this.attemptRef(companyId, attemptId))).data();
        if (!attempt || attempt.state !== 'committed') reject(404, 'backup_unavailable');
        transferBytes += bytes(attempt.byteCount);
      }
      const ref = this.db.doc(`${c.root}/trafficRates/${digest(actor.uid)}`);
      const current = (await tx.get(ref)).data();
      const now = this.clock();
      if (current && ['requestStart', 'transferStart', 'requests', 'transferredBytes'].some(k =>
        !Number.isSafeInteger(current[k]) || current[k] < 0)) reject(503, 'invalid_rate_state');
      if (current && (current.requestStart > now || current.transferStart > now)) reject(503, 'invalid_rate_state');
      const shortWindow = current && now - current.requestStart < 60_000;
      const byteWindow = current && now - current.transferStart < 300_000;
      const requests = shortWindow ? current.requests : 0;
      const transferredBytes = byteWindow ? current.transferredBytes : 0;
      if (requests >= 60 || transferredBytes + transferBytes > 64 * 1024 * 1024) reject(429, 'backup_traffic_rate');
      tx.set(ref, { requestStart: shortWindow ? current.requestStart : now,
        transferStart: byteWindow ? current.transferStart : now,
        requests: requests + 1, transferredBytes: transferredBytes + transferBytes });
    });
  }
  async claim(actor, companyId, approvalId) {
    token(approvalId);
    return this.db.runTransaction(async tx => {
      const c = await this.context(tx, actor, companyId, 'canManageBackup');
      const approvalRef = this.db.doc(`backupApprovals/${approvalId}`);
      const approval = (await tx.get(approvalRef)).data();
      if (!approval || approval.approved !== true || approval.companyId !== companyId ||
          approval.uid !== actor.uid || !['trial', 'paidSeat', 'reviewedRecovery'].includes(approval.kind)) {
        reject(403, 'trusted_approval_required');
      }
      // The eligibility/billing authority, never the client, supplies bytes,
      // policy version and a stable, pseudonymous one-time eligibility key.
      hash(approval.subjectKey);
      const grantBytes = bytes(approval.bytes, MAX_ALLOWANCE_BYTES);
      token(approval.policyVersion);
      const key = digest(`${approval.kind}:${approval.subjectKey}`);
      const claimRef = this.db.doc(`backupEligibilityClaims/${key}`);
      const accountRef = this.db.doc(`backupTrialAccounts/${digest(actor.uid)}`);
      const [prior, account] = await Promise.all([tx.get(claimRef), tx.get(accountRef)]);
      if (prior.exists) {
        const existing = prior.data();
        if (existing.approvalId !== approvalId || existing.companyId !== companyId ||
            existing.bytes !== grantBytes || existing.uid !== actor.uid) reject(409, 'eligibility_already_used');
        return publicUsage(c.usage);
      }
      if (approval.kind === 'trial' && account.exists) reject(409, 'trial_already_used');
      if (approval.kind === 'trial' && c.workspace.trialClaimKey != null) reject(409, 'workspace_trial_already_used');
      if (approval.claimedAt != null) reject(409, 'approval_already_used');
      if (!Number.isSafeInteger(approval.expiresAt) || approval.expiresAt <= this.clock()) {
        reject(403, 'approval_expired');
      }
      if (c.usage.grantedBytes + grantBytes > MAX_ALLOWANCE_BYTES) reject(409, 'allowance_limit');
      const usage = { ...c.usage, grantedBytes: c.usage.grantedBytes + grantBytes };
      tx.create(claimRef, { companyId, uid: actor.uid, approvalId, bytes: grantBytes,
        policyVersion: approval.policyVersion, kind: approval.kind, claimedAt: this.clock() });
      if (approval.kind === 'trial') {
        tx.create(accountRef, { companyId, claimKey: key });
        tx.update(this.db.doc(c.root), { trialClaimKey: key });
      }
      tx.update(approvalRef, { claimedAt: this.clock() });
      tx.set(c.ledgerRef, usage);
      return publicUsage(usage);
    });
  }
  async reserve(actor, companyId, attemptId, value) {
    const spec = uploadSpec(value);
    const ref = this.attemptRef(companyId, attemptId);
    return this.db.runTransaction(async tx => {
      const c = await this.context(tx, actor, companyId);
      const existing = (await tx.get(ref)).data();
      if (existing) {
        sameUpload(existing, actor.uid, spec);
        if (existing.state === 'cancelled') reject(409, 'attempt_cancelled');
        return publicAttempt(existing);
      }
      if (c.usage.openAttempts >= 8) reject(429, 'too_many_pending_backups');
      if (c.usage.usedBytes + c.usage.reservedBytes + spec.byteCount > c.usage.grantedBytes) {
        reject(409, 'backup_allowance_exhausted');
      }
      const rateRef = this.db.doc(`${c.root}/requestRates/${digest(actor.uid)}`);
      const rate = (await tx.get(rateRef)).data();
      const now = this.clock();
      if (rate && (!Number.isSafeInteger(rate.startedAt) || !Number.isSafeInteger(rate.count) ||
          rate.count < 0 || rate.startedAt > now)) reject(503, 'invalid_rate_state');
      const count = rate && now - rate.startedAt < 60_000 ? rate.count : 0;
      if (count >= 20) reject(429, 'backup_request_rate');
      const attempt = { ...spec, uid: actor.uid, companyId, attemptId, state: 'reserved', createdAt: now };
      tx.create(ref, attempt);
      tx.set(rateRef, { startedAt: count ? rate.startedAt : now, count: count + 1 });
      tx.set(c.ledgerRef, { ...c.usage, reservedBytes: c.usage.reservedBytes + spec.byteCount,
        openAttempts: c.usage.openAttempts + 1 });
      return publicAttempt(attempt);
    });
  }
  async beginUpload(actor, companyId, attemptId, spec) {
    const ref = this.attemptRef(companyId, attemptId);
    return this.db.runTransaction(async tx => {
      await this.context(tx, actor, companyId);
      const attempt = (await tx.get(ref)).data();
      if (!attempt) reject(404, 'backup_attempt_missing');
      sameUpload(attempt, actor.uid, uploadSpec(spec));
      if (attempt.state === 'cancelled') reject(409, 'attempt_cancelled');
      if (!['reserved', 'uploading', 'committed'].includes(attempt.state)) reject(503, 'invalid_attempt_state');
      if (attempt.state === 'reserved') tx.update(ref, { state: 'uploading', startedAt: this.clock() });
      return { ...attempt, state: attempt.state === 'reserved' ? 'uploading' : attempt.state };
    });
  }
  // Only called by the storage adapter after it verifies the actual stored
  // object. No client-facing finalize endpoint accepts a claimed byte count.
  async commitVerifiedUpload(actor, companyId, attemptId, spec, generation) {
    if (typeof generation !== 'string' || !/^[0-9]{1,30}$/.test(generation)) reject(503, 'invalid_object_generation');
    const ref = this.attemptRef(companyId, attemptId);
    return this.db.runTransaction(async tx => {
      const c = await this.context(tx, actor, companyId);
      const attempt = (await tx.get(ref)).data();
      if (!attempt) reject(404, 'backup_attempt_missing');
      sameUpload(attempt, actor.uid, uploadSpec(spec));
      if (attempt.state === 'committed') {
        if (attempt.generation !== generation) reject(409, 'backup_object_changed');
        return publicAttempt(attempt);
      }
      if (attempt.state !== 'uploading') reject(409, 'backup_not_uploading');
      if (c.usage.reservedBytes < attempt.byteCount || c.usage.openAttempts < 1) reject(503, 'invalid_allowance_state');
      tx.update(ref, { state: 'committed', generation, committedAt: this.clock() });
      tx.set(c.ledgerRef, { ...c.usage, usedBytes: c.usage.usedBytes + attempt.byteCount,
        reservedBytes: c.usage.reservedBytes - attempt.byteCount, openAttempts: c.usage.openAttempts - 1 });
      return publicAttempt({ ...attempt, state: 'committed' });
    });
  }
  async cancel(actor, companyId, attemptId) {
    const ref = this.attemptRef(companyId, attemptId);
    return this.db.runTransaction(async tx => {
      const c = await this.context(tx, actor, companyId);
      const attempt = (await tx.get(ref)).data();
      if (!attempt || attempt.uid !== actor.uid) reject(404, 'backup_attempt_missing');
      if (attempt.state === 'cancelled') return publicAttempt(attempt);
      // Once upload starts, never release its reservation based on a clock or
      // a client cancellation: a delayed object could otherwise evade quota.
      if (attempt.state !== 'reserved') reject(409, 'backup_requires_reconciliation');
      if (c.usage.reservedBytes < attempt.byteCount || c.usage.openAttempts < 1) reject(503, 'invalid_allowance_state');
      tx.update(ref, { state: 'cancelled', cancelledAt: this.clock() });
      tx.set(c.ledgerRef, { ...c.usage, reservedBytes: c.usage.reservedBytes - attempt.byteCount,
        openAttempts: c.usage.openAttempts - 1 });
      return publicAttempt({ ...attempt, state: 'cancelled' });
    });
  }
  async ownedAttempt(actor, companyId, attemptId) {
    return this.db.runTransaction(async tx => {
      await this.context(tx, actor, companyId);
      const attempt = (await tx.get(this.attemptRef(companyId, attemptId))).data();
      if (!attempt || attempt.uid !== actor.uid) reject(404, 'backup_attempt_missing');
      return attempt;
    });
  }
  async cancelWithVerifiedTombstone(actor, companyId, attemptId, generation) {
    if (typeof generation !== 'string' || !/^[0-9]{1,30}$/.test(generation)) reject(503, 'invalid_object_generation');
    return this.db.runTransaction(async tx => {
      const c = await this.context(tx, actor, companyId);
      const ref = this.attemptRef(companyId, attemptId);
      const attempt = (await tx.get(ref)).data();
      if (!attempt || attempt.uid !== actor.uid) reject(404, 'backup_attempt_missing');
      if (attempt.state === 'cancelled') return publicAttempt(attempt);
      if (!['reserved', 'uploading'].includes(attempt.state)) reject(409, 'backup_already_committed');
      if (c.usage.reservedBytes < attempt.byteCount || c.usage.openAttempts < 1) reject(503, 'invalid_allowance_state');
      tx.update(ref, { state: 'cancelled', cancelledAt: this.clock(), tombstoneGeneration: generation });
      tx.set(c.ledgerRef, { ...c.usage, reservedBytes: c.usage.reservedBytes - attempt.byteCount,
        openAttempts: c.usage.openAttempts - 1 });
      return publicAttempt({ ...attempt, state: 'cancelled' });
    });
  }
  async readable(actor, companyId, attemptId) {
    return this.db.runTransaction(async tx => {
      await this.context(tx, actor, companyId, 'canReadBackup');
      const attempt = (await tx.get(this.attemptRef(companyId, attemptId))).data();
      if (!attempt || attempt.state !== 'committed') reject(404, 'backup_unavailable');
      return attempt;
    });
  }
}
