import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'linksaver_logo.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? trailing;
  final AppThemeMode themeMode;
  final bool showAppLogo;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.themeMode,
    this.icon,
    this.trailing,
    this.showAppLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = themeMode == AppThemeMode.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (showAppLogo) ...[
                    Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.sapphireBlue.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: const LinkSaverLogo(size: 24),
                    ),
                    const SizedBox(width: 12),
                  ] else if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Icon(icon, size: 20, color: AppColors.sapphireBlue),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: isLight ? AppColors.slate900 : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isLight ? AppColors.slate500 : AppColors.slate400,
          ),
        ),
      ],
    );
  }
}
