# Maintainiac Operations Screen Blueprint

Status: collaborative implementation draft 0.1  
Last updated: 2026-08-30  
Applies to: UI Lab 2.1 and later approved production integration (U01 unresolved).
Authority/status: `README.md` and `application_decision_register.md`.

This is the screen-by-screen contract for what each operating surface does,
where its records live, and what a technician, administrator, or owner-technician
may see and change. Read it with `maintainiac_app_blueprint.md`,
`ui_foundation_blueprint.md`, and the relevant feature blueprint.

## 1. People and Context

### Technician

A field worker needs to start a day, understand the next stop, reach the
customer, perform the accepted work, record changes, attach evidence, record
expenses/material use, and close the job/day without unrelated company records
or sensitive financial data.

### Administrator or dispatcher

An authorized office user needs a company overview, employee availability,
unassigned/late work, schedule conflicts, assignment, customer documents,
receipt/work review, receivables, and business reporting.

### Owner-technician

The hybrid user does not get duplicate records. The View control changes scope
between `Technician` and `Admin`. Technician shows the owner's field workflow;
Admin defaults to Company Overview and adds authorized company actions. Changing
view must not silently change the current employee, job, vehicle, date, or
unsaved form. Roles are templates; permission plus record scope is authority.

## Service Company Operating Model

A service company does not merely need separate estimate, job, invoice, and
expense screens. It needs one traceable operating lifecycle:

1. **Customer request:** customer, service location, contact method, problem,
   urgency, source, attachments, and requested appointment window.
2. **Customer and site history:** prior work, equipment, estimates, warranties,
   invoices, payments, notes, communication preferences, and access instructions.
3. **Estimate or direct job:** scope, exclusions, materials, labor, equipment,
   fees, procurement, quantities, internal cost, customer price, discount, tax,
   deposit, terms, expiration, and attachments.
4. **Customer decision:** exact PDF preview, authorized delivery, delivered/
   viewed/accepted/declined/expired state, versions, approval, and signatures.
5. **Plan and dispatch:** date/time window, duration, priority, technician/crew,
   vehicle, skills, material readiness, route, conflicts, rescheduling, and
   reassignment.
6. **Field execution:** accepted scope, contact actions, planned materials/labor,
   notes, access/safety information, status, time/mileage, photos, receipts,
   actual material use, and change orders.
7. **Cost and material control:** expenses, receipt evidence, vendor/unit cost
   history, consumables, purchasing, optional stock, transfers, and job actuals.
8. **Billing and collection:** invoice PDF, deposit/partial/final billing, terms,
   delivery, payments, balances, credits, refunds, reminders, and write-offs.
9. **Closeout and follow-up:** completion checks, customer copy, warranty/service
   history, callbacks, recurring service, review request, and retained evidence.
10. **Business control:** employee availability, hours, mileage, vehicles and
    maintenance, permissions, approvals, receivables, spending, profitability,
    tax/export records, offline/sync health, and audit history.

The user should follow this lifecycle without knowing which database, controller,
or module owns it. Ease of use does not permit duplicated truth: each record has
one owner and stable links.

## 2. Required Contract for Every Screen

Every screen must define:

1. purpose: the user question it answers;
2. record owner: which module owns displayed truth;
3. audience and scope: own, assigned, team, company, employee, or job;
4. permitted actions: view/create/edit/approve/assign/share/export/delete;
5. stable-ID routes to owning records; projections never become copies;
6. one/two/three-lane composition from
   `AppLayoutEngine.operationsFor` and the shared operations workspace frame;
7. loading, empty, offline, incomplete, conflict, parse-proposal, validation,
   permission-denied, and interrupted states;
8. minimum-necessary customer, employee, financial, location, and vehicle data;
9. audit behavior: actor, time, source, old/new value, permission revision.

Without these answers, a screen is not ready to port into 5.7.

## 3. Shared Layout and Interaction Rules

- One shared operational header owns View plus the current employee, company,
  vehicle, or record context. The selected employee/company context persists
  between Dashboard and peer modules. A screen does not repeat the selected
  employee as a second page heading.
- Admin surfaces place the localized date first and genuine Needs Attention
  work next. When the shared 96-by-120-LP horizontal Employees strip is shown,
  it follows those two priorities and changes the existing workspace scope;
  repetitive instructional copy is not required beside its `Employees` label.
- Header settings are contextual to the exact screen being shown. Dashboard,
  Work home, Estimates, Invoices, Expenses, and other operating surfaces define
  their own permitted display/action settings behind the same settings control.
- Calendar presentation, date selection, and accessibility behavior are shared.
  Each module supplies only its own authorized projections; Dashboard receives
  the combined authorized day projection.
- Vehicle odometer events and active workday mileage are global operational
  records. Screens display or edit them only where relevant and permitted; an
  unexplained privacy icon is not a substitute for the workday/location consent
  flow.
- All screens use local post-navigation logical width and platform `TextScaler`.
- Phone uses one lane. Medium windows/tablets use two useful lanes. Wide windows
  use three useful lanes, normally capped at 480-500 LP. Extra width becomes
  responsive gaps and centered outer space, never 600-LP action boxes.
- Routine quick actions are labeled, normally 48 LP high and no wider than 210
  LP. Accessibility may increase height.
- Labeled controls replace unexplained icon-only controls for routine work.
- Mobile primary navigation always shows every destination name, selected or
  not. Unexplained initials such as `T` are prohibited. Calendar Today and
  selected-date states use separate visible markers without placing the word
  `Today` inside every current-day cell.
- Required names, dates, money, statuses, and actions wrap or stack; no ellipsis.
- Operational screens with both scopes list Technician first, Admin second.

## 4. Technician Day

### Before Start Workday

Dashboard answers: What vehicle am I using, what is planned, and what needs my
attention? It shows active vehicle, selected date, notifications, plan, entries,
calendar, Start Workday, permission-derived add actions, and sync/offline state.
Owner presentation updates are owned by `technician_dashboard_blueprint.md`:
Dashboard view access follows the September 13 Dashboard contract; Entries appears only when records
exist, independently of workday state; five summary cards replace the banner.

### Start Workday

This is a state transition. Preserve the applicable 5.7 behavior after read-only
discovery, then reorganize it through the shared engine:

1. confirm active technician and vehicle;
2. require physical starting odometer when mileage is enabled;
3. explain location/trip collection and honor opt-in privacy;
4. show blocking vehicle/permission issues without losing input;
5. confirm workday start exactly once;
6. replace pre-workday emphasis with compact Today at a Glance;
7. show hours, miles, current/next job, receipts to review, and End Workday.

Never silently start GPS, create a trip, or share odometer data before the
required confirmation completes.

Read-only 5.7 discovery on 2026-08-29 established the reusable behavior:

- skip a separate context-choice step when only one valid vehicle and work
  profile exist;
- otherwise make the employee/work profile and vehicle choices explicit;
- accept an exact physical odometer reading and reject a value below that
  vehicle's last confirmed reading;
- keep the physical odometer as official mileage truth even when optional GPS
  assistance is enabled;
- create the active workday only after the review is confirmed, and make start
  idempotent while a session is already active;
