import 'package:flutter/material.dart';

/// Meaning-based color families, shared across screens and employee contexts.
/// September 8 visual trial: exact shades still require owner acceptance.
@immutable
class OperationalCardTone {
  const OperationalCardTone(this.start, this.end, this.row);
  final Color start;
  final Color end;
  final Color row;
  static const ink = Color(0xFFF7F6EF);
  static const darkInk = Color(0xFF172A33);
  Color get foreground => start.computeLuminance() > .3 ? darkInk : ink;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [start, end],
  );
}

abstract final class OperationalCardPalette {
  static const plan = OperationalCardTone(
    Color(0xFF1976B2),
    Color(0xFF1976B2),
    Color(0xFFAFCFE1),
  );
  static const entries = OperationalCardTone(
    Color(0xFF72AE88),
    Color(0xFF72AE88),
    Color(0xFFAEC8B7),
  );
  static const attention = OperationalCardTone(
    Color(0xFFC8955B),
    Color(0xFFC8955B),
    Color(0xFFC8955B),
  );
  static const payments = OperationalCardTone(
    Color(0xFF2F7D32),
    Color(0xFF246529),
    Color(0xFF2F7D32),
  );
  static const expenses = OperationalCardTone(
    Color(0xFFB94A46),
    Color(0xFF943833),
    Color(0xFFB94A46),
  );
  static const miles = OperationalCardTone(
    Color(0xFF6954A0),
    Color(0xFF51407F),
    Color(0xFF6954A0),
  );
  static const work = OperationalCardTone(
    Color(0xFF146C70),
    Color(0xFF10585B),
    Color(0xFF146C70),
  );
  static const action = Color(0xFF303B40);

  /// Preserve accent hue, adjusting toward readable ink on the actual row.
  static Color readableAccent(Color color, Color background) {
    var result = color;
    for (var step = 0; step <= 10; step++) {
      result = Color.lerp(
        color,
        background.computeLuminance() > .3
            ? OperationalCardTone.darkInk
            : OperationalCardTone.ink,
        step / 10,
      )!;
      final a = result.computeLuminance();
      final b = background.computeLuminance();
      final contrast = ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
      if (contrast >= 3) break;
    }
    return result;
  }
}
