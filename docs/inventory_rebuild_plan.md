# Inventory rebuild — September 16, 2026

> **September 19 continuation — latest owner scope:** Catalog expansion is
> deferred for release one. Prioritize useful standalone inventory, manual and
> CSV/spreadsheet entry, user categories, search, purchase-price history, and
> reliable receipt review. Review the whole app for consistency and missing
> engineering safeguards. Durable storage, OCR and the long-receipt workflow
> are explicit priorities. Earlier catalog-first directions below are historical.
> Existing generator/harness work remains development infrastructure, not an
> approved production catalog. Work is authorized on the HP; no delegation.

Inventory list cells use the shared `AppLayoutEngine.inventoryListFor` contract:
compact columns rather than one desktop-wide row. At ordinary text scaling,
800 LP of local content width accommodates three columns and 1100 LP four;
phone widths use one. Increased text size and complete-word measurements reduce
columns when needed. The normal cell-width ceiling is 360 LP, with height growing
for full readable text. Grid mode remains available. This rule concerns inventory
cells, not unrelated operational forms or receipt previews. Widget checks are
not visual acceptance on the owner's hardware.

> **September 18 implementation resumed:** The owner explicitly authorized
> starting the generator and independent harness on the HP. See the
> [engineering checkpoint](inventory_migration/CATALOG_ENGINEERING_CHECKPOINT_2026_09_18.md)
> for inspected legacy limitations, first-slice implementation, tests, open
> requirements and failure analysis. The earlier pause checkpoint below is
> historical. No delegation, Mac edits or live catalog publication is authorized.

> **September 18, HP Windows — read before continuing:** The owner supplied and
> endorsed a complete independent catalog/Inventory verification specification
> and accompanying provenance/source-safety requirements. They are preserved
> **word for word**, not summarized, in
> [the owner verbatim requirements record](inventory_migration/OWNER_VERBATIM_REQUIREMENTS_2026_09_18.md).
> Read that entire record after context compression and before future catalog,
> inventory, parser or validation-harness work. It is a minimum requirement,
> not a claim of implementation or acceptance. Further owner additions are expected.
> Implementation remains paused pending the owner's go-ahead; the present
> authorization is documentation only, on the HP, without delegation.
> Conflicting older scope, device and authorization statements below are historical;
> current owner directions and the linked record take precedence.

> **September 17 desktop transfer correction:** The owner's latest direction is
> Plumbing, Electrical and HVAC only, catalog first, followed by parser integration
> with a rebuilt independently validated harness. Earlier all-21 and catalog-removal
> directions are superseded. See [the desktop handoff](inventory_migration/DESKTOP_HANDOFF_2026_09_17.md)
> for the decision record, incomplete source state, open questions and transfer instructions.
> The older progress and test statements below are historical, not current acceptance.

**Latest owner scope — September 17, fittings review:** Begin with Plumbing → Fittings and owner review of grid/list and light/dark presentation. Bundle Plumbing, Electrical and HVAC for release one. The owner subsequently requested all 21 trade choices, with the other packs downloadable through Firebase by account holders; interrupted downloads and offline availability must be handled. Trade imagery is awaiting clarification following the owner's newer request for two missing photos, which conflicts with the prior text-only direction. Do not silently treat optional packs as downloaded or verified. Parser and receipt-generator work remain deferred. User-inventory persistence belongs to another task. Maintainiac 5.7 Active remains read-only reference; a separately authorized S25 Ultra wireless build awaits device connectivity.

## Required evidence — September 17 owner correction

