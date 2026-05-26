import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum ReactionKind { paw, heart, treat, star }

class ReactionItem {
  final String id;
  final double x;
  final double y;
  final ReactionKind? kind;

  const ReactionItem({
    required this.id,
    required this.x,
    required this.y,
    this.kind,
  });
}

class ReactionBurst extends StatelessWidget {
  const ReactionBurst({
    super.key,
    required this.items,
    this.defaultKind = ReactionKind.paw,
  });

  final List<ReactionItem> items;
  final ReactionKind defaultKind;

  String _getGlyph(ReactionKind kind) {
    switch (kind) {
      case ReactionKind.heart:
        return '❤️';
      case ReactionKind.treat:
        return '🦴';
      case ReactionKind.star:
        return '⭐';
      case ReactionKind.paw:
        return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Use a fixed seed based on items count or something if deterministic builds are needed,
    // but random is fine for visual bursts.
    final math.Random random = math.Random();

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: items.map((it) {
          final dx = (random.nextDouble() - 0.5) * 60.0;
          
          // flutter_animate .rotate expects turns (0.0 to 1.0 = 0 to 360 degrees).
          // We want between -30deg and +30deg.
          // 30 / 360 = 0.0833 turns
          final rotTurns = (random.nextDouble() - 0.5) * (60.0 / 360.0);
          
          final delayMs = random.nextDouble() * 80.0;
          final kind = it.kind ?? defaultKind;
          final glyph = _getGlyph(kind);

          return Positioned(
            left: it.x - 14,
            top: it.y - 14,
            child: Text(
              glyph,
              style: const TextStyle(fontSize: 26, height: 1),
            )
                .animate(
                  delay: delayMs.milliseconds,
                  // We don't remove items here as this is declarative.
                  // The parent should eventually remove the item from the list.
                )
                .fadeIn(
                  duration: 200.milliseconds,
                  curve: Curves.easeOut,
                )
                .moveY(
                  begin: 0,
                  end: -60,
                  duration: 900.milliseconds,
                  curve: const Cubic(0.2, 0.8, 0.2, 1),
                )
                .moveX(
                  begin: 0,
                  end: dx,
                  duration: 900.milliseconds,
                  curve: const Cubic(0.2, 0.8, 0.2, 1),
                )
                .rotate(
                  begin: 0,
                  end: rotTurns,
                  duration: 900.milliseconds,
                  curve: Curves.easeOut,
                )
                .fadeOut(
                  delay: 700.milliseconds,
                  duration: 200.milliseconds,
                ),
          );
        }).toList(),
      ),
    );
  }
}
