import 'expense_workflow_models.dart';
import '../storage/local_draft_checkpoint.dart';
import '../storage/local_draft_store.dart';
import '../storage/sqlite_domain_snapshot_store.dart';
import 'authorized_expense_service.dart';
import 'authorized_recurring_expense_service.dart';
import 'expense_ui_repository_bridge.dart';
import 'expense_ui_repository_controller.dart';
import 'local_expense_repository.dart';
import 'local_recurring_expense_repository.dart';
import 'recurring_expense_payment_coordinator.dart';
import 'recurring_expense_ui_adapter.dart';
import 'recurring_expense_ui_controller.dart';

/// Executes authorized commands against buffers, then commits both aggregates.
/// UI projections reload after success; buffer mutations are never published.
class AtomicRecurringExpensePayment {
  const AtomicRecurringExpensePayment({
    required this.expenses,
    required this.recurringExpenses,
    required this.employeeLabelForId,
  });
  final LocalExpenseRepository expenses;
  final LocalRecurringExpenseRepository recurringExpenses;
  final RecurringExpenseEmployeeLabelResolver employeeLabelForId;

  Future<RecurringExpensePaymentResult> markPaid({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required double actualAmount,
    required DateTime paidOn,
    required ExpenseCommandPermissions expensePermissions,
    required RecurringExpenseCommandPermissions recurringPermissions,
    LocalDraftCheckpoint? draftCheckpoint,
  }) async {
    if (expensePermissions.organizationId !=
            recurringPermissions.organizationId ||
        expensePermissions.actorEmployeeId !=
            recurringPermissions.actorEmployeeId) {
      return const RecurringExpensePaymentResult.failure(
        'Expense and planned-payment sessions do not match.',
      );
    }
    try {
      return await expenses.withStagedWrites(
        (expenseStage) => recurringExpenses.withStagedWrites((
          recurringStage,
        ) async {
          final expenseController = ExpenseUiRepositoryController(
            ExpenseUiRepositoryBridge(
              service: AuthorizedExpenseService(expenseStage.repository),
              employeeLabelForId: employeeLabelForId,
              jobLabelForId: (_) => null,
            ),
            expensePermissions,
          );
          final recurringController = RecurringExpenseUiController(
            AuthorizedRecurringExpenseService(recurringStage.repository),
            recurringPermissions,
            employeeLabelForId,
          );
          try {
            if (!await expenseController.load() ||
                !await recurringController.load()) {
              return const RecurringExpensePaymentResult.failure(
                'Payment records could not be loaded.',
              );
            }
            final template = recurringController.recordById(templateId);
            final occurrence = recurringController.currentOccurrenceFor(
              templateId,
            );
            final completed = recurringController
                .occurrencesFor(templateId)
                .where((item) => item.id == occurrenceId)
                .firstOrNull;
            final confirmed = expenseController.recordById(
              'EXP-RECURRING-$occurrenceId',
            );
            if (template != null &&
                completed?.status == ScheduledExpenseOccurrenceStatus.paid &&
                confirmed != null &&
                actualAmount.isFinite &&
                actualAmount > 0 &&
                recurringController.canRecordPaymentFor(templateId) &&
                expenseController.canCreateForEmployee(
                  template.ownerEmployeeId,
                ) &&
                recurringController.revisionForId(templateId) ==
                    expectedTemplateRevision + 1 &&
                recurringController.occurrenceRevisionForId(occurrenceId) ==
                    expectedOccurrenceRevision + 1 &&
                completed!.expenseId == confirmed.id &&
                completed.actualAmount != null &&
                RecurringExpenseUiAdapter.money(
                      completed.actualAmount!,
                    ).minorUnits ==
                    RecurringExpenseUiAdapter.money(actualAmount).minorUnits &&
                confirmed.amount != null &&
                RecurringExpenseUiAdapter.money(confirmed.amount!).minorUnits ==
                    RecurringExpenseUiAdapter.money(actualAmount).minorUnits &&
                confirmed.vendor == template.title &&
                confirmed.category == template.category &&
                confirmed.paidByEmployeeId == template.ownerEmployeeId &&
                _samePaymentDay(completed.paidOn, paidOn) &&
                _samePaymentDay(confirmed.resolvedDate, paidOn)) {
              if (draftCheckpoint != null) {
                final retained =
                    await LocalDraftStore(
                      recurringStage.prepare().database,
                    ).find(
                      organizationId: recurringPermissions.organizationId,
                      domain: draftCheckpoint.domain,
                      draftId: draftCheckpoint.draftId,
                      ownerId: recurringPermissions.actorEmployeeId,
                    );
                if (draftCheckpoint.domain != 'expenses/planned-payment' ||
                    retained != null) {
                  return const RecurringExpensePaymentResult.failure(
                    'This payment is already recorded, but separate unfinished input remains. Review it before continuing.',
                  );
                }
              }
              return RecurringExpensePaymentResult.success(confirmed);
            }
            if (template == null ||
                occurrence == null ||
                occurrence.id != occurrenceId ||
                recurringController.revisionForId(templateId) !=
                    expectedTemplateRevision ||
                recurringController.occurrenceRevisionForId(occurrenceId) !=
                    expectedOccurrenceRevision) {
              return const RecurringExpensePaymentResult.failure(
                'This payment or its plan changed. Review it before recording payment.',
              );
            }
            if (draftCheckpoint != null) {
              final store = LocalDraftStore(recurringStage.prepare().database);
              final retained = await store.find(
                organizationId: recurringPermissions.organizationId,
                domain: draftCheckpoint.domain,
                draftId: draftCheckpoint.draftId,
                ownerId: recurringPermissions.actorEmployeeId,
              );
              final input = retained == null ? null : store.decode(retained);
              if (draftCheckpoint.domain != 'expenses/planned-payment' ||
                  retained?.revision != draftCheckpoint.revision ||
                  input?['templateId'] != templateId ||
                  input?['occurrenceId'] != occurrenceId ||
                  input?['baseTemplateRevision'] != expectedTemplateRevision ||
                  input?['baseRevision'] != expectedOccurrenceRevision) {
                return const RecurringExpensePaymentResult.failure(
                  'Saved payment input does not match this payment revision. Input was preserved.',
                );
              }
            }
            final result =
                await RecurringExpensePaymentCoordinator(
                  expenses: expenseController,
                  recurringExpenses: recurringController,
                ).markPaid(
                  template: template,
                  occurrence: occurrence,
                  actualAmount: actualAmount,
                  paidOn: paidOn,
                );
            if (!result.succeeded) return result;
            await commitPreparedDomainChanges(
              [expenseStage.prepare(), recurringStage.prepare()],
              organizationId: recurringPermissions.organizationId,
              ownerId: recurringPermissions.actorEmployeeId,
              checkpoint: draftCheckpoint,
            );
            expenseStage.publishCommitted();
            recurringStage.publishCommitted();
            return result;
          } finally {
            expenseController.dispose();
            recurringController.dispose();
          }
        }),
      );
    } on Object {
      return const RecurringExpensePaymentResult.failure(
        'The payment and Expense were not saved. Confirmed records and unfinished input were preserved. Retry saving.',
      );
    }
  }
}

bool _samePaymentDay(DateTime? left, DateTime right) =>
    left != null &&
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
