# Maintainiac Product Control Blueprint

Status: governing working draft 0.1  
Purpose: the one control document an engineer or Codex agent reads before
adding, moving, or wiring a product surface.  
Scope: application architecture and screen/system ownership. Start at
`README.md` and `application_decision_register.md`.

This document does not replace the detailed visual, operations, or Work
lifecycle blueprints. It makes them enforceable: no screen, button, permission,
query, route, record link, integration, or test obligation may be invented in
isolation.

## Blueprint changes: check existing requirements first

Owner requirement, September 5, 2026. Applies to every agent and every request
to add or change blueprint content:

- Before writing, search all repository blueprints, working contracts, and
  handoff documents for the requirement, including equivalent wording. Read
  matching sections and their references; checking only the destination file
  is insufficient. Inspect relevant implementation when the requirement also
  concerns behavior that may already exist.
- Tell the owner what already exists, what is missing or conflicting, and
  what change is proposed before editing. Do not present an incomplete search
  as proof that a requirement is absent; disclose inaccessible material.
- If the requirement exists, update its authoritative section only as needed
  and cross-reference it elsewhere rather than adding a competing copy. If it
  is absent, add it once in the appropriate owning blueprint. Preserve
  unrelated requirements and distinguish superseded decisions explicitly.
- Distinguish documented requirements from implemented behavior and verified
  results. Documentation does not prove functionality, and passing checks do
  not prove that the product meets the owner's intended workflow.

## 1. Authority and non-negotiable rules

Priority order for a conflict:

1. explicit product-owner direction in the current task;
2. owner-evidenced ACCEPTED/CANONICAL decision-register entries;
3. their owning sections indexed in `README.md`, including this document;
4. inherited module proposals and implementation observations, labeled separately;
5. read-only 5.7 behavior evidence;
6. a proposal, which must be labeled **Open** and not silently shipped.

Product rules:

1. Accuracy, privacy, security, dependability, auditability, and consistency
   outrank visual novelty and implementation speed.
2. UI Lab 2.1 is the presentation proving ground. Maintainiac 5.7 Active is
   protected source and behavioral evidence until a specific port is approved.
3. A projection never becomes a second source of truth. Dashboard, calendar,
   recap, count, and report rows always open their owning record.
4. A role is a starting template. Capability, record scope, record state, and
   an active permission revision decide authority.
5. No permission means no navigation item, query result, count, deep-link
   content, action, export, cached preview, or sync payload for that thing.
6. OCR, GPS, AI, receipt parsing, and sync can propose. Only an authorized
   human confirmation creates or changes confirmed business truth.
7. Every ordinary action has a plain-language label. An icon may reinforce a
   label; it never replaces one for routine work.
8. Authored production files target 500 lines. Split by cohesive responsibility;
   document safe exceptions rather than sacrificing functionality to a count.
9. Maintainiac is a recordkeeping/document platform in the current product
   boundary, not a party to contractor/customer work or a guarantor/collector
   of customer payment. Platform Terms, contractor document terms, and customer
   payment-plan consent are separate versioned agreements.
10. Maintainiac does not certify that an account or export is IRS audit ready,
    complete, tax-compliant, or acceptable to a taxing authority. The account
    owner remains responsible for reviewing, correcting, retaining, and keeping
    business records accurate and current; this boundary does not excuse the
    platform from faithfully preserving confirmed data or meeting its own
    security, privacy, consent, and software obligations.

## 2. Shared system contract

