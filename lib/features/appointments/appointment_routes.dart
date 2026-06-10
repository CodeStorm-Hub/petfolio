import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/models/vet_clinic.dart';
import 'presentation/screens/clinic_details_screen.dart';
import 'presentation/screens/vet_clinics_screen.dart';

List<RouteBase> appointmentRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/appointments',
    builder: (_, _) => const VetClinicsScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/appointments/:clinicId',
    builder: (context, state) {
      final clinic = state.extra as VetClinic?;
      if (clinic == null) return const VetClinicsScreen();
      return ClinicDetailsScreen(clinic: clinic);
    },
  ),
];
