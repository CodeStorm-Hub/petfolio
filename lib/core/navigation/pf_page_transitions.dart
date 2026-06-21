import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// M3 Expressive shared-axis (horizontal) push transition — the default for
/// "drilling in" navigation (list → detail). Replaces GoRouter's default
/// platform transition so forward/back navigation reads consistently across
/// Android and iOS.
CustomTransitionPage<T> pfSharedAxisPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: PetfolioThemeExtension.durationLg,
    reverseTransitionDuration: PetfolioThemeExtension.durationMd,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final enter = CurvedAnimation(parent: animation, curve: PetfolioThemeExtension.curveEnter);
      final exit = CurvedAnimation(parent: secondaryAnimation, curve: PetfolioThemeExtension.curveExit);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(enter),
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.04, 0)).animate(exit),
          child: FadeTransition(
            opacity: enter,
            child: FadeTransition(
              opacity: Tween<double>(begin: 1, end: 0).animate(exit),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// M3 Expressive fade-through transition — for modal-like or unrelated-content
/// swaps (e.g. opening a standalone tool, a full-screen takeover) where a
/// lateral slide would imply a spatial relationship that doesn't exist.
CustomTransitionPage<T> pfFadeThroughPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: PetfolioThemeExtension.durationLg,
    reverseTransitionDuration: PetfolioThemeExtension.durationMd,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      );
      final scaleIn = CurvedAnimation(parent: animation, curve: PetfolioThemeExtension.curveEnter);
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(fadeOut),
        child: FadeTransition(
          opacity: fadeIn,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(scaleIn),
            child: child,
          ),
        ),
      );
    },
  );
}
