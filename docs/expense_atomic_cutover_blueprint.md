# Expense Atomic Cutover Blueprint

Status: engineering draft; not rendered owner acceptance.

This document inventories every current UI Lab 2.1 dependency on the prototype
Expense records and defines the one-source-of-truth cutover. It does not approve
the current visual design, migrate 5.7 data, or authorize OCR/parser migration.

## 1. Cutover invariant

The accepted Expense UI must never write through the authorized repository
while a list, total, detail, approval, Dashboard projection, report, Job picker,
or Materials picker still reads the same Expense aggregate from
`ExpensePrototypeStore`.

The cutover is complete only when:

1. every ordinary Expense is created, read, edited, approved, soft-deleted, and
   restored through `ExpenseUiRepositoryController`;
2. every count and total derives from the controller's authorized records or an
   authorized exact-money query;
3. every cross-module link resolves the stable Expense and line-item IDs through
   the same authorized session;
4. Dashboard, Calendar, Needs Attention, and Reports remain projections and do
   not save duplicate Expense values;
5. receipt evidence and recurring obligations use their own durable records and
   invoke an authorized Expense command only when they create or update an
   ordinary Expense; and
6. no screen imports a file repository or treats widget visibility as security.

### Current authorized read-projection checkpoint

`expense_ui_projection.dart` now defines the read model that the atomic cutover
will use. It is deliberately not a second ledger: each row carries the accepted
UI record together with the source record's exact minor-unit total, stable
employee, Job, vehicle, and category IDs, date and optional time, approval
state, lifecycle side, and revision. One authorized service query loads active
and soft-deleted rows into separate immutable lists; unauthorized records never
enter the projection and therefore cannot affect a local count or total.

The projection can filter by date range, stable employee ID, category, Job,
vehicle, approval state, vendor text, and recorded-total eligibility. Daily and
category totals add exact minor units and reject mixed currencies instead of
silently combining them. UI display labels remain presentation only. A saved
mutation refreshes this same projection record, and an ordinary UI edit
preserves an existing vehicle link and optional occurrence time.

This checkpoint is engineering infrastructure, not a screen cutover or rendered
acceptance. All visible Expense consumers remain on their current shared source
until section 4 can switch them in one operation.

The UI bridge now distinguishes an existing durable receipt link from a request
to create or replace receipt evidence. Approval, vendor, total, and confirmed
line-item edits preserve the existing receipt ID. Ordinary Expense commands
still reject any attempt to attach or remove receipt images. The separate
receipt-backed create command accepts only a stable, already-retained Receipt
Draft identity from the authorized Document Intake boundary; it never
manufactures evidence from a label or image count.

### App-level authorized session checkpoint

The platform entry point `lib/main.dart` uses the retryable startup shell and
`lib/src/startup/open_ui_lab_application.dart` to open `LocalPersistence` from
private Application Support/app data and inject one `ExpenseUiRepositoryController`
beneath the app shell. The UI Lab owner session uses a stable organization ID,
actor employee ID, permission revision, company read scope, and explicit
employee and Job label resolvers. File-repository recovery state is carried into
the controller instead of being discarded.

Widget tests that construct `UiLabApp` without a repository retain an explicit
in-memory fixture. The accepted platform launch always supplies the private
repository and binds its controller to the shared operations projection before
the Expense workspace is used. This preserves deterministic widget fixtures
without allowing a platform launch to mix durable writes into prototype reads.

`PrototypeOperationsStore` now accepts that controller as the ordinary Expense
projection provider. Once bound by the platform app, its Expense getter,
attention center, financial summary, report summary, Dashboard, Calendar, Job,
and Materials consumers all observe the same authorized immutable records.
The prototype Expense list remains only the explicit unbound widget-test/demo
fallback. Mutations are asynchronous and delegate to the authorized controller
when the binding exists.

Financial and report projections receive the controller's exact minor-unit
values keyed by stable Expense ID. The unbound demo fallback still rounds its
legacy UI values, but a bound platform session never reconstructs recorded
totals from display doubles.

