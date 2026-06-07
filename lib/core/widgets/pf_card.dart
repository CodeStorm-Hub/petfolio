import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PfCard extends StatelessWidget {
  const PfCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderRadius = 24.0,
    this.boxShadow,
    this.border,
    this.squircle = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final BoxBorder? border;
  /// Uses M3 Expressive [ContinuousRectangleBorder] (squircle) instead of
  /// the standard [RoundedRectangleBorder].
  final bool squircle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? cs.surface;
    final shadows = boxShadow ?? [
      BoxShadow(
        color: isDark ? AppColors.shadowE1D : AppColors.shadowE1L,
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];

    if (squircle) {
      final borderSide = border is Border
          ? (border! as Border).top
          : BorderSide(color: isDark ? AppColors.lineD : AppColors.line);
      return Container(
        padding: padding,
        decoration: ShapeDecoration(
          color: bg,
          shadows: shadows,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius * 2),
            side: borderSide,
          ),
        ),
        child: child,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
