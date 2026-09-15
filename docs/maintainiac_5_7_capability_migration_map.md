# Maintainiac 5.7 Capability Migration Map

September 14 owner authorization D38 starts the inventory/parsing transfer in
UI Lab. See [the extraction checkpoint](inventory_migration/README.md) for
the local source comparison, bounded catalog conversion and unresolved work.
The historical pre-migration status below is not a claim that no extraction
has occurred. All 5.7 originals remain read-only.

September 14 additional owner authorization starts shared device capability
adaptation and image OCR integration. Read-only inspection covered
`shared/device_capabilities/device_capability.dart`, its service and scope,
the Android/iOS `DeviceCapabilityBridge` implementations, the receipt adapter
and `receipt_ocr_service.dart` in 5.7 Active. Reuse assessment: adapt runtime
memory/power/thermal facts and conservative workload budgets; replace advisory
receipt-only limits with a shared admission gate. Keep ML Kit's native Latin
recognition behind an image-only adapter. Exclude old stitching, camera
implementation, PDF processing and broad hardware identity collection. Original
5.7 code was inspected, not executed or changed. The owning behavior and current
limitations are in Receipt/material intake's shared device workload section.

Status: pre-migration control document 0.1  
Historical discovery date: 2026-09-01; not revalidated in this documentation pass.
Purpose: map candidate capabilities to accepted application contracts before
any migration. Authority: `README.md` and `application_decision_register.md`;
production destination is 2.1 (D30), with SQLite/Drift selected (D31).
See `current_product_blueprint.md` and `storage_database_codex_handoff.md`.

Read-only discovery snapshot: branch
`backup/receipt-pipeline-pre-registration-2026-08-04`, HEAD
`729187647cff7d2ed1e259f55d992d91abfef9a1`, pre-existing dirty-state SHA-256
`be2d4d27a4474e67134b999d114512c332ba023887c5b8855230028d04e46ec9`.
This identifies the inspected state; it does not claim the branch is clean,
current, correct, or release-ready.

## 1. Authority and repository boundary

This map controls capability movement between two repositories:

- **Current contract/proving workspace:** `/Volumes/AppleWork/UI-Lab-2.1`
- **Protected source:** `/Users/rbbie/Documents/Maintainiac_5.7_Active`

UI Lab owns the accepted screen behavior, responsive layout, plain-language
copy, and new module contracts. Maintainiac 5.7 owns legacy capability evidence
and persisted-data compatibility. Neither repository is permission to copy a
whole legacy screen, controller, parser, or storage graph.

UI Lab now also owns the generated release-one localization catalog and stable
language/measurement preference codes. Only the shared shell and calendar are
catalog-backed so far; screen-body translation, durable preference storage,
measurement conversion, localized documents, and 5.7 adapters remain explicit
future slices rather than implied completion.

Until the owner approves a bounded slice:

1. 5.7 is read-only. Do not edit, format, clean, reset, delete, migrate, build,
   launch, commit, or change generated files there.
2. Do not copy files from 5.7 into UI Lab.
3. Do not add Hive, Firebase, OCR, AI, PDF, camera, or cloud behavior to UI Lab
   merely because a dependency exists in 5.7.
4. Record every source file, destination contract, dependency, test, data
   conversion, and rollback gate before implementation begins.
5. Preserve unrelated dirty work in both repositories.

Controlled replacement in 2.1 is selected by D30. Assess both repositories'
existing systems; neither age nor passing source tests settles
quality. Preserve useful behavior, not defects. Paths/dispositions below are
historical candidates, not current verification or transplant approval.

## 2. Non-negotiable migration rules

1. **Durable offline work.** Confirmed local operations save before optional
   backup or sync attempts. Global acceptance/authority is category-specific;
   see `data_storage_sync_contract.md` and U02. Local success is not cloud ack.
2. **Stable identity.** Expense, receipt, receipt line, attachment, occurrence,
   job, vehicle, employee, and organization identifiers remain stable across
   restart, import, export, and sync.
3. **Integer money.** New durable contracts store money in minor units such as
   cents. Legacy `double` values are conversion input, not new authority.
4. **Typed time.** Durable records use typed local dates plus UTC audit times.
   UI strings and `Object date` values are presentation/prototype input only.
5. **Human confirmation.** OCR, parsing, AI, duplicate suggestions, inferred
   categories, inferred job links, and inventory matches remain proposals until
   an authorized person confirms them.
6. **Separate reviews.** Receipt-reading review belongs to the person creating
   or correcting the receipt. Company expense approval is a separate business
   decision and may be required by owner policy.
7. **Evidence is not the ledger.** Images/PDFs and their checksums are evidence;
   an Expense record is the financial entry; parsed lines are reviewed data.
   They link by stable IDs and do not silently duplicate one another.
8. **Permissions at every boundary.** Enforce access at navigation, query,
   count, route, action, export, attachment retrieval, and sync. Hiding a widget
   is never the only check.
9. **Recoverable change.** Delete means a tombstone/soft delete until an
   explicit retention policy permits purge. Conflicts preserve both versions
   for review.
10. **No secret shipping.** API keys, Firebase administration credentials, and
    service secrets never live in the client repository or app bundle.
11. **Cohesive files.** Production Dart files target 500 lines or fewer and use
    responsibility-based names. A safe exception must be documented before a
    file exceeds that limit; legacy oversized files are split during adaptation
    rather than copied intact.
12. **One slice at a time.** A slice is not done until code, schema notes,
    migration fixtures, focused tests, full regression, restart proof, and
    rollback evidence agree.
13. **Presence is not proof.** A source file, test, harness, or passing legacy
    check proves only that a capability exists. It is not accepted as correct,
    complete, secure, or release-ready until independent target requirements and
    characterization evidence agree.

## 3. Migration classifications

- **Reuse:** behavior or a small contract can move with minimal semantic change
  after dependencies and tests are isolated.
- **Adapt:** valuable behavior exists, but its public contract, money/time
  types, ownership, coupling, or file shape must change.
- **Rewrite:** retain tests/fixtures and expected behavior, but implement a new
  component only after evidence proves the source is conflicting or unsafe to
  transplant and the owner approves replacement.
- **Reference only:** use as evidence; do not move it into the new runtime.
- **Defer:** explicitly outside the current slice.

No source classification authorizes movement by itself. Owner approval of the
named slice is still required.

## 4. Target architecture and dependency direction

The new dependency direction is one way:

`screens -> application/use cases -> domain contracts <- infrastructure`

Widgets do not open Hive boxes, access Firebase, parse receipts, read files, or
make permission decisions from role labels. Infrastructure does not import
screens. Domain ownership is not storage location. Cloud authority for selected
categories remains U02; an existing local adapter does not settle that policy.

### Planned target responsibilities

All names below describe cohesive responsibilities; none are numbered parts.

#### Domain: `lib/src/domain/expenses/`

- `expense_record.dart`: confirmed business Expense identity, ownership, date,
  vendor, category, amount, allocation references, approval, and lifecycle.
- `expense_money.dart`: checked integer-minor-unit arithmetic and currency code.
- `expense_approval.dart`: pending/approved/declined/not-required state,
  decision actor, reason, and decision time.
- `receipt_record.dart`: receipt header, reviewed totals, evidence references,
  review state, and stable line ordering.
