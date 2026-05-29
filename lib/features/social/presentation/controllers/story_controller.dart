import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../data/models/story.dart';
import '../../data/repositories/story_repository.dart';

part 'story_controller.g.dart';

@riverpod
class Stories extends _$Stories {
  @override
  FutureOr<List<Story>> build() async {
    return ref.read(storyRepositoryProvider).fetchActiveStories();
  }

  StoryRepository get _repo => ref.read(storyRepositoryProvider);

  /// Marks a story as viewed by the current user.
  /// Update is executed optimistically on the UI list.
  Future<void> markStoryViewed(String storyId) async {
    final current = state.value;
    if (current == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final index = current.indexWhere((s) => s.id == storyId);
    if (index == -1) return;

    final story = current[index];
    // If user has already viewed, do nothing.
    if (story.viewedByUsers.contains(userId)) return;

    // 1. Optimistic Update: Append the current user's ID to local state
    final updatedList = List<Story>.from(current);
    updatedList[index] = story.copyWith(
      viewedByUsers: [...story.viewedByUsers, userId],
    );
    state = AsyncData(updatedList);

    try {
      // 2. Perform background write
      await _repo.markStoryViewed(storyId);
    } catch (e) {
      // 3. Rollback on failure
      state = AsyncData(current);
      AppSnackBar.showError(e);
    }
  }

  /// Uploads and posts a new story for a pet.
  Future<void> addStory({
    required String petId,
    required XFile imageFile,
  }) async {
    final current = state.value;
    try {
      // Upload image first
      final imageUrl = await _repo.uploadStoryImage(imageFile);
      // Create database record
      final newStory = await _repo.createStory(petId: petId, imageUrl: imageUrl);

      if (current != null) {
        state = AsyncData([newStory, ...current]);
      } else {
        state = AsyncData([newStory]);
      }
    } catch (e) {
      AppSnackBar.showError(e);
      rethrow;
    }
  }
}
