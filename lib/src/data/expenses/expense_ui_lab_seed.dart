import '../../screens/expenses/expense_models.dart';
import 'expense_record_adapter.dart';
import 'expense_repository.dart';
import 'expense_ui_lab_policy.dart';

const expenseUiLabDemoDataEnabled = bool.fromEnvironment(
  'MAINTAINIAC_UI_LAB_DEMO_DATA',
  defaultValue: true,
);

Future<void> seedExpenseUiLabDemoDataIfEmpty(
  ExpenseRepository repository,
) async {
  if (!expenseUiLabDemoDataEnabled) return;
  final access = ExpenseAccess.company(
    organizationId: expenseUiLabOrganizationId,
    employeeId: expenseUiLabOwnerEmployeeId,
  );
  final existing = await repository.query(ExpenseQuery(access: access));
  if (existing.isNotEmpty) return;

  for (final record in demoExpenses.where(
    (candidate) => !candidate.requiresSubmitterAttention,
  )) {
    final paidByEmployeeId = record.paidByEmployeeId;
    if (paidByEmployeeId == null || paidByEmployeeId.trim().isEmpty) continue;
    final date = record.resolvedDate;
    if (date == null) continue;
    final occurredAtUtc = DateTime.utc(date.year, date.month, date.day, 12);
    final stored = ExpenseRecordAdapter.fromUiRecord(
      record: record,
      organizationId: expenseUiLabOrganizationId,
      createdByEmployeeId: expenseUiLabOwnerEmployeeId,
      paidByEmployeeId: paidByEmployeeId,
      nowUtc: occurredAtUtc,
      receiptId: record.receiptImageCount == 0
          ? null
          : 'ui-lab-receipt-${record.id}',
    );
    await repository.create(
      stored,
      context: ExpenseMutationContext(
        actorEmployeeId: expenseUiLabOwnerEmployeeId,
        occurredAtUtc: occurredAtUtc,
        permissionRevision: expenseUiLabPermissionRevision,
        note: 'UI Lab demo fixture bootstrap',
      ),
    );
  }
}