- require another physical odometer review before End Workday.

UI Lab expresses that contract as one responsive full-screen workflow, not a
chain of compact bottom sheets. Phone stacks Select vehicle, Starting odometer,
and Trip assistance. Medium width uses two bounded lanes. Wide width uses three
bounded lanes. Under the owner's newer automatic-draft requirement, Back retains unfinished
input; explicit discard removes it. Neither action creates a confirmed workday.
Start Workday now retains raw input through the shared draft store and consumes
it atomically with the SQLite start command. Dashboard actions and confirmed
state now use the shared SQLite session. End Workday also retains raw input on
Back and consumes its exact draft in the closing transaction. Physical-device
interruption validation and broader recovery presentation remain unfinished. See the storage contract
for the tested checkpoint and limitations.

After confirmation, the Dashboard header removes `Start workday`; it does not
replace it with a misleading second `Open workday` action. The selected vehicle
and confirmed odometer remain global in the shared header. A compact active-day
summary shows active time on the left,
miles today on the right, then next job and current status without repeating an
odometer card. The Dashboard FAB becomes the labeled `Actions` entry to
a full-screen workday-action surface. Pause/Resume and End Workday are state
actions; stops, fuel, expenses, receipt photos, notes, and estimates route to
their owning modules. Dashboard settings choose which permitted workday actions
appear; hiding an action does not grant or revoke permission.

No workday action may end in a prototype snackbar or an explanatory dead end.
`Add stop` opens the schedule-item workflow; `Add fuel` and `Add expense` open
the Expense editor with appropriate defaults; `Add receipt photos` opens the
real receipt-source workflow; `Add work note` opens the scoped day-entry
workflow; and `Create estimate` opens the Estimate editor. Cancel and system
Back return to the action directory without creating a record.

### During and after work

When permitted, a technician can open an assigned job, contact the customer,
read accepted work/materials/labor, change allowed status, add notes/photos/
receipts/material usage/time/mileage, propose changes, record job-linked costs,
and create estimates/direct jobs. Completion checks company-required notes,
time, changes, evidence, and signatures. Completion does not automatically send
an invoice unless company workflow and permission explicitly allow it. End
Workday records ending odometer when enabled and produces a recoverable recap.

## 5. Dashboard

**Purpose:** orient the selected person/date and expose next actions.  
**Owner:** projection only; Work, Expenses, Mileage, Inventory, and Maintenance
own records.  
**Technician:** own plan/entries, active vehicle, calendar, workday controls.  
**Admin:** Company Overview, employee status, unassigned/late work, conflicts,
and authorized queues. Selecting an employee opens that person's context.

The pre-workday Dashboard FAB pushes a full-screen, labeled, responsive action
grid rather than a compact sheet. Permission-derived shortcuts may include Add
to Schedule, Create Job, Create Estimate, Create Invoice, Record Expense,
Record Fuel, Add Receipt, and Add Day Record. Each shortcut opens the screen
that owns the resulting record. Unauthorized actions and counts do not render.
The directory uses the shared compact-action layout calculation; translated or
text-scaled labels and descriptions grow rather than being capped or clipped.

Today uses `Today's Plan`/`Today's Entries`; another date uses a localized full
date. Future dates show plan/schedule unless confirmed future records exist.
Plan and Entries are separate bounded sections with distinct restrained surface
tints in light mode and neutral charcoal hierarchy in dark mode. Collapsed
sections show three and state the truth as `3 of 5 stops` or `3 of 5 entries`.
An attached `Show all 5` plus chevron expands in place and becomes `Show less`;
every row routes to its source. Calendar badges are derived from the authorized
day projection, never hard-coded, and occupy a separate vertical zone below the
date number so the two labels cannot collide.

### Calendar Day route

Tapping any Dashboard calendar date pushes Calendar Day as a separate route.
It is not a Dashboard body state. Back returns to the same Dashboard scope and
scroll/navigation state. The shared header remains the context authority:

- individual scope names the selected employee in the header;
- Technician scope retains the technician and active vehicle context;
- Company Overview explicitly represents the authorized company projection;
- switching employee or company scope queries that scope; it never relabels a
  cached list from another person.

Phone order is Approvals, Day at a glance, planned work when applicable,
chronological entries, then Day recap. Wider logical windows arrange those same
sections in two or three bounded 480-LP lanes from `AppLayoutEngine.workFor`.
No Calendar Day section stretches to the full desktop canvas.

Approvals render only when authorized pending records exist. The summary opens
a stack of pending records; selecting one opens its evidence and plain-language
Approve entry/Do not approve actions. Review changes approval state and audit
metadata, not the original event time. A 9:59 AM expense remains at 9:59 AM in
chronological history after an approval at a later time. Pending entries use a
subdued error tint, outline, label, and semantics; color is never the only cue.

Day at a glance is a horizontally scrolling set of approximately 100-by-120-LP
cards on a phone. Until typed work-session, trip, and physical-odometer records
are connected, individual scope shows source-derived planned-work, day-record,
trip-record, and selected-vehicle facts; company scope shows source-derived
planned-work, day-record, scheduled-job, and completed-job counts. It never
substitutes fixed demonstration hours, miles, crew counts, or job progress.
Vehicle context may show the latest confirmed physical-odometer reading, but it
must not infer a historical starting reading, ending reading, or distance. When
both day readings do not exist, Calendar Day says the distance is unavailable.
After confirmed sources exist, individual scope may add start time, total time,
miles, and vehicle, while company scope may add authorized active-crew,
total-hours, fleet-mile, and stop metrics. Cards route to their owning records
rather than becoming a second editable copy. Entries show three initially and
use the attached Show all count to expand. The recap follows entries. Sensitive
company revenue, expense, profit, pay, and coworker totals require their own
permissions.
Every recap value is derived from the selected day's authorized source
records. Demonstration builds may seed realistic records, but the recap must
not carry independent hard-coded totals that can disagree with the entry,
expense, invoice, or payment records shown elsewhere.

Past dates emphasize recorded entries and recap. Today may contain both plan
and entries. Future dates emphasize planned work and do not fabricate completed
entries. The permission-derived FAB may add a historical record or planned work
through the owning module. Calendar badges use the authorized record count,
stay physically below the date number, and use a muted approval tone when at
least one authorized record requires review.

## 6. Work

**Purpose:** proposal-to-payment and field execution.  
**Owner:** Work.  
**Technician:** assigned jobs plus permitted estimates/invoices/payments.  
**Admin:** company jobs/documents/schedule/assignment/customer actions.

### Work home

- Drafts and permitted Employees are equal-width, labeled controls in one
  compact row when local width and text scale allow. They reflow at larger text
  without truncating either label; Employees stays absent without view permission.
- The shared charcoal header comes first. It shows `Employee` plus the signed-in
  technician, the selected employee, or `Company Overview`, and the shared View
  selector. Work does not contain Start Workday in this header.
- The six destination icons sit immediately below the shared header. The complete
  localized selected date follows the directory as the first records heading. The selected
  employee is not repeated as a large body heading. A person must never infer
  the active date or employee scope from the calendar alone.
