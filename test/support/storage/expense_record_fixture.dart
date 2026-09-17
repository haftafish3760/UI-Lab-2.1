import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';

/// One explicit persisted expense for storage tests, independent of app demos.
Future<void> createExpenseStorageFixture(ExpenseRepository repository) async {
  final now = DateTime.utc(2026, 9, 1);
  await repository.create(
    StoredExpenseRecord(
      expenseId: 'storage-fixture-expense',
      organizationId: expenseUiLabOrganizationId,
      createdByEmployeeId: 'alex',
      paidByEmployeeId: 'alex',
      expenseDate: now,
      vendorName: 'Test supplier',
      categoryId: 'materials',
      categoryLabelSnapshot: 'Materials',
      total: ExpenseMoney(minorUnits: 12345, currencyCode: 'USD'),
      approval: const ExpenseApproval(state: ExpenseApprovalState.notRequired),
      lifecycle: ExpenseLifecycle(
        revision: 1,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    ),
    context: ExpenseMutationContext(
      actorEmployeeId: 'alex',
      occurredAtUtc: now,
      permissionRevision: 'storage-fixture-v1',
    ),
  );
}
