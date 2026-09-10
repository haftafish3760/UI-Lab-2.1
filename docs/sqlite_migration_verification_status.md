# SQLite migration verification status

Observed 2026-09-09 in UI Lab 2.1. This is a completion audit, not owner acceptance
or a production-readiness certificate. The owning policy remains
[data/storage contract](data_storage_sync_contract.md). Inventory integration from
Maintainiac 5.7 Active is authorized as the next stage only after the local
migration passes its completion audit; that reference remains read-only.

| Requirement | Current evidence | Remaining limit |
|---|---|---|
| Diagnose Firebase errors first | `analysis_options.yaml` excludes vendored `node_modules`; `pubspec.yaml` has Drift/SQLite and no Firebase SDK. Earlier analyzer diagnosis is recorded in the owning contract. | No Firebase project, credentials, deployment or billing protection has been configured. |
| SQLite with Drift as the local store | `open_ui_lab_application.dart` opens `LocalPersistence`, then Work, directory, workday, notes and preferences. `local_database.dart` enables WAL/FULL/foreign keys and verifies integrity. | Domain snapshots still use versioned JSON records in parts of the schema; typed query/index evolution remains work. |
| Save unfinished input automatically | Native regressions cover expense/correction/receipt, recurring payment, Work editors, nested estimate items, signature, delivery, company review, directory, workday and day-note recovery. | Selected tests do not prove every interaction or device interruption. Raw input not yet acknowledged by SQLite cannot be promised recoverable. |
| Keep drafts on leaving; discard explicitly | Shared `DraftNavigationGuard` and each editor's discard/confirmation handlers. Native restart tests exercise retention and atomic consumption. | A unified recovery list for drafts whose parent workflow closed or changed is not implemented. |
| Confirmed records and audit history agree | Work CAS commands and receipt/recurring prepared transactions; injected failures test rollback; Work status history restores scoped events. | Production role revocation and all export/sync permission boundaries are not established by development grants. |
| Preserve UI flexibility | DraftRepository/SavedDraft remove concrete draft-store construction and generated Drift rows from screens/shared/shell. Work models now live under data/work/models; compatibility exports retain existing callers. Typed draft controllers own editor serialization and confirmation; no screen/shared/shell constructs a draft session or transaction checkpoint. Generic autosave delegates media transactions to Work. | Estimate photo/note input and media recovery now use typed workflow boundaries. Global recovery discovery and unsupported/orphan input handling remain unfinished. Presentation preferences and prototype projection boundaries need further assessment. This is not complete UI decoupling or owner UI/UX acceptance. |
| Reusable/shareable test harness | `tooling/storage_qa/run_storage_qa.py` supports named suites and full `--all` discovery, records exact test inventory and source fingerprints, and distinguishes terminal protocol failure from missing completion. Fifteen runner and Android capture helper unit checks passed. | Latest full run: 791 passed, 6 failed across 230 files; all 304 selected storage tests pass within that run. Six original failures remain unresolved. Neither a selected nor full discovered run proves all product requirements. |
| Safe failure opening storage | Startup progress/retry UI, partial-load cleanup and no automatic reset. Internal SQL snapshot capture, verified attachment bundles and restore staging have native tests. | Retry does not repair corruption. Live restore activation, relocated attachment paths and a user-facing restore flow remain unfinished. Version 1 refuses unknown upgrades; future schema versions need explicit migrations. |
| Security first | Scoped records/drafts, CAS, no remote uploads authorized by local outbox, raw exceptions omitted from startup UI. | SQLite encryption/key lifecycle, production authentication/authorization and independent security validation remain unfinished. |
| Optional cloud backup/sync for release one | Requirement retained in owning contract; local journal state is `local` by default. | No functioning cloud adapter, user configuration, conflict policy implementation, restore flow or backend cost-abuse controls. These cannot be represented as delivered. |
| Supported platforms | macOS debug/Android APK builds and host tests passed; an earlier unsigned iOS device build passed. Android 15 emulator checks verify acknowledged employee recovery at wide width and expense recovery at phone width, including exact partial amount text and one confirmation. See `android_storage_recovery_qa.md`. | These checks do not prove physical power loss, unacknowledged input, every workflow, older Android, iOS runtime or Windows. The emulator is shut down. |

### Latest combined editor checkpoint

`20260910T104701Z-97595caf` passes 125 editor tests across 69 files in
295 seconds, with unchanged source and zero failures. This covers the registered
editor suite, not all discovered tests, device QA or owner visual acceptance.
See the remaining-work audit for still-open completion gates and separate source
checkpoints; the migration is not complete.

### Latest core/domain checkpoint — global recovery integration

`20260910T104358Z-24bda824` passes 307 tests across 102 files (109 core,
198 domain), with unchanged source and zero failures. This remains host regression
proof, not full-suite, all-workflow, device or migration completion. See the
remaining-work audit for the separately verified global recovery interaction tests
and current restore, stock consistency, security and platform gaps.

### Previous selected checkpoint — settings recovery routes

`20260910T102113Z-2e74aac2` passed 306 core/domain checks across 102 files
(108 core, 198 domain), with unchanged source. Fourteen settings route checks and
nineteen focused settings persistence/handoff/boundary/size checks also passed.
Analysis is clean and the Android debug APK builds. All seven settings contexts
accept typed recovered workflows; controller validation rejects replaced repositories
and wrong workflow identities. Normal Back retains edits without applying preferences.
No schema or visual layout change was required. Detailed limits and remaining work
are tracked in `sqlite_remaining_work_audit.md`.

Global Saved work UI is now wired into System settings; cross-domain menu-to-editor
and device validation remain outstanding. Job materials recovery routing now
has focused verification recorded in the remaining-work audit. Atomic stock
confirmation remains unresolved;
full completion, runtime/platform, restore and production-security gates remain open.
These checks do not replace a current full-suite run or device validation.

### Previous selected checkpoint — recovery services and session lifetime

`20260910T090859Z-03f87b12` passed 301 core/domain checks across 100 files
(103 core, 198 domain), with unchanged source. Analysis and Android debug build
passed with matching source/APK evidence. Three focused host/hub/size checks also
passed, including native-backed widget verification that layout rebuilds preserve
selection identity while session replacement/unmount retire the old recovery hub.
Expense, recurring and receipt catalogs are now included. Application composition
requires eleven providers; transient previews lacking durable sessions expose no
hub. Development permissions remain explicit, not production authentication.

Global-settings recovery UI and route dispatch are not yet delivered. Conflict
resolution, full regression/runtime/platform/security/restore and earlier completion
gates remain unfinished; inventory has not started. No visual-layout/schema change.

### Previous selected checkpoint — preference recovery catalog

`20260910T084729Z-ecd6fdab` passed all 291 core/domain checks across 94 files
(102 core, 189 domain), with unchanged source. Thirty-four focused, settings-editor
and architecture/size checks passed, along with clean analysis and Android debug
build (13.3 seconds); matching source/APK evidence is retained. Preference recovery
now discovers all seven canonical settings drafts through typed workflow factories.
Fresh repository reads detect confirmed-value conflicts despite stale controller
caches. Discovery/resume preserve legacy input, unknown or malformed drafts remain
listed without application, and explicit discard uses the existing revision guard.
No schema or visual layout changes; no current runtime/visual acceptance.

Expense/receipt registration, combined recovery UI, explicit conflict resolution,
restore/platform/security and full completion gates remain open. Inventory has not
started; Maintainiac 5.7 Active remains read-only.

### Previous selected checkpoint — persistent preference baselines

`20260910T083754Z-07693dc4` passed all 288 core/domain checks across 93 files,
with unchanged source. Thirty-six focused and seven settings-editor checks, clean
analysis and Android build passed with matching source/APK evidence. Drafts retain
only their owning confirmed preference keys; confirmation compares current values
inside the write/consume transaction. Conflicting direct writes and stale caches
preserve input instead of overwriting newer settings; unrelated changes survive.
Legacy input retains field compatibility, but changes before its first captured
baseline cannot be detected historically. No schema or visual layout changed;
the draft payload has an additive baseline field. No current runtime acceptance.

Preference registration/conflict review, expense/receipt recovery, global recovery,
restore/platform/security and completion gates remain open. Inventory has not
started, and 5.7 remains untouched.

### Previous selected checkpoint — preference selected-recovery guards

`20260910T083035Z-03a77208` passed all 285 core/domain checks across 92 files,
with unchanged source. Twenty-five focused checks, clean analysis and Android
build passed with matching source/APK evidence. All seven settings drafts now
verify selected domain/ID/revision before seeding, preserve reopened input, and
refuse consumed or wrong-context selections without recreation. Existing normal
opening and codecs remain compatible. No schema or visual layout changed; no
current device/runtime acceptance is claimed.

Preference catalog registration and concurrent direct-write safeguards remain
unfinished, as do expense/receipt registration, global recovery integration and
the original completion gates. Inventory has not started; 5.7 stays untouched.

### Previous selected checkpoint — exact mileage confirmation

`20260910T082619Z-84f1ead8` passed all 278 core/domain checks across 91 files,
with unchanged source. Twenty-four focused checks, clean analysis and Android debug
build passed with matching source/APK evidence. Shared domain mileage conversion
now uses exact integer tenths, rejecting excess precision, malformed grouping and
exponent syntax instead of rounding. Start/end controllers and presentation
validation agree; vehicle confirmation reuses the parser. Existing workday
whole-mile trailing-decimal compatibility and raw saved input are preserved.
No schema or visual layout changed; no current device/runtime acceptance is claimed.

Preference/expense/receipt registrations, global recovery integration,
restore/platform/security and completion validation remain unfinished. Inventory
has not started; 5.7 remains untouched.

### Previous selected checkpoint — workday/day-note recovery and mileage-query correction

`20260910T082110Z-3cfdba63` passed all 275 core/domain checks across 90 files,
with unchanged source. Twenty-eight focused/editor checks, clean analysis and
Android debug build passed with matching source/APK evidence. Start/end/day-note
recovery preserves workflow context and rejects consumed selections, occupied start
context, ended parents and already-published note identities. The preceding
odometer revision reader had a wrong ownership filter; this is corrected, with a
strengthened test proving initial recoverability before later mileage conflict.
The prior passing test alone had not proved that initial state. No schema or visual
layout changed, and no current device/runtime acceptance is claimed.

Workday mileage's existing floating-point/rounding conversion needs correction;
preference/expense/receipt registrations, global recovery, restore/platform/security
and completion validation remain open. Inventory has not started; 5.7 is untouched.

### Previous selected checkpoint — directory recovery registration

`20260910T081314Z-34e1e8a9` passed all 271 core/domain checks across 88 files,
with unchanged source. Thirty-four focused checks, clean analysis and Android
debug build passed with matching source/APK evidence. Company/client/employee/
vehicle recovery returns domain controllers and verifies exact selected revisions.
Scoped fresh profile/mileage reads detect changes independently of the editor
cache; conflicts, unavailable parents and malformed input remain preserved.
Connected directory editor and boundary checks passed. No schema or visual layout
changed; no current device/runtime acceptance or full-suite rerun is claimed.

Workday/day-note, preferences, expense/receipt registrations and global recovery
integration remain unfinished, along with restore/platform/security and completion
gates. Inventory has not started; protected 5.7 remains read-only.

