part of 'local_receipt_draft_repository.dart';

extension ReceiptSubmissionStaging on LocalReceiptDraftRepository {
  /// Checks app-owned bytes before preparing confirmation. This is not a
  /// filesystem transaction: external changes after verification remain possible.
  Future<void> verifySubmissionEvidence({
    required String draftId,
    required ReceiptDraftAccess access,
    required int expectedRevision,
  }) async {
    final receipt = await find(draftId: draftId, access: access);
    if (receipt == null || receipt.lifecycle.revision != expectedRevision) {
      throw const ReceiptDraftStorageException('Receipt review is stale.');
    }
    if (receipt.activeEvidence.isEmpty) return;
    final root = await _evidenceDirectory.resolveSymbolicLinks();
    for (final item in receipt.activeEvidence) {
      if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(item.evidenceId)) {
        throw const ReceiptDraftStorageException('Invalid evidence identity.');
      }
      final extension = item.kind == ReceiptDraftEvidenceKind.pdf
          ? 'pdf'
          : 'image';
      final expected =
          '$root/${_safeFolder(draftId)}/${item.evidenceId}.$extension';
      final file = File(
        _resolveRetainedPath?.call(item.localPath) ?? item.localPath,
      );
      if (await file.resolveSymbolicLinks() != expected) {
        throw const ReceiptDraftStorageException(
          'Receipt evidence is outside its retained location.',
        );
      }
      final digest = await _validatedDigest(file);
      if (digest.byteLength != item.byteLength ||
          digest.sha256 != item.sha256) {
        throw const ReceiptDraftStorageException(
          'Retained receipt evidence does not match its recorded contents.',
        );
      }
    }
  }

  /// Submission staging can close existing drafts, but cannot import, remove
  /// or reorder evidence files. Caller holds the Expense write queue first.
  Future<R> withStagedSubmission<R>(
    Future<R> Function(StagedDomainMutation<LocalReceiptDraftRepository>)
    action,
  ) => _withStagedReceiptChanges(action, evidenceMetadata: false);

  /// No imports or physical deletions: only existing evidence metadata changes.
  Future<R> withStagedEvidenceReview<R>(
    Future<R> Function(StagedDomainMutation<LocalReceiptDraftRepository>)
    action,
  ) => _withStagedReceiptChanges(action, evidenceMetadata: true);

  /// Prepares imported originals before the SQL group commit. A failed commit
  /// leaves only unreferenced files, never a published receipt or acknowledgment.
  Future<R> withStagedMediaImport<R>(
    Future<R> Function(StagedDomainMutation<LocalReceiptDraftRepository>)
    action,
  ) => _withStagedReceiptChanges(
    action,
    evidenceMetadata: false,
    importFiles: true,
  );

  Future<R> _withStagedReceiptChanges<R>(
    Future<R> Function(StagedDomainMutation<LocalReceiptDraftRepository>)
    action, {
    required bool evidenceMetadata,
    bool importFiles = false,
  }) => _writes.run(() async {
    final storage = _snapshotStore;
    if (storage is! SqliteDomainSnapshotStore<List<StoredReceiptDraft>>) {
      throw const ReceiptDraftStorageException(
        'Atomic submission requires SQLite storage.',
      );
    }
    final buffer = DomainMutationBuffer(storage.value);
    final staged = LocalReceiptDraftRepository._(
      storageDirectory: _evidenceDirectory.parent,
      snapshotStore: buffer,
      records: {for (final record in buffer.value) record.draftId: record},
      resolveRetainedPath: _resolveRetainedPath,
      allowEvidenceWrites: importFiles,
      allowEvidenceMetadata: evidenceMetadata,
    );
    return action(
      StagedDomainMutation(
        repository: staged,
        prepare: () => storage.prepare(buffer.value),
        publishCommitted: () {
          _records = {
            for (final record in storage.value) record.draftId: record,
          };
        },
      ),
    );
  });

  void _requireEvidenceWrites() {
    if (!_allowEvidenceWrites) {
      throw const ReceiptDraftStorageException(
        'Evidence changes cannot be staged during submission.',
      );
    }
  }
}
