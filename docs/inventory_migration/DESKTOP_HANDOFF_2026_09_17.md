# Desktop handoff: catalog, inventory, receipt parser and QA

Prepared September 17, 2026 from this task's conversation and bounded source inspection.
This is an **unfinished-work transfer**, not release certification. Read this first.
The owner requested this handoff and subsequently authorized a GitHub commit/push.
Only documentation and transfer preparation are authorized in this handoff turn;
no application edits, builds, tests, device interaction or parser work were resumed.

Transfer branch: `codex/desktop-inventory-handoff-20260917` on the existing origin.
This is a separate WIP branch; main is not being merged or marked release-ready.
Generated `output/pdf/` previews and local `.gradle` caches are left on the Mac,
not included in this transfer. A bounded credential-pattern scan reported no hits;
that is not a comprehensive security audit. Git's whitespace check reports existing
trailing whitespace in `lib/src/screens/inventory/materials_inventory_tiles.dart:72`;
it is preserved with the unfinished code rather than silently fixed during handoff.

Paste this into the desktop task after obtaining the transfer branch:

> Continue the catalog/inventory/parser work from branch
> `codex/desktop-inventory-handoff-20260917` of `haftafish3760/UI-Lab-2.1`.
> First read `docs/inventory_migration/DESKTOP_HANDOFF_2026_09_17.md` completely
> and inspect the accompanying transfer manifest. Preserve any desktop local
> changes. Tell me what the current scope is, what is unfinished and what your
> first bounded step will be before editing. The snapshot is not a working release.
> Work only in UI Lab; 5.7 is protected read-only reference. Do not revive older
> all-trade or catalog-removal instructions or trust legacy passing tests.

## 1. Receiving task: start here

1. Read this entire document and the repository AGENTS.md. Explain the active scope,
   known blockers and first bounded step to the owner before editing. Do not make
   the owner repeat the conversation or decide routine engineering details.
2. Confirm the transfer branch/commit from the sending task's final message.
   This snapshot includes unfinished work from multiple tasks. Never reset/clean
   a desktop checkout containing local work to make it match. Inspect first.
3. Read `docs/ui_foundation_blueprint.md`, `docs/maintainiac_app_blueprint.md`,
   `docs/product_control_blueprint.md`, `docs/operations_screen_blueprint.md`,
   `docs/work_lifecycle_blueprint.md`, `docs/receipt_material_intake_blueprint.md`,
   `docs/inventory_rebuild_plan.md` and existing migration documentation.
   Current owner corrections below override conflicting older scope statements.
4. Inventory the actual received source, tools and dependencies. Do not assume
   Mac absolute paths, ignored build files, SDKs, screenshots or /tmp logs exist
   on Windows. The protected 5.7 checkout is not transferred by this repo push.
5. Repair the interrupted layout API mismatch as a bounded prerequisite once
   implementation resumes; then proceed catalog-first. Do not silently launch
   the full suite or rebuild the parser before assessing its dependencies.

## 2. Authority and scope — latest owner direction

The product name stated by the owner in this conversation is **Tame Your Biz**.
Repository and older contracts still say Maintainiac. Do not rename the app as
part of this handoff. The audience is small businesses generally; trades are
an initial target, not the only users. Vehicles must not be mandatory for all inventory.

| Topic | Current direction | Superseded or not authorized |
| --- | --- | --- |
| Editable app | UI Lab 2.1, Mac path `/Volumes/AppleWork/UI-Lab-2.1` | Editing/building 5.7 incidentally |
| Release-one catalog | Keep Plumbing, Electrical, HVAC; remove the other 18 from current catalog exposure | Delete all catalog; implement all 21 now |
| Sequence | Catalog first, beginning Plumbing → Fittings; inspect parser requirements early | Wait until huge parser is complete to establish item identities |
| Inventory | Catalog-to-inventory plus user-created items/categories/subcategories | A compulsory preloaded inventory or stock duplicated by trade |
| Parser | Assess 5.7, reuse sound components, repair/rebuild where evidence requires | Blind copy or an unconditional full rewrite without assessment |
| QA | Rebuild the complete trustworthy harness and independently check every item | Legacy green tests, sampling or counts as acceptance |
| Receipt generator | Separate application, preferably another Codex; independent expected answers | Shipping generator inside Tame Your Biz; spawning another agent here |
| Publication | Owner now explicitly requested commit/push for desktop continuation | Claiming a release, deployment, merged acceptance or validated build |

