import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/social_repository.dart';

class CreatePostState {
  CreatePostState({
    this.image,
    this.caption = '',
    this.isSubmitting = false,
    this.error,
  });

  final File? image;
  final String caption;
  final bool isSubmitting;
  final String? error;

  CreatePostState copyWith({
    File? image,
    String? caption,
    bool? isSubmitting,
    String? error,
  }) {
    return CreatePostState(
      image: image ?? this.image,
      caption: caption ?? this.caption,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class CreatePostNotifier extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => CreatePostState();

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  void setImage(File image) => state = state.copyWith(image: image);
  void setCaption(String caption) => state = state.copyWith(caption: caption);

  Future<bool> submit(String petId) async {
    if (state.image == null && state.caption.isEmpty) {
      state = state.copyWith(error: 'Please add an image or caption');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      List<String> imageUrls = [];
      if (state.image != null) {
        final bytes = await state.image!.readAsBytes();
        final ext = state.image!.path.split('.').last;
        final imageUrl = await _repo.uploadImage(bytes, ext);
        imageUrls.add(imageUrl);
      }

      await _repo.createPost(
        petId: petId,
        caption: state.caption,
        imageUrls: imageUrls,
      );

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

final createPostControllerProvider =
    NotifierProvider<CreatePostNotifier, CreatePostState>(
  CreatePostNotifier.new,
);
