import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/shared/operational_summary_strip.dart';
import 'support/load_material_test_font.dart';

Future<void> pumpDashboard(WidgetTester tester, {double scale = 1}) async {
  tester.view.physicalSize = const Size(384, 832);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: const UiLabApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadMaterialTestFont);
  testWidgets('large money values widen cards without splitting digits', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: OperationalSummaryStrip(
            items: [
              OperationalSummaryItem(
                id: 'large',
                label: 'Expenses',
                value: r'$123,456,789.00',
                color: Colors.blue,
                icon: Icons.receipt_long,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    final value = tester.renderObject<RenderBox>(find.text(r'$123,456,789.00'));
    expect(value.size.height, lessThan(25));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('dashboard-summary-large')))
          .width,
      greaterThan(96),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('five ordered horizontal cards use 96 by 120 LP', (tester) async {
    await pumpDashboard(tester);
    const ids = ['attention', 'payments', 'expenses', 'miles', 'work'];
    double? lastX;
    for (final id in ids) {
      final card = find.byKey(ValueKey('dashboard-summary-$id'));
      expect(card, findsOneWidget);
      expect(tester.getSize(card), const Size(96, 120));
      final x = tester.getTopLeft(card).dx;
      if (lastX != null) expect(x - lastX, 108);
      lastX = x;
    }
    await tester.drag(
      find.byKey(const ValueKey('dashboard-summary-strip')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dashboard-summary-work')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('picker reopens with only selected vehicle highlighted blue', (
    tester,
  ) async {
    await pumpDashboard(tester);
    final selector = find.byKey(const ValueKey('active-vehicle-summary'));
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('context-picker-option-service-van-4')),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(DashboardScreen));
    expect(OperationalScope.of(context).selectedVehicleId, 'service-van-4');
    expect(find.text('Service Van 4'), findsOneWidget);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    final selected = find.byKey(
      const ValueKey('context-picker-option-service-van-4'),
    );
    final ink = tester.widget<Ink>(
      find.descendant(of: selected, matching: find.byType(Ink)),
    );
    final gradient =
        (ink.decoration! as BoxDecoration).gradient! as LinearGradient;
    expect(gradient.colors, [AppColors.pickerBlue, AppColors.pickerBlueDeep]);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(
      find.descendant(of: selected, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('entries depend on records, not starting a workday', (
    tester,
  ) async {
    await pumpDashboard(tester);
    final context = tester.element(find.byType(DashboardScreen));
    final store = PrototypeOperationsScope.of(context);
    for (final record in store.expenses.toList()) {
      store.expenseStore.softDeleteExpense(record.id);
    }
    store.updateDashboardDay(
      day: dashboardToday,
      contextId: 'alex',
      data: const DashboardDayData(),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dashboard-technician-entries')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('start-workday-button')), findsOneWidget);
    store.updateDashboardDay(
      day: dashboardToday,
      contextId: 'alex',
      data: const DashboardDayData(
        entries: [
          DayEntry(
            id: 'note-one',
            time: '7:00 AM',
            title: 'Morning note',
            detail: 'Recorded before starting',
            kind: DayEntryKind.note,
            color: Colors.blue,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dashboard-technician-entries')),
      findsOneWidget,
    );
    expect(find.text('Morning note'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-workday-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards and picker preserve scaled text', (tester) async {
    await pumpDashboard(tester, scale: 2);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('dashboard-summary-attention')))
          .width,
      192,
    );
    final selector = find.byKey(const ValueKey('active-vehicle-summary'));
    await tester.ensureVisible(selector);
    await tester.tap(find.text('Transit 12'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('operational-context-picker')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
