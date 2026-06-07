import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community.dart';
import '../models/community_post.dart';

final communityRepositoryProvider = Provider<CommunityRepository>(
  (_) => CommunityRepository(Supabase.instance.client),
);

class CommunityRepository {
  CommunityRepository(this._client);
  final SupabaseClient _client;

  static const _postAuthorEmbed =
      'pets!community_posts_author_pet_id_fkey(name, avatar_url)';

  static const _postSelect = '*, $_postAuthorEmbed';

  Future<List<Community>> fetchAll({String? petId}) async {
    final rows = await _client
        .from('communities')
        .select()
        .order('member_count', ascending: false)
        .limit(50);

    Set<String> memberIds = {};
    if (petId != null) {
      final memberships = await _client
          .from('community_members')
          .select('community_id')
          .eq('pet_id', petId);
      memberIds = {for (final m in memberships) m['community_id'] as String};
    }

    return [
      for (final r in rows)
        Community.fromJson(Map<String, dynamic>.from(r as Map),
            isMember: memberIds.contains(r['id']))
    ];
  }

  Future<List<CommunityPost>> fetchPosts(String communityId,
      {String? petId}) async {
    final rows = await _client
        .from('community_posts')
        .select(_postSelect)
        .eq('community_id', communityId)
        .order('created_at', ascending: false)
        .limit(30);

    Set<String> likedIds = {};
    if (petId != null) {
      final likes = await _client
          .from('community_post_likes')
          .select('post_id')
          .eq('pet_id', petId);
      likedIds = {for (final l in likes) l['post_id'] as String};
    }

    return [
      for (final r in rows)
        CommunityPost.fromJson(Map<String, dynamic>.from(r as Map),
            isLiked: likedIds.contains(r['id']))
    ];
  }

  Future<void> join(String communityId, String petId) async {
    await _client.from('community_members').upsert({
      'community_id': communityId,
      'pet_id': petId,
    });
  }

  Future<void> leave(String communityId, String petId) async {
    await _client
        .from('community_members')
        .delete()
        .eq('community_id', communityId)
        .eq('pet_id', petId);
  }

  Future<Community> createCommunity({
    required String name,
    required String creatorPetId,
    String? description,
    String? speciesFilter,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in to create a community');
    }

    final row = await _client
        .from('communities')
        .insert({
          'name': name.trim(),
          'created_by': userId,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          if (speciesFilter != null && speciesFilter.isNotEmpty)
            'species_filter': speciesFilter,
        })
        .select()
        .single();

    final communityId = row['id'] as String;
    await join(communityId, creatorPetId);

    final updated = await _client
        .from('communities')
        .select()
        .eq('id', communityId)
        .single();

    return Community.fromJson(
      Map<String, dynamic>.from(updated),
      isMember: true,
    );
  }

  Future<CommunityPost> createPost({
    required String communityId,
    required String authorPetId,
    required String content,
    String? imageUrl,
  }) async {
    final row = await _client
        .from('community_posts')
        .insert({
          'community_id': communityId,
          'author_pet_id': authorPetId,
          'content': content,
          if (imageUrl != null) 'image_url': imageUrl, // ignore: use_null_aware_elements
        })
        .select(_postSelect)
        .single();
    return CommunityPost.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> likePost(String postId, String petId) async {
    await _client
        .from('community_post_likes')
        .upsert({'post_id': postId, 'pet_id': petId});
  }

  Future<void> unlikePost(String postId, String petId) async {
    await _client
        .from('community_post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('pet_id', petId);
  }
}