Earlier conversation reversals were real: remove catalog → simple inventory →
possibly no inventory → keep basic inventory → retain three catalogs for matching.
Do not replay an earlier deletion instruction. Older handoffs contain all-trades
scope and catalog-deferred banners; neither overrides the latest three-trade direction.
Owner accepts substantial time for accuracy, even months if needed. This is not
a fixed delivery estimate or permission to burn resources without measurement.

## 3. Working boundaries and communication

- 5.7 Active at `/Users/rbbie/Documents/Maintainiac_5.7_Active` is protected,
  read-only/copy-only evidence. Never edit, clean, reset, commit or build it
  without fresh bounded owner authorization. Older one-time device requests
  do not authorize future changes. Its docs were AI-written, not owner authority.
- Work in this task; no subagents or new tasks unless owner explicitly requests.
- During voice discussion, pauses are not the end of the user's turn. Do not
  interrupt, repeat filler such as “let me check,” or start tools/tests while
  they are still specifying requirements. Stop means stop.
- Screenshots require explicit authorization. Say whether evidence is source,
  a test render, or an actual device screenshot. Never pretend to see a screen.
- Investigate complete workflows before implementation; protect unrelated work.
  Another task has substantial persistence/recovery changes. Coordinate ownership
  before replacing its storage; do not build an independent competing database.
- Explain inspected, changed, tested, failed and unproven separately. A passing
  test or screenshot is not complete catalog correctness or owner acceptance.
- Jobs/templates/recurring scheduling and unrelated dashboard repairs are outside
  this catalog/parser assignment; another Codex was to handle them.

## 4. Catalog correctness and search requirements

- Every actual item in each retained trade must have an accountable identity,
  sensible hierarchy, full name, material/system, connection type, ordered sizes,
  units, aliases and provenance. Preserve all distinct legitimate parts.
- Account for every item and meaningful field in bounded batches. Record accepted,
  rejected, merged and unresolved entries with reasons and evidence. Do not call
  an unverified manufacturer's availability or a machine-generated flag verified.
- Avoid redundant categories: 5.7 showed Toilet Repair beside Closet Repair,
  and Plumbing → Service Truck Stock repeated Water Heater, Toilet Repair,
  Sink/Faucet-related groups already elsewhere. “Drain and Finish Service Stock”
  also overlapped drainage. Review contents and classify parts coherently rather
  than copying those buckets or inventing another parallel stock system.
- Exact shared parts can be found from Plumbing and HVAC while retaining ONE
  catalog identity and ONE stock balance per location. Trade routes are not
  duplicate stock. Similar size or material alone does not establish equivalence.
- 5.7 Galvanized Steel → Tees Expanded displayed 1,728 variants, including a
  systematic sequence of sizes from 1/8 through 4 inches. This suggests generated
  permutations; that is an inference, not proof every entry is invalid. Verify
  real fittings against appropriate product evidence, not a Cartesian matrix.
- Do not make people scroll thousands of tees. Proposed approach: a recognizable
  tee with labeled opening selectors and only supported catalog combinations,
  plus direct search. User-created custom items need not masquerade as verified
  manufacturer products. Tee dimensions use run × run × branch, with positions
  visible; not inlet/outlet flow directions. Other shapes need their own schema.
- Search must reach exact items using names, aliases, abbreviations, sizes and
  part identifiers. Size matching must distinguish 1/2 from 1-1/2; connection
  ordering, material, system and merchant context matter. Alias search must not
  create duplicate items or silently merge incompatible fittings.
