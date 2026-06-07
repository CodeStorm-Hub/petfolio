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
        .select('*, pets(name, avatar_url)')
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
        .select('*, pets(name, avatar_url)')
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
