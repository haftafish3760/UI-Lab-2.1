# SQLite migration remaining-work audit

Current source inspection: 2026-09-10. This is an evidence audit, not a new product
contract or a declaration of completion. Inventory integration is authorized
after the local migration passes its completion audit.

## Current completion gate matrix — September 10, 2026

This current-state audit distinguishes implemented local behavior from remaining work.
It does not adopt new product decisions or declare the migration complete. Earlier
chronological checkpoints below remain historical evidence, not the current checklist.

| Requirement | Current authoritative evidence | Remaining limit or work |
| --- | --- | --- |
| Normal entry uses SQLite/Drift | main.dart → open_ui_lab_application.dart → LocalPersistence.open injects SQLite domain adapters, Work/directory/workday/day-note sessions and preferences | Inventory is the explicitly deferred next stage. Maintenance currently opens ModuleHomeScreen.maintenance with a prototype-notice action, not an editable service-record workflow. |
| Old persistence retired from the normal entry | No Hive/shared-preference/file-repository construction in main/startup. File…Repository names are compatibility aliases; the app's transient notification fallback is for construction without injected repositories | Compatibility readers and preview/test fallbacks still exist. Retained evidence files/checkpoint manifests intentionally remain files; that is not legacy record persistence. |
| Raw autosave, explicit discard and recovery | Versioned DraftRepository/workflow models, selected/global recovery routes, core/domain/editor checkpoint 20260910T180954Z-2ecf8b88. Later early-discard guard reproduced false success before initialization and passed 22 focused checks after correction; analysis clean (mounted-restore-service-20260910/early-discard-*.log) | Calendar Day's two disconnected memory-only switches need the pending product decision. Do not call their advertised behavior implemented merely by storing values. |
| Transaction/concurrency safeguards | Local records/revisions/command/outbox transactions, draft revision CAS and atomic confirmation; core 188/domain 254/editor 136 checks | No claim of cross-device conflict resolution or production cloud identity. Deferred inventory stock side effects are not covered by SQLite stock transactions yet. |
| Startup integrity and compatibility | WAL/FULL/FK checks, established-installation guard, schema/payload checks, explicit unknown-version failure/retention | Future schema upgrades require explicit tested migrations; schema 1 does not prove future upgrade correctness. No reset or silent fallback is an upgrade strategy. |
| App/runtime interruption and recovery | Four current restore cases passed in macOS, iOS 26.5 simulator and Android API 35 (normal restore, open failure, save failure and pending media); Android evidence: mounted-restore-service-20260910/four-case-android-runtime.log. The isolated iOS runner also passed all four cases after the early-discard fix and controller changes: mounted-restore-service-20260910/isolated-ios-simulator-runtime.log. Android standalone force-stop recovered the acknowledged draft after an uncommitted write | Physical iPhone SE/iOS 26.6 QA build and isolated install succeeded, but launch was denied by device signing/trust security (CoreDeviceError 10002); no physical runtime pass. Local signature/profile checks passed; device trust needs checking. Evidence: mounted-restore-service-20260910/ios-physical-launch-result.json. Older supported OS versions, Windows runtime, power loss and gestures already in progress remain unverified. See retained platform execution records for exact limits. |
| Native media retention | Workspace-owned Android native journal retains and hashes camera/library bytes before delivery; Dart acknowledges after retained-file transaction. API 35 normal-result kill/replay, camera cancellation/retry, and external-camera process death passed. Native journal/cleanup regressions: 130 passed with unchanged source (20260910T183518Z-native-64b4db4f/report.json), including a reproduced overlapping-helper overwrite corrected by rechecking published results inside the write transaction | File-picker requires explicit reselection after interruption. Broader provider/physical/older-device behavior, device denial/disk-failure injection, pre-retention source loss, and broader multi-engine/multi-process behavior are unverified. Acknowledged-copy cleanup passed Android activity-death recovery. Staging ownership passed JVM partial-file tests and Android process termination after copy/flush before manifest publication; physical power loss and legacy unregistered copies remain unverified. |
| Checkpoint/restore interaction | Verified bundles, isolated candidates, durable selection, real startup host runtime and LocalRestoreWorkflow review/confirmation service | Global Settings currently has Saved work recovery plus a noninteractive Backup and company sync tile. Whole-installation source selection, confirmation/retry interaction and production access wiring are not exposed. The separate restore-page presentation choice is pending. |
| UI/storage separation | No direct Drift/database imports or LocalDraftStore construction found in screens/shared/shell; schema contains domain IDs, revisions, versioned payloads and journals, not widths/widgets/routes. Startup exposes the pure-Dart LocalRestoreController contract and plain review facts; the implementation keeps selection/runtime private. Copied review facts cannot authorize restore. All 17 focused workflow/host/mounted checks, analysis and Android build passed (mounted-restore-service-20260910/restore-controller-contract-*.log) | Deferred inventory still keeps models under screens/inventory and mutable lists in PrototypeOperationsStore. Its port must move models/workflows behind data services. New navigation still must participate in lifecycle guards, but does not require schema changes for visual composition. |
| Source size/naming | All authored production Dart files checked are at/below 500 lines; the 811-line app_localizations.dart is generated through l10n.yaml, as are Drift .g.dart outputs | No mechanical split of generated output. Maintain descriptive responsibility-based names during remaining work. |
| Reusable QA and regression | Latest declared regression before the subsequent early-discard guard: 578 passed across 200 files (188 core, 254 domain, 136 editor), zero failures/skips/missing/unfinished tests and unchanged source: 20260910T180954Z-2ecf8b88/report.json. Includes reusable process-kill fixtures, platform entry point and isolated Android runner | Latest full discovered run: 1,061 passed, 7 failed across 304 files, no skips/missing/unfinished tests or source changes. Six UI failures match baseline names and assertion details. The additional 648-line test-file failure was subsequently fixed by splitting journal tests and shared fakes; all nine focused checks including size guard passed. No subsequent full-suite rerun is claimed. Evidence: 20260910T170936Z-dce8c6e2/report.json and mounted-restore-service-20260910/media-test-split.log under build/storage_qa. |
| Cloud release-one requirement | Local operation does not require Firebase; no Firebase reference found in lib or pubspec.yaml; local outbox is not an upload acknowledgment | Optional backup/sync, production identity/rules/configuration remain release-one work. Missing cloud credentials are not a filesystem permission problem and do not prevent local migration work. |
| Protected source and next stage | 5.7 unchanged; inventory integration has not begun | Finish the local completion audit before beginning the independently tested 5.7 inventory port. Owner subsequently requested that the backup be on main for laptop continuation. All checkpoint commits through 1fdf43a were fast-forwarded and verified on origin/main September 10; this does not declare release readiness or completion. |

The six retained failures are four attempts to tap the absent dashboard-view-selector
key, the header bound expecting <=290 LP but observing 366, and the Inventory workspace
expecting >1000 LP but observing 375.84. Both names and normalized assertion details
match the earlier 20260910T065305Z-e5e60e52 baseline. They remain unresolved UI expectation
failures; no unapproved layout or test expectations were changed for this audit.

The largest outstanding user-visible integration is whole-installation restore, not
SQLite table conversion. The native-media and platform limits above must remain explicit.
No “enterprise ready,” all-platform, cloud-ready or full migration completion claim is
supported by this matrix.

## Recovery-query access and lifecycle checkpoint — September 10, 2026

DraftRecoveryQuery no longer treats initial construction as a permanent access grant.
The owning workflow supplies a canList callback; denied access avoids the repository
read, and catalog/query checks suppress results when access changes during asynchronous
loading. Work, customer-directory, manual-expense and planned-expense factories now
recheck their owning session's lifecycle/capability. Disposed owners cannot create new
queries, and previously issued queries return no labels. Saved input is retained.

Focused checks verify a denied query performs zero reads, revocation while a read is
pending performs no payload decode/publication, and renewed authorization can read the
same saved input. A native four-domain test confirms each factory lists its draft before
owner disposal, refuses it afterward and leaves the database row intact. The first focused run
passed 15 checks; the second passed three query/lifecycle checks, two overlapping
with the first run.
All affected authored production files remain below 500 lines. Screens, widget trees,
SQL schema and payload formats are unchanged.

These are service callback and lifecycle checks using development permission fixtures.
They do not implement Firebase authentication, production account revocation or a new
identity authority. Device-wide preference recovery retains its separate device/device
scope; this checkpoint does not claim every authorization boundary is release-ready.
Core regression passed 171 checks and domain regression passed 201, with zero
failures and unchanged source (build/storage_qa/20260910T135010Z-72647c25/report.json).
Final Flutter analysis is clean and the normal Android debug build passes. The
migration goal remains active with the existing UI choices and completion gates open.
No commits, pushes, screenshots, inventory changes or 5.7 modifications.

## Android runtime and forced-termination checkpoint — September 10, 2026

The API 35 arm64 MaintainiacSizeAudit emulator passed the three shared restore tests.
A new standalone two-phase probe also verifies acknowledged DraftAutosaveSession raw
input after Android force-stop during a later uncommitted repository transaction. The
writer reported its checkpoint from PID 2655, was externally force-stopped, and the
new reader PID 2753 verified revision 1, exact raw amount/notes and SQLite integrity.
The uncommitted replacement did not survive. Successful read removed only its fixture.
This is OS termination evidence, not physical power loss or a visible editor test.

The first two-phase attempt through flutter test was INVALID: runner cleanup removed
the installation/fixture, and read correctly failed rather than reseeding. The fixture
was also moved out of Dart's Android code_cache into the dedicated QA package's private
support directory for the two-build protocol. This was test-lifecycle work, not a
production database reset or a demonstrated app autosave failure.

Android QA now requires STORAGE_QA=true and a separate .storageqa application ID.
A second isolation check caught Flutter reading the previous APK identity before rebuild
and targeting the normal package during cleanup on the disposable emulator. The new
run_android_restore_qa.py wrapper prebuilds, verifies the APK package using aapt, then
runs with --no-uninstall. The corrected wrapper passed three tests and the normal
application package remained installed afterward. Default APK identity was independently
verified as com.maintainiac.ui_lab_2_1. The normal app-support database is not opened by
these tests; package retention is not a complete user-data comparison. Use the wrapper,
not direct Android flutter test. Standalone interruption steps and evidence requirements
are documented in the shared QA README. A Kotlin import error in the initial QA build
configuration was corrected before these passing builds.

Full valid and invalid attempt logs plus a manual execution record are retained at
build/storage_qa/platform-20260910-android-restore-interruption/report.json. Sixteen
Python harness tests pass; the evidence fingerprint now includes QA Python helpers and
Android application-ID configuration. Only the dedicated QA package was removed during
final cleanup, and the emulator started for this work was shut down. Final normal APK
rebuild passes and Flutter analysis is clean. No screenshots, GitHub
commits/pushes, inventory integration or 5.7 modifications were performed.
The migration remains active; physical/older-device coverage, remaining recovery and
restore interaction, pending product choices and final completion audit remain open.

## macOS and iOS platform restore runtime checkpoint — September 10, 2026

The shared mounted restore contract now has a platform integration-test entry point:
integration_test/local_restore_runtime_test.dart. It invokes the same three tests rather
than duplicating their assertions. Flutter SDK integration_test and its test-tooling
transitive dependencies were added; application storage/media packages were not upgraded.

Actual macOS application execution passed all three cases. An iPhone 17e simulator on
iOS 26.5 also passed all three: restore/rollback, rejected draft writes and retry, and
failed reopen followed by explicit retry. These tests use ApplicationStartupScreen,
UiLabStartupController, the normal loader, temporary SQLite installations and the shared
switch coordinator. The fixture uses an external registered draft session and unsupported
notifications; it does not claim native notification delivery, visible invoice editing,
physical-device behavior, picker interaction, predictive gestures, OS process death or
power-loss validation. No screenshots or owner visual acceptance were obtained.

Full logs and a separately labeled manual execution record are retained at
build/storage_qa/platform-20260910-macos-ios-restore/report.json. The QA fingerprint now
includes integration_test sources; a regression proves changing a device-test entry point
invalidates its digest. Sixteen Python QA-harness checks pass and analysis is clean.
The shared harness README gives commands and distinguishes the platform gate from --all.

Normal macOS debug and unsigned iOS builds passed before these runtime tests. Platform
tests overwrite debug artifacts with a test entry point; normal lib/main.dart artifacts
were rebuilt successfully afterward for macOS and unsigned iOS. Only one simulator
was booted, and it was shut down after
verification. No normal app-support database, 5.7 files, commits or GitHub pushes were used.
The migration remains active; unverified device/interruption, restore interaction and
completion-audit requirements are not replaced by this checkpoint.

## Restore review and explicit confirmation service — September 10, 2026

LocalRestoreWorkflow now owns review identity, private-checkpoint path confinement,
manifest identity, installation revision, staging and switch invocation. Its displayable
LocalRestoreReview contains checkpoint identity, database size and retained-file count,
not Drift rows or widget state. Review verifies an existing private checkpoint without
activating it or staging a writable candidate. Confirmation re-verifies the exact
reviewed manifest and registered contents, checks the current installation/revision,
then prepares a fresh isolated candidate and invokes the existing switch coordinator.
Cancel, superseded reviews, invalid replacement choices, changed manifests, redirected
paths and duplicate operations cannot activate a different selection. Failed reopen
uses explicit retry of the recorded selection, never an automatic fallback.

Six workflow cases use real temporary checkpoint/selection storage with synthetic runtime
callbacks. These do not claim mounted shutdown or production account enforcement.
The focused combined run also includes the existing real-host restore tests: 15 checks
pass. Core regression passes 169 checks with zero failures and unchanged source:
build/storage_qa/20260910T131657Z-cb0f7e86/report.json. Final analysis is clean after a
constructor-style correction; the final Android debug build passes. The previous
editor checkpoint remains 135 passing checks;
that entire suite was not repeated for this isolated service addition.

The separate global-settings restore page is awaiting the owner's presentation choice.
No new UI is exposed, and no source picker, backup scheduling, external-file import,
cloud restore, account authority or export authorization is claimed by this service.
The owning application service must enforce access before exposing it. Production
interaction wiring and remaining runtime/completion gates are still unfinished.
No schema, visual layout, GitHub or 5.7 changes.

## Production startup host boundary — September 10, 2026

The normal main entry point now supplies UiLabStartupController to
ApplicationStartupScreen. Its installation runtime uses the real host attachment for
current application, entry-point blocking, frame completion and replacement. Generic
ApplicationHostController knows only presentation callbacks; UiLabStartupController
composes the existing lifecycle adapter. No screen receives SQL, Drift rows or a schema
from this connection, and no current route/layout identity is serialized.

The host blocks pointers, focus and the device accessibility tree while paused. It
intercepts platform back and incoming route messages before the child application.
ApplicationRoutePause additionally registers a pop guard on navigator-owned modal
routes while services drain. This is necessary because Flutter broadcasts predictive
back to observers rather than stopping after the first observer claims it. Pausing
makes native pop/gesture eligibility false; resume releases the guard. Route replacement
and disposal remove registrations. This is a reusable presentation safeguard, not a
persisted workflow state or visual redesign.

Nine focused combined checks pass. Restore success, rejected draft writes, rollback and
failed-reopen retry now run through ApplicationStartupScreen, replacing the earlier
StatefulBuilder test host. Phone/wide host tests inspect the actual accessibility tree,
keyboard focus, blocked taps, system back, incoming platform route information and
interaction after release. A mounted lifecycle check verifies route pop disposition,
gesture eligibility, retained route/input across resize, and navigation after resume.
A widget finder initially inspected retained semantic widgets rather than the exposed
device tree; that fixture was corrected. Initial compile/analyzer issues were resolved.

Broad regression passed: 163 core and 135 editor checks, zero failures, unchanged
source fingerprint (build/storage_qa/20260910T130529Z-5dee8b79/report.json).
Flutter analysis is clean and Android debug APK build passes. The existing Kotlin
plugin migration advisory remains nonfatal.
The next integration remains the user-facing restore selection/confirmation/retry
service and interaction; no new restore control is exposed here. Physical predictive
back, including gestures already in progress when pausing, and device interruption
coverage remain unverified. This checkpoint does not close the migration objective.
Existing calendar-day product choices and other completion-audit gaps remain open.
No commits, pushes, schema changes, screenshots or 5.7 modifications.

## Host callback failure cleanup — September 10, 2026

Input blocking now executes inside the mounted adapter's guarded pause operation.
Previously, a throwing host callback left adapter ownership set before the cleanup
handler was entered, making subsequent pause attempts unavailable. Both a partially
applied input-block callback and a failed frame-settling callback now release ownership,
request input unblocking, and permit a fresh pause. Neither failure closes storage or
starts presentation/loading. Two explicit host-contract tests cover these cases and
idempotent resume; they are synthetic callback tests, not production device enforcement.

Eleven focused host/runtime/coordinator checks pass; Flutter analysis is clean and
the Android debug build passes.
This is a correction after the preceding 161-core/133-editor checkpoint, not a claim
that that broader report includes the two new checks. Production host wiring remains
unfinished. No schema or visual changes were made.

## Mounted switch adapter and failure-injection harness — September 10, 2026

MountedApplicationSwitchRuntime adapts the application lifecycle to the existing
installation switch coordinator through mount/unmount, input-blocking and loading
callbacks. It contains no SQL, Drift rows, route names or layout keys. Presentation
must finish attaching/detaching before resource ownership changes. Failed draft flush
unblocks the old app; failed loading leaves the selected installation available for
explicit retry. A partially mounted replacement cannot start a second runtime.

Eleven focused checks passed in /tmp/uilab-mounted-switch-verified.log. Mounted tests
exercise successful restore/rollback, failed reopening and retry, and an actual SQLite
trigger rejecting draft insertion. The latter verifies unchanged selection, retained raw
input, released input blocking and successful retry followed by rollback recovery.
These use a mounted app with an external registered draft session, not a visible invoice
editor. The test host supplies pointer/focus blocking; this is not proof of complete
production back-button, accessibility or external-entry-point blocking.

The native widget helper now preserves original asynchronous exceptions instead of
causing an invalid Future.then error-handler return type. A dedicated regression covers
failure identity and subsequent success. Trigger setup/removal advances Flutter frames
and native I/O together; plain runAsync had waited on startup work queued on the test
clock. The stalled diagnostic runs were interrupted and are not counted as passes.

Broader regression passed with 161 core and 133 editor checks, zero failures/skips
and unchanged source fingerprint: build/storage_qa/20260910T124826Z-44d33bfd/report.json.
Flutter analysis is clean; Android debug APK build passed (9.2 seconds). The normal
ApplicationStartupScreen still loads once; production host integration and reviewed
restore interaction remain unfinished. No schema, visual layout, GitHub or 5.7 changes.

## Mounted application service and storage lifetime — September 10, 2026

Normal startup now owns ApplicationStorageLifecycle with private callbacks for domain
queues, draft flushing, storage queues and resource closure. UiLabApp attaches its
service-draining callback and detaches on disposal. Closing a mounted or unpaused prior
application is refused. Never-mounted successful loads can still be abandoned safely.
The app pauses notification input, defers source refresh, and drains media, submissions,
preferences and reminder actions before lower-level storage pauses. Notification read
mutations are serialized; pending native route delivery is drained without waiting for
the lifetime of a pushed screen. No widget identity is persisted and no visual layout
changed. New lifecycle code is split into descriptive, cohesive files below 500 lines;
app.dart is 465 lines.

Fifteen focused checks passed. A mounted native-storage widget test pauses, resizes from
390 to 1400 LP, refuses premature database closure and further draft input, resumes,
edits again, pauses/detaches and reopens the saved raw input. Unit coverage verifies
partial-pause unwinding and never-mounted closure. Final core 160 and editor 130 checks
pass with unchanged source fingerprint: build/storage_qa/20260910T122359Z-58354dbc/report.json.
Analysis is clean and Android debug build passes. Constructor-style analyzer notices
were corrected before final verification.

The host still needs to block entry points, invoke this lifecycle through the switch
runtime adapter, unmount/reopen the application and expose the reviewed restore action.
The existing startup host does not yet perform live switching. This checkpoint does not
claim user restore interaction, device power-loss validation or migration completion.
No commits, pushes, schema changes, screenshots or 5.7 modifications.

## Installation switch coordinator and failure phases — September 10, 2026

LocalInstallationSwitchCoordinator now sequences verification, runtime pause/flush,
close, selection commit and reopen through a storage-independent runtime contract.
Stale or invalid choices fail before touching the runtime. Failed pause leaves the old
selection unchanged. An uncertain close never resumes the old runtime or opens another
one in-process. A failed reopen retains the recorded selection and supports explicit
retry; rollback is explicit rather than an automatic fallback. Duplicate active requests
are rejected. Candidate and rollback-target validation are shared with the selection
service and rechecked before committing selection.

Fifteen focused switch/selection/startup tests pass. The runtime fixture uses real
SQLite and draft/storage pauses to prove an active raw draft is flushed before close
and survives explicit rollback. Other cases cover failed pause, uncertain close, failed
open/retry, duplicate requests and invalid/stale choices. It intentionally does not model
a mounted widget tree or all background services. Final core 158 checks pass across
38 files with unchanged source: build/storage_qa/20260910T121437Z-8735d7ed/report.json.
Analysis is clean and Android build passes.

The production mounted-application adapter for InstallationSwitchRuntime is still
unfinished. Application lifecycle ownership, event suspension/disposal, restore settings
interaction and runtime interruption tests must be connected before this is live restore.
No actual user installation was switched; no UI, schema, commits, pushes or 5.7 changes.

## Domain-service and storage queue pause order — September 10, 2026

Existing Work, directory, workday, day-note, receipt-submission, recurring-payment and
preference queues now expose the same pause capability as media/reminders. Local domain
repositories expose their queues, and LocalPersistence composes expense, recurring,
receipt and notification pauses in dependency order. The reusable sequential acquisition
helper releases already acquired pauses if a later acquisition fails, without releasing
another caller's existing lease. No new queue, storage schema or presentation policy
was introduced for those domain services.

Eighteen focused pause/atomic receipt/payment checks pass. A native fixture holds an
admitted outer expense staging operation while pause starts, then proves its inner
recurring/receipt staging can finish before the dependent queues pause. Another verifies
partial failure release and successful retry. The first test invocation had a mistyped
filename and missing extension imports; those test setup errors were corrected.
Final core 152 and domain 201 checks pass with unchanged source fingerprint:
build/storage_qa/20260910T120815Z-a8a709fc/report.json. Analysis is clean and Android
build passes.

These service controls are not yet acquired by a complete live-switch coordinator.
Entry-point suspension, event detachment, lifecycle ownership, old-runtime closure and
failed-reopen handling remain unfinished. Calendar-day placeholder behavior was raised
with the owner and remains unresolved; no calendar UI change was made. No commits,
pushes, business schema changes or 5.7 writes.

## Serialized media and reminder operation draining — September 10, 2026

SerializedAsyncActions now supports a held pause that immediately rejects new work,
waits for already admitted operations in order, and permits new work after explicit
idempotent release. Settled operations may have failed: their original callers retain
those errors; draining does not claim success or replay failed operations. Native media
coordination, receipt media sessions and native reminder controllers expose that pause.
The reminder controller now reuses the shared queue rather than a private serial tail.

Eighteen existing focused media/reminder/queue checks passed. Six final queue/native
checks include a real SQLite retention probe with a pending fake native picker: pause
waits for retained evidence, rejects new recovery, and resumes afterward. The authorization
callback and picker in that probe are fixtures, not production identity enforcement.
Core passes 150 tests in 36 files with unchanged source fingerprint:
build/storage_qa/20260910T120247Z-fd1e8a36/report.json. Analysis is clean and Android
debug build passes.

These are service lifecycle capabilities; live restore does not yet invoke them.
Application-level ordering, notification event detachment, non-draft domain operations,
connection closure and failed-switch recovery remain to be coordinated and tested.
An external picker that has not returned keeps the drain pending; no timeout is treated
as a successful save. No UI, schema, commits, pushes or 5.7 changes.

