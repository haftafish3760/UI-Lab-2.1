# Tame Your Biz — Windows to Mac continuation

This is a combined development checkpoint of both models' pending work, not a
production release or owner acceptance. Preserve the existing Mac checkout and
any local work. Maintainiac 5.7 is protected read-only reference material.

## Start here

Read `docs/README.md`, the current product blueprint, decision register,
UI foundation, Product Control and the relevant screen blueprint. Screen-first
organization, shared primitives and at most 500 lines per production Dart file
remain the contract. Do not rebuild the technician Dashboard unnecessarily.

## Implemented source in this checkpoint

- Shared PDF mechanics under `lib/src/shared/documents`: fonts, page configuration,
  rendering, image/logo fallback, reusable viewing and export. Work compositions
  live under `lib/src/screens/work/documents`; company branding comes from the
  company directory. Uploaded evidence bypasses PDF generation.
- Work estimate/invoice section-based editors, draft recovery/deletion,
  scheduling, employee assignment and job-related screens have substantial changes.
  Existence of a handler does not prove every workflow is complete or accepted.
- Work activity and export audit record actual actors and persisted revisions.
  Export attempts distinguish cancelled, failed, completed and unconfirmed.
- Invoice actions include Send invoice and Save PDF copy; shared delivery feedback
  explains validation/platform failures and does not equate handoff with receipt.
  The owner questioned the separate Save PDF action; placement is not accepted.
- Admin Dashboard retains the Technician daily Plan/Entries/calendar layout.
  Company review and Job issue summaries exist, but the owner rejected the current
  Admin overview presentation and its vague queues. Do not call that UX finished.
- Other-model Expense, receipt and Inventory changes are included to preserve the
  combined workspace. Read `docs/expense_inventory_delivery_roadmap.md` and
  `docs/inventory_migration/` before changing that work. OCR is not certified.
- Customer portal source exists under `customer_portal/`. It has not been deployed
  by this task or certified secure/ready. No customer web payments are requested.
- PDF fixture output, template artwork/fonts, inventory catalog assets and tests
  accompany source. Installed npm/Pub caches and local personal attachments do not.

## Verified before transfer

- Latest delivery slice: 31 focused tests passed (PDF export boundary, document
  source, Work activity/export audit, Invoice workspace); analyzer clean.
- Windows debug build passed and executable launched. Android debug build passed,
  installed on SM-S928U (S24 Ultra), launch returned success and process existed.
- Earlier Dashboard slice: 30 focused layout/job-queue tests passed.
- These are bounded checks, not a fresh full-suite run or iOS/macOS validation.
- Android emitted a future Kotlin compatibility warning from pdfx. Investigate
  dependency support without blindly upgrading unrelated packages.
- Windows hot reload rejection was resolved by restarting the app; a new build
  alone does not replace a running process. Original native Windows share-panel
  failure has not been conclusively reproduced/fixed.

## Latest owner planning — NOT implemented

- Work one complete flow at a time. Make the mobile Admin selector compact.
- Hide Needs attention when empty. Mobile has a named container plus real count,
  opening a separate list with Back; each entry opens the exact business record
  for review, not an automatic edit or approval action.
- Latest proposal puts Urgent and Routine sections in that same list. It supersedes
  the preceding urgent-only/separate-area discussion, which remains in some
  blueprint prose and needs reconciliation before implementation. Hide empty
  sections and avoid duplicating one record for multiple issues.
- Urgency needs real, tested triggers and owner-configurable categories/thresholds
  in the alerts screen's gear settings. Proposed choices: Urgent, Routine or Off.
  Turning off alerts must never remove an approval requirement.
- Routine approvals may require all records, records above an amount, or none,
  independently by type; allow company defaults and employee-specific exceptions.
  Define reviewer authority, self-approval, amount/currency boundaries, changed
  records and changed policies, unavailable reviewers, retries and offline state.
- Android notification categories must let the device user choose sound/vibration.
  Respect system settings; iOS categories are not equivalent sound channels.
- Proposed Money container opens a full financial recap. Employee breakdown was
  raised then paused. Exact period defaults and metrics remain undecided. Never
  label collections or incomplete costs as actual profit.
- Estimate Edit must open the actual saved section-container form. Verify the
  concrete route and contents against the owner's expectation, not just code.

## Firebase and product name

Owner selected **Tame Your Biz**. Final Android package / Apple bundle identifier
selected: `com.tameyourbiz.app`. Current app identifiers still use UI Lab names;
no rename or Firebase initialization has been implemented in this checkpoint.

Owner chose to REUSE existing Firebase project `maintainiac-aafec` because its
billing setup works. Do not create a competing project or delete registrations.
Downloaded Android `google-services (3).json` and Apple
`GoogleService-Info (1).plist` were read and verified on Windows: both match this
project and identifier. They remain in Windows Downloads, not in app source or
Git. Earlier `google-services (2).json` had a misspelled package; do not use it.
Transfer/download the correct files separately when connecting on the Mac.

Firebase CLI and FlutterFire CLI were installed globally on Windows; they do not
transfer through Git. FlutterFire version reported 1.4.1. `firebase login:list`
reported no authorized CLI account. Browser sign-in does not authenticate the
CLI. `flutterfire configure` has NOT run. No Firebase rules were deployed, no
collections created, no sign-in settings saved and no credentials changed by us.

Owner requested emulator-first security tests, tenant isolation, permission
enforcement and bot/billing abuse protection. Email/password and Google are
desired; email-link passwordless sign-in is explicitly rejected. Apple sign-in
needs Apple Developer setup. MFA, preferably authenticator-based, needs platform,
recovery and Identity Platform review before enabling. SMS was not authorized.
App Check, rate limits and cost controls are separate from MFA; budget alerts
alone do not cap every service's charges.

Android/iOS/macOS/web are intended platforms; Windows remains intended too, but
Firebase's current Flutter Windows guidance limits native support to development.
Choose and test a production-supported Windows backend approach; do not silently
discard Windows or claim native Firebase Windows is production-supported.

## Main remaining release blockers

Read `docs/small_business_readiness_audit.md` for the wider queue. Key blockers:
active employee permissions still use development grants; full historical issued
document integrity; complete native sharing; cancellation/void lifecycle;
financial cost/pay/time attribution; owner-configurable alerts and approvals;
secure portal deployment and review; full restart/migration/recovery tests;
iOS/macOS builds, permissions and native runtime behavior. No enterprise-ready
or audit-compliance certification has been established.

## Mac continuation

Use the existing UI Lab 2.1 repository, verify its remote and dirty state before
pulling, and preserve Mac-side edits. Never reset/clean unrelated work. Run Pub
dependency resolution and relevant analysis/tests, then an Apple-platform build.
Use one simulator at a time and stop task-owned idle build workers afterward.
Do not introduce cloud writes as a side effect of merely launching the app.
