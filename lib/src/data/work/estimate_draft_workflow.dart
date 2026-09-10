import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_recovery_query.dart';
import '../storage/local_record_identity.dart';
import 'estimate_confirmation.dart';
import 'estimate_draft_controller.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';

extension EstimateDraftWorkflow on WorkPersistenceSession {
  /// Validate a selected workflow before a presentation takes ownership.
  void validateEstimateHandoff(
    EstimateDraftController controller, {
    required String creatorId,
    String? existingRecordId,
  }) {
    final input = controller.recoveredInput;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/estimate-editor' ||
        input == null ||
        input.creatorId != creatorId ||
        input.baseRecord?.id != existingRecordId) {
      throw StateError('Selected estimate belongs to another workflow.');
    }
    _requireEstimateCreator(input.creatorId);
    if (existingRecordId != null) editableEstimate(existingRecordId);
  }

  void _requireEstimateCreator(String creatorId) {
    if (!permissions.editableKinds.contains(WorkRecordKind.estimate) ||
        !permissions.visibleCreatorIds.contains(creatorId) ||
        (creatorId != permissions.actorEmployeeId &&
            !permissions.canManageOtherCreators)) {
      throw StateError('Estimate creation is unavailable.');
    }
  }

  DraftRecoveryQuery estimateDraftRecovery(String creatorId) {
    _requireEstimateCreator(creatorId);
    return recoveryFor(WorkRecordKind.estimate);
  }

  WorkRecord editableEstimate(String recordId) {
    final record = records.where((r) => r.id == recordId).firstOrNull;
    if (record == null ||
        record.kind != WorkRecordKind.estimate ||
        !permissions.canEdit(record)) {
      throw StateError('Estimate unavailable.');
    }
    return record;
  }

  Future<EstimateDraftController> openEstimateDraft({
    required String creatorId,
    String? existingRecordId,
    String? recoveryDraftId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    if (existingRecordId == null) {
      _requireEstimateCreator(creatorId);
    } else {
      editableEstimate(existingRecordId);
      if (recoveryDraftId != null) {
        throw ArgumentError('Estimate edit recovery uses its record identity.');
      }
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: 'work/estimate-editor',
      draftId:
          recoverySelection?.draftId ??
          (existingRecordId == null
              ? recoveryDraftId ?? newLocalRecordIdentity('estimate-input')
              : 'edit-${permissions.actorEmployeeId}-$existingRecordId'),
    );
    void validateIdentity(EstimateDraftInput input) {
      _requireEstimateCreator(input.creatorId);
      if (input.estimateId.isEmpty ||
          input.baseStorageRevision < 0 ||
          input.baseRecord?.id != existingRecordId ||
          (existingRecordId != null && input.estimateId != existingRecordId)) {
        throw StateError('Estimate recovery identity is inconsistent.');
      }
    }

    try {
      await draft.initialize();
      requireActiveDraftOwner();
      recoverySelection?.verify(
        openedDomain: draft.domain,
        openedDraftId: draft.draftId,
        openedRevision: draft.savedRevision,
        hasInput: draft.input.isNotEmpty,
      );
      final controller = EstimateDraftController(
        draft,
        confirm: (input, checkpoint) async {
          validateIdentity(input);
          final estimate = buildConfirmedEstimate(input, now: DateTime.now());
          final saved = await save(
            records: [estimate],
            expectedStorageRevisions: {estimate.id: input.baseStorageRevision},
            draftCheckpoint: checkpoint,
          );
          return saved ? estimate : null;
        },
      );
      final recovered = controller.recoveredInput;
      if (recoveryDraftId != null && recovered == null) {
        throw StateError('Selected estimate recovery is unavailable.');
      }
      if (recovered != null) validateIdentity(recovered);
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
