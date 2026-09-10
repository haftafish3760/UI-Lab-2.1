# Maintainiac — current owner blueprint

Reconciled 2026-09-09 from the owner conversation in UI-Lab-2.1.
This is the fresh current-direction entry point, indexed by `README.md`.
It supersedes conflicting earlier product directions, not compatible detailed
engineering requirements. Detailed owners remain linked below; do not create
parallel copies of their schemas or rules. Decisions are not implementation proof.

## 1. Product and destination — ACCEPTED

- Maintainiac is a local-first business-operations and recordkeeping application:
  Customers, Work, Quotes/Estimates, Jobs, Invoices, Payments, Expenses/Receipts,
  Inventory/Materials/trade packs, Trips, vehicles/equipment, Maintenance/Repairs,
  scheduling, notifications, and documents must connect through owning records.
- UI Lab 2.1 is the intended replacement/production codebase, not merely an
  interface to bolt onto 5.7 after completion. It is NOT production-ready today.
- 5.7 Active is protected, read-only capability and data-compatibility evidence.
  Preserve the substantial investment in durable storage, Hive data, OCR, GPS,
  receipt/inventory parsing, trade packs, par, device detection and QA harnesses.
  Reuse verified logic; do not transplant defects or rewrite useful systems just
  because a new database is selected. Passing old tests alone proves neither
  suitability nor completeness. No edits, builds, migration writes or cleanup in
  the protected original. Work on copies only under a bounded assignment.
- Release-one baseline is an owner-operated business. Helpers and multiple
  vehicles remain useful; selecting vehicles is not employee authorization.
  Multi-crew scheduling and employee permissions were discussed and reopened,
  but their release-one scope is UNRESOLVED; do not infer a full team launch.
  Gig-driver-specific product modes are outside the latest stated scope.
- Safety, enterprise-grade dependability, accuracy and recoverability take
  priority over speed. January/mid-2027 discussion is an aspiration, not a promise.
  Approximate 2017 device support is an aspiration requiring OS/capability tests.

## 2. Storage, identity, backup and sync — ACCEPTED

**SQLite with Drift** is the selected local database direction. SQLite is the
database; Drift is the Dart access/schema/query layer. Hive is a migration source,
not the new target. Installing packages is not completion of durable storage.

Release one MUST support the user's choice of:

| Mode | Local operation | Cloud synchronization | Recoverable cloud backups |
| --- | --- | --- | --- |
| Local only | Required, durable and fully usable offline | Off | Off |
| Sync without backup | Required; queue while offline | On by user choice | Off |
| Sync with backup | Required; queue while offline | On by user choice | On by user choice |

Sync is not backup: replicated edits/deletions cannot be the only recovery copy.
Backup-only without sync is not selected or excluded yet; ask before adding it.
The user controls how and when backup/sync happens. Offer backup choice during
onboarding and later in settings; **designing/implementing those screens is not
part of the current documentation pass**. Local-only users need no account,
except an account IS required if they choose to download an inventory trade pack.
This exception does not authorize an account wall for ordinary local workflows.
Whether previously downloaded packs require subsequent login is unresolved.
Cloud/provider identity and recovery must be designed explicitly, not guessed.

Firebase must use a brand-new project separate from 5.7. Owner also requested
separate billing; actual project/account creation and login remain incomplete.
No trial credit is guaranteed. Current Android/iOS app IDs must match their own
Firebase registrations; do not copy 5.7's `com.maintainiac` registrations unchanged.
`GoogleService-Info.plist` is distinct from the app's ordinary `Info.plist`.
Deployment of rules is separate from authoring rules. Do not deploy to 5.7 or
write synthetic data into an existing production project.

Owning engineering contract: `data_storage_sync_contract.md`. It must cover
transactions, stable IDs, money/quantity precision, foreign keys, revision checks,
idempotent commands, durable queues, schema migrations, recovery, authorization,
account transitions, restore and retention before connected workflows are called
finished. Database services own mutations; widgets do not open databases directly.

## 3. Cloud/media and commercial decisions — preserve uncertainty

- User-owned external job-photo storage with durable Job links is desired.
  Google Drive was discussed as a recovery source for both records and media
  indexes, avoiding a requirement to keep photo IDs only on Firebase. This is
  NOT a completed provider architecture. Google Photos/Apple provider feasibility
  and account/cross-device access require fresh validation before promises.
- Local save first; keep the only local evidence until confirmed remote integrity.
  Show pending, successful, failed and unavailable states truthfully. A link or
  queued upload is not a successful backup. New-device restore cannot depend on
  IDs or credentials surviving only on the lost phone.
- Owner stated free local use with bottom banner and appropriate inline video
  ads, NEVER interstitials; $2/month ad removal, $5/month cloud-backup plan with
  no ads. Owner subsequently discussed including 2 GB. These are commercial
  directions; quota/provider/cost/entitlement details and sync-only pricing need
  confirmation. Do not retain the older “only receipt backups can be paid” rule
  as the active complete plan. Do not hardcode unconfirmed billing products.
- Manual receipts remain available; receipt assistance is optional. Basic and
  Detailed receipts are required; Basic category is optional. Original-quality
  input supports optional text extraction. Proposed backup derivatives around
  1 MB/750 KB/500 KB/250 KB require a real readability preview. Source disposal,
  retention and long-receipt sizing remain unresolved. Long-receipt stitching
  needs independent repair-or-rebuild assessment. See receipt intake blueprint.

## 4. Record workflows, realistic data and corrections