| Shared element | Owner | Required behavior | Cannot do |
| --- | --- | --- | --- |
| Shell navigation | application shell | Show only authorized peer modules; retain selected module/context | grant authority or own records |
| Operational header | shared header | Dark charcoal; menu/back, optional screen action, context, View, contextual settings | privately change ordering, colors, or breakpoints |
| View and scope | operational scope | Technician first, Admin second; persist Company Overview or selected employee across peer modules | bypass authorization |
| Vehicle/odometer | vehicle/workday services | Show selected vehicle and confirmed odometer together in header; physical reading is official | create competing per-screen readings |
| Calendar | shared calendar projection and presentation | Same selection/accessibility language; filter module views to owning records; combine authorized module events on Dashboard | own, duplicate, or silently mutate source records |
| Page settings | current screen | Required for top-level modules, Calendar, Repairs, receipt camera and Data Saver; meaningful permission-scoped choices for that page and related behavior | become an unrelated global control panel or fake working placeholder |
| Company/account settings | organization or user preference owner | Identity, shared defaults, language/units, privacy, storage and notifications by scope | override page ownership or silently rewrite history |
| Notifications | shared notification service | Project permission-scoped reminders/updates, unread state, channels, and exact owning-record routes | replace Needs Attention, approve work, or claim platform delivery without adapter evidence |
| Customer reminder delivery | outbound document communication | Send consented payment-plan reminders for an exact Invoice/plan revision through approved channels | infer consent, become chat, change a balance, or enter employee unread counts |
| Accounting connections | provider-neutral accounting integration | Queue authorized exports of confirmed records through mapping, idempotency, conflict, retry, and audit contracts | own operational records, block offline work, or leak provider schemas into screens |
| FAB/quick actions | current screen | Open a labeled action directory appropriate to context | conceal ownership or bypass validation |
| Documents | document engine | Render exact estimate/invoice version, template, and document-specific terms snapshot; issue a revision-bound secure portal link and matching contractor QR code | mutate confirmed financial data, replace historical terms from a newer default, expose raw IDs, or become a chat system |
| Audit/sync | platform services | Record source, actor, time, revision, conflict state | silently resolve sensitive conflicts |

The detailed notification contract is `notification_system_blueprint.md`.
Notifications, Needs Attention, and record activity/notes are separate systems;
release one does not repurpose any of them as unrestricted employee chat.
The future accounting boundary is `accounting_integration_blueprint.md`.
QuickBooks is an adapter behind that boundary, not a release-one dependency or
a second owner of Maintainiac records.

Responsive contract: use available logical width after navigation and insets,
plus Flutter `TextScaler`. Never branch on operating system, device name, or
physical pixel count. Required content wraps/reflows for accessibility; it does
not clip, ellipsize, or quietly disappear. Each screen imports
`AppLayoutEngine`; no private breakpoint calculation is allowed.

## 3. Authorization decision

An attempted operation is allowed only when all checks pass:

1. valid local owner context for account-free operation, or authenticated
   membership for shared/team/cloud resources; no universal sign-in gate;
2. explicit capability for resource and action;
3. allowed scope: own, assigned, team, company, selected employee, or selected
   record;
4. record state permits the transition;
5. user has not been explicitly denied/restricted;
6. current permission revision is still valid;
7. any required consent, approval, or confirmation is complete.

Customer approval is revision-bound. Changing any customer-visible estimate
field invalidates the current signature regardless of the dollar amount. Keep
the old signed revision as superseded audit evidence, return the new revision to
approval required, and block job conversion until that exact revision is
approved. Never transplant an old signature onto revised content.

Company estimate review, when required by policy, is a different revision-bound
decision. `estimate.approve.company` allows customer delivery of that revision;
it does not create customer acceptance. Return and rejection require a reason,
retain history, and route the exact record back to its authorized creator.
Changing customer-visible content invalidates both prior company permission to
send and any prior customer signature for the superseded revision.

Every protected operation has four enforcement points:

| Boundary | Required result |
| --- | --- |
| Navigation/composition | unavailable feature is absent |
| Query/search/count/cache | unauthorized records cannot be inferred |
| Route/deep link | direct navigation rechecks authority and scope |
| Mutation/export/share/sync | server/service rechecks at execution time |

### Capability grammar

Use a resource plus action plus scope, not vague role checks. Examples:

`estimate.view.assigned`, `estimate.create.own`, `estimate.approve.company`,
`job.assign.company`, `expense.review.team`, `employee.pay.view.company`,
`receipt.confirm.assigned_job`, `report.profit.view.company`.

Capabilities are grouped for setup questions, but stored/evaluated individually.
An employee who cannot view a resource cannot create, edit, approve, send,
export, or delete it. Sensitive visibility is separate: view customer contact
does not imply view cost, markup, pay, profit, private notes, or receipts.

### Initial role templates

Owner/solo owner-technician, Administrator, Office manager/dispatcher, Lead
technician, Technician/helper, Inventory staff, Bookkeeper, and optional
customer portal user are editable starting templates only. The owner-facing
setup asks dependency-aware ordinary-language questions, for example: “Can this
employee view estimates?” then, only if yes, “Can they create, edit, approve,
send, or delete estimates?”

## 4. Record ownership and links

