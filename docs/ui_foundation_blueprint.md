# Maintainiac UI Foundation Blueprint

Status: implemented foundation draft 0.2  
Last verified: 2026-08-30  
Applies to: every UI Lab 2.1 screen and later approved production integration.
Authority/status: `README.md` and `application_decision_register.md`.

This is the visual and responsive source of truth. Product and data ownership
remain in `maintainiac_app_blueprint.md`. A screen-specific blueprint may add
rules, but it may not contradict this file or create private breakpoints.

## 1. Design Thesis

**Visual thesis:** a calm blue-gray light workspace and neutral-charcoal dark
workspace anchored by a stable charcoal operational header; compact, high
contrast, restrained, and built for work rather than entertainment.

**Content plan:** establish current person/vehicle/workday context, show the
selected date and messages, present plan and confirmed activity, provide the
calendar, then retain predictable navigation.

**Interaction thesis:** use immediate state feedback, restrained Material menu
transitions, and short reflow/selection transitions. Motion must clarify state
or spatial change and must respect reduced-motion settings; no decorative
entrance sequences belong in routine field work.

The product is not minimalist in the sense of hiding useful context. It is
simple because labels, hierarchy, ownership, and next actions are explicit.

## 2. Non-negotiable Rules

1. Accuracy, consistency, security, privacy, dependability, and accessibility
   outrank decoration.
2. Every screen uses `AppLayoutEngine`, `AppTheme`, and shared surface tokens.
   A feature file may not invent device names or alternate global breakpoints.
3. Layout uses the local logical width after navigation and page insets. It
   never uses physical pixels, monitor inches, pixel ratio, operating-system
   name, or a guessed device model.
4. Flutter's platform `TextScaler` remains active. Never clamp the entire app's
   text scale to make a layout pass.
5. Primary controls, names, dates, money, and state labels may not use ellipsis.
   Reallocate space, intentionally split a label, simplify secondary chrome, or
   reflow the region. At accessibility sizes, content may grow vertically.
6. A light screen may use the intentional charcoal header or navigation anchor,
   but its working canvas must not mix black content panels with white panels.
7. Pure white and pure black are not routine light-mode surfaces. Status and
   accent colors must not become entire competing page themes.
8. Controls and surfaces use modest radii. This is a utility application, not a
   social-feed card system.
9. Before a UI slice enters approved production integration, its blueprint, tests, semantics, permission
   behavior, and visual acceptance must agree.

## 3. Semantic Color Contract

### Owner correction — September 8, 2026: meaning-based whole-card color

Consistency is mandatory, not optional styling. Plan uses the same blue family
on every screen; Entries uses the same jade-green family on every screen.
Employee/company context changes labels and queried records, never the palette.
Color covers the ENTIRE outer card: title background and body have exactly one
solid fill, without a gradient or different header shade. Individual record rows
are lighter neutral surfaces, NOT the same shade as the outer card. Preserve
clear boundaries between nested rows. Labels, icons and readable contrast must
also communicate meaning; color alone is insufficient.

The following shared `OperationalCardPalette` tokens are a Dashboard VISUAL
TRIAL, not owner-approved exact shades. This supersedes the pale header-only
Plan/Entries treatment below. Reuse the shared components; do not privately
recolor other instances of the same component.

| Meaning | Gradient start → end | Record-row surface |
| --- | --- | --- |
| Plan | Solid `#1976B2`, based on the latest menu-button reference | Light blue `#AFCFE1` |
| Entries | Solid medium jade `#72AE88` | Slightly lighter `#AEC8B7` |
| Needs attention / Needs approval | Solid muted orange `#C8955B` | Same `#C8955B` fill for pending approval rows |
| Payments | Money green `#2F7D32` → `#246529` | — |
| Expenses | Brick red `#B94A46` → `#943833` | — |
| Miles | Violet `#6954A0` → `#51407F` | — |
| Work | Teal `#146C70` → `#10585B` (trial, distinct from violet Miles; no peach) | — |

Dark fills use `#F7F6EF` foregrounds; jade/orange and lighter inner rows
use `#172A33`. Verify contrast throughout summary gradients,
on nested rows, and in their menus. Owner update: pending approval receives a
full muted-orange fill matching the Needs attention summary card, not only a
thin outline. Retain the explicit Needs approval label; ordinary entry rows
remain green-tinted. Approved/denied status retains its separate label/accent.
This changes presentation, not approval permissions or state transitions.
FABs use shared charcoal `#303B40`, distinct from
Plan blue. Start Workday remains `#6AD39B`. Do not change the approved status-bar
background or page geometry during this trial. Canvas/navigation remain neutral;
this is not permission to give every page an unrelated color theme.