### Previous selected checkpoint — directory confirmation derives from saved input

`20260910T080522Z-d52d4bd0` passed all 267 core/domain checks across 87 files,
with unchanged source. Twenty-three focused checks, including affected connected
directory editors, architecture/source-size checks, clean analysis and Android
debug build passed with matching source/APK evidence. Company/employee/vehicle
controllers now derive confirmed profiles (and vehicle mileage) from their saved
input inside guarded confirmation; screens receive the committed result rather
than supplying an independent profile. Existing conversion rules/messages and
company base fields are preserved. No schema or visual layout changed.

This resolves the independent directory-profile confirmation finding below.
Directory/general recovery registration and integration remain unfinished, along
with restore/platform/security and the original completion gates. No current
runtime/visual acceptance is claimed; this selected run does not replace the
historical full-suite result. Inventory has not started and 5.7 stays untouched.

### Previous selected checkpoint — job-action and payment recovery registration

`20260910T075859Z-775a6e38` passed all 264 core/domain checks across 86 files,
with unchanged source. Twenty-eight focused checks plus six affected editor
regressions, clean analysis and Android debug build passed with matching source/APK
evidence. Notes/schedule/assignment/materials and invoice-payment recovery now
return existing typed controllers and reject missing/changed selected revisions.
Changed job bases and already-recorded payment identities remain retained conflicts.
The preceding checkpoint remains the latest complete 65-editor selected run; this
source reran the six affected editor cases. No schema or visual layout changed.
No current runtime/visual acceptance or migration completion is claimed.

Directory inspection found confirmed-profile conversion still occurs in screens:
company/employee/vehicle controllers accept independently supplied profiles after
only presence/identity checks. Domain conversion/validation must be corrected
before general directory recovery. Other-domain registration, global recovery UI,
restore/platform/security and the original completion gates remain unfinished.
The prototype job-to-stock update remains non-atomic and is an inventory-stage
gap; inventory migration has not started and 5.7 stays read-only.

### Previous selected checkpoint — estimate-action recovery registration

`20260910T074746Z-4d677a43` passed all 323 selected checks across 130 files
(102 core, 156 domain, 65 editor), with unchanged source. Seventeen focused
workflow/recovery checks, the source-size guard, clean analysis and Android debug
build passed, with matching source/APK evidence. Signature, delivery preparation,
items and both existing company-review decisions now resume through domain services
and the original controllers, preserving exact input and selected revisions.
Consumed selections cannot reseed; changed parents remain retained conflicts.
Company-review access is checked separately from ordinary Work editing. This is
development policy enforcement, not production authentication. No schema or visual
layout changed. Other workflow registrations, global recovery integration and the
broader migration gates remain open. This selected run does not replace the
historical full-suite result or establish current device/visual acceptance.

### Previous selected checkpoint — primary Work recovery registration

`20260910T073342Z-c7720ede` passed all 319 selected checks across 129 files
(102 core, 152 domain, 65 editor), with unchanged source. Twenty-seven focused
checks, clean analysis and Android debug build passed with matching fingerprint
and APK evidence. Primary estimate/invoice/job recovery now uses typed codecs,
current parent/revision checks and the existing workflow confirmation controllers.
Selected domain/ID/revision is verified before any factory can initialize fresh
input; explicit invoice selection cannot be redirected by legacy-ID preference.
Missing/stale parent input remains preserved, and hidden creators are excluded.
No schema or visual layout changes were made. These handlers use the existing
development Work authority; production identity/revocation is not established.
Secondary Work and other-domain handlers, global recovery UI and remaining
migration completion gates are unfinished. No current device/visual acceptance.

### Previous selected checkpoint — recovery catalog and missing selections

`20260910T072412Z-229884cc` passed all 250 final core/domain checks across
82 files (102 core, 148 domain), with unchanged source. Twenty-five focused
checks, clean analysis and Android debug build passed. The preceding catalog
run `20260910T071812Z-78e1fa5d` passed 313 selected checks including 65 editor
checks; that broader run preceded the two missing-selection guards.

A reusable owner/domain-scoped catalog provides recovery entries without raw
payloads, isolates unreadable input, rechecks handler access, and discards only
an unchanged selected revision. Existing per-workflow choosers reuse its query
isolation. Tests cover concurrent save during discard, failed discard/retry,
reopen, foreign scope and revoked synthetic policy. These callbacks do not
establish production accounts. Manual and recurring-plan explicit recovery now
refuses missing/consumed drafts instead of silently creating fresh input.
Combined domain registration, authorized resume actions and a global recovery
presentation remain unfinished. No schema or visual layout changed; no current
device/visual acceptance or full migration completion is claimed.

### Previous selected checkpoint — estimate photo workflow

`20260910T070657Z-8d4fb177` passed all 308 selected checks across 126 files:
97 core, 146 domain and 65 editor checks, with unchanged source. Twenty-four
focused checks and the updated nine-check boundary suite passed; analysis is
clean and Android debug build passed with matching source/APK evidence.
Photo order and unfinished notes use an immutable domain model with the legacy
codec. Estimate media launch/recovery/discard orchestration lives behind a
workflow service and selection read model; widgets do not handle stored requests,
raw photo payloads or saved-revision orchestration. Another estimate cannot
consume/discard this selection. Camera/file interruption and note reopen tests
passed. No schema or visual layout changed. Global recovery, failure/security
completion work and platform/device validation remain open. The preceding full
run below is historical evidence, not a full-suite run of this latest source.

### Previous full checkpoint — expense and receipt-review workflows

`20260910T065305Z-e5e60e52` completed all 230 discovered test files in
476.224 seconds: **791 passed, 6 failed**, no skipped/missing/unfinished tests,
and unchanged source. Failure-name comparison shows the same five Dashboard
expectations and one Inventory presentation expectation; no new failing names.
All 304 registered storage checks passed within the full run (96 core, 144 domain,
64 editor). Thirty-one focused checks, 15 harness unit checks, clean analysis and
Android debug build passed, with matching source and APK evidence.

Expense/correction and receipt-review workflows now own opening, recovery,
identity/revision validation, legacy codecs and guarded confirmation. The form
binds typed input. A source boundary regression rejects session/checkpoint
construction anywhere in screens/shared/shell. Existing payload keys remain
compatible, malformed receipt recovery is retained/discardable, and stale edits
cannot overwrite newer records. Shared validation rejects invalid money outside
widgets too. No schema or visual layout changes were made. Estimate photo/note
raw state and media orchestration remain the next boundary correction; broader
recovery/security/platform requirements remain open. This is not completion or
current device/visual acceptance.

### Previous selected checkpoint — expense nested-line input

`20260910T063635Z-67ca7a18` passed all 297 selected tests across 122 files:
95 core, 138 domain and 64 editor checks, with unchanged source. Sixteen focused
checks, clean analysis and Android debug build passed. Nested expense input now
uses typed domain models and legacy codecs, retaining partial values and edit/job
identities independently of widgets. Native new-line and detail-line recovery
checks are included in the reusable editor suite. The parent manual-expense and
receipt-review draft sessions still need workflow-owned opening/confirmation.
Broader recovery/security/platform completion work remains; no schema, visual
layout or current device acceptance is claimed.

### Previous selected checkpoint — receipt-evidence workflow

`20260910T062830Z-0b02d440` passed all 293 selected tests across 119 files:
95 core, 136 domain and 62 editor checks, with unchanged source. Sixteen focused
checks, clean analysis and Android debug build passed. ReceiptSubmissionSession
now owns evidence-draft opening, authorization, legacy recovery and atomic
confirmation through a typed controller. Malformed/stale input remains retained
and explicitly discardable. Evidence preview UI binds domain selections without
constructing draft sessions or transaction checkpoints. Two screen-created draft
paths remain, alongside broader recovery/security/platform completion work.
No schema, visual layout or current device acceptance is claimed.

### Previous selected checkpoint — receipt-evidence input model

`20260910T062221Z-0ba967ee` passed 229 core/domain tests across 75 files
(95 core, 134 domain), with unchanged source. Fifteen focused checks, clean
analysis and Android debug build passed. Durable evidence identity/order/selection/
undo state and actions now use a domain model with compatible serialization.
Receipt session opening/confirmation still need a workflow controller; three
screen-created draft paths and broader completion requirements remain. No schema,
layout, current device or visual acceptance is claimed.

### Previous selected checkpoint — recurring-plan draft workflow

`20260910T061344Z-62290ff4` passed all 289 selected tests across 117 files:
95 core, 132 domain and 62 editor checks, with unchanged source. Twelve focused
checks, clean analysis and Android debug build passed. Plan identity, input,
reminders, legacy recovery labels/codecs, monthly date adjustment and guarded
confirmation now belong to workflow models/controllers. Existing layout and
reminder behavior remain unchanged. Three screen-created draft paths remain,
alongside broader recovery/security/platform completion requirements. No current
device or visual acceptance is claimed.

### Previous selected checkpoint — scheduled-occurrence draft workflow

`20260910T060737Z-fd26e993` passed 225 core/domain tests across 73 files
(95 core, 130 domain), with unchanged source. Thirteen focused checks, clean
analysis and Android debug build passed. Occurrence input/recovery, stale-state
checks and atomic confirmation now belong to a workflow behind the recurring
controller. Tests preserve existing next-due-pointer and recurrence-rule behavior;
no layout or scheduling policy changed. Four screen-owned draft constructors and
broader recovery/security/platform requirements remain. No device or visual
acceptance is claimed.

### Previous selected checkpoint — scheduled-payment draft workflow

`20260910T060217Z-a49647fc` passed 223 core/domain tests across 72 files
(95 core, 128 domain), with unchanged source. Fourteen focused checks, clean
analysis and Android debug build passed. Scheduled-payment draft state,
serialization, revision checks and guarded confirmation now belong to the payment
workflow; its draft repository is injected at application composition. The existing
atomic expense/occurrence transaction and UI remain unchanged. Five screen-owned
draft constructors and broader recovery/security/platform requirements remain.
No current device or visual acceptance is claimed.

### Previous selected checkpoint — Job-materials workflow

`20260910T055400Z-1e553ca5` passed all 281 selected tests across 112 files:
95 core, 126 domain and 60 editor checks, with unchanged source. Thirty-three
focused checks, clean analysis and Android debug build passed. Job-material
recovery and atomic Job confirmation now belong to a controller; protected
procurement lines retain their domain type. Existing material permissions live
behind the data boundary, including stock-use enforcement without a screen.
Stock quantities still use the prototype adapter after Job commit; this is an
explicit non-atomic cross-domain gap for the authorized inventory migration.
Six expense/receipt screen-owned draft constructors and broader recovery/platform
requirements remain. No device or visual acceptance is claimed.

### Previous selected checkpoint — estimate-detail items workflow

`20260910T054755Z-c5c4d5c0` passed 218 core/domain tests across 70 files
(95 core, 123 domain), with unchanged source. Thirteen focused checks, clean
analysis and Android debug build passed. Estimate-detail item recovery and atomic
confirmation now belong to a workflow controller using acknowledged workspace
state. Existing revision/history and approval invalidation passed direct tests.
Seven screen-owned draft constructors and broader recovery/platform requirements
remain. No current device or visual acceptance is claimed.

