# Application data, storage and synchronization contract

Updated 2026-09-09. Owns cross-module storage policy; domain ownership remains
in [Product control](product_control_blueprint.md). Decision status is governed
by [the register](application_decision_register.md), especially D17–D20/U02.
SQLite with Drift is now selected (D31). This document does not claim deployment
or migration completion. Read `current_product_blueprint.md` and the dated
database handoff for current owner decisions and observed implementation limits.

Current implementation and verification status is maintained in the top gate matrix
of [SQLite remaining-work audit](sqlite_remaining_work_audit.md). The dated
implementation entries below retain historical evidence and may describe gaps
that later checkpoints resolved; they are not a declaration of current completion.

## Active SQLite implementation checkpoint — 2026-09-09

### Business data and example isolation

Owner direction in the September 25 whole-application audit: no hard-coded
business records or unfinished user work may supply ordinary application
screens, be recreated when removed, or be packaged as a new customer's data.
The audit covers every screen, default, startup seed, recovery path and storage
adapter, not just estimates. Existing development records must remain ordinary
durable user records; their fictional contents do not authorize resetting or
deleting them. This direction supersedes historical permission for ordinary
prototype/demo fallbacks elsewhere in this document and older blueprints.

Every screen must read its authorized records from the shared storage system.
Empty results stay empty; storage failures stay visible failures. Neither is
permission to manufacture customers, employees, vehicles, work, stock, receipts,
financial amounts, activity or drafts. User-entered development records remain
separate from source code and distributed application assets. Normal edits,
restart recovery and explicit confirmed deletion must work for them.

Engineering interpretation of the scope: UI labels, genuine reference data,
validation constants and empty form defaults are not fabricated business
records. Isolated automated-test fixtures are evidence, not application records;
they must not be reachable through ordinary startup or shipped-data fallbacks.
Any retained demonstration/import mechanism requires explicit isolation and
must never replace the owner's existing records or silently populate a customer
installation. A build flag defaulting off alone is not proof of that isolation.

This is a required policy, not a completed audit or implementation claim. The
whole-app audit must distinguish reachable runtime examples, gated seed code,
test-only content, legitimate reference data and unresolved paths. Removing
source examples does not authorize deleting existing saved records. Release
verification must establish that a fresh installation contains no developer
business records and that deleting a record does not cause an example to return.

### Cross-platform file preservation — September 19 owner requirement

Owner direction in the device-capability task: the app must never overwrite
anything on a user's device, whether phone or computer, on Android, iOS,
Windows, macOS or another supported platform. It must never delete anything
without the user first choosing an explicit Delete (or equivalent) action and
then confirming deletion before the destructive operation occurs.

Treat this as a required contract, not a claim that existing paths comply.
Resource pressure, OCR completion, cache limits, sync, restore and a successful
derived copy do not confer permission to delete user data. Preserve originals;
exports/copies must not replace an existing destination. Storage protection must
refuse/defer writes rather than silently reclaim user files. A deletion dialog
must identify its target and consequences; cancellation performs no deletion.
Enforcement and tests belong at the mutation boundary, not only in a widget.

Owner follow-up explicitly includes information created by the app itself:
reaching the 100 MB reserve must never cause the app to delete or overwrite
its own information to make room. Only the user may choose what to delete,
and deletion still requires confirmation. No temporary-file exception has been
authorized. Existing OCR temporary cleanup and all resource-reclamation paths
therefore require review; preserve existing information and defer new work.
Normal user-directed record edits and durable autosave must retain their separate
authorization/recovery contracts; neither is permission for pressure-triggered
replacement or for overwriting imported originals.

The shared device-capability system has no authority to delete files. Its
100 MiB reserve is governed by `device_capabilities_blueprint.md`.

September 25 startup-preservation correction: normal application startup no
longer invokes `loadRequestedWorkExamples`, including in debug builds. That
historical review helper deletes Work records, drafts and history before
installing fixtures when its marker is absent; it is not an ordinary startup
migration. Existing development records must use real persistence and survive
reopening. Explicit disposable test fixtures may still call the helper. This
change does not remove existing records or change the separate initial demo
seeding policies. Production identity and release fixture exclusion remain
separate unfinished gates; development permissions are not real account grants.
The regression `startup_preserves_development_records_test.dart` checks full
retention of pre-existing records, revisions, drafts, commands and outbox rows
across two normal startup cycles without the review-example marker.
Verification for this bounded correction: eight focused startup/recovery tests
passed, focused Flutter analysis reported no issues, and the macOS debug build
succeeded. No application launch or physical-device verification was performed.
This does not establish completion of low-storage admission, file-preservation,
production authorization, schema upgrades or the overall storage migration.

September 25 receipt-file preservation: new imports use random evidence IDs
and atomically allocated unique directories. Existing saved paths/IDs remain
readable. Same-time repeated imports must not reuse an acknowledged file's path.
The repository no longer deletes a destination, stale staging file, or imported
copy after a rejected database write. SQL failure still leaves the confirmed
receipt unchanged. Unreferenced/partial copies are deliberately retained under
the no-automatic-deletion rule; a future explicit, confirmed cleanup workflow
and accounting for these files remain unfinished. This is not an automatic
backup, a storage-space reclamation mechanism, or a complete media-pipeline audit.
The initial repeated-import probe failed before SQL confirmation because the
old timestamp-derived identity collided; it did not demonstrate loss of the
previous file. The corrected regression explicitly requires a storage failure,
retains both copies without changing the saved receipt, reopens the database,
and retries with distinct attachment identities. An initial broader run exposed
nine submission/restore failures because those services expected flat paths.
A shared relative-path resolver now preserves that legacy format and recognizes
the new allocation format without weakening canonical-path/hash verification.
The corrected receipt/domain run passed 25 checks and media adoption, evidence
review and snapshot/restore regression passed 30. Focused analysis was clean.
These are isolated host checks, not real-account or physical-device acceptance.
The macOS debug build also succeeded; the app was not launched. The printing
plugin's existing Swift Package Manager warning remains.

September 25 storage admission work in progress: `StorageWriteAdmission` supplies
a UI-independent 1 GiB warning state, conservative 100 MiB protected reserve,
serialized admission and in-memory reservations for concurrent operations. Null,
negative or failed free-space observations refuse new writes. A failed writer
releases its reservation, and checkpoints detect external consumption. Eight
isolated policy/concurrency checks pass. This service is not yet wired into
production database/media writes. Volume-specific native measurement, bounded
SQLite WAL/temporary growth, all write-path integration and dashboard alert
delivery remain open. The reference 5.7 guard was inspected read-only; its
25/50 MiB reserve policies do not meet this contract and were not imported.

September 28 shared-save correction: `LocalRecordStore.commit` now freezes the
submitted write list before waiting for SQLite. Previously a caller could clear
the list during another transaction, leaving a successful command/retry marker
without its submitted record. `LocalDraftStore.save` now serializes its nested
raw input before waiting; previously caller mutation could save an empty map
instead of the submitted form values. Both failures were reproduced with a
deliberately occupied SQLite transaction before the corrections. The regression
is `test/local_record_command_input_test.dart`, registered in the shared core
suite. It verifies submitted content, command retry/history/outbox consistency,
and nested unfinished input. It uses an isolated in-memory SQLite database, not
the owner's installation, and is not a physical power-loss test.

The same checkpoint bounds free-space probe waiting to two seconds by default.
An overdue native probe is retained rather than duplicated on retries; an
unknown result never authorizes a write. A late result alone does not publish a
successful save or clear the unknown state. This is still an isolated admission
component, not full production low-storage enforcement. Native volume reading,
write-budget integration, dashboard notification delivery, and end-to-end
low-space acceptance remain open.

Verification: 39 focused Dart storage checks and 24 Python QA-harness checks
passed; focused analysis of the five changed Dart files reported no issues.
The shared host runner now holds an OS lock so cooperating copies cannot run
simultaneously; tests verify competing-process exclusion and release after
process death. Arbitrary IDE/Flutter commands and device wrappers do not use
this lock. Windows lock behavior has code but no Windows execution evidence.
Work screens were not edited. No backup provider or automatic backup was added.
Logs for this checkpoint: `/tmp/sqlite-input-final.log`,
`/tmp/sqlite-harness-final.log`, `/tmp/sqlite-input-analysis.log`;
the reproducing failures are `/tmp/sqlite-command-input-before.log` and
`/tmp/sqlite-draft-input-before.log`. Temporary logs are not permanent acceptance
artifacts; preserve the exact tree and logs for independent review.

Receipt combined-preview boundary: the screen now asks its owning submission
session for a verified preview path rather than inspecting LocalDraftStore or
constructing an attachment store. The service checks session ownership, live
receipt visibility/revision and attachment integrity, and rejects a changed or
closed draft. It returns no Drift rows or layout state. The architecture test's
remaining direct-storage import is the separately owned Inventory catalog;
this change does not claim that all application boundaries or production account
authorization are complete.
Focused verification passed 14 policy, preview-recovery and receipt-screen
checks, including rejection when another submission session requests the draft's
preview. Analysis was clean and the macOS debug build succeeded, without launch.
The broader core/domain run `20260926T022850Z-30b5c842` was interrupted before
domain completion and is not acceptance evidence; source also changed during
that run. Its core boundary failure identified the receipt-screen dependency
corrected here and the remaining Inventory catalog dependency. A stable-source
broader rerun is still required after production storage admission is connected.

This is progress evidence, not completion or production-security acceptance.
The owner explicitly authorized the 2.1 SQLite/Drift conversion first. Latest
owner follow-up authorizes continuing directly into the 5.7 inventory port only
after the full local migration is verified complete. Inventory reuse assessment,
expanded harness testing and independent validation precede that port; its
unfinished UI must not define storage contracts. Both apps contain demo records;
5.7 remains read-only regardless. Existing 2.1 JSON demo files are left in place,
but new startup uses a separate private SQLite file and fresh demo fixtures.
Preserving those particular old fixtures is not a migration requirement.

Owner clarification: security ranks first, dependability a close second.
Incomplete input must save automatically throughout business workflows, including
quotes/estimates, invoices, expenses and jobs. Calls, distractions, backgrounding
and restart must not depend on an explicit Save. Leaving a route retains the
draft; only an explicit discard decision abandons it. Drafts preserve raw input,
including unfinished numbers, separately from confirmed business effects.
The implementation must expose and test the actual write-acknowledgment boundary;
it cannot promise recovery of input that never reached durable storage.

Dashboard/Calendar Day job-write acknowledgment checkpoint: arrival, completion
and rescheduling now await the Work store result before changing their local
plan/activity projection. Failed saves retain the previous display and report
failure. A missing linked job is rejected; a changed date/operational context
prevents an in-flight result from being projected into that new context. Shared
Dashboard plan actions now have their own cohesive part file. Native SQLite
failure-and-retry widget tests cover arrival and completion on both routes;
these four cases plus the Job Workspace failure test and Work session tests
passed (10 tests total), and full Flutter analysis was clean. Rescheduling uses
the same acknowledgment branch but has not yet received a native-picker failure
test. These checks do not establish restart reconstruction of Work plan/activity,
raw draft recovery inside the native rescheduling pickers, or production
permission revocation. Those remain follow-up work; a successful SQLite write
alone does not complete the whole Dashboard workflow.

Work plan restart checkpoint: `withWorkPlanProjections` now derives connected
Dashboard and Calendar Day job plans from the scoped, committed Work session.
All cached/fixture job-stop plans are replaced, including when the authorized
result is empty; `updateDashboardDay` no longer retains connected job plans.
Scheduled jobs use the existing Work `occursOn` date rule and creator/assignee
filter, with a stable record ID, current schedule and saved status. Unscheduled
jobs remain in Work rather than appearing on every dated Dashboard. Assignment
names remain transitional and are not production authorization. Existing
inclusive end-date semantics have not been redesigned here.

Read-only reuse assessment inspected 5.7 `maintainiac_job_store.dart`: Hive jobs
include recurrence, schedule exceptions, member IDs and vehicle IDs. That broader
model is not imported into this UI Lab projection repair. The already-connected
SQLite Work session is reused; neither 5.7 writes nor executable validation took
place. A native regression forces a reschedule failure, retries, closes/reopens
the database, checks date/status recovery and rejects cached duplicates or
cross-employee projection copies. Dashboard/Calendar failure tests also passed.
These tests are included in the reusable QA manifest. Twenty-one focused
projection, Dashboard, Calendar Day and workday regressions passed; an additional
restricted-session empty-query check passed. Full Flutter analysis was clean and
the macOS debug build succeeded. Job activity entries remain a separate
unfinished projection; this checkpoint proves plan recovery only.

Work status history checkpoint: the existing atomic `local_record_revisions`
ledger now supplies scoped job arrival/completion events through
`work_status_history.dart`. The Work session opens records, financial entries and
history in one read transaction and publishes an identical timestamp/revision
snapshot only after a successful command. No-op saves and subsequent unrelated
edits do not create status events. Initial seeded/imported statuses are not
transitions. Revision payload hashes, versions, identity and contiguous sequences
are checked when rebuilding history. This is consistency validation, not
cryptographic protection against an attacker who can rewrite the database.

Dashboard/Calendar Day project typed job activity from that session by the saved
event's local date and historical creator/assignee context. They no longer add a
second memory-only job event after a connected save. Cached typed events are
replaced even for an empty scoped result. Activity links route to the current
owning job; an unavailable job is rejected rather than opening caller-provided
activity details. This does not add a historical job-detail viewer. Existing
standalone operational tasks remain a separate persistence gap.

Reuse decision: retain the UI Lab Work revision ledger already committed with
records and drafts, rather than introduce another event write or import 5.7's
Hive job model. The preceding read-only 5.7 job-store assessment applies; no 5.7
code was copied or executed. Native regression covers forced revision-insert
rollback, retry/no-op deduplication, later edits, database reopen with exact
event identities/timestamps, organization/owner filters and corrupt hash
rejection. Current history loading reads the scoped revision set; large-history
paging and production permission revocation remain unverified. Focused
history/Work/plan tests passed (11), followed by 20 Dashboard, Calendar, startup
and saved-note/workday route regressions. Flutter analysis was clean and the
macOS debug build succeeded. The reusable QA domains manifest includes the new
history regression; no physical-device interruption or owner visual acceptance
is claimed.

Dashboard scheduling recovery checkpoint: connected Dashboard/Calendar Day job
rescheduling now opens Work's existing `JobScheduleEditorSheet` through shared
record navigation. The same actor/job draft, original storage revision, raw
hour/minute/period/date and atomic draft-consumption command are used whichever
route opens it. Work's duration preservation and status rules apply consistently:
rescheduling only resets a needs-return-visit status, rather than independently
resetting arrived/completed jobs in Dashboard. Fixture-only operational tasks
still use their previous picker flow and are not covered by this cutover.

