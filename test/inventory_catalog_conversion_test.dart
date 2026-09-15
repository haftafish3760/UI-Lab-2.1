import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../tool/inventory/catalog_sqlite_writer.dart';

void main() {
  late Database database;
  setUp(() {
    database = sqlite3.openInMemory();
    database.execute('PRAGMA foreign_keys = ON');
  });
  tearDown(() => database.close());

  Map<String, dynamic> pack() => Map<String, dynamic>.from(
    jsonDecode(
          utf8.decode(
            gzip.decode(
              File(
                'assets/inventory/electrical_core.json.gz',
              ).readAsBytesSync(),
            ),
          ),
        )
        as Map,
  );

  test(
    'packaged SQLite reopens and preserves every item in all three packs',
    () {
      final directory = Directory.systemTemp.createTempSync(
        'inventory_catalog_',
      );
      try {
        final file = File('${directory.path}/catalog.sqlite')
          ..writeAsBytesSync(
            gzip.decode(
              File('assets/inventory/core_catalog.sqlite.gz').readAsBytesSync(),
            ),
          );
        final opened = sqlite3.open(file.path, mode: OpenMode.readOnly);
        try {
          var count = 0;
          for (final trade in ['electrical', 'plumbing', 'hvac']) {
            final source =
                jsonDecode(
                      utf8.decode(
                        gzip.decode(
                          File(
                            'assets/inventory/${trade}_core.json.gz',
                          ).readAsBytesSync(),
                        ),
                      ),
                    )
                    as Map;
            for (final item in source['items'] as List) {
              final row = opened.select(
                'SELECT payload FROM catalog_items WHERE id = ?',
                [item['id']],
              ).single;
              expect(jsonDecode(row['payload'] as String), item);
              count++;
            }
          }
          expect(
            opened
                .select('SELECT count(*) AS n FROM catalog_items')
                .single['n'],
            count,
          );
          expect(
            opened.select('PRAGMA integrity_check').single.values.single,
            'ok',
          );
        } finally {
          opened.close();
        }
      } finally {
        directory.deleteSync(recursive: true);
      }
    },
  );

  test('all core item fields survive SQLite and no stock table is created', () {
    final source = pack();
    writeCatalog(database, {'Electrical': jsonEncode(source)});
    final expected = source['items'] as List;
    expect(
      database.select('SELECT count(*) AS n FROM catalog_items').single['n'],
      expected.length,
    );
    for (final item in expected) {
      final row = database.select(
        'SELECT payload FROM catalog_items WHERE id = ?',
        [item['id']],
      ).single;
      expect(jsonDecode(row['payload'] as String), item);
    }
    expect(
      database
          .select("SELECT name FROM sqlite_master WHERE type='table'")
          .map((row) => row['name'])
          .toSet(),
      {'catalog_packs', 'catalog_items'},
    );
  });

  test('duplicate identity rolls back every row and schema', () {
    final source = pack();
    (source['items'] as List).add((source['items'] as List).first);
    expect(
      () => writeCatalog(database, {'Electrical': jsonEncode(source)}),
      throwsA(isA<SqliteException>()),
    );
    expect(
      database.select("SELECT name FROM sqlite_master WHERE type='table'"),
      isEmpty,
    );
  });

  test('wrong trade and missing units reject the whole pack', () {
    for (final field in ['trade', 'unit']) {
      final source = pack();
      (source['items'] as List).last[field] = field == 'trade'
          ? 'Plumbing'
          : '';
      expect(
        () => writeCatalog(database, {'Electrical': jsonEncode(source)}),
        throwsFormatException,
      );
      expect(
        database.select("SELECT name FROM sqlite_master WHERE type='table'"),
        isEmpty,
      );
    }
  });

  test('unknown schema cannot silently discard fields', () {
    final source = pack()..['sourceSchemaVersion'] = 4;
    expect(
      () => writeCatalog(database, {'Electrical': jsonEncode(source)}),
      throwsFormatException,
    );
  });
}
