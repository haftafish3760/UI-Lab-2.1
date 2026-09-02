# UI Lab 2.1 Work Completed Summary

Status date: 2026-09-01  
Repository: `/Volumes/AppleWork/UI-Lab-2.1`  
Branch: `main`  
Baseline commit: `3818f9a` (`Initial UI Lab 2.1 dashboard prototype`)

## 1. What this document is

This is a factual summary of the work performed in UI Lab 2.1 from the initial
checkout through the current working tree. It separates implemented code,
prototype behavior, documentation, tests, inspected reference material, and
unfinished work. It is not a claim that the app is complete or visually
approved.

The current checkout is not a clean release checkpoint. Immediately before
this summary file was added, relative to the single baseline commit, Git
reported:

- 35 tracked files changed;
- 3,719 tracked lines added and 1,700 tracked lines removed;
- 351 untracked text/source files containing approximately 78,402 lines;
- 79 top-level Flutter test files;
- 13 blueprint/documentation files;
- 64 Dart files under `lib/src/data`;
- 33 Dashboard, 50 Expenses, 73 Work, and 12 Inventory/Materials screen files.

Those counts include work from the full UI Lab effort, not only the most recent
Work-screen pass.

## 2. Repository and environment work

### Completed

- Established `/Volumes/AppleWork/UI-Lab-2.1` as the active UI/UX proving
  checkout.
- Kept `/Users/rbbie/Documents/Maintainiac_5.7_Active` separate as protected
  source/reference material.
- Corrected the Flutter entrypoint to `lib/main.dart` instead of the invalid
  `bin/main.dart` launch target.
- Updated Flutter tooling when the original Dart SDK did not satisfy the
  project's SDK constraint. The recorded working toolchain was Flutter 3.47.1
  with Dart 3.13.1.
- Added or changed Android, iOS, macOS, Linux, and Windows plugin registration
  and platform configuration needed by the current prototype dependencies.
- Added camera/photo and file-selection permission descriptions for receipt and
  job-site evidence on supported Apple/Android platforms.
- Added `file_picker`, `image_picker`, `path_provider`, PDF rendering, and
  `flutter_local_notifications` dependencies used by current prototype flows.

### Important limitation

The workspace remains a large, uncommitted working tree. There is no current
Git checkpoint containing all of the work described here.

## 3. Product and technical blueprints created

The following documents were created or substantially expanded to keep product
rules outside the conversation:

- `docs/ui_foundation_blueprint.md`: shared visual system, responsive layout,
  navigation, header, accessibility, color, density, and file-size rules.
- `docs/maintainiac_app_blueprint.md`: whole-app product definition, module
  ownership, migration strategy, user/access model, and product direction.
- `docs/product_control_blueprint.md`: authorization boundaries, record
  ownership, lifecycle register, screen/action register, and migration gates.
- `docs/operations_screen_blueprint.md`: Dashboard, Work, Expenses, Reports,
  and Materials screen responsibilities.
- `docs/work_lifecycle_blueprint.md`: customer-to-estimate-to-job-to-invoice-to-
  payment lifecycle, signatures, revisions, photos, terms, and permissions.
- `docs/calendar_system_blueprint.md`: shared calendar ownership, module
  projections, day routes, workday/trip/maintenance relationships, and dated
  record behavior.
- `docs/notification_system_blueprint.md`: notification event, delivery,
  permission, routing, privacy, and non-messaging boundaries.
- `docs/receipt_material_intake_blueprint.md`: receipt evidence, manual review,
  proposed OCR/parsing handoff, itemization, allocation, and inventory/job-cost
  boundaries.
- `docs/expense_atomic_cutover_blueprint.md`: staged replacement plan for
  prototype Expense storage with durable records.
- `docs/maintainiac_5_7_capability_migration_map.md`: read-only 5.7 capability
  inventory and proposed bounded migration slices.
- `docs/localization_measurement_blueprint.md`: English/Spanish/French and
  U.S./metric measurement direction.
- `docs/accounting_integration_blueprint.md`: future provider-neutral
  accounting boundary without making QuickBooks a release-one dependency.
