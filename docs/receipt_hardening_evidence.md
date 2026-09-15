# Receipt hardening: implementation evidence

Updated September 15, 2026. This is a status record, not product acceptance.
Requirements are owned by `receipt_material_intake_blueprint.md`.

## September 15: opening receipt screens checkpoint

This pass is Expenses only; inventory and inventory parsing are assigned elsewhere.
The first page is detail choice plus optional category and Continue. The second
page is the two-by-two source grid. Expense home keeps its FAB and only daily/weekly
recap cards. Shared light/dark themes and bounded form widths are retained.

Verification: `build/receipt_flow_final_tests.log` records 53 passing focused tests
across entry navigation, categories, SQLite reopen, existing expense confirmation,
permissions, linked receipt routes, native media recovery and screen rendering.
`build/receipt_flow_analysis_final.log` records no analyzer issues. The gallery
regression verifies that changed setup, picker cancellation and restart preserve
the same receipt, photo and detail choice. Existing PDF media recovery remains
tested without enabling the deferred PDF-import card. No PDF engine was changed.

Rendered light/dark phone and desktop review images are under
`build/receipt-flow-review/`, generated with `tool/receipt_flow_render.dart`.
The render helper resolves the test font fallback to Roboto; these are Flutter
rendered review artifacts, not screenshots of the owner's phone or acceptance.

Still outstanding: first-use Expense assistance onboarding, the custom camera
overlay/brightness control, multi-photo long-receipt arrangement and stitching,
the revised image preview, completed pasted-text proposal handling, full fuel
parser/test-harness migration, and measured end-to-end OCR accuracy/performance.
These 53 tests do not demonstrate a 97-98% recognition accuracy rate.

## Implemented in the current working tree

- Add Expense and calendar-day entry show explained Total only / Items and total
  choices plus optional category, then Continue opens the two-by-two source grid.
  Manual details are reached from Paste/Text. Explicit new manual entry skips the unsolicited
  unfinished-expense dialog; existing draft recovery remains available.
- The 51 receipt-specific 5.7 category labels are represented by stable category
  IDs. Their stored Expense identity/label/amount survives SQLite reopen in
  `receipt_entry_setup_storage_test.dart`. Existing broader categories retain
  their IDs; the new picker avoids presenting them as competing classifications.
- Receipt setup metadata (category, detail choice, source text) survives SQLite
  reopen and unrelated receipt updates. Navigation tests exercise both themes,
  widths 320/700/1440 and 2x text scaling. These are behavior checks, not owner
  visual acceptance or recognition-accuracy measurements.
- Receipt preferences store assistance and detail defaults locally. Preference
  drafts preserve raw choices through restart and failed confirmation. Legacy
  preference baselines retain conflict checks for the newly introduced keys.
- Receipt intake no longer encloses every action in one decorated card or shows
  the old allocation checklist promising unconnected capabilities.
- Opted-in receipt reading starts when a photo is reviewed. Manual read remains
  explicit otherwise. Rebuilds do not duplicate a read; source changes invalidate
  old results. The existing shared device workload gate remains in effect.
- Structural proposals group aligned text/price blocks, preserve repeated item
  rows, and require unique labeled totals. Mismatching arithmetic is flagged.
  Merchant proposals use header structure rather than a merchant whitelist.
- Unambiguous calendar dates can be proposed. Ambiguous numeric dates, competing
  dates and invalid calendar dates are not silently resolved.
- Explicitly selected header suggestions prefill a new editable review. They
  neither commit an expense nor overwrite an existing expense. Previously saved
  review input takes precedence over new suggestions.
- Android long images use sequential overlapping native region copies instead
  of shrinking the whole long receipt. EXIF orientation is mapped to upright
  source coordinates. This implementation uses Android BitmapRegionDecoder and
  the existing ML Kit recognizer; it contains no 5.7 stitching code.
- Matching observations at the same source position are collapsed across
  sections; repeated purchased rows remain. Conflicting observations retain a
  visible warning. No partial result is returned after section failure/timeout.
- Shared workload conditions are refreshed between sections. A timeout stops
  future sections but retains the gate while an in-flight native read finishes.
- Ordinary-photo reads now check expiration before/after image description,
  between preparation stages and before/after recognition. Temporary copies are
  disposed after late native completion; the shared gate remains held through
  cleanup and recognizer closure. Section preparation also rechecks expiration
  after the asynchronous device-capability checkpoint.
