import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/shared/section_card.dart';

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const UiLabApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mobile reserves a labeled ad zone above bottom navigation', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));

    final ad = find.byKey(const ValueKey('prototype-ad-banner'));
    final navigation = find.byType(NavigationBar);
    expect(ad, findsOneWidget);
    expect(find.text('ADVERTISEMENT'), findsOneWidget);
    expect(
      tester.getRect(ad).bottom,
      closeTo(tester.getRect(navigation).top, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop does not reserve the mobile ad zone', (tester) async {
    await _pumpAt(tester, const Size(1440, 900));
    expect(find.byKey(const ValueKey('prototype-ad-banner')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared header menu opens company records and Reports', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('operations-menu-screen')),
      findsOneWidget,
    );
    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Vehicle profiles'), findsOneWidget);
    expect(find.text('Reports and recap'), findsOneWidget);
    expect(find.text('Invite employees'), findsOneWidget);
    expect(find.text('System settings'), findsOneWidget);

    final reports = find.byKey(const ValueKey('menu-reports'));
    for (final id in ['menu-customers', 'menu-vehicles', 'menu-reports']) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey(id)),
          matching: find.byType(SectionCard),
        ),
        findsOneWidget,
      );
    }
    await tester.ensureVisible(reports);
    await tester.pumpAndSettle();
    await tester.tap(reports);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reports-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('System appearance setting changes the whole running app', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    final systemSettings = find.byKey(const ValueKey('menu-system-settings'));
    await tester.ensureVisible(systemSettings);
    await tester.pumpAndSettle();
    await tester.tap(systemSettings);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('system-appearance-setting')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('appearance-dark')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('appearance-settings-screen')),
      findsOneWidget,
    );
    expect(
      Theme.of(tester.element(find.text('Appearance').last)).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
