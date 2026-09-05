# Maintainiac Whole-App Blueprint

Status: collaborative draft 0.1  
Purpose: product, information-architecture, permission, data-ownership, and
migration contract for the service-business version of Maintainiac  
Authority: decisions marked **Confirmed** came directly from the product owner;
items marked **Recommended** remain proposals until reviewed together

This document covers the whole product. The existing
`technician_dashboard_blueprint.md` is useful dashboard evidence, but it is not
the complete app contract and must not silently decide other modules. The
detailed customer → estimate → job → invoice contract is maintained in
`work_lifecycle_blueprint.md` and may not contradict this ownership model.
The technician/admin/hybrid screen contract is maintained in
`operations_screen_blueprint.md`. The cross-cutting action, permission,
ownership, test, and migration rulebook is `product_control_blueprint.md`; new
work must update its register rather than creating an undocumented exception.
The shared Month/Week presentation, module record projections, combined
Dashboard day, Trips/Workday projection, and future vehicle/equipment
maintenance and repair calendar rules are maintained in
`calendar_system_blueprint.md`.
The detailed non-AI scheduling engine, employee planning inputs, recurrence,
company-history suggestions and phased verification contract is
`scheduling_system_blueprint.md`. The isolated first build assignment is
`scheduling_engine_codex_assignment.md`; it does not authorize UI redesign or
replace the calendar's historical-record function.
The receipt photo, long-receipt, OCR-line, package, allocation, job-cost, and
inventory-catalog handoff is `receipt_material_intake_blueprint.md`; no module
may implement a smaller competing receipt flow.
Language onboarding, English/U.S. Spanish/Canadian French localization, and
U.S./Metric measurement truth are governed by
`localization_measurement_blueprint.md`; no screen or parser may invent a
private locale or unit system.
The read-only 5.7 capability inventory, extraction classifications, target
contracts, migration gates, and rollback sequence are maintained in
`maintainiac_5_7_capability_migration_map.md`. No 5.7 capability moves until its
bounded slice is present there and approved by the owner.
The notification/reminder, unread state, delivery-channel, exact-route,
privacy, Needs Attention separation, and deferred messaging rules are governed
by `notification_system_blueprint.md`; no module may create a private
notification engine.
The provider-neutral source of truth for later QuickBooks or other accounting
connections is `accounting_integration_blueprint.md`. Release one has no live
accounting dependency; confirmed Maintainiac records, stable IDs, revisioned
commands, mappings, and a durable outbox preserve the future seam.

## 1. Product Definition

### Non-negotiable product rules

1. Accuracy, privacy, security, dependability, and auditability.
2. Consistency: every screen uses the shared layout, typography, spacing, and
   responsive-constraint engine. No screen may invent its own breakpoint rules.
3. Enterprise-grade safeguards with consumer-grade usability for field-service
   workers; no IT expertise should be required for ordinary work.
4. Readability: 500-800 lines is the preferred working range. Review a file
   before it exceeds 500 lines and look for a safe, responsibility-based split
   above 800. Do not split a cohesive feature merely to satisfy a number when
   that would reduce functionality, reliability, or findability; keep any file
   below 2,000 lines unless there is a documented technical reason not to.

### Confirmed

- Maintainiac is a field-service operations app comparable in broad category to
  ServiceTitan and Jobber, intentionally designed first for small businesses.
- It must be approachable for a solo operator or small crew and scale without a
  structural redesign from roughly five users to at least fifty.
- The main field user is a service technician. Owners and authorized office or
  administrative users need broader operational and business capabilities.
- Features and navigation that a user cannot access should not be shown.
- Permissions are the primary authority. Roles help provide starting defaults,
  but a role name alone must not decide access.
- Phone, modern large tablet, desktop, window resizing, and Flutter logical-pixel
  constraints are first-class layout concerns.
- Core customer, estimate, job, invoice, expense, calendar, workday, odometer,
  and reporting workflows must operate standalone. Network services may sync,
  deliver, back up, or propose OCR/AI results, but loss of those services must
  not make local confirmed records unusable.

### Recommended product standard

The front of the app should feel consumer-simple while the underlying system is
business-grade: local work remains recoverable, sensitive data is isolated,
changes are auditable, and derived views never corrupt source records.

## 2. Replacement and Migration Decision

### Confirmed working boundary