Recovered schedule bases now must match the current job ID, kind and creator;
invalid revisions/periods are rejected before editing is enabled. The retained
payload is not overwritten on rejection. Native full-app tests from both
Dashboard routes close/reopen SQLite with a partial time, force failure during
draft consumption, retry and verify the resulting plan/duration and consumed
draft. The existing Work schedule test also checks date choice and overnight end.
A mismatched-job draft regression verifies unchanged payload/revision and a
disabled Save. These tests are included in the shared QA manifest. This reuses
UI Lab's validated Work editor; no 5.7 files were imported, changed or executed.

Calendar Day manual-note cutover: the historical/day route still had a separate
memory-only description dialog despite Dashboard's durable note editor. Both
routes now use `DashboardRecordNavigation.openStoredDayNoteEditor`, capturing
the selected day and permitted employee before opening the existing editor.
The shared note repository/draft transaction is reused; Calendar does not own
another note format or duplicate storage. An unavailable employee grant fails
closed with a message. Fixture-only apps without a note session retain their
existing demo path.

The full-app note recovery regression now runs through both Dashboard and
Calendar Day, using yesterday for the latter. It checks exact multiline text,
selected time/date, raw draft recovery across SQLite close/reopen, forced
atomic-consumption failure, retry, and a second reopen displaying exactly one
confirmed note. These cases and the existing Calendar Day regression passed
(11 tests). Existing read-only 5.7 note assessment above applies; no reference
writes or extraction occurred. Investigation found standalone plan tasks are
currently fixtures, while Add schedule creates a Work job; creating a new task
subsystem requires its own ownership/workflow design.

Combined reusable QA checkpoint: before the Dashboard preference change below,
`build/storage_qa/20260909T122524Z-c5a03522/report.json` recorded PASS for all
three selected groups: core 25 tests/6 files, domains 42/12 and editors 19/14,
86 tests in 32 files total. All selected suites were observed, no tests were
skipped or failed, and the source fingerprint was unchanged during the run.
This is selected host regression evidence, not full-app/device/cloud acceptance.

Dashboard preference checkpoint: action selections now write immediately through
`AppPreferencesController`/`LocalAppPreferencesStore`, using a validated device
preference value. End workday remains required, unknown/duplicate actions are
rejected, and reads restore choices when Dashboard is recreated. Each toggle or
Restore defaults publishes only after the SQLite write; failures retain the
previous active selection and offer Retry. Save/Back still closes the settings
route, but acknowledged changes no longer depend on using that button. These
choices remain in Dashboard's screen-specific settings and do not grant employee
permissions or authorize cloud activity. Existing local preference transaction,
serialization and malformed-metadata preservation are reused.

Fourteen focused preference/Workday regressions passed, including a native full
app toggle/reopen/failure/retry test and preservation of the required End workday
action. Flutter analysis was clean. The new widget regression is included in the
shared QA manifest. This is device presentation state, not a new business ledger.

Estimate detail acknowledgment checkpoint: detail-screen changes now await the
shared Work session with the captured storage revision before adopting the new
record. Missing records are rejected, stale displayed revisions cannot overwrite
newer saved values, and already-committed editor returns are adopted without a
duplicate write/callback. Input is blocked while the detail command is pending.
Fixture-only callbacks remain for apps without a Work session. Existing Work
revision/draft transaction infrastructure is reused; no 5.7 import was needed.
Presentation cards were split into `estimate_detail_record_cards.dart` at their
existing responsibility boundary to keep the screen below the file target.

The native estimate readiness test forces a SQLite failure, verifies unchanged
status/no optimistic callback, makes a concurrent saved edit, rejects the stale
action, then reopens details and succeeds while preserving that edit. Twenty
focused/lifecycle/signature tests passed; one lifecycle test still fails at the
previously documented missing `quick-customers` target after returning to Work.
Flutter analysis was clean. This is not a claim that the entire estimate approval
workflow is complete: signature strokes are currently discarded by the legacy
signature return value, and signature/delivery/company-review subforms still
lack raw-draft recovery. Their confirmation boundaries require the next cutover;
a failed parent save must not be treated as completed customer approval.

Estimate signature cutover: customer name, normalized handwriting, checkbox
state and original Work/document revisions now autosave as an actor/estimate
scoped raw draft. The signature route owns confirmation: it flushes raw input,
then commits the approval with handwriting and consumes the exact draft in the
same Work transaction. A failed or stale commit keeps the signature route/input;
Back retains the draft, explicit discard removes it. Editing the signer name or
handwriting clears consent and requires checking the approval box again. Merely
restoring a draft does not approve anything. The parent adopts the already-saved
record without a duplicate approval write.

`SignatureInk` stores immutable versioned coordinates normalized to the drawing
pad, validates finite bounds and rejects malformed content rather than silently
dropping points. Existing signatures without ink remain readable; no handwriting
is invented for them. New confirmation requires actual multi-point ink. Approval
invalidation retains its original ink, revision and timestamp for history.

Read-only 5.7 assessment inspected `app_signature_models.dart` and
`app_signature_store.dart`: stroke serialization exists, but the encrypted Hive
store is for a reusable owner signature and explicitly excludes customer
signatures. That global store is unsuitable for an estimate-owned customer
approval. UI Lab reuses its existing Work revision/draft transaction instead;
no protected reference code was copied or executed. This does not establish
production signing identity, legal-signature compliance, encryption/key lifecycle
or remote sharing. SQLite at-rest protection remains an unfinished security gate.

Native recovery verifies exact name, retained consent and handwriting across
close/reopen, failure during draft deletion, one successful approval revision,
consumed draft, exact timestamp/ink after a second reopen, and preserved ink on
invalidation. The existing signature-flow and Work repository/session regressions
passed (11). Delivery and company-review reason subforms remain unfinished.

Estimate delivery preparation cutover: the existing form now retains selected
method, each method's separate raw recipient, review checkbox, original estimate
snapshot/storage revision and first confirmation time. Switching method or
editing a recipient clears review; switching back restores that method's input.
Back retains the draft; explicit discard removes it. Loading/recovery failures
do not enable confirmation or overwrite the retained draft. The form commits
prepared-delivery history and consumes the exact raw checkpoint atomically,
then returns the saved Work record for parent adoption. Failed/stale saves keep
the form open.

`confirmedDelivered` is explicitly false. Preparation does not set sentOn,
advance to awaiting customer, authorize cloud upload, generate a PDF, or send an
email/text/device-share/print operation. This preserves the existing prototype's
honest delivery boundary while making its local records durable. Existing UI
Lab Work codecs, draft guard and transaction are reused; no 5.7 extraction or
execution is involved. Actual external delivery remains a separate integration.

The native full-app regression recovers separate email/text values after SQLite
reopen, injects failure during draft consumption, retries to exactly one
preparation, verifies the unchanged customer stage/null sent date, and reopens
the confirmed history with its exact timestamp. That test plus signature recovery
and estimate save/conflict regression passed (three tests). Flutter analysis was
clean. The test is in the reusable editor suite. Company-review reason drafts
remain the next identified estimate input gap.

Company-review reason cutover: Return for changes and Reject estimate now use a
shared `EstimateReviewReasonDialog` rather than popping a transient text string
before saving. Raw multiline reason, decision, actor/estimate scope, original
record/storage revision and first confirmation timestamp are retained. Opening
requires reviewer permission, an editable estimate and a pending review; a
changed displayed estimate is rejected rather than silently rebasing it. Saved
review drafts validate their estimate, creator and decision identity. Return and
Reject have distinct draft identities, so one cannot silently reinterpret the
other's unfinished input.

Confirmation preserves exact reason text (nonempty validation trims only for the
check), records the acting employee ID, and atomically saves the review with
consumption of its exact draft. Failures keep the dialog/input. Back keeps the
draft; explicit discard removes it without changing the estimate. Existing Work
serialization, revision conflict detection and draft transaction are reused;
no 5.7 extraction or execution is needed for this existing UI Lab workflow.
Approval-for-sending has no free-text input and still uses its explicit prompt
plus the previously corrected acknowledged Work save.

Native tests exercise both rejection and return: draft close/reopen, exact
text recovery, failure during draft consumption, pending status preservation,
retry, one decision with actual actor ID, consumed draft, and exact history time
after another reopen. Those cases plus estimate readiness/conflict regression
passed (three tests). Flutter analysis was clean. The new cases are included in
the reusable editor suite. Production role revocation and recovery access to
drafts whose parent workflow has already closed remain separate open gates.

Standalone estimate-items cutover: the detail screen's Edit items path was
opening `EstimateItemsScreen` without the main estimate editor's draft session.
It now uses `StoredEstimateItemsEditor`, which retains the original estimate and
storage revision plus item list and unfinished nested line payload in its own
actor/estimate draft. Existing nested item widgets and draft-status/Back behavior
are reused. Save items flushes this draft and atomically writes the revised
estimate with exact draft consumption; failures keep the item editor open.
The detail parent adopts the committed record, avoiding a second revision with
a different timestamp. Explicit Discard item changes removes this standalone
draft and leaves the confirmed estimate unchanged. Main-editor nested item
editing retains its existing parent-draft behavior through optional callbacks.

A native full-app test enters an empty quantity, leaves both nested routes,
closes/reopens SQLite, resumes the unfinished line, confirms the line, forces
failure during final draft consumption, retries and checks a single document/
storage revision and an empty draft query. Main estimate raw recovery and line
source/private-cost preservation regressions also passed (three tests). Full
Flutter analysis was clean. Existing UI Lab Work/item codecs and transaction
infrastructure were reused; no 5.7 copying or execution was involved. Inventory
editing/port remains deferred. The optional editable document-preview callback
currently has no application callers and was not treated as a connected flow.

Startup failure recovery checkpoint: main now renders `ApplicationStartupScreen`
before initializing platform/database/domain services. It exposes progress and a
single-flight Retry opening action on failure, without showing raw exceptions or
entering an empty demo app as fallback. `openUiLabApplication` retains the prior
startup/seed order and cleans up successfully opened sessions plus the database
when a later domain fails. The same native-notification gateway is reused across
retries. A completed load abandoned before mounting is closed through an explicit
callback. Successfully mounted resources retain their existing process lifetime;
this is not a new shutdown-draft-drain guarantee.

No reset, replacement, quarantine, export, or automatic repair operation was
introduced. A native test creates an isolated application database and raw draft,
makes a customer payload unreadable, verifies startup failure and untouched draft
revision/content, then restores the test payload and opens that same database.
The correction is test-controlled, not app behavior. Startup UI tests cover
320/1400 LP, private exception text exclusion, one retry at a time, successful
transition and abandoned-load cleanup. Four tests passed. Existing local storage
opening/verification and session bootstraps were reused, without 5.7 extraction
or execution. This retry surface does not itself repair corrupt storage or
establish recovery from a backup; those remain distinct recovery capabilities.

Expanded combined verification: `build/storage_qa/20260909T125812Z-220908a2/report.json`
passed all selected suites with unchanged source fingerprint: core 29 tests/8
files, domains 44/13, editors 26/20; 99 tests across 41 files, zero failures or
skips. Android debug build succeeded and produced
`build/app/outputs/flutter-apk/app-debug.apk`. The build warned that `pdfx` uses
Kotlin Gradle Plugin in a way future Flutter versions will reject; current build
succeeded. No device installation or runtime acceptance is claimed. The current
requirement-by-requirement gap audit is in
[SQLite migration verification status](sqlite_migration_verification_status.md).

iOS/schema verification checkpoint: `flutter build ios --debug --no-codesign`
succeeded and produced `build/ios/iphoneos/Runner.app`; no signing, installation
or device runtime test occurred. The existing unsupported-schema test previously
only asserted an exception. It now seeds a confirmed record and raw draft,
sets user_version to 999, takes a read-only SQLite snapshot, attempts opening
through Drift, closes the refused connection, and compares schema, user_version,
all record/history/command/outbox/draft/metadata rows exactly. Native interruption,
capacity and strengthened refusal tests passed (three). Safe refusal does not
establish a future upgrade, downgrade or backup restore capability.

Implemented so far:

- `local_database.dart` / `local_database.drift`: one app-owned SQLite connection,
  WAL, FULL synchronization, enforced foreign keys, version-one schema and
  refusal of unsupported upgrades. Generated Drift mappings are generator-owned,
  exempt from the authored-file line target; authored SQL and Dart are checked.
- `local_record_store.dart`: scoped record reads, expected revisions, atomic
  multi-record commands, retained per-record revision payloads, replay hashes and
  a local change journal. Journal state `local` does not authorize upload and is
  not a functioning cloud-sync adapter or remote acknowledgment.
- `local_draft_store.dart`: scoped, versioned unconfirmed payloads and conditional
  consumption that preserves a newer draft. Editor integration is NOT complete.
- `draft_autosave_session.dart`: starts serialized writes on input changes,
  preserves raw partial values, exposes local save/failure state, supports retry,
  retains drafts when closing, and discards only explicitly. Tested independently;
  the invoice editor now uses it for its main fields, the working item list,
  and unfinished line-item forms. Nested editors update the same scoped invoice
  checkpoint, including raw quantities/prices and source provenance. Customer,
  company, payment, main estimate fields and nested estimate labor/material
  entries are also connected. Photo-list metadata and unfinished notes now share
  that draft; newly imported estimate images now use verified app-owned copies.
  Other application editors remain unfinished. New-invoice entry offers an owner-scoped recovery chooser; editing
  a saved invoice resumes its specific recovery draft. Native Back retains and
  flushes input, explicit discard removes only that recovery draft, and save
  failure keeps the editor open. A successful invoice confirmation consumes the
  exact recovery revision in the same transaction as the Work record write.
  The original editor storage revision is checked against newer record edits.
- `work/` now contains explicit Work, line-item, signature, date, delivery,
  review-history, photo-link and contact codecs plus `SqliteWorkRepository`.
  Its storage revision is separate from the customer document revision. Scoped
  reads, stale storage-revision rejection and disk reopen have focused tests.
  Normal startup now opens `WorkPersistenceSession` and connects it to the
  shared operations store; Work and payment records reopen from SQLite. Invoice
  issuing and payment actions await a single Work/ledger transaction. Broader
  editor save-result handling and raw draft integration remain incomplete.
  Current double-based Work
  values are serialized as decimal text without an additional rounding step;
  exact financial arithmetic/currency ownership still require domain work.