- Supplier wording includes large retailers and small independent supply houses.
  Codes can be merchant-specific. Do not scrape/copy retailer databases or assume
  barcode scanning supplies product descriptions without an authorized source.
- U.S. first, Canada also requested; English and Spanish important. Owner cannot
  validate foreign languages. Use defensible terminology evidence/review rather
  than claiming automated translations prove correctness. French exists in repo,
  but its complete release scope was not settled in this conversation.
- Language and measurement preferences must use shared settings. Nominal pipe
  designation, measured dimension, converted display and regional equivalent are
  different concepts. Never fabricate an interchangeable metric fitting through
  arithmetic conversion. Europe/Australia/New Zealand were future markets.

## 5. Catalog UI/UX requirements

- Default preference is compact grid; retain list option. Light and dark themes.
  The switch must be modest, not giant controls consuming the screen.
- Three columns when local logical width and accessibility text fit; two or one
  when needed. A last row with fewer cards is fine. Do not fabricate categories
  or stretch controls to fill rows. Desktop/tablet adapt meaningfully.
- Owner liked 5.7's compact colored gradient cards, but wanted larger titles
  centered horizontally and vertically instead of bottom-left.
- Full labels, no ellipsis, clipping or broken words; owner also said no wrapping.
  Long names at large text sizes may make those demands conflict with three
  columns: reflow columns first, never clamp system text or silently abbreviate.
  If an unsplittable label cannot fit even one column, present that specific
  unresolved behavior to the owner rather than pretending the constraint is solved.
- Full item description in each item card, e.g. size + material + 90° elbow,
  not just size with the fitting name visible only in the page header.
  Use degree symbols for 22.5°, 45°, 90° labels. Do not blindly rename technical
  angles based on an uncertain spoken example; verify terminology.
- Grid/list must apply down through sizes/items, not abruptly become a huge list.
  Exact item detail provides Add. Keep top-left Back and correct one-level
  Android Back/iOS swipe behavior, search context and scroll restoration.
- Subtle screen transitions were requested; respect reduced-motion settings.
- Show trade choices promptly without waiting for all catalog data to decode;
  load/index appropriate branches and search data without blocked navigation.
- Release-one trade/category cards were originally text-only. Owner briefly
  requested two missing photos, later returned to liking text-only gradient
  reference. A later fitting diagram/generic tee picture was separately discussed.
  Do not treat that as approval for thousands of product images. Artwork choice
  remains a narrow review issue, not permission to generate a whole image catalog.
- Materials helper text requested: “Choose a trade, find your item, add it to
  your inventory.” Remove patronizing “start with items you already have / without
  a receipt” paragraph. Preserve required behavior without unnecessary helper copy.
- Use AppTheme/AppLayoutEngine/shared components, not private global breakpoints.
  See governing blueprints for color, bounded desktop lanes, permissions and settings.

## 6. User inventory, purchasing, documents and labels

- Support user-created category/trade → subcategory → further subcategories →
  actual item. Make Add category versus Add item explicit; allow multiple sibling
  entries and repeated item entry without navigating from the root each time.
- Item form: identity/name, aliases (“Other names”), optional part number,
  ordered/labeled sizes (at least three or four; do not hard-limit a tee schema
  onto every part), stock unit, quantity, location and optional purchase details.
- Quantity must be directly typable as well as plus/minus. Ask how many remain
  now; purchasing three cases does not mean three full cases remain.
- Cost can be per item, per package/case or total with explicit package count
  and pieces per package. Preserve purchase history and derive per-piece cost
  only when sufficient information exists. Unknown cost is not zero.
- Supplier/date/receipt can be unknown; a receipt must not be required for manual
  stock entry. Separate purchase quantity from present on-hand quantity.
- Locations include individual vehicles, shop/storage and optionally bins.
  Company overview sums the same underlying location counts. Viewing another
  location must not silently change the active work vehicle.
