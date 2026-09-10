part of 'expense_editor_screen.dart';

extension _ExpenseEditorConfirmation on _ExpenseEditorScreenState {
  Future<void> _save() async {
    if (_saving || _draftOpening) return;
    if (_pendingLine != null) {
      _refresh(
        () => _confirmationError =
            'Finish or discard the unfinished item before saving this expense.',
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_receiptType == ExpenseReceiptType.detailed && _lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one receipt item, or choose Save the receipt total.',
          ),
        ),
      );
      return;
    }
    final scope = OperationalScope.of(context);
    final ownerId =
        _draftOwnerId ??
        (scope.view == AppViewMode.technician
            ? demoEmployees.first.id
            : scope.selectedEmployeeId);
    final owner = demoEmployees
        .firstWhere(
          (employee) => employee.id == ownerId,
          orElse: () => demoEmployees.first,
        )
        .name;
    // Preview fallback retains the existing owner selection behavior.
    _draftOwnerId ??= ownerId ?? demoEmployees.first.id;
    _draftOwnerLabel ??= owner;
    _captureExpenseInput();
    _refresh(() => _saving = true);
    try {
      final result = _expenseInput.confirmedRecord();
      await _draft?.flush();
      final saved = _draft == null
          ? (widget.onConfirm == null
                ? result
                : await widget.onConfirm!(result))
          : widget.purpose == ExpenseEditorPurpose.receiptReview
          ? await _receiptWorkflow!.confirm()
          : await _expenseWorkflow!.confirm();
      if (saved == null) throw StateError('Expense was not saved.');
      if (mounted) await finishDraftRoute(saved);
    } on Object {
      if (mounted) {
        _refresh(() {
          _saving = false;
          _confirmationError =
              'The expense was not saved. Your input is still here. Retry saving.';
        });
      }
    }
  }
}
