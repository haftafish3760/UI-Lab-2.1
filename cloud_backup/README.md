# UI Lab backup-upload protections

This is backend source inside **UI Lab 2.1**, not a change to Maintainiac 5.7.
The owning product rules are in `docs/data_storage_sync_contract.md`, September
20 update. Freemium amounts, bonus structure, paid-seat requirements and duration
remain undecided. There is no default free grant or automatic signup credit.
SQLite/Drift remains the device database; no Hive or Flutter/OCR changes are made.

## Reference and reuse assessment

Read-only inspection covered 5.7's `functions/index.js` upload-grant/finalize
flows, `functions/hosted_plans.js` entitlement/sync limits and `storage.rules`.
Useful patterns: authoritative membership, approved entitlements, reservations,
transactions, bounded payloads and App Check. Adapt these responsibilities, not
the per-user occupied-storage quota: the owner discussed cumulative business
backup-upload allowance. Do not treat a client-supplied digest as verified bytes,
release a reservation while an upload can still arrive, or overwrite an object.
No reference code was executed, edited or deployed. Existing UI Lab account
initialization and customer-portal functions remain separate and unchanged.

Firebase target authority is the newer `firebase_connection_checkpoint.md` / D34,
which selects the existing project; the earlier separate-project discussion was
outdated. This folder intentionally has only an **emulator configuration**, no
project alias or production deployment configuration. Never deploy these local
deny-all rule files over an existing project's rules without a scoped merge.

## Implemented server behavior

- Authentication checks revocation, verified email and App Check against an
  explicit allowed-app list. App Check establishes app authenticity, not a
  unique person or trial eligibility. No production authentication bypass.
- Fresh business membership and action permissions are read inside transactions;
  client company IDs and stale account claims alone grant no authority.
- Server-only approvals allocate positive byte grants with a policy version,
  expiry and one-time eligibility key. Clients cannot choose granted bytes,
  approval type or the eligibility key. Trial claims are unique per recognized
  subject, account and workspace. A paid-seat eligibility key may be consumed
  once; the code does not issue paid-seat approvals or pick a commercial plan.
- Usage tracks granted, successfully uploaded and reserved bytes. Atomic
  reservations prevent competing devices from exceeding the shared allowance.
  Each attempt is bound to its creator, size, content type and content digest.
- The server computes the actual body digest. Object writes are create-only,
  and the stored size, digest metadata, MD5 and immutable generation are checked
  before the reserved bytes become used bytes. The MD5 is an additional transport
  comparison, not the authentication or content identity; SHA-256 binds the body.
- Idempotent retry/recovery handles a stored object whose accounting confirmation
  failed. Used bytes never decrease when a backup is cancelled or later removed.
- Cancelling an unstarted reservation releases only held bytes. Completed backups
  remain intact. In-flight cancellation refunds are **disabled by default**;
  retry and recovery remain available. The optional cancellation protocol places
  a create-only zero-byte marker before releasing bytes so delayed writes cannot
  arrive afterward. If real data won the race, it is preserved and charged.
- Downloads recheck membership and fetch the charged object generation with
  integrity verification, even when no upload allowance remains. No public
  download URL, client write/delete endpoint or automatic reclamation is exposed.
- Operational ceilings, independent of commercial entitlements: 8 MiB per object,
  8 outstanding attempts per workspace, 20 new reservations per member/minute,
  60 authenticated requests per member/minute and 64 MiB of attempted upload plus
  download traffic per member/five minutes. Function instances/concurrency are
  bounded. These require workload calibration and are not a guaranteed bill cap.
  Larger media/chunked backup transport is not implemented by this slice.
- Responses contain bounded error codes, not provider errors, account credentials
  or receipt contents. The backend reads bytes for integrity; it does not run OCR.

## Server records and trust boundary

All records use new UI Lab namespaces:

| Path | Owner and purpose |
| --- | --- |
| `backupWorkspaces/{company}` | Trusted company authority; active state and consumed trial key |
| `.../members/{sha256(uid)}` | Trusted membership with active, canUploadBackup, canReadBackup and canManageBackup |
| `.../allowance/current` | Transactional granted/used/reserved bytes and open-attempt count |
| `.../attempts/{attempt}` | Durable upload state, owner, exact payload identity and object generation |
| `.../requestRates/{sha256(uid)}` | New-reservation rate window |
| `.../trafficRates/{sha256(uid)}` | All-request and transfer rate windows |
| `backupApprovals/{approval}` | Server-issued eligibility/billing/manual-review approval |
| `backupEligibilityClaims/{key}` | Consumed one-time recognition/seat/recovery eligibility |
| `backupTrialAccounts/{sha256(uid)}` | Consumed account trial history |
| Bucket `ui-lab-backups/{company}/{attempt}` | Immutable uploaded object or cancellation marker |

