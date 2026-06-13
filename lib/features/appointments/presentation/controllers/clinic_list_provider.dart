import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vet_clinic.dart';
import '../../data/models/vet_service.dart';
import '../../data/repositories/vet_repository.dart';

/// All active clinics — used by VetClinicsScreen.
final clinicListProvider = FutureProvider<List<VetClinic>>((ref) {
  return ref.read(vetRepositoryProvider).fetchClinics();
});

/// Single clinic by ID — used by ClinicDetailsScreen header.
final clinicDetailProvider =
    FutureProvider.family<VetClinic, String>((ref, clinicId) {
  return ref.read(vetRepositoryProvider).fetchClinic(clinicId);
});

/// Services for a clinic — used by ClinicDetailsScreen service list.
final clinicServicesProvider =
    FutureProvider.family<List<VetService>, String>((ref, clinicId) {
  return ref.read(vetRepositoryProvider).fetchServicesForClinic(clinicId);
});
