import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/layout/dashboard_layout.dart';

Future<void> pumpDashboard(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: const MaintainiacApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone presents one ordered container-first Dashboard', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(412, 915));

    expect(find.byKey(const ValueKey('dashboard-1-lane-layout')), findsOne);
    expect(find.byKey(const ValueKey('dashboard-bottom-navigation')), findsOne);
    expect(
      find.byKey(const ValueKey('dashboard-navigation-rail')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('dashboard-date-summary')), findsOne);
    expect(find.byKey(const ValueKey('dashboard-date-content-row')), findsOne);
    expect(find.byKey(const ValueKey('compact-operational-context')), findsOne);
    expect(find.text('Thompson Home Services'), findsNothing);
    expect(find.text('Not started'), findsNothing);
    expect(find.text('DAILY EXPENSES'), findsNothing);
    expect(find.byKey(const ValueKey('start-workday-button')), findsOne);
    expect(
      tester.getSize(find.byKey(const ValueKey('dashboard-header'))).height,
      lessThanOrEqualTo(58),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('dashboard-date-summary')))
          .height,
      lessThanOrEqualTo(72),
    );
    expect(find.byKey(const ValueKey('needs-attention-section')), findsOne);
    expect(find.byKey(const ValueKey('todays-plan-section')), findsOne);
    expect(find.byKey(const ValueKey('todays-entries-section')), findsOne);
    expect(find.byKey(const ValueKey('dashboard-calendar')), findsOne);
    expect(
      find.byKey(const ValueKey('record-Replace kitchen faucet')),
      findsOne,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone landscape reflows into two bounded lanes', (tester) async {
    await pumpDashboard(tester, const Size(915, 412));

    expect(find.byKey(const ValueKey('dashboard-2-lane-layout')), findsOne);
    expect(
      tester.getSize(find.byKey(const ValueKey('todays-plan-section'))).width,
      lessThanOrEqualTo(DashboardLayout.laneMaximum),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('13-inch-class window renders rail and three bounded lanes', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(1366, 768));

    expect(find.byKey(const ValueKey('dashboard-3-lane-layout')), findsOne);
    expect(find.byKey(const ValueKey('dashboard-navigation-rail')), findsOne);
    expect(
      find.byKey(const ValueKey('compact-operational-context')),
      findsNothing,
    );
    expect(find.text('Technician · Alex Morgan'), findsOne);
    expect(find.text('ACTIVE VEHICLE'), findsOne);
    expect(
      find.byKey(const ValueKey('dashboard-bottom-navigation')),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('dashboard-calendar'))).width,
      lessThanOrEqualTo(DashboardLayout.laneMaximum),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('dashboard-workspace'))).width,
      lessThanOrEqualTo(1228),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('dashboard-header'))).width,
      lessThanOrEqualTo(800),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('attention dismissal remains recoverable and changes no record', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(412, 915));

    await tester.tap(find.byKey(const ValueKey('dismiss-attention')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('needs-attention-section')), findsNothing);
    expect(find.byKey(const ValueKey('attention-collapsed')), findsOne);
    expect(find.text('2 unresolved items hidden'), findsOne);

    await tester.tap(find.byKey(const ValueKey('attention-collapsed')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('needs-attention-section')), findsOne);
    expect(find.text('Central Supply receipt'), findsOne);
  });

  testWidgets('calendar selection updates the selected-day heading', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(412, 915));
    final day = find.byKey(const ValueKey('calendar-day-2026-9-8'));
    await tester.drag(
      find.byKey(const ValueKey('dashboard-scroll-view')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(day);
    await tester.tap(day);
    await tester.pumpAndSettle();

    expect(find.text('Tuesday, September 8'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar switches between shared month and week views', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(412, 915));
    await tester.drag(
      find.byKey(const ValueKey('dashboard-scroll-view')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('calendar-view-selector')),
    );

    final monthHeight = tester
        .getSize(find.byKey(const ValueKey('dashboard-calendar')))
        .height;
    expect(find.text('View week'), findsOne);
    await tester.tap(find.text('View week'));
    await tester.pumpAndSettle();
    final weekHeight = tester
        .getSize(find.byKey(const ValueKey('dashboard-calendar')))
        .height;

    expect(weekHeight, lessThan(monthHeight));
    expect(find.text('View month'), findsOne);
    expect(find.byKey(const ValueKey('calendar-grid')), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('month calendar uses only the weeks required by that month', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(412, 915));
    await tester.drag(
      find.byKey(const ValueKey('dashboard-scroll-view')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    final calendar = tester.widget<TableCalendar<void>>(
      find.byKey(const ValueKey('calendar-grid')),
    );
    expect(calendar.sixWeekMonthsEnforced, isFalse);
    expect(find.byKey(const ValueKey('calendar-day-2026-10-5')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('record tap opens its readable detail', (tester) async {
    await pumpDashboard(tester, const Size(412, 915));
    final record = find.byKey(const ValueKey('record-Replace kitchen faucet'));
    await tester.ensureVisible(record);
    await tester.tap(record);
    await tester.pumpAndSettle();

    expect(find.text('Maya Thompson'), findsWidgets);
    expect(find.text('Done'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('theme control switches to layered dark surfaces', (
    tester,
  ) async {
    await pumpDashboard(tester, const Size(412, 915));
    await tester.tap(find.byTooltip('Dashboard settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch light or dark mode'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('representative width and text-scale sweep has no exceptions', (
    tester,
  ) async {
    for (final size in <Size>[
      const Size(320, 900),
      const Size(360, 900),
      const Size(390, 900),
      const Size(700, 900),
      const Size(748, 900),
      const Size(800, 1100),
      const Size(1024, 768),
      const Size(1180, 820),
      const Size(1280, 800),
      const Size(1366, 768),
      const Size(1440, 900),
      const Size(1920, 1080),
    ]) {
      await pumpDashboard(tester, size);
      expect(
        tester.getSize(find.byKey(const ValueKey('dashboard-workspace'))).width,
        lessThanOrEqualTo(1228),
      );
      expect(tester.takeException(), isNull, reason: 'Failed at $size');
    }

    await pumpDashboard(tester, const Size(390, 1100), textScale: 1.5);
    expect(tester.takeException(), isNull);
  });
}
