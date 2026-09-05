# Work Lifecycle Blueprint

Status: UI Lab working contract 0.1  
Applies to: Customers, Estimates, Jobs, Schedule, Invoices, Payments, Materials,
Receipts, Calendar, and Dashboard projections

## Purpose

Define the complete service-work lifecycle so a later Codex model can build or
port one bounded workflow without inventing record ownership, permissions,
responsive behavior, or document transitions.

The front end must remain understandable to a solo contractor. The underlying
records, permissions, audit history, offline behavior, and conversions must
remain dependable enough for a growing service company.

## Governing rules

1. Customer, estimate, job, invoice, payment, expense, receipt, inventory, trip,
   and calendar records keep separate stable IDs and owners.
2. Conversion creates an explicit linked record. It never renames or mutates an
   accepted estimate into a job or a completed job into an invoice.
3. Every read, count, route, edit, attachment, export, share, and sync action is
   capability- and scope-checked. Hiding a control is not authorization.
4. Accepted documents remain historically reproducible. Later corrections or
   change orders retain their actor, time, reason, prior value, and linkage.
5. OCR, AI, GPS, and schedule correlation create proposals only. A user confirms
   them before they alter financial, customer, job, inventory, or mileage truth.
6. Money uses decimal-safe storage and explicit currency. Units are organization
   or user data, not country-based layout branches.
7. UI Lab demo records are presentation evidence only. Production integration
   reuses verified 5.7 repositories and services behind adapters.

## Lifecycle

1. Create or select a customer and service location.
2. Create an estimate, or create a direct job when quoting is not required.
3. Build scope and pricing as flat rate or time and materials.
4. Add labor, materials, equipment, procurement, fees, discounts, tax, deposit,
   validity period, terms, exclusions, and customer-facing notes.
5. Preview and share the proposed estimate through an authorized delivery method.
6. Record acceptance, rejection, requested revision, expiration, or cancellation.
7. Convert an accepted estimate into a linked job through an explicit audited action.
8. Schedule the job and assign employee/crew, vehicle, location, and requirements.
9. Execute the job: status, notes, time, photos, signatures, materials used,
   receipts, expenses, mileage, and authorized change orders.
10. Review completed work and create a linked invoice from confirmed billable data.
11. Share the invoice, record payment terms, payments, balance, credits, refunds,
    and corrections.
12. Project confirmed dated activity into Dashboard, Calendar, reporting, and
    customer history without duplicating source records.

## Customer and location record

Customer identity and service location are related but separate. One customer
may have multiple service locations and contacts.

Required capabilities include:

- person or company name, preferred name, billing identity, and tax fields;
- phone, email, preferred contact method, and communication consent;
- billing address and one or more service locations;
- access instructions, site notes, pets/hazards, and authorized contacts;
- linked estimates, jobs, invoices, payments, attachments, and history;
- duplicate detection and an explicit audited merge workflow;
- import/export and deletion/retention behavior appropriate to privacy policy.

Forms use one column on narrow constraints. Wider constraints may pair logically
related fields, but label order, validation, and keyboard traversal remain stable.
Customer details must not be copied into every workflow as editable parallel truth;
documents store the required historical snapshot plus the stable customer/site ID.

## Estimate workspace

- Estimate details, actions, editor, item/labor editor, delivery, signature,
  site-photo, and customer-preview routes put the estimate's created date
  directly beneath the shared operational header. They do not repeat a generic
  selected-date helper sentence. The record identity, revision, customer,
  amount, and state follow that date.
- Customer preview is always read-only. A draft or company-review-blocked
  revision shows an explicit preview-only gate and cannot email, share, save,
  or print the customer copy. A sendable revision may continue from preview to
  the same permission-aware delivery route used by Estimate actions; preview
  never owns a second delivery implementation or bypasses approval.

The Estimate workspace is date-first on entry and remains searchable across the
complete authorized estimate file. The localized selected date is the first body
context, followed by compact 60-LP normal-scale rows for every estimate with
activity on that date: creation, edit, delivery, follow-up, expiration, proposed
service, decision, or conversion. Every row leads with customer and work title,
then shows status and the estimate total only when separately permitted. A
clearly labeled unfinished-drafts section keeps incomplete estimating work from
being lost when the user changes dates. Search by customer, number, or work
description searches all authorized estimates, so finding a record never
requires remembering its creation date. Selecting a calendar date immediately
refreshes the dated rows and returns them to view.

The home route uses the shared bounded operations workspace for its header,
record lanes, and Month/Week calendar. It never introduces a competing
`Selected date / All estimates` switch. Changes requested and expired estimates
for the selected date appear in a separate high-contrast `Needs attention`
section directly after the date and are excluded from the ordinary dated list.
That section is the shared operational attention panel: at most three compact
rows, a real `Show all N` route, an X dismiss control, and exact Estimate opening.
It does not use private Estimate warning chrome or merge attention records into
the normal dated list after dismissal.
Drafts remain in a separately colored `Unfinished drafts` section. Every
estimate is its own bordered 60-LP-class record container; rows grow only for
accessibility text instead of merging into one large list surface.

