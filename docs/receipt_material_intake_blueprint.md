# Receipt, Material, and Job-Cost Intake Blueprint

Status: UI Lab contract for later production integration  
Last updated: 2026-08-30  
Applies to: Expenses, Receipt Review, Jobs, Estimates, Inventory, and Document Intake  
Maintenance is outside this blueprint.

## 1. Purpose

Owner override, September 14: this application records **business receipts
only**. Do not ask business/personal classification or introduce a personal
budget flow. This does not authorize relabeling historical records or silently
including non-business lines in a business amount. Mixed source evidence needs
explicit exclusion of unrelated lines while retaining the evidence. Category
remains optional and must have a real selector, not a free-text substitute.

Maintainiac must accept receipt evidence without assuming every receipt begins
with a new camera photo. The same reviewed intake system supports:

- taking one or more receipt photos;
- choosing existing receipt photos or a PDF/file;
- choosing a receipt already recorded in Expenses;
- choosing an existing expense, with or without receipt evidence;
- choosing verified material-cost history;
- using material already carried on a selected service vehicle;
- manually adding an item when no source record exists.

The system turns evidence into proposals. The internal recognition engine,
stitching, catalog matching, and AI never directly create or change an expense,
estimate, job charge, invoice, material cost, or stock quantity. An authorized
person reviews and confirms the specific effects first.

### Customer-facing name and choice

Owner update 2026-09-07: receipt reading is optional. Use plain English, not OCR;
“app-assisted receipts” is an owner example, while Receipt Assistant below is a
working label, not a final naming decision. Defaults remain subject to review.

### Basic and Detailed receipts — owner-confirmed

Two receipt modes are required. Detailed includes individual line items and
line prices/quantities as applicable. Basic records the receipt without requiring
line itemization. Category is optional: users may leave it unset or choose a
plain general business-receipt classification. Do not force them to choose even
that general category, invent a tax category, or block save because it is absent.
Required header fields beyond this decision remain to be defined; “Basic” does
not silently make vendor/date or every existing form field mandatory.

Both modes support manual entry with receipt assistance off. Assistance does
not select a category or commit extracted fields without confirmation. An unset
category remains stable/null in storage; any helpful “Uncategorized” display
label is not an inferred tax classification. Category-specific fields appear
when a category is selected, without making category selection mandatory.

### Receipt backup sizes and preview — owner-confirmed

At the backup-choice stage offer approximately 1 MB, 750 KB, 500 KB and 250 KB
image-size targets. These are output-size choices, not guarantees that every
receipt remains legible or an authorization to discard source data.

Generate and show the actual candidate image before the user accepts its size.
Allow useful zoom/pan to inspect fine print and long-receipt sections; show the
actual resulting size. Never preview the original while saving a different
compressed image. If a target cannot preserve readability, report that and let
the user choose another size or retake/add sections; do not silently degrade.

Use the original-quality image for extraction only when the user enables receipt
assistance. The selected reviewed proof image can be the backed-up copy; original
resolution is not a permanent backup requirement. Keep source bytes intact while
capture/stitching/extraction and preview are pending. When/how originals may be
removed after confirmation, and whether targets apply per photo or stitched
output, remain open. No original deletion is implemented or authorized here.

“Receipt photo” or “Saved receipt image” are plain-English naming proposals.
Paid receipt backup is optional; refusing backup cannot block local saving or
manual Basic/Detailed receipts. See `data_storage_sync_contract.md`.

### Shared device workload control — September 14 owner addition

The capability engine is shared across the app and consulted before costly work.
It must protect lower-resource phones using runtime memory, thermal and power
conditions, not phone price, brand, model name or age. Receipt reading targets
roughly 5–10 seconds; this is a performance acceptance target, not a guaranteed
maximum or an established industry standard. Measure cold/warm runs and repeated
receipts on physical lower-resource Android and iPhone devices. Report latency,
memory, thermal changes, failures and recognition accuracy together. Reducing
image quality must not be counted as success when it loses purchased items.

Initial implementation adapts the 5.7 shared device capability service and native
runtime probes, excluding camera controls, identity collection, Bluetooth and
PDF policy. `data/device_capabilities/device_workload_service.dart` owns a shared
heavy-work gate and refreshed admission checks. OCR is its first connected
consumer; other modules do not yet obey this gate. Limited/standard/capable
tiers permit 1/2/3 million pixels in temporary OCR copies, respectively, with
12/32/32 MiB encoded-file limits. These conservative starting budgets require
device calibration. Unknown hardware defaults to limited. Power-saving, small
heaps, low memory or elevated temperature reduce work; serious/critical thermal
conditions and critical memory defer new heavy work. Only one admitted heavy
task runs at a time regardless of tier. A 10-second UI timeout does not release
the slot while native work is still running. Native cancellation, runtime events
during a read and sustained thermal tests remain outstanding.

