import 'package:drift/native.dart';

import 'local_database.dart';
import 'local_record_command.dart';

// Internal SQLite bookkeeping (auto-indexes, sequence, statistics) is governed
// by SQLite. All application-defined tables/indexes/views/triggers must match.
const localSnapshotSchemaQuery = '''
SELECT type, name, tbl_name, sql FROM main.sqlite_schema
WHERE name NOT GLOB 'sqlite_*' ORDER BY type, name
''';

/// Derive the accepted schema from the same generated Drift definitions used
/// by the app. No independently maintained list can silently drift from them.
Future<String> expectedLocalSnapshotSchema(int version) async {
  final reference = LocalDatabase(NativeDatabase.memory());
  try {
    if (reference.schemaVersion != version) {
      throw StateError('Unsupported checkpoint schema version.');
    }
    final rows = await reference.customSelect(localSnapshotSchemaQuery).get();
    return canonicalJson(rows.map((row) => row.data).toList());
  } finally {
    await reference.close();
  }
}