- Authorized records that genuinely require action appear directly below the
  header/date in a distinct `Needs attention` section. Examples are requested
  estimate changes, an expired estimate, an unassigned job visible to dispatch,
  or an overdue invoice. Intake/OCR review is not an Admin attention item. The
  section shows at most three compact records, `Show all N` opens a real list,
  and every row opens that exact owning record rather than a generic module.
  It uses the same shared operations lane calculation as the record sections:
  one full phone lane, then one bounded left-hand lane in two- and three-column
  workspaces. It never stretches across the wide Work canvas.
- Work home, Jobs, Estimates, Invoices, Expenses, and Inventory reuse the same
  permission-aware attention projection, panel heading, compact row, three-row
  limit, `Show all N` control, and dismiss behavior. Module list routes retain
  their contextual Employee or Vehicle header, but reuse the same attention-row
  grammar and open the exact source record. Empty panels render nothing.
  Dismissal is presentation-only for the unchanged item fingerprint and scope;
  it never changes approval, due, assignment, correction, or stock state.
  Invoice urgency is derived from saved status and due date, never from words
  such as `overdue` in a title, note, or description.
- Admin defaults to `Company Overview` and shows the shared horizontally
  scrolling Employees status strip after Needs Attention. Selecting an employee
  updates the header and narrows the same screen/date; it does not create a
  second Work instance or force a user to read helper copy before seeing Work.
- The compact Work directory follows the useful 5.7 invoice-home pattern:
  Jobs, Payments, Scheduling, Quotes, Estimates, and Invoices, in that order.
  The 62-LP icon surfaces contain 32-LP symbols and readable labels. Four fit
  across a normal SE-sized workspace; six fit in a wide workspace. The shared
  engine measures label requirements and reduces columns for larger text rather
  than cutting words. Customers and Company Profile are in the Business menu,
  backed by the same existing company/customer records used by documents.
  Quotes remain explicitly marked Not connected. Scheduling now opens its own
  authorized Job calendar, date/employee filters, scheduled and unscheduled job
  groups, and job details for assignment and schedule editing. This is not yet
  the availability/capacity engine required by `scheduling_system_blueprint.md`.
- Jobs, Estimates, and Invoices are distinct destinations and record lists.
  Tapping one opens that workspace, never a create form. Each workspace offers
  a separate labeled New action.
- The `Add work` FAB opens a full-screen, labeled action grid using the same
  shared header, date, scope, and compact tile grammar. It does not open a tall
  bottom sheet of full-width rows over the Work directory.
- Daily summaries use the same operational card grammar as Dashboard entries:
  every record has its own bordered container, normal-scale phone rows target
  56-60 LP, and accessibility or long primary text may reflow instead of being
  clipped or ellipsized. Jobs use the shared current-work tone, estimates the
  shared planned tone, and invoices the shared successful/financial tone.
  Attention records are removed from the ordinary summaries so one source
  record is never presented twice as two different pieces of work.
- Incomplete estimates live under the clearly labeled and separately colored
  `Unfinished drafts` subsection. Drafts never blend into completed/sent/
  accepted estimate entries, but remain directly openable and included in the
  authorized total count.
- Jobs, Estimates, and Invoices own real list-display settings for status
  details, assignments, and closed records. Saving visibly changes only that
  workspace; the settings cannot alter record state or permission.
- My Info opens the retained company profile in read mode before Edit. Saved
  Clients opens the retained customer directory and then a customer detail;
  adding or editing is an explicit action rather than an always-live form.
- Payments is a distinct ledger tied to invoice IDs. Recording a full payment
  updates that invoice's payment state in the shared prototype store; its own
  calendar counts Payment records and pushes a separate dated Payments route.
  `Record payment` from Work Calendar Day opens that Payments workspace already
  scoped to the selected date; it never ends in a message telling the user to
  navigate there manually.
- One lane: Jobs summary, Estimates summary, Invoices summary, calendar.
- Two lanes: dated attention, employee context, Jobs, Estimates, and Invoices
  form the left working area; the readable Work Calendar occupies the right.
  `AppLayoutEngine.workLandingFor` opens two lanes at 724 local LP at normal
  text size; each lane is capped at 400 LP and separated by 24 LP. Larger text
  raises the transition. The landing screen never grows a third lane.
  Estimates and Invoices may share a vertical lane,
  but never a record list, heading, create action, filter, route, or state.
- Narrow layouts retain Add work as a FAB. Wide layouts expose the same action
  directory beside the date, in addition to the existing labeled New actions.
- Work reserves a labeled demo advertisement above bottom navigation, or below
  the content when side navigation is active. Its width is capped at 728 LP;
  it does not cover records, calendar, or navigation. No ad SDK is connected.
- Work Calendar copies the presentation/interaction language from read-only 5.7.
  UI Lab may adapt theme/accessibility, not replace it with a private calendar.
- Calendar counts/rows are authorized projections that open Work records.
  Badge counts come from the scoped shared Work records, including every date
  covered by a multi-day job; hard-coded day/count maps are prohibited.
- Work settings are real display preferences for Work home: employee status
  cards, daily Jobs/Estimates/Invoices summaries, and inclusion of completed
  work. They visibly apply after Save, never change permission, assignment, or
  source records, and cannot hide the required Work calendar or labeled Work
  destinations.

Selecting a Work calendar date pushes a separate dated Work screen. It is a real
route with Back behavior, the shared header, selected employee/company scope,
and its own contextual Add Work surface; it does not disguise a body-state
change as navigation. Technician scope shows assigned appointments/jobs and
permitted estimate or invoice actions.
Admin scope shows, as authorized:

- unassigned work needing dispatch;
- scheduled jobs grouped or filterable by technician/crew;
- arrival window, duration, customer, location, priority, and vehicle;
- estimates created, sent, awaiting decision, accepted, declined, or expiring;
- jobs scheduled, en route, in progress, paused, completed, or needing review;
- invoices issued/due/overdue and payments recorded for that date;
- conflicts, missing assignments/material readiness, and required follow-up.

Admin Work may additionally select an employee/crew without leaving the date.
Its Entries projection shows estimates, invoices, payments, job changes, and
other Work records that person created on the selected date. Viewing, creating,
editing, approving, sending, assigning, and deleting are separate capabilities;
an Admin role label does not bypass them. Estimate/invoice preview is the exact
customer-facing document presentation, but PDF generation and approval workflow
remain production integrations rather than duplicated UI Lab business logic.
UI Lab still exposes the complete delivery-choice surface—email customer PDF,
share from device, save a copy, or print—and states that nothing was sent. A
later 5.7 adapter may execute the selected method only after confirmation.

The workboard does not duplicate records. Every row names its record type and
state and opens the complete estimate, job, invoice, or payment that owns it.

### Jobs, Estimates, and Invoices workspaces

- Every workspace repeats the localized date, Technician/Admin view, and
  Company Overview/employee scope so a pushed route never loses context.
- Broad production-capability migration from 5.7 does not begin until Work
  home, Active Jobs, Estimates, and Invoices each have an owner-reviewed mobile
  flow, exact-record navigation, responsive regression coverage, and a mapped
  capability boundary. UI Lab completion is a UI-readiness gate, not permission
  to move an uncharacterized 5.7 subsystem.
