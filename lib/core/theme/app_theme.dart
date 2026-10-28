import 'package:flutter/material.dart';
import 'app_colors.dart';

enum AppThemeMode {
  light,
  dark,
  oled,
}

class AppTheme {
  AppTheme._();

  // 1. Light Glassmorphic Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.slate50,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.sapphireBlue,
        surface: Colors.white.withValues(alpha: 0.85),
        surfaceContainerHighest: AppColors.slate100.withValues(alpha: 0.80),
        onSurface: AppColors.slate900,
        outline: AppColors.slate300.withValues(alpha: 0.80),
      ),
      fontFamily: 'sans-serif',
      cardColor: Colors.white.withValues(alpha: 0.75),
      dividerColor: AppColors.slate200.withValues(alpha: 0.60),
    );
  }

  // 2. Dark Glassmorphic Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.slate950,
      colorScheme: ColorScheme.dark(
        primary: AppColors.sapphireBlue,
        secondary: AppColors.iceBlue,
        surface: AppColors.slate900.withValues(alpha: 0.70),
        surfaceContainerHighest: AppColors.slate800.withValues(alpha: 0.60),
        onSurface: AppColors.slate100,
        outline: Colors.white.withValues(alpha: 0.12),
      ),
      fontFamily: 'sans-serif',
      cardColor: AppColors.slate900.withValues(alpha: 0.55),
      dividerColor: Colors.white.withValues(alpha: 0.08),
    );
  }

  // 3. Pure Black OLED Dark Theme
  static ThemeData get oledTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.pureBlack,
      colorScheme: ColorScheme.dark(
        primary: AppColors.iceBlue,
        secondary: AppColors.tealAccent,
        surface: AppColors.pureBlack,
        surfaceContainerHighest: const Color(0xFF0D1117),
        onSurface: Colors.white,
        outline: Colors.white.withValues(alpha: 0.16),
      ),
      fontFamily: 'sans-serif',
      cardColor: const Color(0xFF050505),
      dividerColor: Colors.white.withValues(alpha: 0.10),
    );
  }
}
