# Maintainiac Android media handoff adaptation

Upstream: image_picker_android 0.8.13+21. Original license, sources and tests are
preserved. UPSTREAM.json records the imported file hashes for review.

The local DurableMediaResultJournal is a request-identified SQLite replay store
with app-private copies. It is not yet connected to plugin callbacks or the Dart
gateway. Copy integrity, abrupt termination, cancellation, legacy recovery and
request lifecycle integration must be validated before calling the handoff durable.
Do not edit the global package cache. Do not mistake upstream tests for migration
acceptance. Upstream generated/large files are preserved rather than mechanically
split; local additions should stay at cohesive responsibility boundaries.

Journal manifests now contain original lengths and SHA-256 digests. Copies are
verified against pre/post-copy source hashes, and replay verifies the retained
bytes and canonical paths. Production flushes file contents plus containing
folders before publishing the SQLite result. Robolectric tests inject directory
flushes because its OS model cannot open directories; those tests prove ordering
and failure handling, not device fsync behavior. Actual OS and abrupt-termination
verification remains mandatory before activation.

The plugin now registers maintainiac/native_media_journal (begin/recover/acknowledge)
on a background task queue and gives its delegate the same journal. When an active
request exists, single/list results and lost-result retrieval retain native copies
before callback/cache clearing. Retention failure returns an error and preserves
the upstream retry paths. Empty explicit native results have no bytes to retain.
The application's Dart gateway has not yet activated this protocol. Legacy-cache
migration, pending-operation association, cancellation/error recovery and process
termination remain validation requirements before that activation is complete.

Native journal schema 2 adds durable acknowledgement receipts. Repeating an old
acknowledgement is harmless even after another request begins. Acknowledged keys
cannot be reused for capture. The explicit version-1 upgrade carries its current
acknowledged row forward; the main application's database schema is unchanged.

The Android Dart gateway now activates begin/recover/acknowledge for camera and
library requests. Recovery preparation returns both paths and whether legacy-cache
import is needed; acknowledged requests cannot consume another request's cache.
File-picker and non-Android behavior bypass the journal protocol. Retained native
copies preserve recognized image extensions. Device channel/fsync/lifecycle and
forced-termination testing are still outstanding; mocked channel tests alone are
not runtime validation.


Recovery error preservation (2026-09-10): error-only lost results now report the
cached platform error rather than silently becoming empty recovery. While a native
journal request is pending, error-only and incomplete cache data remain intact;
no acknowledgement is issued. Non-journal error-only retrieval keeps the upstream
one-shot cache behavior while reporting the error. Two delegate regressions cover
repeated error recovery and malformed pending cache without clear/acknowledge.


Retention retry correction (2026-09-10): after journal-backed recovery successfully
retains nonempty selected bytes, suppress only the obsolete native_retention_failed
cache error. Unrelated errors remain visible. A delegate regression first failed
against the prior implementation, then passed with the correction; it also checks
failed-retry preservation and unrelated-error reporting. No journal schema change.


Launch request binding (2026-09-10): capture the journal request in PendingCallState
and synchronously commit its key to the native picker cache before publishing the
callback/launch. Failed identity persistence leaves no pending callback. Normal
result processing uses that captured key; lost-activity processing uses the cached
key, with legacy fallback for old caches. A regression changes the active journal
key after launch and verifies late cancellation cannot retain/acknowledge the new
request. Native retained bytes still live in the SQLite handoff journal; the launch
key is plugin recovery metadata. Device interruption must be revalidated afterward.


Unjournaled launch isolation (2026-09-10): a live PendingCallState with no launch
journal key no longer falls back to a later active key. Its result follows normal
plugin delivery without retaining/acknowledging another request. Legacy lost-result
fallback remains limited to absent pending callback state. A regression reproduced
the earlier cross-request call and verifies isolation after correction.

Unpublished copy cleanup (2026-09-10): retention failures before SQL publication
remove only newly created copies from that attempt. Source files and previously
published manifests are preserved. Root redirection and deletion failures retain
the original error with suppressed cleanup details. Cleanup never runs after the
publication transaction begins, whose failure may have an uncertain outcome.
Tests reproduce missing-later-source and directory-flush leaks, verify original
sources remain intact, and verify retry/replay. Older acknowledged-copy cleanup
and process death before publication still require durable cleanup tracking.

Acknowledged-copy cleanup (2026-09-10): native journal schema 3 adds media_cleanup.
Versions 1 and 2 upgrade without replacing pending/ready handoff records. Finish
queues the original manifest and writes acknowledgment in one transaction before
clearing replay paths. NativeMediaCleanup deletes only queued acknowledged files
confined to native_media_handoff, flushes the directory, then removes the queue row.
Failure keeps the row for idempotent retry after reopen; begin/acknowledge/abandon
attempt cleanup without converting cleanup failure into failed acknowledgment.
Tests cover pending preservation, acknowledgment rollback, failed directory flush
across reopen/new request, path confinement and version-two ready-media upgrade.
Pre-upgrade copies whose manifests were already cleared are not guessed/deleted.
Process death during pre-publication copying remains a separate orphan-tracking gap.

Pre-publication ownership (2026-09-10): native schema 4 adds media_staging. A copy's
canonical destination is registered before file creation. Publishing its ready
manifest and removing staging ownership share one transaction. On begin, stale
ownership from a previous Android process permits confined cleanup and directory
flush before dropping ownership. A shared process nonce protects live copies across
helper reopenings. This relies on the current single-process Android application;
adding android:process requires a cross-process ownership design first. Old
unregistered files are never inferred from a directory scan. Tests cover modeled
previous-process state, same-process reopen, cleanup flush failure, publication
rollback and upgrades from versions 1/2/3. Actual mid-copy OS termination remains
an additional runtime gate.
