# SQLite/Drift migration resumed — September 16

## Latest owner direction

Resume the local durable-storage migration across the application. Preserve
unfinished input and workflow state through interruption, failure and restart.
Validate current code; historical green checks do not establish current behavior.

Catalog and inventory parser work are deferred out of release one. Materials is
becoming a simpler, basic inventory system. Another Codex model is actively
changing that screen. This storage task must preserve its edits and agree on
stable data/workflow interfaces before touching overlapping Materials files.
Do not impose the old catalog hierarchy on the new screen. Earlier all-trades
catalog audit handoff describes a superseded assignment, not current release scope.

5.7 Active remains read-only reference. Durable stock still belongs in the
existing SQLite architecture, without introducing Hive as another authority.
Layout changes must not require schema changes merely because widgets move.
Receipt Generator remains outside this task.

## Current verification and first correction

The September10 migration gate matrix is historical. Later Windows work includes
Firebase/account and receipt changes; recheck actual startup and workflows rather
than claiming the older status remains current.

Fresh initial checks: seven passed across receipt-intake atomic rollback/retry,
application storage lifecycle and receipt-input recovery. The receipt retry
failure described in an older roadmap did not reproduce in this run.

New lifecycle tests reproduced two faults before correction: a view could attach
while closure was pending, and overlapping close requests could invoke disposal
twice and report inconsistent success/failure. The correction shares the pending
close operation, blocks attachment while closing, and permits a later retry after
failure. This is a storage controller change, with no Materials or visual edits.
Follow-up: all ten focused checks passed (lifecycle, mounted-host failure,
selected-installation restart/rollback and receipt failure/retry); focused Dart
analysis found no issues. Restore tests emit Drift multiple-instance warnings:
inspected paths create a separate in-memory schema reference and separately
opened candidate-file executors, rather than sharing the live QueryExecutor.
Warnings were not suppressed. The first broader core regression finished with 188 passes and three failures;
no full completion or physical-device validation is claimed.

Remaining work includes a fresh workflow/persistence census, all relevant draft
and domain transaction checks, basic-inventory storage integration coordinated
with its screen owner, restore integration, broader regression and platform/runtime
verification. Cloud account configuration is not proof of durable backup, sync,
or production authorization. Report those boundaries separately.

## Follow-up boundary and regression checkpoint

The Work customer-review storage service imported its customer document model
from the screen folder. That model now lives in shared document code, with an
export at the original path for compatibility. Its fields and portal JSON remain
unchanged. The portal transport also no longer imports Flutter: its widget scope
is separate. No schema or visual layout changed. Added a boundary regression
check for both shared files. Focused analysis of the changed boundary was clean.

Core rerun `build/storage_qa/20260917T002702Z-353680ea/report.json`:
190 passed, two failed, no skipped tests, source unchanged during the run.
The Work boundary failure is resolved. Remaining failures at that checkpoint:

- Old catalog SQLite implementation still lives below screens. This is visible
  in the boundary test; it is not exempted or declared acceptable. Do not edit
  the other model's Materials/catalog replacement concurrently.
- The pause test relied on demo seeding, now disabled by default. Replaced that
  dependency with an explicit repository write. Initial replacement exposed a
  fixture organization mismatch, correctly rejected by SQLite; corrected the
  fixture to the installation's organization. Focused rerun follows below.

Normal LocalPersistence construction uses SQLite snapshot repositories for
expenses, recurring expenses, receipt drafts and notifications. Compatibility
file-backed constructors remain in those repository classes; a current search
found no calls to their `.open` factories in production `lib`. This is not yet
an exhaustive proof covering all other modules. Receipt evidence and installation
markers intentionally remain files; they are not a second record database.

The installation still uses the UI Lab organization constant. Local test actor
and organization checks must not be represented as production Firebase/company
membership enforcement. That integration remains separate and unverified.

Focused follow-up after correcting the fixture: all four pause, portal and PDF
checks passed; pause-test analysis was clean. Logs: `/tmp/tame-document-boundary-tests.log`
and `/tmp/tame-pause-analysis.log`. Full core has not been rerun after this final
fixture correction. The old catalog boundary failure remains unresolved.
No new platform build or physical-device lifecycle verification in this checkpoint.
Migration goal remains active, not complete.

## Current workflow census findings

- `receipt_text_entry_screen.dart` keeps edited receipt text only in a local
  TextEditingController. Its intake caller receives and persists text only after
  the explicit Use this text action. This is an unresolved interruption-loss
  gap, requiring a reusable durable input workflow and recovery path, not merely
  a save callback tied to widget disposal. Receipt intake also rejects concurrent
  `_persistDraft` requests with false; do not blindly call it on every keystroke.
- Dashboard day-note actions first open the stored day-note editor. The local
  title dialogs are fallback paths when that service is absent; validate normal
  startup admission and recovery before treating those fallbacks as production.
- Maintenance currently uses ModuleHomeScreen prototype notices. Do not claim
  an implemented maintenance-record workflow or its durability from shell presence.
- The domain regression run exposed many tests assuming production demo seeding.
  Correct explicit test fixtures without enabling demo content in production or
  bypassing the rollback/restart checks those tests were intended to exercise.

## Domain/editor baseline and first fixture repair

Run `build/storage_qa/20260917T002916Z-e3e1ebd4/report.json` completed with
unchanged source: domains 207 passed / 48 failed; editors 89 passed / 49 failed;
zero skips. Full failing-test names and errors are retained in
`storage_regression_failures_2026_09_16.json`. These are baseline failures, not
all proven storage defects and not all proven harmless fixtures. Triage remains.

Added `test/support/storage/seeded_directory_fixture.dart`, explicitly supplying
once-only directory fixture records in a test-owned SQLite database. It preserves
edits on reopen and does not change production demo settings. Updated the three
directory persistence, employee persistence and unchanged-confirmation test files
to request these fixtures explicitly. All seven focused tests passed afterward;
focused analysis was clean. Evidence: `/tmp/tame-directory-fixtures.log` and
`/tmp/tame-directory-fixtures-analysis.log`. No checks were removed or disabled.
The remaining broad failures still require individual diagnosis and rerun.

