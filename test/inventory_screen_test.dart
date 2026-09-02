import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/notifications/authorized_notification_service.dart';
import 'package:ui_lab_2_1/src/data/notifications/file_notification_repository.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_demo_policy.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
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

Future<void> _openInventory(WidgetTester tester, {required bool rail}) async {
  await tester.tap(
    find.byKey(
      ValueKey(
        rail ? 'desktop-destination-inventory' : 'app-destination-inventory',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Admin Inventory vehicle scope cannot change employee or active truck',
    () {
      final scope = OperationalScopeController();
      addTearDown(scope.dispose);

      scope.setView(AppViewMode.admin);
      scope.selectInventoryVehicle('service-van-4');

      expect(scope.selectedEmployeeId, isNull);
      expect(scope.selectedVehicleId, 'transit-12');
      expect(scope.inventoryVehicleId, 'service-van-4');
    },
  );

  testWidgets('active vehicle remains consistent from Dashboard to Inventory', (
    tester,
  ) async {
    const size = Size(412, 915);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController()..selectVehicle('service-van-4');
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
        home: NotificationUiScope(
          controller: notificationController,
          child: PrototypeOperationsScope(
            store: store,
            child: OperationalScope(controller: scope, child: const AppShell()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openInventory(tester, rail: false);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('inventory-context-selector')),
        matching: find.text('Service Van 4'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Transit 12 · Count verified'), findsNothing);
    expect(
      find.textContaining('Service Van 4 · Count unknown'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inventory uses the shared header and cost-first workspace', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1440, 900));
    await _openInventory(tester, rail: true);

    expect(
      find.byKey(const ValueKey('inventory-module-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inventory-context-selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inventory-date-heading')),
      findsOneWidget,
    );
    final headerTop = tester
        .getTopLeft(find.byKey(const ValueKey('inventory-module-header')))
        .dy;
    final dateTop = tester
        .getTopLeft(find.byKey(const ValueKey('inventory-date-heading')))
        .dy;
    final attentionTop = tester
        .getTopLeft(find.byKey(const ValueKey('inventory-attention')))
        .dy;
    expect(dateTop, greaterThan(headerTop));
    expect(attentionTop, greaterThan(dateTop));
    expect(find.text('Materials and cost history'), findsOneWidget);
    expect(find.text('Verified cost history'), findsOneWidget);
    expect(find.text('Truck stock'), findsOneWidget);
    expect(find.text('Cost sources'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('inventory-3-column-content')),
      findsOneWidget,
    );
    final costLane = tester.getTopLeft(find.text('Verified cost history'));
    final stockLane = tester.getTopLeft(find.text('Truck stock'));
    final sourceLane = tester.getTopLeft(find.text('Cost sources'));
    expect(stockLane.dx, greaterThan(costLane.dx));
    expect(sourceLane.dx, greaterThan(stockLane.dx));
    expect(find.text('Materials calendar'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('work-5-7-calendar'))).width,
      greaterThan(1000),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('work-5-7-calendar'))).width,
      lessThanOrEqualTo(AppLayoutEngine.maximumOperationsWorkspaceWidth),
    );
    expect(find.text('Braided faucet supply line'), findsWidgets);
    expect(
      find.byKey(const ValueKey('inventory-cost-record-cost-1001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('inventory-stock-record-stock-1001')),
      findsOneWidget,
    );
    expect(find.text('Record purchase cost'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Materials exposes inline actions at the shared two-lane width', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(800, 900));
    await _openInventory(tester, rail: false);

    expect(
      find.byKey(const ValueKey('inventory-2-column-content')),
      findsOneWidget,
    );
    expect(find.text('Record purchase cost'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inventory attention uses the shared panel and exact stock row', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await _openInventory(tester, rail: false);

    expect(find.byKey(const ValueKey('inventory-attention')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('inventory-attention-row-stock-1001')),
      findsOneWidget,
    );
    expect(find.byTooltip('Dismiss Needs attention'), findsOneWidget);
    await tester.tap(find.text('Show all 1'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('inventory-attention-list')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('inventory-attention-list-stock-1001')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stock-count-screen')), findsOneWidget);
    expect(find.text('Braided faucet supply line'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inventory settings visibly update only Inventory content', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await _openInventory(tester, rail: false);
    expect(find.text('Truck stock'), findsOneWidget);
    expect(find.text('Cost sources'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('inventory-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show truck stock'));
    await tester.tap(find.text('Show cost sources'));
    await tester.tap(
      find.byKey(const ValueKey('save-inventory-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Truck stock'), findsNothing);
    expect(find.text('Cost sources'), findsNothing);
    expect(find.text('Verified cost history'), findsOneWidget);
    expect(find.text('Materials calendar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Inventory Admin defaults to Fleet Overview and scopes vehicle stock',
    (tester) async {
      await _pumpAt(tester, const Size(412, 915));
      await _openInventory(tester, rail: false);

      await tester.tap(find.byKey(const ValueKey('inventory-view-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(find.text('Fleet Overview'), findsWidgets);
      expect(
        find.textContaining('Transit 12 · Count verified'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('inventory-context-selector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service Van 4').last);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('inventory-context-selector')),
          matching: find.text('Service Van 4'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Transit 12 · Count verified'), findsNothing);
      expect(
        find.textContaining('Service Van 4 · Count unknown'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Inventory vehicle context persists into its action route', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await _openInventory(tester, rail: false);

    await tester.tap(find.byKey(const ValueKey('inventory-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('inventory-context-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Service Van 4').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add material'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('inventory-action-screen')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('inventory-context-selector')),
        matching: find.text('Service Van 4'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inventory calendar pushes a separate dated screen', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await _openInventory(tester, rail: false);
    final now = DateTime.now();
    final day = find.byKey(
      ValueKey('work-calendar-day-${now.year}-${now.month}-${now.day}'),
    );

    await tester.ensureVisible(day);
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('inventory-day-screen')), findsOneWidget);
    expect(find.text('Material purchases'), findsOneWidget);
    expect(find.text('Stock counts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact Inventory action writes a verified material cost', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(390, 844));
    await _openInventory(tester, rail: false);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.text('Add material'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('inventory-action-screen')),
      findsOneWidget,
    );
    await tester.tap(find.text('Record purchase cost'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('material-name-field')),
      'Quarter turn shutoff valve',
    );
    await tester.enterText(
      find.byKey(const ValueKey('material-vendor-field')),
      'Neighborhood Hardware',
    );
    await tester.enterText(
      find.byKey(const ValueKey('material-unit-cost-field')),
      '12.50',
    );
    await tester.tap(
      find.byKey(const ValueKey('material-source-expense-field')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('EXP-1048 · Central Supply').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-material-cost-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-material-cost-button')));
    await tester.pumpAndSettle();

    expect(find.text('Quarter turn shutoff valve'), findsOneWidget);
    expect(find.text('\$12.50\nper each'), findsOneWidget);

    await tester.ensureVisible(find.text('Quarter turn shutoff valve'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quarter turn shutoff valve'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Source expense EXP-1048 · Tap to open'),
      findsOneWidget,
    );
    await tester.tap(
      find.textContaining('Source expense EXP-1048 · Tap to open'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('expense-detail-screen')), findsOneWidget);
    expect(find.text('Central Supply'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Inventory reflows under accessibility text without overflow', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(320, 844), textScale: 2);
    await _openInventory(tester, rail: false);
    final firstMetric = tester.getTopLeft(
      find.byKey(const ValueKey('verified-material-count')),
    );
    final secondMetric = tester.getTopLeft(
      find.byKey(const ValueKey('linked-expense-count')),
    );
    expect(secondMetric.dx, closeTo(firstMetric.dx, 0.1));
    expect(secondMetric.dy, greaterThan(firstMetric.dy));
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('Verified cost history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('material cost fields use the shared accessible form reflow', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(320, 844), textScale: 2);
    await _openInventory(tester, rail: false);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Add material'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Record purchase cost'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Record purchase cost'));
    await tester.pumpAndSettle();

    final cost = find.byKey(const ValueKey('material-unit-cost-field'));
    final unit = find.byKey(const ValueKey('material-unit-label-field'));
    await tester.ensureVisible(unit);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(unit).dx, closeTo(tester.getTopLeft(cost).dx, .1));
    expect(tester.getTopLeft(unit).dy, greaterThan(tester.getTopLeft(cost).dy));
    expect(tester.takeException(), isNull);
  });
}
