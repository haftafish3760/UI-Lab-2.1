import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';
import 'operational_card_palette.dart';

/// Product color tokens. Routine screens should use [ColorScheme] rather than
/// introducing one-off colors. The dark header is intentionally shared by both
/// modes so it remains a stable orientation landmark.
abstract final class AppColors {
  static const ink = Color(0xFF172A33);
  static const muted = Color(0xFF3D535E);

  static const canvas = Color(0xFFC9D8DF);
  static const surface = Color(0xFFC5D6DE);
  static const surfaceMuted = Color(0xFFB6CDD7);
  static const surfaceStrong = Color(0xFFBED1DA);
  static const border = Color(0xFF91A8B3);
  static const strongBorder = Color(0xFF8298A2);

  static const blue = Color(0xFF285F78);
  static const blueSoft = Color(0xFF91B8CD);
  static const green = Color(0xFF0B6B50);
  static const greenSoft = Color(0xFF95BFA8);
  static const startWorkday = Color(0xFF35E878);
  static const pickerBlue = Color(0xFF1E5A78);
  static const pickerBlueDeep = Color(0xFF102D3D);
  static const warning = Color(0xFF8B5A12);
  static const warningSoft = Color(0xFFF2E5CC);

  static const header = Color(0xFF162326);
  static const headerControl = Color(0xFF24353A);
  static const headerControlAlt = Color(0xFF162529);
  static const headerBorder = Color(0xFF607B82);
  static const onHeader = Color(0xFFF2F5F4);
  static const onHeaderMuted = Color(0xFFD0D9DA);

  // Maintainiac 5.7 dark palette. These are intentionally warmer and more
  // layered than a flat near-black Material dark scheme.
  static const darkCanvas = Color(0xFF202422);
  static const darkCanvasDeep = Color(0xFF101312);
  static const darkSurface = Color(0xFF303532);
  static const darkSurfaceMuted = Color(0xFF1B1F1D);
  static const darkSurfaceStrong = Color(0xFF555C56);
  static const darkField = Color(0xFFAAB4B9);
  static const darkFieldAlt = Color(0xFF8F9BA1);
  static const darkInk = Color(0xFFF3F0E6);
  static const darkLabel = Color(0xFFE9E4D6);
  static const darkBorder = Color(0xFF858176);
  static const darkBlue = Color(0xFF1976B9);
  static const darkGreen = Color(0xFF28A745);
  static const darkRed = Color(0xFFE3342F);
  static const darkYellow = Color(0xFFE0B42D);
  static const darkOrange = Color(0xFFF47C20);
}

abstract final class AppRadii {
  static const control = 7.0;
  static const surface = 8.0;
  static const overlay = 10.0;
}

/// Stable module colors used as a scanning aid, never as the only carrier of
/// meaning. Each tone is deliberately subdued and has a light/dark counterpart.
@immutable
class AppModuleColors extends ThemeExtension<AppModuleColors> {
  const AppModuleColors({
    required this.dashboard,
    required this.work,
    required this.expenses,
    required this.inventory,
    required this.maintenance,
  });

  final Color dashboard;
  final Color work;
  final Color expenses;
  final Color inventory;
  final Color maintenance;

  static const light = AppModuleColors(
    dashboard: Color(0xFF2F6572),
    work: Color(0xFF355F7A),
    expenses: Color(0xFF765923),
    inventory: Color(0xFF356759),
    maintenance: Color(0xFF625B75),
  );

  static const dark = AppModuleColors(
    dashboard: AppColors.darkGreen,
    work: Color(0xFF68B4E3),
    expenses: AppColors.darkYellow,
    inventory: AppColors.darkOrange,
    maintenance: Color(0xFFFF827B),
  );

  @override
  AppModuleColors copyWith({
    Color? dashboard,
    Color? work,
    Color? expenses,
    Color? inventory,
    Color? maintenance,
  }) => AppModuleColors(
    dashboard: dashboard ?? this.dashboard,
    work: work ?? this.work,
    expenses: expenses ?? this.expenses,
    inventory: inventory ?? this.inventory,
    maintenance: maintenance ?? this.maintenance,
  );