Recorded-activity sections use `RecordedEntriesSection` from `shared/`: it owns
the solid outer fill and the scoped row/text/menu treatment. Dashboard,
Calendar Day and the admin projection reuse `TodayEntries` within that wrapper;
Expenses and Payments supply their domain-specific content to the same wrapper.
Do not map an Expense or Payment into a Dashboard-owned record merely to reuse
its appearance. Preserve permissions, amounts, IDs, expansion and destinations.
Future recorded-entry sections must adopt this wrapper rather than copy its
colors. Different record fields may use different row-content widgets.

Plan and entry-section titles use `OperationalSectionHeading`: 48 LP minimum
content height plus 8 LP top and 2 LP bottom padding and a 1 LP divider.
This places the divider approximately 16 LP below the normal title text box,
not below an additional oversized header gap. Preserve record container sizes.
The empty Show all slot does not collapse the title row and change the spacing.
Larger/localized text may grow naturally. The divider separates title from
records without changing the title's background. Dashboard Plan/Entries,
Expense entries and Payment entries reuse this heading rather than copy it.
Today's Entries uses the entry-row light green for its title divider; this
color adjustment does not change divider position, padding, or record sizes.

Gradient comparison, pending owner selection: `lib/gradient_preview.dart` is an
isolated visual entry point using the real Plan/Entries widgets and unchanged
inner rows. It does not write records or replace the normal app entry point.
The pronounced Plan gradient uses the protected 5.7 menu `_ScreenButton` colors
from `lib/screens/settings/system_settings.dart`: `#1976B9` to `#0F4068`, top to
bottom. Subtle uses the same top with 30% of that endpoint change. Entries tries
`#89C49E` to `#59966C`, likewise at full or 30% strength. Headers are transparent
over one continuous section gradient, never separately colored. These green
endpoints are proposals, not accepted owner colors.

The selected Entries green remains unchanged by the September 8 shared-widget
pass. Dark-mode visual acceptance is still open. Opaque outer/row fills must
be verified over a contrasting canvas; translucent icons/borders do not prove
background bleed. A passing opacity test is not proof that an earlier reported
device artifact was reproduced or fixed.

### Light mode

| Token | Value | Use |
| --- | --- | --- |
| Canvas | `#C9D8DF` | Page background; muted blue-gray, never ghost white |
| Surface | `#C5D6DE` | Primary cards, sheets, and bottom navigation |
| Muted surface | `#B6CDD7` | Rows, fields, and secondary regions |
| Strong surface | `#BED1DA` | Section headers, selected navigation, compact controls |
| Ink | `#172A33` | Primary text and icons |
| Muted ink | `#3D535E` | Secondary descriptions and metadata |
| Border | `#91A8B3` | Routine separators and surface outlines |
| Strong border | `#8298A2` | Interactive outlines and stronger separation |
| Primary blue | `#285F78` | Primary action/selection; not a page background |
| Blue tint | `#91B8CD` | Legacy general accent; NOT the Plan fill |
| Success green | `#0B6B50` | Confirmed/success state |
| Green tint | `#95BFA8` | Legacy general accent; NOT the Entries fill |
| Warning | `#8B5A12` | Needs-attention state |
| Warning tint | `#F2E5CC` | Warning background |

Module identity and record state are separate systems. Expenses may use its
muted amber identity while an Expense record still uses the same state color as
an equivalent record elsewhere. `AppSemanticColors` owns these shared states:

| State | Light foreground | Light surface | Meaning |
| --- | --- | --- | --- |
| Current | `#1E607C` | `#CFE5EF` | Selected/current-day information; not the Entries identity fill |
| Planned | `#5D4B83` | `#E1D9EF` | Upcoming and recurring planned activity |
| Success | `#126A4B` | `#D3E9DE` | Approved, saved, completed, or otherwise confirmed |
| Attention | `#944509` | `#F3D8C2` | Action is required but is not destructive failure |
| Danger | `#A62F38` | `#F1D0D3` | Destructive action, failure, overdue, or serious exception |
| Draft | `#526771` | `#D6E1E6` | Incomplete, inactive, or not yet submitted |

