import 'package:flutter/material.dart';

void dismissRootOverlayRoutes(GlobalKey<NavigatorState> rootNavigatorKey) {
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return;
  navigator.popUntil((route) => route is! PopupRoute);
}
