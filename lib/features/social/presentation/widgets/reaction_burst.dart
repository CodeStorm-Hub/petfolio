
import 'package:flutter/material.dart';

class ReactionBurstItem {
  ReactionBurstItem({
    required this.id,
    required this.emoji,
    required this.dx,
    required this.dy,
  });
  final String id;
  final String emoji;
  final double dx;
  final double dy;
}

class ReactionBurst extends StatefulWidget {
  const ReactionBurst({
    super.key,
    required this.items,
  });

  final List<ReactionBurstItem> items;

  @override
  State<ReactionBurst> createState() => _ReactionBurstState();
}

class _ReactionBurstState extends State<ReactionBurst> with TickerProviderStateMixin {
  final Map<String, AnimationController> _controllers = {};

  @override
  void didUpdateWidget(ReactionBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Find new items
    final oldIds = oldWidget.items.map((e) => e.id).toSet();
    for (final item in widget.items) {
      if (!oldIds.contains(item.id)) {
        final ctrl = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        );
        _controllers[item.id] = ctrl;
        ctrl.forward().then((_) {
          if (mounted) {
            setState(() {
              _controllers.remove(item.id)?.dispose();
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: widget.items.where((item) => _controllers.containsKey(item.id)).map((item) {
          final ctrl = _controllers[item.id]!;
          return AnimatedBuilder(
            animation: ctrl,
            builder: (context, child) {
              final val = ctrl.value;
              // Float up and fade out
              final moveY = -val * 150;
              final opacity = val > 0.7 ? 1.0 - ((val - 0.7) / 0.3) : 1.0;
              final scale = val < 0.2 ? (val / 0.2) : 1.0;

              return Positioned(
                left: item.dx,
                top: item.dy + moveY,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