- Estimates open on the selected date with compact customer/work rows and a
  separately colored unfinished-drafts section. Its search covers all
  authorized estimates. Jobs and invoices may retain their own filing controls;
  one generic date/all switch is not imposed across all three workspaces.
- Estimate changes requested or expired on that date occupy a separate `Needs
  attention` section and do not also appear among ordinary dated records. Every
  record remains a distinct bordered container. The Estimate header, record
  lanes, and Month/Week calendar share the same bounded operations workspace at
  every width.
- An accepted estimate exposes the explicit action `Create and plan job`. The
  resulting job keeps a link to the accepted estimate and requires schedule and
  assignment review. The estimate is not renamed or overwritten.
- Jobs carry scheduled start and end dates. Multi-day work appears on every
  covered calendar date. Work not completed gets an explicit return visit,
  reschedule, blocked, or carried-forward state; absence of a completion event
  never silently means completed.
- The Jobs home is date-first and searchable across the authorized Job file.
  Selected-date Jobs, other active Jobs, and real attention work are separate
  colored sections made from individual compact record containers. The same Job
  cannot appear in two sections. There is no generic `Selected date / All jobs`
  toggle, and every row opens that exact Active Job. Jobs reuse the app-wide
  permission-aware `Needs attention` panel rather than private warning chrome:
  it shows at most three exact-record rows, opens the full scoped list through
  `Show all N`, and exposes the same dismiss control as Work and Expenses.
  Dismissal hides only that unchanged presentation for the current scope/date;
  it never resolves, edits, approves, assigns, or closes the owning Job.
- Active Job exposes one labeled `Job actions` directory on phone. Its
  permission-derived actions use the same compact icon-tile grid as the Work
  directory, while a wide layout places bounded action groups side by side.
  Actions follow the current state: Pause is never offered before work starts,
  and in-progress or paused work can be explicitly marked `Needs return visit`.
  Rescheduling that state returns the owning Job to Scheduled.
- Invoice creation begins from confirmed completed work or an authorized direct
  invoice workflow. Jobs, estimates, and invoices keep distinct IDs and history.
- Estimate rows are normally 60 LP tall, grow for accessibility rather than
  truncate, and show customer, work title, status, and a permission-gated total.
  Search and Company Overview/employee scope operate on the same source records.
  Dates include created, edited, sent, viewed, follow-up, valid-through,
  proposed service, decision, and converted; proposed service is never
  presented as a booked Job.
- The permitted New estimate FAB works on phone as a complete field workflow.
  The estimate keeps internal job-site photos and notes so a contractor can
  inspect several sites, then finish pricing later. Camera, library, and file
  sources remain available; customer delivery includes only photos the sender
  explicitly selects.
- Estimate actions and editor navigation follow the September 25 owner correction
  in `work_lifecycle_blueprint.md`: visible labeled controls, a compact editor
  footer, direct approval/signing child routes, and bounded multi-column review.
- Estimate detail groups Labor and Materials separately, binds approval to an
  exact revision, preserves superseded approvals in audit history, and blocks
  conversion after any customer-visible change until the revised copy is
  approved again.
- UI Lab may prepare and record a delivery choice, but it must not mark a network
  message delivered. The production adapter records Sent only after the email,
  text, secure link, device share, save, or print boundary returns confirmed
  evidence appropriate to that channel.
- Invoices use a filing view independent of any single calendar date. One
  invoice may roll up authorized billable entries from a multi-day or multi-week
  Job while preserving each source record, work date, technician, and approval.
- Invoice home still starts with a date for activity and calendar context, then
  exposes separate Open invoices and Unfinished drafts filing lanes plus search
  across the authorized file. It never uses a `Selected date / All invoices`
  switch, never merges multiple invoices into one surface, and never duplicates
  a record between attention, date, open, or draft lanes.
- All Dashboard, Work Home, Work Day, and Invoice Home create actions open the
  same dedicated Invoice editor. A source Job is optional but, when selected,
  remains the owning linkage for copied customer, location, completed work, and
  billable items. Save produces a draft; issuing and customer delivery are
  separate explicit actions.
- An Invoice row opens a phone-complete operational detail with line items,
  totals, balance, payment history, dates, terms, and source Job. Its full-screen
  action route allows draft editing, customer-copy review, explicit issuing,
  and payment recording. Issue writes one ledger event without claiming the
  customer received anything. Payment entries are keyed to the exact Invoice,
  and the Invoice becomes Paid only when recorded payments cover its balance.

### Assignment and active job

Authorized Admin users see Assign/Reassign naming Technician and Vehicle,
schedule conflicts, and allowed Unassigned/No vehicle states. Changes are audited.

The Active Job route uses the same operational header and localized date as the
rest of Work. Phone uses one `Job actions` FAB that opens a full-screen,
permission-derived action directory; it does not duplicate a one-purpose Add
button beside a second action panel. Wide layouts may keep the same actions in a
bounded inline section. Job content lanes and this action presentation are
chosen from the same local post-navigation constraint through
`AppLayoutEngine.detailWorkspaceFor`; the full window width cannot override a
narrow pane. The current lifecycle action is presented first:
`Start travel`, `Mark arrived`, `Start work`, `Pause work`, `Resume work`, or
`Complete job` as appropriate. Each confirmed transition writes back to the
owning Job record. Reschedule and Reassign also update that owning record; local
screen state is never a competing source of truth.

Opening Job details always requires the exact Work-owned record and stable ID.
Dashboard plans, calendar cells, attention rows, and report rows are projections
that route to that record; none may manufacture a Job from its display title.
Unknown contact, location, scope, notes, estimate linkage, items, or evidence is
shown as not recorded or not assigned. Notes, status, schedule, assignment,
additions, and linked Expense IDs persist through the owning Job record and must
remain after leaving and reopening the route.

Active job sections use plain language:

1. Customer and job location;
2. What needs to be done;
3. Notes for this job;
4. Estimate and items for this job, grouped Materials needed, Labor included,
   and Other charges;
5. Receipts and linked expenses, separate from Job photos;
6. Status and scheduling actions.

`Link existing expense` selects an authorized business expense already in the
Expense ledger and attaches its stable ID to the Job. Linking proves/allocates a
cost; it does not silently create a customer-facing charge. `Add materials` is
the explicit reviewed route for actual material additions from manual entry,
confirmed material-cost history, one exact reviewed Expense line, or confirmed
truck stock. It never opens a generic item editor and cannot rewrite accepted
estimate labor or material lines. Field labor, equipment, fees, and customer
change orders require separately named authorized workflows. Material additions
can be reopened, edited, or removed without rewriting the accepted estimate
snapshot. Approved quoted lines remain distinguishable from additions made
during the Job.

The material form requires one visible billing treatment: **Use on job — do not
bill customer**, **Add to invoice later**, or **Customer approval required**.
Job detail labels each addition with that state and keeps the quoted/planned
total, invoice-review candidates, and customer-approval-required changes in
separate amount rows. A user who can add non-billable material but lacks billing
authority cannot edit or remove an existing invoice candidate or proposed
change. A new Invoice imports only quoted/planned lines and explicit invoice
candidates; it never imports non-billable usage or an unapproved proposed
change.