- Simple receipts allow a blank merchant and start with No category. Expense and
  receipt-item category identities/labels persist as null; existing named
  categories remain unchanged. Revision history supports clearing/restoring a
  category. Blank-merchant display labels do not replace the stored blank value.
- Simple amount is nullable through expense confirmation, stored records,
  revisions, receipt submission and editor recovery. Explicit zero is distinct
  from missing; malformed records with an absent total key remain rejected.
  Day/week/month/year and category expense summaries omit unknown amounts from
  arithmetic and show missing-value context. Shared day/category total cards
  reflow long amount labels with accessibility text scaling.
- Receipt submission and private checkpoint/restore path construction now use
  native path separators on Windows. Historical alias keys are preserved while
  validating the full retained identity across separators. Resolved-file checks,
  traversal rejection, byte counts and content hashes remain enforced.

## Executed checks

- Receipt setting restart/failure and expense permission checks: 7 passed.
- Entry reflow at 320/700/1440 logical pixels with 2x text, structural proposals,
  settings and receipt draft bindings: 13 passed.
- Date, opt-in, stale-photo and structural proposal checks: 16 passed.
- New/existing expense suggestion handoff: 2 passed.
- Full analysis initially reported two style findings in date extraction. Both
  were corrected; focused analysis of date parsing, photo review and expense
  editor then reported no issues.
- The isolated Android QA build succeeded again with the date/auto-read and
  reviewed suggestion handoff changes. It was built with STORAGE_QA enabled;
  device installation and runtime acceptance remain unverified.
- The separate native Windows generator rebuilt after the fuel-layout correction.
- Section geometry, overlap conflicts/repeated items, device checkpoints,
  original/copy lifetime, timeout/native failure and existing photo review:
  26 focused checks passed in `build/receipt_sections_tests.log`.
- Focused analysis of receipt data and section tests found no issues. Full
  Flutter analysis also found no issues (`build/receipt_sections_full_analysis.log`).
  The final post-refactor Android STORAGE_QA build succeeded in 37.5 seconds
  (`build/receipt_sections_android_final_build.log`). It has not been installed
  or run on the S25: ADB reported no connected devices during this check.

Counts overlap; they must not be added into an independent sample count.

Optional header verification: 35 checks passed across SQLite restart/category
clearing/history, malformed-record rejection, uncategorized totals, repository,
itemization, authorized bridge, draft workflow and suggested-field handoff.
Six existing atomic/correction checks passed alongside the initial form run.
The new form test initially tapped before the scroll rendered; after synchronizing
and requiring the Save button to be hit-testable, it passed: entering only 24.50
saves blank merchant and No category. Logs are `receipt_optional_header_tests.log`
and `simple_expense_header_flow_retest.log` under `build/`. This is not physical
device or owner visual acceptance.

Final header checks: 6 entry/settings/form checks and 12 projection/permission
checks passed (`receipt_optional_header_ui_regressions.log` and
`receipt_optional_header_scope_tests.log`). Full analysis found no issues. The
Android STORAGE_QA build succeeded in 89.5 seconds. These logs are under `build/`;
the Windows app was not restarted, and no phone installation was performed.

## Additional expense and retention checks, September 15

The first optional-amount verification exposed Windows path-comparison failures:
valid retained files were rejected because constructed forward-slash paths were
compared literally with resolved native paths. Further restore checks exposed
the same assumption in checkpoint folders and historical reference aliases.
These were corrected rather than bypassing retained-location verification.
`build/receipt_retention_restore_final_test.log`: 38 checks passed, including
atomic receipt submission with an omitted amount, retries, same-length/truncated
corruption, redirected paths, restart and multiple local restore generations.
The attachment-byte fixtures in these tests are storage fixtures, not OCR images.

`build/optional_amount_workflow_regressions.log`: 26 checks passed and four
failed. Settings validation had omitted the new uncategorized choice; display
summaries still said Basic; the dashboard test requested a phone-only action at
a desktop test width. The codec/labels and explicit phone test dimensions were
corrected. All four checks then passed in
`build/optional_amount_settings_retest.log`. No dashboard production layout was
changed for this correction.

`build/receipt_amount_scope_sections_tests.log`: 27 checks passed covering
missing-amount rendering at 320/700/1440 logical pixels with 2x text, scoped
projections/permissions and existing OCR section handling. Amount-denied cards
also hide missing-amount status. These are regression checks, not OCR accuracy
samples or owner visual acceptance.

