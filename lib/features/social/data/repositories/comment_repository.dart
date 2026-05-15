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
        .select('id, post_id, pet_id, content, created_at, pet:pets(name)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (rows as List)
        .map((row) => Comment.fromJson(
              row as Map<String, dynamic>,
              activePetId: activePetId,
            ))
        .toList();
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
  }) async {
    final row = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'author_id': _uid,
          'pet_id': petId,
          'content': content.trim(),
        })
        .select('id, post_id, pet_id, content, created_at, pet:pets(name)')
        .single();

    return Comment.fromJson(row, activePetId: activePetId);
  }

  /// Deletes a comment by [commentId].
  ///
  /// The RLS policy ensures only the comment's author can delete it.
  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }
}
