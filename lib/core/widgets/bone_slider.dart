import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BoneSliderWidget extends StatelessWidget {
  const BoneSliderWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 100.0,
    this.color = AppColors.tangerine,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final Color color;

  static const double _thumbW = 44.0;
  static const double _totalH = 64.0;

  double get _pct => ((value - min) / (max - min)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final trackW = w - _thumbW;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) {
            final box = context.findRenderObject() as RenderBox;
            final lx = box.globalToLocal(d.globalPosition).dx;
            final raw = ((lx - _thumbW / 2) / trackW).clamp(0.0, 1.0);
            onChanged(min + raw * (max - min));
          },
          onTapDown: (d) {
            final box = context.findRenderObject() as RenderBox;
            final lx = box.globalToLocal(d.globalPosition).dx;
            final raw = ((lx - _thumbW / 2) / trackW).clamp(0.0, 1.0);
            onChanged(min + raw * (max - min));
          },
          child: SizedBox(
            height: _totalH,
            width: w,
            child: CustomPaint(
              painter: _BoneSliderPainter(pct: _pct, color: color),
            ),
          ),
        );
      },
    );
  }
}

class _BoneSliderPainter extends CustomPainter {
  const _BoneSliderPainter({required this.pct, required this.color});

  final double pct;
  final Color color;

  static const _thumbW = 44.0;
  static const _trackH = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cy = size.height / 2;
    final tl = _thumbW / 2;
    final tr = w - _thumbW / 2;
    final tw = tr - tl;
    final thumbX = tl + tw * pct;

    // Inactive track
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tl, cy - _trackH / 2, tw, _trackH),
        const Radius.circular(999),
      ),
      Paint()..color = color.withAlpha(35),
    );

    // Active track with gradient
    if (pct > 0.002) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(tl, cy - _trackH / 2, tw * pct, _trackH),
          const Radius.circular(999),
        ),
        Paint()
          ..shader = LinearGradient(
            colors: [color, AppColors.poppy],
          ).createShader(Rect.fromLTWH(tl, cy - _trackH / 2, tw, _trackH)),
      );
    }

    // Thumb shadow
    canvas.drawCircle(
      Offset(thumbX, cy),
      _thumbW / 2,
      Paint()
        ..color = color.withAlpha(55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Bone thumb
    final bw = _thumbW;
    final bh = 28.0;
    final r = bh / 2;
    final knobR = r * 0.7;
    final hw = bw / 2 - knobR * 0.5;
    final hh = r * 0.4;

    final bonePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(thumbX, cy), width: hw * 2, height: hh * 2),
        Radius.circular(hh),
      ));
    for (final o in [
      Offset(thumbX - hw, cy - hh),
      Offset(thumbX - hw, cy + hh),
      Offset(thumbX + hw, cy - hh),
      Offset(thumbX + hw, cy + hh),
    ]) {
      bonePath.addOval(Rect.fromCircle(center: o, radius: knobR));
    }

    canvas.drawPath(bonePath, Paint()..color = Colors.white);
    canvas.drawPath(
      bonePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_BoneSliderPainter old) => old.pct != pct || old.color != color;
}