The shared app shell now surfaces Expense repository failure on every module
instead of allowing an empty list or zero total to imply success. The banner
shows the controller's safe failure message and an awaited retry action. A
fallback to an older valid snapshot likewise remains visible until the user
dismisses the recovery notice.

Dashboard and Calendar day data no longer persist source-backed Expense rows.
`dashboardDay()` merges current authorized Expenses by stable source ID at read
time, preserves only harmless presentation hints such as an already-known time
label, and derives vendor, category, amount, Job link, submitter, and approval
state from the source record. Saving a day strips projected Expense rows so a
Calendar mutation cannot become a second Expense ledger.

Exact Expense and receipt-evidence routes now handle a stale, deleted, or
unauthorized source without throwing and without disclosing which condition
occurred. The shared Expense header remains present, the user can navigate
back, and no replacement record is invented.

The visible Expense detail lifecycle now uses explicit own/team removal and
restore permissions based on the signed-in actor's stable employee ID. The
selected employee filter is presentation scope and cannot make a team record
become the actor's own record. Removal is a revision-safe soft delete: the row
leaves active lists, totals, reports, attention, Dashboard, and Calendar
projections without being erased. An authorized user receives immediate Undo,
and the Expense landing screen exposes a compact Removed Expenses route only
while restorable records exist. Restore returns the same stable Expense ID.
The unbound UI-test fixture mirrors this recoverable behavior but is not a
release persistence source.

UI Lab platform launches explicitly bootstrap the accepted demo Expense fixture
into the private repository only when that authorized company repository is
empty. The bootstrap is controlled by the
`MAINTAINIAC_UI_LAB_DEMO_DATA` compile-time flag, never overwrites existing
records, and excludes the unfinished receipt-review row because a receipt draft
is not a confirmed business Expense. This is test-bed behavior and must not be
copied into a release build.

### Durable Receipt Draft and evidence checkpoint

UI Lab now has a bound Receipt Draft system under `lib/src/data/receipts/`.
`StoredReceiptDraft` owns stable organization, employee, Job, business-date,
lifecycle, state, and audit identities together with ordered evidence
references. Each evidence record retains its stable ID, original filename,
photo/PDF kind, private local path, SHA-256 digest, byte length, order, and
active/removed state. Removing an item from the current review marks it removed
with a UTC time; it does not silently erase the original file or its history.

`FileReceiptDraftRepository` serializes mutations into a checksummed two-slot
snapshot beneath private Application Support/app data. Evidence is validated,
copied into a draft-specific private directory, and checksum-verified after the
copy. A failed snapshot write rolls back only newly copied unreferenced files,
preserves the prior record and evidence, and never claims success. A damaged
newest generation falls back to the prior valid generation and exposes a
recovery notice.

`AuthorizedReceiptDraftService` enforces organization plus separate own/team/
company read, create, edit, submit, and discard capabilities at the command
boundary. `ReceiptDraftUiController` retains the last known-good projection,
stable IDs, operation-specific failure state, recovery state, and per-draft
pending state. Platform startup opens and injects this repository once; an
unbound in-memory draft list remains an explicit isolated-widget fixture only.

The Expense landing summary, draft directory, and intake route now consume the
same authorized controller. Employee filtering compares stable employee IDs,
not display names. Opening a draft carries the exact draft ID, loads its retained
evidence, and resumes that record. Selecting or removing evidence persists the
draft before review; a failed save leaves the unsaved selection visible and the
last safe repository record intact.

The intake route now opens a permission-gated evidence review using the shared
responsive detail workspace. It renders the retained local image or PDF,
provides zoom/page inspection and explicit Earlier, Later, Remove, Undo, Save
order, and Continue controls, and persists the exact reviewed stable-ID order.
The reviewed order survives controller reload/repository restart. Same-content
active selections remain separate review items instead of being silently
discarded.