Choosing Expense evidence never converts the complete Expense amount. The
authorized user chooses one reviewed material line and the proposal retains its
stable Expense and Expense-line IDs; a basic/unitemized Expense remains eligible
for a Job-record link only. Link Expense, use truck stock, view private cost,
and set customer price are separate capabilities. A technician may consume
named truck stock without seeing cost/markup and without creating a customer
charge.

Receipt capture, existing-expense linking, and Job-photo capture remain distinct
actions and distinct attachment types. Receipt extraction review belongs to the
person entering the receipt; it is not automatically an Admin attention item.
Job photos are internal evidence unless an authorized user explicitly selects
them for a customer-facing document.
The action directory uses direct field language: Start travel, Mark arrived,
Start work, Pause work, Resume work, Complete job, Reschedule, Reassign, Add
materials, Link existing expense, Add receipt, Add job photo, and Edit job notes.
Call and Message remain in the Customer section because they act on that
customer, not the Job record. `Add materials` opens the permission-aware source
directory defined by `receipt_material_intake_blueprint.md`; expense linking,
receipt capture, photo capture, and note editing stay separate so one action
never implies another. Developer language such as `Approved scope and
assignment` is prohibited in user-facing UI.

The accepted estimate stays the quoted source. Field changes are actual use,
proposed change, change order, or non-billable use; they do not silently rewrite
accepted prices. Receipt extraction remains a proposal until confirmed.

## 7. Expenses

September 14 owner clarification: Expenses is a complete expense application
within the business operations system, not a miscellaneous entry screen. Its
calendar is a historical navigator to the selected day's scoped records and
totals. Expense rows must identify the recorded vendor when known, rather than
use a generic entry shortcut such as Quick fuel as the record's identity. Never
invent a vendor when it is unknown. Shared card hierarchy and entry color
meaning remain consistent with other modules.

**Purpose:** record costs, connect jobs, review evidence, explain spending.  
**Owner:** Expenses; originals remain Document Intake evidence.  
**Technician:** own permitted records/reviews.  
**Admin:** company costs, employee submissions, approvals, job links, reviews.

Initial categories: Materials, Consumables, Fuel, Vehicle and insurance, Tools
and equipment, Subcontractors, Office and business, Meals and travel, Other.
Categories remain organization-configurable and locale/tax-aware.

An expense includes vendor, amount/currency, date, category, payer/employee,
permitted payment source/tax treatment, optional job/customer, notes, original
receipt, and review state.

### Expenses home layout

September 14 owner direction: repair Expenses first, one screen at a time, before Work or further
OCR/inventory engine changes. Every module uses the same navigation placement
under UI foundation's shared shell rule. As narrowed by the September 15 owner
correction, Expense home displays only authorized daily and current-week spending below
the date/scope heading. Week boundaries follow the app locale. Drafts and planned
expenses are excluded until posted; refunds retain their recorded signed value.
Unknown dates are excluded rather than guessed. Personal and company scope must
be explicit and must filter the totals consistently. Month/year summaries remain
available through their owning period/report routes, not extra home recap cards.

September 15: the **Expense recap** home action opens a separate screen with
Month, Quarter, Year to date and Year choices, an explicit date range, recorded
total, missing-amount count, category totals and View expenses drill-down. It
projects the same authorized ledger and employee/company scope; it does not
create summary records or expose company amounts to technicians. Payments recap
remains a separate future module review, not part of this Expense change.

September 15 owner correction: retain one labeled Add expense FAB on Expense
home, including widescreen; remove the inline add-action row. The FAB opens the
receipt detail/category setup followed by Continue to source selection, as owned
by receipt_material_intake_blueprint.md section 1. A receipt-only grant exposes an Add
receipt FAB instead; no add grant exposes neither. This supersedes the earlier
direct inline-action direction and the default wide-screen action placement for
this screen. On widescreen, group attention,
drafts and today's entries in one lane and the dated-record calendar in the
adjacent lane; planned expenses and optional categories share the support lane
or occupy a third lane when space permits. On phones these groups stack in that
order. Company overview is the authorized all-employee scope, with a visible
return action after narrowing to one employee. The calendar opens the exact day
for viewing and permitted creation/editing; calendar navigation is not a totals
filter. No outer decorated card surrounds the workspace. Receipt capture and
review are the next screens, using 5.7 Active's early flow as reference only.
Role names do not grant permissions: keep distinct read, create, own/team edit,
named-team/company scope, removal and approval capabilities at UI and repository
boundaries. No new position-to-permission policy is implied by this layout.

- The shared charcoal operational header comes first. It owns Technician/Admin
  View, Company Overview/employee scope, and Expense screen settings. Admin may
  use the compact employee strip below it; the body does not repeat a second
  employee selector.
- The localized selected date is the first heading. The current year is omitted
  to reduce noise and returns whenever the selected date belongs to another
  year. My Expenses or Company Expenses names the current scope below it. The
  daily and weekly totals follow in a shared responsive summary row, wrapping on
  phones and with larger accessibility text. Daily total remains the first value.
- Technician defaults to that person's records. Admin defaults to all authorized
  employees and may narrow the same selected date to one employee.
- `ExpensePermissions` is the presentation contract for view, amount, create,
  receipt intake, own/team edit, company review, planned-expense management,
  and contextual display settings. Expense home, amount projections, add-action
  directory, day/category/attention/detail routes, receipt-line edit affordance,
  and planned-expense routes evaluate that contract before reading or acting.
  Manual entry, receipt intake/review, and planned-expense editors also reject
  unauthorized direct navigation; every visible handler repeats its applicable
  capability check before it opens or saves.
  A denied amount grant removes daily/category/row/receipt totals rather than
  rendering a masked value that could still leak through semantics.
- Presentation permission is not the write authority. The accepted durable
  binding must call `AuthorizedExpenseService`, which re-evaluates company,
  employee, permission revision, scope, target employee, and action before the
  repository query or mutation.
- Layout uses `AppLayoutEngine.operationsFor` and the shared bounded lane grid.
  The record lane groups Needs Attention, resumable Receipt Drafts, and Today's
  Entries. The adjacent lane holds the Expense calendar; planned expenses and
  optional categories follow it or occupy the third lane where space permits.
- Both phone and widescreen retain the permission-aware FAB described above;
  scrollable content reserves clearance beneath it.
- `AppSemanticColors` supplies Attention, Draft, Planned, and Current treatments;
  module amber remains Expense identity rather than a substitute for record state.
- The first summary value is explicitly `Daily total`; vague labels such as
  `Shown total` are prohibited. Record, review, job-link, employee, and category
  totals derive from the same authorized scope; period totals use their respective
  date boundaries, while today's record and category totals use the selected date.
- Expense records target a compact 60-65-LP row for ordinary vendor names at
  normal text scale. That target is not a hard ceiling: long vendor names and
  accessibility text reflow the individual record container so the vendor,
  state, and amount are never clipped or ellipsized.
