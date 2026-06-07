import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/controllers/admin_auth_controller.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'navigator_keys.dart';
import 'route_overlay_dismissal.dart';

class RouterNotifier extends ChangeNotifier {
  String? _lastDismissedLocation;

  RouterNotifier(this._ref) {
    _ref.listen<bool>(isLoggedInProvider, (previous, next) {
      if (previous != next) {
        _ref.invalidate(petListProvider);
        _ref.invalidate(isAdminProvider);
      }
      notifyListeners();
    });
    _ref.listen(petListProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = _ref.read(isLoggedInProvider);
    final loc = state.matchedLocation;
    final path = state.uri.path;

    if (_lastDismissedLocation != loc) {
      _lastDismissedLocation = loc;
      dismissRootOverlayRoutes(rootNavigatorKey);
    }

    if (path == '/' || path.isEmpty) {
      return isLoggedIn ? '/home' : '/login';
    }

    if (loc == '/pets') return '/home';
    if (loc == '/shop') return '/marketplace';

    if (!isLoggedIn) {
      return (loc == '/login' || loc == '/register') ? null : '/login';
    }

    if (loc == '/login' || loc == '/register') return '/home';

    final pets = _ref.read(petListProvider).value;
    if (pets != null && pets.isEmpty && loc != '/onboarding') {
      return '/onboarding';
    }

    if (loc == '/onboarding' && pets != null && pets.isNotEmpty) {
      final mode = state.uri.queryParameters['mode'];
      if (mode != 'add') return '/care';
    }

    if (loc.startsWith('/admin')) {
      final isAdmin = _ref.read(isAdminProvider);
      if (!isAdmin) return '/home';
    }

    return null;
  }
}
