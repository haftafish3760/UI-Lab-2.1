# Business application delivery roadmap

Product name: **[not selected]**  
Owner conversation captured: 2026-09-11  
Status: owner requirements captured; implementation order below is the proposed
working plan. A checked document is not a finished application.

## How we will work

Expense/OCR assignment, September 15 (Windows UI Lab task): the owner explicitly
authorized continued local expense receipt, OCR/parsing, device workload and
SQLite materials work, with a separate native Flutter receipt generator. This
bounded assignment supersedes the older UI-only restriction below for these
systems only. Preserve the other task's Dashboard/Work/PDF changes; do not touch
the PDF engine, Firebase services, router or network settings. Windows UI Lab
remains under the owner's VS Code session. Physical receipt-flow testing is
limited to the S25 Ultra; no other phone is authorized. The governing receipt
requirements and 97–98% accuracy target remain in
`receipt_material_intake_blueprint.md`; current evidence and gaps are recorded
in `receipt_hardening_evidence.md`. This does not authorize publishing, cloning
or modifying the protected 5.7 reference.

Latest scope clarification, September 11: this task owns **UI/UX only**. The
owner is assigning the data layer and inventory migration to another Codex task.
The storage observations below are handoff evidence, not authorization for this
task to change schemas, repositories, GPS or odometer services. Start Workday
presentation can proceed against existing interfaces; missing service behavior
must be identified honestly and coordinated with its owner. The current owner
direction is to work through SSH in `/Volumes/AppleWork/UI-Lab-2.1`, preserving
the Mac's existing VS Code Flutter session. Publish Windows work to the shared
GitHub repository, then update this existing checkout in place, never as another
clone. Verify the running app belongs to the edited checkout; saved source and
Git synchronization alone do not prove that hot reload has updated the display.

One agent works with the owner on one complete workflow at a time. The owner
will choose separate agents for inventory and GPS/odometer extraction. No agents
are created by this roadmap. Separate GPS versus odometer assignments must agree
on a single owner for overlapping files and contracts before integration.

For each slice: inspect existing code and protected 5.7 evidence; explain the
normal path and exceptions in plain language; implement against existing owning
services; exercise saves/restarts/denials and narrow/wide layouts; review it with
the owner; record remaining limits. Do not claim visual acceptance from tests.
Keep manual operation independent of AI, GPS, inventory and cloud availability.

Current messages outrank inherited AI-authored documents. The owner has NOT
reviewed/approved every old blueprint paragraph. Confirmed requests, proposals,
source observations and verified results must remain separate. No blanket claim
that every possible edge case or every security issue has been eliminated.

Brand choice remains blank. Existing package IDs, Firebase registrations,
database paths and Git repository names are technical identities, not permission
to rename them. Review identity/migration effects separately after name selection.

## Workspace purposes — proposed navigation, required capabilities

The previous assistant assertion that there can be only two dashboards is withdrawn.
Do not require a small business to configure multiple duplicate dashboards.

| Workspace | Question answered | Access and scope |
| --- | --- | --- |
| My Work / Technician | What am I doing today, what is next, and what have I recorded? | Actual signed-in/local owner person; clearly label My schedule and date. Owner-technician sees their own assignments here. |
| Business Overview / Admin | What needs attention and how is the company doing? | Authorized company totals and decisions; not technician Plan/Entries by default. |
| Dispatch / Scheduling | Who can do this work, when, and what must change? | Assignment capability without automatically granting profit, wages or other finance access. |
| Financial Reports / Recap | Where does money go and how do results compare? | Authorized financial scope; finance-only users need not access GPS or dispatch. |

These are purposes within one system, not four new record stores or four mandatory
setup wizards. Navigation labels/placement remain to review. Existing bottom
destinations are not replaced without reviewing the whole navigation workflow.
Selecting an employee from Admin opens that employee's dated work: completed,
current and remaining assignments, with a visible return to Company Overview.
Different employees share a job only when actually assigned together. A selected
employee filter must never change the actor performing an action or grant access.
Location/activity detail requires its own authorization, consent and freshness.

## Ordered delivery map

