# Inventory extraction checkpoint — September 14, 2026

Status: source extraction and reference-catalog SQLite conversion verified. This is not a completed
inventory migration, parser acceptance, or approval of either app's mobile UI.

The owner authorized transferring 5.7 inventory and parsing to UI Lab using
SQLite, including the electrical, plumbing and HVAC core packages. Cloud setup
is outside this local slice. This current authorization supersedes historical
task-specific deferrals, while keeping every 5.7 source read-only.

## Source comparison and reuse assessment

All four local `lib/screens/work_supplies/data` trees contain 275 files totaling
1,898,992 bytes, with identical relative paths and SHA-256 content fingerprints.
The sorted path/hash aggregate is
`2091D9B4AE3413C72F11314D8B06CB11E04E923660A3A98E6DDB4A16DF6F2705`.
This comparison does not cover their entire applications or remote GitHub state.
No re-clone is needed for the identical data subtree.

| Local folder under Documents | HEAD |
| --- | --- |
| 5.7 rebuild | 729187647cff7d2ed1e259f55d992d91abfef9a1 |
| Maintainiac 5.7 copy | 729187647cff7d2ed1e259f55d992d91abfef9a1 |
| Maintainiac_5.7_Active | 80afbad9efea1644cb7556c863c2fd06e9f0a88f |
| Maintainiac_5.7_W_2026-08-03 | 38775d02c047709c97ae6a0ba9ad98e28237a6ff |

Selected source: Active's actual working files, not just its older commit.
`source_manifest.json` records each copied file's hash and source dirty state.
The disposable extraction lives under `build/inventory_migration/source` and
is not compiled into the application. No Hive boxes or personal receipts were
opened or migrated. The snapshot is not a preservation backup.

| Component | Disposition and evidence | Remaining risk |
| --- | --- | --- |
| Catalog definitions, identity, aliases, units, intelligence | Reuse data through the legacy core selector and payload exporter; preserve every serialized field | Core selection and generated metadata need trade review; structural validity is not correct product identity |
| `inventory_parser.dart`, receipt matcher and trade-specific parts | Adapt; isolated text-to-catalog entry point exists; matches require review | Full characterization, false positives, learned identity, locale and ambiguous package handling pending |
| `work_supply_inventory_store.dart` and mappers | Replace Hive persistence with existing app SQLite transaction infrastructure | Sequential record/event/transaction writes can partially commit; preserve IDs, history and evidence rather than copying this write pattern |
| Receipt, custom-catalog and identity Hive stores | Adapt models and migrate behind authorized SQLite services | Malformed rows, stable identifiers, unknown fields, privacy and review status must survive migration |
| Receipt processing bridge, recognition/capture | Dependency mapping required outside the 275-file subtree | This snapshot alone is not the whole parsing/OCR pipeline |
| Legacy inventory screens | Reference workflow only; redesign with shared UI Lab primitives | Neither existing screen is accepted; complete mobile entry/review/recovery flow remains |
| UI Lab current inventory | Mutable lists in `PrototypeOperationsStore`, models under screens | Not yet durable stock; existing cost/count UI must be cut over together with its consumers |

## Executable extraction and conversion

1. `tool/inventory/extract_legacy_inventory.ps1` copies and fingerprints the
   source subtree, rejecting a changing source or an existing snapshot.
2. Its disposable Dart exporter uses the original core selection and schema-3
   payload builder, with all legacy market scopes. Selection is preserved,
   not independently certified as appropriate for every launch country.
3. `tool/inventory/build_sqlite_catalog.dart` converts exported core JSON into
   a SQLite reference catalog in one transaction and reopens it to compare
   every item's complete payload and hash. It rejects overwriting an artifact.
4. `catalog_audit.json` reports item counts and structural gaps. Empty vendor or
   barcode mappings are reported, never invented. No inferred purchase costs
   or stock balances are generated.

Verified counts: Electrical 902, Plumbing 1,153, HVAC 1,279 (3,334 total).
Every item survived the independent SQLite reopen/payload comparison. All
6,668 structural warnings are empty merchant-alias/barcode-alias collections;
no missing package-hint collection or shared canonical-key warning was emitted.
These are metadata gaps, not an assertion of 6,668 defective products.

The distributable SQLite gzip is 1,552,148 bytes, expanding to 31,252,480 bytes.
The three compressed source JSON files total 1,007,378 bytes. Both formats are
lossless; the inflated database is under `build/inventory_migration`.
On-device disk usage and opening/search memory still need measurement.

Validation: five focused Flutter conversion tests pass, including the packaged
SQLite artifact reopening with every field of all three packs preserved and rollback
on duplicate identity, incorrect trade, missing unit and unsupported schema.
Full Flutter analysis reports 14 findings in untouched Work/shared files;
none were in the new conversion tooling or tests. No app runtime or pubspec
change was made, so no platform build or UI acceptance is claimed for this pass.

`parser_characterization.json` records eight passing synthetic smoke cases
against the copied Active parser with only the three core packs: 14/2 versus
12/2 NM-B cable, half-inch versus three-quarter-inch copper elbows, blank input,
receipt footer, subtotal and a grocery line. Positive matches still require
review. This does not test real receipt OCR, HVAC identification, broad size
coverage, learned corrections, restart or receipt-to-ledger confirmation.
Run by copying `tool/inventory/characterize_parser.dart.template` beside the
disposable `source` directory and invoking Dart with the workspace package config.

The catalog artifact is preparatory data, not yet wired into the app bundle,
inventory screen, or receipt intake. Company overrides will belong to the
authorized app database; they must not be overwritten by catalog updates.

## Remaining migration sequence and acceptance

- Complete the external dependency census for receipt parsing, OCR proposals,
  corrections, learned aliases, evidence, custom items and permission checks.
- Adapt the parser into cohesive files within the 500-line production limit;
  independently characterize ambiguous and unmatched lines, receipt totals,
  multi-pack quantities, fractional units, returns, discounts and locale input.
- Define SQLite catalog identities, stock locations, immutable movements,
  purchase-cost history and parsed proposal versions using existing app
  authorization, revisions, idempotent commands and audit infrastructure.
- Import legacy records through a reviewable loss report. Reject or quarantine
  invalid rows with their raw source; never silently skip them. Preserve source
  IDs, receipt links, timestamps and original numeric representation. Unknown
  currency, location identity or pack size must remain unresolved.
- Prove atomic receiving, use, transfer, recount, correction and reversal with
  interrupted saves/restart, duplicate retries, stale revisions, wrong scope,
  denied cost access, insufficient stock and cross-module failures.
- Replace the current in-memory consumers together, including Job materials;
  buying stock, consuming stock and billing must never duplicate an Expense.
- Build and review phone workflows with shared theme/layout components:
  choose/manual item → quantity and purchase unit → paid amount and location →
  evidence preview → explicit effects review → durable save → reopen/history.
  Back/cancel, raw draft recovery, custom items and unknown quantities must work.
- Validate trade usefulness and representative real receipts with the owner;
  generated fixtures and passing tests cannot establish trade accuracy.

Owning requirements: `receipt_material_intake_blueprint.md` §§9–16,
Operations §9, Product Control, storage contract and capability migration map.
No visual acceptance, device performance, iOS build or production cloud claim
is made by this checkpoint.
