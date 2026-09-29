import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_recovery_query.dart';
import '../storage/local_record_identity.dart';
import 'estimate_confirmation.dart';
import '../storage/local_record_store.dart';
import 'work_contact_codec.dart';
import 'estimate_draft_controller.dart';
import 'models/work_models.dart';
import 'models/estimate_models.dart';
import 'work_persistence_session.dart';

extension EstimateDraftWorkflow on WorkPersistenceSession {
  /// Validate a selected workflow before a presentation takes ownership.
  void validateEstimateHandoff(
    EstimateDraftController controller, {
    WorkRecordKind documentKind = WorkRecordKind.estimate,
    required String creatorId,
    String? existingRecordId,
  }) {
    final input = controller.recoveredInput;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/${documentKind.name}-editor' ||
        input == null ||
        input.documentKind != documentKind ||
        input.creatorId != creatorId ||
        input.baseRecord?.id != existingRecordId) {
      throw StateError('Selected estimate belongs to another workflow.');
    }
    _requireEstimateCreator(input.creatorId, documentKind);
    if (existingRecordId != null) {
      editableEstimate(existingRecordId, documentKind: documentKind);
    }
  }

  void _requireEstimateCreator(String creatorId, WorkRecordKind documentKind) {
    if ((documentKind != WorkRecordKind.estimate &&
            documentKind != WorkRecordKind.quote) ||
        !permissions.editableKinds.contains(documentKind) ||
        !permissions.visibleCreatorIds.contains(creatorId) ||
        (creatorId != permissions.actorEmployeeId &&
            !permissions.canManageOtherCreators)) {
      throw StateError('Estimate creation is unavailable.');
    }
  }

  DraftRecoveryQuery estimateDraftRecovery(
    String creatorId, {
    WorkRecordKind documentKind = WorkRecordKind.estimate,
  }) {
    _requireEstimateCreator(creatorId, documentKind);
    return recoveryFor(documentKind);
  }

  WorkRecord editableEstimate(
    String recordId, {
    WorkRecordKind documentKind = WorkRecordKind.estimate,
  }) {
    final record = records.where((r) => r.id == recordId).firstOrNull;
    if (record == null ||
        record.kind != documentKind ||
        !permissions.canEdit(record)) {
      throw StateError('Estimate unavailable.');
    }
    return record;
  }

  Future<EstimateDraftController> openEstimateDraft({
    WorkRecordKind documentKind = WorkRecordKind.estimate,
    required String creatorId,
    String? existingRecordId,
    String? recoveryDraftId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    if (existingRecordId == null) {
      _requireEstimateCreator(creatorId, documentKind);
    } else {
      editableEstimate(existingRecordId, documentKind: documentKind);
      if (recoveryDraftId != null) {
        throw ArgumentError('Estimate edit recovery uses its record identity.');
      }
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: 'work/${documentKind.name}-editor',
      draftId:
          recoverySelection?.draftId ??
          (existingRecordId == null
              ? recoveryDraftId ??
                    newLocalRecordIdentity('${documentKind.name}-input')
              : 'edit-${permissions.actorEmployeeId}-$existingRecordId'),
    );
    void validateIdentity(EstimateDraftInput input) {
      _requireEstimateCreator(input.creatorId, documentKind);
      if (input.documentKind != documentKind ||
          (input.baseRecord != null &&
              input.baseRecord!.kind != documentKind) ||
          input.estimateId.isEmpty ||
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
          var estimate = buildConfirmedEstimate(input, now: DateTime.now());
          if (input.baseRecord == null) {
            final companyStore = LocalRecordStore(repository.database);
            final companies = await companyStore.read(
              organizationId: permissions.organizationId,
              domain: 'directory/company',
              ownerIds: {permissions.organizationId},
              recordIds: {'company'},
            );
            if ((documentKind == WorkRecordKind.quote &&
                    permissions.requiresQuoteApproval) ||
                (documentKind == WorkRecordKind.estimate &&
                    companies.isNotEmpty &&
                    decodeWorkCompanyProfile(
                      companyStore.decode(companies.single),
                    ).requireEstimateApproval)) {
              estimate = estimate.copyWith(
                requiresCompanyReview: true,
                estimateCompanyReviewStatus:
                    EstimateCompanyReviewStatus.pending,
              );
            }
          }
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