The photo review also uses a pixel-bounded preview rather than decoding the
full original into the widget image cache. Other image surfaces have not yet
been adapted. Retained references resolve through the existing installation
file resolver. The image reader uses a bounded temporary copy, retains original photo evidence,
and maps recognized line regions back to source dimensions. It reads only after
an explicit `Read photo` action. Raw text is currently shown in the photo review
session only: durable SQLite recognition history, parsing proposals, automatic
field population and long-receipt assembly are not connected yet. This is an
integration slice, not a complete receipt assistant. Blank text, unsupported
desktop reading, failed reads, source changes and retries have explicit states.
No PDF engine code is part of this slice. The app continues using the native
camera/photo-picker path; no custom camera application is being built.

### Receipt assistance choices

**Receipt Assistant** is the working customer-facing name for the optional
receipt-reading feature. `OCR` remains an internal engineering term and is
prohibited in ordinary customer-facing labels, helper text, buttons, errors,
onboarding, and settings.

On first entering Expenses, offer help without blocking manual use. Before
reading a receipt, ask in plain language unless the user already opted in:

> Would you like Receipt Assistant to suggest the receipt details?

Offer explicit choices:

- **Read and suggest details**;
- **Enter details myself**;
- **Not now**.

Receipt settings offer **Ask every time** as the recommended default, **Use
Receipt Assistant after I select a receipt** as an explicit opt-in, and **Keep
Receipt Assistant off**. The user can change this choice later. Disabling the
assistant never disables taking or attaching receipt photos, retaining evidence,
manually entering an expense, manually entering every receipt line, or linking
the receipt to a job.

If a future implementation sends receipt information away from the device, that
requires a separate plain-language disclosure and explicit permission. Enabling
local receipt suggestions does not silently authorize cloud processing.

Every proposed value and every proposed logical line remains editable regardless
of confidence. The user can add a missed line, edit all fields, merge wrapped
rows, split combined rows, exclude or restore a line, correct package facts, and
change allocations before confirmation. The assistant never locks a field
because it believes the answer is correct.

After confirmation, an authorized user still has an **Edit receipt details** or
**Correct receipt** path. Later corrections preserve the original evidence,
previous confirmed values, linked records, who made the correction, when it was
made, and why. Editing must not require rerunning Receipt Assistant.

## 2. Truth and ownership

- **Document Intake** owns original images/files, page order, stitched previews,
  recognized text, source regions, parser version, and extraction proposals.
- **Expenses** owns the purchase/expense record and its accounting category.
- **Inventory** owns catalog identity, verified cost history, stock locations,
  counts, receipts, transfers, usage, and returns.
- **Work** owns estimate lines, job requirements, actual job use, change orders,
  billable adjustments, and invoice candidates.
- A job links to an expense or receipt by stable identity. It does not copy the
  expense and create a second purchase.
- Using existing truck stock records a job allocation and stock movement. It is
  not a second expense because the purchase happened earlier.
- An estimate may use confirmed historical cost as evidence. Creating an
  estimate never consumes physical stock.
- An invoice includes confirmed billable work. It does not automatically bill
  every expense or every material used.

### Current UI Lab durable draft/evidence checkpoint

September 14 owner-reported workflow defect: receipt drafts are visible in the
company view but their deletion is not discoverable. A permitted user needs a
clearly labeled Delete draft action from the draft list/detail, explaining the
effect before confirmation and refreshing draft counts after success. Reuse the
authorized discard lifecycle below; do not delete a submitted Expense or shared
evidence as a side effect. Failure must preserve the draft and show a retryable
error. Existing discard APIs alone do not establish that this UI is usable.

The current UI Lab implementation establishes Document Intake ownership before
OCR or Materials proposals are introduced:

- `StoredReceiptDraft` owns a stable draft ID, organization, uploader employee,
  business date, optional Job identity/label snapshot, lifecycle revision,
  active/submitted/discarded state, submitted Expense identity, and append-only
  mutation audit events.
- Each retained photo or PDF owns a stable evidence ID, original filename,
  private local path, SHA-256 digest, byte length, order, and active/removed
  state. Removing it from the current review retains its source file and a UTC
  removal time for audit.
