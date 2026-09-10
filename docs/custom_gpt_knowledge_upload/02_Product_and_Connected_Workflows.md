# Maintainiac — replacement whole-app blueprint for owner review

Status: review draft, September 6, 2026. Not an approved replacement, implementation specification, or uploaded Custom GPT knowledge file.

This draft reconciles the current conversation with inspected portions of the existing documentation. It does not certify that every subordinate blueprint or implementation has been audited. Existing files remain intact. The detailed references listed below retain useful requirements but contain unresolved contradictions; their “Confirmed” labels alone do not establish owner approval.

## 1. What Maintainiac is

Maintainiac is a business management system and lightweight CRM. It assists business owners and their employees with day-to-day operations and recordkeeping. It brings multiple connected business applications under one roof, each with its own workflows, records, tools, and responsibilities. Screens are the entrances to those systems, not substitutes for the systems themselves.

The initial focus is businesses with ten or fewer people. Larger businesses are not excluded, but their complexity must not dictate the ordinary small-business experience. The owner plans substantial contractor-focused marketing; advertising emphasis does not limit the product definition. Industry examples belong in examples, not repeated disclaimers in the introduction.

The product should make it straightforward to understand what needs doing, perform the work, record what happened, retain supporting evidence, and follow the financial outcome. Users should not need repeated tutorials to understand where they are or what an action does. Simplicity of use does not justify removing necessary capabilities or safeguards.

Safety, privacy, and security for owners, employees, and customers are the highest priorities. Accuracy and dependability are nearly inseparable from those priorities. Release speed does not justify known corruption, misleading records, or unverified access controls.

## 2. Connected applications and shared information

Dashboard, Work, Expenses, Materials, and Maintenance are the currently documented primary destinations. Work is the umbrella for Jobs, Payments, Scheduling, Quotes, Estimates, and Invoices. Each commercial capability needs its own complete workflow, not merely a shortcut or form.

Customers and Company Profile are app-wide destinations accessible through the menu. Estimates, quotes, invoices, and jobs select or link customer records without maintaining private customer lists. Company identity, contact details, logo, and document defaults belong to Company Profile, not exclusively inside the estimate editor. A business-card presentation is a desired use, with its sharing details still to be designed.

Records remain linked to their owners. An expense owns the financial purchase record; inventory owns a stock movement; Work owns a job and its billable work. Linking those records does not duplicate the purchase, deduct stock twice, or silently add an invoice charge. Stable identities, revisions, authorization, and explicit transitions preserve those relationships.

## 3. Dashboard: the daily operating view

The dashboard brings the authorized user's day together. Today's Plan presents planned work and assignments. Today's Entries presents actual recorded activity. Needs Attention surfaces items requiring a decision or action. The calendar supports selecting and reviewing dates. Plan, Entries, and the readable calendar remain available at every screen size.

Selecting an assigned job opens its authorized working details: customer and location, instructions, approved scope, relevant materials, notes, evidence, and permitted actions. A separate duplicate “next job” card is not required merely because other dashboards use one.

Employee views and company-wide views differ according to permissions and context. An administrator may need unassigned work, conflicts, approvals, and company follow-up; an employee needs their authorized work. Financial information and employee details require their own permissions. A role label is not blanket access.

Workday and vehicle information are shared operational context where applicable. Starting or ending a workday belongs to the workday system; the dashboard displays the result. Whether every business workflow must require a vehicle is unresolved: older vehicle-first rules must not be silently imposed on all businesses.

## 4. Calendar: schedule and historical record access

The calendar is both a way to view scheduled activity and a way to look back at what actually happened. Module calendars show the relevant authorized records; the dashboard combines authorized activity. Selecting a date opens its dated record view, and selecting an entry opens the owning record.

Scheduling changes planned commitments. It must not edit, delete, move, recreate, or reattribute actual daily entries, including today's entries. Historical corrections are separate authorized workflows retaining their evidence.

Week and Month views must remain readable. A month view must not be miniaturized to fit an arbitrary dashboard shape. Switching periods, viewing another date, or changing language must not change stored business dates or source records. Dates, time zones, recurrence, daylight-saving changes, and multi-day jobs require explicit handling.

## 5. Lightweight CRM and customer records

