# Start Workday — first workflow review

Source inspection: 2026-09-11, UI Lab 2.1 GitHub Clone on main, dirty working tree
preserved. Protected donor: `C:/Users/noneya/Documents/Maintainiac_5.7_Active`.
No claim this is the latest Mac build; only this local donor was inspected.
Parent plan: [Delivery roadmap](workflow_delivery_roadmap.md).

## Existing owners — preserve them

| Responsibility | Current source | What inspection establishes |
| --- | --- | --- |
| Start form | `lib/src/screens/dashboard/start_workday_screen.dart` and `start_workday_sections.dart` | Vehicle picker, reading field, GPS switch, guarded confirmation exist. |
| Draft navigation/recovery | `start_workday_draft_recovery.dart`, shared DraftNavigationGuard | Raw input retained; explicit discard; failed save stays open. |
| Draft command | `lib/src/data/workday/start_workday_draft_workflow.dart` | Stable workday ID, raw odometer, context/revisions; validates and consumes draft on commit. |
| Live saved state | `workday_persistence_session.dart` | Serializes commands and reloads after commit; exposes active workday and vehicle readings. |
| SQLite transaction | `sqlite_workday_repository.dart` | Workday, active index, odometer, command acknowledgment and draft consumption within transaction; lower/stale readings rejected. |
| Exact input | `odometer_input.dart` | Integer tenths; no floating rounding; current parser specifically expects U.S. miles syntax. |
| Current access | `workday_ui_lab_bootstrap.dart` | Development actor/organization/employee/vehicle grants, NOT production authentication. |
| Startup | `lib/src/startup/open_ui_lab_application.dart` | Normal entry injects LocalPersistence, Work/directory/workday/day-note sessions and saved preferences. |

## Findings requiring repair before acceptance

1. Form date uses fixed `dashboardToday`; command confirmation uses current UTC.
   Preserve isolated fixed demo scenarios, but production must show actual start
   context/date and not contradict the saved event. Midnight/restart needs testing.
2. Employee label uses demo lookup/fallback to Alex. Actual actor, viewed employee
   and authorized on-behalf-of action must be distinct. A technician cannot start
   somebody else's workday merely by selecting an Admin filter.
3. Vehicle picker uses demo vehicles rather than the complete authorized profile
   directory. No real profile creation/availability proof follows from this list.
4. UI and domain parser hardcode miles. Metric cannot be implemented by changing
   the suffix alone. Coordinate original reading unit, canonical conversion,
   revision and localized number parsing with the odometer engine owner.
5. Missing saved reading is represented by revision 0 / reading 0. UI can prefill
   that as though it were confirmed. Present an unknown baseline explicitly and
   require physical confirmation; do not change stored history silently.
6. Lower reading only produces an error. There is no selectable correction,
   wrong-vehicle/unit review or odometer-replacement route on the form. Keep the
   persistence rejection until a real audited discrepancy workflow exists.
7. Higher readings have no visible gap review here. A gap may be legitimate;
   never automatically label it personal/business or replace it from an average.
8. GPS UI says location will start on confirmation. This form only passes a
   requested boolean; no native start/permission/availability result is established
   by it. Display actual unavailable/off/requested/active/failed state truthfully.
9. Save/open/conflict failures mostly collapse to generic text. Preserve raw
   input and offer meaningful Retry/Review rather than silently ignoring a tap.
   `_confirmStored` currently returns without feedback when employeeId is null.
10. Confirmation is guarded against repeated taps; make saving/busy state visibly
    disable conflicting controls and prove retry after uncertain acknowledgment.
11. Development fallback without WorkdayPersistenceScope does not prove durable
    production behavior. Test through real SQLite startup as well as widget seams.
12. Shared Start green was `#6AD39B`; owner requests inspected donor `#20F060`.
    Contrast, opaque enabled fill, focus, pressed and disabled states need checks.

## Donor suitability — read-only, not a port

