# Engineering, adaptive UX, local-first data, and operational health

This file supplies engineering recommendations for developing the new blueprint. Owner-confirmed direction: local-first, Firebase/storage/sync coverage, app-health admin application, dependable records, accessibility, shared layout consistency, meaningful mobile/wide layouts, and independent verification. Specific services and implementations below are candidates, not claims of existing integrations or approved purchases. Use current official technical documentation before implementation; capabilities, quotas, platform support, and pricing can change.

## Local-first is a behavior contract

Core work should remain usable without a network. Define what each Save means: committed locally, queued for sync, accepted remotely, attachment uploaded, and independently backed up are different states. Tell the user the truth without forcing them to understand infrastructure terminology. A network spinner must not masquerade as durable persistence.

Put authoritative business mutations behind module services rather than inside widgets. Use stable organization/record IDs, typed amounts and units, revisions, provenance, and audit evidence where needed. Shared services should let modules communicate without directly modifying each other's private storage. One operation producing an expense, stock movement, and job allocation needs a coherent transaction or recoverable multi-step protocol with deduplication—not three independent optimistic success messages.

Choose local storage through a documented decision: supported platforms, transactions, durability, encryption/key lifecycle, migrations, indexing, attachments, recovery, maintenance, and testability. Historical references to Hive, JSON stores, or another library do not settle the new architecture. Do not conflate checksums with encryption. Do not store normal business data in a source checkout. Determine appropriate app-private locations and export paths separately.

Plan for disk-full, interrupted writes, corrupt records, failed migrations, multiple local writers, and missing attachments. Never silently replace lost data with demo records. Preserve a recoverable previous state where feasible; define when user intervention is needed. Test restore, not just backup creation.

## Firebase: roles to evaluate explicitly

Firebase is part of the owner's requested architectural discussion, not proof every Firebase product is necessary. Evaluate Authentication for identity; Firestore or another selected database for remote structured records; Cloud Storage for attachments; Cloud Functions or an appropriate server for trusted operations; Cloud Messaging for supported push delivery; Crashlytics for crash diagnostics; Performance Monitoring for supported performance evidence; App Check as an abuse-defense layer; Remote Config for carefully governed rollout settings; Hosting where an admin frontend needs it. Verify exact platform support and costs before choosing any service.

Do not automatically enable Analytics or collect behavior because it is available. Consent, data minimization, retention, and customer expectations determine telemetry. App Check is not user authorization. Authentication is not organization membership or permission. Database security rules do not replace business validation, and server/admin SDK access requires its own enforcement because privileged code may bypass client rules.

Keep development, testing, and production separated. Define configuration ownership, deployment permissions, rules/index testing, secret management, billing budgets/alerts, regional data placement, backups, retention, and recovery. Do not create paid resources, expose service accounts, or broaden access under a vague implementation task. Never package secrets in Custom GPT knowledge, logs, screenshots, source, or client builds.

## Synchronization contract

Separate local durability, cross-device synchronization, and backup. Mirroring a deletion to every device is not a recoverable backup. Offline SDK caching alone does not prove every workflow is local-first.

Recommended design concerns: durable outbox; stable operation ID; idempotent application; retry/backoff; remote acknowledgement; per-record version; conflict handling; attachment upload state; tombstones/deletion policy; ordering across dependent records; resuming after app termination; and bounded queues. A timeout means uncertain delivery, not necessarily failure; retry must not create a second invoice or payment.

Decide authority by record and action. Field-level merge may suit some notes, while concurrent financial corrections need explicit review or stronger serialization. Last-write-wins is not a universal policy. Preserve the conflicting inputs and present a comprehensible resolution. Do not let device clock skew decide financial truth. Distinguish event time, effective business date, creation time, and server receipt time.

Offline authorization requires a policy: which actions remain allowed, for how long, with what cached scope, and what happens if membership is revoked before reconnection. Revalidate queued operations. Show rejected/conflicting sync without losing the user's recoverable work or disclosing newly restricted data. Test two devices editing the same record, revocation, duplicate delivery, reordered messages, deleted parent records, failed attachments, sign-out, and tenant switching.

## Privacy and permissions across all paths

Define actions and scope, not just role names. Enforce authorization at queries, totals/counts, routes/deep links, mutations, document generation, exports, notifications, sync, and administrative access. Hiding a button does not protect its data or endpoint.

Separate employee private information, business records, personal trips, customer contact data, and diagnostic telemetry. Apply least privilege. Decide audit retention, who may correct/delete/export, and what terminated users/devices retain. Financial and personal data require explicit threat modeling and independent review before production claims. Security is a release responsibility, not something added after layouts are finished.

## Admin app and privacy-safe bug diagnosis

The owner wants to see app health and bugs and identify the device context needed to fix them. Recommended admin surfaces: health overview; issues list; issue detail; release/version comparison; sync failure overview; feedback intake; alert settings; and restricted administrative audit. These are proposed screens, not owner-approved layouts.