The SQLite demo-fixture tests initially ran without their required
`MAINTAINIAC_UI_LAB_DEMO_DATA=true` define, so no demo expenses were seeded.
With the explicit fixture flag, all four checks passed in
`build/expense_seed_sqlite_verification.log`. Production demo defaults were not
changed. Final full analysis found no issues
(`build/receipt_amount_final_analysis.log`).

The first Android build ended without a terminal result; its process handle and
workers were gone, so its output was not counted as a successful build. A fresh
isolated STORAGE_QA build then succeeded in 155.2 seconds
(`build/receipt_amount_android_rebuild.log`). The package was not installed:
ADB listed no connected devices. This proves compilation, not native OCR or
rendered phone acceptance. The Windows app was not launched or restarted.
Idle Gradle cleanup was verified afterward: zero Gradle/Kotlin build workers
remained.

## OCR expiration checks

OCR expiration verification: `build/receipt_expiry_lifetime_tests.log` contains
19 passing checks for ordinary-photo/section lifetimes, expiration before source
access, expiration during preparation and recognition, retained-original
preservation, coordinate mapping and shared workload exclusion during delayed
cleanup. The delayed-recognizer tests use fake observations and storage fixtures;
the image-preparation test uses a plain raster for pixel-budget verification.
None is an OCR accuracy sample or a realistic generated receipt.
The 20 receipt review/opt-in/stale-photo/field-proposal/section-overlap checks in
`build/receipt_expiry_review_regressions.log` also passed. Full analysis found no
issues (`build/receipt_expiry_analysis.log`, 153.3 seconds). These counts overlap
earlier suites and must not be represented as additional independent receipts.
The isolated STORAGE_QA ARM64 Android build succeeded in 116.6 seconds
(`build/receipt_expiry_android_build.log`). No installation or native OCR
accuracy run was performed. Existing build warnings report plugin Kotlin
compatibility work and untranslated messages; this slice does not establish
release readiness or modify the separate PDF engine.
After this build, targeted cleanup was verified with zero remaining
Gradle/Kotlin build workers. Source formatting and diff whitespace checks passed.

## Generator evidence and rejected output

The independent project is `C:\Users\noneya\Documents\Receipt Generator`.
No production parser/catalog/PDF/Firebase imports are used by its receipt model.
Its owned library caps saves at 100, serializes concurrent changes and exposes
individual/delete-all controls. Damaged/interrupted examples remain deletable.

The first automated 48-image export was invalid: Flutter test rendering used
Ahem placeholder rectangles. Inspection caught this after structural tests had
passed. The export now explicitly loads an installed font for local evaluation;
the OS font is not bundled or redistributed. The invalid images were replaced.

The next inspected fuel example was also rejected: it repeated fill-ups to make
a long receipt. Fuel generation now produces one purchase, labeled volume and
unit price, and one final total. Fuel no longer exposes a materials-length
choice. A corrected rendered fuel example was visually checked; this is not
owner visual acceptance. Long-receipt examples must use materials purchases.

The generator's 15 checks (including conditional corpus export) passed after
the fuel correction. Exported cases are local development artifacts, not a
validated OCR benchmark. Keep the review set small pending owner feedback.

## Outstanding work — no completion or accuracy claim

### Selected receipt details recovery — September 15

The evidence-review draft now stores explicitly selected header suggestions with
their evidence ID and SHA-256, nullable values, recognized rows and warnings.
The atomic evidence-review command carries this selection into the retained
receipt while consuming the review draft. This covers closing before Continue
and closing after Continue but before an expense editor has opened. New expense
review input can be seeded from that retained selection; existing saved expense
input still wins. No expense, stock movement or approval is created by selecting
details. Removed/mismatched source images cannot supply the next form's values.

Reuse assessment: 5.7 Active's read-only
`expense_receipt_entry_draft_actions.dart` persists raw OCR/review and handoff
state with its unfinished receipt. Preserve that recovery behavior using UI
Lab's existing SQLite draft and evidence transaction, rather than porting its
Hive record or stitcher. Full recognition history and source-region provenance
remain outside this implemented header-selection slice.

Verification:

- `build/receipt_selected_details_acceptance_checks.log`: eight automated checks
  passed, covering SQLite reopen on both sides of the handoff, failed transaction
  rollback/retry, clear/removal/undo, two same-byte evidence identities, wrong
  checksum rejection at the command boundary, malformed payloads and recovered
  form values at 390 and 1400 logical pixels. The filename does not imply owner
  visual acceptance or OCR accuracy.
- `build/receipt_selected_details_regressions.log`: 25 passed and two failed in
  that earlier run. The existing atomic order-only command fixture exposed an
  unnecessarily strict selection check; the command now decodes only the new
  optional suggestion metadata while retaining its prior order contract. The
  other failure was Windows image-fixture cleanup. Both are covered by the final
  eight-check run above. Repository, submission and receipt-review regressions
  in that earlier run passed.
- The extended widget test initially hung after disposing the expense editor.
  Diagnostic markers localized this to test cleanup. The project helper that
  advances native I/O and Flutter's test clock resolved it. The test also needed
  to expect the revision produced by the additional explicit Continue action.
- The old one-pixel fixture had an invalid PNG IDAT checksum. The two touched
  recovery tests now use an existing checksum-valid two-pixel fixture; handoff
  waits for a decoded preview before deleting its temporary directory. These
  images are storage/UI fixtures, not generated receipts or OCR benchmarks.
- `build/receipt_selected_details_final_analysis.log`: no issues found.
- ADB currently lists only the unapproved S24 (USB and wireless); the S25 is
  unavailable. No device was installed, launched, reconfigured or tested.

- `build/receipt_selected_details_android_build.log`: ARM64 debug build with
  `STORAGE_QA=true` passed in 81.2 seconds. No installation or app launch occurred.
  Existing plugin Kotlin compatibility warnings remain; no PDF or Firebase
  plugin changes were made for this slice.
- Build cleanup verified zero remaining Gradle/Kotlin daemons. Gradle reported
  stopping its worker, but PID 10384 lingered; its exact command line was checked,
  that task-owned process was terminated, and a follow-up inventory was empty.

### Item-parser foundation — September 15

Read-only reuse assessment inspected 5.7 Active's parser part index,
`expense_receipt_parser_line_item_logic.dart` and
`expense_receipt_parser_quantity_logic.dart`. Preserve their distinction between
wrapped descriptions, money summaries, fuel facts and catalog matches. Do not
carry over inferred quantity-one/default-unit behavior, double arithmetic or
merchant-profile dependence into stock-facing proposals. No 5.7 source changed.

`receipt_item_parser.dart` now produces review candidates with source row identity
and OCR boxes, explicit quantities and purchase units where printed, exact
decimal unit prices, printed line amounts and separately calculated amounts.
Repeated purchase rows remain separate. Package-description numbers do not imply
purchase quantities or contained pieces. Discounts, returns, missing quantity,
ambiguous money columns and fuel-unit conflicts cannot silently become stock.
This is a parser foundation; it is not connected to the editable line-review,
durable item-proposal history, catalog classification or stock transaction paths.

`receipt_reading_rows.dart` is the shared reading-order implementation for both
header and item parsing; the former header-only grouping behavior was moved
without changing its geometry tolerance. Source lines stay attached to item rows.

Independent evaluation reads only the two existing native-generator folders
`example-62a1c6fa` and `example-599fc6be`: their `printed.txt` input and separately
stored `answers/expected.json`. No generator code is imported into production and
no expected answers are inputs to the parser. All five material lines matched
description, quantity, purchase unit, unit price, calculated and printed amounts.
The fuel candidate matched description, measured volume, purchase unit, unit
price and calculated amount; its printed line amount stays null because only a
receipt total is present. These are two synthetic text cases, not image OCR,
held-out accuracy or evidence that every receipt format works.

The first edge-case run found a mismatched fuel-volume row falling through to the
generic amount parser. That path was corrected to preserve the row as unresolved.
`build/receipt_item_characterization_verified.log` then passed 19 checks,
including existing header parsing, numeric limits, fractional fuel prices,
half-cent rounding, receipt summaries, adjustment exclusions and 1,500 repeated
text purchases. This count is tests, not independent receipts or physical-device
performance evidence. Final rules also preserve trade descriptions such as
terminal strip, return-air grille, pump and tip cleaner rather than excluding
them based on a leading keyword. No synthetic-marker special cases remain.
`build/receipt_item_trade_name_regressions.log` passed 32 tests, including the
two independent text cases, header proposals, photo-read behavior and selected
header recovery. The generator library was read only; no new receipts were made.
The final trade-name fixture check passed after correcting its displayed receipt
total (`build/receipt_item_trade_fixture_check.log`). Final Flutter analysis is
clean (`build/receipt_item_final_analysis.log`); production files added or moved
in this slice are 37–232 lines. The ARM64 offline QA debug build passed in 79.9
seconds (`build/receipt_item_android_build.log`). No app was installed or launched.
The S25 remains unavailable; ADB lists only the S24, which was not used.
Cleanup verified no Gradle/Kotlin workers remained after the task-owned idle
Gradle PID 7916 lingered after `--stop` and was explicitly terminated.