- Existing expense, recurring-expense, receipt-draft and notification mutation
  rules now live in `local_*_repository.dart`; old `file_*` entry points are
  compatibility aliases for legacy tests/readers. The SQLite adapter stores
  changed records individually, retaining existing domain codecs/validation.
- `local_persistence.dart` and normal `main.dart`: shared startup and a one-time,
  transactional demo seed. Original legacy JSON files are not imported or deleted.
- Reusable disk-backed harness under `test/support/storage/`, including a child
  process that is forcibly terminated inside an uncommitted transaction.

Expense-entry checkpoint: manual entry from Expenses and its day route now passes
an awaited confirmation callback to `ExpenseEditorScreen`. The editor stays open
with entered values on failure and prevents competing input/navigation during
confirmation. Successful confirmation returns the persisted record; the parent no
longer closes/reopens the form through a retry loop. New-entry identity is stable
across retries. Existing-expense output now includes the explicitly edited receipt
date, which the previous copy omitted.
Five focused confirmation/input-validation tests passed, plus thirty expense
screen/controller/bridge/SQLite adapter regressions. Analysis and the macOS debug
build passed. The confirmation test verifies the widget callback contract; the
separate adapter tests establish SQLite persistence. This initial checkpoint
alone did not establish interruption recovery; the manual draft integration
below adds that coverage. Nested receipt-line recovery and receipt/correction
confirmation integration remain unfinished.

Shared draft connection checkpoint: normal startup now supplies its existing
`LocalDraftStore` through `UiLabApp` and `LocalDraftScope`, above the navigator.
Feature routes can use this same database without a dependency on the Work
session. The scope supplies no identity or authorization: domain sessions remain
responsible for those checks. A disk-backed widget regression, with no Work
session injected, verifies access from a pushed route, preservation of whitespace
and an incomplete decimal after database reopen, and actor-scoped recovery.
This scope is storage wiring; the manual expense form binding is described below.

Expense atomic-confirmation checkpoint: the SQLite domain adapter now exposes
`persistWithDraft`, which consumes an exact actor-owned draft revision in the
same transaction as record changes, retained revisions, command identity and
outbox entries. Adapter, repository, bridge and controller caches advance only
after successful confirmation. Expense create/update commands carry the optional
checkpoint through the authorized service; legacy storage rejects this request
before writing. Recovered expense edits must supply their original record
revision, and a stale or missing base is rejected without consuming the draft.
Disk-backed tests inject a draft-deletion failure after record writes, verify
rollback and successful retry, reject newer/other-actor drafts, and exercise
controller projection preservation and stale edit rejection across reopen.
Manual expense editor checkpoint: new manual entries with the authorized
Expense controller and shared draft store now persist raw text, date, category,
receipt-detail choice, completed line-item values, employee and job context.
Opening a new entry offers the actor's unfinished entries or a separate new
entry. Back retains input; explicit discard consumes only that draft. Confirmation
flushes raw input and uses the authorized atomic create command before leaving.
The editor stays open after failure. Recovery does not change the global employee
view or silently replace the retained expense identity, date or job context.
A disk-backed widget test leaves the actual form with whitespace and `12.`, closes
and reopens the database, resumes the form, injects confirmation failure, then
retries and verifies the committed projection and consumed draft. The nested item checkpoint below extends this to an interrupted manual-entry
line-item dialog. Existing-expense edits are covered by the correction checkpoint below. Receipt
submission, scheduled expense forms and abrupt device power loss remain
unfinished integration and verification work.

Nested manual expense item checkpoint: the existing item editor accepts the
parent draft session and preserves raw description, part number, quantity,
package quantity, price, category, unit, stable item identity and job context.
Back and Keep unfinished flush the parent draft; completion returns the reviewed
item to the parent's working list. An unfinished item blocks expense confirmation
until it is completed or explicitly discarded. Its recovery controls stay
available even if the receipt-detail choice changes. A disk-backed widget test
leaves both routes with a blank quantity, reopens the database, restores the item,
completes it and confirms the resulting expense. Receipt intake still requires its own parent draft integration; exposing
optional callbacks on the shared item editor does not establish its durability.

Existing expense correction checkpoint: the detail screen's Edit route now
uses an actor-specific draft with a complete base-record codec and the original
record revision. It reads the current authorized record before opening, restores
older retained input without advancing its base revision, and commits through the
controller's revision-checked atomic update. For receipt-backed records, an inline
required correction-reason field is included in raw autosave. The successful
command retains the receipt link and records the correction reason in audit
history. The detail route does not replay the committed update. A disk-backed
widget test opens the actual detail route, retains raw values and reason across
database reopen, injects confirmation failure, retries and verifies exactly one
new revision and one prior version. The direct line-edit shortcut from expense detail now opens its requested item
inside this same parent editor and draft. Existing pending item input takes
precedence over a new shortcut request; a missing requested item reports that it
is unavailable rather than creating a replacement. Completing the item returns
to expense review and its correction reason before confirmation. A disk-backed
shortcut regression leaves a blank quantity, closes both routes, reopens the
database, resumes through the same item, then verifies one audited revision and
preserved item identity, part number and job link.

Caller review also found and removed Dashboard's duplicate create after the
manual expense editor returned a committed record. Dashboard now supplies the
same awaited confirmation callback as Expenses and its day route. Receipt intake
submission and its parent draft use the receipt checkpoints below.

Receipt confirmation boundary checkpoint: intake now supplies an awaited
confirmation callback to its review editor. Submission failure keeps entered
values in the editor; successful submission returns through intake once. The
coordinator rejects mismatched organization or actor sessions before either
repository mutation. Tests cover both mismatches and the actual intake route
with retained image bytes, an injected receipt-close failure, preserved input,
retry and a single committed Expense. SQLite uses the atomic command described
below; the legacy coordinator retains its two-save protocol. Receipt count checkpoint: confirmed expenses and their retained revision
snapshots now store an optional receipt image count. Zero, multiple images and
legacy unknown values remain distinct in storage; unknown data is labeled as
unavailable instead of inferred as one image. UI corrections preserve the stored
count and cannot change it outside the evidence workflow. A receipt link still
requires a correction reason even when its count is zero or unknown. The
submission retry match includes image count. Disk-backed tests cover counts zero,
two and unknown through reopen and correction history; the intake failure/retry
test imports two evidence files and verifies a count of two. A coordinator test
rejects retry after the draft's image count changes. Counts describe retained
metadata, not proof of readable bytes; submission evidence checks are described below.

Prepared domain commit checkpoint: SQLite snapshot adapters now support
preparing immutable domain changes without SQL writes or cache publication.
`commitPreparedDomainChanges` owns one transaction for all prepared changes and
an optional exact draft checkpoint, then publishes adapter caches after commit.
It rejects mixed databases, organizations, duplicate domains and stale prepared
cache bases. Commit/publication is serialized per database connection. Tests
inject failure in the second domain, check that records/history/outbox/command
rows and both caches remain unchanged, verify draft preservation, retry and
reopen, and reject stale no-op plans. Existing single-domain persistence uses
the same path. Receipt submission uses this primitive through the business-command integration
and repository/controller publication described below. Callers must not wrap group commit in an outer
transaction and assume its cache publication waits for that outer commit.

Atomic receipt command checkpoint: `AtomicReceiptSubmission` reuses existing
authorized Expense and Receipt controllers/services against isolated repository
buffers held under the live repositories' write queues (Expense before Receipt).
It checks the reviewed receipt revision, prepares both domain changes and
commits them with an optional exact recovery checkpoint, then refreshes both
live repository caches from committed storage. Staging explicitly rejects
receipt creation or evidence updates, so no file mutations occur while preparing
submission. Disk-backed tests inject receipt-close SQL failure after Expense
preparation and verify no live Expense, no closed receipt and retained raw input;
retry commits both across reopen. Denied submission, stale review and attempted
staged evidence mutation are rejected. Normal SQLite app startup now provides `ReceiptSubmissionSession` above the
navigator. Intake captures the reviewed receipt revision and submits through this
session; controllers reload only after the atomic command succeeds. A receipt-
closure failure test runs through the actual intake UI and verifies no Expense
publication, preserved entered values and successful retry. Already-submitted
retry returns the matching authorized Expense only when the closed receipt
revision/link and confirmed values match, submission permission remains valid,
and no separate recovery draft would be discarded. A database test verifies
retry after reopen adds no command. Legacy/non-SQLite fixtures retain the old
coordinator; they are not evidence of atomic SQLite behavior. Receipt review now restores actor-owned raw input from `expenses/receipt-review`,
including its original receipt identity/revision, image count and unfinished
line-item workspace. Reopening unchanged intake evidence no longer increments
the receipt revision. Confirmation verifies that the exact retained checkpoint
belongs to the reviewed receipt revision before consuming it in the combined
transaction. A changed receipt preserves input and rejects stale confirmation;
an explicit changed-evidence recovery/merge workflow remains unfinished.
The intake widget regression closes/reopens SQLite, recovers raw fields, injects
receipt-close failure, and retries successfully. A separate command regression
rejects an unrelated raw review without changing either record or consuming input.
Before preparing a new submission, the staged receipt repository verifies each
active evidence file remains in its expected app-owned location and matches its
recorded byte length and SHA-256 hash. Missing files, truncation and same-length
corruption reject confirmation while preserving records and raw review input;
disk-backed tests repeat rejection after reopening SQLite and verify retry after
restoring the original bytes. Verification does not make filesystem reads and SQL
one atomic transaction, prevent external changes after hashing, or establish
physical-device power-loss durability. Those interruption checks remain outstanding.

Receipt retention also explicitly flushes the verified temporary image/PDF file
before renaming it and publishing its metadata. This establishes an OS flush
request, not proof of directory-entry durability under sudden physical power loss.

Planned-expense confirmation checkpoint: create and future-template edit routes
now pass an awaited repository confirmation callback into the editor. It blocks
Back and duplicate interaction while saving, preserves fields on failure, and
returns only the confirmed record. New records keep one secure identity across
retries; callers no longer repeat the write after the editor returns. The widget
regression verifies pending-save navigation protection, failed-input retention,
and retry identity; recurring workflow/controller/status regressions also pass.
The authorized recurring repository now supports exact-draft consumption in the
same SQLite transaction as template creation/initial occurrence or template/open
occurrence editing. Unsupported storage rejects draft confirmation. Controller
updates with a draft require its original template revision and reject stale bases.
Disk-backed regressions inject draft-deletion failure and verify no template,
occurrence or command publication, successful retry/reopen, preservation of a newer
raw draft, and stale-edit rejection. Completion/advancement logic was moved into
`local_recurring_expense_completion.dart` at a cohesive responsibility boundary;
existing recurring lifecycle regressions pass.
Planned-expense editors now save actor-owned raw input, including partial amount,
whitespace, category, schedule/date, reminder selections, receipt requirement,
stable record identity and the original template revision for edits. New entry
offers retained drafts or a separate new draft. Back flushes/retains input; explicit
discard deletes only the draft. Confirmation consumes the exact checkpoint in the
repository transaction. Saved due dates are preserved through reopen and unrelated
edits; changing the monthly schedule computes/clamps the selected day at the time
of that change. Date selection can reopen a past retained date. The native-SQLite
widget regression verifies Back, database reopen, raw amount/reminder recovery,
failed confirmation, retry and removal of only confirmed recovery input. Existing-edit recovery now has a native-SQLite widget test: retain raw input,
change the confirmed record, reopen the database, restore the old draft, reject
stale confirmation, explicitly discard only that draft, then edit the current
record and confirm exactly one additional revision. The unchanged 2030 due date
is preserved. Opening/saving a stale draft explains the conflict while retaining
input; an interactive comparison/merge workflow is not yet provided.
Individual occurrence edits now accept an exact draft checkpoint and both original
revisions (payment and parent plan). The authorized repository commits occurrence,
parent next-due-date/revision and draft consumption together. Disk-backed tests
verify rollback on draft-deletion failure, retry/reopen, preservation of the
parent's usual amount, rejection of a changed parent, and rejection of missing
base revisions. The occurrence editor now saves raw amount/date and both original revisions in
an actor-owned draft, retains it on Back, restores it when reopened, and offers
explicit discard. Its confirmation awaits the atomic command; failures keep the
form open and stale records show a conflict message. The detail-screen caller no
longer repeats the completed write. A native-SQLite widget test verifies partial
amount recovery after Back/database reopen, injected draft-delete failure,
unchanged confirmed amounts, retry and exact draft consumption. Recovery after
an occurrence has already been paid/skipped still needs a closed-record recovery
route, and paid-payment entry drafts remain unfinished. No physical-device power-loss claim
follows from these widget tests.

Recurring payment preflight checkpoint: the legacy payment coordinator now checks
matching organization/actor sessions, payment and expense-create permissions,
occurrence-to-template identity, finite positive amount and current payee/title/
category before creating an Expense. Tests prove mismatched company, actor and
denied payment permission produce no Expense and leave the occurrence open.
The interrupted-second-write retry test still passes. Legacy/non-SQLite fixtures retain this two-step coordinator; they are not evidence
of atomic payment recording. `AtomicRecurringExpensePayment` now executes those authorized
business commands against isolated Expense/Recurring buffers under ordered write
queues, checks both original revisions and optional draft identity/base, and
commits expense, paid occurrence, next occurrence, parent plan and exact draft
consumption together. Repository caches publish only after commit. Tests inject
failure in the recurring aggregate and draft deletion, verify no published Expense
or advancement, and verify successful retry across reopen. An already-committed payment can now return its matching authorized Expense after
reopen when both revisions are exactly the expected post-commit revisions, links,
amount/date/payee/title/category match, current permissions allow the operation,
and no separate retained input would be discarded. Tests prove exact retry adds
no command or occurrence, different amount rejects, and a newly written raw draft
is preserved. Later unrelated parent changes conservatively reject this retry;
no automatic merge/rebase is implied. Normal SQLite startup now supplies `RecurringPaymentSession` above navigation.
Mark paid captures both revisions before amount entry and uses the atomic command;
controllers refresh after commit. Session pending state disables conflicting plan
controls and rejects duplicate submissions. A full `UiLabApp` widget test injects
recurring-update failure, verifies no Expense/advancement, then retries and observes
one Expense and one advancement. It passes at 1400 logical pixels. The initial
1000-LP run passed its payment assertions but exposed a 4-LP shared
`operational_header.dart:146` overflow; that visual issue remains unresolved and
these checks are not visual acceptance. Variable payment entry now uses `scheduled_payment_draft_dialog.dart`: it retains
actor-owned raw amount, original payment date and both base revisions, restores
them on reopen, flushes on Keep unfinished/Back, and offers explicit discard.
Record payment waits for the atomic command and keeps input visible on failure;
confirmation consumes its exact draft. A full-app native-SQLite test verifies
partial amount after database reopen, injected failure, retry and consumed input.
Fixed-amount Mark paid remains a direct atomic action. Legacy fixtures retain the
older amount dialog. Planned-expense actions were separated into
`scheduled_expense_actions.dart`; focused regressions pass after the split.
Closed-record draft recovery, stale-draft comparison/merge and physical-device
interruption validation remain outstanding.

