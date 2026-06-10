import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/notification_service.dart';
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
    @Default('Routine') String urgency,
    String? reason,
    String? mediaUrl,
    XFile? selectedMedia,
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

  void selectUrgency(String urgency) {
    state = state.copyWith(urgency: urgency);
  }

  void selectReason(String reason) {
    state = state.copyWith(reason: reason.trim().isEmpty ? null : reason.trim());
  }

  void selectMedia(XFile? media) {
    state = state.copyWith(selectedMedia: media);
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
      String? mediaUrl = state.mediaUrl;

      // Upload selected media file to Supabase Storage if present
      if (state.selectedMedia != null) {
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id;
        if (userId == null) {
          throw StateError('Must be signed in to upload appointment media');
        }

        final bytes = await state.selectedMedia!.readAsBytes();
        final ext = state.selectedMedia!.name.split('.').last.toLowerCase();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
        final path = '$userId/$fileName';
        final mimeType = _getMimeType(ext);

        await client.storage.from('appointment-media').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );

        mediaUrl = client.storage.from('appointment-media').getPublicUrl(path);
      }

      await ref.read(vetRepositoryProvider).bookAppointment(
            petId: state.petId!,
            clinic: state.clinic!,
            service: state.service!,
            scheduledAt: state.selectedSlot!,
            notes: state.notes,
            urgency: state.urgency,
            reason: state.reason,
            mediaUrl: mediaUrl,
          );

      // Trigger immediate local "Booking Received" notification
      try {
        await NotificationService.instance.showPushNotification(
          id: DateTime.now().millisecondsSinceEpoch.abs() % 1000000,
          title: 'Booking Received 🎉',
          body: 'Your appointment for "${state.service!.name}" has been booked successfully.',
          data: {
            'type': 'appointment_reminder',
            'route': '/care/appointments',
          },
        );
      } catch (_) {
        // Silently catch local notification trigger errors if platform is unsupported
      }

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

  String _getMimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
      case 'qt':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}

final vetBookingControllerProvider =
    NotifierProvider<VetBookingController, VetBookingState>(
      VetBookingController.new,
    );
