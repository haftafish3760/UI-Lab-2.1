# Technician Dashboard Blueprint

## Purpose

Give an employee technician or solo owner-technician the information and actions
needed before, during, and after today's field work. The UI Lab demonstrates the
screen and interactions; production data architecture belongs to the main app.

## Approved dashboard regions

- Dark operational header: active vehicle, odometer, navigation,
  start-workday action, role view, and settings.
- Selected date as the first orientation label below the header. Dashboard has
  no competing notification bell; Needs attention is its one action queue.
- Today's Plan: scheduled work still requiring action.
- Today's Entries: completed stops and other records created during the day.
- Calendar: a bounded Week/Month navigator. Selecting a date pushes the
  separate Calendar Day screen for that date; it never replaces Dashboard
  content in place.
- Wide layouts: Plan, Entries, and Calendar each use a bounded Dashboard lane
  no wider than 400 LP.

The date is the first content below the shared operational header. Needs
attention, when it exists, follows the date and precedes ordinary work. A
dismissed panel hides the current projection only; it does not resolve or alter
the underlying records.

Needs attention and Plan always share the priority lane, with Needs attention
directly above Plan. At two lanes, Entries and Calendar share the second lane.
At three lanes, Entries and Calendar receive their own lanes. A missing Needs
attention projection removes the panel and its spacing; it does not leave an
empty placeholder.

The Dashboard receives post-navigation, post-inset logical width from the
shared `AppLayoutEngine` and uses this exact contract:

| Available Dashboard width | Composition |
| --- | --- |
| below 748 LP | one centered lane, maximum 400 LP: attention, Plan, Entries, Calendar |
| 748-1247 LP | two lanes: attention plus Plan; Entries plus Calendar |
| 1248 LP and above | three 400-LP lanes with 24-LP gaps: attention plus Plan; Entries; Calendar |

The 220-LP labeled navigation rail begins on Dashboard at a 1000-LP full-window
width and a 600-LP height, after two useful Dashboard lanes fit. Other modules
retain the shared shell's 1338-LP threshold until their own complete-screen
repair pass confirms an earlier transition. Surplus desktop width becomes outer
breathing room; it never stretches Dashboard cards or the calendar to 600-800
LP.

## Shared visual language

Dashboard uses the application semantic palette rather than screen-local
colors:

- red identifies unresolved Needs attention work;
- purple identifies planned work;
- blue identifies ordinary current-day records;
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
- Technician, selected-employee Admin, and Company Overview use the same Plan
  and Entries components. Scope changes the authorized query, not the visual
  grammar.

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
- Tablet/intermediate: two controlled lanes once 748 LP remains after page
  insets; no stretched cards.
- Wide desktop: persistent labeled navigation and three 400-LP Dashboard lanes
  only once all three fit. The Month calendar is never a full-width desktop
  banner.
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
