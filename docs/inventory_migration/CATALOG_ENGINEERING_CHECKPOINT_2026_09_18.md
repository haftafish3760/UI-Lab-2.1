# Catalog engineering implementation checkpoint — September 18, 2026

## Authorization and scope

Owner: “Go ahead and start building it then if you would, please.” This resumes
generator and independent harness implementation on the HP in UI Lab 2.1.
No delegation. No Mac edits. No 5.7 edits. No live catalog publication, app UI
changes, Firebase writes, branding changes or inventory mutations in this slice.
The verbatim requirement record is retained unchanged as historical source;
its earlier pause notices are superseded by this explicit start authorization.

## Evidence and reuse assessment

Read-only inspection of the Windows 5.7 reference and existing UI Lab tooling:

- 5.7 `tool/work_supply_catalog_blueprint_generator.dart`: `_buildBlueprints`
  cycles families/sizes until a requested count and places an ordinal in each ID.
  It explicitly marks results synthetic, unverified, and review-required. Useful
  reference for staging intent; replace for canonical physical-item generation.
  Its sequence-based identities are not suitable as durable catalog identities.
- 5.7 `test/work_supply_catalog_blueprint_generator_test.dart`: checks output
  count, manifest flags, fields and supported trades. These are useful format
  checks, not independent factual or canonical-identity proof.
- 5.7 `test/work_supply_catalog_scale_test.dart`: checks count floors and coverage
  metadata. It cannot establish that manufactured variants are real.
- UI Lab `tool/inventory/catalog_sqlite_writer.dart`: transaction and source
  fingerprints are useful patterns; canonical duplicate detection is per trade
  and reports warnings. Replace that identity approach for this new framework.
- UI Lab `tool/inventory/build_browse_batch.dart` and `browse_batch_sqlite.dart`:
  protected output and transactional reference-data writing are useful patterns.
  This slice does not reuse the old catalog records or write its browse asset.
- Read the migration map's QA reuse section. The parser and substantial legacy QA
  backbone remain for a separate audited characterization slice; no claim that
  they have now been independently tested, copied, ported or replaced.

Python's standard library was chosen for development tooling: exact rational
arithmetic, SQLite, deterministic JSON, subprocess isolation and unittest require
no app dependency or Flutter build. The application remains Dart/Flutter; this
tooling is outside app assets and imports. Existing unrelated Dart/lock/plugin
changes present before this turn were preserved.

## Implemented first slice

- One declarative candidate generator with three different fixture families:
  pressure tees, conductors and filters. No hardcoded trade branch in the builder.
- Stable identity v1 includes family attributes and named complete dimension
  ports; omits display labels, input ordering and trade/navigation associations.
- Exact fractional/decimal normalization. Nominal and actual remain different.
- The symmetric pressure-tee fixture swaps complete run ports, never its branch.
  Connection types move with port sizes. No general claim about directional tees.
- SQLite staging tables for identities, nodes, associations, aliases, sources and
  evidence. Six synthetic inputs produce five identities with six associations.
- A separate read-only post-build validator, not importing generator code or
  family definitions, checks the limited independent acceptance rules.
- Actionable JSON/Markdown reports; structural pass is separate from release
  eligibility. Release is hard-blocked while unimplemented mandatory gates and
  unverified sample evidence remain. This is intentional, not a finished gate.
- Deterministic negative fixtures, seeded reversal tests, corrupted artifacts,
  and three targeted validator-code mutation experiments in temporary copies.

## Verification performed

`python -m unittest discover -s tool/catalog_engine/tests -v`: **21 tests passed**.
The fixed-seed reversal test includes 120 generated test cases (seed 918).
`check_mutations` detected **3/3** deliberately disabled validator rules, each
after its baseline test passed; detection required an assertion failure rather
than accepting an import error or crash as a successful mutation detection.
Separate generation/validation commands produced the staging database, reopened
it and reported structural pass, factual verification zero, release false.
The `--release` invocation exited **1**, as required for unfinished fixture data.

Initial tests exposed unclosed SQLite handles that prevented Windows temporary
file cleanup. Explicit closing now surrounds generator/test connections. The
regression suite covers failed-build rollback and read-only repeated validation.

Artifacts from this execution are local under `build/catalog_engine/`:
`candidates.sqlite`, `validation.json`, `validation.md`, `release-check.json`,
`release-check.md`, `mutations.json`. They are development outputs, not published
packs. Reusing a generator output path deliberately fails instead of overwriting.

