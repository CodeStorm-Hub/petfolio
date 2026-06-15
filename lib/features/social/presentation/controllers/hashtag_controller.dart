import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/feed_post.dart';
import '../../data/models/hashtag.dart';
import '../../data/repositories/social_repository.dart';

part 'hashtag_controller.g.dart';

@riverpod
class HashtagSearch extends _$HashtagSearch {
  @override
  List<Hashtag> build() => const [];

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const [];
      return;
    }
    final repo = ref.read(socialRepositoryProvider);
    final results = await repo.searchHashtags(query);
    state = results;
  }

  void clear() => state = const [];
}

@riverpod
class HashtagFeed extends _$HashtagFeed {
  static const _pageSize = 20;
  bool _hasMore = true;

  @override
  Future<List<FeedPost>> build(String tag) async {
    _hasMore = true;
    return _load(tag, offset: 0);
  }

  Future<List<FeedPost>> _load(String tag, {required int offset}) async {
    final repo = ref.read(socialRepositoryProvider);
    final activePetId = ref.read(activePetIdProvider);
    return repo.fetchPostsForHashtag(
      tag,
      activePetId: activePetId,
      limit: _pageSize,
      offset: offset,
    );
  }

  Future<void> loadMore(String tag) async {
    if (!_hasMore) return;
    final current = state.asData?.value ?? [];
    final next = await _load(tag, offset: current.length);
    if (next.length < _pageSize) _hasMore = false;
    state = AsyncData([...current, ...next]);
  }
}
