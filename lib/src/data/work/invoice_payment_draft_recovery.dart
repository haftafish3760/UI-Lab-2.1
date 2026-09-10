import '../storage/draft_recovery_catalog.dart';
import '../storage/draft_recovery_selection.dart';
import '../storage/local_record_command.dart';
import 'invoice_payment_draft_workflow.dart';
import 'models/work_models.dart';
import 'work_persistence_session.dart';

/// Payment input retains its identity and raw amount. Recovery never posts money;
/// the existing confirmation service validates against the current balance.
class InvoicePaymentDraftRecovery {
  InvoicePaymentDraftRecovery(this._work) {
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
    domain: 'work/payment-editor',
    workflowLabel: 'Invoice payment',
    canList: () => _canList,
    inspect: _inspect,
    canDiscard: (_) async => _canList,
  );
  Future<List<DraftRecoveryEntry>> list() => _catalog.list();
  Future<void> discard(DraftRecoveryEntry entry) => _catalog.discard(entry);
  Future<DraftRecoveryPreview?> _inspect(Map<String, Object?> raw) async {
    late InvoicePaymentInput input;
    try {
      input = InvoicePaymentInput.fromPayload(raw);
      if (input.invoiceId.isEmpty ||
          input.paymentId.isEmpty ||
          !InvoicePaymentInput.paymentMethods.contains(input.method)) {
        throw StateError('Invalid payment identity.');
      }
    } on Object {
      return const DraftRecoveryPreview(
        title: 'Saved payment input unavailable — kept on this device',
        availability: DraftRecoveryAvailability.unreadable,
      );
    }
    final parent = await _work.repository.find(
      organizationId: _work.permissions.organizationId,
      recordId: input.invoiceId,
      visibleCreatorIds: _work.permissions.visibleCreatorIds,
    );
    if (parent == null || parent.record.kind != WorkRecordKind.invoice) {
      return DraftRecoveryPreview(
        title: 'Saved input — original invoice unavailable',
        availability: DraftRecoveryAvailability.parentUnavailable,
        recordId: input.invoiceId,
      );
    }
    final invoice = parent.record;
    final entries = await _work.repository.queryFinancialEntries(
      organizationId: _work.permissions.organizationId,
      visibleActorIds: _work.permissions.visibleCreatorIds,
    );
    final availability = entries.any((e) => e.id == input.paymentId)
        ? DraftRecoveryAvailability.conflict
        : invoice.status == WorkRecordStatus.draft
        ? DraftRecoveryAvailability.parentUnavailable
        : DraftRecoveryAvailability.recoverable;
    return DraftRecoveryPreview(
      title: invoice.title.trim().isEmpty ? invoice.number : invoice.title,
      availability: availability,
      recordId: invoice.id,
    );
  }

  Future<InvoicePaymentDraftController> resume(DraftRecoveryEntry entry) async {
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
    final input = InvoicePaymentInput.fromPayload(_work.drafts.decode(saved));
    return _work.openInvoicePaymentDraft(
      invoiceId: input.invoiceId,
      initialDay: input.receivedOn,
      recoverySelection: DraftRecoverySelection(
        domain: current.domain,
        draftId: current.draftId,
        revision: current.revision,
      ),
    );
  }
}
