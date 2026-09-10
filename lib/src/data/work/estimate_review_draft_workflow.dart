import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_record_command.dart';
import 'models/estimate_models.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';
import 'work_record_codec.dart';

class EstimateReviewInput {
  const EstimateReviewInput({
    required this.base,
    required this.baseRevision,
    required this.decision,
    this.reason = '',
    this.confirmedAt,
  });
  final WorkRecord base;
  final int baseRevision;
  final EstimateCompanyReviewDecision decision;
  final String reason;
  final DateTime? confirmedAt;

  void validateReview(EstimatePermissions permissions) {
    if (!permissions.canApproveCompanyReview ||
        (decision != EstimateCompanyReviewDecision.changesRequested &&
            decision != EstimateCompanyReviewDecision.rejected)) {
      throw StateError('Review unavailable.');
    }
    if (base.kind != WorkRecordKind.estimate ||
        !base.requiresCompanyReview ||
        base.estimateCompanyReviewStatus !=
            EstimateCompanyReviewStatus.pending) {
      throw StateError('This estimate is not awaiting company review.');
    }
  }

  EstimateReviewInput withReason(String value) => EstimateReviewInput(
    base: base,
    baseRevision: baseRevision,
    decision: decision,
    reason: value,
  );

  EstimateReviewInput prepare() {
    if (reason.trim().isEmpty) throw StateError('Enter a clear reason.');
    return EstimateReviewInput(
      base: base,
      baseRevision: baseRevision,
      decision: decision,
      reason: reason,
      confirmedAt: confirmedAt ?? DateTime.now().toUtc(),
    );
  }

  WorkRecord confirmedRecord(String reviewer) {
    if (reason.trim().isEmpty || confirmedAt == null) {
      throw StateError('Enter a clear reason.');
    }
    return base.recordCompanyReview(
      decision: decision,
      reviewedBy: reviewer,
      note: reason,
      reviewedOn: confirmedAt!,
    );
  }

  Map<String, Object?> toPayload() => {
    'base': encodeWorkRecord(base),
    'baseRevision': baseRevision,
    'decision': decision.name,
    'reason': reason,
    'confirmedAt': confirmedAt?.toIso8601String(),
  };
  factory EstimateReviewInput.fromPayload(Map<String, Object?> payload) =>
      EstimateReviewInput(
        base: decodeWorkRecord(
          (payload['base'] as Map).cast<String, Object?>(),
        ),
        baseRevision: payload['baseRevision'] as int,
        decision: EstimateCompanyReviewDecision.values.byName(
          payload['decision'] as String,
        ),
        reason: payload['reason'] as String,
        confirmedAt: payload['confirmedAt'] == null
            ? null
            : DateTime.parse(payload['confirmedAt'] as String),
      );
}

class EstimateReviewDraftController
    extends DraftWorkflowController<EstimateReviewInput> {
  EstimateReviewDraftController._(DraftAutosaveSession session, this._commit)
    : super(
        session,
        (input) => input.toPayload(),
        EstimateReviewInput.fromPayload,
      );
  final Future<WorkRecord?> Function(EstimateReviewInput, LocalDraftCheckpoint)
  _commit;
  EstimateReviewInput get input => recoveredInput!;
  void updateReason(String value) => updateInput(input.withReason(value));
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

extension EstimateReviewDraftWorkflow on WorkPersistenceSession {
  void validateEstimateReviewHandoff(
    EstimateReviewDraftController controller, {
    required String recordId,
    required EstimateCompanyReviewDecision decision,
    required EstimatePermissions reviewPermissions,
  }) {
    final current = records
        .where((record) => record.id == recordId)
        .firstOrNull;
    if (controller.session.organizationId != permissions.organizationId ||
        controller.session.ownerId != permissions.actorEmployeeId ||
        controller.session.domain != 'work/estimate-review' ||
        controller.input.base.id != recordId ||
        controller.input.decision != decision ||
        current == null ||
        !permissions.canEdit(current)) {
      throw StateError('Selected review belongs to another workflow.');
    }
    EstimateReviewInput(
      base: current,
      baseRevision: storageRevisionFor(recordId),
      decision: decision,
    ).validateReview(reviewPermissions);
  }

  Future<EstimateReviewDraftController> openEstimateReviewDraft(
    WorkRecord expected, {
    required EstimateCompanyReviewDecision decision,
    required EstimatePermissions reviewPermissions,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final current = records.where((r) => r.id == expected.id).firstOrNull;
    if (current == null ||
        !permissions.canEdit(current) ||
        canonicalJson(encodeWorkRecord(current)) !=
            canonicalJson(encodeWorkRecord(expected))) {
      throw StateError('This estimate changed. Reopen it before reviewing.');
    }
    final initial = EstimateReviewInput(
      base: current,
      baseRevision: storageRevisionFor(current.id),
      decision: decision,
    );
    initial.validateReview(reviewPermissions);
    final draft = DraftAutosaveSession(
      store: drafts,
      organizationId: permissions.organizationId,
      domain: 'work/estimate-review',
      draftId:
          recoverySelection?.draftId ??
          'edit-${permissions.actorEmployeeId}-${current.id}-${decision.name}',
      ownerId: permissions.actorEmployeeId,
    );
    void validate(EstimateReviewInput input) {
      if (input.base.id != current.id ||
          input.base.createdByEmployeeId != current.createdByEmployeeId ||
          input.baseRevision < 1 ||
          input.decision != decision ||
          !permissions.canEdit(input.base) ||
          (input.confirmedAt != null && !input.confirmedAt!.isUtc)) {
        throw StateError('Saved review does not match this decision.');
      }
      input.validateReview(reviewPermissions);
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
      final controller = EstimateReviewDraftController._(draft, (
        input,
        checkpoint,
      ) async {
        validate(input);
        final record = input.confirmedRecord(permissions.actorEmployeeId);
        final saved = await save(
          records: [record],
          expectedStorageRevisions: {record.id: input.baseRevision},
          draftCheckpoint: checkpoint,
        );
        return saved ? record : null;
      });
      if (controller.recoveredInput == null) {
        controller.updateInput(initial);
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
