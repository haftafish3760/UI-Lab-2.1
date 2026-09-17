# Tame Your Biz — Inventory/Materials owner handoff

> **Historical document:** For the September 17 desktop catalog/parser assignment,
> use [the current handoff](DESKTOP_HANDOFF_2026_09_17.md). Its latest owner scope
> supersedes both the all-trades requirements and the catalog-deferred banner below.

> Superseded for current execution by the owner’s later direction: catalog and parser are deferred, Materials becomes basic inventory, and this task resumes app-wide SQLite durability. See [current storage scope](../storage_migration_resume_2026_09_16.md). Historical requirements below are retained, not newly authorized work.

September 16, 2026. Current owner requirements and honest continuation state.
This document supersedes narrower scope statements in earlier inventory handoffs.
It is NOT catalog acceptance, a completed migration, or a passing QA report.

## 1. Correct scope and owner authority

- The application is **Tame Your Biz**, in the existing UI Lab 2.1 repository.
  The Mac workspace is `/Volumes/AppleWork/UI-Lab-2.1`. Work only on this app.
- **ALL trades require catalog audit, validation, migration and UI/UX work.**
  Keeping other trades' top-level names alone does not satisfy this requirement.
- **Plumbing, Electrical and HVAC are only the release-one PARSER scope.**
  Do not incorrectly apply that limitation to catalog work.
- Keep every existing top-level trade pack and its trade-selection entry.
- Maintainiac 5.7 Active is read-only source/reference, not an accepted authority
  for product correctness. Mac reference location:
  `/Users/rbbie/Documents/Maintainiac_5.7_Active`.
- Neither legacy tests nor already-migrated UI Lab code, catalogs, parsers,
  SQLite artifacts, documentation or prior success claims establish acceptance.
- The owner initially requested removal of catalog contents and architecture
  below the trade packs, then explicitly allowed existing items to remain IF
  every item is individually validated. Do not delete everything based on the
  superseded sentence. Preserve raw evidence, assess architecture before reuse,
  and rebuild unsound parts instead of retaining them merely because they exist.
  Unverified content must never be presented as accepted reference material.
- Receipt Generator is explicitly OUT OF SCOPE. Another Codex model will build
  that separate application alongside this project on AppleWork. Do not create,
  modify or take over that application. Its eventual output may support testing.
- This owner is one person, not a development team. Do not make the owner manually
  inspect thousands of items, read code, or supply translations they do not know.
  Investigate ordinary engineering questions independently. Escalate specific
  unresolved product/evidence decisions with clear options and a recommendation.
- Stop means stop all tools, edits and checks. While the owner is describing
  requirements or says listen only, do not start background work. Let them finish
  speaking; interruptions disrupt their train of thought. Explicit permission
  to begin was eventually granted, followed by this request to prepare a handoff.
  The current turn is documentation work, not permission to silently resume edits.
- Delegated work, if requested, must be visible Codex sidebar conversations;
  do not substitute hidden agents. No new conversation has been created here.

## 2. Required catalog acceptance: every item, every meaningful field

The owner requires 100% verified catalog accuracy, not a sample, approximate
accuracy, high confidence, or a passing conversion test. Work may be batched,
but every individual record and meaningful field must be accounted for.

For the three retained core exports the expected population is Electrical 902,
Plumbing 1,153, HVAC 1,279: 3,334 total. These counts are NOT the full all-trades
population and are NOT proof of correctness. The owner also referred to roughly
3,700–7,000 items; establish actual populations and distinguish artifacts rather
than treating informal quantities as an accepted census. Determine the full
all-trades population from source and current artifacts.

Each record needs verification of identity, trade/category placement, names,
descriptions, units, dimensions and sizes, ordered connection sizes, material,
system, connection type, package quantity, aliases, product/manufacturer details
where present, identifiers, translations/localized terminology and ALL other
carried fields, including nested generated metadata and matching intelligence.

Check for omitted, duplicate, wrongly combined, wrongly split, wrongly placed,
mistranslated, truncated, corrupted, invented or silently defaulted records or
fields. Do not generate unproven size permutations or promote generated pack
labels into real product categories. Similar products are not interchangeable.