Confirmed Expense details now keep reviewed receipt lines and totals inline and
route the evidence summary to a read-only retained-file viewer. That viewer
derives the receipt ID from the authorized Expense controller, reads the closed
submitted draft through the authorized Receipt Draft controller, and verifies
the draft's `submittedExpenseId` before displaying any filename or preview. An
authorized miss never falls through to prototype/demo Expense data. The viewer
uses the same real local image/PDF renderer as intake review and the shared
bounded detail layout.

Confirmed receipt-backed values now use a revision-safe **Correct receipt**
command. The editor requires a correction reason, preserves the exact retained
receipt identity, appends the previous business values and approval evidence to
durable prior-version history, and records actor/time/reason in the audit trail.
When approval policy applies, changed values are normalized to pending before
the authorized command; a prior approval can never silently authorize the new
amount or line items. This is the confirmed manual-value correction slice, not
Receipt Assistant proposal/provenance correction.

`ReceiptDraftSubmissionCoordinator` creates the confirmed ordinary Expense
first with deterministic ID `EXP-RECEIPT-<draftId>` and the retained draft ID as
its receipt link. It then closes the draft with that Expense ID. If the second
write is interrupted, retry validates and reuses the exact saved Expense rather
than creating a duplicate. It rejects a removed prior Expense, mismatched
confirmed values, a different receipt link, changed evidence count, or an
unreviewed Materials/submitter proposal. Submitted and discarded drafts leave
the active list but remain queryable as closed audit records with their source
evidence.

This checkpoint is the durable draft/evidence and receipt-backed Expense
foundation with image/PDF preview, manual evidence ordering, and audited
confirmed-value correction. Receipt Assistant proposals, long-receipt
stitching, parsing, allocation, proposal-provenance correction, export, and sync
remain separate incomplete slices and must not be inferred from this
checkpoint. Owner rendered acceptance also remains separate from test and build
evidence.

### Durable recurring-obligation cutover checkpoint

UI Lab now has a bound durable recurring-expense system under
`lib/src/data/expenses/`. A recurring template owns the cadence, preferred
monthly day, category, optional Job or vehicle, assigned employee, reminder
preferences, receipt requirement, fixed or enter-when-paid amount policy, and
active/paused/ended lifecycle. A dated occurrence separately owns its due,
paid, or skipped state, the expected and actual exact-minor-unit amounts, and
the stable ordinary Expense ID after payment. Paid values never become mutable
template defaults.

The repository persists the template and its occurrences in one checksummed,
two-slot snapshot in private Application Support/app data. Mutations are
serialized, revision checked, restart safe, and retain actor, permission
revision, time, and action evidence. A damaged newest snapshot falls back to
the prior valid snapshot and reports recovery rather than pretending the
newest write succeeded. Own, team, and company reads plus target-employee
mutation rules are enforced by `AuthorizedRecurringExpenseService`, not by
widget visibility.

The platform entry point opens that repository from private app storage, loads
one authorized recurring controller, and binds the Expense landing summary,
planned-expense list, detail, edits, pause/resume, skip, history, and reminder
publisher to that projection together. Isolated widget tests retain an explicit
unbound in-memory fixture; it is not a platform data source.

`Mark paid` now uses one coordinator that creates an authorized ordinary
Expense first and then links its deterministic stable ID to the occurrence. If
the second write is interrupted, retry validates and reuses the saved Expense;
it cannot create a duplicate or falsely report the occurrence as paid. First
load, failed load, and damaged-newest recovery are visible states rather than
honest-empty claims. Receipt attachment remains a separate adapter. Native
push/sound scheduling now consumes the same authorized reminder events through
an explicit-permission adapter; reminder preferences alone still cannot prove
permission or operating-system delivery.

## 2. Record ownership