Approval fields: companyId, uid, approved, kind (trial/paidSeat/reviewedRecovery),
subjectKey (64 lowercase hex characters), bytes, policyVersion, expiresAt. The
server records claimedAt. Trusted issuance must authenticate and audit the
reviewer/provider; there is intentionally no client approval-creation endpoint.
The keyed recognition helper accepts **already verified** evidence only. It is
not an implementation of Apple DeviceCheck, Google device recall or fingerprinting.
Do not mistake a rotating attestation token for a stable device identifier.

Account IDs and pseudonymous recognition keys are still privacy-sensitive.
Eligibility-provider adapters, operator tooling, retention and shared/secondhand
device reviews are unconnected release prerequisites. There is no automatic
free signup based on an unverified device assertion. Manual recovery grants need
their own reviewed, unique approval; they do not erase previous usage history.

## Local verification

Install with `npm ci --ignore-scripts` in `functions`. Unit tests: `npm test`.
Run integration checks from this folder with a supported Java runtime:

```powershell
firebase emulators:exec --only firestore,storage --project demo-ui-lab-backup --config firebase.emulator.json "npm --prefix functions test && npm --prefix functions run test:emulator"
```

Integration tests refuse to construct Admin clients without both loopback
emulator addresses. They use synthetic receipts, accounts and company records in
a `demo-` project, not the selected live project. No screenshots or live uploads.
Coverage includes shared-quota contention, same-attempt races, body substitution,
grant reuse across accounts, extra members, revoked access, recovery, exhaustion,
malformed state, control/transfer rates and direct unauthenticated rule denials.

The local Storage emulator **does not enforce the generation-zero create-only
precondition**: a negative probe overwrote a synthetic marker rather than rejecting
it. That test exposed the limitation; it is not reported as passing cloud evidence.
SDK contract-double tests cover both cancellation race outcomes. Production
in-flight cancellation stays disabled until an isolated real-bucket test verifies
precondition enforcement, immutable-generation reads and the recovery protocol.
Firestore emulator contention tests likewise do not establish production throughput.

Verified September 20: all **7 unit/SDK-contract tests and 17 Firestore/Storage
emulator tests pass**, with no skipped tests in the final run. Node syntax checks
pass for all five production modules. The production dependency audit reports
zero known vulnerabilities after pinning the transitive UUID fix. The largest
production module is 214 lines. Emulator shutdown completed and task-owned
emulator process absence was checked. These checks apply to this backend slice;
they do not claim Flutter integration, live App Check or production bucket testing.

## Deployment and remaining connections

Nothing from this folder is deployed. Required configuration:

The read-only Firebase CLI project-list check failed on this host; live target
access has not been established by this task. No project creation, rules changes,
billing changes, provider configuration or cloud uploads were performed.

- `BACKUP_ENABLED=true` only after rollout acceptance; absence keeps it disabled.
- `BACKUP_BUCKET` explicitly names the reviewed bucket; no implicit default bucket.
- `BACKUP_ALLOWED_APP_IDS` permits only the reviewed Firebase app registrations.
- `BACKUP_OBJECT_PRECONDITIONS_VERIFIED=true` only after independent real-bucket
  validation; omission keeps in-flight reservation refunds unavailable.

Before rollout: verify project access and bucket/IAM; merge narrowly scoped
Firestore/Storage denies into existing rules without broad allows; ensure the
chosen prefix has no deletion lifecycle or overwrite permission; configure App
Check providers and app clients; connect the canonical company membership and
eligibility/billing authorities; test account deletion/recovery; establish provider
retention and operational cost controls. Existing user uploads must never be
deleted to regain quota. An expired allowance does not imply backup deletion.

The Flutter backup adapter still needs to persist attempt IDs in its existing
SQLite queue and use these endpoints. OCR and receipt capture are unchanged.
Client sign-in alone is not verified company membership. Do not describe this
backend source or synthetic fixtures as a connected backup/anti-abuse product.

Primary API references:

- https://firebase.google.com/docs/firestore/manage-data/transactions
- https://firebase.google.com/docs/app-check/custom-resource-backend
- https://cloud.google.com/storage/docs/request-preconditions
