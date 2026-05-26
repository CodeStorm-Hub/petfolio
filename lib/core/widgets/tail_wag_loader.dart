import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TailWagLoader extends StatefulWidget {
  const TailWagLoader({
    super.key,
    this.size = 70.0,
    this.label,
    this.color,
  });

  final double size;
  final String? label;
  final Color? color;

  @override
  State<TailWagLoader> createState() => _TailWagLoaderState();
}

class _TailWagLoaderState extends State<TailWagLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -0.2, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<PetFolioColors>() ?? PetFolioColors.light;
    final ext = Theme.of(context).extension<PetfolioThemeExtension>() ?? PetfolioThemeExtension.light;

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: [
                // Body
                Positioned(
                  left: widget.size * 0.20,
                  top: widget.size * 0.30,
                  width: widget.size * 0.60,
                  height: widget.size * 0.55,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color ?? colors.tangerine,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.elliptical(50, 60),
                        topRight: Radius.elliptical(60, 50),
                        bottomLeft: Radius.elliptical(55, 60),
                        bottomRight: Radius.elliptical(50, 70),
                      ),
                    ),
                  ),
                ),
                // Head
                Positioned(
                  left: widget.size * 0.10,
                  top: widget.size * 0.15,
                  width: widget.size * 0.38,
                  height: widget.size * 0.42,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color ?? colors.tangerine,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Ear
                Positioned(
                  left: widget.size * 0.08,
                  top: widget.size * 0.05,
                  width: widget.size * 0.18,
                  height: widget.size * 0.24,
                  child: Transform.rotate(
                    angle: -25 * math.pi / 180,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.tangerine700,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(60),
                          topRight: Radius.circular(40),
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                    ),
                  ),
                ),
                // Eye
                Positioned(
                  left: widget.size * 0.28,
                  top: widget.size * 0.28,
                  width: 5,
                  height: 5,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Tail (wagging)
                Positioned(
                  right: widget.size * 0.08,
                  top: widget.size * 0.32,
                  width: widget.size * 0.24,
                  height: widget.size * 0.10,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animation.value,
                        alignment: Alignment.centerLeft,
                        child: child,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.color ?? colors.tangerine,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(60),
                          topRight: Radius.circular(40),
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.label != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.label!,
              style: TextStyle(
                fontSize: 13,
                color: ext.ink500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
