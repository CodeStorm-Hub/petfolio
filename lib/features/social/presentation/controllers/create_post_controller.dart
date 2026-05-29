import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/social_repository.dart';
import 'story_controller.dart';

part 'create_post_controller.g.dart';

enum PostStep { idle, uploading, posting }

class CreatePostState {
  CreatePostState({
    this.image,
    this.caption = '',
    this.step = PostStep.idle,
    this.error,
    this.isStory = false,
  });

  final XFile? image;
  final String caption;
  final PostStep step;
  final String? error;
  final bool isStory;

  bool get isSubmitting => step != PostStep.idle;

  CreatePostState copyWith({
    XFile? image,
    bool clearImage = false,
    String? caption,
    PostStep? step,
    String? error,
    bool clearError = false,
    bool? isStory,
  }) {
    return CreatePostState(
      image: clearImage ? null : (image ?? this.image),
      caption: caption ?? this.caption,
      step: step ?? this.step,
      error: clearError ? null : (error ?? this.error),
      isStory: isStory ?? this.isStory,
    );
  }
}

@riverpod
class CreatePostController extends _$CreatePostController {
  @override
  CreatePostState build() => CreatePostState();

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  void setImage(XFile image) => state = state.copyWith(image: image, clearError: true);
  void removeImage() => state = state.copyWith(clearImage: true);
  void setCaption(String caption) => state = state.copyWith(caption: caption);
  void setIsStory(bool isStory) => state = state.copyWith(isStory: isStory, clearError: true);

  Future<bool> submit(String petId) async {
    if (state.isStory) {
      if (state.image == null) {
        state = state.copyWith(error: 'Stories require an image.');
        return false;
      }

      state = state.copyWith(step: PostStep.uploading, clearError: true);

      try {
        await ref.read(storiesProvider.notifier).addStory(
          petId: petId,
          imageFile: state.image!,
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