Device preference checkpoint: startup opens `LocalAppPreferencesStore` before
building the app and injects it into `AppPreferencesController`. Appearance,
language and measurement values are device-local SQLite metadata, separate from
company records and outbox/cloud consent. Each change transaction merges one
validated field with current saved preferences, publishes only after commit, and
reports save failure/retry while keeping the previous active value. Appearance
surfaces this state in global settings. Existing language/measurement UI availability
is unchanged. Disk-backed tests cover reopen, failure/retry, independent writers
preserving fields, and no business-record/outbox writes; localization regressions
pass. Unknown/malformed preference values now allow startup with default presentation
and a visible notice in Appearance. Opening does not mutate the unreadable row.
An explicit preference change archives its exact original bytes under a unique
recovery metadata key before writing the new value, in one transaction. Tests
cover invalid JSON, wrong payload/value types and unsupported values; injected
update failure leaves the sole original row intact, and retry preserves an archive.
Storage I/O errors still propagate rather than masquerading as malformed data.
This recovery is limited to device presentation metadata, not business records. Physical-device restart/settings acceptance is not yet established.

Workday reuse assessment: current Dashboard `_workday`, pause state and
`OperationalScopeController` confirmed odometers are memory-only. Start/End also
write presentation entries separately, so persisting only one of these would not
satisfy the workflow. Read-only inspection of 5.7
`lib/screens/dashboard/data/active_workday_store.dart` found Hive session storage,
serialized write tails, storage-space checks and context/event identity guards.
Its Hive active-session pointer and work-profile/context-segment model are not a
drop-in SQLite/employee-scoped repository; no 5.7 code or tests were run or changed.
The existing start-review/idempotency/physical-odometer rules remain useful target
behavior. The older discard-on-Back blueprint wording was superseded by the
owner's automatic-draft instruction and corrected in Operations.
`StoredWorkdayRecord` establishes confirmed identity, UTC instants, exact odometer
tenths and validated pause/resume/end transitions. Tests serialize/reopen pause
state, freeze ended elapsed time, exclude final paused intervals and reject
out-of-order/decreasing/invalid records.
`SqliteWorkdayRepository` now commits the workday, employee active-session pointer
and confirmed vehicle odometer together. Changes require scoped employee/vehicle
access and expected revisions. Matching actor-owned start/end drafts are consumed
inside that transaction; unrelated identities or changed drafts reject the whole
command. Native SQLite tests inject odometer-write and draft-delete failures,
verify rollback and retry, reopen paused sessions, and reject cross-organization,
employee and vehicle access. Eleven focused model/repository tests pass.
Command-result records now commit in the same transaction and bind the original
values, expected revisions, actor, permission revision and optional draft
checkpoint. Exact Start/End retries after reopen return their original result
without further writes. Changed requests and newly retained drafts reject;
replaying Start after End cannot reactivate the stored session. Callers must
retain the original request timestamp and reload current state before publishing
it: a retry acknowledgment represents the original action, not the latest state.
`WorkdayPersistenceSession` now loads confirmed workdays and vehicle odometers
in one SQLite read transaction, serializes actions, exposes saving/error state,
and reloads current records after every successful command. A failed post-commit
refresh reports the save as committed and hides unavailable projections until
reload succeeds. Native tests cover failed writes, reopen, late retry after End
and post-commit refresh failure; fourteen model/repository/session tests pass.
The main entrypoint opens the session and UiLabApp provides it above routes.
Bootstrap uses explicit UI Lab demo authority and creates no workdays or assumed
physical readings. This startup connection does not yet connect Dashboard actions
or replace the operational controller's demo odometer values.
`PrototypeOperationsStore` now accepts an optional workday session and derives
started/ended entries from confirmed records by stable event ID, selected employee
and local event date. It subscribes to session updates and refuses to retain
workday projection copies through dashboard writes. Native tests confirm an
overnight workday projects each event on its own date, survives database reopen,
filters another employee and cannot duplicate entries when a caller writes back
an assembled day. Existing expense and Dashboard fixture regressions pass.
The normal app operations store now receives this session. Dashboard Start,
Pause/Resume and End use SQLite commands; started/ended entries come from the
confirmed projection rather than separate dashboard writes. The shared expense projection was moved intact to a cohesive part
to keep the operations store under the source-size target.
This is a storage/session/projection checkpoint, not a connected Dashboard
workflow. Production permission sourcing, shared operational-controller
broader odometer-edit command integration and failure recovery presentation
remain outstanding. GPS/device integration is not activated by this work.

Start Workday now opens an actor-owned `workday/start` raw draft, preserves the
selected employee/vehicle, exact odometer text, assistance choice, original
odometer revisions and confirmation timestamp, and provides local save status,
retry, Back retention and explicit discard. Editing waits until recovery opens.
With the normal SQLite session/draft scopes, confirmation awaits the start
transaction and consumes its exact checkpoint; fixture-only screens retain their
existing in-memory path. Vehicle defaults use the saved odometer when available.
The assistance choice is stored as `gpsAssistanceRequested`; it is not evidence
of device permission or running GPS. Existing records without the field decode
as false. Tests reopen partial `1234.` input, inject a start-record write failure,
retain input, then retry and verify consumption. Twenty-two focused model,
repository, session and widget tests pass. Dashboard now maps its active display from the shared committed session and uses
that session for Pause/Resume and End. Action commands capture workday identity
and expected revision from the opened context. The shared operational header reads
SQLite odometers when connected; its former synchronous memory confirmation API
rejects writes in that mode, so other odometer edit callers still need audited
commands. End awaits confirmation, blocks navigation while saving, and retains
its text when a write fails. A native full-app test starts, pauses, reopens into
Paused, injects an End write failure, retries, and reopens into ended state with
the correct entry/odometer.
End Workday now has an actor/workday-scoped `workday/end` draft with exact raw
odometer text, original workday/odometer revisions and confirmation timestamp.
Keep workday open and Back flush and retain input; explicit discard removes only
that draft. The dialog waits for recovery before editing, blocks departure during
confirmation, and consumes the exact checkpoint in the closing transaction.
The connected app regression now leaves partial `1240.` input, closes/reopens the
database, restores that input and injects a draft-delete failure during End.
Workday closure rolls back; retry succeeds and leaves no raw draft. The app-level workday recovery notice now exposes a local Reload action when
confirmed state cannot be refreshed. It does not replay commands; repeated reload
failure remains recoverable. The operational header distinguishes Not recorded
(no odometer revision), Unavailable (unreadable/out-of-scope snapshot), and a
confirmed numeric reading, including a legitimate zero. A native app test forces
a successful Start followed by read failure, verifies the saved acknowledgment,
tries a failed reload, then restores reads and confirms the command count stays
one. Physical power-loss, stale-draft reconciliation and closed-workday draft
recovery remain unverified or unfinished. This test does not imply cloud backup or GPS activity.

Day-note reuse assessment: UI Lab's Add day record currently collects a title
and time through separate dialogs, then writes only `_dashboardDays` memory.
Read-only inspection of 5.7 `active_workday_store.dart` found note events attached
to an active session/context, physical odometer and current event timestamp;
`toMap` passes note text through a 240-character limit. That is not a direct fit
for UI Lab's standalone or historical day-note input. No reference code or test
was executed or changed. The shared SQLite record/draft transaction mechanism is
reused instead of importing that session-bound Hive representation.
`StoredDayNote` retains stable identity, organization/employee scope, full text,
explicit calendar-date string and clock minutes, plus UTC creation evidence.
`SqliteDayNoteRepository` validates identity/authority and commits a new note with
its matching actor-owned raw draft in one transaction. Confirmation binds the
note ID, employee, date, time and text; command fingerprints reject changed
retries, while exact retries after reopen do not duplicate the record. A newly
retained draft blocks replay consumption. Three native tests cover rollback on
draft deletion, exact reopen/long-text retention, scoped access, mismatched input
and invalid dates/times. `DayNotePersistenceSession` now serializes creates and publishes immutable notes
only after SQLite commits. Startup opens it with explicit demo authority;
UiLabApp supplies it to the shared operations store. Dashboard and Calendar Day
project saved notes by stable source ID, selected date and employee. Their
assembled-day writes cannot retain a confirmed note copy or expose one in another
employee context. Native tests inject a note-write failure, verify no premature
projection, retry, re-feed a projected day, and reopen the database with exactly
one correctly dated note. The normal Dashboard Add day record action now opens a bound employee/date
editor using this session. Description and chosen clock time share one raw draft,
with local status, Back retention, explicit discard and exact checkpoint
confirmation. The existing fixture-only app path remains for isolated UI tests.
A full-app native regression retains multiline whitespace and a chosen time,
leaves/reopens the database, injects a draft-delete failure, retries, and reopens
to exactly one confirmed Dashboard entry with no remaining draft. The native
picker result boundary is exercised; interruption during the platform picker's
unconfirmed internal text entry is not proven. Dashboard body composition and
manual-entry actions were moved intact into cohesive parts to stay within the
source-size target. Unlinked fixture notes remain distinguishable from confirmed
projections; general stale-draft discovery and physical-device interruption
coverage remain incomplete.
Saved day-note detail navigation now resolves the source ID through a scoped
SQLite read and builds the existing detail presentation from that record's text,
clock time and calendar date. Caller-supplied projection fields cannot substitute
for stored values. Missing/inaccessible records display an unavailable state;
read errors expose retry, and note IDs cannot fall through to the Work-domain
lookup. Native route tests verify conflicting caller text/date are ignored and
an out-of-scope employee cannot see either the stored text or the supplied
projection. This is the saved-note route boundary, not a claim that every legacy
Dashboard entry or production permission-refresh path is already secured.
Saved workday detail routes now resolve the exact start/end event from scoped
SQLite records as well. Employee and vehicle filters both apply; an end event
requires an actual retained ending instant, and supplied titles, dates or
odometers cannot replace source values. Notes and workdays reuse the same
loading/unavailable/retry presentation through owning read adapters. Seven native
route/projection regressions cover authorized source resolution, employee and
vehicle denial, a missing ending event, and existing note access behavior.
The shared loader is keyed by session and source identity so switching resources
replaces the prior read state. Production permission-revision invalidation remains
a separate unfinished integration requirement. Demo authority is not production authentication.

Reusable storage QA runner checkpoint: read-only inspection of 5.7's
`tool/receipt_qa_runner.dart` found fixture-pack selection, JSON summaries and
explicit blocker/empty-selection failure. Its parser-bound scoring model is not
a native SQLite/editor harness, and none of its results were adopted as proof.
UI Lab now has `tooling/storage_qa/run_storage_qa.py`, an explicit versioned
`suites.json`, usage/sharing instructions and protocol-evidence unit checks.
The runner uses one Flutter test worker, records platform/Flutter/Git/dirty-state
and source digests, retains machine logs, and fails incomplete, empty, skipped,
changed-source or unsuccessful runs. It creates only local ignored report files.
On macOS, core passed 25 tests across six files; domains passed 40 across ten;
editors passed ten across ten. Both actual reports show unchanged source,
complete selected-suite coverage and no skips. The intentional one-second
runner timeout correctly returned CLI exit 1 and report failure even though the
terminated Flutter process itself returned 0; process inspection found no
remaining Flutter test process. This validates a false-green guard, not a
successful database regression run. Unit checks separately reject incomplete,
skipped, missing-suite and unmatched test completion signals.
The manifest is a selected regression set, not all application tests. Portability
is designed for Python/Flutter hosts but Windows execution, device interruptions,
cloud backup/sync and owner visual acceptance remain independent unverified
gates. Sharing requires the exact checkout/patch, lockfile, selected tests,
helpers, runner and report directory; no external upload is performed.

Current architectural limits requiring further work before task completion:

- Dashboard operational-state persistence and remaining automatic editor
  draft save/resume/discard wiring remain incomplete. Customer/company confirmed
  records are now connected to SQLite, including company-profile raw input.
  Payment and main estimate raw input are connected; existing estimate image-path migration,
  remaining editors and job-detail mutation forms, a shared draft directory and changed-record
  recovery routes remain unfinished. Work record and ledger
  persistence are connected, but several callers still ignore asynchronous
  save results. Estimate-to-job creation now uses a grouped command, while other
  related workflow transitions still require review.
  Existing memory-only UI flows must not be advertised as durable.
- The transitional adapter retains domain aggregates in memory; it is scoped to
  one application bootstrap and rejects stale writes. Query-driven refresh,
  multi-device invalidation, typed domain query indexes and stronger SQL-level
  domain relationship constraints remain to establish. Versioned JSON payloads
  preserve current domain fields; they are not an app-wide snapshot blob.
- Receipt-confirmation and recurring-payment coordinators still use their
  existing deterministic, recoverable two-step commands. Their single-transaction
  application command boundary remains to be implemented and verified.
- The app still uses demo identities/development permission policies. Existing
  authorization tests do not establish production identity or cloud security.
  Encryption/key lifecycle, recovery UX, attachment crash durability, backup and
  restore verification, schema-upgrade fixtures and platform validation remain.
- No Firebase SDK initialization, backend connection, uploads, rules deployment
  or billing change was performed. The reported six analyzer errors came from
  vendored Firebase CLI Dart templates; excluding `**/node_modules/**` resolved
  them without connecting Firebase. Cloud access and abuse/cost protections must
  be verified before any cloud adapter is enabled.

Evidence so far: SQLite reopen/exact values, duplicate commands, stale revisions,
scoped reads, transaction rollback, draft restart, corrupt-file refusal, abrupt
process termination, SQLite capacity exhaustion, newer-schema refusal, domain
fixture reconciliation and last-known-good failure behavior pass focused tests.
These tests do not prove device power-loss behavior, every UI workflow, cloud
operation, encryption, owner visual acceptance or release readiness. The full
regression run also exposed existing UI expectation failures. Its missing existing
Dashboard summary-strip consumer has now been registered without UI edits.
Generated Drift code is excluded explicitly from the authored-size guard; the
recurring repository was split at its persistence responsibility boundary and
its focused regressions pass. Existing Invoice workspace size and UI expectation
failures remain separate from storage changes and are not silently waived.

