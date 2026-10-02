# Work Lifecycle Blueprint

Status: UI Lab working contract 0.1  
Authority/status: `README.md` and `application_decision_register.md`. Inherited
rules without owner evidence remain PLANNED; this file does not select U01.
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
   Work landing's persisted-record projection uses the session actor's stable
   employee ID for technician view, and intersects company/employee selection
   with the session's visible creator IDs. A presentation role or assignment
   does not grant access to an otherwise unauthorized record. This local
   projection guard does not establish connected Firebase enforcement or
   complete module/action permissions.
4. Accepted documents remain historically reproducible. Later corrections or
   change orders retain their actor, time, reason, prior value, and linkage.
5. OCR, AI, GPS, and schedule correlation create proposals only. A user confirms
   them before they alter financial, customer, job, inventory, or mileage truth.
6. Money uses decimal-safe storage and explicit currency. Units are organization
   or user data, not country-based layout branches.
7. UI Lab demo records are presentation evidence only. Production integration
   reuses verified 5.7 repositories and services behind adapters.

## Lifecycle

This is a common connected example, not proof every Invoice/Payment must pass
every earlier step. Direct-entry/link policy remains U04. Do not silently impose
the illustrated sequence as a mandatory gate.

1. Create or select a customer and service location.
2. Create an estimate, or create a direct job when quoting is not required.
3. Build the scope and estimated cost without labeling the Estimate itself a
   fixed-price commitment; fixed-price proposals belong in Quotes.
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

## Quotes — required capability, independent lifecycle unresolved

Quotes must be represented as a complete Work application, not erased because
older registers only listed Estimates. The owner describes a Quote as a fixed
customer price for the agreed scope. It may show itemized work or one total.
Changing that price by any amount, up or down, makes the previous customer
signature inapplicable to the new revision and requires fresh approval; the
signed earlier revision remains in history. Additional work needs an explicit
customer-visible scope and price review rather than silently changing the
accepted quote. The owner wants conversion to a Job and a direct path to an
Invoice when no Job is needed. Exact expiry, a time-and-materials offer that
does not promise a fixed total, and whether a Job may be planned before Quote
approval remain U04. Do not invent legal distinctions or treat Quote and
Estimate as synonyms. Shared customer, pricing and document infrastructure
can be evaluated without settling those remaining policies.

September 28 implementation checkpoint: Quotes now have a distinct persisted
`WorkRecordKind.quote`, separate immutable number claims, and a
`work/quote-editor` recovery domain. The existing proposal draft controller and
pricing/revision machinery are shared; legacy estimate-named payload fields
remain compatible. Draft input carries its document kind, and a record cannot
change kinds through a save. Fixed-price validation and a separate
`requiresQuoteApproval` permission apply; an Estimate approval setting is not
silently treated as a Quote policy. Restart, wrong-kind input, numbering and
permission-bypass tests cover this foundation.

The Quote create/save/reopen/edit flow is now connected from Work, Add Work,
dated Work entries and document recovery. Its landing screen uses the shared
header, conditional Drafts below the header, compact status filters that update
the list in place, and a supporting calendar at the bottom. One form supports a
fixed service price or optional itemized work. Customer selection retains the
saved customer's identity, and incomplete input resumes in the Quote editor,
not the Estimate editor. Returning from an unfinished edit refreshes Drafts.
Explicit Quote status filters include matching closed records even when the
general list setting hides closed records. Date and search constraints still
apply; the closed-record setting governs the unfiltered list only, matching the
Invoice workspace's explicit-filter behavior.

Supervisor/admin Quote approval is now a separate persisted decision: Request
approval, Approve for sending, or Request changes with a reason. The session
requires `canApproveQuotes` for a decision, retains immutable history, records
the acting employee ID, and binds the decision to a fingerprint of saved quote
content and revision. A changed quote needs fresh approval. This never records
customer acceptance. The detail screen exposes these actions only for a quote
requiring this approval; the permission configuration and Firebase enforcement
are not yet delivered. The UI-Lab owner grant is development authority only.

September 29 customer-approval checkpoint: saved Quotes now use the shared
terms-first approval screen, with explicit acceptance followed by an in-person
signature or recorded approval without a signature. Unfinished inputs use
separate `work/quote-approval` and `work/quote-signature` recovery domains.
Persistence enforces the respective customer-approval/signature grants and any
required company approval. A customer approval cannot be combined with changed
quote contents in one save. Price revisions invalidate current approval and
retain prior approval entries and the invalidated signature. Tests cover failed
atomic consumption, restart, denied access, revision changes, and the rendered
manual-approval path. This is automated evidence, not physical-device acceptance.

Accepted Quotes now expose Add to jobs using the shared job editor and atomic
source-to-job command. Recovery recognizes a Quote parent; the saved job retains
its source, client snapshot, photos, items, terms and agreed total. A failed
commit preserves both the accepted quote and unfinished job input. Duplicate
linked jobs are refused, and a converted Quote cannot be reopened or rewritten
as newly accepted work. Additional work belongs on the linked job. Existing
estimate-named draft keys remain compatible; they now identify either proposal
kind. Tentative planning before acceptance remains unresolved under U04.

Approved Estimates and Quotes also expose Create invoice when no separate Job
is needed. The shared action creates an unissued invoice draft and marks the
source converted in the same durable commit. Client snapshot, work, prices,
terms, photos, tax and discount carry over; proposal approval does not become an
invoice signature or payment. Invoice approval requirements still apply before
issue. Source-version checks and exactly-one-target validation prevent stale or
duplicate conversion. Returning to the source exposes Open invoice. Automated
checks cover failure/retry, restart, denied permissions and the Quote screen
route; physical-device acceptance remains outstanding.

Approved versions is now available on saved Estimates and Quotes with approval
evidence. It reads retained database snapshots, validates payload hashes and
record/company/creator identity, and displays the original work, price, terms,
manual approval or normalized signature ink. Bounded 30-save pages keep long
histories manageable; the screen groups approved snapshots by document version.
Approved versions and People and activity share `WorkActivityReader` for durable
availability, permissions, payload integrity and missing-revision checks. A
missing latest snapshot or a record deleted by another session fails closed.
It is read-only and does not offer editing, sharing or issuing historical copies.
Tests cover repeated signing and price changes, reopening, paged history,
unauthorized creator/company access, corrupted payload hashes and the rendered
manual-approval history route. Physical-device review remains outstanding.

