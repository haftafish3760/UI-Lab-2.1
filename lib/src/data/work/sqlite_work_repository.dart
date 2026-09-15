import '../storage/draft_repository.dart';
import 'package:drift/drift.dart';

import 'models/work_models.dart';
import '../prototype_financial_models.dart';
import '../storage/local_database.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_draft_store.dart';
import '../storage/local_record_command.dart';
import '../storage/local_record_store.dart';
import 'work_record_codec.dart';
import 'work_financial_codec.dart';

class PersistedWorkRecord {
  const PersistedWorkRecord({
    required this.record,
    required this.storageRevision,
  });
  final WorkRecord record;
  // Storage revisions include operational changes that do not revise the
  // customer-approved document. Never conflate the two revision sequences.
  final int storageRevision;
}

class WorkRecordMutation {
  const WorkRecordMutation({
    required this.record,
    required this.expectedStorageRevision,
  });
  final WorkRecord record;
  final int expectedStorageRevision;
}

/// Work-owned persistence adapter. Its callers must authorize the operation
/// and choose the scope before invoking it; widgets do not receive this object.
class SqliteWorkRepository {
  const SqliteWorkRepository(this.database);
  final LocalDatabase database;
  DraftRepository get drafts => LocalDraftStore(database);

  Future<List<PersistedWorkRecord>> query({
    required String organizationId,
    required Set<String> visibleCreatorIds,
  }) async {
    final rows = await LocalRecordStore(database).read(
      organizationId: organizationId,
      domain: 'work/records',
      ownerIds: visibleCreatorIds,
    );
    final deleted = await LocalRecordStore(database).read(
      organizationId: organizationId,
      domain: 'work/deleted',
      ownerIds: visibleCreatorIds,
    );
    final deletedIds = deleted.map((row) => row.recordId).toSet();
    return List.unmodifiable(
      rows.where((row) => !deletedIds.contains(row.recordId)).map((row) {
        final record = decodeWorkRecord(LocalRecordStore(database).decode(row));
        if (record.id != row.recordId ||
            record.createdByEmployeeId != row.ownerId) {
          throw StateError('Saved Work record identity is inconsistent.');
        }
        return PersistedWorkRecord(
          record: record,
          storageRevision: row.revision,
        );
      }),
    );
  }

  Future<void> commit({
    required String organizationId,
    required String commandId,
    required String actorEmployeeId,
    required String permissionRevision,
    required DateTime occurredAt,
    required List<WorkRecordMutation> mutations,
    List<PrototypeFinancialEntry> financialEntries = const [],
    List<WorkRecordMutation> unchangedRecords = const [],
    LocalDraftCheckpoint? draftCheckpoint,
    Future<void> Function()? validateBeforeCommit,
  }) async {
    if (actorEmployeeId.trim().isEmpty || permissionRevision.trim().isEmpty) {
      throw ArgumentError(
        'Work mutations require actor and authorization provenance.',
      );
    }
    for (final mutation in mutations) {
      final record = mutation.record;
      if (record.id.trim().isEmpty ||
          record.createdByEmployeeId.trim().isEmpty ||
          record.revision < 1) {
        throw ArgumentError(
          'Work record identity and document revision are required.',
        );
      }
    }
    await database.transaction(() async {
      await validateBeforeCommit?.call();
      for (final mutation in [...mutations, ...unchangedRecords]) {
        final deleted = await LocalRecordStore(database).read(
          organizationId: organizationId,
          domain: 'work/deleted',
          ownerIds: {mutation.record.createdByEmployeeId},
          recordIds: {mutation.record.id},
        );
        if (deleted.isNotEmpty) {
          throw const LocalRecordConflict('This draft was deleted.');
        }
      }

      // Equality against a session cache is not a current SQL acknowledgment.
      // Validate unchanged submitted records before consuming their input.
      for (final expected in unchangedRecords) {
        final current = await find(
          organizationId: organizationId,
          recordId: expected.record.id,
          visibleCreatorIds: {expected.record.createdByEmployeeId},
        );
        if (current == null ||
            current.storageRevision != expected.expectedStorageRevision) {
          throw const LocalRecordConflict(
            'The saved Work record changed. Your recovery input has been preserved.',
          );
        }
      }
      if (draftCheckpoint != null &&
          !await LocalDraftStore(database).consumeIfUnchanged(
            organizationId: organizationId,
            domain: draftCheckpoint.domain,
            draftId: draftCheckpoint.draftId,
            ownerId: actorEmployeeId,
            expectedRevision: draftCheckpoint.revision,
          )) {
        throw const LocalRecordConflict(
          'This draft changed. Its latest saved input was preserved.',
        );
      }
      if (mutations.isEmpty &&
          financialEntries.isEmpty &&
          (draftCheckpoint != null || unchangedRecords.isNotEmpty)) {
        return;
      }
      await LocalRecordStore(database).commit(
        organizationId: organizationId,
        commandId: commandId,
        occurredAt: occurredAt,
        writes: [
          ...mutations.map(
            (mutation) => LocalRecordWrite(
              domain: 'work/records',
              recordId: mutation.record.id,
              ownerId: mutation.record.createdByEmployeeId,
              expectedRevision: mutation.expectedStorageRevision,
              payload: {
                ...encodeWorkRecord(mutation.record),
                'mutationActor': actorEmployeeId,
                'permissionRevision': permissionRevision,
              },
            ),
          ),
          ...financialEntries.map(
            (entry) => LocalRecordWrite(
              domain: 'work/ledger',
              recordId: entry.id,
              ownerId: actorEmployeeId,
              expectedRevision: 0,
              payload: {
                ...encodeFinancialEntry(entry),
                'mutationActor': actorEmployeeId,
                'permissionRevision': permissionRevision,
              },
            ),
          ),
        ],
      );
    });
  }

  Future<List<PrototypeFinancialEntry>> queryFinancialEntries({
    required String organizationId,
    required Set<String> visibleActorIds,
  }) async {
    final rows = await LocalRecordStore(database).read(
      organizationId: organizationId,
      domain: 'work/ledger',
      ownerIds: visibleActorIds,
    );
    return List.unmodifiable(
      rows.map((row) {
        final entry = decodeFinancialEntry(
          LocalRecordStore(database).decode(row),
        );
        if (entry.id != row.recordId) {
          throw StateError('Financial identity mismatch.');
        }
        return entry;
      }),
    );
  }

  /// Used to reconcile a failed/stale command, without allowing a caller to
  /// discover another creator's record by guessing its identity.
  Future<PersistedWorkRecord?> find({
    required String organizationId,
    required String recordId,
    required Set<String> visibleCreatorIds,
  }) async {
    if (visibleCreatorIds.isEmpty) return null;
    final deleted = await LocalRecordStore(database).read(
      organizationId: organizationId,
      domain: 'work/deleted',
      ownerIds: visibleCreatorIds,
      recordIds: {recordId},
    );
    if (deleted.isNotEmpty) return null;
    final row =
        await (database.select(database.localRecords)..where(
              (row) =>
                  row.organizationId.equals(organizationId) &
                  row.domain.equals('work/records') &
                  row.recordId.equals(recordId) &
                  row.ownerId.isIn(visibleCreatorIds),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    final record = decodeWorkRecord(LocalRecordStore(database).decode(row));
    if (record.id != row.recordId ||
        record.createdByEmployeeId != row.ownerId) {
      throw StateError('Saved Work record identity is inconsistent.');
    }
    return PersistedWorkRecord(record: record, storageRevision: row.revision);
  }
}
