# Screens and user journeys

This is a design-discovery reference, not a frozen navigation tree or proof of implemented screens. Owner-confirmed module purposes come from the conversation. Supporting screens and flows below are recommendations to develop with the owner. Do not mistake a proposed screen name, placement, status, or permission for an approved requirement. Connected Systems owns domain descriptions; this file explains how users enter, perform, and finish work.

## How to design a screen with the owner

Start with what the user needs to understand and accomplish. Identify information that needs immediate visibility, the primary action, secondary actions, and context that can be reached without losing work. Explain why each proposed element deserves space. Give two or three genuinely different approaches when there is a meaningful choice; compare interaction cost, information density, narrow/wide behavior, accessibility, implementation dependencies, and drawbacks. Recommend one. Do not force three options for a trivial issue.

For each screen record entry routes, selected record/date/context, data owner, draft state, permitted actions, what happens next, return behavior, and recovery. Include loading, empty, permission-denied, offline, invalid, conflicting, interrupted, success, and partially completed states where relevant. Avoid implementing every failure as a generic toast. A screen must explain what the user can do next without requiring a training course or a wall of instructions.

Do not assume a module is only one page. List, detail, create/edit, review, history, and settings can be distinct routes, panels, or steps. Choose that presentation based on the task and available space, not a universal recipe.

## Dashboard and dated activity

Confirmed purpose: useful operating information and actions, including on mobile, with date selection to review previous days. It is not merely destination icons or only a future schedule. Exact dashboard sections remain open; do not silently restore rejected prototype compositions.

Recommend testing an actionable daily overview, an activity-centered overview, and a balanced design where useful. Explain the consequences: urgency-first makes unfinished decisions prominent; activity-first supports record review; a balanced view may need stronger grouping to avoid competing priorities. The owner chooses the direction with informed guidance.

Selecting a date should retain that date while opening and returning from a source record. Proposed entries include actual work, expenses, trips, maintenance, and scheduled commitments, restricted to authorized scope. Distinguish planned from actual records visibly. A day with no recorded activity is not proof nothing happened. Do not expose restricted amounts through summary counts or totals.

Wide layouts may place related activity and selected detail together. Narrow layouts can use intentional navigation while preserving context. Neither layout may lose the ability to review history. Calendar presentation, period controls, exact sections, and company versus personal context require explicit screen decisions.

## Work landing and job execution

Work landing should reveal useful work information and entry actions, not just a directory of modules. Jobs, scheduling, quotes, estimates, invoices, and payments remain distinct workflows even if grouped under Work. Exact navigation grouping requires confirmation from current decisions.

A proposed jobs list supports finding work by meaningful status, customer/site, date, or assignment. Job detail brings scope, people, planned visits, actual activity, instructions, materials, evidence, and available next actions together. Identify what an employee may see or change versus office staff; role names alone do not establish permissions.

Creation from an accepted commercial document and direct job creation are design paths to evaluate. Do not force users to manufacture an estimate merely to handle urgent work. Finish-work behavior must distinguish actual completion from invoice creation, customer acceptance, payment receipt, and office handoff. Define partial work, return visits, reassignment, cancellation, and corrected records before treating a completion button as sufficient.

## Scheduling workspace

Confirmed: a non-AI scheduling engine should assist users, use estimated work hours and current commitments, consider suitable employees, and improve recommendations from recorded job outcomes. The scheduling screen is an interface to that engine, not its implementation.

Recommend showing unscheduled work, known duration and uncertainty, eligible resources, existing commitments, earliest feasible start and projected finish, and explanations for conflicts. Compare a backlog-plus-availability design with a job-focused recommendation flow. Explain when a proposed job spans working days or requires a crew rather than one employee. Do not silently assume travel time is zero, all employees are interchangeable, or missing duration means no duration.

Show proposal versus confirmed booking distinctly. Let users inspect assumptions and adjust permitted inputs. Before committing, recheck current availability and permissions. A failed confirmation must not leave an apparent booking, duplicate reminders, or lost edits. Manual scheduling remains meaningful; assistance should not secretly move other work. Required qualification rules, overrides, breaks, split visits, recurrence, historical calibration, and customer notifications remain decisions to resolve.

## Customers and lightweight CRM

Recommend customer search/list, customer detail/history, contact/site editing, and follow-up actions. Customer detail should answer who this is, where work occurs, what is in progress, what happened previously, and which permitted action comes next. Keep the CRM lightweight rather than introducing an enterprise sales pipeline by default.