Before any broad 5.7 capability migration, the Work operating surface is
completed in four reviewable slices: Work home, Active Jobs, Estimates, and
Invoices. Each slice must have coherent phone-first navigation, exact-record
opening, permission-aware actions, bounded wide layout, and focused regression
coverage. This readiness gate protects the production OCR, parser, storage, and
inventory systems from being moved into an unsettled workflow.

Primary regions:

- Estimate information: title, app-generated or user-entered number, PO/reference,
  created date, proposed service date or window, validity, pricing method,
  currency, tax treatment, and status. A proposed date is not a scheduled job.
- Company and customer: sender snapshot, customer, service location, contacts.
- Scope: description, inclusions, exclusions, assumptions, notes, and attachments.
- Job-site photos: camera, photo library, or file; optional plain-language note,
  captured-on time, actor, and estimate revision. Authorized internal users can
  review them later when pricing or performing the work. Photos remain internal
  unless the sender explicitly selects them for the customer-facing copy.
- Items: labor, materials, equipment, procurement, fees, discount, tax, deposit.
- Totals: subtotal, adjustments, tax, total, required deposit, and balance basis.
- Terms and delivery: payment terms, acceptance method, signature, delivery history.

An estimate supports Draft, Ready, Sent, Viewed, Accepted, Rejected, Revision
requested, Expired, Cancelled, and Converted states. Editing after acceptance
creates a revision or change order; it does not rewrite the accepted snapshot.
Any change to customer-visible scope, quantity, item, price, discount, tax, or
terms invalidates the current approval even when the total changes by only one
cent. The prior signature remains only with its signed revision in audit
history; it is never displayed or accepted as approval of the revised estimate.
The revised estimate returns to an approval-required state and cannot create a
job until the customer approves that exact revision.
Acceptance never creates a job automatically. A separately permitted, explicit
`Create and plan job` action creates the linked job and then requires schedule
and assignment review.

Company review is a separate revision-bound lifecycle when the owner's policy
requires it. The creator submits the exact estimate revision. An authorized
company reviewer opens that exact saved estimate and can **Approve for
sending**, **Return for changes**, or **Reject estimate**. Return and rejection
require a retained reason. Approval permits customer delivery only; it never
records customer acceptance or supplies a customer signature. A returned
estimate exposes **Edit estimate** and **Submit for approval** to an authorized
creator. Any customer-visible edit invalidates the company approval for the
superseded revision and requires another submission. A rejected estimate stays
in company history rather than being deleted.

The client detail page is another legitimate route into the same estimate. It
shows Active estimates before the complete authorized work history for that
customer—estimates, jobs, invoices, payments, and attachments—and offers New
estimate with that stable client preselected. This is a filtered view of the
same records, not a second copy. The estimate detail screen owns status, exact revision,
meaningful dates, scope, separately grouped Labor and Materials, internal
revision/delivery history, and the actions Preview customer copy, Send or share,
Sign in person, and—only after approval of the current revision—Create and plan
job.

On a compact Estimate detail route, one labeled `Estimate actions` FAB opens a
full-screen, permission-derived action directory. The current next step appears
before record actions. Wide layouts may show the same actions in a bounded
inline section. Existing labor, material, equipment, and charge rows reopen in
the same line-item form and retain their stable IDs and evidence links. Any
customer-visible change creates a new revision and invalidates approval for the
superseded revision. All nested Estimate routes use the shared Work header and
localized record date; generic one-off app bars are prohibited.

Labor is not disguised as a generic material line. Labor rows support role or
service, hours or service quantity, customer rate, private internal rate, and
customer-facing description. Material rows may begin manually, from confirmed
material cost history, or from a recorded expense/receipt. Linking evidence
never silently turns the full receipt total into a customer charge; the human
reviews and edits quantity, description, cost, markup, and price.

Creating an estimate is a phone-complete field workflow. An authorized user can
start the draft at the job site, capture and label condition photos, save the
draft offline, and finish scope and pricing later without losing the customer,
site, photos, or notes. The labeled New estimate FAB is present whenever create
permission is granted. Tablet and desktop may arrange the same information into
bounded additional lanes, but they do not expose required capabilities that are
missing from the phone flow.

Estimate and invoice presentation uses a shared PDF document engine with exact
preview before delivery. Provide restrained professional templates first, then
optional trade-filtered decorative templates such as plumbing, HVAC, lawn care,
or masonry. Company identity, logo, customer, job location, item table, totals,
terms, signatures, and payment details come from confirmed records; the visual
template never owns or rewrites that data.

### Estimate and Invoice terms

The contractor can maintain reusable company-authored terms templates, but a
template is never the historical agreement. Creating or revising a document
copies the selected terms into that exact Estimate or Invoice revision. The
snapshot retains its text, template identity/version, author/editor, locale,
effective time, and document revision so the signed or delivered copy remains
reproducible after the contractor changes a future default.

An Estimate has a clearly labeled **Service terms** section covering the
contractor's customer-visible conditions for the proposed work, such as scope
assumptions and exclusions, site access, deposits, cancellation/rescheduling,
change approval, warranty, validity, and other company-authored conditions. The
customer portal presents those terms with the exact scope, items, total, and
revision before **Approve and sign**. The acceptance evidence identifies that
terms snapshot. Any customer-visible terms edit creates a new Estimate revision
and invalidates the superseded customer signature and company approval to send.

