import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_money.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_recurring_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_payment_coordinator.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_records.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_terms.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  test(
    'retry links one saved Expense after an interrupted second write',
    () async {
      final root = await Directory.systemTemp.createTemp('recurring-payment-');
      addTearDown(() => root.delete(recursive: true));
      final expenseDirectory = Directory('${root.path}/expenses');
      final recurringDirectory = Directory('${root.path}/recurring');
      final durableRecurring = await FileRecurringExpenseRepository.open(
        recurringDirectory,
      );
      final recurringRepository = _FailFirstPaymentRepository(durableRecurring);
      final recurring = _recurringController(recurringRepository);
      final expenses = _expenseController(
        await FileExpenseRepository.open(expenseDirectory),
      );
      addTearDown(recurring.dispose);
      addTearDown(expenses.dispose);
      await recurring.load();
      await expenses.load();
      final template = await recurring.create(_template());
      final occurrence = recurring.currentOccurrenceFor(template!.id)!;
      final coordinator = RecurringExpensePaymentCoordinator(
        expenses: expenses,
        recurringExpenses: recurring,
      );
      final paidOn = DateTime(2027, 1, 30);

      final interrupted = await coordinator.markPaid(
        template: template,
        occurrence: occurrence,
        actualAmount: 421.25,
        paidOn: paidOn,
      );
      expect(interrupted.succeeded, isFalse);
      expect(interrupted.message, contains('Expense was saved'));
      expect(interrupted.message, contains('reuse the saved Expense'));
      expect(expenses.records, hasLength(1));
      expect(recurring.currentOccurrenceFor(template.id)?.id, occurrence.id);

      final retried = await coordinator.markPaid(
        template: template,
        occurrence: occurrence,
        actualAmount: 421.25,
        paidOn: paidOn,
      );
      expect(retried.succeeded, isTrue);
      expect(expenses.records, hasLength(1));
      expect(retried.expense?.id, 'EXP-RECURRING-${occurrence.id}');
      expect(retried.expense?.amount, 421.25);
      expect(
        recurring.currentOccurrenceFor(template.id)?.dueOn,
        DateTime(2027, 2, 28),
      );

      final restartedExpenses = _expenseController(
        await FileExpenseRepository.open(expenseDirectory),
      );
      final restartedRecurring = _recurringController(
        await FileRecurringExpenseRepository.open(recurringDirectory),
      );
      addTearDown(restartedExpenses.dispose);
      addTearDown(restartedRecurring.dispose);
      await restartedExpenses.load();
      await restartedRecurring.load();
      expect(restartedExpenses.records, hasLength(1));
      final history = restartedRecurring.occurrencesFor(template.id);
      expect(
        history.where(
          (item) => item.status == ScheduledExpenseOccurrenceStatus.paid,
        ),
        hasLength(1),
      );
      expect(
        history
            .firstWhere(
              (item) => item.status == ScheduledExpenseOccurrenceStatus.paid,
            )
            .expenseId,
        retried.expense?.id,
      );
    },
  );
  for (final mismatch in ['organization', 'actor', 'denied']) {
    test(
      'payment preflight rejects $mismatch before creating an expense',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'payment-preflight-',
        );
        addTearDown(() => root.delete(recursive: true));
        final recurring = _recurringController(
          await FileRecurringExpenseRepository.open(
            Directory('${root.path}/recurring'),
          ),
          organizationId: mismatch == 'organization'
              ? 'other-company'
              : 'organization-1',
          actorEmployeeId: mismatch == 'actor'
              ? 'other-actor'
              : 'employee-alex',
          canRecordPayment: mismatch != 'denied',
        );
        final expenses = _expenseController(
          await FileExpenseRepository.open(Directory('${root.path}/expenses')),
        );
        addTearDown(recurring.dispose);
        addTearDown(expenses.dispose);
        await recurring.load();
        await expenses.load();
        final template = (await recurring.create(_template()))!;
        final occurrence = recurring.currentOccurrenceFor(template.id)!;
        final result =
            await RecurringExpensePaymentCoordinator(
              expenses: expenses,
              recurringExpenses: recurring,
            ).markPaid(
              template: template,
              occurrence: occurrence,
              actualAmount: 100,
              paidOn: DateTime(2030),
            );
        expect(result.succeeded, isFalse);
        expect(expenses.records, isEmpty);
        expect(recurring.currentOccurrenceFor(template.id)!.id, occurrence.id);
        expect(recurring.currentOccurrenceFor(template.id)!.isOpen, isTrue);
      },
    );
  }
}

ExpenseUiRepositoryController _expenseController(
  ExpenseRepository repository,
) => ExpenseUiRepositoryController(
  ExpenseUiRepositoryBridge(
    service: AuthorizedExpenseService(repository),
    employeeLabelForId: (_) => 'Alex Morgan',
    jobLabelForId: (_) => null,
  ),
  ExpenseCommandPermissions(
    organizationId: 'organization-1',
    actorEmployeeId: 'employee-alex',
    permissionRevision: 'permissions-1',
    readScope: ExpenseReadScope.company,
    canCreate: true,
    canEdit: true,
    canDelete: true,
    canRestore: true,
    canApprove: true,
    canManageOtherEmployees: true,
  ),
);

