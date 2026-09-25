# Shared device capabilities and resource protection

Owner authorization: September 19, 2026, current conversation. This is a
brand-neutral system in UI Lab 2.1; Maintainiac 5.7 Active is read-only.
This document owns the shared contract. Receipt-specific accuracy and timing
remain in `receipt_material_intake_blueprint.md`. Storage authority remains
SQLite/Drift under `data_storage_sync_contract.md`.

Renewed owner authorization, September 19: continue implementing and independently
testing the shared device capabilities system itself in UI Lab 2.1. This
supersedes the interim handoff of engine implementation. OCR remains owned by
the other task; do not edit its files or add consumer connections. Routine
implementation and testing require no discretionary permission checkpoint.

Earlier owner scope correction, September 19: this task is the read-only legacy
audit and standalone device-capability system. Do not connect it to OCR or other
app features. Another task owns OCR. Do not edit or revert OCR files, including
cleanup behavior. The earlier integration notes are historical work outside the
corrected scope, not authorization to continue those edits. Publish a reusable
API and independently validate it; consumer integration belongs to its owner.

## Required behavior

- Exactly six workload tiers: constrained, entry, balanced, enhanced,
  performance, flagship. Hardware evidence establishes a baseline; current
  pressure can only reduce it. Marketing names, price and release year cannot
  increase capacity. Tier thresholds are engineering starting budgets requiring
  physical-device calibration, not verified rankings of named phones.
- Hardware observations and live conditions remain local, ephemeral and separate
  from user identity, business records, backup and sync. Do not collect owner,
  serial, advertising/device/machine IDs, Bluetooth identities, network names,
  sensor samples or location in this subsystem. Do not persist a fingerprint.
- Availability, authorization and service-enabled state are distinct. Reading
  capabilities never asks for permissions or starts camera, motion or GPS.
- Report RAM, usable memory/heap evidence, CPU parallelism/architecture,
  platform performance evidence, sensors, camera availability, battery, power
  saving, thermal pressure and app-volume storage where public APIs permit.
  Missing, invalid, stale and unsupported observations cannot become healthy.
- A shared gate checks current conditions before heavy work, budgets memory and
  disk, rejects competing work, publishes state/reasons and checks between units.
  Native work retains its slot through cleanup even after a caller times out.
  Live pressure requests cooperative stop; it cannot forcibly cancel an opaque
  native call. Callers must bound every such unit and reject late results.
- Preserve at least 100,000,000 free bytes. Use a conservative 100 MiB reserve
  (104,857,600 bytes). Account for peak temporary/output storage before admission;
  unknown free space cannot authorize disk-growing work. Recheck at write/unit
  boundaries. Other processes can consume storage between checks: handle ENOSPC,
  preserve originals and any already-created output without automatic deletion
  or overwriting. This is not an OS quota.
- Low battery, power saving, thermal and memory pressure reduce budgets; serious
  heat or critical resources defer expensive work. Charging never overrides heat.
- No automatic file reclamation to satisfy a resource budget. Cross-platform
  overwrite/deletion consent is owned by the September 19 file-preservation rule
  in `data_storage_sync_contract.md`. The owner's follow-up explicitly protects
  app-created information too; no temporary-file exception is authorized.
- Trip guidance is readiness/advice, not tracking or reliable activity inference.
  Permission plus explicit opt-in are required separately; missing motion signals
  require location-only/manual-review fallback, never invented walking/driving.
- SQLite is the only permitted persistence architecture for any future durable
  user controls. Do not introduce Hive. Do not store transient health snapshots
  just to claim a database migration; the legacy capability service has no Hive
  schema. Any persisted controls must not disable the hard safety reserve.

## Verification and completion

Audit evidence is in `audits/device_capabilities_2026_09_19.md`. Independent
requirements tests must cover malformed/zero/unknown observations, all six tiers,
pressure monotonicity, stale reads, reserve boundaries, competing work, timeout
ownership, pressure during work, recovery, permission separation and privacy.
Android build and native contract checks do not establish iOS compilation or
physical-device thermal/battery acceptance. The S9 Plus compatibility target
needs real-device verification; no model name is a capability guarantee.

Implementation and platform validation are in progress. Do not label this
contract as proof that every app writer or future subsystem is protected.