| Order | Slice and user-visible outcome | Exit evidence / prerequisite |
| --- | --- | --- |
| 0 — current | Start Workday: correct person, vehicle and reading; clear manual/GPS state; recovery and visible start action | See [Start Workday review](start_workday_workflow_review.md). Keep existing SQLite confirmation/drafts; coordinate discrepancy contract before engine extraction. |
| 1 | Active day and My Work: Pause/Resume Day, Add fuel, Add expense, material/receipt entry, End Day; own schedule clearly identified | Real owning routes, offline save/restart, no duplicate fuel expense or invented distance; three Plan/Entries previews on mobile. |
| 2 | Job visit: Arrived, running elapsed time, Pause/Resume, Finish Job and return visit | Persisted time events, interruption-safe timer, actual versus planned duration, permission-aware completion-to-invoice handoff. |
| 3 | Business Overview and employee drill-down; Dispatch reassigns unfinished visits | Company facts replace copied technician cards; conflicts checked at confirmation; stale/offline assignments visible; protected actuals do not move with assignments. |
| 4 | Estimates, Quotes and Invoices: complete forms, drafts, preview, revisions and billing | Read 5.7 Active Create New Estimate/Invoice form first; correct document-specific labels; manual items always usable; no duplicate conversion on retry. |
| 5 | Expenses/receipts and optional allocation to job or inventory | Preview, correction, category, confirmed allocation, linked evidence and no duplicate expense/cost. Inventory engine remains separately owned. |
| 6 | Financial Reports/Recap: day/week/month/year/custom period, category and job drill-down | Independently reconciled fixture totals, partial payments/refunds, missing-cost labels, source links; no tax/payroll deduction engine. |
| 7 | Profiles, contextual settings, localization and unit coverage completed across accepted slices | Employee/vehicle identity, permissions and unit contracts start in slice 0; this is the cross-app completion sweep, not permission to defer essentials. |
| 8 | Maintenance and Repairs, distinct connected workflows | Separate intake/lifecycles, shared assets and expense links; receipt-assisted service logging requires review, never silent confirmation. |
| 9 | Firebase identity/sync/backup plus lightweight customer portal | Isolated project, explicit access/rules/retention design, secure documents and recovery; local workflow work does not wait for branding. |
| 10 | Simulated-company acceptance and release hardening | Three computers/four phones, different responsibilities, denied access, offline conflicts, restores and actual narrow/wide task completion. |

Security contracts, accessibility, English/Spanish and units are part of EVERY
slice, not postponed to the final phase. Firebase implementation can begin once
the owner supplies the isolated project; multi-device acceptance requires it.
Customer portal development may overlap later slices only with explicit scope.
No dates or claim of percentage complete are assigned without measured evidence.

## Start / work / finish behavior to implement

- Start Workday is explicit and creates one durable session, not a booked job,
  payroll calculation, or automatic business-mile classification. Owner
  clarification September 18: it must also support employee time recording and
  accessible weekly-hours review, as specified in
  `operations_screen_blueprint.md`, “Employee weekly hours.” This supersedes any
  reading of the earlier “not employee payroll clock-in” wording as excluding
  employee worked-time records; payroll processing remains outside this request.
- Vehicle and odometer belong beside one another. Clearly distinguish last
  confirmed reading from today's input, with unit and date. Never seed a real
  reading from a demo value, historical average or zero meaning unknown.
- Strong opaque Start action: owner requests the bright 5.7 Active green.
  Source inspected: `lib/screens/dashboard/start_day_panel.dart`, `_green`
  `#20F060`. Reuse the color, not its round button, glow or heavy font treatment.
- Workday quick actions must reach Fuel and Expense entry without visiting a
  module landing screen first. Desktop/wide uses labeled visible actions;
  narrow presentation may use an accessible action menu. Existing owners save.
- Arrived starts the job-presence/time event. Pause/Resume and Finish Job follow;
  restarting the process cannot reset elapsed time. Presence is not automatically
  billable labor: billing policy and reviewed time remain distinct.
- Finish Job leads an authorized biller through an invoice draft/review. A
  technician without billing authority hands off to office billing. Work can be
  saved complete while invoicing/delivery remains pending or offline.
- Completed jobs create/update dated actual projections once. Proposed display:
  completed Plan items move below remaining work with a text status, not color
  alone. Keep this display choice reviewable; do not duplicate actual entries.
- Start Travel is optional in quick actions, not a forced prominent primary
  button. Finishing an invoice must not silently assert driving has begun. Show
  the next assignment; record travel only via explicit action or opted-in, clearly
  identified GPS assistance. Pauses, lunch, detours and no next job are valid.
- Delivery offers email, device share/text, print and portal where available;
  show draft/queued/handed-off/delivered honestly. An opened share sheet is not
  proof the customer received anything. Completion must not depend on delivery.

## Dispatch example and safeguards

Technician B finishes early; Technician A still has work. Show remaining work and
confirmed availability, not just stop count: four long jobs may exceed seven
short jobs. Planner chooses an unfinished visit to move, reviews B's time,
duration, travel allowance, service window, required skills/resources, breaks and
assignment conflicts, then confirms. Unknown travel/location is labeled unknown;
manual planning remains available. Preserve previous assignment and audit reason.
Recheck revisions at save; a second dispatcher must not silently overwrite the
first. Notify the affected workers when a real delivery channel is available.
Never move completed work, expenses, payment events or past time records to B.
See [Scheduling](scheduling_system_blueprint.md) for owning engine contracts.