UI Lab 2.1 defines and proves the new responsive shell, screen contracts, shared
components, typed prototype records, and regression behavior. Maintainiac 5.7
Active remains protected and read-only during this phase. No third Flutter app
is needed: another shell would create a third source of truth without reducing
the migration risk.

### Recommended production path: controlled replacement

Treat UI Lab as the clean replacement shell and 5.7 as the protected capability
source. This is neither a blank-slate rewrite nor a whole-app copy. Proven 5.7
capabilities move behind explicit interfaces in bounded slices only after their
behavior, data ownership, error states, and tests are inventoried. Unused or
duplicate code is never deleted merely because a scan suggests it is unused.

The sequence is:

1. accept one UI Lab screen and its shared primitives visually and through the
   logical-width/accessibility regression matrix;
2. inventory the matching 5.7 routes, controllers, stores, native integrations,
   tests, and persisted schemas read-only;
3. define an adapter contract and stable record IDs at the module boundary;
4. port the smallest proven capability behind that contract without copying its
   legacy presentation layer;
5. run legacy behavior tests, new UI tests, offline/restart tests, and data-
   migration fixtures against the same expected results;
6. retain a reversible import/export or migration checkpoint until the slice is
   accepted on real devices;
7. repeat by module, leaving receipt stitching, OCR, trips, sync, and permission
   enforcement behind separate audited boundaries.

The first production slice must not begin until its UI Lab screen is accepted.
The original 5.7 repository and the separate 5.7 Lab fallback remain untouched.
This preserves the investment in 5.7 while preventing its fragmented layout and
unverified dead code from becoming the foundation of the new shell.

UI Lab is currently the UX and interaction source of truth. Its prototype store
is not automatically the production data source of truth; production storage is
selected per audited module and must include explicit migration and rollback
evidence.

The first local Expense repository foundation is isolated beneath
`lib/src/data/expenses/`. It is not yet the screen data source. The screen may
bind to it only through the explicit record adapter after the UI, authorization,
save-error, recovery, and audit behavior pass their E1 gates. Platform binding
uses Application Support/app data, never Documents; cloud sync remains a later
optional mirror rather than the local source of truth.

Expense screens must receive `AuthorizedExpenseService`, not the file
repository. The service applies organization, employee, permission revision,
scope, target-employee, and action capability checks before every query, total,
or mutation. The repository atomically retains the matching mutation audit
event with the business record; a visual control or route check is never the
sole enforcement boundary.

The first UI command bridge supports total-only and manually itemized Expenses.
It requires explicit employee IDs, rejects money with more than two decimals,
stores package quantities without binary-float persistence, and does not
convert a visible receipt label or image count into receipt evidence. Confirmed
manual lines, subtotal, and tax belong to the Expense aggregate. Receipt
images, recognition proposals/source regions, submitter review, and Materials
proposals remain outside that bridge until their own durable records exist.
The matching UI repository controller now proves one-query authorized
active/deleted loading, offline create/edit/soft-delete/restore, immutable
projections, stale-revision refresh, last-known-good state after a failed write,
denied-read isolation, and explicit damaged-snapshot recovery state. Its read
projection retains exact cents plus stable employee, category, Job, vehicle,
approval, date/time, lifecycle, and revision fields. Day, employee, category,
Job, vehicle, approval, and vendor filters therefore do not depend on visible
labels or UI doubles; mixed currencies cannot be silently combined. The
platform entry point now binds that controller to the shared operations store,
so Expense screens, Dashboard/Calendar projections, Reports, Job links, and
Materials sources cross the same authorized boundary. The prototype list is an
explicit unbound test fixture, not a platform source.
`expense_atomic_cutover_blueprint.md` is the authoritative current dependency
inventory for that transition. It includes Dashboard/Calendar projections,
Reports, Job links, Materials cost sources, receipt intake, and recurring
payments rather than treating the Expense landing screen as the whole system.

The recurring-obligation data system is implemented and bound for platform
sessions. It stores exact-money templates and dated occurrences separately,
supports monthly or one-time cadence, up to five reminder offsets,
pause/resume/end, occurrence-only edits, skipped history, revision/audit
evidence, private two-slot recovery, and authorized own/team/company scope. A
paid occurrence may retain an ordinary Expense ID only after that Expense was
successfully created through the ordinary authorized Expense service. The
coordinator uses a deterministic Expense ID, and a retry after an interrupted
link write reuses the exact saved Expense rather than creating a duplicate or
falsely completing the occurrence. The landing summary, list, detail, editing,
history, and reminder publisher share that authorized controller. Receipt
evidence remains a separate later slice. The bounded native reminder adapter
now schedules the same authorized recurring-Expense events on supported
platforms, with an explicit in-workflow permission action and no startup prompt;
real-device delivery acceptance remains incomplete.

