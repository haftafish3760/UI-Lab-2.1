import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog_database.dart';

void main() {
  test(
    'review slice keeps 21 trade choices but only the bounded copper item family',
    () {
      final data = readInventoryCatalogDatabase(
        File('assets/inventory/browse_batch.sqlite').readAsBytesSync(),
      );
      final catalog = InventoryCatalog.fromJson(data);
      expect(catalog.items.length, 8);
      expect(
        catalog.items.every(
          (item) => item.path.join('/') == 'Plumbing/Fittings/Copper/90 Elbows',
        ),
        isTrue,
      );
      expect(catalog.branches(const []).length, 21);
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('assets/inventory/trades/'),
      );
    },
  );
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
