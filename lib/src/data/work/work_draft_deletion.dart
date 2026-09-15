part of 'work_persistence_session.dart';

extension WorkDraftDeletion on WorkPersistenceSession {
  bool canDeleteDraft(WorkRecord record) =>
      permissions.canDeleteDrafts &&
      permissions.canEdit(record) &&
      (record.kind == WorkRecordKind.estimate
          ? record.resolvedEstimateStage == EstimateStage.draft
          : record.status == WorkRecordStatus.draft) &&
      record.customerSignature == null &&
      record.estimateDeliveries.isEmpty &&
      !_records.values.any((other) => other.sourceId == record.id) &&
      !_entries.values.any(
        (entry) =>
            entry.sourceId == record.id || entry.sourceId == record.number,
      );

  Future<bool> deleteDraft(WorkRecord record) {
    if (_disposed || !canDeleteDraft(record)) {
      return _reject('You cannot delete this draft.');
    }
    final expected = storageRevisionFor(record.id);
    _pendingWrites++;
    _notify();
    return _writes.run(() async {
      try {
        final current = _records[record.id];
        if (_disposed || current == null || !canDeleteDraft(current)) {
          throw StateError('This draft is no longer available to delete.');
        }
        await WorkDraftRepository(repository).delete(
          permissions: permissions,
          record: current,
          expectedRevision: expected,
        );
        _records.remove(record.id);
        _versions.remove(record.id);
        _failureMessage = null;
        return true;
      } on Object {
        _failureMessage =
            'The draft was not deleted. Refresh and try again; it may have changed.';
        return false;
      } finally {
        _pendingWrites--;
        _notify();
      }
    });
  }
}
