import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';

Future<void> _pumpAt(
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
      child: const UiLabApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('view selector lists Technician before Admin and changes view', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
    await tester.pumpAndSettle();

    final technicianItem = find.text('Technician').last;
    final adminItem = find.text('Admin');
    expect(find.text('Technician'), findsNWidgets(2));
    expect(adminItem, findsOneWidget);
    expect(
      tester.getTopLeft(technicianItem).dy,
      lessThan(tester.getTopLeft(adminItem).dy),
    );

    await tester.tap(adminItem);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('dashboard-view-selector')),
        matching: find.text('Admin'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('company-overview-summary')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('employee-status-strip')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('employee-alex'))),
      const Size(96, 120),
    );
    expect(
      find.byKey(const ValueKey('admin-company-schedule')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-needs-attention')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('admin-company-entries')), findsOneWidget);
    final date = find.byKey(const ValueKey('dashboard-date-heading'));
    final attention = find.byKey(const ValueKey('dashboard-needs-attention'));
    final employees = find.byKey(const ValueKey('employee-status-strip'));
    expect(
      tester.getTopLeft(date).dy,
      lessThan(tester.getTopLeft(attention).dy),
    );
    expect(
      tester.getTopLeft(employees).dy,
      lessThan(tester.getTopLeft(attention).dy),
    );
    expect(
      tester.getBottomLeft(attention).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('admin-company-schedule')))
            .dy,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('employee-alex')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('active-employee-summary')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('active-employee-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Company Overview').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('company-overview-summary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Admin overview uses one bounded workspace for records and calendar',
    (tester) async {
      await _pumpAt(tester, const Size(1600, 1000));
      await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Start workday'), findsNothing);

      final schedule = find.byKey(const ValueKey('admin-company-schedule'));
      final attention = find.byKey(const ValueKey('dashboard-needs-attention'));
      final calendar = find.byKey(const ValueKey('admin-company-calendar'));
      expect(
        tester.getTopLeft(attention).dy,
        lessThanOrEqualTo(tester.getTopLeft(schedule).dy),
      );
      expect(tester.getSize(schedule).width, lessThanOrEqualTo(400));
      expect(tester.getSize(attention).width, lessThanOrEqualTo(400));
      expect(tester.getSize(calendar).width, lessThanOrEqualTo(400));
      expect(tester.getTopLeft(attention).dx, tester.getTopLeft(schedule).dx);
      expect(
        tester.getBottomLeft(attention).dy,
        lessThan(tester.getTopLeft(schedule).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Admin overview preserves content at large system text scale', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(320, 844), textScale: 2);
    await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('company-overview-summary')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('employee-status-strip')), findsOneWidget);
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard does not expose the unexplained odometer control', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    expect(find.textContaining('Odometer ·'), findsNothing);
    expect(find.byKey(const ValueKey('odometer-privacy-button')), findsNothing);
    expect(find.text('Share odometer in this view'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected employee persists from Dashboard into Work', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('employee-jordan')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('app-destination-work')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('work-context-selector')),
        matching: find.text('Jordan Lee'),
      ),
      findsOneWidget,
    );
    expect(find.text('Employees'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header controls stay bounded through breakpoint changes', (
    tester,
  ) async {
    for (final width in [1000.0, 1031.0, 1033.0, 1107.0, 1440.0]) {
      await _pumpAt(tester, Size(width, 900));
      expect(
        find.byKey(const ValueKey('date-notification-button')),
        findsNothing,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('active-vehicle-summary')))
            .width,
        lessThanOrEqualTo(290),
      );
      expect(tester.takeException(), isNull);
    }
    final viewRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-view-selector')),
    );
    final settingsRect = tester.getRect(
      find.byKey(const ValueKey('dashboard-settings-button')),
    );
    expect(viewRect.right, lessThan(settingsRect.left));
  });
}
