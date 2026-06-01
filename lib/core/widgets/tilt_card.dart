import 'package:flutter/material.dart';

class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 9.0,
    this.liftScale = 1.0,
    this.depth = 1.0,
    this.showGlare = true,
    this.glareStrength = 0.5,
    this.glareRadius = 24.0, // used as border radius for the glare container
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final double maxTilt;
  final double liftScale;
  final double depth; // 0 for off, 1 for full depth
  final bool showGlare;
  final double glareStrength;
  final double glareRadius;
  final Clip clipBehavior;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _rx = 0;
  double _ry = 0;
  bool _isOn = false;
  bool _isPressed = false;
  double _px = 50.0;
  double _py = 50.0;
  
  void _onPointerMove(PointerEvent event) {
    if (widget.depth == 0) return;
    final size = context.size;
    if (size == null) return;
    
    double x = (event.localPosition.dx / size.width).clamp(0.0, 1.0);
    double y = (event.localPosition.dy / size.height).clamp(0.0, 1.0);
    
    double m = widget.maxTilt * widget.depth;
    
    setState(() {
      _isOn = true;
      _rx = (0.5 - y) * m * 2;
      _ry = (x - 0.5) * m * 2;
      _px = x * 100;
      _py = y * 100;
    });
  }
  
  void _onPointerExit(PointerEvent event) {
    setState(() {
      _isOn = false;
      _isPressed = false;
      _rx = 0;
      _ry = 0;
    });
  }
  
  void _onPointerDown(PointerEvent event) {
    setState(() {
      _isPressed = true;
    });
  }
  
  void _onPointerUp(PointerEvent event) {
    setState(() {
      _isPressed = false;
      if (!_isOn) {
        _rx = 0;
        _ry = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.depth == 0 
      ? (_isPressed ? 0.97 : 1.0)
      : (_isPressed ? 0.965 : (_isOn ? 1.012 * widget.liftScale : 1.0));
    
    final matrix = Matrix4.identity();
    if (widget.depth > 0) {
      matrix.setEntry(3, 2, 0.0015); // perspective
      matrix.rotateX(_rx * 3.14159 / 180);
      matrix.rotateY(_ry * 3.14159 / 180);
    }
    matrix.multiply(Matrix4.diagonal3Values(scale, scale, 1.0));
    
    Widget content = widget.child;
    
    if (widget.depth > 0 && widget.showGlare) {
      content = Stack(
        clipBehavior: widget.clipBehavior,
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: _isOn ? widget.glareStrength : 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.glareRadius),
                    gradient: RadialGradient(
                      center: Alignment((_px - 50) / 50, (_py - 50) / 50),
                      radius: 1.5,
                      colors: [
                        Colors.white.withAlpha(200),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Listener(
      onPointerHover: _onPointerMove,
      onPointerMove: _onPointerMove,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerExit,
      child: MouseRegion(
        onExit: _onPointerExit,
        child: AnimatedContainer(
          duration: _isOn ? const Duration(milliseconds: 80) : const Duration(milliseconds: 400),
          curve: _isOn ? Curves.easeOut : const Cubic(0.2, 0.9, 0.25, 1.0),
          transform: matrix,
          transformAlignment: FractionalOffset.center,
          child: content,
        ),
      ),
    );
  }
}