A useful diagnostic event can include random event ID, timestamp/time zone, app version/build, platform/OS version, device model, exception type, sanitized stack trace, affected module/operation, foreground/background state, relevant connectivity state, local schema version, correlation ID, and a bounded sanitized breadcrumb trail. Collect only justified fields. Avoid raw customer names, addresses, receipts, invoice contents, precise GPS coordinates, access tokens, full database dumps, and stable hardware identifiers by default. Redact before transmission, not only when rendering the admin page.

Permit voluntary user reports with reproduction steps and an explicit preview/consent flow for diagnostic attachments. Screenshots, recordings, or database exports must not be automatically included. Distinguish crash, handled error, performance problem, sync conflict, and user confusion; they require different responses. Offline events need bounded storage and retry without filling the device.

Issue management should group repeated failures, show affected versions/device classes and frequency, track triage/reproduction/fix/verification status, and retain evidence links. A crash-free metric needs a defined denominator and telemetry coverage; missing telemetry is not proof of health. A reported fix needs regression evidence and post-release observation before closure.

Alerts need severity, rate limiting, deduplication, recipients, escalation, and resolution behavior. Avoid sending every repeated event as a separate alarm. Define retention and deletion for telemetry and who can access it. Operator access should be separately authenticated and audited, preferably with strong authentication; support access to business records is not implied. Do not build remote arbitrary code execution into a diagnostic feature. Feature flags and rollbacks require authorization, audit, safe defaults, and tested recovery.

Codex bug handoff should contain sanitized reproduction steps, expected/actual result, affected versions, device context, stack/error signature, relevant timestamps/correlation IDs, recent change context, and evidence gaps. It must not require posting private customer records into an AI conversation. Diagnostics are clues, not automatic proof of root cause.

## Shared adaptive layout and accessibility

Design the task for available space, not a device category. Use local logical constraints after navigation, safe areas, and panels, plus text scaling and content requirements. A widescreen window can be narrow; a phone in an external desktop mode can provide a larger app surface. Mirroring alone does not imply a new layout viewport. Verify behavior rather than promising it.

Define shared layout/spacing/type/control primitives and consistent navigation. Do not implement isolated per-screen breakpoint systems. The new blueprint must decide appropriate lane bounds and transitions; inherited prototype numbers are not sacred. Wide layouts should use relationships such as record list plus selected detail or form plus contextual preview where justified. Narrow layouts should preserve the full task through intentional sequencing, not hide essential data. Useful density is not crowding.

For each screen, specify information/action priority, reading order, selection state, scroll ownership, keyboard/focus behavior, and how secondary context moves as space changes. Test intermediate widths, portrait/landscape changes, resizing during editing, keyboard-open layouts, large text, long translations, long names and money amounts. Preserve drafts, selection, and navigation during reflow.

Preserve system text scaling. Essential labels, amounts, dates, names, and states should remain available rather than clipped or ellipsized. Provide semantic labels, logical focus, visible focus indication, keyboard operation, meaningful error association, adequate contrast, non-color status cues, and suitable touch targets. Exact numeric standards require current platform/accessibility references and rendered verification, not guesses. Generated mockups illustrate options but do not verify responsive or accessible implementation.

## Language, quantities, time, and money

The owner requires multilingual coverage and both measurement systems, including parsing. Inventory, expenses, errors, notifications, PDFs, admin/user-facing diagnostic explanations, and onboarding must be considered—not only translated menu labels. Regional variants are mandatory, not optional polish. Recommend launch locales and fallback policy; the owner must not be expected to supply linguistic expertise. Plan fluent regional review and test localized parsing as well as display. Language, currency, measurement, and time zone are independent choices.

Preserve original evidence and source units. Explicitly distinguish U.S. customary from imperial quantities where they differ. Do not silently convert currency with language. Store quantities and conversion provenance appropriately; round at explicit boundaries. Use safe monetary representations and declared tax/discount/rounding rules. Parsing mixed-language receipts requires review of ambiguity, decimal separators, unit abbreviations, package sizes, and dates. Display conversion must not mutate purchase truth.

## Verification and release discipline

Maintain a matrix connecting each requirement to normal flow, edge/failure flow, permission scope, local persistence, sync, accessibility, language, and device/runtime evidence. Unit tests, integration tests, end-to-end workflows, physical-device checks, and owner review cover different risks. Independent reviewers should challenge assumptions and missing requirements rather than repeat the builder's assertions.

Required investigations include restart after acknowledged save; interruption mid-save; duplicate taps/retries; corrupt storage; backup restoration; migration rollback; revoked access; cross-organization isolation; incorrect document revision; sync conflict; unreadable receipt; notification cancellation; past-day record preservation; maintenance threshold correction; and rescheduling without altering actual work.

Assess release readiness with known defects, residual risks, support/recovery procedures, privacy disclosures, crash/sync monitoring, update compatibility, and rollback strategy. No green test count proves the app is complete or safe for financial records. Never claim professional certification, security guarantees, or production readiness without appropriate evidence.
