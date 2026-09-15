# Inventory migration: owner context and implementation audit

Date: September 15, 2026. Snapshot during the owner's voice planning session.
This is a discussion and audit record, not implementation authorization or a
replacement for the owning blueprints. Other tasks are editing this workspace;
findings describe files inspected during this audit.

## Owner direction retained

- The Materials screen is an inventory system; using inventory is optional.
- Maintainiac 5.7 Copy is the selected source for the intended migration.
- The assignment is to bring the actual inventory parsing engine into this
  application, including its regression tests and test harness, and migrate
  its storage dependencies and inventory persistence from Hive to SQLite.
- Merely referencing legacy code or extracting catalog data does not fulfill
  the assignment. Preserve the existing parser's capabilities.
- The owner is giving context by voice and will authorize implementation
  separately. The immediate request is to inspect what has and has not been
  implemented and retain written notes. This audit changes no app code.

Owning requirements already exist in `../receipt_material_intake_blueprint.md`,
`../operations_screen_blueprint.md` section 9, and decision D38 in
`../application_decision_register.md`. The extraction checkpoint is `README.md`
in this directory. These notes retain the current source selection and scope.

## Verified in the current files

1. `C:/Users/noneya/Documents/Maintainiac 5.7 copy` exists and is readable.
   This establishes filesystem access, not whether the folder was attached in
   the editor's workspace UI.
2. All 275 files under its `lib/screens/work_supplies/data` match the temporary
   `build/inventory_migration/source` snapshot by relative path and SHA-256.
   No files from that source subtree were missing or different. This comparison
   does not cover the whole parser pipeline, external services or test harness.
3. Catalog artifacts exist under `assets/inventory`: compressed SQLite and
   Electrical, Plumbing and HVAC JSON. The audit records 902, 1,153 and 1,279
   entries, respectively: 3,334 total. Conversion tooling and payload/reopen,
   integrity and rollback tests exist. The checkpoint records prior passing
   validation; this audit did not rerun those tests or independently query SQLite.
4. The stored parser characterization report contains eight passing synthetic
   cases against the extracted parser. This is limited smoke evidence, not
   real receipt acceptance or the transferred legacy harness.
5. The app has a separate structural receipt parser in
   `lib/src/data/receipts/receipt_item_parser.dart`. The receipt photo text panel
   calls it. It proposes descriptions, printed amounts, explicit quantities and
   prices, and flags some ambiguity. Its implementation explicitly excludes
   merchant profiles, catalog matching and the legacy generator.

## Not completed in the inspected implementation

- The legacy `InventoryParser` and work-supply matcher are not imported into
  app runtime code. They remain in the disposable build extraction. Copying
  them there is not integrating them into receipt intake or Materials.
- The converted trade catalog is not declared in the Flutter asset bundle or
  loaded by the app. `pubspec.yaml` currently declares document templates only.
- The legacy QA system is not transferred as an executable app test harness:
  110 filenames beginning `work_supply_parser_qa` exist across 5.7 Copy's `tool`
  and `test` trees; none exist under those names in this app's `lib`, `tool` or
  `test`. This is a bounded filename census, not the total count of all related
  legacy tests, fixtures or dependencies. New local receipt tests do exist.
- Materials still reads `PrototypeOperationsStore.inventoryStock`, backed by
  an in-memory list. The reference SQLite catalog is not a durable inventory
  ledger, purchase-cost history or stock-location migration.
- Receipt-to-catalog matching, learned identities/corrections, custom catalogs,
  stock and evidence linkage, and dependent Job-material consumers still need
  a complete migration and runtime verification. Their complete dependency
  census has not been established by this audit.

## Acceptance gaps to preserve for implementation planning

Review ambiguous sizes and units, multipacks, returns, discounts, unknown items,
merchant abbreviations, locale input and real OCR errors. Preserve user review,
receipt evidence and original values. Prove atomic stock/history/evidence writes,
duplicate-retry safety, interrupted-save/restart recovery, permissions and
cross-module consistency. Existing tests and synthetic examples do not prove
end-to-end receipt recognition or inventory accuracy on Android and iOS.

No app was launched, no screenshots were taken, and no 5.7 files were modified.

## Further owner clarification during the same voice discussion

The desired workflow is photographing a receipt such as Lowe's, selecting
Materials, and having the purchased items populated into the optional inventory
workflow with quantities, costs, receipt links and subsequent tracking. The
entire receipt-to-inventory path is the assignment, not just the small class
named `InventoryParser` or its catalog tables.

Sequence: complete the thorough audit; explain what has and has not been done;
discuss that report with the owner; wait for the owner's implementation
authorization. The owner will end voice personally when ready. Statements about
planning to end voice later are not requests for the assistant to end it.

Further read-only source findings in 5.7 Copy:

- `lib/screens/expenses/data/expense_receipt_parser.dart` composes the full
  receipt parser, including merchant profiles, OCR handoff/recovery, row
  classification, quantities, duplicate/overlap handling and material parsing.
  It directly imports the work-supply matcher. Its dependency graph extends
  outside the extracted work-supply data subtree.
- `expense_receipt_merchant_material_profiles.dart` includes a Lowe's profile.
- `lib/screens/work_supplies/entry/add_items_receipt_parser_actions.dart`
  calls `parseExpenseReceiptTextWithLocalMemory`, then
  `buildWorkSupplyParsedReceiptDraft`, and populates staged receipt and inventory
  lines with receipt review information. Source inspection is not device proof.
- `lib/screens/expenses/data/expense_materials_receipt_bridge.dart` preserves
  source line IDs, receipt attachments, merchant/date, quantities, units per
  package, unit, subtotal, tax rate and business-use fields in inventory review
  records. It runs only for a materials receipt with inventory tracking enabled.
  Personal and other business lines are separated; unmatched lines receive a
  review placeholder. Stock confirmation is a distinct step.
- `expense_receipt_inventory_prompt.dart` explicitly offers expense-only or
  preparation of Materials review lines; its UI says stock changes after
  confirmation. Do not conflate automatic item preparation with confirmed stock.
- `expense_receipt_save_actions.dart` saves the Expense before calling its
  Materials bridge and catches bridge failure for telemetry. Atomicity and
  recoverable retry across that boundary require explicit migration assessment.

## Explicit owner requirement: independent regression verification

Do not trust the current app's tests merely because they pass. Review existing
tests and expected results in both applications for meaningful business coverage.
Retest the migrated system and add regression coverage beyond the inherited
suites. Independently derive expected item identities, quantities, package
conversions, costs and stock effects from receipt evidence and confirmed
requirements, rather than using parser output as its own expected answer.

Cover representative receipts, ambiguous and incorrect matches, unknown items,
returns/discounts, mixed purchases, corrections, retries, interrupted saves,
restart recovery, permissions and linked Expense/Job effects. A discovered bug
needs a regression that exposes the failure and verifies the correction. Check
persisted records and the actual user workflow as well as parser return values.
Passing inherited or new tests alone does not establish product acceptance.
This adds an acceptance requirement; implementation remains on hold.
