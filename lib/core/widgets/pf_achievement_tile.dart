import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

class PfAchievementTile extends StatelessWidget {
  const PfAchievementTile({
    super.key,
    required this.emoji,
    required this.color,
    required this.label,
    this.owned = true,
    this.index = 0,
    this.boxSize,
  });

  final String emoji;
  final Color color;
  final String label;
  final bool owned;
  final int index;

  // Fixed pixel size for the box (home-row mode).
  // null = Expanded to fill grid cell height (grid mode).
  final double? boxSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.ink950D : AppColors.ink950;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final angle = (index % 2 != 0 ? -3 : 3) * math.pi / 180;

    final box = Transform.rotate(
      angle: angle,
      child: Container(
        width: boxSize ?? double.infinity,
        height: boxSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: owned ? null : pt.line,
          gradient: owned
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, Color.lerp(color, Colors.white, 0.3)!],
                )
              : null,
          boxShadow: owned
              ? [
                  BoxShadow(
                    color: color.withAlpha(150),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: owned
            ? Text(emoji, style: const TextStyle(fontSize: 36))
            : ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
      ),
    );

    return Opacity(
      opacity: owned ? 1.0 : 0.42,
      child: Column(
        children: [
          if (boxSize != null) box else Expanded(child: box),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: labelColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
