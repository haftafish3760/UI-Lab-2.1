import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/expenses/reports_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpReports(
  WidgetTester tester,
  Size size, {
  AppViewMode view = AppViewMode.technician,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController()..setView(view);
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
          home: ReportsScreen(initialView: view),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Reports is a permission-aware standalone workspace', (
    tester,
  ) async {
    await _pumpReports(tester, const Size(412, 915));
    expect(find.byKey(const ValueKey('reports-screen')), findsOneWidget);
    expect(find.text('My work recap'), findsOneWidget);
    expect(find.byKey(const ValueKey('reports-view-selector')), findsOneWidget);
    expect(find.text('Hours recorded'), findsWidgets);
    expect(find.text('My expenses and review'), findsOneWidget);
    expect(find.text('126.5'), findsNothing);
    expect(find.text('842'), findsNothing);
    expect(find.text('\$714'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin reports distinguish revenue, cash, expenses, and profit', (
    tester,
  ) async {
    await _pumpReports(tester, const Size(1440, 900), view: AppViewMode.admin);

    expect(find.text('Invoiced revenue'), findsOneWidget);
    expect(find.text('Money collected'), findsWidgets);
    expect(find.text('Recorded expenses'), findsOneWidget);
    expect(find.text('Estimated gross profit'), findsWidgets);
    expect(find.text('Estimated gross margin'), findsOneWidget);
    expect(find.text('Payments recorded'), findsOneWidget);
    expect(find.text('Invoices issued'), findsOneWidget);
    expect(find.text('\$24,680'), findsNothing);
    expect(find.text('\$6,215'), findsNothing);
    expect(find.text('\$1,180'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Report totals open the exact supporting record list', (
    tester,
  ) async {
    await _pumpReports(tester, const Size(412, 915));

    await tester.tap(find.byKey(const ValueKey('report-summary-my-expenses')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('report-sources-screen')), findsOneWidget);
    expect(find.text('My expenses'), findsOneWidget);
    expect(find.text('Central Supply'), findsOneWidget);
    expect(find.text('QuickFuel'), findsOneWidget);
    expect(find.text('CleanPro Wholesale'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('report-source-EXP-1048')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('expense-detail-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reports supports calendar and rolling periods', (tester) async {
    await _pumpReports(tester, const Size(412, 915));

    await tester.tap(find.text('This month'));
    await tester.pumpAndSettle();
    expect(find.text('This calendar quarter'), findsOneWidget);
    expect(find.text('Previous calendar quarter'), findsOneWidget);
    expect(find.text('Previous 90 days'), findsOneWidget);
    expect(find.text('Year to date'), findsOneWidget);
    expect(find.text('Previous 12 months'), findsOneWidget);
    await tester.tap(find.text('Previous 90 days'));
    await tester.pumpAndSettle();
    expect(find.text('Previous 90 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Report display choices can be saved and restored to defaults', (
    tester,
  ) async {
    await _pumpReports(tester, const Size(1440, 900), view: AppViewMode.admin);
    expect(find.text('Vehicles and fuel'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reports-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vehicles and fuel'));
    await tester.tap(find.byKey(const ValueKey('save-report-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Vehicles and fuel'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reports-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reset-report-settings')));
    await tester.tap(find.byKey(const ValueKey('save-report-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Vehicles and fuel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
