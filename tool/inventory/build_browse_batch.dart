import 'dart:convert';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'browse_batch_sqlite.dart';

void main() {
  final batch =
      jsonDecode(
            File(
              'docs/inventory_migration/plumbing_fittings_001.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final target = File('assets/inventory/browse_batch.sqlite');
  // Refuse an accidental overwrite; explicit replacement is a separate action.
  if (target.existsSync()) throw StateError('Batch database already exists');
  final db = sqlite3.open(target.path);
  try {
    writeBrowseBatch(db, batch);
    stdout.writeln(
      'SQLite batch: ${db.select('SELECT count(*) AS n FROM items').single['n']} items',
    );
  } finally {
    db.close();
  }
}