- `FileReceiptDraftRepository` copies source files beneath private Application
  Support/app data, verifies the copied checksum, and commits records through a
  serialized checksummed two-generation snapshot. It never uses Documents.
- `AuthorizedReceiptDraftService` enforces organization and separate read,
  create, own/team edit, own/team submit, and own/team discard capabilities at
  the query/action boundary.
- `ReceiptDraftUiController` owns the one authorized session used by the
  Expense landing summary, draft list, and intake route. Those screens filter
  on stable employee IDs and open an exact stable draft ID rather than matching
  display text.
- Camera, existing-photo, and file/PDF selections are retained immediately as
  a draft. Removal is likewise persisted. If persistence fails, the person's
  current unsaved selection stays visible and the prior safe draft remains the
  repository truth.
- `ReceiptEvidenceReviewScreen` previews the exact retained local image or PDF,
  identifies every item by its original filename and position, and provides
  labeled Earlier, Later, and Remove controls with an Undo path. Image and PDF
  previews support inspection without copying, exporting, or changing the
  original evidence.
- Saving review order persists the ordered stable evidence IDs through the
  authorized draft command and survives restart. If the save fails, the
  reviewed order remains visible as unsaved work while the last safe repository
  record remains authoritative. Two active selections with identical bytes
  remain separate reviewable evidence; a previously removed identical source
  may reactivate its original retained evidence identity.
- A confirmed Expense resolves its stable receipt ID through the authorized
  Expense projection, then reads the submitted draft with `includeClosed` at
  the authorized Document Intake boundary. The viewer verifies the draft is
  submitted to that exact Expense before exposing filenames or files. It never
  falls through to prototype/demo records when an authorized Expense scope is
  present.
- The confirmed Expense evidence viewer is read-only, renders the real retained
  local image/PDF, and reflows from stacked phone layout to two bounded desktop
  lanes. Receipt items, totals, and their permission-checked edit path remain
  inline on Expense details rather than being duplicated into the evidence
  reader.
- A receipt-backed Expense exposes **Correct receipt**, not a destructive
  replacement action. Any changed vendor, category, amount, date, Job link, or
  reviewed line requires a plain-language correction reason. The repository
  appends the previous confirmed business values to the same stable Expense's
  revision history and retains the exact receipt link.
- If company policy controls approval, saving corrected business values writes
  the new revision as pending even when the prior revision was approved. The
  earlier approval remains on the retained prior revision; it cannot continue
  authorizing changed totals. Actor, UTC time, permission revision, action, and
  correction reason remain in the mutation audit trail.
- `ReceiptDraftSubmissionCoordinator` writes a deterministic receipt-backed
  Expense first and closes the draft second. A retry after an interrupted close
  validates and reuses that Expense, so one receipt cannot silently create two
  business costs.

This checkpoint does not claim long-receipt stitching, Receipt Assistant
recognition, parser proposals, allocation, proposal-provenance correction,
export, backup, or sync. Those remain separate bounded slices built on these
identities and permission boundaries. Confirmed manual-value correction,
preview, and manual evidence ordering are implemented for retained image/PDF
evidence; owner rendered acceptance remains separate.

## 3. Entry points

### Expense intake

The labeled Expense actions remain:

1. Record an expense;
2. Record fuel;
3. Add a receipt for review.

Add receipt offers Camera, Existing photos, and File/PDF. After evidence review,
the user may create or update one Expense-owned purchase and may allocate its
confirmed lines to jobs, cost history, or stock.

### Active job

Every active job exposes one permission-aware **Job actions** directory. On a
compact screen it is a labeled FAB that opens a full-screen route. On a wide
screen the same actions may appear in a bounded panel. The material-specific
action is **Add materials**, and it opens only the source choices that can
create or revise an actual material addition:

- Add a material manually;
- Use confirmed material-cost history;
- Choose one exact reviewed material line from a recorded Expense;
- Use material from confirmed truck stock.

Labor/time, equipment, fees, and change orders are separately named workflows;
they are not disguised as materials or exposed through this route.

Linking a recorded expense, capturing a new receipt, adding a job photo, and
editing a job note remain sibling Job actions rather than item sources. This
keeps internal expense evidence, customer pricing, photos, and notes from being
silently converted into one another.

