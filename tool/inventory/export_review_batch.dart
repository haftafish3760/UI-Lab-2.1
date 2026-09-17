import 'dart:convert';
import 'dart:io';
import 'legacy_reference/data/work_supply_catalog.dart';
import 'legacy_reference/data/work_supply_catalog_pack_payload.dart';

// Read-only source extraction. The batch is intentionally explicit, not a
// rule that promotes every generated catalog expansion to a browsing category.
void main() {
  final selected = workSupplyCatalogItems
      .where(
        (item) =>
            item.trade == 'Plumbing' &&
            item.category == 'Fittings' &&
            ((item.system == 'PVC Schedule 40' &&
                    ['90 Elbows', 'Tees'].contains(item.itemType)) ||
                (item.system == 'ABS DWV' && item.itemType == 'Sanitary Tees')),
      )
      .toList();
  if (selected.isEmpty) throw StateError('Selected source families missing');
  final output = {
    'batch': 'plumbing-fittings-001',
    'status': 'source-preserved; independent trade coverage review pending',
    'trades': [for (final trade in workSupplyTrades) trade.name],
    'items': [
      for (final item in selected)
        {
          'id': '${item.trade}::${item.id}',
          'sourceId': item.id,
          'name': item.name,
          'unit': item.unit,
          'variant': item.variant,
          'aliases': item.aliases,
          'sourceAliases': item.aliases,
          'path': [item.trade, item.category, item.system, item.itemType],
          'sourcePayload': buildWorkSupplyCatalogPackItemPayload(item).toMap(),
        },
    ],
  };
  final target = File('docs/inventory_migration/plumbing_fittings_001.json');
  target.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));
  stdout.writeln('Exported ${selected.length} source items for batch review');
}
