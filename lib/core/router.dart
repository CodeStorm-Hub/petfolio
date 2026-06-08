import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activity/activity_routes.dart';
import '../features/admin/admin_routes.dart';
import '../features/appointments/appointment_routes.dart';
import '../features/auth/auth_routes.dart';
import '../features/care/care_routes.dart';
import '../features/communities/communities_routes.dart';
import '../features/marketplace/marketplace_routes.dart';
import '../features/matching/matching_routes.dart';
import '../features/pet_profile/pet_profile_routes.dart';
import '../features/social/social_routes.dart';
import 'navigation/app_shell_routes.dart';
import 'navigation/navigator_keys.dart';
import 'navigation/router_error_screen.dart';
import 'navigation/router_notifier.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    errorBuilder: (context, state) => RouterErrorScreen(
      location: state.uri.toString(),
    ),
    routes: [
      appShellRoute(),
      ...authRoutes(),
      ...petProfileRoutes(rootNavigatorKey),
      ...careRoutes(rootNavigatorKey),
      ...appointmentRoutes(rootNavigatorKey),
      ...socialRoutes(rootNavigatorKey),
      ...communitiesRoutes(rootNavigatorKey),
      ...matchingRoutes(rootNavigatorKey),
      ...marketplaceRoutes(rootNavigatorKey),
      ...adminRoutes(rootNavigatorKey),
      ...activityRoutes(rootNavigatorKey),
    ],
  );
});