Validate the source CONTENT as well as migrated representation. Lossless copying,
hashes, row counts, JSON equality and database integrity only establish technical
preservation. They cannot establish that the original product facts are true.

Every accepted value needs traceable authoritative evidence. Build machine-
checkable comparisons where possible, with retained source/version/location,
record identity, field/value, evidence, discrepancies and resolution/retest status.
Do not silently correct uncertain trade terminology or translations. Verify
meaning, including regional English/Spanish/French usage, rather than matching
strings. The owner specifically suspects incorrect Spanish plumbing terms.
Where authoritative evidence is unavailable, retain the uncertainty and seek a
bounded owner decision or qualified review. Never replace missing evidence with
an AI confidence assertion. Human verification requirements must be explicit.

All records must reconcile without unexplained entries or unresolved discrepancies
before catalog acceptance. If even one required item/field is unverified, do not
report 100% validation. Scope any partial result to exactly what it proves.

## 3. Audit before implementation

Determine what 5.7 actually implements, what is already present in UI Lab, how
transferred behavior/data changed, what is missing, and what cannot be proven.
Trace dependencies and callers, not just inventory-named files. Reassess useful
legacy behavior before preserving it. Audit tests for assertion correctness and
coverage instead of assuming a green result establishes correctness.

First resolve why VS Code reports inventory problems. No hiding diagnostics,
excluding failing tests, deleting inconvenient tests, or quick patches to make
the app appear healthy. Fix the actual dependency/build architecture and verify
clean-clone and clean-build reproducibility. Do not make source depend solely
on disposable build output.

## 4. Legacy harness and parser requirements

Recover and evaluate the reusable/shareable 5.7 QA harness, parser registry,
runners, support utilities, fixtures and regression corpus. Inventory ALL tests,
including those outside the dedicated directory; historical file/suite counts
are not a complete executed-test inventory. Port/adapt relevant tests to the new
implementation while retaining test intent. Shared harness should remain reusable
across the app. Characterization of old behavior is distinct from accepted behavior.

Required parser cases include exact identity; similar products; sizes; package
counts versus contained quantities; units; fractional quantities; measured lengths;
merchant abbreviations; OCR errors; ambiguous/unmatched lines; mixed receipts;
discounts; returns/credits; duplicate lines; totals/subtotals; locale/decimal
variation; custom products; learned corrections; and deliberately adversarial input.
Evaluate false confident matches and abstentions, not just successes. Never let a
guessed identity or quantity become confirmed stock. Ambiguous proposals remain
reviewable. Parser accuracy and full catalog accuracy are separate acceptance
questions; an older parser percentage target never weakens catalog verification.

Use independent expected answers. Do not feed receipt-generator answers into
inference, and do not use generated smoke examples as proof of camera/OCR quality.
Separate tuning from evaluation and text parsing from image/device verification.

## 5. Durable inventory and complete connected workflow

Use existing SQLite/Drift storage. Do not reintroduce Hive as a second authority.
Keep domain models/workflows behind repositories/services/controllers, separate
from layouts, widget trees, generated Drift rows and SQL in screens. Later screen
redesign must not require schema changes merely because presentation changes.

Audit/migrate/test stock locations, receiving, consumption, transfers, recounts,
corrections, reversals, purchase-cost history, receipt evidence, custom items,
learned identities/aliases and durable audit/history. Preserve source identity,
raw values and malformed legacy evidence; never discard failures silently.
Related business changes must be atomic or use an explicitly durable idempotent
cross-domain handoff. Test restart, interruption, duplicate retries, stale revisions,
failed writes and partial operations. Confirmed effects must not partially commit.

Verify the COMPLETE receipt flow: photo/imported evidence → recognition → parsing
→ proposed catalog match → user review/correction → explicit confirmation → durable
stock change → Expense/Materials/Job relationships → reopen after restart → history.
Inventory is optional. A parsed receipt must NEVER silently create stock. Manual
catalog addition without a receipt is also needed. Personal/non-stock expenses
must remain outside stock. Unknown items need a review/custom-item path.

