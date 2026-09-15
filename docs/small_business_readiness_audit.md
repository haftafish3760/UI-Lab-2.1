# Small-business application readiness audit — September 14, 2026

This is an implementation inventory and delivery plan, not a replacement product
blueprint or a release certification. Current source was inspected across the
shell, startup, Dashboard, Work, directory, Expenses, receipt intake, Materials,
shared documents and persistence boundaries. Owning requirements remain indexed
in [README](README.md). Previous SQLite/platform test evidence is explicitly
historical; it has not all been rerun against this dirty working tree.

## What the owner can review now

Dashboard → Admin → Company Overview now uses the same daily Plan, Entries and
bounded calendar composition as Technician. Wide layouts use the same supporting
calendar lane. Company action/billing/monthly review follows the daily sections;
it no longer replaces them with a different dashboard. Employee monthly review
uses the same whole-card headings. Technician's daily layout remains the reference.

The preceding Work change added People and activity to saved Estimate, Invoice
and Job details, distinguishing creator, current assignment and actual saved
edits. PDF export attempts have explicit outcomes; handoff is not customer delivery.

## Immediate findings

1. **Release blocker — identity and permission binding.** Startup still opens a
   development company/actor with hard-coded creator grants. The shell lists all
   modules, Dashboard Day uses development permissions, and the view selector is
   not authentication. Employee profile access choices are saved but are not an
   authoritative active-account policy. Source: `work_ui_lab_bootstrap.dart`,
   `operational_scope.dart`, `app_shell.dart`, `dashboard_day_screen.dart`,
   `employee_editor_screen.dart`. Existing domain authorization is useful but
   cannot make an unrestricted development session a secure employee account.
2. **User-reported defect — Windows invoice sharing.** Owner reports Send/Share
   does not permit sharing an unpaid invoice. The code reaches Work validation,
   PDF generation, audit persistence and SharePlus; this inspection does not
   establish which stage fails on that computer. Reproduce on a saved invoice,
   retain the actual error, and verify a real attachment before claiming fixed.
3. **Quotes are not an independent durable document type.**
   `WorkRecordKind` currently contains estimate, job and invoice. A Quotes
   destination is not proof of independent creation, history, issue and sharing.
4. **Historical PDF integrity remains incomplete.** `work_pdf_delivery.dart`
   constructs documents from current company/customer data. Shared rendering
   exists; issuance snapshots and retained exact issued artifacts need integration.
5. **Company figures have limits.** Monthly recorded spending/collections and
   invoice balances exist; complete profit and per-employee contribution do not.
   Do not label missing labor/shared costs as zero or collections as profit.

## Screen and workflow coverage

“Present” below means code exists, not owner visual acceptance or complete native
runtime verification. Every row needs the acceptance checks in the next section.

