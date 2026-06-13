import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vet_service.dart';
import '../../data/repositories/vet_repository.dart';

/// Family key for [availableSlotsProvider].
/// Date equality is day-level only (year/month/day) — time component ignored.
class AvailableSlotsRequest {
  const AvailableSlotsRequest({
    required this.clinicId,
    required this.service,
    required this.date,
  });

  final String clinicId;
  final VetService service;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      other is AvailableSlotsRequest &&
      clinicId == other.clinicId &&
      service.id == other.service.id &&
      date.year == other.date.year &&
      date.month == other.date.month &&
      date.day == other.date.day;

  @override
  int get hashCode =>
      Object.hash(clinicId, service.id, date.year, date.month, date.day);
}

/// Available booking slots for a given clinic, service, and calendar day.
/// Re-fetches automatically when any of the three params change.
final availableSlotsProvider =
    FutureProvider.family<List<DateTime>, AvailableSlotsRequest>(
  (ref, req) => ref.read(vetRepositoryProvider).fetchAvailableSlots(
        clinicId: req.clinicId,
        service: req.service,
        date: req.date,
      ),
);