Expenses, Materials and Job materials must not duplicate financial effects or
create duplicate expenses. Verify ownership, stable receipt/line links, business
scope, permissions and provenance across all consumers, not just parser output.
Security and dependability remain central because users rely on vehicle stock.

## 6. Catalog navigation and responsive UI/UX

Keep the top-level grid of trades. Selecting a trade opens that trade's meaningful
category choices. Continue through appropriate hierarchy to the exact part.
For Plumbing, examples include Pipe/Fittings, then material/system such as copper,
PVC, PEX, cast iron or steel, fitting type and exact sizes/connections. These are
illustrations of meaningful navigation, not one fixed hierarchy for every trade.
Assess the correct hierarchy for EACH trade. HVAC and Plumbing share some material
families, but similar wording does not prove identical dimensions or applications.
Avoid false duplication, incorrect cross-trade matches or lost distinctions.

Use shared AppLayoutEngine, theme and primitives, local post-navigation logical
width and TextScaler. Wide screens need useful bounded composition, not a stretched
phone, huge controls or arbitrary rigid levels. Review phone and desktop, with
accessibility reflow and correct Back/navigation behavior. Owner expects work on
all trade screens, not only the three parser trades. Existing layout is unapproved.
Read the owning UI, operations, calendar (if affected) and product blueprints before
UI edits. Do not alter unrelated UI just to satisfy old test expectations.

Build and launch normal Tame Your Biz on the Mac and S25 Ultra when verifying the
implemented workflow. Verify the actual artifact and device, not just a build exit.
One emulator at most on the 8-GB Mac. Stop idle Android workers after builds; preserve
Codex, the bridge and the owner's app. No blanket Java/Node termination. Screenshots
require the owner's authorization; be truthful about any screen-capture tool used.

## 7. Stage reporting and discrepancy ledger

Maintain a durable discrepancy ledger for every mismatch, uncertain translation,
questionable identity, parser regression, missing test, migration loss, default or
behavior change. Each stays visible until corrected and retested or presented for
an explicit owner decision. Preserve raw source and source hashes where relevant.
Do not silently hide, skip, auto-correct or discard malformed information.

After every major stage report: examined scope, proven facts, failures, changes,
retests and what remains unproven. Appropriate validation includes unit, database,
migration, parser, regression, integration and physical device/UI tests. Audit the
harness itself. Passing tests alone, successful compilation, copied records or
attractive UI are not completion. Do not promise a short fix or claim comprehensive
work happened in minutes. Continue in bounded, traceable stages without sampling.

## 8. Actual current work and evidence — NOT acceptance

**Zero catalog records have been accepted as fully verified by this audit.**

Initial inspection and limited engineering work occurred before this handoff:

1. Analyzer reproduced 28 issues: 24 errors from missing legacy imports in
   `test/inventory_legacy_parser_contract_test.dart` and
   `tool/inventory/export_review_batch.dart`, plus four style notices.
   Both depend on `build/inventory_migration/source`, which is ignored and was
   removed by the requested Flutter clean. This is a reproducibility defect,
   not evidence that all runtime inventory source is broken.
2. VS Code Gradle extension log independently showed it attempting to load the
   vendored image-picker Android library standalone without an Android plugin
   version, followed by Gradle connection errors. This is not yet repaired and
   does not itself prove failure of the real Android app build.
3. Compared all 275 recorded extraction source files against local 5.7. Raw
   hashes differ; ALL match after LF/CRLF normalization. No content difference
   beyond line endings was found by that comparison. This is not semantic proof.
4. Captured 247 transitive dependencies needed by the existing legacy probes into
   `tool/inventory/legacy_reference/data`, preserving source bytes and recording
   hashes in `manifest.json`. Imports use Dart/crypto, not Hive. Protected 5.7 was
   not executed or modified. This is a QA reference, not production acceptance.
   Capture tool: `tooling/inventory_qa/capture_legacy_reference.py`.
