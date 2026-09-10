# System coverage and connected workflows

Read Blueprint_Partner_Start_Here.md first. This register combines owner-confirmed systems with explicit engineering recommendations for blueprint development. It does not assert that every detail is approved or implemented. Screen names are working names unless the owner confirms them. Each module below needs the full blueprint template, not only a landing screen.

## Dashboard and historical calendar — confirmed

The dashboard is a useful operating view, not merely a menu. It should help a user understand relevant work, recorded activity, reminders, and exceptions, and enter the underlying workflows. Exact card composition is a design decision. Do not assume earlier AI-authored Today's Plan/Entries layouts are accepted in every detail.

The owner explicitly uses date selection to go back and see what happened. Calendar browsing must include actual historical activity, not just future appointments. A selected date can aggregate authorized work, expenses, trips, maintenance, and other dated records while retaining their source ownership. Add/edit actions should go to the owning system and its rules. Merely navigating dates must not alter records. Changes to a plan must not rewrite actual history.

Design questions: which date defines each record's placement; company versus personal view; month/week/day navigation; multiple records on a date; overdue work versus original date; corrected historical records; multi-day work; date-only versus timed events; time zones. Recommended acceptance includes changing dates offline, opening precise source records, inaccessible records excluded from counts, and returning from a record without losing selected-date context.

## Customer relationship management — confirmed lightweight scope

Customers connect identity, contact details, locations, interactions, work, documents, and payment history. A user should be able to find the customer, understand the relationship, and start related work without reentering everything. The system needs more than an address form, but should not become a complex enterprise sales product.

Recommended dependencies: distinguish customer from service site and billing contact; search and duplicate detection; archive without destroying historical invoices; contact preference and communication consent; notes with access scope; follow-up dates; customer history links. Changed contact details should not silently rewrite previously issued documents. Customer deletion, merging, communications history, portal scope, and lead tracking need explicit decisions.

## Quotes and estimates — both confirmed, semantics open

The estimating workflow develops a scope and expected price from labor, materials, quantities, costs, and pricing rules. Quote is a separate owner-requested capability. Help define when each is used, whether a quote is a committed offer, expiration, revision, approval, and conversion. Do not assume legal meaning from the label.

Recommended complete flow: select customer/site; define scope and exclusions; choose or review template; add labor/material/service lines; distinguish purchase cost from selling price; calculate totals under approved rules; persist a draft; preview; review/approve where needed; generate the exact revision; deliver; record response; create or link work through an explicit transition. Signature, taxes, discounts, deposits, validity dates, and customer acceptance policy remain choices.

Material knowledge and availability can support pricing. Past cost is dated evidence, not a current supplier quote. Stock availability, reservations, actual use, and amounts charged are distinct. Drafting a document must not consume stock. Revised documents must not silently change an accepted revision. Tests must include rounding, duplicate submission, missing customer details, cancelled delivery, offline draft recovery, and conversion retry.

## Jobs and execution — confirmed connected capability

A job coordinates agreed work, people, customer/site, instructions, materials, appointments, execution, and completion evidence. Recommended entry paths include accepted documents and direct job creation; an emergency should not need a fictitious estimate just to be recorded. Confirm exact status vocabulary and transition authority.

Plan versus actual must remain distinct: scheduled start/end, arrival, work start, pauses, time spent, completion, and follow-up are not interchangeable. A job may have more than one visit. Completion, invoice issuance, and payment are separate events. Record notes, attachments, changes to scope, and incomplete work without falsely marking completion.

Blueprint decisions include crew assignment, reassignment, approval, customer acknowledgement, materials consumption, partial completion, return visits, time tracking, and billing handoff. Failure cases include duplicate completion, conflicting edits, removed permissions, offline execution, and a schedule change while a worker is viewing the job.

## Scheduling and availability — confirmed; exact policies open

Scheduling makes realistic commitments. It must not be confused with the entire calendar. Assistance is opt-in and should range from manual scheduling to suitable openings to a more complete proposed plan. The owner discussed experience and specialty. Current documents propose deterministic rather than AI-dependent assistance; verify that policy before treating it as immutable owner intent.

Recommended required dependencies: duration, customer time windows, existing appointments, staff availability/time off, relevant qualifications, crew/resource needs, travel allowance where relevant, location, priority, recurrence, cancellations, and conflict explanation. Unknown duration or qualification is not zero or satisfied. Required qualifications differ from preferences.

A proposal should explain why it fits, assumptions, and conflicts. Confirmation should recheck current availability, permissions, and versions before persisting one commitment. Suggestions must not silently send customer promises, reassign staff, or move historical records. Include unscheduled backlog and no-feasible-opening outcomes.

