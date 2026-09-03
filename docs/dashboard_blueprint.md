# Maintainiac Dashboard Blueprint

Status: first-screen rebuild for owner review

## Purpose

The Dashboard answers three questions without requiring the user to hunt:

1. What needs my attention?
2. What work is planned for the selected day?
3. What has already been recorded?

It is a projection of records owned by later Work, Expense, Materials, and
Maintenance systems. This rebuild proves the layout and interaction language;
it does not create those systems or claim production data behavior.

## Visual thesis

A practical field-operations board with strong opaque containers, compact
records, obvious priority, and restrained color that directs the eye. Nothing
important floats as an unbounded list on the page.

## Content order

1. Compact operational header with the selected person/view and active vehicle.
2. Selected date and Start Workday action.
3. Needs Attention when unresolved items exist.
4. Today's Plan.
5. Today's Entries.
6. Month calendar.

The order and meaning do not change between phone, landscape, tablet, or
desktop. Only the lane composition changes.

## Responsive contract

All measurements are logical pixels derived from local constraints.

| Local content width | Layout |
| --- | --- |
| below 694 LP | one centered lane, maximum 400 LP |
| 694-1047 LP | two lanes, 14 LP gap, each maximum 400 LP |
| 1048 LP and above | three lanes, 14 LP gaps, each maximum 400 LP |

- Page inset is 10 LP below 360, 12 LP below 700, and 16 LP thereafter.
- A labeled 184-LP navigation rail appears only at 1280 LP of full window
  width and 600 LP of height. At that transition three useful lanes still fit.
- Below the rail threshold, persistent bottom navigation remains visible.
- At three lanes: Needs Attention and Plan share lane one, Entries owns lane
  two, and Calendar owns lane three.
- At two lanes: Needs Attention and Plan share lane one; Entries and Calendar
  share lane two.
- At one lane: Date, Needs Attention, Plan, Entries, and Calendar stack in that
  order.
- Surplus desktop width becomes centered outer space. No Dashboard lane grows
  beyond 400 LP.
- Text scaling can force an earlier collapse when three or two useful lanes no
  longer fit.

## Surface and record contract

- Header, section frames, and every operational record are visually bounded
  opaque surfaces. The date/action row is compact page-level orientation and
  is not wrapped in another full-workspace container.
- Plan, Entries, Attention, and Calendar have stable semantic tints plus text
  and icons; color is never the only identifier.
- Record surfaces retain their owning section tint instead of reverting to
  white or near-white. Titles use a firm medium-bold hierarchy rather than
  oversized extra-bold type; borders remain visible but subordinate.
- Record containers target 60-64 LP at normal text scale and grow when system
  text scaling requires it.
- The first three Plan and Entry records are visible. `Show all N` expands the
  exact section in place and changes to `Show less`.
- Primary names, dates, money, and states never use ellipsis.

## Header and selected-date contract

- The phone header is one compact row. It does not show the company name,
  repeat the employee, or contain a second stacked action row.
- Phone context is one bounded control naming Alex Morgan's Technician view and
  active vehicle, Transit 12. Start Workday is not inside the header.
- Wide mode uses a single-row operational toolbar with separate labeled View
  and Active Vehicle controls and a visible Add Record action. It is a desktop
  composition, not an enlarged phone header. The toolbar is capped at 800 LP;
  it does not stretch across a three-lane workspace.
- Start Workday occupies the selected-date row without an enclosing card.
  Daily expense totals belong to Expenses and are not displayed as a Dashboard
  date metric.

## Needs Attention dismissal

Closing the expanded panel hides only its large presentation. The unresolved
items remain unchanged and a compact `N unresolved items hidden` control stays
in the same priority position. Selecting `Show` restores the panel. Closing a
panel never approves, rejects, deletes, pays, or otherwise changes a record.

## Calendar

- The Dashboard calendar uses the same direct dependency as 5.7 Active:
  `table_calendar` version `3.2.0`. It must not be replaced by a private
  hand-built `GridView` calendar.
- One shared calendar supports both Week and Month presentation. A single
  contextual control reads `View week` in Month view and `View month` in Week
  view. Switching
  presentation preserves the selected date and the underlying authorized
  dated records; it does not create a second calendar or second data owner.
- Month is the default Dashboard presentation and uses the 5.7-style
  contiguous seven-column grid. It renders the five or six week rows actually
  required by the visible month; it never adds a sixth row merely to keep a
  fixed height.
