import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/appointments_screen.dart';

List<RouteBase> appointmentRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/care/appointments',
    builder: (context, state) => const AppointmentsScreen(),
  ),
];