The PDF generation regression from the previous checkpoint also regenerated the
tracked `output/pdf/*estimate.pdf` artifacts. Those changes are test output, not
new approved templates or visual acceptance; preserve/review separately before
publication. No commit, push, physical-device test or platform build in this turn.

## Work fixtures and backward-compatible draft evolution

Added explicit once-only test Work fixtures without enabling production demo data.
Seven Work test files now request them: dashboard projection, status history,
estimate items, delivery, review, signature, and media adoption. All 13 focused
checks passed (`/tmp/tame-work-fixture-regression.log`). Existing assertions for
atomic rollback, approval invalidation, stale revisions, and restart were retained.

Found and corrected a real draft-evolution issue: decoding older drafts supplies
new optional defaults (purchase order, employee assignment, company logo reference).
Recapturing unchanged typed input previously rewrote the stored checkpoint merely
because these keys were new. DraftWorkflowController now compares the decoded
workflow values before replacing the raw payload. It still passes through the
session's lifecycle/failure guards. No SQL schema or layout change is involved.
Compatibility tests explicitly check new default values while retaining their
original raw-byte/revision-preservation checks; fixtures themselves remain legacy.
All 20 compatibility/autosave checks passed (`/tmp/tame-draft-compatibility.log`).

A new disk-backed evolution test verifies that a real purchase-order edit is
saved, survives database close/reopen, preserves unfinished numeric input, and
cannot bypass the closed-session guard. It passed (`/tmp/tame-draft-evolution.log`)
and is registered in the reusable storage QA domain suite. The baseline failure
ledger now marks only entries with matching focused passing evidence as retested;
this is not a full-suite pass. Receipt-text interruption, remaining fixture and
editor failures, Materials coordination, restore integration and device/runtime
validation remain unfinished. Migration goal remains active.

## Accepted company saves and recovery regression follow-up

The repaired fixtures exposed a real lifecycle defect in saveCompany: it admitted
an operation before disposal but rejected it later inside the queue. Removed that
second disposal check while retaining admission and permission/revision validation.
Previously accepted company writes now drain like the other directory writes;
new writes after disposal remain rejected. A new disk-backed regression closes
and reopens the database and proves the accepted company name and revision remain.

Job assignment tests now create real saved employee fixtures and pass employee
IDs alongside labels, matching current domain validation. They still exercise
failed writes, stale parents, legacy input and consumed-draft rejection. This
is a fixture correction, not a relaxation of production assignment validation.
Expense SQL tests now create one explicit expense rather than relying on disabled
production demo seeding. Additional Work/directory recovery tests request explicit
fixtures. Focused results: 27 recovery/domain checks passed, 12 admission/assignment
checks passed, five directory restart/confirmation checks passed. Analysis clean.
Logs: `/tmp/tame-recovery-fixtures-after.log`, `/tmp/tame-admission-assignment-after.log`,
`/tmp/tame-company-restart.log`, `/tmp/tame-recovery-analysis.log`.

Full domain run `20260917T004229Z-6ccd1f2e`: 256 passed, one failed, unchanged
source. It caught a regression introduced by the generic draft normalization:
settings confirmation must deliberately persist its conflict baseline even when
visible input is unchanged. Added an explicit transition-persistence method and
used it in PreferenceDraftWorkflow.confirm; ordinary recapture still preserves
legacy bytes. All six report-baseline, preference-concurrency and draft-evolution
checks now pass, with clean analysis (`/tmp/tame-preference-baseline.log`,
`/tmp/tame-baseline-analysis.log`). A final full domain rerun is in progress.

No Materials or protected reference edits. Receipt-text editing remains a known
interruption gap. Editor-suite failures and broader runtime/build gates remain
outstanding; domain success alone will not complete the migration.

Final domain rerun: `build/storage_qa/20260917T004438Z-fe19a8e8/report.json` — 257 passed, 0 failed, zero skipped; source unchanged. This verifies the declared domain suite only. Migration remains active.

## Receipt-text controller prepared; screen integration still pending

Added ReceiptTextEditingSession behind ReceiptSubmissionSession. It persists raw
unfinished text on the existing receipt draft, preserving its category, type,
evidence, links and revision safeguards. No new SQL table or catalog/parser work.
It serializes text edits and registers with the existing application draft-session
pause/flush registry. Failures retain the latest input, block successful flush,
and require explicit retry; a stale editor never adopts a newer revision merely
to overwrite it. Explicit discard releases only unsaved session input and leaves
the saved receipt untouched. The controller has no widget-tree or SQL dependency.

Three new disk-backed tests passed: rapid queued edits plus pause/reopen without
confirmation, injected write failure plus retry/duplicate retry, and concurrent
stale editor rejection plus explicit discard. Verified no expense records are
created by text autosave. Focused analysis clean. Test registered in the domain
suite. Evidence: `/tmp/tame-receipt-text-session.log` (initial three passes),
with combined receipt evidence/confirmation regression pending below.

IMPORTANT: ReceiptTextEntryScreen is not yet wired to this controller. The
original user-visible interruption gap therefore remains open. Next integrate
editing, save status/retry, back-navigation flush, explicit conflict discard,
and parent receipt revision refresh without changing approved layout. Verify
with widget restart/failure tests and current device runtime before acceptance.

Combined receipt text/evidence/confirmation regression: six checks passed,
`/tmp/tame-receipt-text-regression.log`. No platform build or device validation
for this new controller yet. Goal remains active.

## Receipt-text screen integration checkpoint

ReceiptTextEntryScreen now requires the durable receipt-text controller. It
retains the existing responsive field/actions, adds the shared save status,
shows retry/failure and explicit unsaved-text discard, and flushes before Back
or forward navigation. Intake persists a destination before opening text entry,
prevents duplicate launches, closes the session after return, and refreshes its
receipt/text revision so later saves cannot overwrite it from the older parent.
Unavailable storage is reported instead of opening an in-memory-only editor.

