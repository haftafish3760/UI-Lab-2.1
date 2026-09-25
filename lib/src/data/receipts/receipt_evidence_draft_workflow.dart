import '../storage/draft_recovery_selection.dart';
import '../storage/draft_autosave_session.dart';
import '../storage/draft_workflow_controller.dart';
import '../storage/local_draft_checkpoint.dart';
import 'atomic_receipt_evidence_review.dart';
import 'receipt_draft_record.dart';
import 'receipt_evidence_review_input.dart';
import 'receipt_submission_session.dart';

class ReceiptEvidenceDraftController
    extends DraftWorkflowController<ReceiptEvidenceReviewInput> {
  ReceiptEvidenceDraftController._(
    DraftAutosaveSession session,
    this.source,
    this.recoveryAvailable,
    this._commit,
  ) : super(
        session,
        (input) => input.toPayload(),
        ReceiptEvidenceReviewInput.fromPayload,
      );
  final StoredReceiptDraft source;

  /// Invalid/stale input stays accessible for explicit discard, but cannot be
  /// edited, silently replaced or confirmed through this controller.
  final bool recoveryAvailable;
  final Future<StoredReceiptDraft> Function(
    ReceiptEvidenceReviewInput,
    LocalDraftCheckpoint,
  )
  _commit;
  ReceiptEvidenceReviewInput get input {
    if (!recoveryAvailable) {
      throw StateError('Saved review cannot be recovered.');
    }
    return recoveredInput!;
  }

  @override
  void updateInput(ReceiptEvidenceReviewInput input) {
    if (!recoveryAvailable) {
      throw StateError('Saved review cannot be replaced.');
    }
    input.validate(
      receiptId: source.draftId,
      revision: source.lifecycle.revision,
      availableIds: source.activeEvidence.map((e) => e.evidenceId).toSet(),
    );
    _validateSelectedSource(input, source);
    super.updateInput(input);
  }

  Future<StoredReceiptDraft> confirm() async {
    if (!recoveryAvailable) {
      throw StateError('Saved review cannot be confirmed.');
    }
    late StoredReceiptDraft result;
    await session.confirm((checkpoint) async {
      result = await _commit(input, checkpoint);
      return true;
    });
    return result;
  }
}

extension ReceiptEvidenceDraftWorkflow on ReceiptSubmissionSession {
  Future<ReceiptEvidenceDraftController> openEvidenceDraft({
    required String receiptId,
    required int expectedRevision,
    String? initiallySelectedId,
    DraftRecoverySelection? recoverySelection,
  }) async {
    final repository = drafts;
    final source = recoverySelection == null
        ? receipts.recordById(receiptId)
        : (await receipts.findById(draftId: receiptId)).record;
    final permissions = receiptPermissions;
    if (repository == null ||
        source == null ||
        source.organizationId != permissions.organizationId ||
        permissions.readAccess == null ||
        !permissions.canTarget(source) ||
        !(permissions.owns(source)
            ? permissions.canEditOwn
            : permissions.canEditTeam)) {
      throw StateError('Receipt evidence is unavailable.');
    }
    final draft = DraftAutosaveSession(
      store: repository,
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      domain: AtomicReceiptEvidenceReview.draftDomain,
      draftId: AtomicReceiptEvidenceReview.draftIdFor(
        permissions.actorEmployeeId,
        receiptId,
      ),
    );
    try {
      await draft.initialize();
      recoverySelection?.verify(
        openedDomain: draft.domain,
        openedDraftId: draft.draftId,
        openedRevision: draft.savedRevision,
        hasInput: draft.input.isNotEmpty,
      );

      final order = source.activeEvidence.map((e) => e.evidenceId).toList();
      bool available = true;
      ReceiptEvidenceReviewInput? initial;
      try {
        initial = draft.input.isEmpty
            ? ReceiptEvidenceReviewInput(
                sourceId: receiptId,
                sourceRevision: expectedRevision,
                orderedEvidenceIds: order,
                selectedDetails: source.activeSelectedDetails,
                itemReads: source.activeItemReads,
                stitchState: source.activeStitchState,
                selectedId: order.isEmpty
                    ? null
                    : order.contains(initiallySelectedId)
                    ? initiallySelectedId
                    : order.first,
              )
            : ReceiptEvidenceReviewInput.fromPayload(draft.input);
        initial.validate(
          receiptId: receiptId,
          revision: source.lifecycle.revision,
          availableIds: order.toSet(),
        );
        _validateSelectedSource(initial, source);
      } on Object {
        available = false;
      }
      final controller = ReceiptEvidenceDraftController._(
        draft,
        source,
        available,
        (input, checkpoint) => confirmEvidenceReview(
          receiptId: receiptId,
          expectedRevision: input.sourceRevision,
          orderedEvidenceIds: input.orderedEvidenceIds,
          checkpoint: checkpoint,
        ),
      );
      if (available && draft.input.isEmpty) controller.updateInput(initial!);
      return controller;
    } on Object {
      await draft.close().catchError((Object _) {});
      rethrow;
    }
  }
}

void _validateSelectedSource(
  ReceiptEvidenceReviewInput input,
  StoredReceiptDraft source,
) {
  final stitch = input.stitchState;
  if (stitch != null) {
    for (var index = 0; index < stitch.evidenceIds.length; index++) {
      if (!source.activeEvidence.any(
        (item) =>
            item.evidenceId == stitch.evidenceIds[index] &&
            item.sha256 == stitch.sourceHashes[index],
      )) {
        throw StateError('Stitch sources no longer match the retained photos.');
      }
    }
  }
  final details = input.selectedDetails;
  if (input.itemReads.any(
    (read) => !source.activeEvidence.any(
      (item) => read.matches(item.evidenceId, item.sha256),
    ),
  )) {
    throw StateError('The receipt item reading belongs to another image.');
  }
  if (details != null &&
      !source.activeEvidence.any(
        (item) => details.matches(item.evidenceId, item.sha256),
      )) {
    throw StateError('The selected receipt details belong to another image.');
  }
}
