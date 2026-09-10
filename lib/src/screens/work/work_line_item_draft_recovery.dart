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
  void _captureInput() => widget.onDraftChanged?.call(_input);
}
