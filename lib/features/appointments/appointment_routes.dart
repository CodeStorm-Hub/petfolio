import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/pf_page_transitions.dart';
import 'data/models/vet_clinic.dart';
import 'presentation/screens/clinic_details_screen.dart';
import 'presentation/screens/vet_hub_screen.dart';

List<RouteBase> appointmentRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/appointments',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: const VetHubScreen(),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/appointments/:clinicId',
    pageBuilder: (context, state) {
      final clinic = state.extra as VetClinic?;
      final screen = clinic == null
          ? const VetHubScreen()
          : ClinicDetailsScreen(clinic: clinic);
      return pfSharedAxisPage(state: state, child: screen);
    },
  ),
];
