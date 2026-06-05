import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petfolio/core/errors/app_exception.dart';
import 'package:petfolio/features/matching/data/repositories/matching_repository.dart';

import '../../data/models/pet.dart';
import '../../data/models/pet_gender.dart';
import 'pet_list_controller.dart';

class EditProfileState {
  const EditProfileState({
    this.isSubmitting = false,
    this.errorMessage,
    this.newImageBytes,
    this.newImageFileName,
    this.isSyncingLocation = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final Uint8List? newImageBytes;
  final String? newImageFileName;
  final bool isSyncingLocation;

  EditProfileState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    Uint8List? newImageBytes,
    String? newImageFileName,
    bool clearNewImage = false,
    bool? isSyncingLocation,
  }) {
    return EditProfileState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      newImageBytes: clearNewImage ? null : (newImageBytes ?? this.newImageBytes),
      newImageFileName:
          clearNewImage ? null : (newImageFileName ?? this.newImageFileName),
      isSyncingLocation: isSyncingLocation ?? this.isSyncingLocation,
    );
  }
}

class EditProfileController extends Notifier<EditProfileState> {
  @override
  EditProfileState build() => const EditProfileState();

  Future<void> setImageFromPick(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        state = state.copyWith(
          errorMessage: 'Could not read the selected photo. Try another image.',
        );
        return;
      }
      state = state.copyWith(
        newImageBytes: bytes,
        newImageFileName: file.name,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Could not read the selected photo. Try another image.',
      );
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<bool> syncMatchLocation(String petId) async {
    state = state.copyWith(isSyncingLocation: true, clearError: true);
    try {
      await ref.read(matchingRepositoryProvider).syncActorLocationFromDevice(petId);
      state = state.copyWith(isSyncingLocation: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        isSyncingLocation: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSyncingLocation: false,
        errorMessage: 'Could not update match location. Check location permissions.',
      );
      return false;
    }
  }

  Future<bool> submit({
    required Pet originalPet,
    required String name,
    required String breed,
    required String bio,
    required DateTime? dateOfBirth,
    required PetGender gender,
    required double? weightKg,
    required String? activityLevel,
    required bool isPublic,
    required bool isDiscoverable,
    bool syncLocationIfDiscoverable = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: 'Name is required.');
      return false;
    }
    if (trimmed.length > 80) {
      state = state.copyWith(errorMessage: 'Name must be 80 characters or fewer.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      var avatarUrl = originalPet.avatarUrl;

      if (state.newImageBytes != null) {
        final repo = ref.read(petRepositoryProvider);
        avatarUrl = await repo.uploadAvatar(
          state.newImageBytes!,
          originalPet.id,
          fileName: state.newImageFileName,
        );
      }

      final listNotifier = ref.read(petListProvider.notifier);
      await listNotifier.editPetProfile(
        id: originalPet.id,
        name: trimmed,
        breed: breed.trim().isEmpty ? null : breed.trim(),
        avatarUrl: avatarUrl,
        bio: bio.trim().isEmpty ? null : bio.trim(),
        dateOfBirth: dateOfBirth,
        gender: gender,
        weightKg: weightKg,
        activityLevel: activityLevel,
        isPublic: isPublic,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update profile. Please try again.',
      );
      return false;
    }

    ref.read(matchingRepositoryProvider).invalidatePetLocationCache(originalPet.id);

    if (syncLocationIfDiscoverable && isDiscoverable) {
      try {
        await ref
            .read(matchingRepositoryProvider)
            .syncActorLocationFromDevice(originalPet.id);
      } on AppException catch (e) {
        state = state.copyWith(isSubmitting: false, errorMessage: e.message);
        return true;
      } catch (_) {}
    }

    state = state.copyWith(isSubmitting: false, clearNewImage: true);
    return true;
  }
}

final editProfileControllerProvider =
    NotifierProvider<EditProfileController, EditProfileState>(
  EditProfileController.new,
);

final petMatchLocationProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, petId) {
  return ref.read(matchingRepositoryProvider).actorPetHasLocation(petId);
});