Quotes now reuse the estimate customer-PDF preview and delivery preparation
screen. Their unfinished recipient/method/review input uses the distinct
`work/quote-delivery` recovery domain. Preparation and draft consumption commit
together against the saved document revision. Export checks sharing permission
and any required, content-bound supervisor/admin approval. A native composer or
share-sheet handoff is not delivery evidence and does not mark the quote sent or
approved. Cancellation is retained in the existing export audit. Automated
checks cover failed save/reopen/retry, stale edits, denied sharing, draft export,
required approval, and the quote delivery route. Physical-device composer/PDF
acceptance remains outstanding; nothing has been sent from a user device.

Shared Work/Dashboard Needs attention now includes quotes needing authorized
supervisor/admin approval, changes, or expiry follow-up. Quote entries use the
active Work permission snapshot and visible creator scope, not the selected
Admin/Technician presentation label. Resource/date/employee filters remain in
force; exact-record navigation opens Quote detail. Approval removes its pending
attention entry; no separate attention record is saved.

This is still not a complete Quote product flow. Confirmed delivery remains
unfinished; historical export is not implemented. Unsupported
status transitions continue to fail closed.
These controls must be replaced with audited transitions before claiming the
full workflow delivered.
The owner moved Quotes ahead of the remaining unrelated Work/header cleanup;
this supersedes the earlier Quotes-last sequence.

## Internal invoice approval

Owner direction, September 28: classify invoices requiring supervisor/admin
permission as **Needs approval**, with **Approved** as the completed decision.
Do not duplicate this with an Awaiting review filter. These decisions authorize
issue/delivery; they do not mean the customer paid or accepted an estimate.

Current local implementation: invoice records retain append-only approval events
(actor, time, decision, content fingerprint and optional reason). A submission
must refer to saved invoice content; approving requires the explicit session
`canApproveInvoices` grant. The session's `requiresInvoiceApproval` policy or a
record's retained requirement blocks issuing an unapproved invoice. Approval is
bound to exact content, not only a revision counter: client, prices, items,
terms, due date and other content changes require submission and approval again.
Ordinary saves cannot erase history, remove a recorded requirement, forge an
approver, combine edits with approval, or issue without satisfying this check.
The invoice financial command and shared PDF export authorization enforce the
requirement. Export authorization reads and verifies the current durable record,
checks issue/share authority and approval, and compares the complete submitted
document with saved content. Matching an ID and revision number alone is not
sufficient. Share, save and print use this same check before creating an export
attempt and again through the PDF service authorization callbacks. Legitimate
partial/final payments preserve approval of unchanged invoice content.

The invoice action area exposes Request approval and, for permitted approvers,
Approve invoice. Conditional Needs approval / Approved filters update the same
landing list. This is source implementation with focused local persistence
verification, not proof of full role administration or cloud authorization.
Request changes requires an explanation, preserves the decision in history,
and returns the invoice to submission. Approval controls have English, Spanish
and French labels. A SQLite-backed widget test exercises request, correction,
resubmission and approval. Export regressions exercise unapproved records,
missing authority, altered contents, stale sessions and legitimate payments.
Owner configuration of employee policy, real-device acceptance and Firebase
enforcement remain unfinished. The existing development
owner bootstrap has approval authority; this must not be mistaken for production
membership or a complete owner-settings workflow.

## Reusable jobs

Owner direction, September 28: provide **Reusable jobs**, not a customer-facing
"Job templates" label. Users must be able to save work they perform repeatedly
and start a new job for another client without re-entering that work. This
carries forward the September 19 handoff requirement; it is separate from
recurring scheduled visits. A labeled tab must make the saved jobs discoverable.

Implementation contract: persist ordinary editable reusable-job records through
the shared durable storage and permission boundaries. Copy work title,
description, optional items and prices into new editable work; choose the new
client and location. Do not copy customer identity, appointments, completion,
approvals, signatures, invoice/payment links or payment history. Editing a new
job must not mutate its reusable source or previous jobs. Reusable jobs must
survive restart and must never be automatically seeded as customer data.

September 28 implementation checkpoint: Add work now contains New work and
Reusable jobs tabs; Jobs exposes the same library in Jobs / Reusable jobs tabs.
Switching back preserves the selected Jobs date; the reusable library hides
the unrelated booking controls and calendar while selected.
The reusable library creates common work from scratch or
copies a saved job, supports editing and unfinished-input recovery, and opens
the existing new-job editor with a fresh client/location selection. Placement
is an implementation choice awaiting rendered owner acceptance, not a claim of
an owner-approved exact layout. Use from estimate, quote and invoice creation
is unfinished. Those destinations should reuse this library rather than create
separate copies.

The library uses the shared SQLite record/revision store, actor-scoped drafts,
Work permissions and serialized write/pause boundary. Saves use revision checks
and consume the matching confirmed draft transactionally. A read-only search
and inspection of the 5.7 job store/actions found whole job records with customer,
assignment and document links, not a suitable reusable-job implementation; no
donor source was copied. New work is copied by an explicit field allowlist.
SQLite and widget tests cover persistence, stale edits, permission scope,
draft recovery, excluded customer metadata, and create/edit/reuse/save for a
new client through both Add work and Jobs at 360 and 1200 logical pixels.
Jobs tab switching is also checked at 320 logical pixels with enlarged text.
The new job retains the common price
and work while selecting a fresh customer/location; saving it leaves the
reusable source revision unchanged. Android debug build passed. Physical-device
acceptance and translation coverage remain unfinished.

## Customer document detail level

Latest owner clarification, September 28: Estimates, Invoices and Quotes use
one form with optional individual items. Users can describe the work and enter
one overall price, or add item descriptions, quantities and prices. Do not force
users to choose between two document types before entering work. This supersedes
the earlier requirement for a mandatory Detailed/Summary choice. Existing saved
presentation choices and underlying materials/labor must remain intact; do not
silently erase an itemized breakdown when offering a simple price. Quotes remain
the last implementation flow. Customer-visible changes still require the existing
revision and reapproval safeguards.

Invoice implementation now offers Price for the work when there is no itemized
breakdown. Its raw input survives draft recovery, uses the shared validated
service-price calculation, and confirms as one internal service amount with a
summary customer projection (no individual-item table). An existing detailed
breakdown cannot be overwritten using that price field. The estimate editor now exposes the price directly in the form, with optional
items below it, without a Detailed/Summary selector. The hint sits above the
price field. Adding items carries a directly entered amount into the item editor
instead of silently losing it; canceling leaves the original input unchanged.