| Area | Present / source | Remaining delivery work |
| --- | --- | --- |
| Startup and company setup | SQLite startup, company/directory sessions; `open_ui_lab_application.dart` | Separate review fixtures from real first-run company creation. No sample balances, odometers or employees may silently become real operational facts. Handle open/upgrade/disk failures without reset. |
| Module access and employee identity | Domain permission objects; saved employee profiles | Authoritative active employee/company, allowed modules, own/team/company scope, revocation and route/query/export checks. Keep view choice separate from authority. Offline account behavior and later cloud identity must share one policy. |
| Technician Dashboard | Daily plan/entries, workday actions, job arrival route | Permission-gated entry; verify source record taps, arrival/pause/return/finish across restart, no duplicated plan/actual events, no inaccessible counts. Preserve accepted visual structure. |
| Admin Dashboard | Shared daily layout in this change; action queues, financial source links | Bind real grants, replace remaining demo employee selectors, correct scope attribution, consistent dates/currency, explicit overdue/unpaid totals. Verify all cards open exact authorized records. |
| Calendars and day review | Dashboard and module calendars, separate day routes | Complete dated feeds for estimates, quotes, invoices, payments, jobs, expenses, inventory and maintenance; source identity/deduplication. Distinct authorized company/employee day review. Calendar preferences must implement behavior, not just switches. |
| Employees and vehicles | Editors, directory persistence and assignment identifiers | Active/inactive/archived employees; historical identity; permission changes; vehicle ownership/availability; removal while assigned; no new work assigned to unavailable profiles. Confirm actual profiles drive every selector. |
| Customers and sites | Customer forms, details, linked Work | Compact consistent form; distinguish customer notes from site access only where useful; complete chronological jobs/documents/payment history, multiple sites and duplicate/merge policy. No customer-name matching as durable linkage. |
| Estimates | Editor, draft recovery/deletion, items, signature, approval/delivery and job conversion services | Native end-to-end create/autosave/reopen/edit/delete/preview/share; proposed date/time, company review policy, revisions invalidating old acceptance, visible finalization and delivery controls. |
| Quotes | Destination exists; no independent Work kind | Implement fixed-price proposal semantics and separate persisted lifecycle using shared editor/document primitives. Do not silently call an estimate a quote. |
| Jobs and scheduling | Direct jobs, estimate conversion, multi-employee assignment, Job calendar | End-to-end conversion and original linkage; duration/time windows, conflicts, crew availability, reassignments with history, cancellation/return visits, repeat jobs and time off. Unknown availability must remain unknown. |
| Job execution and workday | Persistent workday/drafts; Job status/arrival | Arrive/pause/resume/finish and measured time per visit/person, corrections with actor history, non-biller completion handoff, end-day with unfinished jobs, midnight/timezone/odometer edge cases. |
| Invoices | Editor, issuance, linked payment actions, preview/share controls | Reproduce Windows sharing; direct/job-based invoices, partial billing, correction/void rules, due date, deposit/payment allocation, stale-editor handling, exact issued customer copy. |
| Payments and balances | Linked payment ledger and report sources | Partial/duplicate/overpayments, refunds/reversals, allocation mistakes, cash/check/external payment recording, actor/date history. Customer portal does not collect payments. |
| Shared PDF and templates | Feature-neutral engine, branding/logo resolver, source/view/export abstractions | Native preview/export/reopen and failure tests; invoice paid/balance content, portrait/landscape visual review, long text/tables/notes, currencies/fonts, missing logos, exact preview/send parity and issuance snapshots. No duplicate expense engine. |
| Customer portal | Client/gateway and local portal project exist | HOLD implementation pending owner direction. Browser-only secure view and approve/reject; no Stripe or payment collection. Before enabling: company/recipient isolation, expiry/revocation, accepted revision, retry and signature/approval evidence. No invented live links. |
| Expenses manual entry | Editor, category/payment/date/evidence fields, SQLite service, drafts | Review every create/edit/cancel/save/reopen/remove/restore path; consistent compact utility forms; refunds, missing category, allocations and clear permission-denied states. Recheck earlier receipt-save retry failures. |
| Receipt camera/import/review | Camera/photo/file picker, evidence selection, original-file preview and retention | Native denied/permanently-denied/cancel/return flows, multi-photo order/replacement/removal/zoom, missing files, duplicates, unreadable images and compression preview. Preserve originals and do not imply import success before durable save. OCR work is deferred. |
| Materials / Inventory | Catalog, costs, stock/count/location screens | Complete durable stock ledger, units/package conversion, transfers, corrections, reservation versus consumption, low stock, duplicate receipt import and restart safety. Catalog availability does not prove owned stock. |
| Expense → Job/document links | Expense/evidence and verified material-cost pickers | Stable IDs and reviewed selected lines; one original expense, explicit customer charge/markup, no automatic duplication or stock deduction. Ensure receipts can be opened later from both owners. |
| Maintenance / Repairs | Shell currently uses `ModuleHomeScreen.maintenance()` | This is still a module placeholder, not a complete maintenance application. Vehicle/item setup, intervals, prior service, reminders, service records and expense/evidence links need their own bounded delivery. |
| Reports / lightweight CRM | Source-backed financial reports and customer detail | Receivables aging, customer history, job costs and employee attribution; financial permission checks before totals; explain incomplete data. CSV/export parity and correction reconciliation require validation. |
| Settings / backup / restore | Preferences, saved-work recovery, lower-level verified restore infrastructure | Usable whole-installation backup/restore flow, choose/verify/confirm/retry, failed restore retains original. Optional Firebase identity/sync/backup is not connected; project setup alone will not complete it. |
| Notifications / approvals | Attention and notification infrastructure | Permission-scoped reminders, real actor approval policy, exact destination, read/dismiss versus resolve, retries and offline queues. No inference of delivery from opening another app. |
| Internationalization / accessibility | Shared layout engine, localization infrastructure | Audit remaining literal labels/USD assumptions, units/date/number formats, long names, 2x text, screen readers, keyboard/focus, touch targets and contrast across every form. |
| Release operations | Local transactions/revisions/outbox, existing extensive tests | Fresh full regression, upgrade/restore drills, device interruption tests, signed Android/iOS builds, Windows native actions, dependency/support review, redacted diagnostics and reviewed Git checkpoints. No claim of comprehensive certification from analyzer/build alone. |

## Delivery order: one complete flow at a time

Owner clarification: this is intended as a commercial Play Store application,
not a prototype release. Development presets and fixture references above identify
unfinished implementation that must be removed or isolated before release.

### Owner financial and reminder requirements still to implement

- Day/week/month/year selection for collected money, recorded spending, outstanding
  and overdue receivables. Show exact date range and full weekday/date for a day.
  Current overview remains month-based; the selector is not implemented here.
- Company revenue per labor-hour, profit per labor-hour and profit margin are
  separate measures. State the revenue basis, included costs and denominator.
  Two employees working one hour equals two labor-hours, not one. Zero/unknown
  hours or missing cost allocations must not produce a fabricated rate or margin.
- Employee pay rates with effective dates, authorized visibility, confirmed
  worked durations, reviewed corrections and immutable historical cost basis.
  This is internal business/labor cost tracking, not payroll tax calculation.
  Changing a current pay rate must not silently change old job profitability.
- Separate direct job costs from overhead; avoid counting one receipt both as
  a job expense and again as another company cost. Owner labor, refunds,
  discounts, shared purchases and nonbillable time need explicit treatment.