The shared notification data foundation is independently implemented under
`lib/src/data/notifications/`. It stores per-recipient
localizable events and separate push/sound delivery records with stable IDs,
deduplication, exact source routes, unread/read/dismissed state,
own/team/company authorization, revision/audit evidence, serialized writes, and
private two-slot recovery. It is new UI Lab engineering rather than a 5.7
transplant. Dashboard recurring-Expense notification items, unread count,
read-state mutation, localization, and exact source routing now cross that
authorized boundary in one operation; the former prototype notification center
has been removed. The recurring-Expense native adapter uses generic localized
lock-screen copy, an ID-only payload, and exact-source reauthorization on open.
Other module publishers, configurable lock-screen preview policy, physical-
device delivery evidence, and rendered owner acceptance remain incomplete.

### Audit snapshot supporting this decision

Observed on 2026-08-28:

| Evidence | UI Lab 2.1 | Maintainiac 5.7 Active |
| --- | ---: | ---: |
| Dart files inspected under app/test/tool scope | 15 | 3,422 |
| Production Dart lines under `lib` | about 1,760 | 338,569 |
| Test Dart files | 1 | 1,636 |
| Test Dart lines | 73 | 346,153 |
| Tool/QA Dart lines | 0 | 31,583 |
| Production dependencies beyond Flutter UI basics | none | local storage, Firebase, OCR/barcode, image/document/PDF, native permissions, maps and more |

The 5.7 checkout was on
`backup/receipt-pipeline-pre-registration-2026-08-04` with extensive uncommitted
work, so it is protected source material rather than a safe direct integration
target. Its line count alone does not prove unused code: nearly half of the Dart
volume is tests, and the brief audit found real controller/store seams plus broad
behavioral coverage. A dedicated reachability and duplicate-code pass is still
required before making any deletion claim.

## 3. User and Access Model

### Confirmed principle

No permission means no navigation item, count, search result, route content, or
action for that capability. Merely hiding a widget is not sufficient protection.

### Recommended model

Use roles as editable permission templates, not permanent security identities.
An authorization decision should combine:

1. active organization and membership;
2. explicit capability;
3. allowed scope: own, assigned, team, company, or selected records;
4. resource identity and ownership;
5. record state and action being attempted;
6. explicit restrictions or denials;
7. current permission revision, especially after revocation.

Enforce the same decision at four boundaries:

- navigation and screen composition;
- queries, counts, search, and projections;
- direct routes and deep links;
- create, edit, approve, assign, share, export, sync, and delete actions.

Default to minimum necessary access. Customer prices, invoice totals, balances,
profit, company expenses, employee pay, and coworker records require distinct
explicit capabilities rather than a general "technician" or "admin" assumption.

### Initial role templates, not hard-coded limits

- Owner / solo owner-technician
- Administrator
- Office manager / dispatcher
- Field manager / lead technician
- Technician / helper
- Inventory-focused staff
- Bookkeeper
- Customer portal recipient with document-specific, revision-bound access only

### Open permission decision

The product owner's intended permission setup method still needs to be captured
before finalizing grants, denials, inheritance, exceptions, or the permission
editor. The existing 5.7 permission enums and screens are implementation
evidence, not automatic approval of that model.

The employee setup UI asks ordinary dependency-aware questions instead of
presenting a raw wall of toggles. For example, first ask whether the employee
may view estimates; only then can create, edit, approve, send, or delete
questions become applicable. Default role templates accelerate setup but never
override explicit permission and scope decisions.

## 4. Primary Information Architecture

### Persistent primary destinations

1. Dashboard
2. Work
3. Expenses
4. Materials
5. Maintenance

These are peer applications within the Maintainiac shell. Each retains the
persistent primary navigation with its own destination selected and may own
secondary tabs, queues, filters, forms, and routes. Moving between them is a
top-level workspace switch, not a push from Dashboard into a child screen.

Only authorized destinations render. Secondary destinations such as Customers,
Team, Reports, Settings, and Audit can live in a role-appropriate More workspace
or desktop navigation without crowding the primary technician navigation. The
current UI Lab Reports/Recap prototype opens from Expenses while the final
authorized More/desktop location is tested.