5. Updated the two broken callers to import that stable reference. No complete
   test rerun or successful clean analysis follows yet. Latest analysis reports
   SIX issues: one invalid constant property access in the legacy parser test,
   the original four style notices, and one initializing-formal notice in the
   preserved reference. Do not claim VS Code is fixed. Raw local logs:
   `/tmp/ui-lab-inventory-analysis.log` and
   `/tmp/inventory-after-reference-analysis.log` (not portable evidence files).
6. Added `tooling/inventory_qa/audit_catalog_artifacts.py`. It traversed ALL 3,334
   records in the three retained compressed JSON exports and compared complete
   decoded payloads with the retained SQLite catalog. No structural discrepancy
   was reported. This proves ONLY agreement between these artifacts. It does not
   independently verify source facts, terminology, dimensions or translations.
   The new audit script itself still needs adversarial/coverage review and tests.
7. Reports are in `docs/inventory_migration/audit_2026_09_16/`:
   `catalog_reconciliation.json` and `catalog_record_evidence.jsonl.gz`.
   Every record is explicitly semantically unverified. The field evidence contains
   top-level value hashes, including nested values, but NO authoritative evidence.
   This is a starting scaffold, not finished leaf-field provenance/acceptance.
8. Current runtime `assets/inventory/browse_batch.sqlite` contains ZERO items and
   21 top-level trades. Separate retained exports contain 902/1153/1279 records.
   Runtime loads the browse database, not the three-trade reference artifact.
   Do not conflate these populations, claim this audit deleted the items, or
   claim all-trades inventory was validated. No bulk catalog deletion was done here.
9. A directory census found 152 files in legacy parser QA support, 151 containing
   an `extends QaSuite` declaration, and 65 shared QA support files. Those counts
   are NOT the complete registry/test inventory. Harness porting has not happened.
10. Inspection exposed automatically derived intelligence, synthetic merchant-style
    identifiers, locale-marker aliases and legacy review flags in exported records.
    Their correctness is unproven. UI search filters certain aliases. Evaluate and
    ledger these behaviors; do not silently accept synthetic IDs as merchant SKUs.

No fresh inventory runtime validation, full regression, translated-term review,
all-trades census, durable stock migration or catalog semantic acceptance has been
completed in this latest pass. Earlier Mac build/launch success predates these edits.

## 9. Worktree and continuation cautions

The branch is main. Work is NOT committed/pushed by this handoff request. There
are existing Apple build configuration, Podfile/lock and pubspec changes produced
by the prior clean/pub-get/macOS build, plus generated caches. Preserve these and
inspect rather than reset. New inventory scripts/reference/reports and two import
changes are also uncommitted. No production layout changes occurred in this pass.

An active inventory migration goal was created, but its initial objective described
exhaustive record verification for only the three core trades. That wording is
STALE: the owner corrected scope to ALL trades for catalog work. This handoff
records the correction; do not use the old goal text to narrow the task.

Useful existing sources, read with their historical limits:
- `docs/inventory_rebuild_plan.md`
- `docs/inventory_migration/receipt_to_inventory_audit_2026_09_15.md`
- `docs/inventory_migration/README.md` and `source_manifest.json`
- `docs/receipt_material_intake_blueprint.md`
- `docs/operations_screen_blueprint.md`
- `docs/data_storage_sync_contract.md`
- `docs/maintainiac_app_blueprint.md` section 2 (reuse assessment)
- `lib/src/data/prototype_operations_store.dart`
- `lib/src/screens/inventory/catalog/` and inventory screen/domain consumers
- `lib/src/data/receipts/`, Work Job-material workflows and SQLite infrastructure
- `tool/inventory/`, `test/inventory*`, and legacy QA support/runner dependencies

Next work should finish the audit/census and discrepancy ledger, resolve test/tool
reproducibility and Gradle discovery without suppression, independently evaluate
catalog source authority and every record/field across ALL trades, and proceed
through tested UI/domain/parser/durability integration stages. This is not a
request to restart or overwrite the existing SQLite foundation.

