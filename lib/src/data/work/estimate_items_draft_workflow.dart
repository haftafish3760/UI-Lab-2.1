import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_command.dart';
import 'models/work_models.dart';
import 'work_items_draft_input.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';

class EstimateItemsDraftInput {
  const EstimateItemsDraftInput({
    required this.base,
    required this.baseRevision,
    required this.workspace,
    this.confirmedAt,
  });
  final WorkRecord base;
  final int baseRevision;
  final WorkItemsDraftInput workspace;
  final DateTime? confirmedAt;
  EstimateItemsDraftInput withWorkspace(WorkItemsDraftInput value) =>
      EstimateItemsDraftInput(
        base: base,
        baseRevision: baseRevision,
        workspace: value,
      );
  EstimateItemsDraftInput prepare() {
    if (workspace.pendingItem != null) {
      throw StateError('Finish or discard the unfinished item before saving.');
    }
    return EstimateItemsDraftInput(
      base: base,
      baseRevision: baseRevision,
      workspace: workspace,
      confirmedAt: confirmedAt ?? DateTime.now().toUtc(),
    );
  }

  WorkRecord confirmedRecord() {
    if (workspace.pendingItem != null || confirmedAt == null) {
      throw StateError('Items are not ready to save.');
    }
    return base.reviseItems(workspace.items, changedOn: confirmedAt!);
  }

  Map<String, Object?> toPayload() => {
    'base': encodeWorkRecord(base),
    'baseRevision': baseRevision,
    'input': workspace.toPayload(),
    'confirmedAt': confirmedAt?.toIso8601String(),
  };
  factory EstimateItemsDraftInput.fromPayload(Map<String, Object?> input) =>
      EstimateItemsDraftInput(
        base: decodeWorkRecord((input['base'] as Map).cast<String, Object?>()),
        baseRevision: input['baseRevision'] as int,
        workspace: WorkItemsDraftInput.fromPayload(
          (input['input'] as Map).cast<String, Object?>(),
        ),
        confirmedAt: input['confirmedAt'] == null
            ? null
            : DateTime.parse(input['confirmedAt'] as String),
      );
}

class EstimateItemsDraftController
    extends DraftWorkflowController<EstimateItemsDraftInput> {
  EstimateItemsDraftController._(DraftAutosaveSession session, this._commit)
    : super(
        session,
        (input) => input.toPayload(),
        EstimateItemsDraftInput.fromPayload,
      );
  final Future<WorkRecord?> Function(
    EstimateItemsDraftInput,
    LocalDraftCheckpoint,
  )
  _commit;
  EstimateItemsDraftInput get input => recoveredInput!;
  void updateWorkspace(WorkItemsDraftInput value) =>
      updateInput(input.withWorkspace(value));
  Future<WorkRecord?> confirm() async {
    updateInput(input.prepare());
    WorkRecord? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension EstimateItemsDraftWorkflow on WorkPersistenceSession {
  void validateEstimateItemsHandoff(
    EstimateItemsDraftController controller,
    String recordId,
  ) {
    final current = records
        .where((record) => record.id == recordId)
        .firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/estimate-items' ||
        controller.input.base.id != recordId ||
        current == null ||
        current.kind != WorkRecordKind.estimate ||
        !permissions.canEdit(current)) {
      throw StateError('Selected items belong to another estimate.');
    }
  }

  Future<EstimateItemsDraftController> openEstimateItemsDraft(
    WorkRecord expected, {
    DraftRecoverySelection? recoverySelection,
  }) async {
    final current = records.where((r) => r.id == expected.id).firstOrNull;
    if (current == null ||
        current.kind != WorkRecordKind.estimate ||
        !permissions.canEdit(current) ||
        canonicalJson(encodeWorkRecord(current)) !=
            canonicalJson(encodeWorkRecord(expected))) {
      throw StateError(
        'This estimate changed or is unavailable. Reopen it before editing.',
      );
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/estimate-items',
      draftId:
          recoverySelection?.draftId ??
          'edit-${permissions.actorEmployeeId}-${current.id}',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(EstimateItemsDraftInput input) {
      if (input.base.id != current.id ||
          input.base.kind != WorkRecordKind.estimate ||
          input.base.createdByEmployeeId != current.createdByEmployeeId ||
          input.baseRevision < 1 ||
          !permissions.canEdit(input.base) ||
          (input.confirmedAt != null && !input.confirmedAt!.isUtc)) {
        throw StateError('Saved items do not match this estimate.');
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
      final controller = EstimateItemsDraftController._(draft, (
        input,
        checkpoint,
      ) async {
        validate(input);
        final record = input.confirmedRecord();
        final saved = await save(
          records: [record],
          expectedStorageRevisions: {record.id: input.baseRevision},
          draftCheckpoint: checkpoint,
        );
        return saved ? record : null;
      });
      if (controller.recoveredInput == null) {
        controller.updateInput(
          EstimateItemsDraftInput(
            base: current,
            baseRevision: storageRevisionFor(current.id),
            workspace: WorkItemsDraftInput(items: current.items),
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
