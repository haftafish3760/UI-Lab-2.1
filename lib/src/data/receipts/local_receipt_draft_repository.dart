import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../storage/dual_slot_json_store.dart';
import '../storage/domain_snapshot_store.dart';
import '../storage/serialized_async_actions.dart';
import '../storage/sqlite_domain_snapshot_store.dart';
import '../storage/staged_domain_mutation.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_repository.dart';

part 'receipt_submission_staging.dart';
part 'receipt_draft_snapshot_decoding.dart';

typedef ReceiptDraftSnapshotWriter = DualSlotSnapshotWriter;

class LocalReceiptDraftRepository implements ReceiptDraftRepository {
  LocalReceiptDraftRepository._({
    required Directory storageDirectory,
    required this._snapshotStore,
    required this._records,
    this._allowEvidenceWrites = true,
    this._allowEvidenceMetadata = false,
    this._resolveRetainedPath,
  }) : _evidenceDirectory = Directory.fromUri(
         storageDirectory.uri.resolve('evidence/'),
       );

  factory LocalReceiptDraftRepository.withStorage(
    DomainSnapshotStore<List<StoredReceiptDraft>> storage,
    Directory storageDirectory, {
    String Function(String)? resolveRetainedPath,
  }) => LocalReceiptDraftRepository._(
    snapshotStore: storage,
    storageDirectory: storageDirectory,
    resolveRetainedPath: resolveRetainedPath,
    records: {for (final item in storage.value) item.draftId: item},
  );

  static const int schemaVersion = 1;
  static const String directoryName = 'receipt_draft_records';

  final String Function(String)? _resolveRetainedPath;
  final bool _allowEvidenceWrites;
  final bool _allowEvidenceMetadata;
  final Directory _evidenceDirectory;
  final DomainSnapshotStore<List<StoredReceiptDraft>> _snapshotStore;
  Map<String, StoredReceiptDraft> _records;
  final _writes = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _writes.pauseAndDrain();

  bool get supportsAtomicSubmission =>
      _snapshotStore is SqliteDomainSnapshotStore<List<StoredReceiptDraft>>;

  bool get recoveredFromDamagedSnapshot =>
      _snapshotStore.recoveredFromDamagedSnapshot;

  static Future<LocalReceiptDraftRepository> open(
    Directory storageDirectory, {
    ReceiptDraftSnapshotWriter? snapshotWriter,
  }) async {
    try {
      final store = await DualSlotJsonStore.open<List<StoredReceiptDraft>>(
        directory: storageDirectory,
        fileStem: 'receipt-drafts',
        schemaVersion: schemaVersion,
        emptyValue: const [],
        encodePayload: (records) => {
          'records': records.map((record) => record.toJson()).toList(),
        },
        decodePayload: _decodeReceiptDrafts,
        snapshotWriter: snapshotWriter,
      );
      return LocalReceiptDraftRepository._(
        storageDirectory: storageDirectory,
        snapshotStore: store,
        records: {for (final item in store.value) item.draftId: item},
      );
    } on DualSlotSnapshotCorruptionException catch (error) {
      throw ReceiptDraftStorageCorruptionException(error.message);
    }
  }

  @override
  Future<List<StoredReceiptDraft>> query(ReceiptDraftQuery query) async {
    final result = _records.values.where(query.matches).toList()
      ..sort(_compareDrafts);
    return List.unmodifiable(result);
  }

  @override
  Future<StoredReceiptDraft?> find({
    required String draftId,
    required ReceiptDraftAccess access,
    bool includeClosed = false,
  }) async {
    final draft = _records[draftId];
    if (draft == null || !access.allows(draft)) return null;
    if (!includeClosed && draft.state != ReceiptDraftState.inProgress) {
      return null;
    }
    return draft;
  }

  @override
  Future<StoredReceiptDraft> create({
    required StoredReceiptDraft draft,
    required List<ReceiptEvidenceImport> evidence,
    required ReceiptDraftMutationContext context,
  }) => _writes.run(() async {
    _requireEvidenceWrites();
    if (_records.containsKey(draft.draftId)) {
      throw ReceiptDraftAlreadyExistsException(
        'Receipt draft ${draft.draftId} already exists.',
      );
    }
    if (draft.lifecycle.revision != 1 ||
        draft.state != ReceiptDraftState.inProgress ||
        draft.evidence.isNotEmpty ||
        draft.auditTrail.isNotEmpty) {
      throw const ReceiptDraftRevisionConflictException(
        'A new receipt draft must begin empty at revision 1.',
      );
    }
    final imported = await _mergeEvidence(
      draftId: draft.draftId,
      current: const [],
      retainedActiveIds: const [],
      imports: evidence,
      occurredAtUtc: context.occurredAtUtc,
    );
    final created = draft.copyWith(
      evidence: imported.evidence,
      lifecycle: ReceiptDraftLifecycle(
        revision: 1,
        createdAtUtc: context.occurredAtUtc,
        updatedAtUtc: context.occurredAtUtc,
      ),
      auditTrail: [
        context.audit(
          action: ReceiptDraftAuditAction.created,
          fromRevision: null,
          toRevision: 1,
        ),
      ],
    );
    try {
      await _persist({..._records, draft.draftId: created});
      return created;
    } on Object {
      await _removeNewFiles(imported.createdFiles);
      rethrow;
    }
  });