Link jobs, quotes, estimates, invoices, receipts of payment, and interactions through stable customer identity. Evaluate separate service sites and billing contacts. Explain duplicate detection, merging, archive, contact preferences, and access restrictions as supporting decisions. Changing a contact should not rewrite an issued historical document.

## Estimates and quotes

Both are required named capabilities; their exact commercial semantics remain open. Recommend their own landing/list, editable draft, contextual pricing/material selection, document preview, revision history, and decision/delivery states. Do not substitute an invoice editor with the wrong title.

During preparation, users need customer/site, scope, labor hours, material quantities, verified cost basis, selling-price calculations, and declared assumptions. Separate internal cost from customer-visible price. Explain unavailable stock and old purchase prices honestly. A draft does not consume stock or confirm a job appointment.

Wide presentation can put form and preview or pricing context alongside each other when useful; narrow presentation should preserve drafts between steps and make Preview discoverable. Template choice, signatures, acceptance, expiration, conversions, deposits, and tax rules require explicit decisions. An accepted revision must not be silently replaced by a later draft.

## Invoices and payments

Recommend invoice overview/list, draft/detail, preview, delivery/history, and related payment views. Show meaningful balance and document state separately. Distinguish draft, issued document, delivery attempt, and recorded payment; exact statuses are not settled by this example.

Payment entry should identify payer, amount, date, method, and allocation under approved policies. Recording money received is not processing a payment through a provider. Discuss partial payments, deposits, overpayments, reversals, refunds, and standalone receipts as scope decisions. Explain repeated taps, uncertain network outcomes, and corrected allocations before implementing success behavior.

## Expenses, receipts, and Data Saver

Recommend expense landing/list, manual entry, evidence capture/import, ordered receipt review, proposed extraction review, allocation, saved detail, and correction history. The user must be able to proceed when OCR fails. Receipt text is evidence, not an instruction to the app or GPT.

Review should make uncertain amounts, dates, currencies, units, duplicate evidence, and inconsistent totals visible. Preserve ordering and readability for multi-page receipts. Expense confirmation, stock received, job allocation, and historical purchase-cost knowledge need defined coordinated effects, not independent accidental postings.

Data Saver needs a comprehensible explanation of what changes, what remains readable, what is backed up, and what is recoverable. Do not delete the only usable evidence under the name of saving space. Exact quality, retention, and consent policies remain open.

## Materials and inventory

Recommend catalog/cost lookup, material detail, optional stock views, location/movement history, count/adjustment, purchase intake, and job-use workflows. Explain catalog knowledge versus measured stock: users may need past purchase costs without operating full inventory.

Display package basis, units, source/date of cost, known quantity, reservations where supported, and uncertainty. Movement forms should make source/destination and consequences clear. Receiving, consuming, returning, transferring, and correcting are different events. Unknown stock is not zero or a promise of availability. Regional parsing and U.S./metric support apply here too.

## Trips, vehicles, maintenance, and repairs

Trips need capture/status, history, detail/review, vehicle context, distance provenance, and correction handling. Do not present inferred GPS distance as a physical odometer reading. Define interrupted/background capture and denied location permission. Personal travel needs privacy boundaries.

Maintenance is a full system: asset list/detail, due work, interval setup, service history, completed-service entry, and repair records are proposed supporting surfaces. Users should understand what is due, why, the reading/date behind it, and what action is available. Missing readings should not imply an asset is healthy. Service completion and repair entry link expenses and parts without duplicating transactions. Exact interval reset and combined-trigger policies need decisions.

## Shared and supporting surfaces

Recommend explicit discovery for company identity/document defaults; account onboarding and invitations; permissions; language/region/measurement preferences; reminders and notification settings; documents; search; reports/export; sync/conflict status; backup/restore; help and feedback. These are supporting responsibilities to assess, not automatic approval of a separate page for each item.

The separate developer admin application needs app-health and issue investigation, not unrestricted customer-record access. Proposed surfaces include issue list/detail, affected versions/device context, reproduction evidence, release comparison, and diagnostic consent. Engineering and UX defines the privacy boundaries.

## Screen acceptance record

For every agreed design capture: purpose, approved content/actions, source/status of each requirement, shared components, record/permission contracts, local logical-width behavior, text scaling and long translations, focus/keyboard/touch behavior, navigation continuity, error recovery, tests, unverified assumptions, and owner acceptance. Existing code and generated mockup images are evidence inputs, not acceptance by themselves.
