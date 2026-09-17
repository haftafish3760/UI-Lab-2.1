import 'package:flutter/widgets.dart';
import '../../../../l10n/app_localizations_extension.dart';
import 'inventory_catalog.dart';
import 'materials_catalog_text.dart';

String materialsBranchLabel(BuildContext context, String source) {
  final l = context.l10n;
  return switch (source) {
    'Plumbing' => l.catalogPlumbing,
    'Electrical' => l.catalogElectrical,
    'HVAC' => l.catalogHvac,
    'Fittings' => l.catalogFittings,
    'Copper' => l.catalogCopper,
    '90 Elbows' => l.catalogElbows90,
    _ => materialsAngleLabel(source),
  };
}

String materialsItemLabel(BuildContext context, InventoryCatalogItem item) =>
    item.labelKey == 'copper_solder_90'
    ? context.l10n.catalogCopperElbow(item.variant)
    : materialsAngleLabel(item.name);

String materialsUnitLabel(BuildContext context, String unit) =>
    unit == 'each' ? context.l10n.catalogEach : unit;
