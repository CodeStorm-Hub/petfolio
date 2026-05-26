import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ─── Wave clipper ─────────────────────────────────────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final W = size.width;
    double sx(double svgX) => W * (svgX / 412.0);

    path.lineTo(0, size.height - 60);
    path.moveTo(0, size.height - 20);
    path.cubicTo(sx(90), size.height - 50, sx(160), size.height + 10, sx(220), size.height - 20);
    path.cubicTo(sx(280), size.height - 45, sx(340), size.height, W, size.height - 30);
    path.lineTo(W, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}

// ─── Wave SVG painter (bottom wave transitioning into page bg) ────────────────

class WavePainter extends CustomPainter {
  const WavePainter({required this.color});
  final Color color;

  // Exact port of home.jsx wave SVG:
  // M0,40 C90,10 160,70 220,40 C280,15 340,60 412,30 L412,60 L0,60 Z
  // Painter height = 60, same as SVG viewBox height.
  // x-coords scaled to size.width (preserveAspectRatio="none").
  static const _svgW = 412.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final W = size.width;
    double sx(double svgX) => W * (svgX / _svgW);

    final path = Path();
    path.moveTo(0, 40);
    path.cubicTo(sx(90), 10, sx(160), 70, sx(220), 40);
    path.cubicTo(sx(280), 15, sx(340), 60, W, 30);
    path.lineTo(W, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter old) => old.color != color;
}

// ─── WaveHeader widget ────────────────────────────────────────────────────────

class WaveHeader extends StatelessWidget {
  const WaveHeader({
    super.key,
    required this.color,
    required this.child,
    this.waveColor,
    this.height,
    this.clipWave = true,
  });

  final Color color;
  final Widget child;
  final Color? waveColor;
  final double? height;
  final bool clipWave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor = waveColor ?? (isDark ? AppColors.creamD : AppColors.cream);

    return RepaintBoundary(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Colored header background clipped to wave shape (optional)
          if (clipWave)
            ClipPath(
              clipper: const _WaveClipper(),
              child: Container(
                color: color,
                height: height,
                child: child,
              ),
            )
          else
            Container(
              color: color,
              height: height,
              child: child,
            ),
          // Wave transition at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 60,
              child: CustomPaint(
                painter: WavePainter(color: pageColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section title with colored accent bar ────────────────────────────────────

class PfSectionTitle extends StatelessWidget {
  const PfSectionTitle({
    super.key,
    required this.title,
    this.accent,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String title;
  final Color? accent;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = accent ?? AppColors.tangerine;
    final textColor = isDark ? AppColors.ink950D : AppColors.ink950;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Container(
            width: 5,
            height: 20,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.2,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ─── PfGreetingWaveHeader ─────────────────────────────────────────────────────

class PfGreetingWaveHeader extends StatelessWidget {
  const PfGreetingWaveHeader({
    super.key,
    required this.petName,
    required this.greeting,
    required this.color,
    this.avatarUrl,
    this.emoji,
  });

  final String petName;
  final String greeting;
  final Color color;
  final String? avatarUrl;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return WaveHeader(
      color: color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(200),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  petName,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PfStreakWaveHeader ───────────────────────────────────────────────────────

class PfStreakWaveHeader extends StatelessWidget {
  const PfStreakWaveHeader({
    super.key,
    required this.streak,
    required this.color,
  });

  final int streak;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return WaveHeader(
      color: color,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HEALTH STREAK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1 * 12,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'days on track',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(Icons.local_fire_department_rounded, color: Colors.white.withAlpha(200), size: 48),
          ],
        ),
      ),
    );
  }
}
