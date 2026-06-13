import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/transitions.dart';
import 'presentation/screens/admin_screen.dart';

List<RouteBase> adminRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/admin',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: const AdminScreen(),
    ),
  ),
];
