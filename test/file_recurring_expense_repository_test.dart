import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_recurring_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_records.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_terms.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_transitions.dart';

void main() {
  test('monthly payment is exact, restart-safe, and idempotent', () async {
    final directory = await Directory.systemTemp.createTemp('recurring-main-');
    addTearDown(() => directory.delete(recursive: true));
    final repository = await FileRecurringExpenseRepository.open(directory);
    final template = _template(dueOn: DateTime(2027, 1, 31));
    final occurrence = _occurrence(template);
    await repository.createTemplate(
      template: template,
      initialOccurrence: occurrence,
      context: _context(DateTime.utc(2027, 1, 2)),
    );

    final paid = await repository.recordPaidOccurrence(
      templateId: template.templateId,
      occurrenceId: occurrence.occurrenceId,
      expectedTemplateRevision: 1,
      expectedOccurrenceRevision: 1,
      actualAmount: const ExpenseMoney(minorUnits: 42125),
      paidOn: DateTime(2027, 1, 30),
      expenseId: 'expense-insurance-2027-01',
      context: _context(DateTime.utc(2027, 1, 30, 15)),
    );

    expect(paid.occurrence.actualAmount?.minorUnits, 42125);
    expect(paid.occurrence.expenseId, 'expense-insurance-2027-01');
    expect(paid.nextOccurrence?.dueOn, DateTime(2027, 2, 28));
    expect(paid.nextOccurrence?.expectedAmount.minorUnits, 41800);
    expect(paid.template.nextDueOn, DateTime(2027, 2, 28));

    final retry = await repository.recordPaidOccurrence(
      templateId: template.templateId,
      occurrenceId: occurrence.occurrenceId,
      expectedTemplateRevision: 1,
      expectedOccurrenceRevision: 1,
      actualAmount: const ExpenseMoney(minorUnits: 42125),
      paidOn: DateTime(2027, 1, 30),
      expenseId: 'expense-insurance-2027-01',
      context: _context(DateTime.utc(2027, 1, 30, 15, 1)),
    );
    expect(retry.occurrence.lifecycle.revision, 2);

    final reopened = await FileRecurringExpenseRepository.open(directory);
    final occurrences = await reopened.queryOccurrences(
      RecurringExpenseOccurrenceQuery(
        access: _companyAccess(),
        templateId: template.templateId,
      ),
    );
    expect(occurrences, hasLength(2));
    expect(occurrences.first.state, RecurringExpenseOccurrenceState.paid);
    expect(occurrences.last.dueOn, DateTime(2027, 2, 28));
  });

  test(
    'editing one payment preserves the template amount and cadence',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'recurring-edit-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = await FileRecurringExpenseRepository.open(directory);
      final template = _template(dueOn: DateTime(2027, 1, 31));
      final occurrence = _occurrence(template);
      await repository.createTemplate(
        template: template,
        initialOccurrence: occurrence,
        context: _context(DateTime.utc(2027, 1, 1)),
      );

      final edited = await repository.updateOpenOccurrence(
        templateId: template.templateId,
        occurrence: occurrence.copyWith(
          dueOn: DateTime(2027, 2, 2),
          expectedAmount: const ExpenseMoney(minorUnits: 42575),
        ),
        expectedTemplateRevision: 1,
        expectedRevision: 1,
        context: _context(DateTime.utc(2027, 1, 10)),
      );
      expect(edited.template.nextDueOn, DateTime(2027, 2, 2));
      expect(edited.template.expectedAmount.minorUnits, 41800);
      expect(edited.occurrence.expectedAmount.minorUnits, 42575);

      final paid = await repository.recordPaidOccurrence(
        templateId: template.templateId,
        occurrenceId: occurrence.occurrenceId,
        expectedTemplateRevision: 2,
        expectedOccurrenceRevision: 2,
        actualAmount: const ExpenseMoney(minorUnits: 42575),
        paidOn: DateTime(2027, 2, 2),
        expenseId: 'expense-insurance-edited',
        context: _context(DateTime.utc(2027, 2, 2, 13)),
      );
      expect(paid.nextOccurrence?.dueOn, DateTime(2027, 3, 31));
      expect(paid.nextOccurrence?.expectedAmount.minorUnits, 41800);
    },
  );

  test('one-time payment ends without creating another occurrence', () async {
    final directory = await Directory.systemTemp.createTemp('recurring-once-');
    addTearDown(() => directory.delete(recursive: true));
    final repository = await FileRecurringExpenseRepository.open(directory);
    final template = _template(
      id: 'license-renewal',
      dueOn: DateTime(2027, 4, 1),
      schedule: RecurringExpenseSchedule.oneTime(),
    );
    final occurrence = _occurrence(template);
    await repository.createTemplate(
      template: template,
      initialOccurrence: occurrence,
      context: _context(DateTime.utc(2027, 3, 1)),
    );

    final paid = await repository.recordPaidOccurrence(
      templateId: template.templateId,
      occurrenceId: occurrence.occurrenceId,
      expectedTemplateRevision: 1,
      expectedOccurrenceRevision: 1,
      actualAmount: template.expectedAmount,
      paidOn: template.nextDueOn,
      expenseId: 'expense-license-2027',
      context: _context(DateTime.utc(2027, 4, 1, 12)),
    );
    expect(paid.template.state, RecurringExpenseState.ended);
    expect(paid.nextOccurrence, isNull);
  });

  test(
    'authorized service scopes reads and protects another employee',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'recurring-auth-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = await FileRecurringExpenseRepository.open(directory);
      final alex = _template(dueOn: DateTime(2027, 5, 1));
      final jamie = _template(
        id: 'jamie-insurance',
        assignedEmployeeId: 'employee-jamie',
        dueOn: DateTime(2027, 5, 2),
      );
      await _seed(repository, alex);
      await _seed(repository, jamie);
      final service = AuthorizedRecurringExpenseService(repository);
      final own = RecurringExpenseCommandPermissions(
        organizationId: 'organization-1',
        actorEmployeeId: 'employee-alex',
        permissionRevision: 'permissions-2',
        readScope: RecurringExpenseReadScope.own,
        canManage: true,
        canRecordPayment: true,
      );

      expect(await service.queryTemplates(permissions: own), hasLength(1));
      await expectLater(
        service.setTemplateState(
          templateId: jamie.templateId,
          state: RecurringExpenseState.paused,
          expectedRevision: 1,
          permissions: own,
          occurredAtUtc: DateTime.utc(2027, 4, 2),
        ),
        throwsA(isA<RecurringExpensePermissionDeniedException>()),
      );
      final noRead = RecurringExpenseCommandPermissions(
        organizationId: 'organization-1',
        actorEmployeeId: 'employee-alex',
        permissionRevision: 'permissions-2',
        readScope: null,
      );
      await expectLater(
        service.queryTemplates(permissions: noRead),
        throwsA(isA<RecurringExpensePermissionDeniedException>()),
      );
    },
  );

  test('damaged newest snapshot falls back to the prior valid slot', () async {
    final directory = await Directory.systemTemp.createTemp(
      'recurring-recover-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = await FileRecurringExpenseRepository.open(directory);
    final template = _template(dueOn: DateTime(2027, 6, 1));
    await _seed(repository, template);
    await repository.setTemplateState(
      templateId: template.templateId,
      state: RecurringExpenseState.paused,
      expectedRevision: 1,
      context: _context(DateTime.utc(2027, 5, 2)),
    );
    await File.fromUri(
      directory.uri.resolve('recurring-expenses-1.json'),
    ).writeAsString('damaged');

    final reopened = await FileRecurringExpenseRepository.open(directory);
    expect(reopened.recoveredFromDamagedSnapshot, isTrue);
    final restored = await reopened.findTemplate(
      templateId: template.templateId,
      access: _companyAccess(),
    );
    expect(restored?.state, RecurringExpenseState.active);
  });

  test('failed write preserves the last valid recurring snapshot', () async {
    final directory = await Directory.systemTemp.createTemp('recurring-fail-');
    addTearDown(() => directory.delete(recursive: true));
    var writes = 0;
    final repository = await FileRecurringExpenseRepository.open(
      directory,
      snapshotWriter: (target, bytes) async {
        writes += 1;
        if (writes == 2) throw const FileSystemException('disk full');
        await target.writeAsBytes(bytes, flush: true);
      },
    );
    final template = _template(dueOn: DateTime(2027, 7, 1));
    await _seed(repository, template);
    await expectLater(
      repository.setTemplateState(
        templateId: template.templateId,
        state: RecurringExpenseState.paused,
        expectedRevision: 1,
        context: _context(DateTime.utc(2027, 6, 2)),
      ),
      throwsA(isA<RecurringExpenseStorageException>()),
    );

    final reopened = await FileRecurringExpenseRepository.open(directory);
    final restored = await reopened.findTemplate(
      templateId: template.templateId,
      access: _companyAccess(),
    );
    expect(restored?.state, RecurringExpenseState.active);
    expect(restored?.lifecycle.revision, 1);
  });

  test('reminders enforce five unique offsets', () {
    expect(
      () => RecurringExpenseReminderSettings(
        daysBefore: const [1, 3, 7, 14, 30, 60],
      ),
      throwsArgumentError,
    );
    expect(
      () => RecurringExpenseReminderSettings(daysBefore: const [1, 1]),
      throwsArgumentError,
    );
  });
}