All six screen/controller/intake regression checks passed in
`/tmp/tame-receipt-screen-regression.log`. This includes native SQLite reopen,
Back blocked on failed writes, successful retry, stale editor protection, and an
extended real intake route test: type text, Back, reopen same text, proceed to
manual details, inject Expense/receipt atomic failure, then retry. The original
financial rollback assertions were retained. The prior pumpAndSettle-only wait
was replaced with the existing bounded native-I/O wait after opening the editor.
Focused screen/controller analysis was clean. Widget tests are registered in the
editor QA suite. A macOS debug build has started; no launch/device acceptance is
claimed. Receipt-text physical interruption and other migration gates remain open.

macOS `flutter build macos --debug --no-pub` succeeded after receipt screen
integration. Evidence: `/tmp/tame-storage-macos-build.log`. Build reports the
printing plugin does not yet support Swift Package Manager and will require a
future compatibility update. App was not relaunched; build success is not visual
or physical-interruption acceptance.

## Editor recovery bundle: current fixtures and navigation

Nine editor test files now use explicit fixture setup where needed, current
estimate action controls, and the existing selected-controller recovery handoff
for new invoice/job drafts. Removed obsolete dialog-label expectations, not
restart/raw-input/discard/rollback assertions. No production layout was changed.
Invoice/job tests select the exact saved draft ID after database reopen and
verify raw input plus explicit discard. Catalog discovery/navigation remains
covered by separate recovery tests and is not inferred from this handoff test.

Delivery now continues into native PDF sharing. Its test now verifies that the
widget host's unavailable native sharing service leaves exactly one durable
preparation; retry cannot duplicate preparation or mark the estimate sent.
The test retains its injected atomic draft-consumption failure and database
reopen checks. This is not proof of successful real-device sharing.

Combined run: all 11 tests passed across invoice, job, company, estimate delivery,
signature, items, job status, Dashboard/Calendar schedule, and review decisions.
Focused analysis clean. Evidence: `/tmp/tame-editor-bundles-verified.log` and
`/tmp/tame-editor-bundle-analysis.log`. The failure ledger marks matching baseline
entries as passed on focused retest. Full editor suite has not been rerun yet.
No source implementation changes or platform build in this bundle. Other editor
failures, restore wiring, cross-workflow audit and device interruption verification
remain outstanding; migration goal remains active.

## Selected, nested-item and native-media recovery follow-up

Updated twelve test files to match current explicit fixture setup and recovery
navigation. No production UI or Materials implementation changed in this bundle.
The six selected-draft handoff files initially passed 15 checks and failed one
obsolete assignment dropdown lookup. The assignment test now selects the current
employee checkbox with a seeded directory; both matching/mismatched handoff cases
passed on retest. This verifies test-owned permission/session cases, not cloud
account authorization.

Invoice/job nested-item tests now reopen the SQLite database and use the actual
saved-drafts screen to resume the named parent draft. They retain assertions that
unfinished items block parent confirmation and preserve raw quantity `2.` through
restart. Price entry uses the current unit-specific label. The media test now
waits for native database I/O before interacting with the recovery list instead
of trying to settle an active loading spinner on Flutter's simulated clock.

Evidence:
- `/tmp/tame-selected-handoff-bundle.log`: 15 passed, one failure subsequently
  repaired and retested; this historical log is not an all-pass result.
- `/tmp/tame-nested-media-editor-bundle.log`: assignment (two), payment (one),
  vehicle (two), and initial media capture (two) passed; four failures retained.
- `/tmp/tame-nested-recovery-current-routes.log`: all six passed, covering both
  nested item workflows and camera/file capture plus simulated restart recovery.
- `/tmp/tame-line-item-provenance.log`: one passed; exact source identities,
  raw recovered quantity, and private internal cost retained.
- `/tmp/tame-current-recovery-analysis.log`: all twelve changed test files clean.

The original regression ledger retains raw failures and now records matching
focused retest dispositions. These widget-host media checks do not prove physical
camera/plugin process-death recovery. No fresh complete editor suite or platform
build was run for this test-only bundle. Remaining editor/settings failures,
restore wiring, workflow coverage audit, current basic Materials integration,
full regression and physical-device lifecycle validation remain open. Goal active.

## Expense category persistence correction and settings verification

Found a production validation defect: the expense display preference codec kept
an older duplicate category-name list, so saving receipt-type preferences for all
current domain categories failed with `Unsupported device preference`. It now
uses the existing domain enum's stable identifiers. No schema migration, UI label
mapping, category invention, or screen dependency was introduced. Unknown names,
invalid receipt types, duplicate custom choices and the existing choice limit
remain rejected; rejected writes preserve the previous saved settings.

Updated the Work settings regression to check the current daily-summary section
instead of an obsolete My Jobs heading. Updated the phone-width expense settings
test to scroll to lazily built controls before tapping them. Production layout
was not changed. `/tmp/tame-expense-settings-current.log` retains the before-fix
failures. `/tmp/tame-settings-repaired.log` proves all four focused checks passed:
all category receipt types across database reopen, Work draft/retry atomicity,
and nested expense-choice recovery plus failed confirmation at 390/1400 widths.

Shared preference regression: 26 passed across local preferences, concurrent draft
confirmation, recovery catalog, selected recovery and repository boundaries
(`/tmp/tame-preference-regression.log`). Focused analysis found no issues
(`/tmp/tame-settings-analysis.log`). This is focused evidence, not whole-app or
physical-device acceptance. Remaining Dashboard/Work editor failures, full suite,
restore wiring, workflow census, Materials coordination and device interruption
gates remain open. Maintainiac 5.7 Active untouched; goal remains active.

## Work identity, estimate submission and nested-item recovery follow-up