- A recurring-expense template is not itself a posted expense. Marking one
  occurrence paid creates a normal dated Expense record with its own receipt and
  audit history. Templates retain vendor/title, fixed or variable amount,
  category, recurrence/next due date, optional job or vehicle, assigned scope,
  reminders, receipt requirement, pause/end state, and occurrence history.
  Editing distinguishes one occurrence from this-and-future occurrences. A
  one-occurrence edit may change only that open payment's expected amount and
  due date; it cannot rewrite a paid/skipped occurrence or silently change the
  recurring template amount. A variable-amount template requires the user to
  enter the actual paid amount before posting. Retrying the same occurrence is
  idempotent and cannot create a second Expense.
- Reminder notifications and `Needs attention` are separate operational
  systems. The bell beside the selected date opens `Reminders and updates`,
  with unread state and exact-record routing for recurring-expense reminders.
  `Needs attention` remains the decision/exception queue for approval, overdue,
  assignment, correction, or other actionable record state. Reading or
  dismissing a reminder never approves, rejects, pays, skips, or edits a record.
  In-app, push, and sound are delivery-channel choices on the same notification
  event; push/sound are not considered implemented until a platform adapter has
  scheduled, delivered, cancelled, and permission-tested them on each supported
  operating system.
- Empty state names the selected date and gives a permitted next action; it does
  not imply that no expenses exist on other dates.
- The Expense calendar is mandatory on Expenses home. It uses the shared
  5.7-derived month structure and app theme, counts Expense-owned records only,
  and marks dates containing receipts that need review. Tapping a date pushes a
  separate Expense Day route with the shared header/context, full localized
  date, total daily expenses, scoped records, receipt review, contextual
  settings, and permitted Add expense action. It does not merely mutate the
  Expenses home body.

Receipt review shows original evidence beside proposed vendor/date/total/tax/
lines, flags low-confidence conflicts, and asks where confirmed data belongs.
The canonical printed-row, logical-line, package, allocation, catalog, and
confirmation contract is `receipt_material_intake_blueprint.md`.
The UI calls the optional recognition feature Receipt Assistant. It offers an
equally complete manual path, permits every line and field to be edited before
confirmation, and provides an audited correction path after confirmation.
That confirmed path is labeled **Correct receipt**. A changed receipt-backed
business value requires a plain-language reason, retains the original evidence
link and prior confirmed values, and records actor/time/reason. If company
policy controls approval, the corrected revision becomes pending and the prior
approval remains historical evidence only; it cannot continue authorizing the
changed total.
Receipt intake is a separate labeled route with Capture receipt photos, Choose
existing photos, and Choose a receipt file. It preserves originals and photo
order, explains the four review steps, and never applies OCR output before an
explicit confirmation. UI Lab's source controls open the real device camera,
multi-photo picker, or supported image/PDF file picker and retain a removable
selection list for the next human-review step. They do not run or imitate OCR,
stitching, storage, or 5.7 persistence. Its settings are contextual to receipt
intake and visibly control the review checklist and evidence reminders. Camera
guides and image compression do not appear as pretend switches before their
separate native adapters exist.
Confirmed material purchases may update vendor cost history and be offered as
job actual material or stock intake. They never silently change stock, estimate
price/markup, invoice, or job completion.

## 8. Reports and Recap

### Employee weekly hours — owner requirement, September 18, 2026

Status: required future workflow; this documentation does not establish that
employee time tracking or weekly review is implemented or verified.

- Begin Workday on the technician dashboard must start a durable time record
  associated with that employee's stable profile identity. End Workday records
  its end. Records remain available across app restarts and offline use; they
  are not merely a running on-screen timer or attached only to a vehicle.
- The account owner or another appropriately authorized reviewer must have an
  easy-to-find view showing each employee's worked hours for a selected week,
  with daily detail and links to the underlying time records. Employee profiles
  must provide access to the same records, not separately maintained totals.
- Weekly review must not require visiting every employee profile individually.
  Review access must be enforced for queries, totals, routes, exports and sync,
  not just by hiding controls. This does not grant all employees team visibility.
- This is employee time recording/review, distinct from a subcontractor bill
  entered as an Expense. It does not authorize payroll processing, withholding,
  take-home-pay calculations or automatic creation of paid expenses.

Implementation planning safeguards (engineering recommendations, not additional
owner-approved pay policies): account for breaks, unfinished sessions, duplicate
starts, overlapping sessions, offline recovery, overnight/week-boundary sessions,
time zones and daylight-saving changes. Corrections must retain prior values,
actor and reason; incomplete records must be visibly distinguished from verified
totals. Test daily-to-weekly reconciliation and scoped access before acceptance.

Open product choices before implementation: week start, break treatment,
correction/approval authority and workflow, and final navigation placement.
“Timesheets” with a “This week” view is the recommended plain-language label,
not an approved final label. Do not call recorded hours “Payroll” as though pay
has been calculated. Apply the app-wide English, Mexican Spanish and Canadian
French requirement to this workflow and its dates, labels and reports.

### September 13: employee contribution on Admin Dashboard

Company Overview exposes actionable work, collections, invoicing, outstanding
balances and recorded spending. Employee scope adds their schedule and monthly
completed jobs and expense records on both narrow and wide layouts.

Employee contribution is required product work: attributed job revenue minus
confirmed labor cost and allocated direct job costs. Overhead stays separate
unless explicitly allocated. Preserve historical hours and effective-dated cost
rates; customer billing rates are distinct. Missing hours, rates or allocations
mean incomplete results, not zero costs. Unpaid owner labor is not silently free.

Owner clarification, September 14: company review must also distinguish revenue
per labor-hour, profit per labor-hour and profit margin. State the selected
day/week/month/year, revenue basis, included costs and worked-hours denominator.
Concurrent employee hours add together; zero or unknown hours do not produce an
hourly rate. Effective-dated employee pay is internal labor-cost tracking, not
payroll tax calculation. Current implementation lacks these connected measures.

Revenue attribution, payment collection and expense submission are distinct.
Collecting payment does not assign that revenue to the collector, and purchasing
crew materials does not assign all costs to the purchaser. Shared jobs require
confirmed allocations, exact money reconciliation and an unallocated remainder;
never duplicate company revenue across employees. Refunds, credits, returns and
corrections retain dated source links. Totals expose period, currency, basis,
source records and missing inputs; sensitive results require separate grants.

Implementation limit: existing employee reports supply recorded associated
expenses and completed jobs. Labor, revenue allocation and payment collector
relationships are not yet connected. Dashboard labels contribution incomplete;
it does not invent a profit or describe development access as production security.

**Purpose:** explain a day/week/month/year and link every total to source.  
**Owner:** projection only.  
**Technician:** own completed jobs, hours, miles, costs, callbacks, review items.
**Admin:** invoiced revenue, money collected/still owed, recorded expenses,
estimated gross profit, completed
work, time/mileage, permitted team results, and review queues.