- User wants Add from Inventory in estimates/quotes/invoices/jobs. Use existing
  inventory identity and copy selected quantity/unit/cost/provenance into an
  appropriate document line snapshot; preserve history if inventory later changes.
  Selection itself must not silently consume stock. Reservation/consumption timing
  and cost valuation policy require existing lifecycle inspection and an explicit
  product decision if not established. Do not invent FIFO, average cost or reserves.
- CSV/Excel import requested to avoid manual initial entry, including location
  and category hierarchy. Plain-language column questions, preview, error rows,
  confirmation, durable save and repeated-import protection. Arbitrary spreadsheets
  cannot be promised automatic perfect interpretation. Cells need parsing, not OCR.
  Photo/chart import needs OCR and separate validation; not yet implemented.
- Printable internal barcode/QR per item and bulk labels requested. Labels should
  include readable material/name, size and all fitting connections, not just code.
  Stable IDs link codes to records; internal codes are not retail-issued UPCs.
- Owner wants a tee/elbow illustration that actually resembles the fitting and
  displays entered sizes beside the proper opening, potentially on labels and
  in-app. Vector/diagram was recommended; no diagram/label system implemented.
- Offline operation, SQLite/Drift durability, draft recovery, permissions, atomic
  stock/cost/receipt changes, safe retry and audit history need actual verification.
  Never present the current prototype's in-memory data as durable business records.

## 7. Parser, expenses and independent harness

- Read 5.7 parser documentation before deciding replacement scope. Catalog and
  inventory contracts inform matching, but navigation category strings must not
  become permanent item identity. OCR extraction and matching are distinct stages.
- Receipt output feeds BOTH expenses and inventory. Preserve source image/text
  regions, merchant, receipt identity, parser version, line description, size,
  package interpretation, quantity/unit, prices, discounts/taxes as applicable,
  proposed item and uncertainty. Never infer missing package details as fact.
- AI/OCR/parser output remains a proposal until authorized human confirmation.
  Unmatched/ambiguous lines require resolution; no silent wrong-item stock updates.
  A catalog alone does not guarantee matching unknown supplier abbreviations.
- Review existing implementations for useful parts, but rebuild acceptance and
  regression evidence independently. Legacy harness/report success is not truth.
  A reported old audit checked report existence; another defaulted to sampled,
  non-strict smoke checks. Verify the precise assertions before reusing any test.
- Complete item population checks must be complemented by independent expected
  answers, deliberate wrong sizes/materials/aliases, near matches, missing items,
  OCR corruption, wrapped lines, package/quantity ambiguity and unfamiliar merchants.
- Include arithmetic, currency rounding, duplicate receipts/submissions, failed
  writes, interrupted import, restart recovery, stale edits, permission changes,
  offline behavior and end-to-end expense/inventory/document links.
- Separate synthetic receipt generator app, separate answer files. Never feed
  expected answers into parser inference. Avoid shared generation/matching logic
  that makes the parser pass its own assumptions. Generator is not part of release.
  Owner preferred another Codex; sender recommended this for independent testing.
- Real representative receipts held out from tuning are needed for real-world
  performance claims. Synthetic tests alone cannot establish an honest accuracy %.
  Measure exact item/variant, quantities/packages, money and whole-receipt success
  separately, including abstentions and confident wrong matches. No current measured
  accuracy or release-ready threshold is established by this handoff. An older doc
  says 90–95%; do not treat that as a newly agreed gate or achieved result.
- Keep fixtures with source/provenance, test identifiers, expected result rationale
  and reproducible commands. Every catalog record must map to evidence or an
  explicit unresolved status. Count agreement is migration fidelity, not semantics.

## 8. Cloud packs and resources

Owner wants large catalogs hosted through Firebase rather than shipping a giant
mandatory catalog. Earlier all-21 downloadable plan is superseded by three-trade
current work, not authorization to discard offline requirements. Exact bundled
starter size versus downloadable three-trade content still needs reconciliation.
Account-created users may download; “verified” meant account ownership, not identity
documents. Account/device download limits, successful local verification, interrupted
download resume, checksums/versioned manifests and offline retained packs requested.
Auth, App Check or a client flag alone is not a complete quota/authorization system.
No pack service or rate limiting is implemented in this task.