| Record | Sole owner | Required links | Key state rules |
| --- | --- | --- | --- |
| Customer/site/contact | Customers | organization, service sites, documents/jobs | detail-first view; edit opens prefilled form |
| Quote | Work / Quotes | customer/site, revisions, proposed work; conversions unresolved | distinct required capability, not automatically an Estimate synonym (U04) |
| Estimate | Work | customer, site, items, template, revisions, attachments | sent/accepted/declined/expired; accepted estimate remains immutable quoted source |
| Job | Work | optional estimate, schedule, assignment, vehicle, field evidence | direct or estimate-created; scheduled state is not completion |
| Invoice | Work | optional job/estimate, document version, payments | own delivery/balance/credit history; never overwrites estimate |
| Payment | Work | amount, date, method, description; invoice/job/estimate link optional | invoice-linked payments affect only that invoice's balance; a prior job/estimate payment needs an explicit application event to affect a later invoice; quote links require saved Quotes |
| Expense | Expenses | payer, category, vendor, receipt, optional job/customer | confirmation can offer cost history/actuals; never posts automatically |
| Receipt/document evidence | Document Intake | source image/files, proposals, allocations, confirmation event | source retained; proposals are reversible until confirmed |
| Material cost history | Inventory | vendor, unit/pack, receipt/expense, confirmer | distinct from markup/customer price/stock certainty |
| Stock transaction | Inventory | location, quantity, cause, optional job/receipt | optional; unmaintained quantity is never presented as certain |
| Vehicle/odometer/workday | Mileage/trips | vehicle, employee, readings, consent/evidence | physical odometer official; start/end are explicit transitions |
| Maintenance record | Maintenance | vehicle/equipment, interval, date/mileage/runtime evidence | cannot own trip, expense, receipt, or inventory truth |
| Repair record | Repairs within Maintenance | vehicle/equipment, report, diagnosis, work, parts, downtime, return-to-service evidence | cannot replace linked expense, inventory, or technician-time truth |
| Audit event | Audit | actor, record, source, old/new values, permission revision | append-only evidence |

All cross-module relationships use stable IDs. Deleting or hiding a projection
never deletes the source record. Destructive actions require resource-specific
retention/correction rules and an audit event; no generic “delete everything”
behavior exists.

## 5. Lifecycle register

### Customer → estimate → job → invoice → payment

1. Create/select customer and site; review their history.
2. Create estimate or direct job. Estimate records scope, labor, materials,
   fees, procurement, quantities, costs, customer prices, taxes, discounts,
   deposits, terms, expiry, notes, attachments, and template/version.
3. Preview the exact customer document. Authorized user sends, revises,
   withdraws, or records customer decision.
4. Acceptance exposes **Create and plan job**. It does not automatically create
   a job. The resulting job links the accepted estimate and requires schedule,
   employee/crew, vehicle, duration, conflict, and material-readiness review.
5. Field work records status, time, mileage, notes, photos, receipts, actual
   material usage, changes, signatures, incomplete/return-visit state.
6. A completed job may close without an invoice. If the business wants one, an authorized user can create an invoice. The invoice has
   a separate customer-facing version, delivery, terms, balance, payment,
   correction, credit/refund, and collection history.
7. Dashboard, calendar, reports, customer history, and recap project confirmed
   events; they never rewrite the source lifecycle.

### Receipt → expense/material/job allocation

The canonical detailed parsing and UI handoff is
`receipt_material_intake_blueprint.md`. It defines printed-row versus logical-line
counts, package contents and per-piece math, multi-destination allocations, job
FAB sources, core catalog packs, permissions, offline conflicts, and acceptance
tests. Receipt Assistant is optional customer-facing language; manual entry and
line-by-line correction remain available whether the assistant is on or off.

1. Capture/attach one or more receipt images to Document Intake.
2. Stitch long receipts only as source evidence; retain original images/order.
3. Extract vendor/date/tax/total/lines as a proposal with confidence and parser
   version.
4. User reviews and corrects the proposal before confirming any expense,
   material cost, stock intake, or job actual.
5. A single-job receipt may default lines to one selected job only after review.
6. For multi-job receipts, user assigns individual lines to jobs; the system
   never evenly splits values or guesses allocations.
7. Confirmation records actor/time/changes/source linkage. It may offer a
   material-cost update or job actual; it never silently changes estimate
   price, invoice, stock, or job completion.

## 6. Screen and action register

