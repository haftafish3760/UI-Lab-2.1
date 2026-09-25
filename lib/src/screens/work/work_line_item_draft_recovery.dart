part of 'work_items_editor.dart';

extension _WorkLineItemDraftRecovery on _WorkLineItemEditorState {
  WorkLineItem? get _original =>
      widget.initialItem ?? widget.recoveryInput?.original;

  void _restoreInput() {
    final input = widget.recoveryInput;
    if (input == null) return;
    _name.text = input.name;
    _description.text = input.description;
    _quantity.text = input.quantity;
    _workers.text = input.workers;
    _price.text = input.price;
    _cost.text = input.cost;
    _type = input.type;
    _unit = input.unit;
    _billingTreatment = input.billingTreatment;
  }

  void _changeInput(VoidCallback change) {
    _refresh(change);
    _captureInput();
  }

  WorkLineItemDraftInput get _input => WorkLineItemDraftInput(
    lineId: _lineId,
    original: _original,
    name: _name.text,
    description: _description.text,
    quantity: _quantity.text,
    workers: _workers.text,
    price: _price.text,
    cost: _cost.text,
    type: _type,
    unit: _unit,
    billingTreatment: _billingTreatment,
    sourceExpenseId:
        widget.recoveryInput?.sourceExpenseId ?? widget.sourceExpenseId,
    sourceExpenseLineId:
        widget.recoveryInput?.sourceExpenseLineId ?? widget.sourceExpenseLineId,
    sourceReceiptId:
        widget.recoveryInput?.sourceReceiptId ?? widget.sourceReceiptId,
    sourceStockId: widget.recoveryInput?.sourceStockId ?? widget.sourceStockId,
    initialCost:
        widget.recoveryInput?.initialCost ?? widget.initialCost?.toString(),
  );
  void _captureInput() {
    if (mounted) _refresh(() {});
    if (_dirty) {
      widget.onDraftChanged?.call(_input);
    } else {
      _restoreUnchangedDraft();
    }
  }

  void _restoreUnchangedDraft() {
    final savedInput = widget.recoveryInput;
    if (savedInput != null) {
      widget.onDraftChanged?.call(savedInput);
    } else {
      widget.onDiscardInput?.call(_lineId);
    }
  }

  Future<void> _leaveItem(Object? result) async {
    if (_exitPromptOpen) return;
    if (result != null || !_dirty) {
      if (result == null) _restoreUnchangedDraft();
      await _flushAndLeaveItem(result);
      return;
    }
    _exitPromptOpen = true;
    WorkLineItem? complete;
    try {
      complete = _input.confirmedItem(
        canSetCustomerPrice: widget.canSetCustomerPrice,
        canViewInternalCost: widget.canViewInternalCost,
        jobMaterialMode: _jobMaterialMode,
      );
    } on StateError {
      /* Incomplete input can still be retained. */
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Save item changes?'),
        content: Text(
          complete == null
              ? 'Keep this unfinished item to complete later. You can continue adding other items.'
              : 'Save your changes before returning to the items list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, 'stay'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, 'discard'),
            child: const Text('Discard changes'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, 'save'),
            child: Text(
              complete == null ? 'Save unfinished item' : 'Save changes',
            ),
          ),
        ],
      ),
    );
    _exitPromptOpen = false;
    if (!mounted || choice == null || choice == 'stay') return;
    if (choice == 'discard') {
      widget.onDiscardInput?.call(_lineId);
      await _flushAndLeaveItem(null);
    } else {
      _captureInput();
      await _flushAndLeaveItem(complete);
    }
  }

  Future<void> _flushAndLeaveItem(Object? result) async {
    try {
      await navigationDraft?.flush();
      if (mounted) await finishDraftRoute(result);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The item could not be saved. Your input is still here. Please retry.',
            ),
          ),
        );
      }
    }
  }
}