### Recommended name: Work

Keep **Work** as the primary destination instead of renaming the whole area
**Jobs**. Jobs are one state in a larger commercial workflow. Within Work, show
only permitted sections:

- Estimates
- Jobs
- Schedule
- Invoices
- Payments / receivables

The layout may use tabs, filters, or task queues rather than five permanent
sub-navigation items on small screens. A technician may see Assigned Jobs while
an owner sees the full commercial workflow.

Schedule is part of Work's source workflow and is projected into Dashboard and
Calendar. Whether office users also receive a top-level Schedule destination is
an open usability decision, not a separate data model.

### Confirmed Work direction

- Estimates, Jobs, and Invoices are separate primary Work surfaces, not actions
  hidden behind a floating button.
- An estimate introduces the proposed work and terms; an accepted estimate can
  transition into a job without making the estimate date the scheduled date.
- A job owns its scheduled date/time, assigned employee, assigned vehicle, and
  field execution. Invoice creation and payment follow confirmed work.
- Dashboard dates show prior-day records and recaps. Future dates show authorized
  schedule availability and conflicts by employee and that employee's vehicle.
- Start Workday begins with a required vehicle-mileage entry. Its active state
  then surfaces a compact Today at a Glance strip and the technician's next work.
- Maintenance is intentionally out of the current UI Lab build. Materials remains
  a provisional workflow until its parsing and stock direction is decided.

## 5. Module Contracts and Data Ownership

| Area | Owns | Must not own |
| --- | --- | --- |
| Dashboard | authorized projections, selected date/context, operational queues | duplicate job, expense, invoice, inventory, trip, or maintenance records |
| Work | estimates, approvals, jobs, assignments, schedule commitments, invoices, payments | receipt OCR internals, truck stock balances, vehicle maintenance history |
| Customers | customer identity, sites, contacts, communication preferences | invoice truth or job execution state |
| Expenses | expenses, receipt attachments, classification, reimbursement/approval state | inventory quantities or invoice income |
| Materials / Inventory engine | catalog, vendor cost history, truck/warehouse stock, transfers, adjustments, material usage | estimate price policy or expense ledger truth |
| Maintenance | vehicles/equipment, maintenance records, service schedules, related odometer references | trip truth or unrelated inventory stock |
| Mileage and trips | confirmed trips, odometer events, evidence proposals, workday mileage sessions | silent job completion or financial posting |
| Calendar | dated projections and explicit schedule records | copied parallel versions of source records |
| Document intake | images/files, extraction proposals, confidence and review state | confirmed financial or inventory records before user review |
| Audit and sync | immutable change evidence, version/conflict metadata, transport state | business decisions or silent conflict resolution |

Every cross-module link uses stable IDs. Editing a Calendar or Dashboard row must
route to the owning module instead of changing a copied summary.

The shell owns shared operational context: current Technician/Admin view,
Company Overview or selected employee, active vehicle/workday where applicable,
and permission revision. Module calendars share one visual and interaction
component while filtering to their owning records; Dashboard projects the
authorized combined day. Odometer events remain global vehicle/workday records,
not private copies inside Dashboard, Expenses, or Maintenance.

## 6. Core Service Workflow

The common full workflow is:

1. create/select customer and service location;
2. create an estimate or create a job directly when no estimate is needed;
3. obtain any required approval;
4. convert the accepted estimate to a job without copying conflicting truth;
5. schedule and assign the job, crew, vehicle, and required materials;
6. perform field work and record status, time, mileage, notes, proof, and
   materials actually used;
7. record linked expenses and review extracted receipt information;
8. create an invoice from confirmed billable work and adjustments;
9. record payments, balances, corrections, and authorized communications;
10. project the confirmed history into Calendar, Dashboard, reporting, and
    customer-visible views.

### Estimate, job, and invoice linkage

- An accepted estimate creates a linked job. It never deletes, replaces, or
  mutates the accepted estimate into a different record.
- A job can also be created directly for urgent or non-quoted work. Jobs own
  schedule, assignment, field status, time, materials used, customer notes,
  photos, signatures, and change orders.
- A completed or otherwise billable job creates a linked invoice. The invoice
  begins from confirmed billable work, but keeps its own payment, balance,
  delivery, and credit/refund history.
