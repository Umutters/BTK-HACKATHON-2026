import 'package:flutter/material.dart';

/// Cyber-Finance Forge — Design System Colors
class AppColors {
  AppColors._();

  // ─── Background Layers ────────────────────────────────────────────────────
  static const Color background = Color(0xFF131313);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surface = Color(0xFF201F1F);
  static const Color surfaceVariant = Color(0xFF353534);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFE5E2E1); // primary text
  static const Color onSurfaceVariant = Color(0xFFC5C8B6); // secondary text
  static const Color outline = Color(0xFF8F9282);
  static const Color outlineVariant = Color(0xFF44483A);

  // Convenience aliases used across widgets
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;

  // ─── Neon Lime — primary accent (actions, growth, "winning") ─────────────
  static const Color neonLime = Color(0xFFDEFF9A);
  static const Color neonLimeDim = Color(0xFFB2D272);
  static const Color neonLimeContainer = Color(0xFFCEEE8B);
  // Alias for legacy widgets
  static const Color secondary = neonLime;

  // ─── Cyber Blue — secondary (data, intelligence, "processing") ────────────
  static const Color cyberBlue = Color(0xFF00E5FF);
  static const Color cyberBlueContainer = Color(0xFF00E3FD);
  static const Color cyberBlueDim = Color(0xFF00DAF3);
  // Alias for legacy widgets
  static const Color primary = cyberBlue;

  // ─── Cyber Magenta — alerts, losses, critical errors ─────────────────────
  static const Color cyberMagenta = Color(0xFFFF007A);

  // ─── Status ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF4CAF50);

  // ─── Glass Surfaces ───────────────────────────────────────────────────────
  static const Color glass05 = Color(0x0DFFFFFF); // 5% white fill
  static const Color glass08 = Color(0x14FFFFFF); // 8% white fill
  static const Color glass10 = Color(0x1AFFFFFF); // 10% white fill
  static const Color glass12 = Color(0x1EFFFFFF); // 12% border
  static const Color glass15 = Color(0x26FFFFFF); // 15% active border

  // ─── Neon Lime translucents ───────────────────────────────────────────────
  static const Color neonLime10 = Color(0x1ADEFF9A);
  static const Color neonLime20 = Color(0x33DEFF9A);
  static const Color neonLime30 = Color(0x4DDEFF9A);
  static const Color neonLime50 = Color(0x80DEFF9A);
  // Legacy aliases
  static const Color glowLime = neonLime;
  static const Color glowLime20 = neonLime20;
  static const Color glowLime30 = neonLime30;
  static const Color glowLime50 = neonLime50;

  // ─── Cyber Blue translucents ──────────────────────────────────────────────
  static const Color cyberBlue10 = Color(0x1A00E5FF);
  static const Color cyberBlue15 = Color(0x2600E5FF);
  static const Color cyberBlue20 = Color(0x3300E5FF);
  static const Color cyberBlue30 = Color(0x4D00E5FF);
  static const Color cyberBlue50 = Color(0x8000E5FF);
  // Legacy aliases
  static const Color glowCyan = cyberBlue;
  static const Color glowCyan15 = cyberBlue15;
  static const Color glowCyan20 = cyberBlue20;
  static const Color primary10 = cyberBlue10;
  static const Color primary15 = cyberBlue15;
  static const Color primary20 = cyberBlue20;
  static const Color primary40 = cyberBlue30;

  // ─── Cyber Magenta translucents ───────────────────────────────────────────
  static const Color cyberMagenta20 = Color(0x33FF007A);
  static const Color cyberMagenta30 = Color(0x4DFF007A);

  // ─── Gradients ────────────────────────────────────────────────────────────

  /// Neon Lime gradient for primary buttons
  static const LinearGradient limeGradient = LinearGradient(
    colors: [neonLime, neonLimeDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dual-gradient for progress bars: Cyber Blue → Neon Lime
  static const LinearGradient progressGradient = LinearGradient(
    colors: [cyberBlue, neonLime],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Legacy alias
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [cyberBlue, cyberBlueDim],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Misc legacy
  static const Color progressBackground = surfaceContainerHigh;
  static const Color cardBorder = glass12;
}