An Invoice has a separate **Payment terms** section covering the exact due date,
accepted payment methods, installment schedule when offered, correction/dispute
route, and any company-authored late-fee, credit, or refund conditions permitted
by applicable policy. Delivering an Invoice records delivery of those terms; it
does not pretend the customer approved the Invoice. If the customer accepts a
payment plan, that separate acceptance identifies the exact Invoice, plan, and
Payment-terms revisions.

Estimate Service terms do not silently become Invoice Payment terms. A company
may choose related defaults, and an Invoice may reference its accepted Estimate,
but the contractor reviews the customer-facing terms in the final preview for
each document. Maintainiac must not supply unreviewed legal promises as if they
were the contractor's approved terms. Starter wording, if offered later, is an
editable proposal and must be clearly identified for professional review.

## Sharing and acceptance

Sharing is a delivery record, not merely opening an operating-system share sheet.
Store document version, recipient, method, actor, time, delivery result, and any
customer-view or acceptance evidence the chosen channel legitimately provides.

Before sending, show a final preview with customer, address, scope, line items,
totals, terms, and attachments. Permission to edit an estimate does not imply
permission to send it or see internal cost/markup/profit. Customer-visible PDFs
and links exclude internal fields by construction.

The UI Lab preview exposes explicit Email, Share from device, Save, and Print
choices while truthfully reporting that no copy has been sent. The production
port replaces that boundary with the authorized document service and records
the confirmed delivery result.

### Release-one customer portal and QR handoff

Release one uses a small, document-specific web portal rather than a customer
messaging system. An authorized contractor generates a QR code from the exact
Estimate or Invoice revision and may display that code in person or share the
same secure link through an approved delivery method. The customer scans the QR
code with their own device and the browser opens the lightweight portal; the
customer is not required to install Maintainiac.

The portal names the contractor as the provider of the proposed or invoiced
service and Maintainiac as the recordkeeping/document-delivery platform. It
does not imply that Maintainiac guarantees, collects, or is owed the
contractor's customer payment. Contractor/customer commercial questions route
to the contractor; portal-security, privacy, and technical issues follow the
approved Maintainiac support route.

The QR code contains only an opaque HTTPS capability link. It does not expose a
raw organization, customer, Estimate, or Invoice identifier and does not embed
customer details. The backing link is unguessable, revision-bound, revocable,
and subject to an explicit expiry and customer-verification policy. Opening it
rechecks document state and exposes only the customer-safe snapshot for that
exact recipient and revision. A superseded, withdrawn, expired, or revoked
revision cannot be approved through an older QR code.

For an Estimate, the portal may:

- display and download the exact customer copy;
- approve and sign that exact revision;
- decline it, with an optional short structured reason; or
- request changes, with an optional short note attached to that revision.

`Request changes` does not edit the Estimate and is not a counteroffer engine.
The contractor reviews the request inside Maintainiac, creates a new revision
when appropriate, and deliberately issues a new secure link or QR code. Formal
counteroffers, free-form conversation threads, employee messaging, and general
contractor/customer chat are deferred beyond release one.

For an Invoice, the portal may display and download the exact issued customer
copy and let the customer report a correction or dispute against that revision.
An Invoice is not presented as something the customer approves or declines.
Payment processing is not implied by this portal contract.

A contractor may offer a payment plan for an issued Invoice. The plan is an
Invoice-owned, revisioned agreement containing the exact installment amounts,
due dates, currency, starting balance, terms, and current status. The customer
reviews and accepts that plan separately from the Estimate and separately from
notification consent. Changing an installment amount, due date, fee, or term
creates a new plan revision and requires the customer to accept that revision;
it never rewrites the prior agreement.

Customer payment reminders are opt-in per delivery channel. The portal presents
separate, initially unselected choices for email, SMS/text, and browser push
when those channels are available. Accepting the Invoice, Estimate, or payment
plan does not select them. Browser permission alone is also not consent to send
business reminders. The consent record retains the exact consent-copy version,
chosen channel and destination, customer/authorized-contact identity, plan
revision, locale, time zone, actor/source, and granted/revoked time using the
minimum evidence required by policy.

The customer can withdraw a channel through the portal and through every
reasonable channel-specific method the delivery provider supports. Revocation
cancels future scheduled deliveries for that channel, retains audit evidence,
and does not cancel the payment plan or change the Invoice balance. Reminder
copy is transactional, identifies the contractor and Invoice safely, contains
no advertising or upsell, avoids sensitive lock-screen detail by default, and
loads current balance truth from the Invoice rather than trusting a queued
message. Jurisdiction-specific consent, quiet-hour, frequency, retention, and
content policy must be approved before production delivery is enabled.

A customer reminder can never mark an installment paid. Confirmed Payments
remain Work-owned records applied to the exact Invoice. A missed installment
may separately create permission-scoped contractor `Needs attention`; that
internal decision queue is not evidence that a customer reminder was delivered.