### Previous selected checkpoint — nested item-workspace model

`20260910T054009Z-acf49d09` passed all 275 selected tests across 109 files:
95 core, 121 domain and 59 editor checks, with unchanged source. Twenty-four
focused checks, clean analysis and Android debug build passed. Nested editors and
main estimate/invoice/Job draft models now exchange typed workspace state with
legacy serialization behind the data boundary. Malformed nested input is retained
without rewrite. Estimate-detail and Job-material wrappers still need controller-
owned opening/confirmation; broader recovery/platform requirements remain active.
No current device or visual acceptance is claimed.

### Previous selected checkpoint — nested line-input model

`20260910T053253Z-631953f3` passed all 268 selected tests across 104 files:
95 core, 119 domain and 54 editor checks, with unchanged source. Sixteen focused
checks, clean analysis and Android debug build passed. Single-line raw input,
legacy serialization and confirmation rules now belong to a typed domain model.
Parent editors still adapt maps; their workspace models/confirmation are next.
Eight screen-owned draft sessions and broader recovery/platform work remain.
No device or visual acceptance is claimed.

### Previous selected checkpoint — estimate-signature workflow

`20260910T052829Z-f066800d` passed 212 core/domain tests across 67 files
(95 core, 117 domain), with unchanged source. Thirteen focused checks, clean
analysis and Android debug build passed. Normalized ink, raw name, acceptance,
recovery and atomic confirmation now belong to a workflow. The pad retains its
appearance and normalized coordinate adapter; no widget dimensions enter storage.
Eight screen-owned draft sessions, nested item input maps and broader recovery/
platform work remain. No current device or visual acceptance is claimed.

### Previous selected checkpoint — estimate-review workflow

`20260910T052410Z-e408d1fd` passed 210 core/domain tests across 66 files
(95 core, 115 domain), with unchanged source. Thirteen focused checks, clean
analysis and Android debug build passed. Review reason recovery, capability and
revision checks, first-attempt timestamp and atomic confirmation now belong to a
workflow; both return/rejection dialogs retain their appearance. Existing supplied
review capabilities are development grants, not production account enforcement.
Nine screen-owned draft sessions and broader recovery/platform work remain.

### Previous selected checkpoint — estimate-delivery workflow

`20260910T051624Z-4e7f77da` passed 207 core/domain tests across 65 files
(95 core, 112 domain), with unchanged source. Eleven focused checks, clean
analysis and Android debug build passed. Delivery recipients, review invalidation,
preparation time, recovery and confirmation now belong to a workflow. Preparation
still does not claim delivery. Ten screen parts still create draft sessions;
remaining editor, recovery and platform requirements keep migration active.

### Previous selected checkpoint — custom input-lock integration

`20260910T050535Z-5ab60152` passed all 259 selected tests across 100 files:
95 core, 110 domain and 54 connected-editor checks, with unchanged source and no
failed/skipped/incomplete tests. Nineteen focused checks, clean analysis and the
Android debug build passed. EditorInputLock now protects the shared navigation
guard, invoice editor, Job workspace, Estimate detail and pending receipt-source
actions from keyboard and pointer activation. No layouts or stored data changed.
Eleven remaining editor draft boundaries and recovery/platform gates keep the
migration active; this is not a full-suite or device-runtime acceptance claim.

### Previous selected checkpoint — shared keyboard confirmation safeguard

`20260910T045859Z-6ea3322e` passed all 257 selected tests across 98 files:
94 core, 110 domain and 53 connected-editor checks, with unchanged source and no
failed/skipped/incomplete tests. Fourteen focused checks, clean analysis and the
Android debug build passed. DraftNavigationGuard now excludes existing keyboard
focus as well as pointer input while busy/leaving. Failed operations restore
editing. Three custom Work pointer-only wrappers still require this safeguard;
other editor/recovery/platform gates remain. No device keyboard or full-suite
acceptance is claimed by these selected tests.

### Previous selected checkpoint — invoice-payment workflow

`20260910T045118Z-a1019829` passed 202 core/domain tests across 62 files
(92 core, 110 domain), with unchanged source. Fourteen focused checks, clean
analysis and the Android debug build passed. Payment raw input, identity, balance
validation and confirmation now belong to a workflow. Eleven screen parts still
construct draft sessions. Payment controls need an additional pending-confirmation
interaction guard; other editor/recovery/platform work remains. This is not a full
migration or runtime acceptance claim.

### Previous selected checkpoint — job-schedule workflow

`20260910T044402Z-309d995f` passed 200 core/domain tests across 61 files
(92 core, 108 domain), with unchanged source. Fifteen focused checks, clean
analysis and Android debug build passed. Rescheduling now delegates raw input,
validation and confirmation to its workflow, retaining old payloads and duration
rules. Twelve screen parts still construct autosave sessions; remaining editor,
recovery and platform work keeps migration active. No new full-suite or rendered
acceptance is claimed by this checkpoint.

### Previous selected checkpoint — expense settings workflow

`20260910T043703Z-1efeb177` passed all 249 selected tests across 94 files:
92 core, 105 domain and 52 connected-editor checks. Source fingerprints match,
with no failures/skips/incomplete tests. Twenty-one focused checks, clean analysis
and the Android debug build passed. Expense preferences and pending category/type
choices now use a typed workflow with finish-before-confirm validation. Settings
screens no longer own stored payload serialization or commit checkpoints. Thirteen
other screen parts still construct autosave sessions; recovery and platform gates
remain. The older 724/6 full-suite result is historical, not a new full-suite run.

### Previous selected checkpoint — report settings workflow

`20260910T043259Z-31c8650d` passed 195 core/domain tests across 59 files
(92 core, 103 domain), with unchanged source. Nineteen focused checks, clean
analysis and the Android debug build passed. Report settings now delegates typed
recovery and confirmation, retaining old payloads and unrelated preferences.
Fourteen screen parts still create autosave sessions; expense settings and other
editor boundaries, recovery safeguards and platform validation remain unfinished.

### Previous selected checkpoint — receipt and Work-list settings workflows

`20260910T042938Z-05b5b6a4` passed 193 core/domain tests across 58 files
(92 core, 101 domain), with unchanged source. Twenty focused checks, clean
analysis and the Android debug build passed. Typed settings workflows now own
receipt/list recovery and confirmation; preference models have no BuildContext
or screen dependency. Fifteen screen parts still construct draft sessions.
Broader recovery/platform gates remain and inventory has not started.

### Previous selected checkpoint — Work-display typed draft workflow

`20260910T042537Z-ede4051b` passed 190 core/domain tests across 57 files
(91 core, 99 domain), with unchanged source. Eighteen focused checks, clean
analysis and Android debug build passed. Work settings now delegates typed draft
opening/confirmation; the generic preference workflow owns checkpoint handling.
Legacy payload keys remain unchanged. Other settings/editor ownership, recovery
and platform gates remain; this does not establish migration completion.

### Previous selected checkpoint — preferences repository boundary

`20260910T042128Z-462b2918` passed 188 core/domain tests across 56 files
(91 core, 97 domain), with unchanged source. Twenty-four focused settings,
architecture and interface acknowledgment/retry checks passed, with clean
analysis and a successful Android debug build. The shared controller and app
injection now accept AppPreferencesRepository; screens use stable preference
keys without importing the concrete SQL store. Compatibility aliases and storage
transactions retain existing behavior. Settings workflow-owned payloads and
confirmation remain follow-up work. The preceding 238-test selected run and
older 724/6 full-suite run remain historical results, not rerun claims.

### Previous selected checkpoint — job-assignment workflow

`20260910T041548Z-9a7c4c94` passed 238 selected tests across 89 files:
89 core, 97 domain and 52 connected-editor checks, with no failures, skipped or
unfinished tests and unchanged source. Ten focused checks, clean analysis and
the Android debug build passed; matching APK/source evidence is beside the report.
The notes and assignment workflows now own their legacy codecs and confirmation.
Eighteen other screen/part files still create draft sessions. Preferences still
expose a concrete store through their controller. Those are remaining boundary
work, alongside recovery/restore and platform gates. No new full-suite or device
runtime acceptance is claimed; migration is still active and inventory is next.

### Previous selected checkpoint — job-notes workflow

`20260910T041300Z-4b023a09` passed 184 core/domain tests across 54 files
(89 core, 95 domain), with unchanged source. Ten focused tests, clean analysis
and the Android debug build passed. No new full-suite or runtime claim is made.

### Previous selected checkpoint — start-workday workflow

`20260910T040608Z-a5194724` passed 182 core/domain tests across 53 files
(89 core, 93 domain), with no failures or source changes. Twenty-one focused
checks, clean analysis and the Android debug build passed. Recovery and guarded
confirmation now belong to the start workflow; the screen binds typed input.
This is not a new full-suite or runtime result and does not complete migration.

### Previous selected checkpoint — end-workday workflow

`20260910T040013Z-ee3d843d` passed 180 core/domain tests across 52 files
(89 core, 91 domain), no failures/skips and unchanged source. Twenty focused
connected/repository/boundary and direct workflow tests passed. Analysis is clean
and Android debug build passed (existing pdfx KGP warning); build verification
records matching source and APK identity.

The end dialog delegates raw input, identity/revision recovery and guarded
confirmation. Workday read models and access types now have a domain definition
outside the SQLite repository. Tests prove rollback/reopen, stable timestamps,
invalid/decreasing-odometer protection and exact-command replay without duplicate
record/odometer revision changes. Workday start and wider migration requirements
remain unfinished; no new whole-app, device-runtime or visual acceptance claim.

### Previous selected checkpoint — day-note workflow

`20260910T035349Z-3eda3f0e` passed 178 core/domain tests across 51 files
(89 core, 89 domain), no failures/skips and unchanged source. Fifteen focused
repository/controller, connected Dashboard/Calendar and direct recovery checks
passed. Analysis is clean and Android debug build passed (existing pdfx KGP
warning); build verification records matching source and APK identity.

Day-note input, recovery context and confirmation now belong to a reusable
workflow. The dialog no longer imports SQLite repository types or constructs
draft checkpoints. Recovery preserves exact text, local date/time, stable IDs
and the first failed-confirmation timestamp; invalid contexts remain retained.
DayNoteAccess has a plain domain definition with compatibility export. Remaining
workday/nested/settings boundaries and wider completion gates remain unfinished.
No new whole-app, device-runtime or visual acceptance is claimed.

### Previous selected checkpoint — expense/receipt domain models

`20260910T034526Z-7e16c40a` passed 225 selected tests across 81 files
(89 core, 87 domain, 49 editor), no failures/skips and unchanged source. Forty-four
focused projection, itemization, SQLite, receipt and recurring-payment checks
passed. Analysis is clean and Android debug build passed (existing pdfx KGP
warning); build verification records matching source and APK identity.

Expense models and demo fixtures now belong to the data layer, while icons live
in a presentation extension. Twenty data imports use domain models directly;
compatibility exports preserve existing UI imports. Enum names/order and wire
fields are unchanged. A regression guard prevents expense/receipt data from
reintroducing screen-model dependencies or icon metadata. Remaining workflow
ownership and broader completion gates are unfinished; no new full-suite or
device-runtime/visual acceptance is claimed.

### Previous selected checkpoint — client workflow ownership