The Work startup test independently verifies store edits and invoice payment
survive closing/reopening the database without fixture reseeding. Work command
tests cover atomic ledger rollback, stale queued revisions and invoice/payment
capability checks. A disk-backed invoice action widget test verifies that a
successful commit returns from the actions route, while an injected ledger write
failure keeps the route open, displays failure and preserves the draft status.
The combined focused storage/Work/payment run passed 33 tests; `flutter analyze`
reported no issues. The macOS build passed again after Work startup integration.

Invoice recovery verification: 14 focused draft/session/widget tests passed,
including raw partial amounts across native Back and database reopen, explicit
discard, failed-confirmation recovery, successful retry, preservation of record
metadata outside the invoice form, and stale-editor protection. The broader
storage/Work/payment/invoice regression run passed 41 tests with the previously
observed Invoice date-heading expectation failure still present. Analysis is
clean and the macOS debug build passed after the editor integration. These are
widget/database/build results, not physical-phone interruption testing or owner
visual acceptance. Subsequent estimate/job editor integrations are described
below. Remaining editor flows still need integration, along with recovery routes
for drafts whose owning records no longer appear in normal action pickers.

Nested invoice item checkpoint: an unfinished line item survives native Back,
closing/reopening the SQLite database, choosing its invoice and reopening the
item editor. Its stable line identity, original item, source Expense/receipt/
stock identities and private cost remain in recovery input. `Continue unfinished
item` restores it; competing item actions and invoice confirmation are blocked
until the pending input is reviewed or explicitly discarded. `Save items`
returns the complete working list to the invoice recovery draft without issuing
an invoice or changing stock. Invoice confirmation was split into its own
cohesive part file; authored files remain within the 500-line target.
Twelve focused nested/editor/material tests passed, plus a provenance recovery
case verifying stable IDs, exact source links and retained hidden cost. A prior
material-source test missed its off-screen target; it now scrolls to the row and
exercises the unchanged safeguard against fabricating unreviewed material lines.
Analysis is clean and the macOS debug build passed. The known Invoice date-heading
expectation failure remains; no visual acceptance or physical-device power-loss
claim follows from these results.

Customer/company checkpoint: `DirectoryPersistenceSession` now owns scoped
customer/company reads and serialized, revision-checked writes. Startup seeds its
disposable fixtures once; the shared operations store reads its committed cache.
Omitting customers from a compatibility list is not deletion. Customer removal/
merge and historical Work-to-customer foreign keys remain separate unfinished
domain work; current Work models still carry customer names.
The customer editor now retains raw contact/location input, resumes owned new or
existing drafts, keeps input on Back, and consumes the exact recovery revision
atomically with confirmation. Directory-backed callers use that committed result
instead of replaying a potentially stale full directory list. Editor startup uses
the current saved customer; restoring older unfinished input keeps its original
revision so newer saved changes win through an explicit conflict, not overwrite.
Company-profile confirmation awaits SQLite and retains the form on failure; raw
company-profile input is now covered by the checkpoint below. Its editor was split
at the existing screen boundary to keep authored files within the size target.
Invoice edit draft keys now include the actor, with owner-scoped fallback for
previous keys, so two authorized people do not contend for one private draft.

Twelve focused directory/customer/invoice/draft tests passed, covering retained
locations/defaults across reopen, permission denial, organization isolation,
stale writes, raw customer recovery, failed confirmation and retry. Analysis is
clean and the macOS debug build passed. The broader UI regression run passed
eight cases with the previously observed employee-permission large-text layout
failure remaining. These results do not establish production authentication,
cloud protection, physical-device interruption behavior or visual acceptance.

Company/payment recovery checkpoint: company-profile raw fields and the existing
logo-label fixture now use an actor-scoped recovery draft. Back retains input;
confirmation commits profile changes and consumes the exact recovery revision
together. Hidden profile fields, such as currency, remain in the base snapshot.
This does not implement actual logo image capture or attachment-byte durability.
Payment amount/method/date/note input also resumes by invoice and actor, retaining
a stable payment identity. Unfinished input never posts revenue or changes a
balance. Confirmation atomically commits the invoice storage revision, payment
entry and recovery-draft consumption; failure retains all previous confirmed
values and the input. Independent sessions posting partial payments now contend
on the invoice revision, closing the stale-balance gap that previously allowed
partial ledger-only writes without a shared invoice comparison.
The existing exact decimal money parser is reused for payment input and now
rejects signed-64-bit overflow through BigInt range checks. It does not silently
round extra decimal places or accept non-finite values. This improves entered
payment amounts; existing double-based Work calculations remain an unresolved
domain limitation, not a solved app-wide accounting model.

Sixteen focused profile/customer/directory/payment/session tests passed. Tests
include native Back/database reopen, failed-save retention and retry, unchanged
company currency, stable payment identity, atomic ledger failure, independent
connection stale-payment rejection, and exact decimal/integer-boundary parsing.
Analysis is clean and the macOS debug build passed. The broader payment/invoice/
legacy-expense run passed 32 cases with the known Invoice date-heading failure
remaining. Physical-device interruption, production identity/cloud controls,
global recovery navigation and remaining forms are still unverified/incomplete.

Estimate editor checkpoint: main raw fields, dates, selected customer, pricing,
template and returned item/photo metadata now use a scoped SQLite recovery draft.
New-estimate entry offers owned unfinished drafts; Back flushes and retains input.
Confirmation checks the original SQL revision and consumes the exact draft in the
same transaction as the estimate revision. Customer-visible changes invalidate
the previous approval only after a successful confirmation. Revision rebuilding
now preserves unrelated location, operational dates/notes and linked expenses.
Nested estimate labor/material routes now retain their working lists and raw
unfinished line items in category-specific fields of that same draft. Back keeps
input, reopening offers Continue unfinished item, and explicit discard restores
the category's original items. Parent confirmation is blocked while a category
has unreviewed input. Existing labor/material grouping is preserved; supporting
widgets were split cohesively into `estimate_item_sections.dart`.
Photo-list metadata and raw unfinished notes now use the same parent draft.
Returning from the note dialog retains unconfirmed text; reopening restores it.
Photos cannot be confirmed with unreviewed notes, and estimate confirmation cannot
silently omit an unfinished photo workspace. The note dialog now owns its text
controller through its exit animation, fixing a controller-disposal exception.
A native SQLite widget test proved raw note recovery after route/database reopen
and subsequent confirmation. This test uses a missing-image fixture and does NOT
prove image-byte retention. New picker imports now pass through `LocalAttachmentStore`: stream-copy to an
app-owned temporary file, flush, verify byte length and SHA-256, rename, then
commit a scoped SQLite manifest. The photo is added to the recovery draft only
after retention succeeds, and imports flush each photo checkpoint. Picker/import
work blocks competing route actions. Original source files are never deleted.
Existing saved photo paths are not yet migrated. A failed manifest write can
leave an unreferenced retained file; automatic deletion is deliberately absent
until drafts/history/restore references can be accounted for safely. SQL manifest
and filesystem rename are not one atomic transaction. Directory-entry power-loss
durability and real camera/lost-picker-data recovery still need platform work.
Verified-file reads enforce organization/owner filters and reject damaged bytes;
existing UI rendering still uses stored paths and needs that verification path
integrated for ongoing integrity reporting.

Focused estimate evidence: two native SQLite widget tests passed for raw partial
input across editor disposal/database reopen, explicit discard, injected failed
confirmation preserving the approved record and raw draft, and successful retry
retaining the prior signature history and unrelated metadata. This is scoped
recovery evidence, not app-wide durability or owner visual acceptance.
Job conversion checkpoint: `WorkPersistenceSession.createJobFromApprovedEstimate`
now writes the new job and the source estimate's converted state in one SQLite
transaction. It checks the captured source storage/document revisions and current
signature; shared save validation rejects standalone conversion, changed approved
items/pricing/customer/total, and conversion without exactly one new linked job.
The job editor waits for confirmed local persistence before returning, keeps the
form open on failure, and prevents competing actions while saving. Three parent
conversion routes no longer replay separate writes when connected to SQLite.
Standalone new jobs also wait for their SQL save. New-job main fields, schedule,
assignment and nested working items now share a scoped raw draft. New-job entry
offers owned unfinished drafts; estimate-linked entry resumes that source-specific
draft with its original source snapshot/storage revision. Back retains input;
explicit discard removes only the draft. Main confirmation rejects unfinished
item input and consumes the exact draft revision in the job/conversion transaction.
Directory names/locations absent from current fixtures are preserved on recovery.
Job-detail mutation forms and an app-wide draft directory still need integration.
Job workspace checkpoint: status, expense links, notes, item updates, rescheduling
and reassignment now await scoped SQLite compare-and-swap confirmation before
replacing the displayed/source job. A failed write leaves the confirmed state
unchanged and shows a failure. Competing workspace actions/Back are blocked during
the commit. SQL-backed routes bypass the legacy void save callback. A native
widget test proved failed status write/retry and absence of duplicate callback
writes; thirteen status/workspace tests passed.
Job notes now use `JobNotesEditorDialog`: actor/job-scoped raw text plus the
original Work snapshot/storage revision, local status and retry, explicit discard,
and exact-draft consumption in the record transaction. Keeping unfinished notes
or Back retains whitespace/partial text. Failed confirmation stays in the dialog;
success updates the workspace from the committed record without a second write.
The dialog owns its controller through route disposal. The Job workspace reassignment sheet now follows the same scoped recovery and
atomic-confirmation pattern for technician/vehicle selections. It keeps the
existing selector choices, preserves recovered values outside the current demo
list, and updates the workspace from the committed record. Work and Work Day assignment entry points now use that same sheet and skip
legacy callback replay when SQLite is connected. Job workspace rescheduling now uses `JobScheduleEditorSheet`, retaining the
shared-calendar date selection and raw hour/minute/AM-PM input in a scoped draft.
It preserves the recorded elapsed duration, blocks missing/invalid duration and
invalid local times, and confirms the record and draft consumption together.
It does not establish a business IANA-zone scheduling engine, ambiguous-clock
resolution, resource feasibility or conflict handling. Those remain separate
requirements; this checkpoint covers the existing local-date Work record flow. Fourteen focused notes/status/workspace tests passed. The notes test closed and
reopened SQLite, recovered raw text, injected a failed confirmation, verified
unchanged confirmed notes and retained input, then retried and verified atomic
draft consumption. Real-device interruption and stale-input conflict resolution
still require separate evidence.
Scheduling recovery evidence: fifteen scheduling/assignment/notes/workspace tests
passed. The schedule test changes a date through the shared calendar, persists
incomplete time input, reopens SQLite, then verifies a failed confirmation leaves
the job unchanged. Retry retains a three-hour-fifteen-minute duration across
midnight, preserves job notes, transitions a return visit back to scheduled and
consumes the draft. This is widget/database evidence, not owner visual acceptance
or physical-device power-loss validation.

Assignment-route evidence: a Work Day widget test opened the actual job action,
changed the technician, left without confirmation, reopened the action, recovered
the selection and saved it. The stored job advanced exactly one revision, proving
that the parent did not replay another write. That route test and the existing
assignment/notes recovery tests passed together (three tests). The original
memory-only `WorkAssignmentSheet` has no remaining production callers; its file
is retained as legacy source, not an alternate active persistence path.

Assignment evidence: fourteen assignment/notes/workspace tests passed, followed by
a passing extension of the assignment case covering vehicle as well as technician.
The case reopens SQLite, injects a failed confirmation, checks both unchanged
confirmed values and retained draft selections, then retries and checks draft
consumption. Full analysis passed. Demo name selectors are not a production
employee/vehicle identity or permission system.
Job-material editing now keeps a scoped job/source-revision checkpoint containing
the working list and unfinished line-item fields. `WorkItemsEditor` accepts an
awaited confirmation callback and keeps its route/input on failure. Job confirmation
consumes the exact draft revision in the same Work transaction; Back retains it,
and explicit discard removes it without modifying confirmed items. Confirmation
also rejects duplicate item IDs, non-material additions and changes to protected
items outside the current edit grant. Existing invoice/new-job item callers retain
their parent-draft behavior.
A native SQLite widget test recovered partial quantity input after reopening the
database, verified that an injected failed job update kept both editor and draft,
then retried and checked the committed material and consumed draft. The existing
missing-stock regression now requires the editor to remain open on failure while
still checking unchanged job/stock data.
Truck stock remains the existing demo/in-memory subsystem: validation now precedes
the Work write and quantity mutation follows successful confirmation, but this is
NOT an atomic inventory/Work transaction. Inventory migration remains deferred.

The latest combined job regression run passed nineteen tests; full analysis and
the macOS debug build passed. Native SQLite widget tests now prove main raw input and unfinished line-item
quantities across editor/database reopen, explicit discard, failed linked-job
confirmation preserving draft and approval, and retry committing the job and
conversion while consuming its draft. These tests do not simulate real device
power loss or establish production role authorization.
A disk-backed test proved rollback on injected insert failure, successful reopen,
retained signature, rejected duplicate conversion and rejected stale conversion
from an independently opened session. Initial focused Work/revision validation
passed nine tests. This does not establish production conversion permissions.

Attachment evidence: twelve focused tests passed, including original source-file
deletion followed by database reopen, scoped visibility, altered-byte rejection,
failed SQL manifest creation with no published record, draft notes and database
transaction regressions. Tests use isolated temporary files. Reuse assessment:
5.7 `receipt_camera_storage_policy.dart` provides storage-pressure policy only;
`receipt_proof_storage_cleanup.dart` avoids destructive cleanup from incomplete
reference lists. Those files were inspected read-only; neither was copied or
treated as validation of the new SQLite/file retention boundary. UI Lab's existing
receipt copy/hash approach informed this implementation; the new path additionally
flushes file writes before manifest publication. Camera runtime and abrupt device
power-loss proof remain outstanding.

Nested estimate evidence: eight focused tests passed, including labor and material
partial quantities across Back/database reopen, blocked premature confirmation,
resumption into the parent draft, estimate revision rules and line-item source
preservation. Full analysis passed. Logs:
`/tmp/maintainiac-estimate-nested-regression.log` and
`/tmp/maintainiac-estimate-nested-analyze.log`.

Broader estimate/revision/signature/transaction validation passed 27 tests with
one unresolved Work navigation failure: `estimate_lifecycle_test.dart` cannot
find `quick-customers` after returning to Work. That failure occurs outside the
estimate editor. Full `flutter analyze` reported no issues and the macOS debug
build passed. Logs: `/tmp/maintainiac-estimate-regression.log`,
`/tmp/maintainiac-estimate-analyze.log`, `/tmp/maintainiac-estimate-build.log`.