Three more editor test files now use explicit test-owned Work fixtures rather
than relying on disabled production demo seeding. No production UI or Materials
screen change in this bundle. A schedule draft deliberately containing a different
job's payload remains unchanged and inaccessible; neither job revision advances.
Verified in `/tmp/tame-work-current-flows.log` (other tests in that historical run
failed and were subsequently corrected; it is not an all-pass suite report).

The estimate detail regression used an obsolete standalone readiness control.
It now sets up an estimate requiring company review and uses the current Submit
for approval action. Injected SQLite failure leaves the stage unchanged; a
concurrent saved note survives a rejected stale submission; reopening and
submitting succeeds with pending review. Test name updated accordingly, with the
historical name and mapping retained in the failure ledger. It passed in
`/tmp/tame-estimate-current-recovery.log`; the two nested tests in that run failed
and were subsequently retested separately.

Nested estimate labor/material tests use the current unified Items entry,
unit-specific Hours/Quantity and Price labels, and the actual saved-drafts route
after SQLite reopen. Tests wait for database loading and settled scrolling before
interaction. Both passed in `/tmp/tame-estimate-nested-recovery.log`. Assertions
retain exact unfinished `2.` input, blocked parent confirmation while a nested
item is unfinished, recovery, item confirmation and persisted parent payload.
These material line-item tests do not certify the separate basic inventory system.
Focused analysis clean (`/tmp/tame-work-recovery-analysis.log`); final diff check
clean. Four behavior checks passed across these runs. Full regression, Dashboard
failures, restore wiring, workflow census and device interruption gates remain
open. Goal active; no completion or physical-device acceptance claimed.

## Dashboard and Calendar recovery follow-up

Updated three tests to use current wide-screen inline actions rather than the
phone-only FAB, and explicit test-owned Work fixtures. Corrected an optional
expand-control lookup that called `.last` before checking for any match. No
production behavior or layout changed. The complete existing assertions remain:
paused workday and raw ending odometer survive reopen; failed end confirmation
retains input and workday state; retry atomically ends and consumes the draft;
Dashboard/Calendar day-note text and selected time survive reopen and rollback;
failed job arrival/completion cannot mutate status or append history, and retry
creates exactly one status event.

`/tmp/tame-dashboard-recovery.log`: workday and both day-note cases passed;
four job cases yielded two passes and two test-finder failures. After the finder
fix `/tmp/tame-dashboard-job-actions.log` passed all four job cases. Seven focused
checks therefore passed across these runs, not a single all-green initial run.
Focused analysis clean (`/tmp/tame-dashboard-analysis.log`), final diff check clean.
Full editor regression is the next gate; broader workflow/restore/device and
Materials integration requirements remain unproven. Goal active.

## Full editor regression checkpoint

Authoritative run `build/storage_qa/20260917T011833Z-4ebe14bf/report.json` completed
75 files in 340.502 seconds: 138 passed, 2 failed, zero skipped, zero missing
suites or unfinished tests, source unchanged. This is not a green suite.
Remaining failures are `material handoff rejects replaced owner and changed
capabilities` and `material recovery preserves nested input and stock through
Back`, both in Job Materials recovery. Inspect current inventory ownership and
fixtures before correction; do not revive deferred catalog/parser behavior or
change the separate model's Materials implementation just to pass tests.

Read-only boundary follow-up found no direct Drift table calls/LocalDraftStore
construction in screens/shared/shell in the queried patterns, but the old
`inventory/catalog/inventory_catalog_database.dart` still directly imports sqlite3
and reads catalog.sqlite. Therefore full UI/storage decoupling remains unproven
for Materials. Global restore service remains unconfigured in normal main.dart;
System settings has only a noninteractive backup/sync tile. Calendar Day still
has two memory-only, disconnected settings. Owner clarification was requested
about implementing those as shared saved preferences versus deferring them.
No default decision or owner approval is inferred while awaiting a reply.
No source changes made during the full editor run. Migration goal remains active.

## Job Materials handoff fixture correction

Both remaining editor failures reproduced missing test-owned jobs after production
demo seeding was disabled. Updated only `job_materials_recovery_handoff_test.dart`
to use the existing explicit Work fixture helper; no Materials implementation,
stock behavior or catalog/parser work changed. Both checks passed in
`/tmp/tame-job-materials-handoff.log`; focused analysis clean. Checks retain
replaced-owner/capability rejection, exact pending quantity through Back and
reopening the workflow, unchanged job revision and unchanged in-memory stock.
They do not prove durable stock recovery across database/process restart.
The full 138-pass/2-fail editor run remains historical; both failures now have
focused passes, not a subsequent all-green complete run. Core suite is next.
Owner decision requested for first local restore UI policy: whole-installation
replacement with reviewed confirmation and retained prior installation versus
UI deferral. Do not infer approval from elapsed time; local save work continues.

## Current core storage regression

`build/storage_qa/20260917T012558Z-1a9f0580/report.json`: 47 files, 191 passed,
one failed, zero skipped, source unchanged. Only failure: presentation storage
boundary detects `lib/src/screens/inventory/catalog/inventory_catalog_database.dart`.
The architecture guard remains intact. Coordinate removal/refactoring with the
active basic Materials rebuild; do not exempt catalog code or revive that deferred
feature. This prevents claiming universal UI/storage separation today.

Read-only production-path search also found retained DualSlotJsonStore constructors
in the four legacy domain repository adapters. No application call sites to those
constructors were found; `LocalPersistence.open` constructs SqliteDomainSnapshotStore
for expenses, recurring expenses, receipt drafts and notifications. FileRepository
names are typedef compatibility aliases, not proof of active file storage. This
search does not certify all runtime entry points; workflow completion audit remains.

## Refreshed domain regression

`build/storage_qa/20260917T012722Z-229d2e51/report.json`: all 81 declared domain
files passed with unchanged source. Consult the report for exact counts. Includes
new receipt-text editing session coverage alongside transaction/restart/concurrency
checks. Does not establish a working global restore UI, physical device behavior,
production account isolation, or complete basic inventory integration. Core's
catalog boundary failure and pending owner choices remain open.