Issuing, viewing, downloading, approving/signing, declining, requesting a
change, reporting a correction, expiring, and revoking are auditable events.
Short customer reasons remain structured activity attached to the owning
document revision; they do not create a chat inbox. Contractor-facing status
always opens the exact owning Estimate or Invoice record.

## Active job workspace

- The record route is titled `Job details` for every lifecycle state. The
  record status chip owns `Scheduled`, `Arrived`, `In progress`, `Paused`,
  `Needs return visit`, and `Completed`; the route must never call a scheduled
  record an active job or repeat a generic selected-date helper line.

The Jobs workspace is a dedicated operational route, not the old generic
document list. It repeats the shared Work header without a second employee
strip, places the localized selected-date control immediately below it, and
uses the shared bounded operations frame for search, record lanes, and the
Month/Week calendar. It never presents a competing `Selected date / All jobs`
switch. Search covers every authorized Job by customer, job number, work title,
or description.

Jobs scheduled on the selected date and other currently active Jobs occupy
separate colored sections. A Job may appear only once: selected-date rows take
priority, while the Active jobs lane shows ongoing work outside that date.
Unassigned dispatch work in Admin scope and Jobs marked Needs return visit move
to `Needs attention` immediately after the date and are excluded from ordinary
dated rows. Each job is its own bordered 60-LP-class record container showing
time or Continues, status, work title, customer, and permitted assignment. The
first three rows are visible; `Show all N` always uses the live authorized count.
Every row opens that exact owning Active Job record. This is the shared
permission-aware attention component used by peer modules, including its
high-contrast heading, exact-record list route, and dismiss control. Dismissal
is presentation-only for that unchanged date/scope/item set; the Job keeps its
original state until an authorized workflow changes the source record.

The active job is where a technician performs assigned work. Dashboard plan rows
open this source job route.

The route requires the exact Work-owned Job record and its stable ID. A calendar
or Dashboard plan item is only a projection and can never instantiate Job
details by itself. The interface must not derive customer contact, service
location, estimate number, scope, notes, line items, receipt evidence, or any
other record truth from a schedule title. Missing saved information is labeled
plainly as not recorded or not assigned. Production persistence keeps stable
customer and service-location IDs plus the required historical snapshots; UI
Lab may resolve its synthetic customer fixture only by an exact saved identity,
never by a fuzzy or title-based guess.

Required regions:

- job identity, current status, schedule, assignment, and linked source estimate;
- customer, service location, contact actions, access notes, and site warnings;
- Call and Message actions expose the confirmed phone/email values. Until the
  production phone adapter is connected, UI Lab provides working copy actions
  instead of pretending a call or message was placed.
- approved scope and every authorized estimate line needed to perform the work;
- technician notes, internal notes according to permission, photos, signatures;
- estimated materials, actual materials used, additions, returns, and shortages;
- receipts and expenses linked to the job but still owned by Expenses/Document Intake;
- time, trip/mileage, odometer events, status history, and audit activity;
- change-order, pause, reschedule, complete, return-visit, and cancellation workflows.

The accepted estimate remains visible as the quoted baseline. Adding a field
material does not silently add customer billing or alter that baseline. The user
chooses whether it is non-billable usage, a billable adjustment, or a proposed
change order, subject to permission and approval policy.

The active-Job material form asks this in direct language before any customer
price is accepted: **Use on job — do not bill customer**, **Add to invoice
later**, or **Customer approval required**. Non-billable use stores a zero
customer charge while retaining authorized internal cost and provenance. The
Job detail never combines these states into one misleading total: quoted or
planned work, invoice-review candidates, and customer-approval-required changes
are shown separately. Users without customer-price permission never receive
those amounts through rows or totals.

The compact active-job FAB is labeled `Job actions`; it opens the complete
permission-derived action directory. Phone actions use the same compact labeled
icon-grid grammar as the Work directory instead of a long stack of full-width
buttons; wide layouts place Status and schedule beside Job records when both
lanes fit. Within that directory, `Add materials` opens the same source flow as
the wide `Add materials` control. The material flow appends or corrects actual
job additions without allowing that screen to delete or rewrite accepted
estimate lines. Sources include manual entry, confirmed material-cost history,
an existing reviewed expense or receipt, and available stock on a named vehicle
or storage location. Each addition keeps its source linkage, internal cost,
customer-price decision, actor, and time.

The active-Job route is specifically **Add materials**, not a generic item or
estimate editor. It may edit only actual material additions; quoted estimate
labor/materials and any separately owned field-labor adjustment remain outside
that route. A recorded Expense is first filtered through the authorized,
confirmed-business-cost query, then the user chooses one exact reviewed
material line. The line description, quantity, unit, unit cost, and stable
Expense and Expense-line IDs prefill the proposal. The whole Expense total is
never copied, and a receipt ID is never manufactured from display status. A
basic or otherwise unitemized Expense can still be linked to Job records, but
it cannot create a material line until reviewed line data exists.

Status actions are contextual. Scheduled work may start travel or be marked
arrived; en-route work may be marked arrived; arrived work may start; work in
progress may pause, complete, or be marked `Needs return visit`; paused work may
resume, complete, or require a return visit. A return-visit Job stays visibly in
that state until rescheduled, and a confirmed reschedule moves it back to
Scheduled rather than showing Pause or Complete actions before the next visit.

