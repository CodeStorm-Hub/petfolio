import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/feed_post.dart';
import '../../data/repositories/social_repository.dart';

part 'saved_posts_controller.g.dart';

@riverpod
class SavedPosts extends _$SavedPosts {
  static const _pageSize = 20;
  bool _hasMore = true;

  @override
  Future<List<FeedPost>> build() async {
    _hasMore = true;
    return _load(offset: 0);
  }

  Future<List<FeedPost>> _load({required int offset}) {
    final repo = ref.read(socialRepositoryProvider);
    final activePetId = ref.read(activePetIdProvider);
    return repo.fetchSavedPosts(
      activePetId: activePetId,
      limit: _pageSize,
      offset: offset,
    );
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.asData?.value ?? [];
    final next = await _load(offset: current.length);
    if (next.length < _pageSize) _hasMore = false;
    state = AsyncData([...current, ...next]);
  }

  Future<void> unsave(String postId) async {
    final repo = ref.read(socialRepositoryProvider);
    await repo.unsavePost(postId);
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((p) => p.id != postId).toList());
  }
}

@riverpod
Future<bool> isPostSaved(Ref ref, String postId) async {
  final repo = ref.read(socialRepositoryProvider);
  return repo.isPostSaved(postId);
}
