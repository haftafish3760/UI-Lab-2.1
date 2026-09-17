import '../expenses/expense_category.dart';

/// Domain identifiers, independent of translated labels and widget layout.
/// Derive this set from the domain so new categories remain persistable.
final expenseDisplayCategoryNames = Set<String>.unmodifiable(
  ExpenseCategory.values.map((category) => category.name),
);

bool validExpenseCategoryChoices(Object? value) =>
    value is List &&
    value.length <= 10 &&
    value.toSet().length == value.length &&
    value.every(expenseDisplayCategoryNames.contains);

bool validExpenseReceiptChoices(Object? value) =>
    value is Map &&
    value.keys.every(expenseDisplayCategoryNames.contains) &&
    value.values.every(const {'basic', 'detailed'}.contains);

bool validExpenseDisplayPreferences(Object? value) =>
    value is Map &&
    ((value.length == 5 && value['version'] == 1) ||
        (value.length == 6 &&
            value['version'] == 2 &&
            value['weekStartsOn'] is int &&
            (value['weekStartsOn'] as int) >= 1 &&
            (value['weekStartsOn'] as int) <= 7)) &&
    value['showJobLinks'] is bool &&
    const {'off', 'topTen', 'custom'}.contains(value['categoryMode']) &&
    validExpenseCategoryChoices(value['customCategories']) &&
    validExpenseReceiptChoices(value['receiptTypes']);