| Record | Owner | May reference | Must not own |
| --- | --- | --- | --- |
| Expense | Expense aggregate | optional Job, vehicle, Receipt, recurring occurrence | image bytes, OCR proposals, Job line items, Dashboard rows |
| Confirmed Expense itemization | Expense aggregate | stable Expense and optional Job/material IDs | OCR regions or unconfirmed extraction |
| Receipt evidence | durable Receipt Draft repository / Document Intake | submitted Expense ID after confirmation | Expense approval or accounting totals |
| Receipt draft | durable Receipt Draft repository and authorized UI controller | uploader, retained evidence, optional Job, submitted Expense | confirmed Expense values before submission |
| Recurring obligation | durable recurring repository and authorized UI controller | occurrence and resulting Expense ID | paid Expense values after creation |
| Dashboard/Calendar entry | projection | source Expense ID | copied mutable Expense record |
| Report source | projection | source Expense ID | a second financial ledger |
| Job attachment/material source | Job or Work aggregate | authorized Expense/line IDs | editing the source Expense |
| Materials cost history | Materials aggregate | authorized source Expense/line IDs | a duplicate Expense or receipt |

## 3. Current dependency inventory

### 3.1 Prototype storage and projections

| Current file | Current dependency | Cutover requirement |
| --- | --- | --- |
| `lib/src/app.dart` with `lib/src/application_data_scopes.dart` | binds authorized ordinary Expense, Receipt Draft, and recurring projections and publishes reminders after committed recurring source revisions | keep notification ownership separate and do not synchronize on controller loading/pending-only changes |
| `lib/src/data/expense_prototype_store.dart` | owns demo Expenses, drafts, recurring templates, and paid-occurrence creation | retain only as explicit rollback/demo fixture; never production source |
| `lib/src/data/prototype_operations_store.dart` | exposes Expense lists/mutations and folds them into financial/report projections | inject authorized Expense projections; remove ordinary Expense ownership |
| `lib/src/data/operational_attention.dart` | derives pending approval/correction rows from prototype Expenses | accept authorized Expense records; never query an unfiltered global list |
| `lib/src/data/prototype_report_projection.dart` | builds Expense counts, categories, approvals, and cents from UI doubles | consume authorized records and exact minor-unit values |

### 3.2 Expense screen family

| Current file | Current behavior | Required replacement |
| --- | --- | --- |
| `lib/src/screens/expenses/expenses_screen.dart` | landing list, daily total, calendar badges, add action, drafts, and recurring summary | controller records for ordinary Expenses; separate durable draft/recurring sources |
| `lib/src/screens/expenses/expenses_day_screen.dart` | filters a prototype day and creates an Expense | controller date projection and authorized create |
| `lib/src/screens/expenses/expense_category_screen.dart` | filters prototype records locally | controller-authorized category/period projection |
| `lib/src/screens/expenses/expense_detail_screen.dart` | finds by ID and synchronously edits/approves lines and totals | controller lookup plus awaited update/approval with pending, failure, and conflict UI |
| `lib/src/screens/expenses/expense_receipt_evidence_screen.dart` | resolves the authorized Expense receipt ID, verifies its exact submitted closed draft, and renders real read-only local image/PDF evidence | retain Document Intake ownership; add export/backup only through later explicit permissions |
| `lib/src/screens/expenses/receipt_intake_screen.dart` | resumes the exact authorized draft; persists selected, removed, and manually ordered evidence; opens real image/PDF review; and invokes the retry-safe receipt submission coordinator | add correction, proposal, allocation, and export slices without bypassing the draft command |
| `lib/src/screens/expenses/receipt_intake_confirmation.dart` | owns the screen's confirmation handler; connected sessions use atomic receipt submission, while the unbound fixture delegates through the operations store | preserve the authorized atomic boundary and keep fixture fallback explicit |
| `lib/src/screens/expenses/expense_receipt_drafts_screen.dart` | reads authorized active drafts with loading/failure/recovery states and routes by stable ID | retain the explicit unbound widget fixture only; never masquerade as Needs Attention |
| `lib/src/screens/expenses/scheduled_expenses_screen.dart` | reads and edits the authorized recurring projection in platform sessions | retain the explicit in-memory fallback for isolated tests only |
| `lib/src/screens/expenses/scheduled_expense_detail_screen.dart` | coordinates an authorized ordinary Expense and durable occurrence link | preserve deterministic retry and never claim both records share one file transaction |
| `lib/src/screens/expenses/reports_screen.dart` | requests prototype report summary | authorized cross-module report projection |
| `lib/src/screens/expenses/report_sources_screen.dart` | drills from report source IDs into prototype records | resolve every source through its owning authorized module |

