# Proposed whole-app screen plan

Status: planning baseline for owner review, not an approved feature expansion or implementation claim. Prepared September 19, 2026. No production changes authorized in this phase.

Audience: small businesses generally; contractor-focused marketing must not force every business to use vehicles, technicians, inventory or on-site jobs.

This is a screen/surface register, not a demand for one separate page per row. Editors, detail views, pickers, dialogs and recovery states can share components where that improves usability. Every distinct route and state will get its own audit coverage entry after mapping. The initial code census has 91 screen-named files; that is not the finished route census.

## Priority meaning

- **E — Essential:** recommended baseline for the capabilities already requested. Modules may be hidden when irrelevant; essential integrity/recovery safeguards cannot be optional.
- **C — Conditional essential:** required if the corresponding capability is offered, such as teams or vehicles. Do not ship a partial version disguised as finished.
- **R — Recommended:** practical improvements to evaluate after core complete workflows.
- **F — Future ceiling:** ambitious but bounded candidates, not release commitments or an assertion of the best possible product.
- **H — Hold:** depends on integrations or unresolved scope; benchmark it without implementing it.
- **X — Excluded:** outside this assignment.

## Evidence and authority

Owning sources: maintainiac_app_blueprint.md (general small-business scope), product_control_blueprint.md (screen/action and permission contracts), operations_screen_blueprint.md, work_lifecycle_blueprint.md, receipt_material_intake_blueprint.md, data_storage_sync_contract.md, ui_foundation_blueprint.md, and latest owner directions in this task. Existing September 14 readiness findings must be revalidated.

Current owner direction excludes payroll/withholding and new integrations. Older cloud sync/backup and portal requirements are marked hold where they conflict; this planning document does not silently rewrite them or disconnect existing Firebase configuration.

Dependable recordkeeping means evidence retention, exact values, historical changes, business-purpose fields, recoverability and traceable exports. These are engineering objectives, not a determination of IRS compliance. Avoiding an advertising phrase does not itself establish which legal obligations apply; that question has not been assessed here.

## Proposed register

