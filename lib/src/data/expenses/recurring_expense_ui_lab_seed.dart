import 'expense_workflow_models.dart';
import 'authorized_recurring_expense_service.dart';
import 'recurring_expense_repository.dart';
import 'recurring_expense_ui_adapter.dart';
import 'recurring_expense_ui_lab_policy.dart';

const bool recurringExpenseUiLabDemoDataEnabled = bool.fromEnvironment(
  'MAINTAINIAC_UI_LAB_DEMO_DATA',
  defaultValue: true,
);

/// Adds deterministic UI Lab obligations only to a new, empty company store.
///
/// This is test-bed bootstrap data. It must remain disabled in release builds
/// and never overwrites a user's recurring-expense records.
Future<void> seedRecurringExpenseUiLabDemoDataIfEmpty(
  RecurringExpenseRepository repository,
) async {
  if (!recurringExpenseUiLabDemoDataEnabled) return;
  final permissions = recurringExpenseUiLabOwnerPermissions();
  final service = AuthorizedRecurringExpenseService(repository);
  final existing = await service.queryTemplates(permissions: permissions);
  if (existing.isNotEmpty) return;
  final now = DateTime.now().toUtc();
  for (final record in demoScheduledExpenses) {
    final stored = RecurringExpenseUiAdapter.newStoredTemplate(
      record: record,
      organizationId: permissions.organizationId,
      createdByEmployeeId: permissions.actorEmployeeId,
      occurredAtUtc: now,
    );
    await service.createTemplate(
      template: stored,
      initialOccurrence: stored.initialOccurrence(
        occurrenceId: _occurrenceId(stored.templateId, stored.nextDueOn),
        occurredAtUtc: now,
        actorEmployeeId: permissions.actorEmployeeId,
        permissionRevision: permissions.permissionRevision,
      ),
      permissions: permissions,
      occurredAtUtc: now,
      note: 'UI Lab demo bootstrap.',
    );
  }
}

String _occurrenceId(String templateId, DateTime dueOn) =>
    '$templateId-${dueOn.year.toString().padLeft(4, '0')}-'
    '${dueOn.month.toString().padLeft(2, '0')}-'
    '${dueOn.day.toString().padLeft(2, '0')}';
