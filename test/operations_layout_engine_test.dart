import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/notifications/authorized_notification_service.dart';
import 'package:ui_lab_2_1/src/data/notifications/file_notification_repository.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_demo_policy.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/shell/app_navigation.dart';
import 'package:ui_lab_2_1/src/shell/app_shell.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpAt(
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
  test('one shared calculation owns all operations lane thresholds', () {
    expect(AppLayoutEngine.operationsFor(717).columns, 1);
    expect(
      AppLayoutEngine.operationsFor(717).showsInlineModuleActions,
      isFalse,
    );
    expect(AppLayoutEngine.operationsFor(718).columns, 2);
    expect(AppLayoutEngine.operationsFor(718).showsInlineModuleActions, isTrue);
    expect(AppLayoutEngine.operationsFor(1085).columns, 2);
    expect(AppLayoutEngine.operationsFor(1086).columns, 3);
    expect(AppLayoutEngine.dashboardFor(747).mode, DashboardLaneMode.single);
    expect(AppLayoutEngine.dashboardFor(748).mode, DashboardLaneMode.two);
    expect(AppLayoutEngine.dashboardFor(1247).mode, DashboardLaneMode.two);
    expect(AppLayoutEngine.dashboardFor(1248).mode, DashboardLaneMode.three);
    expect(AppLayoutEngine.dashboardFor(1248).laneWidth, 400);
    expect(AppLayoutEngine.workFor(1086).columns, 3);
    expect(
      AppLayoutEngine.operationsFor(2000).workspaceWidth,
      AppLayoutEngine.maximumOperationsWorkspaceWidth,
    );
    expect(AppLayoutEngine.operationsFor(700).laneWidth, 400);
    expect(AppLayoutEngine.operationsFor(900).laneWidth, 400);
    expect(AppLayoutEngine.operationsFor(1086).laneWidth, 350);
    expect(AppLayoutEngine.operationsFor(2000).laneWidth, 600);
    expect(AppLayoutEngine.monthCalendarRowHeightFor(TextScaler.noScaling), 70);
    expect(AppLayoutEngine.formWorkspaceWidthFor(390), 390);
    expect(AppLayoutEngine.formWorkspaceWidthFor(1200), 760);
    expect(AppLayoutEngine.stackFormFieldsFor(500), isTrue);
    expect(AppLayoutEngine.stackFormFieldsFor(760), isFalse);
    expect(AppLayoutEngine.summaryMetricColumnsFor(320), 2);
    expect(AppLayoutEngine.summaryMetricColumnsFor(760), 4);
    expect(AppLayoutEngine.stackOperationalRecordFor(320), isTrue);
    expect(AppLayoutEngine.stackOperationalRecordFor(390), isFalse);
    expect(
      AppLayoutEngine.stackOperationalRecordFor(
        390,
        textScaler: const TextScaler.linear(2),
      ),
      isTrue,
    );
    expect(
      AppLayoutEngine.summaryMetricColumnsFor(
        320,
        textScaler: const TextScaler.linear(2),
      ),
      1,
    );
    expect(
      AppLayoutEngine.stackFormFieldsFor(
        560,
        textScaler: const TextScaler.linear(2),
      ),
      isTrue,
    );
  });

  test('shared layouts never emit negative transient geometry', () {
    for (final width in [-100.0, 0.0]) {
      final operations = AppLayoutEngine.operationsFor(width);
      expect(operations.columns, 1);
      expect(operations.laneWidth, 0);
      expect(operations.workspaceWidth, 0);

      final detail = AppLayoutEngine.detailWorkspaceFor(width);
      expect(detail.columns, 1);
      expect(detail.columnWidth, 0);
      expect(detail.workspaceWidth, 0);

      final shortcuts = AppLayoutEngine.workShortcutsFor(width);
      expect(shortcuts.tileWidth, 0);
    }
  });

  test('accessibility raises shared lane requirements for every module', () {
    const largeText = TextScaler.linear(2);

    expect(AppLayoutEngine.operationsFor(718).columns, 2);
    expect(
      AppLayoutEngine.operationsFor(718, textScaler: largeText).columns,
      1,
    );
    expect(AppLayoutEngine.operationsFor(1086).columns, 3);
    expect(
      AppLayoutEngine.operationsFor(1086, textScaler: largeText).columns,
      2,
    );
    expect(
      AppLayoutEngine.detailWorkspaceFor(900, textScaler: largeText).columns,
      1,
    );
  });

  test('header measurement remains part of the same engine', () {
    expect(
      AppLayoutEngine.headerFor(
        availableWidth: 800,
        textScaler: TextScaler.noScaling,
      ).singleRow,
      isTrue,
    );
    expect(
      AppLayoutEngine.headerFor(
        availableWidth: 304,
        textScaler: TextScaler.noScaling,
      ).actionsSideBySide,
      isTrue,
    );
    expect(
      AppLayoutEngine.headerFor(
        availableWidth: 400,
        textScaler: TextScaler.noScaling,
      ).singleRow,
      isFalse,
    );
  });

  testWidgets('rail transition preserves two useful Dashboard lanes', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(999, 900));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-2-lane-row')), findsOneWidget);

    await _pumpAt(tester, const Size(1000, 900));
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byKey(const ValueKey('dashboard-2-lane-row')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all top-level operations modules use one bounded workspace', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(2300, 1000));
    expect(find.byKey(const ValueKey('dashboard-3-lane-row')), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('operations-workspace-frame')))
          .width,
      AppLayoutEngine.dashboardThreeColumnMinimumWidth,
    );

    await tester.tap(find.byKey(const ValueKey('desktop-destination-work')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('work-3-column-queues')), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('operations-workspace-frame')))
          .width,
      AppLayoutEngine.maximumOperationsWorkspaceWidth,
    );

    await tester.tap(
      find.byKey(const ValueKey('desktop-destination-expenses')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expenses-3-column-layout')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('operations-workspace-frame')))
          .width,
      AppLayoutEngine.maximumOperationsWorkspaceWidth,
    );

    await tester.tap(
      find.byKey(const ValueKey('desktop-destination-inventory')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('inventory-3-column-content')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('operations-workspace-frame')))
          .width,
      AppLayoutEngine.maximumOperationsWorkspaceWidth,
    );

    await tester.tap(
      find.byKey(const ValueKey('desktop-destination-maintenance')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('maintenance-3-column-layout')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('operations-workspace-frame')))
          .width,
      AppLayoutEngine.maximumOperationsWorkspaceWidth,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('module lanes switch together at shared local widths', (
    tester,
  ) async {
    for (final scenario
        in <({Size size, int dashboardColumns, int moduleColumns})>[
          (size: const Size(390, 900), dashboardColumns: 1, moduleColumns: 1),
          (size: const Size(800, 900), dashboardColumns: 2, moduleColumns: 2),
          (size: const Size(1120, 900), dashboardColumns: 2, moduleColumns: 3),
        ]) {
      await _pumpAt(tester, scenario.size);
      final bottomDashboard = find.byKey(
        const ValueKey('app-destination-dashboard'),
      );
      final dashboardDestination = bottomDashboard.evaluate().isNotEmpty
          ? bottomDashboard
          : find.byKey(const ValueKey('desktop-destination-dashboard'));
      await tester.tap(dashboardDestination);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('dashboard-${scenario.dashboardColumns}-lane-row')),
        findsOneWidget,
      );

      for (final module in const [
        'work',
        'expenses',
        'inventory',
        'maintenance',
      ]) {
        final desktopDestination = find.byKey(
          ValueKey('desktop-destination-$module'),
        );
        final destination = desktopDestination.evaluate().isNotEmpty
            ? desktopDestination
            : find.byKey(ValueKey('app-destination-$module'));
        await tester.tap(destination);
        await tester.pumpAndSettle();
        final key = switch (module) {
          'work' => 'work-${scenario.moduleColumns}-column-queues',
          'expenses' => 'expenses-${scenario.moduleColumns}-column-layout',
          'inventory' => 'inventory-${scenario.moduleColumns}-column-content',
          _ => 'maintenance-${scenario.moduleColumns}-column-layout',
        };
        expect(find.byKey(ValueKey(key)), findsOneWidget);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('operations-workspace-frame')))
              .width,
          lessThanOrEqualTo(AppLayoutEngine.maximumOperationsWorkspaceWidth),
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('shell and Expense actions honor a constrained local pane', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    final notificationController = NotificationUiController(
      AuthorizedNotificationService(FileNotificationRepository.transient()),
      demoNotificationUserPermissions(),
      Future<void>.value(),
    );
    addTearDown(scope.dispose);
    addTearDown(store.dispose);
    addTearDown(notificationController.dispose);
    await notificationController.load(availableAt: DateTime.now());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(
          child: SizedBox(
            width: 800,
            height: 900,
            child: NotificationUiScope(
              controller: notificationController,
              child: PrototypeOperationsScope(
                store: store,
                child: OperationalScope(
                  controller: scope,
                  child: const AppShell(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(DesktopAppNavigation), findsNothing);
    expect(find.byKey(const ValueKey('dashboard-2-lane-row')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expenses-2-column-layout')),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Record expense'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text preserves Dashboard lanes and scrollable rail', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1120, 900), textScale: 2);
    expect(find.byKey(const ValueKey('dashboard-2-lane-row')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      find.descendant(
        of: find.byType(DesktopAppNavigation),
        matching: find.byType(ListView),
      ),
      findsOneWidget,
    );
    expect(
      AppLayoutEngine.operationsFor(
        868,
        textScaler: const TextScaler.linear(2),
      ).columns,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  test('top-level module sources retain one layout owner', () {
    const owners = {
      'Dashboard': 'lib/src/screens/dashboard/dashboard_screen.dart',
      'Work': 'lib/src/screens/work/work_screen.dart',
      'Expenses': 'lib/src/screens/expenses/expenses_screen.dart',
      'Materials': 'lib/src/screens/inventory/inventory_screen.dart',
      'Maintenance prototype':
          'lib/src/screens/modules/module_home_screen.dart',
    };

    for (final entry in owners.entries) {
      final source = File(entry.value).readAsStringSync();
      expect(
        source,
        entry.key == 'Dashboard'
            ? contains('AppLayoutEngine.dashboardOperationsFor(')
            : contains('AppLayoutEngine.operationsFor('),
        reason: '${entry.key} must use the shared layout calculation.',
      );
      expect(
        source,
        contains('OperationsWorkspaceFrame('),
        reason: '${entry.key} must use the shared bounded frame.',
      );
      expect(
        source,
        isNot(contains('AppBreakpoints')),
        reason: '${entry.key} cannot introduce a second breakpoint owner.',
      );
    }

    final shell = File('lib/src/shell/app_shell.dart').readAsStringSync();
    expect(
      shell,
      isNot(contains('MediaQuery.sizeOf(context)')),
      reason: 'Shell navigation must use its actual local constraints.',
    );
  });
}
