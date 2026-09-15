import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';

/// Builds reference catalog data only. Never creates owned stock or cost facts.
/// All packs form one transaction; any invalid row rolls back the entire build.
Map<String, Object?> writeCatalog(
  Database database,
  Map<String, String> packJson,
) {
  final counts = <String, int>{};
  final warnings = <Map<String, Object?>>[];
  database.execute('BEGIN IMMEDIATE');
  try {
    database.execute('''CREATE TABLE catalog_packs (
      trade TEXT PRIMARY KEY, source_sha256 TEXT NOT NULL,
      item_count INTEGER NOT NULL CHECK(item_count > 0))''');
    database.execute('''CREATE TABLE catalog_items (
      id TEXT PRIMARY KEY, trade TEXT NOT NULL REFERENCES catalog_packs(trade),
      canonical_key TEXT NOT NULL, name TEXT NOT NULL, unit TEXT NOT NULL,
      payload TEXT NOT NULL CHECK(json_valid(payload)),
      source_sha256 TEXT NOT NULL)''');
    database.execute(
      'CREATE INDEX catalog_trade ON catalog_items(trade, name)',
    );
    database.execute('PRAGMA user_version = 1');
    for (final entry in packJson.entries) {
      final pack = jsonDecode(entry.value) as Map<String, dynamic>;
      if (pack['schemaVersion'] != 1 ||
          pack['sourceSchemaVersion'] != 3 ||
          pack['tier'] != 'core' ||
          pack['trade'] != entry.key ||
          pack['marketScope'] != 'all') {
        throw FormatException('Unsupported core pack: ${entry.key}');
      }
      final items = pack['items'] as List;
      if (items.isEmpty) throw FormatException('Empty core pack: ${entry.key}');
      database.execute('INSERT INTO catalog_packs VALUES (?, ?, ?)', [
        entry.key,
        sha256.convert(utf8.encode(entry.value)).toString(),
        items.length,
      ]);
      final canonicalIds = <String, String>{};
      for (final raw in items) {
        final item = Map<String, dynamic>.from(raw as Map);
        for (final field in [
          'id',
          'canonicalKey',
          'name',
          'trade',
          'category',
          'system',
          'itemType',
          'unit',
        ]) {
          if (item[field] is! String ||
              (item[field] as String).trim().isEmpty) {
            throw FormatException('Missing $field in ${item['id']}');
          }
        }
        if (item['trade'] != entry.key) {
          throw FormatException('Wrong item trade');
        }
        for (final field in [
          'marketScopes',
          'searchTerms',
          'aliases',
          'merchantAliases',
          'barcodeAliases',
          'merchantSkuAliases',
          'packageHints',
        ]) {
          if (item[field] is! List) throw FormatException('Invalid $field');
        }
        if (item['intelligence'] is! Map) {
          throw FormatException('Missing intelligence');
        }
        final id = item['id'] as String;
        final key = item['canonicalKey'] as String;
        final previous = canonicalIds[key];
        if (previous != null) {
          warnings.add({
            'itemId': id,
            'otherItemId': previous,
            'issue': 'sharedCanonicalKey',
            'canonicalKey': key,
          });
        }
        canonicalIds[key] = id;
        for (final field in [
          'barcodeAliases',
          'merchantAliases',
          'packageHints',
        ]) {
          if ((item[field] as List).isEmpty) {
            warnings.add({'itemId': id, 'issue': 'empty:$field'});
          }
        }
        final payload = jsonEncode(item);
        database
            .execute('INSERT INTO catalog_items VALUES (?, ?, ?, ?, ?, ?, ?)', [
              id,
              entry.key,
              key,
              item['name'],
              item['unit'],
              payload,
              sha256.convert(utf8.encode(payload)).toString(),
            ]);
      }
      counts[entry.key] = items.length;
    }
    if (database.select('PRAGMA foreign_key_check').isNotEmpty ||
        database.select('PRAGMA integrity_check').single.values.single !=
            'ok') {
      throw StateError('Catalog integrity failed');
    }
    database.execute('COMMIT');
  } catch (_) {
    database.execute('ROLLBACK');
    rethrow;
  }
  return {
    'schemaVersion': 1,
    'counts': counts,
    'warnings': warnings,
    'reviewStatus':
        'structural checks only; trade accuracy and parser acceptance pending',
  };
}
