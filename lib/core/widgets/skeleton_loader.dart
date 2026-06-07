import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Animated shimmer placeholder for loading content.
///
/// Matches the PetFolio surface/neutral palette and honors the
/// Reduce Motion accessibility setting:
/// - **Animations on:** sweeping shimmer gradient (1 500 ms loop).
/// - **Animations off:** static muted rectangle (instant, no flicker).
///
/// Usage:
/// ```dart
/// // Rectangular block
/// SkeletonLoader(width: 200, height: 16)
///
/// // Circle (for avatars)
/// SkeletonLoader(width: 48, height: 48, borderRadius: 999)
///
/// // Compose into a card skeleton
/// Column(children: [
///   SkeletonLoader(width: double.infinity, height: 180),
///   SizedBox(height: 12),
///   SkeletonLoader(width: 160, height: 14),
/// ])
/// ```
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = PetfolioThemeExtension.radiusMd,
  });

  /// Avatar / circular skeleton (e.g. pet avatar in feed header).
  const SkeletonLoader.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = 999;

  /// Full-width image banner skeleton (e.g. post or product card hero).
  const SkeletonLoader.imageBanner({super.key, double bannerHeight = 200})
      : width = double.infinity,
        height = bannerHeight,
        borderRadius = PetfolioThemeExtension.radiusMd;

  /// Single list-tile skeleton row (avatar + two text lines).
  /// Wrap in a `Column` / `ListView` for multi-row loading states.
  factory SkeletonLoader.listTile({Key? key}) => _SkeletonListTile(key: key);

  /// Feed post card skeleton (banner + avatar row + two text lines).
  factory SkeletonLoader.feedCard({Key? key}) => _SkeletonFeedCard(key: key);

  /// Marketplace product card skeleton (square image + title + price).
  factory SkeletonLoader.productCard({Key? key}) =>
      _SkeletonProductCard(key: key);

  final double width;
  final double height;

  /// Corner radius. Pass `999` for a fully circular skeleton.
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  void _syncAnimation() {
    if (!mounted) return;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Base color: surface/2 — the spec's inset-well surface
    final baseColor = isDark ? AppColors.surface2D : AppColors.surface2;
    // Highlight: line/200 — a subtle brighter step
    final highlightColor = isDark ? AppColors.lineD : AppColors.line;

    final radius = BorderRadius.circular(widget.borderRadius);

    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: baseColor, borderRadius: radius),
      );
    }

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_shimmer.value - 0.5).clamp(0.0, 1.0),
                _shimmer.value.clamp(0.0, 1.0),
                (_shimmer.value + 0.5).clamp(0.0, 1.0),
              ],
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Composite named skeletons (returned by factory constructors above)
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonListTile extends SkeletonLoader {
  const _SkeletonListTile({super.key})
      : super(width: 0, height: 0, borderRadius: 0);

  @override
  State<SkeletonLoader> createState() => _SkeletonListTileState();
}

class _SkeletonListTileState extends State<SkeletonLoader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SkeletonLoader.circle(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: double.infinity, height: 13),
                const SizedBox(height: 6),
                SkeletonLoader(width: 120, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonFeedCard extends SkeletonLoader {
  const _SkeletonFeedCard({super.key})
      : super(width: 0, height: 0, borderRadius: 0);

  @override
  State<SkeletonLoader> createState() => _SkeletonFeedCardState();
}

class _SkeletonFeedCardState extends State<SkeletonLoader> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonLoader.circle(size: 36),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 100, height: 12),
                  const SizedBox(height: 4),
                  SkeletonLoader(width: 64, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const SkeletonLoader.imageBanner(bannerHeight: 220),
          const SizedBox(height: 10),
          SkeletonLoader(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          SkeletonLoader(width: 180, height: 12),
        ],
      ),
    );
  }
}

class _SkeletonProductCard extends SkeletonLoader {
  const _SkeletonProductCard({super.key})
      : super(width: 0, height: 0, borderRadius: 0);

  @override
  State<SkeletonLoader> createState() => _SkeletonProductCardState();
}

class _SkeletonProductCardState extends State<SkeletonLoader> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader.imageBanner(bannerHeight: 140),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: double.infinity, height: 13),
              const SizedBox(height: 5),
              SkeletonLoader(width: 72, height: 13),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SkeletonText — convenience for paragraph-like text placeholders
// ─────────────────────────────────────────────────────────────────────────────

/// Stacks multiple [SkeletonLoader] lines to mimic a paragraph.
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.lines = 3,
    this.lineHeight = 14.0,
    this.spacing = 8.0,
    this.lastLineWidthFactor = 0.6,
  });

  final int lines;
  final double lineHeight;
  final double spacing;

  /// The last line is typically shorter. Pass 0.0–1.0 (fraction of full width).
  final double lastLineWidthFactor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < lines; i++) ...[
              SkeletonLoader(
                width: i == lines - 1
                    ? fullWidth * lastLineWidthFactor
                    : fullWidth,
                height: lineHeight,
              ),
              if (i < lines - 1) SizedBox(height: spacing),
            ],
          ],
        );
      },
    );
  }
}