  @override
  Future<StoredReceiptDraft> update({
    required StoredReceiptDraft draft,
    required List<ReceiptEvidenceImport> addedEvidence,
    required int expectedRevision,
    required ReceiptDraftMutationContext context,
  }) => _writes.run(() async {
    if (!_allowEvidenceMetadata || addedEvidence.isNotEmpty) {
      _requireEvidenceWrites();
    }
    final current = _requireCurrent(draft.draftId, expectedRevision);
    _requireOpen(current);
    if (draft.organizationId != current.organizationId ||
        draft.ownerEmployeeId != current.ownerEmployeeId ||
        draft.state != ReceiptDraftState.inProgress ||
        draft.submittedExpenseId != null) {
      throw const ReceiptDraftRevisionConflictException(
        'Receipt draft ownership and state cannot be rewritten.',
      );
    }
    final retained = draft.activeEvidence
        .map((item) => item.evidenceId)
        .toList(growable: false);
    final currentActive = {
      for (final item in current.activeEvidence) item.evidenceId,
    };
    if (retained.any((id) => !currentActive.contains(id))) {
      throw const ReceiptDraftRevisionConflictException(
        'Receipt evidence changed after this draft was opened.',
      );
    }
    final imported = await _mergeEvidence(
      draftId: draft.draftId,
      current: current.evidence,
      retainedActiveIds: retained,
      imports: addedEvidence,
      occurredAtUtc: context.occurredAtUtc,
    );
    final updated = draft.copyWith(
      evidence: imported.evidence,
      lifecycle: current.lifecycle.next(context.occurredAtUtc),
      auditTrail: [
        ...current.auditTrail,
        context.audit(
          action: ReceiptDraftAuditAction.updated,
          fromRevision: current.lifecycle.revision,
          toRevision: current.lifecycle.revision + 1,
        ),
      ],
    );
    try {
      await _persist({..._records, draft.draftId: updated});
      return updated;
    } on Object {
      await _removeNewFiles(imported.createdFiles);
      rethrow;
    }
  });

  @override
  Future<StoredReceiptDraft> submit({
    required String draftId,
    required String expenseId,
    required int expectedRevision,
    required ReceiptDraftMutationContext context,
  }) => _close(
    draftId: draftId,
    expectedRevision: expectedRevision,
    state: ReceiptDraftState.submitted,
    expenseId: expenseId,
    action: ReceiptDraftAuditAction.submitted,
    context: context,
  );

  @override
  Future<StoredReceiptDraft> discard({
    required String draftId,
    required int expectedRevision,
    required ReceiptDraftMutationContext context,
  }) => _close(
    draftId: draftId,
    expectedRevision: expectedRevision,
    state: ReceiptDraftState.discarded,
    action: ReceiptDraftAuditAction.discarded,
    context: context,
  );

  Future<StoredReceiptDraft> _close({
    required String draftId,
    required int expectedRevision,
    required ReceiptDraftState state,
    required ReceiptDraftAuditAction action,
    required ReceiptDraftMutationContext context,
    String? expenseId,
  }) => _writes.run(() async {
    final current = _requireCurrent(draftId, expectedRevision);
    _requireOpen(current);
    final closed = current.copyWith(
      state: state,
      submittedExpenseId: expenseId,
      lifecycle: current.lifecycle.next(context.occurredAtUtc),
      auditTrail: [
        ...current.auditTrail,
        context.audit(
          action: action,
          fromRevision: current.lifecycle.revision,
          toRevision: current.lifecycle.revision + 1,
        ),
      ],
    );
    await _persist({..._records, draftId: closed});
    return closed;
  });

  StoredReceiptDraft _requireCurrent(String id, int expectedRevision) {
    final current = _records[id];
    if (current == null) {
      throw ReceiptDraftNotFoundException('Receipt draft $id does not exist.');
    }
    if (current.lifecycle.revision != expectedRevision) {
      throw ReceiptDraftRevisionConflictException(
        'Receipt draft $id changed after it was opened.',
      );
    }
    return current;
  }

  void _requireOpen(StoredReceiptDraft draft) {
    if (draft.state != ReceiptDraftState.inProgress) {
      throw ReceiptDraftRevisionConflictException(
        'Receipt draft ${draft.draftId} is already closed.',
      );
    }
  }

