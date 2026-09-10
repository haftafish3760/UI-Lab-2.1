# Codex handoff — durable SQLite/Drift foundation and Hive migration assessment

> Historical handoff. Start with [the September 10 continuation](codex_continuation_handoff_2026_09_10.md) and the current storage gate matrix; do not restart from this older status.

Prepared 2026-09-09 for a separate visible owner-controlled task.
Workspace: `/Volumes/AppleWork/UI-Lab-2.1`.
Protected source: `/Users/rbbie/Documents/Maintainiac_5.7_Active` (read-only).

## Read first; do not ask the owner to re-explain the application

Read AGENTS.md, `current_product_blueprint.md`, `application_decision_register.md`,
`data_storage_sync_contract.md`, `maintainiac_app_blueprint.md` §2,
`maintainiac_5_7_capability_migration_map.md` and relevant domain contracts.
Current owner decisions outrank stale AI documentation. Distinguish accepted,
proposed, implemented and verified. Preserve dirty work and current normal app.

## Confirmed destination and requirements

2.1 is the intended replacement production codebase, not yet production-ready.
Local database: SQLite with Drift. Release one includes local-only, sync without
backup, and sync with backup, selected by the user. Ordinary local operation is
account-free; downloading an inventory trade pack requires an account. Never
make local saves depend on Firebase availability. Cloud backup and sync are
distinct required release-one capabilities, not optional future engineering.
User controls how/when; onboarding/settings must eventually expose that choice,
but do not implement their UI during foundation work.

Firebase uses a NEW isolated project, not 5.7's backend. Project/billing/login
are not completed. CLI tooling exists; verify it. Do not deploy rules, register
apps, attach billing or use production credentials without explicit task scope.
Do not copy 5.7's Android/iOS config unchanged: 2.1 has different app IDs.

## First bounded assignment: assessment and migration plan

Do not run headfirst into converting the entire codebase. Inventory the existing
5.7 Hive adapters/type IDs/boxes, durable save/recovery logic, encryption/key
lifecycle, schema versions, parsers/trade packs, catalog identity, units, costs,
stock/par/location/history, Firebase coupling, all callers and the QA harness.
Inspect 2.1's file-based expense repositories and in-memory Work store too.
Explain what can be reused, adapted, replaced or is missing, with source paths.
Tests and legacy docs are evidence, not automatic proof of product correctness.

Deliver a schema/ownership and dependency map, exact migration boundaries,
identified unknowns, and phased test plan. Estimate effort from inspected coupling
and a separately approved representative migration trial, not unsupported days.
Do not modify the original 5.7 or actual owner records to test migration.

## Foundation implementation acceptance (when assigned)

- One database lifecycle/bootstrap; domain repositories and authorized commands,
  not database access inside widgets or a duplicate global mutable store.
- Stable primary/foreign keys; enforced constraints; exact quantities, money and
  currency/units; typed dates/times; revisioned financial/document history.
- Transactional cross-record changes and durable idempotent command identifiers.
  Preserve drafts, committed data and last-known-good state across interruptions.
- Explicit schema migration history, migration tests and recovery policy. Back up
  source input before migration; retain legacy data until independently reconciled.
- Durable sync outbox, replay/revision checks, visible failure/conflict states,
  remote acknowledgment separate from local save. No sensitive silent last-write-wins.
- Backup manifests contain IDs, relationships, versions, media locators and integrity
  information. Test new-device discovery/restore without the old phone. Restoring
  must not duplicate payments, stock mutations, notifications or completed uploads.
- Local secrets/key storage and cloud authorization are separate boundaries. No
  security-by-hidden-widget, embedded admin secrets, or permissive production rules.
- No automatic cascading financial deletion or destructive retention; deletion/
  reversal/restore durations and some cloud identity policies remain owner choices.
- Offline-only users keep working; pack download account gating must not disable
  existing ordinary records. Post-download entitlement behavior is unresolved.

## Inventory migration acceptance (separate implementation slice)

Map every source field, type conversion/default and rejected record explicitly.
Preserve IDs and references, trade-pack/catalog identity and versions, unit/pack
relationships, quantities, par, locations, cost provenance and stock history.
Do not merge similarly named materials, round away quantities, or derive stock
certainty from incomplete cost records. Never silently omit malformed input.
Reuse existing harness where sound and add independent invariants/oracles.
Check count and ID-set reconciliation, referential integrity, exact totals,
duplicate/repeated migration, interrupted writes, low disk, corruption, old schema,
rollback/recovery and app-level read/edit/reopen workflows. Record command/results
and gaps. A compiler pass or importer success does not prove conversion integrity.

## Two-task coordination if the owner opens both

Foundation task owns schema versioning, database bootstrap, repository contracts,
transactions and queue boundaries. Migration task first maps sources read-only;
it must not invent a second database/schema. Agree an explicit versioned schema
contract before converter implementation. Do not concurrently edit shared files
without a file/ownership agreement. No additional agents unless requested.

## Reporting and user control

Report exact files changed, source provenance, preserved behavior, tests actually
run, device evidence and remaining blockers. Never claim production readiness from
fixtures. Realistic demo interval is Aug 31–Sep 13, 2026 with coherent linked data;
do not seed over actual records. No UI redesign, broad OCR/GPS migration, preview
app substitution, or unrelated cleanup. Ask only genuine product/security choices;
own ordinary engineering investigation and safeguards.