- Links are stable IDs with a visible origin: estimate to job, then job to
  invoice. Conversion must be explicit, permission-checked, and auditable.
- Pricing is selected per estimate/job: **flat rate** for an agreed scope price,
  or **time and materials** for labor hours/rates and materials quantities/rates.
  Procurement time, discounts, taxes, deposits, change orders, and actual-used
  materials must remain attributable to the source work and not silently change
  historical documents.
- Company-authored terms are reusable templates only. Each Estimate stores its
  exact Service-terms snapshot with the customer-approved revision, and each
  Invoice stores its exact Payment-terms snapshot with the issued revision. A
  later default never rewrites a signed or delivered document.

Cancellation, rescheduling, estimate revision, partial completion, return visit,
partial payment, refund, and correction flows must be designed rather than
treated as rare errors.

## 7. Dashboard Views

### Technician view

Default visible view for a technician. It answers: correct person/vehicle/work
context, workday state, what needs attention, current/next assigned work, today's
schedule, allowed quick records, and what has happened today.

The UI Lab role selector currently displays `View: Technician` as the design
state. Production availability must come from permission, not this static label.

### Admin view

Available only with the required company-scope capabilities. It centers on
unassigned/late/blocked work, crew status, approvals, scheduling conflicts,
authorized fleet exceptions, and business follow-up. Financial sections are
separately permission-gated.

### Recap view

A selected-date, read-only projection of confirmed source records. Opening Recap
must not create, repair, reclassify, sync, or finalize records.

The detailed dashboard specification should be reconciled from the UI Lab
technician blueprint and 5.7's dashboard workspace blueprint only after the
audiences and permission matrix are approved.

## 8. Inventory Direction

Inventory serves two related but different jobs and should label them clearly:

1. **Cost knowledge:** searchable material/vendor purchase history to help build
   estimates using real prior costs.
2. **Stock control:** optional truck/warehouse quantities, transfers, counts, and
   actual material usage.

Small businesses can begin with cost history without being forced into perfect
truck counts. Stock control can use confidence/status cues and fast adjustments,
but the app must never present an unmaintained quantity as certain. Material cost,
customer price, markup, and job-billed price are separate values with separate
permissions.

Release one should present this destination as **Materials** while it primarily
offers cost history, receipt-derived material review, and optional truck lookup.
The product should use **Inventory** only when the account has enabled genuine
stock control with locations, counts, adjustments, transfers, and auditable
material-use transactions. A label must never overstate the certainty of
unmaintained truck quantities.

Job-site photos and receipt evidence have different storage policy. Job photos
may be captured through Maintainiac but remain device-owned and may be exported
to the user's photo library/provider for its own backup. Receipt evidence is the
app-managed financial-proof class when the account opts into backup. Data Saver
may create smaller retained copies only after a readable preview; extraction
work uses the appropriate source image and destructive compression never becomes
the only evidence. Trial-storage and paid-plan numbers remain commercial
hypotheses until cost testing approves them and must not be hard-coded into
business records or permission rules.

## 9. Responsive and Accessibility Contract

- Base layout decisions on available logical width after navigation and padding,
  not device name, monitor size, or physical pixels.
- Phone uses one clear scroll owner and compact primary navigation.
- Medium widths use two regions only when each remains usable.
- Wide layouts use purposeful lanes with readable maximum widths rather than a
  stretched phone column.
- Required content cannot depend on horizontal card carousels.
- Text scaling, keyboard traversal, screen readers, touch targets, contrast, and
  intermediate window widths are acceptance requirements.
- Breakpoint numbers remain implementation hypotheses until verified at runtime
  on representative phone, large-tablet, and resizable desktop constraints.

Current UI Lab responsive checkpoint: the shell chooses rail or bottom
navigation from its actual local constraints rather than an ambient global
window. Dashboard, Work, Expenses, Materials, and the deferred Maintenance
placeholder use one bounded operations calculation and have rendered regression
coverage at one-, two-, and three-lane widths plus 2x text. Expenses and
Materials derive compact-versus-inline module actions from that same lane
result. Future Maintenance and Maintenance-owned Repair routes inherit this
contract; this checkpoint does not implement their business workflows.

## 10. Data Integrity, Privacy, and Assistance

### Platform payment and contract boundary

