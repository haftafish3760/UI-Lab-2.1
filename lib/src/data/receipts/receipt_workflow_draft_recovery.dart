import '../expenses/expense_draft_input.dart';
import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import 'atomic_receipt_evidence_review.dart';
import 'receipt_draft_record.dart';
import 'receipt_draft_ui_controller.dart';
import 'receipt_evidence_review_input.dart';
import 'receipt_evidence_draft_workflow.dart';
import 'receipt_review_draft_workflow.dart';
import 'receipt_submission_session.dart';

sealed class ResumedReceiptWorkflow {
  const ResumedReceiptWorkflow();
}

class ResumedReceiptReview extends ResumedReceiptWorkflow {
  const ResumedReceiptReview(this.controller);
  final ReceiptReviewDraftController controller;
}

class ResumedReceiptEvidence extends ResumedReceiptWorkflow {
  const ResumedReceiptEvidence(this.controller);
  final ReceiptEvidenceDraftController controller;
}

/// Saved review input is distinct from retained receipt evidence. Discovery
/// neither submits an expense nor changes evidence order or removal state.
class ReceiptWorkflowDraftRecovery {
  ReceiptWorkflowDraftRecovery(this._session) {
    final drafts = _session.drafts;
    if (drafts == null) throw StateError('Receipt storage is unavailable.');
    _catalog = DraftRecoveryCatalog(
      repository: drafts,
      organizationId: _session.receiptPermissions.organizationId,
      ownerId: _session.receiptPermissions.actorEmployeeId,
      handlers: [
        for (final evidence in [false, true])
          DraftRecoveryHandler(
            domain: evidence
                ? AtomicReceiptEvidenceReview.draftDomain
                : 'expenses/receipt-review',
            workflowLabel: evidence
                ? 'Receipt evidence review'
                : 'Receipt expense review',
            canList: () {
              final p = _session.receiptPermissions;
              return p.readAccess != null &&
                  (evidence
                      ? p.canEditOwn || p.canEditTeam
                      : p.canSubmitOwn || p.canSubmitTeam);
            },
            inspect: (raw) => _inspect(raw, evidence),
            canDiscard: (_) async => true,
          ),
      ],
    );
  }
  final ReceiptSubmissionSession _session;
  late final DraftRecoveryCatalog _catalog;
  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);

  Future<DraftRecoveryPreview?> _inspect(
    Map<String, Object?> raw,
    bool evidence,
  ) async {
    late String receiptId;
    late int revision;
    ReceiptEvidenceReviewInput? evidenceInput;
    ExpenseDraftInput? expenseInput;
    try {
      if (evidence) {
        evidenceInput = ReceiptEvidenceReviewInput.fromPayload(raw);
        receiptId = evidenceInput.sourceId;
        revision = evidenceInput.sourceRevision;
      } else {
        expenseInput = ExpenseDraftInput.fromPayload(raw);
        receiptId = expenseInput.receiptSourceId!;
        revision = expenseInput.receiptSourceRevision!;
        if (expenseInput.expenseId.isEmpty ||
            expenseInput.ownerId.isEmpty ||
            expenseInput.baseRecord != null ||
            expenseInput.baseRevision != null) {
          throw const FormatException();
        }
      }
      if (receiptId.isEmpty || revision < 1) throw const FormatException();
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved receipt input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    final lookup = await _session.receipts.findById(
      draftId: receiptId,
      includeClosed: true,
    );
    final source = lookup.record;
    if (source == null) {
      if (lookup.failure?.kind == ReceiptDraftUiFailureKind.permission) {
        return null;
      }
      return DraftRecoveryPreview(
        title: 'Receipt unavailable — saved input retained',
        availability: lookup.failure?.kind == ReceiptDraftUiFailureKind.notFound
            ? DraftRecoveryAvailability.parentUnavailable
            : DraftRecoveryAvailability.unavailable,
      );
    }
    final p = _session.receiptPermissions;
    if (!p.canTarget(source) ||
        !(evidence
            ? (p.owns(source) ? p.canEditOwn : p.canEditTeam)
            : (p.owns(source) ? p.canSubmitOwn : p.canSubmitTeam))) {
      return null;
    }
    if (expenseInput != null &&
        !_session.expenses.canCreateForEmployee(expenseInput.ownerId)) {
      return null;
    }
    if (source.state != ReceiptDraftState.inProgress) {
      return const DraftRecoveryPreview(
        title: 'Receipt closed — saved input retained',
        availability: DraftRecoveryAvailability.parentUnavailable,
      );
    }
    var availability = source.lifecycle.revision == revision
        ? DraftRecoveryAvailability.recoverable
        : DraftRecoveryAvailability.conflict;
    if (availability == DraftRecoveryAvailability.recoverable &&
        evidenceInput != null) {
      try {
        evidenceInput.validate(
          receiptId: receiptId,
          revision: revision,
          availableIds: source.activeEvidence.map((e) => e.evidenceId).toSet(),
        );
      } on Object {
        availability = DraftRecoveryAvailability.unreadable;
      }
    }
    return DraftRecoveryPreview(
      title: 'Saved receipt review',
      recordId: receiptId,
      availability: availability,
    );
  }

  Future<ResumedReceiptWorkflow> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('Receipt input requires review before resuming.');
    }
    final selected = DraftRecoverySelection(
      domain: current.domain,
      draftId: current.draftId,
      revision: current.revision,
    );
    final p = _session.receiptPermissions;
    final saved = await _session.drafts!.find(
      organizationId: p.organizationId,
      ownerId: p.actorEmployeeId,
      domain: current.domain,
      draftId: current.draftId,
    );
    if (saved == null) throw StateError('Saved receipt input is unavailable.');
    final raw = _session.drafts!.decode(saved);
    if (current.domain == AtomicReceiptEvidenceReview.draftDomain) {
      final input = ReceiptEvidenceReviewInput.fromPayload(raw);
      return ResumedReceiptEvidence(
        await _session.openEvidenceDraft(
          receiptId: input.sourceId,
          expectedRevision: input.sourceRevision,
          recoverySelection: selected,
        ),
      );
    }
    final input = ExpenseDraftInput.fromPayload(raw);
    return ResumedReceiptReview(
      await _session.openReviewDraft(
        receiptId: input.receiptSourceId!,
        initial: input,
        recoverySelection: selected,
      ),
    );
  }
}
