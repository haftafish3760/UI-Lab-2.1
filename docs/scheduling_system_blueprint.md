# Scheduling System Blueprint

Status: product requirements and proposed engineering contract; NOT implemented by this document.
Prepared: 2026-09-04. Scope: service-business scheduling within Maintainiac.
Owner review: the owner endorsed deterministic scheduling assistance and requested an explicit build assignment for a separate Codex conversation. Detailed implementation choices below remain proposals unless marked Required.

Latest review and handoff: `development_handoff_2026_09_04.md` captures the
owner's added employee time-off request requirement, dependability expectations,
and unresolved screen/integration sequencing. Request approval mechanics remain
proposals; this document does not establish that they are implemented.

## 1. Purpose and authority

Help a solo operator, owner working in the field, dispatcher, supervisor, or authorized employee make realistic work commitments. The system must explain who can do a job, when it can fit, why a suggestion fits, and what prevents it from fitting. It must remain useful without AI, GPS, or an internet connection.

This is the detailed scheduling specification linked from the whole-app, Work lifecycle, and calendar blueprints. It expands the existing September 4 scheduling requirements in `work_lifecycle_blueprint.md`; it does not replace the full Work lifecycle or the calendar system. New explicit owner instructions take precedence. Historical AI-authored documents are evidence, not proof of owner approval.

The term Work below describes the business-record owner, not a requirement to retain a Work landing screen. Removing that navigation destination must not delete Jobs, scheduling, Estimates, Invoices, or Payments.

Required product outcomes:

- Manual scheduling, suggestions for suitable openings, and an optional proposed day/week schedule.
- Scheduling based on job requirements, actual employee availability, skills, qualifications, crew requirements, and existing commitments.
- Company-specific improvement from confirmed work history, without machine learning or an LLM dependency.
- Recurring service appointments, including weekly and every-other-week lawn care.
- A useful backlog and earliest-opening explanation, not an unsupported promise to the customer.
- Permission-enforced planning and confirmation; no automatic reassignment, cancellation, or customer commitment.
- Continued historical calendar browsing, current-day Plan and Entries, and future schedule viewing.
- Complete manual workflows when assistance is disabled.
- Direct job intake without an estimate, including urgent service calls; priority is independent of estimate approval.
- Local durable records, optional Firebase backup, and a separately specified organization-sync boundary.

This document is NOT a claim of enterprise readiness, complete permissions, reliable cloud delivery, or complete scheduling in the present app.

## 2. One system, distinct responsibilities

The user experiences scheduling and the calendar as one connected system. Internally, separate responsibilities prevent data loss and duplicate truth:

| Responsibility | Owner | Boundary |
| --- | --- | --- |
| Work scope, customer/site, estimate linkage, planning requirements, completion | Jobs / Work domain | Calendar cannot invent or overwrite these records |
| Employee identity, qualifications, skills, availability | Employee/organization domain | Scheduling consumes a restricted read projection, not a second employee directory |
| Dated commitments, assigned people/resources, revisions, recurrence exceptions | Scheduling domain within Work | One canonical commitment per appointment occurrence |
| Candidate evaluation and schedule suggestions | Pure scheduling engine | No persistence, notification, permission grant, or business mutation |
| Actual work time, arrival, pause, completion evidence | Job execution/time records | Scheduled time is never substituted for actual work |
| Month/Week grid, selected date, historical/forward day display | Existing shared calendar system | Read projection plus authorized commands to the record owner |
| Today's Plan and Today's Entries | Dashboard projections | No independently editable copy of a schedule |
| Receipts, expenses, payments, invoices, stock, maintenance | Existing owning domains | A schedule may link them, but cannot become their ledger |
| Organization synchronization and backup | Shared storage/sync boundary | Screens must not write directly to Firebase |
| Assignment/reminder notifications | Shared notification engine | A notification does not confirm a schedule or finish a job |

Data flow:

```text
Authorized job + employee + resource + availability snapshots
                         |
                 Pure scheduling engine
                         |
            Explained, revision-bound proposal
                         |
       Human review + current permission/conflict checks
                         |
          Work-owned durable schedule commitment
                /                      \
     Shared calendar projection     Notification outbox
                |
       Dashboard / filtered day routes

Confirmed execution events -> historical day entries and duration history
```

Do not replace the shared calendar widget, remove historical entries, or introduce an unrelated second calendar dependency as part of the scheduling assignment.

## 3. Observed starting point, not a full audit

Source snapshot: UI Lab 2.1, branch `main`, HEAD `a8d1361692b3b61841ff09df052ad71c6387db84`, inspected September 4. The whole-app and Work lifecycle documents already had uncommitted owner-session edits. Preserve them. The next builder must inspect their own current checkout; these observations can become stale.

