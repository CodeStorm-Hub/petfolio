import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A card with a glassmorphism effect, matching §4.1 of the PetFolio spec.
///
/// **When glass is rendered:**
/// Backdrop blur + fill + specular highlight + top-inset border.
///
/// **Automatic solid fallback** fires when:
/// - [forceOpaque] is `true`.
/// - `MediaQuery.disableAnimations` is active (Reduce Motion / Reduce
///   Transparency on iOS / Remove Animations on Android).
/// - `MediaQuery.highContrast` is active.
///
/// Per spec §4.1: glass must only be placed over a photographic image,
/// a solid neutral/blue surface, or a scrim of ≥ 35 % opacity.
/// Pass [forceOpaque] = `true` when none of those are guaranteed.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = PetfolioThemeExtension.radiusXl,
    this.padding = const EdgeInsets.all(16),
    this.forceOpaque = false,
    this.width,
    this.height,
  });

  final Widget child;

  /// Corner radius. Use [PetfolioThemeExtension.radiusXl] (20) for floating
  /// cards; [PetfolioThemeExtension.radius2xl] (28) for bottom-sheet glass.
  final double borderRadius;

  /// Inner padding around [child].
  final EdgeInsetsGeometry padding;

  /// Force the solid fallback regardless of accessibility settings.
  final bool forceOpaque;

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final useGlass = !forceOpaque && !mq.disableAnimations && !mq.highContrast;

    return useGlass
        ? _GlassBody(
            borderRadius: borderRadius,
            padding: padding,
            width: width,
            height: height,
            child: child,
          )
        : _SolidFallback(
            borderRadius: borderRadius,
            padding: padding,
            width: width,
            height: height,
            child: child,
          );
  }
}

// ── Glass body ────────────────────────────────────────────────────────────────

class _GlassBody extends StatelessWidget {
  const _GlassBody({
    required this.child,
    required this.borderRadius,
    required this.padding,
    this.width,
    this.height,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final radius = BorderRadius.circular(borderRadius);

    final fillColor = isDark ? AppColors.glassFillD : AppColors.glassFillL;
    final topBorder = isDark ? AppColors.glassTopD : AppColors.glassTopL;
    final rimBorder = isDark ? AppColors.glassRimD : AppColors.glassRimL;
    final shineColor = isDark ? AppColors.glassShineD : AppColors.glassShineL;
    final sigma = pt.glassBlurSigma;

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: CustomPaint(
            foregroundPainter: _GlassBorderPainter(
              borderRadius: borderRadius,
              topColor: topBorder,
              rimColor: rimBorder,
              strokeWidth: 1.0,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: radius,
                boxShadow: pt.shadowGlass,
              ),
              child: Stack(
                children: [
                  // Specular highlight — top 30 % linear gradient
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: 0.30,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [shineColor, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(padding: padding, child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glass Border Painter ─────────────────────────────────────────────────────

class _GlassBorderPainter extends CustomPainter {
  const _GlassBorderPainter({
    required this.borderRadius,
    required this.topColor,
    required this.rimColor,
    required this.strokeWidth,
  });

  final double borderRadius;
  final Color topColor;
  final Color rimColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    // Deflate by half the stroke width to ensure the border stays completely inside the widget boundary
    final adjustedRect = rect.deflate(strokeWidth / 2);
    final rrect = RRect.fromRectAndRadius(
      adjustedRect,
      Radius.circular(borderRadius - strokeWidth / 2),
    );

    // Apply a smooth gradient from top border highlight to outer rim border
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, rimColor, rimColor],
      stops: const [0.0, 0.15, 1.0],
    ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.topColor != topColor ||
        oldDelegate.rimColor != rimColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

// ── Solid fallback (§4.2 solid card) ─────────────────────────────────────────

class _SolidFallback extends StatelessWidget {
  const _SolidFallback({
    required this.child,
    required this.borderRadius,
    required this.padding,
    this.width,
    this.height,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface0D : AppColors.surface0,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? AppColors.lineD : AppColors.line,
        ),
        // Halved shadow per spec "solid fallback, same shadow halved"
        boxShadow: pt.shadowE1,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