## Active draft pause and flush boundary — September 10, 2026

Each database now owns a DraftSessionRegistry, exposed through an optional repository
capability. LocalDraftStore instances for that database share it. DraftAutosaveSession
registers while active and unregisters on close or failed initialization. A pause blocks
new sessions and input, waits for initialization and queued writes, and stays held until
explicit release. Failed flush releases the pause and retains editable input for retry.
Discard is now tracked in the same operation queue so draining cannot overtake it.
No widget identities, layout keys, SQL types or domain-specific media rules enter this
registry contract. Existing repository-only tests still run without SQLite.

Twenty focused registry/autosave/boundary checks pass with clean analysis and an Android
debug build. Tests cover pending acknowledgments from multiple editors, refusal of new
editors, failed-write retry, pending initialization/discard, and shared native-database
registration. Core and domain groups passed before the subsequent one-line flush correction.
The first broader editor run was interrupted after a reproducible photo-note hang and
is recorded as failed/interrupted (20260910T114521Z-0e686431), not a passing regression.
The extra initialization await in an already initialized session was removed; pending
initialization is still awaited. Twelve focused photo-note/autosave/registry tests then
passed. Final corrected-source validation passed 147 core checks and 201 domain
checks (20260910T115636Z-ac13223e) plus 129 editor checks
(20260910T115414Z-95e59960), each with unchanged source fingerprints. Analysis is
clean and the corrected-source Android debug build passes. The earlier interrupted
report is retained and is not counted as a pass. The first compile failure was an interface promotion
issue corrected before validation; no visual expectations were altered.

This coordinates active draft sessions only. It is not yet called by a live-switch UI or
application lifecycle coordinator and does not drain background non-draft services.
It does not change existing failed-close recovery guarantees. Full application teardown,
failed-switch reopening, user restore interaction and all remaining gates stay unfinished.
No commits, pushes, schema changes, screenshots or 5.7 modifications.

## Installation selection process interruption — September 10, 2026

A bounded child-process harness now SIGKILLs a native Dart process after three exact
signals: an uncommitted control-row write, the real selection API acknowledgment, and
the real rollback API acknowledgment. Reopening retains revision 0, 1 and 2 respectively,
resolves the expected installation, and preserves both initialized business database
files. The uncommitted probe writes the control-row transaction directly; it does not
claim to exercise an injected pause inside the production select method. Committed
selection and rollback use the production APIs before termination, without graceful close.

Twelve focused interruption/selection/startup tests pass. Analysis is clean. The new
three-case interruption test is registered in the core harness. Initial fixture failures
were corrected for macOS canonical paths and normal SQLite WAL-header initialization;
no production behavior was changed to satisfy those assertions. This is native host
process evidence, not device power-loss, filesystem-loss or live editor shutdown proof.
No production files, UI, schema, commits, pushes or 5.7 content changed in this bundle.
Live switch orchestration and the remaining migration completion gates stay open.

## Selected installation normal startup — September 10, 2026

The normal application factory now resolves the private installation selection before
opening domain repositories and passes the selected attachment resolver into both local
persistence and application presentation scopes. Selection remains behind storage/startup
services; no screen or layout schema changed. A separate root marker detects loss of the
whole selection directory, so that case cannot silently return to the original database.

Sixteen focused startup/selection/cutover checks pass. Native startup coverage proves
selected raw input opens instead of newer original input, post-restore edits survive
reopening, explicit rollback returns to preserved original input, and missing selected
or control storage fails without recreating it. Analysis is clean; Android debug build
passes. Core: 139 tests, 33 files, unchanged source fingerprint, report
build/storage_qa/20260910T113757Z-d3c311ed/report.json.

This connects startup selection, not a live restore settings action. The app must still
coordinate editor flush, closure and activation, and verify process interruption and
failed-switch recovery. No real installation was switched; fixtures alone exercise
selection and rollback. All remaining migration gates stay open. No commits, pushes,
5.7 modifications or unapproved visual changes.

## Private installation selection service — September 10, 2026

LocalInstallationSelection stores the current and previous installation plus a revision
in a separate SQLite/Drift control database, using the existing durability configuration.
Selection validates a prepared restore and rejects stale revisions transactionally.
Explicit rollback validates its previous target and updates selection only; both business
databases remain intact. Missing selected storage is an error, not a fallback. The
control database uses the established-installation guard; missing selection metadata is
also an error. Paths are confined to prepared restore locations under the private root.

Six native tests cover selection/reopen/rollback, competing stale decisions, missing
selected storage, failed rollback, traversal and missing established control storage.
The core harness passed 136 tests across 32 files with unchanged source:
build/storage_qa/20260910T113452Z-9a8e087f/report.json. Analysis is clean.

This is an offline selection primitive, not live application switching. Startup does
not yet consult it. Its caller must drain editors, close the application connection and
coordinate failed-switch recovery; that orchestration and abrupt-termination tests remain
unfinished. No current user installation was selected or rolled back. No UI, business
schema, commits, pushes or 5.7 changes. The migration goal remains active.

## Established-installation startup guard — September 10, 2026

LocalPersistence now checks the database location before SQLite can create a file.
Existing files shorter than a SQLite header and redirected database paths are refused.
Missing main files are refused when an established-installation marker, SQLite sidecars,
retained evidence or checkpoint/restore directories remain. Nothing is reset or deleted.
Successful opens publish a flushed marker before handing repositories to the app; valid
older databases without that marker are adopted with no schema change. Clean first
launch remains supported. The guard and its tests are registered in the reusable harness.

Twenty-nine focused startup/domain/receipt tests pass, analysis is clean and Android
debug build passes. The core suite passes 130 tests across 31 files with unchanged
source: build/storage_qa/20260910T113046Z-beadea63/report.json. Native coverage verifies
raw draft preservation across legacy adoption, missing established storage, zero/short
files, sidecar/evidence remnants and database redirection without overwriting fixtures.

This is detection, not automatic repair or restore activation. Complete deletion of the
installation directory also deletes its marker and cannot be distinguished here from a
clean first launch. It does not claim protection from a hostile concurrent filesystem
writer or make pending input durable before SQLite acknowledgment. Remaining completion
gates are unchanged. No UI changes, commits, pushes or 5.7 writes.

## App widget draft and media boundary — September 10, 2026

UiLabApp now accepts DraftRepository rather than LocalDraftStore. Startup constructs
and injects the native media coordinator; the app widget no longer reaches through a
draft store to its database or constructs native media storage. Normal startup retains
the same receipt permissions, Work session and native device gateway. The presentation
boundary regression now includes app.dart for concrete draft/Drift imports and media
construction. This removes the identified app-level draft database seam, not all concrete
domain composition from the application root. No visual layout or schema changed.

Twenty-four focused checks pass, including estimate and receipt interrupted native
media recovery, PDF reselection, restored-startup settings recovery and existing cutover
contracts. Analysis is clean and Android debug build passes. Both modified production
files are below 500 lines (app.dart 434, startup factory 84). The broader editor suite passed 129 tests across 71 files with no failures/skips and
an unchanged source fingerprint: build/storage_qa/20260910T112334Z-c1aaad51/report.json.
These results do not establish full migration completion.
Activation/rollback, disconnected calendar-day settings, remaining workflow/platform QA
and the completion audit remain open. No commits, pushes or 5.7 modifications.

## Private checkpoint destination guard — September 10, 2026

LocalDatabaseSnapshot.capture now resolves the installation root and refuses a
redirected database_checkpoints directory before creating a candidate or copying SQL
contents. Regression coverage creates a symlink to an unrelated fixture directory and
proves no checkpoint is written there, its sentinel and link remain unchanged, and the
live database still passes integrity verification. Sixteen focused database snapshot,
bundle and restore tests pass; analysis is clean. This guards an existing redirection,
not hostile concurrent filesystem replacement by a process with the same OS privileges.
No UI, schema, commits, pushes or 5.7 changes. The calendar-day switches were rechecked:
they still hold widget-local state and do not affect the day screen, so they remain an
unfinished workflow, not merely a missing preference write.

## Historical attachment references across restore generations — September 10, 2026

Checkpoint manifests now carry optional historical reference aliases. Capture and
verification reject aliases that change the SQL-derived attachment identity, traverse
parent directories, or use malformed metadata. Older manifests without aliases remain
accepted. Prepared restore, reopen, and immutable file resolution preserve those aliases.
PreparedLocalRestore.captureCheckpoint binds the resolver and aliases to the matching
installation database, rejecting another installation before capture. No schema or UI
layout changed. The five affected storage implementation files are each below 500 lines.

Verification: 39 focused snapshot/restore/receipt tests passed, clean flutter analysis,
and Android debug APK build passed. The reusable core suite passed 117 tests in 30 files,
with unchanged source fingerprint: build/storage_qa/20260910T111923Z-777e72ab/report.json.
Coverage includes three successive restores after deleting preceding installations,
oldest-reference byte recovery, mismatched database rejection, malformed imported aliases,
and relocated receipt confirmation/replay. An initial test-only wrong named argument was
corrected before these results. Existing Drift debug multiple-database warnings remain.

A direct-import scan found no drift/local_database/local_draft_store/generated-row imports
in screens, shared widgets or shell. This supports the boundary for this change, not a
complete semantic UI-coupling audit. Live activation/selection, pending-editor draining,
restart-safe switch/rollback, all-workflow/platform validation and the completion audit
remain unfinished. The checkpoint API is private storage infrastructure, not a connected
user-facing backup/export feature. No commits, pushes or 5.7 Active changes.

## Checkpointing relocated receipt evidence — September 10, 2026

LocalSnapshotBundle.capture accepts the installation resolver when locating source
bytes, while retaining the exact registered-root and digest checks. Historical receipt
localPath metadata remains unchanged. The restored receipt integration now captures a
new checkpoint after confirmation/reopen and prepares a second installation; original
receipt references resolve to the correct bytes even though the original file is gone.
Twenty-seven submission/snapshot/verification tests pass; analysis is clean.

This is NOT complete multi-generation backup for all media. Attachment manifests derive
sourcePath from the current storage root, while older estimate photo references can
still name a preceding root. Those historical aliases need validated carry-forward
metadata before multi-generation Work photo restore can be claimed. Current checkpoint
callers must also provide the resolver; live activation/selection and rollback remain
unfinished. No commits, pushes or changes to 5.7 Active.

## Restored startup and receipt confirmation — September 10, 2026

Thirteen native/widget checks pass with clean analysis. The global-settings integration
now prepares a separate installation from a full startup snapshot, opens it through the
normal application factory, then recovers/edits/reopens Work settings at 390 and 1400 LP.
Atomic receipt coverage prepares/reopens a restored installation, removes the original
receipt file, confirms using relocated evidence, reopens again, and verifies replay adds
no duplicate command. The original database retains its unconfirmed receipt and input.

The initial new replay assertion incorrectly expected failure; the established command
contract returns the prior success. The corrected test verifies unchanged command count,
not a change to product behavior. The previously documented multiple-database debug
warning remains in snapshot tests. These are integration results, not active-installation
switching, interrupted switch/rollback, second-generation backup or physical-device proof.
Those requirements and the other local migration completion gates remain open. No product
code changed in this test bundle; no commits, pushes or 5.7 edits.

## Prepared restore reopening — September 10, 2026

PreparedLocalRestore.reopen reconstructs file references from the retained verified
checkpoint manifest, checks copied attachment bytes, rejects missing/redirected files
and validates the writable database without replacing it with the original snapshot.
The caller must select the installation; no directory scan activates a candidate.
The immutable parent checkpoint remains necessary mapping metadata and is not eligible
for cleanup while this installation depends on it.

Nineteen staging/verified-bundle checks pass; analysis is clean. Native coverage now
reopens after a restored draft edit and verifies that edit survives, rejects a missing
attachment and a same-content symlink, and refuses a missing database without creating
an empty replacement. Live database integrity remains intact. The separate database
instances in these tests continue to emit the previously documented Drift debug warning.
Full application startup from the prepared installation and durable selection/rollback
remain unfinished; this is not complete crash-safe activation. No commits/pushes/5.7 edits.

## Isolated writable restore preparation — September 10, 2026

`PreparedLocalRestore` stages a verified checkpoint and copies its database and all
attachments into a separate private writable installation, verifying copied digests and
database integrity before returning it. It maps historical file references to this new
installation, accepts canonical new attachment/receipt paths within it, and rejects
unknown former-installation paths and traversal. Historical JSON is unchanged. The
`path` package already locked at 1.9.1 is now an explicit dependency for path checks;
offline resolution changed its dependency classification, not its version.

Seven native staging checks pass, including opening and editing the restored database
while retaining newer live draft input and reading copied bytes after source-checkpoint
removal. Analysis is clean. This is preparation only: no live directory is switched,
no persistent activation pointer exists, the in-memory reference map is not restart
recovery, and full restored-application/submission/rollback verification remains open.
No Git commits/pushes or changes to 5.7 Active were made.

## Startup file-resolution composition — September 10, 2026

The application startup factory now accepts an installation path resolver, passes it
through LocalPersistence to receipt repositories, and installs it in the application
UI scope. Normal startup without a resolver retains existing path behavior. Scope
composition moved cohesively into `application_data_scopes.dart`; widgets still receive
no database/manifest structures. The owning expense dependency-map entry and source
contract test now account for that companion part instead of assuming one physical file.

Seventeen startup/menu integration, atomic receipt, dependency and size checks pass;
analysis is clean. Tests prove the resolver reaches a mounted editor through actual
startup and is invoked inside atomic staged receipt submission. This proves injection,
not full restored-database submission or activation. Earlier source-inventory failures
were caused by the extraction/expanded startup arguments and were corrected to inspect
the complete composition while preserving dependency assertions.

Preparing a writable restored installation, installing its verified reference mapping,
newly retained file handling, crash-safe activation and rollback remain outstanding.
No historical payload or schema changes, Git commits/pushes or 5.7 edits.

## Receipt submission file resolution — September 10, 2026

LocalReceiptDraftRepository.withStorage accepts an installation file resolver and
propagates it into staged submission/evidence repositories. Submission resolves the
retained path before the existing canonical-location, identity, byte-length and hash
checks; the resolver does not bypass any of those checks or change historical metadata.

Eleven atomic submission/evidence/size checks pass; analysis is clean. Native relocation
coverage removes the original file, verifies the mapped bytes, checks the original
reference remains unchanged, and rejects changed bytes and an outside-root mapping.
That relocation test uses a domain buffer for verification, not full restored atomic
submission. Existing atomic tests cover the ordinary path. A safe snapshot decoding/
ordering extraction keeps the repository at 480 lines. Initial size/analyzer failures
were corrected and the full focused command rerun successfully.

Startup still must install restore resolution and manage activation/rollback. This
component does not itself activate a snapshot or complete migration. No commits,
pushes or changes to 5.7 Active.

## Estimate thumbnail resolution — September 10, 2026

Estimate photo rows now use the shared installation path resolver and retain their
original WorkSitePhoto reference. Resolver failures and missing/undecodable files use
the existing unavailable thumbnail; no fallback to the original path occurs when a
resolver rejects it. Thumbnail dimensions and visual composition are unchanged.

Four path-selection/rejection, native photo-note recovery and size checks pass. Analysis
passed for the product change. The initial new test's direct file I/O stalled under the
widget clock; that known command was interrupted and fixture I/O moved to runAsync.
The corrected run completed successfully. The new test is in the editor harness.
Tests inspect FileImage target selection, not decoded restored-image visual acceptance.
Remaining receipt submission readers, restore activation and rollback still require
integration; no completion claim, Git push or 5.7 modification.

## Shared document resolution boundary — September 10, 2026

Shared receipt image/PDF previews now resolve retained references through
`LocalDocumentPathScope`; a supplied resolver is authoritative, and its failure shows
an unavailable state rather than reading the original path. Existing installations
without a resolver preserve their current behavior. PDF state is keyed to the resolved
path so a changed location does not retain the preceding document controller. No SQL,
manifest parsing or historical-payload rewrite enters the preview widget.

Ten resolver/receipt-review/evidence/size checks pass; analysis is clean. The new checks
verify image-provider path selection across resolver changes and no fallback on resolver
failure, not actual image/PDF rendering from a restored bundle. Native staged-file byte
verification is recorded separately. Tests are registered in the editor harness.
Restore activation must still install the verified map, integrate remaining readers
(including estimate photos and receipt submission), and implement durable rollback.
This boundary is not a completed restore. No commits, pushes or 5.7 modifications.

## Restore candidate file-reference mapping — September 10, 2026

`LocalSnapshotRestoreFiles` builds an immutable source-reference -> staged-file map
only after reverifying the reviewed candidate's database/manifest and attachments.
Unknown references fail closed; ambiguous mappings reject. This preserves historical
payloads and integrity hashes instead of rewriting device paths into audit records.
It does not authorize activation or resource access, and it is not yet wired into
normal evidence readers or the live-restore lifecycle.

Six staging tests pass, including opening staged file bytes after both the original
attachment and source checkpoint are deleted, unknown-reference rejection, and refusal
of an altered candidate attachment. Those deletions occur only in isolated test fixtures.
Analysis and diff whitespace checks pass. Resolver integration, durable activation and
rollback still remain; restore is not complete. No commits, pushes or 5.7 changes.

## Retired file startup helpers — September 10, 2026

Removed the four unused `openPrivate*Repository` helpers for expenses, recurring
expenses, receipt drafts and notifications. Repository-wide search found their
own definitions, negative boundary-test expectations and one stale documentation
reference, but no callers/imports. The owning migration-map entry now identifies
SQLite startup and the retained legacy file repository accurately. Compatibility
repository implementations and their tests remain; this does not claim every
prototype/in-memory/file path has been eliminated.

Ten startup/menu-integration and expense/notification boundary checks pass; analysis
is clean. Previous broad harness reports predate this removal. No business data,
5.7 files, Git commits or remote branches were changed. All completion gates remain.

## Combined editor checkpoint — September 10, 2026

Harness `20260910T104701Z-97595caf` passes all 125 actual editor tests across
69 files in 295 seconds, with zero failures, no missing/unfinished tests and unchanged
source. Live progress counts included successful loading events; the authoritative
harness report filters those and reports 125. This validates the registered editor
inventory, including the current recovery integration, rather than every product path.
The previous 307-test core/domain checkpoint predates the subsequent restore path guard;
seventeen focused restore checks cover that guard separately. These are distinct
checkpoints and must not be represented as one full-suite run.

Full discovered-suite baseline issues, current device/platform validation, restore
activation/rollback/path relocation, stock consistency, conflict handling and remaining
production-security/local ownership gates still prevent migration completion. Inventory
transfer has not started. No source edits occurred during this editor run; no commits,
pushes or changes to Maintainiac 5.7 Active were made.

## Restore staging path isolation — September 10, 2026

Restore staging now refuses a redirected `restore_candidates` directory before
creating/copying a candidate. Native regression creates that directory as a symlink
and proves rejection leaves the unrelated target contents and live draft unchanged.
Seventeen staging/verified-bundle checks pass; analysis and diff whitespace checks pass.
The run emits Drift's multiple-database debug warning when the existing staging test
opens a separate staged snapshot alongside live storage; `LocalDatabase.file` constructs
a separate background executor for each file. The warning was not suppressed.

Live activation/rollback and attachment path relocation still require implementation;
this path check is not a restore-completion or platform-runtime claim. The previous
core/domain checkpoint predates this correction. No commits, pushes or 5.7 changes.

## Current core/domain checkpoint — September 10, 2026

Harness report `20260910T104358Z-24bda824` passes all 307 tests across 102 files
(109 core, 198 domain), zero failures and unchanged source. This checkpoint includes
the current global-recovery integration and cleanup correction in its source fingerprint;
it does not claim the core/domain selection exercises every UI branch.

Current caller search across lib/test finds only definitions for the four old private
file-repository open helpers (expense, recurring, receipt, notifications), no callers.
This is evidence about those entry points, not blanket proof of zero file persistence:
media and snapshot files remain intentional, and other prototype/fallback paths still
require completion review. Restore staging explicitly does not activate a live snapshot.
`adb devices -l` currently lists no connected devices. Device validation is outstanding,
not a reason to block local implementation. No 5.7 modifications, commits or pushes.

## Recovery cleanup failure handling — September 10, 2026

The Saved work view now handles a workflow-close/flush exception without leaving its
opening flag set or emitting an unhandled asynchronous exception. It reports that recent
changes could not be saved and that the last committed draft remains. Generic navigation
failure no longer claims all input was kept. Release remains attempted on unmount.

A native injected UPDATE failure verifies the warning, re-enabled actions and reopening
of the previous committed setting. All three saved-work view checks and nine integration,
controller, navigation lifecycle and file-size regressions pass; analysis is clean.
This is a focused checkpoint, not a new platform or full-suite completion claim. All
outstanding local migration requirements remain active; no inventory transfer or Git push.

## Startup-to-global-recovery integration — September 10, 2026

`system_saved_work_integration_test.dart` uses the real startup factory with a fresh
SQLite directory and the full application/provider composition, then follows hamburger
menu -> System settings -> Saved work -> Work settings. At both 390 and 1400 LP it
restores a false setting, edits it, returns without confirmation, and reopens to observe
the retained new value while the confirmed preference stays absent. Both native widget
checks pass; analysis is clean. The test is registered in the reusable editor suite.

Only Work settings is covered by this full startup/menu integration checkpoint.
Other domain routes have separate focused evidence; this does not claim all-domain
menu coverage, production authentication, device visual acceptance or migration completion.
This bundle adds tests, not product changes; the preceding APK remains the product-code
build checkpoint. All outstanding completion gates below still apply.

## Global Saved work surface — September 10, 2026

Hamburger System settings now exposes Saved work when the composed durable hub is
available, with an explicit unavailable state for incomplete preview sessions.
`SavedWorkRecoveryScreen` presents service summaries through the recovery controller:
loading, complete empty, provider failures, retained unavailable/conflicting/unreadable
input, Continue, Refresh, and explicitly confirmed discard. Application dispatch receives
current prototype view capabilities, not new production authentication. Layout uses
AppLayoutEngine and preserves TextScaler; widgets do not serialize drafts or use SQL.

Two native widget checks at 390/1400 LP and 1.6 text scaling verify resume preserves
input, canceled discard retains it, confirmed discard removes only the draft, and no
confirmed preferences change. File-size guard passes. Twenty-nine surrounding shell,
application preference dispatch, lifecycle and boundary checks pass. Analysis is clean;
Android debug builds (9.0 seconds); diff whitespace checks pass. An initial test wait
settled while native refresh was active; its completion predicate now waits for enabled
actions and completion of loading. No visual layout was changed to satisfy that test.

The menu-to-editor path across every domain, device rendering and permission-change
lifecycle still require explicit integration/runtime validation. Conflict resolution is
not implemented: affected drafts remain retained, Continue is unavailable, and authorized
explicit discard is still guarded by the service. All wider durability/stock/restore/
security/platform/full-suite completion gates remain open. No 5.7 edits or Git pushes.

## Retired recovery list invalidation — September 10, 2026

A failed controller refresh now clears the previous listing. In particular, an
invalidated hub no longer leaves old draft titles visible or old entries actionable
through the controller. The new native-backed regression verifies both resume/discard
are rejected without reaching providers and the saved draft remains in its catalog.
Seven controller/hub/release checks pass; analysis and diff whitespace checks pass.
This is a controller correction, with no schema/UI composition change. The preceding
Android build predates this correction; no new platform/runtime claim is made here.
Global recovery UI integration and the other completion gates remain open.

## Application recovery dispatch — September 10, 2026

`application_recovery_routes.dart` now dispatches every currently registered typed
recovery family to its existing route. The caller supplies current expense, estimate
review, and material capabilities plus display context; the dispatcher grants no roles,
constructs no draft payloads, and knows no SQL/Drift rows. A finally block releases the
workflow even when navigation dependencies are absent or the originating context has
been unmounted. Domain routes retain their existing validation and editor ownership.