Customer records connect people or businesses, contact information, locations, and their relationship with recorded work and documents. Users should be able to find a customer and review the history they are authorized to see, then start or open related work without repeatedly entering the same information.

The intended CRM is lightweight, not a large sales-and-marketing platform. Advanced campaign automation and enterprise sales pipelines are not implied requirements. Exact follow-up, communication-history, duplicate-customer handling, and archiving behavior remain design topics rather than assumed finished features.

## 6. Estimates and quotes

Estimating helps users work out proposed scope and expected pricing using labor, materials, quantities, and relevant costs. Inventory availability and verified purchase history are dependencies of the real estimating workflow. An isolated form or arithmetic test is not an end-to-end estimating test.

Material selection should show what is known to be in stock, what is available after any explicit reservations, and what must be obtained. Previously purchased material can still provide its latest recorded purchase price when stock is zero. That price needs its source, date, vendor, and unit or package basis; it is not a claim about today's store price. Internal cost, markup, and customer price remain separate.

Quotes are a distinct required capability and must not disappear into the word “estimates.” The exact distinction in pricing commitment, customer acceptance, expiry, conversion, and revision rules still needs owner agreement. No legal definition of a quote or estimate is assumed merely from its label.

The document workflow includes selecting a template, entering or reviewing information, previewing the exact document, saving a draft, and authorized delivery and decisions. The owner prefers the supplied section-based form references; duplicate Back controls and incorrect invoice labels on an estimate are not approved behavior. Template-selection order and exact forms still require review.

Preparing a document may identify prospective material demand; it does not silently consume stock. The reservation trigger, expiration, cancellation, and release policy remains to be decided. Accepted or signed revisions retain their historical contents; later edits cannot reuse an old signature as acceptance of new content.

## 7. Jobs and completion

Jobs organize actual work: schedule, assignment, scope, status, notes, evidence, actual materials, and follow-up or return visits. A job can originate from accepted proposed work or be created directly. Emergency work must not require an estimate before it can be scheduled or performed.

Finish Job is a configurable workflow, not simply a completed checkbox. Company policy and separate permissions determine whether the employee reviews billable work, prepares an invoice, obtains a customer signature, sends a document, or records payment. Otherwise, the appropriate office handoff remains available. Completing work, issuing an invoice, receiving a signature, and receiving payment are distinct events.

Partial completion, cancellation, rescheduling, additional work, material returns, and corrections must have defined outcomes. They cannot be implemented as silent changes to previously accepted documents.

## 8. Invoices and payments

Invoicing prepares and manages customer billing, with its own drafts, issued revisions, terms, due information, delivery evidence, and balances. Confirmed job information can supply invoice candidates, but linked expenses or material use do not automatically become customer charges.

Payments records what was received and how it relates to amounts owed. Partial payments, deposits, corrections, credits, refunds, and outstanding balances require explicit rules and history. Document delivery is not proof of payment; recording payment is not the same as processing funds through a financial provider.

Customer document access and signatures require secure, scoped, revision-aware sharing. Portal functionality is desired, but technician and administrator workflows take priority. Employee invitation links and customer document links serve different purposes and must not share an unrestricted account-access model.

## 9. Scheduling assistance without AI

One scheduling system supports opt-in assistance levels: Manual, suggested openings, and proposed day/week plans. These levels share commitments and history. Turning assistance off does not turn off permissions or data-integrity safeguards.

Planning uses available company context: working hours, existing commitments, leave or other unavailability, job duration, readiness, priority, and applicable resources. Optional specialty and experience information can improve recommendations. Required qualifications differ from preferences; missing information is not evidence that someone is qualified.

Suggestions explain their assumptions and unresolved conflicts. An authorized person confirms changes. The scheduler does not silently move established appointments, promise customers a time, or treat a proposal as booked work. Approved estimates can feed a scheduling queue, while urgent direct jobs remain possible.

Improvement from history means explainable calculations from comparable confirmed records, not hidden AI, surveillance, or unexplained employee rankings. Insufficient or inconsistent history must remain visible. Existing proposed algorithms and sample thresholds are proposals, not owner-approved facts or guarantees.

## 10. Expenses, receipts, and Data Saver