No app code changed in this slice, so no Flutter build or app visual acceptance
is claimed. Python tests validate the new tooling, not the running app's stock
integration, parser, rendering or legacy behavior.

## Initial failure-mode analysis

This is an initial component analysis, not a completed formal system review.

| Component / failure | Damage | Reproduction / present check | Remaining evidence |
|---|---|---|---|
| ID depends on input order or aliases | Broken saved references | Reorder and rename tests | App migrations and historical records |
| Run reversal creates duplicate tee | Double stock identities | Literal expected signatures, seeded reversal and duplicate mutation | Verified real-family applicability |
| Branch is sorted with run | Different fittings collapsed | Branch change and signature tests | All fitting families and diagrams |
| Connection stripped from port identity | Wrong physical part | Whole-port reversal vs size-only swap | Adapter, thread and standard semantics |
| Nominal treated as actual | Wrong match | Basis-change separation test | Regional nominal systems and conversions |
| Parent removed/cycle introduced | Unreachable browsing | Orphan/cycle/depth checks | UI navigation and duplicate semantic branches |
| Whole family missing | Incomplete pack passes | Independent declared-scope check and disabled-rule mutation | Complete declared trade coverage |
| Source flag claims verification | Unsupported facts shipped | Forged-verified evidence rejected | Evidence review/rights registry |
| Unknown schema or private tables | Unsafe pack/private data | Corruption/version/extra-schema tests | Full field-level privacy and hostile SQLite isolation |
| Validator modifies evidence | Hidden defects | Byte preservation and deterministic repeat tests | Broader validator audit |
| Build fails or output exists | Damaged prior artifact | Foreign-key failure rollback and exclusive creation | App transactional installation and recovery |
| Rule silently removed | False green report | Three code-mutant experiments | More mutations and independent review |
| Similar copied algorithms share a mistake | Circular false confidence | Literal expectations and separate acceptance code | Externally checked semantic oracles |
| Resource exhaustion / concurrency | Freeze or data loss | File-size/SQL work limits only | Stress, fuzz, process kill, memory, network, simultaneous writes |

## Requirements accounting and partial test mapping

`catalog_requirements_traceability.json` preserves all **110 paragraphs** in
sections 2, 5 and 6 of the verbatim record with stable paragraph references.
This is initial paragraph-level accounting, not atomic requirement completeness.
Every entry remains `not_yet_fully_verified`; mapping a test is only partial
evidence. The original prose is retained, not replaced by summaries.

| Implemented check | Test methods in `tool/catalog_engine/tests/test_engine.py` |
|---|---|
| Symmetry and distinction | `test_reversed_run_deduplicates_but_branch_change_does_not`, `test_connections_travel_with_run_sizes`, `test_seeded_run_reversal_property` |
| Stable canonical IDs | `test_metadata_order_aliases_do_not_change_identity`, `test_rows_reordered_produce_same_identities`, `test_mutated_dimension_breaks_stable_identity` |
| Duplicate detection | `test_duplicate_disguised_by_fraction_format_is_detected` |
| Dimensions/family schema | `test_numeric_boundary_and_malformed_inputs`, `test_nominal_and_actual_never_collapse`, `test_bad_units_and_family_fields_are_rejected` |
| Graph/scope | `test_orphan_cycle_and_wrong_trade_are_detected`, `test_missing_whole_family_is_not_hidden_by_valid_remaining_rows` |
| Evidence/read-only results | `test_forged_verified_evidence_is_rejected`, `test_validator_does_not_repair_or_change_evidence` |
| Artifact boundary | `test_bad_sqlite_and_unknown_schema_rejected`, `test_extra_private_tables_rejected`, `test_malformed_json_shapes_are_reported_not_crashes` |
| Build protection | `test_generator_refuses_overwrite_and_rolls_back_failed_build` |
| Honest release state | `test_valid_fixture_structural_pass_is_not_release_pass`, `test_post_build_cli_has_real_release_failure_exit` |
| Dependency separation | `test_validator_has_no_generator_import_or_definition_dependency` (limited static check, not proof of oracle independence) |

## Next unfinished work

1. Decompose all paragraphs into atomic obligations and map checks, failures,
   independently established expectations and retained evidence bidirectionally.
2. Complete discovery for the first real family. Establish permitted factual
   sources, verified existence/coverage and explicit identity semantics. Do not
   promote these synthetic fittings or treat 5.7 as the source of truth.