Maintainiac is presently an operations, recordkeeping, and document-delivery
software provider. It is not the service contractor, a party to the
contractor/customer service agreement, a payment processor, lender, escrow
holder, debt collector, or guarantor of customer payment. Amounts owed for the
contractor's work, the quality or completion of that work, payment-plan terms,
collection, refunds, disputes, and remedies remain between the contractor and
their customer except for Maintainiac's own separately stated software duties.

That boundary belongs in Maintainiac's platform Terms of Service and plain
onboarding/account acceptance, not in place of the contractor's Estimate
Service terms or Invoice Payment terms. Acceptance evidence retains the Terms
version, locale, account/authorized actor, UTC time, and the minimum additional
evidence required by approved policy. The current Terms remain available from
global settings, and a material revision requires an explicit versioned review
and acceptance flow rather than a silent text replacement.

The customer portal identifies the contractor as the provider of the quoted or
invoiced service and Maintainiac as the software platform. Work, price, payment,
and collection questions route to the contractor; technical portal and privacy
questions route to Maintainiac through an approved support path. This boundary
does not disclaim Maintainiac's responsibility for its own security, privacy,
consent handling, truthful delivery evidence, or applicable software conduct.
Final legal text and jurisdictional applicability require qualified legal review
before release. If Maintainiac later handles, routes, holds, finances, or
collects money, this boundary must be redesigned before that feature ships.

### Tax and recordkeeping boundary

Maintainiac is not a tax preparer, accountant, auditor, attorney, or tax-advice
service. Use of the app, its reports, receipt assistance, exports, backups, or
other records does not certify or guarantee that a business is **IRS audit
ready**, that its books are complete or accurate, that an expense is deductible,
that a classification or tax treatment is correct, or that any record will be
accepted by the IRS or another taxing or regulatory authority.

The account owner is solely responsible for entering and reviewing transactions,
correcting proposed or confirmed values, keeping records complete, accurate,
current, and separated as required, retaining original supporting documents and
independent backups for the required period, substantiating reported income and
expenses, choosing accounting and tax treatment, filing and paying on time, and
obtaining qualified professional advice when needed. An employee's entry, OCR or
AI proposal, app total, category, recap, PDF, export, or synchronization result
does not transfer that responsibility to Maintainiac.

This allocation of tax and recordkeeping responsibility does not permit
Maintainiac to misrepresent, silently alter, lose, or expose confirmed records.
Maintainiac remains responsible for its own stated software behavior, faithful
storage and rendering of committed data, authorization boundaries, security,
privacy, consent handling, and any backup or delivery service it expressly
undertakes. Final Terms and in-product plain-language notice require qualified
legal review before release.

- User-confirmed source records outrank suggestions and derived projections.
- OCR, GPS, Bluetooth, schedule correlation, and AI may propose records or
  corrections but do not silently confirm them.
- Money uses decimal-safe storage and explicit currency.
- Corrections retain audit evidence and recalculate affected projections.
- Offline writes are durable and retries are idempotent.
- Sync conflicts are visible and recoverable; "last write wins" is not an
  acceptable default for sensitive records.
- Accounting export is a separately authorized adapter boundary. A provider
  outage, expired connection, missing mapping, or queued retry never blocks a
  committed local operation or changes Maintainiac record ownership.
- Deletion policy is record-specific and auditable; cleanup is never inferred
  from a screen disappearing.
- Location, receipt images, financial details, customer data, and employee data
  follow minimum-necessary collection, display, export, and retention rules.

## 11. Scale Contract: Five to Fifty Users

- Queries are organization- and permission-scoped before aggregation.
- Employee, job, customer, and inventory collections support search, filters,
  pagination or virtualization, and stable sorting.
- The dashboard does not subscribe to every employee's detailed live state.
- Counts cannot reveal hidden records.
- Assignment and schedule writes detect conflicts and retain before/after audit.
- Company-wide changes are versioned so stale clients cannot unknowingly restore
  revoked access or overwrite a newer decision.

## 12. Integration and Sanitation Plan

### Phase 0: preserve and map

- Keep 5.7 Active read-only during discovery.
- Record the current dirty state and do not clean, reset, or delete it.
- Build a route, controller/store, native integration, schema, and test inventory.
- Map each UI Lab screen to existing production sources and missing contracts.

### Phase 1: create the protected production integration lane

- Start from an explicitly approved 5.7 snapshot in a separate branch/worktree.
- Add a feature flag or alternate shell so old and new flows can be compared.
- Introduce central navigation, operational context, and authorization contracts
  before moving business screens.

