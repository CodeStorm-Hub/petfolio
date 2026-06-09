import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({
    super.key,
    required this.rating,
    this.size = 18,
    this.onRatingChanged,
    this.semanticLabel,
  });

  final double rating;
  final double size;
  final ValueChanged<int>? onRatingChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final interactive = onRatingChanged != null;

    return Semantics(
      label: semanticLabel ?? '${rating.toStringAsFixed(1)} out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final starIndex = i + 1;
          final filled = rating >= starIndex - 0.25;
          final half = !filled && rating > starIndex - 0.75;

          Widget icon = Icon(
            filled
                ? Icons.star_rounded
                : half
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: AppColors.sunny700,
          );

          if (interactive) {
            icon = GestureDetector(
              onTap: () => onRatingChanged!(starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: icon,
              ),
            );
          }

          return icon;
        }),
      ),
    );
  }
}
