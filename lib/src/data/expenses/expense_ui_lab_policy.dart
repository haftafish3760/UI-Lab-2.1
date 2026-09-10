import '../work/models/work_models.dart';
import 'authorized_expense_service.dart';
import 'expense_repository.dart';
import 'file_expense_repository.dart';

const expenseUiLabOrganizationId = 'maintainiac-demo-company';
const expenseUiLabOwnerEmployeeId = 'alex';
const expenseUiLabPermissionRevision = 'ui-lab-expense-owner-permissions-1';

ExpenseCommandPermissions expenseUiLabOwnerPermissions() =>
    ExpenseCommandPermissions(
      organizationId: expenseUiLabOrganizationId,
      actorEmployeeId: expenseUiLabOwnerEmployeeId,
      permissionRevision: expenseUiLabPermissionRevision,
      readScope: ExpenseReadScope.company,
      canCreate: true,
      canEdit: true,
      canDelete: true,
      canRestore: true,
      canApprove: true,
      canManageOtherEmployees: true,
    );

String expenseUiLabEmployeeLabel(String employeeId) => switch (employeeId) {
  'alex' => 'Alex Morgan',
  'jordan' => 'Jordan Lee',
  _ => 'Unknown employee',
};

String? expenseUiLabJobLabel(String jobId, Iterable<WorkRecord> workRecords) {
  for (final record in workRecords) {
    if (record.id == jobId) return '${record.number} · ${record.title}';
  }
  return null;
}

bool expenseRepositoryRecoveredFromDamage(ExpenseRepository repository) =>
    repository is FileExpenseRepository &&
    repository.recoveredFromDamagedSnapshot;