- A passing 5.7 test is not proof that its expected answer or catalog data is correct. Review reusable harness components and expectations independently; adapt useful components rather than rebuilding infrastructure without assessment. The resulting harness belongs to Tame Your Biz and need not remain compatible with 5.7.
- Account for every source record in the three trades, in bounded batches. Track identity, full hierarchy, names, ordered connection sizes, units, aliases, translations and measurement semantics per item. No sample, minimum-count assertion, aggregate percentage or generated report alone establishes complete coverage.
- Keep migration fidelity, independent semantic validation, SQLite integrity, search behavior and rendered accessibility as separate results. Missing or questionable evidence remains unresolved. Never promote a source's `verifiedManually` flag into independent acceptance.
- Observed read-only: `work_supply_plumbing_core_curation_audit_report_test.dart` asserts report-file existence, not correctness of reported findings. `work_supply_parser_qa_harness_test.dart` defaults to smoke/non-strict operation with schema/alias sample limits. `work_supply_catalog_scale_test.dart` checks counts and metadata coverage, not product correctness. These observations concern those assertions, not every legacy test.
- UI Lab baseline on September 17: three existing test files ran 24 tests; 19 passed and five failed because the bundled browse asset has zero items while old tests expect 49 and specific fittings. Fixture-based layout and separate batch round-trip passes do not validate shipped catalog content.
- U.S./Canada catalog scope; English and Spanish must follow shared language settings. Preserve nominal trade designations and distinguish them from actual dimensions and regional equivalence; a display-unit change must not substitute a different product. Foreign-language and regional correctness require evidence, not automatic translation acceptance.
- No tests or implementation during voice discussion unless the owner expressly asks for execution then. Keep work in this chat; no additional agents. Run resource-bounded validation on this Mac.

Owner-authorized work in this task only. No delegation. Maintainiac 5.7 Copy
and Active are read-only. Preserve unrelated working-tree changes and business
records. The retained trade-selection screen is the starting point; rebuild
everything beneath a selected trade, rather than patching misleading pack names.

## Order and acceptance

1. Record and audit the rejected export, then remove it from the application.
2. Rebuild category navigation as compact, image-free grids. Trade artwork follows the pending owner decision; do not show unverified item counts. Use shared responsive layout primitives,
   bounded desktop content, full labels, accessibility scaling, and one-level
   Back. Verify phone first, then portrait/landscape tablet and wide windows.
3. Inspect each trade's actual source hierarchy. Plumbing's material/type/size
   example is not a universal hierarchy. Reach the exact item, including ordered
   connection sizes, material/system, connection distinctions, unit and aliases.
4. Reuse suitable parts of the substantial 5.7 harness. A passing legacy test
   is NOT evidence that its expectation is correct. Review assertions and add
   independent expectations and negative cases before trusting a migrated batch.
5. Migrate very small category batches, one trade at a time, to SQLite. Preserve
   complete source payloads and provenance. Check every row after reopening;
   detect duplicates, incomplete paths, lost aliases and unsupported variants.
   Do not invent all size permutations or silently present unreviewed packs as
   finished categories. Clearly distinguish incomplete coverage from zero stock.
6. Support manual addition from the catalog without a receipt. Existing temporary
   stock must not be represented as durable. Durable authorized atomic stock,
   cost, location, receipt and Job workflows require their own validation.
7. Adapt and validate the receipt parser after its prerequisites. Preserve valid
   aliases and matching behavior; independently evaluate errors rather than
   trusting either app's existing harness.

## Parser evidence

The owner requires at least 90–95 percent accuracy, with a higher result desired.
Define denominators before reporting accuracy: exact item/variant matching,
quantity and package interpretation, price extraction, and complete-receipt
success separately. Report abstentions, incorrect confident matches and coverage.
No single percentage or passing smoke suite establishes production readiness.

The separate Receipt Generator application provides fictional-store synthetic
receipts and separate expected answers. Inspect its data and independence before
reuse. Never feed the answer file to OCR/parser inference. Keep evaluation cases
separate from tuning cases. Synthetic text tests do not establish camera/OCR
accuracy; image and real-device checks remain separate gates. Do not introduce
unauthorized real receipts or assume unknown source permissions are cleared.

## Progress and limits

- Plan recorded before the new implementation.
- Rejected browse export: compressed JSON, omitted aliases and metadata, fixed
  four-level navigation. It is not the earlier three-trade SQLite reference.
- Source inspection found generated pack labels inside 5.7 category definitions;
  their presence in source does not make them appropriate browsing categories.
- Stock persistence, parser accuracy and owner visual acceptance are unproven.
- Continue recording exact completed batches, tests, failures and next steps.
  Do not stop merely because the layout portion is done; progress through the
  authorized sequence without claiming unfinished work is complete.
