import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_add_actions_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/employee_status_strip.dart';
import 'package:ui_lab_2_1/src/screens/work/work_shortcuts.dart';

Future<void> _pumpAt(
  WidgetTester tester,
  Widget child, {
  double textScale = 2,
}) async {
  tester.view.physicalSize = const Size(320, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 844),
          textScaler: TextScaler.linear(textScale),
        ),
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Dashboard action labels and descriptions reflow at 2x text', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      DashboardAddActionsScreen(
        day: DateTime(2026, 8, 31),
        actions: DashboardAddAction.values,
      ),
    );

    expect(find.text('Schedule Job'), findsOneWidget);
    expect(find.text('Record a vehicle fuel purchase'), findsOneWidget);
    expect(find.text('Capture or choose receipt evidence'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.text('Capture or choose receipt evidence'))
          .maxLines,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Work shortcuts preserve every label at 2x text', (tester) async {
    await _pumpAt(tester, Scaffold(body: WorkShortcutGrid(onSelected: (_) {})));

    for (final destination in WorkDestination.values) {
      expect(find.text(destination.label), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(destination.label)).maxLines,
        isNull,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Employee cards grow for complete names and statuses', (
    tester,
  ) async {
    const longName = 'Alexandria Montgomery-Rivera';
    const longStatus = 'Traveling to an assigned customer appointment';
    await _pumpAt(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: EmployeeStatusStrip(
            employees: const [
              EmployeeStatus(
                'alexandria',
                longName,
                longStatus,
                Icons.person_outline,
                Colors.blue,
              ),
            ],
            selectedId: null,
            onSelected: (_) {},
          ),
        ),
      ),
      textScale: 3,
    );

    final strip = find.byKey(const ValueKey('employee-status-strip'));
    expect(tester.getSize(strip).height, greaterThan(210));
    expect(tester.widget<Text>(find.text(longName)).maxLines, isNull);
    expect(tester.widget<Text>(find.text(longStatus)).maxLines, isNull);
    expect(tester.takeException(), isNull);
  });
}
