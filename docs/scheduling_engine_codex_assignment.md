# Scheduling Engine — Bounded Codex Build Assignment

Prepared September 4, 2026. This is an assignment the owner can give another conversation. This document does not start an agent or authorize this current UI conversation to build scheduling.

Before using this assignment, read `development_handoff_2026_09_04.md` for the
latest owner direction on dependability, employee time-off requests, unresolved
screen changes, and continuation on the other development machine.

## Mission

Build the deterministic, non-AI scheduling foundation for Maintainiac, a service-business operations and recordkeeping app. First deliver the source map, domain contracts, single-job feasibility checks and suggested openings: phases S0-S2 of `scheduling_system_blueprint.md` only.

The owner and another Codex conversation are working on UI/UX. Do not redesign their dashboard, navigation, screens or calendar. Do not interpret this as permission to rebuild the whole app.

## Non-negotiable: leave daily entries alone

The owner explicitly prohibits changing the day's actual entries as part of scheduling. This covers today and every other date. Do not edit, delete, move, recreate, reseed or reattribute receipts, expenses, payments, trip/workday/odometer events, material movements, maintenance, notes/evidence or actual job activity. Scheduling may later change authorized planned commitments only—not the actual records displayed alongside them.

Read the detailed protection in section 12 of the scheduling blueprint. Do not replace a whole day object containing both Plan and Entries; concurrent entries must survive scheduling commands. S0 must map these mixed write paths. S1-S2 must not write live records at all. Any later storage/calendar adapter needs separately coordinated scope and SCH-46 through SCH-50 preservation evidence before integration. Do not delete or reset data to fix a mismatch.

## Required reading

Read the repository's `AGENTS.md`, then:

1. `docs/scheduling_system_blueprint.md` completely, including proposed versus confirmed decisions, phase limits and SCH tests.
2. `docs/calendar_system_blueprint.md` completely. The shared calendar shows history AND scheduled work; it is not merely a scheduler.
3. `docs/work_lifecycle_blueprint.md`, especially the September 4 scheduling/staffing/capacity section and Job/Estimate lifecycle.
4. `docs/maintainiac_app_blueprint.md` and `docs/product_control_blueprint.md` for authority, privacy and record ownership.
5. Relevant employee, storage, notification and local authorization implementations named by the scheduling blueprint.

The new scheduling blueprint expands existing rules rather than replacing the app's source record owners. Current explicit owner direction overrides historical AI-authored layout/product assertions.

## Workspace and parallel-work safety

- First report the actual working directory, repository remote, branch, HEAD and dirty paths. Mac path names in prior context do not identify a Windows checkout automatically.
- Reference snapshot at preparation was UI Lab 2.1 `main`, HEAD `a8d1361692b3b61841ff09df052ad71c6387db84`; whole-app and Work lifecycle docs had uncommitted changes. They belong to the existing owner session.
- Do not implement in the UI agent's active checkout. Use an owner-designated isolated checkout/worktree/branch with the complete current blueprint package, including uncommitted requirement changes deliberately transferred by the owner.
- If no isolated checkout is designated, perform read-only mapping and ask for that location before changing files. Do not silently choose UI Lab 2.2; it may be a protected preservation copy.
- 5.7 Active is a protected read-only capability source. Find existing scheduling, employee, time and storage seams if the owner makes that checkout available; do not edit, clean, delete, reset, commit or run mutating tools against it. If unavailable, report reuse discovery as incomplete, not that nothing reusable exists.
- Do not stage, commit, push, install packages, deploy, migrate data, create cloud services or publish anything without explicit owner authorization.

## Ownership and integration rules

- Jobs/Work owns job scope and schedule commitments. The scheduling engine computes proposals; the calendar and Dashboard display projections and invoke authorized owner commands.
- Employee identity/skills/availability belong to a shared employee domain. Do not turn the current private employee-screen fixture into another independent production store.
- Use stable IDs, exact duration units, explicit time zones, immutable input snapshots, injected clocks and versioned company policies.
- Keep actual labor, estimated labor, elapsed appointment duration and billable charges separate. No title/time-label parsing or labor-total/headcount shortcuts.
- Preserve historical events when appointments are moved, cancelled or reassigned. Unscheduled jobs are not on every calendar date.
- Approved estimates are one intake source, not a scheduling prerequisite. Support direct Jobs and assessment visits without fabricating an estimate, price or approval. Keep priority independent of status/deadline; urgent work never silently displaces confirmed assignments or bypasses crew/permission constraints.
- A dedicated Scheduling workspace is proposed for the UI conversation. It consumes this same domain; do not build a separate store/calendar, change navigation or implement that screen in S0-S2.
- One person's time cannot be counted twice across roles or jobs. Skills, simultaneous crew, phase dependencies and resource availability matter independently from total hours.
- Suggestions never commit, notify, invoice or change confirmed records. Recheck permissions and revisions at the eventual confirmation boundary.
- The engine must use authorized projections. It cannot reveal hidden job/leave details in conflict reasons or bypass hidden reservations.
- Learning means transparent company history statistics and reviewed templates, not AI, employee rankings, surveillance or automatic qualification changes.

