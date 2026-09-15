# Pending owner review notes — September 15, 2026

These capture the ongoing screen-by-screen discussion, not implementation or
acceptance. App changes are paused until the owner finishes and authorizes a
combined pass. Reconcile these with the owning blueprints before implementation.

- Review existing screens and their contents before adding more displays. Give
  each workflow a clear home; avoid repeated selectors and redundant summaries.
- Hamburger/business menu: each destination must have its own recognizable
  container, grouped consistently with the rest of the app. One large container
  holding unbounded menu rows does not satisfy the owner's requirement.
- Vehicle profiles must be easy to find. Fuel mileage/fuel economy is required
  per vehicle. Review recorded fuel quantities, odometers, and partial fill-ups;
  the owner has not finished specifying the calculation workflow or its home.
- Each Job needs its own cost breakdown: labor, materials, other expenses and
  travel/fuel, linked to original records, plus billed amounts and payments.
  Determine complete versus incomplete costs before labeling a result profit.
- Daily admin overview and longer-period Recap have different purposes. Recap
  should not duplicate the daily workspace or create independent source records.
- Pending dashboard corrections: remove horizontal duplicate company/employee
  selector; Admin selector approximately half width; replace Business overview
  wording with Recap (final wording remains open).

Existing relevant ownership: operations_screen_blueprint.md,
work_lifecycle_blueprint.md, technician_dashboard_blueprint.md, and
product_control_blueprint.md. No claim that these notes are already implemented.