## Commercial records and optional module connections

Owner distinctions: Estimate is a proposed approximate cost; Quote is a proposed
fixed price and can be itemized or a single service price; Invoice is the bill.
Pricing method and itemization are separate choices. Exact terms and revision/
acceptance policy still need review; these definitions are not legal guarantees.
Never reuse an old signature to imply acceptance of changed customer-visible
content. Preserve the old signed revision and identify what changed.

Read the actual 5.7 Active form opened by Estimates > FAB > Create New Estimate.
Its inherited Invoice Information/title/number/PO/date/due-date wording is
evidence of layout, NOT correct Estimate terminology to copy. Consider estimate
valid-until versus invoice due date, customer/site, scope, items/labor, totals,
terms, attachments, preview and delivery in the complete workflow.

Estimates/Quotes work without Inventory: add a manual item or choose a catalog/
inventory item. Snapshot description, unit, quantity and chosen price/cost with
source ID/version; later catalog changes cannot silently rewrite issued documents.
Picking an item must not deduct stock. Reservations and consumption need explicit
inventory-owned transactions. Keep historical purchase cost, stock and selling
price distinct. Inventory migration/parsers/trade packs are NOT this task.

Receipt intake asks where reviewed lines belong: expense category, job cost,
optional stock intake, or split destinations. Keep the original evidence and
one linked expense; prevent double counting or multiplying stock on retries.
Parser output is editable proposed data, not proof that every Lowe's item was
recognized. Maintenance receipt linkage is a later reviewed workflow.
Detailed owners: [Work](work_lifecycle_blueprint.md),
[Receipt intake](receipt_material_intake_blueprint.md).

## Business reporting requirements

Admin prioritizes collected money, recorded spending, unpaid/overdue balances,
active/unscheduled/blocked jobs and actions needed now. An employee schedule
appears after selecting that employee; company-level workload belongs to Dispatch.
Reports covers day/week/month/year/custom periods and spending by category,
vendor and job with source-record drill-down, not unsolicited saving advice.

Define each metric before implementation: issued invoices are not collected
payments; unpaid balance reflects partial payments/credits; cash movement is not
automatically profit. Show recorded net cash separately from job margin and any
profit calculation. Missing labor/material/overhead costs must be disclosed, not
treated as known zero. Agree report basis, time zone, refunds and cost-allocation
rules before applying a Profit label. Hours x agreed rate can track labor cost;
no payroll withholding, payroll tax computation or take-home-pay claim.

## Global and contextual settings

Hamburger menu contains global settings: account/company, language, display
units, backup/sync, privacy and common permissions. The gear belongs to the current
screen/workflow: Dashboard, Job, Estimate, Quote, Invoice, Expenses, Inventory,
receipt camera and App-assisted receipts. Shared preferences have one owner.
Where Expenses contains several workflows, use clearly labeled settings groups
or a contextual gear on that workflow; avoid several indistinguishable gears.

Proposed GPS split: global privacy/collection/sharing defaults; trip-workflow
settings for assistance behavior; Start Workday reviews effective choice and
actual platform availability. Dashboard gear controls its own presentation and
quick actions. This split remains a proposal, not a shipped policy.
Suggestions are optional, dismissible and can be turned off. Necessary validation
and actionable save failures must remain visible; they are not marketing tips.

## Languages and measurements

English and Spanish are required; Canadian French is requested. Use regional
locale support with readable service-business terminology and native-language
review; do not equate nationality with a language setting. U.S. Spanish is a
starting locale, not proof every regional term is covered. Louisiana French
coverage is an open research/translation decision, not equivalent to fr-CA.
User-switchable U.S./Metric is independent of language, currency and each
vehicle's physical odometer unit. Never relabel miles as kilometers without
conversion or change historical source readings by switching display units.
See [Localization and measurement](localization_measurement_blueprint.md).

## Customer access and later marketplace

Requested: lightweight customer web portal reached through the same secure link
or QR; optional installable/PWA-style experience and a discoverable way to return.
Do not promise silently saving a URL or installing an app on a customer's phone.
Browser/device consent and capability govern Add to Home Screen/bookmark behavior.
Reopening an installed portal still rechecks access; private documents must not
leak through stale offline caches, shared devices, links, logs or browser history.
Keep no-portal customers fully supported through print/email/share workflows.
Existing revision/link ownership is in [Work](work_lifecycle_blueprint.md).

Future, NOT current implementation: a customer marketplace matching service
requests and search distance with contractors' service areas/travel radii. Keep
business records private and marketplace participation/location opt-in. Geography,
verification, moderation and separate public profiles require their own roadmap.

## Visual correction backlog — not claimed complete