Choosing an Expense as a material source is a two-step review: first choose an
authorized Expense that currently counts as a recorded business cost, then
choose one reviewed material line. The proposal copies that line's description,
quantity, unit, internal unit cost, and stable Expense and Expense-line IDs. It
never copies the whole receipt total or constructs a receipt ID from
receipt-status text. A basic or unitemized Expense explains that no reviewed
material lines are available; the user may return and link it to the Job record
without creating a material or customer charge.

Before saving a material addition, the form requires one explicit treatment:

- **Use on job — do not bill customer** records actual usage and authorized
  internal cost with a zero customer charge;
- **Add to invoice later** creates an invoice-review candidate without changing
  the accepted estimate;
- **Customer approval required** records a proposed change that cannot flow to
  an invoice before the separate approval workflow succeeds.

The options themselves are permission-derived. A technician may record
non-billable usage without seeing cost or customer pricing. Existing billable
or approval-required additions remain protected when that technician later
opens the material editor; saving another permitted material cannot delete or
rewrite the protected records.

In UI Lab, **Add receipt** from a Job opens this same receipt-intake route with
the exact Work-owned Job ID and a readable Job label. Confirming the receipt
creates one Expense-owned record, preserves that Job ID on the Expense and its
reviewed lines, and links the resulting Expense ID back to the Job. It never
creates a Job-owned copy of the purchase or a placeholder attachment.

Job photos remain a separate device-media workflow. A photo is not displayed as
attached until the camera/library adapter returns a durable device reference and
the Job link is saved. Release-one policy may save Job photos to the user's
device and allow the user's chosen photo manager to handle backup; that does not
silently upload the image to Maintainiac storage. UI Lab must report an
unconnected adapter honestly instead of manufacturing a filename or success
state.

The action directory preserves the active job. The user must never select the
job again after entering from that job.

### Estimate items

Estimate Items provides Add line item, Add from materials, and Link receipt or
expense. Cost evidence pre-fills internal cost only. The user reviews quantity,
unit, customer description, customer price, markup policy, and tax treatment.
No customer-facing charge is created merely by selecting evidence.

### Inventory and material cost

Inventory accepts a confirmed receipt line as cost history and optionally as a
stock receipt. Those are separate decisions. A company can use cost history
without claiming to maintain exact truck counts.

## 4. Capture and long-receipt contract

1. Preserve source photos/files unchanged through processing and preview;
   permanent original retention is not required by the owner's new backup rule.
   Disposal timing is unresolved; no automatic deletion follows from this text.
2. Record capture/import order, orientation, dimensions, file type, and checksum.
3. Long-receipt capture may use overlapping photos in top-to-bottom order.
4. Stitching creates derived review evidence. Do not overwrite sources while
   processing; the reviewed backup derivative follows the size contract above.
5. Show overlap, missing-section, duplicate-section, blur, glare, and crop
   warnings before extraction is confirmed.
6. Permit reorder, rotate, replace, add, and remove before final review.
7. Detect likely duplicate imports, but let the user inspect before discarding.
8. The recognition engine retains raw recognized text and the image region
   behind every Receipt Assistant proposal.
9. Offline capture and review remain available. Sync happens later if enabled.

Owner decision, September 14: leave the 5.7 long-receipt stitching engine behind.
Build its replacement independently; do not copy the rejected preview/camera
layout. Reuse suitable platform capture/recognition capabilities after assessment,
not the legacy stitching implementation. Original ordered photos remain usable
when stitching cannot establish a reliable overlap. Missing/duplicated sections,
order and text legibility require independent image-based acceptance.

Use existing native camera/picker capabilities. Ask for required OS permissions
at the relevant action, explain denied/limited access, and preserve manual entry.
System photo pickers grant selected-image access without a broad gallery prompt;
do not fabricate a permission dialog or request broader access than necessary.
Android camera-app capture and an embedded CameraX viewfinder are different
integration options; the latter is only needed for an in-app camera interface.

## 5. Receipt-level proposal

The parser proposes, when visible:

- merchant name, address, phone, and store number;
- transaction date/time and receipt/register/transaction identifiers;
- subtotal, discounts, coupons, tax, fees, deposits, tips, and total;
- currency and payment hint without storing prohibited full payment credentials;
- count of printed candidate rows;
- count of logical purchase lines after merge/split review;
- reconciliation difference between line totals and receipt totals;
- confidence and source region for every field;
- parser/version information and any warnings.

Printed row count and logical item count are not assumed to be equal. One item
may wrap across printed rows; a discount may occupy its own row; one printed row
may contain quantity, description, and price that must be separated during
review.

## 6. Receipt-line proposal

Each proposed logical line retains:

