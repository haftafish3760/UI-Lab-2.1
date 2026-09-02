import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/notifications/authorized_notification_service.dart';
import 'package:ui_lab_2_1/src/data/notifications/file_notification_repository.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_demo_policy.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_records.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_terms.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_ui_controller.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_notifications_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';

void main() {
  testWidgets('notification row exposes state and opens its exact source', (
    tester,
  ) async {
    await _pumpApp(tester, FileNotificationRepository.transient());

    expect(find.byTooltip('Notifications. 1 unread item.'), findsNothing);
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardNotificationsScreen(
          permissions: ExpensePermissions.development(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        RegExp(r'Commercial vehicle insurance.*Due in 3 days.*Unread'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    await tester.tap(find.text('Commercial vehicle insurance'));
    await tester.pumpAndSettle();
    expect(find.text('Payment history'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test(
    'notification controller keeps read state after repository restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'dashboard-notification-restart-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final firstRepository = await FileNotificationRepository.open(directory);
      final service = AuthorizedNotificationService(firstRepository);
      final permissions = demoNotificationUserPermissions();
      final now = DateTime.now().toUtc();
      final event = _notificationFixture(now);
      await AuthorizedNotificationService(firstRepository).publish(
        event: event,
        deliveries: const [],
        permissions: demoNotificationPublisherPermissions(),
        occurredAtUtc: now,
      );
      final firstController = NotificationUiController(
        service,
        permissions,
        Future<void>.value(),
      );
      await firstController.load(availableAt: now);
      expect(firstController.unreadCount, 1);
      expect(
        await firstController.markRead(firstController.events.single),
        isTrue,
      );
      firstController.dispose();

      final reopened = await FileNotificationRepository.open(directory);
      final restartedController = NotificationUiController(
        AuthorizedNotificationService(reopened),
        permissions,
        Future<void>.value(),
      );
      addTearDown(restartedController.dispose);
      await restartedController.load(availableAt: now);

      expect(restartedController.unreadCount, 0);
      expect(
        restartedController.events.single.notificationId,
        event.notificationId,
      );
      expect(
        restartedController.events.single.route.sourceRecordId,
        event.route.sourceRecordId,
      );
    },
  );

  testWidgets('an authorized empty repository shows the honest empty state', (
    tester,
  ) async {
    final service = AuthorizedNotificationService(
      FileNotificationRepository.transient(),
    );
    final controller = NotificationUiController(
      service,
      demoNotificationUserPermissions(),
      Future<void>.value(),
    );
    final operationalScope = OperationalScopeController();
    addTearDown(controller.dispose);
    addTearDown(operationalScope.dispose);
    await controller.load(availableAt: DateTime.now());

    await tester.pumpWidget(
      NotificationUiScope(
        controller: controller,
        child: OperationalScope(
          controller: operationalScope,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DashboardNotificationsScreen(
              permissions: ExpensePermissions.development(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No reminders or updates are currently available.'),
      findsOneWidget,
    );
    expect(find.text('Nothing needs attention right now.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('denied notification read scope produces no cached records', () async {
    final service = AuthorizedNotificationService(
      FileNotificationRepository.transient(),
    );
    final denied = NotificationCommandPermissions(
      organizationId: demoNotificationOrganizationId,
      actorEmployeeId: demoNotificationEmployeeId,
      permissionRevision: 'denied-notifications-1',
      readScope: null,
    );
    final controller = NotificationUiController(
      service,
      denied,
      Future<void>.value(),
    );
    addTearDown(controller.dispose);

    await controller.load(availableAt: DateTime.now());

    expect(controller.phase, NotificationUiPhase.failed);
    expect(controller.events, isEmpty);
    expect(controller.unreadCount, 0);
  });
}

StoredNotificationEvent _notificationFixture(DateTime now) =>
    StoredNotificationEvent(
      notificationId: 'expense-insurance-2026-09',
      deduplicationKey: 'expense-insurance-2026-09:alex',
      organizationId: demoNotificationOrganizationId,
      recipientEmployeeId: demoNotificationEmployeeId,
      category: NotificationEventCategory.reminder,
      kind: NotificationEventKind.recurringExpenseDue,
      route: NotificationSourceRoute(
        module: NotificationSourceModule.expenses,
        sourceType: NotificationSourceType.recurringExpense,
        sourceRecordId: 'expense-insurance',
      ),
      content: NotificationContent(
        titleKey: 'notification.recurringExpense.title',
        messageKey: 'notification.recurringExpense.due',
        arguments: {
          'title': 'Commercial vehicle insurance',
          'dueOn': '2026-09-04',
        },
      ),
      scheduledAtUtc: now,
      channels: const {NotificationDeliveryChannel.inApp},
      readState: NotificationReadState.unread,
      lifecycle: NotificationLifecycle(
        revision: 1,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );

Future<void> _pumpApp(
  WidgetTester tester,
  FileNotificationRepository repository,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UiLabApp(notificationRepository: repository));
  await tester.pumpAndSettle();
}
