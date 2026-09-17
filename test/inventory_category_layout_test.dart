import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog_screen.dart';
import 'inventory_screen_test.dart' as harness;

InventoryCatalog categoryFixture() => InventoryCatalog.fromJson({
  'items': [
    for (final category in [
      'Fittings',
      'Pipe and tubing',
      'Valves',
      'Consumables',
    ])
      {
        'id': category,
        'name': '$category sample',
        'unit': 'each',
        'path': ['Plumbing', category, 'Material', 'Type'],
      },
    {
      'id': 'short',
      'name': 'Short path item',
      'unit': 'each',
      'path': ['Plumbing', 'Consumables'],
    },
    {
      'id': 'deep',
      'name': 'Exact deep item',
      'unit': 'each',
      'path': ['Plumbing', 'Fittings', 'Material', 'Type', 'Connection'],
    },
  ],
});

void main() {
  for (final size in [
    const Size(320, 700),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1266, 714),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('category grid reflows at $size and text scale $scale', (
        tester,
      ) async {
        await harness.pump(
          tester,
          InventoryCatalogScreen(
            catalog: categoryFixture(),
            path: const ['Plumbing'],
          ),
          size: size,
          scale: scale,
        );
        expect(find.byType(Image), findsNothing);
        final fittings = tester.getRect(
          find.byKey(const ValueKey('materials:Fittings')),
        );
        final pipe = tester.getRect(
          find.byKey(const ValueKey('materials:Pipe and tubing')),
        );
        if (scale == 1) {
          expect(fittings.width, lessThanOrEqualTo(size.width));
          expect(pipe.width, closeTo(fittings.width, .1));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Back traverses every parent and retains search context', (
    tester,
  ) async {
    await harness.pump(
      tester,
      InventoryCatalogScreen(catalog: categoryFixture()),
    );
    for (final label in [
      'Plumbing',
      'Fittings',
      'Material',
      'Type',
      'Connection',
      'Exact deep item',
    ]) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }
    expect(find.text('Item details'), findsOneWidget);
    for (final parent in [
      'Connection',
      'Type',
      'Material',
      'Fittings',
      'Plumbing',
      'Browse Catalog',
    ]) {
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(parent)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('mixed-depth category exposes both items and child categories', (
    tester,
  ) async {
    await harness.pump(
      tester,
      InventoryCatalogScreen(
        catalog: categoryFixture(),
        path: const ['Plumbing', 'Consumables'],
      ),
    );
    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Short path item'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
