import 'package:flutter/material.dart';

import '../../data/models/product.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProductGlyph — SVG-path glyph rendered in white on the product tile gradient
// ─────────────────────────────────────────────────────────────────────────────

class ProductGlyph extends StatelessWidget {
  const ProductGlyph({super.key, required this.glyphType, this.size = 48});

  final ProductGlyphType glyphType;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GlyphPainter(glyphType),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.type);

  final ProductGlyphType type;

  static final _paint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final _fillPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    // Scale from 40×40 viewBox to actual size
    final s = size.width / 40;
    canvas.scale(s, s);

    switch (type) {
      case ProductGlyphType.bag:
        _drawBag(canvas);
      case ProductGlyphType.ball:
        _drawBall(canvas);
      case ProductGlyphType.leash:
        _drawLeash(canvas);
      case ProductGlyphType.bone:
        _drawBone(canvas);
      case ProductGlyphType.pill:
        _drawPill(canvas);
      case ProductGlyphType.brush:
        _drawBrush(canvas);
      case ProductGlyphType.bowl:
        _drawBowl(canvas);
      case ProductGlyphType.rope:
        _drawRope(canvas);
      case ProductGlyphType.unknown:
        _drawUnknown(canvas);
    }
  }

  void _drawBag(Canvas canvas) {
    final path = Path()
      ..moveTo(10, 12)
      ..lineTo(30, 12)
      ..lineTo(28, 34)
      ..quadraticBezierTo(28, 36, 26, 36.5)
      ..lineTo(14, 36.5)
      ..quadraticBezierTo(12, 36, 12, 34)
      ..close()
      ..moveTo(14, 12)
      ..lineTo(14, 8)
      ..quadraticBezierTo(14, 2, 20, 2)
      ..quadraticBezierTo(26, 2, 26, 8)
      ..lineTo(26, 12);
    canvas.drawPath(path, _paint);
    canvas.drawCircle(const Offset(20, 22), 3, _fillPaint);
  }

  void _drawBall(Canvas canvas) {
    canvas.drawCircle(const Offset(20, 20), 13, _paint);
    final seams = Path()
      ..moveTo(7, 20)
      ..cubicTo(12, 20, 22, 7, 33, 7)
      ..moveTo(7, 20)
      ..cubicTo(12, 20, 22, 33, 33, 33)
      ..moveTo(20, 7)
      ..lineTo(20, 33);
    canvas.drawPath(seams, _paint);
  }

  void _drawLeash(Canvas canvas) {
    final path = Path()
      ..moveTo(10, 8)
      ..cubicTo(14, 8, 14, 14, 20, 14)
      ..cubicTo(26, 14, 26, 8, 30, 8)
      ..cubicTo(30, 20, 24, 24, 20, 30)
      ..lineTo(16, 34)
      ..moveTo(22, 14)
      ..lineTo(28, 14)
      ..lineTo(28, 17)
      ..arcToPoint(const Offset(22, 17), radius: Radius.circular(3))
      ..close();
    canvas.drawPath(path, _paint);
  }

  void _drawBone(Canvas canvas) {
    final path = Path()
      ..moveTo(8, 14)
      ..arcToPoint(const Offset(15, 17), radius: Radius.circular(4))
      ..lineTo(31, 27)
      ..arcToPoint(const Offset(32, 31), radius: Radius.circular(4))
      ..arcToPoint(const Offset(29, 32), radius: Radius.circular(2))
      ..lineTo(13, 22)
      ..arcToPoint(const Offset(8, 19), radius: Radius.circular(4))
      ..close();
    canvas.drawPath(path, _paint);
  }

  void _drawPill(Canvas canvas) {
    // A rotated capsule split diagonally
    canvas.save();
    canvas.translate(20, 20);
    canvas.rotate(-0.436); // ~-25 degrees
    canvas.translate(-20, -20);

    final rect = RRect.fromLTRBR(6, 14, 34, 26, const Radius.circular(6));
    canvas.drawRRect(rect, _paint);
    final divider = Path()
      ..moveTo(20, 14)
      ..lineTo(20, 26);
    canvas.drawPath(divider, _paint);
    canvas.restore();
  }

  void _drawBrush(Canvas canvas) {
    final rect = RRect.fromLTRBR(10, 8, 30, 22, const Radius.circular(3));
    canvas.drawRRect(rect, _paint);
    // Bristle lines
    for (final x in [14.0, 18.0, 22.0, 26.0, 30.0]) {
      canvas.drawLine(Offset(x, 22), Offset(x, 22 + (30 - x)), _paint);
    }
  }

  void _drawBowl(Canvas canvas) {
    final body = Path()
      ..moveTo(6, 18)
      ..lineTo(34, 18)
      ..lineTo(31, 30)
      ..quadraticBezierTo(30, 32.5, 27, 32.5)
      ..lineTo(13, 32.5)
      ..quadraticBezierTo(10, 32.5, 9, 30)
      ..close();
    canvas.drawPath(body, _paint);
    final rim = Path()
      ..moveTo(6, 18)
      ..cubicTo(6, 15, 12, 13, 20, 13)
      ..cubicTo(28, 13, 34, 15, 34, 18);
    canvas.drawPath(rim, _paint);
  }

  void _drawRope(Canvas canvas) {
    void waveRow(double y) {
      final path = Path()..moveTo(6, y);
      path.cubicTo(11, y - 3, 11, y + 3, 16, y);
      path.cubicTo(21, y - 3, 21, y + 3, 26, y);
      path.cubicTo(31, y - 3, 31, y + 3, 36, y);
      canvas.drawPath(path, _paint);
    }

    waveRow(20);
    waveRow(24);
    // Knot ends
    for (final pt in [
      const Offset(9, 16),  const Offset(9, 28),
      const Offset(31, 16), const Offset(31, 28),
    ]) {
      canvas.drawLine(pt, Offset(pt.dx + (pt.dx < 20 ? -3 : 3), pt.dy + (pt.dy < 22 ? -4 : 4)), _paint);
    }
  }

  void _drawUnknown(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromLTRBR(8, 8, 32, 32, const Radius.circular(4)),
      _paint,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.type != type;
}
