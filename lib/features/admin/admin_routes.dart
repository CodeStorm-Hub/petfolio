import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/pf_page_transitions.dart';
import 'presentation/screens/admin_screen.dart';

List<RouteBase> adminRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/admin',
    pageBuilder: (context, state) =>
        pfFadeThroughPage(state: state, child: const AdminScreen()),
  ),
];