3. Extend declarative schemas and independent acceptance policies for more
   families, units, connections, sorting, aliases, packaging and localization.
4. Build reviewed evidence/provenance and source-rights handling; make unknown,
   conflicting and stale data explicit. Software checks cannot give legal clearance.
5. Add signed/versioned pack manifests, independent semantic diffs, installation,
   rollback, update/reference integrity and large-scale performance/security gates.
6. Characterize and adapt the parser separately; connect real SQLite inventory,
   locations, receipts and the reusable item UI only after prerequisites are proven.
7. Prove actual search/navigation/accessibility and inventory flows on supported
   devices, along with the remaining recovery/privacy/concurrency requirements.

The requested generator/harness system is **not complete**. The first executable
foundation and its targeted regression tests are complete; all larger release
claims remain blocked and visible.

## Continuous-goal continuation — September 18

The owner explicitly requested a continuing goal after the first slice. That
active goal now covers the entire specified generator and independent harness.
Do not stop at a small slice or mark this goal complete on synthetic evidence.
Continue directly on HP, without delegation. No new approval is needed for the
authorized implementation and testing. No publishing is authorized.

Additional development-tool work implemented:

- Independent fixed acceptance scope closes an actual bypass: erasing a pack's
  own scope cannot hide a deleted family. Malformed scopes fail explicitly.
- `run_qa.py` records actual unittest events, including failed subtests, skips,
  missing and ambiguous mappings. An empty suite cannot pass. Reports fingerprint
  test/tool source files and retain all 110 owner paragraphs as incomplete.
- `compare.py` produces semantic changes for items, aliases, navigation, trade
  associations and provenance. Removed identities require explicit migration;
  lost trade applicability blocks acceptance. Five-percent removal is an initial
  development review threshold, not an approved commercial policy. No identities
  or inventory are automatically merged or repaired.
- `input_contract.py` rejects duplicate JSON keys, unknown/private fields,
  overlapping/invalid symmetry declarations, malformed Unicode, unbounded fields,
  unsupported statuses and self-asserted verification before output creation.
- `sqlite_policy.py` independently verifies columns and foreign-key declarations,
  not only SQLite's foreign_key_check. A deliberately removed constraint allowed
  that basic check to pass; the new schema contract rejected the corrupt artifact.
- Actual inch/mm lengths normalize exactly; nominal dimensions never receive an
  arithmetic conversion. Literal independently specified metric cases demonstrate
  equivalence, distinction and detection of disguised external duplicates.
- Targeted validator-code mutations now cover five rules, all five detected after
  passing baselines. Report: build/catalog_engine/mutations-scope-schema.json.

The 100,000-identity synthetic volume run completed on HP: generation 7.744 s,
validation 3.727 s, SQLite artifact 124,194,816 bytes, input 26,979,523 bytes, peak
process working set 327,802,880 bytes. All explicit development-tool budgets
passed. Fictional insulation labels are deliberately used for unique stress
identities; they are NOT manufacturer offerings or factual catalog coverage.
Report: build/catalog_engine/stress-100000.json. Temporary stress data removed
by its owning temporary-directory context. App startup/search/UI/receipts and
network were not measured. Do not turn this into app performance acceptance.

Latest completed QA before the final dimension-boundary test: 41 tests passed,
21/110 paragraphs have some passing mapped evidence, 88 have no mapped tests,
zero fully verified requirements. Historical QA reports are retained under
build/catalog_engine/qa-*.json. A later run should include the new boundary test.

Read-only app inspection: receipt_item_parser.dart is structural text parsing,
not catalog identity recognition. Existing independent receipt example tests are
opt-in and skip without RECEIPT_EXAMPLE_LIBRARY. InventoryStockRecord currently
uses double quantity. These observations are audit leads, not completed parser
or inventory verification. No application source was changed in this continuation.

Remaining major work includes real family discovery/evidence, atomic requirement
mapping, declared variant generation, full pack integrity/install/recovery,
actual app SQLite inventory integration, catalog-aware parser behavior, security,
localization/search/UI, and independently verified release gating. Current
release_ready remains false; the full system remains in progress.

### Variant generation and discovery continuation