Dark mode provides distinct counterparts through the same extension. A feature
must not reinterpret one of these colors or introduce a private substitute.
Color always appears with an explicit label, icon, border, shape, or semantic
description. Normal primary actions use the module/primary action color; green
is not applied to every button because it must continue to mean confirmed
success.

The current blue/planned violet pairing is provisional until rendered owner
review. Final state pairs must be checked with common color-vision simulations
and must remain distinguishable by label, icon, border treatment, and wording
when all color is removed. A blue/green current-versus-planned alternative may
be tested, but its planned green must remain visibly separate from the darker
confirmed-success green; hue alone is never the distinction.

The top operational header intentionally remains `#162326`. Header controls use
`#24353A` or `#162529`, `#607B82` borders, `#F2F5F4` primary content, and
`#D0D9DA` secondary content. Header-owned menus remain dark so opening a menu
does not produce a white island inside the dark header.

### Dark mode

Dark mode uses layered neutral blue-charcoal working surfaces so blue-green
color does not glow through the charcoal and panels do not collapse into
black-on-black: canvas `#090C0E`, surface `#121719`, muted surface `#191F22`,
strong surface `#232B2F`, ink `#E8ECEC`, muted ink `#ADB8BB`, border `#354147`,
and strong border `#53646C`. Muted blue and green remain semantic
action/status accents, not page undertones. Hard-coded light surfaces are
prohibited in a dark-mode screen.

Except for the owner-approved Dashboard blue Plan and green Entries section
fills described in section 9, job-workspace section headers, borders, and
routine rows use the neutral dark surface tokens. Blue and green may remain on
small icons, selected state, status labels, and explicit actions, but must not
form a colored edge or undertone around a charcoal working panel.

### Contrast

- Routine body text targets WCAG AA contrast or better.
- State must never be communicated by color alone; pair it with text, icon,
  shape, or semantics.
- Disabled content must remain distinguishable without becoming unreadable.
- High contrast means strong foreground/background separation, not oversized or
  excessively bold typography.

## 4. Shape, Density, and Elevation

| Token | Value |
| --- | ---: |
| Control radius | 7 LP |
| Surface/header radius | 8 LP |
| Popup/sheet radius | 10 LP |
| Routine border | 1 LP |
| Phone page inset below 360 LP | 8 LP per side |
| Page inset from 360 through 699 LP | 12 LP per side |
| Page inset at 700 LP and above | 16 LP per side |
| Dashboard lane gap | 18-48 LP from local available width |
| Routine compact control | 42-44 LP, allowed to grow for accessibility |
| Operational row | 56-60 LP at normal scale |

Use one quiet 2-LP-offset shadow only when a surface needs separation from the
canvas. Do not place shadows and heavy borders on every nested region.

## 5. Typography Contract

Typography responds mildly to available logical width; platform text scaling is
then applied by Flutter.

| Role | 320-LP workspace | 1000-LP workspace | Weight |
| --- | ---: | ---: | ---: |
| Control | 12.5 | 13 | 600 |
| Page/date title | 18 | 21 | 600 |
| Section title | 15 | 16.5 | 600 |
| Operational row title | 13 | 14 | 500 |
| Body | 14 | 14 | 400 |
| Secondary metadata | 12-13 | 12-13 | 400-500 |

There is no width at which primary text becomes lighter in color merely because
the window narrowed. Narrow layouts reduce size and weight modestly while
preserving contrast. Avoid weight 800/900 for routine page, row, and button text.

## 6. Navigation Contract

### Owner requirement: secondary-screen return navigation

Added September 5, 2026. This is a required implementation and acceptance
contract, not a claim that every existing route already complies.

- Every secondary screen outside the top-level navigation destinations must
  provide a visible, accessible Back control on phones, tablets, and desktop,
  including wide layouts. Do not rely solely on a gesture, system button,
  keyboard shortcut, or the bottom navigation to leave a secondary screen.
- Back returns to the actual originating screen and preserves its selected
  date, filters, and scroll position where applicable. A deep-linked screen
  without an existing back stack provides a predictable owning-screen fallback.
- Preserve supported native back navigation, including iOS edge-swipe back and
  Android system back/button or gesture behavior. The iOS home gesture is not
  in-app Back. Do not invent an app-wide swipe gesture that conflicts with
  calendars, horizontal lists, or other controls.