- Fixed orientation header; explicit My schedule versus employee/company scope.
- Odometer next to selected vehicle, bounded context controls (not stretched
  beyond 400 LP); role access independent of presentation.
- Mobile Plan/Entries: three previews and Show all with total; wide can show more.
- Admin must not reuse the technician Plan/Entries landing composition.
- Calendar: no decorative background treatment; remove fully unnecessary final
  week. Four/five/six rows as actually required, not always six or always five.
  The prior painted donor adaptation was rejected; exact intended 5.7 calendar
  instance/color remains to trace, not to approximate and call exact.
- Active job wide detail: three useful bounded lanes when they fit; distinct Job
  photos and Receipts; visible surfaces/borders and readable menu text weights.
- Narrow/wide behavior follows local LP width and text scale on every OS, not
  desktop/tablet labels. Palette remains open except explicitly requested tokens.

## Simulated company acceptance

Use synthetic customers/data and a separate test Firebase project. Windows
desktop: owner; Windows laptop: dispatcher or finance; Mac Mini: office/reviewer;
four phones: owner-technician, Technician A, Technician B and customer portal
(assign supported devices explicitly). Also use a second company for isolation.

Run real onboarding/invitations, not developer-granted authority. Schedule distinct
jobs; reject overlap; arrive/pause/finish; reassign B to help A; attach fuel receipt;
review invoice; send to customer; record partial payment; reconcile reports.
Repeat with network loss, app termination, denied GPS/camera, unit/language change,
permission revocation, stale edits, duplicate submits, expired links and restore.
Compare source records and totals, not screenshots alone. Reject cross-company
reads/writes/counts/exports. Physical simulations complement automated rule tests
and independent security review; they do not prove absence of all vulnerabilities.

## Current progress

### September 23 Admin review and connected follow-up work

Implementation evidence, September 23: Admin composition and page-gear layout
editing are implemented; calendar remains required. Eighteen focused tests pass
across `admin_dashboard_redesign_test.dart`, `admin_dashboard_layout_storage_test.dart`
and `dashboard_owner_presentation_test.dart`, covering responsive/text scaling,
add/remove/reorder/cancel/restore, policy visibility, SQLite reopen and existing
presentation behavior. Focused analysis passes. The macOS debug build launched.
Live visual inspection remains unverified: Computer Use denied app access.
Full analysis still reports the pre-existing inventory parser test constant
expression error and unrelated lint notices. Existing old Admin composition
tests require updating to the superseding design; these results are not a full
suite or owner acceptance. Layout storage is device-local; production user grants,
expense approval policy and owner agenda remain the separate follow-ups below.

- [ ] Accept the compact Admin default and page-gear customization on narrow and
  wide screens. Preserve the calendar, view selector, source-record routes and
  consistent green Entries/blue planning meaning. Technician changes are excluded.
- [ ] Add an owner administrative agenda for calls, customer meetings, site
  visits and bidding, distinct from technician fieldwork. Determine its owning
  task/appointment model before creating a second schedule.
- [ ] Complete permission-based per-user layout grants and storage ownership;
  the current UI Lab layout preference is device-local development presentation.
- [ ] Connect expense/estimate approval policy controls: all, above an amount,
  or none, with authorized reviewers and conditional UI. Under-threshold
  expenses are still recorded; they skip approval, not recordkeeping. Resolve
  existing pending requests when policy changes without silently approving them.
  Owning policy requirements: Operations section 10. Initial employee/setup
  questions follow later; development access must remain available without setup.
- [ ] Complete employee Timesheets and daily/weekly review, corrections and
  access enforcement, per Operations section 8. No payroll inference.
- [ ] Review estimate/invoice required-deposit amount/percentage, due point,
  contractor-provided terms, customer agreement and remaining balance; keep
  received payments distinct from expected deposits and avoid double counting.
- [ ] Design manual sync, Wi-Fi-only/limited-data choices, pending/failure states,
  conflict handling and recovery under the existing data/storage/sync contract.
  Saving locally must not depend on connectivity; sync is not backup.
- [ ] Refresh identified demonstration dates from the preceding weekend through
  the following week coherently. Do not rewrite real records or use the destructive
  Work-example reset as a shortcut. Demo-date changes have not been executed here.

Implementation evidence for this slice must distinguish source changes, tests,
platform build and actual rendered review. The global screen audit is canceled;
shared-layout checks occur one screen at a time when authorized.

- [x] Capture this conversation and distinguish requirements from proposals.
- [x] Inspect Start Workday screen, draft controller, SQLite repository and donor
  odometer/color evidence; see the linked review for limits.
- [ ] Complete Start Workday fixes and acceptance matrix.
- [ ] Complete screen-by-screen non-inventory storage/connection audit.
- [ ] Complete remaining slices above; no subsystem is declared release-ready.
