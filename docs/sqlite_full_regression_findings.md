# SQLite migration full-suite regression findings

## Current full-suite result — 2026-09-10 02:29 UTC (September 9 local)

Full discovered run `build/storage_qa/20260910T022954Z-69dc232b/report.json`
completed in 473.377 seconds: **697 passed, 6 failed across 194 files**. No tests
were skipped and no suites or terminal completions were missing. The source
fingerprint remained unchanged. This is a completed failing whole-app run.

`failure-comparison.json` compares the exact failing names with the prior
`20260909T184816Z-aa9430a6` baseline: no new failing names. The same five Admin
Dashboard expectations and one Inventory presentation expectation remain. No
unapproved visual UI was changed to satisfy them.

The full log includes all selected storage suites: **85 core, 61 domain and 49
editor tests passed (195 total), zero failures or skips in those suites**.
`boundary_validation_summary.json` records this subset, clean analysis, successful
Android debug build, APK hash and matching source fingerprint after the build.
The build retains the pdfx Kotlin Gradle Plugin future-compatibility warning.
No new device installation/runtime acceptance or migration completion is claimed.

The initial selected run for this refactor, `20260910T022439Z-13aa3cb6`, had five
failures. One new source-boundary test detected a Dashboard projection under
Work data; the projection was moved without changing behavior. Four job-action
tests assumed late-day events would appear in the collapsed first three rows;
tests now verify the committed event and use the existing Show all control.
Those corrections passed focused validation and this full run.

Prior full baseline: 692 passed, 6 failed across 192 files at
`20260909T184816Z-aa9430a6`. Its results remain historical evidence.

## Historical checkpoints

Observed 2026-09-09. The full Flutter suite ran with one worker and finished in
5m57s: **613 passed, 18 failed**, exit code 1. The checkout contains 166 test
files. Evidence is retained in
`build/storage_qa/full_regression_20260909/report.json`, `flutter-test.log`, and
`focused-corrections.log`. This is not a green whole-app result or visual
acceptance. No screenshot tool, device installation or 5.7 write occurred.

Three failures were stale migration-test expectations, corrected after the full
run completed. The estimate import test now resumes and explicitly finishes the
item retained by Back before importing another source. The Expense dependency
inventory now names the receipt confirmation part and removes the Dashboard
handler's former direct dependency. The platform-launch check follows the
retryable startup loader instead of expecting repository creation directly in
`main.dart`. The owning cutover map was updated. All 24 tests in the two affected
files passed on rerun. No production UI code changed in this correction.

| File | Test | Current status |
|---|---|---|
| `test/work_screen_test.dart` | estimate items import verified costs through review screens | focused rerun passed after test correction |
| `test/expenses_landing_hierarchy_test.dart` | Expenses keeps total at top and uses shared state colors | focused rerun passed after whole-card contract correction |
| `test/admin_dashboard_test.dart` | view selector lists Technician before Admin and changes view | unresolved |
| `test/admin_dashboard_test.dart` | Admin overview uses one bounded workspace for records and calendar | unresolved |
| `test/admin_dashboard_test.dart` | Admin overview preserves content at large system text scale | unresolved |
| `test/admin_dashboard_test.dart` | selected employee persists from Dashboard into Work | unresolved |
| `test/admin_dashboard_test.dart` | header controls stay bounded through breakpoint changes | unresolved |
| `test/invoice_workspace_test.dart` | Invoices use date activity, filing lanes, and separate rows | focused rerun passed after source-date assertion correction |
| `test/source_size_guard_test.dart` | authored Dart files stay at or below 500 lines | passed after cohesive invoice query extraction |
| `test/estimate_lifecycle_test.dart` | Estimate workspace starts with a date, compact records, drafts, and search | focused rerun passed through Business menu customer route |
| `test/dashboard_notifications_test.dart` | notification center remains separate from Dashboard attention | focused rerun passed with current route/library parts |
| `test/dashboard_notifications_test.dart` | Needs attention Show all remains its own exact-record queue | focused rerun passed with current route/library parts |
| `test/operations_layout_engine_test.dart` | top-level module sources retain one layout owner | focused rerun passed with current route/library parts |
| `test/expenses_layout_test.dart` | Expenses aligns three lanes and bounds its month calendar | focused rerun passed after inclusive boundary and Month/Week assertions |
| `test/company_directory_test.dart` | employee permission questions reflow for large text | focused rerun passed after scrolling to menu destination |
| `test/inventory_screen_test.dart` | Inventory uses the shared header and cost-first workspace | unresolved |
| `test/expense_atomic_cutover_map_contract_test.dart` | Expense prototype dependency inventory stays complete | focused rerun passed after test correction |
| `test/expense_atomic_cutover_map_contract_test.dart` | platform launch injects the private authorized Expense session | focused rerun passed after test correction |

The remaining 10 failures include missing Dashboard view-selector and Work/client
locators, header/date/color/width expectations, and other presentation expectations. The original invoice file-size failure is
resolved as recorded below. Their root causes
and relationship to earlier dirty UI work have not all been established. They
are not silently classified as pre-existing or waived. The full suite has not
been rerun after the focused corrections; only the stated focused result is
proven. The original SQLite/storage completion audit remains in
[verification status](sqlite_migration_verification_status.md).