- `docs/technician_dashboard_blueprint.md`: technician Dashboard content,
  workday, vehicle, calendar, and responsive behavior.

### Blueprint limitation

Some layout language still contradicts the owner's latest calendar and lane
direction. In particular, older text saying that a calendar fills an entire
wide workspace has not yet been fully revised to the newer bounded-lane rule.
The blueprints are extensive, but they are not all owner-approved or internally
final.

## 4. Shared app architecture implemented

### App shell and navigation

- Created a persistent five-module shell for Dashboard, Work, Expenses,
  Materials/Inventory, and Maintenance.
- Implemented bottom navigation for compact windows and a labeled navigation
  rail for sufficiently wide windows.
- Added the fake advertisement region above the bottom navigation bar.
- Added a hamburger/operations menu with prototype routes for employees,
  vehicles, system settings, and appearance settings.
- Added employee and vehicle directory/editor prototypes.
- Preserved module state through the shared shell rather than rebuilding every
  module on each navigation tap.

Key files include:

- `lib/src/shell/app_shell.dart`
- `lib/src/shell/app_navigation.dart`
- `lib/src/shell/operations_menu_screen.dart`
- `lib/src/shell/employee_directory_screen.dart`
- `lib/src/shell/vehicle_directory_screen.dart`

### Shared operational context and header

- Built one shared operational header instead of separate unrelated headers per
  module.
- Added technician/admin view selection and employee/company context.
- Added active-vehicle context support and shared scope state.
- Added contextual settings entry points.
- Moved notification ownership out of the header layout and toward dated/module
  content.

Key files include:

- `lib/src/shared/operational_header.dart`
- `lib/src/shared/operational_header_controls.dart`
- `lib/src/shared/operational_scope.dart`
- `lib/src/shared/app_view_mode.dart`

### Shared responsive layout engine

- Created `AppLayoutEngine` as the central source for navigation, one/two/three
  column operations layouts, form widths, action grids, record stacking, and
  text-scale-aware reflow.
- Replaced several screen-private width decisions with shared calculations.
- Changed the latest lane rules so one and two-column layouts are bounded at
  approximately 400 logical pixels per lane, while three-column desktop layouts
  can grow toward 600 logical pixels per lane.
- Added shared `OperationsWorkspaceFrame` and `OperationsLaneGrid` components.
- Added wide-layout inline actions for several Work routes and retained compact
  FAB behavior only for one-lane layouts.

Key files include:

- `lib/src/layout/app_layout_engine.dart`
- `lib/src/layout/app_breakpoints.dart`
- `lib/src/shared/operations_workspace.dart`

### Shared calendar system

- Replaced duplicated calendar presentations with a shared Month calendar
  widget and shared day-cell component.
- Added record counts, current-day treatment, selected-day treatment, module
  filtering, and separate day routes.
- Adopted the shared calendar in Dashboard, Work, Jobs, Estimates, Invoices,
  Payments, Expenses, and Materials/Inventory screens.
- Added calendar/day routing tests and shared-adoption tests.
- Most recently added a configurable maximum width so a calendar follows its
  owning lane instead of stretching without limit.

Key files include:

- `lib/src/shared/module_month_calendar.dart`
- `lib/src/shared/module_calendar_day_cell.dart`
- `lib/src/screens/dashboard/dashboard_calendar.dart`
- `lib/src/screens/work/work_month_calendar.dart`

### Current calendar limitation

The latest bounded-calendar code has not yet received a complete rendered
owner review across phone, landscape phone, tablet, and desktop. The app that
was already running during the latest pass had not been restarted or confirmed
to contain the newest source. Therefore the latest source change must not be
described as visually accepted.

### Theme and appearance

- Built shared light and dark `AppTheme`/semantic color systems.
- Added tinted blue-gray light surfaces instead of routine pure-white panels.
- Added module identity colors and semantic current/planned/success/attention/
  danger/draft colors.
- Added shared density, radius, border, and typography behavior.
- During the most recent pass, read the 5.7 theme as a protected reference and
  copied its palette values into UI Lab dark-theme tokens. This was a palette
  reference only, not a 5.7 capability migration.
