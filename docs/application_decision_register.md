# Application decision register

Updated 2026-09-09. Entry point: [canonical application map](README.md).
Evidence below is from the owner messages in the existing UI Lab task and the
owner-supplied working contract. Historical AI documents are not acceptance.

## Status rules

- **ACCEPTED/CANONICAL:** explicit owner decision or current working constraint;
  record the evidence and owning section. Does not imply implemented.
- **IMPLEMENTED/VERIFIED:** bounded implementation evidence with source revision,
  checks and result, environment, date and limitations. Independent of product
  acceptance. Code presence alone does not qualify as runtime verification.
- **PLANNED:** engineering proposal or inherited documented requirement without
  sufficient acceptance evidence. Preserve it for review; do not silently ship.
- **DEFERRED:** outside a specified pass/release according to identified evidence.
  A temporary deferral does not remove a required application module.
- **UNRESOLVED:** needs a product choice or evidence to settle competing claims.

Superseded wording is recorded in the conflict log, not left as another active
rule. New entries require ID, status, evidence, owning section, affected systems,
verification obligation and open choices. Never promote by repetition.

## Owner decisions and constraints

Latest decisions are detailed in `current_product_blueprint.md` and
`data_storage_sync_contract.md`. They supersede conflicting historical rows.

| ID | Status | Decision / owner evidence | Owning contract / verification |
| --- | --- | --- | --- |
| D39 | ACCEPTED/CANONICAL | September 14: independent receipt generator must be a separate native Flutter Android/iOS app; delete the web generator. Business receipts only; rebuild Expense presentation. PDF work belongs to the other model | Receipt/material intake and Expense/inventory roadmap; native generator is separate from all target catalog/parser logic; no launch in replacement pass |
| D38 | ACCEPTED/CANONICAL | September 14: transfer 5.7 inventory and parsing to UI Lab with SQLite; ship electrical, plumbing and HVAC core packages; improve mobile workflow without treating passing tests as acceptance | Receipt/material intake §12 and inventory extraction checkpoint; 5.7 stays read-only, cloud setup deferred in this slice, complete ledger/parser/UI integration still pending |
| D37 | ACCEPTED/CANONICAL | September 13 Dashboard-only execution: mobile Admin/Technician, distinct Company Overview, horizontal scope, bounded safe-width calendar and selected navigation clarity | Technician Dashboard September 13 contract; development permissions and incomplete cost/feed coverage remain explicit; visual acceptance pending |
| D30 | ACCEPTED/CANONICAL | Owner: “2.1 is the new production app”; replacement destination selected, not readiness certified | Current blueprint §1; migration gates retain 5.7 protection |
| D31 | ACCEPTED/CANONICAL | Owner selects SQLite with Drift; preserve/convert valuable Hive inventory and test throughout | Storage contract and database handoff; no implementation implied |
| D32 | ACCEPTED/CANONICAL | Release one MUST offer local only, sync without backup, sync with backup; user controls how/when; onboarding/settings choice, UI not current scope | Storage contract; independent sync and restore evidence |
| D33 | ACCEPTED/CANONICAL | No account for local-only operation EXCEPT downloading an inventory trade pack requires an account | Storage/identity; post-download entitlement and cloud identity unresolved |
| D34 | ACCEPTED/CANONICAL | Brand-new isolated Firebase project; owner requests separate billing; no guarantee of credits | Storage contract; CLI installed, project/auth/deployment unfinished |
| D35 | ACCEPTED/CANONICAL | Fixed realistic Aug 31–Sep 13 demo story, related records and usable edit/removal workflows | Current blueprint §4; deletion policy and proposed list layout unresolved |
| D36 | ACCEPTED/CANONICAL | Visible sidebar tasks, full contextual handoffs, no hidden substitute; never replace normal app with preview | Current blueprint §§6,8; no new sidebar task created here |

