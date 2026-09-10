# Phone layout review and staged roadmap

Date: September 7, 2026. Status: bounded source/UI review and recommendations,
not a full security audit or a claim that every screen has been exercised.
Product rules remain in the canonical index and owning screen blueprints.

## Owner requirements guiding this pass

- Information-rich, self-explanatory screens, not minimalism or unlabelled icons.
- Shared dimensions, spacing, typography, surfaces and logical-width engine.
- Compact Dashboard header; background spans the phone content area but stays
  bounded on wide screens. Keep its controls compact and chevron near the name.
- Stronger muted blue Plan and green Entries fills; darker cards; restore the
  light-green Start workday button. Preserve the status-bar background treatment.
- Five horizontally scrolling summary cards, Needs attention first. They must
  retain readable labels and allow accessibility growth, not crop values.
- Show Entries when records exist for that date, even before starting work;
  omit the empty section. Starting a workday is not a records-visibility gate.
- Picker selection is highlighted blue and must agree with the header and
  displayed records/totals. Company scope is not permanently selected.
- People/crews and employee-access permissions remain separate product decisions.
  The owner's willingness to consider crews is not approval of a permission matrix.

## Findings from this bounded review

| Priority | Evidence | Consequence / next step |
| --- | --- | --- |
| 1 | `prototype_operations_store.dart`: `dashboardDay` takes date/context/employee, not vehicle; `financialSummary` takes dates only. `PrototypeFinancialEntry` has no vehicle association. | Vehicle selection is not yet a reliable filter across Dashboard totals. Define explicit company/vehicle query scope and stable record links before claiming this works app-wide. Never infer vehicle identity from text or relabel company totals as truck totals. |
| 1 | `expenses_scope_header.dart` and `work_scope_header.dart` still construct employee/company options; `inventory_scope_header.dart` uses vehicle/fleet context. | The same-looking selector means different things across modules. Reconcile scope ownership, queries, counts, routes, exports and retained selection as one bounded integration slice. A renamed dropdown is insufficient. |
| 1 | Dashboard data falls back to `demoDataFor`; the source store also includes seeded financial/work records. | Existing Entries can appear before a workday because they are demo records, not because Start was pressed. Use explicit empty/pre-workday, active, ended and historical fixtures in design review. Do not erase saved user data to manufacture an empty screen. |
| 2 | Owner header and dark picker now exist in shared components; other module headers retain legacy View/employee UI. | Migrate a complete screen at a time after scope contracts are settled. Do not grant permissions or remove enforcement merely because release one is owner-operated. |
| 2 | `active_workday_overview.dart` contains a private 340-LP reflow threshold and a literal `Next job · 8:00 AM`. | Move reflow to the shared engine and derive next-job content from actual applicable schedule. Verify no-next-job, paused, overnight and resumed states. No scheduling-engine rewrite belongs in visual polish. |
| 2 | Start Workday still has prototype employee data and several English-only strings; new Select vehicle label is localized. | Complete the owner-facing form copy, remove redundant context only after clarifying crew capture, localize all labels/errors and validate keyboard/large text. The existing odometer rejection is not comprehensive odometer-event validation. |
| 2 | Dashboard, Work, Expenses and Materials share AppLayoutEngine and theme; individual records still carry local status colors. | Keep shared surface hierarchy and semantic state styling; avoid assigning every screen a unique color. Test dark/light contrast after token changes across all consumers. |
| 3 | `ModuleHomeScreen.maintenance` is a placeholder presentation with example counts. | Do not interpret it as implemented maintenance. Design interval, history, repair and due-state flows with empty/error states before writing its screen-specific roadmap. |

## Recommended execution order

1. **Owner visual review of this Dashboard/Start Workday pass.** Verify the real
   384-LP phone: header height, green button, blue/green sections, first-card
   visibility, horizontal scrolling, picker selection, content versus empty
   state, and return navigation. Do not treat tests as visual acceptance.