- stable receipt-line identity and original order;
- raw recognized text and source-image region;
- merchant description exactly as printed;
- cleaned display description proposed for the user;
- merchant SKU, UPC, model, or part number when visible;
- proposed catalog material identity and matching aliases;
- category and trade suggestion;
- purchase quantity shown on the receipt;
- receipt unit, such as each, box, pack, roll, foot, pound, or gallon;
- number of packages purchased;
- contained pieces per package when known;
- package size or measure, such as 100 feet, 5 pounds, or 1 gallon;
- total contained pieces or measure derived from confirmed package facts;
- price per purchased package/unit;
- extended line total;
- line discount, coupon, tax, fee, deposit, or return treatment;
- derived cost per contained piece or measure when the divisor is confirmed;
- confidence for description, quantity, package facts, and money separately;
- review state: proposed, corrected, excluded, confirmed, or conflict;
- allocations and remaining unassigned quantity/value.

The displayed measurement preference is **U.S.** or **Metric**, never
customer-facing `Imperial`. Receipt evidence retains the original printed unit
even when the current user views a safe conversion. Volume packages cover fluid
ounces, quarts, gallons, milliliters, and liters; length covers inches, feet,
yards, millimeters, centimeters, and meters; mass covers ounces, pounds, grams,
and kilograms. Count packages cover each, pair, pack, box, case, bag, bucket,
roll, spool, tube, cartridge, and a user-confirmed other style. The complete
cross-cutting contract is `localization_measurement_blueprint.md`.

Package details frequently do not appear on a receipt. If the parser cannot
prove that a box contains 10 fittings or a carton contains 20 receptacles, the
field remains **Needs confirmation**. It must not divide the package price by an
invented count.

### Package examples

If a receipt confirms two boxes, ten fittings per box, and a $30 line total:

- packages purchased = 2;
- pieces per package = 10;
- total pieces = 20;
- cost per package = $15;
- cost per piece = $1.50.

If only `2 BOX FITTINGS $30.00` is visible, packages and total are known, but
pieces per box and per-piece cost remain unconfirmed until the user chooses a
known package variant or enters the count.

Measured products retain both package and usable measure. A 100-foot wire roll
costing $80 has an $80 package cost and an $0.80-per-foot confirmed cost only
after the 100-foot package size is confirmed.

## 7. Human review screen

The review screen shows original evidence and proposed values together. On
phones the evidence and fields may switch between clearly labeled views. On
wide screens they can be side by side within readable bounded widths.

The user can:

- correct receipt header fields;
- merge wrapped rows into one logical item;
- split incorrectly combined rows;
- exclude totals, advertisements, payment lines, and non-purchase text;
- choose or create a catalog match;
- confirm or correct package quantity, contained count, and unit of measure;
- correct price, discount, tax, and return treatment;
- assign all or part of a line to one or more destinations;
- leave unresolved lines unassigned without losing them;
- see why totals do not reconcile before confirming.

Low-confidence fields are noticeable but not alarming. The screen explains the
specific uncertainty instead of showing only a generic warning.

### UI Lab manual-entry candidate

Status: prior candidate rejected by the owner September 14. Rebuild the Expense
entry/review presentation; existing durable recovery must survive the redesign.

The manual path is one complete form, not a reduced fallback. Its phone order
is receipt date and vendor, expense category and optional related job, the
plain-language receipt-detail choice, searchable receipt items, receipt totals,
the explicit Materials follow-up choice, then Save. The form uses a bounded
working lane. Vendor/date, category/job, price/unit, quantity/package facts,
and subtotal/tax share the foundation's text-scaling-aware two-field reflow
rule: they sit side by side when both remain usable and stack otherwise.

The owner rejected **Save the receipt total**, **Review every item on the
receipt**, and the generic **Use for materials** explanation as misleading
choices. Review is required for all confirmed facts. Preserve Basic/Detailed
capability using an optional item list and explicit **Add item** action, not an
implied choice to skip reviewing the receipt. Save says what record is saved.

Do not enclose the whole form inside one decorated parent container. Use
full available bounded width with separate meaningful sections, shared spacing,
legible controls, and the application's richer blue-gray/meaning-based colors.
No white/pale nested-card replacement or private color system. Refer to the
Dashboard's accepted shared hierarchy without copying dashboard content.

Related work must offer actual searchable selectors for an existing **Job**,
**Estimate**, or **Invoice**, with stable IDs and authorization. Linking an
Expense does not rewrite an accepted Estimate or issued Invoice or add a second
purchase. Cross-record billing/stock effects require their owner's explicit
confirmation. The other Work model owns those destination workflows.

