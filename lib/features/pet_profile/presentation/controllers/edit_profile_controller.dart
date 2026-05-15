import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pet.dart';
import 'pet_list_controller.dart';

class EditProfileState {
  const EditProfileState({
    this.isSubmitting = false,
    this.errorMessage,
    this.newImage,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final File? newImage;

  EditProfileState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    File? newImage,
  }) {
    return EditProfileState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      newImage: newImage ?? this.newImage,
    );
  }
}

class EditProfileController extends AutoDisposeNotifier<EditProfileState> {
  @override
  EditProfileState build() => const EditProfileState();

  void setImage(File file) {
    state = state.copyWith(newImage: file, errorMessage: null);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  Future<bool> submit({
    required Pet originalPet,
    required String name,
    required String breed,
    required String bio,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Name cannot be empty.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      String? avatarUrl = originalPet.avatarUrl;

      // 1. Upload new image if selected
      if (state.newImage != null) {
        final repo = ref.read(petRepositoryProvider);
        final bytes = await state.newImage!.readAsBytes();
        avatarUrl = await repo.uploadAvatar(bytes, originalPet.id);
      }

      // 2. Update pet
      final listNotifier = ref.read(petListProvider.notifier);
      await listNotifier.editPet(
        id: originalPet.id,
        name: name.trim(),
        breed: breed.trim().isEmpty ? null : breed.trim(),
        avatarUrl: avatarUrl,
        bio: bio.trim().isEmpty ? null : bio.trim(),
      );

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update profile. Please try again.',
      );
      return false;
    }
  }
}

final editProfileControllerProvider =
    NotifierProvider.autoDispose<EditProfileController, EditProfileState>(
  EditProfileController.new,
);
