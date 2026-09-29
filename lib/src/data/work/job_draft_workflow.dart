import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_recovery_query.dart';
import '../storage/local_record_identity.dart';
import 'job_confirmation.dart';
import 'job_draft_controller.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';

extension JobDraftWorkflow on WorkPersistenceSession {
  /// Checks domain and current access before transferring a selected workflow.
  void validateJobHandoff(
    JobDraftController controller, {
    String? sourceEstimateId,
  }) {
    final input = controller.recoveredInput;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/job-editor' ||
        input == null ||
        input.sourceEstimate?.id != sourceEstimateId) {
      throw StateError('Selected job belongs to another workflow.');
    }
    _requireJobAccess();
    if (sourceEstimateId != null) {
      final source = records.where((r) => r.id == sourceEstimateId).firstOrNull;
      if (source == null ||
          !source.isProposal ||
          !permissions.canEdit(source)) {
        throw StateError('Source estimate or quote unavailable.');
      }
    }
  }

  DraftRecoveryQuery get jobDraftRecovery {
    _requireJobAccess();
    return recoveryFor(WorkRecordKind.job);
  }

  void _requireJobAccess() {
    if (!permissions.editableKinds.contains(WorkRecordKind.job) ||
        !permissions.visibleCreatorIds.contains(permissions.actorEmployeeId)) {
      throw StateError('Job creation is unavailable.');
    }
  }

  Future<JobDraftController> openJobDraft({
    String? sourceEstimateId,
    String? recoveryDraftId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    _requireJobAccess();
    if (sourceEstimateId != null) {
      final source = records.where((r) => r.id == sourceEstimateId).firstOrNull;
      if (source == null ||
          !source.isProposal ||
          !permissions.canEdit(source)) {
        throw StateError('Source estimate or quote unavailable.');
      }
      if (recoveryDraftId != null) {
        throw ArgumentError('Linked job recovery uses its source identity.');
      }
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: 'work/job-editor',
      draftId:
          recoverySelection?.draftId ??
          (sourceEstimateId == null
              ? recoveryDraftId ?? newLocalRecordIdentity('job-input')
              : 'source-${permissions.actorEmployeeId}-$sourceEstimateId'),
    );
    try {
      await draft.initialize();
      requireActiveDraftOwner();
      recoverySelection?.verify(
        openedDomain: draft.domain,
        openedDraftId: draft.draftId,
        openedRevision: draft.savedRevision,
        hasInput: draft.input.isNotEmpty,
      );
      final controller = JobDraftController(
        draft,
        confirm: (input, checkpoint) async {
          if (input.sourceEstimate?.id != sourceEstimateId) {
            throw StateError('Job source does not match this workflow.');
          }
          final job = buildConfirmedJob(
            input,
            actorEmployeeId: permissions.actorEmployeeId,
            now: DateTime.now(),
          );
          final source = input.sourceEstimate;
          final saved = source == null
              ? await save(
                  records: [job],
                  expectedStorageRevisions: {job.id: 0},
                  draftCheckpoint: checkpoint,
                )
              : await createJobFromApprovedEstimate(
                  job: job,
                  expectedSourceStorageRevision: input.sourceStorageRevision,
                  expectedSourceDocumentRevision: source.revision,
                  draftCheckpoint: checkpoint,
                );
          return saved ? job : null;
        },
      );
      final input = controller.recoveredInput;
      if ((recoveryDraftId != null && input == null) ||
          (input != null && input.sourceEstimate?.id != sourceEstimateId)) {
        throw StateError('Saved job input does not match this workflow.');
      }
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
