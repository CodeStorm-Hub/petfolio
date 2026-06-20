import 'package:flutter/material.dart';

import '../theme/theme.dart';


// ─── WaveHeader size tokens ───────────────────────────────────────────────────

enum WaveHeaderSize {
  compact(80),
  regular(140),
  hero(220);

  const WaveHeaderSize(this.dp);
  final double dp;
}

// ─── WaveHeader widget ────────────────────────────────────────────────────────

class WaveHeader extends StatelessWidget {
  const WaveHeader({
    super.key,
    required this.color,
    required this.child,
    this.size = WaveHeaderSize.regular,
    this.height,
  });

  final Color color;
  final Widget child;
  final WaveHeaderSize size;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ?? size.dp;

    return Container(
      color: color,
      height: resolvedHeight,
      width: double.infinity,
      child: child,
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