- Visible Back, native back gestures, and keyboard back actions must share the
  same navigation and unsaved-change policy. Protect unsaved edits with a
  recoverable draft or an explicit user choice; never silently discard work.
  If a dirty form must interrupt native back, explain why and keep visible Back
  available. The assistant must not choose a consequential confirmation for
  the owner during validation.
- During each screen's implementation, verify return navigation on narrow and
  wide layouts, supported native gestures, keyboard/accessibility access,
  unsaved edits, and deep-link fallback. Record actual verification separately
  from this requirement. Do not mark all platforms verified from widget tests.

### Existing shell rules

- Dashboard may use the 220-LP labeled rail when the full window is at least
  1000 LP wide and 600 LP high, because its two compact lanes still fit after
  the rail and page insets. Other modules retain the 1338-LP shared threshold
  until their complete-screen repair verifies an earlier transition. The shell
  reevaluates navigation when the selected top-level module changes.
- Work's repaired landing screen uses the rail from 1000 LP of shell width,
  independent of height. Its existing scrollable destination list handles short
  windows; resizing height does not move navigation to another edge. Other
  modules retain their existing transition until reviewed separately.
- Otherwise use bottom navigation. Its height interpolates from 62 LP on a
  narrow phone to 66 LP on wider windows.
- Show every destination name at every mobile width. A user must not select a
  destination merely to learn what it is. Icons reinforce labels; they do not
  replace them.
- The bottom bar uses the light/dark surface tokens. It is not a charcoal bar in
  light mode.
- Dashboard, Work, Expenses, Materials, and Maintenance are peer applications
  inside one persistent shell. Selecting one changes the active top-level
  workspace and selected navigation state; it does not push a subordinate page.
  Repairs retain their own record type and lifecycle inside Maintenance; a
  Repair list, detail, or form is a pushed Maintenance workspace, not a sixth
  primary destination.
- The shell preserves each module's state while switching. Forms, record detail,
  and other subordinate workflows may push over the shell and return to their
  owning module.
- Permission-denied destinations do not render and cannot be reached by route,
  search, count, deep link, or action.
- A future collapsed rail or hamburger menu is selected only from the local
  width contract. Desktop, tablet, phone, macOS, Windows, iOS, and Android do not
  receive hard-coded navigation modes merely because of their platform name.
- The shell passes its actual `LayoutBuilder` size to
  `AppLayoutEngine.navigationFor`. A larger surrounding `MediaQuery`, monitor,
  host window, or split-view parent cannot force rail navigation into a locally
  constrained shell. Bottom-navigation typography also uses that control's
  local width.
- Compact module workspaces may use one labeled FAB for their permitted add
  menu. Wide/rail workspaces normally replace it with visible labeled actions;
  the same capability list drives both presentations.

## 7. Workspace and Lane Contract

The numeric modes below describe an existing shared composition, not a universal
phone/tablet/desktop or one/two/three-column design requirement. Each workflow
must justify information/action priority, bounded components and reflow through
the shared engine using local logical constraints and TextScaler. Current
layouts remain redesign candidates; no private global breakpoint system.

The lane calculation receives the remaining width after rail and page insets.
That value is normalized to a nonnegative local width before any lane, detail,
or compact-action geometry is emitted, so startup and resize transitions cannot
produce negative widths. The shared result type is
`OperationsWorkspaceLayout`; it is not owned or named after any one module.
Its `showsInlineModuleActions` result follows the same measured lane decision:
one lane keeps the labeled compact action route, while two or three lanes may
show the same permitted actions inline. Screens cannot choose action
presentation from rail presence or the surrounding global window.

| Mode | Normal-scale requirement | Lane behavior |
| --- | ---: | --- |
| One lane | below 718 LP | centered; maximum 600 LP |
| Two lanes | at least 718 LP | two lanes, minimum 350 LP, responsive 18-48-LP gap |
| Three lanes | at least 1086 LP | three lanes, minimum 350 LP, responsive 18-48-LP gaps |

Each record/form lane stops growing at 500 LP. Surplus width first increases
inter-lane breathing room, capped at 48 LP. Dashboard's supporting Month calendar
occupies one lane capped at 400 LP; it must not expand across the workspace.
Other module calendar composition requires an explicit shared-engine contract,
not a blanket full-width exception. At increased
text scale the engine raises the two- and three-lane requirements so record
columns collapse before content crowds.

