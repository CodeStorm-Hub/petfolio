import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PawToggle extends StatefulWidget {
  const PawToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.tangerine,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  State<PawToggle> createState() => _PawToggleState();
}

class _PawToggleState extends State<PawToggle> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _scale;

  static const _w = 56.0;
  static const _h = 32.0;
  static const _thumbD = 26.0;
  static const _pad = 3.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: widget.value ? 1.0 : 0.0,
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(PawToggle old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      widget.value ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final slideX = _pad + (_w - _thumbD - _pad * 2) * _slide.value;
          final trackColor = Color.lerp(
            Colors.black.withAlpha(30),
            widget.activeColor,
            _ctrl.value,
          )!;

          return SizedBox(
            width: _w,
            height: _h,
            child: Stack(
              children: [
                // Track
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                // Thumb
                Positioned(
                  left: slideX,
                  top: _pad,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: _thumbD,
                      height: _thumbD,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '🐾',
                        style: TextStyle(fontSize: _thumbD * 0.52),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