## Lifecycle and pre-entry coverage audit — not completion

Current source trace: DraftAutosaveSession.replaceInput queues each changed raw
payload immediately through the repository, with revision checks and a durable
acknowledgement state. It does not depend on a debounce or an OS background event.
ApplicationStartupScreen's WidgetsBindingObserver guards routes during installation
switching; it is not a background-save hook. ApplicationStorageLifecycle drains
view/domain/draft/storage operations during controlled switching/closure. Abrupt
OS termination still only guarantees input whose SQLite write was acknowledged;
physical termination tests remain required for the current build.

The source search identifies 52 screen files with text controllers/fields. This
is a discovery inventory, not proof of 52 independently verified workflows.
Account password/confirmation inputs must not be persisted as ordinary SQLite
drafts. Search queries are presentation state. Dashboard/Calendar fallback note
dialogs are memory-only when constructed without the domain session; normal
startup injects DayNotePersistenceSession and openStoredDayNoteEditor selects its
durable route before the fallback. This distinction needs ongoing entry-point
coverage, not a blanket claim that all fallback paths are production storage.

New concrete gap: ExpenseEntryChoiceScreen keeps `_selected` detail and `_category`
only in widget state; ReceiptCategoryPickerScreen also stages `_selected` locally.
`openExpenseEntryFlow` creates/opens the receipt or manual expense editor only
inside onContinue. Thus stopping before Continue loses those setup choices.
After Continue the existing receipt entrySetup/manual expense draft retains them.
No confirmed financial record is created by setup itself. Next correction must
use a workflow-owned recoverable setup state, safe transfer into the owning draft,
explicit discard and retry/stale handling without duplicate expenses or a second
storage authority. Retain existing screen layout and preserve category semantics;
do not write SQL/JSON keys directly into setup widgets. This uncovered gap means
passing the declared editor suite alone cannot establish migration completion.

## Expense setup workflow foundation — integration unfinished

Added ExpenseEntrySetupInput and ExpenseEntrySetupWorkflow behind the existing
DraftRepository/DraftAutosaveSession boundary. Existing ExpenseUiRepositoryController
now offers an owner-bound factory with live local capability/disposal checks.
Versioned setup preserves date, detail choice, accepted category and pending category
separately. No expense/stock effects, table/schema additions or widget identifiers.
Unknown versions and missing selected drafts fail without reseeding or rewriting.

Three native SQLite tests passed (`/tmp/tame-expense-setup-workflow.log`): restart
with pending category/detail, category acceptance and explicit discard with zero
business rows; injected write failure/retry plus stale/revoked edits; and unchanged
retention of unknown versions/missing recovery. Registered in the domain QA suite.
Initial focused analysis clean. These tests use explicit test authority, not
production account enforcement. This is a workflow foundation, not an implemented
user-facing fix: setup/category screens, recovery catalog/route, safe ownership
transfer into receipt/manual drafts, and end-to-end failure/restart tests remain
required. Do not report the pre-Continue data-loss gap closed yet.

## Atomic unfinished-input transfer foundation

Added DraftTransferRepository, implemented by LocalDraftStore using one SQLite
transaction for creating a fresh destination and consuming the exact scoped
source revision. Existing targets, wrong owners, missing/stale sources reject;
source deletion failure rolls back destination and revision marker writes. Caller
payload is copied before asynchronous work. No schema or business-record change.

ExpenseEntrySetupWorkflow.continueManually now uses that capability behind its
live local owner check. It rejects pending category choices and produces a stable,
recoverable expenses/manual-entry destination with raw blank financial fields.
It consumes setup atomically and seals the session after success; no expense is
confirmed. The existing expense editor/recovery contract can own that destination.
Receipt continuation and UI/recovery-route integration remain unfinished.

Verification: transfer plus existing draft-generation regressions, four passed
(`/tmp/tame-draft-transfer.log`); setup workflow, four passed including manual
continuation and duplicate rejection (`/tmp/tame-setup-transfer.log`). Focused
analysis clean (`/tmp/tame-draft-transfer-analysis.log`,
`/tmp/tame-setup-transfer-analysis.log`). Transfer tests are in the core manifest.
These eight checks are not new full-suite or device results. The user-facing
pre-Continue loss is not yet fixed until the screens and recovery are wired.

## Atomic setup-to-receipt continuation

Added AtomicExpenseSetupReceipt and an application-owned continuation on
ReceiptSubmissionSession. The existing staged receipt repository and grouped
SQLite commit create an empty receipt draft and consume the exact saved setup
revision together. Category/date/detail come from validated saved input, not
widget payloads. Pending category decisions cannot continue. The session checks
that setup belongs to its active Expense owner/repository and receipt authority.
The destination ID is stable; successful setup confirmation seals duplicate
submission. No evidence import, OCR, expense or inventory effect is introduced.

`expense_setup_receipt_transfer_test.dart` injects source-consumption failure and
proves no receipt/record publication and retained setup, then retries, rejects a
duplicate continuation, closes/reopens SQLite and verifies exactly one receipt
with its category plus no expense/draft remainder. Added to domain manifest.
Combined receipt evidence, raw-text and setup regressions: six passed in
`/tmp/tame-receipt-setup-regression.log`; focused analysis clean in
`/tmp/tame-receipt-setup-final-analysis.log`. No full-suite or physical-device
claim. Setup screen/category picker integration and Saved work recovery routing
remain unfinished, so the user-facing pre-Continue gap is still open. Maintainiac
5.7 Active and Materials implementation untouched.

## Expense setup screen wiring — WORK IN PROGRESS, not ready