- `receipt_line.dart`: printed row identity, reviewed description, quantity,
  unit/package facts, category, amount, and allocation references.
- `receipt_evidence.dart`: attachment identity, media type, size, checksum,
  original order, local reference, and optional remote reference.
- `expense_draft.dart`: recoverable unconfirmed entry/checkpoint.
- `recurring_expense_template.dart`: recurrence rule and defaults only.
- `recurring_expense_occurrence.dart`: due/paid/skipped state for one occurrence.
- `expense_query.dart`: authorized date, employee, company, job, vendor,
  category, approval, and search filters.

#### Application: `lib/src/application/expenses/`

- `expense_repository.dart`: local CRUD/query contract for confirmed expenses.
- `expense_draft_repository.dart`: recoverable draft contract.
- `receipt_evidence_repository.dart`: stage, persist, retrieve, and rollback.
- `recurring_expense_repository.dart`: template and occurrence contract.
- `expense_permission_policy.dart`: operation plus record-scope authorization.
- `expense_approval_policy.dart`: owner rule and allowed approval transitions.
- `expense_command_service.dart`: create/edit/delete/restore/link operations.
- `receipt_review_service.dart`: apply confirmed receipt corrections only.
- `expense_query_service.dart`: permission-filtered results and totals.
- `expense_sync_outbox.dart`: optional idempotent upload work, not direct UI sync.

#### Infrastructure: `lib/src/infrastructure/`

- `local/expenses/hive_expense_repository.dart`
- `local/expenses/hive_expense_draft_repository.dart`
- `local/expenses/hive_recurring_expense_repository.dart`
- `local/receipts/file_receipt_evidence_repository.dart`
- `migration/expenses/legacy_expense_decoder.dart`
- `migration/expenses/legacy_expense_import_report.dart`
- `receipts/receipt_suggestion_engine.dart`
- `receipts/legacy_receipt_suggestion_adapter.dart`
- `sync/expense_sync_document_mapper.dart`
- `sync/hive_expense_sync_outbox.dart`
- `sync/firebase_expense_backup_gateway.dart`

The first approved data slice creates only the domain, application, and local
manual-expense pieces it needs. Empty future abstractions are not scaffolded.

## 5. Current UI Lab ownership to replace

| Current UI Lab source | Current role | Migration treatment |
| --- | --- | --- |
| `lib/src/data/expense_prototype_store.dart` | in-memory Expense, receipt draft, and scheduled-expense lists | Reference UI behavior; replace behind repositories after a bounded slice passes |
| `lib/src/data/prototype_operations_store.dart` | in-memory cross-module demo projections | Keep as demo fixture source until each module has a repository; do not turn it into a production god object |
| `lib/src/screens/expenses/expense_models.dart` | UI/prototype records using `double` and legacy date shapes | Reference only; map to typed domain records at the application boundary |
| `lib/src/screens/expenses/expense_demo_data.dart` | realistic rendered scenarios | Convert selected cases into deterministic fixtures; never import as user data |
| `lib/src/screens/expenses/expenses_screen.dart` | accepted landing behavior under review | Keep presentation-only; queries and actions move through application contracts |
| `lib/src/screens/expenses/expense_editor_screen.dart` | manual entry prototype | Bind to command service only after local repository slice passes |
| `lib/src/screens/expenses/expense_detail_screen.dart` | detail/edit route | Bind to authorized query and edit commands; retain inline evidence and lines |
| `lib/src/screens/expenses/scheduled_expenses_screen.dart` | recurring/upcoming presentation with an authorized platform binding and explicit test fallback | preserve the accepted presentation; migrate only through the recurring application contracts |

Prototype records are not serialized into a production box. A dedicated mapper
keeps UI proof data from accidentally becoming a permanent schema.

## 6. 5.7 source inventory and disposition

Paths in this section are relative to the protected 5.7 root.

### 6.1 Shared local durability

| 5.7 source | Classification | Surgical use |
| --- | --- | --- |
| `lib/shared/storage/maintainiac_hive_bootstrap.dart` | Adapt | Preserve private Application Support location, known-box registration, and safe legacy-location recovery; expose initialization without feature imports |
| `lib/shared/storage/maintainiac_secure_storage.dart` | Reuse/Adapt | Preserve secure secret boundary; inject it behind key-vault interfaces |
| `lib/shared/storage/app_storage_guard.dart` | Adapt | Preserve capacity checks and no-delete behavior; separate operation estimates from UI copy |
| `lib/shared/records/maintainiac_record_lifecycle.dart` | Adapt | Preserve revision, UTC audit order, soft delete, restore, and draft checkpoint behavior |
| `lib/shared/records/maintainiac_durable_record_store.dart` | Adapt | Preserve serialized writes, expected-revision conflict checks, integrity reporting, and audit archive; type module payloads at adapters |
| `lib/shared/durable_storage/maintainiac_durable_storage.dart` | Reference only | Use as capability index; do not recreate a barrel that makes every feature depend on Firebase |

Required extraction tests: concurrent writes serialize, disk-full refusal does
not mutate state, restart reads identical records, interrupted writes preserve
the last confirmed state, backward/equal clocks retain lifecycle order,
delete/restore is recoverable, corrupt values are reported and preserved,
missing encryption material fails safely where applicable, schema upgrades are
repeatable, and stale revisions cannot overwrite.

### 6.2 Expense ledger and financial records

| 5.7 source | Classification | Surgical use |
| --- | --- | --- |
| `lib/screens/expenses/data/expense_ledger_store.dart` | Adapt | Preserve stable CRUD, date/range queries, duplicate helpers, line replacement, soft delete/restore, and write queue; remove widget notifier as repository authority |
| `lib/screens/expenses/data/expense_ledger_models.dart` | Reference only | Part-file index and legacy decoder surface only |
| `lib/screens/expenses/data/expense_receipt_record.dart` | Adapt | Decode merchant/header, totals, evidence references, context, duplicate state, lifecycle, and lines into separated Expense/Receipt records |
| `lib/screens/expenses/data/expense_line_record.dart` | Rewrite around fixtures | Preserve useful field meaning but split printed row, review proposal, business allocation, fuel facts, and catalog match; do not copy the oversized mixed model |
| `lib/screens/expenses/data/expense_split_allocation.dart` | Adapt | Preserve percentage/amount/quantity validation; use integer money for amount splits and explicit rounding remainder |
| `lib/screens/expenses/data/expense_category_store.dart` | Adapt | Preserve durable category identity and rename behavior; filter release-one defaults to business categories |
| `lib/screens/expenses/data/expense_receipt_item_memory_store.dart` | Defer | Consider only after confirmed manual receipt storage; suggestions may never silently modify saved values |

Legacy `enteredSubtotal`, `enteredTax`, `enteredTotal`, line subtotal, and unit
price doubles are decoded once using documented rounding. New writes store cents.
The import report must list every rounded, rejected, corrupt, or unresolved row.

### 6.3 Drafts and receipt evidence