## 10. Cross-check against related blueprints

Reviewed for this handoff: the inventory rebuild plan; September 14 extraction
checkpoint; September 15 receipt-to-inventory audit; September 15 inventory UI
verification; Expense/inventory delivery roadmap; Operations section9; and
Receipt/material intake sections8–16. Their historical completion claims were
not rerun or adopted as current acceptance. Latest owner corrections govern.

Additional existing requirements that must remain visible during this work:

- The historical rejected bulk export reported 57,314 trade-scoped entries across
  21 trades. That is a DIFFERENT population from the 3,334 core export records
  and current empty browse database. Reconcile provenance and every intended
  all-trades record; do not silently equate or discard these populations.
- Materials landing has real authorized attention, My Inventory, Browse Catalog
  and its supporting calendar. Location selection belongs inside My Inventory
  and must not change the official active vehicle. Unknown stock is not zero.
- Physical count replacement differs from stock addition. Per-item/location
  minimums may be disabled independently. Low-stock reminders require enabled
  reminders and explicit thresholds; no invented shortage or incoming counts.
- Catalog installation never creates owned stock. Company-confirmed aliases,
  package facts, custom items and cost history survive reference-pack updates.
- Estimates use cost history without automatically reserving/deducting stock.
  A roadmap contains older opt-in estimate-reservation wording; Operations says
  the later September15 direction supersedes that arrangement. Do not silently
  restore the older reservation behavior.
- Scheduling/assignment checks requirements by exact item/size and location,
  including combined commitments; assignment/date changes require rechecking.
  Transfers remain proposals until physical movement is confirmed. Actual use,
  cancellation, return and correction must not double-deduct.
- Materials receipt intake distinguishes all/some/not received. Only confirmed
  received quantities enter stock. Incoming orders and optional delivery reminders
  are separate from available stock and must not create another Expense.
- Line allocations may target Jobs, estimate cost evidence, a stock location,
  cost history only, expense-only use or unassigned review. Allocated quantities
  must not exceed confirmed quantities. Tax/discount allocation needs an explicit
  company policy or stays receipt-level, never a parser guess.
- Purchase history retains vendor/date/unit/package/currency/tax inclusion and
  source/confirmer. Markup changes selling price, not old purchases or issued
  documents. Stock consumption is not another purchase Expense; linking an
  Expense is not automatic invoicing. Accepted estimates are not rewritten by use.
- Cost, receipt, stock, billing and approval permissions are distinct; hidden
  costs must not leak through totals, exports, notifications or errors. Historical
  development-grant checks are not production employee/account enforcement.
- Evidence originals and raw printed rows remain separate from reviewed logical
  lines. Source regions, parser/proposal versions, actor, time, before/after and
  reversal reason must survive correction. Reprocessing produces a new proposal,
  not a rewrite of confirmed history. Numeric cost/quantity math must be decimal-safe.
- Local offline operation, pending writes and conflict review are required;
  no duplicate stock or financial effects after retries/sync. Global cloud work
  is not silently added to this inventory-only assignment.
- Existing documents assign PDF work to another model. Preserve record/evidence
  interfaces without taking over that subsystem or the Receipt Generator.
- Older roadmap says Expenses-first and defers inventory engines; the latest
  explicit inventory assignment supersedes that task-specific priority. Old
  parser percentage/coverage goals are not catalog semantic acceptance criteria.
- Earlier inventory StatefulWidget/hot-reload and passing UI/build claims are
  historical evidence only. Fresh runtime verification is needed after current fixes.

## 11. Owner-facing handoff readback

The following is the plain-language description of this handoff's assignment,
not a claim that the work has been completed.

The application is Tame Your Biz. This assignment covers the complete Inventory
and Materials system in UI Lab 2.1. Catalog audit, validation, migration and
layout work cover every trade. Plumbing, Electrical and HVAC are only the
release-one parser scope. Every top-level trade remains available. The receipt
generator is outside this assignment, and Maintainiac 5.7 Active remains read-only.

