import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog_database.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog_screen.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/materials_catalog_text.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/materials_catalog_tiles.dart';
import 'inventory_screen_test.dart' as harness;

void main() {
  final source =
      jsonDecode(
            File(
              'docs/inventory_migration/materials_copper_review_001.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final actual = readInventoryCatalogDatabase(
    File('assets/inventory/browse_batch.sqlite').readAsBytesSync(),
  );
  final catalog = InventoryCatalog.fromJson(actual);

  test(
    'every review record survives SQLite with its complete source payload',
    () {
      final expected = {for (final row in source['items']) row['id']: row};
      final stored = {for (final row in actual['items']) row['id']: row};
      expect(stored, expected);
      expect(stored.length, 8);
    },
  );

  test(
    'independent size ordering, degree display and retained source names',
    () {
      expect(
        catalog
            .itemsAt(['Plumbing', 'Fittings', 'Copper', '90 Elbows'])
            .map((item) => item.variant),
        [
          '1/4 in',
          '3/8 in',
          '1/2 in',
          '3/4 in',
          '1 in',
          '1-1/4 in',
          '1-1/2 in',
          '2 in',
        ],
      );
      expect(materialsAngleLabel('22.5 Elbows'), '22.5° Elbows');
      expect(
        materialsAngleLabel('1/2 in Copper 90 Elbow'),
        '1/2 in Copper 90° Elbow',
      );
      expect(catalog.items.first.name, isNot(contains('°')));
      expect(
        compareMaterialsSizes('1/2 x 3/4 x 1/2', '1/2 x 1/2 x 3/4'),
        greaterThan(0),
      );
    },
  );

  test(
    'shared engine selects three, two, then one from width and text size',
    () {
      int columns(double width, double scale) =>
          AppLayoutEngine.materialsCatalogFor(
            width,
            textScaler: TextScaler.linear(scale),
            longestWordWidth: 70 * scale,
          ).columns;
      expect(columns(360, 1), 3);
      expect(columns(304, 1), 2);
      expect(columns(360, 2), 1);
    },
  );

  for (final dark in [false, true]) {
    for (final list in [false, true]) {
      for (final width in [320.0, 384.0, 768.0, 1440.0]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets(
            'fittings dark=$dark list=$list width=$width scale=$scale',
            (tester) async {
              await harness.pump(
                tester,
                Scaffold(
                  body: SingleChildScrollView(
                    child: MaterialsCatalogTiles(
                      listView: list,
                      entries: [
                        for (final name in [
                          '90° Elbows',
                          'Street 90° Elbows',
                          'Reducing Couplings',
                        ])
                          MaterialsCatalogTileData(label: name, onTap: () {}),
                      ],
                    ),
                  ),
                ),
                size: Size(width, 1000),
                scale: scale,
                dark: dark,
              );
              expect(find.byType(Image), findsNothing);
              for (final label in [
                '90° Elbows',
                'Street 90° Elbows',
                'Reducing Couplings',
              ]) {
                final text = find.text(label);
                final paragraph = tester.renderObject<RenderParagraph>(text);
                expect(
                  tester
                      .getRect(find.byKey(ValueKey('materials:$label')))
                      .contains(tester.getRect(text).center),
                  isTrue,
                );
                for (final word in RegExp(r'\S+').allMatches(label)) {
                  expect(
                    paragraph
                        .getBoxesForSelection(
                          TextSelection(
                            baseOffset: word.start,
                            extentOffset: word.end,
                          ),
                        )
                        .length,
                    1,
                    reason: 'Word must not split: ${word[0]}',
                  );
                }
              }
              final first = tester.getRect(
                find.byKey(const ValueKey('materials:90° Elbows')),
              );
              final second = tester.getRect(
                find.byKey(const ValueKey('materials:Street 90° Elbows')),
              );
              if (list) expect(second.top, greaterThanOrEqualTo(first.bottom));
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }

  testWidgets(
    'grid/list selection follows the path and item details have Add',
    (tester) async {
      await harness.pump(tester, InventoryCatalogScreen(catalog: catalog));
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();
      for (final name in ['Plumbing', 'Fittings', 'Copper', '90° Elbows']) {
        await tester.tap(find.text(name).last);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
              .selected,
          {true},
        );
        expect(find.byType(BackButton), findsOneWidget);
      }
      await tester.tap(find.text('Grid'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1/4 in'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(FilledButton, 'Add to My Inventory'),
        findsOneWidget,
      );
      // Never submit stock changes in a catalog navigation test.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('90° Elbows').first, findsOneWidget);
    },
  );
}
