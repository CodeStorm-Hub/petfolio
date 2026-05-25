import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BentoTile extends StatelessWidget {
  const BentoTile({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.radius = PetfolioThemeExtension.radius3xl,
    this.onTap,
    this.height,
    this.showBorder = true,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final double? height;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final tileColor = color ?? cs.surface;

    final tile = Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: showBorder
            ? BorderSide(color: pt.line200, width: 0.5)
            : BorderSide.none,
      ),
      color: tileColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );

    return height != null ? SizedBox(height: height, child: tile) : tile;
  }
}
