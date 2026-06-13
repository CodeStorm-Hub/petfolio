import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kPushDuration = Duration(milliseconds: 320);
const _kModalDuration = Duration(milliseconds: 360);

CustomTransitionPage<T> pushPage<T>({
  required LocalKey key,
  required Widget child,
}) =>
    CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: _kPushDuration,
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubicEmphasized,
          reverseCurve: Curves.easeInCubic,
        ));
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.5, curve: Curves.easeIn),
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

CustomTransitionPage<T> modalPage<T>({
  required LocalKey key,
  required Widget child,
}) =>
    CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: _kModalDuration,
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        final fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
