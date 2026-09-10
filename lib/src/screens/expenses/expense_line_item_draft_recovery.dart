part of 'expense_line_item_editor.dart';

extension _ExpenseLineRawInput on _ExpenseLineItemEditorScreenState {
  List<TextEditingController> get _rawFields => [
    _description,
    _partNumber,
    _quantity,
    _unitsPerPackage,
    _unitPrice,
  ];

  void _restoreLineDraft() {
    final input = widget.recoveryInput;
    if (input == null) return;
    _itemId = input.itemId;
    _category = input.category;
    _unit = input.unit;
    _description.text = input.description;
    _partNumber.text = input.partNumber;
    _quantity.text = input.quantity;
    _unitsPerPackage.text = input.unitsPerPackage;
    _unitPrice.text = input.unitPrice;
  }

  ExpenseLineDraftInput get _lineInput => ExpenseLineDraftInput(
    itemId: _itemId,
    category: _category,
    unit: _unit,
    jobId: widget.recoveryInput?.jobId ?? widget.initial?.jobId ?? widget.jobId,
    jobLabel:
        widget.recoveryInput?.jobLabel ??
        widget.initial?.jobLabel ??
        widget.jobLabel,
    description: _description.text,
    partNumber: _partNumber.text,
    quantity: _quantity.text,
    unitsPerPackage: _unitsPerPackage.text,
    unitPrice: _unitPrice.text,
  );

  void _captureLineDraft() => widget.onDraftChanged?.call(_lineInput);

  void _changeLineUnit(String unit) {
    _refreshDraft(() => _unit = unit);
    _captureLineDraft();
  }
}
