import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_notifications_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';

Future<void> _pumpDashboard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const UiLabApp());
  await tester.pumpAndSettle();
}

Future<void> _switchToAdmin(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('app-destination-work')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('work-view-selector')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Admin'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('app-destination-dashboard')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('notification center remains separate from Dashboard attention', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(find.byTooltip('Notifications. 1 unread item.'), findsNothing);
    await _switchToAdmin(tester);
    expect(find.byTooltip('Notifications. 1 unread item.'), findsNothing);

    Navigator.of(tester.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(
        builder: (_) => const DashboardNotificationsScreen(
          permissions: ExpensePermissions.development(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dashboard-notifications-screen')),
      findsOneWidget,
    );
    expect(find.text('Reminders and updates'), findsOneWidget);
    expect(find.text('Commercial vehicle insurance'), findsOneWidget);
    expect(find.text('Due in 3 days'), findsOneWidget);
    expect(find.text('Rental property move-out repairs'), findsNothing);

    await tester.tap(find.text('Commercial vehicle insurance'));
    await tester.pumpAndSettle();
    expect(find.text('Payment history'), findsOneWidget);
    expect(find.text('Edit this and future'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Needs attention opens its own exact-record queue', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _switchToAdmin(tester);

    final attention = find.byKey(const ValueKey('dashboard-summary-attention'));
    await tester.ensureVisible(attention);
    await tester.tap(attention);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard-attention-screen')),
      findsOneWidget,
    );
    expect(find.text('Rental property move-out repairs'), findsOneWidget);
    expect(find.text('Commercial vehicle insurance'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('dashboard-attention-list-est-1039')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('estimate-detail-est-1039')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('approve-estimate-for-sending')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