Company totals, profit, cost, markup, pay, and coworker results require separate
permissions. Revenue, collected money, and invoice total are not synonyms. Each
metric declares basis, date rule, states, currency, and filters. Tapping a metric
opens supporting records while preserving filters. The earlier 5.7 dashboard
recap belongs here after source-field audit, not as the technician default.
`Estimated gross profit` is labeled as invoiced revenue minus recorded costs and
must disclose excluded/unrecorded costs. It is not labeled net income and is not
presented as tax or payroll advice.

UI Lab's report projection reads the selected period directly from typed Work,
Expense, Invoice-ledger, and Payment-ledger records. It does not keep an
independent report total. Company scope may project company financials; an
employee context projects only that employee's attributable work and expenses
and never inherits unattributed company revenue or payments. A report metric
opens a filtered supporting-record list, and each supporting row opens the
owning Expense, Job, Estimate, or Invoice record.

Company cost and estimated-profit totals include only complete Expense records
whose approval state is `not required` or `approved`. Pending, declined, and
submitter-incomplete Expense records remain visible in their authorized record
and review lists but do not enter company books or profit projections.

Completed-work reporting requires a confirmed `completedOn` timestamp. Planned
or scheduled end dates are not silently substituted for completion. Job
completion records that timestamp when the user confirms Complete job. Hours,
miles, callbacks, drive time, fuel economy, and trend claims remain visibly
`Not recorded yet` until their confirmed source models are connected; the UI
must never fill those gaps with demonstration totals. Vehicle reporting may
still show source-derived fuel, repair, and maintenance expenses without
claiming that mileage or vehicle-health telemetry exists.

## 9. Inventory and Materials

September 14 owner clarification: inventory and receipt-reading assistance are
opt-in. Contractor/service users need understandable item, location, on-hand,
available quantities, plus chosen low-stock thresholds
and reminders. Estimates do not reserve stock; release/cancellation/revision and
insufficient availability must be handled through explicit authorized commands.
Keep unknown counts distinct from zero. Core/Standard/Professional/Complete
membership needs usefulness review, not arbitrary item-count quotas. The three
launch Core packs are bundled, with other trades and custom items supported.
Delivery and cross-model boundaries: [Expense/inventory roadmap](expense_inventory_delivery_roadmap.md).

**Purpose:** remember verified vendor costs and optionally stock location.  
**Primary value:** cost history for faster estimates; perfect truck counts are
not assumed.  
**Technician:** permitted cost lookup, assigned truck stock, use/return/report.  
**Admin:** catalog, vendor/date/unit costs, optional truck/warehouse stock,
transfers, adjustments, reorder, variance review.

Each cost keeps unit/pack, vendor, purchase date, currency, tax inclusion,
receipt/expense source, and confirmer. Estimate price/markup stays separate.

### Read-only 5.7 capability census

The 2026-08-30 Inventory discovery inspected the existing 5.7 inventory screen,
its current/previous-purchase flows, stock rows, record detail, item/stock/
transaction models, Hive-backed store, and recap projection without changing
5.7. Reusable behavior exists for canonical material identity, trade/category/
system catalog paths, stock by location, low thresholds, physical adjustments,
transfers, purchase transactions, unit/pack cost, receipt linkage, recent cost
history, and export snapshots. The legacy screen mixes dark private styling,
catalog navigation, stock certainty, and price history inside one long flow; it
is behavioral evidence, not the new presentation contract.

The read-only 5.7 catalog tests require at least 11,000 canonical items across
21 trades and its source is split across 160 catalog files. That breadth is a
protected reusable capability. A later production port must expose it through a
bounded catalog/search adapter; UI Lab must not manually duplicate, truncate, or
silently replace that catalog with its small demonstration ledger.

### UI Lab Materials home

September 15 owner direction supersedes the previous cost-first landing and
Estimate reservation arrangement.

**Purpose:** help service contractors find what they have, know what they paid,
and prepare supplies for work. Inventory use is optional.

**Landing:** no truck picker. Show real, authorized inventory needs first:
items at/below their location-specific minimum, and quantities needing a count.
Keep **My Inventory** and **Browse Catalog** prominent, enclosed, and readable.
Keep the supporting Materials calendar below. Remove cost-source explanations
and technical count-confidence metrics from the landing. Do not show invented
incoming-order or Job-shortage counts before their workflows are connected.

**Browse Catalog:** September 16 correction: preserve the trade selection;
replace the rejected screens beneath it, in small batches, one trade at a time.
Each trade owns its hierarchy; do not impose Plumbing's category/material/type
sequence on every trade. Reach the exact item, including ordered connection
sizes, aliases, unit and variant. Two trade columns on an ordinary phone; reflow for larger text
and wider local workspaces through AppLayoutEngine. Trade cards may use photos;
all deeper levels use compact image-free grids with full readable labels,
typically two or three columns when labels fit, and bounded columns on wide
screens. Do not stretch every category into a full-window row.
Search stays inside the current branch, clear restores the tree, and Back
returns to the parent. No item photos are required. Material, size and unit
must remain visible; no picture may misrepresent an item's material.

**My Inventory:** use the same tree, showing only branches containing added
items. Choose truck/storage inside this route. Browsing a location must not
change the official active truck or employee. Show unknown quantity as needing
a count, never as zero. A stock item's details offer a physical-count action,
its location minimum and recorded purchase prices. Minimums can be disabled
independently per item/location. Counts are replaced on confirmation; adding
stock is a different action. Adding items must not require a receipt.

**Implementation boundary:** the September 15 UI slice uses the existing
in-memory inventory store, with an explicit review notice on mutation routes.
It is not durable stock storage, production inventory authorization, receipt
parsing, or notification delivery. Existing record visibility is applied to
landing counts, lists, and item lookup. Dedicated inventory permissions and
durable, atomic stock commands remain required before release. Do not remove
the review notice until restart and permission tests prove the durable system.

**Superseded bulk-export evidence:** the existing read-only 5.7 extraction yields 57,314 unique
trade-scoped entries across 21 trades, exported as a compressed browse asset
(832,849 bytes). Fourteen existing trade PNGs total about 2 MB. The app loads
the compact browse data without loading the legacy parser or Hive runtime.
Source size is not evidence of accuracy or complete residential-trade coverage.
Audit item definitions, duplicate-equivalent variants and trade organization
before treating the source as an accepted catalog. The source combines some
trades (including well/septic); owner-requested divisions remain to be reviewed.
Exporter read the isolated extraction; no protected 5.7 files were modified.
The owner rejected this bulk browsing implementation. It must not serve as the
accepted catalog: it omitted aliases and exposed expansion-pack labels directly.
The replacement uses small SQLite batches with complete source payloads.
See [Inventory rebuild plan](inventory_rebuild_plan.md) for current order and
verification gates. Reused legacy tests require independent expectation review;
passing tests in either app do not establish correctness or parser accuracy.

**Follow-on connected workflows, required but not implemented by this UI slice:**
- Estimates use stored purchase prices without selecting a truck, deducting
  stock or reserving stock automatically.
- At scheduling/assignment, check every required item, of every size, against
  the assigned location and combined commitments. Recheck assignment/date
  changes. Offer other permitted locations when a shortage exists.