RecurringExpenseUiController _recurringController(
  RecurringExpenseRepository repository, {
  String organizationId = 'organization-1',
  String actorEmployeeId = 'employee-alex',
  bool canRecordPayment = true,
}) => RecurringExpenseUiController(
  AuthorizedRecurringExpenseService(repository),
  RecurringExpenseCommandPermissions(
    organizationId: organizationId,
    actorEmployeeId: actorEmployeeId,
    permissionRevision: 'permissions-1',
    readScope: RecurringExpenseReadScope.company,
    canManage: true,
    canRecordPayment: canRecordPayment,
    canManageOtherEmployees: true,
  ),
  (_) => 'Alex Morgan',
);

ScheduledExpenseRecord _template() => ScheduledExpenseRecord(
  id: 'vehicle-insurance',
  title: 'Commercial vehicle insurance',
  category: ExpenseCategory.vehicleInsurance,
  amount: 418,
  nextDueOn: DateTime(2027, 1, 31),
  kind: ExpenseScheduleKind.monthly,
  ownerEmployeeId: 'employee-alex',
  owner: 'Alex Morgan',
  reminderDaysBefore: const [7, 1],
  receiptRequired: true,
  dueDay: 31,
);

class _FailFirstPaymentRepository implements RecurringExpenseRepository {
  _FailFirstPaymentRepository(this._delegate);

  final RecurringExpenseRepository _delegate;
  bool _failNextPayment = true;

  @override
  Future<RecurringExpenseMutationResult> recordPaidOccurrence({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required ExpenseMoney actualAmount,
    required DateTime paidOn,
    required String expenseId,
    required RecurringExpenseMutationContext context,
  }) {
    if (_failNextPayment) {
      _failNextPayment = false;
      throw const RecurringExpenseStorageException('Simulated interruption.');
    }
    return _delegate.recordPaidOccurrence(
      templateId: templateId,
      occurrenceId: occurrenceId,
      expectedTemplateRevision: expectedTemplateRevision,
      expectedOccurrenceRevision: expectedOccurrenceRevision,
      actualAmount: actualAmount,
      paidOn: paidOn,
      expenseId: expenseId,
      context: context,
    );
  }

  @override
  Future<RecurringExpenseMutationResult> createTemplate({
    required StoredRecurringExpenseTemplate template,
    required StoredRecurringExpenseOccurrence initialOccurrence,
    required RecurringExpenseMutationContext context,
  }) => _delegate.createTemplate(
    template: template,
    initialOccurrence: initialOccurrence,
    context: context,
  );

  @override
  Future<StoredRecurringExpenseTemplate?> findTemplate({
    required String templateId,
    required RecurringExpenseAccess access,
  }) => _delegate.findTemplate(templateId: templateId, access: access);

  @override
  Future<StoredRecurringExpenseOccurrence?> findOccurrence({
    required String occurrenceId,
    required RecurringExpenseAccess access,
  }) => _delegate.findOccurrence(occurrenceId: occurrenceId, access: access);

  @override
  Future<List<StoredRecurringExpenseOccurrence>> queryOccurrences(
    RecurringExpenseOccurrenceQuery query,
  ) => _delegate.queryOccurrences(query);

  @override
  Future<List<StoredRecurringExpenseTemplate>> queryTemplates(
    RecurringExpenseTemplateQuery query,
  ) => _delegate.queryTemplates(query);

  @override
  Future<StoredRecurringExpenseTemplate> setTemplateState({
    required String templateId,
    required RecurringExpenseState state,
    required int expectedRevision,
    required RecurringExpenseMutationContext context,
  }) => _delegate.setTemplateState(
    templateId: templateId,
    state: state,
    expectedRevision: expectedRevision,
    context: context,
  );

  @override
  Future<RecurringExpenseMutationResult> skipOccurrence({
    required String templateId,
    required String occurrenceId,
    required int expectedTemplateRevision,
    required int expectedOccurrenceRevision,
    required RecurringExpenseMutationContext context,
  }) => _delegate.skipOccurrence(
    templateId: templateId,
    occurrenceId: occurrenceId,
    expectedTemplateRevision: expectedTemplateRevision,
    expectedOccurrenceRevision: expectedOccurrenceRevision,
    context: context,
  );

  @override
  Future<RecurringExpenseMutationResult> updateOpenOccurrence({
    required String templateId,
    required StoredRecurringExpenseOccurrence occurrence,
    required int expectedTemplateRevision,
    required int expectedRevision,
    required RecurringExpenseMutationContext context,
  }) => _delegate.updateOpenOccurrence(
    templateId: templateId,
    occurrence: occurrence,
    expectedTemplateRevision: expectedTemplateRevision,
    expectedRevision: expectedRevision,
    context: context,
  );

  @override
  Future<RecurringExpenseMutationResult> updateTemplateAndOpenOccurrence({
    required StoredRecurringExpenseTemplate template,
    required int expectedTemplateRevision,
    required RecurringExpenseMutationContext context,
  }) => _delegate.updateTemplateAndOpenOccurrence(
    template: template,
    expectedTemplateRevision: expectedTemplateRevision,
    context: context,
  );
}
