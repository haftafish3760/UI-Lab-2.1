import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';

/// Reference definitions only. No stock or receipt records are created here.
void writeBrowseBatch(Database db, Map<String, dynamic> batch) {
  db.execute('BEGIN IMMEDIATE');
  try {
    db.execute('CREATE TABLE trades (name TEXT PRIMARY KEY)');
    db.execute(
      'CREATE TABLE items (id TEXT PRIMARY KEY, payload TEXT NOT NULL CHECK(json_valid(payload)))',
    );
    db.execute(
      'CREATE TABLE batch_info (id TEXT PRIMARY KEY, status TEXT NOT NULL)',
    );
    db.execute('PRAGMA user_version = 1');
    final trades = List<String>.from(batch['trades'] as List);
    for (final trade in trades) {
      if (trade.trim().isEmpty) throw const FormatException('Empty trade');
      db.execute('INSERT INTO trades VALUES (?)', [trade]);
    }
    final items = batch['items'] as List;
    if (items.isEmpty) throw const FormatException('Empty batch');
    for (final raw in items) {
      final item = Map<String, dynamic>.from(raw as Map);
      for (final key in ['id', 'sourceId', 'name', 'unit']) {
        if (item[key] is! String || (item[key] as String).trim().isEmpty) {
          throw FormatException('Missing $key');
        }
      }
      final path = List<String>.from(item['path'] as List);
      if (path.isEmpty ||
          path.any((s) => s.trim().isEmpty) ||
          !trades.contains(path.first))
        throw const FormatException('Invalid path');
      if (item['aliases'] is! List || item['sourcePayload'] is! Map) {
        throw const FormatException('Missing source metadata');
      }
      final source = item['sourcePayload'] as Map;
      if (source['id'] != item['sourceId'] ||
          source['name'] != item['name'] ||
          source['unit'] != item['unit'] ||
          source['variant'] != item['variant'] ||
          jsonEncode(item['sourceAliases']) != jsonEncode(item['aliases'])) {
        throw const FormatException('Source identity or aliases changed');
      }
      final exportedAliasValues = (source['aliases'] as List)
          .map((alias) => (alias as Map)['value'])
          .toSet();
      if (!(item['aliases'] as List).every(exportedAliasValues.contains)) {
        throw const FormatException('Alias not present in source payload');
      }
      db.execute('INSERT INTO items VALUES (?, ?)', [
        item['id'],
        jsonEncode(item),
      ]);
    }
    db.execute('INSERT INTO batch_info VALUES (?, ?)', [
      batch['batch'],
      batch['status'],
    ]);
    db.execute('COMMIT');
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
}