## Allowed implementation footprint for this first assignment

Proposed new locations, subject to confirming they do not already have owners:

- `lib/src/domain/scheduling/`: pure Dart models, typed reasons, input validation, interval operations, feasibility and candidate calculations.
- `test/scheduling/`: deterministic unit/property/reference-solver tests and fictional fixtures.
- `docs/scheduling/`: source map, decisions, requirement-to-test matrix and phase evidence.

Do not write another engine if a reusable compatible one is discovered. Produce the adapter/reuse proposal first. New implementation files should stay at or below 500 lines and split by responsibility, not arbitrary fragments. Do not create a giant catch-all service.

Protected during S0-S2:

- `lib/src/screens/`, `lib/src/shell/`, `lib/src/shared/`, `lib/src/layout/`, theme and generated localization files.
- App entry points and current shared/prototype repositories.
- `pubspec.yaml`, lockfiles, platform projects and existing test files.
- Owner-edited whole-app and Work lifecycle documents; use additive phase notes rather than overwriting them.
- All external 5.7 and preservation checkouts.

If a protected edit becomes necessary, explain the exact dependency and proposed diff and request coordination. Do not make it silently. First-pass pure engine tests can use existing test dependencies without adding a new database or app launch.

## Deliver S0: evidence and contract map

Map current job creation, reschedule, assignment, arrival/completion, employee identity, Dashboard projection, calendar counts/routes and storage calls. List the present data owners, unsupported inputs, duplicate-write risks and intended adapter seam for each.

Current observed weaknesses to verify, not blindly repeat: Work uses display-string assignees, the employee directory is screen-local, Dashboard has separately assembled plans, and Work durability is not established by Expense durability. Preserve functioning paths while designing future cutover.

Return explicit input/output type contracts, units, versions and policy injection. Do not wait for every future UI decision: use explicit test policies for pure calculations while labeling unapproved product defaults.

Deliver the dependency table required by blueprint section 16: owner, IDs/revisions, units/time zones, permissions, missing-data behavior, real-versus-fixture status, integration slice and acceptance tests. Identify absent employee/storage/execution capabilities without building them outside this assignment. Every fixture-backed input must be reported as not connected to production.

## Deliver S1: pure domain foundation

Provide immutable job phase/crew requirements, employee planning snapshots, reservations, resource/availability windows, policy/clock interfaces, candidate result/reason models, validators and safe interval arithmetic.

Model optional estimate linkage, direct/assessment visit intent, priority and reviewed duration assumptions explicitly. Include their core validation cases from SCH-39 through SCH-42; full dispatch rearrangement, intake UI, conversion persistence and queue aging remain later integration/planning work.

No UI imports, direct disk/network access, device APIs, global mutable singleton, Firebase code or automatic mutations. Unknown input must remain unknown. Keep authorization context in the orchestration contract; do not label a pure calculator an authorization system.

## Deliver S2: feasibility and suggestions

Evaluate a proposed appointment and provide bounded alternatives. Include total and skill-specific capacity, simultaneous crew, nonparallel phases, breaks, travel/setup/cleanup, resource reservations, qualification validity and missing data.

Use deterministic ordering and explicit search bounds. Return unsupported complex recurrence/week-plan cases as not implemented in this phase rather than pretending to solve them. Never report search exhaustion as mathematical impossibility.

Do not implement recurrence, durable Hive cutover, Firebase team sync, production employee profiles, UI adapter wiring, history-based duration suggestions, customer portal or invoice-finalization screens in this assignment. They have named later phases and dependencies in the blueprint; nothing is being dropped.

## Verification and report

- Read-only baseline analysis as practical; distinguish existing failures from new ones.
- Run formatting for your new Dart files, targeted analysis and `flutter test --concurrency=1 test/scheduling` (or the project's confirmed equivalent). Do not run parallel builds/emulators on the memory-constrained Mac.
- Test relevant SCH requirements and properties, including false-positive feasibility cases, wrong organization, stale snapshots, unknown data, hidden busy time, crew/skill double counting, travel gaps, exact boundaries and deterministic repeats.
- Add a deliberately simple independent reference solver for bounded tiny fixture problems; do not copy the production algorithm into the expected-result implementation.
- Leave app runtime, current user windows, devices and debug sessions alone. No screenshots without explicit owner request.
- Report exact changed paths, executed commands/results, covered SCH IDs, algorithm limits, remaining decisions and what was NOT implemented. Do not claim full scheduling, offline durability or enterprise security from these phases.
- Explicitly report that daily-entry code and live records were untouched in S0-S2. Later adapter acceptance must compare protected record fields and concurrent-entry survival, not merely record counts or a successful build. Do not claim those integration tests passed during the headless phase.

At S2 completion, stop for review of the contracts and evidence. The owner can then assign S3 and coordinate the storage/employee/calendar integration slices with the UI conversation.

## Plain-language first response expected

Explain what exists, what is missing, what this bounded assignment will build, which files remain untouched and how success will be proved. Do not begin by asking the owner to design a scheduler or by redesigning the dashboard.
