import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/feed_post.dart';
import '../models/pet_stats.dart';

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(Supabase.instance.client),
);

/// Repository for the Social Feed feature.
///
/// [fetchFeed] returns the public timeline joined with the post's pet
/// (avatar / species) and the author user (handle / display name).
///
/// [toggleLike] and [toggleCandle] **throw** on failure so that
/// [SocialNotifier] can catch the error and roll back the optimistic update.
class SocialRepository {
  SocialRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Not authenticated');
    return id;
  }

  // ── Feed ──────────────────────────────────────────────────────────────────

  /// Fetches the public feed.
  ///
  /// Joins on `pets` for avatar/species/breed and on `users` for the handle.
  /// A nested `post_likes` selection lets us compute `isLiked` for the
  /// currently active pet without a second round-trip.
  Future<List<FeedPost>> fetchFeed({required String activePetId}) async {
    final rows = await _client
        .from('posts')
        .select('''
          id,
          content,
          image_urls,
          like_count,
          comment_count,
          created_at,
          pet:pets!posts_pet_id_fkey(id, name, species, breed, avatar_url),
          author:users!posts_author_id_fkey(id, username, display_name, avatar_url),
          post_likes(pet_id)
        ''')
        .eq('visibility', 'public')
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => _rowToFeedPost(r, activePetId))
        .toList(growable: false);
  }

  /// Fetches posts authored by a specific pet.
  Future<List<FeedPost>> fetchPostsForPet(String petId, {required String activePetId}) async {
    final rows = await _client
        .from('posts')
        .select('''
          id,
          content,
          image_urls,
          like_count,
          comment_count,
          created_at,
          pet:pets!posts_pet_id_fkey(id, name, species, breed, avatar_url),
          author:users!posts_author_id_fkey(id, username, display_name, avatar_url),
          post_likes(pet_id)
        ''')
        .eq('pet_id', petId)
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map((r) => _rowToFeedPost(r, activePetId))
        .toList(growable: false);
  }

  FeedPost _rowToFeedPost(Map<String, dynamic> r, String activePetId) {
    final pet = (r['pet'] as Map?)?.cast<String, dynamic>() ?? const {};
    final author = (r['author'] as Map?)?.cast<String, dynamic>() ?? const {};
    final likes = (r['post_likes'] as List?) ?? const [];

    final petName = (pet['name'] as String?) ?? 'Unknown';
    final petSpecies = (pet['species'] as String?) ?? 'dog';
    final breed = pet['breed'] as String?;
    final handle =
        (author['username'] as String?) ??
        (author['display_name'] as String?) ??
        'petfolio_user';

    final palette = _paletteFor(petSpecies);
    final isLiked = likes.any((l) {
      final m = (l as Map).cast<String, dynamic>();
      return m['pet_id'] == activePetId;
    });

    return FeedPost(
      id: r['id'] as String,
      handle: handle,
      petName: petName,
      petSpecies: petSpecies,
      accentColor: palette.accent,
      fuzzyLocation: '', // not modelled in DB yet
      caption: (r['content'] as String?) ?? '',
      likes: (r['like_count'] as int?) ?? 0,
      comments: (r['comment_count'] as int?) ?? 0,
      timeAgo: _timeAgo(DateTime.tryParse(r['created_at'] as String? ?? '')),
      isLiked: isLiked,
      gradientColors: palette.gradient,
      subjectColor: palette.subject,
      breed: breed,
      imageUrls: (r['image_urls'] as List?)?.cast<String>() ?? const [],
    );
  }

  /// Deterministic colour palette per species so feed cards stay on-brand
  /// without needing extra columns in the DB.
  _SpeciesPalette _paletteFor(String species) {
    switch (species.toLowerCase()) {
      case 'cat':
        return const _SpeciesPalette(
          accent: AppColors.mulberry500,
          subject: Color(0xFF7A4570),
          gradient: [
            Color(0xFFF5ECD7),
            Color(0xFFD4B896),
            AppColors.mulberry500,
          ],
        );
      case 'rabbit':
        return const _SpeciesPalette(
          accent: AppColors.meadow500,
          subject: Color(0xFF4F8C72),
          gradient: [Color(0xFFE3F1E9), Color(0xFF9CCDB3), AppColors.meadow500],
        );
      case 'dog':
      default:
        return const _SpeciesPalette(
          accent: AppColors.blue500,
          subject: Color(0xFF1D4ED8),
          gradient: [Color(0xFFBFD7FF), Color(0xFF6EA8FE), AppColors.blue500],
        );
    }
  }

  String _timeAgo(DateTime? ts) {
    if (ts == null) return '';
    final d = DateTime.now().difference(ts);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${(d.inDays / 7).floor()}w';
  }

  // ── Paw likes ─────────────────────────────────────────────────────────────

  Future<void> toggleLike({
    required String postId,
    required String petId,
    required bool liked,
  }) async {
    if (liked) {
      await _client.from('post_likes').upsert({
        'post_id': postId,
        'pet_id': petId,
        'user_id': _uid,
      }, onConflict: 'post_id, pet_id');
    } else {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('pet_id', petId);
    }
  }

  // ── Post Creation ─────────────────────────────────────────────────────────

  Future<String> uploadImage(Uint8List bytes, String extension) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'posts/$fileName';

    await _client.storage.from('post-images').uploadBinary(path, bytes);
    return _client.storage.from('post-images').getPublicUrl(path);
  }

  Future<void> createPost({
    required String petId,
    required String caption,
    List<String> imageUrls = const [],
  }) async {
    await _client.from('posts').insert({
      'author_id': _uid,
      'pet_id': petId,
      'content': caption,
      'image_urls': imageUrls,
      'visibility': 'public',
    });
  }

  /// Fetches real-time stats for a pet: posts, followers, and following counts.
  Future<PetStats> fetchPetStats(String petId) async {
    final results = await Future.wait([
      _client.from('posts').select().eq('pet_id', petId).count(CountOption.exact),
      _client.from('pet_follows').select().eq('following_pet_id', petId).count(CountOption.exact),
      _client.from('pet_follows').select().eq('follower_pet_id', petId).count(CountOption.exact),
    ]);

    return PetStats(
      postCount: results[0].count,
      followerCount: results[1].count,
      followingCount: results[2].count,
    );
  }
}

class _SpeciesPalette {
  const _SpeciesPalette({
    required this.accent,
    required this.subject,
    required this.gradient,
  });

  final Color accent;
  final Color subject;
  final List<Color> gradient;
}
