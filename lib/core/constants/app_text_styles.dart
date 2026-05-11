import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Cyber-Finance Forge typography.
/// Outfit (display/body) + Space Grotesk (labels/data) — bundled as assets.
class AppTextStyles {
  AppTextStyles._();

  // ─── Display — Outfit ─────────────────────────────────────────────────────

  static const TextStyle display = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.onSurface,
    letterSpacing: -0.96,
    height: 1.1,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.3,
  );

  // ─── Headlines ────────────────────────────────────────────────────────────

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.3,
  );

  // ─── Titles ───────────────────────────────────────────────────────────────

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    height: 1.4,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.6,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.6,
  );
  // ─── Labels — Space Grotesk ───────────────────────────────────────────────

  static const TextStyle labelCaps = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    letterSpacing: 1.2,
    height: 1.0,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    letterSpacing: 1.04,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 1.1,
  );
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 1.0,
  );

  // ─── Data Mono — Space Grotesk ────────────────────────────────────────────

  static const TextStyle dataMono = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    height: 1.4,
  );

  // ─── Semantic aliases ─────────────────────────────────────────────────────

  static const TextStyle xpText = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.cyberBlue,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.cyberBlue,
    letterSpacing: 0.5,
  );
}
