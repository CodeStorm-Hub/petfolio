import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/feed_post.dart';
import '../../data/repositories/social_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final socialControllerProvider =
    AsyncNotifierProvider.family<SocialNotifier, List<FeedPost>, String>(
  SocialNotifier.new,
);

/// Fetches a single post by ID — used as a fallback on deep links / restarts.
final postDetailProvider =
    FutureProvider.autoDispose.family<FeedPost, String>((ref, postId) async {
  final activePetId = ref.watch(activePetIdProvider) ?? '';
  return ref
      .read(socialRepositoryProvider)
      .fetchPostById(postId: postId, activePetId: activePetId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the social feed for a given [petId].
///
/// Optimistic UI pattern (paw like / candle):
///   1. Snapshot the current state.
///   2. Apply the optimistic update immediately → heart turns red on next frame.
///   3. Await the Supabase write — [SocialRepository] throws on failure.
///   4. On catch, restore the snapshot — UI reverts transparently.
class SocialNotifier extends FamilyAsyncNotifier<List<FeedPost>, String> {
  RealtimeChannel? _channel;

  @override
  Future<List<FeedPost>> build(String petId) async {
    final posts = await _repo.fetchFeed(activePetId: petId);

    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('public:posts')
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

            final current = state.valueOrNull;
            if (current == null) return;

            final idx = current.indexWhere((p) => p.id == postId);
            if (idx == -1) return;

            final updated = List<FeedPost>.from(current);
            updated[idx] = updated[idx].copyWithCounts(
              likes: likeCount,
              comments: commentCount,
            );
            
            state = AsyncData(updated);
          },
        )
        .subscribe();

    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    return posts;
  }

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  /// Pull-to-refresh entry point.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _repo.fetchFeed(activePetId: arg));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Paw like ──────────────────────────────────────────────────────────────

  Future<void> toggleLike(String postId) async {
    final prev = state.valueOrNull;
    if (prev == null) return;

    final idx = prev.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = prev[idx];
    final nowLiked = !post.isLiked;

    // 1. Optimistic update — the heart turns red instantly.
    final updated = List<FeedPost>.from(prev)
      ..[idx] = post.copyWithLike(liked: nowLiked);
    state = AsyncData(updated);

    try {
      // 2. Background write — throws on failure.
      await _repo.toggleLike(
        postId: postId,
        petId: arg,
        liked: nowLiked,
      );
    } catch (_) {
      state = AsyncData(prev);
    }
  }

  // ── Edit caption ──────────────────────────────────────────────────────────

  /// Edits a post's caption with an optimistic update.
  Future<void> updateCaption(String postId, String newCaption) async {
    final prev = state.valueOrNull;
    if (prev == null) return;

    final idx = prev.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    // 1. Optimistic update — caption changes immediately in the feed.
    final updated = List<FeedPost>.from(prev)
      ..[idx] = prev[idx].copyWithCaption(newCaption);
    state = AsyncData(updated);

    try {
      // 2. Background write.
      await _repo.updatePostCaption(postId: postId, newCaption: newCaption);
    } catch (_) {
      // 3. Rollback on failure.
      state = AsyncData(prev);
    }
  }

  // ── Delete post ───────────────────────────────────────────────────────────

  /// Removes a post from the feed with optimistic removal.
  Future<void> deletePost(String postId) async {
    final prev = state.valueOrNull;
    if (prev == null) return;

    // 1. Optimistic remove — post disappears from feed instantly.
    state = AsyncData(prev.where((p) => p.id != postId).toList());

    try {
      // 2. Background delete.
      await _repo.deletePost(postId);
    } catch (_) {
      // 3. Rollback on failure.
      state = AsyncData(prev);
    }
  }
  /// Optimistically increments the comment count for a post.
  /// Called when a user submits a new comment.
  void incrementCommentCount(String postId) {
    final prev = state.valueOrNull;
    if (prev == null) return;

    final idx = prev.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final updated = List<FeedPost>.from(prev)
      ..[idx] = prev[idx].copyWithIncrementedComment();
    state = AsyncData(updated);
  }

  /// Optimistically decrements the comment count for a post.
  /// Called when a user deletes a comment.
  void decrementCommentCount(String postId) {
    final prev = state.valueOrNull;
    if (prev == null) return;

    final idx = prev.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final updated = List<FeedPost>.from(prev)
      ..[idx] = prev[idx].copyWithDecrementedComment();
    state = AsyncData(updated);
  }
}