| ID | Tier | Area | Screen / surface | Required purpose or boundary |
|---|---|---|---|---|
| SC-001 | E | Foundation | First-run setup | Business name, locale, currency, optional industry; ordinary local use without compulsory cloud account |
| SC-002 | E | Foundation | Business profile | Contact details, branding, document defaults; no invented business facts |
| SC-003 | E | Foundation | Workspace and module preferences | Select useful modules; vehicles and field-worker terminology must not be prerequisites |
| SC-004 | E | Foundation | Home / business overview | Useful actions, outstanding work and record-backed totals; solo-owner experience |
| SC-005 | E | Foundation | Navigation and global search | Find records across dates and modules; permissions apply before results and counts |
| SC-006 | E | Foundation | Needs attention | Actionable issues linked to exact records; distinguish urgency from notifications |
| SC-007 | E | Foundation | Notification history and preferences | Read, dismiss, resolve and delivery states remain distinct |
| SC-008 | E | Foundation | Settings home | Consistent ownership of app, company, account and module settings |
| SC-009 | E | Foundation | Language, region and accessibility | English, Spanish and French scope; local dates, numbers, units, text scale and keyboard access |
| SC-010 | E | Foundation | Help and recovery guidance | Explain failed actions, recovery choices, app version and privacy-safe diagnostics |
| SC-011 | E | Records | Customer directory | Search, sort, filters, duplicate warnings and archived records |
| SC-012 | E | Records | Customer add/edit | Solo person or organization, contacts, notes and useful validation |
| SC-013 | E | Records | Customer details/history | Linked work, documents, balances and receipts without copying records |
| SC-014 | E | Records | Customer sites / service addresses | Multiple sites when relevant; avoid requiring a service site for every business |
| SC-015 | E | Work | Work overview | Cross-date outstanding work and clear distinctions among document types |
| SC-016 | E | Work | Estimates directory | Draft, awaiting response, accepted and closed states; discoverability independent of calendar |
| SC-017 | E | Work | Estimate editor | Line items, quantities, units, prices, notes and revision-aware autosave |
| SC-018 | E | Work | Estimate detail and revision history | Status, customer response, source links and explicit conversion |
| SC-019 | E | Work | Quotes directory and editor | Explicit quote semantics and durable lifecycle; may share components with estimates |
| SC-020 | E | Work | Document line-item selection | Manual, reusable service or inventory lines; cost distinct from selling price |
| SC-021 | E | Work | Document preview and export | Customer copy matches issued version; PDF save and operating-system share outcomes |
| SC-022 | E | Work | Document delivery / acceptance record | Manual status and evidence supported without a hosted portal; revised content invalidates stale acceptance |
| SC-023 | E | Work | Jobs / projects directory | Searchable planned, active, completed and cancelled work, with original relationships |
| SC-024 | E | Work | Job editor / assignment | Customer, dates, duration, people and applicable location; no compulsory vehicle |
| SC-025 | E | Work | Job detail / execution | Notes, status, attachments, expenses, materials and actual time |
| SC-026 | E | Work | Job completion / billing handoff | Completion separate from invoicing; preserve incomplete and return-visit work |
| SC-027 | E | Work | Calendar / schedule | Month, week and day views; exact owning records and conflict visibility |
| SC-028 | E | Work | Schedule change / conflict review | Explain clashes and effects before changing assignments or dates |
| SC-029 | E | Work | Invoices directory | Draft, unpaid, overdue, partly paid, paid and voided states |
| SC-030 | E | Work | Invoice editor / issuance | Direct or job-linked invoices, due dates, explicit finalization and historical snapshot |
| SC-031 | E | Work | Invoice detail / payment history | Reconciled amount due, correction/void trail and linked records |
| SC-032 | E | Work | Record payment / allocation | Record money received externally; exact amounts, partial payments, duplicates and reversals |
| SC-033 | E | Work | Payment history / detail | Trace receipt and allocation of money without pretending to process payments |
| SC-034 | E | Expenses | Expense overview / directory | Cross-date search, categories, receipt status and exact totals |
| SC-035 | E | Expenses | Expense add/edit/detail | Manual entry always usable; supplier, date, amount, business purpose, evidence and corrections |
| SC-036 | E | Expenses | Expense category picker / management | Aliases and related terms across all 21 trades plus general business expenses; custom categories |
| SC-037 | E | Expenses | Receipt source selection | Camera, photo/file import and manual entry; permissions, cancellation and supported formats |
| SC-038 | E | Expenses | Receipt capture | Readable framing and retake; preserve source until durable acceptance |
| SC-039 | E | Expenses | Receipt evidence preview / editing | Zoom, rotate, reorder, replace, remove and explicit original/derived-image distinction |
| SC-040 | E | Expenses | Long-receipt capture / alignment | Ordered overlapping photos, missing/duplicate section warnings and reviewable result |
| SC-041 | E | Expenses | OCR progress / result review | Editable proposed text and fields, uncertainty, source links and manual fallback |
| SC-042 | E | Expenses | Receipt line review | Quantity, package unit, unit cost, discounts and returns; unresolved values never invented |
| SC-043 | E | Expenses | Receipt destination / allocation review | Expense, job/material cost and optional stock effects; avoid duplicate financial records |
| SC-044 | E | Expenses | Receipt drafts / interrupted intake recovery | Resume, inspect failure and safely retry without duplicate expense or stock |
| SC-045 | E | Expenses | Evidence viewer | Reopen retained originals from expenses and linked work; useful missing-file recovery |
| SC-046 | E | Expenses | Expense correction / removed-record recovery | Explicit retention and restoration policy; historical business records protected |
| SC-047 | C | Expenses | Recurring expense setup / occurrence review | When enabled, distinguish planned obligations from actual paid expenses |
| SC-048 | E | Inventory | Inventory home / category browser | User-owned categories and subcategories; grid and compact multicolumn list |
| SC-049 | E | Inventory | Inventory search / filters | Search user-created items and aliases without a preloaded catalog |
| SC-050 | E | Inventory | Item add/edit/detail | Name, unit, category, optional identifiers, notes and purchase-cost history |
| SC-051 | E | Inventory | Locations directory / editor | Company stock, custom places and vehicles backed by actual profiles |
| SC-052 | E | Inventory | Stock add/use/count/transfer | Quantity, location, explicit operation and atomic history; no compulsory per-item scanning |
| SC-053 | E | Inventory | Stock history / correction | Who changed what, when and why; reversals preserve the trail |
| SC-054 | E | Inventory | CSV / spreadsheet import source and mapping | File/sheet/header selection, suggested mappings, units and locale handling |
| SC-055 | E | Inventory | Import preview / duplicate review | Row errors, ambiguous matches, new versus updated items and resulting quantities before commit |
| SC-056 | E | Inventory | Import result / recovery | Durable receipt of applied changes, rejected-row report and safe retry/undo policy |
| SC-057 | E | Inventory | Purchase-price history | Supplier/date/quantity/unit/cost; do not overwrite old quotes or invoices |
| SC-058 | C | Inventory | Low stock / replenishment list | User-enabled thresholds; unknown usage not falsely treated as exact stock |
| SC-059 | C | People | Employee / helper directory and editor | Required before multi-user operation; active/archive states and historical identities |
| SC-060 | C | People | Permissions / scope review | Required before multi-user operation; real authority, revocation, own/team/company access |
| SC-061 | C | People | Office / dispatch / worker views | Authorized views of shared records, not separate copies or role-name-only access |
| SC-062 | C | Time | Workday start / active / finish | For businesses using time or field tracking; handle interruption, pauses and midnight |
| SC-063 | C | Time | Time entries / correction approval | Actual duration and labor costs where used; expressly not payroll processing |
| SC-064 | C | Vehicles | Vehicle / equipment directory and profiles | Optional module; real identifiers and availability instead of assumed default operational facts |
| SC-065 | C | Vehicles | Trips / mileage entry and review | Business-use records, manual correction, unknown distance and odometer handling |
| SC-066 | C | Vehicles | Maintenance / repair list, editor and detail | Owned assets, due rules, service history, costs and evidence |
| SC-067 | E | Reports | Business reports / date selection | Cash received, spending, receivables and job costs with explicit definitions |
| SC-068 | E | Reports | Report source drill-down | Every total traceable to permission-allowed records and date boundaries |
| SC-069 | E | Reports | Records export / export preview | Human-readable and structured exports, attachment references and completeness checks |
| SC-070 | E | Recovery | Saved drafts / unsaved changes | Resume pending edits and explain autosave versus final business save |
| SC-071 | E | Recovery | Backup creation / verification | Local portable backup of records and evidence with integrity verification |
| SC-072 | E | Recovery | Restore selection / preview / progress / result | Compatibility, missing evidence, recoverable failure and existing-data protection |
| SC-073 | E | Recovery | Storage health / recovery | Disk-full, corrupt/unavailable storage, interrupted migration and retained last-good data |
| SC-074 | E | Recovery | Record activity / change history | Authorized historical trail of consequential changes |
| SC-075 | E | Recovery | Error / denied / unavailable states | Route-level and action-level failures, offline behavior and useful next steps |
| SC-076 | R | Work | Reusable services / common-job templates | Speed entry with editable labor and materials; never confuse estimate with actual usage |
| SC-077 | R | Work | Repeat jobs / appointment series | Exceptions, rescheduling and cancelled occurrences handled explicitly |
| SC-078 | R | Records | Supplier directory and purchase history | Useful vendor lookup and cost comparison; avoid requiring duplicate entry |
| SC-079 | R | Records | Customer merge review | Explicit conflict resolution and preserved related records |
| SC-080 | R | Inventory | Saved import profiles | Reuse a supplier or user's column mappings without bypassing preview |
| SC-081 | R | Inventory | Reorder worksheet / purchase order documents | Local planning and export, no supplier API dependency |
| SC-082 | R | Work | Tasks / checklists / reusable forms | Configurable for different businesses rather than trade-hardcoded forms |
| SC-083 | R | Reports | Receivables aging and follow-up workspace | Local reminders and manual contact records; no automatic message service required |
| SC-084 | R | Reports | Profitability and labor-cost review | Explain included costs, missing data and labor-hour basis; no payroll calculations |
| SC-085 | R | Foundation | Keyboard / bulk-action workflows | Selection, preview and undo where safe; responsive to desktop productivity |
| SC-086 | R | Foundation | Saved searches / favorites | Reduce repeated navigation without hiding authoritative records |
| SC-087 | R | Recovery | Duplicate and reconciliation center | Review competing records/imports with evidence; never silent ambiguous merges |
| SC-088 | R | Recovery | Local diagnostics export | Explicit review and redaction of customer data before sharing |
| SC-089 | F | Inventory | Optional barcode / QR labels | User demand first; distinguish item, package, bin and location |
| SC-090 | F | Inventory | Verified catalog pack browser / manager | Deferred; optional packs, provenance, integrity and independent validation |
| SC-091 | F | Work | Advanced dispatch / capacity planning | Crew skills, availability, workload and explainable recommendations |
| SC-092 | F | Work | Service agreements / recurring-work plans | Operational schedule and documents only; legal drafting and billing integrations excluded |
| SC-093 | F | Reports | Custom report builder | Reconciled measures and permission filtering; no general-ledger accounting promise |
| SC-094 | F | Foundation | Configurable business workspaces | Different terminology and enabled modules without separate fragile app forks |
| SC-095 | F | Records | Extended asset / serial / warranty records | Only for businesses with verified demand; retain documentary evidence |
| SC-096 | F | Recovery | Advanced retention / review controls | Policy-driven archive and evidence exports after requirements are reviewed |
| SC-097 | H | Cloud | Account / connected services settings | Existing Firebase presence recorded; no new integrations in this assignment |
| SC-098 | H | Cloud | Cloud sync status / conflict resolution | Historical blueprint requirement conflicts with current no-integration scope; deferred decision, not silently removed |
| SC-099 | H | Cloud | Hosted customer portal / approvals / booking | Requires connected service/security/operational commitments; benchmark only for now |
| SC-100 | H | Cloud | Automated external messages / payment collection | Provider dependencies and ongoing costs; out of current implementation scope |
| SC-101 | X | Excluded | Payroll and payroll tax withholding | No wage disbursement, withholding, payroll filings or payroll compliance service |
| SC-102 | X | Excluded | Tax filing / tax advice / IRS certification | No filing engine or audit-ready guarantee; recordkeeping quality remains important |
| SC-103 | X | Excluded | QuickBooks / banks / third-party accounting connectors | No integration implementation now |
| SC-104 | X | Excluded | Legal or accounting professional services | No legal drafting, compliance certification or professional representation |