- Changed the prototype default theme preference to light during the recent
  visual correction pass.

### Current theme limitation

The newest dark module colors still have an unresolved automated contrast
failure. The dark Work screen also has not been visually rechecked after the
latest surface changes. The old running build visibly showed near-black canvas
through colored panels and lacked acceptable hierarchy.

## 5. Dashboard work implemented

- Rebuilt the Dashboard around the shared operational header and shared scope.
- Added technician and admin/company-overview presentations.
- Added Start Workday, active-workday summary, pause/resume/end-workday flows,
  and physical-odometer review prototypes.
- Added active-vehicle controls and shared vehicle context.
- Added date-first content and notification access.
- Added Needs Attention, Today's Plan, Today's Entries, and shared Calendar
  sections.
- Added compact record rows, three-dot actions, day details, notification
  details, calendar-day routes, and approval-detail prototypes.
- Added admin employee status/selection presentation.
- Added prototype chronological projection behavior through
  `PrototypeOperationsStore`.

The Dashboard has received multiple responsive and Android/macOS visual-review
passes, but it has not received final owner acceptance. Several layouts and
example records were repeatedly rejected and revised.

## 6. Work module work implemented

The Work module now contains prototype routes and data models for:

- Work home;
- Jobs list and job details;
- job creation/editing, assignment, schedule, and status actions;
- active job actions and customer contact;
- materials/item sources and job item editing;
- Estimates list, detail, editor, items, company review, delivery, signature,
  revision behavior, and job-site photos;
- Invoices list, detail, editor, delivery actions, and payment entry;
- Payments;
- Saved Clients and customer detail/edit;
- company profile/My Info;
- date-filtered Work, Job, Estimate, and Invoice routes;
- document preview and local PDF/image preview support.

Important product behavior represented in code/tests includes:

- estimates, jobs, invoices, and payments remain separate records;
- changing customer-visible estimate content invalidates the prior signature;
- company approval and customer acceptance are separate states;
- job photos can come from camera or files;
- a job can link an existing expense or select a material source;
- Work records are scoped by employee/company context and date projections.

### Most recent Work-screen changes

The newest source pass began correcting the rejected wide Work home:

- removed the six equal-weight shortcut tiles from the top of Work home;
- promoted My Jobs, Estimates, and Invoices as the primary records;
- added visible New job, New estimate, and New invoice actions to their owning
  sections;
- moved My Info, Saved Clients, and Payments into a secondary Company records
  area;
- removed the wide-screen Work FAB while retaining it for compact one-lane
  layouts;
- added inline wide-screen creation actions on Jobs, Estimates, Invoices, and
  Payments screens;
- changed Work section bodies to use solid shared surfaces instead of allowing
  near-black canvas to show through translucent colored widgets.

### Current Work limitation

This latest Work hierarchy is unfinished and not rendered/owner-approved. The
header still needs a clear, verified employee-and-assigned-vehicle presentation
for the selected scope. The entire Work flow still requires a normal-user audit
so every state exposes a truthful next action (for example, a scheduled job must
not offer Pause before it has started).

## 7. Expenses work implemented

### UI and workflows

- Built a business-only Expenses home direction with date-first content.
- Separated Needs Attention from Receipt Drafts.
- Added daily totals, compact dated entries, category views, day views, reports,
  recurring/scheduled expenses, removed-expense recovery, and settings screens.
- Added individual expense record containers rather than merged flat entries.
- Added detail, editor, correction reason, permission-denied, and unavailable
  states.
- Added total-only versus itemized receipt modes.
- Added editable receipt line items, purchase/package fields, subtotal, tax,
  total, category, job allocation, and receipt evidence.
- Added photo/file receipt source selection and local image/PDF evidence review.
- Added receipt-draft intake and resume screens.
- Added scheduled/recurring expense creation, occurrence editing, reminders,
  mark-paid, skip, pause/end, and monthly receipt attachment prototypes.

### Durable local Expense foundation

Unlike most UI-only areas, Expenses now contains a significant local data-layer
prototype:

