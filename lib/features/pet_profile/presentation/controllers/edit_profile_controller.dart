import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petfolio/core/errors/app_exception.dart';
import 'package:petfolio/features/matching/data/repositories/matching_repository.dart';

import 'package:petfolio/core/domain/models/pet.dart';
import 'package:petfolio/core/domain/models/pet_gender.dart';
import 'package:petfolio/core/domain/controllers/pet_list_controller.dart';

class EditProfileState {
  const EditProfileState({
    this.isSubmitting = false,
    this.errorMessage,
    this.newImage,
    this.isSyncingLocation = false,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final XFile? newImage;
  final bool isSyncingLocation;

  EditProfileState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    XFile? newImage,
    bool? isSyncingLocation,
  }) {
    return EditProfileState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      newImage: newImage ?? this.newImage,
      isSyncingLocation: isSyncingLocation ?? this.isSyncingLocation,
    );
  }
}

class EditProfileController extends Notifier<EditProfileState> {
  @override
  EditProfileState build() => const EditProfileState();

  void setImage(XFile file) {
    state = state.copyWith(newImage: file, clearError: true);
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

      if (state.newImage != null) {
        final repo = ref.read(petRepositoryProvider);
        final bytes = await state.newImage!.readAsBytes();
        avatarUrl = await repo.uploadAvatar(bytes, originalPet.id);
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
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update profile. Please try again.',
      );
      return false;
    }

    // Location sync is best-effort: a failure must not undo a successful save.
    if (syncLocationIfDiscoverable && isDiscoverable) {
      try {
        await ref
            .read(matchingRepositoryProvider)
            .syncActorLocationFromDevice(originalPet.id);
      } on AppException catch (e) {
        state = state.copyWith(isSubmitting: false, errorMessage: e.message);
        return true; // profile saved — surface location error as non-fatal banner
      } catch (_) {
        // silent — GPS failure must not block profile save confirmation
      }
    }

    state = state.copyWith(isSubmitting: false);
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