Presentation remains persisted for compatibility and exact historical document
reproduction. A directly priced estimate uses the summary customer projection;
existing itemized records keep their presentation and underlying prices. The
single-price field cannot overwrite an existing itemized breakdown. Raw price
input remains recoverable, and clearing a saved service price requires entering
a replacement rather than silently restoring the previous amount. These source
changes and focused tests are not physical-device or full workflow acceptance.

## Customer and location record

Customer identity and service location are related but separate. One customer
may have multiple service locations and contacts.

Estimate Client information opens one section screen. Its bordered Saved clients
and Add new client controls stay at the top. Both change content within that same
screen: the initial view offers those choices without opening the saved list.
Saved clients displays a searchable alphabetical list, and Add new client
displays the directory form inline. Only the selected saved-list view of empty
storage says No saved clients, retains
the Add new client action, and never redirects. Tapping a saved name selects its
stable identity for this estimate without pushing a detail route. Save and use
client commits a new directory record and selects it for the estimate. Switching
between the two choices retains unfinished input; leaving flushes client and
estimate drafts before returning. Native Back and visible Back first return
through the inline client choices in visited order; they do not skip directly
from the new-client form to the estimate. Done explicitly finishes the section.
The form reuses directory persistence,
permissions, recovery, and validation, with no second client store. These controls
retain their labels with accessibility scaling. This September 28 owner correction
supersedes the prior text-only actions and nested client routes for Estimates.
It does not change the separate estimate review composition or document templates.
The inline new-client editor is a conventional form: persistent labels above
unfilled, underlined inputs, grouped by client/contact and billing/service details.
Do not turn each input into a filled container. Retain the bordered choice buttons
above the form and normal accessible spacing between fields.

September 29 correction: inline Add new client opens a fresh form without an
automatic recovery dialog. The initial choices expose existing input separately
as Unfinished client forms; selecting one resumes it in place. Merely opening an
empty form must not persist an unnamed draft. Existing unfinished input remains
recoverable and is never deleted by this presentation change. Native Back and
visible Back preserve entered input. Single-line fields use keyboard Next to
advance focus, following UI foundation section 11. The optional business field
identifies the client's business, not the account owner's company.

Invoice Client information uses the same Saved clients / Add new row and
searchable client-detail selection as Estimates. Opening or backing out of a
client detail does not select that client. Use this client selects its stable
saved ID and snapshot, updates the service location for a different client, and
preserves invoice work, prices and dates. Selection checks directory access
before navigation and after returning; Add new also requires client-management
permission. Existing authorized invoice snapshots remain historical document
information rather than granting access to the live customer directory.


Required capabilities include:

- person or company name, preferred name, billing identity, and tax fields;
- phone, email, preferred contact method, and communication consent;
- optional customer website; address entry exposes street, city, state/region
  and ZIP/postal code with the appropriate country format;
- billing address and one or more service locations;
- access instructions, site notes, pets/hazards, and authorized contacts;
- linked estimates, jobs, invoices, payments, attachments, and history;
- duplicate detection and an explicit audited merge workflow;
- import/export and deletion/retention behavior appropriate to privacy policy.

Forms use one column on narrow constraints. Wider constraints may pair logically
related fields, but label order, validation, and keyboard traversal remain stable.
Customer details must not be copied into every workflow as editable parallel truth;
documents store the required historical snapshot plus the stable customer/site ID.

Owner clarification, September 14, 2026: Quotes, Estimates, and Invoices link
to the customer and appear in that customer's authorized history. They also
remain visible through the relevant day's Work entries and calendar activity;
these are views of the same record, not separately maintained copies. A customer
link does not grant the customer access to the company's internal record.

Customer storage checkpoint, September 9, 2026: saved contacts and all existing
service locations now persist in SQLite. The client editor retains raw unfinished
input locally, offers owned unfinished new clients on reopening, and resumes the
specific edit draft for an existing client. Back keeps input; explicit discard
removes only the recovery draft. Save waits for the customer write and exact draft
consumption to commit together. A failure or stale edit preserves input and keeps
the form open. This is tested implementation evidence, not owner visual acceptance
or completion of duplicate merging, privacy retention, stable Work foreign keys,
production identity, or every nested workflow. See the storage contract for gates.

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
Drafts have a clearly labeled route reachable from their document workspaces.
Owner correction, September 28 removes the general Work landing Drafts shortcut;
this does not delete any draft records or unfinished input.
New Estimate and New Invoice open fresh forms immediately; existing
unfinished input never interrupts that action. The Drafts route presents saved
draft records and unfinished input in one destination, associates recovered edits
with their existing record, and shows customer/work identity and last-edited dates.
The Estimate or Invoice workspace shows its type-specific drafts shortcut only
when an authorized saved draft or unfinished input exists. The destination title
and every draft row identify the document type; an empty workspace does not offer
a shortcut to a no-drafts page. A draft-load failure remains discoverable for
retry instead of being treated as proof that no drafts exist.
The Drafts list uses visible dividers between both saved records and recoverable
input, and stays at a readable width on larger screens.
Returning to Work never automatically opens a draft. Resume is an explicit choice.
An estimate draft opens its editing form; its saved record also exposes permitted
deletion, editing, items, PDF preview and sending without an obscuring floating menu.
Saved draft deletion retains a tombstone and history, rejects linked or issued
records, and prevents stale editors from bringing a deleted draft back. Every
estimate is its own bordered 60-LP-class record container; rows grow for
accessibility text.

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

The app's stable record ID is separate from the customer-facing document number.
New estimates suggest the next company-wide estimate number and new invoices
suggest the next company-wide invoice number; the two counts are independent.
The business may enter its existing starting number or another custom number
before the first save. A chosen numeric ending advances the next suggestion
by one (for example, 777 then 778), while a one-off custom number does not
silently renumber already saved documents. Saving checks for duplicates across
the whole company, including records created by other employees, in the same
transaction as the document. Deleted or superseded numbers remain reserved so
they cannot later identify a different customer's document. A provisional
number shown on two unsaved forms is not a reservation; the second save must
reject a collision and let its author choose an available number. Existing
saved document numbers are not silently rewritten. The source estimate number
remains a link on a converted job/invoice; the invoice uses its own number.
- Company and customer: sender snapshot, customer, service location, contacts.
- Scope: description, inclusions, exclusions, assumptions, notes, and attachments.
- Job-site photos: camera, photo library, or file; optional plain-language note,
  captured-on time, actor, and estimate revision. Authorized internal users can
  review them later when pricing or performing the work. Photos remain internal
  unless the sender explicitly selects them for the customer-facing copy.
