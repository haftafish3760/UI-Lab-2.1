# Maintainiac canonical application map

**Current working plan (September 11):** [Workflow delivery roadmap](workflow_delivery_roadmap.md).
Start with its owner corrections and [Start Workday review](start_workday_workflow_review.md).
Product name is not selected. Historical titles/technical IDs are not a branding decision.

**Laptop continuation:** [Current Codex handoff — September 10](codex_continuation_handoff_2026_09_10.md). Main contains the migration checkpoint; implementation is not complete.

Updated 2026-09-09. This is the canonical documentation entry point, not a
claim that the application is implemented or that every inherited rule was
approved. Read [the decision register](application_decision_register.md) first.

Current storage implementation, verification and remaining gates:
[SQLite migration completion checklist](sqlite_remaining_work_audit.md).
The product blueprint describes required behavior; this checklist distinguishes
implemented and tested behavior from unfinished work.

## Authority and how to use this corpus

Start with [Current owner blueprint](current_product_blueprint.md), reconciled
from this conversation, then the detailed owners below. D30–D34 supersede older
destination/database/receipt-only backup wording: 2.1 replacement, SQLite/Drift,
local-only/sync-only/sync-with-backup, optional cloud use in release one, and
account-required trade-pack download. Detailed commercial/provider choices remain
open. [Database task handoff](storage_database_codex_handoff.md) is ready to paste
into a separate visible task; no such task was created by this documentation pass.

1. Explicit current owner decisions govern product behavior. Accepted UI Lab
   decisions override conflicting 5.7 documents and implementation.
2. The decision register identifies accepted decisions, proposals, deferrals,
   unresolved choices, and the evidence needed for implementation claims.
3. The owning document below holds the detailed contract. Other documents link
   to it rather than creating competing versions. A heading saying Confirmed
   in an old AI document is not evidence of owner acceptance by itself.
4. Code and test results establish observed behavior, not product authority.
   5.7 remains protected capability and compatibility evidence only.
5. Handoffs, GPT uploads, and review drafts are derived artifacts. They must name
   their canonical sources and decision IDs; they cannot override them.

One source of truth means one authoritative owner per decision/record, not one
giant file or one database for every kind of information. Product authority,
domain record ownership, storage location, and replication authority are
different concepts; see [storage contracts](data_storage_sync_contract.md).

## Owning documentation

| Topic | Canonical owner | Boundary / next unresolved work |
| --- | --- | --- |
| Product identity, priorities, scope | [Whole app](maintainiac_app_blueprint.md) §§1,3–8,10–11 | Use decision-register status, not inherited Confirmed headings alone |
| Decisions, corrections, release intent | [Decision register](application_decision_register.md) | Only owner evidence promotes product decisions |
| Screens, actions, record owners, permissions | [Product control](product_control_blueprint.md) §§2–8 and [Operations](operations_screen_blueprint.md) | Screen contracts below include gaps, not invented finished designs |
| Shared responsive layout, theme, accessibility | [UI foundation](ui_foundation_blueprint.md) | Shared AppLayoutEngine, local logical constraints and TextScaler; lane counts are not universal design recipes |
| Dashboard / technician / company context | [Technician dashboard](technician_dashboard_blueprint.md), Operations §5 | Dashboard projects other modules; it is not their database |
| Calendar, dated history and day routes | [Calendar](calendar_system_blueprint.md) | Work owns commitments; owning modules own actual entries |
| Customers, Quotes, Estimates, Jobs, Invoices, Payments | [Work lifecycle](work_lifecycle_blueprint.md) | Quotes required; independent lifecycle remains unresolved |
| Scheduling, staffing, recurrence, history-based assistance | [Scheduling](scheduling_system_blueprint.md) | Non-AI engine; policy/defaults and full integration remain open |
| Expense ledger and atomic consumer cutover | [Expense cutover](expense_atomic_cutover_blueprint.md) | Expense screens and projections must agree on one authorized source |
| Receipt capture/import, OCR, review, Data Saver, allocation | [Receipt/material intake](receipt_material_intake_blueprint.md) | Evidence, proposals and confirmed effects remain distinct |
| Inventory, trade packs, par, cost and stock | Operations §9 and Receipt/material intake §§12–13 | Preserve catalog/parser investment; thresholds and stock policies need decisions |
| Trips, workday, odometer | Product control §7 and Calendar §Trips and workday | Dedicated trip lifecycle/recovery specification still needed before migration |
| Maintenance / Repairs / vehicles and equipment | Calendar §Vehicles, equipment, maintenance, and repairs; Product control §4 | Module is required; implementation outside this pass; exact interval/reset policies open |
| Storage, sync, evidence location, backup, retention | [Data/storage/sync](data_storage_sync_contract.md) | Per-record authority decisions not inferred from legacy optional-backup code |
| Notifications, Needs Attention and record activity | [Notifications](notification_system_blueprint.md) | Separate systems; dismissal is not business approval or delivery proof |
| Languages, regional variants and units | [Localization/measurement](localization_measurement_blueprint.md) | Mandatory throughout; catalog coverage is not full localization |
| Shared document reader and PDF generation | Receipt/material intake §Shared document platform boundary; Work §Sharing and acceptance | Share infrastructure, not receipt and invoice domain schemas |
| Customer portal / QR / signatures / delivery | Work §Release-one customer portal and QR handoff | Existing design retained as PLANNED; release timing, expiry and identity policy need owner evidence |
| Settings hierarchy | Product control §2 | Page gear is page-specific; company/account/privacy preferences have separate ownership |
| AI-agent planning | Work §Internationalization, measurements, accounting, and AI | Optional command-facing assistant, not a record owner or scheduler dependency |
| Admin health / bugs / diagnostics | Data/storage/sync §Operational health | Owner-required separate admin application; redaction/access/retention policies open |
| Future accounting connections | [Accounting integration](accounting_integration_blueprint.md) | DEFERRED in existing plan; no bank/account-number storage in current scope |
| Build / reuse / migration gates | [Capability migration map](maintainiac_5_7_capability_migration_map.md) | 2.1 replacement selected; bounded migration assessment required, no migration executed here |