| Existing source | What was actually observed | Consequence for integration |
| --- | --- | --- |
| `lib/src/screens/work/work_models.dart` | `WorkRecord` has scheduled start/end, completed date, revision, source link, display-string assignee and vehicle | Reuse stable Work IDs; do not treat display names as canonical employee/resource identity |
| `lib/src/data/prototype_operations_store.dart` | In-memory Work list and date/context Dashboard maps; durable Expense adapter is a separate path | A Work update is not proof of restart-safe scheduling; plan projection reconciliation explicitly |
| `lib/src/screens/dashboard/dashboard_projection_actions.dart` | Job/document projections are assembled in Dashboard action methods | Replace duplication only through a tested adapter/cutover, not by deleting map contents |
| `lib/src/screens/dashboard/dashboard_models.dart` | Display-time strings and development permission defaults | Engine must use typed times and authenticated authorization snapshots, not these defaults |
| `lib/src/screens/dashboard/today_plan.dart` | Existing sorted schedule, three-record expansion, job/task menu differences | Preserve row navigation and distinguish a job visit from a non-job task |
| `lib/src/screens/dashboard/dashboard_screen_actions.dart` | Dashboard handlers update plan/job state | Map all write paths before introducing a new command service |
| `lib/src/screens/work/work_job_editor.dart` | Existing job creation/scheduling form | Keep source linkage and existing creation flow during future adapter work |
| `lib/src/screens/work/job_workspace_interactions.dart` | Existing job arrival, status, reschedule and reassignment actions | All entry points eventually use the same authorization and transition service |
| `lib/src/shell/employee_directory_screen.dart` | Screen-local employee list and private profile type, with contact/role/pay and several permission flags | Not a durable scheduling-skills/availability source; do not build another private employee store |
| `lib/src/shared/module_month_calendar.dart`, `module_calendar_day_cell.dart` | Existing shared calendar sources named in calendar contract | Preserve their historical/projection responsibilities and coordinate any UI change separately |
| `lib/src/data/storage/dual_slot_json_store.dart` | Existing common checksummed snapshot mechanism | Assess reuse/migration; checksums are not encryption or multi-device conflict control |
| `pubspec.yaml` | Current dependencies include timezone; no Hive or Firebase package declared | Do not claim those integrations already exist. Hive remains the owner's requested local-database direction |
| `test/prototype_operations_store_test.dart` | Existing shared-record and duplicate-retry tests | Retain tests; add independent engine and historical-projection tests |

This inspection did not execute tests, measure scheduler performance, inspect every file, or audit 5.7. No scheduling implementation or app UI was changed during preparation of this specification.

## 4. Required domain contracts

Names below describe responsibilities. The builder maps them to existing types before choosing final Dart names. Domain code must not import screen models or depend on Flutter widgets.

### 4.1 Identity, units, and versions

- Stable organization, employee, membership, job, visit, skill, resource, and source-record IDs. Names are labels, not foreign keys.
- Version every mutable planning input and policy. Retain effective dates for availability and qualifications.
- Use integer elapsed minutes and person-minutes for planning arithmetic. Preserve finer precision if existing actual-time records use seconds; rounding happens once under a documented boundary.
- Store appointment instants with the relevant business/service IANA time-zone identifier. Keep local date and recurrence intent where applicable.
- Do not parse localized displayed times, invoice totals, job titles, or monetary labor charges to discover duration.
- Keep estimated labor, billable labor, scheduled elapsed duration, and actual labor distinct.
- Unknown is not zero. Missing skills, duration, time zone, travel allowance, or availability must produce a specific missing-data state when needed to determine feasibility.

### 4.2 Job planning requirements

Required fields or explicit unknown/not-applicable values:

- Organization, Job ID/revision, optional accepted Estimate ID/revision.
- Created date, estimate-approved date when applicable, ready-to-schedule date, due/customer commitment dates if recorded. These dates have different meanings.
- Company-defined service/job type and versioned template reference; not a fixed construction-only taxonomy.
- Service location ID, customer appointment window, earliest start, deadline, priority, dependencies and readiness state.
- One or more phases with estimated person-minutes, required elapsed duration where constrained, allowed splitting, dependency order, minimum simultaneous crew and maximum useful crew.
- Skill requirements and quantities, independent-worker/supervisor needs, qualification validity, and explicit allowed substitutions.
- Whether each phase can run in parallel; default unknown parallelism to no assumed speedup.
- Setup, cleanup, travel and contingency allowances with a clear included/excluded basis to prevent double-counting.
- Required vehicle/equipment/resource reservations and material readiness facts from their owning modules.
- Job-specific planned effort, source estimate effort, any override reason/actor/time, and remaining-effort review state.

An estimate can be tentatively planned without a confirmed job only as a distinctly labeled nonbinding proposal. It does not consume confirmed capacity or promise a customer an appointment. Explicit time holds, if later approved, need their own owner, expiry, scope and capacity policy; do not quietly implement them.

Creating a linked job from an accepted estimate remains explicit. Re-estimating the job's planning time must never change the customer's accepted price, labor charges, signature or document revision.

### 4.2a Job intake does not require an estimate

Owner clarification: an approved-estimate queue is useful, but a customer with an urgent leak or failed water heater may need service before a written estimate exists. Required:

- Support approved-estimate conversion, an existing unscheduled Job, and a new direct service Job as distinct intake paths. Recurring service creates visits linked to its owning Job/series.
- Keep estimate linkage optional. Never manufacture an accepted estimate, acceptance date, price or customer signature to allow scheduling.
- A direct job records customer/contact, service location or explicit missing-location state, reported problem, urgency, intake time and authorized creator. Reuse existing customer/site identities when known; do not require unrelated full-profile fields before saving an intake draft.
- Saving intake is not booking capacity. Confirmation additionally needs enough duration, crew, location/travel and availability information to validate the visit.
- If repair scope is unknown, allow an explicitly labeled assessment/diagnostic visit with a reviewed duration allowance and suitably qualified crew. Do not invent the entire repair duration or imply that the quoted arrival window promises repair completion.
- Preserve subsequent estimate/authorization, repair visits, materials, completion and invoice links on the same Job. Whether an estimate, service authorization or pricing approval is needed remains separate company workflow policy; urgent intake does not automatically waive it.
- An approved estimate already linked to a Job opens that Job instead of converting it twice. Partial/multi-visit work retains its existing scope and unscheduled remainder. Repeated taps/retries must not duplicate jobs or visits.

### 4.2b Priority and urgent dispatch

Owner requirement: Jobs need explicit priorities, including work received without an estimate. Proposed initial labels, subject to owner review:

| Priority | Meaning for planning |
| --- | --- |
| Emergency | Request for immediate dispatch review; not a guarantee that a crew is available |
| Urgent | Time-sensitive work needing an explicitly recorded target/window |
| Normal | Routine work, respecting customer commitments, readiness and queue age |
| Flexible | Customer/company explicitly permits placement around firmer commitments |

