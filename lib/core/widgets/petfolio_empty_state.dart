import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_theme.dart';

class PetfolioEmptyState extends StatefulWidget {
  const PetfolioEmptyState({
    super.key,
    this.icon,
    this.lottieAsset,
    required this.title,
    this.subtitle,
    this.action,
  }) : assert(icon != null || lottieAsset != null,
            'Provide either icon or lottieAsset');

  final IconData? icon;

  /// Path to a bundled Lottie JSON file (e.g. 'assets/lottie/empty_inbox.json').
  /// When provided, a looping Lottie animation replaces the static icon.
  final String? lottieAsset;

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  State<PetfolioEmptyState> createState() => _PetfolioEmptyStateState();
}

class _PetfolioEmptyStateState extends State<PetfolioEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _scale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.subtitle != null
          ? '${widget.title}. ${widget.subtitle}'
          : widget.title,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.lottieAsset != null)
                      Lottie.asset(
                        widget.lottieAsset!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        repeat: true,
                      )
                    else
                      Icon(widget.icon!, size: 48, color: pt.ink300),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: pt.ink700,
                        ),
                      ),
                    ],
                    if (widget.action != null) ...[
                      const SizedBox(height: 20),
                      widget.action!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
