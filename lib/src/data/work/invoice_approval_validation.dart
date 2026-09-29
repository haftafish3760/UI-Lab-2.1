part of 'work_persistence_session.dart';

extension _InvoiceApprovalValidation on WorkPersistenceSession {
  void _validateInvoiceApproval(WorkRecord next, WorkRecord? previous) {
    if (next.kind != WorkRecordKind.invoice) {
      if (next.requiresInvoiceApproval ||
          next.invoiceApprovalHistory.isNotEmpty) {
        throw StateError('Invoice approval belongs to an invoice.');
      }
      return;
    }
    if (permissions.requiresInvoiceApproval &&
        !next.requiresInvoiceApproval &&
        next.status == WorkRecordStatus.draft) {
      throw StateError('This account requires invoice approval.');
    }
    if (previous?.requiresInvoiceApproval == true &&
        !next.requiresInvoiceApproval) {
      throw StateError('Required invoice approval cannot be removed.');
    }
    final before =
        previous?.invoiceApprovalHistory ?? const <InvoiceApprovalEvent>[];
    final after = next.invoiceApprovalHistory;
    if (after.length < before.length || after.length > before.length + 1) {
      throw StateError('Invoice approval history must be retained.');
    }
    for (var i = 0; i < before.length; i++) {
      if (canonicalJson(before[i].toJson()) !=
          canonicalJson(after[i].toJson())) {
        throw StateError('An earlier invoice approval cannot be rewritten.');
      }
    }
    if (after.length == before.length) return;
    final event = after.last;
    if (previous == null ||
        previous.status != WorkRecordStatus.draft ||
        next.status != WorkRecordStatus.draft ||
        !next.requiresInvoiceApproval ||
        invoiceApprovalFingerprint(next) !=
            invoiceApprovalFingerprint(previous) ||
        event.contentFingerprint != invoiceApprovalFingerprint(next) ||
        event.actorEmployeeId != permissions.actorEmployeeId ||
        event.occurredOn.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 1)),
        ) ||
        (before.isNotEmpty &&
            event.occurredOn.isBefore(before.last.occurredOn))) {
      throw StateError(
        'Approve or submit the current saved invoice without changing its contents.',
      );
    }
    if (event.decision != InvoiceApprovalDecision.submitted) {
      if (!permissions.canApproveInvoices) {
        throw StateError('You do not have permission to approve invoices.');
      }
      if (before.isEmpty ||
          before.last.decision != InvoiceApprovalDecision.submitted ||
          before.last.contentFingerprint != event.contentFingerprint) {
        throw StateError('Submit this invoice for approval first.');
      }
      if (event.decision == InvoiceApprovalDecision.changesRequested &&
          event.note.trim().isEmpty) {
        throw StateError('Explain which changes are needed.');
      }
    }
  }
}

extension InvoiceApprovalCommands on WorkPersistenceSession {
  Future<bool> recordInvoiceApproval(
    WorkRecord record,
    InvoiceApprovalDecision decision, {
    String note = '',
  }) => save(
    records: [
      record.copyWith(
        requiresInvoiceApproval: true,
        invoiceApprovalHistory: [
          ...record.invoiceApprovalHistory,
          InvoiceApprovalEvent(
            decision: decision,
            actorEmployeeId: permissions.actorEmployeeId,
            occurredOn: DateTime.now().toUtc(),
            contentFingerprint: invoiceApprovalFingerprint(record),
            note: note.trim(),
          ),
        ],
      ),
    ],
  );
}
