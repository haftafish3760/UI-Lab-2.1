# Maintainiac: current Codex continuation, September 10, 2026

## Start here

The owner is one person, moving from the Mac Mini to a laptop. This is a
continuation of the same application, not a new project or parallel team.
Existing repository: https://github.com/haftafish3760/UI-Lab-2.1.git.
Work on `main`, which contains the full migration checkpoint through `1fdf43a`
plus this documentation checkpoint. Do not make the owner manage another lane.
Fetch/status first and preserve any newer laptop changes. No force push/reset.
Build directories are ignored and untracked; regenerate build artifacts locally.

Read AGENTS.md, current_product_blueprint.md sections 6–8, and the **top gate
matrix** of sqlite_remaining_work_audit.md. Then read only the owning blueprint
and relevant source for the next change. Avoid repeatedly scanning the enormous
historical storage narrative. The owner explicitly asks to conserve rate limits
without reducing engineering quality. Batch related work and focused tests;
run broader regression at meaningful checkpoints.

Protected reference on Mac: `/Users/rbbie/Documents/Maintainiac_5.7_Active`.
Read/copy only; do not edit, clean, build in, commit or reset it. If unavailable
on laptop, say so rather than inventing a reference result. Do not invoke or
configure Maintainiac bridge recursively. No agents unless explicitly requested.

## What is actually done

- SQLite/Drift is wired into normal startup through `open_ui_lab_application.dart`
  and `LocalPersistence.open`. Work documents/jobs/payments, directory,
  expenses/receipts, notifications, workday/day notes, preferences and draft
  workflows use the implemented local persistence adapters. Inventory remains
  a prototype; Maintenance is not a completed editable service-record system.
- Local records, revisions, commands and outbox changes use transactions;
  draft revision checks and confirmation protect against stale/duplicate writes.
  WAL, FULL synchronization, foreign-key/integrity and established-installation
  checks exist. Never describe these as proof against every power-loss case.
- Raw unfinished input is versioned behind draft/workflow interfaces; errors
  must not report success or silently discard drafts. Early initialization
  discard now rejects instead of falsely claiming success. Existing demo data
  is disposable; preserving it is not the reason for migration compatibility.
- UI/storage separation was corrected: screens do not construct LocalDraftStore
  from databases or expose generated Drift rows for recovery. Pure-Dart
  LocalRestoreController exposes plain review facts, while implementation keeps
  verified selection/runtime private. Layout changes must not alter schemas
  merely because widgets/routes move. Preserve lifecycle and discard guards.
- Android retained-media journal copies/hashes bytes before delivery, and Dart
  acknowledges after retained-file transaction. Overlapping publication helpers
  now recheck the published result inside the transaction. Keep staging cleanup,
  failed-write, replay and acknowledgment semantics intact.
- Reusable QA includes core/domain/editor suites, process interruption fixtures,
  native-media checks and isolated Android/iOS restore runners. QA application
  identities must remain separate from the owner's normal app.
- Old record-file readers/aliases and transient test/preview fallbacks remain;
  normal startup is not constructing the former Hive/file domain store. Media
  evidence files and checkpoint manifests intentionally remain files.
- Git commits: `4882281` migration checkpoint; `7bd0fed` storage blueprint
  refresh; `1fdf43a` build-worker cleanup rules. All were fast-forwarded to main
  and remote hash verified. This is a backup, not a release/completion label.

## Verification already recorded, with limits

Do not call these newly rerun checks. Exact checkpoint/source provenance lives
in the storage gate matrix. Raw `build/storage_qa` logs are intentionally ignored
and therefore will not be available from a laptop clone.