### Phase 2: technician vertical slice

- New responsive shell and Technician dashboard.
- Assigned-job list/detail and schedule projection.
- Existing workday, odometer, and trip systems behind stable adapters.
- Active vehicle and confirmed physical odometer remain shared operational
  truth. Dashboard, Expenses, Maintenance, and jobs may project that truth but
  no screen owns a competing vehicle reading.
- Positive and negative permission tests, restart proof, and real-device QA.

### Phase 3: commercial Work lifecycle

- Customers, estimates, approvals, jobs, assignment, invoices, and payments.
- Canonical conversion/link rules and correction behavior.

### Phase 4: supporting operational modules

- Expenses and receipt review.
- Materials cost knowledge, then optional Inventory stock control.
- Maintenance and shared Calendar/Recap projections.

### Phase 5: evidence-based sanitation

For every suspected unused file or duplicate, require import/route/registration
tracing, serialization and migration checks, native callback checks, focused
tests, full relevant regression tests, and a rollback path. Produce a proposed
removal list for owner approval before deleting anything.

Large files and old names are audit leads, not deletion evidence.

## 13. Acceptance Gate for Every Migrated Slice

A slice is complete only when:

- product behavior and permission matrix are approved;
- source ownership and migration behavior are documented;
- query, route, action, export, and sync enforcement agree;
- denied users cannot infer protected data;
- offline/restart/interruption and correction cases pass;
- responsive and accessibility checks pass;
- old and new behavior are compared where parity is intended;
- known gaps and rollback steps are recorded;
- the product owner has completed visual acceptance.

Compilation or a green unit test alone is not acceptance.

## 14. Decision Register

### Confirmed now

- Primary market: service technicians and small service businesses.
- Scale target: small teams first, with no structural ceiling at five users.
- Primary destinations: Dashboard, Work, Expenses, Materials, Maintenance.
- Permission-denied administrative UI should not appear.
- Current UI Lab view label: Technician.
- Responsive behavior uses Flutter logical constraints.
- Option A with a separate, protected 5.7-derived integration lane.

### Recommended for review

- Keep Work as the umbrella name.
- Roles seed editable permissions; capability and scope enforce access.
- Materials supports cost knowledge; the Inventory label appears only when the
  account enables genuine stock control.
- Dashboard and Calendar are projections, not record owners.

### Open workshops

1. Capture the product owner's intended permission setup, including exceptions,
   explicit denials, temporary access, and who may grant access to whom.
2. Approve the Work lifecycle and decide which office users need a top-level
   Schedule surface.
3. Decide whether gig-driver mode remains a supported product profile or becomes
   legacy migration scope only.
4. Complete the release-one document portal security policy: opaque QR/link
   tokens, recipient verification, expiry/revocation, signatures, and audit.
5. Define estimate pricing, markup visibility, change orders, deposits, taxes,
   invoice corrections, refunds, and payment methods.
6. Define inventory confidence and stock-adjustment workflows for teams that do
   not maintain exact truck counts.
7. Approve the permission matrix before redesigning the production dashboard.


## Owner-confirmed direction update — 2026-09-04

This section records current product-owner decisions and overrides conflicting older AI-authored documentation.

- Historical Maintainiac documentation was AI-authored. It is discovery evidence only unless the product owner explicitly confirms the requirement during current review. Existing documentation must never be presented as proof that the owner previously approved a product decision.
- Maintainiac's primary market is contractors and small businesses. Service technicians are a primary field-user type within that market.
- Gig drivers, rideshare drivers, delivery drivers, and other vehicle-based workers may still use applicable Maintainiac features, but they are secondary audiences. Their workflows must not drive the core product architecture or weaken contractor and small-business operational workflows.
- Scheduling is an operational planning system, not merely a calendar. Maintainiac must help an authorized planner compare estimated labor requirements with employee availability, existing commitments, and employee skills before confirming work.
- Schedule assistance is advisory. Maintainiac may identify overbooking, understaffing, skill shortages, and better alternatives, but an authorized user confirms assignments and schedule changes.
- When the product owner describes a desired outcome or implementation idea, the design/build process must challenge weak, risky, unnecessarily complex, or non-standard implementation approaches and explain a stronger production pattern before Codex is instructed to build it. The owner's desired business outcome remains authoritative; implementation mechanics are open to professional review.
