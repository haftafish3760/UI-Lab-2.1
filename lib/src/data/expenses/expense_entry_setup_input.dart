import 'expense_workflow_models.dart';

enum ExpenseSetupDestination { manual, receipt }

/// Identifies unfinished work, never a route, widget, or database row type.
class ExpenseSetupContinuation {
  ExpenseSetupContinuation({
    required this.destination,
    required this.id,
    required this.revision,
  }) {
    if (id.trim().isEmpty || revision < 1) {
      throw const FormatException('Invalid expense continuation.');
    }
  }
  final ExpenseSetupDestination destination;
  final String id;
  final int revision;

  Map<String, Object?> toPayload() => {
    'destination': destination.name,
    'id': id,
    'revision': revision,
  };

  factory ExpenseSetupContinuation.fromPayload(Map<String, Object?> value) =>
      ExpenseSetupContinuation(
        destination: ExpenseSetupDestination.values.byName(
          value['destination'] as String,
        ),
        id: value['id'] as String,
        revision: value['revision'] as int,
      );
}

/// Unconfirmed expense setup, independent of routes and visual composition.
class ExpenseEntrySetupInput {
  const ExpenseEntrySetupInput({
    required this.date,
    required this.category,
    required this.receiptType,
    this.pendingCategory,
    this.continuation,
  });

  final DateTime date;
  final ExpenseCategory category;
  final ExpenseReceiptType receiptType;
  final ExpenseCategory? pendingCategory;
  final ExpenseSetupContinuation? continuation;

  ExpenseEntrySetupInput change({
    ExpenseCategory? category,
    ExpenseReceiptType? receiptType,
    ExpenseCategory? pendingCategory,
    bool clearPendingCategory = false,
  }) => ExpenseEntrySetupInput(
    date: date,
    continuation: continuation,
    category: category ?? this.category,
    receiptType: receiptType ?? this.receiptType,
    pendingCategory: clearPendingCategory
        ? null
        : pendingCategory ?? this.pendingCategory,
  );

  Map<String, Object?> toPayload() => {
    'version': 1,
    'date': date.toIso8601String(),
    'category': category.name,
    'receiptType': receiptType.name,
    'pendingCategory': pendingCategory?.name,
    if (continuation != null) 'continuation': continuation!.toPayload(),
  };

  factory ExpenseEntrySetupInput.fromPayload(Map<String, Object?> value) {
    if (value['version'] != 1 || value['date'] is! String) {
      throw const FormatException('Unsupported expense setup.');
    }
    final rawDate = value['date'] as String;
    final date = DateTime.tryParse(rawDate);
    if (date == null || date.toIso8601String() != rawDate) {
      throw const FormatException('Invalid expense setup date.');
    }
    return ExpenseEntrySetupInput(
      date: date,
      continuation: value['continuation'] == null
          ? null
          : ExpenseSetupContinuation.fromPayload(
              (value['continuation'] as Map).cast<String, Object?>(),
            ),
      category: ExpenseCategory.values.byName(value['category'] as String),
      receiptType: ExpenseReceiptType.values.byName(
        value['receiptType'] as String,
      ),
      pendingCategory: value['pendingCategory'] == null
          ? null
          : ExpenseCategory.values.byName(value['pendingCategory'] as String),
    );
  }
}