Mac Mini M2 has 8 GB RAM, often near pressure before tests. HP ProDesk 600 G6 has
i5-10500 and 48 GB; laptop has 32 GB. Desktop was recommended for large test batches,
Mac for Apple-platform verification. More RAM is headroom, not a promise that using
all RAM speeds tests. Start bounded concurrency and measure before increasing it.
At most one emulator on Mac; physical devices preferred when authorized. Stop only
task-owned idle build workers after confirming no active build; never kill all Java
or Node or the Maintainiac bridge. No emulators/tests/builds during this handoff.

## 9. Current implementation — live observations and inherited evidence

Handoff inspection found branch `main`, base HEAD
`98d240558df1c9de4044a894fd22810bf167bf81`, origin
`https://github.com/haftafish3760/UI-Lab-2.1.git`. Transfer commit will differ.
See adjacent `desktop_transfer_manifest_2026_09_17.json` for changed-file hashes
and exclusions. Much storage/expense/document work belongs to other tasks;
snapshot inclusion is preservation, not an assertion this task authored/verified it.

### Confirmed source blockers on September 17 (no tests run)

- `lib/src/layout/app_layout_engine.dart` now declares `materialsInventoryFor`
  and includes `materials_inventory_layout_calculator.dart`, but catalog tiles
  and `test/materials_catalog_review_test.dart` still call `materialsCatalogFor`.
  This interrupted rename is inconsistent and expected to break compilation.
  It was NOT repaired during handoff. Do not represent this snapshot as runnable.
- `materials_trade_manifest.dart` still lists 21 trade names and three bundled
  names. Latest removal of other 18 has NOT been implemented.
- `inventory_catalog.dart` still loads the bundled SQLite bytes and decodes via
  compute before returning catalog. Prompt root loading has NOT been delivered.
- New `InventoryCategoryRecord`, `InventoryItemSize` and stock optional fields
  (category, aliases, sizes, part number, cost, currency) exist. Prototype store
  has in-memory category addition; this is NOT durable SQLite inventory.
- `inventory_item_entry_screen.dart` is a new unfinished form with dynamic sizes,
  aliases, location, quantity/cost and Add another. It is unformatted/untested and
  not yet connected as a complete workflow. Currency is USD-defaulted, quantity
  stepper and durable draft/persistence are not complete. Do not ship it as-is.
- `materials_inventory_tiles.dart` and inventory layout calculator were copied
  during the since-reversed catalog-removal direction. Assess/reconcile duplication.
- Existing Work uses `TruckStockSourcePicker(stock: store.inventoryStock)`;
  inspect authorization filtering before reuse. Existing wording is “Use truck
  stock.” Requested universal Add from Inventory and estimate integration are
  NOT implemented by this task. Quotes lifecycle is not established here.

### Prior task evidence — not rerun or newly accepted

- Bundled catalog review was only eight copper solder 90° elbow records, not
  complete Plumbing, Electrical or HVAC. Batch tool:
  `tool/materials/materials_copper_review_batch.dart`; review JSON:
  `docs/inventory_migration/materials_copper_review_001.json`; asset:
  `assets/inventory/browse_batch.sqlite`. Recount on receipt; no semantic approval.
- Catalog work includes centered tile primitives, fractional sorting, degree labels,
  EN/ES/FR limited labels, detail route/Add and platform navigation tests. Search,
  metric handling, complete localization and performance remain unproven/incomplete.
- Owner rejected previous rendered oversized grid/list controls and size-only item
  tiles. Old screenshots are not owner acceptance. Some title rendering used test
  fonts; inspect preview portability before using it as device evidence.
