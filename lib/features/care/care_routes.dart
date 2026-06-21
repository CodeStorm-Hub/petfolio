import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/pf_page_transitions.dart';
import 'presentation/screens/medications_screen.dart';
import 'presentation/screens/symptom_checker_screen.dart';

List<RouteBase> careRoutes(GlobalKey<NavigatorState> rootKey) => [
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/care/medications',
        pageBuilder: (context, state) => pfSharedAxisPage(
          state: state,
          child: const MedicationsScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/care/symptoms',
        pageBuilder: (context, state) => pfFadeThroughPage(
          state: state,
          child: const SymptomCheckerScreen(),
        ),
      ),
    ];
