import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/calendar_panel_surface.dart';

void main() {
  testWidgets('calendar leaves surrounding pixels untouched on every edge', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: const SizedBox(
              width: 160,
              height: 160,
              child: ColoredBox(
                color: Color(0xFFFF00FF),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CalendarPanelSurface(
                    includeSurround: true,
                    child: SizedBox.expand(),
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
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    for (var y = 0; y < 160; y++) {
      for (var x = 0; x < 160; x++) {
        if (x >= 20 && x < 140 && y >= 20 && y < 140) continue;
        final index = (y * 160 + x) * 4;
        expect(bytes!.sublist(index, index + 4), [
          255,
          0,
          255,
          255,
        ], reason: 'Overflow at $x, $y');
      }
    }
  });
}
