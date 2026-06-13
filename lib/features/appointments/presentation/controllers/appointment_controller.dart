import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/appointment.dart';
import '../../data/repositories/appointment_repository.dart';

final appointmentControllerProvider =
    AsyncNotifierProvider<AppointmentController, List<Appointment>>(
  AppointmentController.new,
);

class AppointmentController extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() {
    final petId = ref.watch(activePetIdProvider) ?? '';
    if (petId.isEmpty) return Future.value([]);
    return ref.read(appointmentRepositoryProvider).fetchForPet(petId);
  }

  Future<void> add(Appointment appointment) async {
    final repo = ref.read(appointmentRepositoryProvider);
    final created = await repo.create(appointment);
    final current = state.value ?? [];
    state = AsyncData([...current, created]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)));
  }

  Future<void> toggleComplete(String id) async {
    final current = state.value ?? [];
    final index = current.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final item = current[index];
    final updated = item.copyWith(isCompleted: !item.isCompleted);
    final next = List<Appointment>.from(current)..[index] = updated;
    state = AsyncData(next);
    await ref
        .read(appointmentRepositoryProvider)
        .toggleComplete(id, completed: updated.isCompleted);
  }

  Future<void> remove(String id) async {
    await ref.read(appointmentRepositoryProvider).delete(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((a) => a.id != id).toList());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tabbed Appointments Notifiers
// ─────────────────────────────────────────────────────────────────────────────

final upcomingAppointmentsProvider =
    AsyncNotifierProvider<UpcomingAppointmentsNotifier, List<Appointment>>(
  UpcomingAppointmentsNotifier.new,
);

class UpcomingAppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];
    return ref.read(appointmentRepositoryProvider).fetchAppointments(userId, past: false);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];
      return ref.read(appointmentRepositoryProvider).fetchAppointments(userId, past: false);
    });
  }
}

final pastAppointmentsProvider =
    AsyncNotifierProvider<PastAppointmentsNotifier, List<Appointment>>(
  PastAppointmentsNotifier.new,
);

class PastAppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];
    return ref.read(appointmentRepositoryProvider).fetchAppointments(userId, past: true);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return [];
      return ref.read(appointmentRepositoryProvider).fetchAppointments(userId, past: true);
    });
  }
}
