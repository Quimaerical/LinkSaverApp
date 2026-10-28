import 'package:flutter/material.dart';

class LinkSaverLogo extends StatelessWidget {
  final double size;
  final bool monochrome;
  final Color? color;

  const LinkSaverLogo({
    super.key,
    this.size = 24.0,
    this.monochrome = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (monochrome && color != null) {
      return Image.asset(
        'assets/images/linksaver_icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: BlendMode.srcIn,
      );
    }

    return Image.asset(
      'assets/images/linksaver_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