- UI Lab simulation dates are bounded to 2020-2040 to avoid a known Flutter
  debug precision assertion in `table_calendar 3.2.0` across thousands of
  internal week pages. This is not the production retention policy; the
  production range must follow the approved record-retention contract.
- The calendar remains inside one bounded Dashboard lane in this rebuild.
- The selected day and the actual current day have different visual markers.
- Calendar grid dividers remain visible but subordinate at 0.7 LP, with a
  1-LP outer border. The selected day uses the shared blue action/context tone;
  the actual current day uses a separate green outline and light tint.
- A small badge displays the number of authorized records for a date.
- Selecting a date updates the Dashboard's selected-date heading in this UI
  prototype. A later approved screen may route to a dedicated Day screen.

## Light and dark modes

- Light mode uses a blue-gray canvas and opaque pale working surfaces rather
  than pure white.
- Dark mode uses layered blue-charcoal surfaces rather than pure black.
- Both modes preserve the same hierarchy, borders, labels, and state meanings.
- Final palette tuning follows owner review; layout acceptance does not depend
  on a particular hue.

## Acceptance matrix

- Widths: 320, 360, 390, 412, 700, 718, 800, 915 landscape, 1024, 1180,
  1280, 1366, 1440, and 1920 LP.
- Text scale: 1.0, 1.3, 1.5, and 2.0 representative checks.
- Verify one/two/three lane transitions, rail transition, bounded 400-LP
  lanes, individual record containers, expansion, attention restoration,
  calendar selection, light/dark rendering, no overflow, and visible labels.

## Scope lock

This pass modifies only the Dashboard and the minimum theme/layout/navigation
foundation required to render it. Work, Expenses, Materials, Maintenance,
employee permissions, Hive, OCR, Firebase, and production routing remain out
of scope until this Dashboard receives owner visual approval.

## Next foundation slice: removable Hive simulation data

Immediately after Dashboard acceptance, introduce a repository interface and a
Hive implementation behind it. Fictional companies and their records must be
loaded through a separately identified seed package with stable simulation
account IDs. Production startup never loads that package. A development reset
deletes only those seed namespaces, making all simulation data removable
without special-case deletion code or risk to real records. The 5.7 Hive
implementation is audited read-only and only proven storage behavior plus its
tests are migrated; its UI is not copied.

## Owner-decided future Company Overview

This is blueprint-only planning for a later company-management surface. It does not authorize implementation during the current Technician Dashboard slice.

- `OWNER-DECIDED TARGET`: The user-facing name is `Company Overview`, not `Admin View`. It is a distinct operational view rather than a settings page.
- `OWNER-DECIDED TARGET`: Company Overview is available only to a signed-in person with the required company permission. Hiding the selector is not the security boundary; unauthorized users must also be prevented from retrieving or opening company-level employee data.
- `OWNER-DECIDED TARGET`: The overview shows an employee tile for each employee. Desktop tile sizing should target approximately 100 LP wide by 120 LP tall, while still allowing accessibility text and content constraints to grow the presentation safely rather than clipping it.
- `OWNER-DECIDED TARGET`: Selecting an employee tile opens that employee's authorized company-work detail. The primary information is the employee's schedule for the day, work completed for the day, and work remaining for the day.
- `OWNER-DECIDED TARGET`: Employee detail includes an `Add Assignment` action. Exact assignment creation/import choices remain an open decision; do not invent integration choices until the owner approves them.
- `OWNER-DECIDED TARGET`: Employee detail may summarize that employee's total miles, total expenses for the day, and payments collected for the day. These are derived summaries of authorized source records, not separately editable company-dashboard totals.
- `OWNER-DECIDED TARGET`: Company Overview must not expose an employee's unrelated personal mileage, personal expenses, or other private records.

## Owner-decided Technician plan density

- `OWNER-DECIDED TARGET`: `Today's plan` initially shows at most three scheduled items, matching the current prototype behavior.
- `OWNER-DECIDED TARGET`: When more than three scheduled items exist, the section provides `Show all N`. Selecting it expands the section in normal document flow and pushes every section below it farther down the page. It must never overlay, float over, or obscure the content below it.
- `OWNER-DECIDED TARGET`: Expanded plan content provides `Show less` and returns to the first three visible scheduled items.
- `OWNER-DECIDED TARGET`: The owner currently expects a typical field technician day to contain roughly four to six stops. This is a planning expectation only, not a record limit or validation rule. Longer schedules must remain fully displayable through the same in-place expansion behavior.