ExpenseEntryChoiceScreen and ReceiptCategoryPickerScreen now accept the reusable
setup controller and capture detail/pending category choices, with draft-aware
Back and shared save/retry status. Application recovery has an Expense setup
provider, typed route dispatch, and release handling; unsupported input remains
visible rather than reset. Entry flow creates setup through ExpenseUiScope and
uses atomic receipt/manual transfer. Screens do not construct SQLite repositories.
Owner/repository mismatch is rejected before recovered setup is presented.

Two checks passed in `/tmp/tame-setup-screen-recovery.log`: the new widget test
restores detailed mode and an unfinished Fuel category after database reopen,
and the existing application recovery scope check. Integrated source analysis
was clean before the new test. Test registered in the editor manifest.

CRITICAL unfinished integration: current expense_entry_flow.dart uses
pushReplacement after transfer. Existing expense_entry_choice_test.dart expects
receipt-source Back to return to editable setup. Do not accept the replacement
navigation as owner-approved or alter that test to bless it. Preserve Back using
a workflow-owned continuation reference/re-entry mechanism that cannot duplicate
the existing receipt or lose its evidence/edits. Manual re-entry needs equivalent
care. The old standalone entry-choice test also lacks actual durable session
fixtures, which need updating without weakening its layout/Back assertions.
Explicit setup discard presentation, continuation retry after navigation failure,
complete global Saved work resume tests, focused regression and platform build
are still required. No release/readiness or complete user-facing fix claim.

## Expense return-to-setup storage safeguards — route repair still unfinished

Draft transfer now supports an explicitly reviewed destination revision as well
as fresh creation. Updating that destination and consuming setup use the same
SQLite transaction. A new regression injects failure during source consumption
after the destination update, verifies both drafts remain byte-for-byte unchanged,
then verifies retry, duplicate rejection, exact revision and database reopen.

Setup input can carry a domain-level continuation identity and revision, with no
route, widget or SQL-table identifiers. Manual continuation retains the same draft
and preserves raw input and unknown fields while changing only the chosen category
and detail level. Missing/stale targets, receipt-backed input and existing confirmed
record edits are rejected instead of being overwritten. Existing setup payloads
without this optional continuation remain readable.

Eight focused checks passed in `/tmp/tame-expense-return-tests.log`, including
unfinished amount `12.`, original owner label, unknown-field preservation and a
stale second setup retaining its own recoverable input. Earlier transfer/generation
run also passed five checks in `/tmp/tame-draft-return-transfer.log`.

This does NOT fix the route yet: receipt continuation updates, setup re-entry,
and the existing Back-navigation regression still need implementation/verification.
No new UI changes, Materials edits, schema changes or device-validation claims in
this storage/test bundle. Full migration remains active and incomplete.

Receipt continuation now also updates the referenced existing receipt through
the staged authorized repository, checks its reviewed revision, retains evidence,
selected details/item reads, job links and pasted text, and consumes setup in the
same commit. Two checks passed in `/tmp/tame-receipt-return-tests.log`, including
injected source-consumption failure leaving the original receipt unchanged,
successful retry preserving two evidence records and unfinished text, and stale
setup rejection. Focused analysis clean (`/tmp/tame-receipt-return-analysis.log`).
This is repository/service evidence only: the screen still needs the re-entry
handoff wiring and Back-navigation regression before this correction is finished.

## Expense setup Back navigation connected — focused validation only

Entry flow now pushes the receipt/manual editor rather than replacing setup.
On Back, authorized workflow services obtain the same unfinished destination and
create recoverable setup with its identity and reviewed revision. The setup screen
adopts that controller; Continue updates the referenced destination atomically.
Successful expense completion exits through the existing guarded route mechanism.
No SQL or payload serialization was added to screens and no layout was redesigned.

`expense_setup_back_navigation_test.dart` exercises real SQLite and authorized
application sessions: Continue, receipt Back, Continue again, one unchanged receipt
identity, no confirmed expense, and exit through setup. Added to editor QA manifest.
Nine combined setup workflow/restart/receipt transaction/navigation checks passed
in `/tmp/tame-setup-back-regression.log`. Focused analysis clean in
`/tmp/tame-setup-back-final-analysis.log`.

Remaining: adapt the original seven responsive setup tests to explicit durable
fixtures without changing layout expectations; test manual Back and successful
completion; handle failure between committed transfer and route/re-entry creation
without leaving a sealed setup controller as the only available action; complete
explicit setup discard and global recovery cases. No full regression/build/device
acceptance for this bundle. Earlier pushReplacement warning is superseded by this
implementation, but expense setup integration is not yet fully verified.

Original responsive regression follow-up: all seven cases in
`expense_entry_choice_test.dart` now run against explicit SQLite-backed Expense
and Receipt sessions. Native I/O waits replace simulated-clock-only waits at
durable transitions. Existing 24-LP card gap, equal card widths/alignment, source
grid, unavailable PDF action, category cancellation and return-to-setup assertions
are unchanged. The six responsive cases cover 320/700/1440 logical pixels, light
and dark themes, with 2x text scaling. All seven passed in
`/tmp/tame-setup-responsive.log`. These are widget-host checks, not owner visual
acceptance or physical-device lifecycle proof. Manual navigation, post-commit
navigation/re-entry failures, explicit discard and wider gates remain unfinished.

Manual navigation follow-up: the shared integration test now covers receipt and
manual entry. Manual entry edits vendor text and raw amount `12.`, requests native
Back, returns through setup, then verifies the same manual draft identity and exact
unfinished input. Both cases passed in `/tmp/tame-manual-back-native.log`. Earlier
runs failed because the test omitted OperationalScope and then searched for a
stock BackButton that the editor does not use; these fixture/action errors were
corrected without production layout changes. The receipt-specific toolbar Back
path remains covered by the original responsive tests. These tests do not yet
prove successful completion navigation or interruption during re-entry creation.

## Recovery after a committed transfer and failed setup re-entry