Ordinary two-field form rows use `AppLayoutEngine.stackFormFieldsFor`. The
calculation receives the local width inside the form plus Flutter's active
`TextScaler`; it keeps two useful fields side by side only while each retains a
250-LP working width and the shared 12-LP gap. A screen or form may not invent a
second private threshold for the same decision.

Plain-language employee permission questions use that same width-and-text-scale
decision for their question and Yes/No choices. The choices remain beside the
question only while both are readable; otherwise they move below it without
changing the selected value, dependency rules, or authorization semantics.

One cohesive data-entry form uses `AppLayoutEngine.formWorkspaceWidthFor` and
stops at 760 LP. Phone fields stack; a tablet or desktop can use two internal
field columns without stretching the form across the application canvas.

Dashboard, Work, Expenses, Materials, Maintenance, Maintenance-owned Repair
workspaces, and Reports use `AppLayoutEngine.operationsFor`. Compatibility entry
points may delegate to that calculation, but a top-level module cannot select a
different lane threshold. Maintenance and Repairs may supply different records
and actions later; they do not receive a second responsive engine. One lane
remains below the measured two-lane requirement, two lanes require at least 350
LP each, and three lanes require at least 350 LP each. Normal operations lanes
stop at 500 LP. Compact quick actions stop at 210 LP wide and 48 LP high at
normal text scale; accessibility may increase height but never truncates the
label.

Record directories nested under a module, including Saved Clients, reuse these
same one/two/three-lane calculations. They do not stop at two oversized desktop
columns or declare their own width threshold; active text scaling collapses the
shared lanes before customer or record metadata crowds.

Detail screens derive both their content lanes and compact-versus-wide action
presentation from the same local post-navigation constraint and active
`TextScaler`. A wide application window cannot suppress a compact action route
inside a narrow rail, split view, or bounded pane, and a screen may not use the
global `MediaQuery` width as a competing action breakpoint.

Dated module routes, including Work Day, apply the same rule to compact FABs
and wide inline add controls. The action cannot switch presentation separately
from the records and lanes it operates on.

Compact operational metric groups use
`AppLayoutEngine.summaryMetricColumnsFor`. They may present two metrics per row
on a normal phone and four in a sufficiently wide pane, but increased text scale
collapses the group before labels crowd. Modules do not declare private metric
grid thresholds.

The shared `Needs attention` panel derives its heading and row typography from
the panel's own lane constraints. A bounded attention panel never takes desktop
type sizing merely because its parent window is wide.

Dashboard plan rows and recorded-entry rows use the same
`AppLayoutEngine.stackOperationalRecordFor` decision. At ordinary text size
they retain the compact 56-60-LP-class row whenever it is readable; narrow
constraints or accessibility text reflow the metadata without truncation.

Work's top-level directory is a distinct compact-navigation pattern based on the
accepted 5.7 invoice-home language. `AppLayoutEngine.workShortcutsFor` lays out
six labeled destinations around 62-LP icon surfaces: up to four columns on a
normal phone, six when a wide workspace supports them, and fewer columns when
measured words or accessibility text need more width. The icon does not replace
its label. Existing action directories retain their three/six-column calculation;
the Work destination grid supplies its measured label width to the shared engine.
Dashboard, Workday, Expense, Inventory, Job, and Work action directories reuse
that same calculation rather than declaring screen-private column thresholds.
Action labels and any visible detail copy have no fixed line cap; tiles grow
vertically when translation or accessibility scaling requires it.

## 8. Shared Operational Header Contract

The header is one shared app component and an intentional dark orientation
anchor. Dashboard, Work, Expenses, Materials, Maintenance, its Repair
workspaces, and their pushed
workspaces may configure its context and actions, but may not recreate its
layout, palette, View menu, or responsive rules privately.

The context control names both the kind of scope and its selected value, such as
`Active vehicle: Transit 12 · 42,116.4 mi`, `Employee: Alex Morgan`, or `Employee: Company
Overview`. The body renders records for that exact context without repeating the
selected employee as a second large heading. Admin screens may also show the
shared horizontal Employees strip for at-a-glance status and direct selection.
The selected View and employee/company scope persist while switching top-level
modules; each module keeps its own selected date and record filters.

