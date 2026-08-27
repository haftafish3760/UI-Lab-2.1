import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';

Future<void> pumpAt(
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
  testWidgets('phone uses bottom navigation and stacked dashboard', (
    tester,
  ) async {
    await pumpAt(tester, const Size(412, 915));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('ACTIVE VEHICLE'), findsOneWidget);
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet uses a two-column dashboard', (tester) async {
    await pumpAt(tester, const Size(800, 1280));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('August 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop uses labeled navigation and useful lanes', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('MAINTAINIAC'), findsOneWidget);
    expect(find.text('Day Prep'), findsOneWidget);
    expect(find.text('14 of 16 ready'), findsOneWidget);
    expect(find.text('Workday Snapshot'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('intermediate width does not lose a content lane to navigation', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1107, 713));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('MAINTAINIAC'), findsNothing);
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.text("Today's Entries"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large phone text does not overflow', (tester) async {
    await pumpAt(tester, const Size(412, 915), textScale: 1.5);
    expect(find.text('Start workday'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
