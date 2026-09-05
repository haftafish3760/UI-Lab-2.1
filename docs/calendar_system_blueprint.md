# Calendar System Blueprint

Status: UI Lab working contract 0.1  
Applies to: Dashboard, Work, Jobs, Estimates, Invoices, Payments, Expenses,
Materials, Trips/Workday, Maintenance, Repairs, Reports, and Recap

## Purpose

Maintainiac has one shared calendar presentation and projection system. A
calendar shows authorized dated activity from owning modules; it does not own a
second copy of a job, expense, trip, maintenance event, repair, invoice, or any
other business record.

This distinction keeps the front end easy to understand while preventing the
Dashboard and calendar from becoming competing databases.

The detailed scheduling calculation, staffing, recurrence, history-assistance,
confirmation and parallel-build contract is `scheduling_system_blueprint.md`.
Scheduling and this calendar form one connected user experience: Work owns
commitments; Calendar displays them alongside historical activity. The separate
scheduling assignment must preserve existing past-day records and calendar routes.

Owner clarification: daily actual entries are protected on **all dates, including
today**. Scheduling must not edit, delete, move, recreate or reattribute them.
Only authorized planned commitments may change through the scheduling boundary;
existing corrections remain separate owning-module workflows. Mixed Plan/Entries
day objects must not be replaced from scheduling snapshots. See scheduling
blueprint section 12 and SCH-46 through SCH-50 for required preservation and
concurrent-entry tests before any shared-store/calendar integration.

## Plain-language model

- The module owns the record.
- The calendar shows when that record happened, is planned, or is due.
- The Dashboard combines authorized calendar entries from all modules into one
  chronological workday.
- Tapping an entry opens the exact owning record.
- Editing from a calendar route sends a permitted command to the owning module.
- The calendar refreshes from that same record after the command succeeds.

The calendar is therefore a dated index and operating view, not the business
record itself and not merely a scheduling tool.

## Ownership

| Activity | Sole record owner | Calendar responsibility |
| --- | --- | --- |
| Estimate activity | Work / Estimates | Project created, edited, sent, decision, follow-up, expiration, or conversion events |
| Job schedule and lifecycle | Work / Jobs | Project planned dates and confirmed travel, arrival, work, pause, completion, or return-visit events |
| Invoice and payment activity | Work / Invoices and Payments | Project issue, due, overdue, payment, credit, refund, or correction events |
| Business expense | Expenses | Project expense date, approval state, recurring due date, and confirmed payment event |
| Material movement or verified cost | Materials / Inventory engine | Project confirmed purchase, adjustment, transfer, usage, or count event |
| Workday and trip | Trips / Workday | Project workday start/end, trip segment, stop, mileage, and confirmed odometer events |
| Scheduled maintenance | Maintenance | Project due date or forecast threshold without presenting it as completed work |
| Completed maintenance | Maintenance | Project confirmed service event and evidence date |
| Repair | Repairs within the Maintenance module | Project reported, scheduled, in-progress, completed, or returned-to-service events |
| Dashboard day | No record ownership | Combine authorized module projections in chronological order |

Expenses own financial expense records even when a maintenance or repair record
links to the cost. Inventory owns stock truth even when a Job consumes the item.
Trips own mileage and stops even when Dashboard starts or displays the workday.

## Shared presentation contract

One shared component owns:

- Month and Week presentation;
- previous/next period navigation;
- month/date selection;
- weekday headings;
- Today and selected-date visual states;
- authorized count and attention markers;
- logical-width and accessibility reflow;
- keyboard, pointer, touch, and semantic behavior.

Every day cell follows one scan order: the date is a compact outlined square in
the upper-right, the authorized record count is a small unboxed dot-and-number
in the lower-left, and the center remains visually quiet. Routine counts are
gray; only genuine attention may recolor the count. Selected date uses a tinted
full-cell surface plus outline, while the actual current date uses a separate
bottom underline and never writes `Today` inside the grid. The date square and
period/weekday headers grow with accessibility text rather than clipping it.
Month/Week changes use one short shared size transition; selection still occurs
only after a date tap.

