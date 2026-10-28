import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_decorations.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final AppThemeMode themeMode;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isInteractive;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    required this.themeMode,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = 20.0,
    this.isInteractive = false,
    this.onTap,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: GlassDecoration.blurFilter,
        child: Container(
          padding: widget.padding,
          decoration: GlassDecoration.card(
            context: context,
            themeMode: widget.themeMode,
            borderRadius: widget.borderRadius,
            isHighlighted: _isHovered,
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.isInteractive || widget.onTap != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : (_isHovered ? 1.008 : 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
