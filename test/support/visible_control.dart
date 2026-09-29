import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reaches a control through the scrollable screen before interacting with it.
/// Missing controls still fail; this does not invoke callbacks directly.
Future<void> revealControl(WidgetTester tester, Finder control) async {
  if (control.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      control,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  expect(control.hitTestable(), findsOneWidget);
}

Future<void> tapVisibleControl(WidgetTester tester, Finder control) async {
  await revealControl(tester, control);
  await tester.tap(control);
}