Every listed screen needs: purpose, owner, context, authorized queries, empty /
offline / denied / conflict states, contextual settings, audit events, and
positive and negative permission tests. “Open” means a design requirement has
not yet been approved, not permission for an agent to improvise.

| Screen/workspace | Answers | Owner | Context | Permitted primary actions |
| --- | --- | --- | --- | --- |
| Dashboard | What do I need to do today and what happened? | projections | employee/company, date, workday/vehicle | Start/Open/End workday; open job/entry; authorized add actions |
| Work home | What commercial/field records need attention? | Work projections | employee/company, date | open Jobs/Estimates/Invoices/Payments/Customers; authorized New |
| Quotes | What proposed work needs preparation or response? | Work / Quotes | customer/site/revision | complete workflow required; acceptance and conversion rules await U04 |
| Estimates | What was proposed and what needs a decision? | Work | employee/company, date/search | create, attach internal job-site photos, edit, preview, send, approve, accept/decline, create/plan job |
| Jobs | What is scheduled, active, blocked, or complete? | Work | employee/company, date/filter | create, assign/reassign, schedule/reschedule, change status, open active job |
| Active job | What work is to be done and what evidence/actuals exist? | Work | job | call/message, notes, photos, receipts, actual materials, change, complete, return visit |
| Invoices | What is billed, due, overdue, or paid? | Work | employee/company, date/filter | create, edit permitted draft, preview/send, record payment, credit/refund |
| Payments | What was collected and what remains? | Work | invoice/customer/date | record, correct, refund, receipt/export if granted |
| My Info | What company identity appears on documents? | Customers/company profile | organization | view; edit prefilled profile; manage logo with explicit confirmation |
| Saved Clients | Who are the customers and what history do they have? | Customers | authorized organization | search, open detail, add, edit; no implied financial visibility |
| Expenses | What did this scope spend and what evidence needs review? | Expenses | employee/company, date | record expense, fuel, receipt; review/approve; link job |
| Receipt review | What did this evidence say and where does it belong? | Document Intake | receipt/source record | correct, allocate lines, confirm/reject proposal; preserve source |
| Materials | What did we pay and what stock do we know? | Inventory | employee/company and location | lookup cost; record verified purchase cost; open source evidence; verify a chosen physical count; adjustment/transfer only if granted |
| Maintenance | What service is due or completed for equipment? | Maintenance | vehicle/equipment | record service, schedule, attach evidence |
| Reports/Recap | What do confirmed records total for this period? | projections | authorized scope/date/filter | drill into source; export if granted |
| Team/Employees | Who can do what and what is their status? | organization/permissions | company | add/edit/inactivate employee; permission interview; assign context |
| Vehicles | What assets are available and what are their readings? | vehicles | company/assigned | view/edit authorized profile; assign; odometer/maintenance links |
| Audit/Sync | What changed and does it need attention? | audit/sync | authorized company/record | inspect history, retry allowed sync; no silent repair |
| Reminders and updates | What scheduled information should this person see? | notification projection | authorized employee/company scope | mark read; open exact source record; delivery settings if granted |
| Customer document portal | What exact Estimate or Invoice did the contractor share? | customer-safe document projection | opaque secure link to one recipient/revision | view/download; Estimate approve/sign, decline, or request changes; Invoice report correction; no chat or customer record editing |
| Customer payment plan | What installment schedule did this customer accept? | Work / Invoice | exact Invoice and plan revision | review/accept plan; separately opt in or revoke reminder channels; never mark a Payment merely from reminder activity |

### Button/action implementation rule

Before adding a button, register all of these in its module blueprint or test:

1. visible label and accessible semantic label;
2. owning screen and owning business resource;
3. capability/scope/state preconditions;
4. exact route, dialog, or state transition;
5. validation, cancellation, duplicate-submit, offline, and denied behavior;
6. audit event and source links for a mutation;
7. destination owner's responsibility after navigation;
8. positive, negative, and accessibility regression tests.

No button may exist merely because a prototype needs something to tap. A disabled
control explains what condition is missing only when revealing that condition is
itself authorized; otherwise it is absent.

## 7. Workday controls

Owner update D25: users need not create a vehicle profile to use the app. Supply
one ready-to-use vehicle identity without labeling it “Default vehicle.” A user
tracking two vehicles needs two distinct profiles; readings/trips must never
merge across them. Display name is unresolved. Required vehicle/odometer checks
below concern a vehicle-based workday action, not a universal app-entry barrier;
non-vehicle recordkeeping cannot require completing a vehicle setup form.