| 5.7 source | Classification | Surgical use |
| --- | --- | --- |
| `lib/screens/expenses/data/expense_draft_store.dart` | Adapt | Preserve autosave recovery, serialized writes, unchanged-check deletion, and staged-proof cleanup without deleting recoverable drafts by age |
| `lib/screens/expenses/data/expense_receipt_draft_record.dart` | Adapt | Decode legacy drafts into the new draft schema with source-version metadata |
| `lib/shared/widgets/receipt_capture/receipt_proof_storage.dart` | Adapt | Preserve checksum-backed attachment persistence, staging, promotion, rollback, and original order |
| `lib/shared/widgets/receipt_capture/receipt_attachment_record.dart` | Adapt | Map to `ReceiptEvidence`; retain media type, checksum, size, order, and safe local identity |
| `lib/shared/pdf/app_generated_pdf_storage.dart` | Defer | Evaluate with the shared Document Platform slice, not manual Expense storage |

Evidence movement must be transactional from the user’s perspective: failed
record confirmation rolls back newly persisted files; failed cleanup never
removes an attachment still referenced by a draft or confirmed record.

The UI Lab target foundation now implements this separation without copying a
5.7 source file: `receipt_draft_record.dart`,
`receipt_draft_repository.dart`, `file_receipt_draft_repository.dart`,
`authorized_receipt_draft_service.dart`, `receipt_draft_ui_controller.dart`,
and `receipt_draft_submission_coordinator.dart`. The repository stores ordered
photo/PDF evidence with checksums under private Application Support/app data;
removed evidence and closed drafts remain auditable. This target contract is
presented through a new permission-gated review screen that renders the real
local image/PDF and persists explicit labeled evidence ordering by stable ID.
The same target boundary now lets a confirmed Expense reopen only the exact
submitted closed draft named by its authorized receipt ID; it verifies the
reverse `submittedExpenseId` link and refuses prototype fallback before showing
files. No 5.7 source was copied or edited for either presentation. This target
contract is the destination for a later synthetic-fixture legacy decoder. It is
not proof that either 5.7 draft or capture implementation is safe to transplant.

### 6.4 Recurring expenses and reminders

| 5.7 source | Classification | Surgical use |
| --- | --- | --- |
| `lib/screens/expenses/data/expense_reminder_store.dart` | Adapt | Preserve cadence math, active state, lifecycle, storage guard, delete/restore, and write queue |
| `lib/screens/expenses/data/expense_reminder_draft.dart` | Reference only | Use form/default evidence; do not make a reminder draft the recurring financial record |

5.7 reminders are not enough by themselves. The replacement separates:

- a recurring template;
- generated occurrences;
- reminder delivery preferences;
- one occurrence’s paid/skipped/overdue state;
- the normal dated Expense created when an occurrence is marked paid;
- optional evidence linked to that Expense.

Editing future recurrence must not rewrite already posted expenses. “Edit this
occurrence” and “edit this and future occurrences” are explicit operations.

UI Lab now proves the presentation contract with synthetic records: fixed and
variable templates, exact monthly occurrences, up to five reminder offsets,
pause/resume/end, one-occurrence edit, future-template edit, paid/skipped
history, and an idempotent normal Expense link when paid. Its in-app reminder
center is intentionally separate from Needs Attention. Native push and sound
delivery remain unimplemented platform adapters; preference flags and UI
labels are not evidence that an operating-system notification was sent. The
shared platform-neutral queue does preserve stable occurrence/reminder/channel
identities and does not require the in-app channel; native adapters must prove
permission, scheduling, cancellation, restart, time-zone, and delivery behavior
separately.

The E4 data system now exists and is bound in UI Lab without copying or
modifying 5.7. It provides exact-minor-unit recurring templates and occurrences,
deterministic occurrence identity, short-month cadence, revision/audit evidence,
own/team/company authorization, serialized two-slot private persistence,
damaged-snapshot recovery, and visible first-load/failure/recovery states. The
Expense landing summary, planned-expense list, detail, edits, pause/resume,
skip, paid history, and reminder publisher read the same authorized controller
in platform sessions. The test-only prototype fallback remains explicit.

The payment coordinator proves that creation of the ordinary Expense and
linkage of its stable ID to the occurrence cannot create duplicates or falsely
completed payments after interruption: an interrupted second write leaves one
saved Expense, and retry validates and reuses it before completing the link.
Native push/sound scheduling and receipt evidence stay outside this checkpoint.

### 6.4.1 Shared notifications

5.7 has no accepted app-wide notification engine to transplant. Its known
Expense reminder store is cadence evidence only. UI Lab therefore owns a new,
shared foundation under `lib/src/data/notifications/` with stable
organization/recipient IDs, localizable content keys, exact source routes,
per-recipient unread/read/dismissed state, separate push/sound delivery state,
organization-scoped deduplication, revision/audit evidence, own/team/company
authorization, and serialized private two-slot recovery.

Dashboard recurring-Expense items, unread count, read-state action,
localization, and exact source route have switched atomically to that shared
foundation. The former prototype notification center has been removed so it
cannot become a rollback data source or compete with durable state. Rollback is
the repository/test checkpoint, not a second runtime store. This checkpoint
still does not claim native delivery or rendered owner acceptance. Android,
iOS, macOS, and Windows delivery adapters must prove platform behavior
independently, and every later module publisher remains its own bounded slice.
General employee chat remains a separate deferred product decision; structured
record notes and required return/correction reasons do not make the
notification repository a messaging store.

### 6.5 Receipt Assistant, OCR, and parser

| 5.7 source | Classification | Surgical use |
| --- | --- | --- |
| `lib/shared/receipts/receipt_ocr_contract.dart` | Adapt | Preserve source-region/evidence contracts and candidate results behind a proposal-only interface |
| `lib/screens/expenses/data/expense_receipt_parser.dart` | Preserve engine; add adapter | Keep the legacy parser intact as the comparison implementation; expose no legacy UI/store imports through the new interface |
| `lib/screens/expenses/data/expense_receipt_parse_result.dart` | Adapt | Map totals, reconciliation, and allocation proposals without confirming them |
| `lib/screens/expenses/data/expense_receipt_user_review_merge.dart` | Reference/Adapt | Preserve confirmed-user-wins behavior with explicit reviewed-field provenance |
| `lib/screens/expenses/data/expense_ocr_failure_diagnostics.dart` | Defer | Reintroduce only through privacy-reviewed diagnostic contracts |
| `lib/screens/expenses/data/expense_screen_telemetry.dart` | Reference only | Treat this root and its companion telemetry files as one legacy family; do not migrate wholesale; redesign minimal privacy-safe operational telemetry later |

Long-receipt repair versus replacement requires independent assessment; the
owner allowed either route. The old mandatory-rewrite disposition is not
approval. Original images and
their order remain evidence. A stitched image is derived evidence and cannot
replace originals. The engine must have overlap, missing-middle, duplicate-row,
rotation, blur, glare, and very-long-receipt fixtures before it can feed Receipt
Assistant. OCR and parsing never block manual entry.

### 6.6 Expense-to-material and inventory bridge