- decimal-safe Expense money/itemization records;
- Expense lifecycle, approval, revision, and audit records;
- repository interfaces with own/team/company read scopes;
- authorized command services;
- revision-conflict and correction-reason enforcement;
- file-backed private repositories;
- dual-slot JSON snapshots designed to preserve the last valid copy;
- UI repository bridges/controllers;
- recurring expense records, repositories, transitions, controllers, and
  payment coordinator;
- durable Receipt Draft records, evidence hashes/copies, repository, authorized
  service, UI controller, and submission coordinator.

### Current Expenses limitation

- This is not Firebase, Hive, or the production 5.7 Expense database.
- The receipt assistant/OCR engine and inventory parser have not been migrated.
- Long-receipt stitching has not been migrated or rebuilt.
- Several Expense screens have not received final visual approval.
- The local repositories have tests, but they have not been formally proven as
  the final production storage architecture.

## 8. Notifications and recurring reminders implemented

- Defined notification categories, event kinds, source modules/types, routes,
  in-app/push/sound channels, read state, delivery state, lifecycle, and audit
  events.
- Added repository interfaces, authorization guards, file-backed private
  storage, snapshot codec, and UI controllers.
- Added a native notification gateway based on
  `flutter_local_notifications`.
- Added native permission/status UI and a delivery coordinator.
- Added recurring-expense notification publication.
- Kept notifications separate from Needs Attention and did not create employee
  chat/messaging.

This is a new UI Lab notification foundation. It was not transferred from a
complete 5.7 notification engine.

## 9. Materials/Inventory work implemented

UI Lab currently has only a prototype Materials/Inventory presentation:

- Materials/Inventory home;
- scope header and settings;
- attention and day screens;
- material detail and cost editor;
- stock selection and physical stock count screens;
- prototype inventory models and demo data;
- links from receipt/job flows to material-cost and stock concepts.

### Critical limitation

The proven or expensive 5.7 inventory parsing/catalog system has **not** been
transferred into UI Lab. No 5.7 trade-pack database, OCR-to-inventory parser,
Hive inventory store, Firebase catalog, or production stock engine has been
copied. The current Inventory screen must not be described as a true completed
inventory system.

## 10. Localization and measurement work

- Added English, Spanish, and French localization scaffolding.
- Added U.S. and metric measurement preference models.
- Added generated localization configuration and initial translated strings.
- Added blueprint/test coverage for first-run language selection and package/
  measurement fields.

The full app is not completely translated, onboarding is deliberately deferred,
and all receipt/material forms have not yet been audited for every unit and
locale.

## 11. Reports, customer portal, accounting, AI, and maintenance status

### Reports

- Added prototype report source models, period selection, summary projection,
  report screens, and source drilldown.
- Profit, payment, expense, and operational summaries remain prototype
  projections, not a final accounting ledger.

### Customer portal and QR

- The estimate/invoice customer portal, secure signing links, QR-code handoff,
  customer reminder consent, and payment-plan presentation are documented.
- They are not implemented as a production lightweight web app in UI Lab.

### Accounting

- A future provider-neutral accounting/QuickBooks boundary is documented.
- No QuickBooks integration is implemented.

### AI

- AI confirmation, permissions, audit, and human-review principles are
  documented.
- No production AI agent or OpenAI API integration is implemented in UI Lab.

### Maintenance, repairs, and trip tracking

- Their calendar ownership, record-ownership boundaries, and future shared
  layout requirements are documented.
- The current bottom-navigation Maintenance destination is not a completed
  vehicle/equipment maintenance and repair system.
- Production GPS/trip tracking has not been migrated from 5.7.

## 12. Exactly what has and has not come from 5.7 Active

### Used as read-only reference

- product capability names and architectural census information;
- selected theme/color values during the latest dark-theme pass;
- migration planning for Expense storage, Receipt Assistant, inventory parsing,
  permissions, backup/sync, and the QA harness;
- visual and workflow comparison points.

### Not transferred

- OCR/ML Kit engine;
- long-receipt stitching engine;
- inventory parsing/trade-pack system;
- production Hive databases and adapters;
- Firebase/cloud backup and sync;
- GPS/trip engine;
- centralized PDF/document engine;
- complete permission engine;
- complete 5.7 QA harness;
- customer portal;
- AI agent.