**Add expense** must open an understandable new-expense route, not Fuel or an
unnamed draft popup. Provide a separate visible unfinished-expenses route with
useful vendor/date/amount titles. Preserve recovery and explicit resume/discard
without silently resuming or deleting an unrelated draft. Optional Category,
receipt images, **Add item**, totals, related work and final review must be
discoverable. Daily totals must show date/scope/currency and drill into the
included confirmed records; exclude drafts and avoid mixed-currency sums.

The item section says **Tap any item to review or change it**. Every item is an
individual bordered control with an explicit Edit action and a separate Remove
action. Tapping the row or Edit pushes the full-screen item form. The form
captures description as printed, optional part/SKU/model number, expense
category, purchase quantity, sold-as unit, price for one purchased unit, and
contained pieces for pack/package/box units. Confirmed package facts show the
derived total contained pieces and cost per piece; an unknown package count is
never invented.

The local Expense domain now has a separate confirmed-itemization record for
these manually reviewed facts. It stores stable line IDs, exact package
quantity, package style, optional confirmed contained quantity and unit, exact
money, subtotal, tax, and the line-to-subtotal reconciliation difference. It
does not store images, recognized text, source regions, confidence, or parser
proposals; those remain Document Intake responsibilities. The accepted screen
is not yet bound to this repository because every authorized read, total,
detail, and mutation must switch together rather than creating two competing
sources of truth.

Both the manual form and saved detailed receipt provide an always-labeled item
search. It matches description, part number, category, and related job. Results
render 25 at a time with an explicit Show more action so a receipt with hundreds
of logical lines does not create one unbounded first frame. Vendor-wide and
cross-receipt search remains an Expenses filing/search responsibility rather
than pretending one receipt's item search covers the company ledger.

Receipt totals appear after items in receipt order: subtotal, sales tax, then
final amount paid. The saved detail keeps the original receipt evidence inline,
centers vendor/date as document orientation, retains editable item controls, and
keeps the totals at the bottom. A later reconciliation state must explain any
difference between reviewed item totals, receipt subtotal, tax, and final total
before confirmation.

The follow-up choice is **Keep them with this expense** or **Prepare the items
for Materials review**. Preparing review records intent and confirmed cost
evidence only. It does not change an inventory count, truck stock, job charge,
estimate, invoice, or customer price. Those effects require their own later
authorized confirmation summary.

### Shared document platform boundary

The future centralized document platform has two distinct presentations behind
shared file, permission, audit, export, and offline contracts:

1. an Expense evidence reader for imported receipt images and PDF files,
   including page navigation, zoom, readable preview, original-file retention,
   and access from the reviewed receipt fields and lines. The read-only
   retained-file viewer and exact submitted-Expense link are implemented in UI
   Lab; the reviewed fields and lines remain on the Expense detail document;
2. an Estimate/Invoice document renderer and viewer for versioned customer PDFs
   and templates.

Receipt evidence is not forced into the estimate/invoice document schema, and
estimate/invoice generation does not own receipt parsing. They share secure
document infrastructure without becoming one undifferentiated engine.

## 8. Line allocation

A receipt may cover one job, several jobs, truck restock, business use, or a
mixture. Every line supports quantity-aware allocation to:

- a specific job as actual material/cost;
- a specific estimate as internal cost evidence only;
- a selected vehicle or storage location as stock received;
- Inventory cost history without a stock claim;
- expense-only business use;
- unassigned for later review.

Allocation rules:

1. The user selects actual lines and quantities; the app never evenly splits a
   multi-job receipt by guess.
2. Confirmed allocated quantity cannot exceed confirmed purchased quantity.
3. Allocations may be corrected later with an audit entry; history is retained.
4. The UI always displays assigned, remaining, and conflicting amounts.
5. A whole-receipt shortcut is allowed for a single job, but the user reviews
   the included lines before confirmation.
6. Returns and negative lines reverse the appropriate cost/stock allocation
   through a visible correction, not silent deletion.
7. Tax and receipt-level discounts use an explicit company allocation policy or
   remain receipt-level; the parser does not invent a distribution.

## 9. Confirmation effects

Before saving, show a plain-language summary of every resulting change. Example:

> Add 2 supply lines from Transit 12 to JOB-1038. Internal job cost: $31.40.
> Customer charge: $54.00. Truck stock changes from 6 to 4. No new expense is
> created.

The summary must separately state whether confirmation will:

