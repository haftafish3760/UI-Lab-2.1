import 'dart:io';

import '../storage/dual_slot_json_store.dart';
import '../storage/domain_snapshot_store.dart';
import '../storage/serialized_async_actions.dart';
import '../storage/sqlite_domain_snapshot_store.dart';
import '../storage/staged_domain_mutation.dart';
import 'expense_record.dart';
import 'expense_repository.dart';

typedef ExpenseSnapshotWriter =
    Future<void> Function(File target, List<int> bytes);

class LocalExpenseRepository
    implements ExpenseRepository, ExpenseDraftConfirmationRepository {
  LocalExpenseRepository._({
    required this._snapshotStore,
    required this._records,
  });

  factory LocalExpenseRepository.withStorage(
    DomainSnapshotStore<List<StoredExpenseRecord>> storage,
  ) => LocalExpenseRepository._(
    snapshotStore: storage,
    records: {for (final item in storage.value) item.expenseId: item},
  );

  static const int schemaVersion = 1;
  static const String directoryName = 'expense_records';

  final DomainSnapshotStore<List<StoredExpenseRecord>> _snapshotStore;
  Map<String, StoredExpenseRecord> _records;
  final _writes = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _writes.pauseAndDrain();

  bool get recoveredFromDamagedSnapshot =>
      _snapshotStore.recoveredFromDamagedSnapshot;

  @override
  bool get supportsDraftConfirmation =>
      _snapshotStore
          is DraftConfirmingDomainSnapshotStore<List<StoredExpenseRecord>>;

  /// Hold this queue before the receipt queue when composing submission.
  Future<R> withStagedWrites<R>(
    Future<R> Function(StagedDomainMutation<LocalExpenseRepository>) action,
  ) => _writes.run(() async {
    final storage = _snapshotStore;
    if (storage is! SqliteDomainSnapshotStore<List<StoredExpenseRecord>>) {
      throw const ExpenseStorageException(
        'Atomic submission requires SQLite storage.',
      );
    }
    final buffer = DomainMutationBuffer(storage.value);
    return action(
      StagedDomainMutation(
        repository: LocalExpenseRepository.withStorage(buffer),
        prepare: () => storage.prepare(buffer.value),
        publishCommitted: () {
          _records = {
            for (final record in storage.value) record.expenseId: record,
          };
        },
      ),
    );
  });

  static Future<LocalExpenseRepository> open(
    Directory storageDirectory, {
    ExpenseSnapshotWriter? snapshotWriter,
  }) async {
    try {
      final snapshots = await DualSlotJsonStore.open<List<StoredExpenseRecord>>(
        directory: storageDirectory,
        fileStem: 'expenses',
        schemaVersion: schemaVersion,
        emptyValue: const [],
        encodePayload: (records) => {
          'records': records.map((record) => record.toJson()).toList(),
        },
        decodePayload: _decodeExpenseRecords,
        snapshotWriter: snapshotWriter,
      );
      return LocalExpenseRepository._(
        snapshotStore: snapshots,
        records: {
          for (final record in snapshots.value) record.expenseId: record,
        },
      );
    } on DualSlotSnapshotCorruptionException catch (error) {
      throw ExpenseStorageCorruptionException(error.message);
    }
  }

  @override
  Future<List<StoredExpenseRecord>> query(ExpenseQuery query) async {
    final result = _records.values.where(query.matches).toList()
      ..sort(_compareRecords);
    return List.unmodifiable(result);
  }

  @override
  Future<StoredExpenseRecord?> findById({
    required String expenseId,
    required ExpenseAccess access,
    bool includeDeleted = false,
  }) async {
    final record = _records[expenseId];
    if (record == null || !access.allows(record)) return null;
    if (!includeDeleted && record.lifecycle.isDeleted) return null;
    return record;
  }

  @override
  Future<StoredExpenseRecord> create(
    StoredExpenseRecord record, {
    required ExpenseMutationContext context,
  }) => _writes.run(() async {
    if (_records.containsKey(record.expenseId)) {
      throw ExpenseAlreadyExistsException(
        'Expense ${record.expenseId} already exists.',
      );
    }
    if (record.lifecycle.revision != 1 || record.lifecycle.isDeleted) {
      throw const ExpenseRevisionConflictException(
        'A new Expense must begin at revision 1 and cannot be deleted.',
      );
    }
    final created = record.copyWith(
      lifecycle: ExpenseLifecycle(
        revision: 1,
        createdAtUtc: context.occurredAtUtc,
        updatedAtUtc: context.occurredAtUtc,
      ),
      auditTrail: [
        context.auditEvent(
          action: ExpenseAuditAction.created,
          fromRevision: null,
          toRevision: 1,
        ),
      ],
    );
    final next = {..._records, record.expenseId: created};
    await _persist(
      next,
      context: context,
      organizationId: created.organizationId,
    );
    return created;
  });

  @override
  Future<StoredExpenseRecord> update(
    StoredExpenseRecord record, {
    required int expectedRevision,
    required ExpenseMutationContext context,
    ExpenseAuditAction auditAction = ExpenseAuditAction.updated,
  }) => _writes.run(() async {
    final current = _requireCurrent(record.expenseId, expectedRevision);
    if (record.organizationId != current.organizationId ||
        record.createdByEmployeeId != current.createdByEmployeeId) {
      throw const ExpenseRevisionConflictException(
        'Expense organization and creator identity cannot be rewritten.',
      );
    }
    if (current.lifecycle.isDeleted) {
      throw ExpenseRevisionConflictException(
        'Deleted Expense ${record.expenseId} must be restored before editing.',
      );
    }
    final updated = record.copyWith(
      lifecycle: current.lifecycle.nextRevision(
        updatedAtUtc: context.occurredAtUtc,
      ),
      priorVersions: [
        ...current.priorVersions,
        ExpenseRevisionSnapshot.fromRecord(current),
      ],
      auditTrail: [
        ...current.auditTrail,
        context.auditEvent(
          action: auditAction,
          fromRevision: current.lifecycle.revision,
          toRevision: current.lifecycle.revision + 1,
        ),
      ],
    );
    final next = {..._records, record.expenseId: updated};
    await _persist(
      next,
      context: context,
      organizationId: updated.organizationId,
    );
    return updated;
  });

  @override
  Future<StoredExpenseRecord> softDelete({
    required String expenseId,
    required int expectedRevision,
    required ExpenseMutationContext context,
  }) => _writes.run(() async {
    final current = _requireCurrent(expenseId, expectedRevision);
    if (current.lifecycle.isDeleted) {
      throw ExpenseRevisionConflictException(
        'Expense $expenseId is already deleted.',
      );
    }
    final deleted = current.copyWith(
      lifecycle: current.lifecycle.nextRevision(
        updatedAtUtc: context.occurredAtUtc,
        deletedAtUtc: context.occurredAtUtc,
      ),
      auditTrail: [
        ...current.auditTrail,
        context.auditEvent(
          action: ExpenseAuditAction.deleted,
          fromRevision: current.lifecycle.revision,
          toRevision: current.lifecycle.revision + 1,
        ),
      ],
    );
    final next = {..._records, expenseId: deleted};
    await _persist(
      next,
      context: context,
      organizationId: deleted.organizationId,
    );
    return deleted;
  });

  @override
  Future<StoredExpenseRecord> restore({
    required String expenseId,
    required int expectedRevision,
    required ExpenseMutationContext context,
  }) => _writes.run(() async {
    final current = _requireCurrent(expenseId, expectedRevision);
    if (!current.lifecycle.isDeleted) {
      throw ExpenseRevisionConflictException(
        'Expense $expenseId is not deleted.',
      );
    }
    final restored = current.copyWith(
      lifecycle: current.lifecycle.nextRevision(
        updatedAtUtc: context.occurredAtUtc,
        deletedAtUtc: null,
      ),
      auditTrail: [
        ...current.auditTrail,
        context.auditEvent(
          action: ExpenseAuditAction.restored,
          fromRevision: current.lifecycle.revision,
          toRevision: current.lifecycle.revision + 1,
        ),
      ],
    );
    final next = {..._records, expenseId: restored};
    await _persist(
      next,
      context: context,
      organizationId: restored.organizationId,
    );
    return restored;
  });

  @override
  Future<int> approvedTotalMinorUnits(ExpenseQuery query) async => _records
      .values
      .where(query.matches)
      .where(
        (record) =>
            record.approval.entersApprovedTotals && record.total != null,
      )
      .fold<int>(0, (sum, record) => sum + record.total!.minorUnits);

  StoredExpenseRecord _requireCurrent(String id, int expectedRevision) {
    final current = _records[id];
    if (current == null) {
      throw ExpenseNotFoundException('Expense $id does not exist.');
    }
    if (current.lifecycle.revision != expectedRevision) {
      throw ExpenseRevisionConflictException(
        'Expense $id changed after it was opened.',
      );
    }
    return current;
  }

  Future<void> _persist(
    Map<String, StoredExpenseRecord> next, {
    ExpenseMutationContext? context,
    String? organizationId,
  }) async {
    final records = next.values.toList()
      ..sort((a, b) => a.expenseId.compareTo(b.expenseId));
    try {
      final checkpoint = context?.draftCheckpoint;
      final storage = _snapshotStore;
      if (checkpoint == null) {
        await storage.persist(records);
      } else if (storage
              is DraftConfirmingDomainSnapshotStore<
                List<StoredExpenseRecord>
              > &&
          organizationId != null) {
        await storage.persistWithDraft(
          records,
          organizationId: organizationId,
          ownerId: context!.actorEmployeeId,
          checkpoint: checkpoint,
        );
      } else {
        throw const ExpenseStorageException(
          'This storage cannot safely confirm a saved draft.',
        );
      }
    } on DualSlotSnapshotWriteException catch (error) {
      throw ExpenseStorageException(error.message);
    }
    _records = next;
  }
}

List<StoredExpenseRecord> _decodeExpenseRecords(Map<String, Object?> payload) {
  final recordValues = payload['records'];
  if (recordValues is! List) {
    throw const FormatException('Invalid Expense record list.');
  }
  final records = recordValues
      .map(
        (value) => StoredExpenseRecord.fromJson(
          (value as Map).cast<String, Object?>(),
        ),
      )
      .toList();
  if (records.map((record) => record.expenseId).toSet().length !=
      records.length) {
    throw const FormatException('Duplicate Expense identity.');
  }
  return List.unmodifiable(records);
}

int _compareRecords(StoredExpenseRecord a, StoredExpenseRecord b) {
  final date = b.expenseDate.compareTo(a.expenseDate);
  if (date != 0) return date;
  final time = (b.expenseTimeMinutes ?? -1).compareTo(
    a.expenseTimeMinutes ?? -1,
  );
  if (time != 0) return time;
  return a.expenseId.compareTo(b.expenseId);
}
