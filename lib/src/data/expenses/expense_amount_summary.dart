import 'expense_workflow_models.dart';

/// Summarizes already-authorized records without turning missing money into zero.
class ExpenseAmountSummary {
  factory ExpenseAmountSummary(Iterable<ExpenseRecord> records) {
    var knownMinorUnits = 0, missingCount = 0, enteredCount = 0;
    for (final record in records) {
      final value = record.amount;
      if (value == null) {
        missingCount++;
      } else {
        if (!value.isFinite || value < 0) {
          throw ArgumentError.value(value, 'amount', 'Invalid expense amount.');
        }
        enteredCount++;
        knownMinorUnits += (value * 100).round();
      }
    }
    return ExpenseAmountSummary._(knownMinorUnits, missingCount, enteredCount);
  }

  const ExpenseAmountSummary._(
    this.knownMinorUnits,
    this.missingCount,
    this.enteredCount,
  );
  final int knownMinorUnits;
  final int missingCount;
  final int enteredCount;
  double? get displayAmount =>
      enteredCount == 0 && missingCount > 0 ? null : knownMinorUnits / 100;
  String? get missingMessage => missingCount == 0
      ? null
      : missingCount == 1
      ? '1 receipt has no amount. Not included in the total.'
      : '$missingCount receipts have no amount. Not included in the total.';
}