Priority, customer deadline, readiness, job execution status and appointment confirmation are separate fields. An authorized person sets priority during intake/conversion or later with actor, reason, time and revision history. A customer-reported urgency is input for review, not permission to self-promote or displace another customer's job. Do not infer Emergency solely from a service name; a reported leak needs human triage.

Emergency priority changes what receives attention first; it does not bypass authorization, qualifications, minimum crew, existing active work, travel or exclusive resource constraints. Candidate results must explain the earliest feasible response and any missing facts. An unknown-duration call can use the reviewed assessment-visit path, not a zero-minute reservation.

When an urgent insertion cannot fit without moving existing commitments:

1. Show a clearly labeled proposed rearrangement, affected appointments/people, revised arrival windows and any jobs left without a slot.
2. Preserve the current schedule until an authorized dispatcher reviews and explicitly confirms the changes under revision/conflict checks.
3. Keep customer/employee communication status separate from confirmation. Queue authorized notices through the shared notification system; do not report recipients informed merely because a schedule was saved.
4. Never silently interrupt in-progress work, displace a confirmed visit, or claim an impossible same-day promise. Return alternatives or a clear no-feasible-opening/needs-review result.

Queue ordering must remain explainable and consider commitments, deadlines and waiting age within the configured urgency policy. Flag overdue or repeatedly deferred normal work rather than allowing an urgent queue to hide it indefinitely.

### 4.3 Employee planning projection

- Employee and membership IDs, active dates, eligible organization/team scopes.
- Normal working intervals, exceptions, leave/unavailability intervals and personal/company time zone as needed.
- Skill IDs and company-confirmed proficiency, independent-work eligibility and supervision constraints.
- Qualification references and effective/expiry times when the company tracks them.
- Existing reserved commitments, approved overtime rules and maximum configured planning load.
- Assigned vehicle/resource access only when necessary to evaluate that job.

Exclude pay, emergency contacts, medical details, private absence reasons, protected characteristics and unrelated personnel notes. Availability can say unavailable without explaining private reasons. A helper is not interchangeable with a qualified independent worker. A supervisor's capacity cannot simultaneously satisfy two incompatible supervision assignments.

A scheduler may not invent skills from a job title, automatically promote qualifications from completed jobs, or use work history to rank or penalize people. Explicit company-reviewed experience can inform eligibility; qualification authority remains with its owner.

### 4.4 Schedule commitment and visit

A Job may have many visits and phases. Each confirmed visit retains:

- Commitment/occurrence ID, organization and Job ID, optional phase/series ID.
- Start and end instants, service time zone and customer arrival window separately.
- Employee/resource reservations with role, start/end and quantities.
- Planned effort and elapsed-duration basis, buffers and relevant source revisions.
- Planned/confirmed/cancelled/superseded state, revision, confirmer and confirmation time.
- Local pending-sync versus organization-acknowledged status, not conflated with business state.
- Previous commitment revision, change/cancellation reason and idempotency key.

Appointment state and job execution state are separate. Rescheduling cannot erase an arrival or completion event. Cancelling a visit does not delete its Job, invoice, historical expenses or actual-time evidence. Reassigning tomorrow's work does not reattribute yesterday's work to the new employee.

### 4.5 Pure planning result

Input: an authorized immutable snapshot, requested jobs/time horizon, explicit clock, company-policy version and engine version.

Output: candidate plans, unscheduled work, constraint reasons, capacity summaries, missing inputs, considered horizon and snapshot revisions. No output has a side effect.

Each candidate identifies exact people/resources/intervals, why it fits, remaining buffer, assumptions, data freshness and which source facts must be rechecked before confirmation. Include failures for unplaced jobs; never silently drop them.

Retain the existing requested result vocabulary where appropriate: comfortable, tight, understaffed, skill blocked, overbooked, schedule conflict, insufficient planning data. Add explicit outside-horizon, dependency blocked and resource blocked reasons. Several reasons may apply; a single status must not hide a more serious failure.

## 5. Deterministic feasibility rules

### Required invariants

1. Intervals use a documented half-open rule `[start, end)`. Adjacent visits do not overlap, but required travel/setup can still make adjacency infeasible.
2. Subtract the union of overlapping busy/leave/break intervals; do not subtract the same minute twice.
3. One employee-minute cannot be allocated to two phases, two jobs, or two independent skill requirements at once.
4. Multi-skilled people can satisfy eligible roles over distinct allocations. Having two skills does not create two simultaneous workers.
5. Both total person-minute demand and time-specific skill/crew feasibility must pass.
6. Continuous crew requirements require people available together, not merely enough scattered hours in a day.
7. More workers reduce elapsed time only under an explicit phase/crew model. Do not divide labor hours by headcount and call it feasible.
8. Do not split a non-splittable phase around breaks or across days. Splittable work retains per-visit setup/travel requirements.
9. Resource reservations are checked over the needed interval; an unavailable van or machine cannot be assigned twice. Tools/materials declared not required impose no invented constraint.
10. Qualification and membership validity must cover the interval required by policy, not just the date of calculation.
11. Manual scheduling still validates hard constraints. It is not a bypass around eligibility, scope or double-booking.
12. Missing critical information never produces a green available/confirmed-feasible label.

### Capacity versus a usable slot

Report person-hours, elapsed appointment hours and contiguous availability separately. A day can have enough aggregate free time but no continuous slot for a particular job.

Example: two people each available for two hours provide four person-hours only if their intervals and roles fit the work. A phase needing one qualified technician and one helper together for two hours needs those two eligible people simultaneously. A four-hour solo/nonparallel task still takes four elapsed hours even if helpers are idle.

### Travel and readiness

Use explicit company/job travel allowances initially. Do not require GPS, a paid routing service or a new map subsystem to schedule manually. A future travel adapter can propose time with source/freshness/uncertainty, never manufacture precision or alter confirmed mileage.

