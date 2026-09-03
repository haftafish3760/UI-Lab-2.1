import 'package:flutter/material.dart';

@immutable
class DashboardColors extends ThemeExtension<DashboardColors> {
  const DashboardColors({
    required this.canvasTop,
    required this.canvasBottom,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.border,
    required this.header,
    required this.headerControl,
    required this.onHeader,
    required this.attention,
    required this.attentionSurface,
    required this.plan,
    required this.planSurface,
    required this.entries,
    required this.entriesSurface,
    required this.calendar,
    required this.calendarSurface,
  });

  final Color canvasTop;
  final Color canvasBottom;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color ink;
  final Color inkMuted;
  final Color border;
  final Color header;
  final Color headerControl;
  final Color onHeader;
  final Color attention;
  final Color attentionSurface;
  final Color plan;
  final Color planSurface;
  final Color entries;
  final Color entriesSurface;
  final Color calendar;
  final Color calendarSurface;

  @override
  DashboardColors copyWith() => this;

  @override
  DashboardColors lerp(covariant DashboardColors? other, double t) =>
      other ?? this;

  static const light = DashboardColors(
    canvasTop: Color(0xFFD7E5EA),
    canvasBottom: Color(0xFFC4D6DE),
    surface: Color(0xFFDCE9ED),
    surfaceRaised: Color(0xFFE6EFF2),
    surfaceMuted: Color(0xFFCADCE3),
    ink: Color(0xFF172A33),
    inkMuted: Color(0xFF536871),
    border: Color(0xFF8EA7B2),
    header: Color(0xFF173038),
    headerControl: Color(0xFF29464F),
    onHeader: Color(0xFFF3F7F7),
    attention: Color(0xFFB43D2D),
    attentionSurface: Color(0xFFEECFC5),
    plan: Color(0xFF2E6FA8),
    planSurface: Color(0xFFC9E0F0),
    entries: Color(0xFF28A745),
    entriesSurface: Color(0xFFCBE4D1),
    calendar: Color(0xFF4B5F73),
    calendarSurface: Color(0xFFDCE4EB),
  );

  static const dark = DashboardColors(
    canvasTop: Color(0xFF182126),
    canvasBottom: Color(0xFF101619),
    surface: Color(0xFF202B30),
    surfaceRaised: Color(0xFF29363C),
    surfaceMuted: Color(0xFF1B2529),
    ink: Color(0xFFEAF0F1),
    inkMuted: Color(0xFFB5C1C5),
    border: Color(0xFF50636B),
    header: Color(0xFF10252C),
    headerControl: Color(0xFF29444D),
    onHeader: Color(0xFFF2F7F7),
    attention: Color(0xFFFF8F78),
    attentionSurface: Color(0xFF4A2B25),
    plan: Color(0xFF62A9DC),
    planSurface: Color(0xFF243D50),
    entries: Color(0xFF46C76A),
    entriesSurface: Color(0xFF23443A),
    calendar: Color(0xFFA7C1D6),
    calendarSurface: Color(0xFF2B3945),
  );
}

abstract final class AppTheme {
  static ThemeData light = _theme(Brightness.light, DashboardColors.light);
  static ThemeData dark = _theme(Brightness.dark, DashboardColors.dark);

  static ThemeData _theme(Brightness brightness, DashboardColors palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.plan,
      brightness: brightness,
      surface: palette.surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(
        primary: palette.plan,
        surface: palette.surface,
        onSurface: palette.ink,
        outline: palette.border,
      ),
      scaffoldBackgroundColor: palette.canvasBottom,
      extensions: [palette],
      dividerColor: palette.border,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.planSurface,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: palette.ink, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.entries,
          foregroundColor: const Color(0xFF07130F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(0, 44),
        ),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme
          .apply(bodyColor: palette.ink, displayColor: palette.ink),
    );
  }
}