  @override
  AppModuleColors lerp(covariant AppModuleColors? other, double t) {
    if (other == null) return this;
    return AppModuleColors(
      dashboard: Color.lerp(dashboard, other.dashboard, t)!,
      work: Color.lerp(work, other.work, t)!,
      expenses: Color.lerp(expenses, other.expenses, t)!,
      inventory: Color.lerp(inventory, other.inventory, t)!,
      maintenance: Color.lerp(maintenance, other.maintenance, t)!,
    );
  }
}

abstract final class AppTheme {
  static final ThemeData light = _build(
    brightness: Brightness.light,
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    surfaceMuted: AppColors.surfaceMuted,
    surfaceStrong: AppColors.surfaceStrong,
    ink: AppColors.ink,
    muted: AppColors.muted,
    border: AppColors.border,
    strongBorder: AppColors.strongBorder,
    blue: AppColors.blue,
    blueSoft: AppColors.blueSoft,
    green: AppColors.green,
    greenSoft: AppColors.greenSoft,
    moduleColors: AppModuleColors.light,
    semanticColors: AppSemanticColors.light,
  );

  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    canvas: AppColors.darkCanvas,
    surface: AppColors.darkSurface,
    surfaceMuted: AppColors.darkSurfaceMuted,
    surfaceStrong: AppColors.darkSurfaceStrong,
    ink: AppColors.darkInk,
    muted: AppColors.darkLabel,
    border: AppColors.darkBorder,
    strongBorder: AppColors.darkFieldAlt,
    blue: AppColors.darkBlue,
    blueSoft: const Color(0xFF173C5D),
    green: AppColors.darkGreen,
    greenSoft: const Color(0xFF1D4A2A),
    moduleColors: AppModuleColors.dark,
    semanticColors: AppSemanticColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color surfaceMuted,
    required Color surfaceStrong,
    required Color ink,
    required Color muted,
    required Color border,
    required Color strongBorder,
    required Color blue,
    required Color blueSoft,
    required Color green,
    required Color greenSoft,
    required AppModuleColors moduleColors,
    required AppSemanticColors semanticColors,
  }) {
    final scheme = ColorScheme.fromSeed(seedColor: blue, brightness: brightness)
        .copyWith(
          primary: blue,
          onPrimary: brightness == Brightness.light
              ? const Color(0xFFF7FAFB)
              : const Color(0xFF10232C),
          primaryContainer: blueSoft,
          onPrimaryContainer: brightness == Brightness.light ? ink : blue,
          secondary: green,
          onSecondary: brightness == Brightness.light
              ? const Color(0xFFF7FAFB)
              : const Color(0xFF10271F),
          secondaryContainer: greenSoft,
          onSecondaryContainer: brightness == Brightness.light ? ink : green,
          surface: surface,
          surfaceContainerLowest: canvas,
          surfaceContainerLow: surfaceMuted,
          surfaceContainer: surface,
          surfaceContainerHigh: surfaceStrong,
          surfaceContainerHighest: surfaceStrong,
          onSurface: ink,
          onSurfaceVariant: muted,
          outline: border,
          outlineVariant: strongBorder,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      dividerColor: border,
    );
    final textTheme = base.textTheme.apply(bodyColor: ink, displayColor: ink);

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[moduleColors, semanticColors],
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.3,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: blueSoft,
        surfaceTintColor: Colors.transparent,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
            decoration: states.contains(WidgetState.selected)
                ? TextDecoration.underline
                : null,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border),
          borderRadius: BorderRadius.circular(AppRadii.overlay),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.overlay),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: strongBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: IconThemeData(color: ink, size: 22),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: OperationalCardPalette.action,
        foregroundColor: OperationalCardTone.ink,
      ),
    );
  }
}
