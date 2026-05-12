import 'package:flutter/material.dart';
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
///   2. Apply the optimistic update immediately → UI updates on next frame.
///   3. Await the Supabase write — [SocialRepository] throws on failure.
///   4. On catch, restore the snapshot — UI reverts transparently.
class SocialNotifier extends FamilyAsyncNotifier<List<FeedPost>, String> {
  @override
  Future<List<FeedPost>> build(String petId) async => _demoPosts();

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  // ── Paw like ──────────────────────────────────────────────────────────────

  Future<void> toggleLike(String postId) async {
    final prev = state.valueOrNull;
    if (prev == null) return;

    final idx = prev.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = prev[idx];
    final nowLiked = !post.isLiked;

    // 1. Optimistic update.
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
      // 3. Rollback.
      state = AsyncData(prev);
    }
  }

  // ── Memorial candle ───────────────────────────────────────────────────────

  Future<void> toggleCandle(String postId) async {
    final prev = state.valueOrNull;
    if (prev == null) return;

    final idx = prev.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = prev[idx];
    final nowLit = !post.isCandleLit;

    // 1. Optimistic update.
    final updated = List<FeedPost>.from(prev)
      ..[idx] = post.copyWithCandle(lit: nowLit);
    state = AsyncData(updated);

    try {
      // 2. Background write — throws on failure.
      await _repo.toggleCandle(
        postId: postId,
        petId: arg,
        lit: nowLit,
      );
    } catch (_) {
      // 3. Rollback.
      state = AsyncData(prev);
    }
  }

  // ── Demo data ─────────────────────────────────────────────────────────────
  // Post IDs must be UUID format because post_likes.post_id is type uuid.

  static List<FeedPost> _demoPosts() => const [
        FeedPost(
          id: '11111111-1111-1111-1111-111111111111',
          handle: 'buddy.the.collie',
          petName: 'Buddy',
          petSpecies: 'dog',
          accentColor: Color(0xFF2563EB),
          fuzzyLocation: 'Highbury, London',
          caption:
              'Morning zoomies ✅  Mud bath ✅  Unconditional love ✅  Another perfect Tuesday.',
          likes: 142,
          comments: 18,
          timeAgo: '2h',
          isLiked: false,
          gradientColors: [
            Color(0xFFBFD7FF),
            Color(0xFF6EA8FE),
            Color(0xFF2563EB),
          ],
          subjectColor: Color(0xFF1D4ED8),
          tag: 'Morning walk',
        ),
        FeedPost(
          id: '22222222-2222-2222-2222-222222222222',
          handle: "mia's_garden",
          petName: 'Mia',
          petSpecies: 'cat',
          accentColor: Color(0xFF9B5C8A),
          fuzzyLocation: 'Camden, London',
          caption:
              'She loved Tuesday mornings in the garden. The lavender was her favourite spot. '
              'We miss you every single day, sweet girl. 🕯️',
          likes: 0,
          comments: 31,
          timeAgo: '1d',
          isLiked: false,
          gradientColors: [
            Color(0xFFF5ECD7),
            Color(0xFFD4B896),
            Color(0xFF9B5C8A),
          ],
          subjectColor: Color(0xFF7A4570),
          isMemorial: true,
          memorialDates: '2018 – 2025',
          candles: 47,
          tributes: 12,
          isCandleLit: false,
          breed: 'British Shorthair',
        ),
        FeedPost(
          id: '33333333-3333-3333-3333-333333333333',
          handle: 'rex.does.agility',
          petName: 'Rex',
          petSpecies: 'dog',
          accentColor: Color(0xFFF4A261),
          fuzzyLocation: 'Hackney, London',
          caption:
              'New personal best on the A-frame today 🏆  Five months of training '
              'and this boy just keeps levelling up.',
          likes: 89,
          comments: 7,
          timeAgo: '5h',
          isLiked: true,
          gradientColors: [
            Color(0xFFFDE8D0),
            Color(0xFFF4A261),
            Color(0xFFE07B39),
          ],
          subjectColor: Color(0xFFBC6249),
          tag: 'Agility training',
          isCarousel: true,
        ),
      ];
}
