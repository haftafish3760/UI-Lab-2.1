# Receipt-to-inventory migration audit

September 15, 2026. Source inspection of Maintainiac 5.7 Copy against the
current UI Lab 2.1 working files. Prepared directly in the owner's voice task.

## Conclusion

The connected legacy receipt-to-inventory system has not been migrated into
the running app. Completed preparation consists of a matching source snapshot,
three exported trade catalogs, a SQLite catalog artifact, conversion tooling
and tests, and a small recorded parser smoke run. New receipt-reading and
itemization code exists in the app, but it is a different, narrower parser.
Inventory stock remains an in-memory prototype collection.

The assignment is to transfer the working capability, not just its catalogs.
The owner will review this audit before authorizing implementation, and will
end the voice conversation personally. Inventory use remains optional.

## What the inspected 5.7 source actually does

The receipt path spans Expenses, shared receipt code and Work Supplies:

1. Receipt capture/OCR or imported text supplies the receipt content.
2. The Expenses receipt parser handles merchant profiles, header fields,
   receipt rows, quantities, totals, duplicate/overlap diagnostics, confidence
   and category/material matching. A Lowe's merchant profile is present.
3. Local receipt-item memory can refine matching for a recognized merchant
   when inventory matching is enabled. The local-memory store uses Hive.
4. Work Supplies converts parsed lines into staged receipt and inventory
   entries. These carry item identity, quantity, package size, unit, purchase
   cost, storage location, merchant, receipt and receipt-line references.
5. The Expenses route can also create Materials review records after saving
   an Expense, when its materials-receipt and inventory-tracking flags permit it.
   Personal, other business and inventory lines are distinguished. Unknown
   catalog items can remain review placeholders.
6. Automatic preparation and confirmed stock are separate in the source:
   assisted inventory lines require review/confirmation before stock changes.
   Work Supplies ultimately calls its Hive inventory store to add stock.

This describes inspected source paths. It is not a claim that every legacy
camera-to-stock scenario has been exercised successfully on a device.

## Component disposition

| Component | Present in this app | Missing or unverified | Migration disposition |
| --- | --- | --- | --- |
| Legacy work-supply data source | All 275 files in the temporary extraction match Copy by path and SHA-256 | Snapshot is outside runtime; external dependencies are not covered | Reuse protected source through a bounded adaptation |
| Electrical, Plumbing, HVAC catalogs | Compressed JSON and SQLite artifacts; recorded counts 902 / 1,153 / 1,279 | Not declared in Flutter assets or loaded by the app; trade usefulness not independently accepted | Reuse data; integrate validated loading/search and update handling |
| Catalog conversion | Exporter, transactional writer, structural report and five conversion tests | Reference catalog only; no owned stock, purchase history or receipt migration | Reuse tooling and verification; extend only for defined data contracts |
| Legacy inventory matcher | Copied in temporary extraction | No legacy matcher imported in app runtime | Adapt matching logic and its actual dependency graph |
| Full receipt parser | Separate structural parser and field proposals exist | Legacy merchant profiles, receipt parser composition and material matching are not integrated | Adapt the legacy receipt pipeline to current receipt contracts |
| Photo reading | Native ML Kit reader, bounded image processing and Android long-photo section code exist | No fresh device verification; this is not the legacy end-to-end inventory flow | Reuse suitable current adapters; verify native behavior separately |
| Parsed evidence/drafts | Models retain recognized text, parser version, source rows and evidence checksum; recovery tests exist | Does not establish confirmed catalog identity or inventory receipt persistence | Reuse evidence/draft infrastructure through explicit adapters |
| Merchant correction memory | Legacy Hive implementation inspected | No equivalent legacy memory adapter connected to current receipt parser | Adapt to SQLite with scope, revision and review provenance |
| Custom catalogs and identity | Legacy catalog/identity source in extraction | Not integrated with current receipt or Materials workflows | Adapt storage and callers; verify unknown/custom identities |
| Receipt-to-Materials bridge | Legacy bridge source inspected outside extracted subtree | No equivalent legacy runtime handoff in current app | Adapt stable receipt/line links and review staging |
| Stock and locations | Current Materials screens read prototype stock | No durable inventory ledger connected to those screens | Replace Hive persistence using the existing SQLite foundation |
| Purchase cost and movements | Legacy record/event/transaction structure inspected | Current inventory does not persist equivalent movement and cost history | Preserve meaning/IDs; make related changes atomic |
| Job materials | Current Job materials drafts, permissions and Work persistence code exist | They are not proof of durable stock consumption or receipt-linked inventory integration | Connect consumers to the inventory authority and verify effects |
| Legacy parser harness | No same-named files from its dedicated support directory found in local lib/test/tool | Full registry, runners, support, fixtures and adaptation are outstanding | Port relevant harness and regression coverage, retaining test intent |
| Runtime acceptance | Existing tests and recorded limited results | Real Lowe's receipt to reviewed stock, restart, retries and Android/iOS acceptance not established | Verify the complete workflow after implementation |

## Harness and validation evidence

- Fresh SHA-256 comparison: 275 source data files, zero missing and zero
  different in the temporary extraction.
