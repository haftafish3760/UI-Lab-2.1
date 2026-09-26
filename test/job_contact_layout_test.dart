import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('Job contact actions reflow with accessibility text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
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
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(600, 900),
              textScaler: TextScaler.linear(2),
            ),
            child: MaterialApp(
              theme: AppTheme.light,
              home: JobWorkspaceScreen(
                workRecord: prototypeDemoWorkRecords().firstWhere(
                  (record) => record.id == 'job-1038',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final call = find.text('Call customer');
    await tester.ensureVisible(call);
    await tester.pumpAndSettle();
    await tester.tap(call);
    await tester.pumpAndSettle();

    final value = tester.getRect(
      find.byKey(const ValueKey('job-contact-value-Phone number')),
    );
    final copy = tester.getRect(
      find.byKey(const ValueKey('job-contact-copy-Phone number')),
    );
    expect(copy.top, greaterThanOrEqualTo(value.bottom));
    expect(tester.takeException(), isNull);
  });
}
