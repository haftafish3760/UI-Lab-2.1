# UI Lab 2.1 update handoff — September 19, 2026

## Transfer scope and baseline

Owner explicitly authorized committing and pushing all current UI Lab 2.1
changes on the Mac Mini, including diffs, blueprints and a detailed handoff.
Repository: /Volumes/AppleWork/UI-Lab-2.1.
Remote: https://github.com/haftafish3760/UI-Lab-2.1.git.
Branch: codex/desktop-inventory-handoff-20260917.
Previous pushed baseline: a10edd5593e04e8b123afea6d52e710f2b5851a2.
The commit containing this document is the new snapshot; use Git to obtain its
identity. Compare that commit to the baseline for the complete tracked diff.
Main is not being merged or overwritten. Maintainiac 5.7 is not part of this push.

This is preservation of unfinished work, not release certification. Existing
source changes were present before this transfer. No application functionality
was implemented during the push itself. Documentation changes in this transfer
add this handoff, its index link and the latest employee permission clarification.

## Existing source changes since the baseline

- Expense onboarding now offers Basic, Detailed, Mixed and Not sure yet with no
  preselected option. A selection is required before proceeding.
- Mixed and Not sure yet are distinct saved preferences, not new receipt record
  types. Both require Basic or Detailed selection for each new receipt.
- App preferences and the local preferences allowlist persist the new preference.
  Existing Basic/Detailed callers retain compatibility.
- ExpenseEntrySetupInput persists detailChosen. Older payloads without the field
  default to chosen, preserving existing draft behavior.
- Manual continuation and atomic receipt transfer reject a missing required
  detail selection. Direct new receipt entry also presents the choice gate.
- Receipt settings explain the per-receipt choice for Mixed/Not sure yet.
- Onboarding transitions slide/fade, respecting system reduced-motion settings.
- AppLayoutEngine restores materialsCatalogFor compatibility and its calculator
  part alongside the separate inventory layout calculator.
- These changes do not add expense-category synonyms or replace the OCR/parser.
- Recorded edit evidence identifies the conversation titled
  "Update technician view and blueprint" as implementing the four-choice receipt
  setup on September 18. This transfer conversation reviewed those edits.

## Tests and documentation included

Updated expense welcome, setup-workflow and receipt-transfer tests, plus new
expense_setup_four_choices_test.dart, cover choice gating and related behavior.
Receipt intake blueprint documents the four choices and transitions. Operations
blueprint and workflow roadmap record employee workday/weekly-hours requirements.
These documents distinguish future time-recording workflow from payroll.

The existing September 18 audit directory is included with its reports, source
manifest, discrepancy ledger, failing-test inventory, raw JSON test events,
audit-only probes, summarizer and generated PDF evidence. Existing tracked PDF
previews are included in their current state as requested. The audit reports
that tests regenerated already-dirty previews; pre-audit bytes were not retained.
Do not claim these PDF differences are newly owner-approved template designs.

## Verification evidence and known failures

The included audit reports 1,313 passing existing tests, 74 failed/errored,
three skipped, and one additional suite compile failure across 378 discovered
files. Five independent audit probes also failed. Analyzer reported one error
and seven informational findings. The storage Python harness passed 22 tests;
a macOS debug build passed but was not launched. These are prior audit results,
not fresh execution by this transfer task. Read output/audit-2026-09-18/
application-audit.md and verification-summary.json for scope and limitations.

Important recorded defects include trusted user/company authority not fully
connected, inventory not surviving the tested SQLite reopen path, partial
payments not reducing a tested outstanding balance, employee expense scope
matching names rather than stable identity, EV charging absent from a vehicle
report, and example-data loading erasing unrelated Work records. Receipt-to-stock
is incomplete. The audit includes additional discrepancies; this paragraph is
not the full defect list. Do not hide these failures or alter tests just to pass.

This transfer performs Git diff checks and remote-commit verification. It does
not rerun builds/tests or repair audited defects. Native recovery, device visual
acceptance, production account isolation and catalog correctness remain unproven.
Local Gradle caches are excluded from version control and preserved on disk.

## Current owner discussion and authority boundaries

- Day-one required workflows discussed here: linked jobs, estimates, quotes,
  invoices, payment records, expenses, scheduling, timesheets, optional vehicle
  beginning/end mileage, dashboard daily schedule/entries and enforced access.
  Optional use by a business does not mean optional delivery of a required module.
- Reusable job templates belong on Jobs and can apply to different customers;
  they are distinct from recurring scheduled visits.
- Latest employee permission clarification is owned by Operations section 10.
  Self-editing recorded timesheets defaults off. Full default permissions and
  Skip behavior remain unresolved following the owner's reconsideration.
- Online payment-provider integration was explicitly deferred after discussing
  risk, until the owner can obtain professional development/security support.
  Do not implement Stripe/PayPal/Venmo integration from earlier exploratory talk.
  This does not establish removal of ordinary payment recordkeeping.
- A lightweight customer portal/PWA for document viewing and estimate approval
  or signature was discussed. Exact scope/release timing is not finalized here.
  Do not interpret "all of Work" as unrestricted customer access or editing.
- Desired invoice/estimate visual examples are trade-themed lawn-care, masonry
  and plumbing scenes with document sections integrated into the artwork. Exact
  replication is not required. No new template implementation was performed here.
- Materials scope changed repeatedly. Later discussion reopened simple manual
  inventory with CSV/Excel import; do not treat older three-trade catalog or
  total-removal instructions as a newly settled implementation mandate.
- Owner explicitly requires device capability detection. 5.7 was inspected
  read-only: shared hardware/runtime classification, camera/sensor/battery/
  display/media/network detection, receipt processing and stitching policies,
  trip-assistance validation and consent, and native Android/iOS bridges exist.
  Storage and Android step-counter/step-detector checks exist. This is source
  evidence, not physical-device validation or completed migration. Some budget
  fields may lack consumers; platform parity and enforcement need further audit.
  No 5.7 code was changed or copied in this inspection.

## Continuation instructions

1. Verify machine, checkout, branch, remote and local dirty state before edits.
   Preserve any work on the receiving computer; do not reset/clean it to match.
2. Read AGENTS.md, governing blueprints and the included audit. Separate owner
   decisions from recommendations, legacy prose and tests. Ask only about real
   unresolved product choices, not routine engineering steps.
3. Address trusted identity/permissions and durable records before claiming
   production dependability. Use the discrepancy ledger to plan bounded repairs.
4. For device capability reuse, trace native readings through policy consumers
   and validate on target devices; do not equate a defined flag with enforcement.
5. Keep 5.7 read-only unless the owner explicitly authorizes a bounded exception.
6. The user requested this snapshot, not autonomous feature expansion. Voice
   pauses do not mean the user has finished speaking; honor explicit stop requests.