Check buffers on both sides of an insertion. Required materials not yet available may flag a warning or block confirmation according to explicit company policy. Stock uncertainty must be labeled unknown, not assumed available or unavailable. Maintenance downtime can reserve a vehicle/equipment interval without exposing unrelated repair/financial details.

### Hard requirements and preferences

- Hard: authorization, organization isolation, required eligibility, impossible interval, required minimum simultaneous crew, exclusive resource collision and nonparallel phase constraints.
- Soft: preferred employee, target load, optional contingency, customer preference and travel allowance where the company explicitly permits a reasoned override.
- Missing critical input: blocked until supplied or replaced with an explicit authorized planning assumption. It is not equivalent to a soft preference.

Each override names the rule, scope, reason and actor. An override permission never permits unauthorized access or falsifying qualifications. Overtime limits and employment policy must be company-configured and legally reviewed where needed; the engine does not invent legal limits.

## 6. Assistance levels and scheduling procedure

### Manual

The planner chooses people/date/time. Engine evaluates the proposal and explains problems. User confirms only after required checks pass. Manual remains available even with no history or no cloud service.

### Suggest openings

Find several feasible windows for a requested Job within an explicit bounded horizon. Explain candidate people, expected duration, preparation/travel allowance and uncertainty. Suggestions do not reserve time or notify customers.

### Draft day/week

Consider selected authorized backlog jobs, existing commitments and current inputs. Keep already confirmed appointments fixed unless the planner explicitly includes them in a proposed move. Present all proposed changes together with unscheduled jobs and reasons. Confirmation is a distinct command.

Proposed first implementation algorithm:

1. Normalize and validate the authorized snapshot, date range and duration units.
2. Expand only recurrence occurrences intersecting the requested horizon, honoring exceptions.
3. Build employee/resource free intervals after confirmed reservations and required buffers.
4. Resolve readiness/dependencies and eligible crews before candidate placement.
5. Sort work deterministically: explicit locked commitments first; then approved urgency/deadline policy; then ready-to-schedule age and stable Job ID as a tie-breaker. Policy must be recorded, not inferred from title or invoice value.
6. Generate bounded candidate start times from free-interval boundaries and explicit appointment windows. Evaluate phases, simultaneous skills, resources, travel and buffers.
7. Rank only feasible candidates using transparent company preferences, earliest suitable opening and available buffer. Do not rank people by unexplained productivity scores.
8. Update the draft's temporary reservation model after each placement; evaluate dependencies between placements.
9. Return the proposed plan plus every unplaced job and explanation. Revalidate the whole plan, not only each visit independently.

This heuristic is a recommended first design, not a claim of globally optimal scheduling. Bound search time, employees, jobs, date range, recurrence expansion and candidate count using configurable limits. Exhausting a budget returns a partial/search-limited result, never a false claim that no feasible schedule exists. Equal inputs, engine version, policy version and injected clock must yield equal results.

## 7. Backlog and remaining work

Separate: confirmed scheduled work, ready but unscheduled work, accepted work awaiting readiness, and pending estimates. A pending estimate must not silently become booked work.

Estimate creation/approval dates support queue context, not automatic scheduling priority. A later approved urgent job may legitimately precede older routine work under explicit policy.

Calculate workload by skill/crew constraints over a stated future horizon. Display assumptions and freshness. Useful outputs include scheduled effort, unscheduled effort, constrained-skill shortages, and earliest feasible opening for a specified job. A single company-wide number of weeks can be misleading when one specialty is overloaded and another is available.

Actual time already spent does not prove how much work remains. An arithmetic estimate may be shown as a labeled calculation, but if time exceeds the estimate, it must not report zero remaining as if the job were complete. Ask for an authorized remaining-work review, preserve the original estimate, and do not move subsequent commitments automatically.

## 8. Recurring service scheduling

Required initial service patterns: weekly, every N weeks, selected weekdays, effective start, optional end date/count, time zone, preferred arrival window and normal job template. Monthly/date-based extensions need explicit missing-day policy before enabling them; do not reuse recurring expense rules without checking semantics.

- Keep a series definition separate from generated visit occurrences and separate from actual completed work.
- Occurrence identity must survive rescheduling; use stable series identity plus original recurrence identity, not the moved display date.
- Materialize/query a finite horizon. Never generate an infinite series on startup.
- Scope edits explicitly: this visit, this and future visits, or series defaults. Completed occurrences and historical exceptions never change retroactively.
- Skipping/cancelling one visit retains its exception and does not cancel the series.
- A series edit rechecks conflicts, preserves detached/moved exceptions, and does not silently assign work to unavailable staff.
- Recurring preference is not permission to send messages or charge a customer.
- Series proposal, confirmation and delivery are distinct. Initial draft generation cannot populate the company's confirmed calendar without review.

Store local recurrence intent with its named time zone. Define and test daylight-saving gaps/ambiguous times, leap days and month boundaries. Never silently shift a nonexistent local time; show a conflict/proposal requiring the configured reviewed policy. A device changing time zone does not rewrite the appointment's service-local time.

## 9. Improvement from history, without AI

### What may improve

Typical job/phase duration, setup/cleanup allowances and suggested preparation can use comparable company-confirmed records. Estimates, customer prices, employee permissions, qualifications and signed records must not be changed automatically.

### Minimum history contract

- Job/phase/service-template identity and version; completed source revision.
- Planned effort and elapsed duration, actual work intervals, crew roles/count and their attendance intervals.
- Whether the actual time includes travel, waiting, breaks, setup and cleanup.
- Separately recorded delays, changed scope, rework/return visits, cancellation and incomplete capture.
- Company/authorized source scope, confirmation actor/time and correction provenance.

