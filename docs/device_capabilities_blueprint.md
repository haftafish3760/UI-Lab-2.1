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
- Preserve the reference hardware score/confidence and 1–10 grade as advisory
  evidence within this same profile. Unknown hardware stays ungraded. Grade is
  capped by the six-tier policy; it is not another admission gate. Public GPU
  compute and codec evidence can support higher tiers on platforms without
  Android Media Performance Class, subject to memory/CPU limits. Neither a
  grade nor a platform capability claim proves sustained throughput.
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
- The full 5.7 inventory is the migration baseline: detailed camera lenses and
  formats, complete normalized sensor inventory, display, hardware media codecs,
  graphics, connectivity and Bluetooth readiness, plus hardware and live power
  conditions. Extend existing profile/service ownership; do not duplicate it.
  Manufacturer/model/OS and CPU/RAM are permitted local diagnostic context;
  registered owner, serials and unique identifiers remain excluded. Capability
  detection must not read samples or start sessions to fill missing fields.
- Durable Storage owns remaining-space measurement and storage policy. Existing
  resource-gate compatibility fields remain until its owner connects the shared
  storage source; this slice adds no second storage detector or reclamation.
- Future admin-health integration follows the operational-health boundary in
  `data_storage_sync_contract.md`. This subsystem provides local metadata only;
  it does not create a telemetry uploader or claim to detect whole-device crashes.
- Synthetic device/pressure profiles must exercise the same policy and service
  as native observations. Simulation is test tooling, never a production switch
  that can relax real safety conditions. Physical thermal/battery acceptance
  remains necessary.
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
  Readiness requires a dated observation no older than ten seconds (at most two
  seconds of future clock tolerance) and explicitly enabled location services.
  Missing dates and unknown service state produce manual fallback. Consumers
  must reassess when starting work; a returned proposal is not a lasting grant.
  An observed native background denial/restriction or disabled service vetoes
  a consumer-supplied grant; cached permission cannot override revocation.
- SQLite is the only permitted persistence architecture for any future durable
  user controls. Do not introduce Hive. Do not store transient health snapshots
  just to claim a database migration; the legacy capability service has no Hive
  schema. Any persisted controls must not disable the hard safety reserve.
  Android's performance-class lookup must be asynchronous and memory-only;
  do not import the reference wrapper's blocking preference-cache behavior.

## Verification and completion

Full reuse/parity evidence is in
`audits/device_capabilities_full_parity_2026_09_19.md`; earlier test history is in
`audits/device_capabilities_2026_09_19.md`. Independent
requirements tests must cover malformed/zero/unknown observations, all six tiers,
pressure monotonicity, stale reads, reserve boundaries, competing work, timeout
ownership, pressure during work, recovery, permission separation and privacy.
Android build and native contract checks do not establish iOS compilation or
physical-device thermal/battery acceptance. The S9 Plus compatibility target
needs real-device verification; no model name is a capability guarantee.

The shared implementation has passed focused Flutter tests, Android native tests
and the available Android/Windows builds recorded in the audit. Apple builds and
physical-device release acceptance remain outstanding. Do not label this contract
as proof that every app writer or future subsystem is protected.
