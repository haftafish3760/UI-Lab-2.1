import 'expense_workflow_models.dart';

/// Unfinished domain input, including partial numeric text, independent of a form.
class ExpenseLineDraftInput {
  const ExpenseLineDraftInput({
    required this.itemId,
    required this.description,
    required this.partNumber,
    required this.quantity,
    required this.unitsPerPackage,
    required this.unitPrice,
    required this.unit,
    required this.category,
    this.jobId,
    this.jobLabel,
  });

  final String itemId;
  final String description;
  final String partNumber;
  final String quantity;
  final String unitsPerPackage;
  final String unitPrice;
  final String unit;
  final ExpenseCategory category;
  final String? jobId;
  final String? jobLabel;

  Map<String, Object?> toPayload() => {
    'itemId': itemId,
    'description': description,
    'partNumber': partNumber,
    'quantity': quantity,
    'unitsPerPackage': unitsPerPackage,
    'unitPrice': unitPrice,
    'unit': unit,
    'category': category.name,
    'jobId': jobId,
    'jobLabel': jobLabel,
  };

  factory ExpenseLineDraftInput.fromPayload(Map<String, Object?> value) =>
      ExpenseLineDraftInput(
        itemId: value['itemId'] as String,
        description: value['description'] as String,
        partNumber: value['partNumber'] as String,
        quantity: value['quantity'] as String,
        unitsPerPackage: value['unitsPerPackage'] as String,
        unitPrice: value['unitPrice'] as String,
        unit: value['unit'] as String,
        category: ExpenseCategory.values.byName(value['category'] as String),
        jobId: value['jobId'] as String?,
        jobLabel: value['jobLabel'] as String?,
      );
}

/// The edit target is separate from the unfinished line's stable identity.
class PendingExpenseLineInput {
  const PendingExpenseLineInput({this.editingId, required this.input});
  final String? editingId;
  final ExpenseLineDraftInput input;

  Map<String, Object?> toPayload() => {
    'editingId': editingId,
    'input': input.toPayload(),
  };

  factory PendingExpenseLineInput.fromPayload(Map<String, Object?> value) =>
      PendingExpenseLineInput(
        editingId: value['editingId'] as String?,
        input: ExpenseLineDraftInput.fromPayload(
          (value['input'] as Map).cast<String, Object?>(),
        ),
      );
}