Entry flow now remembers the destination immediately after a successful atomic
transfer. If opening/re-entering the workflow subsequently fails, Continue recovers
setup from that destination instead of re-submitting the consumed setup. Closed
setup input cannot be edited while this retry is pending. Failed new setup sessions
are closed/unregistered without deleting the saved destination. No schema change.

The navigation tests inject failure specifically on insertion of returned setup.
Receipt retry passed in `/tmp/tame-receipt-return-retry2.log`; manual retry passed
in `/tmp/tame-manual-return-retry2.log`, retaining the same ID, vendor text and raw
amount `12.`. Tests then continue again without duplicate business records. The
initial retry test tapped under a SnackBar/before a scheduled busy frame; fixed
test synchronization. Two manual runs were stopped after hanging while the test
blocked its fake clock during a pending native write. Explicitly draining that
write with the existing dual-clock helper fixed the test; those stopped runs are
not passing evidence. No unrelated test processes were stopped.

Focused six-file analysis clean (`/tmp/tame-return-retry-analysis.log`). Final
test-only synchronization edit needs its own subsequent analysis. Completion
navigation, setup discard/global recovery coverage, full regression and current
platform/device validation still remain; migration is not complete.

## Application recovery ownership and manual completion

Found a real recovery defect: ExpenseDraftRecovery.setup constructed a fresh
catalog on every access, while application composition separately bound list,
resume and discard. Selection tokens therefore belonged to a different catalog
from the one handling resume/discard. Setup recovery is now one lazily retained
instance per ExpenseDraftRecovery owner. No selection-identity guard was relaxed.

Application recovery scope regression now creates expense setup, lists it through
the composed application hub, resumes exact category/detail, closes it, explicitly
discards it and verifies it disappears. Existing layout rebuild, replaced-owner
and retired-host assertions remain. Passed in `/tmp/tame-setup-global-recovery.log`;
analysis clean in `/tmp/tame-setup-global-analysis.log`. This exercises the service
behind Saved work; it does not claim every recovery screen route is verified.

Manual route regression now continues past Back/re-entry failure/retry: replace
raw `12.` with `12.50`, Save expense, return to the original Start route, verify
one expense for 12.50 and zero remaining drafts. Passed in
`/tmp/tame-manual-complete-navigation.log`. Receipt confirmation navigation and
discarding linked setup without discarding its underlying draft still need focused
coverage, alongside broader migration/build/device gates.

Linked setup discard is now tested for both receipt and manual destinations.
`expense_setup_discard_isolation_test.dart` rejects stale selected setup, injects
delete failure and verifies retained setup, then explicitly discards it and reopens
the database. Destination payload/receipt JSON remains unchanged, receipt evidence
files still exist, and no expense is created. Two checks passed in
`/tmp/tame-setup-discard-isolation.log`; focused analysis clean in
`/tmp/tame-discard-isolation-analysis.log`. Registered in the domain QA manifest.
The existing Saved work discard action can perform this operation; this bundle
adds no new screen control or layout. Receipt confirmation navigation and broader
workflow/build/device verification remain outstanding.

Fresh boundary search still finds the old catalog's sqlite3 import/open below
`screens/inventory/catalog`; other model owns the Materials replacement. Do not
claim complete UI/storage separation or bypass the existing architecture guard.

## Receipt completion and refreshed domain gate

Navigation integration now also follows receipt source -> text/manual details ->
Save expense -> original Start route. It verifies one expense for 23.45, the
submitted receipt linked to that exact expense, and zero unfinished draft rows.
Both manual and receipt cases pass together in `/tmp/tame-expense-completion-paths.log`;
focused analysis clean (`/tmp/tame-receipt-completion-analysis.log`). The fixture
now includes ReceiptDraftUiScope as normal application composition does.

Full declared domain gate `build/storage_qa/20260917T021945Z-0377f21f/report.json`:
84 files, 269 passed, zero failed/skipped/missing/unfinished, source fingerprint
unchanged, 69.661 seconds. This includes the new setup/transfer/discard cases;
it is not a full editor/core/build/device gate.

Further read-only census: expense correction reason dialog is memory-only, but
its callers in ExpenseDetailScreen select the durable expense editor when both
LocalDraftScope and ExpenseUiScope exist. The dialog is on the service-absent
fallback branches. Do not classify it as a proven normal-startup data-loss gap
without verifying service admission; equally, do not declare all entry points
covered merely because this guard exists. Broader census and gates remain open.

## Full editor gate and gallery setup regression

`build/storage_qa/20260917T022206Z-cf96b214/report.json`: 77 files,
142 passed, one failed, zero skipped/missing/unfinished, unchanged source,
397.823 seconds. The failing gallery-media recovery test tapped before durable
setup opened and later before Back finished reconstructing setup. Updated only
native-I/O readiness waits, including enabled category selection after Back.
No image retention, receipt identity, category, restart, or layout assertion was
removed. Focused gallery retest passed (`/tmp/tame-gallery-setup-final.log`).
This is a focused repair, not a subsequent all-green full editor run.

Owner efficiency direction: avoid reading unchanged files repeatedly, intermediate
test-output polling, and verbose progress narration. Use bounded relevant reads,
saved evidence, and completed test results; retain full logs without printing them.

Combined targeted regression after the gallery wait repair: 15 passed across
native receipt media, original responsive setup, and manual/receipt completion
navigation (`/tmp/tame-expense-media-regression.log`); gallery analysis clean.

Current macOS debug build succeeded with no launch
(`/tmp/tame-storage-current-macos-build.log`). Printing plugin Swift Package Manager
compatibility warning remains. Full `flutter analyze` reports seven issues
(`/tmp/tame-storage-current-full-analysis.log`): one setup-callback test warning
introduced by this storage work, and six inventory/catalog-related diagnostics,
including a const-expression error in the legacy parser contract test. Preserve
the parallel Materials task's files; these prevent a whole-worktree clean-analysis
claim. New build success does not prove device interruption or visual acceptance.

