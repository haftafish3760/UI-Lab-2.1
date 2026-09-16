# Technician Dashboard Blueprint

## Purpose

Today's Plan job-menu arrival is governed by the repeated-visit arrival contract
in Work lifecycle's Active job workspace section. The Dashboard projects the
saved Job event; it never owns an independent arrival timestamp.

Give an employee technician or solo owner-technician the information and actions
needed before, during, and after today's field work. The UI Lab demonstrates the
screen and interactions; production data architecture belongs to the main app.

## September 13 Dashboard review contract

September 14 owner correction: compact Dashboard header background is square
and spans the safe available width through the shared 550-LP compact cutoff.
Menu/settings have equal 8-LP outer insets and equal 48-LP control slots.
Vehicle selection has a visible bordered surface and centered text; the labeled
odometer is a separate area to its right. Technician/Admin moves out of the
header to the row opposite Start workday. Header minimum height is 76 LP with
content/accessibility growth, not a hard height cap. Start workday uses the
shared brighter green token. This supersedes the previous header View placement.

Employee monthly results and incomplete contribution are governed by Operations
screen blueprint section 8. Employee results remain distinct from the selected
day's schedule; every supported total opens its supporting records.

September 15 owner correction: Admin retains the same daily Plan/Entries/calendar
composition as Technician, using shared whole-card components and logical-width
layout. Company summary containers precede daily work: Needs attention first
when nonempty, then one compact Recap row. The entire row is
tappable and opens the existing Reports screen with period selection and source
records. Large green/red financial cards are rejected. The 5.7 screenshot was
an illustration of readable totals, not a visual design to copy. Reflow uses
AppLayoutEngine and TextScaler.
Remove the old bottom monthly money panel and its invoiced-revenue metric.
Billing and collections may remain below daily work; the supporting calendar
stays bounded. Employee review remains separate from the company summary.

Needs attention shows the actual authorized count and is completely hidden at
zero. Opening it leads to a separate list grouped into Urgent and Normal;
opening an item leads to its owning record, not directly into an edit or fix.
Routine Estimate, Invoice and expense approvals belong in Normal. The owner
configures urgency and thresholds in contextual alert settings. Pending approval
alone is not urgent. Avoid permanent sample warnings and duplicate Job entries.
Draft/completed Jobs are not overdue active work. Dates, balances, payment terms
and installment plans belong to their source workflows, not dashboard copies.
An unpaid installment may qualify for escalation only under the owner's rule;
a payment must update the source balance before the projected alert changes.

Money received uses confirmed recorded payments; Money spent uses confirmed
expenses. Each shows its month and opens supporting records. Neither invoicing
nor cash difference is a claim of profit. Operations section 8 owns financial
source and permission rules. Payment recording remains separate from processing:
no card or bank credentials are collected. The earlier single Money destination
proposal is superseded by the compact Business overview entry. Hourly averages
and per-vehicle fuel/mileage breakdowns remain requirements for the detailed
overview and must not be claimed available until their sources are verified.

Implementation boundary: the top summary layout uses existing local projections.
The list supports source-provided Urgent/Normal grouping. Current source adapters
remain Normal until owner escalation policies are implemented; do not interpret
this as completed urgent-event detection. Saved owner urgency controls, complete payment-plan
integration and production permission binding are not verified by this layout
change and remain required work. Visual acceptance is still pending.

Current owner direction supersedes the older mobile-header and company Plan/Entries rules below.
Dashboard alone is this implementation slice, on the existing Windows checkout.
Technician and Admin are primary perspectives, with separate Scheduling/Reports
workspaces still required; this does not limit the product to two screens.

- The shared Dashboard header exposes Technician/Admin at every width, menu at
  left and page settings at right, with relevant vehicle/odometer or company scope.
  No redundant Dashboard title. Normal text shares one row; accessibility reflows.
- Admin defaults to Company Overview. Its header selector is the only company/
  employee selector; the duplicate horizontal strip is removed. On compact
  layouts the Admin view control occupies approximately half the row, with
  accessibility-driven height growth. Returning to company never changes actor.
- Company Overview shows current unfinished/unassigned/overdue/paused-return work,
  pending customer estimates, unpaid invoices, outstanding balance, selected-month
  collections/invoicing/spending and assigned workload. Rows open owning records.
  Paused/return states are explicit; there is no invented generic blocked state.
- Partial payments reduce individual outstanding balances; drafts are excluded.
  USD is the current ledger currency. Profit remains unavailable because labor,
  materials and overhead are incomplete. No implied production authentication:
  Work queries use current session creator grants; the UI capability preset and
  employee identities remain development fixtures. Broader team authorization,
  currency/reconciliation and revocation remain release gates.
