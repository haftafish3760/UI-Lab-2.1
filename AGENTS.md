# UI Lab 2.1 Working Contract

Read these before changing UI:

1. `docs/ui_foundation_blueprint.md`
2. `docs/maintainiac_app_blueprint.md`
3. `docs/product_control_blueprint.md`
4. `docs/operations_screen_blueprint.md`
5. `docs/work_lifecycle_blueprint.md` for any Work change
6. `docs/calendar_system_blueprint.md` for any calendar or dated-projection change
7. the relevant screen-specific blueprint under `docs/`

For catalog, Inventory, parser or validation-harness work, also read
`docs/inventory_rebuild_plan.md` and the complete owner-supplied passages in
`docs/inventory_migration/OWNER_VERBATIM_REQUIREMENTS_2026_09_18.md`.
Re-read that verbatim record after context compression; do not substitute a
summary for it. The owner authorized generator/harness implementation on the HP
on September 18 after its documentation-only checkpoint. Read
`docs/inventory_migration/CATALOG_ENGINEERING_CHECKPOINT_2026_09_18.md` for the
current evidence and unfinished scope. No delegation is authorized.

## Repository boundary

- This repository is the active UI/UX blueprint and test bed.
- Maintainiac 5.7 Active is the production master and protected reference until
  the owner explicitly starts a bounded integration slice.
- Do not edit, clean, reset, delete, or commit 5.7 from a UI Lab task.
- Do not take computer screenshots unless the owner explicitly reauthorizes it.

## Required implementation behavior

### Owner data-preservation rule — September 19, 2026

- On every supported platform (Android, iOS, Windows, macOS and others), the app
  must not overwrite existing user information, including information the app
  created itself, to make room or accommodate resource pressure.
- The app must never automatically delete existing information to free storage.
  Deletion requires the user to choose an explicit Delete (or equivalent) action
  and then confirm that deletion before it occurs. Cancellation deletes nothing.
- Reaching the minimum 100 MB free-storage reserve must stop or defer additional
  storage-consuming work and explain that the user must choose what to remove.
  It must never trigger automatic deletion, replacement or overwriting.
- Preserve original files and existing export destinations. App ownership of a
  file is not deletion permission. No exception for temporary processing files
  has been authorized. Audit existing cleanup paths against this rule.
- These are implementation requirements, not claims that existing code complies.
  The owning detailed rule is in `docs/data_storage_sync_contract.md`.

- Consistency is mandatory. Use `AppTheme`, `AppLayoutEngine`, and shared
  primitives; never create a private global breakpoint system inside a screen.
- Follow the whole-card, meaning-based color rule in UI foundation section 3:
  Plan and Entries retain their respective families across screens/employees.
  Do not substitute minimalist pale bodies or header-only color. Exact trial
  shades are not owner acceptance; verify the rendered result against feedback.
- Surface missing dependencies and safeguards proactively within the requested
  scope; do not require the owner to specify routine engineering necessities.
  Explain unresolved product choices and never portray a fixture as a connected
  production system. See Product Control's authority and completion rules.
- Base layout on local post-navigation logical constraints and `TextScaler`, not
  OS, device name, orientation label, physical pixels, or monitor size.
- Preserve system accessibility scaling. Reflow instead of globally clamping.
- Do not use ellipsis for primary controls, record names, dates, money, or state.
- Light mode uses blue-gray tinted surfaces. Pure-white working panels and
  black content sections are prohibited; the charcoal operational header is an
  intentional exception.
- Normal phone action controls must not stack early. The dashboard header has a
  tested side-by-side contract at 320 LP.
- Keep record, form, and supporting-calendar lanes bounded; desktop is not an
  enlarged phone. On Dashboard the Month calendar occupies one 400-LP maximum
  lane and its day route remains separate.
- Security and privacy enforcement must exist at navigation, query/count, route,
  action, export, and sync boundaries. Hiding a widget alone is not permission.
- AI, OCR, GPS, and inferred data remain proposals until user-confirmed.

## Change discipline

- Owner direction, September 19: continue authorized implementation and testing
  in UI Lab 2.1 without stopping for repeated permission questions. Routine
  engineering decisions are already authorized. Maintainiac 5.7 Active remains
  strictly read-only; this authorization never permits changing it. Mandatory
  host/sandbox restrictions still apply and must be described accurately if they
  block execution; do not invent discretionary approval checkpoints.

- Before substantial subsystem work or delegation, follow the required reuse
  assessment in `docs/maintainiac_app_blueprint.md` section 2. Inspect relevant
  5.7 capabilities read-only, report suitability and unverified risks, and carry
  the requirement into each bounded agent assignment before implementation.
- Before blueprint edits, follow "Blueprint changes: check existing
  requirements first" in `docs/product_control_blueprint.md`; update the owning
  rule or cross-reference it instead of creating competing copies.
- Inspect branch and dirty state before editing; preserve unrelated work.
- Update code, blueprint, and regression test together when a shared UI rule
  changes.
- Keep production Dart files at or below 500 lines. Split only at cohesive
  responsibility boundaries and run focused regression tests after each split.
  If a safe split genuinely cannot preserve behavior, document the constraint
  before allowing an exception.
- Use `dart format`, `flutter analyze`, `flutter test`, and the relevant platform
  build. A green test is not owner visual acceptance.

## Build resource cleanup — owner direction

- On this 8-GB Mac Mini, run at most one emulator/simulator at a time.
- After Android build/test work finishes, check for active builds, then stop idle
  Gradle/Kotlin daemons and other task-owned build workers. Verify they exited.
- Do not leave build services running between unrelated UI/review work. Preserve
  the app being reviewed, Codex, and the Maintainiac bridge; identify Node process
  ownership before stopping anything. Never kill all Java/Node processes blindly.