| ID | Status | Decision / identifying owner evidence | Owning contract / verification obligation |
| --- | --- | --- | --- |
| D01 | ACCEPTED/CANONICAL | “business management system and lightweight CRM”; “multiple apps under one roof”; apps “talk to each other” | Whole app §§1,5; connected workflows, no duplicated ledgers |
| D02 | ACCEPTED/CANONICAL | Business owners broadly; tradespeople important, not exclusive; remove gig-driver product framing but retain useful driving systems | Whole app §1; scope review of navigation, data defaults and GPT exports |
| D03 | ACCEPTED/CANONICAL | “users' safety”, dependability, accuracy ahead of release speed | Whole app §1; failure/recovery and independent accuracy evidence |
| D04 | ACCEPTED/CANONICAL | January 2027 preferred, prepared for mid-2027; extra months preferable to preventable defects | Release intent, not feasibility estimate or promised date; release gates remain evidence-based |
| D05 | ACCEPTED/CANONICAL | Current explicit decisions override AI-authored 5.7 documentation; passing legacy tests does not prove correct implementation | Whole app §2 and migration map; independent requirements/test assessment |
| D06 | ACCEPTED/CANONICAL | Shared app-wide layout engine, no stretched phone or mechanical distribution into columns, non-minimalist self-explanatory UI | UI foundation; local post-navigation logical width and TextScaler, stateful resize and a11y QA |
| D07 | ACCEPTED/CANONICAL | Current working contract preserves scaling, primary text, semantic colors, Dashboard 320-LP action behavior and 400-LP Month lane | UI foundation; no global scaling clamp, no primary ellipsis, no private breakpoint system |
| D08 | ACCEPTED/CANONICAL | Current pass preserves 500-line authored-file target and regression rules | Product control; cohesive boundaries, documented safe exceptions, generated output distinguished |
| D09 | ACCEPTED/CANONICAL | Calendar includes previous-day inspection/add/edit and scheduling; current contract protects actual entries from scheduler writes | Calendar; all-date historical integrity and exact source routes |
| D10 | ACCEPTED/CANONICAL | Scheduling “smart without being AI”; improves from prior jobs; uses estimates/availability and potentially employee fit | Scheduling; explainable proposals, confirmed commitments; formulas/defaults remain U05 |
| D11 | ACCEPTED/CANONICAL | Multilingual and regional variants “absolutely”; metric and U.S. measurements “including the parsing stuff” | Localization; full workflow coverage, original values retained; exact locale rollout U06 |
| D12 | ACCEPTED/CANONICAL | Quotes, Estimates, Invoices represent full applications; Jobs, Expenses, Inventory, trips and maintenance must not be omitted | Work and screen map; quote semantics U04, not synonym assumption |
| D13 | ACCEPTED/CANONICAL | Maintenance, repairs, intervals, reminders, vehicle miles; working contract includes equipment and materials par | Calendar/Operations; asset-appropriate triggers and record links, detailed policy U07 |
| D14 | ACCEPTED/CANONICAL | OCR, durable storage, Hive/database, inventory parsing and trade packs represent substantial investment to assess | Migration map; preserve evidence, inspect dependencies and tests independently |
| D15 | ACCEPTED/CANONICAL | Shared PDF generation and document reading; receipt camera/Data Saver settings; selected expense category shapes form | Receipt/Work; exact revision/evidence and contextual form QA |
| D16 | ACCEPTED/CANONICAL | Each top-level gear controls that page and related behavior, not unrelated global settings | Product control §2; meaningful page choices and permission boundaries |
| D17 | ACCEPTED/CANONICAL | Local-first, durable storage, Firebase/sync context required; latest owner requests explicit whole-app storage categories | Data/storage/sync; category mapping required, global cloud policy NOT thereby settled |
| D18 | ACCEPTED/CANONICAL | Working contract: no security by hidden widget; AI/OCR/GPS proposals until confirmed | Product control; navigation/query/count/route/action/export/sync enforcement |
| D19 | ACCEPTED/CANONICAL | Separate admin application for app health, bugs and useful device information | Data/storage/sync; minimal diagnostic schema and access policy U09 |
| D20 | ACCEPTED/CANONICAL | “not going to have anybody's account number in this app” in current scope | Data/storage/sync; no bank/account-number fields or accidental diagnostic capture |
| D21 | ACCEPTED/CANONICAL | Optional future AI helper; scheduling must work without it; opt-in situational sarcasm, not insults at user | Work AI section; model/cost/release and tone boundaries U10 |
| D22 | ACCEPTED/CANONICAL | Proactively identify omitted dependencies; ask genuine product choices; no kindergarten app introductions in existing-task prompts | README handoff; task delta, references, necessary constraints and acceptance evidence |
| D23 | ACCEPTED/CANONICAL | Initial consolidation and latest Sep 9 pass are documentation-only | Pass-specific scope, not a permanent ban on owner-assigned implementation |

