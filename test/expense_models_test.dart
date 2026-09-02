import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  test('expense dates tolerate the legacy string representation', () {
    final record = ExpenseRecord(
      id: 'legacy',
      vendor: 'Legacy Vendor',
      category: ExpenseCategory.materials,
      amount: 12.50,
      date: '2026-08-25',
      owner: 'Alex Morgan',
    );

    expect(record.resolvedDate, DateTime(2026, 8, 25));
  });

  test('expense dates preserve typed DateTime values', () {
    final date = DateTime(2026, 8, 25, 14, 30);
    final record = ExpenseRecord(
      id: 'typed',
      vendor: 'Typed Vendor',
      category: ExpenseCategory.tools,
      amount: 42,
      date: date,
      owner: 'Alex Morgan',
    );

    expect(record.resolvedDate, same(date));
  });

  test('invalid expense dates are rejected without a type exception', () {
    expect(parseExpenseDate('not-a-date'), isNull);
    expect(parseExpenseDate(Object()), isNull);
  });
}