- Items: labor, materials, equipment, procurement, fees, discount, tax, deposit.
- Totals: subtotal, adjustments, tax, total, required deposit, and balance basis.
  September 27: Service terms includes Require a deposit and an explicit amount.
  The requirement is stored with the estimate and its recovery input; it does not
  record money received or change the estimate total. A changed requirement is
  customer-visible and invalidates approval of the prior revision. The amount
  appears in native review, signing, and the generated customer copy. Existing
  records without this field have no structured requirement. Record deposit
  received belongs beside those terms and uses the existing payment workflow.
- Terms and delivery: payment terms, acceptance method, signature, delivery history.

The October 1 owner direction supersedes the separate estimate section cards:
the working estimate resembles a business document on one tinted surface.
Company identity, estimate identity, customer, scope, prices, terms and approval
are separated by headings and rules, not individual boxed cards. Add/Edit
controls open the existing owned forms and return to the document. Company
information links to the permission-guarded saved company editor. Display values
remain projections of durable records; document appearance does not introduce a
second financial store. Narrow estimate pages use 5-LP outer gutters; readable
internal document margins remain. PDF output omits application editing controls.
Material rows now occupy a separately scrollable bordered area capped at half
the usable viewport, with a visible scrollbar, item count, fixed subtotal and
Add or edit materials action opening the existing items screen. Labor and other
charges remain outside that scrolling area. Inventory selection remains future
work and is not simulated.
This is a first visual implementation, not owner acceptance or a completed
portal/approval redesign.

Created date is editable; Date finished is explicit and separate from Date sent
to customer. Dates Edit allows the user to record the actual sent date; this is
user-reported metadata, not proof of receipt, a sending action, or customer
approval. It does not silently advance the document lifecycle. Validity choices are 7 days, 30 days, 90 days, one year (365 days),
and custom days, with no default selected on new estimates. Owner confirmed that
the selected period starts on Date sent to customer. Until sending is recorded,
there is no computed expiry; the customer copy states the selected period.
Legacy explicit expiration dates remain intact until deliberately changed.
Multiple proposed service dates/times remain suggestions, not booked visits.

Labor/materials retain their separate entry screen. Their complete item list and
subtotal, discount, tax and estimate total share a single document section.
Edit pricing within that section includes
a flat price when there are no individual items, plus discount and tax. Terms
allow multiple saved selections or custom text and display the resulting text.
Customer approval remains embedded below those terms; saved approval belongs to
the exact saved revision, and changing customer content requires fresh approval.

PDF previews and template browsing permit an incomplete company profile with a
visible preview-only notice. Outgoing PDFs still require the business name and
report that missing information accurately; no fake company record is inserted.
September 29 native verification: all ten catalog PDFs generated, opened through
pdfx, and rendered a page on the Galaxy S25 Ultra in the isolated STORAGE_QA
application, with no company record and no outgoing messages. This proves native
PDF rendering, not owner visual acceptance of the main document layout.
PDF template selection, Preview PDF and Send estimate are grouped in a Customer
document section with visible action boundaries. Save estimate and Cancel follow
in scrolling content. Back/Cancel with changed input offers Save changes,
Discard changes, and Keep editing. Discarding changes must preserve the existing
saved estimate. Delete draft removes only the recovery draft after confirmation;
for an existing record the label is Delete draft changes. Opening delivery or a
composer does not establish that anything was sent.

The earlier flat form passed 166 regression tests and an Android build and was
installed on the S25 Ultra, but the owner rejected its grouping and action layout.
That evidence does not validate this corrected layout. Current grouped layout and
validity changes require renewed regression and rendered verification. The owner
has requested finishing these changes without launching on a device at present.
Existing UI-Lab draft, signature and approval systems are reused; 5.7 remains
read-only and no source was copied from it for this correction.

An estimate supports Draft, Ready, Sent, Viewed, Accepted, Rejected, Revision
requested, Expired, Cancelled, and Converted states. Editing after acceptance
creates a revision or change order; it does not rewrite the accepted snapshot.
Any change to customer-visible scope, quantity, item, price, discount, tax, or
terms invalidates the current approval even when the total changes by only one
cent. The prior signature remains only with its signed revision in audit
history; it is never displayed or accepted as approval of the revised estimate.
The revised estimate returns to an approval-required state and cannot create a
job until the customer approves that exact revision.
Implementation checkpoint: the estimate editor's main input now persists as a
separate local recovery draft. Back retains it; explicit confirmation atomically
writes the estimate revision and consumes that exact recovery draft. A failed
confirmation preserves the saved approval and unfinished input. Nested labor/material lists and unfinished line items now share this recovery
draft; confirmation requires reviewing those changes first. Photo-list metadata and unfinished notes also recover locally, but durable
new imports use app-owned verified files. Existing-path migration and real-device
image interruption validation remain unfinished; see `data_storage_sync_contract.md` for the
verified scope and remaining gaps.

Job workspace rescheduling now retains unfinished date/time input separately and
preserves the recorded elapsed duration when confirming a new arrival time. A
missing start/end interval blocks confirmation instead of assuming two hours.
This storage checkpoint does not replace the time-zone, feasibility or scheduling
engine requirements in `scheduling_system_blueprint.md`.

Acceptance never creates a job automatically. A separately permitted, explicit
`Create and plan job` action creates the linked job and then requires schedule
and assignment review. SQLite-backed creation now commits the job and estimate
conversion together, checks the captured source revision/current signature, and
rejects competing conversions. The editor stays open if confirmation fails; raw
job main-form and nested item input now autosave separately, retain on Back,
and are consumed only with successful confirmation.

The linked job must retain the approved estimate's saved customer snapshot;
conversion rejects a substituted or missing snapshot. Job contact display uses
that recorded snapshot before a current-directory fallback, so later directory
edits do not silently change the contact details carried into the job or invoice.
The conversion also retains the estimate's photo references and notes, without
copying or deleting original media. Dropping those references blocks conversion.
The job's photo section opens a read-only preview after checking current job
visibility and saved membership. Missing files show an unavailable image state.
New job camera/library/file imports use the shared native coordinator and a
separate actor-owned `work/job-photos` draft. Photo notes and selections survive
Back and reopen; unfinished input is also reachable from saved-work recovery.
Save confirms the reviewed photo list atomically against the original job
revision. Failed or stale saves retain unfinished photos and original files.
The `canAttachJobPhotos` grant is checked on opening, native adoption and record
mutation; a visible button is not authority. Production account provisioning,
Google Drive backup and physical-device interruption testing remain unfinished.