## Screen and workflow coverage map

This is an inventory of responsibilities, not approval of one route per row.
List, detail, create/edit, history, preview and settings may be separate screens
or adaptive parts of one workspace. Layout selection remains owner-reviewed.

| Screen family | User task and authoritative connection | Gaps to resolve before implementation |
| --- | --- | --- |
| Dashboard, company/employee views | See attention, planned work and confirmed dated activity; open exact sources | Final priority/composition per scope and available width |
| Calendar Month/Week/Day, module day routes | Browse past/present/future; edit through record owners; retain selected date on return | No schedule command may replace actual day entries |
| Work landing/directories | Discover authorized commercial applications, their records and actions | Final navigation placement is not a data-ownership decision |
| Customers/sites/contacts and company profile | Maintain identity, sites, history and document identity | Merge/retention and field-level visibility policy |
| Quotes and Estimates | Prepare, revise, review and communicate proposed work | Quote/estimate distinction and conversions; do not erase Quotes |
| Jobs, active job, Scheduling | Plan/assign, execute, record actuals, complete or return | Staffing/override/recurrence/completion policy; see SCH cases |
| Invoices, Payments, credit/correction | Issue exact documents, record amounts and reconcile balances | Direct entry/link rules, rounding/tax policy, corrections and approval matrix |
| Expenses, recurring obligations, Receipt review | Record costs, review evidence, link confirmed outcomes | Complete interruption/recovery and cross-module commit contracts |
| Camera/import, long receipt, Data Saver, evidence viewer | Obtain readable retained evidence; review proposals and compression | Provider/quality/retention policy; no fabricated attachment success |
| Materials, catalog/trade packs, locations, stock/history | Know item identity, purchase cost, par and known quantities | Cost history is not stock certainty; par and adjustment policy |
| Trips/workday, vehicles and equipment | Record confirmed readings/trips and asset context | Offline/background GPS lifecycle and device acceptance |
| Maintenance and Repairs | See due service; plan, record repairs/service and history | Date/mileage/runtime triggers, reset/correction and downtime rules |
| Reports/Recap/search/export | Aggregate authorized source records and drill back | No mixed-currency sum or unauthorized inference |
| Team/permissions/settings | Configure membership, scope and relevant preferences | Grant delegation, revocation offline, inherited defaults and override rules |
| Notifications/attention/sync recovery | Identify reminders, action needs and failed/pending operations | Channels, quiet hours and record-specific conflict resolution |
| Customer portal/document preview/QR | Share customer-safe exact revision and record permitted responses | Authentication/expiry/revocation, consent and launch scope |
| Admin health/support | Diagnose failures with approved device/app/build context | Consent/redaction/retention, access and support workflow |
| Optional AI assistance | Explain and propose using authorized commands | Provider/model, cost, data boundary and release scope |

## Required architecture relationships

- Domain owners expose authorized application commands and projections.
  Screens, calendar, reports, notifications and AI do not open parallel ledgers.
- Work scheduling consumes employee availability and job requirements; only an
  authorized confirmation changes commitments. Actual history is separate.
- Receipt review may yield separately confirmed Expense, cost-history, stock
  intake and job-actual commands. Retry/link failures must not duplicate them.
- Trips supply confirmed mileage references; Maintenance owns service rules;
  Expenses own service costs and Inventory owns consumed stock.
- Documents render exact source revisions. Portal links, QR codes and PDFs
  cannot expose internal fields or become editable replacement source records.
- Storage/sync and notifications transport approved changes; transport success
  does not prove global business acceptance, device delivery or user review.

## Agent handoff: send the task, not an app introduction

For an existing Codex conversation, identify the exact target and read only the
relevant available context. Do not repeat what Maintainiac is or teach basic
Flutter/Firebase concepts when the target already has that context. Send the
requested outcome, decision IDs and changes since its last known state,
canonical section references, scope/exclusions, dependencies, acceptance
evidence and unresolved decisions. Include all task-critical constraints even
when omitting background. A fresh task receives the relevant context packet,
not this entire corpus by default. Unknown context is stated, not assumed.

New owner decisions update the owning section and register in the same change;
then update derived GPT files deliberately. A local edit does not update an
uploaded attachment. No attachment or bridge Instruction is changed by this pass.
