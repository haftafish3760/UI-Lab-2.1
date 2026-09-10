part of 'sqlite_domain_snapshot_store.dart';

/// A validated domain write with deferred cache publication. Only the group
/// commit function can apply it; preparation alone never acknowledges a save.
class PreparedDomainSnapshotChange {
  PreparedDomainSnapshotChange._(
    this.database,
    this.scope,
    this._validate,
    this._apply,
    this._publish,
  );

  final LocalDatabase database;
  final (String, String) scope;
  final void Function() _validate;
  final Future<void> Function() _apply;
  final void Function() _publish;
}

final _preparedCommitQueues = Expando<SerializedAsyncActions>();

/// Owns the transaction: callers must not wrap this in another transaction.
/// Serializes commits and cache publication on this database connection.
Future<void> commitPreparedDomainChanges(
  List<PreparedDomainSnapshotChange> changes, {
  required String organizationId,
  String? ownerId,
  LocalDraftCheckpoint? checkpoint,
  LocalMediaPickerRequest? mediaRequest,
}) {
  if (changes.isEmpty) throw ArgumentError('A commit needs prepared changes.');
  final plans = List<PreparedDomainSnapshotChange>.unmodifiable(changes);
  final database = plans.first.database;
  if (plans.any(
        (plan) =>
            !identical(plan.database, database) ||
            plan.scope.$1 != organizationId,
      ) ||
      plans.map((plan) => plan.scope).toSet().length != plans.length ||
      (checkpoint != null &&
          ((ownerId ?? '').trim().isEmpty || checkpoint.revision < 1)) ||
      (mediaRequest != null &&
          (mediaRequest.organizationId != organizationId ||
              mediaRequest.ownerId != ownerId ||
              mediaRequest.retainedAttachmentIds == null))) {
    throw ArgumentError(
      'Prepared changes must have one database, one organization and distinct domains.',
    );
  }
  final queue = _preparedCommitQueues[database] ??= SerializedAsyncActions();
  return queue.run(() async {
    try {
      for (final plan in plans) {
        plan._validate();
      }
      await database.transaction(() async {
        for (final plan in plans) {
          await plan._apply();
        }
        if (mediaRequest != null) {
          await LocalMediaPickerRequestStore(database).consume(
            request: mediaRequest,
            organizationId: organizationId,
            ownerId: ownerId!,
            commit: () async {},
          );
        }
        if (checkpoint != null) {
          final consumed = await LocalDraftStore(database).consumeIfUnchanged(
            organizationId: organizationId,
            ownerId: ownerId!,
            domain: checkpoint.domain,
            draftId: checkpoint.draftId,
            expectedRevision: checkpoint.revision,
          );
          if (!consumed) {
            throw const LocalRecordConflict(
              'The draft changed before confirmation.',
            );
          }
        }
      });
    } on Object {
      throw const DualSlotSnapshotWriteException(
        'The local database did not accept this save. Saved data was preserved; reload before retrying.',
      );
    }
    for (final plan in plans) {
      plan._publish();
    }
  });
}
