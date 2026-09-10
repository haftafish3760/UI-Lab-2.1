part of 'receipt_intake_screen.dart';

extension _ReceiptIntakeConfirmation on _ReceiptIntakeScreenState {
  Future<ExpenseRecord?> _confirmReceiptRecord(
    ExpenseRecord record, {
    int? expectedReceiptRevision,
  }) async {
    _reviewDraft = record;
    final draftController = ReceiptDraftUiScope.maybeOf(context);
    final expenseController = ExpenseUiScope.maybeOf(context);
    final draftId = _activeDraftId;
    if (draftController != null && draftId != null) {
      if (expenseController == null) {
        _showDraftMessage(
          'Expense storage is unavailable. The receipt draft remains open.',
        );
        return null;
      }
      final atomic = ReceiptSubmissionScope.maybeOf(context);
      if (atomic != null && expectedReceiptRevision == null) {
        _showDraftMessage(
          'Receipt review revision is missing. Reopen the receipt before saving.',
        );
        return null;
      }
      final result = atomic != null
          ? await atomic.submit(
              draftId: draftId,
              expectedReceiptRevision: expectedReceiptRevision!,
              reviewedRecord: record,
              paidByEmployeeId:
                  record.paidByEmployeeId ?? expenseController.actorEmployeeId,
              occurredAtUtc: DateTime.now().toUtc(),
            )
          : await ReceiptDraftSubmissionCoordinator(
              expenses: expenseController,
              receiptDrafts: draftController,
            ).submit(
              draftId: draftId,
              reviewedRecord: record,
              paidByEmployeeId:
                  record.paidByEmployeeId ??
                  OperationalScope.of(context).selectedEmployeeId ??
                  'alex',
              occurredAtUtc: DateTime.now().toUtc(),
            );
      if (!mounted) return null;
      if (!result.succeeded) {
        _showDraftMessage(result.message ?? 'The Expense was not saved.');
        return null;
      }
      return result.expense;
    }
    final saved = await PrototypeOperationsScope.of(context).addExpense(record);
    if (!mounted) return null;
    return saved;
  }
}
