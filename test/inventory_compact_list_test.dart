import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/materials_catalog_tiles.dart';

void main() {
  for (final example in [
    (800.0, 3, 1.0),
    (1100.0, 4, 1.0),
    (360.0, 1, 1.0),
    (800.0, 1, 2.0),
  ]) {
    testWidgets(
      'list uses ${example.$2} columns at ${example.$1}, scale ${example.$3}',
      (tester) async {
        tester.view.physicalSize = Size(example.$1, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(example.$3)),
              child: child!,
            ),
            home: Scaffold(
              body: MaterialsCatalogTiles(
                listView: true,
                entries: List.generate(
                  8,
                  (i) => MaterialsCatalogTileData(
                    label: 'Item $i',
                    detail: 'Truck stock',
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        final first = tester.getRect(
          find.byKey(const ValueKey('materials:Item 0')),
        );
        for (var i = 1; i < example.$2; i++) {
          final next = tester.getRect(
            find.byKey(ValueKey('materials:Item $i')),
          );
          expect(next.top, first.top);
          expect(next.left, greaterThan(first.left));
        }
        final wrapped = tester.getRect(
          find.byKey(ValueKey('materials:Item ${example.$2}')),
        );
        expect(wrapped.top, greaterThan(first.top));
        expect(first.width, lessThanOrEqualTo(360 * example.$3));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
