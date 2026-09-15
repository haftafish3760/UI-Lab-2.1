import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/calendar_panel_surface.dart';

void main() {
  for (final size in [const Size(320, 426), const Size(400, 476)]) {
    for (final brightness in Brightness.values) {
      testWidgets('5.7 background pixel parity $size $brightness', (
        tester,
      ) async {
        Future<List<int>> render(bool reference) async {
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: key,
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: reference
                          ? CustomPaint(
                              painter: const ReferenceCalendarPanelPainter(),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF111517),
                                    width: 1.4,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x88000000),
                                      blurRadius: 7,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const SizedBox.expand(),
                              ),
                            )
                          : const CalendarPanelSurface(
                              child: SizedBox.expand(),
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
          final pixels = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final data = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            image.dispose();
            return data!.buffer.asUint8List().toList();
          });
          return pixels!;
        }

        final expected = await render(true);
        final actual = await render(false);
        expect(actual, orderedEquals(expected));
      });
    }
  }
}

// Frozen, verbatim 5.7 Active painter; only its class name changes.
// Source: lib/shared/calendar/app_month_calendar_widgets.dart (2026-09-12).
class ReferenceCalendarPanelPainter extends CustomPainter {
  const ReferenceCalendarPanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0E4DC),
            Color(0xFFB6B9AB),
            Color(0xFFC9D0D3),
            Color(0xFF8F9A9D),
            Color(0xFFD5D0BE),
          ],
          stops: [0, 0.22, 0.48, 0.73, 1],
        ).createShader(rect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.18, size.height * 0.32),
        width: size.width * 0.72,
        height: size.height * 0.42,
      ),
      Paint()
        ..color = const Color(0xFFEDE7D2).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.68),
        width: size.width * 0.68,
        height: size.height * 0.5,
      ),
      Paint()
        ..color = const Color(0xFF667274).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
  }

  @override
  bool shouldRepaint(covariant ReferenceCalendarPanelPainter oldDelegate) =>
      false;
}