StoredRecurringExpenseTemplate _template({
  String id = 'vehicle-insurance',
  String assignedEmployeeId = 'employee-alex',
  required DateTime dueOn,
  RecurringExpenseSchedule? schedule,
}) => StoredRecurringExpenseTemplate(
  templateId: id,
  organizationId: 'organization-1',
  createdByEmployeeId: 'employee-alex',
  assignedEmployeeId: assignedEmployeeId,
  title: 'Commercial vehicle insurance',
  categoryId: 'vehicle-insurance',
  categoryLabelSnapshot: 'Vehicle and insurance',
  expectedAmount: const ExpenseMoney(minorUnits: 41800),
  amountMode: RecurringExpenseAmountMode.fixed,
  schedule: schedule ?? RecurringExpenseSchedule.monthly(31),
  nextDueOn: dueOn,
  reminders: RecurringExpenseReminderSettings(daysBefore: const [7, 1]),
  receiptRequired: true,
  state: RecurringExpenseState.active,
  lifecycle: RecurringExpenseLifecycle(
    revision: 1,
    createdAtUtc: DateTime.utc(2027, 1, 1),
    updatedAtUtc: DateTime.utc(2027, 1, 1),
  ),
);

StoredRecurringExpenseOccurrence _occurrence(
  StoredRecurringExpenseTemplate template,
) => template.initialOccurrence(
  occurrenceId: recurringExpenseOccurrenceId(
    template.templateId,
    template.nextDueOn,
  ),
  occurredAtUtc: DateTime.utc(2027, 1, 1),
  actorEmployeeId: 'employee-alex',
  permissionRevision: 'permissions-1',
);

Future<void> _seed(
  FileRecurringExpenseRepository repository,
  StoredRecurringExpenseTemplate template,
) => repository.createTemplate(
  template: template,
  initialOccurrence: _occurrence(template),
  context: _context(DateTime.utc(2027, 1, 1)),
);

RecurringExpenseMutationContext _context(DateTime occurredAtUtc) =>
    RecurringExpenseMutationContext(
      actorEmployeeId: 'employee-alex',
      occurredAtUtc: occurredAtUtc,
      permissionRevision: 'permissions-1',
    );

RecurringExpenseAccess _companyAccess() => RecurringExpenseAccess.company(
  organizationId: 'organization-1',
  employeeId: 'employee-alex',
);