Expenses records spending with relevant vendor, date, category, amount, payment context, attachments, and optional job or vehicle links. Review and reimbursement permissions may differ from recording permissions. Recurring obligations distinguish what is due from what was actually paid.

Receipt intake supports manual entry and assisted extraction. Images and PDFs are evidence; extracted fields and lines are proposals until reviewed. Users must be able to correct quantities, packages, taxes, discounts, and allocations. A receipt covering multiple jobs must not be evenly divided by guesswork.

Data Saver concerns storage-efficient receipt evidence without destroying its usefulness. The inspected blueprint permits a smaller retained copy after a readable preview and rejects destructive compression as the only evidence. Exact retention, backup, compression settings, cost limits, and recovery policy still need review; they are not invented in this draft.

Receipt evidence, a confirmed Expense, purchase-cost knowledge, stock received, and job usage are related but different records. Confirmation must make its effects clear and must not leave half-applied financial or inventory changes after interruption.

## 11. Materials and inventory

Materials provides catalog and verified purchase-cost knowledge. Optional stock tracking adds quantities, locations such as a truck or warehouse, counts, transfers, adjustments, reservations, and usage. A business should not have to maintain perfect stock counts merely to look up prior costs.

Unmaintained quantities must not appear certain. Purchased packages, individual contents, available stock, reserved stock, and actual use need distinct meanings. Returns and corrections retain history rather than erasing the original purchase.

Parsing must cover the required languages and both measurement systems, including mixed-language input and ambiguous quantities. Existing plumbing, electrical, and HVAC specialization is reusable capability, not the definition of every user. Parser implementation is assigned elsewhere; this task does not authorize parser changes.

## 12. Trips, mileage, maintenance, and repairs

GPS-assisted trip tracking supports business travel and recordkeeping. Trips connect vehicle, employee, time, distance, and supporting evidence. Physical odometer readings and inferred GPS distance must remain distinguishable. Fuel purchases and other travel expenses link to the appropriate vehicle or trip while remaining Expense-owned records. Consent, private activity, offline capture, corrections, and confirmation need explicit behavior.

Maintenance manages asset service needs and completed service history, including vehicles and other applicable equipment. Triggers may involve dates, mileage, or runtime. A forecast is not a completed service record. Repairs retain their own problem, work, parts, and completion history, linked to expenses and inventory rather than owning duplicate financial or stock records.

## 13. Shared documents, reports, and languages

A shared document platform supports generating, rendering, viewing, and exporting PDFs for quotes, estimates, and invoices, plus reading receipt and other imported evidence. Common storage and permissions do not mean receipt extraction and customer-document generation are the same workflow. Historical PDFs must correspond to the correct record revision and template.

Reports and recaps explain authorized recorded activity and totals with access to supporting records. They must not silently repair or finalize records merely because a report was opened. Recordkeeping supports tax preparation and substantiation, without claims of IRS approval or guaranteed audit readiness. Legal and tax obligations need qualified review; this draft is not compliance certification.

The entire app is intended to support English, U.S. Spanish, and Canadian French, and both U.S. and Metric measurements. This includes forms, actions, errors, calendars, documents, reports, receipts, and parsing. Language and measurement preferences are independent. Original evidence and quantities are preserved; switching display units must not alter purchase truth, currency, or permissions. Existing localization scaffolding is not complete multilingual implementation.

## 14. Responsive design and personality

Desktop and tablet layouts must organize work purposefully, not stretch or distribute a phone screen into arbitrary columns. Narrow layouts still need useful information, not only navigation icons. Individual reading and form areas stay usable without capping the whole workspace so narrowly that available space serves no purpose. A fixed column count is not proof of good design.

Shared layout rules use actual available logical constraints after navigation and system text scaling. Required content reflows instead of disappearing. Labels stay understandable, words remain intact when possible, and primary names, amounts, states, and controls do not rely on truncation. Secondary screens have visible Back controls and appropriate platform back behavior.

The recent Work layout was rejected. Its documented dimensions and composition must not be taught as approved design. Supplied visual references establish preferences, not approval of every label, route, or duplicated control visible in them. Exact breakpoints and header composition remain subject to rendered review.

