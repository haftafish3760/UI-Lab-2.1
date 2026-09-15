import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_calendar.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/calendar_day_overview.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_day_screen.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_plan.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/localized_date.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpDashboard(WidgetTester tester) async {
  const size = Size(412, 915);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const UiLabApp());
  await tester.pumpAndSettle();
}

Future<void> _openPreviousDay(WidgetTester tester) async {
  final calendar = find.byType(DashboardCalendar);
  await tester.scrollUntilVisible(
    calendar,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  final previousDay = dashboardToday.subtract(const Duration(days: 1));
  final target = find.byKey(
    ValueKey(
      'calendar-day-number-${previousDay.year}-${previousDay.month}-${previousDay.day}',
    ),
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<OperationalScopeController> _pumpCalendarDay(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  AppViewMode view = AppViewMode.technician,
  String? employeeId,
  PrototypeOperationsStore? operationsStore,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController(view: view);
  final store = operationsStore ?? PrototypeOperationsStore();
  if (employeeId != null) scope.selectEmployee(employeeId);
  addTearDown(scope.dispose);
  addTearDown(store.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: DashboardDayScreen(initialDay: dashboardToday),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return scope;
}

void main() {
  testWidgets('day metrics derive from the selected day records', (
    tester,
  ) async {
    const data = DashboardDayData(
      plan: [
        PlanItem(
          '8:00 AM',
          'First job',
          'Customer',
          Icons.work_outline,
          Colors.blue,
          id: 'job-1',
          status: 'Completed',
        ),
        PlanItem(
          '10:00 AM',
          'Supply stop',
          'Vendor',
          Icons.inventory_2_outlined,
          Colors.orange,
          id: 'stop-1',
          kind: PlanItemKind.operationalTask,
        ),
      ],
      entries: [
        DayEntry(
          id: 'trip-1',
          time: '9:00 AM',
          title: 'Trip',
          detail: 'Customer to vendor',
          kind: DayEntryKind.trip,
          color: Colors.blue,
        ),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CalendarDayMetricStrip(
            companyScope: true,
            data: data,
            vehicleName: 'Transit 12',
            onVehicleDetails: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('1 record'), findsOneWidget);
    expect(find.text('1 job'), findsNWidgets(2));
    expect(find.text('32h 18m'), findsNothing);
    expect(find.text('118.6 mi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar distinguishes today from another selection', (
    tester,
  ) async {
    var selected = dashboardToday.subtract(const Duration(days: 1));
    final nextSelection = dashboardToday.subtract(const Duration(days: 2));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: SizedBox(
              width: 360,
              child: DashboardCalendar(
                compact: true,
                selectedDay: selected,
                onDaySelected: (day) => setState(() => selected = day),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('calendar-today-indicator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-selected-outline')),
      findsOneWidget,
    );
    expect(find.text('TODAY'), findsNothing);

    final target = find.byKey(
      ValueKey(
        'calendar-day-${nextSelection.year}-${nextSelection.month}-${nextSelection.day}',
      ),
    );
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('calendar-today-indicator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('calendar-selected-outline')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'calendar uses a top-centered date and unboxed lower-left record count',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: DashboardCalendar(
                selectedDay: dashboardToday,
                entryCountForDay: (day) =>
                    sameDashboardDay(day, dashboardToday) ? 5 : 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final suffix =
          '${dashboardToday.year}-${dashboardToday.month}-${dashboardToday.day}';
      final cell = find.byKey(ValueKey('work-calendar-day-$suffix'));
      final count = find.byKey(ValueKey('calendar-entry-count-$suffix'));
      final dayNumber = find.byKey(ValueKey('calendar-day-number-$suffix'));
      expect(count, findsOneWidget);
      expect(
        find.descendant(of: count, matching: find.text('5')),
        findsOneWidget,
      );
      final cellRect = tester.getRect(cell);
      final dayRect = tester.getRect(dayNumber);
      final countRect = tester.getRect(count);
      expect(dayRect.center.dx, closeTo(cellRect.center.dx, .1));
      expect(
        find.descendant(of: dayNumber, matching: find.byType(Container)),
        findsNothing,
      );
      expect(dayRect.top, closeTo(cellRect.top + 6, .1));
      expect(countRect.left, closeTo(cellRect.left + 7, .1));
      expect(countRect.bottom, closeTo(cellRect.bottom - 7, .1));
      expect(tester.getSize(count).height, lessThanOrEqualTo(12));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'day selection pushes its own screen and Back preserves Dashboard',
    (tester) async {
      await _pumpDashboard(tester);
      final previousDay = dashboardToday.subtract(const Duration(days: 1));
      await _openPreviousDay(tester);

      expect(find.byType(DashboardDayScreen), findsOneWidget);
      final dayContext = tester.element(find.byType(DashboardDayScreen));
      expect(
        find.text(operationalDateLabel(dayContext, previousDay)),
        findsOneWidget,
      );
      expect(find.text('Entries'), findsOneWidget);
      expect(find.byType(TodayPlan), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DashboardDayScreen), findsNothing);
      final dashboardContext = tester.element(find.byType(DashboardCalendar));
      expect(
        find.text(operationalDateLabel(dashboardContext, dashboardToday)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Calendar Day owns settings and a permission-aware FAB', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _openPreviousDay(tester);

    expect(find.text('Add entry'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dashboard-settings-button')));
    await tester.pumpAndSettle();
    expect(find.text('Calendar day settings'), findsOneWidget);
    expect(
      find.text('These choices apply only to the calendar day screen.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Calendar Day approval keeps the original entry time and position',
    (tester) async {
      await _pumpCalendarDay(
        tester,
        view: AppViewMode.admin,
        employeeId: 'alex',
      );

      expect(find.text('Alex Morgan'), findsOneWidget);
      final metrics = find.byKey(const ValueKey('calendar-day-metric-strip'));
      expect(
        find.descendant(of: metrics, matching: find.text('5 items')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: metrics, matching: find.text('7 records')),
        findsOneWidget,
      );
      expect(find.text('1 item needs approval'), findsOneWidget);
      await tester.tap(find.text('1 item needs approval'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('approval-row-expense-1047')));
      await tester.pumpAndSettle();

      expect(find.text('QuickFuel'), findsWidgets);
      expect(find.textContaining(r'$50 field-expense limit'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('receipt-evidence-preview-EXP-1047')),
        findsOneWidget,
      );
      final approve = find.text('Approve expense');
      await tester.ensureVisible(approve);
      await tester.pumpAndSettle();
      await tester.tap(approve);
      await tester.pumpAndSettle();

      expect(find.text('1 item needs approval'), findsNothing);
      final expense = find.byKey(const ValueKey('day-entry-expense-1047'));
      expect(expense, findsOneWidget);
      expect(
        find.descendant(of: expense, matching: find.text('9:59 AM')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(expense).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('day-entry-expense-1048')))
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Calendar Day uses bounded three-lane layout on a wide window', (
    tester,
  ) async {
    await _pumpCalendarDay(
      tester,
      size: const Size(1500, 1000),
      view: AppViewMode.admin,
      employeeId: 'alex',
    );

    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-day-3-column-layout')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('calendar-day-approvals')))
          .width,
      lessThanOrEqualTo(480),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('vehicle details do not invent a day distance', (tester) async {
    await _pumpCalendarDay(tester);

    await tester.tap(find.text('Transit 12'));
    await tester.pumpAndSettle();

    expect(
      find.text('Latest confirmed odometer · 42,116.4 mi'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not have both a starting and an ending'),
      findsOneWidget,
    );
    expect(find.text('Distance recorded · 27.4 mi'), findsNothing);
    expect(find.textContaining('Beginning odometer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('company day recap derives money from that day records', (
    tester,
  ) async {
    final store = PrototypeOperationsStore(
      financialEntries: [
        PrototypeFinancialEntry(
          id: 'day-invoice',
          kind: PrototypeFinancialKind.invoiceIssued,
          occurredOn: dashboardToday,
          amountCents: 10000,
          sourceId: 'INV-DAY',
        ),
        PrototypeFinancialEntry(
          id: 'day-payment',
          kind: PrototypeFinancialKind.paymentReceived,
          occurredOn: dashboardToday,
          amountCents: 8000,
          sourceId: 'INV-DAY',
        ),
      ],
      expenses: [
        ExpenseRecord(
          id: 'day-expense',
          vendor: 'Test Supply',
          category: ExpenseCategory.materials,
          amount: 25,
          date: dashboardToday,
          owner: 'Alex Morgan',
        ),
      ],
    );
    await _pumpCalendarDay(
      tester,
      view: AppViewMode.admin,
      operationsStore: store,
    );

    expect(find.text('Company day recap'), findsOneWidget);
    expect(find.text(r'$100.00'), findsOneWidget);
    expect(find.text(r'$80.00'), findsOneWidget);
    expect(find.text(r'$25.00'), findsOneWidget);
    expect(
      find.text(r'$75.00 · invoiced minus recorded expenses'),
      findsOneWidget,
    );
    expect(find.text(r'$4,280.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