Twenty-six settings-through-application-dispatch/release/boundary/size checks pass.
Two additional native widget lifecycle checks prove missing Work scope and unmounted
context both release the workflow while preserving partial estimate discount `0.` and
creating no business record. The lifecycle checks are registered in the reusable harness.
This does not prove every dispatcher branch at runtime; domain route checks provide
separate evidence. Global recovery list UI and its dispatcher call remain unfinished.
No schema or visual layout changes, commits, pushes, or 5.7 edits.

## Job materials recovery routing — September 10, 2026

Selected material workflows now enter the existing job workspace/material editor via
`job_materials_recovery_route.dart`. The owning Work service validates job identity,
current access, session ownership and material capability equivalence before handing
off input. The controller keeps its serializer and confirmation closure; screens do
not construct stored payloads. Early disposal, normal Back, and failures close the
workflow without consuming the draft. No schema or visual composition change.

Native-backed route regression proves unfinished quantity `1.` survives Back and
reopen, with unchanged confirmed job revision and stock quantities. Replaced-session
and changed-capability handoffs reject without consuming input. Thirty-seven broader
material/job/permission/recovery/boundary/size checks pass; analysis is clean and
Android debug builds (9.5 seconds). Git diff whitespace checks pass. The
previous core/domain checkpoint predates this bundle and remains historical evidence.

This is recovery routing, NOT atomic inventory migration: existing stock mutation is
still applied after the durable job commit. Global recovery entry/dispatch remains
unwired, and that stock consistency gap plus all earlier completion gates remain open.
Inventory transfer from 5.7 has not started. No commits or pushes.

## Settings recovery handoffs and routing — September 10, 2026

All seven settings contexts accept selected typed workflows: Work, jobs, estimates,
invoices, receipt intake, reports, and expenses. Controller validators check repository
identity and canonical workflow identifiers; screens do not reconstruct draft payloads.
`preference_recovery_routes.dart` dispatches these workflows and closes them on normal
Back or failure, retaining input unless explicitly confirmed/discarded. Expense choices
retain their existing nested unfinished-state model. No schema or visual layout change.

Fourteen actual route tests verify Back/reopen after editing and rejection after store
replacement. Nineteen settings persistence/handoff/boundary/size checks pass, including
existing nested expense recovery and failed Save at phone and wide widths. Core/domain
harness `20260910T102113Z-2e74aac2` passes 306 checks across 102 files (108 core,
198 domain), with unchanged source. Analysis is clean; Android debug APK builds.
Initial test authoring had a missing required list argument, corrected to use the
recovery catalog. These are host/build results, not current physical-device acceptance.

Global recovery entry/dispatch integration, job materials selected routing, conflict and
orphan handling, restore/security/platform/full regression and the remaining completion
gates are still open. Inventory has not started; no commits or pushes were made.

## Estimate action routing verification — September 10 local, 2026

Estimate action routing now handles selected signature, delivery, company review and
item controllers. Current review authority is an explicit parameter; no role grant is
invented by navigation. Services validate current context before dispatch; every branch
closes the selected workflow on return/failure without confirming or discarding input.

Five signature/delivery route/handoff/size checks and four review/item route/handoff
checks passed. All four valid branches exercise normal Back/Keep unfinished and await
route completion; wrong-target cases retain input. Nested item input survives reopening.
Evidence: `/tmp/uilab-estimate-action-routes.log`,
`/tmp/uilab-estimate-review-item-routes.log`, `/tmp/uilab-estimate-routes-analysis.log`.

Preferences/material routes, global recovery UI, explicit conflict handling and original
migration completion gates remain unfinished. No schema/layout changes, commits/pushes,
or 5.7 writes. These focused routes are not current full regression/runtime acceptance.

## Estimate review/item selected handoffs — September 10 local, 2026

Estimate-review dialog and stored-item editor accept selected controllers. Review
validation checks current review authority/status plus session, record and decision;
item validation checks current edit authority/session/record. A missing Work session
cannot turn selected review input into a transient confirmation. Closing retains input.

Six review handoff/domain/size checks passed, including unchanged pending review and
wrong-decision rejection. Five item handoff/domain/detail-editor checks passed,
including nested partial quantity handoff/reopen, wrong-estimate rejection, stale-write
protection and existing nested editor confirmation. The handoff's nested-input assertion
checks the typed child input; the existing detail test supplies interaction coverage.
Analysis is clean. Logs: `/tmp/uilab-review-handoff.log`,
`/tmp/uilab-estimate-items-handoff.log`, `/tmp/uilab-review-items-analysis.log`.

Estimate-action route dispatch, preferences/material recovery integration, global
recovery UI and original completion gates remain unfinished. No schema/layout change,
commit/push or 5.7 modification.

## Estimate delivery/signature selected handoffs — September 10 local, 2026

Delivery and signature editors accept selected workflow controllers, validate current
Work session/access/domain/record identity through domain services and refuse transient
fallback for selected input without its Work session. Closing does not deliver, sign,
or consume input. Existing workflow serialization/confirmation rules are retained.

Nine focused handoff/domain/size checks passed. Four new native widget cases verify
partial recipient/customer-name restoration, further edits, wrong-estimate rejection,
retained drafts and unchanged confirmed estimate revisions. Existing normalized ink,
recipient-method and failed confirmation/reopen safeguards passed. These new handoff
cases do not individually test ink gestures or real delivery. Evidence:
`/tmp/uilab-estimate-actions-handoff.log`, `/tmp/uilab-estimate-actions-analysis.log`.

Estimate review/item handoffs and estimate action routing remain unfinished, as do
global recovery and original migration completion gates. No schema/layout changes,
commits/pushes or 5.7 writes.

## Directory recovery routing verification — September 10 local, 2026

Directory routing now dispatches company/client/employee/vehicle selections to their
existing editors after service-level session/access/record validation. Selected input
remains in the domain controller; no serialized payload or schema knowledge is used by
the router. It closes the workflow on return/failure. All four routed Back cases plus
the size guard passed, preserving edited draft names and unchanged confirmed profiles.

Android debug build passed (9.4 seconds) before a brace-only analyzer correction.
Final analysis is `/tmp/uilab-directory-routes-analysis-final.log`; route evidence is
`/tmp/uilab-directory-routes.log`, build evidence `/tmp/uilab-directory-routes-build.log`.
This is not current full-suite/runtime acceptance. Remaining estimate action, preference
and material routing/global recovery integration and original completion gates remain
unfinished. No layout/schema changes, commits/pushes or 5.7 writes.

## Directory editor handoffs and Workday route validation — September 10 local, 2026

Start/end Workday recovery routes now pass normal exit tests preserving partial input,
without starting/ending work or updating confirmed odometer data. Fourteen combined
route/catalog/architecture/size checks passed (`/tmp/uilab-workday-routes.log`).

Company, customer, employee and vehicle editors accept selected typed controllers.
A shared directory service validates session/domain/access and record context; selected
input without its durable directory cannot enter a transient save path. Client recovery
bypasses the ordinary draft chooser. Editors own closing their selected workflows.
There are no database rows, SQL or serialized layout keys added to presentation.

Twenty-six combined native handoff/workflow/confirmation/catalog/boundary/size checks
passed, including edited-name retention, unchanged confirmed profiles and wrong-record
handoff rejection for client/employee/vehicle. Initial new-test import/field-selector
errors were corrected. Evidence: `/tmp/uilab-directory-handoff-final.log` and
`/tmp/uilab-directory-handoff-final-analysis.log`. Directory route dispatch is still
unfinished. Global recovery, other remaining workflows and original completion gates
remain open. No schema/layout changes, commits/pushes or 5.7 writes.

## Start-workday handoff and Workday routes — September 10 local, 2026

Start-workday editing accepts a selected controller, validates domain/session/access,
and restores its raw employee/vehicle/odometer context before registering input
listeners. Selected recovery cannot fall back to transient saving without Workday
persistence. Three focused handoff/existing recovery/size checks passed. The new native
case verifies Admin recovery restores Jordan/service-van-4 over a different current
selection, retains partial mileage edits, and creates no workday. An initial test
used technician view, which intentionally fixes the employee and rejected the different
employee; that existing view constraint was preserved, not changed to satisfy the test.

Typed start/end recovery routing is now implemented, validates before navigation and
closes on return/failure. Direct handoffs are tested; new route-level tests are still
needed for both Workday branches. Evidence: `/tmp/uilab-start-workday-handoff-final.log`
and `/tmp/uilab-workday-handoff-analysis.log`. No schema or visual layout changes.
Global recovery and original migration completion gates remain unfinished; no commits,
pushes or 5.7 changes.

## End-workday selected handoff — September 10 local, 2026

EndWorkdayDialog accepts an already-selected controller and retains its raw odometer
input instead of reopening from today's dashboard state. Workday service validation
checks organization/actor/domain, target workday, employee/vehicle access and refuses
closed workdays. A selected controller without its durable session cannot enter the
transient confirmation path. Closure retains the unfinished draft.

Six focused handoff/workflow/catalog/size checks passed, including partial odometer
restoration, further saved edits, wrong-workday rejection and unchanged active workday
and confirmed odometer. Existing rollback/reopen/atomic confirmation and catalog tests
passed. Evidence: `/tmp/uilab-end-workday-handoff-final.log`; analysis is recorded in
`/tmp/uilab-end-workday-analysis.log`. Start-workday handoff and workday recovery routing
are still unfinished, as are the global recovery UI and original completion gates.
No schema/layout change, commit/push or 5.7 modification.

## Day-note selected recovery and routing — September 10 local, 2026

Day-note editing accepts a selected controller and validates organization, actor,
workflow domain, employee/date context and current creation access in its service.
Canonical date formatting is shared with ordinary draft opening; no payload/schema
change. Its presentation route derives the day/employee from typed input, accepts a
presentation label and session, and closes the workflow on return/failure.

Seven handoff/domain/catalog/size checks passed. The routed valid and wrong-date
cases then passed, including Keep unfinished return, retained exact text/time/date,
and unchanged confirmed-note count. Existing Dashboard and Calendar Day recovery/
failed-confirmation cases also passed. An initial route-test missing local variable
was corrected; final route evidence is `/tmp/uilab-day-note-route-final.log`.
Analysis: `/tmp/uilab-day-note-route-analysis.log`. Other evidence:
`/tmp/uilab-day-note-handoff.log`, `/tmp/uilab-day-note-route.log` (records the initial
test-load failure alongside the two passing existing editor cases).

No visual layout change, database migration, commit/push or 5.7 writes. Global
recovery integration and the original migration completion gates remain unfinished.

## Combined recovery route exit verification — September 10 local, 2026

Fifteen combined checks passed across seven files, including notes/schedule actual
route dispatch and Keep unfinished exit, assignment route exit, invoice payment route
exit, primary invoice/job route exit, estimate handoff, late recovery cleanup and source
size. Drafts retain edited raw input and confirmed records remain unchanged in these
cases. `git diff --check` is clean. Evidence:
`/tmp/uilab-combined-recovery-routes.log`. The notes/schedule dispatcher verification
gap recorded below is now covered; no product layout changed for these tests.

The global recovery interface is still absent. Job-material input currently opens
through the owning workspace with prototype stock validation/application outside the
record transaction; generic recovery must not bypass that dependency or represent it
as atomic inventory integration. Remaining secondary and directory/workday/preferences
handoffs, global recovery UX, conflict/restore/security/platform and original completion
gates still apply. No commits, pushes, or 5.7 changes.

## Assignment handoff and job-details routes — September 10 local, 2026

Assignment recovery accepts a selected workflow, checks its current job/session/access
through the Work service, and refuses transient fallback when a recovered workflow
has no Work session. Five handoff/domain/size checks passed, covering changed unconfirmed
choices, wrong-parent rejection and retained drafts without confirmed revision changes.

Job-details presentation routing now handles selected notes, schedule and assignment
controllers using the existing dialog/sheet components. It validates before navigation
and closes on return/failure. Materials explicitly require a separate item-workspace
route; they are not silently opened in an unrelated editor. The assignment route passed
normal Keep unfinished assignment exit and retained-choice verification; notes/schedule
have direct handoff tests but their new dispatcher branches still need route-level QA.

Evidence: `/tmp/uilab-assignment-handoff.log`, `/tmp/uilab-assignment-route.log`,
`/tmp/uilab-job-details-analysis.log`. Global recovery UI, other routes and original
completion gates remain unfinished. No schema/visual layout changes, commits or 5.7 writes.

## Payment routing and job action handoffs — September 10 local, 2026

Invoice payment recovery now has presentation routing through its selected controller,
with current access/identity validation before navigation and guaranteed workflow closure
on return/failure. Its routed widget check verifies normal Back and retained partial
amount without posting. Three payment-route/size checks passed.

Job notes and schedule editors now accept selected controllers. Work-service handoff
validation checks organization, actor, domain, parent identity and current edit access.
Missing Work sessions cannot silently use the transient editor path for selected input.
Four new native widget cases exercise matching/wrong-parent handoffs, subsequent notes
and partial-time autosave, draft retention and unchanged confirmed revisions. Combined
with existing notes/schedule recovery and identity regressions, seven checks passed.
Analysis is clean. Logs: `/tmp/uilab-payment-route.log`,
`/tmp/uilab-job-action-handoff.log`, `/tmp/uilab-job-action-analysis.log`.

No visual composition/schema changes, commits or 5.7 writes. Remaining job actions,
other workflow routing, global recovery UI and the original migration completion gates
remain open; focused results do not replace the earlier broad fingerprint or runtime QA.

## Invoice payment handoff checkpoint — September 10 local, 2026

The payment editor accepts an already-selected InvoicePaymentDraftController and
owns closure without posting or discarding on exit. The Work service checks actor,
organization, workflow domain, invoice identity and current payment visibility/access.
Missing durable Work sessions do not fall back to transient payment entry when a
recovered controller was supplied. Storage serialization remains in the workflow;
no visual layout or schema changed.

Eight focused handoff/payment/recovery/size checks passed. New native widget cases
verify partial amount restoration, later raw edits, wrong-invoice rejection and
unchanged financial-entry count/balance. Two initial test-authoring errors (unsupported
fixture copyWith argument and TextFormField assumption for an existing TextField)
were corrected; no product behavior was weakened. Analysis was clean before the
final test-only correction. Evidence: `/tmp/uilab-payment-handoff-final.log` and
`/tmp/uilab-payment-handoff-analysis.log`. Global recovery routing/UI, other handoffs
and original completion gates remain unfinished. No commits/pushes or 5.7 changes.

## Application recovery cleanup checkpoint — September 10 local, 2026

Added application-owned recovery release dispatch for all currently registered
workflow result types and a recovery-controller factory that always installs it.
A future recovery view can dispose while opening without implementing domain-specific
cleanup itself. Closing retains unfinished input; unsupported result types fail
explicitly rather than silently leaking a controller. This is infrastructure for
the still-unfinished global recovery screen, not completed UI integration.

Fifteen focused controller, native release, architecture and size checks passed.
The two release checks passed again using the application factory. Native SQLite
evidence covers a late estimate result after view disposal, retained partial input,
no business confirmation and successful reopen; it does not individually exercise
every release branch. Analysis was clean before the factory-only addition. Logs:
`/tmp/uilab-recovery-release-tests.log`, `/tmp/uilab-recovery-release-final.log`,
`/tmp/uilab-recovery-release-analysis.log`. No schema/layout/5.7 changes or commits.
The broad checkpoint below predates this addition; original completion gates remain.

## Work recovery combined regression — September 10 local, 2026

Checkpoint `20260910T093911Z-2bc65b2e` passed 304 core/domain checks across
101 files (106 core, 198 domain), with unchanged source during execution.
The subsequent test-only route-exit adjustment scrolls the existing invoice Back
control into view before tapping it; both invoice/job routes then passed normal
Back, awaited route completion, and retained-draft checks. The earlier test failure
was an offscreen tap, not a persistence failure; no product layout was changed.
Evidence: `/tmp/uilab-work-route-exit.log`. The broad fingerprint precedes this
single test adjustment. Full editor/full-suite/platform completion remains open.

## Primary Work editor handoff checkpoint — September 10 local, 2026

Estimate, invoice and job editors now accept already-selected typed workflow
controllers. They bypass ordinary draft selection, restore domain input, and own
workflow closure without consuming unfinished input on exit. Work services validate
session organization/actor, workflow domain, current access and the relevant parent
identity before the editor binds input. Missing Work sessions fail closed for these
handoffs. No visual layout or schema changes.

A presentation dispatcher now routes primary Work recovery through these controllers;
it closes workflows on navigation return or failure. The global recovery screen is
still not wired. Invoice/job route checks verify retained edits without confirmed
record creation; estimate checks verify exact partial input, independent drafts and
rejection of mismatched creator context. This is not production account enforcement.

The estimate bundle passed 16 focused checks. The combined handoff/domain/boundary/
size run passed 20 checks (`/tmp/uilab-work-handoff-final.log`). Initial test-authoring
errors were corrected; two analyzer brace findings were corrected. Final analysis
is recorded in `/tmp/uilab-work-handoff-analysis.log`. Broader regression/build and
runtime validation remain due; these results do not replace the previous fingerprinted
broad checkpoint. Remaining secondary/domain routing, global recovery, conflict review,
restore/security/platform and original completion requirements remain open. No commit
or push; inventory has not started and 5.7 remains read-only.

## Expense recovery route dispatcher checkpoint — September 10 local, 2026

Expense recovery now has presentation-only dispatch for manual/corrected expenses,
receipt expense/evidence review, planned-expense templates, occurrence edits and
payment entry. Routes take typed controllers rather than reconstructing payloads.
Recurring parent display records come through the controller's fresh authorized
read; unavailable parents fail before navigation. Workflow closure is guaranteed
on route return/failure, without consuming unfinished input. Explicit UI permission
input remains required; no development grant is invented inside this dispatcher.

Seven focused checks passed. Existing planned and recurring handoff tests now
exercise dispatch directly; the planned case verifies Back and route completion.
Manual/receipt handoff and size regressions also passed. Analysis was clean before
the final test-only dispatch adaptation. Logs:
`/tmp/uilab-expenserecoveryroutes-focused.log`,
`/tmp/uilab-expenserecoveryroutes-regression.log`, and
`/tmp/uilab-expenserecoveryroutes-analysis.log`. Global recovery screen integration
and other domain routing are still unfinished; this is not a completed user flow.
No visual layout/schema change, inventory remains pending, 5.7 untouched.

## Secondary expense editor handoff checkpoint — September 10 local, 2026

Receipt evidence review, recurring occurrence editing and payment entry now accept
already-selected typed workflows, verify the target/session and retain existing
confirmation behavior. Their editor owns closure; merely leaving preserves input.
No visual layout or schema change. New widget cases verify partial payment amounts,
subsequent autosave without payment/schedule mutation, and evidence-removal undo
state without changing retained source evidence.

Three new handoff checks passed, plus four existing evidence/occurrence/size checks;
analysis is clean. The initial test run had a parenthesis error in a new test only.
After correcting it, two cleanup waits exposed Flutter fake-clock/native callback
coordination: blocking runAsync could not advance disposal's queued stream closure.
A bounded finishNativeOperation helper now pumps both; all three new tests finish
in about one second. Diagnostic waits were stopped and replaced with bounded tests;
no production durability behavior was weakened to pass them. Evidence:
`/tmp/uilab-secondaryhandoff-focused.log` (four existing passes and initial test load
failure), `/tmp/uilab-secondaryhandoff-recheck.log` (three final passes), and
`/tmp/uilab-secondaryhandoff-analysis.log` (clean). Full regression/build remain due
at the user-flow milestone. Global recovery list/dispatch, other editor handoffs,
conflict review and earlier completion gates remain open; 5.7 untouched.

## Expense editor handoff checkpoint — September 10 local, 2026

Planned expense, manual expense/correction and receipt-review editors accept typed
already-selected workflow controllers. They bypass their ordinary draft picker,
restore typed unfinished input and retain the existing confirmation/autosave path.
Ownership transfers to the editor, which closes the workflow on exit. Context checks
reject mismatched company/actor/record or receipt targets. These are controller
handoffs, not database row/SQL dependencies or a visual layout redesign.

Seven focused widget checks passed across new handoff tests and existing planned,
manual and correction recovery tests. New cases verify a chosen plan among multiple
drafts, exact partial amounts, subsequent edits retained on exit, no extra picker,
and no unintended business confirmation. Analysis of the edited production source
was clean. Logs: `/tmp/uilab-planhandoff-focused.log`,
`/tmp/uilab-expensehandoff-focused.log`, and matching analysis logs. These are focused
checks, not current full regression/platform/visual acceptance. Global recovery list
and dispatch, other editor handoffs, conflict review and earlier completion gates
remain open. Inventory has not started; 5.7 remains untouched.

## Recovery interaction controller checkpoint — September 10 local, 2026

DraftRecoveryController separates loading/action state from the eventual recovery
screen. Refresh generations prevent older query results replacing newer results;
actions require a currently listed selection and exclude overlapping operations.
Failed discard retains its entry; successful acknowledgement removes it. Disposing
while resume is pending releases the returned workflow through a required owner
callback without discarding input. Error messages omit raw storage exceptions.

Four focused controller/hub checks and clean analysis passed; logs are
`/tmp/uilab-recoverycontroller-focused.log` and
`/tmp/uilab-recoverycontroller-analysis.log`. This controller is not yet wired into
a global-settings recovery screen. Route dispatch, user conflict review, broader
runtime/completion requirements and the later inventory stage remain open. No
schema/layout change; no broad rerun for this intermediate interaction bundle.

## Recovery session lifetime checkpoint — September 10 local, 2026

ApplicationRecoveryHost is wired into UiLabApp scopes. Provider identity survives
presentation rebuilds; changing session dependencies or unmounting invalidates old
hub entry points. A retired hub rejects list/resume/discard and suppresses pending
list results. Already-dispatched domain operations retain their existing transaction
semantics; this is not production permission-revocation infrastructure. Native widget
verification exercised layout rebuild, preference-session replacement, selection
resume and retirement while retaining the saved draft. Transient previews lacking
required durable dependencies expose no hub. Current development grant policies
are preserved, including estimate review mode and existing job material grants.

Checkpoint `20260910T090859Z-03f87b12`: 301 core/domain checks across 100 files,
three focused host/hub/size checks, clean analysis and Android debug build with
matching source/APK evidence. No current full-suite/runtime acceptance. Next work:
global-settings recovery interface and workflow dispatch, conflict review, then the
remaining previously documented completion gates. This does not finish migration
or authorize inventory to begin before the local completion audit. 5.7 untouched.

## Recovery aggregation checkpoint — September 10 local, 2026

DraftRecoveryHub aggregates service-owned selections without recreating them in a
foreign catalog. Each resume/discard returns to the original authorized provider;
foreign hub selections are rejected. Listing retains successful results while
explicitly reporting unavailable providers, with no raw exceptions or payloads.
The application composition function requires all eleven supported domain services.
It contains no SQL, widgets or routes. Startup/global-settings UI wiring is still
unfinished; this is a tested service boundary, not a delivered recovery screen.

Sixteen focused hub/catalog/repository-boundary/size checks and clean analysis
passed. Native integration covers reopened expense and receipt drafts, partial
provider failure, cross-session rejection, stale-discard protection and explicit
discard without business confirmation. Logs: `/tmp/uilab-recoveryhub-focused.log`
and `/tmp/uilab-recoveryhub-analysis.log`. Current broad regression/build/runtime
remain due at the combined user-flow milestone. No layout/schema changes; all
prior completion gates and inventory work remain open, with 5.7 read-only.

## Receipt workflow recovery checkpoint — September 10 local, 2026

ReceiptWorkflowDraftRecovery registers receipt expense review and evidence review
as distinct saved-input workflows. Current scoped receipt lookup checks permissions,
state and source revision without modifying the receipt projection. Typed selected
factories reject missing/stale selections before seeding and use fresh retained
sources. Discovery/resume never submits expenses or changes evidence. A changed
source yields conflict; a submitted/discarded source retains input but blocks resume.
Raw amount text and evidence-removal undo state remain unchanged across reopen.

