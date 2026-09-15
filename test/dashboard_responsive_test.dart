import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/today_entries.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/active_vehicle_header.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_calendar.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_models.dart';
import 'support/load_material_test_font.dart';

Future<void> pumpAt(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: const UiLabApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadMaterialTestFont);
  testWidgets(
    'Admin company and employee views are reachable at narrow and wide widths',
    (tester) async {
      for (final size in [
        const Size(320, 844),
        const Size(844, 390),
        const Size(1440, 900),
      ]) {
        await pumpAt(tester, size);
        await tester.tap(find.byKey(const ValueKey('dashboard-view-selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Admin').last);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('admin-company-overview')),
          findsOneWidget,
        );
        final collections = find.text('Collected money');
        await tester.ensureVisible(collections);
        await tester.pumpAndSettle();
        await tester.tap(collections);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('report-sources-screen')),
          findsOneWidget,
        );
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();
        final employee = find.byKey(const ValueKey('employee-alex'));
        await tester.ensureVisible(employee);
        await tester.pumpAndSettle();
        await tester.tap(employee);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('admin-employee-overview')),
          findsOneWidget,
        );
        expect(find.text('Employee contribution · Incomplete'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('admin-company-overview')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
  testWidgets(
    'transient zero-size startup does not build invalid constraints',
    (tester) async {
      await pumpAt(tester, Size.zero);
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('phone uses bottom navigation and shared dashboard header', (
    tester,
  ) async {
    await pumpAt(tester, const Size(412, 915));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('ACTIVE VEHICLE'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-view-selector')),
      findsOneWidget,
    );
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('bottom navigation reserves the platform safe area', (
    tester,
  ) async {
    await pumpAt(tester, const Size(412, 915));

    final safeArea = tester.widget<SafeArea>(
      find.byKey(const ValueKey('app-bottom-safe-area')),
    );
    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isTrue);
    expect(safeArea.minimum.bottom, 4);
    expect(safeArea.maintainBottomViewPadding, isTrue);
    final navigation = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      navigation.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );
    for (final label in [
      'Dashboard',
      'Work',
      'Expenses',
      'Materials',
      'Maintenance',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('every primary module is a top-level bottom-nav destination', (
    tester,
  ) async {
    await pumpAt(tester, const Size(412, 915));

    const modules = <(String, int, String)>[
      ('work', 1, 'work-module-screen'),
      ('expenses', 2, 'expenses-module-screen'),
      ('inventory', 3, 'inventory-module-screen'),
      ('maintenance', 4, 'maintenance-module-screen'),
      ('dashboard', 0, 'active-vehicle-summary'),
    ];
    for (final (module, index, screenKey) in modules) {
      await tester.tap(find.byKey(ValueKey('app-destination-$module')));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        index,
      );
      expect(find.byKey(ValueKey(screenKey)), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('calendar switches inline between Month and Week', (
    tester,
  ) async {
    await pumpAt(tester, const Size(412, 915));
    final action = find.byKey(const ValueKey('calendar-view-toggle'));
    await tester.scrollUntilVisible(
      action,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('inline-month-grid')), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);

    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('inline-week-grid')), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Calendar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet uses a two-column dashboard', (tester) async {
    await pumpAt(tester, const Size(800, 1280));
    expect(find.byType(NavigationBar), findsOneWidget);
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    expect(
      find.text('${months[dashboardToday.month - 1]} ${dashboardToday.year}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard composes priority, records, and calendar by lane', (
    tester,
  ) async {
    await pumpAt(tester, const Size(412, 915));
    final attention = find.byKey(const ValueKey('dashboard-summary-attention'));
    final plan = find.byKey(const ValueKey('dashboard-technician-schedule'));
    final entries = find.byKey(const ValueKey('dashboard-technician-entries'));
    final calendar = find.byKey(
      const ValueKey('dashboard-technician-calendar'),
    );
    expect(
      tester.getBottomLeft(attention).dy,
      lessThan(tester.getTopLeft(plan).dy),
    );
    expect(
      tester.getBottomLeft(plan).dy,
      lessThan(tester.getTopLeft(entries).dy),
    );
    await tester.scrollUntilVisible(
      calendar,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getBottomLeft(entries).dy,
      lessThan(tester.getTopLeft(calendar).dy),
    );

    await pumpAt(tester, const Size(800, 1100));
    expect(tester.getTopLeft(plan).dx, tester.getTopLeft(entries).dx);
    expect(
      tester.getTopLeft(calendar).dx,
      greaterThan(tester.getTopLeft(entries).dx),
    );
    expect(tester.getTopLeft(plan).dy, tester.getTopLeft(calendar).dy);

    await pumpAt(tester, const Size(1600, 1000));
    expect(tester.getTopLeft(attention).dx, tester.getTopLeft(plan).dx);
    expect(tester.getTopLeft(plan).dx, lessThan(tester.getTopLeft(entries).dx));
    expect(
      tester.getTopLeft(entries).dx,
      lessThan(tester.getTopLeft(calendar).dx),
    );
    expect(tester.getSize(calendar).width, lessThanOrEqualTo(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation fills its available width', (tester) async {
    await pumpAt(tester, const Size(800, 900));
    expect(tester.getSize(find.byType(NavigationBar)).width, 800);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop uses labeled navigation and useful lanes', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1440, 900));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('MAINTAINIAC'), findsOneWidget);
    expect(find.text('Day Prep'), findsNothing);
    expect(find.text('Open day prep'), findsNothing);
    expect(find.text('14 of 16 ready'), findsNothing);
    expect(find.text('Workday Snapshot'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop rail switches peer modules without pushing a child', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1440, 900));

    await tester.tap(find.byKey(const ValueKey('desktop-destination-work')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('work-module-screen')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('desktop-destination-expenses')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expenses-module-screen')),
      findsOneWidget,
    );
    final selectedTile = tester.widget<ListTile>(
      find.byKey(const ValueKey('desktop-destination-expenses')),
    );
    expect(selectedTile.selected, isTrue);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('intermediate width does not lose a content lane to navigation', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1107, 713));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('MAINTAINIAC'), findsOneWidget);
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.text("Today's Entries"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('logical-width sweep keeps one responsive Dashboard contract', (
    tester,
  ) async {
    for (final width in <double>[
      320,
      360,
      412,
      600,
      700,
      748,
      800,
      1107,
      1178,
      1180,
      1280,
      1307,
      1308,
      1337,
      1338,
      1440,
      1920,
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpAt(tester, Size(width, 900));

      final expectsRail =
          width >= AppLayoutEngine.dashboardRailMinimumWindowWidth;
      expect(
        find.byType(NavigationBar),
        expectsRail ? findsNothing : findsOneWidget,
        reason: 'Navigation contract diverged at $width logical pixels.',
      );
      expect(find.byType(ActiveVehicleHeader), findsOneWidget);
      expect(
        tester.getSize(find.byType(ActiveVehicleHeader)).height,
        lessThanOrEqualTo(125),
        reason: 'Header exceeded its two-row limit at $width logical pixels.',
      );
      await tester.scrollUntilVisible(
        find.byType(DashboardCalendar),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.getSize(find.byType(DashboardCalendar)).width,
        lessThanOrEqualTo(width),
      );
      final error = tester.takeException();
      expect(error, isNull, reason: 'At width $width: $error');
    }
  });

  testWidgets('large phone text does not overflow', (tester) async {
    await pumpAt(tester, const Size(412, 915), textScale: 1.5);
    expect(find.byKey(const ValueKey('start-workday-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'owner header is compact and Start remains outside it at normal scale',
    (tester) async {
      for (final width in [320.0, 360.0, 412.0, 450.0]) {
        await pumpAt(tester, Size(width, 844));

        final selector = find.byKey(const ValueKey('dashboard-view-selector'));
        expect(selector, findsOneWidget);
        final startRect = tester.getRect(
          find.byKey(const ValueKey('start-workday-button')),
        );
        final headerRect = tester.getRect(find.byType(ActiveVehicleHeader));
        expect(startRect.top, greaterThan(headerRect.bottom));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('system text scaling preserves complete header content', (
    tester,
  ) async {
    for (final scale in [1.3, 1.5, 2.0]) {
      await pumpAt(tester, const Size(320, 844), textScale: scale);
      expect(
        find.byKey(const ValueKey('start-workday-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dashboard-view-selector')),
        findsOneWidget,
      );
      expect(find.text('ACTIVE VEHICLE'), findsOneWidget);
      final error = tester.takeException();
      expect(error, isNull, reason: 'At text scale $scale: $error');
    }
  });

  testWidgets('month calendar occupies one bounded Dashboard lane', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1600, 900));
    expect(find.byKey(const ValueKey('dashboard-3-lane-row')), findsOneWidget);
    final calendarSize = tester.getSize(
      find.byKey(const ValueKey('work-5-7-calendar')),
    );
    expect(
      calendarSize.width,
      lessThanOrEqualTo(AppLayoutEngine.dashboardLaneMaximum),
    );
    expect(calendarSize.width, lessThan(500));
    expect(calendarSize.height, lessThanOrEqualTo(510));
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan and entries expand and entry records open full details', (
    tester,
  ) async {
    await pumpAt(tester, const Size(412, 915));

    expect(find.text('3 of 5 stops'), findsOneWidget);
    expect(find.text('Show all 5'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('plan-expand-button')));
    await tester.pumpAndSettle();
    expect(find.text('Return unused job materials'), findsOneWidget);
    expect(find.text('5 of 5 stops'), findsOneWidget);
    expect(find.text('Show less'), findsWidgets);

    final entriesButton = find.byKey(const ValueKey('entries-expand-button'));
    await tester.ensureVisible(entriesButton);
    await tester.pumpAndSettle();
    final entryCount = tester
        .widget<TodayEntries>(find.byType(TodayEntries))
        .entries
        .length;
    expect(find.text('3 of $entryCount entries'), findsOneWidget);
    await tester.tap(entriesButton);
    await tester.pumpAndSettle();
    expect(find.text('Estimate sent'), findsOneWidget);
    expect(find.text('$entryCount of $entryCount entries'), findsOneWidget);

    final receipt = find.text('Central Supply');
    await tester.ensureVisible(receipt);
    await tester.pumpAndSettle();
    await tester.tap(receipt);
    await tester.pumpAndSettle();
    expect(find.text('Expense details'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('receipt-evidence-preview-EXP-1048')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('plan menus offer actions that match the owning record', (
    tester,
  ) async {
    await pumpAt(tester, const Size(412, 915));

    await tester.tap(
      find.byKey(const ValueKey('plan-actions-pickup-job-1038')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mark arrived'), findsNothing);
    expect(find.text('Mark task completed'), findsOneWidget);
    await tester.tap(find.text('View full details'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('job-workspace-job-1038')),
      findsOneWidget,
    );
    expect(find.text('Scheduled'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('plan-actions-job-1038')));
    await tester.pumpAndSettle();
    expect(find.text('Mark arrived'), findsOneWidget);
    expect(find.text('Mark task completed'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schedule Job opens the job-owned editor', (tester) async {
    await pumpAt(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('dashboard-add-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-schedule-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job-editor-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-start-date')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-start-time')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard FAB exposes permission-scoped date actions', (
    tester,
  ) async {
    await pumpAt(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('dashboard-add-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('dashboard-add-actions-screen')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('add-schedule-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-entry-action')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-add-expense-action')),
      findsOneWidget,
    );
    expect(find.text('Create Estimate'), findsOneWidget);
    expect(find.text('Create Invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('dashboard-add-expense-action')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('expense-editor-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard Actions remains labeled at large system text', (
    tester,
  ) async {
    await pumpAt(tester, const Size(320, 844), textScale: 1.5);
    await tester.tap(find.byKey(const ValueKey('dashboard-add-button')));
    await tester.pumpAndSettle();

    expect(find.text('Schedule Job'), findsOneWidget);
    expect(find.text('Record Expense'), findsOneWidget);
    expect(find.text('Add Receipt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