`variants.py` now expands explicit bounded rows into candidate identities through
existing declarative families. It does not compute a Cartesian product. Recipe
columns may change existing identity fields only, not evidence, provenance or
arbitrary object paths. Generator CLI accepts mutually exclusive --recipe and
--candidates. Original recipe bytes remain the recorded input fingerprint.
Tests prove two reversed runs collapse, a different branch remains distinct,
no undeclared variants appear, inputs remain unchanged, and malformed tables,
unsafe paths and excessive expansion are rejected. Source dictionaries use a
shallow probe to avoid repeatedly copying a growing candidate collection.

46 tests passed after variant implementation. Subsequent QA fingerprints now
include JSON definitions/fixtures as well as code and traceability, with a
before/after check to reject changed inputs during execution. New QA run pending.

Initial real-family discovery is recorded in
PLUMBING_FAMILY_DISCOVERY_2026_09_18.md. One primary manufacturer row was inspected
for an existence fact only; page content was not imported and no product was
promoted. A copper dimensional-reference retrieval failed and is marked a lead,
not verified evidence. Remaining physical semantics and source review are open.

Continue the active goal; no completion or pause has been recorded.

Latest retained verification: qa-continuous-goal-01.json reports 46 passing tests,
unchanged input fingerprints, 22 paragraphs with partial passing evidence,
87 without mapped tests, and zero fully verified paragraphs. The separate
mutations-continuous-goal-01.json detected 5/5 targeted disabled validator rules.

Next continuation should prioritize an atomic rule/evidence registry and a
verified family schema beyond the deliberately minimal fixture definitions,
then pack installation/recovery and the app integration contract. Read-only audit
found actual stock held in prototype_operations_store.dart's in-memory list;
existing catalog database loader materializes every item before returning trades.
Do not report those app behaviors as repaired by development-tool tests.

## Continued goal turn: manifests and release evidence gates

Previous turn classified as progress: generator, validator, tests, reports and
research records changed authoritative state. Goal remains active; no blocker
has prevented meaningful work. No delegation or app/live-data writes.

Implemented `release_gate.py` and tests: exact artifact and source binding,
missing tier/check rejection, full declared subject accounting, rejection of
skipped/unknown/failed evidence, duplicate/conflicting report rejection, unresolved
review rejection, requirement links and deterministic ordering. These checks
assume authenticated CI evidence at their input boundary; reports are not signed
and cannot themselves establish publisher authenticity.

`acceptance/release_policy.json` declares 20 mandatory groups with owner paragraph
links. It is explicitly draft. Pack-level subjects are placeholders for finer
coverage, not completed atomic traceability. `verify_release.py` runs the actual
validator and supplies only the structural evidence it performed. All other
checks remain absent. On candidates.sqlite it exited 1 with 20 blockers (19
missing gates plus draft policy). The detailed report is
build/catalog_engine/actual-release-assessment.json. Unknowns have not become passes.

`manifest.py` creates and independently verifies staging artifact identity,
byte size, schema/version, input fingerprints, counts and source IDs. It rejects
path escapes, extra fields, malformed sizes, truncated/corrupted bytes, forged
metadata and publication claims. Integrity is not signature authentication.
The actual candidates.manifest.json was written beside candidates.sqlite and
verified. No pack was installed, published, uploaded or approved.

Validator now rejects private/unexpected fields inside source JSON and metadata,
not only extra SQLite tables/columns. Invalid or missing aliases fail structural
search prerequisites, which is not evidence that full search behavior works.

61 tests passed after these additions. Final source-fingerprinted QA is rerun
below this checkpoint after traceability mapping updates. Initial gate tests use
explicit hypothetical policies; only the integrated assessment reflects the
actual draft policy. Do not confuse those positive gate-unit tests with release.

Oversized 200,000-record synthetic stress run: generation 16.092 s, validation
8.770 s, artifact 248,672,256 bytes, inputs 54,179,513 bytes, process peak working
set 633,790,464 bytes. All development-tool budgets passed. Report:
build/catalog_engine/stress-200000.json. Data is deliberately fictional and was
removed from its owned temporary directory. It does not establish app startup,
search/UI, inventory, network, or real-family factual performance.

New failure modes covered: metadata hiding private fields, constraints removed
from otherwise healthy SQLite, stale green reports, a skipped release tier,
partial subject coverage, conflicting evidence overwritten, a hash mistaken for
a publisher signature, and manifest counts diverging from actual database rows.

Next priority remains real-family schema/evidence and atomic rule mapping, then
actual app storage/parser integration and transactional installation/recovery.
Release, signing, real-product verification, and app-level tests remain unfinished.

