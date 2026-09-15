import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_period_range.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_period_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';

void main() {
  ExpenseRecord record(String owner, DateTime date) => ExpenseRecord(
    id: owner,
    vendor: 'Test supplier',
    category: ExpenseCategory.materials,
    amount: 10,
    date: date,
    owner: owner,
    paidByEmployeeId: owner,
  );

  test('periods include crossing-year week and exclude next period', () {
    final range = expensePeriodRange('Week', DateTime(2026, 1, 1), 1);
    expect(range.start, DateTime(2025, 12, 29));
    expect(range.end, DateTime(2026, 1, 5));
    const access = ExpensePermissions.development();
    expect(
      expenseVisibleInPeriod(record('alex', range.start), range, access, null),
      isTrue,
    );
    expect(
      expenseVisibleInPeriod(record('alex', range.end), range, access, null),
      isFalse,
    );
    expect(
      expensePeriodRange('Month', DateTime(2024, 2, 29), 1).end,
      DateTime(2024, 3, 1),
    );
    expect(
      () => expensePeriodRange('Unknown', DateTime(2026), 1),
      throwsArgumentError,
    );
    expect(
      () => expensePeriodRange('Week', DateTime(2026), 0),
      throwsArgumentError,
    );
  });

  test('employee selector cannot grant access to another employee', () {
    final range = expensePeriodRange('Year', DateTime(2026), 1);
    final other = record('other', DateTime(2026, 3, 2));
    const technician = ExpensePermissions.technicianDevelopment();
    expect(expenseVisibleInPeriod(other, range, technician, null), isFalse);
    expect(expenseVisibleInPeriod(other, range, technician, 'other'), isFalse);
    expect(
      expenseVisibleInPeriod(
        record('alex', DateTime(2026)),
        range,
        technician,
        null,
      ),
      isTrue,
    );
    expect(
      expenseVisibleInPeriod(
        other,
        range,
        const ExpensePermissions.development(),
        'other',
      ),
      isTrue,
    );
    expect(
      expenseVisibleInPeriod(
        other,
        range,
        const ExpensePermissions.development(),
        'alex',
      ),
      isFalse,
    );
  });
}