New Job presents a prominent direct-job action before the optional estimate
chooser. Choosing an estimate opens that exact document for approval review;
it does not skip straight to conversion. Estimate choices use the same compact,
fully tappable bordered rows as the other Work lists, with number, work title,
customer and approval state visible. They grow when text is enlarged instead
of reserving large empty card space. A new direct job has resumable unfinished
input even when no estimate or quote exists; it does not require filling out
a proposal first.

September 14 repair checkpoint: Work exposed Employees and a separate Drafts
route. A later in-progress repair replaces the Work entry with Employee status;
the private profile directory remains in the main menu. The status list and
Dashboard summary derive labels from visible saved job/workday records, and the
employee detail opens job assignment through the existing assignment editor.
The Work status route and Payments entry point were visually checked on the
USB-connected S25 Ultra. This is a saved-record view, not live location or
dispatch; assignment save and timesheet permissions still need broader device
acceptance. Job creation and assignment select active saved employee profiles
by stable ID, including multiple employees. Add employee opens the shared profile editor
from job assignment after flushing unfinished job input; a newly saved profile is
selected on return. Assignment changes recheck the explicit assignment grant and
active profile identities inside the SQLite commit transaction. The dashboard
Plan projection and Work employee filters recognize these IDs. Regression tests
cover new profiles, approved-estimate conversion, two-person assignment across
reopen, reassignment, missing/inactive profiles, denied assignment, and assignment
save failure with retained input and retry. Employee profile editor tests cover
creation, recovery, failed save/retry and denied private routes.

This is local profile and Work persistence wiring, not employee authentication,
cross-device dispatch, skill/availability scheduling, or owner visual acceptance.
Those dependencies remain required; see `data_storage_sync_contract.md` and
`scheduling_system_blueprint.md`.

Current repair checkpoint: Estimate and Invoice details expose inline Edit,
Preview PDF, Send, and permitted draft deletion. Estimate details also expose
customer approval and Create and assign job, enabled only when the recorded
revision permits them. A confirmed form Save opens document review; leaving a
form or returning to Work does not automatically reopen unfinished input.
Drafts are reached through one dedicated destination filtered by document type,
with last-edited dates and saved/recoverable versions grouped by record identity.
The initial client section precedes document details, template and PDF preview.


Scheduling now projects existing authorized Jobs, including overnight windows,
with employee filtering and screen-specific display settings. It links to the
existing persisted job schedule and assignment editors. It does not assert that
employees are available or that a crew has sufficient skills/capacity.
September 28 UI checkpoint: Scheduling reuses WorkDetailHeader with Back and
its own settings. Scheduled jobs and Needs scheduling use the shared compact
horizontal summary strip and switch the record list in place. Empty record
sections are absent; there are no zero-count section containers or repeated
no-jobs paragraphs. New job uses the lower-right action with reserved scroll
space. Calendar and both counts derive from the same authorized, person-scoped
job projection, with an additional assigned-employee filter. Returning from a
durably confirmed new job does not attempt a second create. Focused widget and
schedule persistence/conflict tests pass; real-device acceptance remains open.
New owner-requested debug Work examples use distinct customers for draft, ready,
approved, scheduled, completed and invoiced examples. Replacement is once-only,
company-scoped, and preserves other modules. Plan is scheduled work; Entries
shows dated recorded activity, with document numbers, status and time visible.

Employee/activity repair checkpoint: Estimate, Invoice and Job details expose
People and activity. Creator and current assigned employee IDs are separate from
the actual mutation actor on each committed SQLite revision. The history reader
checks company/owner boundaries, payload hashes, identity and revision sequence,
and pages older changes without creating a second source of document history.
Names resolve through the authorized current directory; stable IDs remain visible
when a profile is renamed, unavailable or no longer active. This does not claim
employee login/authentication is connected in the development shell.

PDF exports now persist a Work-owned attempt before launching external sharing,
saving or printing, followed by completed/cancelled/unconfirmed/failed outcome.
An interrupted attempt remains explicitly unresolved. Exporting checks the stored
source revision again around rendering. The shared exporter returns technical
outcomes only; Work owns the business audit. A share-app handoff never claims
customer delivery, reading or approval. Quote integration remains unfinished and
must adopt these same boundaries when its own workflow is connected.

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
same records, not a second copy. Customer history uses the same authorized Work
projection as other Work lists. A saved customer snapshot ID takes precedence
over names, preserving identity after renaming and separating identical names.
For legacy records without an ID, a name matches only when exactly one saved
client has that name; ambiguous legacy records remain in their Work lists and
are not silently assigned. The same identity rule applies to PDF previews,
exports, customer-review copies, and default email/text recipients: never choose
the first of several clients with the same name. A saved document snapshot remains
authoritative even if the live directory changes. Visible history counts are derived from those rows,
not a cached customer count. New estimate from client details carries the stable
customer snapshot into the existing draft workflow. This checkpoint does not
complete payment/attachment history or granular financial permissions.
The estimate detail screen owns status, exact revision,
meaningful dates, scope, separately grouped Labor and Materials, internal
revision/delivery history, and the actions Preview customer copy, Send or share,
Sign in person, and—only after approval of the current revision—Create and plan
job.

Owner correction, September 25: ordinary estimate actions remain visible and
labeled rather than hidden in an action directory. September 27 owner correction: the editor exposes a distinct **Review estimate**
route into the native estimate details, separate from **Preview PDF**. Review
shows the current form information without committing it. Continue editing/back
returns to the same input; Save estimate explicitly confirms through the existing
atomic save/recovery path. Continue editing appears as an unboxed text button beside the estimate title,
aligned to its first text baseline.
Save estimate and a second Continue editing appear after the review content,
inside the page scroll, never in a pinned footer. Save appears only at the bottom;
no additional Cancel or Close action is introduced. Controls may reflow without truncation.
September 27 direct-edit correction: tapping a review section opens its own
editor titled **Editing [section]**, with **Save changes** returning to the same
review route and scroll position. Customer information, work details, labor and
materials, discount and tax, dates, and service terms use the existing draft
controls and recovery paths. Saved records commit explicitly; pre-save review
retains changes in its existing draft until Save estimate. The proposed service
date remains visible near the customer, including **Not set** when empty. Use
**Continue adding the work details and prices** instead of developer-oriented wording.
September 30 estimate refinement: retain the existing section editors and recovery
workflow. The editor begins with the authorized saved company identity and estimate
reference/status, then its existing document sections. Missing company access or
storage is shown honestly. Use compact shared document navigation with Dashboard's
76-LP minimum height, expanding for accessibility. Tighten section spacing without
removing grouping; detailed item quantities, unit prices and amounts use aligned
columns, reflowing to labeled rows on narrow screens. Amounts and totals align at
the end edge with tabular digits, including at enlarged text sizes. PDF templates
and generation remain unchanged. This supersedes the status-card placement below
for the editor only; saved detail and review routes retain their existing behavior.

