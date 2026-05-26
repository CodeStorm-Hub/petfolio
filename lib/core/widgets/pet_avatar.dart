import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:petfolio/core/domain/models/pet_species.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'skeleton_loader.dart';

export 'package:petfolio/core/domain/models/pet_species.dart'
    show PetSpecies;

enum PetAvatarSize {
  sm(32),
  md(40),
  lg(48),
  xl(56),
  xxl(72);

  const PetAvatarSize(this.dp);
  final double dp;
  double get dotSize => (dp * 0.25).clamp(8.0, 16.0);
  double get ringWidth => dp < 48 ? 1.5 : 2.0;
}

class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    this.imageUrl,
    this.species,
    this.size = PetAvatarSize.md,
    this.isOnline,
    this.semanticLabel = '',
    this.initials,
    this.showRing = false,
    this.onTap,
    this.borderColor,
    this.glow = false,
  });

  final String? imageUrl;
  final PetSpecies? species;
  final PetAvatarSize size;
  final bool? isOnline;
  final String semanticLabel;
  final String? initials;
  final bool showRing;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool glow;

  Color _getSpeciesColor(PetFolioColors colors, PetSpecies sp) {
    switch (sp) {
      case PetSpecies.dog:
        return colors.tangerine;
      case PetSpecies.cat:
        return colors.mint;
      case PetSpecies.bird:
        return colors.sunny;
      case PetSpecies.reptile:
        return colors.poppy;
      case PetSpecies.fish:
        return colors.sky;
      default:
        return colors.lilac;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PetFolioColors>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = size.dp;
    final sp = species ?? PetSpecies.dog;

    if (colors == null) {
      return SizedBox(width: d, height: d);
    }

    final baseColor = _getSpeciesColor(colors, sp);

    Widget innerDisc = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const FractionalOffset(0.3, 0.3),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.6),
            baseColor,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: initials != null && initials!.isNotEmpty
          ? Text(
              initials!.substring(0, initials!.length.clamp(0, 2)).toUpperCase(),
              style: TextStyle(
                fontSize: (d * 0.35).clamp(10.0, 24.0),
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            )
          : Text(
              sp.emoji,
              style: TextStyle(
                fontSize: d * 0.55,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
    );

    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: d,
          height: d,
          fit: BoxFit.cover,
          placeholder: (_, _) => SkeletonLoader(
            width: d,
            height: d,
            borderRadius: d / 2,
          ),
          errorWidget: (_, _, _) => innerDisc,
        ),
      );
    } else {
      avatar = SizedBox(width: d, height: d, child: innerDisc);
    }

    if (showRing || borderColor != null) {
      if (borderColor != null) {
        avatar = Container(
          width: d + 4,
          height: d + 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor!, width: 2),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: avatar,
        );
      } else {
        avatar = Container(
          width: d + 10,
          height: d + 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              transform: const GradientRotation(220 * math.pi / 180),
              colors: [
                colors.tangerine,
                colors.poppy,
                colors.sunny,
                colors.mint,
                colors.tangerine,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: baseColor.withValues(alpha: 0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(3.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            padding: const EdgeInsets.all(2.0),
            child: avatar,
          ),
        );
      }
    } else if (glow) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: avatar,
      );
    }

    if (isOnline != null) {
      final dotColor = isOnline!
          ? (isDark ? AppColors.mintD : AppColors.mint)
          : (isDark ? AppColors.ink300D : AppColors.ink300);
      final ringColor = isDark ? AppColors.surface0D : AppColors.surface0;

      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: PetfolioThemeExtension.durationSm,
              width: size.dotSize,
              height: size.dotSize,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: size.ringWidth),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      final hitArea = d < 48 ? 48.0 : d;
      avatar = GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: hitArea,
          height: hitArea,
          child: Center(child: avatar),
        ),
      );
    }

    return RepaintBoundary(
      child: Semantics(
        label: semanticLabel.isNotEmpty ? semanticLabel : null,
        image: imageUrl != null,
        child: avatar,
      ),
    );
  }
}