## Planned and deferred scope

Latest owner decisions, after the initial consolidation:

| ID | Status | Decision / evidence | Owner and remaining boundary |
| --- | --- | --- | --- |
| D24 | ACCEPTED/CANONICAL | “not required to create an account”; app works offline; backend “for storage” | Data/storage/sync; no cloud dependency for ordinary operations; team/identity/recovery details U02 |
| D25 | ACCEPTED/CANONICAL | No vehicle-profile setup required; supply usable single vehicle, do not call it default; two vehicles need two profiles | Product control §7; visible name and initialization of real readings unresolved |
| D26 | ACCEPTED/CANONICAL, partially superseded | Earlier receipt-only commercial restriction superseded by D32 and later plan discussion; retain user-owned linked job-photo intent | Current blueprint §3; provider allocation/quotas unresolved |
| D27 | ACCEPTED/CANONICAL | Basic and Detailed receipts; Basic category optional, even general business-receipt selection not required; manual entry allowed | Receipt intake; detailed itemization, remaining mandatory header fields unresolved |
| D28 | ACCEPTED/CANONICAL | Original-quality image for optional extraction; approximately 1 MB, 750 KB, 500 KB, 250 KB with real preview before backup | Receipt intake; targets not readability guarantees; per-image/stitched scope and disposal timing unresolved |
| D29 | ACCEPTED/CANONICAL | Plain-English receipt assistance, no customer-facing OCR; reliable long-receipt stitching required | Receipt intake; naming open; 5.7 failure owner-reported, not reproduced here |

| ID | Status | Existing material to preserve without inventing approval | Owner / gate |
| --- | --- | --- | --- |
| P01 | PLANNED | Detailed role templates, grant grammar, estimate review, pricing/payment-plan rules | Product control and Work; validate actual owner approvals and U03/U04 |
| P02 | PLANNED | Document portal, QR, revision-bound signature/response and consent design | Work sharing section; current request requires mapping, not proof of release-one approval; U08 |
| P03 | PLANNED | Exact cloud adapters/authority remain to design; release-one backup/sync capability itself is ACCEPTED under D32 | Data/storage/sync; U02 governs policies, not whether release one includes cloud |
| P04 | PLANNED | Exact launch locales, first-run order and English fallback in existing localization document | Regional/multilingual requirement accepted; exact choices U06 |
| P05 | PLANNED | Concrete responsive thresholds and composition choices not explicitly owner-accepted | UI foundation; shared engine guardrails accepted, layout designs require evidence |
| F01 | DEFERRED | Maintenance implementation, onboarding implementation, broad migration, unrelated UI | Explicit current-pass exclusions only; modules remain in product map |
| F02 | DEFERRED | Accounting-provider integration and general employee/customer chat | Existing accounting/notification/Work documented plan, not newly verified owner approval; reopen only explicitly |

## Open decisions / evidence requests