| 5.7 source | Classification | Surgical use |
| --- | --- | --- |
| `lib/screens/expenses/data/expense_materials_receipt_bridge.dart` | Rewrite behind command | Preserve the idea of transferring confirmed receipt lines; remove direct cross-store mutation |
| `lib/screens/work_supplies/data/work_supply_inventory_store.dart` | Adapt later | Preserve vehicle/location stock transactions, events, and records after Inventory ownership is mapped |
| `lib/screens/work_supplies/data/work_supply_inventory_receipt_store.dart` | Adapt later | Preserve confirmed receipt identity and line correction behavior |
| `lib/screens/work_supplies/data/work_supply_item_identity_store.dart` | Adapt later | Preserve stable catalog/custom item identities |
| `lib/screens/work_supplies/data/work_supply_catalog.dart` | Reuse by indexed boundary later | Keep trade-pack coverage; do not load the entire catalog into Expenses |
| `lib/screens/work_supplies/data/work_supply_receipt_parser.dart` | Adapter later | Consume only confirmed receipt lines or explicit proposals |

The protected Inventory capability is a system, not the six entry-point files
listed above. Its baseline includes the complete
`lib/screens/work_supplies/data/` tree, trade catalogs, identity/index rules,
inventory transaction stores, parser families, merchant/trade precedence, and
its fixtures and QA support. No file is removed from that dependency graph
because a text search suggests it is unused. Before an Inventory slice, create
a full path, byte-size, line-count, and SHA-256 manifest and compare it before
and after every extraction attempt.

Confirming an Expense does not automatically change truck stock, job actuals,
estimate price, or invoice price. Those are separate authorized commands with
idempotency keys and audit links back to the receipt line.

The intended Inventory-assisted receipt outcome is four separately reviewable
destinations, not one bulk “apply” side effect:

1. save the business Expense and reviewed receipt evidence;
2. retain confirmed vendor/item/unit/package price as cost history;
3. optionally create a stock-receipt transaction for a selected vehicle or
   inventory location and confirmed quantity;
4. optionally allocate confirmed lines to one or more Jobs as actual costs or
   materials used.

Receipt Assistant may propose all four. The user can accept none, one, or
several according to permission. A cost-history record does not claim stock is
on a truck; a stock transaction does not make an item billable; and a job cost
does not change a customer Estimate or Invoice.

### 6.7 Permissions and approval

| 5.7 source | Classification | Surgical use |
| --- | --- | --- |
| `lib/shared/profiles/user_permissions.dart` | Adapt | Preserve granular Expense permissions; remove release-one personal-expense presentation and add any missing explicit operations |
| `lib/shared/profiles/user_profile_models.dart` | Adapt | Preserve active profile plus explicit permission set; never infer authorization from role label alone |
| `lib/shared/profiles/employee_permission_pack_store.dart` | Adapt later | Preserve reusable permission packs and targeted scopes after policy semantics are tested |

Minimum Expense operations are:

- view own expenses;
- add/edit/delete own expense;
- attach/view own receipt evidence;
- view/add/edit/delete team expense;
- approve/decline submitted expense;
- view restricted amount/category/evidence fields;
- manage recurring expenses and reminders;
- view recap/profit projections;
- export records and export proof separately;
- manage Expense settings and owner approval policy.

Owner policy `requireApprovalForEveryExpense` determines whether a submitted
Expense counts as approved company spending. A creator’s receipt review never
satisfies that policy. Pending amounts do not enter approved totals unless a
report explicitly requests pending submissions and the viewer is authorized.

### 6.8 Optional cloud backup and sync

| 5.7 source | Classification | Surgical use |
| --- | --- | --- |
| `lib/shared/firebase/maintainiac_cloud_identity.dart` | Reuse/Adapt | Inject read-only authenticated identity; local-only use remains valid without it |
| `lib/shared/firebase/maintainiac_firestore_schema.dart` | Adapt | Version every new path/document contract and retain organization scope |
| `lib/shared/firebase/maintainiac_firestore_upload_queue.dart` | Adapt | Preserve idempotent queue, quota, integrity, conflict, and acknowledgment behavior; split transport from queue storage |
| `lib/screens/expenses/data/expense_cloud_backup_service.dart` | Rewrite by responsibility | Split coordinator, mapper, outbox, blob gateway, restore planner, and identity dependency; do not copy oversized service |
| `lib/screens/expenses/data/expense_firestore_documents.dart` | Rewrite mapper | Emit versioned documents from confirmed domain records only |
| `lib/screens/expenses/data/expense_cloud_proof_storage.dart` | Adapt later | Upload evidence only when the user’s backup choice and plan allow it |
| `lib/screens/expenses/data/expense_cloud_restore_coordinator.dart` | Adapt later | Restore to a reviewable plan before mutating local truth |

The UI talks to local application services. Sync observes committed local
changes through an outbox. Offline create/edit/delete stays available. Retries
are idempotent; quota or network failure never rolls back the local record.

### 6.9 Adjacent module entry points

These paths are recorded now so Expenses does not invent competing ownership.
They require their own detailed slice map before movement.

| Domain owner | 5.7 entry point | Current disposition |
| --- | --- | --- |
| Jobs | `lib/shared/jobs/maintainiac_job_store.dart` | Adapt later; Expenses stores only an optional stable job ID and authorized context snapshot |
| Invoices | `lib/screens/invoices/data/invoice_ledger_store.dart` | Adapt later; no Expense screen writes invoices directly |
| Invoice record | `lib/screens/invoices/data/invoice_record.dart` | Reference field/lifecycle behavior; convert money to cents in replacement |
| Invoice PDF | `lib/screens/invoices/data/invoice_pdf_template_renderer.dart` | Defer to shared Document Platform |
| Active workday | `lib/screens/dashboard/data/active_workday_store.dart` | Adapt in Dashboard/Work slice; Expense can receive scoped employee/job/vehicle defaults only |
| Vehicle inventory | `lib/screens/work_supplies/data/work_supply_inventory_store.dart` | Inventory owns stock, not employees and not Expenses |

No dedicated 5.7 estimate ledger entry point was found in the targeted store
inventory. Before an Estimate slice begins, perform a new read-only search and
map its actual ownership rather than assuming it shares Jobs or Invoices.

### 6.9.1 Future accounting connector boundary

`accounting_integration_blueprint.md` is the contract for a later QuickBooks or
other accounting adapter. This migration does not copy provider-specific fields
into Customer, Invoice, Payment, or Expense records and does not add a live
provider dependency to UI Lab.

Before a connector slice, perform a fresh read-only 5.7 inventory for any
accounting export, provider credential, external-ID mapping, or sync code.
Classify it as reuse, adapt, or replace only after independent tests. The target
architecture is a provider-neutral command/outbox port, a separate external
mapping repository, secure connection credentials, and an adapter behind that
port. Maintainiac keeps stable record IDs and revision authority; the provider
cannot become the owner of jobs, receipt review, signatures, stock, or local
offline writes.

### 6.10 QA harness and independent characterization

5.7 already contains substantial QA infrastructure. Preserve it as production
evidence, but do not treat its existence as proof that an engine is correct.

