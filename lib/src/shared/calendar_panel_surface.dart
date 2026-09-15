import 'package:flutter/material.dart';

/// Exact background painter and decoration order from 5.7 Active:
/// lib/shared/calendar/app_month_calendar.dart and its widgets part.
/// No theme tint, dark veil, or opaque panel is added.
class CalendarPanelSurface extends StatelessWidget {
  const CalendarPanelSurface({
    required this.child,
    this.includeSurround = false,
    super.key,
  });
  final Widget child;
  final bool includeSurround;

  // 5.7 Active AppScreenShell's app_background_painter.dart.
  static const surround = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A3337), Color(0xFF354147), Color(0xFF222B30)],
  );

  static Color gridLine(BuildContext context) => const Color(0xFF111517);

  static const decoration = BoxDecoration(
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFF111517), width: 1.4),
    ),
    boxShadow: [
      BoxShadow(color: Color(0x88000000), blurRadius: 7, offset: Offset(0, 3)),
    ],
  );

  static const headerForeground = Color(0xFFF7FAF4);

  static const textShadows = [
    Shadow(color: Color(0xEE000000), blurRadius: 2, offset: Offset(0, 1)),
    Shadow(color: Color(0xAA000000), blurRadius: 5),
  ];

  @override
  Widget build(BuildContext context) {
    final panel = CustomPaint(
      painter: const CalendarPanelPainter(),
      child: Container(
        width: double.infinity,
        decoration: decoration,
        child: child,
      ),
    );
    return ClipRect(
      child: includeSurround
          ? DecoratedBox(
              decoration: const BoxDecoration(gradient: surround),
              child: panel,
            )
          : panel,
    );
  }
}

class CalendarPanelPainter extends CustomPainter {
  const CalendarPanelPainter();

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
  bool shouldRepaint(covariant CalendarPanelPainter oldDelegate) => false;
}
