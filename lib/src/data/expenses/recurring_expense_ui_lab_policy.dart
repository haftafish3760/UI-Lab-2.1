import 'authorized_recurring_expense_service.dart';
import 'expense_ui_lab_policy.dart';
import 'file_recurring_expense_repository.dart';
import 'recurring_expense_repository.dart';

const recurringExpenseUiLabPermissionRevision =
    'ui-lab-recurring-expense-owner-permissions-1';

RecurringExpenseCommandPermissions recurringExpenseUiLabOwnerPermissions() =>
    RecurringExpenseCommandPermissions(
      organizationId: expenseUiLabOrganizationId,
      actorEmployeeId: expenseUiLabOwnerEmployeeId,
      permissionRevision: recurringExpenseUiLabPermissionRevision,
      readScope: RecurringExpenseReadScope.company,
      canManage: true,
      canRecordPayment: true,
      canManageOtherEmployees: true,
    );

bool recurringExpenseRepositoryRecoveredFromDamage(
  RecurringExpenseRepository repository,
) =>
    repository is FileRecurringExpenseRepository &&
    repository.recoveredFromDamagedSnapshot;