Sixteen focused catalog, workflow, repository-boundary and size checks passed;
analysis is clean. Logs: `/tmp/uilab-receiptcatalog-focused.log` and
`/tmp/uilab-receiptcatalog-analysis.log`. The catalog regression exercises both
workflows, revision selection, independent source updates, closed sources and
explicit input discard. No layout/schema changes or runtime acceptance. Broad
regression/build remain due at the combined recovery milestone. Unified provider
aggregation and UI, explicit conflict resolution, other recovery/completion gates,
platform/security and inventory stages remain unfinished. 5.7 remains untouched.

## Recurring recovery integration checkpoint — September 10 local, 2026

RecurringDraftRecovery registers new plans, plan edits, occurrence edits and payment
input, returning typed controllers without navigation/SQL details. Fresh scoped
service reads check parent and occurrence revisions/state; selected factories read
current parents without changing projection caches and verify exact draft selection
before seeding. Discovery/resume do not pay expenses or change schedules. Changed
parents produce conflicts; closed/skipped occurrences retain input but block resume.
New-plan creator identity follows the existing workflow rule. Device/demo grants
remain separate from production account enforcement.

Ten focused workflow/selection/catalog/size checks passed. The expanded catalog
recheck also passed all four reopen cases, stale selection rejection, independent
session revision changes, skipped occurrence rejection, retained raw input and
explicit discard. Analysis is clean. Evidence: `/tmp/uilab-recurringcatalog-focused.log`,
`/tmp/uilab-recurringcatalog-recheck.log`, `/tmp/uilab-recurringcatalog-analysis.log`.
No broad suite/build was repeated for this intermediate registration bundle; these
remain required at the combined recovery milestone. Receipt registration, unified
recovery, conflict resolution and all earlier completion gates remain outstanding.
No schema/visual layout changes; inventory remains pending and 5.7 untouched.

## Expense recovery integration checkpoint — September 10 local, 2026

New and correcting manual expenses now have a presentation-independent recovery
catalog. Fresh authorized repository lookup detects changed/deleted parents without
relying on, or mutating, the visible list cache or date filter. Selected correction
opening uses that fresh parent and validates domain/ID/revision before seeding.
Manual and planned expense factories both have exact selected-recovery guards.
Draft input remains unchanged across reopen/resume; stale/consumed selections are
refused, and malformed owned input is retained as unreadable. No UI/schema change.

Focused verification: nine manual/planned workflow and selection checks passed in
`/tmp/uilab-expenseselection-focused.log`. Expense catalog, workflow, selection,
size and permission verification produced 14 passes and one test assertion error
(the permission denial was synchronous); after correcting only that assertion, all
three catalog checks passed in `/tmp/uilab-expensecatalog-recheck.log`. Analysis was
clean before that test-only correction. Broader regression/build are deliberately
reserved for the combined recovery milestone to avoid redundant runs. The latest
fingerprinted broad checkpoint remains `20260910T084729Z-ecd6fdab`, not current-source
proof. Recurring/receipt catalog registration, global recovery, conflict review and
the previously listed completion gates remain unfinished; inventory has not begun.

## Preference recovery catalog checkpoint — September 10 local, 2026

PreferenceDraftRecovery exposes typed resumed workflows and safe catalog previews
for all seven settings contexts, without SQL/generated rows or navigation/widget
state in its public interface. The catalog supports selection-aware inspection so
canonical domain/ID/revision are verified before opening existing input. Existing
codecs are reused and sessions closed immediately during discovery; nothing is
confirmed or seeded by listing. A fresh repository read checks saved baselines
against current metadata without publishing changes into a stale controller cache.
Legacy drafts remain unchanged on discovery/resume and are labeled for review;
unknown identities or malformed input remain visible as unreadable, not replaced.
Explicit discard retains the existing scoped revision check. Device scope is not
production account authorization. Conflict resolution UI remains unfinished.

Evidence: `20260910T084729Z-ecd6fdab`, 291 core/domain checks across 94 files,
34 focused/editor/boundary/size checks, clean analysis and Android debug build,
with matching source fingerprint/APK hash. No new schema or visual layout changes.
This selected checkpoint does not replace the historical full-suite result or
prove runtime acceptance. Expense/receipt registration, global recovery, restore,
platform/security and completion gates remain; inventory has not started.

## Preference confirmed-value baseline checkpoint — September 10 local, 2026

PreferenceDraftWorkflow now retains a confirmed-value baseline with raw input,
limited to the owning workflow's preference keys. The same ownership map validates
store confirmation, replacing duplicated key allowlists. LocalAppPreferencesStore
reads and compares that baseline with current values inside the settings-write /
draft-consumption transaction. A same-key direct write or stale repository cache
cannot silently overwrite newer settings through a retained draft. Conflict rolls
back draft consumption and keeps input/revision unchanged; unrelated keys merge
without being copied into another workflow's baseline. Reopen retains the original
baseline rather than silently refreshing it to the newer settings.

Legacy payloads without a baseline remain unchanged on opening. Their first edit
or explicit confirmation persists the captured baseline, with existing field values
preserved; malformed legacy input is still refused without replacement. There is
no historical baseline for changes predating that first opening, so this is not
proof against pre-upgrade conflicts. That limitation and explicit conflict review
remain part of the global recovery completion work. No SQLite schema or visual
layout changed; the raw draft envelope has an additive reserved baseline field.

Thirty-six focused checks and seven connected settings-editor regressions passed,
including conflicting direct writes across reopen, stale cache, unrelated-key
preservation, legacy report retry, all selected recovery guards, failure/retry,
unfinished choices and boundary/size checks. A new test initially used unsupported
`imperial` rather than stored `us`; the fixture was corrected and the final run
passed. All 288 core/domain checks across 93 files passed with unchanged source
(`20260910T083754Z-07693dc4`), clean analysis and Android debug build (9.2 seconds),
with matching source/APK evidence. No current device/runtime acceptance or full-
suite rerun is claimed. Protected 5.7 remains untouched.

Preference catalog registration and explicit conflict-resolution presentation,
expense/receipt registration, global recovery integration, restore/platform/security
and the original completion gates remain unfinished. Inventory has not started.

## Preference selected-recovery guard checkpoint — September 10 local, 2026

PreferenceDraftWorkflow and the five typed opening APIs now accept an explicit
DraftRecoverySelection. The seven stable settings drafts (Work home, receipt,
report, expense, and jobs/estimates/invoices lists) verify domain/ID/revision and
retained input before seeding. Selection cannot redirect a workflow to another
settings ID. Missing or consumed selection fails without recreation; normal
unselected opening retains existing initialization and codecs. No schema or
visual layout changed, and these device preferences do not grant account access.

Twenty-five focused checks passed, including all seven native reopen/selection
cases, wrong domain/ID/revision refusal, consumed selection, unchanged confirmed
preferences, independent new opening, existing atomic confirmation/unfinished
choice behavior and boundary/size checks. All 285 core/domain checks across 92
files passed with unchanged source (`20260910T083035Z-03a77208`), clean analysis
and Android debug build (9.0 seconds), with matching source/APK evidence. No
current device/runtime acceptance or full/editor-suite rerun is claimed.

Preference catalog registration is still unfinished. Confirmation consumes the
exact draft atomically, but the store merges proposed keys over a fresh metadata
read without a captured confirmed-value baseline. A separate direct preference
write may therefore be overwritten by an older retained proposal; the current
connected draft path's revision guard is not proof against that different path.
Inspection found direct APIs and preview/fallback callers, not a demonstrated
normal connected-UI reproduction. Resolve/test this concurrency boundary before
claiming preference recovery complete. Expense/receipt registration, global
recovery integration, restore/platform/security and original completion gates
remain open. Inventory has not started; 5.7 remains untouched.

## Exact mileage confirmation checkpoint — September 10 local, 2026

The preceding workday mileage conversion finding is corrected. A shared domain
parser converts explicit miles directly to integer tenths using decimal digits,
without floating point or rounding. Start/end workday controllers and their
presentation validation both use it; vehicle profile confirmation uses the same
parser with its existing strict trailing-decimal rule. Workday retains explicit
confirmation compatibility for whole-mile input such as `12,345.`. Excess decimal
places, malformed grouping, signs, exponent/non-finite values and readings above
9,999,999 miles are rejected instead of silently changing the value. Existing
validation messages, maximum and blank vehicle-reading behavior remain. Raw draft
text and existing confirmed history are not rewritten or inferred.

Twenty-four focused checks passed, including exact parser boundaries, start/end
reopen after invalid precision/grouping/exponent input, unchanged records/mileage
on rejection, exact corrected-value confirmation, existing atomic retry and
connected Workday/vehicle editor flows, architecture and source-size checks.
All 278 core/domain regressions across 91 files passed with unchanged source
(`20260910T082619Z-84f1ead8`), clean analysis and Android debug build (9.0 seconds),
with matching source/APK evidence. No schema or visual layout changed. No current
device/runtime acceptance or full-suite rerun is claimed; protected 5.7 untouched.

Preference/expense/receipt recovery registration and combined global recovery
integration remain unfinished, alongside restore/platform/security and the original
completion gates. Inventory has not started. Next inspect preference workflow
identity, recovery and concurrent confirmation before registering its device-scoped
recovery; device preferences are not production account permission enforcement.

## Workday/day-note recovery and mileage-query correction — September 10 local, 2026

WorkdayDraftRecovery and DayNoteDraftRecovery register start/end and immutable
calendar-note creation through existing domain controllers. Explicit selection
checks domain/ID/revision before seeding. Recovery does not start/end work, enable
GPS or publish a note. Workday discovery checks current records and mileage in one
read transaction; occupied start context, changed revisions and ended/missing
parents retain input. Day-note discovery checks only the selected note ID, retains
its civil date/employee/time and refuses an already-published identity. Malformed
dates are isolated; inaccessible employee/vehicle input is not exposed. Existing
development capabilities remain distinct from production authentication.

This bundle also corrects the preceding directory recovery reader: odometer rows
are owned by vehicle ID, not company ID. The original test only asserted conflict
after mileage advanced, so it missed an already-conflicted initial state. The query
now uses vehicle ownership and validates the reading; the strengthened native test
asserts initial revision 1, recoverability and exact resumption, followed by revision
2 and conflict after independent workday advancement. The preceding checkpoint's
passing count did not prove that initial mileage recovery behavior was correct.

Twenty-four focused checks plus four affected editor regressions passed. Coverage
includes start/end/note reopen with exact raw input, all three selected-after-
discard guards, another session occupying start context, closed workday retention,
duplicate note identity, malformed date, scope filtering, the corrected mileage
sequence, existing rollback/retry, architecture and size guards. All 275 core/domain
checks across 90 files passed with unchanged source (`20260910T082110Z-3cfdba63`),
clean analysis and Android debug build (9.0 seconds), with matching source/APK
evidence. No schema or visual layout changed; no current device/runtime acceptance
or full/editor-suite rerun is claimed. Protected 5.7 remains untouched.

Next accuracy finding: StartWorkdayDraftController and EndWorkdayDraftController
still parse mileage with double.tryParse after stripping commas and round to
tenths. Excess precision/exponent or malformed grouping can therefore silently
become a different confirmed value. Resolve exact input conversion with explicit
validation while preserving saved raw drafts and appropriate existing workflow
compatibility. Preference/expense/receipt registration, global recovery integration,
restore/platform/security, full regression and completion gates remain unfinished.
Inventory has not started.

## Directory recovery registration checkpoint — September 10 local, 2026

DirectoryDraftRecovery registers company/client/employee/vehicle input and returns
existing typed controllers. All four factories verify selected domain/ID/revision
before new initialization. Missing, consumed or changed selected input cannot be
reseeded. Existing stable IDs and customer recovery IDs remain compatible.

DirectoryRecoveryRead performs scoped, permission-checked reads of only the chosen
profile and its mileage revision, within one SQLite read transaction. It validates
profile decoding/identity and returns domain revision values, not SQL rows. It
avoids loading the entire directory per draft and does not mutate the editor cache.
A newer record, newly occupied draft identity or independently advanced mileage
is a retained conflict. Missing parents and malformed input remain listed with
generic labels; unreadable private content is not used as the label. The tests
exercise application-issued development capabilities, not production accounts.

Thirty-four focused checks passed, including all four reopened workflows with
exact raw input/revisions, all selected-after-discard guards, second-session client
creation, independent workday mileage advance, unreadable/orphan retention, denied
revision queries, connected directory editor regressions and boundary/size guards.
All 271 core/domain checks across 88 files passed with unchanged source
(`20260910T081314Z-34e1e8a9`), clean analysis and Android debug build (8.9 seconds).
Matching source/APK evidence is saved beside the report. Multi-connection native
fixtures emitted Drift's database-instance warning; inspection confirmed each
DatabaseHarness.open constructs its own NativeDatabase executor, and no warning
was suppressed. This is concurrency-test evidence, not device/runtime acceptance.

No schema or visual layout changed. Workday/day-note, preference, expense/receipt
recovery registration and combined global recovery integration remain unfinished,
as do restore/platform/security and the original completion gates. The complete
editor/full suite was not rerun here; affected directory editor cases were.
Inventory migration has not started; protected 5.7 remains untouched.

## Directory confirmation input boundary checkpoint — September 10 local, 2026

Company, employee and vehicle draft models now convert and validate confirmed
profiles. Vehicle mileage parsing moved unchanged from presentation into the raw
input model: explicit miles, exact tenths, grouping/precision/range validation and
blank-as-no-reading behavior remain. Employee conversion enforces the existing
profile capability-consistency rule. Company conversion retains untouched base
fields such as default currency. No new product policy or visual layout was added.

All three controllers now expose no-argument confirmation returning the committed
profile (null on failed transaction). Conversion runs inside guarded confirmation
after draft acknowledgement; callers cannot separately supply a different profile
or vehicle mileage. Screens capture typed raw input, call that workflow, and use
its committed result. Standalone preview paths use the same domain conversion;
a present directory with no workflow fails closed. The existing test previously
passed an unrelated confirmed employee name despite different raw input; it now
asserts that committed fields derive from that input and stale confirmation fails.

Twenty-three focused checks passed, including connected directory editors,
SQLite reopen, rollback/retry, duplicate/stale submit, company base-field retention,
vehicle/profile-plus-mileage atomicity, domain validation, architecture boundaries
and source-size guard. All 267 core/domain regressions across 87 files passed with
unchanged source (`20260910T080522Z-d52d4bd0`), clean analysis and Android debug
build (9.0 seconds), with matching source/APK evidence. The complete editor suite
was not rerun for this bundle; affected company/employee/vehicle tests were. No
current runtime/visual acceptance is claimed. Schema and protected 5.7 unchanged.

Directory catalog registration, other domains and global recovery integration
remain unfinished. The prior independently supplied directory-profile boundary
finding is corrected by this checkpoint. Restore/platform/security, final full
regression and original completion gates remain open. Inventory has not started.

## Job-action and payment recovery checkpoint — September 10 local, 2026

JobActionDraftRecovery registers notes, schedule, assignment and materials through
existing typed controllers. InvoicePaymentDraftRecovery separately preserves raw
amount/payment identity, checks the current invoice and refuses a payment identity
already present in the ledger. Recovery does not confirm work or post a payment.
All five factories now verify an explicit selected domain/ID/revision before any
fresh initialization. Missing/consumed or changed selections cannot be recreated.
Changed job bases remain conflicts. Material discovery/resume/discard requires its
own supplied material capability as well as Work edit access. These remain local
application-issued development capabilities, not production account enforcement.

Twenty-eight focused checks and six affected editor regressions passed. Coverage
includes reopened exact unfinished job/payment input, revision/consume guards,
material-capability changes, current payment balance and already-recorded payment
identity, existing rollback/retry, architecture boundaries and source-size guard.
All 264 core/domain checks across 86 files passed with unchanged source
(`20260910T075859Z-775a6e38`), clean analysis and Android debug build (8.9 seconds).
Matching source/APK evidence is saved beside the report. The full 65-editor suite
was last run on the preceding estimate-action checkpoint; this source reran the
six affected editor checks. No current device/visual acceptance is claimed.

No schema or visual layout changed. General recovery UI and other-domain
registration remain unfinished. Materials still use the existing job-record
confirmation; separate prototype truck-stock changes are not made atomic here
and must be resolved during inventory integration before exposing equivalent
stock-changing recovery confirmation through a new route. Inventory has not
started, and protected 5.7 remains untouched.

Next inspection found another boundary to correct: CompanyDraftController,
EmployeeDraftController and VehicleDraftController accept screen-built confirmed
profiles (vehicle also accepts an independently supplied odometer value). Their
current guard checks presence/identity, not full correspondence with acknowledged
raw draft fields. Move raw-input validation and profile conversion into their
domain models/controllers before integrating general directory recovery. This
is an implementation finding, not an approved change to directory UI or policy.

## Estimate-action recovery registration checkpoint — September 10 local, 2026

EstimateActionDraftRecovery registers signature, delivery preparation, items and
both existing company-review decisions through typed domain controllers. Reopening
never signs, sends or reviews an estimate. The four workflow factories verify the
selected domain/ID/revision before seeding; consumed or changed selections fail
without recreating input. Current parent revisions gate resumption. Changed parent
records retain every draft as a conflict rather than silently rebasing it.
Company-review list/resume/discard separately require the supplied review authority;
ordinary Work edit access does not grant company approval. Test capability changes
are synthetic development policy checks, not production account enforcement.

Seventeen focused workflow/recovery checks plus the source-size guard passed.
SQLite close/reopen preserves all five action drafts byte-equivalent at the decoded
payload level and preserves their revisions without changing confirmed Work.
All 323 selected regressions passed across 130 files (102 core, 156 domain,
65 editor), with unchanged source (`20260910T074746Z-4d677a43`), clean analysis
and Android debug build (8.8 seconds). Matching source/APK evidence is saved beside
the report. No schema, screen layout or protected 5.7 file changed. No current
runtime/visual acceptance is claimed. Job/payment and other-domain registration,
global recovery integration, restore/platform/security and completion gates remain
unfinished; the goal is active and inventory has not started.

## Primary Work recovery registration checkpoint — September 10 local, 2026

WorkPrimaryDraftRecovery registers estimate, invoice and job editors using their
typed codecs and current repository parent/revision checks. It returns existing
typed workflow controllers, not widget routes or payload maps. Hidden creators
are excluded; unavailable parents, changed records and malformed input remain
classified without silently rebasing or replacing data. Explicit discard still
uses the scoped catalog/CAS operation. These are application-issued development
Work permissions, not production authentication or live role revocation.

DraftRecoverySelection binds opening to the selected domain/ID/revision before
factories can seed input. Primary factories retain existing normal-open behavior
and legacy invoice lookup; explicit catalog selection wins over legacy lookup,
so two saved invoice IDs cannot open each other's input. Missing/changed selected
input fails without recreation. Twenty-seven focused checks passed, including
SQLite reopen for all three controllers, stable raw input/record counts, stale
and orphaned parent handling, hidden creator filtering and exact legacy/current
invoice selection. No schema or visual layout changed. Global UI integration,
secondary Work workflow handlers and the other domains remain unfinished.
All 319 selected regressions across 129 files passed (102 core, 152 domain,
65 editor), followed by clean analysis and Android debug build, with matching
source (`20260910T073342Z-c7720ede`). No current device/visual acceptance or
full migration completion is claimed.

## Recovery catalog service checkpoint — September 10 local, 2026

DraftRepository now supports a scoped owner/domain-set query. DraftRecoveryCatalog
collects presentation-safe entries across registered workflows, including parent-
unavailable and unreadable input, without exposing payloads or SQL rows. Handlers
check domain and record access before labels become visible. Explicit discard
refreshes scope/access and the selected revision, then uses the existing atomic
consume operation so a concurrent save cannot be deleted. Unsupported versions
remain unchanged until a handler separately authorizes explicit discard. Entries
from another catalog cannot be used as actions. Existing DraftRecoveryQuery
choosers now reuse catalog isolation, with no discard grant or UI change.

Eighteen focused checks passed: reopened owner/company isolation, missing parent,
unreadable version alongside valid work, revoked access, cross-catalog refusal,
stale revisions, a write during discard authorization, rollback and retry.
Access callbacks in these tests are synthetic policy checks, not production
accounts. Combined application/domain registration, resume actions and a global
recovery presentation remain unfinished. No schema or visual layout changed.
The catalog passed all 313 selected checks (102 core, 146 domain, 65 editor)
with unchanged source (`20260910T071812Z-78e1fa5d`). A subsequent audit found
manual-expense and recurring-plan explicit recovery could create an empty draft
when the selected draft was missing. Both factories now refuse that case, matching
customer/estimate/invoice/job behavior. Twenty-five focused checks passed,
including selected-after-discard, never-existing selection and independent new
entry. Final source passed 250 core/domain checks across 82 files (102 core,
148 domain), clean analysis and Android debug build, with matching fingerprint
(`20260910T072412Z-229884cc`). The broader 313-check run preceded the two
missing-selection guards. Migration and combined recovery integration remain open.

## Estimate-photo workflow checkpoint — September 10 local, 2026

Estimate photo/note recovery now uses immutable EstimatePhotosDraftInput with the
legacy photos/pendingNotes payload. Parent estimate drafts and media adoption use
that model; widgets no longer encode/decode nested photo maps. Unfinished notes
block confirmation through the model, independently of the current dialog layout.
EstimatePhotoMediaWorkflow owns scoped selection lookup, acknowledged launch,
recovery/adoption and revision-checked discard. Its selection read model hides
stored requests; the screen binds state and delegates without request-store calls
or saved-revision orchestration. Another estimate cannot discard its selection.
The obsolete presentation recovery codec helper was removed. No schema or visual
layout changed. Existing unsupported/orphan input still needs broader recovery
handling; this does not claim a complete global recovery experience.

Twenty-four focused checks passed, including connected camera/files launch and
restart recovery, retained originals, raw parent values, exact unfinished-note
reopen, legacy codec compatibility and immutable state. The boundary suite also
passed after adding a guard against raw recovery-input maps in presentation.
Analysis is clean. All 308 selected regression checks across 126 files passed
(97 core, 146 domain, 65 editor), followed by Android debug build, with matching
source (`20260910T070657Z-8d4fb177`). No current device/visual acceptance or
full-migration completion is claimed.

## Expense and receipt-review workflow checkpoint — September 10 local, 2026

Manual expense/correction opening, recovery discovery, canonical record identity,
legacy serialization and guarded confirmation now belong to domain workflow
controllers. Receipt review uses the same typed input model through its own
controller, with revision validation and atomic receipt/expense/draft confirmation.
Malformed receipt input remains retained and explicitly discardable. Recovered
manual edits preserve their original base; opening does not recapture/rewrite them.
The shared form binds typed state and delegates. No screen/shared/shell constructs
DraftAutosaveSession or LocalDraftCheckpoint; a regression guard enforces that.
Remaining LocalDraftScope presence checks distinguish preview from missing required
context and do not construct persistence. No schema or visual layout changed.

Shared money validation moved under data/expenses with a compatibility export.
Domain confirmation rejects partial, malformed, excess-precision and nonfinite
amounts, including optional subtotal/tax, independently of widget validation.
Missing draft-repository wiring in a durable manual-editor context fails closed.
Thirty-one focused checks and clean analysis passed; 15 harness unit checks passed.
Full discovered regression completed with 791 passed and the same 6 prior UI
failures across 230 files, no new failing names, and unchanged source
(`20260910T065305Z-e5e60e52`). All 304 registered storage checks passed within
that run (96 core, 144 domain, 64 editor). Android debug build passed. This closes
the known screen-session construction gap, not the broader local completion audit. A fresh
boundary search found estimate-site photo/note recovery still using raw maps
between widgets; that typed input/media boundary is the next correction.

## Expense nested-line input checkpoint — September 10 local, 2026

The expense line editor and its parent now exchange ExpenseLineDraftInput and
PendingExpenseLineInput instead of widget-owned maps. Domain codecs preserve
legacy field names, partial numeric text, stable line/edit identities and job
provenance. The complete expense base/line codec moved under data/expenses with
a compatibility export. No schema or visual layout changed. The parent expense
and receipt-review sessions still require workflow-owned opening/confirmation;
this checkpoint does not claim that final boundary is complete.