| 5.7 source | Classification | Surgical use |
| --- | --- | --- |
| `test/support/qa_harness/qa_harness.dart` | Preserve/audit | Shared reports, suites, severity, artifacts, filters, and failure taxonomy; first split only if required by the target line policy |
| `test/support/qa_harness/qa_threshold_gate.dart` | Preserve/audit | Keep threshold behavior and real-parser-call evidence; do not weaken gates to make a port pass |
| `test/support/work_supply_parser_qa/work_supply_parser_qa.dart` | Preserve/audit | Registry for Inventory parser suites; verify every registered suite and focused rerun route |
| `test/fixtures/work_supply_parser/golden_fixtures.json` | Preserve fixture | Tuning/regression evidence, never secretly rewritten to match new output |
| `test/fixtures/work_supply_parser/holdout_fixtures.json` | Preserve holdout | Keep separate from golden/tuning data and do not inspect while tuning a port |
| `test/fixtures/receipt_qa/fixture_pack_inventory.json` | Preserve/audit | Receipt QA corpus inventory and provenance boundary |
| `tool/maintainiac_qa_backbone.dart` | Preserve/audit | Reproducible harness entry point; validate commands on macOS before reuse |
| `docs/inventory_parser_qa_harness_contract_completion_checklist.md` | Reference truthfully | It explicitly says contract completion is not parser, corpus, device, OCR, UI, cloud, or release completion |

Before moving OCR or Inventory code, add independent black-box
characterization tests around public inputs and outputs. Run those tests against
the untouched 5.7 engine first, freeze privacy-safe expected artifacts, then run
the same cases against the adapter/target. New tests cover gaps in the existing
harness; they do not replace or relax it. Any output difference is reviewed,
not automatically accepted as an improvement.

This is an active characterization requirement, not permission to treat 5.7 as
documentation only. At the start of each approved capability slice, run the
existing untouched 5.7 harness, add narrowly scoped tests for uncovered public
behavior, freeze privacy-safe artifacts, and only then decide whether the
capability is adapted, wrapped, or replaced. Long-receipt repair/replacement
requires its own evidence and bounded approval; do not transplant it wholesale.

### 6.11 Evidence maturity labels

Every mapped capability carries one of these states in its slice notes:

- **Discovered:** source and likely responsibility found; correctness unknown.
- **Characterized:** public behavior and failure cases frozen by independent
  tests against the untouched source.
- **Accepted:** requirements, tests, privacy, security, and owner behavior agree.
- **Adapted:** target implementation passes the same accepted contract.
- **Integrated:** UI, restart, offline, permissions, migration, and rollback are
  proven in the target app.

All capabilities in this 0.1 map are only **Discovered** unless a later slice
records stronger evidence. Existing tests are valuable inputs to that audit,
not an automatic promotion to Accepted.

## 7. Canonical Expense record mapping

| UI/business meaning | New durable field | Legacy 5.7 input | Rule |
| --- | --- | --- | --- |
| Expense identity | `expenseId` | receipt/expense `id` | Preserve valid stable IDs; namespaced generated ID only when missing |
| Organization | `organizationId` | cloud/context scope | Required for synced company records; local-only install scope is explicit |
| Creator/payer | `createdByEmployeeId`, `paidByEmployeeId` | context/work profile | Never infer from selected UI label |
| Business date | `expenseDate` | `receiptDate` | Calendar date in recorded local zone |
| Time | `expenseTimeMinutes` | `receiptTimeMinutes` | Optional; no fake midnight semantics |
| Vendor | `vendorName`, optional contact | merchant fields | User-confirmed text wins over parser proposal |
| Category | `categoryId`, snapshot label | line/header category | Stable ID plus historical label; rename does not rewrite history |
| Amount | `totalMinorUnits`, `currencyCode` | `enteredTotal`/line totals | Exact cents; unresolved mismatch requires review |
| Receipt | `receiptId` | embedded receipt | Extract to linked Receipt with stable ID |
| Job | `jobId` | context/job link | Optional, permission-checked, never guessed into confirmed data |
| Vehicle | `vehicleId` | context/vehicle ID | Optional and scoped; not the owner of all Expenses |
| Approval | `approval` | not consistently modeled | New explicit state independent of receipt review |
| Lifecycle | `lifecycle` | record state/revision/audit | Preserve created/updated/deleted order and source revision |
| Sync | outbox metadata | local/cloud revision fields | Infrastructure-only; not UI-editable business data |

Receipt line order and source identity are immutable. Corrections create a new
revision of reviewed fields while retaining source text/region provenance.

## 8. Query, total, and attention rules

1. Date-first Expense landing queries the selected date and authorized scope.
2. Company scope is a permission-filtered aggregation, never an unfiltered list
   later hidden by widgets.
3. Daily total uses approved business Expenses for that date and scope.
4. When owner policy does not require approval, a confirmed authorized Expense
   is approved at creation with an audit reason of policy-not-required.
5. Pending submissions appear in Needs Attention for an authorized approver and
   as pending state for the submitter; they do not impersonate receipt review.
6. Receipt drafts appear in Receipt Drafts, not Needs Attention.
7. OCR/parser corrections remain inside the receipt review flow unless a saved
   record becomes inconsistent or evidence is missing.
8. Record lists return actual totals and expose “show all N”; they never assume
   five records.
9. Search is repository-backed by vendor, item description, category, job,
   vehicle, employee, date range, amount, approval, and receipt presence.
10. Counts and money summaries apply the same permission predicate as records.

### September 14, 2026: Invoice/Estimate form presentation slice

Owner authorized adapting the 5.7 create-form arrangement into UI Lab, retaining
5.7 read-only, and installing UI Lab on the S25 Ultra. Inventory parsing and the
materials integration are explicitly deferred. This slice changes presentation,
not the Work ledger schema or ownership. No 5.7 source file was copied or edited.

Fresh local reference: `C:/Users/noneya/Documents/5.7 rebuild`, particularly
`lib/screens/invoices/home/invoice_form_screen.dart`, `invoice_form_details.dart`
and `invoice_form_sheets.dart`. The inspected form uses separate summary tiles
for document/client information, template, items, money, terms and payment.
The discount/tax/terms sheet Save handler only pops its route and the totals
sheet contains static zero values; those handlers are not transplantation targets.

| Capability | Disposition in this slice |
| --- | --- |
| 5.7 first-form summary containers | Adapt presentation using shared UI Lab primitives |
| 5.7 document/client/item section organization | Adapt; keep focused editors and current record links |
| 5.7 sheet handlers and local-only status selector | Replace with existing UI Lab draft and payment commands |
| UI Lab invoice/estimate draft recovery and atomic confirmation | Retain and regression-test through new section routes |
| UI Lab linked invoice payment workflow | Retain; validate balance, partial payment and permission regressions |
| 5.7 PDF renderer and reader | Separate shared Document Platform task; not imported here |
| Inventory intake/parser and Quote lifecycle | Not implemented by this presentation slice |

Source inspection establishes suitability, not legacy runtime correctness. No
5.7 build or test was run. Owner visual acceptance remains required after install.

Verification: 77 focused tests passed across 17 files, covering form routes,
invoice source imports, linked payments, failed confirmation, nested item/photo
recovery and database reopen. The nine shared-form tests passed again after the
final action-color change. Android debug APK built and updated the S25 Ultra
successfully with `adb install -r`; no uninstall or data clearing was needed.
The owner deferred launch and visual review until later, so the app was not
launched. Gradle was stopped after the build. Analysis reported one pre-existing
Dashboard braces-style lint; the build also reported the existing pdfx Kotlin
plugin migration warning. These checks are not production-release certification.

## 9. Pre-migration UI readiness gate

Substantial 5.7 capability movement waits until the operational record surfaces
that will consume it are coherent in UI Lab and accepted by the owner. Complete
these one screen/workflow at a time, using synthetic prototype data:

1. **Expenses:** landing hierarchy, date/scope, attention, daily total, compact
   records, recurring/upcoming, category access, manual entry, receipt detail,
   editable reviewed lines, evidence preview, and correct navigation.
2. **Work home:** compact separate containers for Active Jobs, Estimates, and
   Invoices; drafts and attention remain separate; each record opens itself.
3. **Active Jobs:** schedule and assignment, multi-day state, status actions,
   customer contact, scope/photos/notes, time, materials, linked Expense/receipt,
   change handling, completion, return visit, and job history.
4. **Estimates:** draft versus sent/accepted/declined/expired, customer and job
   photos, separate labor/materials, terms/deposit, share/print/sign, exact
   revision approval, revision invalidation, and conversion to Job.
5. **Invoices:** job/customer ownership, multi-day actuals, draft/issued/due/
   overdue/paid state, delivery, payments/credits/refunds, PDF preview/share,
   and retained record history.

The shared header, date-first rule, compact record component, attention
component, calendar/day route, bounded responsive lanes, permissions, back
navigation, and module settings entry must stay consistent across those screens.

Current UI Lab Job-ownership checkpoint: Job details accepts an exact
`WorkRecord`; Dashboard/calendar/report projections only carry navigation to the
owning record. The route no longer invents contact, scope, notes, estimate
numbers, items, or receipts from the schedule title. Linked existing Expenses
are retained by stable Expense ID on that Job prototype. Before production
integration, map UI Lab's temporary exact-name customer lookup to 5.7's stable
customer and service-location identifiers and verify every read/write through
the production authorization boundary.

This checkpoint moved no Job, camera, OCR, receipt-stitching, Inventory parser,
GPS, cloud, or storage capability from 5.7. Those systems remain protected
discovery subjects for later bounded slices with independent tests and a
reuse/adapt/replace classification.

UI Lab's Job receipt entry now reuses its own shared Expense receipt-intake UI,
passes the exact Job ID into the created Expense and reviewed lines, and links
the saved Expense ID back to the Job. This is a prototype ownership contract,
not a port of 5.7 receipt storage. Job-photo actions intentionally create no
placeholder attachment while the durable device/photo-manager adapter is
unconnected.

The current Job-material source checkpoint also remains entirely inside UI Lab
prototype records. `Add materials` edits only actual material additions. An
Expense-derived proposal requires an authorized Expense that currently counts
as a recorded business cost plus one exact reviewed material line; the complete
Expense amount is never copied, the stable Expense-line ID is retained, and UI
Lab does not synthesize a receipt ID.
Unitemized Expenses remain linkable to the Job record but cannot become a
material line. Link Expense, use truck stock, view private cost, and set
customer price are independent prototype capabilities. Focused tests cover
exact line provenance, pending/incomplete Expense filtering, unitemized
evidence, cost-hidden truck use, independent action grants, and missing stock
identity without mutation.

The UI Lab prototype now also assigns every Job material addition one explicit
billing treatment: non-billable use, invoice candidate, or customer approval
required. These treatments do not rewrite the accepted Estimate. Job totals are
projected separately by treatment, restricted users cannot overwrite protected
billing decisions, and a new Invoice draft imports only quoted/planned lines
plus explicit invoice candidates. Focused tests cover treatment-only revisions,
protected-item preservation, source-Estimate signature preservation, and
Invoice import filtering. This remains prototype target behavior; no 5.7 Job,
Estimate, Invoice, approval, or storage implementation was moved.

Before this gate passes, allowed work is limited to UI, synthetic data,
blueprints, independent tests, and small shared foundations explicitly approved
by the owner. Do not transplant OCR, Inventory parsing, cloud sync, or a whole
legacy store merely to make a prototype screen appear functional.

## 10. First bounded implementation slice

No code begins until the owner approves this slice.

### Slice E1: manual local Expense foundation

In scope:

1. typed `ExpenseMoney`, `ExpenseRecord`, `ExpenseApproval`, and lifecycle;
2. local Expense repository using a private application-data location;
3. manual create, restart, open, edit, soft delete, and restore;
4. expected-revision conflict protection and serialized writes;
5. owner approval policy with pending versus approved totals;
6. permission-filtered own/team/company queries;
7. adapter that lets the accepted Expense UI use the repository without
   changing its layout;
8. import decoder fixtures only—no automatic import of the owner’s 5.7 data.

Explicitly out of scope:

- receipt photos/PDFs;
- OCR, parsing, AI, and long-receipt stitching;
- drafts/autosave;
- recurring expenses;
- inventory/material transfer;
- Firebase backup/sync;
- exports and shared PDF reader;
- Jobs, Estimates, Invoices, Dashboard, and Maintenance data movement.

### E1 verification gate

- create/edit/delete/restore succeeds offline;
- process restart returns byte-equivalent business values and stable IDs;
- decimal edge cases never lose a cent;
- concurrent saves serialize and stale revisions fail safely;
- disk-full simulation preserves prior data and shows a recoverable error;
- own/team/company queries and counts cannot leak denied records or totals;
- pending approval never enters approved daily total;
- legacy fixture decoding produces a review report and never mutates 5.7;
- focused tests, full `flutter analyze`, full `flutter test`, Android build, and
  macOS build pass;
- rendered owner review remains a separate acceptance gate.

### Current UI Lab E1 foundation status

The repository foundation is implemented and bound to UI Lab platform Expense
sessions, but it is **not migrated to 5.7 or owner-rendered accepted**. The
current boundary is intentional:

1. `expense_record.dart` defines exact minor-unit money, explicit currency,
   stable organization/employee identity, date-only business dates, approval,
   and revisioned soft-delete lifecycle records.
2. `expense_repository.dart` defines own/team/company query predicates before
   aggregation plus create, update, soft-delete, restore, and approved-total
   operations.
3. The retained legacy `file_expense_repository.dart` uses two checksummed
   generations with serialized writes for compatibility and independent tests.
   It is not the current application startup path.
4. Current startup opens SQLite through `LocalPersistence.open`, beneath private
   Application Support/app data, and injects its repositories into the app.
   The unused private file-repository startup helpers were removed during the
   SQLite migration. Live storage must not be redirected to Documents or a
   user-selected export directory.
5. `expense_record_adapter.dart` requires explicit organization and employee
   IDs. It does not infer authorization identity from the visible employee
   label.
6. `authorized_expense_service.dart` is the only approved UI command boundary.
   It evaluates the active organization, employee, permission revision,
   own/team/company scope, target employee, and create/edit/delete/restore/
   approve capability before delegating to the repository.
7. Every successful repository mutation appends actor, UTC time, permission
   revision, before/after record revision, action, and optional note to the
   checksummed record snapshot. A failed write cannot commit either the record
   change or its audit event alone.
8. Focused tests prove cent-safe parsing, restart recovery, revision conflict,
   soft delete/restore, serialized concurrent writes, storage-pressure
   rollback, damaged-generation fallback, permission-filtered totals, and the
   explicit UI-adapter identity boundary. Separate authorization tests prove
   denied cross-employee writes, denied approval, denied queries/totals, and
   retained mutation evidence.