Deferred modules do not get deferred layout rules. When genuine Inventory
control, Maintenance, and its Repair workspaces are implemented, they must
consume the same shared
post-navigation logical-width engine and regression sweep. Different record
ownership never permits private breakpoints, device-name branches, or a second
calendar-width contract.

### Contents and order

1. navigation or Back action;
2. optional screen action such as Start Workday;
3. current operational context and selector;
4. View selector;
5. settings for the exact screen currently shown.

Owner Dashboard presentation supersedes the legacy Start/View header below:
compact title/navigation/settings row, vehicle and separate odometer beneath,
no role selector, and Start Workday in the body. The background fills the phone
content width and is capped by the shared dashboard workspace plus its gutters
on wide windows; inner controls remain bounded. No status-bar/safe-area change.
Normal vertical padding is 0 LP above and 6 LP below, with a 2-LP row gap;
required text can grow rather than being clipped. The chevron sits 4 LP beside
the selected name, not at the far end of an expanded empty row.
While active, the body shows the workday summary and labeled Actions entry.
Both Start Workday actions use shared `#6AD39B` with dark readable text.
Legacy non-owner variants remain staged migration work. Work omits
the Start action and uses Company Overview/employee context. The settings
button is contextual; it does not open one undifferentiated settings warehouse
for the entire product.

The notification bell is not part of this control distribution. It lives beside
the selected date immediately below the header.

### Sizing and reflow

The Start/View split-control rules below describe the retained legacy variant,
not the current owner Dashboard or Start Workday presentation.

- Header internal horizontal padding is 8 LP below 420 LP and 12 LP otherwise.
- Menu and settings each occupy a 42-LP control extent. A route without a
  settings action reserves that same 42-LP slot so the header does not shift or
  exceed the layout engine's measured row budget.
- Active Vehicle is 176-240 LP in a one-row header and never stretches beyond
  240 LP. Its selected vehicle and confirmed odometer stay together in that
  header context. In a compact header, View stays in the first row and context
  becomes the next full-width row; neither is silently omitted or moved into
  the body.
- Normal context-control height is 42 LP. It grows from actual `TextScaler`
  measurements when large accessibility text requires more lines.
- Normal action height is 44 LP and may grow for accessibility.
- Start Workday is a dashboard-specific action. On compact widths, Start Workday
  and View remain side by side whenever their measured split-label minimums fit.
  At the 320-LP test window, the 8-LP page insets leave a 304-LP header; its
  288-LP internal action row still holds both controls.
- A label may intentionally become `Start` / `workday` or `View:` /
  `Technician`. This is a designed two-line label, not clipping, overflow, or
  ellipsis.
- The two action controls stack only when the measured text-scaled minimums no
  longer fit. Large accessibility text can therefore stack earlier without
  changing the normal S25-Ultra-class layout.
- Technician is the first View menu item and Admin is the second. Both the View
  menu and vehicle menu retain the dark header palette.

At normal text scale, Admin employee-status cards are 96 LP wide by 120 LP tall
and scroll horizontally. Accessibility scaling may increase both dimensions;
it never shrinks, clips, or ellipsizes the employee name or status. The shared
strip measures the longest authorized name and status at the active
`TextScaler`, so every card in the strip receives sufficient common height.

### Shared context and record behavior

- Technician active vehicle selection is one operational context shared by
  Dashboard, Workday, and Inventory. A screen cannot invent a second selected
  truck. Admin Inventory may narrow from Fleet Overview to a truck locally
  without changing a technician's assigned vehicle.
- Dashboard and its pushed Calendar Day route read and update the same records,
  keyed by date plus Company Overview or employee scope. Adding an entry,
  changing approval state, or changing the plan must be visible when returning
  to Dashboard; a route-local copy is prohibited.
- Contextual display settings must visibly alter the screen they describe and
  survive returning from that settings route for the current app session. A
  switch that changes nothing is a defect.
- A settings control renders only when that exact screen has an honest,
  functional choice. A dead placeholder sheet is prohibited. Top-level module,
  calendar-day, and receipt-intake settings remain required; subordinate forms
  add the control when their own setting is implemented.
- Required operational labels wrap or reflow. Names, dates, money, units,
  statuses, and action labels must not use ellipsis, fading, or clipping to hide
  information.

## 9. Dashboard Body Contract

