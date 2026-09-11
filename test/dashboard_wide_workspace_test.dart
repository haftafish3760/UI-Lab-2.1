import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/active_vehicle_header.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_plan.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'support/load_material_test_font.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadMaterialTestFont);

  test('wide geometry is bounded, asymmetric and handles empty entries', () {
    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (double width = 0; width <= 2200; width += 4) {
        final layout = AppLayoutEngine.dashboardOperationsFor(
          width,
          textScaler: TextScaler.linear(scale),
        );
        expect(layout.workspaceWidth, lessThanOrEqualTo(width));
        expect(layout.laneWidth, inInclusiveRange(0, 600));
        expect(layout.calendarWidth, inInclusiveRange(0, 400));
        if (layout.columns > 1) {
          expect(layout.laneWidth, greaterThan(layout.calendarWidth));
          expect(
            layout.laneWidth * (layout.columns - 1) +
                layout.calendarWidth +
                layout.gap * (layout.columns - 1),
            closeTo(layout.workspaceWidth, .01),
          );
        }
      }
    }
    final empty = AppLayoutEngine.dashboardOperationsFor(
      2000,
      hasEntries: false,
    );
    expect(empty.columns, 2);
    expect(empty.workspaceWidth, 1016);
  });

  Future<void> pump(WidgetTester tester, Size size, double scale) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(scale)),
        child: const UiLabApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wide toolbar, calendar and both scopes survive resizing', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [
      const Size(1000, 700),
      const Size(1440, 900),
      const Size(1920, 1080),
    ]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        await pump(tester, size, scale);
        final scope = OperationalScope.of(
          tester.element(find.byType(DashboardScreen)),
        );
        for (final view in AppViewMode.values) {
          scope.setView(view);
          await tester.pumpAndSettle();
          final header = tester.widget<ActiveVehicleHeader>(
            find.byType(ActiveVehicleHeader),
          );
          if (header.dashboardWide) {
            expect(
              find.byKey(const ValueKey('dashboard-view-selector')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('dashboard-inline-actions')),
              findsOneWidget,
            );
            expect(find.byType(FloatingActionButton), findsNothing);
            expect(
              tester.widget<TodayPlan>(find.byType(TodayPlan)).previewCount,
              6,
            );
            final calendar = find.byKey(
              ValueKey(
                view == AppViewMode.admin
                    ? 'admin-company-calendar'
                    : 'dashboard-technician-calendar',
              ),
            );
            final plan = find.byKey(
              ValueKey(
                view == AppViewMode.admin
                    ? 'admin-company-schedule'
                    : 'dashboard-technician-schedule',
              ),
            );
            expect(tester.getTopLeft(calendar).dy, tester.getTopLeft(plan).dy);
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$size / $scale / $view',
          );
        }
      }
    }
  });

  testWidgets('view menu and employee selection preserve actual context', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(tester, const Size(1440, 900), 1);
    await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin').last);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('company-overview-summary')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('start-workday-button')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('employee-alex')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('active-employee-summary')),
      findsOneWidget,
    );
    final scope = OperationalScope.of(
      tester.element(find.byType(DashboardScreen)),
    );
    expect(scope.selectedEmployeeId, 'alex');
    await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Technician').last);
    await tester.pumpAndSettle();
    expect(scope.view, AppViewMode.technician);
    expect(
      find.byKey(const ValueKey('active-vehicle-summary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
