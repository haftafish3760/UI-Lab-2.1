import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/inventory/inventory_screen.dart';
import 'package:ui_lab_2_1/src/screens/inventory/inventory_models.dart';
import 'package:ui_lab_2_1/src/screens/inventory/stock_count_screen.dart';
import 'package:ui_lab_2_1/src/screens/inventory/inventory_visible_records.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog_screen.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog_item_screen.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/materials_catalog_tiles.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

final fixture = InventoryCatalog.fromJson({
  'items': [
    {
      'id': 'p',
      'name': 'PVC elbow half inch',
      'trade': 'Plumbing',
      'category': 'Fittings',
      'system': 'PVC',
      'type': 'Elbows',
      'variant': 'Half inch',
      'unit': 'each',
    },
    {
      'id': 'c',
      'name': 'Wood screw',
      'trade': 'Carpentry',
      'category': 'Fasteners',
      'system': 'Steel',
      'type': 'Screws',
      'unit': 'each',
    },
  ],
});

Future<void> pump(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
  double scale = 1,
  PrototypeOperationsStore? store,
  OperationalScopeController? scope,
  bool dark = false,
  TargetPlatform? platform,
  Locale? locale,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final records = store ?? PrototypeOperationsStore();
  final access = scope ?? OperationalScopeController(view: AppViewMode.admin);
  if (store == null) addTearDown(records.dispose);
  if (scope == null) addTearDown(access.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: records,
      child: OperationalScope(
        controller: access,
        child: MaterialApp(
          theme: (dark ? AppTheme.dark : AppTheme.light).copyWith(
            platform: platform,
          ),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reducedMotion,
            ),
            child: child!,
          ),
          home: screen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('technician stock reads exclude another employee and vehicle', () {
    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    addTearDown(scope.dispose);
    addTearDown(store.dispose);
    final records = visibleInventoryStock(store, scope);
    expect(records, isNotEmpty);
    expect(
      records.every(
        (r) => r.ownerEmployeeId == 'alex' && r.locationId == 'transit-12',
      ),
      isTrue,
    );
  });

  testWidgets(
    'bundled catalog loads and displays actual trade branches offline',
    (tester) async {
      final catalog = await tester.runAsync(InventoryCatalog.load);
      expect(catalog!.branches([]).length, 21);
      await pump(tester, InventoryCatalogScreen(catalog: catalog));
      expect(find.text('Choose a trade'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stock count rejects invalid numbers and can disable its minimum',
    (tester) async {
      InventoryStockRecord? saved;
      final record = demoInventoryStock.first;
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Check item'),
              onPressed: () async {
                saved = await Navigator.of(context).push<InventoryStockRecord>(
                  MaterialPageRoute(
                    builder: (_) => StockCountScreen(record: record),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Check item'));
      await tester.pumpAndSettle();
      for (final invalid in ['NaN', 'Infinity', '-1']) {
        await tester.enterText(
          find.byKey(const ValueKey('stock-quantity-field')),
          invalid,
        );
        await tester.tap(find.text('Save count'));
        await tester.pumpAndSettle();
        expect(saved, isNull);
        expect(find.text('Enter zero or a positive number.'), findsOneWidget);
      }
      await tester.enterText(
        find.byKey(const ValueKey('stock-quantity-field')),
        '7',
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save count'));
      await tester.pumpAndSettle();
      expect(saved!.quantity, 7);
      expect(saved!.lowAt, isNull);
      expect(saved!.locationId, record.locationId);
    },
  );
  testWidgets(
    'landing puts real attention before browsing without a vehicle selector',
    (tester) async {
      await pump(tester, const InventoryScreen());
      expect(find.text('My Inventory'), findsOneWidget);
      expect(find.text('Browse Catalog'), findsOneWidget);
      expect(find.text('Running low'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('inventory-context-selector')),
        findsNothing,
      );
      expect(find.text('Cost sources'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Running low')).dy,
        lessThan(tester.getTopLeft(find.text('My Inventory')).dy),
      );
      await tester.tap(find.text('Running low'));
      await tester.pumpAndSettle();
      expect(find.text('Braided faucet supply line'), findsOneWidget);
      expect(find.text('PTFE thread seal tape'), findsNothing);
      await tester.tap(find.text('Braided faucet supply line'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('stock-count-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty inventory does not invent alerts or deliveries', (
    tester,
  ) async {
    final store = PrototypeOperationsStore(
      inventoryStock: [],
      materialCosts: [],
    );
    addTearDown(store.dispose);
    await pump(tester, const InventoryScreen(), store: store);
    expect(find.text('Running low'), findsNothing);
    expect(find.text('Orders awaiting arrival'), findsNothing);
    expect(find.textContaining('Start with the items'), findsOneWidget);
  });

  testWidgets('browse follows every level and back preserves parent', (
    tester,
  ) async {
    await pump(tester, InventoryCatalogScreen(catalog: fixture));
    final a = tester.getTopLeft(find.text('Carpentry'));
    final b = tester.getTopLeft(find.text('Plumbing'));
    expect(a.dy, closeTo(b.dy, 1)); // two trade columns on an ordinary phone
    await tester.tap(find.text('Plumbing'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNothing); // photos only at trade level
    for (final label in ['Fittings', 'PVC', 'Elbows', 'PVC elbow half inch']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }
    expect(find.text('Item details'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Add to My Inventory'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Elbows'), findsWidgets);
    expect(find.text('PVC elbow half inch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search and clear restore the tree', (tester) async {
    await pump(tester, InventoryCatalogScreen(catalog: fixture));
    await tester.enterText(find.byType(TextField), 'half inch');
    await tester.pumpAndSettle();
    expect(find.text('PVC elbow half inch'), findsOneWidget);
    expect(find.text('Wood screw'), findsNothing);
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();
    expect(find.textContaining('No matching items'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a trade'), findsOneWidget);
  });

  testWidgets(
    'My Inventory excludes unused trades and filtering never changes active truck',
    (tester) async {
      final scope = OperationalScopeController(view: AppViewMode.admin);
      final store = PrototypeOperationsStore(
        materialCosts: [],
        inventoryStock: [
          InventoryStockRecord(
            id: 's',
            materialId: 'p',
            materialName: 'PVC elbow half inch',
            locationId: 'truck-a',
            locationLabel: 'Truck A',
            quantity: 5,
            unitLabel: 'each',
            confidence: InventoryStockConfidence.verified,
            updatedOn: DateTime(2026),
            ownerEmployeeId: 'alex',
          ),
        ],
      );
      addTearDown(scope.dispose);
      addTearDown(store.dispose);
      await pump(
        tester,
        InventoryCatalogScreen(catalog: fixture, myInventory: true),
        store: store,
        scope: scope,
      );
      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('Carpentry'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Truck A').last);
      await tester.pumpAndSettle();
      expect(scope.selectedVehicleId, 'transit-12');
      expect(scope.selectedEmployeeId, isNull);
    },
  );

  testWidgets(
    'adding catalog stock validates quantities and keeps one location record',
    (tester) async {
      final store = PrototypeOperationsStore(
        inventoryStock: [],
        materialCosts: [],
      );
      addTearDown(store.dispose);
      await pump(
        tester,
        InventoryCatalogItemScreen(item: fixture.items.first),
        store: store,
      );
      await tester.ensureVisible(find.text('Add to My Inventory').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to My Inventory').last);
      await tester.pumpAndSettle();
      expect(store.inventoryStock, isEmpty);
      expect(find.text('Enter a location.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Truck A');
      await tester.enterText(find.byType(TextFormField).at(1), 'NaN');
      await tester.ensureVisible(find.text('Add to My Inventory').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to My Inventory').last);
      await tester.pumpAndSettle();
      expect(store.inventoryStock, isEmpty);
      await tester.enterText(find.byType(TextFormField).at(1), '5');
      await tester.ensureVisible(find.text('Add to My Inventory').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to My Inventory').last);
      await tester.pumpAndSettle();
      expect(store.inventoryStock.single.quantity, 5);
      expect(store.inventoryStock.single.materialId, 'p');
    },
  );

  for (final unknown in [false, true]) {
    testWidgets('adding more stock respects existing count; unknown=$unknown', (
      tester,
    ) async {
      final store = PrototypeOperationsStore(
        materialCosts: [],
        inventoryStock: [
          InventoryStockRecord(
            id: 'stock-p-a',
            materialId: 'p',
            materialName: 'PVC elbow half inch',
            locationId: 'truck-a',
            locationLabel: 'Truck A',
            quantity: 5,
            unitLabel: 'each',
            lowAt: 2,
            confidence: unknown
                ? InventoryStockConfidence.unknown
                : InventoryStockConfidence.verified,
            updatedOn: DateTime(2026),
            ownerEmployeeId: 'alex',
          ),
        ],
      );
      addTearDown(store.dispose);
      await pump(
        tester,
        InventoryCatalogItemScreen(item: fixture.items.first),
        store: store,
      );
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Truck A').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '3');
      await tester.ensureVisible(find.text('Add to My Inventory').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to My Inventory').last);
      await tester.pumpAndSettle();
      expect(store.inventoryStock.length, 1);
      expect(store.inventoryStock.single.id, 'stock-p-a');
      expect(store.inventoryStock.single.quantity, unknown ? 5 : 8);
      expect(store.inventoryStock.single.lowAt, 2);
      if (unknown)
        expect(
          find.textContaining('Check the current quantity'),
          findsOneWidget,
        );
    });
  }

  for (final configuration in [
    (const Size(320, 844), 1.0, false),
    (const Size(320, 844), 2.0, true),
    (const Size(844, 390), 1.0, false),
    (const Size(1024, 768), 2.0, true),
    (const Size(1440, 900), 1.0, false),
  ]) {
    testWidgets('landing and catalog reflow at $configuration', (tester) async {
      await pump(
        tester,
        const InventoryScreen(),
        size: configuration.$1,
        scale: configuration.$2,
        dark: configuration.$3,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await pump(
        tester,
        InventoryCatalogScreen(catalog: fixture),
        size: configuration.$1,
        scale: configuration.$2,
        dark: configuration.$3,
      );
      expect(find.byType(MaterialsCatalogTiles), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
