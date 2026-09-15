import '../expenses/expense_workflow_models.dart';
import '../storage/expense_display_preference_codec.dart';

enum ExpenseCategoryDisplayMode { off, topTen, custom }

class ExpenseDisplayPreferences {
  const ExpenseDisplayPreferences({
    required this.showJobLinks,
    this.weekStartsOn = DateTime.monday,
    required this.categoryMode,
    this.customCategories = const [],
    this.receiptTypes = const {
      ExpenseCategory.materials: ExpenseReceiptType.detailed,
    },
  });

  const ExpenseDisplayPreferences.defaults()
    : weekStartsOn = DateTime.monday,
      showJobLinks = true,
      categoryMode = ExpenseCategoryDisplayMode.off,
      customCategories = const [],
      receiptTypes = const {
        ExpenseCategory.materials: ExpenseReceiptType.detailed,
      };

  Map<String, Object?> toPayload() => {
    'version': 2,
    'weekStartsOn': weekStartsOn,
    'showJobLinks': showJobLinks,
    'categoryMode': categoryMode.name,
    'customCategories': customCategories.map((c) => c.name).toList(),
    'receiptTypes': {
      for (final e in receiptTypes.entries) e.key.name: e.value.name,
    },
  };
  static ExpenseDisplayPreferences fromPayload(Object? input) {
    if (!validExpenseDisplayPreferences(input)) {
      throw const FormatException('Invalid expense display preferences.');
    }
    final value = input as Map;
    return ExpenseDisplayPreferences(
      weekStartsOn: value['weekStartsOn'] as int? ?? DateTime.monday,
      showJobLinks: value['showJobLinks'] as bool,
      categoryMode: ExpenseCategoryDisplayMode.values.byName(
        value['categoryMode'] as String,
      ),
      customCategories: [
        for (final name in value['customCategories'] as List)
          ExpenseCategory.values.byName(name as String),
      ],
      receiptTypes: {
        for (final e in (value['receiptTypes'] as Map).entries)
          ExpenseCategory.values.byName(e.key as String): ExpenseReceiptType
              .values
              .byName(e.value as String),
      },
    );
  }

  final int weekStartsOn;
  final bool showJobLinks;
  final ExpenseCategoryDisplayMode categoryMode;
  final List<ExpenseCategory> customCategories;
  final Map<ExpenseCategory, ExpenseReceiptType> receiptTypes;

  ExpenseReceiptType receiptTypeFor(ExpenseCategory category) =>
      receiptTypes[category] ?? ExpenseReceiptType.basic;
}