The estimate status card sits directly below the header. Its label and value
share the existing heading size and weight. Work details, labor and materials,
service terms/deposit, and date edit controls are inside their respective cards
at the top right; the dates action sits above the date-value column. The whole
editable card still opens its existing section editor.
Saved details put proposed work, Labor and materials, and Service terms and deposit
before approval, scheduling, and sharing actions. Actions sit with the section
they affect; no large action wall precedes the record. Tinted surfaces and readable
labels provide grouping without depending on color alone.
Customer signature and approval is the final tappable section of the scrollable
form. Photos has its own compact bordered summary card with Add photos inside
it, opening camera/library/file choices and per-photo details. View photo opens
a read-only, zoomable image inside the app. Removing an attachment requires
confirmation naming the photo; cancel preserves its note and attachment, and
confirmed removal does not delete the retained image file. Remaining attachments
stay linked to this estimate through existing recovery and media retention.
Review also exposes Add photos and Save and get customer
approval at its end. Approval saves the current estimate before opening the
customer approval route; its primary action is Add customer signature. The
signing pad is visible on entry and provides Fine (2), Medium (3, default), and
Bold (4 logical pixels) thickness choices. Thickness is retained with normalized
ink through recovery, saved records and proportionally rendered customer PDFs;
legacy ink retains its previous rendering. Changing ink thickness resets consent.
Signed estimates remain shareable as a signed copy. Android email/text composition
filters installed apps by their email/messaging category and PDF attachment
support; the generic device share option remains separate. Recipient, PDF bytes,
read permission and filename pass to the external composer. Opening a composer
never records confirmed delivery. A customer must still send from that app.
Device verification on September 27: Gmail attached the generated PDF; Messages
opened a composer addressed to a synthetic test number with the PDF, and tapping
it opened the one-page estimate in a device PDF viewer. No message was sent. Remote portal approval and
optional Google Drive photo backup are separate, not prerequisites for local signing
or email/device sharing. These changes do not publish or activate cloud services.
Preview and approval are child routes of that exact editor. Back/cancel returns
to the same editor and scroll position, with its input retained; successful
approval refreshes its status without closing it or detouring through details.
The approved version must be saved before recording acceptance, with failed
writes leaving recoverable input. Separate capabilities govern recording an
approval and collecting a signature.

Approval opens a full screen with an explicit Review and sign in person action.
The signing screen presents the work, item prices, adjustments, total, terms,
customer name, a clear Tap to sign action, and an acceptance control. Tap to sign
reveals a bounded handwriting area with thin strokes, Clear, and Done signing;
acceptance stays unavailable until handwriting exists. The saved signature
remains tied to the exact reviewed revision. Remote signing links
are deferred by the owner; offline in-person signing remains required. Approval
and its exact document version must survive a local save and restart.

Estimate review separates work and prices, approval and dates, and changes and
sharing history. Wide layouts use the shared bounded operations lanes, including
three columns when available width and text scaling permit. History is not the
Add more work action. Existing line items retain stable IDs and evidence links;
customer-visible changes invalidate the prior approval for the revised copy.

Labor is not disguised as a generic material line. Labor rows support role or
service, hours or service quantity, customer rate, private internal rate, and
customer-facing description. The line-entry form separates fields by at least
20 logical pixels; explanations about worker rates and private costs appear above
the relevant field with an 8-LP gap. Narrow layouts reflow quantity/unit controls
with accessibility text scaling. Routine local-save messages stay hidden in the
estimate and item editors; write failures remain visible with a retry action.
Units also support miles, kilometers, trips, and loads for travel and delivery
charges in the same item workflow. Material rows may begin manually, from confirmed
material cost history, or from a recorded expense/receipt. Linking evidence
never silently turns the full receipt total into a customer charge; the human
reviews and edits quantity, description, cost, markup, and price.
On the Estimate Items screen, Labor, Materials, and other-charge sections appear
only after their first item is added. Empty sections do not instruct the user
to tap an item that does not exist.

September 14 owner direction: Add items for Estimates, Invoices and itemized
Quotes must offer clearly labeled Add from materials and Add from previous
receipt. Materials opens the Materials home screen in a selection context;
receipt selection opens previously saved authorized receipts and their items.
Selecting items returns to the original document draft with its existing input
preserved. Review quantities, units, cost and customer price before confirming.
Cancel returns without adding items. Preserve source IDs; do not duplicate an
expense or consume stock merely by inserting a document line. Quote lifecycle
decisions remain open independently of this required item-source workflow.

Creating an estimate is a phone-complete field workflow. An authorized user can
start the draft at the job site, capture and label condition photos, save the
draft offline, and finish scope and pricing later without losing the customer,
site, photos, or notes. The labeled New estimate FAB is present whenever create
permission is granted. Tablet and desktop may arrange the same information into
bounded additional lanes, but they do not expose required capabilities that are
missing from the phone flow.

Quote, Estimate, and Invoice presentation uses a shared PDF document engine with exact
preview before delivery. Provide restrained professional templates first, then
optional trade-filtered decorative templates such as plumbing, HVAC, lawn care,
or masonry. Company identity, logo, customer, job location, item table, totals,
terms, signatures, and payment details come from confirmed records; the visual
template never owns or rewrites that data.
For an invoice customer copy, retain the original total and show paid and amount
due from the current invoice ledger, including any prior job or estimate payment
explicitly applied to that invoice. Applying a deposit is not a second receipt
of money. Generated PDFs and customer review copies use the same calculation.

Owner requirement, September 14, 2026: build the shared PDF generator and reader
as application-wide infrastructure, reusable for these documents and Expenses.
A formal document preview is complete only when it renders the actual generated
PDF that can be saved and shared, not a screen imitation or placeholder.
Generation, local reading, and saved-copy retrieval must work offline. Document
templates consume the same confirmed revision, including items, totals, company
and customer snapshots, and terms; changing graphics must not change its content.
This is a required build dependency, not a claim that the current engine exists.

