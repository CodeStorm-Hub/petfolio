import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class BoneSliderWidget extends StatelessWidget {
  const BoneSliderWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.color,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PetFolioColors>() ?? PetFolioColors.light;
    final activeColor = color ?? colors.tangerine;
    
    return RepaintBoundary(
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 8,
          activeTrackColor: Colors.white,
          inactiveTrackColor: Theme.of(context).extension<PetfolioThemeExtension>()?.line2 ?? AppColors.line2,
          thumbShape: _BoneSliderThumbShape(color: activeColor),
          trackShape: _GradientSliderTrackShape(
            activeGradient: LinearGradient(colors: [activeColor, colors.poppy]),
          ),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
          overlayColor: activeColor.withValues(alpha: 0.1),
        ),
        child: Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BoneSliderThumbShape extends SliderComponentShape {
  const _BoneSliderThumbShape({required this.color});

  final Color color;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(36, 28);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-15 * math.pi / 180);

    // Draw the bone
    // viewBox is 36x28. Center is at (18, 14)
    // Offset calculation: (cx - 18, cy - 14)
    final offsets = [
      const Offset(6 - 18, 8 - 14),
      const Offset(6 - 18, 20 - 14),
      const Offset(30 - 18, 8 - 14),
      const Offset(30 - 18, 20 - 14),
    ];
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8 - 18, 9 - 14, 20, 10),
      const Radius.circular(3),
    );

    // Fill
    for (final offset in offsets) {
      canvas.drawCircle(offset, 5, fillPaint);
    }
    canvas.drawRRect(rect, fillPaint);

    // Stroke
    for (final offset in offsets) {
      canvas.drawCircle(offset, 5, strokePaint);
    }
    canvas.drawRRect(rect, strokePaint);

    canvas.restore();
  }
}

class _GradientSliderTrackShape extends SliderTrackShape {
  const _GradientSliderTrackShape({required this.activeGradient});

  final LinearGradient activeGradient;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 8.0;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Radius trackRadius = Radius.circular(trackRect.height / 2);

    final ColorTween inactiveTrackColorTween = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    );
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation)!;

    // Inactive track (background)
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, trackRadius),
      inactivePaint,
    );

    // Active track (gradient)
    if (thumbCenter.dx > trackRect.left) {
      final Paint activePaint = Paint()
        ..shader = activeGradient.createShader(trackRect);
      
      final Rect activeTrackRect = Rect.fromLTRB(
        trackRect.left,
        trackRect.top,
        thumbCenter.dx,
        trackRect.bottom,
      );
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(activeTrackRect, trackRadius),
        activePaint,
      );
    }
  }
}