## Audit procedure after this list

1. Map every entry to actual routes/widgets, owning blueprint and business-data services. Separate absent, placeholder, partially wired and verified capabilities.
2. Expand existing route inventory to cover shared homes, dialogs, sheets, permission variants, and empty/loading/error/recovery states. Record unreachable or blocked paths.
3. Record an explicit supported logical-width range per target; capture at 100-LP intervals plus exact breakpoints and adjacent widths. Desktop screenshots do not establish native phone correctness. No claim of all widths until min/max are defined and exercised.
4. Inspect each capture for density, readable type, full labels, bounded lanes, grid/list behavior, overflow, scroll reachability, keyboard/focus and enlarged text. Screenshot collection alone is not acceptance.
5. Exercise connected workflows on disposable data: save/restart/reopen, duplicate retries, denied access, interrupted import, failed restore and linked-record consistency. No destructive tests against real customer data or live shared services.
6. Compare current official competitor documentation with demonstrated app behavior. Rank each recommendation by user benefit, complexity, recurring cost, maintainability and evidence confidence. Feature count does not imply parity.
7. Produce a prioritized defect/recommendation register and an explicit unfinished-coverage list. Keep implementation paused until separately authorized.

## Competitive reference starting points

- [Housecall Pro features](https://www.housecallpro.com/features/)
- [Housecall Pro navigation documentation](https://help.housecallpro.com/en/articles/6934643-navigating-housecall-pro)
- [Jobber client hub documentation](https://help.getjobber.com/en/articles/client-hub-settings/)
- [Jobber automations documentation](https://help.getjobber.com/en/articles/automations/)

These establish documented capabilities, not hands-on competitor validation. Service Pro is ambiguous across vendors; its exact identity remains unconfirmed. No paid subscriptions or accounts were created.
