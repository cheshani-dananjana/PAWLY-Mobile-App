// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFBF5700);    // Burnt Orange
  static const Color textDark = Color(0xFF251605);   // Dark Espresso Brown
  static const Color bgCream = Color(0xFFF7DBA7);    // Soft Warm Cream
  static const Color cardWhite = Color(0xFFFFFFFF);  // Pure White Cards
}

ThemeData buildPawlyTheme() {
  return ThemeData(
    scaffoldBackgroundColor: AppColors.bgCream,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.cardWhite,
      onPrimary: Colors.white,
      onSurface: AppColors.textDark,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textDark),
      bodyMedium: TextStyle(color: AppColors.textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}