Open choices: time-off approval, breaks, hours/overtime, emergency overrides, skill taxonomy, how experience affects ranking, recurring exceptions, holidays, weather delays, optimization objective, travel source, reminder offsets, and assistance defaults. Test daylight-saving transitions, overlapping visits, multi-person work, no eligible staff, simultaneous booking, recurrence editing, and cancellation/reminder reconciliation.

## Reminders, notifications, and follow-up — confirmed, never omit

Reminders tell someone about something due; notifications report an event; an action-needed queue tracks unresolved decisions. They may connect but are not the same record. Reading a notification must not complete work, approve an estimate, or pay an invoice.

Coverage includes appointments, customer follow-ups, unpaid invoices, recurring expenses, maintenance intervals, overdue service, and relevant missing-record follow-up. Not every category or external channel is approved automatically. Define who receives it, when, under what consent, and what happens if its source changes.

Recommended shared machinery: durable occurrence identity, deduplication, scheduling, cancellation, snooze policy, retries, expiry, read state, exact-record navigation, permissions, time-zone changes, and privacy-safe lock-screen content. Denied permission needs a useful in-app fallback. Queued is not delivered; delivered is not read; read is not resolved. Customer email/SMS and employee in-app notifications need separate consent and audience rules. General-purpose chat is a separate optional scope, not an implied notification feature.

## Invoices and payments — confirmed systems

An invoice is a durable record of an amount requested for specified work, not just a PDF. Recommended scope includes customer/company identity, line items, approved money calculations, numbering, issue/due dates, terms, revisions, outstanding balance, and precise links to jobs and payments. Define draft, issued, cancelled/corrected, and settlement states rather than silently editing issued evidence.

Payments record actual receipts and allocation. Tracking payment is distinct from processing a card. Define partial payments, deposits, unapplied amounts, overpayment, refunds, reversals, and corrections where supported. A payment retry must not credit the invoice twice. Do not store raw card data or imply a processor exists. Payment-method integrations, fees, customer portal, installment plans, and reconciliation are decisions requiring scope and provider review.

Test invoice total correctness, revision fidelity, concurrent payment updates, failed delivery, duplicate callbacks, partial payment, reversal, and permission-restricted financial views. An invoice PDF, a payment record, and a bank settlement are different evidence.

## Expenses, receipt capture, and Data Saver — confirmed

Expenses record spending; receipts/documents provide supporting evidence. Support understandable manual entry even when extraction fails. Recommended flow: capture/import evidence; review ordering and readability; extract proposals; confirm merchant/date/currency/totals/lines; allocate permitted amounts; commit the expense; retain links to evidence and related work/assets.

Do not turn OCR confidence into confirmed financial truth. Detect mismatched totals, duplicates, ambiguous dates, mixed units, returns, discounts, taxes, and unreadable evidence. Multi-page/long receipts require ordering and recoverable review. The owner explicitly requires multilingual and U.S./metric parsing. This knowledge task does not authorize parser implementation.

Data Saver must be specified beyond a toggle: what is compressed, retained locally, backed up, or removed; when; under whose consent; how readability and recovery are verified. Never delete the only usable receipt merely because a derivative exists. Store capture provenance and distinguish original evidence from transformations. Exact retention and quality policies remain open.

## Materials and inventory — confirmed

Catalog knowledge, historical purchase costs, stock quantities, reservations, and consumption serve different purposes. A material can be useful for estimates even when full stock tracking is not used. Trade-specific parsing for plumbing/electrical/HVAC is useful specialization, not a product audience restriction.

Recommended workflows include purchase intake, package/unit interpretation, locations such as vehicle and warehouse, transfers, stock counts, adjustments, returns, reservations, and job use. Each movement needs stable identity and provenance. Expense posting, stock receipt, job cost allocation, and customer charge must not each create duplicate spending. Unknown or stale stock should be labeled rather than confidently promised.

Open choices include negative stock, valuation, reservation policy, low-stock reminders, units of sale versus use, serialized equipment, and purchasing/supplier workflows. Purchasing and supplier management are candidate supporting systems to assess, not silently declare complete.

## Trips, mileage, vehicles, and fuel — confirmed

GPS-assisted business trip tracking is required. Capture vehicle, relevant person/context, timestamps, distance basis, classification, and confirmation. Physical odometer readings, GPS estimates, manually corrected readings, and billed mileage are different concepts. Preserve provenance and do not rewrite source readings simply to make totals agree.