## Receipt attachment and parsing boundary

The complete field, package, allocation, confirmation, permission, offline, and
QA contract is maintained in `receipt_material_intake_blueprint.md`. This section
is the lifecycle summary and must not be implemented as a simpler competing flow.
Customer-facing screens call the optional feature **Receipt Assistant**, never
OCR. Users can keep it off and complete the entire flow manually. Every line is
editable before confirmation and correctable afterward with retained history.

The first action is attaching evidence to the correct job/expense context:
camera, photo library, file, existing receipt, or existing expense. Preserve the
original file and source metadata. An active job exposes one labeled `Job
actions` directory. Its separate actions cover adding or editing job items,
linking a recorded expense, capturing a new receipt, recording a job photo, and
editing a job note. The item editor then offers manual items, confirmed cost
history, truck stock, and reviewed expense or receipt sources without conflating
evidence attachment with customer billing.

The review flow then:

1. orders and rotates pages/photos without overwriting originals;
2. extracts vendor, date, total, tax, payment hints, and line-item proposals;
3. shows confidence and the exact source region for uncertain values;
4. allows the user to correct, merge, split, or exclude proposed lines;
5. asks where confirmed information belongs: expense, job actual material,
   inventory cost history, stock intake, or none;
6. applies only the choices the user explicitly confirms;
7. retains the extraction version, confirmation actor, time, and source linkage.

Receipt parsing never creates an estimate automatically. Confirmed cost history
may be offered while the user builds a later estimate, with the vendor/date/source
visible. Customer price and markup remain separate decisions.

A receipt may default all confirmed lines to one estimate/job. When one purchase
contains items for multiple jobs, review shows every source line and lets the
user assign each line and quantity to the correct job, stock, expense-only, or
unassigned destination. The system does not infer an even split or silently
allocate lines. Every allocation retains the original receipt and line linkage.

## Company and saved-customer presentation

My Info and Saved Clients open read-only detail first. My Info shows confirmed
company identity, contact and billing details, logo, tax/document defaults, and
the information used on customer documents. A labeled Edit action opens the
prefilled form; Cancel or Back discards unconfirmed changes. Saved Clients is an
alphabetically sorted, searchable customer list. Selecting a client opens the
same detail-first pattern with contacts, billing and service locations, access
notes, and authorized linked history before Edit is offered.
Its record directory uses the shared operations lanes: one on phone, two where
two useful record widths fit, and three bounded lanes on desktop. Accessibility
text raises those requirements and collapses the directory before customer
names or contact metadata crowd.

## Job to invoice

The Invoice workspace is not a generic document list and does not ask the user
to choose between `Selected date` and `All invoices`. It keeps the shared Work
header, places the localized date immediately below it, and uses that date for
invoice activity and calendar counts. Search independently covers the complete
authorized invoice file by customer, invoice number, linked job, or work title.
Open balances and Unfinished drafts remain directly visible in separate colored
filing lanes without changing the selected date. A record is excluded from later
lanes after it appears in attention or selected-date activity, so one Invoice is
never presented as multiple pieces of work.

Every invoice row is its own bordered 60-LP-class container with invoice number,
customer, work title, status, and permission-gated amount. Overdue invoices move
to `Needs attention` immediately after the date. Drafts never mix with issued,
due, or paid records. Rows open the exact Invoice record; the first three in a
lane are visible and `Show all N` uses the live authorized count. Header, record
lanes, and Month/Week calendar share the same bounded operations workspace.
Invoice attention reuses the shared operational panel and full-list route, and
the overdue decision comes only from the saved Due status plus a due date before
the organization-local current day. Display copy can never create or clear a
financial warning.
An empty attention, open-balance, or draft lane is omitted instead of consuming
phone space with a zero-count panel; it returns automatically when a qualifying
authorized record exists.

Invoice authorization is enforced at the workspace route, record detail,
financial projection, action directory, and write handler. `Can view invoices`,
`Can create invoices`, `Can view invoice amounts and payments`, `Can edit a
draft`, `Can review the customer copy`, `Can issue an invoice`, and `Can record
a payment` remain separate answers. A denied user cannot obtain records by
opening a route directly; an amount-denied user does not query or render payment
history, balances, or item prices; and every mutating handler rechecks its grant
instead of relying on a hidden button.

Every Invoice creation entry point uses one dedicated editor. The user first
chooses a source Job or `Direct invoice`; choosing a Job copies its customer,
service location, completed-work summary, pricing method, and reviewed items
while preserving the Job ID as the source. The user may then review customer,
work completed, invoice items, invoice and due dates, discount, tax, template,
expected payment method, and payment terms. An incomplete form does not create
a record. Save creates an Unfinished draft; it does not issue or deliver it.
The import includes quoted/planned Job items and additions explicitly marked
**Add to invoice later**. It excludes non-billable material use and proposed
changes still awaiting customer approval. Invoice review remains explicit and
does not mutate the Job or its source Estimate.
Only Jobs with confirmed completed status appear as invoice sources. Scheduled,
en-route, paused, return-visit, and already non-billable work cannot be treated
as completed merely because an invoice form was opened.