- Owner-adjustable reminder lead times, repeat interval and quiet periods in
  the owning screen's settings; durable preferences and notification rescheduling
  on due-date changes. Reminder lead time never makes a future obligation overdue.
- One primary job action queue, additional issues on Job details. Current
  priority is overdue, paused/return, unassigned, unscheduled, other active.
  Invoice collection state remains an invoice fact, not a duplicate Job record.
- Explicit cancelled/void Job lifecycle is absent from the current status enum.
  Add the state, correction history and projection exclusions in the lifecycle
  slice. Current queues exclude drafts/completed/non-job records using an explicit
  active-state allowlist; this is not a completed cancellation workflow.

These are delivery requirements, not completed functionality. Recordkeeping,
traceability and export controls need verification; no tax/audit compliance
certification is established by this implementation or this document.

1. **Dashboard parity and access foundation.** Finish owner review of this layout,
   then bind dashboard/shell/day/detail queries to actual employee/company grants.
   Prove no access via Admin switch, totals, deep links or stale open screens.
2. **Create Estimate → share → approved Job → assign crew.** First reproduce and
   repair desktop sharing. Complete the visible customer/document form, durable
   interruption recovery, actual PDF preview, outcome labels, scheduled conversion
   and assignment with tests against real SQLite. Portal is not a dependency.
3. **Arrive → work → finish → Invoice → record payment.** Keep completion separate
   from billing permission and external delivery, reconcile balances and history.
4. **Expense and receipt UI/UX.** Manual save first, then native capture/import,
   preview/reorder/compression, evidence reopen, correction and Job links. OCR later.
5. **Materials transactions and reviewed purchase links.** Finish quantities and
   units with atomic retry-safe accounting; connect Work using stable source IDs.
6. **Independent Quotes, customer histories and reporting gaps.** Reuse shared
   primitives while maintaining each application's own business definitions.
7. **Remaining module/release gates.** Maintenance, complete backups/restore,
   optional cloud and portal after owner setup, localization and native platform
   acceptance. Security and storage hardening accompany every earlier slice.

## Definition of done for each flow

- Visible entry and return destinations are understandable on phone and wide view.
- Correct employee/company can view and act; denied users cannot query/count/open
  or export the record. Permission changes during asynchronous work are rechecked.
- Save acknowledgments correspond to durable data; interruption, disk failure,
  cancelled native action, retries and concurrent edits do not lose or duplicate it.
- Creator, assignees and actual actors/times remain distinct. Changes do not rewrite
  historical acceptance, issued documents or unrelated module facts.
- Calendar/summary/detail agree on the same record IDs and money/date boundaries.
- Relevant automated tests, analyzer and platform build pass. Install and launch
  the final Android build on the connected S24 Ultra; report whether that succeeded.
- Owner reviews the actual layout. A green test does not substitute for acceptance.

## Evidence limits and follow-up audit

### Delivery feedback follow-up

Invoice actions now provide Save PDF copy beside Send invoice. Shared export
feedback distinguishes cancellation, platform failure, validation failure and
an unconfirmed result. Native share success is described as handoff, never proof
of customer receipt. The platform adapter remains downstream of authorization
and byte validation. A non-box render context no longer causes a cast failure
while finding the sharing anchor.

Five new boundary tests cover exact PDF bytes/name/MIME type, revoked permission
before handoff, invalid PDF input, cancelled/unconfirmed results and safe error
messages. Together with document-source, export-history and Invoice workspace
regressions, 31 tests passed; analyzer clean. This is a delivery-controls repair,
not proof that the owner's original Windows sharing-panel failure is resolved.
Active employee permission binding remains an open release blocker.
Windows debug build passed (37.6 seconds) and the rebuilt executable was launched.
Android debug build passed (91.9 seconds); ADB install succeeded on SM-S928U,
launch returned Status: ok and the application process was present. The pdfx
plugin reports a future Kotlin build compatibility warning; it did not prevent
this build. No native recipient delivery or owner visual acceptance is claimed.

This dashboard checkpoint: analyzer clean; 30 focused Dashboard/layout/job-queue
tests passed. Windows debug build passed (33.8 seconds); Android debug build
passed (33.0 seconds). ADB install returned Success on SM-S928U (S24 Ultra), and
launch returned Status: ok with a running app process. This confirms installation
and launch, not visual acceptance. The Windows binary was rebuilt; the already
running Windows review app was not restarted by this checkpoint.

The current audit identifies concrete blockers and maps all known screen families;
it cannot honestly guarantee every possible defect has been found. Native Windows
sharing reproduction, all-route permission attacks, the full current regression
suite, physical camera permission states, iOS runtime and power-loss recovery are
not completed by this pass. Old roadmap success statements must not override newer
failures. Track each reproduced issue with source, test, fix and verification.

Earlier detailed evidence: [SQLite audit](sqlite_remaining_work_audit.md),
[shared documents](shared_document_implementation_status.md),
[Expense/Inventory roadmap](expense_inventory_delivery_roadmap.md), and
[workflow delivery](workflow_delivery_roadmap.md). Those contain historical results
and remaining gates; this audit does not silently promote them to current passes.
