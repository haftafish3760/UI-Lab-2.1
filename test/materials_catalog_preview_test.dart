// Opt-in rendered review artifacts; not a golden baseline or owner acceptance.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog.dart';
import 'package:ui_lab_2_1/src/screens/inventory/catalog/inventory_catalog_screen.dart';
import 'inventory_screen_test.dart' as harness;

void main() {
  const enabled = bool.fromEnvironment('MATERIALS_PREVIEWS');
  testWidgets('render actual copper review screens', (tester) async {
    final font = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              'assets/document_templates/NotoSans-Regular.ttf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await tester.runAsync(font.load);
    final fallback = FontLoader('Ahem')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              'assets/document_templates/NotoSans-Regular.ttf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await tester.runAsync(fallback.load);
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await tester.runAsync(icons.load);
    final catalog = await tester.runAsync(InventoryCatalog.load);
    final output = Directory('build/materials_review')
      ..createSync(recursive: true);
    for (final wide in [false, true]) {
      for (final dark in [false, true]) {
        for (final list in [false, true]) {
          final key = GlobalKey();
          await harness.pump(
            tester,
            RepaintBoundary(
              key: key,
              child: Builder(
                builder: (context) => Theme(
                  data: Theme.of(context).copyWith(
                    appBarTheme: Theme.of(context).appBarTheme.copyWith(
                      titleTextStyle: Theme.of(context)
                          .appBarTheme
                          .titleTextStyle!
                          .copyWith(fontFamily: 'Roboto'),
                    ),
                  ),
                  child: InventoryCatalogScreen(
                    key: UniqueKey(),
                    catalog: catalog,
                    path: const ['Plumbing', 'Fittings', 'Copper', '90 Elbows'],
                    listView: list,
                  ),
                ),
              ),
            ),
            size: wide ? const Size(1280, 900) : const Size(384, 844),
            dark: dark,
          );
          await tester.pump();
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = (await tester.runAsync(
            () => boundary.toImage(pixelRatio: 1),
          ))!;
          final data = await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.png),
          );
          File(
            '${output.path}/${wide ? 'desktop' : 'phone'}-${dark ? 'dark' : 'light'}-${list ? 'list' : 'grid'}.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
          expect(tester.takeException(), isNull);
        }
      }
    }
  }, skip: !enabled);
}