- Existing catalog audit reports 3,334 entries. The compressed SQLite artifact
  exists. The prior checkpoint reports successful full-payload comparison after
  reopening; this audit did not independently rerun that database comparison.
- The stored parser characterization contains eight synthetic smoke cases:
  four item matches and four blank/non-item examples. It is not the legacy
  regression corpus and does not establish broad HVAC or real-receipt accuracy.
- Fresh dedicated-directory census: 152 files in legacy
  `test/support/work_supply_parser_qa`, including 151 files containing an
  `extends QaSuite` declaration. None of those 152 basenames appear in this
  app's `lib`, `test` or `tool`. This counts files, not executed test cases.
- The legacy shared `test/support/qa_harness` contains 65 files. Additional
  runner and fixture paths exist outside the dedicated parser directory.
  The earlier 110-file prefix census was narrower, not the harness's full size.
- The legacy checklist's recorded 142-suite result is historical and is not
  a fresh run or current registry count. Its own completion definition excludes
  comprehensive executable behavior, real receipts, device/OCR and release proof.
- Local structural parser, independent examples, receipt recovery and catalog
  conversion tests exist. A focused four-file Flutter test invocation was
  attempted during this audit, produced no output, and was stopped. It supplies
  no fresh pass/fail evidence. No legacy harness was run in its protected source.

## Risks the transfer must resolve

- **Partial saves:** the legacy inventory store writes records, events and
  transactions separately. Expense saving precedes the Materials bridge, whose
  errors are caught and recorded. A successful Expense save is not proof of a
  successful inventory handoff. Adapt this with atomic commits or a durable,
  idempotent handoff and visible recovery, as appropriate to ownership.
- **Ambiguous quantities:** preserve printed values and distinguish package
  counts, contained units, measured lengths and unit prices. Do not promote a
  guessed quantity or exact item identity into confirmed stock.
- **Mixed receipts:** personal purchases and non-stock business expenses must
  remain outside inventory; unmatched items require a usable review/custom path.
- **Nonpositive lines:** inspected bridge paths filter nonpositive subtotals;
  returns/credits need deliberate coverage rather than inheriting that omission.
- **Recognition and identity:** verify merchant abbreviations, similar sizes,
  units, locale decimals, discounts, OCR noise and learned corrections. The
  structural catalog report has 6,668 empty merchant/barcode alias collections;
  this is a metadata gap, not proof that every item is unusable.
- **Durability and authorization:** verify restart, interruption, duplicate
  retries, stale edits, stock movement history, receipt access, organization
  scope and Job/Expense consistency. Shared SQLite infrastructure already exists;
  inventory must be connected to it rather than creating another authority.

## Remaining implementation stages

1. Map and adapt the full receipt/parser dependency graph and legacy tests.
2. Integrate the catalog and SQLite-backed identity/custom/learning data.
3. Implement durable inventory receipts, locations, movements and cost history.
4. Connect materials receipt review/confirmation to inventory, Expenses and Jobs.
5. Verify regression parity, migration integrity, failure recovery and the
   actual phone receipt-to-inventory workflow. Preserve the owner's optional
   inventory choice and explicit confirmation of business records.

These are migration stages, not separate authorizations. No implementation,
source cleanup, legacy edits, app launch or screenshots were performed here.

## Primary evidence files

Legacy paths relative to `C:/Users/noneya/Documents/Maintainiac 5.7 copy`:

- `lib/screens/expenses/data/expense_receipt_parser.dart`
- `lib/screens/expenses/data/expense_receipt_merchant_material_profiles.dart`
- `lib/screens/expenses/data/expense_receipt_item_memory_store.dart`
- `lib/screens/expenses/data/expense_materials_receipt_bridge.dart`
- `lib/screens/expenses/entry/expense_receipt_save_actions.dart`
- `lib/screens/work_supplies/entry/add_items_receipt_parser_actions.dart`
- `lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart`
- `lib/screens/work_supplies/data/work_supply_inventory_store.dart`
- `lib/screens/work_supplies/data/work_supply_inventory_receipt_store.dart`
- `test/support/work_supply_parser_qa/work_supply_parser_qa.dart`
- `docs/inventory_parser_qa_harness_contract_completion_checklist.md`

Current-app paths:

- `docs/inventory_migration/README.md`, `catalog_audit.json`, `parser_characterization.json`
- `tool/inventory/`, `assets/inventory/`, `pubspec.yaml`
- `lib/src/data/receipts/receipt_item_parser.dart`, `receipt_photo_reader.dart`, `receipt_item_read.dart`
- `lib/src/screens/expenses/receipt_photo_text_panel.dart`
- `lib/src/screens/inventory/inventory_screen.dart`
- `lib/src/data/prototype_operations_store.dart`
- `lib/src/data/storage/local_database.drift`, `sqlite_domain_snapshot_store.dart`
- `lib/src/data/work/job_materials_draft_workflow.dart`
- `test/inventory_catalog_conversion_test.dart`, `receipt_item_parser_test.dart`,
  `receipt_item_independent_examples_test.dart`, `receipt_item_read_recovery_test.dart`