Sixteen focused checks passed with clean analysis, including native parent/DB
reopen and direct detail-line recovery, partial input and legacy codec isolation.
All 297 selected tests across 122 files passed (95 core, 138 domain, 64 editor),
with unchanged source, followed by a successful Android debug build
(`20260910T063635Z-67ca7a18`). No current device or visual acceptance is claimed.

## Receipt-evidence workflow checkpoint — September 10 local, 2026

ReceiptSubmissionSession receives the draft repository at application composition.
Its evidence workflow owns authorized opening, source/revision/identity validation,
legacy recovery and guarded atomic confirmation. Malformed/stale typed input is
retained in a controller that permits explicit discard but rejects update/confirm;
this preserves the existing error/discard path. The screen binds domain evidence
to previews and delegates. Its remaining LocalDraftScope presence check only
preserves the original distinction between an unpersisted preview and missing
required receipt context; it does not obtain a store for draft construction.
No schema, files or layout changed. Two screen-created draft paths remain.

Sixteen focused checks passed with clean analysis, covering reopen/undo recovery,
atomic failure/retry, retained original files, duplicate refusal, malformed review
discard without receipt mutation, existing preview tests and connected recovery
at phone/wide widths. All 293 selected tests across 119 files passed (95 core,
136 domain, 62 editor), with unchanged source, followed by a successful Android
debug build (`20260910T062830Z-0b02d440`). This is not current device or visual
acceptance; the migration remains active.

## Receipt-evidence input model checkpoint — September 10 local, 2026

ReceiptEvidenceReviewInput owns the legacy source/revision/order/selection/undo
payload, identity validation and durable reorder/remove/undo actions. The screen
binds stable IDs to preview selections. The unpersisted preview path retains its
existing local behavior. This is an intermediate boundary correction: receipt
session opening and confirmation still belong to the screen and are next. Three
screen-created sessions remain. No schema, files or visual layout changed.

Fifteen focused checks passed with clean analysis, including direct identity,
immutability, empty-review undo and legacy round-trip checks plus native review
reopen/failure/retry at phone and wide widths and existing preview regressions.
All 229 core/domain tests across 75 files and Android debug build passed with
unchanged source (`20260910T062221Z-0ba967ee`).

## Recurring-plan draft workflow checkpoint — September 10 local, 2026

Recurring-plan input, immutable reminders, record/draft identity, legacy codec,
recovery labels, stale-state checks and create/update confirmation now belong to
workflow models/controllers. The existing monthly due-day adjustment moved into a
domain function. The form binds typed values and recovery choices, without stored
field keys, session construction or transaction checkpoints. Existing preview and
permission-denial paths remain; no schema/layout or reminder policy changed.
Three screen-created draft paths remain: manual expenses, receipt review and
receipt evidence.

Twelve focused tests passed with clean analysis, covering new-plan discovery and
raw recovery, immutable reminder snapshots, failed create/retry and duplicate
refusal, stale edit preservation, legacy connected new/edit recovery and the
monthly February clamp independently of widgets. All 289 selected tests across
117 files and Android debug build passed with unchanged source
(`20260910T061344Z-62290ff4`).

## Scheduled-occurrence draft workflow checkpoint — September 10 local, 2026

The recurring-expense controller now receives its draft repository at composition.
Occurrence workflows own raw amount/date serialization, identity/base revisions,
stale-state checks and guarded update/consumption. The screen binds fields and
uses the same finite positive amount validation in preview and durable modes.
Existing edit capabilities and route-level denial remain; no schema/layout changed.
The native test now injects its repository into the controller, not through the
screen's context lookup. Four expense/receipt draft constructors remain.

Thirteen focused tests passed with clean analysis, covering reopen/retry, malformed
amount retention, stale refusal and connected occurrence/payment recovery. An
initial test wrongly expected the template next-due pointer to remain unchanged;
repository inspection shows updateOpenOccurrence intentionally updates that pointer
while preserving the schedule rule. The corrected test checks the revised pointer,
unchanged recurrence kind/day and unchanged template amount. No scheduling policy
was changed to make the test pass. All 225 core/domain tests across 73 files and
Android debug build passed with unchanged source (`20260910T060737Z-fd26e993`).

## Scheduled-payment draft workflow checkpoint — September 10 local, 2026

RecurringPaymentSession receives the draft repository at application composition.
Its workflow owns raw amount/date state, existing template/occurrence identity,
permission/revision checks, compatible serialization and guarded confirmation.
The dialog no longer obtains a draft store from context or constructs sessions/
checkpoints. Existing positive finite amount validation is shared with the domain;
the atomic expense/occurrence transaction remains unchanged. No schema/layout or
payment-date policy changed. Five expense/receipt screen constructors remain.

Fourteen focused tests passed with clean analysis: raw invalid amount/date reopen,
failed atomic confirmation/retry, one-time completion, stale occurrence refusal,
existing native payment-dialog recovery and transaction regressions. All 223
core/domain tests across 72 files and Android debug build passed with unchanged
source (`20260910T060217Z-a49647fc`).

## Job-materials workflow checkpoint — September 10 local, 2026

Job-material draft opening/recovery, identity/revision validation, raw workspace,
first confirmation time, protected-line validation and atomic Job confirmation now
belong to a workflow controller. The existing material capability model/rules live
under data/work with compatibility exports; stock-use permission is also enforced
without a screen. Job presentation conversion no longer rewrites protected lines:
a procurement line keeps its domain type rather than becoming a fee. No layout
changed. The Job screen no longer accepts or constructs draft checkpoints.

Thirty-three focused tests passed with clean analysis, including direct
rollback/reopen/retry, duplicate/protected-ID refusal, stale revision preservation,
stock permission and procurement-type retention, plus existing billing/source,
connected draft, stock-use and responsive tests. The connected Job-material draft
test is now registered in the reusable editor suite. All 281 selected tests across
112 files and Android debug build passed with unchanged source
(`20260910T055400Z-1e553ca5`). Six expense/receipt screen-owned draft constructors
remain.

Known inventory boundary: stock availability checking and quantity updates still
use PrototypeOperationsStore in the presentation adapter. The quantity update
occurs after the SQLite Job commit, not in the same durable transaction. This is
an existing cross-domain durability gap, not delivered inventory persistence. The
authorized inventory stage must replace this with a durable repository/service
transaction and interruption/concurrency tests; current UI tests only prove the
existing demo behavior. Local completion audit must retain this explicit boundary.

## Estimate-detail items workflow checkpoint — September 10 local, 2026

The estimate-detail items wrapper now delegates opening, base identity/revision
validation, legacy recovery, timestamp preparation and guarded atomic confirmation
to EstimateItemsDraftController. Confirmation uses the acknowledged workspace,
not an independently supplied widget item list. Pending lines cannot be confirmed.
Existing item revision/history and customer approval invalidation remain domain
rules. Failed opening closes the session without rewriting malformed input.
No schema or layout changed. Seven screen-owned draft constructors remain.

Thirteen focused tests passed, including native detail/nested editor recovery and
direct rollback/reopen/retry, stale-revision refusal and one-time approval-invalidating
item revision. Analysis is clean after two brace-style corrections. All 218
core/domain tests across 70 files and Android debug build passed with unchanged
source (`20260910T054755Z-c5c4d5c0`).

## Nested item-workspace model checkpoint — September 10 local, 2026

WorkItemsDraftInput now owns confirmed-line lists and typed pending line input.
EstimateItemsScreen and WorkItemsEditor bind these values without stored field
keys or codecs. Main estimate/invoice/Job draft models serialize their typed nested
workspaces behind the data boundary. Estimate-detail and Job-material wrappers
still adapt legacy payloads and own confirmation; they remain the next correction.
Existing category-specific estimate draft keys are retained for recovery rather
than replaced as a layout decision. No schema or visual composition changed.

Twenty-four focused tests passed with clean analysis. Compatibility fixtures now
use the actual legacy workspace/line shape emitted by the editors; earlier test
maps containing only name/quantity never represented a complete editor payload.
A separate malformed-workspace test proves those invalid maps fail decoding while
the stored payload and revision remain unchanged. The reusable editor suite now
explicitly includes nested estimate/invoice/Job and imported-line provenance tests.
All 275 selected core/domain/editor tests across 109 files and Android debug
build passed with unchanged source (`20260910T054009Z-acf49d09`).

## Nested line-input model checkpoint — September 10 local, 2026

WorkLineItemDraftInput now owns legacy raw field serialization and confirmation
validation/construction for a single line, including imported source identities
and hidden cost/price preservation. The line editor binds typed input; its parent
editors temporarily adapt to their existing stored maps. No schema, layout or
billing policy changed. Those parent adapters and workspace confirmation still
need migration; this is not complete nested-editor decoupling.

Sixteen focused tests passed with clean analysis, including native estimate,
invoice, Job and estimate-detail nested recovery, provenance/private-cost recovery
and direct raw-input/confirmation validation without widgets. All 268 selected
core/domain/editor tests across 104 files and Android debug build passed with
unchanged source (`20260910T053253Z-631953f3`).

## Estimate-signature workflow checkpoint — September 10 local, 2026

Signature draft input now owns normalized ink, raw name, acceptance and the first
confirmation time behind a workflow controller. Name/ink changes invalidate
acceptance and time there, including clearing ink after a failed confirmation.
The signature pad only converts pointer coordinates to normalized domain points
and paints them; recovery and confirmation no longer depend on its dimensions or
widget arrangement. Legacy payload keys remain compatible, with no schema/layout
change. Existing development access checks are retained, not production identity.

Thirteen focused checks passed with clean analysis, including direct SQLite
rollback/reopen/retry, immutable drawing snapshots, stale revision refusal and the
existing connected signature recovery test. All 212 core/domain tests across 67
files and the Android debug build passed with unchanged source
(`20260910T052829Z-f066800d`). Eight screen-owned draft sessions, nested item
input payloads and broader recovery/platform work remain before completion.

## Estimate-review workflow checkpoint — September 10 local, 2026

Return/rejection reasons now use typed workflow input and a controller for legacy
payload recovery, record identity/revision checks, review eligibility and guarded
atomic confirmation. Raw reason whitespace and the first confirmation timestamp
survive failed save/reopen/retry. Editing the reason clears that timestamp. The
dialog only binds values and delegates; no schema or visual layout changed.
The existing supplied EstimatePermissions remains a development capability, not
proof of production account enforcement or live role-revocation protection.

Thirteen focused checks passed with clean analysis, including both connected
review dialogs and direct rollback, duplicate, stale-record and capability tests.
All 210 core/domain tests across 66 files and the Android debug build passed
with unchanged source (`20260910T052410Z-e408d1fd`).
Nine screen-owned draft sessions and broader recovery/platform work remain.

## Estimate-delivery workflow checkpoint — September 10 local, 2026

Delivery preparation now uses typed workflow input for its base record/revision,
method-specific recipients, review state and first preparation time. Recipient
and method changes invalidate review in the workflow; changing methods retains
previous raw recipients. Default contact selection remains the existing authorized
customer-name lookup, now outside the screen. The screen binds input and delegates
opening and confirmation without constructing stored payloads/checkpoints.

Eleven focused checks passed with clean analysis. Native SQLite tests prove
rollback/reopen/retry, stable first preparation time, exact recipient recovery,
stale-record refusal and one-time preparation that never claims actual delivery.
Existing company-review gating and local preparation behavior are retained; no
network sending, secure-link integration or visual redesign was introduced.
All 207 core/domain tests across 65 files and the Android debug build passed
with unchanged source (`20260910T051624Z-4e7f77da`). Ten screen-owned draft
sessions and broader recovery/platform work remain before migration completion.

## Custom input-lock integration checkpoint — September 10 local, 2026

EditorInputLock now owns keyboard-focus exclusion and pointer blocking. The shared
draft navigation guard, invoice editor, Job workspace and Estimate detail reuse it.
Receipt intake also uses it for source actions while a media request is pending,
preventing an already focused source button from bypassing pointer-only blocking.
Existing busy conditions, layout and record/media rules remain unchanged.

Nineteen focused checks passed with clean analysis. Tests prove keyboard action
suppression and restoration, pending confirmation/Back focus exclusion, connected
invoice recovery, receipt native-media recovery and Job status failure/retry. The
Job status test is now explicitly registered in the reusable editor suite. All 259 core/domain/editor tests across 100 files and the Android debug build
passed with unchanged source (`20260910T050535Z-5ab60152`). The remaining eleven
screen-owned draft sessions and recovery/platform gates are still unfinished.

## Shared keyboard-confirmation safeguard — September 10 local, 2026

Current inspection corrected the earlier diagnosis: DraftNavigationGuard already
absorbed pointer input while busy or leaving; the missing protection was existing
keyboard/IME focus. It now uses ExcludeFocus as well, without layout changes.
The installed Flutter FocusNode implementation unfocuses existing descendants
when descendantsAreFocusable becomes false. The guard covers its callers during
confirmation/discard and while Back waits for autosave.

Fourteen focused tests passed with clean analysis. Controlled pending-operation
widget tests prove IME detachment, blocked keyboard focus and pointer actions,
failed-flush input retention and restored editing after failure. The test cleanup
was corrected to close its fake draft within the widget test clock; no product
storage workaround was introduced. All 257 core/domain/editor checks across 98 files and the Android debug build
passed with unchanged source (`20260910T045859Z-6ea3322e`). No device keyboard or rendered acceptance is claimed.

That checkpoint identified separate pointer-only wrappers in the invoice editor,
Job workspace, Estimate detail and receipt source actions. Their subsequent shared
input-lock integration and verification are recorded above.

## Invoice-payment workflow checkpoint — September 10 local, 2026

Invoice payments now use a typed workflow for stable draft/payment identities,
raw amount/note/method/date recovery, current balance validation and guarded ledger
confirmation. The screen no longer serializes payment input, constructs ledger
entries/checkpoints or calculates the connected balance. Existing preview behavior,
validation messages and ledger transaction are retained. The current invoice-number
ledger linkage remains compatible; converting those links to stable record IDs
would also require updating number-only payment/report projections, not a blind
field substitution. This is a data-identity concern, not a layout schema change.

Fourteen focused checks passed with clean analysis. Direct SQLite tests prove
partial input/reopen, retained identity, failed ledger rollback including invoice
revision/balance, one-time retry and live-balance validation after another payment.
The payment recovery widget test is now explicit in the reusable editor suite.
All 202 core/domain tests across 62 files and the Android debug build passed
with unchanged source (`20260910T045118Z-a1019829`). Eleven screen parts still
construct autosave sessions; other editor, recovery and platform work remains.

## Job-schedule workflow checkpoint — September 10 local, 2026

Rescheduling now uses a typed JobScheduleInput and controller-owned recovery,
identity/revision validation and guarded confirmation. The existing raw day/hour/
minute/period payload remains compatible. Time-range, recorded-duration and local
clock-change validation and return-visit status handling moved unchanged behind
the workflow; invalid period values are also rejected without widgets. The sheet
binds input and shares the same confirmation builder in preview mode. No layout
or scheduling policy was redesigned.

Twelve connected/boundary checks and three direct tests passed. Evidence covers
Dashboard/Calendar Day recovery, raw partial input, failed save/reopen/retry,
midnight/noon conversion, retained duration/status, stale record protection and
missing-duration refusal. Final analysis is clean; all 200 core/domain tests across 61 files and the
Android debug build passed with unchanged source (`20260910T044402Z-309d995f`). Twelve screen parts still construct draft sessions; remaining editor
boundaries and recovery/platform gates prevent a migration completion claim.

## Expense settings workflow checkpoint — September 10 local, 2026

Expense display preferences and raw proposed category/receipt-type selections now
have typed models outside screen code. The controller opens the shared preference
workflow, owns the legacy codec/identity and refuses confirmation while proposed
choices remain unfinished. Captured input copies external collections; later dialog
or caller mutations cannot rewrite that snapshot. The screen binds restored values
without owning storage payload keys or commit checkpoints. Existing UI is unchanged.

Nineteen connected/storage/boundary checks and two direct tests passed, with clean
analysis. Native SQLite checks prove nested recovery, finish-before-confirm,
failed confirmation/retry, duplicate refusal and exact invalid legacy-byte retention.
All 249 core/domain/editor tests across 94 files and the Android debug build
passed with unchanged source (`20260910T043703Z-1efeb177`). Thirteen screen parts
still create autosave sessions; other Work/expense/receipt boundaries and broader
recovery/platform gates remain. This does not mark migration or inventory complete.

## Report settings workflow checkpoint — September 10 local, 2026

Report display preferences now live outside screen code. A controller-owned
workflow handles the legacy five-choice payload, recovery identity and guarded
confirmation; the screen binds a typed model. BuildContext preference reading
remains a separate presentation adapter. Existing UI and stored keys are unchanged.

Seventeen existing focused checks and two direct tests passed. Native SQLite
verification covers all legacy choices, failed confirmation/reopen/retry, preservation
of unrelated preferences, duplicate refusal and exact incomplete-payload retention.
Final analysis is clean; 195 core/domain tests across 59 files and the Android
debug build passed with unchanged source (`20260910T043259Z-31c8650d`). Expense
settings and other domain editor boundaries remain unfinished.

## Receipt and Work-list settings workflow checkpoint — September 10 local, 2026

Receipt and Work-list settings now open typed preference workflows through their
controller. Recovery codecs, stable domain/workspace keys and confirmation
checkpoints no longer belong to the screens. The preference models moved to
`data/preferences`; BuildContext readers remain separate presentation adapters.
Existing controls, stored keys and confirmed preference transactions are unchanged.

Twenty focused checks passed with clean analysis. Direct SQLite tests prove
receipt/Jobs/Invoices draft isolation, reopen recovery, preservation of unrelated
confirmed choices, rejection of stale confirmation and unsupported workspace IDs.
Existing connected failure/retry tests also pass. An architecture guard forbids
widget/screen dependencies in saved preference models. All 193 core/domain tests across 58 files and the Android
debug build passed with unchanged source (`20260910T042938Z-05b5b6a4`). Fifteen screen parts still create autosave sessions;
the remaining settings, Work and expense/receipt workflows require further work.

## Work-display draft workflow checkpoint — September 10 local, 2026

Work settings now uses a reusable typed PreferenceDraftWorkflow, opened and
confirmed through an AppPreferencesController extension. WorkDisplayPreferences
moved out of the screen with a compatibility export. The screen no longer owns
payload serialization, device draft identity or commit checkpoint construction.
The workflow freezes confirmation and seals successful submission while retaining
failed input. Existing saved payload keys and visual behavior are unchanged.

Eighteen focused checks passed, including native rollback/reopen/retry, active
settings unchanged on failure, one-time draft consumption and malformed legacy
payload/revision retention. Analysis is clean; 190 core/domain tests across 57 files and the Android
debug build passed with unchanged source (`20260910T042537Z-ede4051b`). Other settings workflows remain to be converted to this boundary.

## Preferences repository boundary checkpoint — September 10 local, 2026

AppPreferencesController and app injection now accept AppPreferencesRepository,
which exposes acknowledged values, recovery status, drafts and atomic saveMany.
No controller/screen imports the concrete SQLite preferences store. Stable
preference/recovery identifiers moved to a shared contract; compatibility aliases
retain existing callers and saved keys. SQLite validation, corrupt-value archive,
read/merge/write transactions and checkpoint consumption are unchanged.

Twenty-two focused settings/architecture checks and two database-independent
interface checks passed. The latter prove visible values wait for acknowledgment
and that failed writes preserve active values and retry the same proposal. The
architecture guard now rejects concrete preference-store imports in presentation.
All 188 core/domain tests across 56 files passed with unchanged source
(`20260910T042128Z-462b2918`); final analysis is clean and Android debug build passed.

Settings forms still own their typed-choice assembly, payloads and confirmation
checkpoints; removing the concrete repository dependency is not a claim that all
settings workflows have been decoupled. No appearance or saved-key changes occurred.

## Job-assignment workflow checkpoint — September 10 local, 2026

Assignment draft opening, legacy serialization, record identity/revision and
confirmation now belong to a typed workflow. The sheet binds technician/vehicle
values and generic save status. Recovery retains the exact pair; a failed command
changes neither confirmed assignment field. No schema or layout changes occurred.
Names remain transitional assignment values, not production authorization IDs.

Ten focused checks passed, including failed commit/reopen/retry, atomic assignment
pair confirmation, duplicate refusal, stale base preservation and mismatched-parent
recovery retention. Analysis and the Android debug build passed. The combined
core/domain/editor harness passed all 238 tests across 89 files with unchanged
source (`20260910T041548Z-9a7c4c94`). The reusable manifest now includes direct
notes/assignment workflow checks and both connected editor recovery regressions.

Current boundary scan still finds 18 screen/part files constructing autosave
sessions, mainly nested Work, expense/receipt and settings workflows. These still
need workflow ownership; moving notes and assignment does not complete the
application-wide UI/storage boundary audit.

## Job-notes workflow checkpoint — September 10 local, 2026

Job notes now use a typed workflow that owns the legacy payload, record identity,
base revision and guarded confirmation. The dialog binds raw note text and save
status; it no longer creates autosave sessions, serializes records or constructs
commit checkpoints. Existing layout and preview-only behavior are unchanged.
Recovery rejects mismatched job identities without deleting the saved input.

Ten focused tests passed, including real SQLite failed-write/reopen/retry,
stale revisions, duplicate confirmation, legacy payload preservation, the
connected notes dialog and architecture/file-size guards. Analysis is clean and
the Android debug build passed. All 184 core/domain tests across 54 files passed with unchanged source
(`20260910T041300Z-4b023a09`).
This remains a local migration checkpoint, not completion or runtime acceptance.

## Start-workday workflow checkpoint — September 10 local, 2026

Workday start now uses a typed workflow for identity, employee/vehicle recovery,
raw odometer text, GPS-assistance request, retained odometer revisions and guarded
confirmation. The screen no longer constructs draft sessions/checkpoints or
serializes these fields. Recovery may retain an unfinished employee selection;
confirmation requires valid authorized context. The saved context wins over a
new presentation's initial selection, and a UI unable to display that context
refuses to silently replace it. No GPS behavior or visual layout was changed.

Nineteen focused connected/repository/boundary checks and two direct tests passed.
They verify rollback/reopen, exact raw comma/decimal input, stable first attempt
time and workday identity, correct vehicle updates, duplicate refusal and incomplete
selection recovery without creating a workday. Analysis is clean; 182 core/domain tests across 53 files and the Android debug
build passed (`20260910T040608Z-a5194724`), with unchanged source fingerprints. The start-screen recovery regression
is also now explicitly listed in the reusable editor suite.

## End-workday workflow checkpoint — September 10 local, 2026

Ending input now has a typed workflow for stable identities, raw odometer text,
record/odometer revisions and first confirmation timestamp. The dialog delegates
opening and guarded confirmation, while the existing domain transaction owns
atomic workday/odometer updates. WorkdayAccess, WorkdaySnapshot and confirmed
odometer read models moved out of the SQLite repository with compatibility
exports; Dashboard and its end dialog import only those read models.

Eighteen connected/repository/boundary checks and two direct tests passed. The
direct tests prove failed-end rollback, reopened raw input/timestamps, invalid
or decreasing-reading rejection and exact replay returning its original success
without advancing either revision. Analysis is clean; core/domain run
`20260910T040013Z-ee3d843d` passed 180 tests across 52 files (89 core, 91 domain),
no failures/skips and unchanged source. Android debug build passed (existing pdfx
KGP warning); build verification records matching source and APK identity. No new
whole-app or device-runtime acceptance is claimed. Workday start remains the next boundary;
all wider completion gates remain unfinished.

## Day-note workflow checkpoint — September 9 local, 2026

The day-note dialog now uses a typed workflow for opening, identity/date/time
validation, raw serialization and guarded confirmation. It no longer imports a
SQLite repository, constructs checkpoints or obtains storage from widget scope.
DayNoteAccess moved into a plain domain file with a compatibility export. The
first confirmation timestamp is durably checkpointed before the domain command
and survives failed-save retry/recovery. Raw text and local calendar time retain
their existing semantics; only confirmed timestamps use UTC.

