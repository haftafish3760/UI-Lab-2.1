# Maintainiac UI Lab 2.1

Responsive Flutter UI/UX blueprint for the Maintainiac field-service app.
Maintainiac 5.7 remains the production master; approved presentation slices from
this lab are later ported into that application without moving its business
logic into the lab.

Start with:

- `AGENTS.md` for the working contract;
- `docs/ui_foundation_blueprint.md` for exact palette, typography, breakpoint,
  accessibility, and QA rules;
- `docs/maintainiac_app_blueprint.md` for product, permission, data ownership,
  workflow, and migration decisions;
- `docs/product_control_blueprint.md` for record ownership, permission
  enforcement, action routing, and the UI Lab-to-5.7 boundary;
- `docs/operations_screen_blueprint.md` for every top-level operational screen,
  shared context, Calendar Day behavior, and acceptance coverage;
- `docs/work_lifecycle_blueprint.md` for Estimate, Job, Invoice, Payment, and
  receipt/material relationships;
- `docs/technician_dashboard_blueprint.md` for dashboard content behavior.

## Local verification

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build macos --debug
```

The active Flutter entry point is `lib/main.dart`. Static checks and a successful
build are required evidence, but the product owner still performs final visual
acceptance in the running app.
