import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';

void main() {
  testWidgets('Dashboard uses Needs attention instead of a competing bell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const UiLabApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard-date-heading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dashboard-needs-attention')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('date-notification-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