Earlier runtime checkpoint (before Work startup integration):
`flutter build macos --debug` passed and the normal app
launched. A read-only query of its private SQLite file reported `quick_check=ok`,
11 expenses, 2 recurring templates with 2 occurrences, 2 receipt drafts,
5 notification events and 10 deliveries, plus the committed demo-seed marker.
This proves startup used SQLite; it does not prove editor interruption recovery
or owner visual acceptance. Protected 5.7 Git state remains clean and unchanged.

## Release-one mode and database decision — 2026-09-09

September 28 owner clarification: both additional on-device backup and cloud
backup are opt-in only. Routine local SQLite saving and unfinished-input recovery
remain the primary storage behavior; they are not consent to create a second
backup copy or upload data. The owner's intended provider direction is Firebase
for structured business data, Google Drive for media, and possibly Apple iCloud.
The iCloud choice, provider integration, retention, quotas, and consent UI are
not implemented or settled by this direction. Current work remains the shared
local storage migration and reusable verification harness; another task owns
Work screens, including estimates, invoices, quotes and jobs.

Concurrent development must preserve those screen/domain edits. The storage
owner works in shared repositories/services and tests, and exposes stable
contracts rather than requiring screens to open databases. On the 8-GB Mac,
coordinate resource-heavy tests/builds serially; ordinary editing need not stop.

Owner clarification, September 15: offer separate, selectable scopes for backup
and synchronization. A user may choose receipt backup without backing up other
modules. Choosing receipt assistance does not grant cloud consent. Explain backup
as a recoverable copy and sync as keeping selected data consistent across devices.
Dependency metadata needed to restore selected records must be disclosed; do not
silently expand scope to unrelated records. This is a recorded requirement, not
implemented cloud selection or verified restore behavior. Current Expense UI work
is local only; the backup/sync setup screen is a subsequent reviewed flow.

Required modes: local only; sync without backup; sync with backup. All keep
durable local operation through SQLite/Drift. Cloud use is optional for the user,
but cloud backup/sync capability is REQUIRED for release one, not deferred.
User chooses how/when; onboarding and settings must offer the choice, but their
UI is not part of this pass. A backup-only fourth mode remains unresolved.
No account is required for local-only use except to download inventory trade
packs. Cloud identity and post-download pack entitlement remain unresolved.
Separate synchronization (including changes/deletions) from recoverable snapshots;
design mode transitions, durable queues, new-device restore and conflict handling.
No background schedule guarantees exact execution time on a mobile OS.
The original separate-project direction is superseded by the September 15
owner decision in `firebase_connection_checkpoint.md` and D34: use the selected
existing Firebase project. Changes still require bounded app namespaces and
verification of existing rules, bucket configuration and access before rollout.

## Distinguish the authorities

### Owner decision update — account-free operation and storage, 2026-09-07

Account creation is NOT required. Ordinary app workflows must work offline as
well as online; Maintainiac's backend purpose is storage, not a required runtime
for calculations, scheduling or record entry. No sign-in/vehicle-setup wall.
Local ownership still requires stable internal identities and scoped services;
this does not mean anonymous access to someone else's cloud or team records.
Provider sign-in for optional Google/Apple storage is separate from creating a
Maintainiac account. Identity, recovery and team-sharing mechanics remain open.

Earlier receipt-only paid scope is superseded. The owner discussed $2 ad removal
and $5 ad-free cloud backup, later a possible 2 GB allowance. Final quota, provider
allocation and sync-only entitlements remain unresolved. Ordinary local features
remain usable; do not invent paywalls or provider cost guarantees.

September 20 owner update: implement backup-upload allowance and abuse-protection
infrastructure inside UI Lab 2.1; do not modify Maintainiac 5.7. The owner is
still considering the freemium plan. Amounts, per-person bonuses, paid-seat
requirements and trial duration remain UNDECIDED. None may become a default
commercial entitlement merely because discussed in conversation.

The discussed allowance measures cumulative successfully backed-up upload bytes,
not device storage, current cloud occupancy or OCR processing. The server owns
grant approval and usage; local SQLite remains the device persistence authority.
No reset from changing an email, reinstalling, deleting a backup or re-adding a
member. Retries of one durable upload attempt consume allowance once. Reserve
bytes atomically before upload, preserve completed backups at exhaustion, and
keep local workflows available. Network traffic controls separately bound retries
and downloads; an uncharged retry is not unlimited bandwidth.

Unique recognition is authorized for narrowly scoped abuse prevention, not as
an addition to generic capability telemetry. Account history and trusted,
pseudonymous eligibility evidence can support grant decisions; arbitrary client
device IDs, email verification or App Check alone do not establish a new person's
eligibility. Shared/secondhand devices need reviewed recovery. Provider validation,
retention, operator permissions and account-deletion handling must be settled
before automatic recognition is enabled. No hardware serial/advertising-ID
collection or cross-app fingerprinting is implemented by this slice.

Implementation and validation evidence: `../cloud_backup/README.md`. It records
server transactions, object integrity, local emulator coverage and unconnected
production prerequisites. This is not evidence of deployed protection.

Job-photo bytes belong in the user's chosen local/external storage, not their
paid Maintainiac receipt-backup allocation. Required provider directions are
Google Photos for library-style storage, Google Drive for file-style storage,
and an Apple Photos/iCloud or file-storage option on supported Apple devices.
Exact adapters and available cross-device operations require feasibility work.
The durable job-to-photo link remains in Maintainiac. Show the actual location
and state, not “backed up by Maintainiac” when only an external link exists.

Offline capture, local saving, linking and access to retained local bytes must
work without provider availability. Upload/download cannot complete offline;
queue uploads durably and show pending status. Never delete the only local copy
merely because an upload was submitted. Offline availability after a user
chooses remote-only media, local cache retention and new-device recovery need
explicit policy; do not promise remote bytes are available without a connection.

- Product authority: accepted owner decisions and their canonical contracts.
- Domain authority: the module allowed to change a business record.
- Persistence: where drafts, confirmed records, evidence and replicas reside.
- Synchronization authority: which revision wins or needs review across devices.
- Backup: a recoverable historical copy, not automatically a live sync service.

“Single source of truth” does not authorize one giant mutable store, direct
widget database access, or duplicate copies independently accepting changes.
Offline-first and cloud-authoritative records can coexist, but a locally saved
pending command must not be described as globally accepted before reconciliation.

## Category map and unresolved product policy

The owner requires these categories to be explicit. Their inclusion is accepted;
assigning all business records to a cloud service or promising paid storage is not.

| Category | Record/content owner and minimum contract | Decision still required |
| --- | --- | --- |
| Cloud-authoritative business records, if later selected | NOT a current requirement for ordinary local operation; backend is storage-only under latest owner direction | Multi-device authority/reconciliation remains open; no mandatory cloud-first writes |
| Local/offline working data | Durable drafts, confirmed local operations, pending commands and authorized cached records; UI distinguishes local save, awaiting sync, synced and conflict | Cache lifetime, offline grants, device-loss and logout behavior per category |
| Optional user-controlled external media | Document/asset links refer to provider-owned bytes; inaccessible, moved, revoked or deleted media is a visible state | Providers, consent, supported exports, availability promises and original retention |
| Cloud backup snapshots | Recoverable records, relationships and included evidence; distinct from live sync and external job-media storage | Provider allocation, quota, retention, cancellation grace and recovery objectives |
| Metadata/link records | Owning record ID, content ID, provider locator, revision, size/type/integrity, state, scope and provenance; no raw credential embedded | Which metadata synchronizes, link retention after byte deletion, external provider changes |
| Derived projections/indexes | Calendar, Dashboard, counts, reports and search read authorized domain records; rebuildable without business mutation | Refresh/caching budgets and offline coverage indicators |
| Diagnostic/operational data | Separate admin-health boundary; minimal app/build/device/error context, redacted and access controlled | Consent, fields, retention, operator access and deletion policy |

Hive and durable-storage systems in 5.7 are valuable reuse/migration sources.
SQLite/Drift is the target; existing two-slot JSON checkpoints must be assessed
for migration, not silently discarded. Required cloud backup/sync remains behind
provider boundaries, with exact cloud data classes/rules/cost policy unresolved.
Firebase setup was requested, but no cloud project or deployment completed here.
Do not target 5.7's backend or attach billing without explicit scoped authority.

## Domain ownership and cross-record operations

Work owns Quotes, Estimates, Jobs, commitments, Invoices and Payments; Customers
owns customer/site identity; Expenses owns spending; Document Intake owns receipt
evidence/proposals; Inventory owns catalog/cost/stock; Trips owns trip/odometer
events; Maintenance/Repairs owns service/repair events. Asset identity needs a
shared owner decision (U07), not separate editable vehicle copies per module.

One user action may need several records. Specify the transaction or recoverable
command group, idempotency key, expected revisions and compensating/retry policy.
Do not infer cross-record atomicity from Hive boxes, JSON checksums or Firebase's
presence. A retried receipt confirmation cannot create a second expense, stock
receipt or job charge. Source links preserve exact versions where history needs
them; a mutable customer default never rewrites an issued document.

## Offline and sync engineering contracts

- Save locally through an authorized application boundary, with explicit result
  and last-known-good recovery. Outage must not discard local confirmed records.
- Persist pending intent before claiming a retry is queued. Commands carry
  stable IDs, expected revisions and organization/actor scope.
- Reauthorize on replay. Permission expiry/revocation offline is U02/U03; never
  silently grant permanent offline access or erase evidence to resolve a denial.
- Acknowledge cloud acceptance separately from local save. Preserve rejected or
  conflicting revisions for authorized resolution; sensitive last-write-wins is
  not an assumed policy. A schedule can be locally pending while a competing
  device has reserved the same resource.
- Paginate bounded transfers; interrupted uploads/retries must not duplicate
  bytes, records or notifications. Verify content before marking evidence ready.
- Restore into a reviewable plan, preserving IDs, references, audit and pending
  intent. Restore must not resend old reminders or overwrite newer records.
- Physical location of a replica cannot grant permission. Enforce scope at
  navigation, queries/counts, direct routes, bytes/attachments, exports and sync.

## Documents, external media and backup

Receipt evidence and job photos remain distinct content classes. September 27
owner direction: estimate/job images use optional user-owned Google Drive backup.
Local creation, editing and retained photos continue without connecting Drive.
September 27 owner clarification: backup starts disabled. Guided setup must ask
the person using this device before enabling uploads, including employees using
personal phones. Company authorization to access a job does not substitute for
that person's device/upload consent. Explain the destination account, selected
content, network use and local-storage consequences before enabling backup.
After verified backup, keeping the local copy is the default. Removing local
copies requires a separate explicit choice and confirmation by the device user;
an employer's backup setting, completed upload or low-space condition is not
deletion permission. Preserve the record/photo relationship and explain that a
removed local copy will require network access and valid provider permissions
to view again. These are required behaviors, not implemented-provider claims.
Provider consent, durable file/account links, verified upload and restore remain
required before displaying any backed-up state. This direction does not establish
an implemented Drive adapter or settle structured-record backup under D32. Backup must
cover recovery of records and relationships, not just receipt bytes. A locator is not proof bytes
remain accessible or that Maintainiac backed them up. Save provider/account
namespace, media/file ID, job ID, local reference and synchronization state;
never use an expiring display URL as the permanent relationship.

Data Saver creates reviewed derivatives; it must not silently destroy the only
readable evidence. Retain provenance, source/derived relationships and declared
quality states. Original-quality input is required for optional receipt reading,
not automatically for permanent backup. The owner permits reviewed compressed
proof images. Original disposal timing remains unresolved, not auto-delete
authorization. Receipt size/mode details live in `receipt_material_intake_blueprint.md`.

### Provider feasibility evidence — inspected 2026-09-07, not implemented