### 3.3 Dashboard and Calendar consumers

| Current file | Current behavior | Required replacement |
| --- | --- | --- |
| `lib/src/screens/dashboard/dashboard_screen.dart` | combined attention reads prototype-derived Expense alerts | authorized attention projection |
| `lib/src/screens/dashboard/dashboard_attention_screen.dart` | lists combined prototype attention | authorized projection and exact source route |
| `lib/src/screens/dashboard/dashboard_attention_actions.dart` | opens Expense detail and resynchronizes a copied Dashboard row | open exact controller record; Dashboard redraws from source |
| `lib/src/screens/dashboard/dashboard_record_navigation.dart` | checks prototype existence before opening Expense detail | controller `recordById`/authorized route result |
| `lib/src/screens/dashboard/dashboard_day_record_actions.dart` | copies approval state from prototype Expense into a day entry | derive review state from current source record |
| `lib/src/screens/dashboard/dashboard_projection_actions.dart` | manually creates and updates duplicate Expense day rows | replace with source-driven day projection |
| `lib/src/screens/dashboard/dashboard_screen_actions.dart` | delegates add/fuel to the shared record-navigation/editor flow; no direct prototype Expense dependency remains | retain awaited authorized confirmation and source-derived projections |
| `lib/src/screens/dashboard/dashboard_summary_strip.dart` | summarizes operational-store financial totals, using authorized Expense totals when bound | retain exact authorized Expense projection while Work ledger persistence is migrated |
| `lib/src/screens/dashboard/dashboard_day_screen.dart` | daily recap folds prototype Expense doubles | exact authorized daily total and source list |

### 3.4 Work and Materials consumers

| Current file | Current behavior | Required replacement |
| --- | --- | --- |
| `lib/src/screens/work/job_workspace_screen.dart` | resolves linked Expense IDs from prototype records | authorized linked-record query; missing/denied are distinct states |
| `lib/src/screens/work/job_workspace_interactions.dart` | links existing prototype Expense or receipt-created Expense | controller source picker; Job owns only stable link IDs |
| `lib/src/screens/work/work_items_editor.dart` | selects a reviewed Expense line from prototype records | authorized Expense/line projection; copy facts with provenance only |
| `lib/src/screens/work/estimate_items_screen.dart` | selects a reviewed Expense line for estimate costing | same authorized source boundary; never copy full receipt total |
| `lib/src/screens/inventory/material_cost_editor_screen.dart` | offers prototype Materials expenses as cost sources | Materials-labeled screen queries authorized confirmed Expense lines |
| `lib/src/screens/inventory/material_detail_screen.dart` | checks prototype Expense existence before opening source | authorized exact-source route with denied/missing handling |

The top-level navigation label is **Materials** for release one. Internal
inventory types may remain while a true truck-inventory engine is designed, but
they do not justify a second Expense source.

## 4. Atomic implementation sequence

1. Keep the accepted visible layout unchanged while the data boundary is built.
2. Install one app-level authorized Expense session beneath the shell. The
   platform repository opens from private Application Support/app data.
   **Implemented and bound for platform launches; unbound widget fixtures are
   explicit test-only fallbacks.**
3. Map the signed-in actor, organization, permission revision, own/team/company
   scope, employee labels, and Job labels explicitly. Visible labels are never
   identities.
4. Load active and soft-deleted records in one authorized projection snapshot
   before enabling Expense mutations. **Implemented.**
5. Replace every ordinary Expense read in sections 3.2 through 3.4 with the
   controller or a read-only projection derived from it. **Implemented through
   the bound shared operations projection; Receipt Draft and recurring records
   use separate bound owners rather than a second Expense ledger.**
