import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vet_clinic.dart';
import '../../data/models/vet_service.dart';
import '../../data/repositories/vet_repository.dart';
import 'appointment_controller.dart';

part 'vet_booking_controller.freezed.dart';

enum VetBookingStatus { idle, loading, success, error }

@freezed
abstract class VetBookingState with _$VetBookingState {
  const VetBookingState._();

  const factory VetBookingState({
    VetClinic? clinic,
    VetService? service,
    DateTime? selectedDate,
    DateTime? selectedSlot,
    String? petId,
    String? notes,
    @Default(VetBookingStatus.idle) VetBookingStatus status,
    String? errorMessage,
  }) = _VetBookingState;

  bool get canBook =>
      clinic != null &&
      service != null &&
      selectedSlot != null &&
      petId != null;

  bool get isLoading => status == VetBookingStatus.loading;
}

// ─────────────────────────────────────────────────────────────────────────────

class VetBookingController extends Notifier<VetBookingState> {
  @override
  VetBookingState build() => const VetBookingState();

  /// Called when the user opens ClinicDetailsScreen for a specific clinic.
  /// Resets any prior selection state.
  void initForClinic(VetClinic clinic) {
    state = VetBookingState(clinic: clinic);
  }

  void selectService(VetService service) {
    state = state.copyWith(
      service: service,
      selectedDate: null,
      selectedSlot: null,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
      selectedSlot: null,
    );
  }

  void selectSlot(DateTime slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  void selectPet(String petId) {
    state = state.copyWith(petId: petId);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes.isEmpty ? null : notes);
  }

  void resetStatus() {
    state = state.copyWith(
      status: VetBookingStatus.idle,
      errorMessage: null,
    );
  }

  Future<void> book() async {
    if (!state.canBook) return;
    state = state.copyWith(status: VetBookingStatus.loading, errorMessage: null);
    try {
      await ref.read(vetRepositoryProvider).bookAppointment(
            petId: state.petId!,
            clinic: state.clinic!,
            service: state.service!,
            scheduledAt: state.selectedSlot!,
            notes: state.notes,
          );
      // Refresh the existing appointments calendar so the new booking appears.
      ref.invalidate(appointmentControllerProvider);
      state = state.copyWith(status: VetBookingStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: VetBookingStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final vetBookingControllerProvider =
    NotifierProvider<VetBookingController, VetBookingState>(
  VetBookingController.new,
);
