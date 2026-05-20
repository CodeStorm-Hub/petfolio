import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/feed_post.dart';
import '../../data/repositories/social_repository.dart';

const int _feedPageSize = 15;

// ─────────────────────────────────────────────────────────────────────────────
// Feed state
// ─────────────────────────────────────────────────────────────────────────────

class SocialFeedState {
  const SocialFeedState({
    this.posts = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.nextOffset = 0,
  });

  final List<FeedPost> posts;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextOffset;

  SocialFeedState copyWith({
    List<FeedPost>? posts,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextOffset,
  }) =>
      SocialFeedState(
        posts: posts ?? this.posts,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        nextOffset: nextOffset ?? this.nextOffset,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final socialControllerProvider =
    AsyncNotifierProvider.family<SocialNotifier, SocialFeedState, String>(
  SocialNotifier.new,
);

final postDetailProvider =
    FutureProvider.family<FeedPost, String>((ref, postId) async {
  final activePetId = ref.watch(activePetIdProvider) ?? '';
  return ref
      .read(socialRepositoryProvider)
      .fetchPostById(postId: postId, activePetId: activePetId);
});

final postProvider = Provider.family<FeedPost?, String>((ref, postId) {
  final activePetId = ref.watch(activePetIdProvider) ?? '';
  final feedState = ref.watch(socialControllerProvider(activePetId)).value;
  if (feedState == null) return null;
  try {
    return feedState.posts.firstWhere((p) => p.id == postId);
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class SocialNotifier extends AsyncNotifier<SocialFeedState> {
  SocialNotifier(this.arg);
  final String arg;

  RealtimeChannel? _channel;

  @override
  Future<SocialFeedState> build() async {
    final petId = arg;

    // Register cleanup BEFORE the async gap. If the provider is disposed while
    // the fetch is in flight, this callback still fires and prevents a zombie
    // channel from being created below (the mounted guard handles that).
    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    final posts = await _repo.fetchFeed(
      activePetId: petId,
      limit: _feedPageSize,
      offset: 0,
    );

    // Skip channel setup if the provider was disposed during the fetch.
    if (ref.mounted) {
      // Use a unique channel name per arg so concurrent instances (different
      // active pets) don't collide and silently drop each other's callbacks.
      _channel = Supabase.instance.client
          .channel('social_feed_$petId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'posts',
            callback: (payload) {
              final newRow = payload.newRecord;
              final postId = newRow['id'] as String?;
              if (postId == null) return;

              final likeCount = newRow['like_count'] as int?;
              final commentCount = newRow['comment_count'] as int?;

              final current = state.value;
              if (current == null) return;

              final idx = current.posts.indexWhere((p) => p.id == postId);
              if (idx == -1) return;

              final updated = List<FeedPost>.from(current.posts)
                ..[idx] = current.posts[idx].copyWithCounts(
                  likes: likeCount,
                  comments: commentCount,
                );

              state = AsyncData(current.copyWith(posts: updated));
            },
          )
          .subscribe();
    }

    return SocialFeedState(
      posts: posts,
      hasMore: posts.length >= _feedPageSize,
      nextOffset: posts.length,
    );
  }

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final posts = await _repo.fetchFeed(
        activePetId: arg,
        limit: _feedPageSize,
        offset: 0,
      );
      state = AsyncData(SocialFeedState(
        posts: posts,
        hasMore: posts.length >= _feedPageSize,
        nextOffset: posts.length,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final more = await _repo.fetchFeed(
        activePetId: arg,
        limit: _feedPageSize,
        offset: current.nextOffset,
      );

      if (!ref.mounted) return;

      final existingIds = current.posts.map((p) => p.id).toSet();
      final newPosts =
          more.where((p) => !existingIds.contains(p.id)).toList();

      state = AsyncData(current.copyWith(
        posts: [...current.posts, ...newPosts],
        isLoadingMore: false,
        hasMore: more.length >= _feedPageSize,
        nextOffset: current.nextOffset + more.length,
      ));
    } catch (_) {
      if (ref.mounted) {
        final cur = state.value;
        if (cur != null) state = AsyncData(cur.copyWith(isLoadingMore: false));
      }
    }
  }

  // ── Paw like ──────────────────────────────────────────────────────────────

  Future<void> toggleLike(String postId) async {
    final current = state.value;
    if (current == null) return;

    final idx = current.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = current.posts[idx];
    final nowLiked = !post.isLiked;

    final updated = List<FeedPost>.from(current.posts)
      ..[idx] = post.copyWithLike(liked: nowLiked);
    state = AsyncData(current.copyWith(posts: updated));

    try {
      await _repo.toggleLike(postId: postId, petId: arg, liked: nowLiked);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  // ── Edit caption ──────────────────────────────────────────────────────────

  Future<void> updateCaption(String postId, String newCaption) async {
    final current = state.value;
    if (current == null) return;

    final idx = current.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final updated = List<FeedPost>.from(current.posts)
      ..[idx] = current.posts[idx].copyWithCaption(newCaption);
    state = AsyncData(current.copyWith(posts: updated));

    try {
      await _repo.updatePostCaption(postId: postId, newCaption: newCaption);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  // ── Delete post ───────────────────────────────────────────────────────────

  Future<void> deletePost(String postId) async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(
      posts: current.posts.where((p) => p.id != postId).toList(),
    ));

    try {
      await _repo.deletePost(postId);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  void incrementCommentCount(String postId) {
    final current = state.value;
    if (current == null) return;

    final idx = current.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final updated = List<FeedPost>.from(current.posts)
      ..[idx] = current.posts[idx].copyWithIncrementedComment();
    state = AsyncData(current.copyWith(posts: updated));
  }

  void decrementCommentCount(String postId) {
    final current = state.value;
    if (current == null) return;

    final idx = current.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final updated = List<FeedPost>.from(current.posts)
      ..[idx] = current.posts[idx].copyWithDecrementedComment();
    state = AsyncData(current.copyWith(posts: updated));
  }
}
