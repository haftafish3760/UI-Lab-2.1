import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';

/// The bundled SQLite catalog is immutable reference data. A private temporary
/// copy permits native SQLite reads without mixing catalog data with stock.
/// Returned payloads are detached before the connection and file are closed.
Map<String, dynamic> readInventoryCatalogDatabase(Uint8List bytes) {
  final directory = Directory.systemTemp.createTempSync('tame_catalog_');
  Database? db;
  try {
    final file = File('${directory.path}/catalog.sqlite')
      ..writeAsBytesSync(bytes);
    db = sqlite3.open(file.path, mode: OpenMode.readOnly);
    if (db.select('PRAGMA user_version').single.values.single != 1 ||
        db.select('PRAGMA integrity_check').single.values.single != 'ok') {
      throw const FormatException('Unsupported or damaged catalog');
    }
    return {
      'trades': [
        for (final row in db.select('SELECT name FROM trades ORDER BY name'))
          row['name'],
      ],
      'items': [
        for (final row in db.select('SELECT payload FROM items ORDER BY id'))
          jsonDecode(row['payload'] as String),
      ],
    };
  } finally {
    db?.close();
    directory.deleteSync(recursive: true);
  }
}