## Actual process exercise requested by owner

Owner clarified that the generator must actually create output during development,
not merely pass synthetic assertions. Added exercise_pipeline.py: no generator or
validator imports; invokes real CLI processes, closes generation before validation,
reads completed SQLite rows with independent literal owner tee expectations,
retains generated-items.json and all artifacts. Four damaged copies must produce
specific duplicate/orphan/missing-evidence/missing-family diagnoses and nonzero
exits. Read-only validation is checked by before/after hashes. Release must fail.

Run pipeline-proof-20260918-01 failed due to an incorrect working-directory path
in the new driver. Fixed the path; retained that failure evidence. Run
build/catalog_engine/pipeline-proof-20260918-02 completed successfully: actual
five-item SQLite artifact, three expected tee identities, four diagnosed defects,
and blocked release. This still uses authored engineering examples, NOT externally
verified production products. The owner's request for actual product validation
remains broader than this operational proof and is unfinished.

Earlier Dart work also needs continuation: added SQLite inventory ledger with exact
quantities, revisions, idempotent events and atomic stock changes using the existing
LocalRecordStore. Eight initial tests passed, including restart and induced save
failure rollback. Later transfer/concurrency tests were interrupted; inspect and
rerun before claiming them. UI/vehicle-profile/permission integration is unfinished.
Full analyzer had unrelated existing errors; no claim of a green app build.

## September 19 continuation: inventory, receipts and whole-app review

Latest owner scope supersedes catalog-first work: catalog expansion deferred;
standalone inventory with CSV/spreadsheet intake, search, categories and purchase
cost history remains important. Whole-app consistency, durable persistence, OCR
and long-receipt capture/review are explicit priorities. Do not claim the rejected
bundled catalog has been replaced or removed; that requested work is unresolved.

Verified repairs and evidence:
- Receipt item parser now retains pending unpriced material descriptions before
  separators, tender and adjustment rows. New regression failed before the fix.
  Parser version is structural-items-v2; parser and parsed-panel suite: 19 passed.
- SQLite ledger suite: 11 passed, including transfers and concurrent replay.
  This ledger is still not connected to the inventory UI and vehicle profiles.
- Shared compact inventory list now has three columns at 800 local LP, four at
  1100 and one at 360. Four widget tests pass, including 2x text scaling reflow.
  No visual owner acceptance yet.
- Removed unused orphan materials_catalog_layout_calculator.dart; the active
  materials_inventory_layout_calculator.dart remains. Extracted layout result
  models to a part file to keep production Dart under 500 lines.
- Repaired isolated legacy parser test compilation (nonconstant fixture access
  and missing Flutter Color adapter). Five contract checks pass. These are not
  evidence of factual catalog accuracy or OCR accuracy.
- Additional six-file startup/lifecycle/receipt-review/image-preparation/recovery
  suite: 14 passed, log build/receipt-storage-audit-test.log.
- Analyzer now has no errors/warnings, but exits nonzero on seven informational
  lint findings. Do not call the full analyzer green.

Observed architecture: open_ui_lab_application opens durable LocalPersistence
and connects work, directory, workday, notes, expenses and receipt drafts. Durable
storage is not absent; integration, authorization and recovery require continued
review. Receipt evidence UI supports preview/order/removal and proposed OCR data.
Section reading handles regions of one image, not a complete overlapping-photo
long-receipt workflow. The owning receipt_material_intake_blueprint section 4
already documents the unfinished workflow and rejection of the old stitch engine.
Read-only 5.7 photo-review build uses a dominant photo surface, thumbnail strip and
separate review modes; inspecting that source is not rendered UI verification.

Device blocker: S24 Ultra connection succeeded, but replacement APK install was
rejected because the existing app's signing certificate differs. No uninstall or
data erasure occurred. Matching signing key remains required. Earlier APK predates
the latest repairs. No claim that the phone is running these changes.

Confirmed high-priority storage gap: inventory_screen.dart explicitly warns that
inventory changes are not saved after closing. PrototypeOperationsStore retains
inventory categories/stock in in-memory lists. The new ledger's isolated tests
do not fix that UI path. Connecting inventory to durable repositories and proving
real app restart recovery remains unfinished. Avoid describing all app persistence
as complete because other modules use SQLite.

Windows debug platform build passed (build/windows-audit-build.log). This proves
compilation, not rendered UI quality, long-receipt completion or owner acceptance.