- create or update an expense;
- retain/link receipt evidence;
- add internal job cost;
- add a billable job adjustment;
- propose a customer change order;
- update verified material cost history;
- increase or decrease a named stock location;
- leave any quantity or value unassigned.

Cancel leaves source evidence and proposals intact but applies none of those
effects. Partial failures do not leave half-applied financial or stock changes.

## 10. Estimate, job, and invoice behavior

- The accepted estimate stays an immutable quoted baseline.
- Editing a signed estimate creates a new approval-required revision. Any
  customer-visible item or price change invalidates the current signature; the
  prior signature is retained only with the superseded revision for audit.
- Actual material used during the job is recorded separately from estimated
  material required.
- A field addition is explicitly non-billable use, billable adjustment, or
  proposed change order according to permission and company policy.
- Using truck stock never silently changes the accepted estimate.
- Linking an expense never automatically creates an invoice line.
- Invoice preparation includes quoted/planned items and can offer explicit
  invoice candidates. It excludes non-billable usage and proposed changes that
  still require customer approval; an authorized user decides what is invoiced.
- Unused/returned material creates a usage correction or stock return without
  rewriting the historical purchase.

## 11. Permissions and approvals

Permissions remain separate for:

- viewing receipt images and expense details;
- viewing private company cost;
- linking an existing expense to a job;
- capturing and submitting a new receipt;
- correcting Receipt Assistant proposals;
- allocating receipt lines across jobs;
- consuming or receiving truck stock;
- adding internal job cost;
- setting markup/customer price;
- adding a billable adjustment or change order;
- confirming another employee's submission;
- correcting or reversing a confirmed allocation.

A technician may be allowed to use truck material without seeing its private
cost or markup. The UI shows only authorized fields and never reveals hidden
values through totals, exports, notifications, or error messages.

## 12. Catalog and core package strategy

Owner clarification, September 14, 2026: electrical, plumbing, and HVAC core
packages ship with the application and remain usable locally without cloud
setup. These bundled definitions do not create owned stock or purchase costs.
Optional later downloads remain governed by D33. Other trades and custom items
remain supported; the three launch packs are not a restriction on who can use
inventory. The authorized Hive-to-SQLite inventory/parsing transfer and its
observed gaps are tracked in [the extraction checkpoint](inventory_migration/README.md).

The built-in catalog is not one enormous mandatory inventory. It has layers:

1. **Cross-trade core:** common consumables, fasteners, safety supplies, cleanup,
   sealants, tape, batteries, and frequently used general materials.
2. **Trade core packs:** plumbing, electrical, HVAC, lawn/landscape, cleaning,
   handyman/general repair, and later validated service trades.
3. **Company catalog:** items, aliases, package variants, and preferred vendors
   learned and confirmed by that company.
4. **Custom item:** immediate manual entry when no catalog match exists.

Every catalog item can define trade/category, manufacturer/model aliases,
merchant descriptions, purchase units, usable units, package variants,
conversion facts, regional availability, and locale/measurement labels.

Covering roughly 75% of common service-vehicle items is a product target, not an
unverified claim. A professional catalog pass must validate coverage using real
vehicle stock lists and representative receipts from the intended trades and
regions. Coverage is measured by frequently carried item families and receipt
match rate, not by shipping thousands of rarely used names.

The core remains usable offline. Optional trade packs may be downloaded and
updated, but updates do not overwrite company-confirmed aliases, package facts,
cost history, or custom items.

## 13. Offline, sync, and conflict behavior

- Capture, manual review, allocation drafting, and local confirmation work
  offline under local permissions.
- Original evidence and confirmed records use durable local identities before
  synchronization.
- Sync retries are visible and do not duplicate expenses, receipt lines,
  allocations, or stock movements.
- If two people allocate the same remaining quantity, the later sync produces a
  conflict requiring review rather than negative stock or double job cost.
- Parser/model upgrades never rewrite prior confirmed data. Reprocessing creates
  a new proposal version beside the confirmed version.

## 14. Audit record

Retain who, when, device/local record identity, original value, proposed value,
confirmed value, source receipt region, parser version, allocation destination,
quantity, cost basis, billable decision, stock effect, approval, correction,
and reversal reason as applicable.

Deleting a source photo after retention rules permit it must not erase the fact
that a financial, job, or stock decision was based on that evidence. Material
deletion, retention, and privacy policies require owner-controlled settings.

## 15. Required states and edge cases

Design and test:

