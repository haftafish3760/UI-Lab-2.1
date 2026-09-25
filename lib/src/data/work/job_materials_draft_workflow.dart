import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'job_material_permissions.dart';
import 'models/work_models.dart';
import 'work_items_draft_input.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';
import 'work_record_detail_codec.dart';

List<WorkLineItem> editableJobMaterials(
  WorkRecord base,
  JobWorkspacePermissions permissions,
) => base.items
    .where(
      (item) =>
          item.isJobAddition &&
          canEditJobMaterialTreatment(
            item.resolvedJobMaterialBillingTreatment,
            permissions,
          ),
    )
    .toList();

class JobMaterialsDraftInput {
  const JobMaterialsDraftInput({
    required this.base,
    required this.baseRevision,
    required this.workspace,
    this.confirmedAt,
  });
  final WorkRecord base;
  final int baseRevision;
  final WorkItemsDraftInput workspace;
  final DateTime? confirmedAt;
  JobMaterialsDraftInput withWorkspace(WorkItemsDraftInput value) =>
      JobMaterialsDraftInput(
        base: base,
        baseRevision: baseRevision,
        workspace: value,
      );
  JobMaterialsDraftInput prepare() {
    if (workspace.pendingItem != null) {
      throw StateError(
        'Finish or discard the unfinished material before saving.',
      );
    }
    return JobMaterialsDraftInput(
      base: base,
      baseRevision: baseRevision,
      workspace: workspace,
      confirmedAt: confirmedAt ?? DateTime.now().toUtc(),
    );
  }

  WorkRecord confirmedRecord(JobWorkspacePermissions permissions) {
    if (!permissions.canAddMaterials ||
        workspace.pendingItem != null ||
        confirmedAt == null) {
      throw StateError('Materials are not ready to save.');
    }
    final existing = editableJobMaterials(base, permissions);
    if (!permissions.canUseTruckStock &&
        [
          ...existing,
          ...workspace.items,
        ].any((item) => item.sourceStockId != null)) {
      throw StateError('You do not have permission to change truck stock.');
    }
    final editableIds = editableJobMaterials(
      base,
      permissions,
    ).map((item) => item.id).toSet();
    final protected = base.items
        .where((item) => !editableIds.contains(item.id))
        .toList();
    final protectedIds = protected.map((item) => item.id).toSet();
    final additions = workspace.items;
    if (additions.map((item) => item.id).toSet().length != additions.length ||
        additions.any(
          (item) =>
              protectedIds.contains(item.id) ||
              !canEditJobMaterialTreatment(
                item.resolvedJobMaterialBillingTreatment,
                permissions,
              ),
        )) {
      throw StateError(
        'These materials cannot be changed with the current permissions.',
      );
    }
    if (additions.any(
      (item) =>
          item.resolvedJobMaterialBillingTreatment ==
              JobMaterialBillingTreatment.invoiceCandidate &&
          item.changeApproval == null,
    )) {
      throw StateError(
        'Record customer approval for billable additions before saving.',
      );
    }
    return base.reviseItems([
      ...protected,
      ...additions.map(
        (item) => decodeWorkLineItem({
          ...encodeWorkLineItem(item),
          'isJobAddition': true,
        }),
      ),
    ], changedOn: confirmedAt!);
  }

  Map<String, Object?> toPayload() => {
    'base': encodeWorkRecord(base),
    'baseRevision': baseRevision,
    'workspace': workspace.toPayload(),
    'confirmedAt': confirmedAt?.toIso8601String(),
  };
  factory JobMaterialsDraftInput.fromPayload(Map<String, Object?> input) =>
      JobMaterialsDraftInput(
        base: decodeWorkRecord((input['base'] as Map).cast<String, Object?>()),
        baseRevision: input['baseRevision'] as int,
        workspace: WorkItemsDraftInput.fromPayload(
          (input['workspace'] as Map).cast<String, Object?>(),
        ),
        confirmedAt: input['confirmedAt'] == null
            ? null
            : DateTime.parse(input['confirmedAt'] as String),
      );
}

class JobMaterialsDraftController
    extends DraftWorkflowController<JobMaterialsDraftInput> {
  JobMaterialsDraftController._(
    DraftAutosaveSession session,
    this._owner,
    this._materialPermissions,
    this._commit,
  ) : super(
        session,
        (input) => input.toPayload(),
        JobMaterialsDraftInput.fromPayload,
      );
  final Future<WorkRecord?> Function(
    JobMaterialsDraftInput,
    LocalDraftCheckpoint,
  )
  _commit;
  final WorkPersistenceSession _owner;
  final JobWorkspacePermissions _materialPermissions;
  JobMaterialsDraftInput get input => recoveredInput!;
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

extension JobMaterialsDraftWorkflow on WorkPersistenceSession {
  void validateJobMaterialsHandoff(
    JobMaterialsDraftController controller,
    String recordId, {
    required JobWorkspacePermissions materialPermissions,
  }) {
    final current = records.where((r) => r.id == recordId).firstOrNull;
    if (!identical(controller._owner, this) ||
        controller.input.base.id != recordId ||
        current == null ||
        current.kind != WorkRecordKind.job ||
        !permissions.canEdit(current) ||
        !materialPermissions.canAddMaterials ||
        _materialAuthority(controller._materialPermissions) !=
            _materialAuthority(materialPermissions)) {
      throw StateError(
        'Materials recovery does not match the current job access.',
      );
    }
  }

  Future<JobMaterialsDraftController> openJobMaterialsDraft(
    String recordId, {
    required JobWorkspacePermissions materialPermissions,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final current = records.where((r) => r.id == recordId).firstOrNull;
    if (current == null ||
        current.kind != WorkRecordKind.job ||
        !permissions.canEdit(current) ||
        !materialPermissions.canAddMaterials) {
      throw StateError('Job unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/job-materials',
      draftId:
          recoverySelection?.draftId ??
          'edit-${permissions.actorEmployeeId}-$recordId',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(JobMaterialsDraftInput input) {
      if (input.base.id != recordId ||
          input.base.kind != WorkRecordKind.job ||
          input.base.createdByEmployeeId != current.createdByEmployeeId ||
          input.baseRevision < 1 ||
          !permissions.canEdit(input.base) ||
          (input.confirmedAt != null && !input.confirmedAt!.isUtc)) {
        throw StateError('Saved materials do not match this job.');
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
      final controller = JobMaterialsDraftController._(
        draft,
        this,
        materialPermissions,
        (input, checkpoint) async {
          validate(input);
          final record = input.confirmedRecord(materialPermissions);
          final saved = await save(
            records: [record],
            expectedStorageRevisions: {record.id: input.baseRevision},
            draftCheckpoint: checkpoint,
          );
          return saved ? record : null;
        },
      );
      if (controller.recoveredInput == null) {
        controller.updateInput(
          JobMaterialsDraftInput(
            base: current,
            baseRevision: storageRevisionFor(recordId),
            workspace: WorkItemsDraftInput(
              items: editableJobMaterials(current, materialPermissions),
            ),
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

// Compare capabilities used by the material workflow, independently of widgets.
Object _materialAuthority(JobWorkspacePermissions value) => (
  value.canAddMaterials,
  value.canLinkExpenses,
  value.canUseTruckStock,
  value.canViewInternalCost,
  value.canViewCustomerPrice,
  value.canSetCustomerPrice,
  value.canAddBillableAdjustment,
  value.canProposeChangeOrder,
);