A second focused correction addressed three more failures. Notification/attention
regressions now switch the existing global view through Work, return to Dashboard,
and use its current Needs attention summary control; they still assert the exact
owning records and separation from reminders. All 12 tests across notification
and layout-engine files passed. The layout source guard now checks declared Dart
parts in addition to the entry source, preserving the no-private-breakpoints
assertion across the whole library. No production UI changed.

Inspection confirmed that `dashboard_body_layout.dart` selects
`ownerPresentation: true`, whose header branch omits the Dashboard view selector.
The Dashboard-specific tests have not been redirected or marked passing. That
presentation/interaction discrepancy belongs to the still-unaccepted UI review;
this storage task has not silently restored or redesigned the control. The
remaining 12 original failures are still open, and no new full-suite result is
claimed. Analysis after the focused corrections is recorded separately.

The file-size guard now passes after extracting the invoice workspace's scoped
record/date/search/attention queries into `invoice_workspace_queries.dart`.
The query bodies were compared with the pre-edit tracked source and are unchanged.
The entry file is 422 lines; the part is 99. Eight focused size/persistence/payment
checks passed, and analysis was clean. The whole invoice workspace file was also
rerun: 18 passed, with the same full-date text expectation still failing as in the
original broad run. Thus 11 original failures remain open. No date presentation,
permissions or query behavior was changed to satisfy that unrelated assertion.

Vehicle-directory checkpoint: the large-text employee test attempted to tap its
menu destination at y=1006 outside the 900-LP viewport. It now scrolls that
destination into view before tapping and preserves the original question/Yes
vertical-reflow assertion. All nine directory/source-size/navigation checks
passed. This resolves one additional original failure, leaving ten unresolved.
The vehicle editor label expectation also includes the explicit miles unit.
No production layout was changed for these test corrections.

## Refreshed full-suite baseline — 2026-09-09

A fresh full run completed in 6m23s: **652 passed, 10 failed**, exit code 1.
Evidence: `build/storage_qa/full_audit_20260909T152123Z/report.json` and `flutter-test.log`.
It reproduced the same ten unresolved cases listed above: five Admin Dashboard
cases, Expenses state colors, Invoice date/activity presentation, Estimate
workspace presentation, Expense lane width, and Inventory presentation. No
additional failing test was reported. This supersedes the older full-suite count,
not the requirement to resolve the ten remaining failures. No production source
was edited during this run; no initial fingerprint was captured for this expanded
runner invocation. The selected storage harness retains its separate fingerprint
evidence. The new remaining-work audit identifies active preferences and startup
dependencies still requiring implementation; a broad test pass alone would not
prove those missing behaviors exist.

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

## Expense Entries color contract correction — 2026-09-09

The failing assertion read `Container.color` and expected the superseded semantic
header shade. The current shared heading paints through `BoxDecoration`; the
owning UI foundation rule requires the shared jade fill across header and body.
The test now checks the heading decoration and outer SectionCard against
`OperationalCardPalette.entries.start`, with no gradient on either wrapper/card.
Its existing date, hierarchy, attention, draft, permission-view and Plan checks
remain. No production UI or storage code changed.

The corrected Expenses test plus the shared light/dark Entries checks passed
(three tests), and analysis is clean. Evidence:
`build/storage_qa/expense_entries_contract_20260909/report.json`.
Nine original failures remain unresolved. The last full run remains 665 passed,
10 failed; it predates this focused correction and was not rerun for it.

## Work navigation/date contract corrections — 2026-09-09

The estimate workflow still targeted the removed `quick-customers` shortcut.
Operations blueprint's Work directory contract places Customers in the Business
menu. Its test now mounts the real app shell, selects Work/Admin, exercises the
existing estimate/calendar workflow, then opens Customers through the shared
menu. The same customer/estimate history and New estimate assertions remain.
The invoice test hard-coded September 1 while its demo record's issue date is
`today`. It now captures the source invoice issue date before navigation and
asserts the invoice detail's keyed date heading displays that localized full date.
No production navigation, UI, records or storage code changed.

All 19 estimate tests and 23 invoice/navigation tests passed (42 total), with
clean analysis. Evidence: `build/storage_qa/work_route_date_contract_20260909/report.json`.
Seven original failures remain: five Dashboard cases, Expenses calendar height,
and Inventory presentation. The last full-run count remains 665 passed/10 failed;
it predates these focused corrections. No new full-suite pass is claimed.

## Expense calendar boundary — 2026-09-09

The calendar's six 70-LP rows plus headers measure exactly 510 LP in the tested
workspace. The old strict `<510` assertion rejected that boundary. The test now
uses `<=510`, verifies all 42 month cells, switches to seven week cells and checks
that grid height falls by five rows (350 LP). Overall Week height must also be
smaller. The period header may reflow for the longer week label, as required by
the calendar accessibility contract; it is not incorrectly held to Month height.
No application geometry, calendar behavior, or storage code changed.

Eleven focused Expense/shared-layout tests passed; analysis is clean. Evidence:
`build/storage_qa/calendar_boundary_contract_20260909/report.json`.
Six original failures remain unresolved: five Dashboard cases and Inventory
presentation. The last full-run count remains 665 passed/10 failed and predates
the four subsequent focused test corrections. No full-suite pass is claimed.