Thirteen focused repository/controller/connected Dashboard and Calendar Day checks
passed. Two additional direct tests prove reopen after failure, stable timestamp
and identity, legacy payload recovery without rewriting, and malformed-context
retention. Analysis is clean; core/domain run `20260910T035349Z-3eda3f0e`
passed 178 tests across 51 files (89 core, 89 domain), no failures/skips and
unchanged source. Android debug build passed (existing pdfx KGP warning), with
source/APK identity in build verification. Connected Dashboard/Calendar editors
were tested directly; no new whole-app or device-runtime acceptance is claimed.
Other workflow boundaries and broader completion gates remain unfinished.

## Expense/receipt model boundary checkpoint — September 9 local, 2026

Expense workflow models and demo fixtures now live under the data layer; their
only Flutter dependency is foundation annotations. Category icon mappings moved
to a screen presentation extension. Compatibility exports preserve current UI
imports. Twenty data-layer imports now use domain models directly; expense and
receipt data no longer import screen-owned model definitions. Enum names/order,
field values and date-only behavior remain unchanged, with no schema migration.

Forty-four focused projection, itemization, SQLite repository, receipt submission,
recurring-payment and boundary/size checks passed. Analysis is clean and Android
debug build passed (existing pdfx KGP warning). Selected core/domain/editor run
`20260910T034526Z-7e16c40a` passed 225 tests across 81 files (89 core, 87 domain,
49 editor), no failures/skips and unchanged source. Build verification records
matching source and APK identity. The prior 724/6 full run is historical, and no
new device-runtime acceptance is claimed. Remaining workflow ownership includes day-note access
types exposed through repository imports and other nested/settings draft flows.

## Client workflow ownership checkpoint — September 9 local, 2026

Client opening, recovery identity validation, record construction and guarded
confirmation now belong to directory workflows. The primary-location update
retains additional locations and linked-record counts. Screens no longer build
profile records, draft sessions or checkpoints for this workflow; original raw
payload keys and validation text remain unchanged.

Eighteen focused checks passed, including real reopened SQLite, failed-update
retry, stale submission, incomplete contact values and extra-location retention.
Core/domain run `20260910T034151Z-ced9e344` passed 175 checks across 50 files
(88 core, 87 domain), no failures/skips and unchanged source. Analysis is clean
and Android debug build passed (existing pdfx KGP warning); build verification
records matching source and APK identity. The preceding 724/6 full run predates
this bundle; affected client editor/layout checks were run directly. No new
device-runtime or completion claim. Remaining expense/receipt data imports of
screen-owned models with icon metadata are the next structural boundary.

## Estimate workflow ownership checkpoint — September 9 local, 2026

Estimate draft opening, creator/record checks, record construction, readiness
validation and guarded confirmation now live behind a Work service/controller.
The pre-existing estimate revision extension moved unchanged into the domain,
with a compatibility export at its old screen path. Screens no longer construct
autosave sessions, confirmed estimates or revision checkpoints. Existing media
adoption still uses the same session and atomic draft/media transaction.

Nineteen focused editor, revision, native-media harness, compatibility and size
checks passed. Two new widget-independent tests verify reopened unfinished photo
notes, failed-update retention, atomic approval invalidation/history on retry,
duplicate refusal, incomplete-estimate confirmation as a draft and denied/missing
recovery. Analysis is clean and Android debug build passed (existing pdfx KGP
warning). Full run `20260910T032944Z-d555394e` completed with 724 passes and six
failures across 200 files, unchanged source, no skips/incomplete tests. Failure
names match the prior 697/6 baseline exactly. All 222 selected storage checks
pass within this full run (88 core, 85 domain, 49 editor). Comparison and build
artifacts record failure names, source fingerprint and APK identity. Fifteen
Python harness self-tests also passed. No new device-runtime acceptance is claimed.

A current source scan still finds 24 screen-side autosave constructors and 24
checkpoint assembly sites across customer, nested Work, expenses, workday,
notes and settings. These are already persisted workflows; the remaining issue
is reusable workflow ownership. Normal application startup supplies SQLite
repositories; optional transient host fallbacks still exist. Inventory remains
the next stage after local completion, and 5.7 remains untouched.

## Invoice workflow ownership checkpoint — September 9 local, 2026

Invoice opening, legacy actor-independent edit-key lookup, identity validation,
record construction and guarded confirmation now live in Work domain workflows.
Screens bind typed input and surface the same validation text; they no longer
construct autosave sessions, confirmed WorkRecord or revision checkpoints.
Existing invoice metadata is retained from the authorized record snapshot while
the original storage revision still gates the transaction. Invalid money remains
raw recoverable input; successful commands seal against duplicate confirmation.

Thirteen focused editor/recovery/compatibility/boundary tests passed. Two new
widget-independent tests verify old edit-key recovery after SQLite reopen,
actual edited-record rollback/retry, stale-submit refusal, metadata retention,
invalid raw money correction and missing-recovery refusal. Core/domain regression
`20260910T032421Z-cdcc0559` passed 171 tests across 48 files (88 core, 83 domain),
no failures/skips and unchanged source. Analysis is clean and Android debug build
passed (existing pdfx KGP warning); build verification records source/APK identity.
Affected invoice editors were tested directly; no new whole-app or device-runtime
acceptance is claimed. No schema, payload version or
visual changes; other editors/preferences and wider completion gates remain.

## Job workflow ownership checkpoint — September 9 local, 2026

Job opening, stable linked-source identity, scoped recovery access and guarded
confirmation now belong to a Work workflow service. The domain builder owns the
existing required-field, unfinished-item, schedule and approved-source rules and
confirmed record construction. The screen binds typed input, shows the same
validation messages and delegates confirmation. A new screen/layout can reuse
these rules without reconstructing SQL checkpoints or estimate conversion logic.
The existing preview-only host still uses the shared builder without claiming a
durable save; normal startup uses the bound persistence workflow.

Seventeen focused tests passed, including existing connected editor recovery and
linked-save failure/retry. Four new service tests cover standalone/linked
database reopen, incomplete item input, injected SQL failure, atomic retry,
duplicate prevention, missing recovery and creator-visibility denial at both
discovery and opening. Core/domain regression `20260910T031830Z-0e630e94`
passed 169 tests across 47 files (88 core, 81 domain), no failures/skips and
unchanged source. Analysis is clean and Android debug build passed with the
existing pdfx KGP warning; the build artifact records APK and source identity.
No schema/payload version or visual-layout changes were made. The preceding
214-test editor-inclusive run predates this bundle; affected job editor tests
were run directly, not every editor or the full app. No new runtime claim.

Other Work editors, nested workflows and preferences still need equivalent
ownership; all broader completion gates remain outstanding.

## Profile confirmation ownership checkpoint — September 9 local, 2026

Company/employee/vehicle typed controllers now confirm through directory-bound
callbacks. Screens no longer flush drafts, assemble revision checkpoints or
invoke profile persistence directly. Generic autosave confirmation freezes input,
waits for queued acknowledgements and supplies the exact durable checkpoint to
the existing domain transaction. A false/throwing command preserves editable
input; successful confirmation seals the session against duplicate submission
and recreating consumed input. Domain callbacks use the recovered base revisions,
including the vehicle odometer revision; employee/vehicle identity mismatches
are rejected before any command runs. No visual layout or wire-format changes.

Twenty-six initial focused checks passed; an additional direct reopened-database
confirmation/stale-submit test passed with the nine related service/boundary
checks. Analysis is clean. Selected regression `20260910T030916Z-523c6317`
passed 214 tests across 77 files (88 core, 77 domain, 49 editor), no failures/skips
and unchanged source. Android debug build passed with the existing pdfx KGP
warning; `build_verification.json` records matching source and APK identity.
Other workflows still need equivalent confirmation ownership;
this bundle does not close the overall migration or security/platform gates.

## Profile opening service checkpoint — September 9 local, 2026

Company/employee/vehicle screens now open typed workflows through
`DirectoryDraftWorkflows`. The service owns stable actor/record draft identities,
checks directory access and record availability, initializes recovery and closes
failed opening sessions without deleting input. These screens no longer create
DraftAutosaveSession or choose persisted domain/key strings. Company failed
recovery also now releases its opening session before returning an error.

Nineteen focused service/compatibility/connected editor/source-size checks passed.
Core and domain regression `20260910T030453Z-39cd3219` passed 162 checks across
46 files (86 core, 76 domain), no failures/skips and unchanged source. Analysis
is clean and Android debug build passed, with APK/source identity recorded in
`build_verification.json`. The preceding 207-test run is historical; this bundle
used focused affected editor checks rather than rerunning every editor. No new
device runtime, whole-app or visual acceptance is claimed. Service access tests
use synthetic identities; they are not production account enforcement.

Next boundary work includes reusable confirmation orchestration and remaining
editor/preference workflows. All broader recovery/platform/security gates below
remain in force; the migration and subsequent inventory stage are unfinished.

## Profile draft controller checkpoint — September 9 local, 2026

Company, employee and vehicle editors now bind typed workflow input instead of
serializing storage maps. Domain controllers retain version-one field names and
raw unfinished values. Employee/vehicle recovery identity, revision and role
validation moved out of widgets without relaxing the existing checks. Nine new
database-reopen compatibility and malformed-input tests preserve saved bytes and
revisions; they are registered in the reusable domain suite.

Focused verification passed all 24 tests, including connected recovery,
failure/retry, unchanged confirmation, directory persistence and source sizes.
Full analysis is clean. Android debug build passed with the existing pdfx KGP
future-compatibility warning. Selected regression
`20260910T025754Z-64e49d2c` passed 207 tests across 76 files (86 core, 72 domain,
49 editor), no failures/skips and unchanged source. The build verification
artifact records the APK hash and matching post-build source fingerprint. No
current full-suite or new device-runtime acceptance is claimed.

Remaining coupling includes screen-owned draft opening/identity and confirmation
orchestration, preference implementation access and other nested/raw editors.
The profile codec separation does not close those broader completion gates.

## Job/client and recovery-query checkpoint — September 9 local, 2026

Job and client raw input now use typed controllers and codecs, preserving all
legacy keys and values. Job scheduling passes DateTime values through the
workflow boundary; separate date/time widgets no longer define serialization.
Estimate/invoice/job/client recovery choosers receive DraftRecoveryChoice read
models from domain-issued queries; those widgets no longer inspect stored
payloads to filter or label recovery entries. Scoped discovery preserves unknown
versions and malformed labels without hiding valid drafts or changing any row.

Focused checks passed: 16 tests covering old raw payloads, reopened databases,
linked-job failure/retry, nested item input, chooser isolation and source bounds.
Selected regression `20260910T024625Z-2c51abec` passed **198 tests across 75 files**
(86 core, 63 domain, 49 editor), no skips/failures, unchanged source fingerprint.
Full analysis is clean and Android debug build passed (existing pdfx KGP
future-compatibility warning). `build_verification.json` records APK identity and
matching post-build source fingerprint. No new runtime acceptance is claimed. The most
recent full-suite run is still the prior 697/6 baseline; it was not rerun for
this narrower bundle and is not proof of the changed source's whole-app result.

Remaining: other editor/preference typed workflows, route-independent opening,
identity/recovery selection and confirmation orchestration, and the existing
recovery/durability/platform/security gates below. No inventory integration or
visual UI redesign has begun.

## UI boundary refactor in progress — 2026-09-09 evening

- Applied: storage-independent DraftRepository/SavedDraft, injected draft access
  at 21 former screen/shell construction sites, typed estimate/invoice input
  controllers, domain-owned Work models with compatibility exports, and Work-owned
  estimate media commit/attachment retention. SQL schema and payload versions,
  wire keys, identities and transaction-consumption behavior are unchanged.
- Focused verification: clean analysis and 14 initial storage/recovery checks;
  then 15 controller, compatibility, repository and media/editor checks passed.
  Selected run `20260910T022439Z-13aa3cb6` recorded 190 passes and 5 failures
  (84/1 core, 61/0 domains, 45/4 editors), with unchanged source. The new
  boundary guard found a Dashboard projection in the data layer; it now lives
  under Dashboard. Four existing arrival/completion tests assumed a new late-day
  event appeared in the collapsed first three rows. Tests now assert durable
  events and use the existing Show all control; no UI behavior changed. All
  eight focused boundary/projection/failure checks then passed; analysis is clean.
  Full run `20260910T022954Z-69dc232b` then completed: 697 passed, six existing
  UI failures across 194 files, unchanged source and no new failing names.
  All 195 selected storage checks passed within that full run (85/61/49).
  Analysis is clean and Android debug build succeeded; no new runtime or visual
  acceptance is claimed. The pdfx KGP future-compatibility warning remains.
- Still unfinished: typed workflow ownership for remaining editors, centralized
  recovery discovery/selection and confirmation orchestration, presentation
  preference interfaces, remaining persistence/recovery gaps and platform QA.
- Latest owner sequencing: complete and verify local migration first, then
  continue inventory assessment, test-harness expansion and SQLite/Drift port.
  The 5.7 reference remains read-only; inventory UI is not accepted or frozen.

## Confirmed remaining local-storage work

- **Native camera/photo-picker handoff:** receipt and estimate camera/library
  paths now save their destination before launch and share one app-owned native
  coordinator. Startup retains recovered originals for their saved target. Receipt
  adoption updates its draft; estimate adoption atomically updates its parent raw
  input and preserves photo ordering, pending notes and other unfinished fields.
  Each owning photo screen offers recovery or explicit selection discard. App-path
  tests use a fake native gateway and reopened SQLite/files. The receipt camera
  and estimate camera paths also passed API 35 emulator checks with the app killed
  while the external camera stayed active, followed by result retention and
  one-photo adoption into the correct draft. A gallery SIGKILL check preserved
  the receipt but received no native result; explicit selection discard and
  manual reselection recovered into the same draft with matching original bytes.
  Automatic gallery recovery and broader physical-device coverage remain unproven.
  Document-file selection now journals its exact destination before launch and
  retains returned originals through the same coordinator. A missing file result
  requires explicit reselection against that saved destination; it never consumes
  the image-picker recovery cache. Receipt PDF reselection passed a native
  Android DocumentsUI interruption check; estimate file-picker runtime parity
  and broader provider coverage remain outstanding. The Android image plugin clears cached results during retrieval,
  leaving a pre-checkpoint loss window these changes do not eliminate.
  See `data_storage_sync_contract.md` for the assessment and verified scope.

- **Calendar Day settings:** the two switches in
  `dashboard_day_settings_screen.dart` are memory-only and not connected to the
  day screen. Persisting them alone would not make their advertised behavior real.
  Inspect the owning calendar rules before wiring presentation or changing UI.

## Resolved since this audit

- **One unreadable draft blocking its whole chooser:** recovery previews now
  isolate decode/label failures per saved row in six editors. Unsupported input
  remains visible and unchanged; valid recovery and Start another remain available.
  Strict selected-draft initialization and current permissions are unchanged.
  A reopened-database estimate regression verifies valid recovery and independent
  discard alongside an unsupported-version draft.

- **Receipt evidence-review input:** ordering, removal, selected evidence and the
  latest Undo action now recover from an actor/receipt-scoped SQLite draft.
  Save/Continue checks the original receipt revision and atomically confirms
  metadata while consuming the exact input revision. Original files are retained.
  Native widget tests reopen the database, restore removal/Undo, inject a failed
  confirmation and retry at 390 and 1400 logical pixels. Intake uses the committed
  result without a second write. Stale or malformed recovery input is preserved
  behind an explicit discard option; conflict merging remains unfinished.

- **Receipt evidence revision boundary:** the controller rejects unknown retained
  IDs instead of silently dropping them and accepts the review's expected receipt
  revision. Intake retains its loaded revision across edits/retries, validates even
  unchanged evidence against it, and refuses to recreate a missing previously saved
  draft. This protects newer receipt state alongside the recovery path above.

- **Expense display preferences:** related-job display, category mode/custom
  categories and per-category receipt types now persist in SQLite. Both nested
  choice dialogs retain their own pending selections inside the parent draft.
  Back retains them; Use promotes them into the unfinished parent choices; Cancel
  explicitly discards only that dialog's selections. Overall Save is blocked
  until pending choices are resolved, then atomically applies preferences and
  consumes the parent draft. Database reopen/failure/retry is tested at phone and
  desktop widths; all registered receipt-type/category values have storage checks.

- **Report display preferences:** confirmed settings now use device-local SQLite
  preferences, and raw choices use a separately scoped settings draft. Save applies
  all five choices and consumes that exact draft atomically. Failed confirmation
  retains active values and unfinished input. The Reports screen reads confirmed
  values after reopening. The existing report scope/presentation behavior is
  preserved; these choices do not grant access to report data.

- **Optional notification startup dependency:** native reminder initialization no
  longer gates SQLite opening. The existing reminder controller serializes launch
  payload retrieval and catches platform failures. Reminder failures are visible
  even before permission status is known; Retry initializes without requesting
  permission. Tests in `notification_startup_isolation_test.dart` reproduce the
  prior startup/callback failures and now verify preserved SQLite input, while
  `native_notification_ui_controller_test.dart` verifies visible retry and
  successful one-time launch payload handling. Broader evidence is recorded in
  `sqlite_migration_verification_status.md`.

## Apparent field gaps already routed through durable paths

- Expense detail correction reasons and line edits use the durable expense editor
  when `LocalDraftScope` and `ExpenseUiScope` are present. The older standalone
  correction dialog is a fallback; its presence alone is not a connected-app gap.
- Calendar Day manual entries use `openStoredDayNoteEditor` before the old title
  dialog fallback. Test the connected route, rather than treating every TextField
  search hit as a missing database integration.
- Invoice/customer/record search fields filter existing records. They are not
  unfinished invoice/customer records and do not establish missing record storage.

## Existing evidence and limits

An earlier selected harness is
`build/storage_qa/20260909T184353Z-05832843/report.json`: 190 passes across 72 files,
clean analysis, and a successful Android debug build. Its manifest covers selected
storage/editor behavior; it is not complete workflow or production-security proof.
Android force-stop checks now cover an acknowledged employee draft at wide
width and a manual expense at phone width (including exact partial amount
recovery and one confirmed record). They are not physical battery-loss proof for
all workflows or supported devices. See `android_storage_recovery_qa.md`.

`open_ui_lab_application.dart` supplies the shared SQLite database repositories,
Work/directory/workday/day-note sessions, draft store and device preferences.
`local_database.dart` enforces WAL/FULL/foreign keys and verifies stored history.
Schema version 1 rejects unknown upgrades; any future schema version still needs
an explicit tested migration. Current raw drafts retain incomplete values and use
revision-checked confirmation/discard, including persistent markers across reused
editor IDs. These are implemented foundations, not a production-readiness claim.

Cloud backup/sync remain release-one requirements with unfinished remote identity,
authorization, consent/UI, live restore and billing-abuse protections. Local
at-rest protection and production account/permission integration also remain
unfinished. Existing demo authority must not be described as production security.
Inventory is excluded from this slice. No protected 5.7 operation was performed
in this audit. Full-suite results follow.

Previous full run completed: **724 passed, 6 failed** across 200 files in
461.829 seconds, with unchanged source fingerprints. Evidence:
`build/storage_qa/20260910T032944Z-d555394e/report.json`,
`failure-comparison.json` and `build_verification.json`. The same five
Dashboard expectations and one Inventory presentation expectation remain; no new
failing names appeared. All 222 selected storage tests passed within that full
run. The overall suite remains failing and the migration is not complete.

## Estimate native file-picker probe preparation — September 10, 2026

Added `integration_test/estimate_file_picker_interruption_test.dart`, reusing the
production estimate controller, native gateway, application media coordinator,
and adoption service. No production layout, schema, or storage behavior changed.
The standalone write/read probe preserves a real typed unfinished estimate across
an external kill, then requires actual DocumentsUI reselection and checks retained
bytes, consumed intent, duplicate rejection, raw-field preservation and reopening.

The QA Android APK compiled and aapt confirmed the dedicated `.storageqa` ID.
Four existing simulated-picker estimate widget regressions passed. Native execution
of this new probe remains pending; these results do NOT close the estimate native
file-picker runtime gate. No commits, pushes, inventory or 5.7 changes.

## Estimate native file-picker execution — September 10, 2026

The corrected standalone probe passed on Android API 35 arm64. Writer PID 2090
reached the actual system photo picker after saving typed raw estimate input and
durable intent. An external force-stop terminated only the QA package. The old
external picker remained visible; Android Back dismissed it before reader launch.
Reader PID 2325 recovered the same draft/request, explicitly reopened file selection,
and selected the synthetic PNG through Photo picker → Browse → DocumentsUI → Downloads.
It verified exact retained bytes, raw unfinished fields, file provenance, consumed
intent, duplicate-adoption conflict, subsequent database reopen and integrity, and
no confirmed estimate creation. Success and Flutter test completion appear in
`build/storage_qa/platform-estimate-picker-20260910/read.log`; report.json records
the scope and evidence. The initial failed probe used an invalid recovery identity;
that test setup was corrected, with no production behavior change.

This closes this one emulator/native file-selection parity check, not full visible
editor acceptance, physical power-loss behavior, every provider, or production auth.
The migration remains active; all other completion gates remain unchanged.

## Settings recovery lifecycle boundary — September 10, 2026

The current source scan found no direct Drift/local_database/LocalDraftStore use
in screens/shared/shell. Four legacy JSON repository open factories still exist
for compatibility tests; normal application construction does not call them.
The preview-only notification fallback remains as previously documented.

Settings draft discovery previously used permanently true catalog callbacks.
AppPreferencesController now exposes its live recovery capability, and
PreferenceDraftRecovery checks it for construction, discovery, discard and resume.
If disposal occurs during resume, the opened workflow is closed before publication.
Saved records and codecs are unchanged. The native regression verifies disposal
hides entries, rejects resume/discard/new discovery ownership, and allows a fresh
controller to recover the same draft identity and revision. This is a lifecycle
safeguard, not new account authentication or a change to device-wide settings scope.

Eleven settings catalog/selected-recovery checks passed and analysis was clean.
The two changed authored production files are 251 and 203 lines. No schema,
unapproved visual UI, inventory, 5.7, commit or push changes.
Seven additional saved-work integration/screen and preferences repository boundary
checks also passed. The normal Android debug build passed. The full-suite checkpoint
remains the earlier 993 pass / 6 known UI expectation failures; it was not rerun for
this bounded lifecycle correction. Migration completion remains unproven.

## Stale settings write admission — September 10, 2026

Disposed AppPreferencesController instances now reject new save and retry calls,
including preview-only controllers; canRetrySave also becomes false. Already admitted
writes remain queued and finish normally, preserving the installation-switch drain
contract rather than dropping acknowledged user work. Tests cover disposal before
queue execution and retry after a failed write. No settings values, codecs, schema
or visual layout changed; the controller remains 255 lines.

Ten focused lifecycle/recovery/repository tests and six mounted installation-switch,
rollback and host-failure checks passed. Analysis is clean. Evidence is retained in
build/storage_qa/preference-lifecycle-20260910, with source hashes and scope limits.
This is lifecycle protection, not production account authorization. The goal remains
active and the previously documented completion gaps remain open.

## Consolidated local persistence regression — September 10, 2026

The reusable runner completed core (43 files, 173 tests), domains (72 files,
202 tests), and editors (74 files, 135 tests): 510 passed, zero failed or skipped.
The 867-file source fingerprint matched before/after. Authoritative artifact:
build/storage_qa/20260910T142123Z-4f674bbc/report.json, with per-suite machine logs.
All 16 Python harness checks also passed. This checkpoint includes the settings
recovery/write lifecycle corrections; Android native estimate-picker execution is
separate evidence under platform-estimate-picker-20260910.

