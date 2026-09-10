import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';

/// Workflow state, independent of the dialog or any future page composition.
class JobAssignmentInput {
  const JobAssignmentInput({
    required this.base,
    required this.baseRevision,
    required this.assignee,
    required this.vehicle,
  });

  final WorkRecord base;
  final int baseRevision;
  final String assignee;
  final String vehicle;

  Map<String, Object?> toPayload() => {
    'base': encodeWorkRecord(base),
    'baseRevision': baseRevision,
    'assignee': assignee,
    'vehicle': vehicle,
  };

  factory JobAssignmentInput.fromPayload(Map<String, Object?> payload) =>
      JobAssignmentInput(
        base: decodeWorkRecord(
          (payload['base'] as Map).cast<String, Object?>(),
        ),
        baseRevision: payload['baseRevision'] as int,
        assignee: payload['assignee'] as String,
        vehicle: payload['vehicle'] as String,
      );
}

class JobAssignmentDraftController
    extends DraftWorkflowController<JobAssignmentInput> {
  JobAssignmentDraftController._(DraftAutosaveSession session, this._commit)
    : super(
        session,
        (input) => input.toPayload(),
        JobAssignmentInput.fromPayload,
      );

  final Future<WorkRecord?> Function(JobAssignmentInput, LocalDraftCheckpoint)
  _commit;
  JobAssignmentInput get input => recoveredInput!;

  void updateAssignment({required String assignee, required String vehicle}) =>
      updateInput(
        JobAssignmentInput(
          base: input.base,
          baseRevision: input.baseRevision,
          assignee: assignee,
          vehicle: vehicle,
        ),
      );

  Future<WorkRecord?> confirm() async {
    WorkRecord? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension JobAssignmentDraftWorkflow on WorkPersistenceSession {
  void validateJobAssignmentHandoff(
    JobAssignmentDraftController controller,
    String recordId,
  ) {
    final current = records
        .where((record) => record.id == recordId)
        .firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/job-assignment' ||
        controller.input.base.id != recordId ||
        current == null ||
        current.kind != WorkRecordKind.job ||
        !permissions.canEdit(current)) {
      throw StateError('Selected job assignment belongs to another workflow.');
    }
  }

  Future<JobAssignmentDraftController> openJobAssignmentDraft(
    String recordId, {
    DraftRecoverySelection? recoverySelection,
  }) async {
    final current = records.where((r) => r.id == recordId).firstOrNull;
    if (current == null ||
        current.kind != WorkRecordKind.job ||
        !permissions.canEdit(current)) {
      throw StateError('Job unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/job-assignment',
      draftId:
          recoverySelection?.draftId ??
          'edit-${permissions.actorEmployeeId}-$recordId',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(JobAssignmentInput input) {
      if (input.base.id != recordId ||
          input.base.kind != WorkRecordKind.job ||
          input.base.createdByEmployeeId != current.createdByEmployeeId ||
          input.baseRevision < 1 ||
          !permissions.canEdit(input.base)) {
        throw StateError('Saved job assignment identity is inconsistent.');
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
      final controller = JobAssignmentDraftController._(draft, (
        input,
        checkpoint,
      ) async {
        validate(input);
        final record = input.base.copyWith(
          assignee: input.assignee,
          vehicle: input.vehicle,
        );
        final saved = await save(
          records: [record],
          expectedStorageRevisions: {record.id: input.baseRevision},
          draftCheckpoint: checkpoint,
        );
        return saved ? record : null;
      });
      if (controller.recoveredInput == null) {
        controller.updateInput(
          JobAssignmentInput(
            base: current,
            baseRevision: storageRevisionFor(recordId),
            assignee: current.assignee ?? 'Unassigned',
            vehicle: current.vehicle ?? 'No vehicle assigned',
          ),
        );
      } else {
        validate(controller.input);
      }
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