Selecting an Invoice opens its exact operational record rather than jumping
straight to a PDF preview. Phone detail shows customer/work ownership, source
Job, every line item, subtotal/discount/tax/total, amount paid, balance, payment
history, invoice/due dates, method, and terms. `Invoice actions` is a full-screen
route on phone. Drafts may be edited, reviewed as a customer copy, or explicitly
issued. Issuing posts one invoice-issued ledger event but does not claim email,
text, print, or secure-link delivery. Issued invoices may record payment against
their exact invoice number; only payments that reduce the balance to zero mark
the Invoice Paid. Customer-copy preparation remains distinct from delivery
confirmation.
Every payment entry point uses the same full-screen balance-aware form. The
Payments workspace first selects an authorized open invoice through a searchable
list, then opens that exact form; drafts and paid invoices are excluded, prior
payments reduce the offered balance, and overpayment is rejected. Selecting a
saved payment opens its owning Invoice record. Saved payments use the same
compact record grammar as the rest of Work: each payment is a separate bordered
60-LP-class container rather than a merged list inside one undifferentiated panel.
Invoice detail, actions, editor, payment entry, Payments, and Payment day routes
put their applicable record date immediately below the shared operational header.
`Work completed` contains the confirmed service summary; due timing belongs only
to the invoice dates and balance terms.

Invoice creation begins with confirmed billable job data and the accepted estimate
or approved change orders. The review must distinguish quoted, actual, added,
non-billable, already invoiced, credited, and disputed items.

The invoice owns its number, issue/due dates, terms, delivery, balance, payments,
credits, refunds, and collection state. Creating it does not close the job unless
the user or company workflow explicitly performs a permitted status transition.

Invoice filing cannot depend on issue date alone. The Invoice workspace must
support customer, invoice number, linked job, issue date, due date, delivery
date, payment activity date, balance state, assigned employee/company scope, and
search. One invoice may summarize confirmed work from multiple visits across
multiple days or weeks; each source entry keeps its own date, actor, job, and
audit identity. The invoice is a financial document assembled from those
confirmed records, not a replacement for the multi-day Job history.

## Permission surfaces

At minimum, distinguish capabilities to:

- view/edit customer identity, sensitive notes, and communication preferences;
- view internal cost, markup, profit, customer price, tax, and totals separately;
- create/revise/send/accept/convert estimates;
- view assigned jobs versus company jobs;
- assign employees/vehicles, reschedule, change status, and complete work;
- view/add/use/return materials and approve billable adjustments;
- link an existing Expense to a Job, consume truck stock, view private cost,
  and set customer price as four independent capabilities;
- attach/view/review/confirm receipt proposals;
- create/send/correct invoices and record/refund payments;
- export, share, delete, restore, and administer retention.

Development mode may expose all prototype actions, but production must obtain the
same result from the authenticated capability and record scope. Privacy choices
such as location or odometer sharing remain separate from role grants.

## Responsive contract

- Every screen uses local post-navigation logical constraints and `TextScaler`.
- Client identity and contact pairs reuse
  `AppLayoutEngine.stackFormFieldsFor`; the editor does not keep a private
  width or accessibility threshold for ordinary two-field rows.
- Active Job contact values and their labeled copy actions reuse the same local
  width-and-text-scale reflow rule, so accessibility text moves the action below
  the value before either control crowds.
- Active job and document detail use `AppLayoutEngine.detailWorkspaceFor`.
- Phone uses one scroll owner and one content column.
- Wide layouts use two bounded columns only when both remain readable.
- Customer names, addresses, scope, notes, item descriptions, money, and status
  reflow; they are not ellipsized to force a desktop arrangement onto a phone.
- Dark mode uses neutral charcoal panels and section headers. Semantic colors are
  reserved for status, selection, warnings, and actions—not colored panel edges.
- Work home uses `AppLayoutEngine.operationsFor` and no private width rules. Its wide
  composition is Jobs, separate Estimates and Invoices summaries, and Work
  Calendar in three bounded lanes no wider than 480 LP. Its directory uses six
  labeled 62-LP icon tiles governed by `AppLayoutEngine.workShortcutsFor`.
- Work home order is shared header, localized date, genuine Needs Attention,
  optional Admin employee strip, six labeled destinations, compact daily record
  summaries, then the full module-width calendar. Redundant date and employee
  helper paragraphs are omitted. `Add work` pushes a full-screen labeled action
  grid and returns the chosen action; it is not a modal list sheet.
- Work Day derives its records, lanes, and compact-FAB-versus-inline `Add work`
  presentation from the same local `AppLayoutEngine.workFor` result. A wide
  window cannot hide the compact action while the dated route occupies a narrow
  rail or split-view pane.
- Work attention, Jobs, Estimates, Invoices, and unfinished drafts reuse one
  compact record-container primitive. `Show all N` always opens a real list;
  individual rows open their exact record. The normal phone target is 56-60 LP,
  while long names and accessibility text reflow rather than disappear.
- Work Calendar copies the visual and interaction language from read-only 5.7.
  Calendar rows project Work-owned records; the calendar is not a second job
  store.
