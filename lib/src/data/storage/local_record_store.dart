import 'dart:convert';

import 'package:drift/drift.dart';

import 'local_database.dart';
import 'local_record_command.dart';

/// Storage boundary only. Application services must authorize each command.
/// Organization and owner predicates are also required on every public read.
class LocalRecordStore {
  const LocalRecordStore(this.database);

  final LocalDatabase database;

  Future<List<LocalRecord>> read({
    required String organizationId,
    required String domain,
    required Set<String> ownerIds,
    Set<String>? recordIds,
  }) {
    if (ownerIds.isEmpty || (recordIds?.isEmpty ?? false)) {
      return Future.value(const []);
    }
    return (database.select(database.localRecords)..where(
          (row) =>
              row.organizationId.equals(organizationId) &
              row.domain.equals(domain) &
              row.ownerId.isIn(ownerIds) &
              (recordIds == null
                  ? const Constant(true)
                  : row.recordId.isIn(recordIds)),
        ))
        .get();
  }

  /// Records, retained revisions, command identity, and local change journal
  /// commit together. Replaying the same command cannot duplicate side effects.
  /// Time is excluded from the fingerprint so a retry can use a new clock time.
  Future<void> commit({
    required String organizationId,
    required String commandId,
    required List<LocalRecordWrite> writes,
    required DateTime occurredAt,
  }) async {
    // Capture the command before the first asynchronous boundary. Callers may
    // reuse their list while SQLite is busy; the fingerprint and actual writes
    // must continue to describe the same immutable request.
    final submittedWrites = List<LocalRecordWrite>.unmodifiable(writes);
    if (organizationId.trim().isEmpty ||
        commandId.trim().isEmpty ||
        submittedWrites.isEmpty) {
      throw ArgumentError(
        'A command needs an organization, identity and writes.',
      );
    }
    final keys = submittedWrites
        .map((write) => (write.domain, write.recordId))
        .toSet();
    if (keys.length != submittedWrites.length) {
      throw ArgumentError('A command cannot write the same record twice.');
    }
    final hash = payloadDigest(
      canonicalJson(submittedWrites.map((w) => w.toJson()).toList()),
    );
    final time = occurredAt.toUtc().microsecondsSinceEpoch;
    await database.transaction(() async {
      final previous =
          await (database.select(database.localCommands)..where(
                (row) =>
                    row.organizationId.equals(organizationId) &
                    row.commandId.equals(commandId),
              ))
              .getSingleOrNull();
      if (previous != null) {
        if (previous.requestHash != hash) {
          throw const LocalRecordConflict(
            'This command was already used for different values.',
          );
        }
        return;
      }
      await database
          .into(database.localCommands)
          .insert(
            LocalCommandsCompanion.insert(
              organizationId: organizationId,
              commandId: commandId,
              requestHash: hash,
              committedAtUs: time,
            ),
          );
      for (final write in submittedWrites) {
        final current =
            await (database.select(database.localRecords)..where(
                  (row) =>
                      row.organizationId.equals(organizationId) &
                      row.domain.equals(write.domain) &
                      row.recordId.equals(write.recordId),
                ))
                .getSingleOrNull();
        if ((current?.revision ?? 0) != write.expectedRevision) {
          throw const LocalRecordConflict(
            'The saved record changed. Reload it before saving again.',
          );
        }
        final record = LocalRecordsCompanion.insert(
          organizationId: organizationId,
          domain: write.domain,
          recordId: write.recordId,
          ownerId: write.ownerId,
          revision: write.nextRevision,
          payloadVersion: write.payloadVersion,
          payload: write.payloadJson,
          updatedAtUs: time,
        );
        if (current == null) {
          await database.into(database.localRecords).insert(record);
        } else {
          await (database.update(database.localRecords)..where(
                (row) =>
                    row.organizationId.equals(organizationId) &
                    row.domain.equals(write.domain) &
                    row.recordId.equals(write.recordId),
              ))
              .write(record);
        }
        await database
            .into(database.localRecordRevisions)
            .insert(
              LocalRecordRevisionsCompanion.insert(
                organizationId: organizationId,
                domain: write.domain,
                recordId: write.recordId,
                revision: write.nextRevision,
                commandId: commandId,
                ownerId: write.ownerId,
                payloadVersion: write.payloadVersion,
                payload: write.payloadJson,
                payloadHash: payloadDigest(write.payloadJson),
                updatedAtUs: time,
              ),
            );
      }
      await database
          .into(database.localChangeOutbox)
          .insert(
            LocalChangeOutboxCompanion.insert(
              organizationId: organizationId,
              commandId: commandId,
            ),
          );
    });
  }

  Map<String, Object?> decode(LocalRecord record) {
    if (record.payloadVersion != 1) {
      throw StateError('Unsupported ${record.domain} payload version.');
    }
    return (jsonDecode(record.payload) as Map).cast<String, Object?>();
  }
}
