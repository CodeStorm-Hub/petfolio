import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../features/pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/feed_post.dart';
import '../../data/repositories/social_repository.dart';

part 'social_controller.g.dart';

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
// Providers & Notifiers
// ─────────────────────────────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

@riverpod
class SocialController extends _$SocialController {
  RealtimeChannel? _channel;

  @override
  FutureOr<SocialFeedState> build(String petId) async {
    // Register cleanup on dispose
    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    final posts = await ref.read(socialRepositoryProvider).fetchFeed(
      activePetId: petId,
      limit: _feedPageSize,
      offset: 0,
    );

    _subscribeToRealtime(petId);

    return SocialFeedState(
      posts: posts,
      hasMore: posts.length >= _feedPageSize,
      nextOffset: posts.length,
    );
  }

  void _subscribeToRealtime(String petId) {
    if (!ref.mounted) return;
    _channel = ref.read(supabaseClientProvider)
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

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final posts = await ref.read(socialRepositoryProvider).fetchFeed(
        activePetId: petId,
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
      final more = await ref.read(socialRepositoryProvider).fetchFeed(
        activePetId: petId,
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
      await ref.read(socialRepositoryProvider).toggleLike(
        postId: postId,
        petId: petId,
        liked: nowLiked,
      );
    } catch (e) {
      state = AsyncData(current);
      AppSnackBar.showError(e);
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
      await ref.read(socialRepositoryProvider).updatePostCaption(
        postId: postId,
        newCaption: newCaption,
      );
    } catch (e) {
      state = AsyncData(current);
      AppSnackBar.showError(e);
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
      await ref.read(socialRepositoryProvider).deletePost(postId);
    } catch (e) {
      state = AsyncData(current);
      AppSnackBar.showError(e);
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

@riverpod
Future<FeedPost?> postDetail(Ref ref, String postId) async {
  final activePetId = ref.watch(activePetIdProvider);
  if (activePetId == null || activePetId.isEmpty) return null;
  return ref
      .read(socialRepositoryProvider)
      .fetchPostById(postId: postId, activePetId: activePetId);
}

@riverpod
FeedPost? post(Ref ref, String postId) {
  final activePetId = ref.watch(activePetIdProvider);
  if (activePetId == null || activePetId.isEmpty) return null;
  final feedState = ref.watch(socialControllerProvider(activePetId)).value;
  if (feedState == null) return null;
  try {
    return feedState.posts.firstWhere((p) => p.id == postId);
  } catch (_) {
    return null;
  }
}
