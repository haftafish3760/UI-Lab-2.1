import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog_database.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_trade_assets.dart';

void main() {
  test('trade artwork stays local and within a small bundled budget', () {
    var size = 0;
    for (final trade in inventoryTradeAssets.keys) {
      final file = File(inventoryTradeImage(trade)!);
      expect(file.existsSync(), isTrue, reason: trade);
      size += file.lengthSync();
    }
    expect(size, lessThan(3 * 1024 * 1024));
  });
  test('bounded SQLite batch has unique identities and navigable paths', () {
    final data = readInventoryCatalogDatabase(
      File('assets/inventory/browse_batch.sqlite').readAsBytesSync(),
    );
    final catalog = InventoryCatalog.fromJson(data);
    expect(catalog.items.length, 49);
    expect(catalog.items.map((i) => i.id).toSet().length, catalog.items.length);
    final trades = catalog.branches(const []);
    for (final name in [
      'Plumbing',
      'Electrical',
      'HVAC',
      'Carpentry',
      'Roofing',
    ]) {
      expect(trades, contains(name));
    }
    for (final item in catalog.items) {
      expect(item.path.take(2), ['Plumbing', 'Fittings']);
      expect(item.path.every((p) => p.trim().isNotEmpty), isTrue);
      expect(item.name.trim(), isNotEmpty);
      expect(item.unit.trim(), isNotEmpty);
    }
  });
  test('search stays within chosen trade and does not alter its path', () {
    final catalog = InventoryCatalog.fromJson({
      'version': 1,
      'items': [
        {
          'id': 'p',
          'name': 'Half inch elbow',
          'trade': 'Plumbing',
          'category': 'Pipe fittings',
          'system': 'PVC',
          'type': 'Elbows',
          'unit': 'each',
        },
        {
          'id': 'e',
          'name': 'Conduit elbow',
          'trade': 'Electrical',
          'category': 'Conduit',
          'system': 'PVC',
          'type': 'Elbows',
          'unit': 'each',
        },
      ],
    });
    expect(catalog.search('elbow', ['Plumbing']).map((i) => i.id), ['p']);
    expect(catalog.branches(['Plumbing', 'Pipe fittings']), ['PVC']);
    expect(catalog.search('missing', []), isEmpty);
  });
}
