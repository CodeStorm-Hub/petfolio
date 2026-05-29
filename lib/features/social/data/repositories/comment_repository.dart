import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/comment.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(Supabase.instance.client),
);

/// Repository for post comments.
///
/// All methods are thin wrappers around Supabase calls.
/// Business logic and state management live in [CommentNotifier].
///
/// [addComment] and [deleteComment] throw on failure so the controller
/// can roll back its optimistic UI update.
class CommentRepository {
  CommentRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Not authenticated');
    return id;
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Fetches all comments for [postId], ordered oldest-first.
  ///
  /// Joins the `pets` table to get the commenter's handle and name.
  Future<List<Comment>> fetchComments({
    required String postId,
    required String activePetId,
  }) async {
    final rows = await _client
        .from('comments')
        .select('id, post_id, pet_id, content, created_at, parent_id, like_count, pet:pets(name, handle, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final comments = (rows as List).cast<Map<String, dynamic>>();

    var likedIds = const <String>{};
    if (activePetId.isNotEmpty && comments.isNotEmpty) {
      final commentIds = comments.map((r) => r['id'] as String).toList();
      likedIds = await _fetchLikedCommentIds(activePetId, commentIds);
    }

    return comments
        .map((row) => Comment.fromJson(
              row,
              activePetId: activePetId,
              isLiked: likedIds.contains(row['id'] as String),
            ))
        .toList();
  }

  Future<Set<String>> _fetchLikedCommentIds(
    String petId,
    List<String> commentIds,
  ) async {
    if (commentIds.isEmpty) return const {};
    final rows = await _client
        .from('comment_likes')
        .select('comment_id')
        .eq('pet_id', petId)
        .inFilter('comment_id', commentIds);
    return {for (final r in (rows as List)) r['comment_id'] as String};
  }

  // ── Write ────────────────────────────────────────────────────────────────

  /// Inserts a new comment. Returns the newly created [Comment].
  ///
  /// Throws [PostgrestException] on failure.
  Future<Comment> addComment({
    required String postId,
    required String petId,
    required String content,
    required String activePetId,
    String? parentId,
  }) async {
    final row = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'author_id': _uid,
          'pet_id': petId,
          'content': content.trim(),
          'parent_id': parentId,
        })
        .select('id, post_id, pet_id, content, created_at, parent_id, like_count, pet:pets(name, handle, avatar_url)')
        .single();

    return Comment.fromJson(row, activePetId: activePetId);
  }

  /// Likes or unlikes a comment.
  Future<void> toggleCommentLike({
    required String commentId,
    required String petId,
    required bool liked,
  }) async {
    if (liked) {
      await _client.from('comment_likes').upsert({
        'comment_id': commentId,
        'pet_id': petId,
        'user_id': _uid,
      }, onConflict: 'comment_id, pet_id');
    } else {
      await _client
          .from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('pet_id', petId);
    }
  }

  /// Deletes a comment by [commentId].
  ///
  /// The RLS policy ensures only the comment's author can delete it.
  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  /// Updates the [content] of an existing comment.
  ///
  /// The RLS policy (`author_id = auth.uid()`) enforces ownership server-side,
  /// so no client-side guard is needed.
  Future<void> updateComment(String commentId, String newContent) async {
    await _client
        .from('comments')
        .update({'content': newContent.trim()})
        .eq('id', commentId);
  }
}