- Technician and Admin are explicit Work scopes. Admin assignment/reassignment
  names both Technician and Vehicle and remains permission guarded.
- Active Job uses the shared Work header/date. Its phone `Job actions` route
  exposes only authorized actions and keeps the current operational transition
  first: travel, arrival, start, pause/resume, and completion. Every transition
  writes through to the owning Job record.
- Job status, schedule, assignment, notes, additions, and stable linked-Expense
  IDs write through to that same Work-owned Job record. Leaving and reopening
  the route must reproduce the saved state; route-local screen state is not a
  second Job store.
- Existing Expense links, receipt evidence, customer-facing Job additions,
  truck-stock consumption, and Job photos are separate reviewed outcomes. A
  linked Expense is never automatically converted into a customer charge.
- A technician who may consume truck stock but may not view private cost or set
  customer price sees the material identity, location, available quantity, and
  count confidence only. Saving records zero new customer charge while retaining
  authorized cost provenance behind the permission boundary for later review.
- `Add receipt` reuses the Expense-owned receipt intake with the exact Job ID.
  A confirmed new Expense links back by stable ID; cancel or intake failure
  changes neither record. `Add job photo` is a separate device-media outcome
  and may not create a placeholder filename or attached state before durable
  device evidence exists.

## Internationalization, measurements, accounting, and AI

- The first onboarding question is language: English, U.S. Spanish, or Canadian
  French. The next measurement choice is plain-language **U.S.** or **Metric**;
  the product does not label the U.S. choice `Imperial`.
- User-facing strings move through Flutter localization resources before the
  production port. English fixtures in UI Lab are not permission to embed
  English in 5.7 controllers or persisted records. Spanish is the first required
  expansion language; layouts must also survive longer translated labels and
  right-to-left text even if initial release locales are narrower.
- Dates, times, decimal separators, currency display, addresses, taxes, paper
  sizes, and customer-document formatting use organization/user locale. Stable
  timestamps, currency codes, and decimal-safe money remain locale-neutral in
  storage.
- Measurements store an explicit unit and value. U.S. customary and metric are
  display/input preferences, not platform or country branches. Source value,
  source unit, converted display value, and rounding policy remain auditable.
- `localization_measurement_blueprint.md` is the detailed source of truth for
  language resources, preferences, package styles, conversions, receipts,
  documents, accessibility, persistence, and tests.
- Receipt or expense evidence can propose a confirmed internal material cost for
  an estimate or job. It never creates a customer-facing line, price, markup,
  stock change, or invoice without the user's explicit reviewed choice.
- A future accounting connector such as QuickBooks is an export/sync adapter
  governed by `accounting_integration_blueprint.md`, with stable internal IDs,
  external mapping, revisioned commands, idempotency, conflict, audit, and
  offline retry rules. Maintainiac source records and daily workflows do not
  become dependent on that provider.
- The future AI assistant is a permission-scoped interface over existing product
  commands, not a parallel data owner. Speech-to-text and text-to-speech are
  replaceable adapters. Every AI/OCR output is labeled as a proposal, carries
  provenance, obeys the same company/employee/customer scope, and requires user
  confirmation before financial, schedule, customer, inventory, or job changes.
- Model routing and vendor choice are runtime policy. The proposed Luna/Terra
  split must not be embedded in screen widgets, persisted business records, or
  authorization logic; cost, latency, privacy, and capability policy select the
  model behind one auditable assistant service boundary.

## Required integration discovery before 5.7 changes

For each bounded slice, identify and report the existing 5.7 models, repositories,
services, routes, permissions, storage, sync, tests, and customer/document widgets.
Classify each as reuse, adapt, replace presentation only, or missing. Stop for
owner review before changing production data ownership or deleting suspected
duplicates.

The receipt camera/review flow is a separate integration slice because it crosses
native capture, file durability, OCR, expenses, jobs, materials, inventory, sync,
and confirmation. It must be designed and tested independently from the job
workspace presentation.


## Owner-confirmed scheduling, staffing, and capacity planning — 2026-09-04

The following requirements are expanded by `scheduling_system_blueprint.md`,
including recurring service, actual-time history, calendar preservation,
permissions, local/cloud boundaries and the company-configurable Finish Job
handoff to invoice review/signature/delivery where permitted. The parallel
builder's initial scope is in `scheduling_engine_codex_assignment.md`. These
documents specify planned work; their existence does not mean it is implemented.

### Product goal

Schedule is not a passive appointment calendar. Maintainiac must help a contractor or small business determine whether proposed work can actually fit into the available workday without overbooking people or assigning the wrong people. The scheduling engine uses labor requirements from the Estimate/Job together with employee availability and employee skill profiles. It may recommend a plan, but it never silently commits, moves, cancels, or reassigns work.

### Required planning inputs

Each schedulable Job needs structured planning data rather than display-text scraping:

- estimated total labor hours from the accepted Estimate, or an explicitly reviewed Job planning value when no Estimate exists;
- labor requirements by skill or work type when known, such as electrical, plumbing, drywall, HVAC, general labor, equipment operation, or company-defined specialties;
- minimum crew size and preferred crew size when applicable;
- whether the work can be parallelized, so the engine never assumes that doubling the crew always halves elapsed time;
- required qualifications, licenses, certifications, or company-defined eligibility restrictions where applicable;
- proposed appointment window, service location, expected setup/cleanup time, and planner-defined travel or buffer allowance;
- existing Job assignments and other schedule commitments for the same people;
- employee working availability, time off, and company-defined working hours.

An Estimate labor total is planning evidence, not a guaranteed duration. The planner may revise the Job planning estimate without rewriting the accepted customer Estimate. The Job retains the source Estimate value, current planning value, actor, time, and reason for the change.

### Employee skill profile

An employee is not modeled as one generic unit of labor. Each employee may have multiple company-defined skills. A skill assignment includes at minimum:

- stable skill ID and display name;
- proficiency level using a small deterministic scale such as learning, capable, advanced, or expert;
- whether the employee is eligible to perform that work independently;
- optional qualification/certification references and expiration when the business chooses to track them;
- effective dates and audit history for changes.

Job title or role may provide defaults, but scheduling eligibility comes from the employee's current skill/qualification profile and authorization, not a display title alone. Future performance history may produce advisory evidence, but the first production scheduler must not automatically rank or penalize employees from sparse completion data.

### Deterministic capacity engine

Release-one scheduling must be deterministic and testable. It does not require machine learning. For a proposed Job or appointment window, the engine:

1. loads the exact Job planning requirements and proposed time window;
2. loads only employees the authorized planner may schedule;
3. removes employees who are unavailable, already committed, on leave, or otherwise ineligible for the relevant part of the window;
4. evaluates required skills and qualifications for each remaining employee;
5. calculates available labor capacity for the window in minutes or another exact duration representation rather than binary floating-point hours;
6. compares total available labor capacity with estimated labor demand;
7. separately compares skill-specific capacity with skill-specific demand, so excess general labor cannot hide a shortage of a required specialty;
8. applies minimum-crew, preferred-crew, parallelization, travel, setup, cleanup, and buffer rules before determining fit;
9. returns a planning result with reasons and alternatives instead of changing the schedule itself.

### Planning result states

At minimum the engine can return:

- `comfortable`: requirements fit with meaningful remaining capacity;
- `tight`: requirements fit but leave little buffer or rely on near-full utilization;
- `understaffed`: enough time may exist but not enough eligible people or required crew size;
- `skill_blocked`: total labor capacity exists but required skilled capacity does not;
- `overbooked`: existing commitments leave insufficient usable labor capacity;
- `schedule_conflict`: one or more proposed assignments overlap incompatible commitments;
- `insufficient_planning_data`: required hours, skills, availability, or other critical inputs are missing and the system cannot make a trustworthy claim.

Every result includes human-readable reasons based on stored inputs. The UI must never display a green or available state when critical planning data is missing.

### Recommendations, not authority

When a proposed slot does not fit, Maintainiac may recommend alternatives supported by actual availability data:

- use a different employee or crew with the required skills;
- move the appointment to a later available window;
- extend the job across multiple days;
- increase crew size only when the Job's parallelization rules say additional people can reduce elapsed time;
- split separately schedulable work phases when the Job plan allows it;
- flag the Estimate/Job planning hours for owner review when the work cannot fit a reasonable available window.

The recommendation identifies the constraint it is solving. AI may later turn deterministic results into conversational explanations, but AI is not the source of schedule truth and cannot confirm, move, assign, or cancel work without an authorized user action.

### Overbooking and conflict rules

- One person cannot contribute the same minute of labor capacity to two Jobs.
- A person assigned to sequential Jobs retains the planner-defined travel/buffer allowance between locations unless an authorized user overrides it with a recorded reason.
- A Job requiring two qualified workers is not schedulable merely because one qualified worker has enough total hours.
- A Job requiring a specialty cannot consume unqualified general-labor capacity to satisfy that specialty requirement.
- Company-wide available hours and specialty available hours are separate metrics.
- The engine may show theoretical capacity and recommended capacity separately; theoretical capacity must not be presented as a confirmed feasible schedule.
- Schedule confirmation writes an audited Work-owned schedule commitment. The calculation result remains a derived planning artifact and never becomes a second Job or Calendar record.

### Example planning behavior

If a Job is planned for 24 labor-hours and three eligible employees each have eight genuinely available hours, the engine may report 24 theoretical labor-hours of capacity. It still checks required skills, minimum crew, parallelization, travel/buffer time, and other commitments before calling the day feasible. If the same Job requires ten electrical labor-hours but only six qualified electrical hours remain, the result is `skill_blocked` even when total company labor capacity exceeds 24 hours.

### Required QA coverage

Focused tests cover at least exact-fit, comfortable-fit, tight-fit, overbooked, overlapping appointments, unavailable employee, time off, missing hours, missing skill data, specialty shortage with excess general capacity, minimum-crew failure, non-parallelizable work, parallelizable work, multi-day recommendation, travel/buffer conflict, qualification expiration, permission-scoped employee visibility, schedule edit, cancellation/reschedule recovery, and offline/restart reproduction of the same confirmed schedule commitments.
