import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../models/feed_post.dart';
import '../models/hashtag.dart';
import '../models/pet_stats.dart';

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(Supabase.instance.client),
);

/// Repository for the Social Feed feature.
///
/// [fetchFeed] returns the public timeline joined with the post's pet
/// (avatar / species) and the author user (handle / display name).
///
/// [toggleLike] **throws** on failure so that
/// [SocialNotifier] can catch the error and roll back the optimistic update.
class SocialRepository {
  SocialRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const NotAuthenticatedException();
    return id;
  }

  // ── Feed ──────────────────────────────────────────────────────────────────

  /// Fetches the public feed.
  ///
  /// Joins on `pets` for avatar/species/breed and on `users` for the handle.
  /// A nested `post_likes` selection lets us compute `isLiked` for the
  /// currently active pet without a second round-trip.
  Future<List<FeedPost>> fetchFeed({
    String? activePetId,
    int limit = 15,
    int offset = 0,
  }) async {
    final rows = await _client
        .from('posts')
        .select('''
          id,
          content,
          image_urls,
          created_at,
          like_count,
          comment_count,
          pet:pets!posts_pet_id_fkey!inner(id, name, species, breed, avatar_url),
          author:users!posts_author_id_fkey(id, username, display_name, avatar_url, location)
        ''')
        .eq('visibility', 'public')
        .eq('pets.is_public', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final posts = (rows as List).cast<Map<String, dynamic>>();

    // Fetch only the active pet's likes for this page in a single targeted
    // query — replaces the nested post_likes(pet_id) that pulled ALL likes
    // for ALL pets on every post.
    var likedIds = const <String>{};
    if (activePetId != null && posts.isNotEmpty) {
      final postIds = posts.map((r) => r['id'] as String).toList();
      likedIds = await _fetchLikedPostIds(activePetId, postIds);
    }

    return posts
        .map((r) => _rowToFeedPost(
              r,
              isLiked: likedIds.contains(r['id'] as String),
            ))
        .toList(growable: false);
  }

  /// Fetches posts authored by a specific pet with offset pagination.
  Future<List<FeedPost>> fetchPostsForPet(
    String petId, {
    String? activePetId,
    int limit = 30,
    int offset = 0,
  }) async {
    final rows = await _client
        .from('posts')
        .select('''
          id,
          content,
          image_urls,
          created_at,
          like_count,
          comment_count,
          pet:pets!posts_pet_id_fkey!inner(id, name, species, breed, avatar_url),
          author:users!posts_author_id_fkey(id, username, display_name, avatar_url, location)
        ''')
        .eq('pet_id', petId)
        .eq('visibility', 'public')
        .eq('pets.is_public', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final posts = (rows as List).cast<Map<String, dynamic>>();

    var likedIds = const <String>{};
    if (activePetId != null && posts.isNotEmpty) {
      final postIds = posts.map((r) => r['id'] as String).toList();
      likedIds = await _fetchLikedPostIds(activePetId, postIds);
    }

    return posts
        .map((r) => _rowToFeedPost(
              r,
              isLiked: likedIds.contains(r['id'] as String),
            ))
        .toList(growable: false);
  }

  /// Fetches a single post by its ID.
  ///
  /// Used when the user navigates directly to `/social/post/:postId` via a
  /// deep link or hot-restart, where `state.extra` is null.
  Future<FeedPost> fetchPostById({
    required String postId,
    String? activePetId,
  }) async {
    final row = await _client
        .from('posts')
        .select('''
          id,
          content,
          image_urls,
          created_at,
          like_count,
          comment_count,
          pet:pets!posts_pet_id_fkey(id, name, species, breed, avatar_url),
          author:users!posts_author_id_fkey(id, username, display_name, avatar_url, location)
        ''')
        .eq('id', postId)
        .single();

    // Single targeted like-status check (one row, no full-table scan).
    final isLiked = activePetId != null
        ? await _client
              .from('post_likes')
              .select('post_id')
              .eq('post_id', postId)
              .eq('pet_id', activePetId)
              .maybeSingle()
              .then((r) => r != null)
        : false;

    return _rowToFeedPost(
      Map<String, dynamic>.from(row as Map),
      isLiked: isLiked,
    );
  }

  /// Returns a [FeedPost] from a raw Supabase row.
  ///
  /// [isLiked] is computed by the caller via a targeted like-status query
  /// (either [_fetchLikedPostIds] for list views or a single check for
  /// [fetchPostById]) — the nested `post_likes` column is no longer fetched.
  FeedPost _rowToFeedPost(Map<String, dynamic> r, {bool isLiked = false}) {
    final pet = (r['pet'] as Map?)?.cast<String, dynamic>() ?? const {};
    final author = (r['author'] as Map?)?.cast<String, dynamic>() ?? const {};

    final petName = (pet['name'] as String?) ?? 'Unknown';
    final petSpecies = (pet['species'] as String?) ?? 'dog';
    final breed = pet['breed'] as String?;
    final handle =
        (author['username'] as String?) ??
        (author['display_name'] as String?) ??
        'petfolio_user';
    final fuzzyLocation = (author['location'] as String?) ?? '';

    final palette = _paletteFor(petSpecies);

    return FeedPost(
      id: r['id'] as String,
      petId: (pet['id'] as String?) ?? '',
      handle: handle,
      petName: petName,
      petSpecies: petSpecies,
      accentColor: palette.accent,
      fuzzyLocation: fuzzyLocation,
      caption: (r['content'] as String?) ?? '',
      likes: (r['like_count'] as int?) ?? 0,
      comments: (r['comment_count'] as int?) ?? 0,
      timeAgo: r['created_at'] != null
          ? formatTimeAgo(DateTime.parse(r['created_at'] as String))
          : '',
      isLiked: isLiked,
      gradientColors: palette.gradient,
      subjectColor: palette.subject,
      breed: breed,
      imageUrls: (r['image_urls'] as List?)?.cast<String>() ?? const [],
      petAvatarUrl: pet['avatar_url'] as String?,
      videoUrl: r['video_url'] as String?,
    );
  }

  /// Deterministic colour palette per species so feed cards stay on-brand
  /// without needing extra columns in the DB.
  _SpeciesPalette _paletteFor(String species) {
    switch (species.toLowerCase()) {
      case 'cat':
        return const _SpeciesPalette(
          accent: AppColors.mulberry500,
          subject: AppColors.lilac700,
          gradient: [AppColors.cream, AppColors.ink300, AppColors.mulberry500],
        );
      case 'rabbit':
        return const _SpeciesPalette(
          accent: AppColors.meadow500,
          subject: AppColors.mint700,
          gradient: [AppColors.mintSoft, AppColors.mint, AppColors.meadow500],
        );
      case 'dog':
      default:
        return const _SpeciesPalette(
          accent: AppColors.blue500,
          subject: AppColors.blue700,
          gradient: [AppColors.blue100, AppColors.blue300, AppColors.blue500],
        );
    }
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Returns the subset of [postIds] that the given [petId] has liked.
  ///
  /// One round-trip regardless of page size — replaces the nested
  /// `post_likes(pet_id)` select that returned all likes for all pets.
  Future<Set<String>> _fetchLikedPostIds(
    String petId,
    List<String> postIds,
  ) async {
    if (postIds.isEmpty) return const {};
    final rows = await _client
        .from('post_likes')
        .select('post_id')
        .eq('pet_id', petId)
        .inFilter('post_id', postIds);
    return {for (final r in (rows as List)) r['post_id'] as String};
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

  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'};
  static const _maxImageBytes = 10 * 1024 * 1024; // 10 MB
  static const _mimeTypes = {
    'jpg':  'image/jpeg',
    'jpeg': 'image/jpeg',
    'png':  'image/png',
    'webp': 'image/webp',
    'gif':  'image/gif',
    'heic': 'image/heic',
  };

  Future<String> uploadPostImage(XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw const ValidationException(message: 'Unsupported image format. Use JPG, PNG, WebP, GIF, or HEIC.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > _maxImageBytes) {
      throw const ValidationException(message: 'Image must be under 10 MB.');
    }

    final path = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    try {
      await _client.storage.from('post-images').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: _mimeTypes[ext] ?? 'image/$ext'),
      );
    } on StorageException catch (e) {
      throw NetworkException(message: 'Image upload failed: ${e.message}');
    }
    return _client.storage.from('post-images').getPublicUrl(path);
  }

  Future<void> createPost({
    required String petId,
    required String caption,
    List<String> imageUrls = const [],
  }) async {
    final row = await _client.from('posts').insert({
      'author_id': _uid,
      'pet_id': petId,
      'content': caption,
      'image_urls': imageUrls,
      'visibility': 'public',
    }).select('id').single();
    final postId = row['id'] as String;
    await attachHashtagsToPost(postId, caption);
  }

  /// Fetches stats for a pet (posts, followers, following) in a single RPC.
  ///
  /// Replaces three parallel COUNT queries that each required a separate
  /// network round-trip.
  Future<PetStats> fetchPetStats(String petId) async {
    final rows = await _client.rpc(
      'get_pet_stats',
      params: {'p_pet_id': petId},
    );
    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      return const PetStats(postCount: 0, followerCount: 0, followingCount: 0);
    }
    final row = list.first;
    return PetStats(
      postCount: (row['post_count'] as num).toInt(),
      followerCount: (row['follower_count'] as num).toInt(),
      followingCount: (row['following_count'] as num).toInt(),
    );
  }
  // ── Follow system ─────────────────────────────────────────────────────────

  /// Returns true if [followerPetId] is currently following [followingPetId].
  Future<bool> isFollowing({
    required String followerPetId,
    required String followingPetId,
  }) async {
    final result = await _client
        .from('pet_follows')
        .select('follower_pet_id')
        .eq('follower_pet_id', followerPetId)
        .eq('following_pet_id', followingPetId)
        .maybeSingle();
    return result != null;
  }

  /// Creates a follow relationship — [followerPetId] follows [followingPetId].
  Future<void> followPet({
    required String followerPetId,
    required String followingPetId,
  }) async {
    await _client.from('pet_follows').upsert(
      {
        'follower_pet_id': followerPetId,
        'following_pet_id': followingPetId,
      },
      onConflict: 'follower_pet_id, following_pet_id',
    );
  }

  /// Removes the follow relationship — [followerPetId] unfollows [followingPetId].
  Future<void> unfollowPet({
    required String followerPetId,
    required String followingPetId,
  }) async {
    await _client
        .from('pet_follows')
        .delete()
        .eq('follower_pet_id', followerPetId)
        .eq('following_pet_id', followingPetId);
  }

  // ── Post Management ───────────────────────────────────────────────────────

  /// Updates the caption of an existing post.
  ///
  /// The RLS policy on the `posts` table ensures only the post owner can
  /// update it. Throws on failure.
  Future<void> updatePostCaption({
    required String postId,
    required String newCaption,
  }) async {
    await _client
        .from('posts')
        .update({'content': newCaption.trim()})
        .eq('id', postId)
        .eq('author_id', _uid); // belt-and-suspenders guard
  }

  /// Permanently deletes a post by [postId].
  ///
  /// Cascades to its comments and likes via the DB foreign-key constraints.
  Future<void> deletePost(String postId) async {
    await _client
        .from('posts')
        .delete()
        .eq('id', postId)
        .eq('author_id', _uid); // belt-and-suspenders guard
  }

  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    try {
      await _client.from('reported_posts').insert({
        'post_id': postId,
        'reporter_id': _uid,
        'reason': reason,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const ValidationException(
          message: 'You have already reported this post.',
        );
      }
      throw DatabaseException.fromPostgrest(e);
    }
  }

  // ── Hashtags ──────────────────────────────────────────────────────────────

  Future<List<Hashtag>> searchHashtags(String query, {int limit = 20}) async {
    try {
      final q = query.trim().replaceAll('#', '');
      if (q.isEmpty) return const [];
      final rows = await _client
          .from('hashtags')
          .select()
          .ilike('tag', '$q%')
          .order('post_count', ascending: false)
          .limit(limit);
      return (rows as List).cast<Map<String, dynamic>>().map(Hashtag.fromJson).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  Future<List<FeedPost>> fetchPostsForHashtag(
    String tag, {
    String? activePetId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final cleanTag = tag.replaceAll('#', '').toLowerCase();
      final rows = await _client
          .from('post_hashtags')
          .select('post_id')
          .eq('tag', cleanTag)
          .range(offset, offset + limit - 1);
      final postIds = (rows as List).cast<Map<String, dynamic>>().map((r) => r['post_id'] as String).toList();
      if (postIds.isEmpty) return const [];

      final postRows = await _client
          .from('posts')
          .select('''
            id,
            content,
            image_urls,
            created_at,
            like_count,
            comment_count,
            pet:pets!posts_pet_id_fkey!inner(id, name, species, breed, avatar_url),
            author:users!posts_author_id_fkey(id, username, display_name, avatar_url, location)
          ''')
          .inFilter('id', postIds)
          .eq('visibility', 'public')
          .order('created_at', ascending: false);

      final posts = (postRows as List).cast<Map<String, dynamic>>();
      var likedIds = const <String>{};
      if (activePetId != null && posts.isNotEmpty) {
        likedIds = await _fetchLikedPostIds(activePetId, postIds);
      }
      return posts.map((r) => _rowToFeedPost(r, isLiked: likedIds.contains(r['id'] as String))).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  Future<void> attachHashtagsToPost(String postId, String caption) async {
    final tags = _extractHashtags(caption);
    if (tags.isEmpty) return;
    try {
      await _client.from('hashtags').upsert(
        tags.map((t) => {'tag': t}).toList(),
        onConflict: 'tag',
        ignoreDuplicates: true,
      );
      await _client.from('post_hashtags').upsert(
        tags.map((t) => {'post_id': postId, 'tag': t}).toList(),
        onConflict: 'post_id,tag',
        ignoreDuplicates: true,
      );
    } on PostgrestException {
      // Non-fatal: hashtag indexing failure doesn't break the post.
    }
  }

  List<String> _extractHashtags(String text) {
    final pattern = RegExp(r'#([a-zA-Z0-9_]+)');
    return pattern
        .allMatches(text)
        .map((m) => m.group(1)!.toLowerCase())
        .toSet()
        .toList();
  }

  // ── Saved posts / bookmarks ───────────────────────────────────────────────

  Future<bool> isPostSaved(String postId) async {
    final row = await _client
        .from('saved_posts')
        .select('id')
        .eq('user_id', _uid)
        .eq('post_id', postId)
        .maybeSingle();
    return row != null;
  }

  Future<void> savePost(String postId) async {
    try {
      await _client.from('saved_posts').upsert(
        {'user_id': _uid, 'post_id': postId},
        onConflict: 'user_id,post_id',
        ignoreDuplicates: true,
      );
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  Future<void> unsavePost(String postId) async {
    try {
      await _client
          .from('saved_posts')
          .delete()
          .eq('user_id', _uid)
          .eq('post_id', postId);
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  Future<List<FeedPost>> fetchSavedPosts({
    String? activePetId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final savedRows = await _client
          .from('saved_posts')
          .select('post_id')
          .eq('user_id', _uid)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      final postIds = (savedRows as List).cast<Map<String, dynamic>>().map((r) => r['post_id'] as String).toList();
      if (postIds.isEmpty) return const [];

      final postRows = await _client
          .from('posts')
          .select('''
            id,
            content,
            image_urls,
            created_at,
            like_count,
            comment_count,
            pet:pets!posts_pet_id_fkey!inner(id, name, species, breed, avatar_url),
            author:users!posts_author_id_fkey(id, username, display_name, avatar_url, location)
          ''')
          .inFilter('id', postIds)
          .eq('visibility', 'public');

      final posts = (postRows as List).cast<Map<String, dynamic>>();
      var likedIds = const <String>{};
      if (activePetId != null && posts.isNotEmpty) {
        likedIds = await _fetchLikedPostIds(activePetId, postIds);
      }
      return posts.map((r) => _rowToFeedPost(r, isLiked: likedIds.contains(r['id'] as String))).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  // ── Social DMs ────────────────────────────────────────────────────────────

  Future<String> getOrCreateSocialThread(String otherUserId) async {
    try {
      final result = await _client.rpc(
        'get_or_create_social_thread',
        params: {'p_other_user_id': otherUserId},
      );
      return result as String;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
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