The full discovered suite was not rerun here; its earlier six UI expectation
failures remain unresolved. Global Settings restore selection/review/confirmation/
retry integration remains unimplemented, and the owner has been asked about the
separate-page presentation. Calendar Day switches remain temporary and unwired.
Older/physical/Windows runtime coverage and the documented native image recovery
pre-checkpoint window remain unverified or unresolved. Cloud release-one work
is not supplied by local outbox or development identity fixtures. No completion
claim or inventory cutover is justified by this selected-suite checkpoint alone.

## Restore checkpoint discovery boundary — September 10, 2026

LocalRestoreWorkflow.listCheckpoints now provides immutable checkpoint summaries
through local_checkpoint_catalog.dart. Presentation code need not enumerate files,
parse manifests or touch SQL. Complete candidates undergo existing database/hash/
attachment verification. Partial, malformed and linked entries are reported as
unavailable without deletion; a redirected root is refused. The workflow serializes
discovery with restore actions and checks installation identity/revision before
publishing results. Listing neither replaces a pending review nor grants activation;
review and confirmation retain their independent validation.

Twenty-three focused catalog/restore/bundle checks and fifteen switch/staging
regressions passed. Analysis is clean and the normal Android debug build passed.
Evidence: build/storage_qa/checkpoint-catalog-20260910/report.json and logs. The two
production files are 63 and 169 lines. No UI, schema, account authority, 5.7, inventory,
commit or push changes. Global Settings connection still awaits its presentation
choice and access wiring; migration completion is not claimed.

## Restore access revalidation — September 10, 2026

LocalRestoreWorkflow now requires an injected live authorization check. Admission,
discovery/review publication, preparation and installation switching recheck it.
The lower-level switch coordinator accepts the workflow's check after verification,
after pausing and before selection. Revocation during pause releases the pause and
leaves the old runtime open with unchanged durable selection; it does not consume
or activate the reviewed checkpoint. Revocation after close still requires explicit
reopening of the recorded selection under renewed access, not an automatic switch.

Tests use an explicit synthetic callback, not Firebase/authentication. A test revokes
access from inside the runtime pause and verifies one resume, zero closes/opens and
selection revision zero. Separate tests deny listing, review and confirmation after
revocation. Sixteen focused checks and fifteen overlapping workflow/mounted regression
checks passed. Analysis is clean; Android debug build passed before an initializer-only
analyzer cleanup. Evidence: build/storage_qa/restore-access-20260910. Production access
wiring and restore presentation remain unfinished. No UI/schema/5.7/inventory/commit
or push changes; migration remains active.

## Native image handoff gap: source-confirmed — September 10, 2026

Inspected the installed image_picker_android 0.8.13+21 dependency read-only.
ImagePickerDelegate.retrieveLostImage (lines 261–289) reads cached paths, optionally
resizes them, clears the cache at line 286, then returns results to Dart. Its normal
finishWithSuccess/finishWithListSuccess paths (approximately lines 975–1014) save
results only when no pending callback exists. A normal callback therefore has no
replay journal either. ImagePickerCache.saveResult uses SharedPreferences.apply,
which supplies no synchronous disk acknowledgment to the delegate.

NativeMediaPickerCoordinator records returned paths only after gateway.pick/recover
returns. Consequently Dart-side retries or the successful file-picker reselection
probe cannot prove automatic camera/gallery recovery across death in this handoff.
The remaining repair must cover both normal and lost-result delivery, preserve a
request identity before native launch, retain replayable results until the local
request/attachment transaction acknowledges them, and reject mismatched or stale
acknowledgments. It must also validate referenced bytes, not merely retain paths in
an evictable cache. An acknowledged native protocol belongs behind the media gateway,
not in widgets or SQL schemas. A controlled local Android plugin adaptation is the
appropriate integration point; do not edit the shared pub cache or read undocumented
plugin preferences directly from application screens. No dependency fork or native
repair has been implemented by this inspection. This gap remains open.

## Request-aware native acknowledgement boundary — September 10, 2026

NativeMediaPickerCoordinator now supports JournaledNativeMediaPickerGateway:
pick/recover receive the existing durable request identity, and acknowledgement
occurs only after attachment copying/verification and retained IDs have committed.
A failed acknowledgement keeps that SQL state; recovery retries acknowledgement
without importing originals again. Existing gateways retain their prior behavior.

A native SQLite test uses a synthetic journal gateway: a missing source prevents
acknowledgement; restored source bytes allow retention; an injected acknowledgement
failure survives database reopen; after deleting the original source, recovery
verifies retained bytes and acknowledges the same request without a legacy picker
call or another import. Five coordinator checks passed after that test expansion;
the earlier combined coordinator/estimate widget run passed nine checks. Analysis
is clean and the normal Android debug build passed.

This is the Dart protocol portion only. NativeDeviceMediaGateway still implements
the original interface; no Android journal/native acknowledgement implementation
or plugin override is connected yet. Therefore this checkpoint does NOT eliminate
the source-confirmed normal/lost-result handoff windows. Implementing the native
side and validating forced termination before/after SQL acknowledgement remain next.
No UI/schema/5.7/inventory/commit/push changes.

## Workspace native journal foundation — September 10, 2026

Imported image_picker_android 0.8.13+21 into third_party/image_picker_android,
retaining upstream license, sources, tests and an UPSTREAM.json file hash inventory.
An offline path override selects the same version; the shared pub cache is unchanged.
The new DurableMediaResultJournal uses app-private SQLite with synchronous FULL,
request-key checks, replayable retained paths, flushed app-private file copies and
idempotent acknowledgement. Different pending identities cannot overwrite each other.

Three Robolectric API 28 tests passed: retained bytes survive journal reopen and
original-source deletion, a pending request cannot be overwritten/acknowledged, and
a missing source does not publish ready results. The first run exposed canonical
host-path handling; canonicalizing the files-directory base fixed it without allowing
redirected child folders. This is JVM/native SQLite test evidence, not an Android
process-kill or physical-device proof. Copy-integrity verification, directory-entry
durability, native callback/channel wiring, cancellation/legacy recovery, and Dart
integration remain unfinished; the journal is currently unused by picker callbacks.

App analysis is clean after excluding only the upstream standalone example and
Pigeon inputs, whose development dependencies are separate. Runtime plugin Dart
remains analyzed. The QA source fingerprint now includes the local plugin runtime,
native sources/tests, generator input, pubspec and provenance; its regression test
checks native edits invalidate evidence. All 16 Python harness tests passed.
No visual/schema/5.7/inventory/commit/push changes. The migration remains active.

## Native journal integrity and directory flush — September 10, 2026

The currently unused native journal now stores path/length/SHA-256 manifests,
checks source before/after copying, verifies retained bytes, and refuses changed,
missing or redirected replay files without clearing the original entry. Production
uses strict Os.open/fstat/fsync on the journal and parent directories after file
flush and before SQLite ready-state publication. Android's public constants lack
O_DIRECTORY; the implementation uses O_RDONLY and verifies the descriptor is a
directory with fstat instead. No ignored directory-sync failures.

Five focused Robolectric tests pass, including same-length corruption and injected
directory-sync failure. Directory operations are explicitly injected in JVM tests:
Robolectric's host filesystem implementation cannot open directory descriptors.
This does not prove real Android fsync or power-loss recovery. The broader native
plugin run failed (36 executed, 5 failed): two were the initial directory model
failure, now covered by explicit injection; three upstream class initialization
failures require Java 21 for their default SDK. No full native-suite pass is claimed.
App analysis passed. Native callback wiring, channel acknowledgement, cancellation,
legacy recovery, full native regression and device interruption tests remain open.

## Native regression runtime corrected — September 10, 2026

The installed OpenJDK 21.0.11 successfully ran the entire vendored image-picker
native suite: 108 tests, zero failures/errors/skips across seven classes. Counts
were verified from JUnit XML, not inferred from Gradle's exit alone. This supersedes
the earlier Java 17/default-SDK initialization failures. Command-local JAVA_HOME
left Flutter's normal JDK configuration unchanged. No upstream cases were skipped
or assertions altered. Evidence: build/storage_qa/native-plugin-java21-20260910.

The journal still is not connected to native result delivery or the Dart gateway;
its JVM directory-flush injection is not real-device proof. Callback wiring,
cancellation/legacy handling and actual process-kill tests remain required. The
migration is active and inventory remains deferred. No commits/pushes/5.7 changes.

## Native delivery and journal channel connection — September 10, 2026

The workspace plugin now registers a request-keyed begin/recover/acknowledge channel
on a background task queue. It shares its journal with the activity delegate. With
an active request, single and list successful delivery passes through verified native
retention before callback; recovered results are retained before clearing upstream
cache. Retention failures report a native error and preserve upstream retry paths.
Without an active journal request, existing plugin behavior remains in place.

All 108 existing native tests passed after native wiring. An additional delegate
regression covers both successful retention-before-callback and injected storage
failure; neither path acknowledges the journal before Dart. The additional focused
case passed separately. App analysis is clean. Dart NativeDeviceMediaGateway still
uses the legacy interface and has not called begin/recover/acknowledge, so the app's
camera/gallery durability gap is NOT yet closed. Native channel round-trip, live
request association across errors/cancellation/restart, legacy cached-result import,
and actual process-kill tests remain required. No UI/schema/5.7/inventory/commit/push
changes. The migration remains active.

## Native acknowledgement history — September 10, 2026

The native journal now retains acknowledgement receipts independently of its active
handoff slot. This prevents recovery of an older already-retained draft from failing
or clearing a newer native request. Acknowledgement remains idempotent across later
requests and database reopen; unknown keys still fail and acknowledged capture keys
cannot be reused. An explicit native journal schema 1→2 upgrade preserves the old
acknowledged row. Main application SQLite/Drift schema and workflow payloads are unchanged.

Six focused native journal tests passed, including old acknowledgement after a new
request/reopen and the version-1 upgrade. The broad native checkpoint remains the
previous run; this bounded change did not rerun every upstream test. Dart gateway
activation, error/cancellation association and actual device interruption checks
remain required before closing the native handoff gap. No UI/5.7/inventory/commit/push
changes. Migration remains active.

## Android gateway activation — September 10, 2026

NativeDeviceMediaGateway now implements the journal interface. On Android,
camera/gallery launches await native begin before opening the picker; recovery
uses request-specific native replay, or prepared legacy-cache import; retained SQL
results trigger native acknowledgement. Non-Android and file-picker paths bypass
this channel. Invalid channel payloads and premature acknowledgement fail closed.
Native recovery returns an explicit legacy-needed flag, preventing an acknowledged
older request from consuming another native cache. Native copies preserve recognized
image extensions for downstream media handling.

Twelve Dart gateway/coordinator/estimate checks passed. All 111 native tests passed
with zero failures/errors/skips under Java 21. Analysis is clean. Evidence:
build/storage_qa/native-gateway-activation-20260910. Unlike earlier checkpoints, the
Android application path is now connected, but no real device/emulator channel,
directory-fsync or forced-termination proof has been collected for this activation.
Those runtime gates, cancellation/error lifecycle coverage and remaining migration
completion work remain open. No UI/main-schema/5.7/inventory/commit/push changes.

## Actual Android native handoff interruption — September 10, 2026

The new standalone estimate_native_journal_interruption_test passed on API 35 arm64.
Writer PID 1922 used the real image-picker library path through system Photo picker →
Browse → Downloads. Native file/hash/directory flush completed, exact bytes were
checked, and the probe paused before returning paths to the Dart coordinator. The
QA process was externally force-stopped at that marker. The synthetic download and
its observed picker cache copy were removed. Reader PID 2280 reopened the same fixture,
verified SQLite had no returned paths/retained IDs yet, recovered via native replay
without reselection, adopted exact bytes, rejected duplicate adoption and reopened
SQLite again with unchanged raw estimate and image. No confirmed estimate was created.

This is real native channel/fsync/replay evidence for the library delivery boundary;
it is not camera capture, physical power loss, all providers, or a complete visible
editor acceptance test. Cancellation/permission-error/legacy activity recovery and
additional interruption boundaries remain to validate. Evidence and scope are in
build/storage_qa/native-journal-runtime-20260910/report.json and PID logs. The isolated
QA package was removed and emulator stopped. No 5.7/inventory/commit/push changes.

## Native selection discard coordination — September 10, 2026

ReceiptMediaSession and EstimatePhotoMediaWorkflow now discard selections through
the shared coordinator instead of clearing only the SQL request. The store validates
the exact current request/scope inside its cancellation transaction before invoking
native abandonment; it clears the intent only after that local native operation
succeeds. Native failure rolls back SQL cancellation. Native abandonment records an
idempotent acknowledgement even for pending selections, without deleting retained
files or the parent draft. Retrying an old abandonment cannot disturb a newer request.
The same path handles an explicit empty picker result.

Sixteen Dart coordinator/request/gateway/estimate checks and eight native journal
checks passed. A new test verifies failed native abandonment keeps the SQL request,
wrong-owner discard never calls native code, and a successful retry clears only the
selection. Native tests verify abandonment/reopen/new-request isolation. Analysis
is clean. This fixes a request-lifecycle gap found before camera/error runtime QA;
real-device cancellation/permission-error validation remains outstanding. No visual,
main-schema, 5.7, inventory, commit or push changes. Goal remains active.
Six additional receipt recovery/adoption regressions and the normal Android build
also passed. Logs and counts: build/storage_qa/native-discard-20260910/report.json.

## Actual Android camera cancellation and replay — September 10, 2026

Extended the native-journal probe with camera/library source selection and optional
cancel-first execution. On API 35 arm64, writer PID 1944 canceled the external camera
using Back, verified SQL selection removal and unchanged parent estimate, reopened
camera, captured/confirmed an image, recorded its test-owned digest and reached native
replay-ready. External force-stop then killed the QA app before Dart received paths.
Both observed QA camera-cache files were removed. Reader PID 2315 recovered without
reopening camera, verified matching digest/raw estimate, rejected duplicate adoption,
reopened SQLite again and checked integrity/no confirmed estimate. Evidence:
build/storage_qa/native-camera-runtime-20260910/report.json and PID logs.

This proves emulator cancellation→retry and normal camera-result handoff replay.
It does not prove physical power loss, denial/error recovery, or death while the
external camera activity is open (legacy lost-activity path). Those remain separate
runtime gates. Probe analysis passed; QA package removed and emulator stopped. No
production layout, main schema, 5.7, inventory, commit or push changes. Goal stays active.


### Android external camera activity process death — 2026-09-10

Extended the existing native journal interruption probe with an activity mode that
uses one unchanged QA APK. A fresh fixture selects write; Android process recreation
selects recovery from that same fixture. Recovery waits at most 20 seconds for the
returning activity result without opening another picker. A unique original camera
cache JPEG supplies an independent SHA256 oracle; ambiguous sources fail the probe.

On API 35 emulator, writer PID 1650 saved the raw estimate and opened the external
camera. `am kill` killed only the background QA app, with its PID verified absent
before capture. Capture/Done in the surviving camera restarted the app as PID 2089,
without reinstall or manual app launch. Recovery passed: exact raw unfinished input,
photo digest matching the original capture, duplicate-adoption rejection, persisted
photo and draft after database reopen, no confirmed estimate, and SQLite integrity.
Evidence: `build/storage_qa/camera-activity-death-20260910/report.json`, writer/reader
logs, kill metadata, and external-camera UI XML (no screenshots).

Focused gateway/coordinator regression: 9 passed. Flutter analysis: no issues.
Normal Android debug build passed and its normal application ID was verified after
the probe. QA package uninstalled and emulator stopped. Only the integration probe
and this audit were changed; no production UI, schema, or storage boundary changed.
This closes the emulator external-camera process-death gate, not physical battery
loss, older-device validation, native error/denial cases, or the full migration audit.
The migration goal remains active; 5.7 and inventory remain untouched. No commit/push.


### Native recovery error preservation — 2026-09-10

Found that retrieveLostImage cleared cached errors with no path and returned null,
which concealed failures as empty recovery. It now reports the original error and
preserves cache evidence while a journal request is pending. Incomplete pending
cache also fails explicitly without clearing or acknowledging. This changes native
recovery only; main SQLite schema and UI/workflow interfaces are unchanged.

Verification: 114 native plugin tests passed with zero failures/errors/skips under
Java 21, including two new delegate regressions; 9 focused Flutter gateway/coordinator
tests passed; analysis clean; normal Android debug build passed. Evidence resides in
build/storage_qa/native-recovery-errors-20260910/report.json and captured logs/XML.
These new error regressions use JVM mocks, not device denial injection. Broader
migration completion and platform/error validation remain open. No commit/push,
5.7 edits, inventory changes, or unapproved layout changes.


### Native retention retry stale-error correction — 2026-09-10

A new regression reproduced successful recovered-byte retention returning the prior
native_retention_failed cache error, which Dart would throw instead of accepting
that successful retry. The native delegate now removes only that resolved error
after nonempty journal-backed retention succeeds. Failed retries preserve the cache;
unrelated errors remain visible. No UI, workflow API, or SQLite schema change.

Verification: regression failed before the fix on the stale-error assertion. After
fix, all 115 native tests passed with no failures/errors/skips, 9 focused Flutter
tests passed, analysis was clean, and the normal Android debug build passed.
Evidence: build/storage_qa/native-retention-retry-20260910/report.json and logs/XML.
This is injected JVM failure evidence, not physical device disk-failure validation.
Migration remains active; full completion/platform audit remains outstanding.
No Git commit/push, inventory work, or 5.7 changes.


### Current migration boundary and regression checkpoint — 2026-09-10

Current screens/shared/shell scan found no direct Drift/database imports, SQL calls,
or LocalDraftStore construction. Reviewed estimate workflow/controller input and
main schema: recovery uses workflow identity and typed raw state, while SQLite owns
records, revisions, commands, drafts and metadata. Visual widths/widgets/navigation
are not schema columns. Existing architecture-boundary tests passed in this run.
Authored production Dart scan found no file over 500 lines (generated output excluded).
Normal main/startup/app scan found no legacy file-repository/Hive/preferences construction.
The Settings backup/sync tile remains noninteractive and has no restore-workflow wiring.

Fresh unchanged-source checkpoint 20260910T152745Z-1012c58f passed all declared suites:
182 core, 202 domain, 135 editor checks (519 total), zero failures/skips. The harness
verified completion and matching before/after source fingerprints. This is the declared
storage regression set, not another full discovered-suite run; the six older full-suite
UI expectation failures remain unresolved. Native plugin verification remains separately
recorded as 115 passing tests in native-retention-retry-20260910.

The matrix now reflects verified Android native handoff recovery instead of its stale
pre-journal status. Remaining work includes restore interaction/access wiring, pending
Calendar Day behavior decisions, native concurrency review and retained-file cleanup,
physical/older-platform/failure validation, and final scope-wide completion audit.
Substantial layout redesign should not require schema changes solely for presentation;
new navigation must still honor lifecycle guards. Deferred inventory remains a separate
coupling risk to remove in its authorized later port. No completion claim or commit/push.


### Work draft-opening owner lifecycle — 2026-09-10

Six new regressions reproduced estimate/invoice/job draft factories returning
controllers when the owner was disposed before or during asynchronous opening.
WorkPersistenceSession now guards draft-repository access and exposes a shared
post-load owner check. All twelve Work draft factories use that check after loading;
existing exception cleanup closes unpublished sessions. Directory factories are
separate owners and were not changed in this bundle. No raw input/schema/UI changes.

New primary lifecycle cases verify rejected opening, registry pause/flush after
cleanup, SQLite integrity, and successful opening through a replacement owner.
The lifecycle test is registered in the reusable suite manifest. Focused primary,
query-lifecycle and compatibility checks: 15 passed. Related delivery/review/items/
signature/notes/assignment/schedule/materials/payment workflow checks: 21 passed.
Analysis clean; normal Android build passed. Evidence:
build/storage_qa/work-draft-open-lifecycle-20260910/report.json and logs.

The 519-check broad checkpoint predates this fix; it is not represented as covering
this changed source. This fix addresses opening, not every action through previously
issued controllers; application pause/drain and remaining lifecycle review still
matter. Work session file remains 473 lines. Migration remains active with existing
completion gaps; no commits/pushes, inventory, 5.7, or unapproved visual changes.


### Directory draft-opening owner lifecycle — 2026-09-10

Eight new cases reproduced customer/company/employee/vehicle controllers returned
after disposal before or during draft loading. Directory repository access now
rejects disposed owners, and customer/profile factories recheck after initialization
before publishing state. Existing exception cleanup closes unpublished sessions.
Tests confirm replacement owners can still open drafts and SQLite remains valid.
The lifecycle test is registered in the reusable storage suite.

Validation: 24 focused lifecycle/catalog/compatibility/customer checks plus 10 editor
recovery/handoff checks passed. Android debug build passed; analysis is clean after
correcting one brace-style lint (build preceded that behavior-neutral correction).
Evidence: build/storage_qa/directory-draft-open-lifecycle-20260910/report.json and logs.
No schema/payload/layout changes. Previously issued controller actions remain a
separate lifecycle concern; broad 519-check evidence predates these owner fixes.
Goal remains active; no commit/push, inventory work, or 5.7 changes.


### Expense draft-opening owner lifecycle — 2026-09-10

Manual/planned expense opening already rejected owners disposed before loading, but
two new tests reproduced controllers returned when disposal occurred during loading.
Expense, recurring-plan/occurrence, and payment factories now check owner lifecycle
before work and after draft initialization. Payment additionally checks its expense
and recurring owners. This prevents seeding/publishing a newly opened controller
from a disposed owner; existing cleanup preserves saved rows and releases sessions.

Four new before/during cases are registered in the reusable harness, including no
unintended new draft rows and registry/integrity checks. With existing expense/plan/
occurrence/payment and selected-recovery regressions, 17 checks passed. Analysis
clean, normal Android build passed. Evidence:
build/storage_qa/expense-draft-open-lifecycle-20260910/report.json and logs.
New interleaving tests cover manual/plan; occurrence/payment have existing workflow
regressions, not exhaustive owner-interleaving coverage. This does not claim all
already-issued controller actions are lifecycle-guarded. No schema/layout changes,
5.7 edits, inventory work, commits or pushes. Migration remains active.


### Payment and occurrence owner-interleaving verification — 2026-09-10

Expanded expense_draft_open_lifecycle_test to twelve before/during combinations:
manual expense, planned expense, occurrence, payment owner, payment expense owner,
and payment recurring owner. Tests seed a real SQLite plan/occurrence, reject draft
opening after the selected owner is disposed, verify no new workflow draft, compare
all existing local-record rows before/after, and check registry pause/integrity.

All twelve lifecycle cases plus four existing payment/occurrence workflow tests
passed (16 total). Analysis clean. Evidence:
build/storage_qa/payment-owner-lifecycle-20260910/report.json and logs. This closes
the previously recorded occurrence/payment opening-interleaving test gap; it does
not establish every action on an already-issued controller. Only tests/audit changed;
no production rebuild was needed for this test-only extension. Goal remains active.
No schema/UI changes, inventory, 5.7 edits, commits or pushes.


### Work/directory write admission after disposal — 2026-09-10

Five regressions reproduced new saves accepted after owner disposal in Work,
customers, company, employees, and vehicles. Added entry guards to the five shared
save paths. Already-admitted queue operations still drain; disposal is not inserted
inside their transaction callbacks. New rejected submissions return false using
the existing failure contract and leave database records unchanged.

Ten paired tests cover rejection after disposal and completion of previously
accepted writes. With Work/directory/employee/vehicle regression, 25 checks passed.
Analysis clean after removing a redundant test null assertion; normal Android build
passed. Evidence: build/storage_qa/disposed-write-admission-20260910/report.json.
This covers save admission, not independent draft-session revocation or every
subsystem mutation. No schema, payload, UI changes, commits/pushes, inventory, or
5.7 edits. Migration remains active pending remaining safeguards and completion gates.


### Expense/recurring mutation admission — 2026-09-10

Three paired regressions reproduced expense create/update and recurring-plan update
admitted after owner disposal. Added entry guards to expense create/receipt-create,
shared expense record mutation, and shared recurring mutation. Existing admitted
operations still complete; no disposal check was added inside their commit callbacks.
Tests compare unchanged records for rejected submissions and successful accepted work.