September 10 wide-dashboard override: `technician_dashboard_blueprint.md` owns
the revised asymmetric 748/1132-LP composition, text-scale adjustments, bounded
record/calendar widths, wide context/view toolbar and inline workday actions.
It supersedes this document's inherited equal-400-LP Dashboard lanes and
owner-without-View statements on wide Dashboard only. Portrait, other modules,
semantic color, safe areas, and calendar behavior are unchanged. Wide previews
show six records; the three-record statements below remain the compact default.

### Date and attention

- The full selected date is the section orientation label.
- Dashboard does not show a notification bell beside the date. `Needs
  attention` is the Dashboard's single action queue and is FIRST in its five-card
  horizontal summary strip, without a duplicate banner. Reminder infrastructure may
  remain available through an explicit global route elsewhere; it does not
  compete with the Dashboard queue.

### Today's Plan

- Whole blue card family from section 3, with title, schedule icon, and Show All.
- Up to three operational stops in the collapsed view.
- Rows use compact metadata, a status marker, one clear title, and a menu.
- Normal rows are 56-60 LP. Narrow rows reorganize title and time rather than
  shrinking contrast or using ellipsis. Accessibility text may increase height.

### Today's Entries

- Solid jade-green outer card from section 3, with title and record count.
- Confirmed activity is chronological and opens its owning record.
- Omit the section and its spacing only when the selected day's entries are
  empty. Workday-start state is not a visibility gate.
- Entry titles use medium weight; details use high-contrast muted ink.
- The section is a projection. It does not duplicate source records.

### Calendar

- The Month calendar occupies one Dashboard lane and never exceeds 400 LP.
- In a one-lane workspace, show one week plus a Month control in the calendar
  header.
- At larger one-lane widths and in two-/three-lane dashboards, show the month.
- Month cells use the shared 70-LP normal-scale row-height contract at every
  width, increasing only when accessibility text needs it. The grid
  may widen with the module but dates, badges, and status markers stay compact
  instead of scaling with the cells.
- Month expands the same calendar in place using a short size animation;
  Week collapses it. The calendar has no explanatory footer or duplicate record
  state. Tapping a day pushes the separate Calendar Day route.
- The date owns a compact outlined square in the upper-right of every cell.
  Authorized record counts sit unboxed in the lower-left with a small dot and
  subdued ink. A routine count stays gray; only a genuine attention state may
  recolor the dot and count. The count never receives a competing square,
  filled pill, or large centered treatment.
- Counts include authorized records only. Tapping a date changes selected
  date context on Calendar Day; it does not silently create, edit, or confirm
  records. An explicit permitted Calendar Day action mutates the owning module
  record and its Dashboard projection refreshes from that same source.
- Today uses a compact underline/state marker without writing the word `Today`
  inside the grid. A user-selected date uses a full-cell outline and distinct
  selected surface. When Today is selected, both signals remain visible; no
  state relies on color alone and the record count remains separate.

## 10. Admin Company Overview Contract

- Switching to Admin opens Company Overview first; it does not arbitrarily pick
  an employee or imply permission to all company data.
- Active employees remain a compact horizontal strip at every width. Selecting
  one employee changes the existing selected-date workspace to that person's
  Plan and Entries. `Company overview` returns without changing the date.
- Company Overview uses the same Dashboard engine: one stacked lane, two useful
  lanes, or three bounded 400-LP lanes. Needs attention remains directly above
  Company schedule in the priority lane; Company entries and Calendar follow
  the same two-/three-lane composition as technician scope.
- Company entries explicitly identify the employee and record type. Needs
  attention contains decision queues such as estimate approval, assignment,
  receipt review, and overdue invoices, but actions render only when permitted.
- The UI Lab panels demonstrate layout and information hierarchy. Production
  counts, permissions, employee status, and routes remain owned by 5.7 services.

### Navigation safe area and module color

- Bottom navigation always sits above Android system navigation and the iOS
  home indicator using the platform-reported bottom safe area. A 4-LP minimum
  breathing space remains when the reported inset is zero.
- Color is a redundant scanning aid, never the sole carrier of meaning.
  Dashboard uses blue-gray, Work blue, Expenses muted amber, Inventory muted
  green, and Maintenance slate-violet.
- Light and dark modes use separate module tokens with at least 3:1 contrast
  against their navigation surface. Routine icons may not introduce one-off
  bright colors outside this semantic map.

## 11. Accessibility and Localization

- Required QA text scales: 1.0, 1.3, 1.5, and 2.0.
- Minimum normal touch target is 42 LP in this dense utility prototype; production
  platform review must verify 44/48-LP guidance where applicable.