ACCEPTED: all records must be findable and support appropriate editing/removal;
dated entries, customers, estimates, jobs, invoices and payments must agree.
Selected date must not be the sole means of finding outstanding business.
The owner requested a realistic fixed demo interval **2026-08-31–2026-09-13**.
Use varied believable customers, jobs, documents, expenses and payment timing;
repeat customers only where their business story warrants it. Do not clone three
customers across dates or regenerate history relative to today's clock.
Use stable related records, exact reconciled amounts and credible event order.
Generate test data through validated owning services, isolated from real records.
Keep fixture identity/version/reset explicit; never silently overwrite user edits.

PROPOSED, not yet accepted navigation: Estimates has Drafts/Awaiting customer/
Accepted/Closed/All; Invoices has Drafts/Unpaid/Overdue/Paid/All; Payments has a
searchable history linked to invoices/customers; customer detail shows related
records. Dated sections coexist with cross-date work lists. About 12 customers
was an engineering suggestion, not an owner-mandated count.

UNRESOLVED: deletion/restore periods and correction/void/reversal policy. Do not
interpret “delete everything” as permission to erase settled financial history
or cascade-delete payments. Preserve exact document revisions and explain
downstream effects. Owner has not yet answered the recoverable-delete proposal.
Work owns these lifecycles; Dashboard and Calendar are projections, not new stores.

## 5. Vehicles, mileage and scheduling

- No manual first vehicle setup required. Supply a usable context without calling
  it “Default vehicle”; never invent a real odometer reading. Multiple vehicles
  need stable separate IDs/profiles. Confirmed readings update app-wide for that
  vehicle, not every vehicle. Source dates/order and correction history matter.
- Header selection controls the viewed scope. Reopening the picker highlights
  ONLY the selected vehicle/company view in blue, not always company view.
- Start workday is optional and outside the header. It signals workday beginning;
  it does not automatically classify every mile as business or clock in helpers.
- Today's Entries appears when records exist for that date, even before Start;
  hide an empty Entries section rather than fabricate activity. Today's Plan is
  available before work begins when scheduled items exist.
- Higher/lower starting or ending odometer values need validation and a reviewed
  correction/discrepancy path. A gap is not automatically personal mileage; it
  might be omitted travel, wrong vehicle, units or a typo. Never create negative
  mileage or silently rewrite history. Historical averages may suggest unusual
  readings, not determine truth. Exact thresholds/replacement/rollover rules open.
- Business/personal separation is required direction; allocation mechanics remain
  to specify. No advertised IRS/audit-compliance certification. Preserve accurate
  records and correction evidence without presenting tax advice as product truth.
- Scheduling must be useful without AI, prevent/warn about conflicts using
  actual commitments and capacity, and improve recommendations from recorded
  history. Human confirmation owns scheduling changes. Exact policy remains open.

## 6. UI consistency and localization

- Shared layout/theme/widgets, accessibility scaling, full readable primary text,
  contextual settings and information-rich non-minimalist presentation are required.
- Single-column/600-LP statements were later revised for wider layouts. Do not
  resurrect an all-device 600-LP cap. Follow current AppLayoutEngine and the
  current working contract; responsive compositions remain owner-reviewable.
- Plan stays in its blue family and recorded Entries in green app-wide, including
  “Entries/Estimates/Invoices for this date” headings and bodies. Inner rows remain
  lighter. Shared primitives must allow future changes in one place. Gradients
  are now being explored; exact approved final palette is NOT settled.
- Pending approval/Needs attention use the same muted-orange attention treatment;
  Work must be distinct from Miles and must not return to rejected peach. Preserve
  labels/icons as well as colors for accessibility. Start Workday's accepted
  lighter green and the fixed status-bar background must not change incidentally.
- Five horizontal summary cards were requested, initially 96×120 LP at normal
  text size, with necessary accessible growth; Needs attention first. Do not
  change row sizes, spacing, or divider position during color-only changes.
- Current reference blue gradient was read from protected 5.7 menu source:
  `#1976B9` to `#0F4068`. Two full-height gradient trials were rejected as too flat.
  Their presence in code/tests is NOT owner visual approval.
- Never replace the normal phone app with a standalone preview entry point again.
  A comparison must preserve access to the normal app and its navigation.
- English/Spanish multilingual support AND regional language variants are mandatory;
  units, money, dates, documents, input/parsing and accessibility must follow suit.
  Exact supported locales and translations require confirmed coverage.

## 7. Current implementation evidence and limits

Verified in this task before this documentation pass: normal app rebuilt from
`lib/main.dart`, installed on S24 Ultra, Dashboard/navigation visibly restored.
Color/preview tests do not establish storage or complete workflow correctness.
Source inspection found file-based durable expense-related repositories, but
Work/financial prototype lists in memory and separately generated demo dates.
No Hive or Drift dependency/initialization was found in 2.1 at that inspection.
Firebase CLI 15.29.0 installed under `tooling/firebase`, version command succeeded;
login list reported no authorized accounts. No new Firebase project, rules
deployment or connected cloud backup/sync was established by this task.
Recheck these facts before the next implementation; another task may change them.

## 8. Collaboration and remaining work

Owner requires full contextual handoffs, visible separate sidebar tasks when
delegating, and no hidden-agent substitution. No sidebar task was created here;
the available tool search did not expose a task-creation tool. Owner will open
the next task with `storage_database_codex_handoff.md`.

Scope now: documentation only. Next storage task must assess existing systems,
map dependencies, propose bounded slices, and test throughout; no unsupported
time estimates. The owner reports over a month invested in inventory. Respect
that work without assuming migration takes the same time or a few hours.

This reconciliation records substantive product directions visible in this
conversation, not a claim to recover missing transcript details or certify every
legacy document. Older knowledge-upload files/review drafts are derived historical
artifacts and must not override this blueprint or be uploaded as current without
refresh. Owners of detailed mechanics: Product control, data/storage/sync, Work
lifecycle, receipt/material intake, scheduling, localization and UI foundation.