- Narrow calendars occupy safe viewport width up to shared 500 LP, outside record
  padding. This is a trial cap: seven cells get about 71 LP without stretching
  across a wide workspace. Wide Technician composition retains a supporting lane;
  company daily content uses that same supporting lane. Additional company
  review sections use the shared engine's bounded grid below the daily content.
- Calendar currently receives job plan/status, expense, workday and day-note
  projections plus residual demo entries. Badges count entries, not every planned
  job. Full live dated estimate/invoice/payment, inventory, maintenance and repair
  feeds still need integration; do not describe this as complete module coverage.
- Icon and label both signal the selected bottom destination. FAB size is unchanged.

These rules are implemented for review, not owner visual acceptance. Android build
and widget checks cannot establish iOS/device accessibility or production readiness.

## Dashboard regions

- Dark operational header follows the September 13 contract above; Start workday
  remains below the header.
- Selected date as the first orientation label below the header. Dashboard has
  no competing notification bell; Needs attention is its one action queue.
- Today's Plan: scheduled work still requiring action.
- Today's Entries: recorded activity for the selected day. Omit the section
  when no entries exist, regardless of whether Start workday was pressed.
  Existing entries remain visible before starting and after ending a workday.
- Calendar: a bounded Week/Month navigator. Selecting a date pushes the
  separate Calendar Day screen for that date; it never replaces Dashboard
  content in place.
- Wide layouts follow the September 10 composition below: record columns have
  more reading room than the supporting calendar. Narrow calendar width follows the September 13 contract.

The date is the first content below the shared operational header. Needs
attention, when it exists, follows the date and precedes ordinary work. A
dismissed panel hides the current projection only; it does not resolve or alter
the underlying records.

Owner update, September 7: Needs attention is first in the five-card horizontal
strip, followed by Payments, Expenses, Miles, and Work. Do not also render the
old attention panel. Cards are 96 by 120 logical pixels at normal text size;
long values, translation and accessibility text may grow the shared dimensions.
Measure monetary values before laying out the strip: widen the common card
width when necessary rather than split digits, abbreviate money or clamp text.
Use icons, full labels and visible values; color alone is insufficient.
Plan and Entries use the lanes below this strip. With no entries, omit that
lane and its spacing rather than leaving an empty box.

The owner requires solid whole-card blue for Plan and medium-depth jade for Entries,
not header-only color or section gradients. Inner record rows are lighter and
distinct. September 8 exact shades are a visual trial owned
by UI foundation section 3 and `OperationalCardPalette`, not accepted colors
or private screen values. Employee changes never change these meanings. Keep
the restored light-green Start workday action. The
status-bar background/safe-area treatment must remain unchanged in this pass.

The owner vehicle picker adapts the dark 5.7 dialog with vehicle name/detail.
Exactly the current selection is highlighted BLUE when reopened, not green and
not an always-selected company row. The app-wide intended contract is that
header, picker, records and totals share vehicle/company scope. IMPORTANT:
current Dashboard/financial prototype projections do not yet satisfy that
whole-app filtering contract; this presentation pass is not its implementation.
Do not infer vehicle association from a display label or reassign old records.

The Dashboard receives post-navigation, post-inset logical width from the
shared `AppLayoutEngine` and uses this exact contract:

| Available Dashboard width | Composition |
| --- | --- |
| below 748 LP | bounded record lane; separate safe-width calendar up to 500 LP |
| 748-1131 LP | work column (Plan then Entries), supporting Calendar aligned at the top; 16-LP gap; total maximum 1016 LP |
| 1132 LP and above | Plan and Entries side by side, Calendar at top-right; 16-LP gaps; total maximum 1432 LP |

September 10 owner-requested wide-dashboard redesign: these thresholds use
post-navigation width, not OS or physical orientation. Increased TextScaler
adds 160 LP per scale penalty to the two-column threshold and 240 LP to the
three-column threshold. Work columns remain at or below 600 LP, Calendar at or
below 400 LP. Empty Entries selects the two-column composition instead of
reserving a vacant third column. All panels scroll with one page scroll surface.

The wide header places menu, operational context, confirmed odometer (Technician),
Technician/Admin selector and settings together. Admin uses Company Overview
or the selected employee, never a misleading vehicle selector. Its employee
status controls wrap as compact selectable chips. The wide date command row
offers the existing Add/workday actions and direct End workday review, while
the floating action remains on compact layouts. No new persistence path is used.
Five summary controls share the wide band (96 LP minimum height); long values
and accessibility keep their measured minimum and horizontal scroll if needed.
Wide Plan/Entries show up to six records before Show all; compact remains three.
Workday status does not invent a next-job time. Existing colors, records,
calendar day routes, and all non-Dashboard presentations remain unchanged.

Target audience clarified: independent contractors and small service companies,
typically up to five to ten people. Both views remain. This presentation does
not establish production team authorization, vehicle-scoped financial totals,
live employee telemetry, or any other currently missing data integration.

