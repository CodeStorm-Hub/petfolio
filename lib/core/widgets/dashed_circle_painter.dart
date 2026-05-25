import 'dart:math';
import 'package:flutter/material.dart';

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.dashLength = 5.0,
    this.dashSpace = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final radius = min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final circumference = 2 * pi * radius;
    final totalDashLength = dashLength + dashSpace;
    final dashCount = (circumference / totalDashLength).floor();
    final adjustedDashLength = dashLength;
    final adjustedDashSpace = (circumference - (dashCount * adjustedDashLength)) / dashCount;
    
    double currentAngle = 0;
    for (int i = 0; i < dashCount; i++) {
      final sweepAngle = (adjustedDashLength / circumference) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += ((adjustedDashLength + adjustedDashSpace) / circumference) * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashSpace != dashSpace;
  }
}