9. `expense_itemization.dart` now owns confirmed manual purchase facts beneath
   the Expense aggregate: stable line identity and order, description and
   category snapshots, exact package quantity, package style, optional
   confirmed contained quantity/unit, exact price and extended line total,
   optional part and Job references, subtotal, and sales tax. Quantities retain
   up to six decimal places without binary-float storage, all money remains in
   minor units, and the line-to-subtotal difference stays visible instead of
   being silently forced to zero.
10. `expense_ui_repository_bridge.dart` now supplies the first explicit UI-to-
    service command bridge for total-only and manually itemized Expenses.
    Visible employee labels never become authorization identity, values with
    more than two money decimals are rejected instead of rounded, and a stale
    editor returns a reload instruction. The bridge never manufactures a
    Receipt ID from receipt-status text or an image count.
11. The bridge intentionally rejects receipt images, submitter-review state,
    and Materials proposals as one atomic unsupported command. It does not save
    a partial Expense and discard fields owned by later receipt or Materials
    slices. Focused tests prove the rejection leaves the repository empty and
    the earlier valid snapshot intact.
12. `expense_ui_repository_controller.dart` now owns the future accepted UI's
    authorized offline session state without binding any screen early. It loads
    active and soft-deleted projections atomically, exposes immutable lists,
    performs create/edit/delete/restore through the bridge, retains the last
    known-good UI after storage failure, reloads current records after a stale
    revision, and retains damaged-snapshot recovery as a dismissible notice.
    Restart, denial, conflict, storage-pressure, delete/restore, and recovery
    tests cover this controller contract. It does not reference or mirror the
    prototype store.
13. `expense_ui_projection.dart` preserves the authorized source record's exact
    cents, stable employee/category/Job/vehicle IDs, business date and optional
    time, approval state, lifecycle side, and revision beside the presentation
    record. One permission-filtered query builds the active/deleted snapshot.
    Local day, employee, category, Job, vehicle, approval, vendor, and recorded-
    total filters cannot expand that authorized source set. Totals and category
    totals add minor units and reject mixed currencies. Focused tests also prove
    that ordinary UI edits preserve an existing vehicle link and occurrence
    time rather than erasing fields the current form does not expose.
14. `file_receipt_draft_repository.dart` owns restart-safe Receipt Draft
    metadata and checksum-verified photo/PDF copies in private app data. It
    serializes mutations through two checksummed generations, retains removed
    evidence and closed drafts, rolls back newly copied unreferenced files when
    a snapshot fails, and reports damaged-newest recovery.
15. `authorized_receipt_draft_service.dart` separately enforces organization,
    own/team/company read, create, own/team edit, own/team submit, and own/team
    discard capabilities. Display names and visible employee selectors never
    grant access.
16. `receipt_draft_ui_controller.dart` is bound once under the platform shell.
    Expense landing, draft directory, and intake use its stable authorized
    projection; isolated widgets retain an explicit unbound fixture only.
17. Receipt intake persists selected/removed evidence before confirmation and
    resumes the exact stable draft ID. It keeps unsaved selection visible after
    failure rather than pretending the evidence is durable.
18. `receipt_draft_submission_coordinator.dart` creates one deterministic
    receipt-backed Expense before closing the draft. Interrupted second-write
    retry validates and reuses the same Expense. Tests prove restart, checksum,
    removal retention, denial, last-known-good storage failure, exact UI route,
    app binding, and no-duplicate retry behavior.
19. Confirmed receipt-backed Expense correction now requires a plain-language
    reason, retains the exact receipt link, appends the previous confirmed
    values and approval evidence to durable revision history, and records the
    actor/time/reason audit event. Any policy-controlled correction becomes
    pending before it can re-enter approved totals.

Still required before the full Expense/Document Intake cutover is accepted:
receive rendered owner acceptance; finish image/PDF preview and order controls;
complete allocation, export, backup/sync, and proposal-only Receipt Assistant
and proposal-provenance correction slices; remove any remaining prototype-query
bypass only after its authorized replacement and rollback evidence are green;
and run rendered platform/restart/accessibility QA. The existing
`PrototypeOperationsStore` remains an explicit isolated-widget/rollback fixture
until those gates pass. No 5.7 file or user record is read, copied, or modified
by this foundation.

The complete current UI dependency list and the required one-operation cutover
are maintained in `expense_atomic_cutover_blueprint.md`. That map explicitly
includes Dashboard, Calendar, Reports, Job/Estimate source pickers, Materials,
receipt intake, and recurring-payment creation so none can remain an unnoticed
prototype bypass.

The current Expense presentation now has a separate `ExpensePermissions`
contract and positive/negative widget coverage. It removes denied routes,
amount projections, add actions, settings, edit affordances, approval controls,
receipt-line editing, and planned-expense management before presentation. The
manual editor, receipt intake/review, and planned-expense editor also deny a
direct route without the corresponding capability. This is UI-layer defense in
depth; it does not replace the authorized service above.

Rollback: remove the UI Lab repository binding and return the UI to its
prototype store. Never alter or delete the protected 5.7 boxes.

## 11. Later slice sequence

Each slice receives its own source inventory and owner approval.

1. **E1 Manual local Expense foundation.**
2. **E2 Draft recovery.** Durable create/update/resume/submit/discard,
   staged-evidence-safe lifecycle, checksummed restart recovery, authorization,
   and exact-route binding are implemented in UI Lab. Explicit discard UI and
   later correction remain follow-up work.
3. **E3 Receipt evidence.** Camera/photos/file/PDF selection, private attachment
   storage, checksums, stable ordering metadata, rollback, removed-evidence
   retention, and retry-safe Expense linking are implemented foundations.
   Visual preview, manual reorder controls, inline reader, export, and sync
   remain incomplete.
4. **E4 Recurring expenses.** Durable templates, occurrences, in-app reminder
   publication, mark paid, pause/end, and occurrence history are bound; native
   delivery and receipt attachment remain bounded follow-up slices.
5. **E5 Expense approval.** Full submission queues, decline/correct/resubmit,
   policy changes, audit views, and notifications.
6. **E6 Receipt Assistant.** Existing OCR/parser engine behind a proposal-only
   adapter, independent characterization parity, field/line review,
   search/paging, corrections, and reconciliation.
7. **E7 Long-receipt engine.** New stitching implementation and adversarial image
   fixtures; never a direct transplant.
8. **E8 Expense-to-job/material handoff.** Stable links and separate confirmed
   commands for job actuals, cost history, and vehicle stock.
9. **E9 Optional backup/sync.** Outbox, versioned documents, proof blobs, quota,
   conflict review, restore plan, and offline retry.
10. **E10 Export/Document Platform.** Expense evidence reader/export plus shared
    Estimate/Invoice PDF infrastructure with separate privacy rules.
11. **Module slices.** Dashboard, Work/Jobs, Estimates, Invoices/Payments,
    Customers, Inventory, and reporting each repeat this mapping process.

Maintenance remains excluded until the owner opens that module.

### Current UI Lab reporting checkpoint

