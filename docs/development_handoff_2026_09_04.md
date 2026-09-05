# Development handoff — September 4, 2026

Status: documentation handoff; scheduling implementation has not started in
this conversation. Read this alongside the scheduling blueprint and assignment.

## Current owner direction

- Scheduling must target enterprise-level dependability while remaining easy
  for an average person to understand. A staged build is not a reduced product
  requirement or evidence of production readiness.
- Include the ability for a technician or employee to request time off.
  The detailed approval, cancellation, privacy, and availability rules still
  need review; the existing mention of leave is not a complete request workflow.
- The owner is rearranging screens and may need other fixes before scheduling
  implementation. Scheduling UI/UX and navigation placement remain unsettled.
  This handoff does not choose or begin those changes.
- Scheduling needs proper connections to Estimates, Jobs, employees, and
  availability. Screen imports or demonstration data do not establish a working
  domain integration. Preserve exact accepted estimate revisions and customer
  terms while allowing separate reviewed job-planning requirements.
- The owner requested a GitHub push to continue development on the machine
  they report has 32 GB RAM. The current Mac has 8 GB RAM. No destination
  checkout, installed SDK, or device connection has been verified here.

## Recommendations discussed, not approved policy

- Separate a time-off request from approval and from delivery/sync status.
- Pending requests could warn authorized planners; approved time off would
  block new assignments during the unavailable interval.
- Show existing appointments affected by an absence for dispatch review.
  Never silently move or cancel them, or rewrite actual daily entries.
- Keep private absence reasons out of scheduling projections.
- Provide a separate way to report unexpected unavailability; a future leave
  approval process alone cannot represent every same-day absence.
- Settle shared record contracts and screen workflows before wiring the
  scheduling interface. Build and verify the full design in bounded slices.

## Evidence and limits

The scheduling blueprint, build assignment, and calendar blueprint were read,
along with Work lifecycle and related permission, notification, and screen
contracts. Targeted source inspection confirmed prototype integration gaps:

- `lib/src/screens/work/work_models.dart` uses string assignee/vehicle fields
  and scheduled dates; it is not the proposed full scheduling domain.
- `lib/src/shell/employee_directory_screen.dart` keeps its employee profiles
  inside the screen, without the proposed shared skills/availability source.
- `lib/src/data/prototype_operations_store.dart` keeps Work records in memory
  and exposes mixed Dashboard Plan/Entries replacement paths.
- Dashboard and Job rescheduling currently have different duration handling;
  the Job action assigns a two-hour duration. Do not treat it as reviewed effort.

These are source-inspection findings, not runtime or regression-test results.
No scheduling engine, request screen, new storage adapter, or team sync was
implemented. Existing daily-entry code and live records were not changed.
No screenshots, builds, emulators, or 5.7 operations were performed in this review.

## Resume on the other machine

1. Clone the repository, or inspect and preserve any existing checkout changes
   before pulling `main`. Do not reset a dirty destination checkout.
2. Read `AGENTS.md`, this handoff, `scheduling_system_blueprint.md`, and
   `scheduling_engine_codex_assignment.md` under `docs/` (AGENTS is at repo root).
3. Recheck branch, commit, dirty paths, SDK requirements, and available devices.
4. Establish which screen/dependency slice the owner wants next. The saved
   S0–S2 assignment is available for a later bounded engine build; pushing these
   documents does not itself start it or authorize parallel agents.
5. Keep Maintainiac 5.7 Active and preservation checkouts protected. Keep
   implemented, tested, and owner-accepted outcomes explicitly distinct.

Git transfers repository files and history. It does not transfer local app
records, credentials, SDK installations, running sessions, or this conversation.
