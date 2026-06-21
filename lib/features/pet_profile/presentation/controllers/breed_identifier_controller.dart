import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/platform/media_picker.dart';
import '../../domain/services/breed_identification_service.dart';

class BreedIdentifierState {
  const BreedIdentifierState({
    this.imageFile,
    this.loading = false,
    this.error,
    this.result,
  });

  final File? imageFile;
  final bool loading;
  final String? error;
  final BreedIdentificationResult? result;

  BreedIdentifierState copyWith({
    File? imageFile,
    bool? loading,
    String? error,
    BreedIdentificationResult? result,
    bool clearError = false,
    bool clearResult = false,
  }) =>
      BreedIdentifierState(
        imageFile: imageFile ?? this.imageFile,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        result: clearResult ? null : (result ?? this.result),
      );
}

final breedIdentifierControllerProvider =
    NotifierProvider<BreedIdentifierController, BreedIdentifierState>(
  BreedIdentifierController.new,
);

class BreedIdentifierController extends Notifier<BreedIdentifierState> {
  @override
  BreedIdentifierState build() => const BreedIdentifierState();

  Future<void> pickAndIdentify(ImageSource source) async {
    final picked = await pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    state = BreedIdentifierState(
      imageFile: File(picked.path),
      loading: true,
    );

    try {
      final result = await ref
          .read(breedIdentificationServiceProvider)
          .identifyBreed(state.imageFile!);
      state = state.copyWith(loading: false, result: result);
    } on BreedIdentificationException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }
}