  Future<_EvidenceMerge> _mergeEvidence({
    required String draftId,
    required List<ReceiptDraftEvidence> current,
    required List<String> retainedActiveIds,
    required List<ReceiptEvidenceImport> imports,
    required DateTime occurredAtUtc,
  }) async {
    final byId = {for (final item in current) item.evidenceId: item};
    final next = <ReceiptDraftEvidence>[];
    var order = 0;
    for (final id in retainedActiveIds) {
      next.add(
        byId[id]!.copyWith(
          order: order++,
          state: ReceiptDraftEvidenceState.active,
          removedAtUtc: null,
        ),
      );
    }
    for (final item in current) {
      if (retainedActiveIds.contains(item.evidenceId)) continue;
      next.add(
        item.isActive
            ? item.copyWith(
                state: ReceiptDraftEvidenceState.removed,
                removedAtUtc: occurredAtUtc,
              )
            : item,
      );
    }

    final createdFiles = <File>[];
    for (var index = 0; index < imports.length; index++) {
      final source = File(imports[index].sourcePath);
      final digest = await _validatedDigest(source);
      final duplicateIndex = next.indexWhere(
        (item) =>
            !item.isActive &&
            item.sha256 == digest.sha256 &&
            item.kind == imports[index].kind,
      );
      if (duplicateIndex >= 0) {
        final duplicate = next[duplicateIndex];
        next.removeAt(duplicateIndex);
        next.insert(
          order,
          duplicate.copyWith(
            order: order++,
            state: ReceiptDraftEvidenceState.active,
            removedAtUtc: null,
          ),
        );
        continue;
      }
      final evidenceId = _evidenceId(
        draftId,
        digest.sha256,
        occurredAtUtc,
        index,
      );
      final target = await _copyEvidence(
        draftId: draftId,
        evidenceId: evidenceId,
        kind: imports[index].kind,
        source: source,
        expectedSha256: digest.sha256,
      );
      createdFiles.add(target);
      next.insert(
        order,
        ReceiptDraftEvidence(
          evidenceId: evidenceId,
          originalName: imports[index].originalName,
          kind: imports[index].kind,
          localPath: target.path,
          sha256: digest.sha256,
          byteLength: digest.byteLength,
          order: order++,
        ),
      );
    }
    return _EvidenceMerge(evidence: next, createdFiles: createdFiles);
  }

  Future<_FileDigest> _validatedDigest(File source) async {
    if (!await source.exists()) {
      throw ReceiptDraftStorageException(
        'Receipt evidence ${source.path} is no longer available.',
      );
    }
    final length = await source.length();
    if (length < 1) {
      throw const ReceiptDraftStorageException(
        'An empty file cannot be retained as receipt evidence.',
      );
    }
    final digest = await sha256.bind(source.openRead()).first;
    return _FileDigest(sha256: digest.toString(), byteLength: length);
  }

  Future<File> _copyEvidence({
    required String draftId,
    required String evidenceId,
    required ReceiptDraftEvidenceKind kind,
    required File source,
    required String expectedSha256,
  }) async {
    final folder = Directory.fromUri(
      _evidenceDirectory.uri.resolve('${_safeFolder(draftId)}/'),
    );
    await folder.create(recursive: true);
    final extension = kind == ReceiptDraftEvidenceKind.pdf ? 'pdf' : 'image';
    final target = File.fromUri(folder.uri.resolve('$evidenceId.$extension'));
    final temporary = File('${target.path}.tmp');
    try {
      if (await temporary.exists()) await temporary.delete();
      await source.copy(temporary.path);
      final copied = await _validatedDigest(temporary);
      if (copied.sha256 != expectedSha256) {
        throw const ReceiptDraftStorageException(
          'Receipt evidence changed while it was being retained.',
        );
      }
      // File.copy completing does not acknowledge a flush to disk. Flush the
      // verified temporary file before publishing its final path and SQL row.
      final retained = await temporary.open(mode: FileMode.append);
      try {
        await retained.flush();
      } finally {
        await retained.close();
      }
      if (await target.exists()) await target.delete();
      return await temporary.rename(target.path);
    } on ReceiptDraftRepositoryException {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    } on Object catch (error) {
      if (await temporary.exists()) await temporary.delete();
      throw ReceiptDraftStorageException(
        'Receipt evidence was not retained. ($error)',
      );
    }
  }

  Future<void> _persist(Map<String, StoredReceiptDraft> next) async {
    final records = next.values.toList()
      ..sort((a, b) => a.draftId.compareTo(b.draftId));
    try {
      await _snapshotStore.persist(records);
    } on DualSlotSnapshotWriteException catch (error) {
      throw ReceiptDraftStorageException(error.message);
    }
    _records = next;
  }
}

Future<void> _removeNewFiles(Iterable<File> files) async {
  for (final file in files) {
    try {
      if (await file.exists()) await file.delete();
    } on Object {
      // The unreferenced file is retained rather than risking existing evidence.
    }
  }
}

String _safeFolder(String draftId) =>
    sha256.convert(utf8.encode(draftId)).toString().substring(0, 24);

String _evidenceId(
  String draftId,
  String digest,
  DateTime occurredAtUtc,
  int index,
) =>
    '${_safeFolder(draftId)}-'
    '${occurredAtUtc.microsecondsSinceEpoch}-$index-${digest.substring(0, 12)}';

class _EvidenceMerge {
  const _EvidenceMerge({required this.evidence, required this.createdFiles});
  final List<ReceiptDraftEvidence> evidence;
  final List<File> createdFiles;
}

class _FileDigest {
  const _FileDigest({required this.sha256, required this.byteLength});
  final String sha256;
  final int byteLength;
}