No time inferred from a scheduled appointment, invoice amount or GPS stop is confirmed productive time. Do not turn missing time into zero-duration work. Source corrections or revocation must invalidate affected derived history.

### Proposed transparent first estimator

Use comparable company job type/template revision, phase, crew composition and duration basis. Do not compare a two-person install with a one-person inspection merely because titles share a word.

Begin with median and a displayed range of confirmed comparable observations, plus count and date range. Suggested initial minimum is five independent completed comparable jobs; this is a proposed configurable product default, not a statistically guaranteed threshold. Do not inflate evidence count by counting several entries from the same job as separate jobs. With inadequate data, use the reviewed planning value and say there is not enough comparable history.

Keep sparse samples separate rather than widening comparison silently. Show delay/change-order exclusions and their reasons; unusual jobs are not deleted. Do not claim a confidence percentage unless independently calibrated and explained. Never provide employee leaderboard, pay, discipline or skill-rating recommendations from this estimator.

The user can inspect the source history they are permitted to see, accept/override a suggested planning value, or disable history assistance. Store which method/version and source snapshot produced an accepted suggestion. Disabling assistance does not erase business records or prevent manual scheduling.

No cross-company training, hidden employee surveillance, or automatic customer promises. Recommendations use only data the requester may use; an aggregate must not leak private employee/customer information.

## 10. Permissions and company policy

Required separate capabilities include viewing own/assigned/team/company schedules, viewing permitted availability, creating draft schedules, confirming schedules, assigning/reassigning specific employees, rescheduling/cancelling visits, managing recurrence, editing availability/skills, inspecting duration history and overriding specific soft constraints.

Roles seed permissions; job title does not grant them. A working owner can have individual and Company Overview scopes without duplicated records. A solo owner need not see an artificial administrator/technician switch.

Apply authorization before queries/counts/candidate generation, before returning reasons, at routes, at commands, and at export/sync. Bind every proposal to organization, actor, permission revision, job revisions and availability/commitment revisions. Recheck on confirmation. A proposal created before access revocation is not authority to commit afterward.

Busy-time conflict checking sometimes needs reservations whose job details a planner cannot see. Use a separately authorized free/busy projection or server-side constraint check with generic reasons. Do not expose hidden job names, customer locations or private leave explanations; do not ignore hidden reservations and claim availability.

An offline device cannot receive instantaneous revocation. Define a bounded offline authorization policy before organization rollout. Unknown/expired authority cannot silently grant company scheduling power. Local pending work and server-acknowledged company commitments must be visibly distinguished; never market cached UI checks as complete security.

## 11. Local persistence, Firebase backup and team synchronization

Cross-module policy owner: `data_storage_sync_contract.md`. The local/Hive and
optional-backup plan below is historical direction, not a resolved app-wide
cloud-authority choice. U02 governs category authority, offline privileges,
sync versus paid backup, external media and retention. No storage migration here.

The owner's target is Hive-backed local operation with optional Firebase backup. Current UI Lab Work is not proved durable by the presence of durable Expense code. Do not silently substitute a different database or migrate existing Expense/receipt/notification storage inside the scheduling task.

First implement repository contracts and in-memory test adapters for the headless engine. Before durable cutover, provide a schema/migration decision: reuse of existing common storage mechanics, an isolated Hive adapter, identity mapping, revision/audit transaction boundaries, recovery, encryption/key handling and data export/rollback. Any new dependency or shared startup change is a coordinated integration slice.

Required commit behavior:

1. Validate current organization, actor, permissions, record state and referenced IDs.
2. Recheck versions and all employee/resource conflicts using the confirmation snapshot.
3. Persist commitment, audit and durable outbox intent together under an explicit atomic/journaled contract.
4. Return confirmed-local/pending-sync status only after durable success.
5. Refresh calendar/Dashboard projections from the saved owner record.
6. Process notification and sync intents idempotently; delivery failure cannot erase the saved schedule.

Command IDs scoped to organization prevent duplicate saves/retries. A crash during a multi-visit confirmation must yield all-or-nothing locally, or an explicitly designed recoverable batch state; never silently leave half the week scheduled. Do not assume independent Hive boxes or a checksum provide cross-record transactions.

Firebase backup is recoverable data protection, not automatically live employee synchronization. Team sync needs authenticated memberships, server authorization, revision/conflict checks, acknowledgements and notification publication. Two offline devices can propose overlapping reservations; the app must detect that on reconciliation and require review rather than silently overwrite either version or pretend both were globally confirmed.

History remains available offline from authorized cached records. Restoring a backup must preserve IDs, audit and revisions, avoid replaying sent notifications, and reconcile pending commands safely. Scheduling must not create Firebase projects, deploy rules, enable billing, publish access, or run unbounded cloud tests without separately authorized setup.

## 12. Calendar and dashboard preservation contract

Required at every supported width:

- Today's Plan, Today's Entries and readable Week/Month calendar remain available.
- Past days show confirmed history and permitted corrections; today shows plan and activity; future days show scheduled work and due items.
- The calendar is not limited to scheduling. Expenses, payments, trip/workday, maintenance and repairs retain their existing or planned owning-module projections.
- A date opens the existing separate day route. Source rows open exact records by stable ID.
- Counts and event order are derived from authorized source events, not independent demo dictionaries.
- Unscheduled work appears in the unscheduled queue, not on every calendar day because its date is null.
- Multi-day jobs project visits/reservations accurately; an end exactly at midnight uses the defined interval rule rather than creating a false extra day's booking.
- Actual event time, planned time and audit edit time stay distinct. A correction today does not move yesterday's payment to today.
- Rescheduling removes the old planned projection and creates the new one while retaining audit/history. It does not delete completed events from the original day.
- Cancelling/deleting a projection is not permission to delete the source record.

