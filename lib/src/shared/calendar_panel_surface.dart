import 'package:flutter/material.dart';

/// Presentation adapted read-only from 5.7's _CalendarPanelPainter.
/// The dark veil preserves the app's light-text contrast in dark mode.
class CalendarPanelSurface extends StatelessWidget {
  const CalendarPanelSurface({required this.child, super.key});
  final Widget child;

  static Color gridLine(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF8298A2)
      : const Color(0xFF43565E);

  @override
  Widget build(BuildContext context) => ClipRect(
    child: CustomPaint(
      painter: CalendarPanelPainter(
        dark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: child,
    ),
  );
}

class CalendarPanelPainter extends CustomPainter {
  const CalendarPanelPainter({required this.dark});
  final bool dark;

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
          stops: [0, .22, .48, .73, 1],
        ).createShader(rect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .18, size.height * .32),
        width: size.width * .72,
        height: size.height * .42,
      ),
      Paint()
        ..color = const Color(0xFFEDE7D2).withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .78, size.height * .68),
        width: size.width * .68,
        height: size.height * .5,
      ),
      Paint()
        ..color = const Color(0xFF667274).withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
    if (dark) {
      canvas.drawRect(
        rect,
        Paint()..color = const Color(0xFF121719).withValues(alpha: .88),
      );
    }
  }

  @override
  bool shouldRepaint(CalendarPanelPainter oldDelegate) =>
      dark != oldDelegate.dark;
}
