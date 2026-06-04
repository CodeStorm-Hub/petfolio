import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:petfolio/core/platform/web_image_cache.dart';
import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'skeleton_loader.dart';

export 'package:petfolio/features/pet_profile/data/models/pet_species.dart'
    show PetSpecies;

// ─────────────────────────────────────────────────────────────────────────────
// Size token
// ─────────────────────────────────────────────────────────────────────────────

enum PetAvatarSize {
  sm(32), md(40), lg(48), xl(56), xxl(72);

  const PetAvatarSize(this.dp);
  final double dp;
  double get dotSize => (dp * 0.25).clamp(8.0, 16.0);
  double get ringWidth => dp < 48 ? 1.5 : 2.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// PetAvatar
// ─────────────────────────────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = size.dp;

    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = _NetworkAvatar(
        imageUrl: imageUrl!,
        diameter: d,
        isDark: isDark,
        species: species,
        initials: initials,
        memCacheWidth: networkImageMemCacheWidth(
          context,
          d,
          maxPixels: webNetworkImageMemCacheAvatar,
        ),
      );
    } else {
      avatar = _SpeciesDisc(
        species: species,
        diameter: d,
        isDark: isDark,
        initials: initials,
      );
    }

    if (showRing || borderColor != null) {
      if (borderColor != null) {
        avatar = Container(
          width: d + 4,
          height: d + 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor!, width: 2),
          ),
          child: avatar,
        );
      } else {
        avatar = _RainbowRing(diameter: d, child: avatar);
      }
    }

    if (isOnline != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: _StatusDot(
              isOnline: isOnline!,
              isDark: isDark,
              dotSize: size.dotSize,
              ringWidth: size.ringWidth,
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      final hitArea = d < 48 ? 48.0 : d;
      avatar = GestureDetector(
        onTap: onTap,
        child: SizedBox(width: hitArea, height: hitArea, child: Center(child: avatar)),
      );
    }

    return Semantics(
      label: semanticLabel.isNotEmpty ? semanticLabel : null,
      image: imageUrl != null,
      child: avatar,
    );
  }
}

// ─── Species emoji disc ───────────────────────────────────────────────────────

class _SpeciesDisc extends StatelessWidget {
  const _SpeciesDisc({
    required this.species,
    required this.diameter,
    required this.isDark,
    this.initials,
  });

  final PetSpecies? species;
  final double diameter;
  final bool isDark;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    final sp = species ?? PetSpecies.dog;
    final base = sp.resolvedAccent(isDark);
    final soft = sp.resolvedTint(isDark);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [soft, base],
        ),
      ),
      alignment: Alignment.center,
      child: initials != null
          ? Text(
              initials!.substring(0, initials!.length.clamp(0, 2)).toUpperCase(),
              style: TextStyle(
                fontSize: (diameter * 0.35).clamp(10.0, 24.0),
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
            )
          : Text(
              sp.emoji,
              style: TextStyle(fontSize: diameter * 0.55, height: 1.0),
            ),
    );
  }
}

// ─── Network avatar ───────────────────────────────────────────────────────────

class _NetworkAvatar extends StatelessWidget {
  const _NetworkAvatar({
    required this.imageUrl,
    required this.diameter,
    required this.isDark,
    this.species,
    this.initials,
    this.memCacheWidth,
  });

  final String imageUrl;
  final double diameter;
  final bool isDark;
  final PetSpecies? species;
  final String? initials;
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: diameter,
        height: diameter,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheWidth,
        fit: BoxFit.cover,
        placeholder: (_, _) => SkeletonLoader(
          width: diameter,
          height: diameter,
          borderRadius: diameter / 2,
        ),
        errorWidget: (_, _, _) => _SpeciesDisc(
          species: species,
          diameter: diameter,
          isDark: isDark,
          initials: initials,
        ),
      ),
    );
  }
}

// ─── Rainbow ring ─────────────────────────────────────────────────────────────

class _RainbowRing extends StatelessWidget {
  const _RainbowRing({required this.diameter, required this.child});

  final double diameter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter + 10,
      height: diameter + 10,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: 3.8,
          colors: [
            AppColors.tangerine,
            AppColors.poppy,
            AppColors.sunny,
            AppColors.mint,
            AppColors.tangerine,
          ],
        ),
      ),
      padding: const EdgeInsets.all(2), // 2px gradient border
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        padding: const EdgeInsets.all(3), // 3px white gap
        child: child,
      ),
    );
  }
}

// ─── Status dot ───────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.isOnline,
    required this.isDark,
    required this.dotSize,
    required this.ringWidth,
  });

  final bool isOnline;
  final bool isDark;
  final double dotSize;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final dotColor = isOnline
        ? (isDark ? AppColors.mintD : AppColors.mint)
        : (isDark ? AppColors.ink300D : AppColors.ink300);
    final ringColor = isDark ? AppColors.surface0D : AppColors.surface0;

    return AnimatedContainer(
      duration: PetfolioThemeExtension.durationSm,
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: ringWidth),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
    );
  }
}
