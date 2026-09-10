import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';

/// Workflow state, independent of the dialog or any future page composition.
class JobNotesInput {
  const JobNotesInput({
    required this.base,
    required this.baseRevision,
    required this.notes,
  });

  final WorkRecord base;
  final int baseRevision;
  final String notes;

  Map<String, Object?> toPayload() => {
    'base': encodeWorkRecord(base),
    'baseRevision': baseRevision,
    'notes': notes,
  };

  factory JobNotesInput.fromPayload(Map<String, Object?> payload) =>
      JobNotesInput(
        base: decodeWorkRecord(
          (payload['base'] as Map).cast<String, Object?>(),
        ),
        baseRevision: payload['baseRevision'] as int,
        notes: payload['notes'] as String,
      );
}

class JobNotesDraftController extends DraftWorkflowController<JobNotesInput> {
  JobNotesDraftController._(DraftAutosaveSession session, this._commit)
    : super(session, (input) => input.toPayload(), JobNotesInput.fromPayload);

  final Future<WorkRecord?> Function(JobNotesInput, LocalDraftCheckpoint)
  _commit;
  JobNotesInput get input => recoveredInput!;

  void updateNotes(String notes) => updateInput(
    JobNotesInput(
      base: input.base,
      baseRevision: input.baseRevision,
      notes: notes,
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

extension JobNotesDraftWorkflow on WorkPersistenceSession {
  void validateJobNotesHandoff(
    JobNotesDraftController controller,
    String recordId,
  ) {
    final current = records
        .where((record) => record.id == recordId)
        .firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/job-notes' ||
        controller.input.base.id != recordId ||
        current == null ||
        current.kind != WorkRecordKind.job ||
        !permissions.canEdit(current)) {
      throw StateError('Selected job notes belong to another workflow.');
    }
  }

  Future<JobNotesDraftController> openJobNotesDraft(
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
      domain: 'work/job-notes',
      draftId:
          recoverySelection?.draftId ??
          'edit-${permissions.actorEmployeeId}-$recordId',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(JobNotesInput input) {
      if (input.base.id != recordId ||
          input.base.kind != WorkRecordKind.job ||
          input.base.createdByEmployeeId != current.createdByEmployeeId ||
          input.baseRevision < 1 ||
          !permissions.canEdit(input.base)) {
        throw StateError('Saved job notes identity is inconsistent.');
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
      final controller = JobNotesDraftController._(draft, (
        input,
        checkpoint,
      ) async {
        validate(input);
        final record = input.base.copyWith(jobNotes: input.notes.trim());
        final saved = await save(
          records: [record],
          expectedStorageRevisions: {record.id: input.baseRevision},
          draftCheckpoint: checkpoint,
        );
        return saved ? record : null;
      });
      if (controller.recoveredInput == null) {
        controller.updateInput(
          JobNotesInput(
            base: current,
            baseRevision: storageRevisionFor(recordId),
            notes: current.jobNotes,
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