### Estimate and Invoice terms

Quotes also require editable, reusable terms copied into the document revision;
their acceptance and conversion rules remain subject to U04. Estimates must
include applicable payment expectations as well as service conditions, for
example company-authored wording such as "Payment is due at time of service."
That example is not an automatic default. Show the reviewed terms in both the
formal PDF and any customer web view of that same revision.

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

The in-app customer approval form also displays the work, customer prices, total,
and terms before the acknowledgment and approval actions. Adding a customer
signature reveals the signing area in that same form; it does not navigate to
another review screen or require another "Tap to sign" button. Approval without
a signature remains a separate explicit action. Unfinished ink uses the existing
durable signature draft and Back must flush it before leaving. These UI checks
do not substitute for permission enforcement, revision checks, or external
approval evidence.

Unfinished approval entered without a signature follows the same durable draft
contract. Opening the form alone creates no unfinished business input. Entered
method, customer name, notes, and acknowledgment recover without granting
approval. Confirmation checks the saved estimate revision and consumes the input
atomically with approval; failed confirmation preserves it. Recovery entries are
scoped to the current organization, employee, and approval permissions.

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

Owner clarification, September 14: Send estimate begins from the working draft.
The user must not first discover a separate Mark ready action. Leaving delivery
preparation before confirmation preserves Draft status; confirming preparation
finalizes the customer copy without falsely claiming the customer received it.
Company approval remains enforced when enabled. Estimate settings expose that
company-owned default for new estimates, restricted to company-profile managers;
existing issued records retain their recorded requirements and history.

Owner clarification, September 14, 2026: Quotes, Estimates, and Invoices need
customer-understandable delivery through email and text-message sharing, as well
as saving the actual PDF. Channel capabilities determine whether an attachment
or secure document link can be used; unavailable channels must offer another
supported method without losing the document. Customers must not need to install
Maintainiac to read their copy. Use everyday labels and spell out Quote,
Estimate, and Invoice in customer-facing presentation.

Presentation recommendation under discussion: keep the PDF as the formal,
downloadable and printable copy, and offer a phone-friendly browser view of the
same revision through the planned portal below. That view must show the same
items, totals and terms without exposing internal information. This does not
settle portal release timing, customer verification, or Quote acceptance policy.

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

Status reconciliation: the following is the existing PLANNED portal design
(P02). The current owner requests mapping, not automatic approval of its
release-one timing or every commercial/consent rule. U08 owns those open choices.
Preserve security boundaries while awaiting decisions.

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

September 14 owner requirement: the three-dot menu on a job in Today's Plan
must offer recording arrival time. It sends the same authorized job command as
arrival from Job detail; the actual Job owns the event, not the Dashboard row.
Record the arrival's actual date/time, employee/actor and stable Job and visit
identities. Jobs lasting days, weeks or months retain separate arrivals for
each visit, including multiple visits in a day; never overwrite an earlier
arrival with the newest one. Job history and the relevant calendar day project
those same events. Later corrections retain who changed what and when.
Repeated taps/retries must not create duplicate arrivals for one command.

The owner also requires an odometer prompt on arrival. Whether an absent
reading blocks continuation or leaves a follow-up reminder remains unanswered.
Arrival must remain distinct from work-start and must not silently start billed
labor time. Current status-only handlers do not fulfill this event contract.

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

September 14 form review: use the demonstrated Maintainiac form's separate,
visibly tappable summary containers as the design reference. Each shows its
section name and current value/status, and opens that section's editor. Inspect
the relevant latest local reference implementation before adapting; do not copy
the whole form, its incorrect labels, or unverified behavior wholesale.

Owner clarification: reproduce substantially this form arrangement, not 5.7's
colors or decorative skin. Support both the current app's light theme and a
dark theme through shared theme components. Preview must render the current
Invoice, Estimate or Quote document with its actual current content and chosen
template, rather than a generic sample. Generation and viewing belong to the
shared document/PDF system; its separate assignment is controlled by the owner.

September 14 repair checkpoint, superseding the rejected earlier arrangement:
New/Edit Invoice and Estimate open individually bordered, tappable summary
containers with Client information first, then document information (including
number and optional purchase order), template near the top, dates, and a unified
Items entry. Client and document information open separate editors without
nested decorated cards. Dates, discount, tax,
template and terms open focused editors; item editing retains the existing
labor/material/source workflows. Invoice source and expected payment method
remain separate from issuing or receiving a payment. Subtotal and total are
calculated summaries, not editable amounts. The 5.7 invoice source was inspected
read-only as the structural reference; UI Lab retains its shared theme and
persistence. This implementation checkpoint is not owner visual acceptance.

The shared `DocumentFormOverview` assembles the same ordered section groups into
one, two or three lanes using `AppLayoutEngine.workFor` and local `TextScaler`.
`DocumentSectionEditor` keeps the owning draft's controllers and autosave session;
Back/Done waits for the latest local save, retains failed input and offers retry.
Saving the enclosing document remains the existing validated atomic command.
Neither opening a section nor selecting a payment method issues an invoice,
records a payment, shares a document or marks it paid. Payments retain their
existing exact invoice ID and balance-aware form. Full PDF delivery, Quote
lifecycle policy and production inventory intake remain separate dependencies;
the owner explicitly deferred materials integration and receipt parsing here.

PDF delivery feedback: invoice actions expose Save PDF copy beside Send invoice.
Both use the same current-record authorization, PDF generation and export audit.
Drafts still require the existing explicit finalization flow before final-copy
delivery. Validation failures retain actionable messages; native failures do not
expose private platform details. Cancellation and an unconfirmed system result
are distinct from completion. A successful share handoff never claims that a
customer received the document. Preview delivery uses the same feedback rules.

Company information comes from the account owner's confirmed business profile;
do not make the user enter it again for each document. The owner tentatively
prefers removing the Company Information card from ordinary document creation.
Final card visibility remains open; missing required profile details must still
have a clear setup/review path. Client Information selects or creates the client
with name, street, city, state/region, postal code, email, optional website and
phone, reusing the customer/site ownership rules above. Historical document
identity remains a snapshot, not a live rewrite when the profile changes.

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
The display view does not revoke a company owner's active Work-session payment
grant. Work home and its Payments route use that grant to show Record payment;
the company-wide ledger remains restricted to company-wide authority until
employee-scoped payment queries are enforced throughout the route.