- no receipt evidence;
- unreadable/blurred/glare-heavy image;
- missing middle of a long receipt;
- duplicate or out-of-order photos;
- receipt total without readable lines;
- readable lines that do not reconcile to subtotal/total;
- package count unknown;
- fractional measured quantity;
- discounts, coupons, tax, deposits, returns, and negative lines;
- one line split by quantity across several jobs;
- one receipt containing several packages of the same item;
- receipt already linked or partially allocated;
- expense without receipt evidence;
- item absent from the catalog;
- conflicting catalog/package matches;
- employee lacks cost, stock, billing, or approval permission;
- offline confirmation and later sync conflict;
- currency, decimal, metric/US customary, language, and locale differences.

## 16. Acceptance tests for the parsing handoff

The parsing implementation is not complete until tests prove:

1. originals remain unchanged and ordered;
2. raw printed rows and reviewed logical lines are both retained;
3. recognition confidence and source regions survive correction;
4. package math occurs only from confirmed facts;
5. per-piece/per-measure cost is decimal-safe and reproducible;
6. line allocations cannot exceed confirmed quantities;
7. multi-job allocation never uses an automatic even split;
8. selecting an existing expense does not create a duplicate expense;
9. consuming truck stock does not create a duplicate purchase expense;
10. estimate evidence does not consume stock or create customer billing;
11. job additions do not rewrite the accepted estimate;
12. invoices receive only confirmed authorized billable lines;
13. cancellation applies no financial, job, or stock effect;
14. retry/sync does not duplicate records or movements;
15. denied users cannot infer restricted cost or receipt information;
16. correction and reversal preserve complete history;
17. phone, tablet, and resizable desktop review layouts remain readable;
18. accessibility scaling, keyboard, screen reader, and touch targets work;
19. English/Spanish expansion and US/metric units do not truncate meaning;
20. every displayed total reconciles or clearly explains the difference;
21. Ask every time, explicit opt-in, and Off preferences are honored;
22. the manual path remains complete when Receipt Assistant is off;
23. every proposed line and field can be edited before confirmation;
24. confirmed lines can be corrected later without losing prior history;
25. customer-facing UI never requires the term `OCR` to understand the flow.
26. Job receipt intake retains the exact Job ID and links the resulting Expense
    without duplicating either record;
27. cancelling or failing Job-photo capture creates no attachment or success
    state.
28. selected photo/PDF evidence is copied into private app storage and survives
    restart with the same draft and evidence identities;
29. evidence removal preserves the source file, removal time, and audit history;
30. a denied draft query or direct route exposes no draft metadata or evidence;
31. landing summary, draft list, and intake resolve the same authorized stable
    draft ID and employee ID rather than a display-name match;
32. a failed draft/evidence snapshot retains the prior safe UI and disk record;
33. an interrupted Expense-save/draft-close sequence can be retried and yields
    exactly one linked Expense and one submitted closed draft;
34. active queries omit submitted/discarded drafts while authorized audit
    queries retain their lifecycle and evidence.
35. image and PDF evidence open in a real local preview without altering or
    exporting the retained source;
36. labeled order controls persist the exact stable-ID order through restart;
37. a denied direct evidence-review route exposes no filenames or previews;
38. narrow 320-LP layout at 2x text scale reflows the review controls without
    hidden primary labels or layout exceptions; and
39. two active same-content selections remain separate reviewable items while
    a removed identical source can recover its original retained identity.
40. a confirmed Expense can reopen the exact submitted draft and render every
    retained image/PDF without reactivating it in the draft list;
41. a missing, unauthorized, or mismatched Expense-to-draft link exposes no
    evidence filename, preview, or prototype fallback; and
42. the confirmed evidence reader stacks on phone and uses two bounded lanes
    when local width permits without changing its record ownership;
43. correcting confirmed receipt-backed business values requires a nonblank
    reason and retains the exact original receipt link;
44. every successful correction retains the previous confirmed values,
    previous approval evidence, actor, UTC time, permission revision, and reason
    through repository restart; and
45. a policy-controlled correction becomes pending and cannot remain in
    approved totals, even when the correcting employee lacks approval power.

## 17. Implementation boundary for another model

Before changing 5.7 Active, the assigned parsing model must inventory the
existing camera, long-receipt stitching, OCR, expense, inventory, job, storage,
permission, and sync implementations read-only. It must identify which source
can be safely reused, which behavior conflicts, and which tests already protect
it. This blueprint defines the product contract; it does not authorize deleting
or replacing existing 5.7 code without a separate evidence-backed plan.
