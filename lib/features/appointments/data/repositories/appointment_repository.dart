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
    try {
      final rows = await _client
          .from('appointments')
          .select()
          .eq('pet_id', petId)
          .order('scheduled_at', ascending: true);
      return (rows as List)
          .map((r) => Appointment.fromJson(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch appointments for pet: ${e.message}');
    }
  }

  Future<List<Appointment>> fetchAppointments(String userId, {bool past = false}) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final PostgrestTransformBuilder<PostgrestList> query;

      if (past) {
        query = _client
            .from('appointments')
            .select()
            .eq('owner_id', userId)
            .lt('scheduled_at', now)
            .order('scheduled_at', ascending: false);
      } else {
        query = _client
            .from('appointments')
            .select()
            .eq('owner_id', userId)
            .gte('scheduled_at', now)
            .order('scheduled_at', ascending: true);
      }

      final rows = await query;
      return (rows as List)
          .map((r) => Appointment.fromJson(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch appointments: ${e.message}');
    }
  }

  Future<Appointment> create(Appointment appointment) async {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw StateError('Must be signed in to create an appointment');
    }
    try {
      final row = await _client
          .from('appointments')
          .insert(appointment.toInsertJson(ownerId: ownerId))
          .select()
          .single();
      return Appointment.fromJson(Map<String, dynamic>.from(row as Map));
    } on PostgrestException catch (e) {
      throw Exception('Failed to create appointment: ${e.message}');
    }
  }

  Future<Appointment> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      final row = await _client
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId)
          .select()
          .single();
      return Appointment.fromJson(Map<String, dynamic>.from(row as Map));
    } on PostgrestException catch (e) {
      throw Exception('Failed to update appointment status: ${e.message}');
    }
  }

  Future<Appointment> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
    String timeSlot,
  ) async {
    try {
      final rescheduledTime = _combineDateAndTime(newDate, timeSlot);
      final row = await _client
          .from('appointments')
          .update({
            'scheduled_at': rescheduledTime.toUtc().toIso8601String(),
            'status': 'pending', // Reset to pending when rescheduled
          })
          .eq('id', appointmentId)
          .select()
          .single();
      return Appointment.fromJson(Map<String, dynamic>.from(row as Map));
    } on PostgrestException catch (e) {
      throw Exception('Failed to reschedule appointment: ${e.message}');
    }
  }

  Future<void> toggleComplete(String id, {required bool completed}) async {
    try {
      await _client.from('appointments').update({
        'status': completed ? 'completed' : 'pending',
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to toggle completion: ${e.message}');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('appointments').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete appointment: ${e.message}');
    }
  }

  DateTime _combineDateAndTime(DateTime date, String timeSlot) {
    try {
      final cleanSlot = timeSlot.trim().toUpperCase();
      final isPm = cleanSlot.contains('PM');
      final isAm = cleanSlot.contains('AM');
      final timeParts = cleanSlot.replaceAll(RegExp(r'[APM\s]'), '').split(':');
      int hour = int.parse(timeParts[0]);
      int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

      if (isPm && hour < 12) {
        hour += 12;
      } else if (isAm && hour == 12) {
        hour = 0;
      }
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return DateTime(date.year, date.month, date.day, date.hour, date.minute);
    }
  }
}
