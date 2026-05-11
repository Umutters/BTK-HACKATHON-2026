import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Cyber-Finance Forge — Dark theme
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyberBlue,
        secondary: AppColors.neonLime,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.background,
        onSecondary: AppColors.background,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.cyberBlue,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glass08,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          side: const BorderSide(color: AppColors.glass12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
      ),
    );

    // Apply Outfit to the entire text theme
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Outfit',
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
    );
  }
}
