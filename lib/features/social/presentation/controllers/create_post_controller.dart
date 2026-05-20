import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/social_repository.dart';

enum PostStep { idle, uploading, posting }

class CreatePostState {
  CreatePostState({
    this.image,
    this.caption = '',
    this.step = PostStep.idle,
    this.error,
  });

  final XFile? image;
  final String caption;
  final PostStep step;
  final String? error;

  bool get isSubmitting => step != PostStep.idle;

  CreatePostState copyWith({
    XFile? image,
    bool clearImage = false,
    String? caption,
    PostStep? step,
    String? error,
    bool clearError = false,
  }) {
    return CreatePostState(
      image: clearImage ? null : (image ?? this.image),
      caption: caption ?? this.caption,
      step: step ?? this.step,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CreatePostNotifier extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => CreatePostState();

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  void setImage(XFile image) => state = state.copyWith(image: image, clearError: true);
  void removeImage() => state = state.copyWith(clearImage: true);
  void setCaption(String caption) => state = state.copyWith(caption: caption);

  Future<bool> submit(String petId) async {
    if (state.image == null && state.caption.trim().isEmpty) {
      state = state.copyWith(error: 'Please add an image or caption.');
      return false;
    }

    state = state.copyWith(step: PostStep.uploading, clearError: true);

    try {
      List<String> imageUrls = [];
      if (state.image != null) {
        final imageUrl = await _repo.uploadPostImage(state.image!);
        imageUrls.add(imageUrl);
      }

      state = state.copyWith(step: PostStep.posting);

      await _repo.createPost(
        petId: petId,
        caption: state.caption.trim(),
        imageUrls: imageUrls,
      );

      state = state.copyWith(step: PostStep.idle);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(step: PostStep.idle, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(step: PostStep.idle, error: e.toString());
      return false;
    }
  }
}

final createPostControllerProvider =
    NotifierProvider<CreatePostNotifier, CreatePostState>(
  CreatePostNotifier.new,
);
