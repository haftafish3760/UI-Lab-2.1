# Work repair checkpoint — September 14, 2026

This is a verified implementation checkpoint, not a declaration that the entire
application or shared document system is ready for release.

## Implemented in this repair

- Work keeps Plan and Entries in separate operational color families. Rows show
  the customer, work title, document number, status and time. Entries are ordered
  chronologically. Completed jobs are excluded from the Work home Plan group.
- Estimate and Invoice workspaces each have a prominent, filtered Drafts route.
  Drafts no longer appear in a second ordinary list. Recoverable input and its
  saved draft are grouped by record identity. Last-edited dates are visible.
- Returning to Work never automatically resumes an editor. Selecting a draft
  explicitly resumes it. Confirming Save opens document review with next actions.
- Estimate review exposes Edit, Items, Preview PDF, Send estimate, customer
  approval, Create and assign job, and permitted draft deletion. Invoice review
  exposes Edit, Preview PDF, Finalize, Send, payment recording and permitted
  draft deletion. These actions no longer sit behind a detail-screen floating
  button that covers content.
- A draft estimate can proceed directly into delivery preparation. Required
  customer/work/items are checked. Cancelling before confirmation preserves the
  draft. Preparing a share is not recorded as confirmed delivery.
- Client information comes first in Estimate and Invoice forms. Proposed service
  date/time is editable on estimates and included in their customer PDF.
- The company profile owns an optional approval-before-sending setting exposed
  through Estimate settings. Existing company-management permissions control it.
  New estimates inherit it; existing records retain their recorded policy.
- Scheduling has its own Job calendar and selected date, employee filter,
  scheduled jobs, jobs needing scheduling, New job, and screen-specific display
  settings. It reuses job records and the existing assignment/schedule editors.
- Existing job creation supports an approved estimate or a standalone job and
  persisted employee IDs, including multiple employees. Existing SQLite guards
  validate permission, current estimate revision, signature and employee status.
- Debug Work examples are replaced once with distinct customer names for draft,
  ready, approved, scheduled, completed and invoiced records. The invoice has a
  matching ledger entry. Other modules and other companies are preserved.
- The template gallery creates preview readers by visible rows instead of
  eagerly opening every template reader.

## Principal files

New components include `work_schedule_screen.dart`, `work_saved_document_route.dart`,
`work_drafts_screen.dart`, `estimate_primary_actions.dart`,
`invoice_primary_actions.dart`, `estimate_approval_settings.dart`, and the
Work-only `work_review_examples.dart` fixture replacement.

Existing Work landing, workspace, editor, recovery, detail and PDF composition
files were adapted. Company profile/codec and estimate delivery/confirmation
use the existing persistence and permissions systems. The owning Work and
Operations blueprints record the implementation boundary. Expenses, receipt OCR
and Inventory were not modified by this repair.

## Verification

- Analyzer: no issues in the final analysis run.
- Twenty Work navigation/layout tests pass, including explicit estimate-to-job
  navigation, delivery controls, wide forms, large accessibility text and
  multi-day jobs.
- Twenty-eight focused tests pass across Invoice workspace/issuance, Estimate
  recovery/company policy, Scheduling and employee assignment persistence.
- Both Work replacement tests pass: once-only persistence/ledger consistency
  and preservation of unrelated records and another company.
- Draft deletion tests cover restart, stale editors, permission denial, linked
  records, and an estimate whose legacy general status differs from its draft
  stage. Responsive form tests cover 320 and 1440 logical pixels at normal and
  doubled text size. Scheduling tests cover 320, 430 and 1280 logical pixels.
- All Work production Dart files remain at or below 500 lines.
- Android debug APK build passed (33.2 seconds); Windows debug build passed
  (34.1 seconds). Both include the latest Work changes. Android emits a pdfx
  future Kotlin compatibility warning; it does not fail this build.
- ADB currently lists no phone, so the latest APK has not been installed.
  The running Windows app has not been restarted: automatic approval review
  rejected closing the review app without explicit permission. An earlier
  launch is not proof that these latest changes are running on either device.

## Unfinished release work

### Additional employee activity and sharing audit repair

Estimate, Invoice and Job details now have a **People and activity** control.
It shows creator and current assigned employees separately from each saved
change's acting employee and date. It reads the existing SQLite revision chain,
verifies hashes/identity/order, and pages earlier history. Changes are described
in ordinary language without displaying hidden financial values. Names come from
the authorized current directory and stable IDs remain visible.

Work PDF sharing/saving/printing now writes an attempt before opening the native
action, then records completed, cancelled, unconfirmed or failed outcome. A
process interruption leaves an explicit unresolved attempt. Completed sharing
means another app reported a handoff, not confirmed customer delivery. Retries
of recording the same outcome do not duplicate the attempt. The shared PDF
exporter provides technical outcomes; Work owns this audit and authorization.

New files: `work_activity_reader.dart`, `work_export_audit.dart`,
`work_activity_screen.dart`, and two focused activity test files. Twenty-seven
combined history/audit/Invoice/Estimate regression tests passed; eight focused
history and real SQLite-backed screen tests passed, including 320/430/1440 logical
pixel widths with doubled text. Analyzer is clear. Employee sign-in, cross-device
identity and Quote integration are not completed by this change.

### Remaining work

- Quotes still need their independent record/workflow integration.
- Scheduling availability, overlapping commitments, crew capacity, skills,
  time off, travel allowances and cross-device dispatch are not implemented by
  the Job calendar. It makes no claim that a proposed slot is feasible.
- The optional customer portal has not been deployed or verified. Sharing uses
  native apps; supported recipients/attachments depend on the selected app, and
  opening a share sheet does not prove delivery.
- Immutable issuance snapshots/exact retained PDFs are architecturally supported
  but not yet integrated into Work issuance. Historical regeneration still uses
  live company/customer information. Landscape template composition, invoice
  paid/balance PDF details, native failure/reopen tests, accessibility/localization
  coverage and native gallery memory testing remain release gates.
- Midnight is currently the date-only proposed-time sentinel; explicit midnight
  and an unspecified time need separate representation before that edge case is
  considered complete.
- Receipt/evidence and inventory integration must be coordinated with the other
  active work; this repair does not claim those flows are finished.
- Automated layout tests do not establish owner visual acceptance.
