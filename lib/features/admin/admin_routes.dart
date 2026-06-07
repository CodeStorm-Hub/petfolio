import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/admin_screen.dart';

List<RouteBase> adminRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/admin',
    builder: (context, state) => const AdminScreen(),
  ),
];