| ID | Question not to decide silently | Affected owners / safe work before answer |
| --- | --- | --- |
| U01 | RESOLVED by D30: 2.1 is intended replacement production codebase, not yet production-ready | Migration map; protected 5.7, verify each integration |
| U02 | D31–D34 settle database, three modes, optional cloud in release one and pack-download account exception. Open: provider allocation, cloud identity, conflicts, media retention, quota/entitlements, backup-only mode, restore and deletion policy | Data/storage/sync; setup must be explicitly scoped; no production deployment here |
| U03 | Permission inheritance, temporary grants, explicit denials, field visibility, customer identity and offline revocation policy? | Product control; preserve minimum-scope checks, no invented grant defaults |
| U04 | Quote vs estimate lifecycle; direct invoice/payment routes; tax/rounding, deposit/credit/refund and document approval policies? | Work; inventory proposed flows without imposing a mandatory linear pipeline |
| U05 | Scheduler objectives, hours/breaks, emergency overrides, staff-fit/history formulas, recurrence/time-off policy and assistance defaults? | Scheduling §17; engine examples remain explicit test policies |
| U06 | Exact launch regional locales, fallback/translation review, document language, preference precedence and conversion/rounding policies? | Localization; do not downgrade mandatory regional support |
| U07 | Asset identity ownership, meter corrections, interval resets/combined thresholds, par defaults, negative stock and stock certainty? | Calendar/Operations; maintenance and par scope accepted, mechanics not guessed |
| U08 | Portal release timing, identity verification, link expiry/revocation, signature evidence, customer reminder channels/consent? | Work/Notifications; retain secure planned design without enabling delivery |
| U09 | Admin health data collection, opt-in/necessary diagnostics, redaction, device fields, operator access and retention? | Data/storage/sync; no unrestricted customer-record access for support |
| U10 | AI helper release scope/provider/model/budget and exact humor content policy? | Work; no paid calls or claim broadcast-law compliance from informal tone analogy |
| U11 | Full module release gates, supported OS/device floor and performance budgets? | Migration map/UI foundation; approximate 2017 device aspiration is not verified compatibility |

## Implementation evidence register

No runtime behavior was verified in this documentation-only pass. No production
capability is promoted to IMPLEMENTED/VERIFIED here. Existing dated checkpoints
remain historical assertions with their limitations, not new acceptance.

| Evidence location | Current classification | Required to promote/refresh |
| --- | --- | --- |
| UI foundation §15 | Historical implementation checkpoint; owner visual gaps listed | Revision, rendered width/scaling/locale matrix and owner acceptance |
| Expense cutover checkpoints | Historical source/test claims | Current dependency/read-write trace, targeted tests and restart/recovery evidence |
| Notification blueprint status | Historical foundation claims; device delivery explicitly incomplete | Exact publisher/adapter tests and physical-device delivery readback |
| Migration map §6.11 and §10 checkpoints | Historical source discovery / later slice claims | Current source fingerprint, independent expected behavior, target integration proof |
| AppLayoutEngine, AuthorizedExpenseService, AuthorizedNotificationService | Source declarations located this pass ONLY | Presence does not verify enforcement, durability or runtime correctness |

## Conflict and supersession log

- D30 now resolves U01 in favor of the 2.1 replacement. Earlier unresolved
  destination language is historical, not active authority. 5.7 stays protected.
- D02 closes the older open workshop about a gig-driver product mode. General
  business trip/mileage functionality remains; it is not that product mode.
- Calendar's “explicit schedule records” ownership wording is corrected: Work
  owns commitments; Calendar owns projections/presentation only.
- D17/U02 supersede blanket statements that cloud is always only backup or that
  cloud code can never participate in record authority. They do not mandate a
  cloud-authoritative category before the owner specifies it.
- D08 reconciles 500–800 guidance with this pass's explicit 500-line authored
  target. Cohesion and documented exceptions remain; no mechanical splitting.
- D07 overrides the older foundation text expanding Dashboard Month across
  the full workspace. Its supporting Month lane is bounded at 400 LP.
- D12 restores Quotes to Work ownership/coverage; a missing old row does not
  remove the capability. U04 retains its undecided semantics.
- The migration map's mandatory long-receipt rewrite is replaced with the owner's
  repair-or-rebuild assessment requirement; tests cannot choose that outcome.
- Declaring “Confirmed” without identifiable owner evidence no longer promotes
  inherited role, portal, locale, workflow or release rules automatically.
- D24 removes universal account/membership gates for local use; shared/cloud
  access still requires appropriate authority. D25 removes vehicle setup as an
  app-entry prerequisite, not identity separation for multiple vehicles.
- D26's receipt-only commercial restriction is superseded by later cloud-plan
  discussion and D32. Keep external job-photo intent, but provider allocation,
  billing/quotas and team-sync policy still require decisions. See current blueprint §3.
- D28 supersedes permanent-original-resolution requirements for receipt backups.
  Historical original-retaining implementations remain evidence, not a mandate;
  automatic source deletion is not authorized until its lifecycle is decided.
