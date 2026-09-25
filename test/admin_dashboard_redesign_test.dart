import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_calendar.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_plan.dart';
import 'package:ui_lab_2_1/src/shared/app_preferences.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<AppPreferencesController> pumpDashboard(
  WidgetTester tester, {
  double width = 1440,
  double scale = 1,
  bool approvals = false,
}) async {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final prefs = AppPreferencesController();
  final scope = OperationalScopeController(view: AppViewMode.admin);
  final store = PrototypeOperationsStore(
    expenses: [],
    scheduledExpenses: [],
    financialEntries: [],
    workRecords: [],
    inventoryStock: [],
  );
  // Use the same existing company policy as the estimate workflow.
  final configured = PrototypeOperationsStore(
    expenses: [],
    scheduledExpenses: [],
    financialEntries: [],
    workRecords: [],
    inventoryStock: [],
    companyProfile: store.companyProfile.copyWith(
      requireEstimateApproval: approvals,
    ),
  );
  store.dispose();
  addTearDown(prefs.dispose);
  addTearDown(scope.dispose);
  addTearDown(configured.dispose);
  await tester.pumpWidget(
    AppPreferencesScope(
      controller: prefs,
      child: OperationalScope(
        controller: scope,
        child: PrototypeOperationsScope(
          store: configured,
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(body: DashboardScreen()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

Future<void> editLayout(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(const ValueKey('dashboard-settings-button')),
  );
  await tester.tap(find.byKey(const ValueKey('dashboard-settings-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Customize dashboard'));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0, 844.0, 1440.0, 2000.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Admin adapts at $width with text scale $scale', (
        tester,
      ) async {
        await pumpDashboard(tester, width: width, scale: scale);
        expect(find.byType(TodayPlan), findsNothing);
        expect(find.text('Viewing: Company Overview'), findsOneWidget);
        expect(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('company-overview-summary')),
              )
              .dy,
          greaterThan(
            tester
                .getBottomLeft(
                  find.byKey(const ValueKey('dashboard-settings-button')),
                )
                .dy,
          ),
        );
        expect(find.byType(DashboardCalendar), findsOneWidget);
        expect(
          tester.getSize(find.byType(DashboardCalendar)).width,
          lessThanOrEqualTo(400),
        );
        expect(
          find.byKey(const ValueKey('dashboard-view-selector')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('company-overview-summary')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('admin-widget-approvals')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'Cancel discards changes; Save retains selection; calendar required',
    (tester) async {
      final prefs = await pumpDashboard(tester);
      await editLayout(tester);
      expect(
        find.byKey(const ValueKey('remove-widget-Calendar')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('remove-widget-Billing and collections')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('admin-widget-billing')),
        findsOneWidget,
      );
      await editLayout(tester);
      await tester.tap(
        find.byKey(const ValueKey('remove-widget-Billing and collections')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save layout'));
      await tester.pumpAndSettle();
      expect(prefs.adminDashboardWidgets, isNot(contains('billing')));
      expect(find.byKey(const ValueKey('admin-widget-billing')), findsNothing);
      await editLayout(tester);
      await tester.tap(find.text('Add widgets'));
      await tester.pumpAndSettle();
      expect(find.text('Approvals'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('add-widget-payments')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save layout'));
      await tester.pumpAndSettle();
      expect(prefs.adminDashboardWidgets, contains('payments'));
      await editLayout(tester);
      final calendarControls = find.byKey(
        const ValueKey('admin-widget-calendar'),
      );
      await tester.ensureVisible(calendarControls);
      await tester.tap(
        find.descendant(of: calendarControls, matching: find.text('Earlier')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save layout'));
      await tester.tap(find.text('Save layout'));
      await tester.pumpAndSettle();
      expect(prefs.adminDashboardWidgets.first, 'calendar');
      await editLayout(tester);
      await tester.tap(find.text('Restore default layout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save layout'));
      await tester.pumpAndSettle();
      expect(prefs.adminDashboardWidgets, contains('billing'));
      expect(prefs.adminDashboardWidgets, isNot(contains('payments')));
      await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Technician').last);
      await tester.pumpAndSettle();
      expect(find.byType(TodayPlan), findsOneWidget);
      expect(
        find.byKey(const ValueKey('admin-company-schedule')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Enabled approvals show even with no pending requests', (
    tester,
  ) async {
    await pumpDashboard(tester, approvals: true);
    expect(
      find.byKey(const ValueKey('admin-widget-approvals')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
