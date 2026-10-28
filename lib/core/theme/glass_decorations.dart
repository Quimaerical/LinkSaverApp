import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class GlassDecoration {
  GlassDecoration._();

  static BoxDecoration card({
    required BuildContext context,
    required AppThemeMode themeMode,
    double borderRadius = 20.0,
    bool isHighlighted = false,
  }) {
    final isLight = themeMode == AppThemeMode.light;
    final isOled = themeMode == AppThemeMode.oled;

    final Color bgColor;
    final Color borderColor;

    if (isOled) {
      bgColor = isHighlighted
          ? const Color(0xFF0F172A).withValues(alpha: 0.50)
          : const Color(0xFF050505).withValues(alpha: 0.85);
      borderColor = isHighlighted
          ? Colors.blueAccent.withValues(alpha: 0.40)
          : Colors.white.withValues(alpha: 0.12);
    } else if (isLight) {
      bgColor = isHighlighted
          ? Colors.white.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.70);
      borderColor = isHighlighted
          ? const Color(0xFF2563EB).withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.90);
    } else {
      // Dark
      bgColor = isHighlighted
          ? const Color(0xFF1E293B).withValues(alpha: 0.65)
          : const Color(0xFF0F172A).withValues(alpha: 0.45);
      borderColor = isHighlighted
          ? const Color(0xFF38BDF8).withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.10);
    }

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isLight
              ? Colors.black.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: isOled ? 0.30 : 0.45),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static ImageFilter get blurFilter => ImageFilter.blur(sigmaX: 12, sigmaY: 12);
}
