# UI Lab 2.1 Working Contract

Read these before changing UI:

1. `docs/ui_foundation_blueprint.md`
2. `docs/maintainiac_app_blueprint.md`
3. `docs/product_control_blueprint.md`
4. `docs/operations_screen_blueprint.md`
5. `docs/work_lifecycle_blueprint.md` for any Work change
6. `docs/calendar_system_blueprint.md` for any calendar or dated-projection change
7. the relevant screen-specific blueprint under `docs/`

## Repository boundary

- This repository is the active UI/UX blueprint and test bed.
- Maintainiac 5.7 Active is the production master and protected reference until
  the owner explicitly starts a bounded integration slice.
- Do not edit, clean, reset, delete, or commit 5.7 from a UI Lab task.
- Do not take computer screenshots unless the owner explicitly reauthorizes it.

## Required implementation behavior

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
