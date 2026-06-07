import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/medical_vault_screen.dart';
import 'presentation/screens/nutrition_screen.dart';

List<RouteBase> careRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/care/nutrition',
    builder: (context, state) => const NutritionScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/care/medical-vault',
    builder: (context, state) => const MedicalVaultScreen(),
  ),
];
