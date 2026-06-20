import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TailWagLoader extends StatefulWidget {
  const TailWagLoader({
    super.key,
    this.size = 64.0,
    this.color = AppColors.tangerine,
    this.label,
  });

  final double size;
  final Color color;
  final String? label;

  @override
  State<TailWagLoader> createState() => _TailWagLoaderState();
}

class _TailWagLoaderState extends State<TailWagLoader> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label ?? 'Loading',
      liveRegion: true,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _DogPainter(
                tailAngle: Curves.easeInOutBack.transform(_ctrl.value),
                color: widget.color,
              ),
            );
          },
        ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 10),
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: widget.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
      ),
    );
  }
}

class _DogPainter extends CustomPainter {
  const _DogPainter({required this.tailAngle, required this.color});

  final double tailAngle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final unit = w / 8;

    final bodyPaint = Paint()..color = color;
    final whitePaint = Paint()..color = Colors.white;
    final darkPaint = Paint()..color = color.withAlpha(200);
    final nosePaint = Paint()..color = Colors.black87;

    // Body (slightly wider oval)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + unit * 0.3), width: unit * 4.4, height: unit * 3),
      bodyPaint,
    );

    // Head
    canvas.drawCircle(Offset(cx + unit * 1.8, cy - unit * 0.3), unit * 1.7, bodyPaint);

    // Ears (floppy)
    final earPaint = Paint()..color = color.withAlpha(220);
    final leftEarPath = Path()
      ..moveTo(cx + unit * 0.6, cy - unit * 1.2)
      ..cubicTo(
        cx + unit * 0.2, cy - unit * 2.8,
        cx + unit * 1.0, cy - unit * 3.2,
        cx + unit * 1.4, cy - unit * 1.8,
      )
      ..close();
    canvas.drawPath(leftEarPath, earPaint);

    final rightEarPath = Path()
      ..moveTo(cx + unit * 3.0, cy - unit * 1.2)
      ..cubicTo(
        cx + unit * 3.6, cy - unit * 2.8,
        cx + unit * 2.8, cy - unit * 3.2,
        cx + unit * 2.4, cy - unit * 1.8,
      )
      ..close();
    canvas.drawPath(rightEarPath, earPaint);

    // Eye
    canvas.drawCircle(Offset(cx + unit * 2.6, cy - unit * 0.5), unit * 0.28, nosePaint);
    canvas.drawCircle(Offset(cx + unit * 2.65, cy - unit * 0.55), unit * 0.09, whitePaint);

    // Nose
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + unit * 3.2, cy + unit * 0.1), width: unit * 0.6, height: unit * 0.42),
      nosePaint,
    );

    // Legs (4 simple rounded rects)
    for (final xOff in [-unit * 1.2, -unit * 0.2, unit * 0.7, unit * 1.7]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + xOff, cy + unit * 2.0), width: unit * 0.75, height: unit * 1.5),
          Radius.circular(unit * 0.35),
        ),
        bodyPaint,
      );
    }

    // Tail — wagging
    final tailBaseX = cx - unit * 2.0;
    final tailBaseY = cy - unit * 0.2;
    final wagMax = math.pi / 5;
    final angle = -math.pi / 2 - wagMax + wagMax * 2 * tailAngle;

    canvas.save();
    canvas.translate(tailBaseX, tailBaseY);
    canvas.rotate(angle);

    final tailPath = Path()
      ..moveTo(-unit * 0.3, 0)
      ..cubicTo(-unit * 0.5, -unit * 1.2, unit * 0.3, -unit * 2.2, unit * 0.15, -unit * 2.8)
      ..cubicTo(unit * 0.0, -unit * 2.2, -unit * 0.7, -unit * 1.4, -unit * 0.3, 0)
      ..close();
    canvas.drawPath(tailPath, bodyPaint);

    canvas.restore();

    // Belly lighter patch
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + unit * 0.3, cy + unit * 0.8), width: unit * 2.4, height: unit * 1.4),
      Paint()..color = color.withAlpha(60),
    );

    // Spots (two small circles on body for personality)
    canvas.drawCircle(Offset(cx - unit * 0.4, cy + unit * 0.0), unit * 0.3, darkPaint);
    canvas.drawCircle(Offset(cx + unit * 0.8, cy - unit * 0.5), unit * 0.2, darkPaint);
  }

  @override
  bool shouldRepaint(_DogPainter old) => old.tailAngle != tailAngle || old.color != color;
}