Every Invoice creation entry point uses one dedicated editor. The user first
chooses a source Job or `Direct invoice`; choosing a Job copies its customer,
service location, completed-work summary, pricing method, and reviewed items
while preserving the Job ID as the source. The user may then review customer,
work completed, invoice items, invoice and due dates, discount, tax, template,
expected payment method, and payment terms. An incomplete form does not create
a record. The editor offers **Save draft** and, with explicit issue authority,
**Create invoice**. Save draft creates an Unfinished draft. Create invoice
confirms that the amount will be added to the books, then saves the issued
Invoice and its single financial entry together. Neither action sends a
customer copy; delivery is a separate, labeled step.
The two editor actions remain in scrolling content. Their row uses measured
label widths and the current TextScaler against local available width; normal
320-LP phone text fits side by side, and enlarged text stacks when needed.
Both retain at least 48-LP touch height. Tests load the shipped Material font
and exercise direct creation at normal and doubled text, plus failed-save retry.
Storage integration checkpoint, September 9, 2026: the main Invoice editor now
keeps raw unfinished input separately from the saved invoice file. It shows local
write acknowledgment and retry failure, offers owner-scoped unfinished invoices
when starting another invoice, and restores the specific recovery draft when
editing an existing invoice. Back retains input; `Discard unfinished input`
requires an explicit confirmation and does not delete a saved invoice record.
`Save draft` validates the form and atomically stores the record while
consuming the exact recovery draft revision. Failed or stale confirmation keeps
the editor and recovery input. Direct Create invoice likewise consumes that
revision only when both the Invoice and its ledger entry commit. This is an
implementation checkpoint, not owner
visual acceptance or complete workflow durability. The invoice item workspace
and line-item form now share its recovery checkpoint, preserving partial numbers,
item identity and source links. Back retains their input. A pending item offers
`Continue unfinished item`; starting competing edits and saving the enclosing
invoice wait until that input is reviewed or explicitly discarded. `Discard item
changes` confirms removal of that working item session, leaving previously saved
invoice records unchanged. New-customer input is now connected to its own scoped directory recovery
draft; company-profile and payment input now have their own scoped recovery
drafts as well. Other module editors and global recovery navigation still need
integration. The shared storage contract owns cross-module draft policy and
remaining gates.

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
Dashboard, Payments, Invoice detail, and reports derive the open amount from
the invoice total minus recorded payments, including partial payments. Existing
payments linked by displayed invoice number and payments linked by stable
invoice ID must resolve to the same invoice; a status label alone cannot stand
in for the balance. A dated report excludes payments after its as-of day.
An invoice payment uses the full-screen balance-aware form. Payments also has a
direct path for money received without an invoice, with amount, date, method,
description, optional payer, and an optional link to a saved Job or Estimate.
The received date defaults to today when recording from a future calendar day.
It can be today or earlier, but a future date cannot be recorded as money
already received. A promised or expected payment needs its own distinct state.
When open invoices exist, Record payment offers those two paths plainly; when
none exist, it opens the direct form. The invoice path selects an authorized
open invoice; drafts and paid invoices are excluded, prior payments reduce the
offered balance, and overpayment is rejected. A direct payment does not change
an invoice balance. Quote links wait until Quotes are stored as real records.
An Estimate or Job may offer a contextual Record deposit/payment action; that
link alone does not apply money to a later Invoice. On an issued Invoice, Apply
a recorded deposit offers only prior payments tied to its source Job or
Estimate. Confirmation writes a separate durable application event for the
lesser of the available deposit and invoice balance. It never records money
received again. The source payment cannot be applied twice, including across
different invoices or concurrent sessions; an invoice revision advances with
each application. Unlinked payments still need an explicit customer-safe
allocation path rather than a name-based automatic match.
Selecting a saved payment opens its payment details and any linked Work record.
An authorized owner can preview a customer payment receipt generated from the
saved money-received entry, including a standalone payment with no invoice or
job. The receipt shows company identity, received date, amount, method, optional
payer and work description, plus a stable public reference derived from the
private payment ID. Internal payment notes and the raw storage ID stay off the
customer copy. A saved, viewable company identity is required; the UI Lab demo
company fallback cannot be used to prepare a customer receipt. Save PDF and
Share PDF are separate explicit actions; opening
the sharing app is not proof of customer delivery. Applying an existing deposit
to an invoice never produces a second receipt for money received.
Saved payments use the same
compact record grammar as the rest of Work: each payment is a separate bordered
60-LP-class container rather than a merged list inside one undifferentiated panel.
Payment storage checkpoint, September 9, 2026: raw amount, method, date and note
save locally without creating a payment. Back retains input; explicit discard
removes only the unconfirmed draft. Saving validates exact decimal cents, checks
the current authorized balance, and commits the payment, invoice storage revision
and exact draft consumption together. A failed or stale write keeps the form and
input. Even partial payments advance the shared invoice storage revision so two
independent sessions cannot post against the same stale balance. This has focused
regression evidence; it does not establish physical-device interruption behavior
or complete recovery access after an invoice leaves the normal open-invoice list.

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

Invoice collection presentation uses one read-only projection for all-date list
filters, list labels and the review heading: confirmed invoice payments and
allocations determine paid/partial balance, and the local due date determines
overdue after that date ends. Drafts remain drafts. Existing explicit Paid
records remain recognized for compatibility; the projection does not rewrite
historical status or ledger entries. Review access without financial permission
must not infer a new payment status from a ledger it cannot display. This shared
presentation rule does not establish complete account or Firebase enforcement.

Opening invoice review resolves the stable invoice ID against the current Work
store and current employee scope before rendering. A passed route snapshot is
not a fallback source when that invoice is absent or inaccessible. Scope changes
while review is open must replace its contents with an unavailable state and
remove its financial/actions content; an available back route remains usable.

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
- Work home uses `AppLayoutEngine.workLandingFor` and no private width rules.
  Its wide composition groups dated records beside a readable calendar in two
  bounded 400-LP-maximum lanes. Its directory uses six labeled 62-LP icon
  surfaces governed by `AppLayoutEngine.workShortcutsFor` with measured labels.
- Work home order and compact money overview follow the owning Work home
  section of operations_screen_blueprint.md. The selected date remains near
  the header; the calendar follows records on narrow screens and sits alongside
  them when the shared layout has room.
  Destination ownership and the remaining unconnected Quotes state are specified
  in the Work home section of `operations_screen_blueprint.md`. Redundant date and employee
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