- `lib/screens/dashboard/start_day_panel.dart`: `_green = #20F060`; suitable color
  reference. Do not copy its glow, fixed size, FittedBox or ellipsis treatment.
- `lib/shared/odometer/odometer_validation.dart`: accepted / needsConfirmation /
  blocked outcomes, lower-reading correction wording and history trend checks.
  Adapt after assessing precision/unit differences (donor uses integer readings).
- `lib/shared/trip_tracking/trip_tracking_odometer_usage_anomaly.dart`: reviewed
  history, optional anomaly alerts and explicit prohibition on automatic odometer
  correction. Its numeric thresholds are existing implementation defaults, NOT
  owner-approved policy. No reliability claim from source reading.
- Related correction/reconciliation files were located, not fully audited or
  executed. Extraction agent must inspect callers, persistence, tests and failure
  behavior before integration; do not copy only the validation function.

## Proposed plain-language normal flow

1. Heading: My workday; identify the person and vehicle together. A single
   eligible vehicle needs no extra selection wizard; switching remains available.
2. Show Last confirmed reading with date/unit, or No reading recorded yet.
   Ask for the number physically shown now. Do not require GPS to proceed.
3. Validate in context; show a correction/review choice only when necessary.
4. Confirm once. Report Saved locally after actual commit, not before it.
5. Return to My Work, active-day status and quick Fuel/Expense/Pause/End actions.

## Edge-case acceptance matrix — not yet all implemented

| Case | Required/proposed outcome |
| --- | --- |
| Same reading as last event | Valid stationary day; no fake travel. |
| Higher start after yesterday | Accept legitimate reading; gap review does not automatically classify distance. |
| Very large change / unusual daily usage | Optional history-informed review, confirm or correct; averages are not truth. No history means no claimed personal average. |
| Lower start | Check selected vehicle/unit and typo; preserved input plus audited correction path. Never negative mileage or overwrite history. |
| End below start/latest vehicle reading | Retain draft, explain discrepancy, offer proper correction; do not force a made-up number. |
| Unknown reading / cannot access truck | Proposed: continue non-mileage business work with unresolved mileage clearly identified; exact deferred start/end policy requires agreement with engine owner. |
| Replacement/rollover | Explicit documented event and continuity handling, never ordinary decrease; engine contract pending. |
| Unit or language change | Preserve original reading/unit and raw draft; deliberate conversion/locale parsing, no reinterpretation. |
| Vehicle swap during day / shared truck | Explicit handover/segment records; previous vehicle history stays intact. Do not attribute another driver's miles automatically. |
| Two devices start / stale odometer | Exactly one authoritative result or visible conflict; no silent winner or duplicate day. Local and cloud tests are separate. |
| Existing active/paused day | Open/resume existing session; explain overnight day, no reset at midnight. |
| Denied GPS / no hardware / offline | Complete manual path; no false Active tracking state and no inferred consent. |
| Save failure / low storage / kill | Raw input recoverable where acknowledgment occurred; actionable error; no false start success. |
| Permission revoked / wrong company | Recheck command scope; preserve data without exposing another person's records. |
| DST / time zone / clock change | Retain instants and relevant zone; elapsed time cannot rely solely on screen refresh or negative wall-clock differences. |
| Large text / narrow resize | Readable controls and error text, no hidden actions or private platform breakpoints. |

## Verification and next implementation

Existing focused tests to run against this checkout:
`exact_odometer_input_test.dart`, `start_workday_draft_workflow_test.dart`,
`sqlite_workday_repository_test.dart`, `start_workday_draft_recovery_test.dart`,
`dashboard_workday_sqlite_recovery_test.dart`, `dashboard_workday_test.dart`.
These test existing behavior, not every new acceptance row above.

First implementation must reconcile actor/profile and real date/unit context,
expose truthful assistance state and a clear recovery path using existing services.
Do not implement a second odometer engine here while another agent extracts it.
Document unresolved engine contracts explicitly; user-facing correction choices
must not claim to work before their audited command exists.