The first stage is an audit of the legacy implementation and everything already
transferred. Existing code, documentation, generated data and passing tests are
evidence, not acceptance. The audit identifies what exists, what changed, what
is missing, and what cannot be proven. It includes the VS Code failures and
repairs their actual causes without hiding diagnostics or deleting tests.

Every catalog record and every meaningful field requires individual accounting.
Batches are acceptable; sampling is not. Verification includes identity, names,
descriptions, trade and category, material, system, dimensions, ordered connection
sizes, units, package quantities, aliases, manufacturer and product information,
identifiers, translations and all nested matching metadata. It also checks for
missing, duplicate, wrongly merged or split, invented, defaulted, corrupted or
misplaced information. Similar plumbing and HVAC materials must retain their
real distinctions.

Every accepted value needs traceable authoritative evidence. Copying a wrong
value perfectly does not make it correct. English, Spanish and French terminology
requires meaning-based verification, including regional usage. Uncertain terms
are recorded, not silently corrected or guessed. Missing evidence remains a
visible unresolved issue. The owner is not expected to read code or personally
verify thousands of products and translations. Specific decisions or qualified
review are identified where evidence cannot establish an answer.

The complete legacy parser and reusable QA harness need an inventory of their
runners, fixtures, assertions and dependencies, including tests outside the main
support directory. Relevant tests are adapted to the new implementation, and
their expectations are independently reviewed. Parser testing covers similar
products, sizes, packages, fractions, measured lengths, units, abbreviations,
OCR errors, ambiguous and unmatched lines, mixed receipts, discounts, returns,
duplicates, totals, locale decimals, custom items, learned corrections and
adversarial cases. Guessed identity or quantity never becomes confirmed stock.

Durable inventory uses the existing SQLite and Drift architecture, without Hive
as another authority. Stock locations, receiving, consumption, transfers,
recounts, corrections, reversals, cost history, evidence, custom products and
learned aliases need durable audit history. Related changes cannot partially
commit. Verification includes interruption, restart, failed writes, stale edits,
duplicate retries and partial operations. Storage stays behind reusable domain
interfaces so later layout changes do not require rewriting the database.

The complete receipt workflow needs verification from photo or import through
recognition, proposals, human correction and confirmation, stock effects,
Expense and Job relationships, reopening and history. Inventory is optional.
Parsing alone never creates stock. Catalog installation never creates stock.
Manual additions remain possible without a receipt. Partial receiving, incoming
orders, actual consumption and stock corrections remain distinct. Stock use and
receipt linking never create duplicate expenses or financial effects.

The catalog begins with the retained trade grid. Each trade then has its own
meaningful category hierarchy leading to the exact part. Plumbing examples do
not impose one rigid structure on every trade. Phone and wide-screen layouts
need appropriate composition, readable labels, bounded controls, accessible text
scaling, correct Back behavior and useful search. My Inventory location browsing
does not change the active vehicle. Unknown counts remain different from zero.

Security checks cover record access, cost privacy, actions and related outputs.
Purchase history remains separate from markup and selling price. Estimates do
not silently reserve or consume stock, and confirmed documents are not rewritten
by later material use. The existing PDF and receipt-generator assignments remain
with their other models.

A discrepancy ledger keeps every uncertainty, mismatch, missing test, migration
loss and behavior difference visible until resolution and retesting. Each major
stage reports what was examined, proven, changed, failed, retested and remains
unproven. Unit, parser, database, migration, regression, integration and actual
Mac and phone checks are required where applicable. Tests themselves also need
review. Compilation or a green test alone is not completion.

The current audit has accepted zero records as fully verified. The comparison of
three thousand three hundred thirty-four core records established only that
exported payloads matched their SQLite copies. It did not verify their real-world
accuracy. The current browse database, retained core exports and historical bulk
export are different populations and still require reconciliation. The small
reference-dependency repair is unfinished, analyzer issues remain, and the legacy
harness has not been ported. The full all-trades audit and durable migration remain
unfinished. No claim of one hundred percent catalog accuracy is justified until
every required record and field is accounted for and all discrepancies are resolved.