Optional humor and sarcasm levels are desired, beginning with mild dad-joke-style content without profanity. The owner's broadcast-television comparison describes an intended tone ceiling; it is not an established legal compliance standard for the app. Exact levels, localization, and where humor is inappropriate remain to be defined. A neutral experience must remain available.

## 15. Dependability, reuse, and validation

Durable storage, permission enforcement, stable identities, recoverable revisions, and cross-module consistency are foundations, not cosmetic follow-ups. Authorization applies to navigation, queries, counts, routes, actions, export, and sync. Hidden widgets alone do not protect data. Interrupted saves, repeated taps, retries, stale permissions, offline use, and concurrent changes require defined behavior.

Before substantial subsystem work, inspect relevant 5.7 capabilities read-only, classify reuse or repair opportunities, and report unverified risks. Existing code, invested effort, and passing tests do not alone prove suitability. Approved copying uses a bounded working context; the protected original and preservation backup are not disposable extraction targets.

Build order follows dependencies. For example, real material availability and purchase history are needed to validate integrated estimating; real document infrastructure is needed to validate customer PDFs. Layout demonstrations can be reviewed separately but cannot establish business-workflow correctness.

The owner plans private, connected, real-device company rehearsals: ordinary installation, owner signup, employee invitations, separate accounts, and normal business workflows across computers and phones. Builder regression testing is supplemented by independent validation against requirements, not merely repetition of builder assertions. Compiling, static analysis, automated checks, device launch, and owner acceptance are separate evidence levels.

## 16. Open boundaries and reconciliation register

- This draft is intended to underpin a detailed Custom GPT reference, not magically confer expertise or complete knowledge. Page-level specifications and open questions require further reconciliation before the package is complete.
- The existing narrow field-service introduction is superseded in this draft by the owner's business management and lightweight CRM definition.
- Quotes are required despite omissions in older module and lifecycle registers. Their full independent lifecycle is unresolved.
- The whole-app blueprint describes accepted-estimate job creation differently from Product Control, which explicitly requires a Create and plan job action. No automatic conversion assumption is approved here.
- Migration documents disagree about whether the replacement shell receives capabilities or a separate 5.7-derived integration lane receives the UI. That architectural decision must not be silently settled by uploading one account of it.
- Older line-count rules conflict with the current working contract. Current AGENTS.md requires production Dart files at or below 500 lines unless a safe-split constraint is documented; older 800/2,000-line allowances are not carried forward.
- Customer portal timing, document templates, stock reservation policy, payment-processing scope, notification channels, retention, and exact release gates remain to be reconciled.
- Payroll is outside the current release scope. A future discovery marketplace and possible commission model are long-term ideas, not implemented or first-release commitments.
- The Custom GPT should eventually receive a reviewed purpose/workflow/data/dependency/permission/state/layout specification for every module, plus a source index and explicit unknowns. It must not treat legacy labels or rejected prototypes as settled requirements.

## 17. Existing detailed source map

These are references for continued reconciliation, not blanket approval of all their contents:

- `maintainiac_app_blueprint.md`: whole-product ownership, reuse assessment, privacy, documents, and Data Saver.
- `product_control_blueprint.md`: authority, duplicate checks, permissions, lifecycle and acceptance register.
- `operations_screen_blueprint.md` and `technician_dashboard_blueprint.md`: screen/context detail; legacy and rejected layout passages require review.
- `work_lifecycle_blueprint.md`: commercial records, terms, signatures, job actuals, and customer portal.
- `calendar_system_blueprint.md`: shared dated projections and protection of actual history.
- `scheduling_system_blueprint.md`: opt-in assistance, feasibility, history, and explicit proposals.
- `receipt_material_intake_blueprint.md`: evidence, review, package quantities, allocation, and document-reader boundaries.
- `localization_measurement_blueprint.md`: whole-app languages, units, and incomplete implementation boundary.
- `notification_system_blueprint.md` and `accounting_integration_blueprint.md`: notification and later accounting seams; not yet fully reviewed for this replacement.
- `maintainiac_5_7_capability_migration_map.md`: discovery starting point, not current proof of production readiness.

No source code, existing blueprint, Custom GPT field, knowledge upload, or publication setting was changed by creating this review draft.
