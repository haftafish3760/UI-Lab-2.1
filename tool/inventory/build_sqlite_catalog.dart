import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

import 'catalog_sqlite_writer.dart';

void main() {
  const destination = 'build/inventory_migration/core_catalog.sqlite';
  if (File(destination).existsSync() ||
      File('assets/inventory/core_catalog.sqlite.gz').existsSync()) {
    throw StateError(
      'Catalog exists; preserve the prior artifact before rebuilding.',
    );
  }
  File(destination).parent.createSync(recursive: true);
  final packs = <String, String>{
    for (final trade in ['Electrical', 'Plumbing', 'HVAC'])
      trade: utf8.decode(
        gzip.decode(
          File(
            'assets/inventory/${trade.toLowerCase()}_core.json.gz',
          ).readAsBytesSync(),
        ),
      ),
  };
  final database = sqlite3.open(destination);
  late Map<String, Object?> report;
  try {
    database.execute('PRAGMA foreign_keys = ON');
    database.execute('PRAGMA synchronous = FULL');
    report = writeCatalog(database, packs);
  } finally {
    database.close();
  }
  // Reopen independently and compare every serialized field, not just counts.
  final reopened = sqlite3.open(destination, mode: OpenMode.readOnly);
  var compared = 0;
  try {
    for (final pack in packs.values) {
      for (final item in (jsonDecode(pack) as Map)['items'] as List) {
        final row = reopened.select(
          'SELECT payload, source_sha256 FROM catalog_items WHERE id = ?',
          [item['id']],
        ).single;
        final expected = jsonEncode(item);
        if (row['payload'] != expected ||
            row['source_sha256'] !=
                sha256.convert(utf8.encode(expected)).toString()) {
          throw StateError('Round-trip mismatch: ${item['id']}');
        }
        compared++;
      }
    }
  } finally {
    reopened.close();
  }
  report['roundTripComparedItems'] = compared;
  report['sqliteSha256'] = sha256
      .convert(File(destination).readAsBytesSync())
      .toString();
  File('assets/inventory/core_catalog.sqlite.gz').writeAsBytesSync(
    gzip.encode(File(destination).readAsBytesSync()),
    flush: true,
  );
  File('docs/inventory_migration/catalog_audit.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(report),
    flush: true,
  );
  stdout.writeln(
    'SQLite catalog: $compared items preserved and verified after reopen.',
  );
  stdout.writeln(
    'Structural warnings: ${(report['warnings'] as List).length}; see catalog_audit.json.',
  );
}
