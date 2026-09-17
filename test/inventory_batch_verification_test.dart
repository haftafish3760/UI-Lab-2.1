import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog.dart';
import '../tool/inventory/browse_batch_sqlite.dart';

Map<String, dynamic> sourceBatch() =>
    jsonDecode(
          File(
            'docs/inventory_migration/plumbing_fittings_001.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  late InventoryCatalog catalog;
  setUp(() {
    // Historical fixture tests do not claim acceptance of the shipped asset.
    catalog = InventoryCatalog.fromJson(sourceBatch());
  });

  // Adapted from 5.7 test/work_supply_plumbing_catalog_identity_test.dart.
  // Its original presence check is preserved; it is NOT an accuracy measure.
  test('legacy: plumbing retains exact ABS DWV sanitary-tee identity', () {
    final matches = catalog.items.where(
      (item) =>
          item.path.first == 'Plumbing' &&
          item.name.toLowerCase().contains('abs dwv sanitary tee'),
    );
    expect(matches, isNotEmpty);
    expect(matches.map((i) => i.name), contains('3 in ABS DWV Sanitary Tee'));
  });

  test('independent: exact material path and unit accompany ABS alias', () {
    final item = catalog.items.singleWhere(
      (i) => i.name == '3 in ABS DWV Sanitary Tee',
    );
    expect(item.path, ['Plumbing', 'Fittings', 'ABS DWV', 'Sanitary Tees']);
    expect(item.variant, '3 in');
    expect(item.unit, 'each');
    expect(item.aliases, contains('abs san tee'));
    expect(
      catalog.search('abs san tee', ['Plumbing']).map((i) => i.id),
      contains(item.id),
    );
    expect(catalog.search('abs san tee', ['Electrical']), isEmpty);
  });

  test(
    'independent: requested three-quarter PVC elbow is not ABS or a tee',
    () {
      final item = catalog.items.singleWhere(
        (i) => i.name == '3/4 in PVC Schedule 40 90 Elbow',
      );
      expect(item.path, [
        'Plumbing',
        'Fittings',
        'PVC Schedule 40',
        '90 Elbows',
      ]);
      expect(item.variant, '3/4 in');
      expect(item.unit, 'each');
      expect(item.aliases, contains('pvc 90'));
      expect(
        catalog.search('pvc 90', ['Plumbing', 'Fittings', 'ABS DWV']),
        isEmpty,
      );
    },
  );

  test('independent: ordered tee sizes remain distinct without sorting', () {
    final tees = catalog.items.where((i) => i.path.last == 'Tees');
    final first = tees.singleWhere((i) => i.variant == '1/2 x 1/2 x 3/4');
    final second = tees.singleWhere((i) => i.variant == '1/2 x 3/4 x 1/2');
    expect(first.id, isNot(second.id));
    expect(first.name, isNot(second.name));
    expect(first.aliases, contains('pvc t'));
  });

  test('every source field survives writing and reopening SQLite', () {
    final dir = Directory.systemTemp.createTempSync('inventory_batch_test_');
    final path = '${dir.path}/batch.sqlite';
    try {
      final writer = sqlite3.open(path);
      try {
        writeBrowseBatch(writer, sourceBatch());
      } finally {
        writer.close();
      }
      final reader = sqlite3.open(path, mode: OpenMode.readOnly);
      try {
        final expected = sourceBatch()['items'] as List;
        expect(
          reader.select('SELECT count(*) AS n FROM items').single['n'],
          expected.length,
        );
        for (final item in expected) {
          final stored = reader.select(
            'SELECT payload FROM items WHERE id = ?',
            [item['id']],
          ).single;
          expect(
            jsonDecode(stored['payload'] as String),
            item,
            reason: item['id'] as String,
          );
        }
        expect(
          reader.select('PRAGMA integrity_check').single.values.single,
          'ok',
        );
      } finally {
        reader.close();
      }
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  for (final defect in [
    'duplicate',
    'lost alias',
    'changed unit',
    'empty path',
  ]) {
    test('invalid batch rolls back completely: $defect', () {
      final db = sqlite3.openInMemory();
      try {
        final batch = sourceBatch();
        final items = batch['items'] as List;
        switch (defect) {
          case 'duplicate':
            items.add(items.first);
          case 'lost alias':
            items.first['aliases'] = <String>[];
          case 'changed unit':
            items.first['unit'] = 'box';
          case 'empty path':
            items.first['path'] = <String>[];
        }
        expect(() => writeBrowseBatch(db, batch), throwsA(anything));
        expect(
          db.select("SELECT name FROM sqlite_master WHERE type='table'"),
          isEmpty,
        );
      } finally {
        db.close();
      }
    });
  }
}