| Recorded check | Result / qualification |
| --- | --- |
| Declared core/domain/editor regression | 578 passed across 200 files: 188 core, 254 domain, 136 editor; checkpoint `20260910T180954Z-2ecf8b88`; predates subsequent focused fixes |
| Full discovered Flutter suite | 1,061 passed / 7 failed across 304 files; `20260910T170936Z-dce8c6e2`; no later full green run claimed |
| Failures | Four missing dashboard-view-selector expectations, header height 366 vs <=290, Inventory width 375.84 vs >1000; seventh test-file size issue subsequently fixed with nine focused checks |
| Native media | 130 passed, unchanged source, `20260910T183518Z-native-64b4db4f`; includes overlapping-helper correction |
| Early-discard correction | Reproduced before fix; 22 focused checks passed afterward; analysis and Android build passed |
| Restore controller boundary | 17 focused workflow/host/mounted checks, analysis and Android build passed |
| Restore runtime | Four cases (normal, open failure, save failure, pending media) passed on macOS, Android API35 and iOS26.5 simulator; latest isolated iOS run includes controller/discard fixes |
| Physical iPhone SE | Build/install succeeded; launch denied CoreDeviceError10002/FBSOpenApplicationErrorDomain3. Local profile/signature checks passed. Device trust/signing unresolved; no physical runtime pass |
| S25 Ultra | Normal debug build installed and foreground activity verified September10; not whole-workflow or owner visual acceptance |

No fresh app tests were run for this documentation-only handoff. Do not modify
unapproved UI just to make inherited expectations pass. The owner's latest
layout request now authorizes a redesign, but expectations must follow the
actual intended behavior, not simply be loosened to hide failures.

## What remains in storage

1. Whole-installation restore source selection/review/retry is not exposed in
   normal Settings. Saved-work recovery exists; Backup/company sync tile is
   noninteractive. Backend completion can continue without Firebase or a final
   visual design. Resolve genuine restore product choices narrowly with owner.
2. Calendar Day has two disconnected memory-only switches whose advertised
   behavior needs a product decision; persisting flags alone does not implement it.
3. Final regression/completion audit after all actual fixes; preserve unresolved
   UI failures and confirm affected workflows rather than assuming old passes.
4. Physical iPhone signing/trust runtime, Windows and older supported platforms,
   broader physical media providers/failure cases, interruption in active picker
   gestures and physical power-loss limits remain unverified.
5. Firebase backup/sync, production authentication, tenant isolation enforcement
   and abuse controls are not connected production services. Synthetic local
   permissions tests are not proof of deployed account enforcement. Missing
   credentials do not block local SQLite implementation.
6. After local migration completion is actually verified, inventory port from
   read-only 5.7 is authorized, with independent tests, regression and reusable
   harness extension. It has NOT started. Move screen-owned inventory models
   and mutable prototype lists behind domain/controller/repository boundaries.

Do not claim the full migration goal complete. Do not confuse past goal/session
status with filesystem access: this Mac session had full write access. An old
blocked goal is not evidence of a current implementation permission problem.

## Immediate priority: UI/layout with the owner

The latest owner priority is professional adaptive layout throughout the app,
starting with Dashboard/shared infrastructure, then screen by screen. No source
edits for this latest request were made before the GitHub/handoff interruption.
The observed issues and source locations below save repeating discovery:

- `lib/src/layout/app_layout_engine.dart` and `dashboard_layout_calculator.dart`:
  Dashboard thresholds are 748/1248 local LP, capped 400-LP lanes, 24-LP gaps.
  Two lanes stop at 824 LP while waiting for 1248, wasting space. Generic
  operations use 718/1086 thresholds; inspect Work's separate calculator too.
  Audit app-wide shared/private width decisions, not Dashboard alone. Use local
  post-navigation constraints and TextScaler, never device type or raw pixels.
- `lib/src/screens/dashboard/dashboard_body_layout.dart`: header and workspace
  centered/capped; 2 lanes put Calendar below Entries, 3 give it its own lane.
  Owner wants a useful command center, not stretched phone cards. Calendar stays
  bounded. Determine sensible widths/content hierarchy, then render-review.
- `lib/src/shared/operational_owner_header.dart`: current title/menu/settings
  row above vehicle/odometer. Owner wants menu, vehicle, odometer, settings on
  one compact row; active vehicle and odometer together. Keep accessibility.
  `OperationalHeader` caps this owner presentation at form width. Investigate
  all callers before changing shared behavior.
