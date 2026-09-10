import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
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
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'employee directory opens a real editor with permission questions',
    (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('menu-employees')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('employee-directory-screen')),
        findsOneWidget,
      );
      expect(find.text('Active employees'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-employee-button')));
      await tester.pumpAndSettle();

      expect(find.text('Employee information'), findsOneWidget);
      expect(find.text('Can this employee see estimates?'), findsOneWidget);
      expect(find.text('Can this employee record expenses?'), findsOneWidget);
      expect(find.text('Save employee'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('employee permission questions fit a narrow screen', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(320, 700));
    await tester.tap(find.byKey(const ValueKey('menu-employees')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-employee-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Can this employee see estimates?'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('employee permission questions reflow for large text', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(600, 900), textScale: 2);
    await tester.ensureVisible(find.byKey(const ValueKey('menu-employees')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-employees')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-employee-button')));
    await tester.pumpAndSettle();

    final group = find.byKey(const ValueKey('permission-view-estimates'));
    await tester.ensureVisible(group);
    await tester.pumpAndSettle();
    final question = find.descendant(
      of: group,
      matching: find.text('Can this employee see estimates?'),
    );
    final yes = find.descendant(of: group, matching: find.text('Yes'));
    expect(
      tester.getBottomLeft(question).dy,
      lessThan(tester.getTopLeft(yes).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('vehicle profiles open a real editor', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('menu-vehicles')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('vehicle-directory-screen')),
      findsOneWidget,
    );
    expect(find.text('Active vehicles'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-vehicle-button')));
    await tester.pumpAndSettle();

    expect(find.text('Vehicle information'), findsOneWidget);
    expect(find.text('Confirmed odometer reading (mi)'), findsOneWidget);
    expect(find.text('Assigned employee or crew'), findsOneWidget);
    expect(find.text('Save vehicle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
