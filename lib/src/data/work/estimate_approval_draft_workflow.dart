import '../storage/draft_autosave_session.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'estimate_customer_approval.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';

/// Unfinished approval input is not approval evidence until explicitly confirmed.
class EstimateApprovalInput {
  const EstimateApprovalInput({
    required this.base,
    required this.baseRevision,
    required this.name,
    this.method,
    this.note = '',
    this.accepted = false,
    this.confirmedAt,
    this.evidence = const [],
  });
  final WorkRecord base;
  final int baseRevision;
  final String name, note;
  final CustomerApprovalMethod? method;
  final bool accepted;
  final DateTime? confirmedAt;
  final List<WorkApprovalEvidence> evidence;

  Map<String, Object?> toPayload() => {
    'base': encodeWorkRecord(base),
    'baseRevision': baseRevision,
    'name': name,
    'method': method?.name,
    'note': note,
    'accepted': accepted,
    'confirmedAt': confirmedAt?.toIso8601String(),
    if (evidence.isNotEmpty)
      'evidence': evidence.map((item) => item.toJson()).toList(),
  };
  factory EstimateApprovalInput.fromPayload(Map<String, Object?> raw) =>
      EstimateApprovalInput(
        base: decodeWorkRecord((raw['base'] as Map).cast<String, Object?>()),
        baseRevision: raw['baseRevision'] as int,
        name: raw['name'] as String,
        method: raw['method'] == null
            ? null
            : CustomerApprovalMethod.values.byName(raw['method'] as String),
        note: raw['note'] as String,
        evidence: List.unmodifiable(
          ((raw['evidence'] as List?) ?? const []).map(
            (item) => WorkApprovalEvidence.fromJson(
              (item as Map).cast<String, Object?>(),
            ),
          ),
        ),
        accepted: raw['accepted'] as bool,
        confirmedAt: raw['confirmedAt'] == null
            ? null
            : DateTime.parse(raw['confirmedAt'] as String),
      );
}

class EstimateApprovalDraftController
    extends DraftWorkflowController<EstimateApprovalInput> {
  EstimateApprovalDraftController._(
    DraftAutosaveSession session,
    this._commit,
    this._initial,
  ) : super(
        session,
        (value) => value.toPayload(),
        EstimateApprovalInput.fromPayload,
      );
  final Future<WorkRecord?> Function(
    EstimateApprovalInput,
    LocalDraftCheckpoint,
  )
  _commit;
  final EstimateApprovalInput _initial;
  EstimateApprovalInput get input => recoveredInput ?? _initial;

  Future<WorkRecord?> confirm() async {
    if (!input.accepted ||
        input.method == null ||
        input.method == CustomerApprovalMethod.signedEstimate) {
      throw StateError(
        'Accept the terms and choose how the customer approved.',
      );
    }
    updateInput(
      EstimateApprovalInput(
        base: input.base,
        baseRevision: input.baseRevision,
        name: input.name,
        method: input.method,
        note: input.note,
        evidence: input.evidence,
        accepted: input.accepted,
        confirmedAt: input.confirmedAt ?? DateTime.now().toUtc(),
      ),
    );
    WorkRecord? result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return result != null;
    });
    return result;
  }
}

extension EstimateApprovalDraftWorkflow on WorkPersistenceSession {
  void validateEstimateApprovalHandoff(
    EstimateApprovalDraftController controller,
    String recordId,
  ) {
    final current = records.where((r) => r.id == recordId).firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain !=
            'work/${controller.input.base.kind.name}-approval' ||
        controller.input.base.id != recordId ||
        current == null ||
        !current.isProposal ||
        current.kind != controller.input.base.kind ||
        !permissions.canEdit(current) ||
        !permissions.canRecordCustomerApproval) {
      throw StateError(
        'Saved approval belongs to another workflow or access scope.',
      );
    }
  }

  Future<EstimateApprovalDraftController> openEstimateApprovalDraft(
    String recordId, {
    DraftRecoverySelection? recoverySelection,
  }) async {
    final current = records
        .where((record) => record.id == recordId)
        .firstOrNull;
    if (current == null ||
        !current.isProposal ||
        !permissions.canEdit(current) ||
        !permissions.canRecordCustomerApproval) {
      throw StateError(
        'Customer approval is not available with your current access.',
      );
    }
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/${current.kind.name}-approval',
      draftId:
          recoverySelection?.draftId ??
          'edit-${permissions.actorEmployeeId}-$recordId',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(EstimateApprovalInput input) {
      if (input.base.id != recordId ||
          input.base.kind != current.kind ||
          input.base.createdByEmployeeId != current.createdByEmployeeId ||
          input.baseRevision < 1 ||
          !permissions.canEdit(input.base) ||
          !permissions.canRecordCustomerApproval ||
          input.method == CustomerApprovalMethod.signedEstimate ||
          (input.confirmedAt != null && !input.confirmedAt!.isUtc)) {
        throw StateError(
          'Saved approval does not match this estimate or your access.',
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
      final controller = EstimateApprovalDraftController._(
        draft,
        (input, checkpoint) async {
          validate(input);
          final record = input.base.recordCustomerApproval(
            WorkCustomerApproval(
              method: input.method!,
              customerName: input.name.trim(),
              recordedByEmployeeId: permissions.actorEmployeeId,
              recordedOn: input.confirmedAt!,
              revision: input.base.revision,
              note: input.note.trim(),
              evidence: input.evidence,
            ),
          );
          final saved = await save(
            records: [record],
            expectedStorageRevisions: {record.id: input.baseRevision},
            draftCheckpoint: checkpoint,
          );
          return saved ? record : null;
        },
        EstimateApprovalInput(
          base: current,
          baseRevision: storageRevisionFor(recordId),
          name: current.client,
        ),
      );
      if (controller.recoveredInput != null) validate(controller.input);
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}
