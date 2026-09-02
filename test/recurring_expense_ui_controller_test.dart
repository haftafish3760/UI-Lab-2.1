import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_recurring_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_recurring_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_expense_ui_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  test('controller preserves the recurring lifecycle across restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'recurring-ui-controller-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final controller = _controller(
      await FileRecurringExpenseRepository.open(directory),
    );
    addTearDown(controller.dispose);

    expect(await controller.load(), isTrue);
    expect(controller.sourceRevision, 1);
    final created = await controller.create(_template());
    expect(created?.amount, 418);
    expect(controller.sourceRevision, 2);

    final january = controller.currentOccurrenceFor('vehicle-insurance')!;
    final edited = await controller.updateOccurrence(
      january.copyWith(dueOn: DateTime(2027, 2, 2), expectedAmount: 425.75),
    );
    expect(edited?.expectedAmount, 425.75);
    expect(controller.recordById('vehicle-insurance')?.amount, 418);
    expect(controller.sourceRevision, 3);

    expect(await controller.skip('vehicle-insurance', january.id), isTrue);
    expect(controller.sourceRevision, 4);
    expect(
      controller.currentOccurrenceFor('vehicle-insurance')?.dueOn,
      DateTime(2027, 3, 31),
    );

    final restarted = _controller(
      await FileRecurringExpenseRepository.open(directory),
    );
    addTearDown(restarted.dispose);
    expect(await restarted.load(), isTrue);
    expect(restarted.records, hasLength(1));
    expect(
      restarted
          .occurrencesFor('vehicle-insurance')
          .where(
            (item) => item.status == ScheduledExpenseOccurrenceStatus.skipped,
          ),
      hasLength(1),
    );
    expect(
      restarted.currentOccurrenceFor('vehicle-insurance')?.dueOn,
      DateTime(2027, 3, 31),
    );
  });

  test(
    'controller reports denied writes without changing its source',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'recurring-ui-permission-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final controller = _controller(
        await FileRecurringExpenseRepository.open(directory),
        canManage: false,
      );
      addTearDown(controller.dispose);

      expect(await controller.load(), isTrue);
      final before = controller.sourceRevision;
      expect(await controller.create(_template()), isNull);
      expect(controller.sourceRevision, before);
      expect(
        controller.failureMessage,
        'You do not have permission to change that planned expense.',
      );
      expect(controller.records, isEmpty);
    },
  );
}

RecurringExpenseUiController _controller(
  RecurringExpenseRepository repository, {
  bool canManage = true,
}) => RecurringExpenseUiController(
  AuthorizedRecurringExpenseService(repository),
  RecurringExpenseCommandPermissions(
    organizationId: 'organization-1',
    actorEmployeeId: 'employee-alex',
    permissionRevision: 'permissions-1',
    readScope: RecurringExpenseReadScope.company,
    canManage: canManage,
    canRecordPayment: true,
    canManageOtherEmployees: true,
  ),
  (employeeId) => employeeId == 'employee-alex' ? 'Alex Morgan' : 'Unknown',
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