`20260910T034151Z-ced9e344` passed 175 core/domain tests across 50 files
(88 core, 87 domain), no failures/skips and unchanged source. Eighteen focused
workflow, connected editor/layout, compatibility and boundary tests passed.
Analysis is clean and Android debug build passed with the existing pdfx KGP
warning; build verification records matching source and APK identity.

Client opening, record construction and guarded confirmation now belong to the
directory workflow. Reopened drafts, failed edits, retry and stale-submit tests
retain extra locations, linked-record counts and raw unfinished contact data.
No visual/schema change. The 724/6 full result below predates this bundle;
affected editor tests were run directly. Remaining nested workflows, preference
interfaces and expense/receipt model ownership still require work.

### Latest full checkpoint — estimate workflow ownership

Estimate opening, access/identity checks, confirmation construction and guarded
transaction submission now belong to Work workflows. Existing revision rules
moved unchanged from the screen directory into the domain, with a compatibility
export. New tests prove reopened unfinished photo notes, failed-edit retention,
approval invalidation/history on retry, duplicate prevention and explicit saving
of incomplete estimates as drafts. Nineteen focused regression tests plus these
two direct tests passed; analysis is clean and Android debug build passed with
the existing pdfx KGP warning. Fifteen Python QA-harness self-tests also passed.

Full regression `20260910T032944Z-d555394e` completed: 724 passed, six failed
across 200 files, unchanged source, no skips or incomplete tests. Exact failure
names match `20260910T022954Z-69dc232b`; no new failing names. All 222 selected
storage checks pass within this full run (88 core, 85 domain, 49 editor).
`failure-comparison.json` and `build_verification.json` record the comparison,
APK identity and matching source. No schema/payload/visual change or
new device-runtime acceptance is claimed. Twenty-four remaining screen-owned
draft openings/checkpoint assembly sites and the broader recovery/platform/
security gates still prevent migration completion.

### Previous selected checkpoint — invoice workflow ownership

`20260910T032421Z-cdcc0559` passed 171 core/domain tests across 48 files
(88 core, 83 domain), no failures/skips and unchanged source. Thirteen focused
editor/recovery/compatibility/boundary tests and two direct workflow tests passed.
Analysis is clean and Android debug build passed (existing pdfx KGP warning);
build verification records the matching source fingerprint and APK identity.

Invoice opening, legacy edit-key handling, identity validation, record construction
and atomic confirmation now belong to domain services/controllers. Tests prove
reopened legacy recovery, failed-update retention, retry, stale-submit refusal,
metadata preservation and invalid raw money correction. Existing wire formats and
visual layouts remain unchanged. Other workflows and completion gates remain;
affected editors were tested directly, not a new whole-app or device runtime run.

### Previous selected checkpoint — job workflow ownership

`20260910T031830Z-0e630e94` passed 169 core/domain checks across 47 files
(88 core, 81 domain), no failures/skips and unchanged source. Seventeen focused
checks passed, including connected job editors, legacy compatibility, conversion
and new widget-independent failure/retry/reopen workflows. Analysis is clean and
Android debug build passed (existing pdfx KGP warning); build verification records
matching source and APK identity.

Job creation now uses service-owned draft opening, discovery access checks,
record construction/validation and guarded atomic confirmation. Screens no
longer construct WorkRecord, DraftAutosaveSession or LocalDraftCheckpoint for
this workflow. Stable source/draft keys and old payload values are preserved;
missing selected recovery fails without silently creating blank input. Other
editors/preferences and broader completion gates remain unfinished. The previous
214-test run predates this source; focused affected editors were tested directly.
No new whole-app, device-runtime or owner visual acceptance is claimed.

### Previous selected checkpoint — profile confirmation ownership

Company/employee/vehicle controllers now confirm through directory-bound commands.
Screens no longer construct revision checkpoints or perform draft flush/command
sequencing. Generic confirmation freezes edits, waits for queued writes, rejects
unacknowledged input and seals successful sessions against duplicate submission.
Failed commands retain input and permit retry. Domain transactions still own
atomic record/revision/journal/draft consumption; no schema or UI changes.

Twenty-six initial focused checks passed; a further reopened-database test proves
one confirmed employee, consumed draft and rejected stale second submission.
That test and nine related service/boundary checks passed. Analysis and Android
debug build passed (existing pdfx KGP warning). Selected regression
`20260910T030916Z-523c6317` passed 214 tests across 77 files (88 core, 77 domain,
49 editor), no failures/skips and unchanged source. `build_verification.json`
records APK identity and the matching post-build source fingerprint.
No current full-suite/device acceptance or completion claim is made.

### Previous selected checkpoint — directory-owned profile opening

`20260910T030453Z-39cd3219` passes 162 core/domain tests across 46 files
(86 core, 76 domain), no failures/skips and unchanged source. Nineteen focused
service, legacy compatibility, connected profile editor and size checks also
pass. Analysis is clean and Android debug build passed (existing pdfx KGP warning);
`build_verification.json` records APK identity and matching source.

Company/employee/vehicle screens request typed workflows through a directory
service instead of constructing autosave sessions or choosing persisted keys.
Opening enforces access, validates recovery and releases failed sessions while
retaining draft rows. Tests verify stable legacy identities, actor isolation and
retry without widgets; their permissions are synthetic, not production accounts.
Confirmation orchestration and other editor/preference boundaries remain.
The broader 207-test result below predates this bundle; affected editor tests
were run directly. No new whole-app/runtime/visual acceptance is claimed.

### Previous selected checkpoint — company/employee/vehicle controllers

`20260910T025754Z-64e49d2c` passes 207 selected storage tests across 76 files
(86 core, 72 domain, 49 editor), with no failures/skips and unchanged source.
Company, employee and vehicle raw draft serialization now lives in typed domain
controllers. Employee/vehicle identity and revision validation also moved out of
widgets. Nine new reopened-database compatibility/malformed-input cases preserve
version-one bytes and incomplete values; all 24 focused checks passed. Analysis
is clean and Android debug build passed with the existing pdfx KGP warning.
`build_verification.json` records matching source and APK identity. Opening,
confirmation and remaining preference/editor boundaries still require work.
The 697/6 full-suite result above predates this bundle; no new runtime or visual
acceptance, inventory integration, or migration completion is claimed.

### Previous selected checkpoint — job/client and recovery discovery

`20260910T024625Z-2c51abec` passes 198 selected storage tests across 75 files
(86 core, 63 domain, 49 editor), with clean analysis, no skips/failures and
unchanged source. Job and client typed controllers preserve version-one raw
input; job dates/times are domain values. All four main Work/directory recovery
choosers now receive label/identity read models from scoped queries, including
safe unreadable-draft entries. Discovery never rewrites stored input. Sixteen
focused compatibility, recovery, conversion and boundary checks also passed.
Android debug build passed with the existing pdfx KGP future-compatibility
warning; `build_verification.json` records APK identity and the matching post-build
fingerprint. The full-suite result in the preceding table is the
prior 697/6 baseline, not a new full run on this bundle. No visual UI or schema
change, inventory integration, or completion claim is made.

### Current boundary correction checkpoint — 2026-09-09 evening

The source now supplies `DraftRepository`/`SavedDraft` to draft-facing UI, rather
than database construction or generated rows. Work model declarations moved to
`data/work/models`, retaining source-compatible exports at former screen paths.
Estimate/invoice typed input controllers own serialization of the existing
version-one fields, including nested unfinished input. Generic autosave delegates
atomic input commits; estimate-specific request validation/consumption remains in
Work. Attachment retention also moved out of the estimate screen. No SQL schema,
wire names, enum values or visual layout changed in this correction.

New controller tests seed legacy payloads, reopen the actual SQLite file and
restore through controllers without widgets, preserving incomplete decimals and
nested input. A repository-only test verifies acknowledgement, rollback/retry and
stale-commit rejection without a database or native gateway. Source boundary
checks guard against concrete draft/Drift imports in screens/shared/shell and
presentation dependencies in Work data.

Selected run `20260910T022439Z-13aa3cb6` completed with 190 passes and five failures;
its source remained unchanged. One new boundary failure identified a misplaced
Dashboard projection; it was relocated without changing behavior. Four existing
job-action tests depended on the new event being among the first three visible
rows; assertions now check the durable event and expand the existing list. All
eight affected focused tests then passed and analysis is clean. The subsequent
full run `20260910T022954Z-69dc232b` completed with 697 passes and the same six
baseline UI failures across 194 files. All 195 selected storage tests pass within
that full log; no source change, skip, missing suite or new failing name occurred.
Android debug build succeeded with the existing pdfx KGP future-compatibility
warning. `boundary_validation_summary.json` records the APK hash and matching
post-build source fingerprint. This is build evidence, not new device/runtime
or visual acceptance. Historical 692/6 results below are the earlier baseline.

Remaining editor workflows still need typed state, recovery discovery/identity
and confirmation moved out of screens; preference and prototype presentation
boundaries remain transitional. This checkpoint does not finish the migration.

### Current unresolved gates

- Calendar Day settings still contain memory-only switches. Their advertised
  ordering behavior conflicts with the chronological-entry contract; the owner
  choice previously requested is pending. Saving a disconnected switch alone
  would not complete it.
- Raw input is recoverable within the connected routes. A unified recovery path
  for drafts whose source workflow/record is no longer reachable, conflict
  resolution, native gallery/document runtime validation and broader device
  coverage remain unfinished. Receipt and estimate camera recovery have bounded
  API 35 emulator evidence recorded below.
- Backup capture/validation/staging is internal evidence, not live restore or
  cloud backup. U02 in `application_decision_register.md` leaves provider
  allocation, identity, conflicts, retention, quota/entitlements, restore and
  deletion policy open. Do not invent those product decisions or portray demo
  permissions as production authentication.
- The six unresolved original test failures are five Dashboard presentation/
  navigation cases and one deferred Inventory presentation case. They remain
  visible in the baseline; they are not waived or permission to redesign the UI.
- The local SQLite implementation and bounded tests do not satisfy the entire
  release-security or device-support requirement. Completion remains unproven.

The chronological sections below retain historical checkpoints. Their older
counts and statements of pending work are superseded by this table and the
current remaining-work audit where newer evidence explicitly says so.

The expanded run `build/storage_qa/20260909T125812Z-220908a2/report.json`
passed 99 tests across 41 selected files: core 29 tests, domains 44, editors 26.
No failures/skips/missing selected suites were reported, and the source
fingerprint stayed unchanged. `flutter build apk --debug` then succeeded and
produced `build/app/outputs/flutter-apk/app-debug.apk`. Gradle reported a `pdfx`
Kotlin-plugin warning about future Flutter compatibility; it did not block this
build. No device installation, production deployment or cloud write occurred.
`flutter build ios --debug --no-codesign` also succeeded, producing
`build/ios/iphoneos/Runner.app`. The app was not signed or installed on a device.
Actual device interruption/recovery remains pending.

The unsupported-newer-schema regression now compares a raw read-only SQLite
snapshot before and after a rejected open: schema, user version, records,
revisions, command/outbox rows, drafts and metadata must all remain identical.
It passed with the native interruption/capacity tests. It proves safe refusal,
not a migration path to a future schema.

