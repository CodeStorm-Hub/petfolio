import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'presentation/screens/medications_screen.dart';
import 'presentation/screens/symptom_checker_screen.dart';

List<RouteBase> careRoutes(GlobalKey<NavigatorState> rootKey) => [
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/care/medications',
        builder: (context, state) => const MedicationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/care/symptoms',
        builder: (context, state) => const SymptomCheckerScreen(),
      ),
    ];