Calendar cells never display revenue, expenses, payment amounts, cost, profit,
margin, employee pay, hours, or mileage. Those values belong to the authorized
day summary, Dashboard recap, or Reports/Recap surfaces. The grid remains a
date, count, selection, and attention index.

Each module supplies only:

- the selected date;
- its authorized projected entries and counts;
- plain-language record labels;
- optional attention state;
- the route to its filtered day screen;
- the exact owning-record route for each day entry.

Counts are queried with the complete local calendar date. A day-of-month key
such as `29` is prohibited because it can repeat a count in the wrong month or
year after period navigation. Month navigation also advances the internal
focused date, so changing to Week remains in the period the user is viewing;
neither operation silently changes the selected business date.

A module must not fork or copy the calendar grid to change width, cell height,
colors, or selection behavior. Shared presentation changes belong in the shared
calendar component and require cross-module regression coverage.

## Day routes

Tapping a date always pushes a real route with Back behavior. It never replaces
the current page body while pretending to be navigation.

- **Dashboard Day:** combined authorized projections from every enabled module,
  sorted by actual event time. Undated all-day or due items follow timed items
  in a clearly labeled group.
- **Work Day:** Work-owned jobs, estimate activity, invoice activity, and
  payments for the selected scope and date.
- **Job Day:** Jobs scheduled or active on the date, including every covered
  date of multi-day work.
- **Estimate Day:** estimate activity on the date; drafts remain in their own
  unfinished-work section.
- **Invoice Day:** invoice activity on the date; the complete Invoice file
  remains searchable independently.
- **Expense Day:** business expenses and recurring expense events for the date.
- **Materials Day:** confirmed material transactions and cost events.
- **Maintenance Day:** due, scheduled, and completed service or repair events
  for authorized vehicles and equipment.

Every day row states its record type, status, time when known, useful title, and
owning context. Each record has its own compact bordered container. The day
route uses the same date-first and Needs Attention hierarchy as its module.

The current UI Lab routes Dashboard, Work, Jobs, Estimates, Invoices, Payments,
Expenses, and Materials date taps to real dated screens. Work-owned day rows
open the exact Job, Estimate, Invoice, or payment owner rather than routing to a
general workspace and making the operator locate the record again. Job,
Estimate, and Invoice dated routes retain previous/next-day review. Their
owning detail screens remain responsible for permission-gated edits and state
changes. Work-record archival/correction history is not considered complete
until the Work domain has a recoverable audited lifecycle equivalent to the
Expense soft-delete/restore foundation.

## Dashboard convergence

Dashboard is a projection coordinator, not a record owner. It requests the
authorized calendar projection from each enabled module, merges the results,
and sorts confirmed events chronologically. Planned and due items remain
visually distinct from confirmed history.

The combined projection must retain:

- owning module and stable record ID;
- event ID and event type;
- employee/company scope and permission revision;
- event time or explicit all-day/due classification;
- confirmed, planned, proposed, overdue, or attention state;
- offline/sync state without changing business meaning.

Duplicate projections of the same source event are collapsed by stable event
identity, never by similar title or amount.

## Trips and workday

Start Workday lives on Dashboard because Dashboard is the daily operating
surface. Confirming Start Workday creates or resumes a Workday record in the
Trips/Workday owner; Dashboard merely displays it.

Trip tracking may include:

- confirmed physical start and end odometer readings;
- optional GPS-assisted trip segments and stops;
- manual corrections with reason and audit history;
- business/personal or excluded-segment review where permitted;
- vehicle and employee assignment;
- offline capture and later sync.

GPS, inferred stops, and inferred mileage remain proposals until the user
confirms them. The Dashboard Day route shows confirmed trip/workday events in
chronological order and opens their exact owner.

## Vehicles, equipment, maintenance, and repairs

Maintenance covers vehicles and other business equipment. An asset declares
which measurement types apply; the UI must not show meaningless vehicle fields
for ordinary equipment.

Supported maintenance triggers include:

- calendar date or elapsed time;
- vehicle mileage;
- equipment runtime hours;
- another explicitly supported usage counter, such as cycles, when the asset
  requires it;
