# Scheduling and Capacity Blueprint

Status: product-direction draft 0.1  
Last updated: 2026-09-04  
Applies to: UI Lab 2.1 Work, Team/Employees, Jobs, Dashboard, and Calendar

## Purpose

Scheduling helps a service business place the right confirmed work with a
qualified, available employee or crew without silently overbooking people,
vehicles, or time. It is an enterprise decision system behind a simple,
plain-language interface. It does not replace the owner's judgment or make a
schedule change without an authorized human confirmation.

The source of truth for a commitment is the Work-owned Job. Calendar and
Dashboard show authorized projections only. Employee capability data belongs to
the organization/employee record; historical duration evidence belongs to the
completed Job record.

## Customer outcomes

An authorized dispatcher or owner can:

1. create an employee operating profile that says what work they can perform;
2. schedule a one-time job, or a recurring visit to the same customer site;
3. see whether an assignment fits the person's usable day before saving it;
4. receive a transparent recommendation when more than one person can do the
   work;
5. understand why a person is unavailable, overloaded, underused, or a poor
   fit; and
6. deliberately override a recommendation when real-world knowledge requires
   it, while preserving the reason and history.

A technician sees only their authorized assignments and the job information
needed to perform them. They do not see coworkers' schedules, qualifications,
or private staffing information unless a separate capability grants it.

## Employee operating profile

Employee creation and editing includes a distinct **Work capabilities** step.
It is separate from identity, role, permissions, pay, and emergency-contact
information. It records only operational data needed for assignment:

- trades or service categories the employee is qualified to perform;
- specific task capabilities within each trade, such as mowing, irrigation
  repair, HVAC diagnostic work, or equipment installation;
- capability state: not qualified, qualified, or temporarily unavailable;
- optional proficiency and verification note when company policy uses them;
- normal work availability, approved time off, and blocked periods; and
- vehicles, equipment, certifications, or crew requirements that are necessary
  for a particular assignment.

The interface uses searchable, plain-language trade and task choices plus an
authorized custom entry path. It never invents a qualification from a role
title, a prior assignment, or an AI suggestion. A capability change is audited
with actor, time, previous value, new value, and reason when it changes future
assignment eligibility.

## Work duration evidence

Every schedulable Job has an expected duration and an explicit source:

1. confirmed estimate or job scope;
2. a user-entered planning duration; or
3. a clearly labeled recommendation from comparable completed work.

Comparable history may use the same customer service location and same service
or task type. It must disclose the sample basis and never masquerade as a
guarantee. The planner can revise the recommended duration before saving. A
completed Job records actual start/end work time and outcome; that evidence can
improve later recommendations without rewriting the original estimate or the
historical schedule.

Travel, required breaks, job windows, vehicle/equipment availability, and
company-defined buffers are separate planning values. They are visible in the
capacity calculation and are not silently hidden inside the job duration.

## Capacity and assignment rules

The planner calculates each candidate's usable time for the selected date from
their working availability minus approved leave, blocked time, confirmed jobs,
travel, breaks, and required buffers. It then evaluates the proposed job's
requirements against that remaining capacity.

Job count is a supporting signal, not the balancing rule. Ten jobs for three
employees cannot be split as fractional jobs. The system assigns whole jobs by
qualification, time, location, required resources, and remaining usable time.
For example, one qualified person may receive four short visits while two
others receive three longer visits only when their actual planned hours still
fit. The planner must not present equal job count as equal workload.

An employee is not an eligible automatic recommendation when any hard
requirement fails: missing required capability, unavailable time, overlapping
confirmed work, insufficient remaining capacity, unavailable required vehicle
or equipment, or missing assignment permission. The interface states the
specific reason without exposing private employee data.

When no eligible assignment exists, the system offers authorized next actions:
choose another time, change the crew or resource requirement, split the work
only when the job type permits it, place the job in an unassigned review queue,
or save a deliberate override. It never silently drops, duplicates, or moves a
customer appointment.

## Recurring service

Recurring service is a reusable schedule rule, not a copy of a finished job.
It supports weekly and every-other-week lawn-care-style visits first, with a
start date, optional end date, preferred weekday/time window, expected duration,
required trade/task capabilities, service location, assigned employee or crew
when chosen, vehicle/equipment requirements, and customer/site access notes.

Each upcoming occurrence is a dated Work-owned scheduling commitment linked to
the recurrence rule. Completing, cancelling, rescheduling, or correcting one
occurrence changes that occurrence only. Editing the rule offers explicit
choices for this occurrence, future occurrences, or the whole rule where that
choice is valid; completed history remains intact. Holidays, customer skips,
weather holds, staff leave, and a one-off alternate technician become visible
exceptions with a reason rather than altering prior visits or silently breaking
the cadence.

Before each future occurrence is confirmed or regenerated, capacity and
eligibility are recalculated. A recurring rule never guarantees that the same
employee remains available forever, and it never auto-books a person beyond
their usable day.

## Simple planner experience

Schedule is a Work surface, not a separate duplicate data system. The planner
asks for the customer/site, work required, duration, date/window, recurrence
when applicable, and any required resource. It then presents plain-language
choices such as **Best fit**, **Fits with less remaining time**, and **Needs
review**, with an explanation of time, capability, and conflict factors.

Saving requires an authorized review of the selected assignment, duration,
date/window, recurrence scope, and any warning or override. The resulting Job
assignment and schedule are written once through Work, audited, queued safely
offline, and projected to Calendar and Dashboard after authorization. A retry
is idempotent and cannot create a second visit.

## Safety, permissions, and edge cases

- Scheduling recommendations are proposals. Only an authorized human commits
  or overrides an assignment.
- A change rechecks current permissions, employee status, availability,
  capability, resource availability, and Job revision immediately before save.
- Offline planning may save a clearly marked pending change. Sync conflicts
  preserve both versions for review; the service never silently selects one.
- Inactive or former employees remain in historical assignments but cannot
  receive new assignments.
- A schedule change that creates an overlap, overload, expired certification,
  unavailable vehicle, or changed customer window becomes a visible conflict;
  it is not converted into a false "confirmed" state.
- Missing historical durations, a new customer site, or a new employee produce
  no fabricated precision. The user supplies or confirms the planning duration.
- Accessibility and localization rules apply to every recommendation,
  explanation, date/time, duration, and capacity label. Long translated labels
  reflow; they do not clip or disappear.

## Acceptance evidence

The blueprint is not satisfied by a calendar mockup. A later implementation
must demonstrate employee capability entry, qualified versus unqualified
candidate filtering, estimated and historical duration provenance, whole-job
capacity balancing, weekly and biweekly occurrence behavior, one-occurrence
exceptions, conflict recovery, offline retry/conflict behavior, permission
denial, audit history, and responsive accessible layouts.
