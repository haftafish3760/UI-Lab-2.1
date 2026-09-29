import '../storage/draft_autosave_session.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_command.dart';
import 'estimate_photos_draft_input.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';
import 'work_record_detail_codec.dart';

class JobPhotosDraftInput {
  const JobPhotosDraftInput({
    required this.base,
    required this.baseRevision,
    required this.photos,
  });
  final WorkRecord base;
  final int baseRevision;
  final EstimatePhotosDraftInput photos;
  Map<String, Object?> toPayload() => {
    'baseRecord': encodeWorkRecord(base),
    'baseStorageRevision': baseRevision,
    'creatorId': base.createdByEmployeeId,
    'jobId': base.id,
    'sitePhotos': base.sitePhotos.map(encodeWorkSitePhoto).toList(),
    'photoEditor': photos.toPayload(),
  };
  factory JobPhotosDraftInput.fromPayload(Map<String, Object?> input) =>
      JobPhotosDraftInput(
        base: decodeWorkRecord(
          (input['baseRecord'] as Map).cast<String, Object?>(),
        ),
        baseRevision: input['baseStorageRevision'] as int,
        photos: EstimatePhotosDraftInput.fromPayload(
          (input['photoEditor'] as Map).cast<String, Object?>(),
        ),
      );
}

class JobPhotosDraftController
    extends DraftWorkflowController<JobPhotosDraftInput> {
  JobPhotosDraftController._(
    DraftAutosaveSession session,
    this._initial,
    this._commit,
  ) : super(
        session,
        (input) => input.toPayload(),
        JobPhotosDraftInput.fromPayload,
      );
  final JobPhotosDraftInput _initial;
  final Future<WorkRecord?> Function(JobPhotosDraftInput, LocalDraftCheckpoint)
  _commit;
  JobPhotosDraftInput get input => recoveredInput ?? _initial;
  void updatePhotos(EstimatePhotosDraftInput photos) => updateInput(
    JobPhotosDraftInput(
      base: input.base,
      baseRevision: input.baseRevision,
      photos: photos,
    ),
  );
  Future<WorkRecord?> confirm() async {
    input.photos.confirmedPhotos();
    updateInput(input);
    WorkRecord? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension JobPhotosDraftWorkflow on WorkPersistenceSession {
  void validateJobPhotosHandoff(
    JobPhotosDraftController controller,
    String recordId,
  ) {
    requireActiveDraftOwner();
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/job-photos' ||
        controller.input.base.id != recordId ||
        !permissions.canAttachJobPhotos ||
        !permissions.canEdit(controller.input.base)) {
      throw StateError('Saved photos belong to another job or access scope.');
    }
  }

  Future<JobPhotosDraftController> openJobPhotosDraft(
    String recordId, {
    DraftRecoverySelection? recoverySelection,
  }) async {
    final current = records.where((r) => r.id == recordId).firstOrNull;
    if (current == null ||
        current.kind != WorkRecordKind.job ||
        !permissions.canEdit(current) ||
        !permissions.canAttachJobPhotos) {
      throw StateError('You do not have access to change this job’s photos.');
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: 'work/job-photos',
      draftId:
          recoverySelection?.draftId ??
          'photos-${permissions.actorEmployeeId}-$recordId',
    );
    void validate(JobPhotosDraftInput input) {
      if (input.base.id != recordId ||
          input.base.kind != WorkRecordKind.job ||
          input.baseRevision != storageRevisionFor(recordId) ||
          canonicalJson(encodeWorkRecord(input.base)) !=
              canonicalJson(encodeWorkRecord(current))) {
        throw StateError(
          'This job changed. Reopen it before saving photos. Your unfinished photos are retained.',
        );
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
      final controller = JobPhotosDraftController._(
        draft,
        JobPhotosDraftInput(
          base: current,
          baseRevision: storageRevisionFor(recordId),
          photos: EstimatePhotosDraftInput(
            photos: current.sitePhotos,
            pendingNotes: const {},
          ),
        ),
        (input, checkpoint) async {
          validate(input);
          final record = decodeWorkRecord({
            ...encodeWorkRecord(input.base),
            'sitePhotos': input.photos
                .confirmedPhotos()
                .map(encodeWorkSitePhoto)
                .toList(),
          });
          final saved = await save(
            records: [record],
            expectedStorageRevisions: {record.id: input.baseRevision},
            draftCheckpoint: checkpoint,
          );
          return saved ? record : null;
        },
      );
      if (controller.recoveredInput != null) validate(controller.input);
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