- combined rules such as a date or meter threshold, whichever comes first.

The system distinguishes:

- a maintenance plan or interval;
- a forecast due event;
- a scheduled service appointment;
- a completed maintenance record;
- a repair report and diagnosis;
- repair work and parts;
- repair completion and return to service.

Repairs live beside maintenance within the asset-care module but retain their
own record type and lifecycle. Any expense, receipt, inventory part, technician
time, or downtime is linked by stable ID and remains owned by its source module.

Forecast dates generated from mileage or runtime are labeled estimates. They
must update when confirmed meter readings change and must never appear as
completed service. Completed maintenance and repairs require user confirmation
and retained evidence.

## Time and ordering

- Confirmed activity is ordered by event time, not record creation order.
- Planned items use scheduled time or an explicit all-day/due group.
- Multi-day Jobs project onto every covered local business date without
  duplicating the Job record.
- Recurring expenses and maintenance intervals create occurrences or due
  projections; editing one occurrence is distinct from editing the series.
- Stored timestamps, business time zone, daylight-saving behavior, and imported
  local date are explicit. Device-local display must not silently rewrite an
  owning record's business date.
- Historical corrections recompute affected projections and summaries while
  retaining the prior audit event.

## Permission, privacy, and offline behavior

Authorization is enforced before navigation, query/count, route, action,
export, and sync. A hidden calendar marker is not security. Counts reveal only
records the viewer may know exist.

The shared calendar must render cached confirmed records offline. Commands made
from a day route are queued through the owning module with idempotent identity,
visible pending state, retry behavior, and conflict review. The calendar never
claims a queued change is synced or a proposed event is confirmed.

## Human-readable code organization

The target organization uses responsibility-based names:

```text
lib/src/shared/calendar/
  operations_calendar.dart
  calendar_day_cell.dart
  calendar_projection.dart
  calendar_projection_entry.dart

lib/src/screens/dashboard/
  dashboard_calendar.dart
  dashboard_day_screen.dart

lib/src/screens/work/
  work_calendar.dart
  work_day_screen.dart

lib/src/screens/expenses/
  expenses_calendar.dart
  expense_day_screen.dart

lib/src/screens/maintenance/
  maintenance_calendar.dart
  maintenance_day_screen.dart
```

`operations_calendar.dart` is the shared Month/Week widget. A module calendar
file adapts that module's projection and routes; it does not contain another
grid engine. `calendar_projection.dart` defines the read contract only. Module
commands remain with their module.

The current shared widget is still named `WorkMonthCalendar` in
`shared/module_month_calendar.dart`. Rename and folder movement must be a
separate behavior-preserving slice with import updates and cross-module tests;
do not mix that mechanical change into an unsettled screen redesign.

## Deferred implementation boundary

Trip, equipment maintenance, and repair UI are planned here so current calendar
and Dashboard choices do not block them. Their detailed screens, data adapters,
and production migration remain deferred until the owner begins those bounded
passes. Current Work and Expense work must not invent placeholder maintenance
logic or move protected 5.7 capability early.

## Required regression evidence

- the same shared grid renders for Dashboard, Work, Jobs, Estimates, Invoices,
  Payments, Expenses, Materials, Reports, Recap, and future Trips, Maintenance,
  and Repairs wrappers;
- module calendars receive only their authorized owning-module entries;
- Dashboard Day merges and chronologically orders authorized module events;
- tapping a row opens the exact source record;
- editing/rescheduling updates the owner and refreshes every projection;
- planned, proposed, due, completed, attention, offline, and conflict states are
  distinguishable without color alone;
- phone, landscape phone, tablet, resized desktop, large text, keyboard, and
  screen-reader behavior remain usable;
- no screen introduces a private width or calendar-cell rule.

This is an app-wide acceptance list, not a Dashboard-only follow-up. A calendar
presentation change is incomplete until every existing calendar wrapper above
uses it, every newly introduced module imports the same shared component, and
the cross-module regression suite proves that none of those screens retained a
private day-cell implementation.