6. Replace every create/edit/approval/delete/restore action with awaited
   controller commands. Disable only the action being saved and retain the
   editor draft if the save fails. **Implemented for ordinary Expenses.**
7. Replace Dashboard/Calendar copied rows with projections keyed by source ID.
   **Implemented for Expense rows.**
8. Replace financial/report folds over doubles with exact authorized cents.
   **Implemented for bound Expense projections.**
9. Route Job and Materials pickers through authorized confirmed records and
   line IDs; they may not mutate the source Expense.
10. Bind recurring templates, occurrences, payment posting, history, and
    reminder publication atomically. **Implemented for platform sessions with
    interruption-safe same-Expense retry. The recurring native scheduling
    adapter is implemented without a startup prompt; receipt evidence and
    physical-device delivery acceptance remain separate incomplete slices.**
11. Bind Receipt Draft metadata, private evidence, stable routing, and
    receipt-backed Expense submission together. **Implemented for the durable
    draft/evidence foundation with interruption-safe same-Expense retry;
    real image/PDF preview and persistent labeled reordering are implemented;
    audited confirmed-value correction is implemented; parsing, allocation,
    proposal-provenance correction, export, and sync remain later slices.**
    **Confirmed Expense detail also reopens only its exact verified submitted
    evidence; missing, denied, or mismatched links reveal no files.**
12. Surface damaged-snapshot recovery, storage failure, permission denial,
    missing record, and revision conflict in the accepted hierarchy.
13. Run restart, offline, narrow/wide/accessibility, Android, and macOS QA.
14. Only after the cutover passes may direct ordinary-Expense access through
    `ExpensePrototypeStore` be removed. Deletion still requires owner approval.

## 5. Failure behavior

- **Initial load fails:** show a retryable Expense workspace state; do not show
  demo records as if they were the user's data.
- **Recovered older snapshot:** show the controller recovery notice and the
  recovered records; never claim the newest invalid write succeeded.
- **Save fails:** retain the last known-good list and the user's unsaved editor
  values; explain that nothing was saved.
- **Revision conflict:** reload the current record, preserve the user's draft in
  the editor, and let the user compare before retrying.
- **Permission denied:** reveal neither record existence nor totals outside the
  authorized scope.
- **Linked source missing:** keep the Job/Materials history link as unavailable
  evidence; do not delete or silently replace it.
- **Receipt evidence save fails:** keep the user's current selection visible,
  retain the last safe draft/evidence generation, and do not open confirmation
  as though the evidence were durable.
- **Expense saves but draft close fails:** keep the draft open and instruct
  retry; retry must validate and reuse the deterministic saved Expense.

## 6. Verification gate

- dependency-inventory contract test matches every direct prototype Expense
  consumer;
- no production screen imports `FileExpenseRepository`;
- no production screen imports `FileRecurringExpenseRepository` or either
  private-storage opener;
- no production screen imports `FileReceiptDraftRepository` or its private
  storage opener;
- one normal create/edit/approval/delete/restore path survives restart;
- Dashboard day count, Expense day list, report total, and linked Job source all
  resolve the same stable Expense ID;
- pending approval is excluded from approved totals everywhere;
- daily, employee, category, Job, vehicle, approval, and vendor filters operate
  on stable authorized projection fields, and all totals use exact cents;
- mixed currencies fail explicitly rather than entering a combined total;
- denied records do not affect visible counts, categories, calendar badges,
  attention rows, source pickers, or reports;
- receipt evidence and recurring payments cannot bypass the durable command;
- selected Receipt Draft evidence survives restart with checksums and stable
  identity; removed evidence remains auditable;
- an interrupted Receipt Draft close followed by retry leaves exactly one
  Expense linked to the exact draft and one submitted closed draft;
- a receipt-backed correction requires a reason, preserves the original
  evidence link and previous confirmed revision through restart, and returns a
  policy-controlled Expense to pending approval;
- `flutter analyze`, source-size guard, full tests, Android build, and macOS
  build pass;
- rendered owner acceptance remains separate from automated verification.