Start Workday: confirm eligible person/work context, active vehicle, and
physical odometer; explain optional GPS/trip assistance; reject an odometer
below last confirmed reading; confirm exactly once; create no partial record on
back/cancel. Active day: global header retains vehicle and confirmed odometer;
summary shows active time, miles today, next job, and status. Action directory
uses compact labeled tiles: Pause/Resume, End Workday, Add stop, Fuel, Expense,
Receipt, Note, Estimate, limited by capability and screen setting. End Workday
requires another physical odometer review and creates a recoverable ending event.

Calendar dispatch follows `calendar_system_blueprint.md`. Dashboard calendar is
the combined authorized projection;
module calendars filter the same projection to their owning records. A day tap
pushes Calendar Day. An authorized Admin may reassign or reschedule unfinished
jobs between employees there, including same-day load balancing. The mutation
must update Work's assignment/schedule record by stable ID, detect conflicts,
retain before/after audit, queue safely offline, and refresh every affected
Dashboard projection. Calendar never owns a duplicate assignment.

Calendar Day keeps the selected employee or Company Overview in the shared
header. Pending approvals precede day metrics and chronological entries. Review
changes approval state while preserving the source entry's original event time.
Phone metrics use compact horizontal cards; wide windows use bounded shared
layout lanes. Past, present, and future dates render recorded entries, today's
plan plus entries, and planned work respectively. Expense, Work, Inventory, and
other module calendars push their own filtered day routes; they never substitute
a private body-state change for navigation.

Dashboard and Calendar Day must query and mutate the same record by selected
date and operational scope. Approval, plan, and entry changes made in Calendar
Day are visible after Back without a second copy or manual refresh. Technician
vehicle selection is likewise shared operational context; Admin Fleet Overview
and per-truck drilldown do not create employee-owned inventory.

## 8. Required state coverage

Each resource/action must explicitly test: normal success; no permission;
wrong scope; stale permission revision; invalid state transition; validation;
cancel/back; duplicate tap/retry; offline/restart; conflict/sync retry; loading;
empty; long/localized text; text scaling 1.0/1.3/1.5/2.0; 320/360/390/412,
tablet, narrow desktop, 1440, and wide desktop; light/dark contrast; keyboard,
screen reader, and touch target semantics.

## 9. Migration decision and gates

Recommended strategy: **staged migration, not wholesale rewrite**.

1. Keep UI Lab as the approved UI/layout/interaction source of truth.
2. Keep 5.7 read-only during the architectural census; do not delete, reset,
   “clean up,” or call code unused without reachability/dependency/test evidence.
3. For every production port, map 5.7 route, model/IDs, controller/store,
   persistence, permission provider, sync/audit behavior, native integration,
   fixtures, and tests.
4. Classify each discovered implementation: reuse unchanged; adapter; replace
   presentation; consolidate duplicate; retire only with proof; or Open risk.
5. With 2.1 selected by D30, port one complete vertical slice in a
   separately approved integration boundary. Compare old/new behavior, run tests,
   restart/offline checks, and owner visual review before defaulting it on.
6. Move in dependency order: shared authorization/context/adapters; Dashboard
   and active workday; Work lifecycle; Expenses and receipt review; Inventory;
   Maintenance; reports/recap. Expenses may be blueprinted next, but receipt
   stitching remains a distinct production integration slice.

The destination is 2.1 under D30, not a production-readiness certification.
Assess existing systems in BOTH repositories,
including storage/Hive, OCR, GPS, inventory parsers/trade packs, permissions and
sync. Existing tests and documentation do not establish independent correctness.
The migration map owns dependency/gate detail. App-wide cloud authority, local
state, external media, paid backup and retention belong to
`data_storage_sync_contract.md`, not a legacy optional-mirror assumption.

## 10. Traceability and completion rule

Every future change must update, in the same review:

- this register if it adds/changes a screen, action, capability, record owner,
  integration, or migration rule;
- the module blueprint for detailed flow and layout;
- widget/unit/integration tests for success and denial behavior;
- source-size and responsive/accessibility regression evidence;
- migration mapping when production code is involved.

An implementation is not “done” because it compiles. It is complete only when
its route, authority, source ownership, validation, audit, QA evidence, and
owner visual acceptance are all known.