Implementation boundary: Start Workday still uses its original equal-width
form geometry through the legacy `dashboardFor` adapter. It must not consume
the asymmetric `dashboardOperationsFor` result. Regression explicitly starts
and opens End workday review from a wide dashboard without ending the session.

The 220-LP labeled navigation rail follows UI foundation's shared shell rule:
1000 LP of full-window width for every module, independent of window height.
Switching modules must not change navigation placement. Surplus desktop width becomes outer
breathing room; it never stretches Dashboard cards or the calendar to 600-800
LP.

## Shared visual language

Dashboard uses the application semantic palette rather than screen-local
colors:

- muted orange identifies unresolved Needs attention and pending approval;
- blue section fill identifies Plan;
- jade-green outer section fill identifies recorded Entries;
- orange identifies a record waiting for an authorized decision;
- green identifies approved or completed state; and
- red also identifies a declined or failed state inside a record list.

Color is never the only state indicator. Entry metadata also names `Needs
approval`, `Approved`, or `Not approved`. Every plan and entry remains its own
compact bordered control; neighboring records must not visually merge.

## Record ownership and navigation

- Dashboard is a projection, not an owner of jobs, estimates, invoices, or
  expenses. Every such row carries the stable ID of its owning record.
- Tapping a row opens that exact owning record. A missing stable ID or missing
  source record produces a clear non-destructive message; it must never open a
  plausible but unrelated demo record.
- Returning from a source record refreshes the Dashboard projection. An
  expense approved from Needs attention therefore becomes an approved green
  ordinary entry without requiring an app restart.
- Local day notes and telemetry that have no separate owning module use a
  Dashboard-owned detail route and must be labeled as such.
- Technician and selected-employee Admin reuse Plan/Entries. Company Overview
  uses the distinct business queues defined above. Scope never grants authority.

The exact palette, type, breakpoint, header, calendar, and accessibility rules
are owned by `ui_foundation_blueprint.md`.

## Deferred Day Prep concepts

Day Prep is not part of the current dashboard composition. If it returns, it is
an optional workflow reached from an explicit action or permission-aware module;
it must not displace Plan, Entries, or Calendar by default.

### Truck Ready

Company-configurable physical items normally expected on the assigned vehicle,
including tools, safety equipment, common stock, and consumables. A solo user is
their own company administrator. This is not a job-material source of truth.

### Today's Job Prep

Derived from the technician's scheduled jobs. It aggregates the materials,
parts, tools, and equipment recorded as required by those jobs. Checking readiness
must never alter the job requirement itself.

Production implementation must reuse existing job, technician, vehicle, schedule,
materials, inventory, and start-day models and services. Do not create replacement
models for dashboard convenience. Inspect and report integration gaps before any
production implementation.

## Readiness rules

- Show required, confirmed available, and still needed when quantities apply.
- Do not infer carryover because an estimate was not fully consumed. Carryover
  requires an inventory transaction or explicit technician confirmation.
- Imprecise consumables may use user-confirmed states such as Enough for today,
  Low, or Replace.
- The app records user or company choices. It does not prescribe trade methods,
  interpret building codes, or declare materials interchangeable.
- Only company-, user-, or legally configured requirements may block work. Ordinary
  reminders may warn but must not prevent starting the day.

## Roles and customization

- Solo users configure their own templates and optional dashboard sections.
- Companies can set defaults by role, crew, vehicle, trade, location, or job type.
- Technicians may personalize non-required content; company-required content is
  visibly identified and protected according to permission.
- Renaming or rearranging UI must not change the meaning of historical records.

## Privacy and tracking

Any feature that observes, infers, logs, or reports a person's activity or location
is opt-in. Explain what is collected, why, who can see it, and how to disable it.
Manual workflows remain complete when tracking or AI is disabled.

Odometer visibility is a separate explicit sharing choice. An Admin role or a
development profile does not imply consent to expose it. The dashboard, entry
rows, and detail routes all enforce the same choice.

## Calendar Day workspace and scheduling

- Dashboard opens on the device-local current date. No fixed demo date may act
  as today's production value.
- A calendar cell is a navigation control. It pushes a separate Calendar Day
  route whose header provides Back, current employee/company context, current
  View, and settings for that Calendar Day screen.
- Past Calendar Day routes show confirmed entries and authorized corrections.
  Today shows Today's Plan followed by today's entries. Future days show planned
  work and schedule actions; they do not fabricate historical entries.
- Plan appears before Entries. Each shows its first three chronological records
  and an accessible chevron to expand or collapse the complete list.