- Earlier bounded runs reportedly passed 59 focused tests and 40 render/platform
  tests at earlier states. Those counts are historical conversation evidence only;
  they do not validate this commit or the later manual-inventory/layout changes.
  Old baseline 19/24 passes with five failures concerned an empty asset versus
  historical 49-record expectations, not a complete catalog census.
- `/tmp/materials-*.log`, `/tmp/s24-*.png` and `build/materials_review/` were local
  ephemeral evidence. Not transferred or rerun here. Do not require them to build.
- Two optional images were generated outside repo for Appliance and Cabinets,
  not integrated; not transferred. Existing tracked trade artwork remains.
- `tool/inventory/legacy_reference/` and its manifest are captured source evidence,
  not accepted production modules. Earlier tests imported ignored build paths;
  check clean-checkout portability and avoid silently requiring those artifacts.

## 10. Read-only parser reference starting points

Under the protected 5.7 `docs/` directory, these paths were located during handoff;
their contents were NOT freshly audited in this turn:

- `reusable_parsing_qa_handoff_index.md`
- `reusable_parsing_qa_scope_boundary.md`
- `inventory_parser_peh_core_roadmap.md`
- `inventory_parser_plumbing_core_roadmap.md`
- `inventory_parser_electrical_core_roadmap.md`
- `inventory_parser_hvac_core_mac_handoff.md`
- `inventory_parser_qa_harness_plan.md`
- `inventory_parser_qa_harness_contract_completion_checklist.md`
- `inventory_parser_qa_master_coverage_matrix.md`
- `inventory_parser_release1_acceptance_scorecard.md`
- `work_supply_peh_catalog_coverage_audit.md`
- `qa/work_supply_core_parser_handoff.md`

UI Lab existing `docs/inventory_migration/`, `docs/receipt_material_intake_blueprint.md`,
`tooling/inventory_qa/` and captured legacy code are starting evidence, not substitutes
for reading actual dependencies. On Windows locate the protected reference or request
its transfer; do not pretend this GitHub push includes the entire 5.7 app and docs.

## 11. Device and transfer facts

- Owner used S24 Ultra SM-S928U for 5.7 catalog reference screenshots. Those were
  NOT UI Lab 2.1 screenshots. S25 Ultra SM-S938U was also connected at times.
- ADB network endpoints change; rediscover and verify model/serial before action.
- Owner requested SSD eject. Normal eject was blocked by Android ADB PID 43754;
  sender stopped ADB server and macOS reported `Disk disk6 ejected`. Owner then
  reconnected drive. The project path was readable again during this handoff.
- AppleWork was APFS on inspection. Do not assume native Windows access to this
  volume; use the verified GitHub transfer for source. Do not format the SSD.
- A Git commit transfers tracked/staged source, not ignored build caches, live
  databases, SDKs, secrets, external generated images or protected 5.7. Preserve
  desktop local work; fetch the named branch and compare before checkout/merge.

## 12. Receipt checklist for the receiving agent

- [ ] Read latest scope, superseded directions, governing contracts and all blockers.
- [ ] Confirm exact remote commit and transfer manifest; preserve desktop local edits.
- [ ] Report understanding: three trades, catalog first, new independent QA, parser
      also feeds expenses, generator separate, no legacy success accepted blindly.
- [ ] Locate protected reference without modifying it; identify missing external inputs.
- [ ] Repair interrupted source inconsistency only when work resumes; run bounded
      analysis/tests and report remaining errors before claiming a working baseline.
- [ ] Independently census all retained records and duplicates; no count-only acceptance.
- [ ] Review one Plumbing/Fittings UI slice with full labels and actual rendered evidence.
- [ ] Assess parser reuse and persistence/document boundaries before deeper integration.
- [ ] Build independent item/e2e harness and report unresolved evidence, not invented passes.
- [ ] Obtain held-out real receipt evidence before real-world accuracy claims.

This handoff was checked against the available conversation and current targeted
source observations. It is not a verbatim transcript or a guarantee no historical
detail was lost; unresolved issues are deliberately surfaced instead of guessed.
