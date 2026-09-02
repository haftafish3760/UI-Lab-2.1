import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/work_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('Work Day add action follows a narrow pane on a wide window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    addTearDown(scope.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 700,
                height: 900,
                child: WorkDayScreen(initialDay: DateTime(2026, 8, 30)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('work-day-add-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('work-day-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
