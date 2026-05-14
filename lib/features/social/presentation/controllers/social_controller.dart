import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/feed_post.dart';
import '../../data/repositories/social_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final socialControllerProvider =
    AsyncNotifierProvider.family<SocialNotifier, List<FeedPost>, String>(
  SocialNotifier.new,
);

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
  @override
  Future<List<FeedPost>> build(String petId) async {
    return _repo.fetchFeed(activePetId: petId);
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
}
