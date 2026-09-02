import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ui_lab_2_1/src/data/expense_prototype_store.dart';
import 'package:ui_lab_2_1/src/data/notifications/authorized_notification_service.dart';
import 'package:ui_lab_2_1/src/data/notifications/file_notification_repository.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_demo_policy.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_terms.dart';
import 'package:ui_lab_2_1/src/data/notifications/recurring_expense_notification_publisher.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/expenses/scheduled_expense_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

ScheduledExpenseRecord _monthlyTemplate({
  DateTime? nextDueOn,
  ScheduledExpenseState state = ScheduledExpenseState.active,
}) => ScheduledExpenseRecord(
  id: 'vehicle-insurance',
  title: 'Commercial vehicle insurance',
  category: ExpenseCategory.vehicleInsurance,
  amount: 418,
  nextDueOn: nextDueOn ?? DateTime(2027, 1, 31),
  kind: ExpenseScheduleKind.monthly,
  ownerEmployeeId: 'alex',
  owner: 'Alex Morgan',
  reminderDaysBefore: const [7, 1],
  dueDay: 31,
  state: state,
  receiptRequired: true,
);

void main() {
  test(
    'monthly recurrence preserves the intended day through short months',
    () {
      final template = _monthlyTemplate();

      expect(
        template.nextDueAfter(DateTime(2027, 1, 31)),
        DateTime(2027, 2, 28),
      );
      expect(
        template.nextDueAfter(DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29),
      );
      expect(
        template.nextDueAfter(DateTime(2027, 2, 28)),
        DateTime(2027, 3, 31),
      );
    },
  );

  test('paying one occurrence posts one expense and advances the template', () {
    final store = ExpensePrototypeStore(
      expenses: const [],
      receiptDrafts: const [],
      scheduledExpenses: [_monthlyTemplate()],
    );
    addTearDown(store.dispose);
    final january = store.currentOccurrenceFor('vehicle-insurance')!;

    final expense = store.markScheduledExpensePaid(
      templateId: 'vehicle-insurance',
      occurrenceId: january.id,
      paidOn: DateTime(2027, 1, 30),
      actualAmount: 421.25,
    );

    expect(expense, isNotNull);
    expect(store.expenses, hasLength(1));
    expect(store.expenses.single.amount, 421.25);
    expect(store.expenses.single.resolvedDate, DateTime(2027, 1, 30));
    expect(
      store.occurrencesFor('vehicle-insurance').last.status,
      ScheduledExpenseOccurrenceStatus.paid,
    );
    expect(
      store.currentOccurrenceFor('vehicle-insurance')!.dueOn,
      DateTime(2027, 2, 28),
    );

    final retry = store.markScheduledExpensePaid(
      templateId: 'vehicle-insurance',
      occurrenceId: january.id,
      paidOn: DateTime(2027, 1, 30),
      actualAmount: 421.25,
    );
    expect(retry?.id, expense?.id);
    expect(store.expenses, hasLength(1));
    expect(
      store.currentOccurrenceFor('vehicle-insurance')!.dueOn,
      DateTime(2027, 2, 28),
    );
  });

  test('skipping an exact occurrence creates no expense and advances once', () {
    final store = ExpensePrototypeStore(
      expenses: const [],
      receiptDrafts: const [],
      scheduledExpenses: [_monthlyTemplate()],
    );
    addTearDown(store.dispose);
    final january = store.currentOccurrenceFor('vehicle-insurance')!;

    expect(
      store.skipScheduledExpense(
        templateId: 'vehicle-insurance',
        occurrenceId: january.id,
      ),
      isTrue,
    );
    expect(store.expenses, isEmpty);
    expect(
      store.currentOccurrenceFor('vehicle-insurance')!.dueOn,
      DateTime(2027, 2, 28),
    );
    expect(
      store.skipScheduledExpense(
        templateId: 'vehicle-insurance',
        occurrenceId: january.id,
      ),
      isFalse,
    );
  });

  test('editing one occurrence leaves the recurring template amount alone', () {
    final store = ExpensePrototypeStore(
      expenses: const [],
      receiptDrafts: const [],
      scheduledExpenses: [_monthlyTemplate()],
    );
    addTearDown(store.dispose);
    final january = store.currentOccurrenceFor('vehicle-insurance')!;

    expect(
      store.updateScheduledExpenseOccurrence(
        templateId: 'vehicle-insurance',
        occurrenceId: january.id,
        dueOn: DateTime(2027, 2, 2),
        expectedAmount: 425.75,
      ),
      isTrue,
    );
    final edited = store.currentOccurrenceFor('vehicle-insurance')!;
    expect(edited.dueOn, DateTime(2027, 2, 2));
    expect(edited.expectedAmount, 425.75);
    expect(store.scheduledExpenses.single.amount, 418);

    store.markScheduledExpensePaid(
      templateId: 'vehicle-insurance',
      occurrenceId: edited.id,
      paidOn: DateTime(2027, 2, 2),
      actualAmount: 425.75,
    );
    expect(
      store.currentOccurrenceFor('vehicle-insurance')!.dueOn,
      DateTime(2027, 3, 31),
    );
    expect(
      store.currentOccurrenceFor('vehicle-insurance')!.expectedAmount,
      418,
    );
  });

  test('durable notification source publishes an exact due reminder', () async {
    final template = _monthlyTemplate(nextDueOn: DateTime(2027, 9, 10));
    final occurrence = ScheduledExpenseOccurrence(
      id: 'insurance-2027-9-10',
      templateId: template.id,
      dueOn: template.nextDueOn,
      expectedAmount: template.amount,
    );
    final service = AuthorizedNotificationService(
      FileNotificationRepository.transient(),
    );
    final publisher = RecurringExpenseNotificationPublisher(
      service,
      () => [template],
      () => [occurrence],
    );
    await publisher.synchronize(asOf: DateTime(2027, 9, 3));

    final notices = await service.queryEvents(
      permissions: demoNotificationUserPermissions(),
      availableAtUtc: DateTime(2027, 9, 3, 10).toUtc(),
      channel: NotificationDeliveryChannel.inApp,
    );
    expect(notices, hasLength(1));
    expect(notices.single.content.arguments['dueOn'], '2027-09-10');
    expect(notices.single.route.sourceRecordId, 'vehicle-insurance');
    expect(notices.single.route.sourceChildId, 'insurance-2027-9-10');
    expect(
      notices.single.channels,
      containsAll({
        NotificationDeliveryChannel.inApp,
        NotificationDeliveryChannel.push,
        NotificationDeliveryChannel.sound,
      }),
    );
    await service.changeReadState(
      notificationId: notices.single.notificationId,
      state: NotificationReadState.read,
      expectedRevision: notices.single.lifecycle.revision,
      permissions: demoNotificationUserPermissions(),
      occurredAtUtc: notices.single.scheduledAtUtc.add(
        const Duration(hours: 1),
      ),
    );
    expect(
      await service.unreadCount(
        permissions: demoNotificationUserPermissions(),
        availableAtUtc: notices.single.scheduledAtUtc.add(
          const Duration(hours: 2),
        ),
      ),
      0,
    );
  });

  test('paused templates do not emit reminder notifications', () async {
    final template = _monthlyTemplate(
      nextDueOn: DateTime(2027, 9, 10),
      state: ScheduledExpenseState.paused,
    );
    final service = AuthorizedNotificationService(
      FileNotificationRepository.transient(),
    );
    final publisher = RecurringExpenseNotificationPublisher(
      service,
      () => [template],
      () => [
        ScheduledExpenseOccurrence(
          id: 'paused',
          templateId: template.id,
          dueOn: template.nextDueOn,
          expectedAmount: template.amount,
        ),
      ],
    );
    await publisher.synchronize(asOf: DateTime(2027, 9, 10));

    expect(
      await service.queryEvents(
        permissions: demoNotificationUserPermissions(),
        availableAtUtc: DateTime(2027, 9, 10).toUtc(),
      ),
      isEmpty,
    );
  });

  test(
    'push-only reminders stay out of UI and retain delivery history',
    () async {
      final template = _monthlyTemplate(nextDueOn: DateTime(2027, 9, 10))
          .copyWith(
            reminderDaysBefore: [7, 3, 1],
            inAppReminder: false,
            pushReminder: true,
            soundReminder: false,
          );
      final occurrence = ScheduledExpenseOccurrence(
        id: 'push-only-occurrence',
        templateId: template.id,
        dueOn: template.nextDueOn,
        expectedAmount: template.amount,
      );
      final service = AuthorizedNotificationService(
        FileNotificationRepository.transient(),
      );
      final publisher = RecurringExpenseNotificationPublisher(
        service,
        () => [template],
        () => [occurrence],
      );
      for (final day in [3, 7, 9]) {
        await publisher.synchronize(asOf: DateTime(2027, 9, day));
      }

      expect(
        await service.queryEvents(
          permissions: demoNotificationUserPermissions(),
          availableAtUtc: DateTime(2027, 9, 10).toUtc(),
          channel: NotificationDeliveryChannel.inApp,
        ),
        isEmpty,
      );
      final deliveries = await service.queryDeliveries(
        permissions: demoNotificationPublisherPermissions(),
        fromInclusiveUtc: DateTime(2027, 9, 1).toUtc(),
        toExclusiveUtc: DateTime(2027, 9, 11).toUtc(),
      );
      expect(deliveries, hasLength(3));
      expect(deliveries.map((item) => item.scheduledAtUtc.toLocal()), [
        DateTime(2027, 9, 3, 9),
        DateTime(2027, 9, 7, 9),
        DateTime(2027, 9, 9, 9),
      ]);
      expect(
        deliveries.map((item) => item.deliveryId).toSet(),
        hasLength(deliveries.length),
      );
      expect(
        deliveries.every(
          (item) => item.channel == NotificationDeliveryChannel.push,
        ),
        isTrue,
      );
    },
  );

  testWidgets('variable recurring payment requires the actual paid amount', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final template = _monthlyTemplate(
      nextDueOn: DateTime(2027, 1, 31),
    ).copyWith(amountKind: ScheduledExpenseAmountKind.enterWhenPaid);
    final store = PrototypeOperationsStore(
      expenses: const [],
      scheduledExpenses: [template],
    );
    final scope = OperationalScopeController();
    addTearDown(store.dispose);
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ScheduledExpenseDetailScreen(
              recordId: 'vehicle-insurance',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final markPaid = find.byKey(const ValueKey('mark-scheduled-expense-paid'));
    await tester.scrollUntilVisible(
      markPaid,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(markPaid);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('scheduled-expense-payment-amount-dialog')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('scheduled-expense-actual-amount')),
      '425.75',
    );
    await tester.tap(
      find.byKey(const ValueKey('confirm-scheduled-expense-payment')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expense-detail-screen')), findsOneWidget);
    expect(store.expenses, hasLength(1));
    expect(store.expenses.single.amount, 425.75);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Payment history'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(
      store.expenseStore.currentOccurrenceFor('vehicle-insurance')!.dueOn,
      DateTime(2027, 2, 28),
    );
    expect(tester.takeException(), isNull);
  });
}
