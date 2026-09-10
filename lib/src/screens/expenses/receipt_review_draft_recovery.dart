part of 'expense_editor_screen.dart';

extension _ReceiptReviewDraftRecovery on _ExpenseEditorScreenState {
  Future<void> _openReceiptReviewDraft() async {
    final session = ReceiptSubmissionScope.maybeOf(context)!;
    try {
      final scope = OperationalScope.of(context);
      _draftOwnerId = scope.view == AppViewMode.technician
          ? session.expenses.actorEmployeeId
          : scope.selectedEmployeeId ?? session.expenses.actorEmployeeId;
      _draftOwnerLabel =
          demoEmployees
              .where((employee) => employee.id == _draftOwnerId)
              .firstOrNull
              ?.name ??
          'Unknown employee';
      final workflow =
          widget.recoveredReceiptWorkflow ??
          await session.openReviewDraft(
            receiptId: widget.receiptDraftId!,
            initial: _expenseInput,
          );
      if (!mounted) {
        await workflow.session.close();
        return;
      }
      if (widget.recoveredExpenseWorkflow != null ||
          workflow.session.organizationId !=
              session.receiptPermissions.organizationId ||
          workflow.session.ownerId !=
              session.receiptPermissions.actorEmployeeId ||
          workflow.source.draftId != widget.receiptDraftId ||
          !widget.permissions.canUseEditor(
            isExisting: false,
            isOwn: widget.existingRecordIsOwn,
            purpose: widget.purpose,
          )) {
        await workflow.session.close();
        _draft = null;
        throw StateError('Recovered receipt does not match this editor.');
      }
      _receiptWorkflow = workflow;
      _inputWorkflow = workflow;
      _draft = workflow.session;
      if (!workflow.recoveryAvailable) {
        throw StateError('Saved review is unavailable.');
      }
      _restoreExpenseDraftInput(workflow.input);
      _activateExpenseDraft(workflow.session);
      if (workflow.isStale) {
        _refresh(
          () => _confirmationError =
              'The receipt changed after this review started. Your input is preserved; review the changed receipt before confirming.',
        );
      }
    } on Object {
      if (mounted) {
        _refresh(
          () => _confirmationError =
              'Saved receipt review could not be opened. Leave and retry; retained input has been preserved.',
        );
      }
    }
  }
}
