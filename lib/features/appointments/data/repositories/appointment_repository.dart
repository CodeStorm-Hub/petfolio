import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (_) => AppointmentRepository(Supabase.instance.client),
);

class AppointmentRepository {
  const AppointmentRepository(this._client);

  final SupabaseClient _client;

  Future<List<Appointment>> fetchForPet(String petId) async {
    final rows = await _client
        .from('appointments')
        .select()
        .eq('pet_id', petId)
        .order('scheduled_at', ascending: true);
    return (rows as List)
        .map((r) => Appointment.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment> create(Appointment appointment) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw StateError('Must be signed in to create an appointment');
    }
    final row = await _client
        .from('appointments')
        .insert(appointment.toInsertJson(ownerId: ownerId))
        .select()
        .single();
    return Appointment.fromJson(Map<String, dynamic>.from(row as Map));
  }

  Future<void> toggleComplete(String id, {required bool completed}) async {
    await _client.from('appointments').update({
      'status': completed ? 'completed' : 'upcoming',
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('appointments').delete().eq('id', id);
  }
}
