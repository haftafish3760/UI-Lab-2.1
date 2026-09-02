import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/customer_edit_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpEditor(
  WidgetTester tester, {
  required double textScale,
}) async {
  tester.view.physicalSize = const Size(600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController();
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    OperationalScope(
      controller: scope,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(600, 900),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: CustomerEditScreen(selectedDay: DateTime(2026, 8, 30)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Client fields reuse the shared width and text-scale rule', (
    tester,
  ) async {
    await _pumpEditor(tester, textScale: 1);
    final name = find.byKey(const ValueKey('client-name-field'));
    final company = find.byKey(const ValueKey('client-company-field'));
    expect(
      tester.getTopLeft(company).dx,
      greaterThan(tester.getTopLeft(name).dx),
    );

    await _pumpEditor(tester, textScale: 2);
    expect(
      tester.getTopLeft(company).dx,
      closeTo(tester.getTopLeft(name).dx, 0.1),
    );
    expect(
      tester.getTopLeft(company).dy,
      greaterThan(tester.getTopLeft(name).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