### September 15: manual item facts and calculation corrections

The manual item editor previously defaulted unknown package contents to one,
while its UI/domain adapter restored absent SQLite contents as one. That could
invent a per-piece cost. The nullable value now survives editor save, draft
serialization and SQLite close/reopen; an explicitly recorded one is retained
as a known fact. Receipt retries compare count-package contents, while ignoring
legacy each-unit defaults that were never stored as package facts.

Reopening a quantity no longer rounds six accepted decimal places down to two.
The 320-LP/2x-text widget check exposed a 9.1-LP Sold-as dropdown overflow, fixed
by allowing the control to use its available width and grow its option height.
The item form's decorated outer card was removed to follow the existing owning
blueprint; its AppLayoutEngine form-width bound remains.

A second defect accepted grouped quantities such as `1,000` but calculated
them as zero. Calculation now normalizes the accepted grouping and multiplies
decimal values using integer arithmetic, rounding the extended amount once.
Tests include 1,000 at 15.00, 2.5 at 1,234.56, the half-cent boundary 1.005 at
1.00, six-decimal quantities, invalid input and oversized results. An oversized
total cannot be saved, and an incomplete calculation is shown as incomplete.
This still uses the existing cents-only manual unit-price contract; fuel prices
with fractional cents require a separate persistence/editor change.

`build/expense_package_contents_final_tests.log` passed 30 tests after the
dropdown correction. `build/expense_review_quantity_regressions.log` passed 34
after the calculation change. The earlier failing logs are retained, including
the initial SQLite test organization mismatch (the test was corrected; the
production organization-scope guard was preserved) and the accessibility
overflow. The first final-check command referenced a nonexistent draft-test
filename; the corrected `build/expense_review_package_verified.log` passed all
35 checks, including actual unfinished-line recovery through SQLite reopen.
Final Flutter analysis is clean (`build/expense_review_package_analysis.log`).
The ARM64 local-only QA debug APK built successfully in 92.4 seconds
(`build/expense_review_package_android_build.log`); it was not installed. The
build reports an existing future Kotlin-plugin compatibility warning for
firebase_auth, firebase_core and pdfx; those dependencies were not changed.
Cleanup confirmed zero Gradle/Kotlin workers after stopping the build daemon
and its lingering task-owned worker processes 8844 and 10800.
The touched production Dart files remain below 500 lines. No generator receipts
were changed or added, and no app was launched.

### September 15: existing generator image inspection

The agent opened the existing `receipt.png` artifacts for `example-62a1c6fa`
and `example-599fc6be`, without generating replacements. The material image has
five purchase rows, subtotal 83.26, tax 5.83 and one final total 89.09 USD. The
fuel image has one purchase, 16.810 gallons at 3.49 and one total 58.67 USD.
Both have readable lettering and explicitly synthetic labeling. This is a
two-image agent inspection, not owner visual acceptance or OCR accuracy proof.

Read-only generator inspection found the tilted condition rotates only 0.008
radians (about 0.46 degrees). Folded/wrinkled conditions paint crease shadows and
highlights over the image; they do not deform the printed text or model paper
occlusion. These conditions must not be described as comprehensive camera/skew
or physical fold coverage. Their names alone do not make a difficult dataset.
The owner review limit remains: keep the library unchanged rather than expand
these examples into a large benchmark before reviewing their quality.

Current ADB inventory contains only two wireless entries for the S24 model
SM_S928U. No S25 is available; no physical receipt-flow test was attempted and
no network/debugging setting changed.

### September 15: fractional unit prices through reviewed expense storage

