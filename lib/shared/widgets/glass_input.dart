import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class GlassInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final bool isMonospace;
  final AppThemeMode themeMode;
  final ValueChanged<String>? onChanged;

  const GlassInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.themeMode,
    this.prefixIcon,
    this.obscureText = false,
    this.isMonospace = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = themeMode == AppThemeMode.light;
    final isOled = themeMode == AppThemeMode.oled;

    final Color bgColor = isOled
        ? const Color(0xFF080808)
        : (isLight ? Colors.white.withValues(alpha: 0.80) : const Color(0xFF020617).withValues(alpha: 0.85));

    final Color borderColor = isLight
        ? AppColors.slate300.withValues(alpha: 0.80)
        : Colors.white.withValues(alpha: 0.12);

    final Color textColor = isLight ? AppColors.slate900 : Colors.white;
    final Color hintColor = isLight ? AppColors.slate400 : AppColors.slate500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isLight ? AppColors.slate700 : AppColors.slate300,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 13,
                color: hintColor,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 18, color: isLight ? AppColors.slate500 : AppColors.slate400)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