The file-backed database now checks its effective WAL and FULL synchronization
settings during opening and refuses a connection with weaker settings. Two native
regressions deliberately open an existing database with NORMAL synchronization or
DELETE journaling, verify refusal, and then recover the exact saved raw draft
through the normal connection. The combined durability/interruption suite passed
13 tests. This checks configuration enforcement and preservation after refusal;
it does not simulate physical power loss. SQLite documents the underlying
[WAL synchronization behavior](https://www.sqlite.org/pragma.html#pragma_synchronous).

Draft queue regressions additionally exercise a rejected intermediate write
followed by a successful newer raw-input checkpoint, and two simultaneously open
editors where stale save/retry/discard must preserve the newer committed draft.
Both tests close and reopen the native database to inspect the saved content.
They do not provide a conflict-resolution UI: the stale editor retains its input
in memory and reports failure, while the newer committed checkpoint remains safe.

The subsequent shared run `build/storage_qa/20260909T130913Z-537695a7/report.json`
passed 103 tests across the same 41 files (core 33, domains 44, editors 26),
with an unchanged source fingerprint. Analysis was clean. This run includes
the two durability-setting refusal tests and the two draft queue/conflict tests.

Internal SQL checkpoint slice: `local_database_snapshot.dart` now creates a
unique app-owned snapshot using SQLite `VACUUM INTO`, checks schema version,
full integrity and foreign keys on a read-only connection, flushes the output,
and returns its byte count and SHA-256 digest only after success. The live WAL
file must not be omitted by copying the main database alone. Tests compare
records, revision history, command journal, outbox, raw drafts and metadata;
subsequent live edits do not change the captured checkpoint. A capture attempted
inside a transaction fails, removes only its own staging directory, and preserves
both the live database and an earlier checkpoint. These two tests passed and
are included in the shared core suite.

Reuse assessment for this slice inspected 5.7's `cloud_backup_manifest.dart`,
`cloud_backup_service.dart`, `maintainiac_restore_contract.dart`, and the public
`maintainiac_durable_storage.dart` exports read-only. File hashes, explicit
privacy scope and corruption/conflict dispositions are useful design concepts;
the document/media/Firebase-specific types are not a drop-in SQL snapshot
implementation. No legacy code was copied or executed. Their runtime durability
and cloud restoration remain unverified by this inspection.

This is an internal SQL component, **not a complete backup/restore feature**.
It is not exposed as an export or uploaded. It contains all local database scopes
and is not a per-user permission-filtered cloud payload. It excludes attachment
bytes, and UI Lab receipt evidence still includes absolute device paths. Portable
restore must capture/validate those files and resolve their locations without
rewriting business history. Pending editor input must be drained by the future
coordinator. No backup schedule, retention policy, encryption, restore UI,
interrupted-checkpoint discovery, or directory-fsync guarantee is established.
SQLite documents the snapshot guarantees and interruption limits under
[VACUUM INTO](https://www.sqlite.org/lang_vacuum.html#vacuum_with_an_into_clause).

The next internal component, `local_snapshot_bundle.dart`, now captures files
registered by the snapshot's attachment and receipt evidence manifests. It reads
both current records and revision history from the captured SQL database, rather
than a newer live cache. Paths are derived from scoped attachment IDs or receipt
evidence IDs; source files must resolve to their registered app-owned location.
Each copied file must match its stored size and SHA-256 hash and is flushed
before a versioned completion manifest is published. Failed capture removes only
its own unique checkpoint directory; earlier checkpoints and live data remain.
The local manifest deliberately retains original device paths for future restore
mapping and is **not cloud-safe metadata** or a permission-filtered export.

Native tests exercised estimate attachment bytes, removed receipt PDF evidence,
source deletion after capture, and refusal of missing/changed files and a symlink
to matching bytes outside the registered location. Together with the SQL snapshot
tests, six tests passed; analysis was clean. The new bundle test is in the shared
core suite. This does not prove every feature registers its files correctly, nor
implement portable restore, encryption, user controls, scheduling, retention,
editor-write draining, crash discovery or physical-device power-loss recovery.

`verified_local_snapshot_bundle.dart` now reopens completed private checkpoints
without consulting the original media locations. It bounds manifest reads to
16 MiB, requires the supported manifest/database versions, verifies database
size/hash and SQL integrity, derives the attachment inventory again from SQL,
and requires exact agreement with the completion manifest. Copied file sizes,
hashes and resolved locations are checked; manifest paths do not choose arbitrary
files to read. The capture manifest now includes its original storage root for
local reference mapping. No external/cloud-safe format is claimed.

Eight native verification cases passed: relocated checkpoint after original
media removal, missing manifest, omitted file inventory, path traversal, changed
SQL bytes, changed media bytes, redirected media and unsupported SQL schema even
with a recomputed file hash. Together with capture tests, 14 tests passed; the
verification test is included in the shared core suite. Live file contents and
SQLite integrity were checked after rejected opens. Hashes detect damage but do
not authenticate an attacker-controlled package. This is verification at a point
in time; future restoration must stage a copy and verify it again before any
activation. No live-data replacement, encryption, restore authorization, user
controls or cloud transfer has been implemented by this component.

Checkpoint verification now also compares all application-defined SQL tables,
indexes, views and triggers with a fresh in-memory database created from the
app's generated Drift definitions (`local_snapshot_schema.dart`). SQLite internal
bookkeeping objects are excluded. This avoids accepting an altered structure
merely because `user_version` and file hashes match. Read-only inspection uses
`trusted_schema=OFF` and `query_only=ON`; schema comparison precedes full integrity
and attachment queries. Exact SQL definition matching is deliberately strict for
this version-one private format; future supported migrations need their own
validated schema transition.

Three new regressions modify a captured database with an injected trigger, an
extra table, or an added column, then recompute the manifest's database hash and
size. Verification must refuse each specifically for schema mismatch. All 17
snapshot/capture/verification tests passed; the 11 verification cases also passed
after strengthening the specific schema-error assertions. Analysis was clean. This is structural validation, not source
authentication, record-level authorization, or a complete restore workflow.
The underlying schema inventory is documented by
[SQLite's schema table reference](https://www.sqlite.org/schematab.html).

The subsequent full Flutter suite finished with 613 passed and 18 failed. Three
stale migration-test expectations were corrected and both affected files passed
all 24 tests on focused rerun. Fifteen other failures remain unresolved; see
[full-suite findings](sqlite_full_regression_findings.md) for the exact list and
retained logs. This supersedes any implication that selected-suite success proves
a green whole-app regression result.

A further focused rerun passed all 12 notification/layout-engine tests after
updating existing UI routes and making the static layout guard include declared
Dart parts. Three more original failures are resolved; 12 remain open. No
production UI was changed or accepted. See the full-suite findings for the
Dashboard header discrepancy and the preserved initial failed-run evidence.

A native regression reproduced an unverified-sidecar gap in checkpoint opening:
a valid WAL-mode main file and matching manifest were accepted, then a separate
writer committed metadata into WAL without changing the hashed main bytes.
Opening still succeeded. The initial capture format normally produces a standalone
file, but its verifier had not enforced that property for later opens. Evidence
is retained in `build/storage_qa/snapshot_sidecar_20260909/before.log`.

Verification now rejects nonempty WAL/rollback journals and redirected/non-file
SQLite sidecars before and after SQL inspection, and checks again before returning
the verified bundle. It never checkpoints or deletes those sidecars to make a
capture pass. Empty WAL and a regular derived shared-memory index remain allowed
for SQLite readers. The same reproduction now rejects the unhashed committed
changes for the specific sidecar reason, while ordinary capture/relocation tests
still pass. All 18 snapshot tests passed (`after.log`); analysis was clean.
This remains point-in-time checking, not protection against an actor concurrently
rewriting app-private storage. Staged restore must copy and reverify before
activation; authentication, encryption and live restore remain unfinished.

Restore staging now copies a previously verified private checkpoint into a new
`restore_candidates/candidate-*` directory beside the live database. It copies
only the named SQL file and registered attachments, checks copied bytes against
the previously verified digests, flushes them, and copies the exact reviewed
manifest last. The verifier now retains that manifest digest, so a newly changed
manifest cannot silently redefine the reviewed contents. SQLite sidecars are
checked before and after copying. The completed candidate is reverified before
being returned; errors remove only this invocation's unique candidate directory.

Four native staging regressions passed: reopening the candidate's captured raw
draft and photo while newer live input remains intact, and refusing a changed
source database, attachment, or manifest after verification. Failed candidates
are removed while source bytes and live drafts remain unchanged. The combined
snapshot/capture/verification/staging set passed all 22 tests, and the staging
file is included in the shared core suite.

This is an isolated restore candidate, not activated restoration. It has not
replaced live records, remapped absolute media references, closed/reloaded app
sessions, or provided a confirmation/recovery UI. Encryption/authentication,
permissions, atomic activation and rollback, and interrupted-activation recovery
remain outstanding. Merely opening the candidate as a writable database may
change its file hash; production activation must reverify before that transition.

The invoice workspace size guard is resolved by moving unchanged scoped queries
into a declared part (422-line entry, 99-line query part). Eight focused checks
passed; the broader invoice workspace rerun had 18 passed and the same existing
date-text assertion failed. Eleven original full-suite failures remain open.

Logical record-integrity validation is now shared by startup database opening
and checkpoint verification. A native reproduction changed a current record's
amount with valid SQL/JSON: SQLite quick-check remained `ok`, and the previous
validator accepted it despite disagreement with the recorded revision. That
before-fix evidence is retained alongside
`build/storage_qa/20260909T134829Z-5ad6b96b/report.json`.

`local_record_integrity.dart` now checks current payload/owner/version/time
against the current revision; requires a contiguous revision range from one
through the current revision; requires each command to have history and an
outbox entry; and verifies all historical payload digests in 256-row batches.
The caller holds a consistent read transaction, and hashing runs off the UI
isolate. Mismatches throw generic errors without rewriting records. The checks
are internal database validation, not an authorization-filtered user query.

Five new regressions cover current-record disagreement, altered historical
payload, a deleted revision, a missing journal row, and hash corruption beyond
the first 256-row batch. The expanded shared harness passed 130 tests across 46
files (core 60, domains 44, editors 26), with no failures/skips and an unchanged
source fingerprint during that run. A subsequent change only added braces to
satisfy analysis around the same throw statement.

This enforces the current unpruned history model. Future migration/compaction
must explicitly preserve or evolve that contract. It is not cryptographic
source authentication, full command-request-hash reconstruction, automatic
repair, or protection against an actor able to rewrite all local evidence. Large
production-history startup performance and actual-device interruption testing
remain unverified. The 11 outstanding full-suite UI findings are unaffected.

Employee directory coverage checkpoint (2026-09-09): found and replaced the
screen-local employee list with scoped SQLite records and raw employee editor
recovery. See the owning storage contract's employee directory checkpoint for
reuse assessment, behavior and limitations. Ten focused employee/domain/source
size/navigation checks passed; `flutter analyze` is clean and the macOS debug
build passed. This does not resolve the eleven previously recorded whole-suite
UI failures or establish production employee account permissions. Vehicle
profiles remain a known screen-local persistence gap.
The expanded shared harness `build/storage_qa/20260909T140349Z-afc5b064/report.json`
passed 135 tests across 48 selected files (60 core, 47 domain, 28 editor tests),
with no skips/failures/missing results and an unchanged source fingerprint.
Employee domain and editor regressions are now in the shareable suite manifest.

Vehicle directory checkpoint (2026-09-09): profile fields now persist in SQLite,
raw input resumes through the editor, and confirmed mileage shares the workday
odometer row and its revision. The owning storage contract records atomicity,
permission behavior, 5.7 read-only reuse assessment, and remaining selector/unit/
production-security limitations. The selected harness report
`build/storage_qa/20260909T141508Z-ee58e272/report.json` passed 141 tests across
50 files (60 core, 51 domain, 30 editor), with no failures/skips/missing results
and an unchanged source fingerprint during the run. Analysis is clean and the
macOS debug build passed.
After that harness checkpoint, the directory navigation test was updated for the
explicit miles label and to scroll to an off-screen employee menu destination.
Nine directory/source-size/navigation cases passed, preserving the large-text
reflow assertion. Ten failures from the earlier full-suite run remain unresolved;
the full suite was not rerun. No device installation or visual acceptance occurred.

Unchanged-confirmation correction (2026-09-09): native regressions reproduced
customer/company and Work saves acknowledging unchanged cached input after
another connection had updated the SQL record. Directory and Work confirmation
now check unchanged submitted records' scoped SQL revisions in the same
transaction as draft consumption. Current unchanged records can confirm without
an artificial business revision; stale records fail and keep their draft.
See the owning storage contract's concurrency correction checkpoint.

The shared harness `build/storage_qa/20260909T142304Z-9ce77e22/report.json`
passed 144 tests across 51 selected files (60 core, 54 domain, 30 editor), with
no skips/failures/missing results and an unchanged source fingerprint. Analysis
is clean and the macOS debug build passed. Reproduction logs and focused checks
are archived beside the report. Full conflict-review UI, remaining workflow
coverage, production security/cloud controls and ten earlier full-suite
regressions remain incomplete; this is not a completion or visual-acceptance claim.

Android runtime checkpoint (2026-09-09): the current APK built and installed on
one isolated Android 15/API 35 emulator. Exact employee name/partial phone/pay
input was observed with a local-save acknowledgment, then recovered after Home,
force-stop (PID absence verified), cold launch and reopening Add employee. Before
confirmation the directory still had three fixtures; after Save it had four.
After a second force-stop, a read-only copy of main/WAL/SHM contained exactly one
matching employee at revision 1, exact raw field values, zero employee-editor
drafts, and successful SQLite integrity checking.

Evidence and repeatable procedure: `android_storage_recovery_qa.md` and
`build/storage_qa/android_recovery_20260909/report.json`. This adds one real
Android runtime workflow to the host tests; it does not establish physical
power-loss behavior, phone layout, all workflows/Android versions, iOS/Windows,
production security or cloud functionality. No screenshots, AVD wipe, physical
phone installation, cloud operation or 5.7 modification occurred. The emulator
was shut down after the check. Production sources were unchanged in this
checkpoint, so the prior 144-test host result is not being presented as a new run.

Work home settings checkpoint (2026-09-09): the existing apply-after-Save behavior
is preserved. Unfinished switches/reset choices now use a device-owned SQLite
draft; Save atomically applies all three settings and consumes the exact draft.
Confirmed values are read from the shared preference controller after reopening.
Failed confirmation stays in the form; its retry is not exposed from unrelated
global appearance settings. Other screen-specific settings still need auditing.

The intermediate harness `build/storage_qa/20260909T144557Z-e466e165/report.json`
reported 146 passes and one Dashboard workday test failure. Investigation showed
a time-dependent preview assumption: after an additional fixture time passed,
the ended workday was beyond Today’s Entries' first-three preview. The test now
expands the existing entry list before asserting started/ended events, retaining
all source/odometer/draft assertions and changing no production Dashboard UI.
The corrected Work-settings/workday/preferences focused run passed ten tests.
The final shared harness `build/storage_qa/20260909T145056Z-3b3a56f6/report.json`
passed 147 tests across 52 selected files (62 core, 54 domain, 31 editor), with
no skips/failures/missing results and an unchanged source fingerprint. Analysis
is clean and the macOS debug build passed. Other settings, remaining workflow
integration, conflict-review UI, production security/cloud controls and ten
previously recorded full-suite regressions remain unfinished. The Android
runtime checkpoint above predates this Work-settings change and is not evidence
of its device behavior.

### Work list settings checkpoint — 2026-09-09

Jobs, Estimates, and Invoices now read independent confirmed SQLite display
preferences and preserve unfinished settings input. Explicit Save atomically
applies those choices and consumes the exact workspace draft. The new disk-backed
widget regression verifies interrupted input across database reopen, injected
metadata-write failure, retained draft, successful retry, and isolation from the
other two workspace preferences. Ten focused preference/settings tests passed.

Shared harness: `build/storage_qa/20260909T145946Z-a538814c/report.json`.
All 148 selected tests across 53 files passed (62 core, 54 domain, 32 editor),
with unchanged source fingerprint, no skips, failures, or missing results.
Analysis is clean and the macOS debug build passed; logs are archived beside
the report. This is not physical-device interruption or owner UI acceptance.
The ten previously recorded full-suite regressions, remaining workflow coverage,
production security and optional cloud backup/sync remain unfinished. Protected
5.7 Active was not changed.

### Reused draft identity checkpoint — 2026-09-09

A new native regression reproduced a shared-store defect: after consumption and
database reopen, a replacement draft reused revision 1, allowing the old revision
checkpoint to delete it. `LocalDraftStore` now retains monotonically increasing
revision markers for each scoped draft ID in the same SQLite transaction as
saving or consuming input. Legacy drafts initialize the marker at consumption.
Markers carry no draft payload. New tests cover stale consumption after reopen,
legacy revision continuity, failed draft insertion, and rollback of a surrounding
failed confirmation. Existing callers use the returned revision.

`build/storage_qa/20260909T150441Z-6b491a1f/report.json` passed all 150 selected
checks across 54 files: 64 core, 54 domain, 32 editor. Source fingerprint stayed
unchanged; no failures, skips, missing suites, or unfinished results. Clean
analysis and successful macOS debug build logs, plus the failing-before and
passing-focused evidence, are archived beside the report. This fixes an actual
stale-editor data-loss path; it does not establish full production security or
all-device interruption guarantees. Prior full-suite regressions remain open.

Continued settings inspection found receipt display choices still memory-only
and Calendar Day switches not connected to the day screen. These remain pending;
no behavior or presentation was invented for those controls in this checkpoint.
Protected 5.7 Active remains unchanged; inventory is deferred.

### Receipt display settings checkpoint — 2026-09-09

Receipt intake display preferences now persist in SQLite with a separately
recoverable unfinished-settings draft. Explicit Save applies both choices and
consumes the exact draft revision atomically; failures keep the previous active
preferences and draft. The intake screen reads confirmed settings on reopening.
The existing canConfigureDisplay action check and receipt confirmation semantics
are unchanged. No 5.7 files or cloud resources were changed.

The new disk-backed widget regression passed recovery after database reopen,
injected confirmation failure, retained raw choices, successful retry and draft
consumption. Twelve focused settings/expense UI checks passed, including the
existing visible effect on receipt intake. The receipt confirmation rollback
regression also passed. An initial new-test failure was a copied Work toggle
locator; correcting it to the actual receipt switch resolved that test setup.

`build/storage_qa/20260909T151039Z-08729161/report.json`: 151 selected checks
passed across 55 files (64 core, 54 domain, 33 editor); unchanged source
fingerprint, no skips, failures, missing suites or unfinished tests. Analysis is
clean; macOS debug build passed. Logs are archived beside the report. This is
host verification, not physical-device or owner UI acceptance. Calendar Day's
unconnected settings, prior full-suite regressions, and other outstanding
workflow/security/cloud requirements remain open; the overall goal is active.

### Full-scope audit checkpoint — 2026-09-09

The full Flutter suite was rerun: 652 passes and the same ten unresolved failures
in 6m23s. See `build/storage_qa/full_audit_20260909T152123Z/report.json` and
`sqlite_full_regression_findings.md`. `sqlite_remaining_work_audit.md` records
current source evidence for memory-only Expense and Report preferences, disconnected
Calendar Day settings, and the optional native-notification dependency before
SQLite startup. These are still open; no code implementation is claimed in this
audit checkpoint. Several apparent TextField gaps were verified to be fixture
fallbacks behind durable connected routes. The objective remains active.

### Notification startup isolation — 2026-09-09

Two new regressions reproduced native notification failure blocking SQLite open
and escaping the initial launch callback. Local bootstrap now opens independently
of native reminders. The reminder controller serializes launch payload retrieval,
contains platform failures, and preserves successful payload delivery. Its status
widget now displays failure before permission status is known and offers Retry
without requesting notification permission. Failure/retry labels have English,
Spanish and French localizations. Explicit Enable remains the permission action.

Sixteen focused startup/reminder/controller/delivery tests passed, including
SQLite draft reopen under a failed gateway, contained callback failure, visible
retry without permission request and successful one-time payload retrieval.
`build/storage_qa/20260909T152446Z-50ab2c73/report.json` passed 157 selected tests
across 57 files (70 core, 54 domain, 33 editor), with unchanged source fingerprint
and no skips/failures/missing results. Analysis is clean and macOS debug build
passed. Before/after/focused/build/analysis logs are archived beside the report.
These are injected platform-failure host tests, not device delivery certification.
The preceding full-suite baseline remains 652 passes/10 unresolved failures;
it was not rerun after this checkpoint. Expense/Report preferences and other
remaining-work audit items are still open. Protected 5.7 Active was not changed.

### Report settings recovery — 2026-09-09

Reports now reads confirmed SQLite display preferences, while unfinished choices
use their own revision-checked raw draft. Save applies all five choices and
consumes the draft atomically. Failed confirmation leaves previous values active
and keeps the draft. Back retains input; explicit discard removes it. Existing
report scope and accounting projections are unchanged. Six focused settings and
Reports checks passed, including native database reopen, injected metadata-write
failure and retry, plus existing report presentation/scope tests.

`build/storage_qa/20260909T152947Z-58909254/report.json` passed 158 selected tests
across 58 files (70 core, 54 domain, 34 editor), with unchanged source fingerprint
and no skips/failures/missing results. Analysis is clean and macOS debug build
passed; logs are archived beside the report. This is host verification, not
physical-device or owner visual acceptance. Expense settings, Calendar Day
settings and other audit requirements remain open. The last full-suite baseline
is still 652 passes and ten unresolved failures, not a newly green whole-app run.
Protected 5.7 Active and deferred inventory were not changed.

### Expense settings and nested selection recovery — 2026-09-09

Expense display choices now persist in validated SQLite preferences. Pending
category and receipt-type selections remain separate inside the raw settings
draft and survive Back and database reopen. Overall Save/Restore defaults cannot
silently apply or erase unreviewed nested selections. Use promotes them to the
unfinished parent, Cancel explicitly clears that selection, and overall Save
atomically applies settings and consumes the exact draft. Failed writes preserve
active values and input. The receipt-type summary now reflects current choices.

Fourteen focused checks passed, including recovery/failure/retry at 390 and 1400
logical pixels and the existing Expense-screen regressions. A native roundtrip
covers all supported category/receipt-type names and rejection of duplicates,
over-limit category selections, unknown categories and unknown receipt types.

An intermediate harness (`20260909T153822Z-fad20e41`) overlapped the final UI
feedback/test corrections; its changed source fingerprint invalidated the run,
and two new assertions encountered the earlier stale-message behavior. It is not
used as final verification. The fresh, unchanged-source harness
`build/storage_qa/20260909T154135Z-8b70f0e9/report.json` passed **161 tests across
59 files** (70 core, 54 domain, 37 editor), with no skips/failures/missing results.
Final analysis is clean and macOS debug build passed; logs are archived beside
the report. These are host/widget checks, not physical battery-loss proof or owner
visual acceptance. Calendar Day's disconnected settings and other audit gaps
remain open. The previous full-suite baseline remains 652 passes/ten failures.
Protected 5.7 Active and deferred inventory were not changed.

### Abrupt termination during draft replacement — 2026-09-09

An additional isolated child-process test commits a replacement draft, then is
killed with SIGKILL during a later consume/create transaction. Reopening SQLite
recovers the exact acknowledged raw input. Old revision checkpoints cannot write
or delete it; the uncommitted revision marker rolls back, and subsequent creation
continues at the expected newer revision. Only disposable harness data is used.

Six focused interruption/generation checks passed. The final core harness
`build/storage_qa/20260909T154843Z-a56f4656/report.json` passed 71 tests across
16 files with an unchanged source fingerprint, no skips/failures/missing results;
analysis is clean. Production code did not change in this checkpoint, so no new
platform build or full-suite rerun is claimed. This is host SIGKILL evidence, not
physical battery-loss certification. Calendar Day ordering remains pending an
owner choice: the unused completed-first switch conflicts with the working
blueprint's chronological-entry rule. No ordering or settings UI change was made
while awaiting that answer. The overall migration remains active.

### Receipt evidence identity/revision boundary — 2026-09-09

A native regression reproduced silent omission of an unknown retained evidence
ID. The controller now rejects unknown IDs, and review updates can supply their
expected lifecycle revision. Intake pins the revision it loaded/last saved,
checks it even for unchanged evidence, and passes it on update. A missing receipt
that previously had a saved identity cannot silently become a newly created one.
The regression also verifies that a stale order update cannot replace a newer
order, with saved revision/order checked after reopening SQLite.

Six focused receipt-controller/confirmation/boundary tests passed. The shared
harness `build/storage_qa/20260909T155336Z-f6aa28ae/report.json` passed 163 tests
across 60 files (71 core, 55 domain, 37 editor), unchanged source fingerprint and
no skips/failures/missing results. Analysis is clean and macOS debug build passed;
before/after/analysis/build logs are archived beside the report. This is a boundary
fix, not completion of receipt-review draft recovery: evidence ordering/removal/
undo still needs its own recoverable input and atomic confirmation workflow.
Calendar Day ordering awaits the owner's requested choice. The overall migration
and previous full-suite UI regressions remain open. Protected 5.7 was untouched.

### Receipt evidence-review draft recovery — 2026-09-09

Ordering, removal, selected evidence and the latest Undo action now persist as
an actor/receipt-scoped recovery draft. Restored identities are resolved against
the authorized receipt; paths are not accepted from raw input. Save/Continue
requires the original receipt revision and exact saved input, then atomically
updates evidence metadata and consumes the recovery draft. Original files remain
retained. Intake accepts the committed result without a second write. Stale or
malformed input is preserved behind explicit discard; conflict merging remains
unfinished. Back retains the unfinished review.

The native backend regression checks denied access, mismatched input, forced
transaction failure, retry, stale repeat confirmation, original bytes and database
reopen. Native widget tests reopen SQLite and restore removal/Undo, then inject
confirmation failure and retry through actual intake/review routes at 390 and
1400 logical pixels. Twelve focused receipt tests and the two-width run passed.
The shared harness `build/storage_qa/20260909T161402Z-10b829f1/report.json` passed
166 tests across 62 files (71 core, 56 domain, 39 editor), with unchanged source
fingerprint and no skips/failures/missing results. Analysis is clean and macOS
debug build passed. Logs are archived beside the report.

These are host SQLite/widget checks, not physical battery-loss, device-wide,
production-security or owner visual acceptance. Previous full-suite UI failures,
Calendar Day ordering, cloud backup/sync and release security work remain open.
Protected 5.7 Active was untouched; inventory remains deferred.

### Stale receipt review navigation — 2026-09-09

The recovery error/loading panel lacked a visible Back action. Two native widget
regressions reproduced the missing control at 390 and 1400 logical pixels.
The panel now offers Back to receipt through the existing draft navigation guard.
The tests verify that stale input cannot be confirmed, Back retains the exact raw
payload, reopening still exposes explicit discard, and discard consumes only the
input without changing the confirmed receipt revision. Both tests pass; analysis
is clean and macOS debug build passed. Evidence and source hashes are in
`build/storage_qa/evidence_stale_review_20260909/report.json`.

The previous 166-test shared-harness checkpoint predates this four-line UI change;
it was not rerun for this navigation-only addition. Host tests do not establish
owner visual acceptance or physical interruption guarantees. The wider migration
and release requirements remain open; protected 5.7 remains untouched.

## Full discovered-suite checkpoint — 2026-09-09

The reusable runner now accepts `--all`, discovers nested `*_test.dart` files,
records its complete test inventory, and rejects empty, duplicate or external
paths. It retains named suites as the default and disallows mixing both modes.
Five runner unit tests pass, including terminal failure versus absent completion.

`python3 tooling/storage_qa/run_storage_qa.py --all` completed in 420.965 seconds:
**665 passed, 10 failed**, 183 test files, no skips, missing suites or unfinished
results. Source fingerprints matched throughout execution. Evidence is
`build/storage_qa/20260909T162049Z-4ca4280c/report.json` and `all.jsonl`.
The ten failures match the previous baseline exactly: five Admin Dashboard cases,
Estimate workspace, Expenses colors, Expenses lane width, Inventory presentation,
and Invoice date/activity presentation. No additional failure was reported.

After completion, a reporting-only correction separates protocol termination
from protocol success: Flutter emitted a terminal `done` event with success false.
The original report is preserved; `protocol-recheck.json` records the corrected
parser's evaluation and the raw log hash. The runner unit tests cover that
separation. Production/test Dart stayed unchanged; the whole suite was not rerun
for this parser-only correction. The suite is still failing, and this result does
not establish complete workflow coverage, owner UI acceptance, device durability
or release security. Protected 5.7 was untouched; inventory remains deferred.

## Phone-width Expense recovery — 2026-09-09

The current debug APK was built and installed over the isolated emulator's
existing synthetic data. Only one Android 15/API 35 emulator ran, with 1536 MB
RAM and two cores. Display overrides were temporarily 1080×1920 at 420 dpi
(about 411 logical pixels wide), restored to 1260×768/160 dpi before shutdown.
No screenshot, physical-device install, data wipe, upload or 5.7 write occurred.

The exercised route was Expenses → Add expense → Record expense. Input used
vendor `QA-Android-Expense-1635`, total-only mode, amount `7.`, blank subtotal,
and tax `0.00`. The UI acknowledged local saving. Home and force-stop terminated
a verified live app PID without editor Back/Save. The stopped database contained
the exact raw input and no confirmed record for that vendor. After cold launch,
Record expense offered the named unfinished expense; selecting it restored the
vendor and incomplete amount exactly in the native accessibility tree.

Attempting Save with `7.` correctly displayed decimal validation and retained
the editor. Completing the text to `7.50` and saving returned to Expenses, whose
total increased from $308.22 to $315.72. After another force-stop, the copied
SQLite main/WAL/SHM set contained exactly one matching expense, revision 1,
750 cents, and no matching recovery draft. `PRAGMA integrity_check` returned
`ok`. The emulator process exited and `adb devices -l` was empty afterward.

Evidence: `build/storage_qa/android_expense_recovery_20260909/report.json`,
numbered UI XML files, interruption PID evidence, APK/build evidence and separate
before/after stopped database copies. The procedure follows the same safety and
copy rules above; use fresh UI bounds and a unique synthetic vendor on rerun.

This adds one acknowledged manual-expense interruption/confirmation path at
phone width. It does not establish physical battery/power-loss recovery,
unacknowledged keystroke durability, all workflows, other Android versions,
iOS/Windows, production security or owner visual acceptance.

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

### Receipt native capture and recovery connected — 2026-09-09

The SQLite application now creates one receipt media session and performs scoped
native recovery after mounting. Camera/library capture saves a receipt destination
before launching, then adopts returned originals atomically. Startup retains
recovered originals without silently changing receipt metadata. The original
receipt exposes Recover photos and an explicit Discard photo selection confirmation.
A failed native startup recovery leaves local navigation usable and can be retried.
Ordinary receipt editing does not wait on an empty startup media check.

Seven focused receipt regressions passed, including three app-path tests using a
fake native picker, real files and reopened SQLite. The selected storage harness
`build/storage_qa/20260909T172216Z-d3e72c92/report.json` passed 176 tests across 67
files (77 core, 57 domain, 42 editor), with unchanged source fingerprint and no
failures/skips/missing results. Analysis is clean and macOS debug build passed;
logs are archived with the report. Authored changed Dart files remain below 500
lines. This does not establish Android camera-active interruption recovery, visual
owner acceptance or a green whole-app suite. Estimate media integration, document
picker interruption and the other audited migration gaps remain unfinished.
Protected 5.7 was not modified.

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

Final source validation after the lint-only callback rename: core harness
`build/storage_qa/20260909T173243Z-c002347b/report.json` passed 78 tests across 20
files with unchanged source fingerprint, no failures/skips/missing results, and
clean analysis. Domain/editor validation and macOS build above precede only that
unused-parameter rename. Estimate picker wiring remains unfinished.

### Estimate and receipt shared native recovery connected — 2026-09-09

The app now owns a single native picker coordinator, with receipt and estimate
SQL-target authorization. Estimate camera/library capture persists its parent
input before launch; the photo screen can recover or explicitly discard the
saved selection. Adoption verifies retained originals, preserves existing order
and unfinished notes, and atomically updates only the raw estimate draft while
acknowledging the request. Work access/source revision is rechecked inside the
transaction. Receipt capture continues through the same coordinator. See the
owning contract's Shared picker and estimate recovery app connection section.

Ten focused tests passed. Selected harness
`build/storage_qa/20260909T174430Z-205835a1/report.json` passed 181 tests across 70
files (78 core, 59 domain, 44 editor), with unchanged source fingerprint and no
failures/skips/missing results. Analysis is clean and Android debug build passed;
logs are archived with the report. The build still reports the previously known
pdfx Kotlin migration warning. No device is currently attached (`adb devices -l`
returned an empty list). The APK was built but not installed or runtime-validated
in this checkpoint. Native Android camera-active process death, document-file
picker interruption and other remaining-work audit items remain outstanding.
5.7 Active remains read-only; no inventory integration occurred. Existing
whole-application regression findings are not superseded by this selected run.

### Android external-camera process-death recovery — 2026-09-09

Evidence: `build/storage_qa/android_native_media_recovery_20260909/report.json`,
numbered accessibility XML, three stopped-process SQLite/WAL/SHM sets, retained
original copies and an empty crash buffer. The APK/source identity matches selected
harness `20260909T174430Z-205835a1`. No app/test source changed during this runtime
check. One API 35 ARM64 ATD emulator was used; no screenshots were taken.

The receipt camera was launched through Expenses → Add expense → Add receipt →
Capture receipt photos. With com.android.camera2/CaptureActivity foreground,
`am kill com.maintainiac.ui_lab_2_1` removed app PID 1852. A stopped-process SQL
copy showed receipt `receipt-draft-1788976235868937` at revision 1 with no evidence
and the exact scoped pending request. The camera remained available. Capturing
and accepting its photo restarted Maintainiac as PID 2297. After another app
force-stop, SQL showed returned source metadata and one retained attachment.
Its 75,783 bytes matched SHA-256
`e6703c8e662e920c33dca3e2386643c362bceca2de7e01c201d281809d8395bc`.

After relaunch, the original receipt draft offered Recover photos. Selecting it
showed one photo for review. A third stopped-process SQL check verified receipt
revision 2 with exactly one active evidence item, matching original bytes/hash,
no pending picker request, unchanged confirmed Expense records and integrity_check
ok. Recovery did not create an Expense or submit the receipt. The emulator was
shut down; its original 1080x1920/420 overrides were unchanged, and adb subsequently
reported no attached device. No 5.7 changes occurred.

This proves the exercised receipt-camera interruption path on this emulator.
It does not prove physical power loss, unacknowledged callback durability,
estimate/gallery runtime parity, older-device coverage or production security.

### Reusable Android SQLite evidence capture — 2026-09-09

`tooling/storage_qa/capture_android_database.py` replaces ad hoc raw-file capture
for later device checks. It requires an explicit serial and new output directory,
refuses a running main/package-prefixed secondary process, captures existing main,
WAL, SHM and rollback sidecars, compares repeated reads, and validates schema,
integrity and foreign keys on a disposable copy. Raw bytes/hashes remain intact;
reports identify the script, host, target and bounded checks. The helper does not
stop/reset the app, mutate device files or upload evidence. It is a stopped-app
QA helper, not a live backup or proof of workflow completion.

Fifteen Python harness tests passed. A live API 35 ATD run refused capture while
Maintainiac was running; after an explicit operator force-stop, capture succeeded.
An independent read recovered the prior receipt at revision 2 with one image and
verified unchanged raw hashes. Final helper source (including the secondary-process
guard) was exercised again against the stopped emulator. Evidence is in
`build/storage_qa/android_capture_tool_20260909/validation.json` and its paired
capture reports/raw files. The emulator was shut down afterward. Android device
scenario documentation and the shared harness README describe reuse and limits.
No Dart/app behavior, Firebase configuration or protected 5.7 files changed in
this checkpoint. Existing migration/device/security boundaries remain open.

### Android estimate camera process-death recovery — 2026-09-09

Evidence: `build/storage_qa/android_estimate_camera_recovery_20260909/report.json`,
numbered accessibility XML and three stopped-app captures from the reusable
Android capture helper. The source fingerprint matches selected harness
`20260909T174430Z-205835a1`; no app/test source changed during this runtime check.
One API 35 ARM64 ATD emulator was used without screenshots.

Through Work → Estimates → New estimate, entered
`QA-Android-Estimate-Camera-1802` and raw discount `7.`. After opening Job-site
photos → Take photo, the external camera stayed foreground while `am kill`
removed Maintainiac PID 1791. The first capture proved estimate input
`estimate-input-15e5a6d2de9b277501fbd63d35144481` and its scoped picker request
both at revision 39, with the exact title/discount and empty photo editor.
Accepting the camera image restarted Maintainiac as PID 2431. A second app
force-stop/capture verified the retained 74,906-byte original and its hash.

Relaunch offered the same unfinished estimate by name. Its original photo screen
showed Recover photos; recovery displayed one photo, and Save photos and notes
returned it to the parent draft. The title and raw `7.` were visible after recovery.
The final stopped capture showed revision 41, one site photo, null nested photo
editor and no picker request. All other raw fields matched the pre-camera input
exactly. Every confirmed Work, Expense and Receipt record matched the initial
capture. Original bytes matched SHA-256
`b34be1a9bd8bdba2532d261feecf3546e8e7292686abdfa1382f729fc9f63442`.
All captures passed schema/integrity/foreign-key checks. The emulator shut down
and adb reported no attached devices. Protected 5.7 remained unchanged.

This proves the exercised estimate camera path on this emulator, complementing
the earlier receipt-camera check. Gallery/document selection, physical power loss,
older and physical devices, production security/cloud and owner visual acceptance
remain separate boundaries. It does not eliminate the native callback-to-SQL
acknowledgment window. The raw draft remains unfinished; no business estimate was
confirmed by this check.


### Document-file picker checkpoint — 2026-09-09

Receipt PDF/image-file and estimate image-file selection now save their destination
before launching the external picker. Missing returned results offer explicit
reselection into the same saved draft. Returned originals follow the verified
retention and atomic adoption path. File requests never retrieve the camera/gallery
lost-result cache. This preserves draft context without claiming automatic native
recovery of an unreturned document.

Selected harness `build/storage_qa/20260909T182553Z-41c7ef5b/report.json`
passed 185 tests across 70 files (core 78, domains 59, editors 48), with no failures,
skips, missing suites or source changes. Eleven focused receipt/estimate/coordinator
tests passed; `flutter analyze --no-pub` was clean and Android debug APK build
passed. Logs are beside that report. The build retains the known pdfx Kotlin
migration warning. No device installation or new native document/gallery runtime
check occurred in this checkpoint. Six previously recorded full-suite failures
remain unresolved; this selected run does not replace that baseline. Protected
5.7 was not modified, and inventory integration remains deferred.


### Receipt document-picker interruption check — 2026-09-09

Evidence: `build/storage_qa/android_document_recovery_20260909/report.json`,
three stopped-app SQLite captures, accessibility XML and retained synthetic PDF.
The APK comes from selected checkpoint `20260909T182553Z-41c7ef5b`; no production
source changed during this check. A new coordinator boundary regression also
passed with the two existing coordinator tests, and analysis was clean.

On one API 35 ARM64 ATD emulator at 1080×1920 / density 420, opened Expenses →
Add expense → Add receipt → Choose a receipt file. While Android DocumentsUI
remained foreground, `am kill` removed Maintainiac PID 1873. The first capture
proved a revision-1 receipt and matching files-source request. Choosing the PDF
restarted Maintainiac as PID 2261. The second stopped capture showed the same
request and records; the plugin had not durably returned the file to the app.

After relaunch, Receipt drafts → original receipt showed Unfinished file selection
and Choose file again. Reselecting the same Downloads PDF displayed one retained
item and cleared the pending notice. The final stopped capture proved revision 2,
one PDF, consumed request, preserved original receipt fields and unchanged
pre-existing unrelated records. Exactly one attachment manifest was added.
The retained 430-byte PDF matched the source byte-for-byte and SHA-256
`ea688b683d3ce01221aac808fe97b4030109e9529e5edcb8b28a5efc3efa6022`.
No expense was confirmed. The verifier accounts separately for that expected
new attachment manifest; it does not call all database rows unchanged.

This proves explicit receipt file reselection after process death for the exercised
Downloads provider and PDF. It does not prove automatic recovery of an unreturned
file, estimate file-picker runtime parity, gallery behavior, every provider/device
or physical power loss. No screenshots were taken. Protected 5.7 was unchanged.


### Exact native file paths — 2026-09-09

Fixed adapter trimming of platform-returned paths, which changed a valid local
filename ending with a space. The new adapter regression failed before the fix
and passed afterward with readable original bytes. Selection order, cancellation,
unavailable mixed selections and destination filters are covered in the same test
file, registered in the reusable core suite. Six focused tests passed; core run
`20260909T183912Z-223ef90b` passed 82 tests across 21 files with unchanged source.
Analysis and Android debug build passed (known pdfx Kotlin warning remains).
No new emulator run or full-app regression run occurred for this correction.


### Isolated draft-preview failures — 2026-09-09

Six editor recovery choosers now isolate unreadable preview rows, keeping them
visible and saved while allowing valid drafts and Start another. Selected-draft
validation remains strict. The estimate reopen regression verifies exact valid
raw input beside an unsupported-version draft, then explicitly discards only the
valid draft and confirms the unsupported row's ID, version and payload unchanged.
The other five affected editor regressions passed. Planned-expense recovery is
now also registered in the reusable selected editor suite.

Selected checkpoint `20260909T184353Z-05832843` passed 190 tests across 72 files:
core 82, domains 59, editors 49. Source remained unchanged, with no failures,
skips or missing suite files. Analysis and Android debug build passed; logs are
beside the report. The known pdfx Kotlin warning remains. No new device run or
owner visual acceptance is claimed. The broader app's six previously recorded
unresolved failures and unified recovery navigation remain separate open items.


### Refreshed full-app regression — 2026-09-09

Full discovered checkpoint `20260909T184816Z-aa9430a6` completed with
**692 passed, 6 failed across 192 files**, unchanged source and no skips or missing
protocol completions. The same five Dashboard and one Inventory cases remain;
no new failing names appeared. Four earlier focused corrections now pass in this
full run. See `sqlite_full_regression_findings.md` for exact evidence and limits.
This is a completed failing run, not whole-app acceptance or migration completion.


### Gallery interruption: retained draft and manual reselection — 2026-09-09

Evidence: `build/storage_qa/android_gallery_recovery_20260909/report.json`,
accessibility XML and four valid stopped-database captures. The first attempted
capture is preserved separately as refused: `am kill` left the app running while
Android PhotoPicker remained foreground. A subsequent run-as SIGKILL terminated
Maintainiac PID 1841 without closing the gallery. This differs from the earlier
camera background-reclamation check and must not be described as the same test.

The revision-1 receipt and library-source request were durable before termination.
Selecting the gallery PNG and Add returned Android to its ATD launcher rather than
delivering the result to Maintainiac. After relaunch, Recover photos reported no
returned files. The receipt and pending request were unchanged. Thus this run
DID NOT prove automatic gallery-image recovery; it exposed the undelivered-result
limit in this harsher interruption path.

The existing fallback was then exercised: explicitly discard only the pending
selection, whose dialog promises the saved receipt/evidence remain. A stopped
capture verified all records unchanged and only the picker request consumed.
After another relaunch, opening the original receipt and selecting the PNG again
produced exactly one retained image and revision 2. All other existing records
and the receipt's non-evidence fields were unchanged. One attachment manifest was
added. Retained image bytes matched the original 68-byte fixture and SHA-256
`6b1048f8a6d40bac0b2954c18fefa40c4ea7a96120fc2e54b7317c0e43c2bbec`.
No Expense was confirmed, no screenshots were taken, and 5.7 was not modified.

The report separates `fallback_verified: true` from
`automatic_image_recovery: false`. This is one API 35 ARM64 ATD/provider case,
not every device, gallery, interruption or physical battery-loss guarantee.
The APK came from selected checkpoint `20260909T184353Z-05832843`; no app source
changed during this runtime check. Estimate file/gallery runtime coverage and
broader provider/device coverage remain separate outstanding work.
