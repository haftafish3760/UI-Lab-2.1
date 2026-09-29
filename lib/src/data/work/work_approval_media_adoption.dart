import '../storage/draft_autosave_session.dart';
import '../storage/local_attachment_store.dart';
import '../storage/local_draft_store.dart';
import '../storage/local_media_picker_request.dart';
import '../storage/local_record_command.dart';
import 'estimate_approval_draft_workflow.dart';
import 'estimate_draft_media_commit.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';

/// Retained files enter the actor's approval draft, never the approved record.
class WorkApprovalMediaAdoption {
  WorkApprovalMediaAdoption(this.work, this.destination) {
    if (destination != MediaPickerDestination.estimateApproval &&
        destination != MediaPickerDestination.quoteApproval) {
      throw ArgumentError('An approval destination is required.');
    }
  }
  final WorkPersistenceSession work;
  final MediaPickerDestination destination;
  WorkRecordKind get kind =>
      destination == MediaPickerDestination.estimateApproval
      ? WorkRecordKind.estimate
      : WorkRecordKind.quote;
  String get domain => 'work/${kind.name}-approval';

  Future<void> authorize({
    required String organizationId,
    required String ownerId,
    required MediaPickerDestination destination,
    required String targetId,
    required int targetRevision,
  }) async {
    await _read(organizationId, ownerId, destination, targetId, targetRevision);
  }

  Future<EstimateApprovalInput> _read(
    String organizationId,
    String ownerId,
    MediaPickerDestination target,
    String targetId,
    int targetRevision,
  ) async {
    work.requireActiveDraftOwner();
    final permissions = work.permissions;
    if (target != destination ||
        organizationId != permissions.organizationId ||
        ownerId != permissions.actorEmployeeId ||
        !permissions.canRecordCustomerApproval) {
      throw StateError('Customer approval attachment access is unavailable.');
    }
    final drafts = LocalDraftStore(work.repository.database);
    final row = await drafts.find(
      organizationId: organizationId,
      domain: domain,
      draftId: targetId,
      ownerId: ownerId,
    );
    if (row == null || row.revision != targetRevision) {
      throw const LocalRecordConflict('The approval input changed.');
    }
    final input = EstimateApprovalInput.fromPayload(drafts.decode(row));
    final saved = await work.repository.find(
      organizationId: organizationId,
      recordId: input.base.id,
      visibleCreatorIds: permissions.visibleCreatorIds,
    );
    work.requireActiveDraftOwner();
    if (input.base.kind != kind ||
        saved == null ||
        saved.record.kind != kind ||
        saved.record.createdByEmployeeId != input.base.createdByEmployeeId ||
        !permissions.canEdit(saved.record) ||
        !permissions.canEdit(input.base) ||
        saved.storageRevision != input.baseRevision) {
      throw const LocalRecordConflict(
        'Reopen the current document before adding approval evidence.',
      );
    }
    return input;
  }

  Future<EstimateApprovalInput> adopt({
    required LocalMediaPickerRequest request,
    required DraftAutosaveSession draft,
  }) async {
    if (draft.store is! LocalDraftStore ||
        !identical(
          (draft.store as LocalDraftStore).database,
          work.repository.database,
        ) ||
        draft.domain != domain ||
        draft.organizationId != request.organizationId ||
        draft.ownerId != request.ownerId ||
        draft.draftId != request.targetId ||
        request.retainedAttachmentIds == null ||
        request.returnedFiles == null ||
        request.retainedAttachmentIds!.length !=
            request.returnedFiles!.length) {
      throw StateError('The attachment selection belongs to another approval.');
    }
    final input = await _read(
      request.organizationId,
      request.ownerId,
      request.destination,
      request.targetId,
      request.targetRevision,
    );
    final ids = request.retainedAttachmentIds!;
    if (ids.toSet().length != ids.length) {
      throw StateError('Duplicate attachment selection.');
    }
    await LocalAttachmentStore(work.repository.database).verifiedFiles(
      organizationId: request.organizationId,
      ownerIds: {request.ownerId},
      attachmentIds: ids.toSet(),
    );
    final evidence = [...input.evidence];
    for (var i = 0; i < ids.length; i++) {
      if (evidence.any((item) => item.attachmentId == ids[i])) {
        throw StateError('Attachment already added.');
      }
      evidence.add(
        WorkApprovalEvidence.fromJson({
          'attachmentId': ids[i],
          'name': request.returnedFiles![i].name,
        }),
      );
    }
    final payload = {
      ...input.toPayload(),
      'evidence': evidence.map((item) => item.toJson()).toList(),
    };
    await draft.adoptMediaInput(
      request: request,
      input: payload,
      validateBeforeCommit: () => authorize(
        organizationId: request.organizationId,
        ownerId: request.ownerId,
        destination: request.destination,
        targetId: request.targetId,
        targetRevision: request.targetRevision,
      ),
    );
    return EstimateApprovalInput.fromPayload(payload);
  }
}