UI Lab now has a projection-only Reports/Recap contract over its typed Work,
Expense, invoice-ledger, and payment-ledger records. Period totals carry their
supporting record identities; company financial rows do not leak into an
employee projection; completed-work counts require `completedOn`; and missing
time, mileage, callback, or fuel-economy sources display as unavailable instead
of synthetic numbers. Pending, declined, or submitter-incomplete Expense
records are excluded from company cost and estimated-profit totals. This
defines target behavior only. No 5.7 report, recap, GPS, trip, payroll, or
maintenance implementation has been copied or approved for migration. A later
reporting slice must independently inventory and test those 5.7 sources before
adapting any of them.

### Current UI Lab Materials checkpoint

Release-one presentation is `Materials`: verified purchase-cost history first,
with optional, explicitly qualified truck counts. The screen now consumes the
same local `AppLayoutEngine.operationsFor` lane calculation as Dashboard, Work,
and Expenses. The default cost-history, truck-stock, and source sections occupy
separate lanes when three lanes fit; inline actions appear at the shared
two-lane threshold instead of waiting for a desktop rail.

A manually recorded cost can link only to an existing confirmed Materials
Expense. The UI cannot claim receipt evidence through a checkbox or synthesize
a receipt identity. The linked Expense remains the financial/evidence owner and
opens as the exact source record; an unlinked cost remains a direct verified
entry. This is UI Lab target behavior over prototype records only. No 5.7
catalog, parser, stock store, receipt bridge, or Inventory transaction code has
been copied or approved for migration. Those capabilities still require the
independent manifest and characterization gates above.

## 12. Per-slice extraction procedure

1. Record source branch, commit, exact dirty-state fingerprint, and a SHA-256
   manifest for every critical source/test/fixture tree without modifying it.
   Generate the read-only manifest with
   `tool/audit_maintainiac_5_7_source.sh`; retain reviewed output outside both
   repositories for the slice evidence packet.
2. List only the source files and tests required by the slice.
3. Write the target public contract and permission operations first.
4. Create legacy fixtures from synthetic/test data, never private user data.
5. Port the smallest behavior behind the contract.
6. Keep old and new implementations isolated; no hidden fallback to legacy UI.
7. Run contract tests against source behavior and target implementation where
   legally and technically possible.
8. Run corruption, restart, storage pressure, concurrency, denied-permission,
   duplicate, and offline cases.
9. Verify every production Dart file remains within the source-size contract.
10. Compare 5.7 dirty-state fingerprint before/after; any difference stops the
    slice until explained.
11. Present rendered behavior for owner acceptance.
12. Record the accepted schema version, migration report, and rollback action.

## 13. Stop conditions

Stop without moving code if any of these is true:

- the source record owner is ambiguous;
- a source file has unreviewed cross-module writes;
- stable identity or money conversion cannot be proven;
- a denied user can infer restricted counts, totals, attachments, or names;
- original receipt evidence could be removed or overwritten;
- migration requires writing into 5.7;
- the target requires a legacy UI/controller import;
- a rollback would require deleting user data;
- tests pass but restart, rendered behavior, or owner acceptance is missing.

## 14. Map maintenance rule

This map is updated before—not after—scope expands. A discovered source file,
field, box, permission, native dependency, or cloud document that is not listed
here is unapproved work. Add it, classify it, identify its tests and rollback,
then seek approval for the revised slice.

## 15. Whole-application build and dependency map — 2026-09-07

Documentation only; no 5.7 inspection or migration in this pass. Paths below
refer to historical discovery in §6 where available. Unknown paths remain
unknown. D/U references resolve in `application_decision_register.md`. All
reuse dispositions require refreshed independent assessment before execution.

| Target contract | Candidate 5.7 capability/evidence | Dependencies and gate before movement |
| --- | --- | --- |
| Shared layout/accessibility D06–D08 | Legacy presentation is comparison evidence, not target design | Shared engine, scoped state, full width/scaling/locale workflow acceptance |
| Durable records/Hive D14,D17 | §6.1 bootstrap, secure storage, guard, lifecycle, durable store | Independently assess schemas, atomicity, recovery, keys, U01/U02 |
| Cloud/sync/backup D17 | §6.8 identity, schema, queue, proof storage and restore | Decide record authority and entitlement; distinguish sync, backup and external media |
| Expenses/receipts D12,D15 | §6.2 ledger and §6.3 drafts/evidence | Expense cutover map, exact money, confirmed effects, interrupted-save recovery |
| OCR/long receipts D14,D15 | §6.5 OCR contract, parser, review merge | Regional fixtures, retained originals, manual fallback; repair vs replace undecided |
| Inventory/trade packs/par D13,D14 | §6.6 complete work_supplies data/catalog/parser/QA families | Preserve manifests/identities; cost vs stock vs job actuals; par policy U07 |
| Trips/GPS/workday D09,D13,D14 | §6.9 active_workday_store; GPS path inventory still required | Background permissions, battery, lifecycle, durable samples, confirmation, real-device proof |
| Customers/Quotes/Estimates/Jobs D01,D12 | §6.9 job store; estimate census incomplete; quote/customer census required | Stable identity, U03/U04, independent workflow characterization |
| Scheduling D09,D10 | Work/employee/time seams need fresh census | Pure proposal engine, staffing scope, U05 and historical-entry protection |
| Invoices/Payments/Documents D12,D15 | §6.9 invoice ledger/record/PDF renderer | Exact revisions, decimal arithmetic, shared renderer/reader and safe exports |
| Calendar/history D09 | Workday/source dates; legacy calendar reference | Project owners' records, no duplicate day-ledger authority |
| Maintenance/Repairs/assets D13 | No complete source inventory in this map | U07 identity, thresholds, service/repair vs expense/stock ownership; no build this pass |
| Notifications/attention D13 | §6.4 reminder evidence and §6.4.1 notification assessment | Proven adapters, separate action queues and delivery states |
| Localization/units D11 | Legacy parser/catalog regional and unit behavior needs assessment | Shared catalog, source units/evidence and no translated record identity |
| Permissions/settings D16,D18 | §6.7 permission/approval evidence | Capability/scope/revision, U03 and page vs company/user settings |
| Portal/QR and AI planning P02,D21 | No accepted reusable implementation established here | Scoped commands, exact revision links, U08/U10; no auth/paid-service setup |
| Admin health D19 | §6.5 diagnostics/telemetry are reference only | U09 minimal data, redaction, separate operator scope |
| QA D05 | §6.10 harness, fixtures and holdout inventory | Assess test assumptions; green legacy checks are not independent correctness |

Recommended dependency sequence, not implementation authorization:

1. Reconcile product authority and assess both foundations without changing 5.7.
   Establish stable record identities, command boundaries and storage decisions.
2. Assess high-investment storage/Hive, OCR, GPS, inventory/trade packs as complete
   dependency groups. Explain reuse/repair/replace with actual evidence.
3. Prove the selected SQLite/Drift foundation in an approved isolated context;
   preserve Hive source data and verify conversion rather than assuming parity.
4. Integrate one approved workflow across domain, storage, permissions, screen,
   history, notifications and recovery. Retain a reversible migration path.
5. Expand only after regression, runtime/device and owner acceptance evidence.

Every future slice records decision IDs, source revision/manifest, destination,
schema/data conversion, dependencies, protected records, permissions/offline
states, independent expected results, tests actually run, runtime evidence,
rollback, approval and open gaps. Do not freeze known incorrect legacy output
as the expected target result. A legacy test and its implementation may agree
while both violating the owner's requirements.