- Suggested transfers never move stock; confirm physical movement. Actual use,
  returns, cancellations, corrections and repeated completion must not
  double-deduct. Direct-to-Job purchases remain distinct from truck stock.
- In Expenses' Materials receipt flow, ask all/some/not received. Track only
  confirmed received quantities as stock. Optional expected delivery date and
  reminders lead to a receiving confirmation. Incoming orders must never
  create duplicate Expenses or count as available stock before receipt.
- Default/per-item markup affects selling price, not purchase history or
  already-issued documents. Optional notifications consume item/location
  thresholds through the separately owned notification system.
- Preserve vendor/date/unit/currency and source evidence on purchase history;
  Estimates, Jobs and Invoices refer to that history without rewriting it.
- Custom-item entry, durable stock and cost edits, category coverage review,
  barcode workflows, ordering and Job readiness are subsequent bounded work.


Maintenance and Maintenance-owned Repair screens remain deferred product
slices. Their future home, list, day, detail, and form routes must consume the
same local `AppLayoutEngine.operationsFor` result and bounded workspace frame as
Dashboard, Work, Expenses, and Materials. Vehicle/equipment-specific content
does not justify a private breakpoint, unbounded desktop canvas, or different
phone/tablet/desktop classifier.

### Required Inventory states and tests

Loading, empty search, no tracked stock, offline pending write, interrupted
count, invalid quantity/cost, duplicate save/retry, stale permission revision,
sync conflict, unknown stock, receipt proposal, and denied scope are explicit
states. Regression covers 320/390 phone, wide desktop, text scale 2.0, Admin
Company Overview and employee narrowing, separate day navigation, stable-ID
writes, file size, light/dark contrast, semantics, and eventual production
offline/restart behavior. UI Lab proves layout and typed interactions; it does
not claim the prototype store is the 5.7 persistence design.

## 10. Permission and Scope Matrix

### Owner approval rules — September 14 voice planning

Required direction, not a claim of implementation: routine approvals and urgent
Needs attention are separate flows. Follow the latest urgency definition in the
Technician Dashboard blueprint; awaiting approval alone is not an urgent alert.
The owner needs independent approval choices for applicable record/document
types, including Expenses with receipt evidence, Estimates and Invoices:
require approval for all, require approval above a chosen amount, or require no
approval. Receipt evidence must retain its relationship to the owning Expense;
do not invent a duplicate financial record just to request approval.

The owner also raised employee-specific approval rules. Plan for company
defaults with explicit employee exceptions; the precise controls and precedence
remain to be settled. Permission to enter or submit a record, permission to
approve it, and the rule requiring approval are distinct. No approval required
does not grant unrelated access or classify a record as manually approved.

Engineering details to resolve before implementing this flow: exact threshold
and currency handling, who can approve and whether self-approval is allowed,
changes to amounts after approval, policy changes while requests are pending,
unavailable reviewers, offline submissions and repeated requests. Preserve
the actual submitting/reviewing actor, time, document revision and applicable
policy. These safeguards are design work, not functionality proven by these notes.

### September 19 employee-permission clarification

Owner requirement: employees cannot directly edit their own recorded timesheets
by default. Direct editing needs an explicit grant. Employees need a correction
request workflow; reviewer rules, approval states and audit details remain to be
specified and validated before implementation. The earlier assistant's suggested
approval design is a recommendation, not a completed feature.

The employee permission questionnaire must address applicable view, create/add,
edit, delete, approve and send actions across business modules. Job access must
not automatically expose invoice totals, payments, costs or profit. Existing
minimum-access rules and enforcement boundaries below still apply.

Owner requested Skip with a confirmation explaining the loss of capabilities
when permissions are off. The owner subsequently reopened whether some defaults
should be enabled. Therefore the exact default matrix and final Skip behavior
remain unresolved; the assistant's proposed starter grants are not approved.
Do not silently assign those grants. The no-self-timesheet-edit default above
is explicit and remains in force.

Employee setup asks plain-language Yes/No questions rather than presenting raw
permission names. A dependent permission cannot survive without its parent:
for example, turning off `Can this employee see estimates?` also turns off
create and approve. Active and former employee records remain distinct; pay and
emergency contact data are private company records. Vehicle profiles retain
confirmed odometer, assignment, and active/inactive state. Inventory is scoped
to vehicles or Fleet Overview, never to an employee-owned stock bucket.
Question rows use the shared local-width plus `TextScaler` form calculation:
Yes/No stays beside a readable question when it fits and moves below it when it
does not. No private phone-width breakpoint may crowd or clip the interview.

| Capability | Technician default | Admin template | Hybrid behavior |
| --- | --- | --- | --- |
| View jobs | own/assigned | team/company | follows View scope |
| Create estimate | off or granted | commonly granted | one shared record |
| See cost/markup/profit | off | separate grants | hidden unless granted/needed |
| Assign employee/vehicle | off | dispatcher/admin grant | Admin scope only |
| Record own expense | policy grant | granted | acting user retained |
| Approve others' costs | off | explicit company scope | Admin scope plus grant |
| Company reports | off | explicit financial grant | Admin never overrides denial |
| Add job photos/receipts | assigned job | company job if granted | source job decides |
| Change schedule/status | limited | operational grants | audited to actor |
| Send customer document | explicit | explicit | document/customer scope |

Navigation, direct routes, search, counts, exports, offline caches, and sync
payloads enforce the same permission and scope.

## 11. UI Lab to 5.7 Boundary

The prototype description below is historical, not a current all-module storage
audit. Expense/notification checkpoints have separate owning documents. Use the
decision register and `data_storage_sync_contract.md`; a prototype repository
is not automatically the entire application's production store.

UI Lab owns a small offline prototype repository, fixtures, view models, layout,
semantics, and widget tests. Screens query and mutate that shared prototype
repository so Calendar, Dashboard, Work, Expenses, reports, employees, and
vehicles demonstrate coherent records. That repository is not automatically a
production database design.

Within UI Lab, the repository is nevertheless the only source for shared
prototype records. Dashboard and Calendar Day use the same date-and-scope key;
Work records use stable record IDs; and the selected technician vehicle is
global operational context. Private per-screen copies that make edits disappear
on Back are forbidden even in the prototype.
Before each port, map 5.7's model/IDs, controller/repository/store, permission and
scope provider, route, offline/sync/conflict/audit behavior, native adapters, and
tests. Classify reuse, presentation adapter, presentation replacement, or
missing. Never move UI Lab mock state into 5.7 as business logic or change 5.7
data ownership without separate evidence and owner authorization.

## 12. Acceptance Per Screen

- 320, 360, 390, 412, tablet, narrow desktop, 1440, wide desktop;
- text scales 1.0, 1.3, 1.5, 2.0;
- coherent light/dark palettes;
- no clipping, ellipsis, unexplained icon-only action, oversized action box, or
  private breakpoint;
- Technician/Admin/hybrid and permission denial tested;
- localized date/currency/unit/RTL expansion tested;
- offline/retry/interruption/conflict/duplicate-submit tested;
- source ownership and audit verified;
- owner visual acceptance in running UI Lab before any 5.7 port.
