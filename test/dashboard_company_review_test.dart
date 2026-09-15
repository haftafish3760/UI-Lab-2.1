import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/admin_dashboard_overview.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_calendar.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_plan.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_review_section.dart';
import 'dashboard_responsive_test.dart' show pumpAt;
import 'support/load_material_test_font.dart';

void main() {
  setUpAll(loadMaterialTestFont);
  for (final width in [320.0, 1440.0]) {
    testWidgets('Admin reuses daily layout and bounded calendar at $width', (
      tester,
    ) async {
      await pumpAt(tester, Size(width, 900), textScale: 2);
      final technicianPlanWidth = tester.getSize(find.byType(TodayPlan)).width;
      await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('admin-company-schedule')),
        findsOneWidget,
      );
      expect(find.byType(TodayPlan), findsOneWidget);
      expect(tester.getSize(find.byType(TodayPlan)).width, technicianPlanWidth);
      expect(find.byType(DashboardReviewSection), findsNWidgets(3));
      expect(
        tester.getTopLeft(find.byType(AdminDashboardOverview)).dy,
        greaterThan(tester.getTopLeft(find.byType(TodayPlan)).dy),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byType(DashboardCalendar),
        400,
        maxScrolls: 60,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(DashboardCalendar), findsOneWidget);
      expect(
        tester.getSize(find.byType(DashboardCalendar)).width,
        lessThanOrEqualTo(500),
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'mobile and landscape Admin defaults to company and returns from employee scope',
    (tester) async {
      for (final size in [
        const Size(320, 844),
        const Size(844, 390),
        const Size(1200, 900),
      ]) {
        await pumpAt(tester, size);
        await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Admin').last);
        await tester.pumpAndSettle();
        expect(find.byType(AdminDashboardOverview), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dashboard-technician-schedule')),
          findsNothing,
        );
        await tester.ensureVisible(find.byKey(const ValueKey('employee-alex')));
        await tester.tap(find.byKey(const ValueKey('employee-alex')));
        await tester.pumpAndSettle();
        expect(find.byType(AdminDashboardOverview), findsNothing);
        expect(
          find.byKey(const ValueKey('dashboard-technician-schedule')),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('dashboard-company-scope')),
        );
        await tester.tap(find.byKey(const ValueKey('dashboard-company-scope')));
        await tester.pumpAndSettle();
        expect(find.byType(AdminDashboardOverview), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'narrow calendar uses safe width without record insets and caps at 500',
    (tester) async {
      for (final width in [320.0, 412.0, 600.0]) {
        await pumpAt(tester, Size(width, 915));
        await tester.scrollUntilVisible(
          find.byType(DashboardCalendar),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        final rect = tester.getRect(find.byType(DashboardCalendar));
        expect(rect.width, width < 500 ? width : 500);
        expect(rect.left, (width - rect.width) / 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'company balance subtracts partial payment and excludes draft invoice',
    (tester) async {
      final today = DateTime(2026, 9, 13);
      WorkRecord invoice(String id, double amount, {bool draft = false}) =>
          WorkRecord(
            id: id,
            kind: WorkRecordKind.invoice,
            number: id,
            title: id,
            client: 'Customer',
            detail: '',
            pricing: WorkPricingModel.flatRate,
            total: amount,
            status: draft ? WorkRecordStatus.draft : WorkRecordStatus.due,
            issuedOn: draft ? null : today,
            dueOn: today.subtract(const Duration(days: 1)),
          );
      final store = PrototypeOperationsStore(
        workRecords: [
          invoice('INV-A', 100),
          invoice('DRAFT', 500, draft: true),
        ],
        financialEntries: [
          PrototypeFinancialEntry(
            id: 'payment',
            kind: PrototypeFinancialKind.paymentReceived,
            occurredOn: today,
            amountCents: 2500,
            sourceId: 'INV-A',
          ),
        ],
        expenses: [],
      );
      final scope = OperationalScopeController(view: AppViewMode.admin);
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: OperationalScope(
            controller: scope,
            child: PrototypeOperationsScope(
              store: store,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: AdminDashboardOverview(
                    date: today,
                    permissions: const DashboardPermissions.development(),
                    onOpenPlan: (_) {},
                    onAttention: () {},
                    attentionCount: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Outstanding balance · \$75.00'), findsOneWidget);
      expect(
        find.text('Profit unavailable — costs incomplete'),
        findsOneWidget,
      );
      expect(find.text('Unpaid invoices · 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
