import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'skeleton_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Size token
// ─────────────────────────────────────────────────────────────────────────────

/// §4.4: avatars always use `pill` radius (fully circular).
enum PetAvatarSize {
  sm(32),
  md(40),
  lg(48),
  xl(56);

  const PetAvatarSize(this.dp);

  /// Logical-pixel diameter of the avatar circle.
  final double dp;

  /// Status indicator dot diameter (~25 % of avatar, min 8 dp).
  double get dotSize => (dp * 0.25).clamp(8.0, 16.0);

  /// White ring around the dot keeps it legible on any background.
  double get ringWidth => dp < 48 ? 1.5 : 2.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// PetAvatar
// ─────────────────────────────────────────────────────────────────────────────

/// Circular avatar for pets or users, with an optional online/offline indicator.
///
/// Follows PetFolio §4.4: avatars always use `pill` (fully circular) radius.
/// The online dot uses `meadow/500` (Health pillar green) as its color per
/// the design system's semantic color usage.
///
/// ```dart
/// // Pet with online indicator
/// PetAvatar(
///   imageUrl: pet.avatarUrl,
///   isOnline: true,
///   semanticLabel: pet.name,
/// )
///
/// // Placeholder / no image
/// PetAvatar(size: PetAvatarSize.lg)
///
/// // Custom initials fallback
/// PetAvatar(initials: 'MX', size: PetAvatarSize.md)
/// ```
class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    this.imageUrl,
    this.size = PetAvatarSize.md,
    this.isOnline,
    this.semanticLabel = '',
    this.initials,
    this.onTap,
    this.borderColor,
  });

  /// Remote image URL. Uses [CachedNetworkImage] with a shimmer placeholder.
  final String? imageUrl;

  final PetAvatarSize size;

  /// `true` → green dot, `false` → gray dot, `null` → no indicator.
  final bool? isOnline;

  /// Accessibility label passed to [Semantics].
  final String semanticLabel;

  /// Shown when [imageUrl] is null or fails to load. Max 2 characters.
  final String? initials;

  final VoidCallback? onTap;

  /// Optional colored ring around the avatar (e.g. pillar accent for active match).
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = size.dp;

    Widget avatar = _AvatarImage(
      imageUrl: imageUrl,
      initials: initials,
      diameter: d,
      isDark: isDark,
    );

    // Optional colored ring
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
    }

    // Stack with status indicator
    if (isOnline != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: borderColor != null ? 2 : 0,
            bottom: borderColor != null ? 2 : 0,
            child: _StatusDot(
              isOnline: isOnline!,
              size: size,
              isDark: isDark,
            ),
          ),
        ],
      );
    }

    // Tap affordance (§5.1: touch targets ≥ 48 dp)
    if (onTap != null) {
      final hitArea = d < 48 ? 48.0 : d;
      avatar = GestureDetector(
        onTap: onTap,
        child: SizedBox(width: hitArea, height: hitArea, child: Center(child: avatar)),
      );
    }

    return Semantics(
      label: semanticLabel.isNotEmpty
          ? '$semanticLabel, ${isOnline == true ? 'online' : isOnline == false ? 'offline' : ''}'
          : null,
      image: imageUrl != null,
      child: avatar,
    );
  }
}

// ── Avatar image ─────────────────────────────────────────────────────────────

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.imageUrl,
    required this.initials,
    required this.diameter,
    required this.isDark,
  });

  final String? imageUrl;
  final String? initials;
  final double diameter;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final radius = diameter / 2;
    final bgColor = isDark ? AppColors.blue100D : AppColors.blue100;
    final fgColor = isDark ? AppColors.blue500D : AppColors.blue700;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          placeholder: (_, _) => SkeletonLoader(
            width: diameter,
            height: diameter,
            borderRadius: radius,
          ),
          errorWidget: (_, _, _) => _InitialsCircle(
            initials: initials,
            diameter: diameter,
            bgColor: bgColor,
            fgColor: fgColor,
          ),
        ),
      );
    }

    return _InitialsCircle(
      initials: initials,
      diameter: diameter,
      bgColor: bgColor,
      fgColor: fgColor,
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({
    required this.initials,
    required this.diameter,
    required this.bgColor,
    required this.fgColor,
  });

  final String? initials;
  final double diameter;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    final label = initials?.substring(0, initials!.length.clamp(0, 2)).toUpperCase() ?? '?';
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: (diameter * 0.35).clamp(10.0, 24.0),
          fontWeight: FontWeight.w600,
          color: fgColor,
          height: 1.0,
        ),
      ),
    );
  }
}

// ── Status indicator dot ─────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.isOnline,
    required this.size,
    required this.isDark,
  });

  final bool isOnline;
  final PetAvatarSize size;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dotDiameter = size.dotSize;
    final ringWidth = size.ringWidth;

    // Online: meadow/500 (Health green — vitality / wellness streak color).
    // Offline: ink/300 (tertiary / placeholder neutral).
    final dotColor = isOnline
        ? (isDark ? AppColors.meadow500D : AppColors.meadow500)
        : (isDark ? AppColors.ink300D : AppColors.ink300);

    final ringColor = isDark ? AppColors.surface0D : AppColors.surface0;

    return AnimatedContainer(
      duration: PetfolioThemeExtension.durationSm,
      width: dotDiameter,
      height: dotDiameter,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: ringWidth),
        // Subtle shadow so dot reads over both light and dark images
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
