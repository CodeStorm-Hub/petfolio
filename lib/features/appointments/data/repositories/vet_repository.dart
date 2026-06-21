import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';
import '../models/vet_clinic.dart';
import '../models/vet_service.dart';

final vetRepositoryProvider = Provider<VetRepository>(
  (_) => VetRepository(Supabase.instance.client),
);

class VetRepository {
  const VetRepository(this._client);

  final SupabaseClient _client;

  Future<List<VetClinic>> fetchClinics() async {
    final rows = await _client
        .from('vet_clinics')
        .select()
        .eq('is_active', true)
        .order('name');
    return (rows as List)
        .map((r) => VetClinic.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<VetClinic> fetchClinic(String clinicId) async {
    final row = await _client
        .from('vet_clinics')
        .select()
        .eq('id', clinicId)
        .single();
    return VetClinic.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<List<VetService>> fetchServicesForClinic(String clinicId) async {
    final rows = await _client
        .from('vet_services')
        .select()
        .eq('clinic_id', clinicId)
        .order('name');
    return (rows as List)
        .map((r) => VetService.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<VetService> fetchService(String serviceId) async {
    final row = await _client
        .from('vet_services')
        .select()
        .eq('id', serviceId)
        .single();
    return VetService.fromJson(Map<String, dynamic>.from(row as Map));
  }

  /// Generates available time slots for [date] at a clinic offering [service].
  /// Slots run 09:00–18:00 in steps of [service.durationMinutes].
  /// Already-booked slots for [clinicId] on that day are excluded.
  Future<List<DateTime>> fetchAvailableSlots({
    required String clinicId,
    required VetService service,
    required DateTime date,
  }) async {
    final dayStart = DateTime(date.year, date.month, date.day, 9, 0);
    final dayEnd   = DateTime(date.year, date.month, date.day, 18, 0);

    // Fetch existing bookings for this clinic on this day.
    final startUtc = dayStart.toUtc().toIso8601String();
    final endUtc   = dayEnd.toUtc().toIso8601String();
    final booked = await _client
        .from('appointments')
        .select('scheduled_at')
        .eq('clinic_id', clinicId)
        .eq('service_id', service.id)
        .gte('scheduled_at', startUtc)
        .lte('scheduled_at', endUtc)
        .neq('status', 'cancelled');

    final bookedTimes = (booked as List)
        .map((r) => DateTime.parse(r['scheduled_at'] as String).toLocal())
        .toSet();

    final slots = <DateTime>[];
    var cursor = dayStart;
    while (cursor.isBefore(dayEnd)) {
      if (!bookedTimes.any((b) =>
          b.hour == cursor.hour && b.minute == cursor.minute)) {
        slots.add(cursor);
      }
      cursor = cursor.add(Duration(minutes: service.durationMinutes));
    }
    return slots;
  }

  /// Books a vet appointment and returns the persisted [Appointment].
  Future<Appointment> bookAppointment({
    required String petId,
    required VetClinic clinic,
    required VetService service,
    required DateTime scheduledAt,
    String? notes,
    String? urgency,
    String? reason,
    String? mediaUrl,
  }) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) throw StateError('Must be signed in to book');

    final payload = {
      'pet_id':       petId,
      'owner_id':     ownerId,
      'title':        service.name,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'status':       'pending',
      'vet_name':     null,
      'location':     clinic.name,
      'clinic_id':    clinic.id,
      'service_id':   service.id,
      'urgency':      urgency,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (mediaUrl != null && mediaUrl.isNotEmpty) 'media_url': mediaUrl,
    };

    final row = await _client
        .from('appointments')
        .insert(payload)
        .select()
        .single();
    return Appointment.fromJson(Map<String, dynamic>.from(row as Map));
  }
}