- `active_workday_overview.dart`: displays elapsed time/miles and hardcoded
  "Next job · 8:00 AM". There is no direct End control. Existing
  `dashboard_screen_actions.dart` / `dashboard_workday_persistence.dart` and
  `EndWorkdayDialog` implement ending; expose the existing workflow rather than
  constructing a second persistence path. Do not present a fixture as real job.
- `lib/src/shared/module_month_calendar.dart`: `_showWeek ? 7 : 42` forces six
  weeks. Calculate natural 4/5/6 rows; September2026 needs five. Check calendar
  date arithmetic around DST rather than treating civil days as fixed24h.
- Protected 5.7 `lib/shared/calendar/app_month_calendar_widgets.dart` contains
  `_CalendarPanelPainter`: gradient E0E4DC/B6B9AB/C9D0D3/8F9A9D/D5D0BE, stops
  0/.22/.48/.73/1, plus tinted blurred ovals. Owner explicitly requests that
  background for Month AND Week. Adapt presentation only; do not copy 5.7's
  enforced six-week calendar behavior. Shared day cells currently paint opaque
  surfaces, so replacing the panel alone will not produce a visible match.
- Later: Jobs date/search stretching across full width is rejected. Other colors
  can wait except calendar contrast. Existing screens are not approved designs.

Before changing UI read the owning foundation, app, product-control, operations,
calendar and relevant screen blueprints. Current product blueprint section8
records latest overrides. Update owning rules and cross-references, not competing
copies. Verify natural calendar rows/navigation, 320-LP normal header, increased
text scale, intermediate/wide layouts, and actual workday-end recovery. Focused
checks first, then broader affected regression and target render inspection.

## Requirements already documented but not necessarily implemented

Master Dashboard calendar combines authorized records; each module filters its
own calendar and pushes a dated route with historical/future authorized actions.
All mutations return to the owning record domain. See calendar_system_blueprint.
Scheduling should explain availability/conflicts/skills; review the scheduling
blueprint before recommending policy. Detailed scheduling choices are not all
approved or implemented. Localization catalogs and preferences exist, including
regional resources, but screen-body/units/parsing/document coverage is incomplete;
see localization_measurement_blueprint. Canadian French, regional Spanish and
metric/US measurement are required. Trial duration/storage policy is undecided.
Strong recordkeeping is required; do not advertise IRS audit-ready/compliance.

## Machine and runtime cautions

8-GB M2 Mac Mini: one emulator/simulator maximum. Stop idle Gradle/Kotlin workers
after Android work, verify exit. Preserve app, Codex and bridge; don't blanket
kill Java/Node. Two idle Gradle daemons were stopped; CUA session workers reset.
Gradle currently declares very large heap ceilings (8G heap/4G metaspace); no
memory-limit tuning was implemented. App debug footprint measured ~482 MB; this
is not a proven memory leak or production baseline. Swap is system-wide.

Mac bundle: `build/macos/Build/Products/Debug/ui_lab_2_1.app`, bundle ID
`com.maintainiac.uiLab21`. `open` previously activated an OLD running process,
so a successful build did not prove the running app was latest. Safely quit and
relaunch the correct artifact before next review; preserve draft lifecycle.

S25 normal Android package `com.maintainiac.ui_lab_2_1`, model SM-S938U. Last ADB
serial `adb-RFCY51Q7R1D-8bLSro._adb-tls-connect._tcp`; endpoint may change. Pairing
and connection ports differ; do not assume pairing means current device access.
Normal Android and iOS QA IDs end in `.storageqa`; never replace normal user app
with test harness. No emulator was intentionally left running at handoff.

The owner has requested screen inspection for layout review; follow current
screenshot authority and platform tools. Do not claim a screenshot, build or
launch as owner acceptance. The laptop does not inherit Mac hardware, signing,
Flutter SDK paths, ignored logs, device pairing, or this live conversation.