The scheduling builder does not redesign calendar cells, change mobile calendar readability, add dashboard boxes, change bottom navigation, move menu actions, or invent another responsive engine. The UI conversation owns that work. Required adapters are coordinated after headless contracts pass.

### Owner-required protection: daily entries are outside scheduling's write authority

This protects **every day's entries, including today**, not only past dates. The scheduling assignment must not edit, delete, move to another day, reattribute, renumber, recreate or reseed actual entries. Protected records include expenses, receipts, payments, invoice activity, trips/mileage/odometer readings, workday events, material movements, maintenance, repairs, notes/evidence and confirmed arrival/work/pause/completion events. Other non-scheduling dated records remain protected even if not enumerated here.

- Scheduling reads only permitted facts needed for planning. Its command/repository interfaces must not expose general-purpose day replacement, history deletion or actual-entry update methods.
- If the existing store combines Plan and Entries in one day object, do not clear/rebuild/save that whole object from a stale scheduling snapshot. Before integration, design a revision-safe targeted schedule command that preserves unrelated fields and concurrent activity.
- Moving an appointment changes only its planned commitment/projection. An arrival, receipt or payment already recorded against that Job stays on its actual event date, with its original actor, source ID, amount/value, attachments and audit history.
- Cancelling a visit or changing a recurring series must not cascade-delete linked actual records. Actual completion is read from the execution owner; the scheduler cannot manufacture, undo or reset completion to free capacity.
- Calendar markers/counts may legitimately reflect changed planned appointments, but actual-entry counts, ordering, source links, visibility rules and amounts must remain correct. Do not freeze all calendar counts as a shortcut, or replace mixed activity markers with schedule-only counts.
- Existing authorized entry corrections remain the owning module's separate workflow. These protections do not remove that capability; they prohibit the scheduling builder from changing it or using it as a migration shortcut.
- No reset, fixture reseed, broad data migration, database deletion or removal of existing records to make tests pass. Test fixtures use isolated temporary storage, never the owner's live app data.

S0 must identify the actual-entry owners and every mixed Plan/Entries write path. S1-S2 have no live storage writes at all. S4-S5 cannot integrate until the owner approves the narrow adapter scope and the preservation tests below pass. If safely preserving a mixed store is not yet possible, report that specific dependency and stop integration rather than overwrite it.

## 13. Job completion and billing dependency

The owner requires a company-configurable Finished/Finish Job workflow. This is a Work lifecycle dependency, not permission for the scheduling builder to implement invoicing or payment handling.

- Scheduled work is not arrived work; arrived work is not started work; only active/otherwise policy-eligible work can finish through the authorized completion review.
- A non-job task cannot create an invoice merely because it is marked complete.
- Completion records confirmed actuals and outstanding/return-visit work under explicit company requirements.
- Once work completion is saved, company policy may route to office review, an invoice draft, approval review, customer signature if required, invoice issue/delivery and optional payment recording.
- Invoice view/create/edit/approve/issue/send and payment collection/recording are separate capabilities. No field employee is forced to see or handle money.
- A signature is tied to the exact document/revision and purpose. Customer job-completion acknowledgment, estimate acceptance and invoice acknowledgment are not interchangeable.
- Finishing work, signing, issuing, delivering and receiving payment remain separate recorded outcomes. Retries must not duplicate invoices or payments.
- Scheduling consumes confirmed completion/remaining-work facts; it never issues an invoice, records a payment, changes terms or notifies a customer itself.
- Customer portal implementation remains a later, separately approved slice after technician and office workflows are settled.

## 14. Screen-facing contracts, not new screen authorization

### Dedicated Scheduling workspace — recommended, awaiting layout agreement

The owner proposed a separate Scheduling screen. Recommendation: use a dedicated planning workspace backed by the same scheduling domain and shared calendar projections, not another scheduling store or independent calendar system. This documents the intended capability; it does not authorize the engine builder to implement UI.

Its primary action is **Schedule a job**, with clearly labeled paths to:

- **Approved estimates:** authorized accepted estimates needing conversion/planning; show existing linked work instead of duplicating it.
- **Unscheduled jobs:** direct jobs, remaining visits and other ready work, with blocked/not-ready work separately identified.
- **New service job:** immediate intake without a required estimate, including a prominent priority selector and assessment-visit option when scope is unknown.

The screen should show the scheduling queue, selected day/week commitments and people/crew availability. An authorized planner can inspect a job, choose people/time or request suggestions, review conflicts and confirm. Recurring controls belong to the same workflow. Solo operators see their own capacity without mandatory employee-management setup; field employees see only permitted assignments/actions.

On wide layouts, pair a bounded queue with the planning workspace and reveal selected-job details where useful. On phones, provide the same queue, day/week and assignment capabilities through clear views with preserved selection—not a squeezed multi-person desktop grid. Exact dimensions and placement remain with the UI conversation. No tiny month grid, new private breakpoints or loss of historical browsing.

Keep **Scheduling** (planning and dispatch), **Calendar** (scheduled work plus dated historical records), and **Today's Plan** (the person's actionable assignments) distinct in purpose but backed by the same source IDs and commands. Navigation placement is still to be agreed; do not silently replace any of the five requested bottom destinations.

### Shared surface interfaces

| Existing/future surface | Needs from scheduling | Must not do |
| --- | --- | --- |
| Dashboard / My Day wording under review | Scoped plan, states, visit IDs, exact source actions, activity, calendar projections | Duplicate next-job panel or fabricate job details |
| Company Overview | Authorized backlog, conflicts, capacity by skill, workload, pending confirmations | Reveal private personnel details or unapproved financial totals |
| Scheduling workspace, proposed | Intake queues, priority, day/week commitments, capacity, suggestions and reviewed changes | Require an estimate for every job or maintain a second editable schedule |
| Job planning/editor | Requirements, valid people/resources, candidate windows, missing facts, confirm action | Treat an estimate's creation date as appointment date |
| Employee profile | Company-confirmed skills/qualifications and availability editing by permission | Keep independent scheduler-only employee identities |
| Calendar Day | Scheduled and actual events with exact owner links | Own a separate editable schedule |
| Recurring-service management | Series/visit exceptions, edit scope, upcoming preview | Rewrite completed visits when a template changes |
| Job finish review | Completion status and remaining-work update | Couple successful completion to successful internet delivery |

