import '../prototype_financial_models.dart';
import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/local_record_command.dart';
import 'direct_payment_draft_workflow.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';

class DirectPaymentDraftRecovery {
  DirectPaymentDraftRecovery(this._work) {
    _catalog = DraftRecoveryCatalog(
      repository: _work.drafts,
      organizationId: _work.permissions.organizationId,
      ownerId: _work.permissions.actorEmployeeId,
      handlers: [handler],
    );
  }

  final WorkPersistenceSession _work;
  late final DraftRecoveryCatalog _catalog;
  bool get _canList =>
      _work.permissions.canRecordPayments &&
      _work.permissions.visibleCreatorIds.isNotEmpty;

  DraftRecoveryHandler get handler => DraftRecoveryHandler(
    domain: 'work/direct-payment-editor',
    workflowLabel: 'Payment',
    canList: () => _canList,
    inspect: _inspect,
    canDiscard: (_) async => _canList,
  );

  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);

  Future<DraftRecoveryPreview?> _inspect(Map<String, Object?> raw) async {
    late DirectPaymentInput input;
    try {
      input = DirectPaymentInput.fromPayload(raw);
      if (input.paymentId.isEmpty ||
          input.linkKind == PaymentLinkKind.invoice ||
          input.linkKind == PaymentLinkKind.quote) {
        throw StateError('Invalid payment input.');
      }
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved payment input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    final entries = await _work.repository.queryFinancialEntries(
      organizationId: _work.permissions.organizationId,
      visibleActorIds: _work.permissions.visibleCreatorIds,
    );
    if (entries.any((entry) => entry.id == input.paymentId)) {
      return const DraftRecoveryPreview(
        title: 'Payment was already recorded',
        availability: DraftRecoveryAvailability.conflict,
      );
    }
    if (input.linkKind != PaymentLinkKind.none) {
      final parent = await _work.repository.find(
        organizationId: _work.permissions.organizationId,
        recordId: input.sourceId,
        visibleCreatorIds: _work.permissions.visibleCreatorIds,
      );
      final kind = input.linkKind == PaymentLinkKind.job
          ? WorkRecordKind.job
          : WorkRecordKind.estimate;
      if (parent == null || parent.record.kind != kind) {
        return const DraftRecoveryPreview(
          title: 'Saved payment — linked work unavailable',
          availability: DraftRecoveryAvailability.parentUnavailable,
        );
      }
    }
    return DraftRecoveryPreview(
      title: input.description.trim().isEmpty
          ? 'Unfinished payment'
          : input.description.trim(),
    );
  }

  Future<DirectPaymentDraftController> resume(DraftRecoveryEntry entry) async {
    final current = await _catalog.refresh(entry);
    if (current.preview.availability != DraftRecoveryAvailability.recoverable) {
      throw StateError('Saved payment input requires review before resuming.');
    }
    final saved = await _work.drafts.find(
      organizationId: _work.permissions.organizationId,
      ownerId: _work.permissions.actorEmployeeId,
      domain: current.domain,
      draftId: current.draftId,
    );
    if (saved == null || saved.revision != current.revision) {
      throw const LocalRecordConflict(
        'Selected input changed; refresh recovery.',
      );
    }
    final input = DirectPaymentInput.fromPayload(_work.drafts.decode(saved));
    return _work.openDirectPaymentDraft(
      initialDay: input.receivedOn,
      recoverySelection: DraftRecoverySelection(
        domain: current.domain,
        draftId: current.draftId,
        revision: current.revision,
      ),
    );
  }
}
