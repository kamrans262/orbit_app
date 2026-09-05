import 'package:flutter/material.dart';

import 'orbit_colors.dart';

abstract final class OrbitTheme {
  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: OrbitColors.background,
      colorScheme: const ColorScheme.dark(
        primary: OrbitColors.primary,
        secondary: OrbitColors.teal,
        surface: OrbitColors.backgroundElevated,
        error: OrbitColors.danger,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 30,
          height: 1.08,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
          color: OrbitColors.textPrimary,
        ),
        headlineSmall: const TextStyle(
          fontSize: 21,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: OrbitColors.textPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: 18,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: OrbitColors.textPrimary,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: OrbitColors.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: OrbitColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: OrbitColors.textSecondary,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: OrbitColors.textMuted,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: OrbitColors.textPrimary,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w600,
          color: OrbitColors.textMuted,
        ),
      ),
      dividerColor: OrbitColors.borderSubtle,
      splashColor: OrbitColors.primary.withValues(alpha: 0.10),
      highlightColor: Colors.transparent,
    );
  }
}