- Google Photos Library supports stable app-created media IDs; base URLs
  expire after 60 minutes. Persist IDs and obtain fresh authorized URLs, handle
  deletion/revocation, and do not assume arbitrary library-wide persistent access.
  [Media access](https://developers.google.com/photos/library/guides/access-media-items),
  [API changes](https://developers.google.com/photos/support/updates).
- Google Drive's `drive.file` scope supports app-created or user-selected files;
  assess that narrower access before broad Drive scopes. Visible user files are
  distinct from hidden appDataFolder storage.
  [Drive scopes](https://developers.google.com/workspace/drive/api/guides/api-specific-auth).
- Apple PhotoKit is a candidate for photo-library integration, not proof of
  guaranteed iCloud backup or stable cross-device linkage. Apple file-provider
  integration and identity/recovery require separate testing.
  [PhotoKit](https://developer.apple.com/documentation/photokit).

These are external constraints, not accepted adapter designs. Test upload and
retrieval, revoked consent, deleted/moved media, reinstall/new device, account
switch, quotas, offline retry, and team-access boundaries before promising the
feature. No provider setup, credentials or implementation occurred here.

PDF rendering, source receipt viewing and secure portal delivery share document
infrastructure but retain different domain schemas. Each render records source
revision, template/version and locale/unit presentation. Cloud/media entitlement
does not authorize access to internal costs or other recipients' documents.

## Retention, deletion and account boundaries

No retention duration, backup grace period, storage quota, purge schedule or
recovery guarantee is invented here. U02 requires a category-specific policy.
Until approved, do not implement automatic destructive cleanup from this document.

The policy must distinguish hiding a projection, deleting a link, tombstoning a
business record, deleting source bytes, expiring cached data, purging backups,
revoking a shared link and deleting an account. Document downstream links,
offline replicas, audit retention, restore behavior, consent and who may act.
Preserve corrections and record history; no generic cascading “delete all.”

Bank/account-number storage is outside current owner scope. Do not add such
fields for payment recording, diagnostics or future accounting placeholders.
Receipts/imports can incidentally contain sensitive numbers: redaction and
retention policy must address that risk, not assume uploaded content is clean.
Secrets are not business records, diagnostics, exports or GPT knowledge.

## Operational health and optional AI

The owner wants a separate admin application for health and bugs, including
device context useful for repair. PLANNED design: correlate a redacted failure
with app/build/OS, capability state and bounded error/operation identifiers;
collect no receipt image, GPS trail, customer details or full record payload by
default. U09 must define required fields, consent, staff access and retention.
Monitoring is not permission to browse customer data or silently fix records.

AI agents use the same scoped query/command interfaces. They do not own a new
ledger, directly access secret stores, gain broader permissions or confirm their
own proposals. Provider/model choice and costs remain unresolved; deterministic
scheduling and ordinary recordkeeping must remain functional without AI.

## Verification gate for future implementation

Test exact arithmetic and explicit rounding separately from uncertain input
quality. Cover save interruption, low disk, corrupt newest/all copies, restart,
schema upgrade, duplicate command, concurrent edit, cross-device conflict,
permission revocation, unavailable external media, upload interruption, restore
with pending/sent notifications, deletion propagation and scoped export.
Record the revision/environment, expected contract, observed outcome and gaps.
No database, cloud SDK, checksum or green legacy test proves these outcomes.

Employee directory checkpoint (2026-09-09): the existing employee profile editor
and directory now use `DirectoryPersistenceSession` for company-scoped SQL
records in `directory/employees`. The three existing UI Lab demo profiles are
seeded once under a separate marker so upgrading an already-seeded directory
adds them without replacing saved customer/company records. Confirmed changes
publish only after the record/history/command/outbox transaction commits.
Employee reads and writes require explicit view/manage capabilities; the menu,
direct directory route and editor refuse denied access. These are development
session capabilities, not a production authentication or role-revocation system.

Raw name, phone, emergency contact, pay arrangement, role and access choices use
an actor-scoped employee recovery draft. New-entry recovery retains one stable
employee ID; edit recovery retains its original record revision. Back flushes
and retains input. Save atomically consumes the exact draft revision and commits
the employee record with SQL compare-and-set, including unchanged submissions.
A failed or stale confirmation preserves both the previously confirmed profile
and recovery input. Explicit discard is separate from Back. Screen composition
is preserved; the previously misleading assertion of connected account access
was replaced with an accurate UI Lab limitation.

Read-only reuse assessment: 5.7 `lib/shared/profiles/employee_directory_store.dart`
uses Hive, offers a memory fallback on open failure, and mutates its record cache
before persistence succeeds. It was inspected as evidence, not copied as a
validated durable implementation; no 5.7 files or tests were changed or run.
UI Lab reuses its existing SQLite transaction/draft infrastructure instead.

Native tests cover reopen/no reseeding, all persisted profile fields, denied and
view-only mutation, organization isolation, SQL failure rollback and stale
cross-connection writes. Widget tests cover incomplete phone/pay input and an
access toggle across native Back/database reopening, failed confirmation and
single-record retry, plus denied menu/direct routes. These do not prove physical
power-loss durability, production account authorization or owner visual approval.
The employee directory does not yet replace fixture employee selectors in other
modules, activate invitations, or define payroll calculations. Vehicle-profile
persistence and inventory integration remain separate incomplete work.

Vehicle directory checkpoint (2026-09-09): the existing vehicle directory/editor
now use scoped SQLite profiles and actor-owned raw drafts. A separate one-time
fixture marker seeds the two existing profile identities without creating any
confirmed odometer. Name/model/assignment notes/active state belong to
`directory/vehicles`; mileage belongs to the existing `workday/odometers` record.
The profile stores no competing formatted mileage string. Profile/odometer writes
and exact draft consumption commit in one transaction before publishing caches.
Odometer confirmation compares its original SQL revision and rejects decreases;
a configuration-only save does not change mileage. Confirming a vehicle profile
does not fabricate a workday, trip, stock transaction, or account assignment.

The editor keeps incomplete raw odometer text and a stable new-vehicle identity
across Back/reopen. Confirmation accepts explicit miles with up to one decimal
place using exact integer parsing; it does not round excess precision or guess
units. Blank input keeps the saved reading. The directory reloads committed
profiles/odometers before showing editable data, and an existing editor refreshes
its source snapshot before opening recovery input. Restored input keeps its
original revisions. After confirmation the bound workday cache reloads; a failed
reload marks that cache unavailable instead of replaying the committed save.
Denied navigation, direct routes, queries and writes use explicit vehicle
view/manage capabilities. These remain development grants, not production auth.

Read-only 5.7 assessment: `lib/shared/state/app_state.dart` vehicle mutations
serialize writes and publish after `_writeVehicleSnapshot` succeeds, and
`app_state_vehicle_models.dart` separates stable identity from display name.
The snapshot writer also returns silently if its Hive box is unavailable, so
its public completion cannot alone prove durable storage. Those identity and
write-order patterns support this design, but the 5.7 snapshot store was not
copied, executed or modified. UI Lab uses its existing SQLite records and draft engine.

Native tests verify restart, shared workday visibility, atomic odometer failure
rollback, retained recovery input, retry, stale workday/profile contention,
configuration-only mileage preservation, and denied/other-company access.
Widget tests recover raw model/odometer input and active state across Back and
database reopen, inject a failed confirmation, retry to one profile, and refuse
denied menu/direct routes. The failure-injection test first waits for the native
autosave acknowledgment to avoid deadlocking Flutter's fake test zone against a
pending SQLite transaction. This is test coordination, not a production debounce.

Limits: assignment text remains a note; profile creation does not grant workday
or inventory access. Other modules still have fixture employee/vehicle selectors.
This checkpoint does not implement their full directory projection, odometer
correction/replacement workflow, metric odometer entry, production identity,
cloud sync/backup, physical-device interruption proof, or owner UI acceptance.

Unchanged-confirmation concurrency correction (2026-09-09): customer/company
and Work sessions previously compared submitted data to their in-memory cache
and could skip the SQL record revision check when values appeared identical.
A second connection could already have changed the saved record; the stale
session still acknowledged success and, when supplied, consumed its recovery
draft. Native regressions reproduced this for both directory kinds and Work.

Directory confirmation now validates every submitted record's scoped SQL
revision inside the same transaction as draft consumption and actual writes.
Work confirmation similarly sends unchanged submitted records as revision
preconditions to its repository transaction, including saves without a draft.
These checks do not create an artificial business revision for a genuinely
unchanged record. Changed records still use their existing write compare-and-set.
A stale confirmation fails before consuming input, so the newer saved record and
older recoverable input both remain. The fix does not automatically merge input,
advance an editor's base revision, or silently retry against newer records.

Fifteen focused directory/Work/repository/confirmation tests passed after the
reproduced failures. Customer/company native editor recovery tests also passed
with the directory change. Full conflict review, app-wide stranded-draft
navigation, and production permission revocation remain outstanding; preserving
a draft is not proof that every conflict can already be resolved in the UI.

Work home display-settings checkpoint (2026-09-09): the three existing Work
home choices now use the device-local SQLite preference store. The owning
Operations blueprint's apply-after-Save rule is preserved. Switches and Reset
update a durable `device/work-display-editor` draft; Back retains it and explicit
Discard removes only unfinished choices. Reopening restores the draft without
changing the active Work layout. Save validates/commits the three preference
values and consumes the exact draft revision in one SQLite transaction. A failed
confirmation keeps the original active values and the editable draft.

The device preference store now supports validated multi-field updates, merging
with current metadata so confirming/resetting Work choices preserves appearance,
language, measurements and Dashboard action choices. Device presentation input
uses fixed device ownership and cannot consume a business editor's draft token.
No business records, assignments, permission grants or cloud outbox entries are
created by these settings. Work reads its committed presentation values from the
shared controller instead of a screen-local list that disappears on restart.

The existing UI Lab preference/draft infrastructure remains the implementation
owner. Read-only review of 5.7's `shared/calendar/calendar_preferences_store.dart`
confirmed a screen-owned preference controller that awaits durable record saving
before notification. Its Calendar-specific schema/controller was not copied into
Work and no 5.7 code was changed or executed. This checkpoint extends UI Lab's
existing storage implementation, rather than porting a separate settings engine.

Focused checks cover draft recovery across database reopen, unchanged active
layout before confirmation, injected confirmation failure, retained input,
successful retry/consumption, atomic three-field reset, stale/unrelated draft
rejection and preservation of other preferences. The existing Work and Dashboard
regressions also pass. Other screen-specific settings still require their own
coverage audit; this does not claim all settings, conflict-review UI, production
security, cloud behavior, or visual acceptance are complete.

### Work list settings recovery

Jobs, Estimates, and Invoices retain separate device-local confirmed display
preferences and unfinished input in SQLite. Stable workspace IDs own the three
boolean choices; localized screen labels are not database keys. Back retains
input, explicit Discard removes that editor draft, and Save atomically consumes
its exact revision with the preference update. A failed write preserves both
previously active settings and unfinished input. These preferences change list
presentation only, never business records or authorization. They remain separate
from optional cloud consent and global settings. The existing operations-screen
rule that Save applies list settings remains authoritative.

### Draft identity reuse and revision safety

A draft ID may be reused after confirmation or explicit discard. Revision values
must not be reused for that scoped ID: an older editor checkpoint must never
consume replacement input. `LocalDraftStore` therefore retains a per-organization,
domain and draft-ID revision marker in `local_metadata`, inside the same SQLite
transaction as every draft write or consumption. New draft creation still expects
an absent row (`expectedRevision: 0`), but its returned saved revision can exceed
one. Callers must use that returned revision, not infer it from existence.
Consumption of older drafts initializes the marker from their existing revision.
Failed writes and failed surrounding confirmations roll back both changes.
Markers contain identity and revision only, not the discarded draft payload.
They are retained with database snapshots and must not be independently pruned.

### Receipt intake display preferences

Receipt intake's review-checklist and evidence-reminder display choices now use
the device preference store. Unfinished choices use a separate receipt-settings
draft. Back retains input, explicit Discard removes it, and Save atomically
applies both choices and consumes that exact draft revision. Failed confirmation
retains active values and recoverable input. The intake screen reads confirmed
preferences on reopening. These two switches control explanatory presentation;
they do not waive human confirmation, change receipt evidence, grant access,
configure OCR, or authorize cloud operations. Existing intake permission checks
continue to govern access to its settings action.

### Optional device reminders cannot gate local storage

SQLite bootstrap does not await native notification initialization. The mounted
app's reminder controller owns platform initialization and serialized launch
payload retrieval. Platform failures stay in reminder state rather than blocking
saved-work access or escaping the initial post-frame callback. The existing
reminder status surface shows initialization failures even when permission status
is unknown; Retry refreshes initialization without requesting permission. Explicit
Enable remains the permission-request action. This separation does not suppress
real database-open failures or imply successful notification delivery.

### Report display preference recovery

The five existing report display choices are device-local SQLite preferences,
separate from record permissions and report calculations. Unfinished choices are
stored in a scoped report-settings draft. Back retains input, explicit Discard
removes it, and Save atomically applies the choices and consumes the exact draft
revision. Restore defaults changes the unfinished choices until Save. Failed
writes preserve active preferences and recoverable input. Reports reads the
confirmed preference controller on reopening. The original company/employee scope
checks remain in the report projection; display preferences cannot widen them.

### Expense display settings and nested choices

Expense display preferences use a versioned, validated device-local JSON value in
SQLite: related-job display, category mode, up to ten distinct custom categories,
and category-specific Basic/Detailed receipt types. Storage identities use stable
names rather than translated labels. Unknown category/type values and malformed
preferences are rejected without replacing the saved value.

The settings editor keeps one raw draft containing parent preferences plus
separate pending category and receipt-type selections. Back/barrier dismissal
retains pending selections; Use promotes them to the unfinished parent; Cancel
explicitly discards the corresponding pending selection. Pending nested choices
block overall Save and Restore defaults until reviewed or canceled. Overall Save
atomically applies the versioned preferences and consumes the exact raw-draft
revision. Failures preserve active settings and recoverable input. The receipt-type
summary reflects the current choices. Record confirmation and access rules remain
separate; these preferences do not authorize accounting or cloud operations.

### Receipt evidence identity and revision checks

A requested retained evidence ID must identify an active item in the reviewed
receipt. Unknown IDs are errors, not silently omitted entries. Receipt update
commands can carry the caller's expected lifecycle revision; mismatch rejects the
command. Intake keeps the revision originally loaded or last successfully saved
and checks it before both changed and unchanged persistence paths. A missing
previously saved receipt is not treated as a new receipt to recreate. These
checks preserve newer evidence across stale review/retry attempts. Evidence-review ordering,
removal, selection and the latest Undo action use an actor/receipt-scoped raw
SQLite draft, with evidence identities resolved only against the authorized
receipt. Save/Continue checks that source revision and the exact saved input,
then commits evidence metadata and consumes the draft in one transaction.
Imports and physical file deletion are prohibited in this staging path. Back
retains the review; explicit discard removes its raw input without changing the
receipt. Intake accepts the committed result without issuing another update.
Malformed or stale input remains preserved for explicit discard; this does not
provide conflict merging or restore inaccessible files.

### Native image-picker handoff assessment — 2026-09-09

Inspection only; no recovery implementation or new dependency is claimed.
UI Lab `receipt_source_picker.dart` and `estimate_site_photos_screen.dart` use
camera/multi-image picker calls, but no current startup or screen code calls
`retrieveLostData`. Receipt intake allocates its receipt identity only after the
picker result. Estimate photos have a parent raw draft, but no persisted shared
picker operation identifies the intended target after process death. This is a
different boundary from saving files that have already reached a Dart editor.

Read-only reuse assessment inspected 5.7
`lib/shared/widgets/receipt_capture/receipt_image_picker.dart`: its wrapper
normalizes selected paths, avoids source recompression and selects the Android
photo-picker contract. It does not implement lost-result retrieval or a durable
request-to-owner association. Search found no `retrieveLostData` call in that
reference's `lib`. This wrapper is therefore not evidence of a reusable durable
handoff. No 5.7 code was copied, executed or changed.

The official [image_picker documentation](https://pub.dev/packages/image_picker)
requires startup lost-result handling when Android destroys MainActivity and
states that camera files are temporary cache files. The pinned
`image_picker_android` 0.8.13+21 implementation was checked locally:
`ImagePickerDelegate.retrieveLostImage` clears its cache before returning paths.
A retrieved path must not be called durably saved until app-owned file retention
and its SQLite association acknowledge success. A second process interruption
inside this handoff remains a separate failure window to test, not an assumed
atomic transfer between native preferences and SQLite.

Required implementation sequence before considering this gap closed:

1. Persist an unambiguous request identity, organization/actor, destination draft
   identity/revision and intended media source before invoking native picking.
   Serialize outstanding picker operations so the native singleton result cannot
   be reassigned by another workflow. A failed intent write must not launch it.
2. Use one startup/foreground coordinator to recover results; individual screens
   must not race to consume the same native cache. Retain originals privately,
   preserve errors and validate the target's current access/revision before use.
3. Make attachment adoption retry-safe across result retrieval, file retention,
   SQLite update and operation acknowledgment. Preserve pending data on failure;
   do not append twice after a restart or silently attach to a different record.
4. Re-enter the owning unfinished workflow or retain an explicitly recoverable
   result when its source is unavailable. Menu placement remains the separate
   owner choice already requested; it is not a reason to guess media ownership.
5. Exercise denied permission, cancellation, missing target, stale source,
   competing pickers, failed SQLite/file writes and repeated recovery. Add an
   Android process-death check while the external picker is active. Existing
   host draft-reopen and completed-expense force-stop checks do not cover it.

FilePicker document imports and platform-specific cancellation behavior also
need a separate capability check; `retrieveLostData` must not be assumed to cover
those APIs. This work does not authorize OCR, inference, cloud transfer, receipt
confirmation or changes to protected 5.7.

### Native media request journal foundation — 2026-09-09

`local_media_picker_request.dart` stores a single device-wide pending picker
request in SQLite metadata because the native picker exposes one result cache.
The immutable request identifies organization/actor, destination, target identity
and source revision, source type and a random request ID. Begin refuses an
occupied slot even if its contents cannot be decoded. Scoped reads do not expose
another actor's pending request. This storage API is not an authorization grant:
callers must check the saved target before launch and current access before use.

SQL adoption and acknowledgment share one transaction. Stale/mismatched requests
are rejected before the adoption callback; exact-value deletion guards against
replacement during that callback. File retention must precede this SQL-only
callback, and UI/repository caches may publish only after it succeeds. Route
exit does not implicitly consume the request.

Native tests verify failed intent creation, competing-owner rejection, scoped
reads, exact reopen, rollback when acknowledgment fails, successful retry,
rejection of a stale acknowledgment after a new request, and preservation of an
unknown-version request. Two focused tests passed. Core harness
`build/storage_qa/20260909T165052Z-e5fdc84c/report.json` passed 73 tests across 17
files with unchanged source fingerprint and no skips/failures/missing results.
Analysis is clean and macOS debug build passed; logs are archived with the report.

This API is not yet connected to native picking, startup lost-result retrieval,
file retention, receipt/estimate target adoption or recovery UI. Consequently,
the camera/picker interruption gap is still open. The journal tests prove SQL
request ownership and acknowledgment behavior, not end-to-end media recovery.
No schema version change, plugin modification or 5.7 write occurred.

### Retained media-result checkpoint — 2026-09-09

The native request journal now records an immutable ordered list of retained
attachment IDs. Checkpointing requires existing `attachments/files` manifests
with matching organization/owner and supported payload version. Duplicate IDs,
another actor's manifests, replacement results and stale requests are rejected.
Repeating the same checkpoint is idempotent. A failed metadata update preserves
the pending request and previously retained files.

Adoption now requires a retained result. Explicit cancellation is a separate
operation; stale cancellation cannot consume a request that advanced to retained
state. Cancellation removes only the request, leaving retained files/manifests
for the separate ownership-aware cleanup policy. Reopen tests verify the ordered
result and cancellation behavior. This API checks manifest references; retaining
and adopting services must still verify actual bytes and current target access.
It does not itself implement image-picker invocation or recovered-file copying.

Three focused tests passed. Core harness
`build/storage_qa/20260909T165523Z-d0fafdeb/report.json` passed 74 tests across 17
files, with an unchanged source fingerprint and no failures/skips/missing results.
Analysis is clean and macOS debug build passed. The native startup/recovery and
receipt/estimate integrations remain unfinished; no end-to-end picker recovery
claim is made. No protected 5.7 files changed.

### Native returned-file checkpoint and retention service — 2026-09-09

The media journal can now checkpoint ordered native source paths and original
filenames before slow retention. Source lists are immutable; duplicate paths,
replacement results and another request's state are rejected. This records a
retry source, not proof that temporary camera/cache bytes are durably retained.
An acknowledgment failure preserves the previous journal state.

`MediaPickerResultRetention` serializes retention through the existing scoped
`LocalAttachmentStore`, then checkpoints the resulting attachment IDs. The
request and attachment stores must share one database. Repeating a completed
retention returns its existing result without copying again. The service rejects
another owner or a different request identity. It does not invoke a native picker,
consume its cache, confirm a business record or publish UI state.

A native test injects a returned-source checkpoint failure, preserves raw paths
through missing-file failure and database restart, verifies the original name,
retries retention, checks exact copied bytes and verifies no duplicate attachment
on a completed retry. Four focused media tests passed. Core harness
`build/storage_qa/20260909T170015Z-a070906a/report.json` passed 75 tests across 18
files with unchanged source fingerprint and no failures/skips/missing results.
Analysis is clean and macOS debug build passed; logs are archived with the report.

Startup/native cache recovery, receipt/estimate adoption, permission revalidation,
user recovery and Android picker-active process-death testing remain unfinished.
A crash before the returned-source checkpoint is acknowledged can still lose the
native cache association. Temporary source deletion and multi-file partial-copy
failure remain limits; unreferenced retained files are preserved rather than
silently garbage-collected. These tests are not end-to-end media recovery proof.
Protected 5.7 remains unchanged.

### Native picker coordinator and atomic receipt adoption — 2026-09-09

The app-independent native picker coordinator now authorizes the saved target,
commits picker intent before launching the external activity, checkpoints returned
source paths before retaining bytes, and serializes recovery. It does not read
another actor's native recovery cache. Explicit cancellation from a normal picker
return clears its pending request; an empty startup recovery keeps the request
because emptiness does not prove cancellation. Permission changes prevent file
retention/adoption while preserving already-checkpointed source association.
The ImagePicker gateway supports Android lost-data retrieval, but app startup and
receipt/estimate picker buttons are not connected to this coordinator yet.

AtomicReceiptMediaAdoption verifies the current receipt revision, edit permission
and scoped retained originals, then stages the receipt update. Prepared domain
commit now consumes the media request inside its own transaction; cache publication
follows successful outer commit. Do not wrap a prepared group commit in a caller's
transaction. A forced request-delete failure rolls back receipt metadata and leaves
the request available. Retry produces one receipt revision; reopening verifies the
original bytes. No Expense/accounting record is created by media adoption.

Fifteen focused tests passed. The selected storage harness at
`build/storage_qa/20260909T170839Z-76d2a7fe/report.json` passed 173 tests across 66
files (77 core, 57 domain, 39 editor), with unchanged source fingerprint and no
failures, skips or missing results. Analysis is clean and macOS debug build passed;
logs are archived beside the report. Coordinator tests use a fake native gateway
with real SQLite/files, so this does not prove Android picker-active process-death
recovery. App startup/UI wiring, estimate adoption and device validation remain
unfinished. Protected 5.7 remains unchanged. This selected run does not supersede
the outstanding whole-application regression findings.

### Receipt native picker app connection — 2026-09-09

`UiLabApp` now owns a `ReceiptMediaSession` for its SQLite receipt repository and
calls recovery after mount without gating local startup. Receipt camera/library
buttons first persist an empty or existing receipt destination, then invoke the
durable coordinator. Returned originals are adopted by the atomic service and
published back to the receipt screen at the committed revision. Transient fixture
screens retain their existing picker path; document-file selection is unchanged.

Startup recovery retains originals without changing receipt metadata. The original
receipt offers Recover photos and an explicit Discard photo selection confirmation.
Pending selection recovery does not create an Expense or perform receipt analysis.
No request or selection is reassigned to whatever editor happens to be open. A
native startup failure remains retryable from the original receipt and does not
prevent opening local records. Estimate media integration and Android interruption
validation remain outstanding; see `sqlite_remaining_work_audit.md`.

`receipt_native_media_recovery_test.dart` exercises the app-owned session and actual
receipt buttons with a fake native gateway, real SQLite and database reopen. It
checks a persisted receipt/request before camera invocation, one attachment after
adoption, startup retention after reopen, recovery after removal of the temporary
source, and retry after an injected native startup failure. The source is a small
synthetic PNG; these are not physical camera or image-quality acceptance tests.

### Atomic estimate raw-input media adoption — 2026-09-09

DraftAutosaveSession now provides a queued adoption operation for retained media
belonging to the exact organization, actor and estimate-editor draft. It checks
the original raw-input revision, saves the prepared input and consumes the media
request in one transaction, then publishes the new input/revision. Normal input
replacement, retry and explicit discard are rejected during adoption so stale
queued UI input cannot overwrite the recovered media. Closing waits for the queue.
The caller must validate current Work permissions and retained originals before
using this primitive; it is not an authorization service or picker integration.

A failed adoption preserves the previous session input and native request. Its
error belongs to media recovery; ordinary draft retry does not silently consume
that request. Native tests inject failure while acknowledging the request, verify
SQL/cache rollback, retry once, reject a duplicate, reopen the database, preserve
incomplete numeric text, reject another actor and verify that a newer editor's SQL
input survives stale adoption. Normal autosaving resumes from the committed revision.

Nine focused tests passed. The selected harness
`build/storage_qa/20260909T172921Z-178d3f2d/report.json` passed 177 tests across 68
files with unchanged source fingerprint. The macOS debug build passed. A subsequent
lint-only edit changed an unused callback parameter from `__` to `_`; final core
validation and analysis are recorded in the verification-status checkpoint.
Estimate native picker/startup/UI integration remains outstanding. No 5.7 edits
or inventory integration occurred.

### Shared picker and estimate recovery app connection — 2026-09-09

The application now creates one NativeMediaPickerCoordinator independently of
receipt submission and exposes it through NativeMediaPickerScope. Receipt capture
uses that same coordinator; startup dispatches authorization by saved destination.
An estimate destination is its actor-owned `work/estimate-editor` raw draft, not
its business record ID. EstimateMediaAdoption verifies that SQL draft/revision,
Work edit scope and (for existing estimates) the current source record/revision
before reading retained originals, then revalidates inside the atomic input save.
The new draft commit callback is for SQL authorization checks, not file/network work.

Estimate camera/library buttons persist current photo-editor input before native
launch. The original photo editor can recover a selection or explicitly discard
it. Adoption preserves existing order, saved/unfinished notes and other raw fields;
it does not update confirmed Work records. The parent widget receives committed
photo-editor input before normal autosaving resumes. Save photos and notes then
moves that reviewed list into the parent estimate draft through its existing flow.
Route exit while a native operation runs is guarded; ordinary Back with a pending
selection keeps input and the request. Receipt and estimate widgets never retrieve
native lost data independently of the shared coordinator.

Job photo capture extends this same coordinator with destination `job` and
actor-owned domain `work/job-photos`. Shared WorkPhotoMediaAdoption retains the
estimate authorization behavior and checks job edit/photo grants, current job
revision, and the photo draft before adoption. The existing request-consumption
transaction accepts only each destination's matching domain. Job confirmation
consumes the draft with the photo-list update; a failed commit leaves both prior
job data and unfinished photos intact. No camera callback directly updates a
confirmed job. Saved-work recovery checks access and revision before reopening.
This connection is covered by simulated native capture/recovery and widget save
tests; it is not proof of physical camera process-death recovery or cloud backup.

Ten focused tests passed, including real app routes with a fake native gateway,
reopened SQLite and valid synthetic PNG rendering. The estimate test observes the
saved destination before camera invocation, simulates callback interruption,
reopens the app, recovers via startup and the original editor, and confirms one
photo list back into the still-unfinished estimate. Service tests cover new and
existing estimates, permission denial, stale source Work revision, preservation
of notes/raw decimals, and unchanged confirmed Work records. Receipt capture,
startup-failure retry and prior estimate draft/note tests still pass. Real Android
camera-active process death and document-file picker recovery remain outstanding.


### Document-file selection destination recovery — 2026-09-09

Receipt document selection and estimate image-file selection now use the shared
native coordinator. Both save current input and journal the exact actor-owned
destination/revision before opening FilePicker. Returned paths are checkpointed,
original bytes retained and verified, and adoption consumes the matching request
in the same transaction as its draft update. Receipt PDFs retain their PDF kind;
estimate image files retain their file source. Confirmed business records are
not changed by selecting evidence.

FilePicker does not provide the image-picker lost-result cache. Startup therefore
preserves a file request without calling that cache or opening an external picker.
The original editor offers Choose file again when no returned path was committed.
Explicit reselection reuses the saved request and rechecks its current permission
and revision. A checkpointed result is retained rather than replaced. Explicit
picker cancellation consumes only the pending request; the draft remains saved.
An inaccessible returned path raises a recoverable error instead of cancellation.

Eleven focused app/coordinator tests passed with fake native gateways, actual
SQLite reopen and synthetic valid PDF/PNG files. They cover normal file selection,
interrupted file reselection, camera recovery and startup recovery failure. These
checks prove application wiring, not native document-provider behavior. The
callback-to-durable-checkpoint window, native document/gallery runtime validation
and broader physical-device coverage remain outstanding.


### Native file path preservation — 2026-09-09

The native file adapter now preserves the exact platform-returned local path.
Trimming is used only to reject an empty path, not to rewrite a selected filename.
A regression using a real temporary filename with a trailing space reproduced
the previous wrong-path result before the correction and then verified reading
the original bytes. Adapter tests also preserve selection order/names, distinguish
explicit cancellation from an inaccessible member of a mixed selection, and check
receipt PDF/image versus estimate image filters. They replace only the plugin's
platform interface, exercising the application's actual adapter.

Core checkpoint `20260909T183912Z-223ef90b` passed 82 tests across 21 files with
unchanged source and no failures/skips. Six focused adapter/coordinator tests,
analysis and Android debug build passed. The full domains/editors suites were
not rerun for this one-line adapter correction; their preceding selected run
remains separately recorded. No new runtime or owner visual acceptance is claimed.


### Isolate unreadable draft previews — 2026-09-09

A recovery chooser must not make one unsupported or malformed saved-input preview
block access to other drafts or to Start another. The shared DraftRecoveryPreview
helper catches failures only while deriving chooser membership/labels. Unknown
input stays visible as Saved input unavailable — kept on this device. This helper
does not migrate, delete, repair, authorize or initialize a draft. Actor/domain
queries remain scoped, and selection still goes through strict existing editor
initialization and validation. An unreadable selection may remain unavailable;
this change does not claim to repair it or bypass current record permissions.

Estimate, invoice, client, job, manual expense and planned-expense choosers now
use this preview boundary. A database-reopen widget regression retains a valid
estimate beside a version-2 draft the current reader cannot decode. It recovers
the exact valid title and incomplete discount, explicitly discards that valid
input, and checks that the unsupported draft's ID, version and payload remain
unchanged. Five other affected editor regressions also passed. The global recovery
route for input whose source workflow is unreachable remains a separate open item.
