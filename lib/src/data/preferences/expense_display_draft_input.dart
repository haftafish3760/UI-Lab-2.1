import '../expenses/expense_workflow_models.dart';
import '../storage/expense_display_preference_codec.dart';
import 'expense_display_preferences.dart';

/// Proposed choices remain separate from accepted settings, whether edited in
/// a dialog, a page or another future presentation.
class ExpenseDisplayDraftInput {
  ExpenseDisplayDraftInput({
    required ExpenseDisplayPreferences preferences,
    Set<ExpenseCategory>? pendingCategories,
    Map<ExpenseCategory, ExpenseReceiptType>? pendingReceiptTypes,
  }) : preferences = ExpenseDisplayPreferences.fromPayload(
         preferences.toPayload(),
       ),
       pendingCategories = pendingCategories == null
           ? null
           : Set.unmodifiable(pendingCategories),
       pendingReceiptTypes = pendingReceiptTypes == null
           ? null
           : Map.unmodifiable(pendingReceiptTypes);

  final ExpenseDisplayPreferences preferences;
  final Set<ExpenseCategory>? pendingCategories;
  final Map<ExpenseCategory, ExpenseReceiptType>? pendingReceiptTypes;
  bool get hasUnfinishedChoices =>
      pendingCategories != null || pendingReceiptTypes != null;

  Map<String, Object?> toPayload() => {
    'preferences': preferences.toPayload(),
    'pendingCategories': pendingCategories?.map((c) => c.name).toList(),
    'pendingReceiptTypes': pendingReceiptTypes == null
        ? null
        : {
            for (final entry in pendingReceiptTypes!.entries)
              entry.key.name: entry.value.name,
          },
  };

  factory ExpenseDisplayDraftInput.fromPayload(Map<String, Object?> payload) {
    final categories = payload['pendingCategories'];
    final receipts = payload['pendingReceiptTypes'];
    if (categories != null && !validExpenseCategoryChoices(categories)) {
      throw const FormatException('Invalid pending categories.');
    }
    if (receipts != null && !validExpenseReceiptChoices(receipts)) {
      throw const FormatException('Invalid pending receipt types.');
    }
    return ExpenseDisplayDraftInput(
      preferences: ExpenseDisplayPreferences.fromPayload(
        payload['preferences'],
      ),
      pendingCategories: categories == null
          ? null
          : {
              for (final name in categories as List)
                ExpenseCategory.values.byName(name as String),
            },
      pendingReceiptTypes: receipts == null
          ? null
          : {
              for (final entry in (receipts as Map).entries)
                ExpenseCategory.values.byName(entry.key as String):
                    ExpenseReceiptType.values.byName(entry.value as String),
            },
    );
  }
}
