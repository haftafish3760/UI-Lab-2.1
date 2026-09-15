import '../expenses/expense_workflow_models.dart';

/// User choices retained with the receipt before leaving for a device picker.
class ReceiptEntrySetup {
  const ReceiptEntrySetup({
    this.category = ExpenseCategory.uncategorized,
    this.type = ExpenseReceiptType.basic,
    this.pastedText = '',
  });

  final ExpenseCategory category;
  final ExpenseReceiptType type;
  final String pastedText;

  Map<String, Object?> toJson() => {
    'category': category.storageId,
    'type': type.name,
    'pastedText': pastedText,
  };

  factory ReceiptEntrySetup.fromJson(Map<String, Object?> json) {
    if (!json.containsKey('category') || json['pastedText'] is! String) {
      throw const FormatException('Invalid receipt setup.');
    }
    return ReceiptEntrySetup(
      category: ExpenseCategory.fromStorageId(json['category'] as String?),
      type: ExpenseReceiptType.values.byName(json['type'] as String),
      pastedText: json['pastedText'] as String,
    );
  }
}