Therefore UI Lab is currently a broad UI/UX and local-domain prototype with a
more substantial durable Expense/Receipt Draft/Notification foundation. It is
not yet a complete replacement for 5.7 Active.

## 13. Testing and validation actually performed

Across the effort, the recorded checks include:

- repeated `flutter analyze` runs;
- focused Dashboard, layout, calendar, Work, Expenses, Inventory, repository,
  notification, localization, and accessibility widget/unit tests;
- full-suite runs reported at different points with approximately 125-129 tests
  passing;
- source-size guard tests;
- Android debug APK builds and launches on Samsung devices;
- macOS debug builds and Dart VM connections;
- visual review on compact Android and resizable macOS windows.

### Current test truth

The most recent targeted run after the unfinished Work/theme changes reported
30 passing tests and 5 failures:

1. dark module-color contrast;
2. an Estimate navigation test still tapping the old Work shortcut;
3. a Work settings test still expecting the removed Jobs shortcut;
4. a wide Work form test still expecting the intentionally removed wide FAB;
5. a lane-width test still expecting the older 500-LP maximum instead of the
   newest three-column 600-LP rule.

`flutter analyze lib/src` passed immediately before that targeted test run, but
there has not been a new full green analysis/test/platform-build sweep after
the latest changes. Green historical runs must not be presented as proof that
the current dirty tree is green.

## 14. Known unresolved problems

- Work and other wide layouts have not yet achieved owner-approved visual
  hierarchy.
- The latest dark palette/surface repair is incomplete and has an automated
  contrast failure.
- Calendar/lane rules changed several times and the newest rule is not yet
  consistently documented and rendered across all screens.
- Some running-device observations were from stale builds or sessions that
  later lost their device connection.
- App startup/launch delay on macOS and Android has been observed but not fully
  profiled or resolved.
- Prototype fake data is mixed with UI flows and is not yet a final seeded test
  database strategy.
- Work actions are not yet fully contextual to every lifecycle state.
- Assigned employee/vehicle context needs a complete rendered audit across
  Dashboard and Work screens.
- Inventory is a prototype, not a production inventory engine.
- Maintenance/repairs/trips remain largely unimplemented.
- Firebase, Hive production integration, sync, OCR, stitching, catalog parsing,
  centralized PDF generation, customer portal, QR sharing, and AI remain future
  bounded slices.
- The current working tree is too broad and dirty for two agents to edit shared
  architecture files safely without strict isolation.

## 15. Current parallel Inventory safety answer

Another Codex model should **not** edit Inventory in this same checkout at the
same time as broad layout/theme/shell work. The current Inventory UI imports
shared files that are actively changing, including `AppTheme`,
`AppLayoutEngine`, the operational header/scope, shared calendar, shell, and
prototype stores. Concurrent edits would be difficult to attribute and easy to
overwrite.

Parallel Inventory work is safe only if all of these are true:

1. it uses a separate Git worktree and separate branch made from a deliberate
   checkpoint;
2. its scope is limited to Inventory models, repositories, parser adapters,
   characterization tests, and Inventory-owned screens;
3. it does not edit shared theme, layout, shell, header, calendar, app wiring,
   dependencies, platform files, or 5.7 Active;
4. 5.7 is read-only source material;
5. the model first characterizes the 5.7 inventory parser and tests instead of
   copying files blindly;
6. integration back into UI Lab happens as a reviewed bounded slice after the
   shared UI work is stable.

No separate checkpoint or safe Inventory worktree has been created as part of
this summary.

## 16. Bottom-line status

Substantial UI, data-model, local-repository, documentation, and test work has
been added to UI Lab 2.1. The strongest implemented backend-like portion is the
local Expense, recurring-expense, Receipt Draft, and notification foundation.
The broadest UI portion is Dashboard and Work. The most important 5.7 engines
have not yet been moved. The present app is still an unfinished prototype and
is not ready to be called a dependable 5.7 replacement, a release candidate,
or an owner-approved professional UI.