Focused write/open lifecycle and expense/plan/occurrence/payment regressions: 27
passed. Analysis clean; normal Android build passed. Evidence:
build/storage_qa/expense-write-admission-20260910/report.json and before/after logs.
The existing lifecycle fixture is reused by the new admission tests; the new test
is registered in suites.json. New paired cases cover create/update/plan, not every
operation independently. No UI/schema changes, commits/pushes, inventory or 5.7
changes. Full migration completion remains unproven and the goal stays active.


### Activity and receipt owner lifecycle — 2026-09-10

Reproduced day-note/start-workday drafts returned after owner disposal before/during
loading, plus receipt creation admitted after disposal (five failing cases). Guarded
day-note/workday draft repository access and rechecked after initialization in day-note,
start and end workflows. Shared receipt mutation now rejects disposed owners at entry;
an already-started receipt save still completes. No payload/schema/layout changes.

Six new cases plus existing day-note/start/end/receipt regressions: 16 passed.
Analysis clean after brace-style corrections; Android build passed before those
behavior-neutral corrections. Evidence: build/storage_qa/activity-receipt-owner-20260910.
The receipt legacy-controller regression uses its existing file fixture; new lifecycle
cases use LocalPersistence SQLite. These results are not interchangeable evidence.
Remaining observed issue: day-note/workday queues have inner disposal checks that can
reject already-admitted commands; investigate paired drain tests next. Migration stays
active. No commits/pushes, inventory work, or 5.7 modifications.


### Activity accepted-command draining — 2026-09-10

Paired tests reproduced day-note and workday commands admitted before disposal but
rejected inside their queued callback. Removed only that second check. The entry
check still rejects new post-disposal commands, while accepted commands reach their
existing transaction and acknowledgement path. SQLite reopen verifies committed
note/workday presence for admitted commands and absence for rejected commands.

Four paired cases plus workday, raw draft/retry and mounted lifecycle regression:
14 passed. Analysis clean; Android debug build passed. Evidence:
build/storage_qa/activity-write-drain-20260910/report.json and before/after logs.
This resolves the accepted-command issue observed in the previous activity bundle.
No schema/payload/visual changes, commits/pushes, inventory or 5.7 edits. Migration
remains active; these focused checks do not replace final broad/platform validation.


### Combined owner lifecycle and restore regression — 2026-09-10

Ran fourteen current test files together after the owner lifecycle/admission/drain
corrections: application storage lifecycle, mounted switch/runtime/storage, switch
coordinator, restore workflow, failed switch host, all new owner opening/admission/
drain regressions, and draft repository architecture boundary. The shared machine-log
evaluator verified 85 passing checks, zero failures/skips/missing/unfinished tests,
terminal success, and identical source fingerprints before and after execution.

Evidence: build/storage_qa/combined-owner-restore-20260910/report.json and tests.jsonl.
This strengthens interaction evidence across the changed controllers and restore
services. It is a selected host regression checkpoint, not a full discovered-suite,
physical-device, native-media, cloud, or visual-acceptance claim. Only audit notes
changed during this verification turn; no production rebuild was necessary.
The original migration goal remains active with restore interaction, remaining native
concurrency/retention cleanup, platform/failure validation and final completion audit
still open. No commits/pushes, inventory work, 5.7 changes, or unapproved UI edits.


### Native launch-request binding — 2026-09-10

Result processing previously selected the currently active journal key at delivery,
which could differ from the launch identity. PendingCallState now captures the key;
a synchronous plugin-cache commit preserves it before launch for lost-activity
recovery. Failed key persistence leaves no pending callback. Processing uses the
captured/cached identity so the journal rejects a replacement key; old caches retain
legacy scoped recovery fallback. Main SQLite schema and UI interfaces are unchanged.

Native suite: 116 passed, zero failures/errors/skips, including delayed cancellation
with replacement active key. Flutter gateway/coordinator: 9 passed. Analysis and
normal Android build passed. Evidence: build/storage_qa/native-launch-request-binding-20260910.
The new identity metadata uses the existing Android plugin SharedPreferences cache;
retained result bytes/acknowledgements remain native SQLite. This is not a new domain
record persistence path. Device interruption evidence predates this change and must
be refreshed; overlapping callback orderings are not exhaustively proven. Migration
remains active. No UI changes, commits/pushes, inventory or 5.7 edits.


### Native launch binding Android process-death revalidation — 2026-09-10

Rebuilt the activity-mode QA probe from current source (run activity_binding_20260910b).
Verified its separate QA package and APK hash. The app-private picker metadata
contained the launch request key before killing writer PID 1494 while the external
camera stayed foreground. After capture/Done, Android restarted the same unchanged
installation as PID 2100 without reinstall/manual launch. Recovery passed exact raw
estimate input, photo SHA256 comparison with the original capture, duplicate-adoption
rejection, database reopen persistence and SQLite integrity.

Evidence: build/storage_qa/native-binding-activity-runtime-20260910/report.json,
writer/reader logs, kill metadata, QA picker metadata and camera UI XML (no screenshots).
QA package removed, emulator stopped, normal APK rebuilt and package ID verified.
This refreshes API35 external-camera process-death evidence after launch binding;
it does not prove all callback races, physical power loss or older platform behavior.
Only audit/evidence changed this turn. Migration remains active; no commits/pushes,
inventory, 5.7 modifications, or unapproved UI changes.


### Native request-binding failure verification — 2026-09-10

Added delegate regressions for a failed launch-identity cache write (no external
picker launch, no stuck pending callback, retry succeeds) and a cached original
request under a replacement active journal key (original identity used, no new-key
retention/acknowledgement, cache evidence preserved). Corrected an initial test-only
Java generic callback declaration before running assertions.

All 60 selected delegate tests passed, zero failures/errors/skips.
Evidence: build/storage_qa/native-binding-failures-20260910/report.json and native
JUnit XML/log. This is injected JVM failure evidence; API35 process-death runtime
remains separately recorded. Only native tests/audit changed; production build and
Dart tests were not repeated for this test-only addition. Migration remains active.
No commits/pushes, schema/UI changes, inventory work or 5.7 modifications.


### Unjournaled launch isolation — 2026-09-10

A regression reproduced a live unjournaled picker cancellation using a subsequently
created active journal request. Such known unjournaled callbacks now bypass journal
processing; missing-key legacy fallback remains for lost-activity recovery without a
live callback. This prevents cross-request retention/acknowledgement in this ordering.

All 61 selected native delegate tests and 9 Flutter coordinator/gateway
tests passed. Analysis clean and Android build passed. Evidence:
build/storage_qa/unjournaled-launch-isolation-20260910/report.json, before/after logs.
This is mocked overlapping-caller evidence, not exhaustive device-race validation.
No main schema/UI changes, commits/pushes, inventory or 5.7 edits. Goal remains active.


### Reusable native-media QA runner — 2026-09-10

Added tooling/storage_qa/run_native_media_qa.py so native journal/plugin tests have
a reproducible evidence path alongside Flutter storage suites. It uses an explicit
command-local JDK, forced Gradle test execution, timeout/process-group cleanup,
source fingerprints, raw Gradle logs, captured JUnit XML, and expected test-class
inventory. Its evaluator checks testcase counts against declared totals and refuses
empty/malformed/failed/skipped/missing/duplicate/unexpected class results. Process
failure, interruption, timeout, or source mutation cannot produce passed=true.
README documents invocation and JVM-only limits. No global Java setting changed.

Actual execution: all 119 native tests passed, no failures/errors/skips/missing
classes, source unchanged. Evidence:
build/storage_qa/20260910T160502Z-native-dcf666f5/report.json. All 20 Python storage
harness checks passed, including four new evaluator tests. This was a harness-only
change; no production build or Flutter regression rerun was required. It does not
replace device interruption or final migration audit. Goal remains active; no
commits/pushes, inventory, 5.7 or unapproved UI changes.


### Application-owned restore service boundary — 2026-09-10

UiLabStartupController can now be configured once with a LocalRestoreWorkflow and
live authorization callback. Presentation can receive the stable service getter;
selection storage/runtime/database construction stays in application composition.
Its current-database callback resolves the currently attached UiLabApp each time,
not a database captured by a Settings route. Duplicate configuration is rejected.
Selection lifetime remains composition-owned, spanning app installation switches.

New real-SQLite boundary test verifies stable service identity, detached-host rejection,
private checkpoint review, revoked confirmation with unchanged selection, and detach
rejection. Combined with restore workflow and mounted runtime regression: 14 passed.
Analysis clean; Android build passed. Evidence:
build/storage_qa/startup-restore-boundary-20260910/report.json and logs.
This integration point is NOT configured in main yet; Settings presentation and
production access wiring remain unfinished. Callback revocation in this test is
synthetic authority, not Firebase accounts. No schema/layout changes, commits/pushes,
inventory or 5.7 edits. Migration goal remains active.


### Mounted application-owned restore service verification — 2026-09-10

The existing mounted restore tests now configure and use startup.restoreWorkflow
for private checkpoint review, confirmation, and failed-open retry. Rollback still
uses the lower-level coordinator to verify the old installation's unfinished input.
Assertions compare the mounted database path to durable selection, without opening
a duplicate live candidate connection solely for test inspection.

Final combined service/boundary/mounted run: 14 passed; analysis clean. Evidence:
build/storage_qa/mounted-restore-service-20260910/report.json and passed-tests.log.
Earlier attempts are not passes: a void-return test helper declaration was corrected;
plain runAsync stalled draft initialization and was interrupted; opening a second
live candidate in a paused test clock caused a database-lock assertion failure.
Using the established native/widget pump and durable-selection path check resolved
those fixture issues. No production code changed in this bundle.

The shared device entry point imports this mounted test, so future device runs gain
service-level coverage; this turn is host-only evidence. Main configuration, Settings
interaction, remaining native safeguards/platform gates and completion audit remain.
No commits/pushes, schema/layout edits, inventory or 5.7 changes. Goal remains active.

### Mounted restore service macOS runtime checkpoint — 2026-09-10

The updated shared integration entry passed all three cases in the macOS application:
service review/confirmation and rollback, failed reopen with retry, and rejected
draft-save handling. The normal lib/main.dart macOS debug artifact was rebuilt
successfully afterward. All nine draft repository/architecture boundary checks passed.
Evidence: build/storage_qa/mounted-restore-service-20260910/macos-runtime-report.json
and its runtime, architecture and normal-build logs.

Runtime logs retain Drift's multiple LocalDatabase instance debug warnings. These
tests open temporary installations and validation connections; passing assertions
are not exhaustive connection-concurrency proof. No warning suppression was added.
This checkpoint does not validate physical power loss, production identities or a
Settings restore interaction. Main restore configuration, remaining platform and
durability gates, and the full completion audit remain unfinished. No product code,
visual layout, schema, inventory, 5.7 or GitHub changes were made in this checkpoint.

### Runtime reopen concurrency guard — 2026-09-10

MountedApplicationSwitchRuntime now reserves opening synchronously before awaiting
the application loader. A separate caller cannot bypass a workflow/coordinator's
busy flag to load a second application against the selected installation. The
reservation is released in finally, including loader failure, so explicit retry
remains available. No widget, schema or payload contract changed.

The mounted failure test holds a failing loader pending, calls open through both
the workflow and runtime, asserts exactly one loader started, then retries normally
and verifies restore/rollback with unfinished input. An initial fixture attempt hit
a guarded test-pump assertion; it is not a valid before-fix reproduction. After
moving that assertion outside the pump helper, all 29 focused restore/architecture
checks passed, analysis was clean, and all three macOS runtime cases passed.
Logs are under build/storage_qa/mounted-restore-service-20260910/concurrent-open-*.
Normal lib/main.dart macOS debug build passed afterward; the checkpoint is recorded
in concurrent-open-report.json. No commits or pushes were performed.

Installed Drift 2.34.4 db_base.dart counts instances by runtimeType when producing
the multiple-database warning; it does not compare executors or file paths. The
selection service uses its own installation_selection database and every
LocalDatabase.file call creates a native executor. Thus the warning alone does not
prove shared-executor misuse. Warnings remain visible; this is not exhaustive
cross-process/concurrency certification. Migration completion remains unproven.

### Combined current storage regression — 2026-09-10

The declared core/domain/editor harness completed after the owner-lifecycle and
restore-runtime opening changes: 183 core + 254 domain + 135 editor checks = 572
passing checks across 45 + 79 + 74 files. No failures, skips, missing suites,
unfinished tests or source fingerprint changes. Evidence:
build/storage_qa/20260910T162524Z-a5af2c64/report.json and raw suite JSONL logs.
This supersedes the earlier declared-suite checkpoint for these source changes.

This was not an all-discovered-test rerun. The six previously recorded unapproved
UI expectation failures remain unresolved, and the existing platform, restore
integration and completion gates remain open. No production changes, commits,
pushes, inventory integration or 5.7 edits were made during this checkpoint.

### Reject installation changes during restore review — 2026-09-10

LocalRestoreWorkflow now rechecks the current database path and durable selection
revision after checkpoint verification and before publishing its review. Confirmation
already rejected stale reviews; review itself now rejects a result obtained across
an installation change. The regression supplies a changing database provider and
reproduced a returned LocalRestoreReview before the fix, where StateError was expected.
An initial test getter compilation mistake was corrected before that reproduction.

All 24 focused service/startup/mounted/architecture checks passed, analysis was clean,
and the normal Android debug build passed. Evidence:
build/storage_qa/mounted-restore-service-20260910/stale-review-report.json and logs.
The previous 572-check combined checkpoint predates this service-only correction;
no broad or platform runtime rerun is claimed here. Main restore integration,
Settings interaction and the remaining completion gates are still open. No layout,
schema, draft format, inventory, 5.7, commit or push changes were made.

### Failed native retention copy cleanup — 2026-09-10

Native retention now tracks files newly created by each attempt and removes those
copies when copying, hashing, manifest construction or directory flushing fails
before SQL publication starts. It preserves original sources and existing published
recovery files. Cleanup errors are suppressed onto the original failure; redirected
roots are rejected. No cleanup runs after the publication transaction starts,
because a transaction-end failure can leave the commit outcome uncertain.

Before correction, the missing-later-source and directory-flush regression cases
both failed their unchanged-directory assertions. After correction, all 120 native
tests passed with unchanged source fingerprint, nine Dart handoff/coordinator checks
passed, analysis was clean and the normal Android debug build passed. Native report:
build/storage_qa/20260910T163703Z-native-4c9a6c79/report.json. Other logs:
build/storage_qa/mounted-restore-service-20260910/unpublished-media-*.

This closes an ordinary failure leak, not the complete native cleanup gate. Old
acknowledged copies and process termination before publication still need durable
cleanup tracking. Device filesystem failure injection was not run. No main schema,
UI, inventory, 5.7, commit or push changes were made; migration remains active.

### Durable acknowledged-native-media cleanup — 2026-09-10

Native journal schema 3 adds a cleanup queue. Acknowledgment and its original
manifest enter durable storage in the same transaction before replay paths clear.
NativeMediaCleanup removes only queued acknowledged files confined to the handoff
directory, flushes that directory, then removes the queue row. Failures retain the
row for retry; already removed files are harmless on retry after reopen. Cleanup
failure does not invalidate an already committed acknowledgment. Main Drift schema,
domain records, draft formats and presentation remain unchanged.

Versions 1 and 2 upgrade without replacing pending/ready state. Tests verify a
version-two ready result survives upgrade, acknowledgment transaction failure leaves
replay intact with no cleanup ownership, failed cleanup flush survives reopen and a
new request, unacknowledged files remain, and outside paths are rejected. All 124
native tests passed with unchanged source during the run; nine Dart handoff tests,
analysis and normal Android debug build also passed. Evidence:
build/storage_qa/20260910T164114Z-native-f22ec848/report.json and
build/storage_qa/mounted-restore-service-20260910/acknowledged-cleanup-report.json.

This has no new device-interruption evidence. Old copies whose manifests were
cleared before this upgrade are retained rather than guessed at; process death
during copying before manifest publication still needs orphan tracking. These and
the other completion gates remain open. No inventory, 5.7, commit or push changes.

### Android process-death recovery with acknowledged cleanup — 2026-09-10

The standalone estimate probe now asserts native returned paths no longer exist
after retained-file acknowledgment, then checks the retained photo digest through
adoption and database reopen. On the API 35 arm64 emulator, QA writer PID 1901
launched the camera with a persisted journal key. am kill removed that background
process (pidof verified absent); completing the surviving camera activity restarted
the same QA APK as PID 2090 without reinstall or reseeding. The reader emitted the
recovery success marker and all-tests-passed terminal output. The private native
handoff directory was empty afterward.

This proves that the tested activity-death path preserves exact raw estimate input,
recovers native media, removes its acknowledged copy, preserves the independently
retained photo through database reopen, rejects duplicate adoption and passes
SQLite integrity checks. Evidence: build/storage_qa/mounted-restore-service-20260910/
cleanup-runtime-report.json, writer/reader logs and camera-control XML. No screenshots.

The isolated QA package was uninstalled and emulator shut down; the normal main
Android debug APK was rebuilt and aapt confirmed com.maintainiac.ui_lab_2_1. Analysis
is clean. This does not prove physical power loss, older devices, or interruption
inside the native copying/cleanup transaction. Untracked-copy and other completion
gates remain open. No production UI, inventory, 5.7, commit or push changes.

### Durable ownership before native copy creation — 2026-09-10

Native schema 4 adds media_staging; destinations enter durable storage before file
creation. Publishing a ready manifest removes those staging rows in the same SQL
transaction. A later begin can remove confined partial files owned by a previous
process, flush the directory, then drop the rows. The shared process nonce leaves
current-process copies alone across helper reopenings. This is valid for the current
single-process Android app; no android:process configuration was found in the checked
application/plugin manifests. Adding multiple processes requires a different lease.

Five new tests cover prior-process partial files, current-process preservation,
cleanup flush failure, failed manifest publication rollback, and version-three
upgrade. Existing version-one/two upgrade tests also pass. Initial fixture paths
were noncanonical and two checks failed because cleanup refused them; corrected
fixtures now match production's canonical root. Final result: 129 native tests,
nine Dart media tests, clean analysis and successful normal Android debug build.
Evidence: build/storage_qa/20260910T164950Z-native-39d22fcd/report.json and
build/storage_qa/mounted-restore-service-20260910/staged-copy-report.json.

These tests model previous-process persisted state; actual mid-copy termination
still needs runtime verification. Previously unregistered copies remain untouched.
Main Drift schema, domain/UI contracts and draft formats are unchanged. No inventory,
5.7, commits or pushes. Migration remains active with completion gates still open.

### Preserve app-wide media handoff before installation switch — 2026-09-10

NativeMediaPickerCoordinator's pause now inspects the persisted installation
handoff after draining active operations. A journaled camera/library request with
unretained results prevents switching; it remains recoverable or explicitly
discardable in its owning installation. Retained results retry idempotent native
acknowledgment before the pause succeeds. Any failure releases the pause lease,
allowing recovery/discard instead of stranding the old application. File-selection
requests do not use the app-wide native journal and retain their existing behavior.

The lifecycle-only store query exposes no new editor lookup or UI/SQL dependency.
Tests cover interrupted unretained requests, failed acknowledgment of retained
results, unchanged request identity, released failure leases, explicit discard,
retry and database integrity. All 11 focused coordinator/mounted-restore checks
passed; analysis and normal Android debug build passed. The new regression is
registered in the core harness. Evidence logs: build/storage_qa/
mounted-restore-service-20260910/media-switch-guard-*.

This avoids leaving an unresolved app-wide picker journal behind when selecting a
different local installation. It does not implement cross-installation media merging
or silently discard user input. No new device run is claimed for this guard. The
remaining restore interaction, staging runtime and completion gates stay open.
No layout, schema, inventory, 5.7, commit or push changes were made.

### Mounted restore refusal with unresolved native media — 2026-09-10

The shared mounted restore regression now includes a persisted unretained camera
request. Restore fails during pause, before database close or selection change;
the original UiLabApp stays mounted, host controls are unblocked, raw input and
request identity remain, and selection revision stays zero. After fixture-only
request retirement, the same ready host successfully restores and rolls back with
unfinished input intact. No native camera was launched in this synthetic case.

All six mounted/service handoff checks passed and analysis is clean. Logs:
build/storage_qa/mounted-restore-service-20260910/mounted-media-guard-tests.log and
mounted-media-guard-analysis.log. The shared platform entry point imports this test,
but it has not yet rerun the new fourth case on devices. This bundle changes tests
only; no redundant production build is claimed. Migration remains active, with
mid-copy runtime, restore interaction and completion gates still open. No UI,
schema, inventory, 5.7, commit or push changes.

### Native staging Android process-termination proof — 2026-09-10

Added a STORAGE_QA-only debug instrumentation probe under android/app/src/storageQa.
Normal debug/release builds do not include that source set; the probe additionally
requires the isolated QA package at runtime. Writer PID 1917 copied and flushed its
file/directory, logged KILL_BEFORE_PUBLICATION, and killed itself before SQL manifest
publication. Instrumentation reported the expected crash and pidof confirmed no QA
process. Without reinstalling, reader PID 1955 verified one surviving staged file,
no ready result, previous-process cleanup, unchanged source, successful byte-exact
retry/replay, and acknowledged deletion. It returned STAGING_INTERRUPTION_VERIFIED
with instrumentation code -1 on Android API 35.

The QA package was uninstalled and emulator stopped. Normal main Android build
passed; aapt verified normal package identity and APK dex inspection found no probe
class. Analysis is clean. The harness now fingerprints Android app sources, with
regression coverage that instrumentation changes invalidate evidence; all 20 Python
harness tests passed. README records isolation, two phases, expected crash marker,
PID and result checks, and cleanup. Evidence: build/storage_qa/
mounted-restore-service-20260910/staging-probe-report.json and associated logs.

This is actual OS process termination before publication, not physical power loss
or a kill inside a write syscall. Combined with the partial-file JVM cases, it adds
runtime evidence for the recorded staging recovery path. It does not finish the
remaining restore interaction, platform or completion gates. No production UI,
domain schema, inventory, 5.7, commit or push changes were made.

### Four-case macOS restore runtime and remaining integration — 2026-09-10

The shared runtime entry passed all four current mounted cases in macOS: ordinary
restore/rollback, failed reopen/retry, failed draft saving, and unresolved native
media refusing the switch with the old application usable. Normal lib/main.dart
macOS debug build passed afterward. Logs: build/storage_qa/
mounted-restore-service-20260910/four-case-macos-runtime.log and
four-case-normal-macos-build.log. Multiple-instance Drift debug warnings remain
visible; their class-count mechanism was assessed earlier, not suppressed.

Current main.dart still does not configure the restore service; Global Settings
still lacks source review/confirmation/retry interaction. The owner has been asked
whether to add a separate page with existing components or leave presentation for
UI review. Work bootstrap permissions are explicitly ui-lab-work-owner-permissions-1
fixtures, not production identity enforcement. Neither missing cloud configuration
nor that product integration question is a filesystem/tool permission blocker.
The latest four-case runtime evidence is macOS only; other platform checkpoints
retain their earlier scope. Goal remains active; no commits, pushes or 5.7 edits.

### Current four-case iOS restore runtime — 2026-09-10

All four shared restore cases passed on the iPhone 17e simulator running iOS 26.5,
including the unresolved-media refusal case and retry using the still-mounted host.
The run used temporary local installations and a synthetic pending media request.
It does not claim iOS camera interruption, physical-device behavior, older OS support
or visual acceptance. Drift multiple-instance warnings remain retained in the log.

The simulator was shut down after testing. Normal lib/main.dart artifacts rebuilt
successfully for both simulator debug and unsigned device debug, replacing the
test simulator build as well. Evidence: build/storage_qa/
mounted-restore-service-20260910/four-case-ios-report.json and runtime/build logs.
No product code, UI, schema, inventory, 5.7, commits or pushes changed in this
checkpoint. The restore presentation decision and remaining completion gates are
still open; migration remains active.
