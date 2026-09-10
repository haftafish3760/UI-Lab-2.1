part of 'expense_editor_screen.dart';

extension _ExpenseNestedLineRecovery on _ExpenseEditorScreenState {
  Future<void> _openRequestedExpenseLine() async {
    if (_pendingLine != null) {
      await _openExpenseLine();
      return;
    }
    final item = _lineItems
        .where((line) => line.id == widget.initialLineId)
        .firstOrNull;
    if (item == null) {
      _refresh(
        () => _confirmationError =
            'This item is no longer available in the expense. Review the expense before making changes.',
      );
      return;
    }
    await _openExpenseLine(item);
  }

  Future<void> _openExpenseLine([ExpenseLineItem? item]) async {
    if (_saving || _draftOpening) return;
    final pending = _pendingLine;
    final editingId = pending == null ? item?.id : pending.editingId;
    final initial = editingId == null
        ? null
        : _lineItems.where((line) => line.id == editingId).firstOrNull;
    final line = await showExpenseLineItemEditor(
      context,
      initial: initial,
      defaultCategory: _category,
      jobId: widget.existing?.jobId ?? _draftJobId,
      jobLabel: _job.text.trim().isEmpty ? null : _job.text.trim(),
      draftSession: _draft,
      recoveryInput: pending?.input,
      onDraftChanged: _draft == null
          ? null
          : (input) {
              _refresh(
                () => _pendingLine = PendingExpenseLineInput(
                  editingId: editingId,
                  input: input,
                ),
              );
              _captureExpenseInput();
            },
    );
    if (!mounted || line == null) return;
    _refresh(() {
      final index = _lineItems.indexWhere((item) => item.id == line.id);
      if (index < 0) {
        _lineItems.add(line);
      } else {
        _lineItems[index] = line;
      }
      _pendingLine = null;
    });
    _syncTotalsFromLines();
    _captureExpenseInput();
    try {
      await _draft?.flush();
    } on Object {
      /* Shared draft status exposes retry. */
    }
  }

  Future<void> _discardPendingExpenseLine() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unfinished item changes?'),
        content: const Text('Previously completed items stay unchanged.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep working'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard item changes'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    _refresh(() => _pendingLine = null);
    _captureExpenseInput();
    try {
      await _draft?.flush();
    } on Object {
      /* Shared draft status exposes retry. */
    }
  }
}
