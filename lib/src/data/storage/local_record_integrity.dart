import 'dart:isolate';

import 'local_record_command.dart';

typedef LocalIntegrityQuery =
    Future<List<Map<String, Object?>>> Function(
      String sql,
      List<int> arguments,
    );

/// Internal whole-database validation, inside the caller's consistent read
/// transaction. Never repairs mismatches or exposes record contents in errors.
Future<void> verifyLocalRecordHistory(LocalIntegrityQuery query) async {
  final mismatches = await query('''
SELECT 1 FROM local_records r LEFT JOIN local_record_revisions h
ON h.organization_id = r.organization_id AND h.domain = r.domain
AND h.record_id = r.record_id AND h.revision = r.revision
WHERE h.record_id IS NULL OR h.owner_id <> r.owner_id
OR h.payload_version <> r.payload_version OR h.payload <> r.payload
OR h.updated_at_us <> r.updated_at_us LIMIT 1
''', const []);
  if (mismatches.isNotEmpty) {
    throw StateError('Saved records disagree with their revision history.');
  }
  final gaps = await query('''
SELECT 1 FROM local_record_revisions h JOIN local_records r
ON r.organization_id = h.organization_id AND r.domain = h.domain
AND r.record_id = h.record_id
GROUP BY h.organization_id, h.domain, h.record_id
HAVING MIN(h.revision) <> 1 OR MAX(h.revision) <> MAX(r.revision)
OR COUNT(*) <> MAX(r.revision) LIMIT 1
''', const []);
  if (gaps.isNotEmpty) {
    throw StateError('Saved revision history is incomplete.');
  }
  final journal = await query('''
SELECT 1 FROM local_commands c
WHERE NOT EXISTS (SELECT 1 FROM local_change_outbox o
  WHERE o.organization_id = c.organization_id AND o.command_id = c.command_id)
OR NOT EXISTS (SELECT 1 FROM local_record_revisions h
  WHERE h.organization_id = c.organization_id AND h.command_id = c.command_id)
LIMIT 1
''', const []);
  if (journal.isNotEmpty) {
    throw StateError('Saved command journals are incomplete.');
  }
  int? cursor;
  while (true) {
    final rows = await query('''
SELECT rowid AS cursor, payload, payload_hash FROM local_record_revisions
${cursor == null ? '' : 'WHERE rowid > ?'} ORDER BY rowid LIMIT 256
''', cursor == null ? const [] : [cursor]);
    if (rows.isEmpty) return;
    final payloads = [
      for (final row in rows)
        (row['payload'] as String, row['payload_hash'] as String),
    ];
    // Bound transferred rows and keep hashing off the UI isolate on startup.
    final valid = await Isolate.run(
      () => payloads.every((entry) => payloadDigest(entry.$1) == entry.$2),
    );
    if (!valid) {
      throw StateError('Saved revision contents failed verification.');
    }
    cursor = rows.last['cursor'] as int;
  }
}