- Keyboard focus order follows visual order. Every icon-only action has a
  tooltip and semantic label.
- When visual space hides secondary vehicle metadata at very large text scales,
  its full value remains in the selector and accessibility semantics.
- Do not encode U.S. date, currency, distance, or unit assumptions into layout.
  Strings must tolerate Spanish and French expansion and locale-specific order.
- Unit choice is organization/user data: U.S. customary or metric. Layout does
  not branch on country names.
- The first onboarding question is `Choose a language`: English, Español
  (U.S.), or Français (Canada). The measurement choices are visibly labeled
  `U.S. — miles, feet, inches, gallons, and quarts` and `Metric — kilometers,
  meters, centimeters, liters, and milliliters`; customer-facing UI does not
  use `Imperial` for this choice.
- `localization_measurement_blueprint.md` owns the shared locale, unit,
  receipt-package, conversion, persistence, and regression contract. A screen
  may not create a private translation or measurement implementation.
- RTL support must be preserved through directional padding and positioning.

## 12. AI-ready Implementation Rules

This app may be maintained by different Codex models. The contract must remain
machine-verifiable instead of depending on remembered conversation.

1. Read `AGENTS.md`, this file, and the relevant screen blueprint before editing.
2. Update semantic tokens or `AppLayoutEngine`; do not scatter one-off fixes.
3. Add a regression test for every repaired width, text scale, or state.
4. If a design decision changes, update code, this blueprint, and tests in the
   same change.
5. Demo data stays outside layout decisions. Approved production adapters provide
   permissions and records; their destination/source is not chosen by this file.
6. AI/OCR/GPS suggestions are visibly proposals until user-confirmed. No AI
   surface receives broader customer, financial, employee, or location data
   merely because it can improve a suggestion.

## 13. Required Regression Matrix

At minimum, test 320, 360, 390, 412, 600, 717, 718, 800, 1085, 1086, 1180,
1337, 1338, 1440, and a wide desktop constraint. Combine representative widths with text
scales 1.0, 1.3, 1.5, and 2.0.

For each relevant screen verify:

- no overflow, clipping, ellipsis, accidental horizontal scrolling, or early
  action stacking;
- expected navigation mode and lane count;
- surface and calendar maximum widths;
- light and dark palette consistency;
- keyboard, semantics, and touch targets;
- permission-denied content absent from navigation, counts, queries, and routes;
- locale expansion, U.S./metric values, and RTL direction where supported;
- restart, offline, interruption, and source-record integrity for production
  slices.

Static analysis and widget tests are necessary but not visual acceptance. The
owner must review the running UI Lab build before a presentation slice enters
approved production integration.

## 14. File Ownership and Size

- `lib/src/theme/app_theme.dart`: semantic color, type, radius, and component
  theme tokens.
- `lib/src/layout/app_layout_engine.dart`: navigation, page inset, typography,
  lane, header measurement, and text-scale rules.
- `lib/src/shared/`: reusable surfaces and non-feature-specific UI primitives.
- `lib/src/screens/<feature>/`: feature composition and interactions only.
- `test/dashboard_responsive_test.dart`: representative responsive behavior.

Production Dart files stay at or below 500 lines. Split by cohesive widget,
state, layout, or interaction responsibility and run the affected regression
tests immediately after each split. Functionality and reliability still outrank
a mechanical split; any exception requires a documented technical constraint
and evidence that the safer split would damage behavior or discoverability.

## 15. Current Implementation Boundary

Implemented in this foundation pass: coherent light/neutral-charcoal dark theme
tokens, dark header contract, responsive header controls, notification/date
relationship, shared 500-LP lane calculations and expanding gutters, compact
typography, distinct Today/Selected calendar states, a persistent top-level
module shell, safe responsive bottom navigation, a functional whole-app
Light/Dark/Device appearance choice, and regression tests. The current rendered
contract now also proves Dashboard, Work, Expenses, Materials, and the deferred
Maintenance placeholder switch together at 390-, 800-, and 1120-LP windows,
collapse together at 2x text, remain bounded at wide widths, and retain bottom
navigation when the shell itself is narrow inside a larger host window.

Not yet visually accepted: final color tuning by the owner, production fonts,
complete keyboard/screen-reader audit, every locale, every module screen, and the
5.7 integration. Those remain explicit work, not implied completion.
