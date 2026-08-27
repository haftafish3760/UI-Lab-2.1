import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF162326);
  static const muted = Color(0xFF526367);
  static const canvas = Color(0xFFDCE7E3);
  static const surface = Colors.white;
  static const border = Color(0xFFB8C6C2);
  static const strongBorder = Color(0xFF7D928C);
  static const green = Color(0xFF087A4A);
  static const greenSoft = Color(0xFFE2F3EA);
  static const blue = Color(0xFF2D6680);
  static const blueSoft = Color(0xFFE4F0F5);
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyMedium: TextStyle(color: AppColors.ink, height: 1.25),
    ),
    dividerColor: AppColors.border,
  );
}