2. **Scope contract before more screen migration.** Company and vehicle are
   explicit scopes, not role names. Track the last selection per agreed screen
   behavior. Preserve selected date. Link records by vehicle IDs where valid;
   decide how unassigned records appear. Reopening always selects the current
   option. Test vehicle A -> B -> company -> Back with distinct data and totals.
3. **Dashboard/workday completion.** Replace literal/demo status with supplied
   data; remove private layout decisions; verify cancel/start/pause/end/restart
   presentation, optional tracking and keyboard access. Odometer correction,
   units, historical readings and unusual-distance warnings need their own
   event/data contract. A daily average may warn; it must not overwrite readings
   or classify an unexplained gap as personal/business automatically.
4. **Expenses vertical flow.** Home -> scoped day/category -> Basic/Detailed
   receipt -> review -> saved detail -> return. Apply the same picker/surfaces;
   test mixed use, incomplete drafts, failed saves, offline and back navigation.
   OCR and long-receipt repair remain separately assessed capability work.
5. **Work vertical flow.** Home -> estimate/job/invoice/payment -> detail/edit
   -> return. Make primary actions visible without competing cards, repeated
   headers or duplicate ownership. Scheduling requirements precede crew UI.
6. **Materials, then Maintenance/Repairs.** Keep record lookup, actual stock,
   costs and attention distinct. Carry the shared vehicle/company and dated
   projection contract into each screen; no fabricated counts or stock certainty.
7. **Whole-app consistency sweep.** Secondary routes, settings, dialogs, forms,
   empty/error states, localization and keyboard behavior after each slice.
   Preserve wide-screen lanes, but never let phone changes silently break them.

## Acceptance matrix for each slice

- Phone widths 320, 360, 384, 412 LP; representative short landscape; keyboard
  visible; text scaling 1.0/1.3/1.5/2.0; light/dark and longer translated labels.
- Existing intermediate/wide checks at 800, 1440 and 1920 LP; bounded controls
  and records, no stretched header controls or private device breakpoints.
- Same selected scope/date across header, picker, list, totals and record route.
- Zero, one, many and very long records; no fabricated zero or false completeness.
- Cancel/back leaves data unchanged. Retry does not duplicate records. Separate
  local prototype evidence from durable offline/restart verification.
- Independent expectations based on owner workflows, not just tests mirroring
  the current implementation. Security/privacy is an enforcement review, not
  an assumption based on hidden widgets or a successful navigation test.

## Explicit remaining decisions

Company/vehicle scope behavior on screens whose records are not inherently tied
to a vehicle; how unassigned records are shown; final header maximum after wide
visual review; employee login scope versus owner-managed crews; conflict override
policy; shared/offline scheduling reconciliation. No answers are invented here.

The app-wide vehicle-filtering repair remains outstanding. The current visual
pass must not be described as a completed scope, scheduling, odometer or
permissions system.

## Verification checkpoint — September 7, 2026

- The focused 52-test Dashboard/layout/navigation suite passed. After the phone
  review exposed wrapping in the expense amount, the owner/responsive tests
  passed again and a new long-currency regression passed with the complete
  five-test owner-presentation file. This is not a claim that every repository
  test was run.
- `flutter analyze --no-pub` and `git diff --check` passed. The Android debug APK
  built, installed and launched on the connected SM-S938U (Galaxy S25 Ultra),
  with a measured 384-logical-pixel width at the current display settings.
- Native phone captures verified the compact header, restored light-green Start
  workday button, stronger card/Plan colors, blue selected vehicle dialog row,
  and the final expense amount displayed on one line. The existing status-bar
  background behavior was preserved. Owner visual acceptance is still separate.
- The phone was left on Dashboard. No workday confirmation was submitted and
  no app data was cleared. Start-workday form changes have widget-test coverage;
  this checkpoint does not claim a completed native start/end workday workflow.
- Miles remains explicitly unavailable in the prototype rather than displaying
  an invented total. Shared vehicle/company record filtering remains the next
  architectural prerequisite, not something proved by the picker appearance.
- The build reported an existing `pdfx` Kotlin Gradle Plugin compatibility
  warning. It did not block this build; track it before future Flutter upgrades.