Errors are plain-language and actionable: required skill unavailable, missing duration, employee unavailable, appointment changed since review, pending organization confirmation, or search limit reached. Use localized labels and duration/date formatting for English, Spanish and French; engine reason codes are not UI copy. Respect accessibility scaling and existing shared layout rules when the UI owner integrates them.

## 15. Verification matrix

Every test below must have an explicit expected result, not just execute without throwing. Tests use fixed clocks, fictional organizations and stable seed IDs. Never seed a real customer's account implicitly.

| ID | Scenario | Required evidence |
| --- | --- | --- |
| SCH-01 | Exact-fit solo appointment | Feasible interval and zero slack correctly reported; no automatic commit |
| SCH-02 | Adjacent appointments with travel | Arrival buffer blocks an otherwise touching interval |
| SCH-03 | Overlapping leave and existing job | Busy union counted once; no negative capacity |
| SCH-04 | Multi-skilled employee | Same minute cannot satisfy two simultaneous roles |
| SCH-05 | Technician plus helper | Both required roles overlap for the entire required phase |
| SCH-06 | Extra helper on nonparallel work | No invented duration reduction |
| SCH-07 | Enough aggregate hours, fragmented time | Non-splittable job rejected for that day |
| SCH-08 | Split phases / multi-day job | Dependencies, buffers, per-visit IDs and capacity remain correct |
| SCH-09 | Qualification expires during visit | Policy-valid interval required, not just qualification at proposal time |
| SCH-10 | Vehicle/equipment maintenance overlap | Exclusive reservation prevents conflicting assignment |
| SCH-11 | Missing duration/availability/skill | Explicit insufficient-data result, not feasible by default |
| SCH-12 | Approved estimate versus job planning override | Original estimate/revision/signature unchanged |
| SCH-13 | Backlog with pending estimates | Unconfirmed business not silently counted as booked capacity |
| SCH-14 | Capacity dominated by one specialty | Generic free hours cannot hide a specialty backlog |
| SCH-15 | No feasible plan / bounded search exhausted | All unplaced jobs accounted for; impossibility distinct from incomplete search |
| SCH-16 | Same input/order-independent snapshot | Stable deterministic result and reason ordering |
| SCH-17 | Two different organizations | No cross-company IDs, counts, candidates, evidence or reasons leak |
| SCH-18 | Hidden busy reservation | Generic conflict blocks double booking without disclosing hidden record |
| SCH-19 | Permission or availability changes after preview | Confirmation rejects stale proposal and requires refreshed review |
| SCH-20 | Double tap / retry after crash | One commitment and audit result, no duplicate notification intent |
| SCH-21 | Disk failure / damaged snapshot / restart | No false success; recoverable last valid state and retained input |
| SCH-22 | Two offline planners reserve same person | Explicit pending/reconciliation conflict; no silent last-write-wins |
| SCH-23 | Weekly / every-other-week series | Correct bounded occurrences and stable identity |
| SCH-24 | Move/skip one recurring visit | Other visits and original recurrence identity preserved |
| SCH-25 | This-and-future series edit | Past completed occurrences and exceptions unchanged |
| SCH-26 | DST gap / repeated local hour / device-zone change | Explicit policy, unambiguous stored instant and preserved service-local intent |
| SCH-27 | Midnight end / leap day / year boundary | Correct date inclusion and counts without duplicated day |
| SCH-28 | Historical entry then reschedule/reassign | Actual history and original actor retained; only planned projection changes |
| SCH-29 | Calendar past/today/future and Back | Existing historical records and exact source routes remain reachable |
| SCH-30 | Sparse/incomplete/changed-scope duration history | No misleading typical-duration claim; exclusions explained |
| SCH-31 | Two-person versus one-person history | Comparable duration basis only; no inflated independent sample count |
| SCH-32 | Correct source actuals / disable history | Derived suggestion invalidates; manual scheduling still works |
| SCH-33 | Finish without invoice permission | Completion durable; no financial action or data disclosure |
| SCH-34 | Finish with draft-only versus issue authority | Correct reviewed workflow handoff; no implicit issue/payment |
| SCH-35 | Notification/backup failure after local commit | Schedule remains saved; retry intent retained without false delivery claim |
| SCH-36 | Restore backup with pending/sent intents | No duplicate commitments, reissued invoices or repeated delivery |
| SCH-37 | English/Spanish/French, large text, narrow/wide host | Same accessible capabilities, no hidden essential actions or private breakpoints |
| SCH-38 | Synthetic scale/load runs | Bounded query/search/memory; report measured dataset/time limits rather than unlimited-scale claims |
| SCH-39 | Direct urgent job with no estimate | Intake and feasible visit can be recorded without fabricated approval, pricing or estimate records |
| SCH-40 | Unknown repair scope | Explicit assessment allowance used; no zero-duration slot or invented full repair commitment |
| SCH-41 | Change priority / customer-reported urgency | Authorized, audited change only; status/deadline/price unchanged; untrusted urgency cannot self-promote |
| SCH-42 | Urgent insertion against existing commitments | No silent displacement; explained proposed moves, permission/revision checks and separate communication state |
| SCH-43 | Approved estimate already converted / retry | Existing Job reused; no duplicate job or visit; unscheduled remainder preserved |
| SCH-44 | Sustained urgent queue | Routine overdue/deferred work remains visible; deterministic policy and waiting-age explanations |
| SCH-45 | Separate Scheduling and historical Calendar surfaces | Same source commitment IDs and authorized commands; intake source does not suppress historical events |
| SCH-46 | Mixed day containing planned work and actual entries | Schedule create/move/cancel leaves every protected actual record's ID, date, actor, revision, values, links and attachments unchanged |
| SCH-47 | Receipt/payment recorded after schedule preview | Concurrent new entry survives confirmation; stale full-day replacement is rejected or avoided |
| SCH-48 | Reschedule Job after arrival or recorded costs | Only authorized future planning changes; arrival/costs remain on original actual dates and retain ownership |
| SCH-49 | Recurrence cancellation / failed save / retry / restart | No actual entries deleted, reseeded, duplicated or reattributed; planned and actual markers reconcile independently |
| SCH-50 | Scheduling interface boundary | Calculator has no writes; scheduling commands cannot invoke day replacement or actual-entry mutation; isolated tests never touch live records |

