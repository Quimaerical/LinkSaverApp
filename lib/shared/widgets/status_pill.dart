import 'package:flutter/material.dart';

enum PillVariant {
  success,
  warning,
  info,
  neutral,
  error,
}

class StatusPill extends StatelessWidget {
  final String label;
  final PillVariant variant;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    this.variant = PillVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor;
    final Color bgColor;
    final Color borderColor;

    switch (variant) {
      case PillVariant.success:
        textColor = const Color(0xFF4ADE80);
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.15);
        borderColor = const Color(0xFF22C55E).withValues(alpha: 0.30);
        break;
      case PillVariant.warning:
        textColor = const Color(0xFFFBBF24);
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.30);
        break;
      case PillVariant.info:
        textColor = const Color(0xFF38BDF8);
        bgColor = const Color(0xFF0284C7).withValues(alpha: 0.15);
        borderColor = const Color(0xFF38BDF8).withValues(alpha: 0.30);
        break;
      case PillVariant.error:
        textColor = const Color(0xFFFB7185);
        bgColor = const Color(0xFFE11D48).withValues(alpha: 0.15);
        borderColor = const Color(0xFFFB7185).withValues(alpha: 0.30);
        break;
      case PillVariant.neutral:
        textColor = const Color(0xFF94A3B8);
        bgColor = Colors.white.withValues(alpha: 0.08);
        borderColor = Colors.white.withValues(alpha: 0.15);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
