import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final AppThemeMode themeMode;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.themeMode,
    this.isPrimary = true,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  void _handleTap() {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color border;

    if (widget.isPrimary) {
      bg = isEnabled
          ? AppColors.primaryBlue.withValues(alpha: widget.themeMode == AppThemeMode.oled ? 0.85 : 0.90)
          : AppColors.slate700.withValues(alpha: 0.50);
      border = Colors.white.withValues(alpha: 0.25);
    } else {
      bg = Colors.white.withValues(alpha: widget.themeMode == AppThemeMode.light ? 0.70 : 0.08);
      border = Colors.white.withValues(alpha: 0.15);
    }

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.0),
            boxShadow: widget.isPrimary && isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    child: widget.child,
                  ),
          ),
        ),
      ),
    );
  }
}
