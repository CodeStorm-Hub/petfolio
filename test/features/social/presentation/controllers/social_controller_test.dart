import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/features/social/data/models/feed_post.dart';
import 'package:petfolio/features/social/data/repositories/social_repository.dart';
import 'package:petfolio/features/social/presentation/controllers/social_controller.dart';

class MockSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #channel) {
      return MockRealtimeChannel();
    }
    return null;
  }
}

class MockRealtimeChannel implements RealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #onPostgresChanges) {
      return this;
    }
    if (invocation.memberName == #subscribe) {
      return this;
    }
    if (invocation.memberName == #unsubscribe) {
      return Future.value('');
    }
    return null;
  }
}

class MockSocialRepository implements SocialRepository {
  MockSocialRepository({
    List<FeedPost>? initialPosts,
    this.toggleLikeError,
  }) : posts = initialPosts ?? [];

  final List<FeedPost> posts;
  Object? toggleLikeError;
  
  final List<({String postId, String petId, bool liked})> toggleLikeCalls = [];

  @override
  Future<List<FeedPost>> fetchFeed({
    String? activePetId,
    int limit = 15,
    int offset = 0,
  }) async {
    return posts.skip(offset).take(limit).toList();
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String petId,
    required bool liked,
  }) async {
    toggleLikeCalls.add((postId: postId, petId: petId, liked: liked));
    if (toggleLikeError != null) {
      throw toggleLikeError!;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SocialController Tests', () {
    late MockSocialRepository mockRepository;
    late FeedPost testPost;

    setUp(() {
      testPost = const FeedPost(
        id: 'post-1',
        petId: 'pet-owner',
        handle: 'owner_handle',
        petName: 'Rex',
        petSpecies: 'dog',
        accentColor: Colors.blue,
        fuzzyLocation: 'New York',
        caption: 'Hello World',
        likes: 5,
        comments: 2,
        timeAgo: '1h',
        isLiked: false,
        gradientColors: [Colors.blue, Colors.green],
        subjectColor: Colors.blue,
      );
      mockRepository = MockSocialRepository(initialPosts: [testPost]);
    });

    test('initial build fetches and stores feed state', () async {
      final container = ProviderContainer(
        overrides: [
          socialRepositoryProvider.overrideWithValue(mockRepository),
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(socialControllerProvider('pet-123')),
        const AsyncValue<SocialFeedState>.loading(),
      );

      final state = await container.read(socialControllerProvider('pet-123').future);
      expect(state.posts.length, 1);
      expect(state.posts.first.id, 'post-1');
      expect(state.posts.first.isLiked, false);
    });

    test('toggleLike optimistic update and success', () async {
      final container = ProviderContainer(
        overrides: [
          socialRepositoryProvider.overrideWithValue(mockRepository),
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(socialControllerProvider('pet-123').future);

      final controller = container.read(socialControllerProvider('pet-123').notifier);

      final future = controller.toggleLike('post-1');

      var currentState = container.read(socialControllerProvider('pet-123')).value!;
      expect(currentState.posts.first.isLiked, true);
      expect(currentState.posts.first.likes, 6);

      await future;

      expect(mockRepository.toggleLikeCalls.length, 1);
      expect(mockRepository.toggleLikeCalls.first.postId, 'post-1');
      expect(mockRepository.toggleLikeCalls.first.petId, 'pet-123');
      expect(mockRepository.toggleLikeCalls.first.liked, true);

      currentState = container.read(socialControllerProvider('pet-123')).value!;
      expect(currentState.posts.first.isLiked, true);
      expect(currentState.posts.first.likes, 6);
    });

    test('toggleLike optimistic update and rollback on failure', () async {
      mockRepository.toggleLikeError = Exception('Supabase connection failed');

      final container = ProviderContainer(
        overrides: [
          socialRepositoryProvider.overrideWithValue(mockRepository),
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(socialControllerProvider('pet-123').future);

      final controller = container.read(socialControllerProvider('pet-123').notifier);

      final future = controller.toggleLike('post-1');

      var currentState = container.read(socialControllerProvider('pet-123')).value!;
      expect(currentState.posts.first.isLiked, true);
      expect(currentState.posts.first.likes, 6);

      await future;

      currentState = container.read(socialControllerProvider('pet-123')).value!;
      expect(currentState.posts.first.isLiked, false);
      expect(currentState.posts.first.likes, 5);
    });
  });
}