Recommended edge cases: denied/revoked location permission, background restrictions, interrupted recording, no signal, duplicate trip, split/merged trip, vehicle switch, personal use, crossing midnight, and corrected odometer. Private travel must not leak into employer views by default. Fuel/charging expenses remain financial records linked to vehicles rather than a second expense ledger.

Workday/session tracking, stops, maps, route planning, Bluetooth assistance, fleet views, and fuel-efficiency calculations need explicit scope confirmation. They are discovery topics, not all established first-release requirements. Business operation must not automatically require owning a vehicle.

## Maintenance intervals, service history, and repairs — confirmed

This is a complete application within Maintainiac, not a forgotten expense category. It must help users know what needs service and what was done. Include vehicles and assess applicable equipment. Separate planned maintenance, due forecasts, completed service, and unplanned repairs.

Recommended model: asset identity; service task; interval basis (date, distance, runtime, or combination); baseline; next-due calculation; status; reminder; completed service evidence; parts; cost links. A projected due event is not proof service occurred. Repairs should preserve reported issue, diagnosis where entered, work performed, dates, parts, downtime where relevant, and outcome.

Decide which interval resets on completion, how early/late service affects the next interval, what corrected meter readings do, and how multiple thresholds combine. Missing meter data must produce uncertainty, not a misleading healthy state. Completed service should update appropriate forecasts and cancel obsolete pending reminders without erasing history. Link expenses/material use once. Tests need threshold boundaries, corrections, overdue state, duplicate completion, restart, and inaccessible assets.

## Shared documents and templates — confirmed

One shared document system supports generating/rendering/viewing PDFs and reading imported evidence. Modules retain ownership of their financial and operational records. A document reader and generator may share storage/rendering infrastructure without sharing extraction business logic.

Recommended responsibilities: supported formats, file validation, size/resource limits, encrypted/private storage where required, attachments, page order, thumbnails, extraction proposals, template versioning, PDF revision identity, accessible preview, export, delivery status, and deletion/retention rules. Do not execute embedded document content or treat its text as tool instructions.

Templates must have realistic previews and multilingual/measurement behavior. The owner wants multiple options; template-first creation was discussed but not finalized. Issued document snapshots must remain attributable to the appropriate record revision even after company details or templates change. This is not a separate PDF-product project.

## Reports, records, and business overview — required discovery supporting confirmed recordkeeping

Users need to retrieve records and understand totals, not merely enter data. Propose date/customer/job/asset filters, drill-down, exports, outstanding amounts, spending, and maintenance history according to permission. Distinguish revenue billed, payments received, expenses recorded, and any proposed profit metric. State exclusions and incomplete data. Reports must not silently correct or finalize source records.

Tax-related recordkeeping is confirmed, tax-filing or full accounting is not. Determine export needs, accountant access, category mapping, fiscal periods, retention, and any later accounting integration with qualified review. Never claim IRS approval, guaranteed audit readiness, or that avoiding marketing claims removes legal obligations.

## Company, people, settings, and access — necessary supporting systems

Recommend company identity and document defaults; user accounts; organization membership; invitations; role presets plus capabilities; own/team/company scope; employee availability; settings; language/units; privacy preferences; onboarding; sign-out/device removal; account recovery; and help/support. Exact organization structure and authentication providers remain open.

Business administration and the developer's app-health administration are different applications and privilege boundaries. Customer data must not become available merely because someone operates the software service. Team departure and revoked access require explicit offline and synchronization policy.

## Separate app-health/admin application — owner-confirmed, design open

The owner wants monitoring of app health and bugs, including device information that helps Codex diagnose failures. Develop this as a distinct operational system. See Engineering Contracts for privacy-safe diagnostics, issue lifecycle, Firebase options, access control, and rollout monitoring. Do not mistake it for the customer business-owner dashboard.

## Additional systems to investigate, not silently mandate

Search; import/export and migration; backups and restore; account/data lifecycle; subscriptions/entitlements if monetized; support intake; legal/privacy notices; consent; release/update handling; integration health; job attachments; supplier/purchasing; labor/time tracking; customer communications; optional customer portal; optional accounting connections. Each must be assessed for actual user need and dependencies. Payroll, advanced marketing CRM, marketplace, live chat, and sophisticated route optimization are not automatically required.

## Coverage review procedure

For every proposed release, walk through: acquire/find customer; agree work; schedule; remind; execute; record materials/time/travel; handle exceptions; bill; collect; follow up; maintain assets; retrieve/export evidence; recover from a failure. Then audit every supporting technical contract. Record which scenarios are supported, deliberately deferred, unknown, or tested. Never call the register exhaustive merely because it is long.