The preceding manual-editor checkpoint's cents-only unit-price limitation is
now addressed. `ExpenseUnitPrice` retains up to six decimal places separately
from final charged `ExpenseMoney` cents. Existing cents-only unit-price JSON
continues to serialize in its old shape. Fractional prices use an explicit
decimal value; mixed or malformed representations are rejected. This supports
reading existing records; it is not a claim that an older app binary can read
new fractional-price records.

The reviewed UI/domain adapter, editor, item descriptions, saved on-screen
receipt and draft codec retain the unit price. The line calculator multiplies
all quantity and price digits with integer arithmetic, rounding only the line
amount. A recorded zero unit price is allowed, while blank remains incomplete.
Receipt retries compare the actual price instead of comparing rounded cents.
Decimal quantities were extracted into their own cohesive file and now reject
integer overflow rather than wrapping during scaled multiplication. The UI
quantity/unit-price bounds are below one billion with up to six decimals, so
the existing double-valued UI bridge can round-trip those digits.

Read-only 5.7 quantity inspection again found double parsing and default-one
fuel quantities. Those defaults were not imported. Tests use independently
specified arithmetic, including 16.810 gallons at 3.499 -> 58.82 and at 3.491
-> 58.68. SQLite verification closes/reopens storage after a correction and
checks the current 3.491 price and prior 3.499123 price with their separate
totals and actor history. Compatibility, malformed input, explicit zero and
same-cent retry conflicts are also checked.

`build/expense_unit_price_initial_regressions.log` passed 28 checks;
`build/expense_unit_price_precision_checks.log` passed seven dedicated checks;
`build/expense_fractional_price_workflow_regressions.log` passed 66, including
the receipt parser, manual form, package facts, item recovery and save retry.
`build/expense_unit_price_recovery_bounds.log` passed eight checks, including
unfinished nested-item recovery at both 3.25 and 3.251234 through database
close/reopen and final parent expense save. The maximum six-decimal UI boundary
is also exercised. `build/expense_unit_price_serialization_limits.log` passed
12 checks after extending serialization to retain large valid decimal prices
without overflowing the legacy cents representation.
Final Flutter analysis is clean (`build/expense_unit_price_final_analysis.log`).
The ARM64 STORAGE_QA debug build passed in 95.0 seconds
(`build/expense_fractional_price_android_build.log`). The existing future KGP
compatibility warning remains; no dependency migration was attempted. No app
was installed or launched. All changed production Dart files stay below 500
lines; the largest is `expense_workflow_models.dart` at 476 lines.
Cleanup verified zero Gradle/Kotlin workers after normal daemon stop and
termination of the lingering task-owned Gradle PID 22092.
No generator receipts, Firebase operations, PDF implementation, phone settings,
or other-model Work/dashboard code changed in this slice. Item-proposal handoff
and reviewed stock adoption remain unfinished.

### Remaining requirements (ongoing)

- Optional Simple merchant/category/amount handling is implemented, but physical
  receipt-flow acceptance remains unverified. Cross-module financial reporting
  still needs a completeness-indicator audit; omitting unknown amounts from a
  sum does not make a business's records complete. Currency/localization and
  detailed item reconciliation remain separate unfinished requirements.
- Full item extraction, unit/package handling and reviewed stock adoption are
  not connected. Current structural header proposals are preliminary.
- Multi-photo registration/stitching, long-image text preservation, skew and
  degradation handling remain unverified on physical devices and substantially
  unfinished. Android single-image section reading now has implementation and
  fault-injection evidence; native EXIF cases, real OCR accuracy, iPhone parity
  and cross-photo registration are not proven. Do not reuse the 5.7 stitcher.
- Selected header proposals now persist through evidence review and its atomic
  handoff, tied to the retained image ID and checksum. Complete per-photo OCR
  history, source regions and parser-version provenance remain unfinished.
- Compression choices with actual full-screen candidate previews remain pending.
- No physical S25 OCR run or baseline-versus-enhanced accuracy measurement was
  completed in this slice. The S25 is not currently visible to ADB; the connected
  S24 is outside the authorized testing scope. No network changes were made.
- The Windows computer-use launch encountered an app-access approval timeout;
  native window interaction was not verified. Source/build checks are separate.
- No measured 97–98% result exists. Real independently labeled receipts, held-out
  synthetic cases and lower-resource physical-device evidence remain necessary.
- Inventory costs/quantities/locations, reservations, low-stock notifications,
  permission enforcement and configurable expense approval need further work.

Firebase and PDF work remain outside this slice. The overall goal stays active.