Resolved this task's nullable setup callback warning in expense_welcome_test.
Its app-level regression initially exposed a service-absent UiLabApp fixture;
it now supplies real temporary SQLite expense/receipt/draft repositories and waits
for setup readiness. All eight welcome/setup tests passed in
`/tmp/tame-expense-welcome-final.log`; focused analysis clean in
`/tmp/tame-expense-welcome-analysis.log`. Other inventory diagnostics remain outside
this parallel task's edits; no subsequent clean whole-worktree analysis is claimed.

## Dashboard editor commit ownership

Dashboard home, Calendar Day, and attention-estimate callbacks no longer submit
returned Work records a second time when a durable Work session is attached.
The editor/workflow owns the commit (including atomic estimate conversion and
draft consumption); Dashboard observes the session's projections. Prototype-only
fallbacks remain for contexts without a session. No layout or schema changed.
Identical saves can already be deduplicated by the session; the specific risk
addressed here is replaying a stale editor result or repeating source conversion.

Verification: the existing job-draft, Dashboard projection, schedule recovery and
SQLite failure bundle passed 11 tests (`/tmp/tame-dashboard-save-ownership.log`).
Two formatting diagnostics were corrected. The new
`dashboard_editor_commit_ownership_test.dart` enters the real Dashboard schedule
route, commits a record and a newer status, then returns the older editor result.
It checks no rejected duplicate action, preserves the newer status, and reopens
the database to verify persistence. This deliberately simulates the route-return
race; actual editor confirmation and conversion are separate regression tests.
The three-test bundle passed (`/tmp/tame-dashboard-ownership-final.log`), and
focused analysis reported no issues (`/tmp/tame-dashboard-ownership-final-analysis.log`).
The new test is registered in the reusable editors suite. Initial test fixture
errors and a stopped waiting run were not passes; native-clock-aware completion
and single-disposal cleanup corrected the fixture. Existing conversion tests emit
Drift's multiple-database warning during their competing-session checks.

This is not full migration acceptance: the new direct race test covers Dashboard
job creation, not every estimate/invoice/attention callback. Full editor/core
regression, parallel Materials integration, remaining recovery/configuration
questions, and current physical-device lifecycle verification remain open as
recorded above. Maintainiac 5.7 and the other model's Materials files were untouched.

## Current verification continuation

Started the full editors manifest after the Dashboard ownership correction;
runner output is `/tmp/tame-storage-editors-current.log` (retrieve the final report,
not intermediate counters). No tested source files changed during this run.
Read-only inspection confirms `openExpenseEntryFlow` can throw before its route
opens if storage is missing, owner identity changes, or setup initialization
fails. The ordinary Expenses and Expenses Day callers do not catch these opening
failures. This remains an error-reporting gap to fix/test; it is not evidence of
a lost committed record. Recovery ownership validation must remain intact.

ADB currently exposes duplicate mDNS aliases for two physical phones. Transport 4
responded with `SM-S938U`; no phone test was launched in this continuation.
The existing Android restore runner prebuilds and verifies the separate
`com.maintainiac.ui_lab_2_1.storageqa` package, uses `--no-uninstall`, and exercises
temporary-directory restore/rollback fixtures. Its tests explicitly configure a
fixture authorization callback; they do not prove production account enforcement,
normal settings restore integration, or abrupt OS termination. Normal app package
is `com.tameyourbiz.app`. Use the isolated runner for subsequent physical-device
verification after the host regression, and keep results distinct from OS-kill
and owner visual acceptance.

## Green editor gate and expense opening failures

`build/storage_qa/20260917T024446Z-6c0a5606/report.json`: all 144 tests passed
across 78 editor files, zero failures/skips/missing/unfinished tests, source
unchanged, 368.634 seconds. This closes the prior full-editor gallery failure
at this snapshot; it is not a whole-application or physical-device acceptance.

Subsequent bounded correction: expense-entry preparation now reports a plain
failure message on the originating screen if the storage/owner check or draft
initialization fails. It does not open a service-free form, bypass ownership,
consume saved input, or catch/pretend successful domain confirmation.
`expense_entry_open_failure_test.dart` exercises missing storage and an actual
SQLite read failure (temporary table rename in a disposable fixture), verifies
raw existing input and its revision are retained, and successfully retries after
the table is restored. The test uses existing test-only owner permissions.
It is registered in the editors manifest. Two new tests plus existing setup Back
and responsive choice tests passed: 11 total in
`/tmp/tame-expense-open-regression.log`; focused analysis clean in
`/tmp/tame-expense-open-final-analysis.log`. This change occurred after the green
full-editor gate, so the full gate is not claimed to include it.

Started the existing isolated Android restore runner against the verified
SM-S938U wireless device. Output: `/tmp/tame-android-restore-current.log`.
Pending at this checkpoint: build/install/runtime result, and task-owned Android
build worker cleanup after confirming no active build remains. Do not infer a
pass from launch or this start record. Normal app data and protected 5.7 were not
changed by this task. OS-kill verification remains a separate gate.

## Device target correction and first runtime result

Owner explicitly directs physical testing to the S24 Ultra, not the S25 Ultra
(the owner is using the S25). S24 transport 1276 returned `SM-S928U`.
Do not issue further test/launch/stop commands to the S25.

The first isolated Android restore run built and verified the QA package, installed,
and passed the success case. It then ended with the remaining three cases and
teardown not completed, plus a Flutter temporary-listener cleanup error. Log:
`/tmp/tame-android-restore-current.log`. This is a failed/incomplete overall run;
the available output does not establish the cause of the interruption.

The same isolated runner has now started on the S24 mDNS serial
`adb-R5CX14WC8FA-Mgu1lZ._adb-tls-connect._tcp`, output `/tmp/tame-s24-restore.log`.
It uses synthetic identities and temporary data; it is not production Firebase
account enforcement, normal Settings restore UI acceptance, physical camera use,
or abrupt OS-kill testing. Retrieve the final result and clean up idle task-owned
Android build workers afterward, preserving unrelated work and both normal apps.
