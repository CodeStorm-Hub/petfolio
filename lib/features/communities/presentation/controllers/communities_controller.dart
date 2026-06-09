import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/community.dart';
import '../../data/models/community_post.dart';
import '../../data/repositories/community_repository.dart';

// ─── Communities list ─────────────────────────────────────────────────────────

final communitiesControllerProvider =
    AsyncNotifierProvider<CommunitiesController, List<Community>>(
  CommunitiesController.new,
);

class CommunitiesController extends AsyncNotifier<List<Community>> {
  @override
  Future<List<Community>> build() {
    final petId = ref.watch(activePetIdProvider);
    return ref.read(communityRepositoryProvider).fetchAll(petId: petId);
  }

  Future<void> toggleMembership(Community community) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    final repo = ref.read(communityRepositoryProvider);
    final current = state.value ?? [];

    if (community.isMember) {
      await repo.leave(community.id, petId);
    } else {
      await repo.join(community.id, petId);
    }

    state = AsyncData([
      for (final c in current)
        if (c.id == community.id)
          c.copyWith(
            isMember: !community.isMember,
            memberCount: (community.memberCount +
                    (community.isMember ? -1 : 1))
                .clamp(0, 999999),
          )
        else
          c,
    ]);
  }

  Future<Community?> createCommunity({
    required String name,
    String? description,
  }) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return null;

    final community = await ref.read(communityRepositoryProvider).createCommunity(
          name: name,
          description: description,
          creatorPetId: petId,
        );

    final current = state.value ?? [];
    state = AsyncData([community, ...current]);
    return community;
  }
}

// ─── Community posts ──────────────────────────────────────────────────────────

class PostsState {
  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });
  final List<CommunityPost> posts;
  final bool isLoading;
  final Object? error;

  PostsState copyWith({
    List<CommunityPost>? posts,
    bool? isLoading,
    Object? error,
  }) =>
      PostsState(
        posts: posts ?? this.posts,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class CommunityPostsNotifier extends Notifier<PostsState> {
  RealtimeChannel? _channel;
  String? _communityId;

  @override
  PostsState build() {
    final communityId = ref.watch(_activeCommunityIdProvider);
    if (communityId == null) return const PostsState();
    _communityId = communityId;
    _load(communityId);
    ref.onDispose(() => unawaited(_channel?.unsubscribe()));
    return const PostsState(isLoading: true);
  }

  Future<void> _load(String communityId) async {
    try {
      final petId = ref.read(activePetIdProvider);
      final posts = await ref
          .read(communityRepositoryProvider)
          .fetchPosts(communityId, petId: petId);
      state = PostsState(posts: posts);
      _subscribeRealtime(communityId);
    } catch (e) {
      state = PostsState(error: e);
    }
  }

  Future<void> reload() async {
    final communityId = _communityId;
    if (communityId == null) return;
    state = const PostsState(isLoading: true);
    await _load(communityId);
  }

  void _subscribeRealtime(String communityId) {
    unawaited(_channel?.unsubscribe());
    final client = Supabase.instance.client;
    _channel = client
        .channel('community_posts:$communityId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'community_posts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'community_id',
            value: communityId,
          ),
          callback: (payload) {
            final row = Map<String, dynamic>.from(payload.newRecord);
            final post = CommunityPost.fromJson(row);
            if (!state.posts.any((p) => p.id == post.id)) {
              state = state.copyWith(posts: [post, ...state.posts]);
            }
          },
        )
        .subscribe();
  }

  Future<void> createPost(String content) async {
    final communityId = _communityId;
    final petId = ref.read(activePetIdProvider);
    if (communityId == null || petId == null) return;

    try {
      final post = await ref.read(communityRepositoryProvider).createPost(
            communityId: communityId,
            authorPetId: petId,
            content: content,
          );
      if (!state.posts.any((p) => p.id == post.id)) {
        state = state.copyWith(posts: [post, ...state.posts], error: null);
      }
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }

  Future<void> toggleLike(CommunityPost post) async {
    final petId = ref.read(activePetIdProvider);
    if (petId == null) return;
    final repo = ref.read(communityRepositoryProvider);

    if (post.isLiked) {
      await repo.unlikePost(post.id, petId);
    } else {
      await repo.likePost(post.id, petId);
    }

    state = state.copyWith(
      posts: [
        for (final p in state.posts)
          p.id == post.id
              ? p.copyWith(
                  isLiked: !post.isLiked,
                  likeCount: post.likeCount + (post.isLiked ? -1 : 1),
                )
              : p,
      ],
    );
  }
}

class _ActiveCommunityNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String id) => state = id;
}

final _activeCommunityIdProvider =
    NotifierProvider<_ActiveCommunityNotifier, String?>(
  _ActiveCommunityNotifier.new,
);

final communityPostsProvider =
    NotifierProvider.autoDispose<CommunityPostsNotifier, PostsState>(
  CommunityPostsNotifier.new,
);

void setActiveCommunity(WidgetRef ref, String communityId) {
  ref.read(_activeCommunityIdProvider.notifier).set(communityId);
}
