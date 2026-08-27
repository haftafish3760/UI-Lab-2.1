# Technician Dashboard Blueprint

## Purpose

Give an employee technician or solo owner-technician the information and actions
needed before, during, and after today's field work. The UI Lab demonstrates the
screen and interactions; production data architecture belongs to the main app.

## Approved dashboard regions

- Active vehicle, odometer, navigation, start-workday action, role view, settings,
  and notifications.
- Today's Plan: scheduled work still requiring action.
- Day Prep: a compact readiness summary that opens a full preparation screen.
- Today's Entries: completed stops and other records created during the day.
- Calendar: seven-day dashboard view on phones and month view on larger screens.
- Wide layouts: Plan and Entries remain the primary work lane, Day Prep becomes a
  contextual lane, and the calendar is anchored at the upper right.

## Day Prep concepts

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

## Responsive behavior

- Phone: stacked Plan, compact Day Prep summary, Entries, and seven-day calendar.
- Tablet/intermediate: controlled work column with calendar; no stretched cards.
- Wide desktop: persistent navigation plus three purposeful content lanes.
- Text may become smaller and lighter on compact screens but must support system
  accessibility scaling without clipping or losing actions.

## Required production discovery

Before building this feature in Maintainiac, report the existing models,
repositories, services, permissions, and screens that own the required data.
Identify missing capabilities and stop for review. Do not invent duplicate data
architecture during discovery.