Add property tests for conservation of person-minutes, interval containment, no overlaps, correct qualifications/crew at every allocated interval, nonnegative durations, no cross-organization references, and no lost/duplicated occurrences. Compare small generated scheduling problems with a simple exhaustive reference solver in tests so a defect in the production heuristic is not copied into expected results.

## 16. Safe build sequence and gates

| Phase | Deliverable | Exit gate |
| --- | --- | --- |
| S0 | Read-only source/5.7 reuse map, field ownership and dependency decisions | Existing write routes, identities, missing employee sources and protected paths listed |
| S1 | Pure domain contracts, validation, clocks/policies and fixtures | No widget/storage/network side effects; unit/serialization contract coverage |
| S2 | Single-job feasibility and alternative openings | SCH-01 through SCH-12, SCH-15 through SCH-19 relevant core portions and property tests |
| S3 | Day/week draft planning, backlog, recurring service | Deterministic placement, unscheduled reasons, finite expansion and temporal tests |
| S4 | Approved local repository adapter and authorized command service | Restart, failure, idempotency, transaction/audit/recovery tests; no false durability claims |
| S5 | Coordinated adapters into Jobs, employees, calendar and notifications | One write authority; source-ID reconciliation; SCH-46 through SCH-50 preservation evidence and existing calendar regressions |
| S6 | Confirmed actual-time history and transparent recommendations | Sparse-data, delay, correction, privacy and comparable-crew tests |
| S7 | Separately approved team-sync/device acceptance | Real authorization/conflict/delivery tests in isolated test organization |

First parallel assignment is S0-S2 only, in an isolated checkout. It must not modify UI, existing calendars, app startup, pubspec, or existing shared stores. Subsequent phases require reviewed contracts and coordinated integration; completing pure calculations is not completing the whole scheduler.

### Required dependency handoff before integration

S0 must produce an explicit contract/dependency table: input or command, authoritative module, stable ID/revision, units/time zone, read/write permission, missing-data behavior, implementation status, responsible integration slice and acceptance test IDs. Cover Jobs/approved-estimate conversion/direct intake, employee membership/skills/availability, resources/material readiness, schedule storage, actual-time/history, calendar projections and notification/sync adapters.

When a required subsystem is absent, define the smallest interface and deterministic fictional fixtures for engine tests. Mark it **not connected**, name the blocked production capability and propose the bounded follow-up. Do not pretend a fixture is a working employee database or expand this assignment into building all missing modules.

At every phase, deliver the requirement-to-test matrix, changed-path manifest, exact executed checks, unsupported cases and remaining decisions. A test ID in this document is a requirement, not evidence that its test exists or passed. For the eventual adapter tests, snapshot typed protected records before and after each schedule command and verify both preserved source fields and correct calendar projections; checking only total record count is insufficient.

The device acceptance plan uses fictional solo and crew companies. Available owner devices include S24 Ultra, S25 Ultra, iPhone SE third generation, Samsung S9 Plus, macOS and Windows machines. Verify actual connectivity before testing. Use two devices for planner/field scenarios, another for conflicting/offline actions; reuse ordinary authenticated account and record flows in a test environment. Do not run several emulators or parallel builds on the 8-GB Mac. Screenshots require fresh explicit owner authorization.

## 17. Proposed defaults and unresolved decisions

The business outcomes and safety boundaries are required. These details need owner review or explicit S0 proposals before integration:

- Daily working hours, breaks, overtime policy, contingency thresholds and what comfortable versus tight means.
- Normal appointment rounding/search grid, planning horizon and bounded-search budget.
- Priority labels, urgency/deadline ordering, emergency dispatch review, and the Scheduling workspace's navigation/layout placement.
- Job types, phase parallelism and crew-role rules; never silently invent trade-specific productivity.
- Recurrence approval policy, holiday/weather deferral and monthly missing-day/DST behavior.
- Who may edit skills/availability and override each soft constraint; audit and retention policy.
- Minimum history sample, comparison groups, age window and treatment of unusual jobs.
- Hive adapter/encryption/migration design and shared employee/Work durable ownership.
- Organization-sync authority, offline permission expiry and cloud cost/test limits.
- Completion checklist requirements, invoice approval/signature policy and payment permissions.

Record each decision with owner, date, version and affected tests. A missing decision may block a particular capability without blocking pure engine work on explicit test policies.

## 18. Definition of done and evidence honesty

Report scope, files, tests actually run, measured limits, known gaps, migration changes and remaining owner decisions after each phase. Keep a requirement-to-test mapping using the SCH IDs. Mark PLANNED, IMPLEMENTED, TESTED or OWNER ACCEPTED separately.

The scheduler is not production complete until durable storage, permissions, historical calendar behavior, offline/restart/conflict handling, integration, real-device testing and owner workflow acceptance pass. Do not label mock data, UI visibility checks, a source inspection or a green unit test as full company simulation or enterprise security.
