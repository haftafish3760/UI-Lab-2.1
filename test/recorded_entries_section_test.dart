import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/recorded_entries_section.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/theme/operational_card_palette.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    testWidgets(
      'Entries paints opaque title, body and rows in ${theme.brightness}',
      (tester) async {
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: ColoredBox(
                    color: const Color(0xFFFF00FF),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: RecordedEntriesSection(
                        builder: (context) => Column(
                          children: [
                            const SizedBox(height: 50),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Material(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerLow,
                                child: const SizedBox(width: 180, height: 40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final pixels = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return bytes;
        });
        Color pixel(int x, int y) {
          final offset = (y * 200 + x) * 4;
          return Color.fromARGB(
            pixels!.getUint8(offset + 3),
            pixels.getUint8(offset),
            pixels.getUint8(offset + 1),
            pixels.getUint8(offset + 2),
          );
        }

        expect(pixel(20, 20), OperationalCardPalette.entries.start);
        expect(pixel(20, 150), OperationalCardPalette.entries.start);
        expect(pixel(20, 70), OperationalCardPalette.entries.row);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