- A job plan row opens its exact Work job record, not a generic stop-details
  page. Estimate follow-ups open their exact estimate. A job-related operational
  task may open its owning job but does not pretend to be a job stop.
  An entry row opens the full owning
  record projection (expense, estimate, invoice, payment, trip, workday, or
  note); production routing must permission-check the source route as well.
- Calendar Day's FAB is capability-derived. Plan Work is available only with
  schedule-create permission. Add Day Record is available only with record
  creation permission and never for a future day.
- Work owns jobs, assignments, and schedule commitments. Calendar Day edits the
  same owning records by stable ID and projects the result back to Dashboard;
  it does not keep an independent copy of a schedule.
- Rescheduling a job updates both the Work record's scheduled start/end and its
  Dashboard projection. Mark Arrived and Mark Completed update the owning job
  status before adding the corresponding day record.
- An authorized dispatcher may reassign or reschedule remaining work during the
  day. Conflict checks, before/after audit, offline queueing, and employee scope
  are mandatory. A technician sees the resulting authorized assignment after
  local or organization sync.
- Demo additions are local prototype data. Production must use the existing
  scheduling and record repositories and their audit trail.

## Active job workspace

The dashboard Plan is an operational projection. Opening an assigned job routes
to Work's job record and provides the technician's authorized working surface:

- job identity, status, schedule, assigned technician, and assigned vehicle;
- customer identity, contact methods, service location, and communication notes;
- approved scope, description, field notes, change-order state, and job history;
- the linked accepted estimate and every authorized labor, material, equipment,
  procurement, fee, discount, tax, and deposit line;
- materials actually added or used, kept distinct from the historical accepted
  estimate unless an explicit audited change order changes billable scope;
- receipt/photo/file attachments with review state;
- permission-derived edit, contact, attach, status, and completion actions.

Phone uses one continuous column. A sufficiently wide local content constraint
uses two bounded columns from `AppLayoutEngine.detailWorkspaceFor`; it does not
stretch a phone layout or invent a screen-specific breakpoint.

## Dashboard actions and workday state

- `Start workday` appears only for Technician view, only on the local current
  date, and only while no workday session is active. Starting creates the real
  `Workday started` entry before the header changes to active-workday state.
- Admin Company Overview never offers Start workday. A solo owner-technician
  uses Technician behavior without a meaningless role choice in production.
- A scheduled job may offer Start travel or Mark arrived. An operational task
  never offers Mark arrived. A job that is already active offers Pause; a
  paused job offers Resume; a completed job offers neither.
- Dashboard `Schedule Job` opens Work's job editor with the selected date. It
  does not create an unlinked title-only schedule row.
- Create Estimate, Create Invoice, Record Expense, Record Fuel, Add Receipt,
  and Add Day Record open the screen that owns the resulting record. Saving
  projects that record back into the selected day by stable ID.
- The prototype fixtures must be internally coherent and pass through the same
  store APIs as newly saved records. For example, a 10:30 scheduled job cannot
  simultaneously be seeded as already in progress.

## Admin employee context

- Technician view retains Active Vehicle.
- Admin view opens Company Overview by default. Its compact header summarizes
  company context instead of pretending an employee was selected.
- The selected date remains the first content below that shared header, and
  Needs attention follows the date before the employee status chooser.
- Authorized active employees appear in compact horizontally scrollable status
  cards at every width. A wide screen may show more cards at once, but the cards
  do not stretch into oversized equal-width boxes.
- Selecting an employee changes the employee context used by the same selected
  date, Plan, and Entries projection. It does not grant broader permission.
- Company Overview returns to company schedule, decision queues, company
  entries, and the shared calendar without changing the selected date.
- Employee status is a concise authorized state such as Driving, On a job,
  Available, On break, or Off duty. The dashboard must not subscribe to or
  expose detailed activity that the viewer is not allowed to see.

## Responsive behavior

- Phone: stacked Needs attention, Plan, Entries, and the shared Month calendar. The
  Week control collapses it to the selected week; Month restores all six weeks
  in place. There is no footer action. Tapping a day pushes Calendar Day.
- Tablet/intermediate and wider windows: use the composition table above;
  Calendar stays top-right rather than dropping underneath recorded entries.
  The Month calendar is never a full-width desktop banner.
- Text may become modestly smaller and lighter in weight on compact screens, but
  never lighter in contrast. System accessibility scaling must not clip,
  truncate, or lose actions.
- Dashboard, Work, Expenses, Inventory, and Maintenance remain peer top-level
  modules in the persistent shell; navigating away and back preserves each
  module's working state.

## Required production discovery

Before building this feature in Maintainiac, report the existing models,
repositories, services, permissions, and screens that own the required data.
Identify missing capabilities and stop for review. Do not invent duplicate data
architecture during discovery.

September 15 selector correction: the Admin header is the single company/employee selector. Remove the duplicate horizontal company/employee strip between Admin and Business overview; preserve header access to both scopes.
