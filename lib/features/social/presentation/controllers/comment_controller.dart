import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/comment.dart';
import '../../data/repositories/comment_repository.dart';
import 'social_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the comment list for a given post, keyed by [postId].
///
/// Auto-disposes when the PostDetailScreen is closed, freeing memory.
final commentListProvider =
    AsyncNotifierProvider.family<CommentNotifier, List<Comment>, String>(
  CommentNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the comment list for a single post (identified by [arg] = postId).
///
/// Optimistic UI pattern on [delete]:
///   1. Snapshot current state.
///   2. Remove comment locally — UI updates instantly.
///   3. Await Supabase delete — on error, restore snapshot.
///
/// [add] is non-optimistic because we need the server-generated
/// timestamp and ID to display the comment correctly.
class CommentNotifier extends AsyncNotifier<List<Comment>> {
  CommentNotifier(this.arg);
  final String arg;

  @override
  Future<List<Comment>> build() {
    final activePetId = ref.read(activePetControllerProvider)?.id ?? '';
    return _repo.fetchComments(postId: arg, activePetId: activePetId);
  }

  CommentRepository get _repo => ref.read(commentRepositoryProvider);

  String get _activePetId =>
      ref.read(activePetControllerProvider)?.id ?? '';

  // ── Public actions ────────────────────────────────────────────────────────

  /// Submits a new comment and appends it to the local list on success.
  Future<void> add({required String petId, required String content}) async {
    if (content.trim().isEmpty) return;

    final previousComments = state.value ?? [];
    state = const AsyncLoading();

    try {
      final newComment = await _repo.addComment(
        postId: arg,
        petId: petId,
        content: content,
        activePetId: petId, // the new comment is always "own"
      );

      state = AsyncData([...previousComments, newComment]);
      
      // Optimistically update the parent feed's comment count
      ref.read(socialControllerProvider(petId).notifier).incrementCommentCount(arg);
    } catch (e) {
      // Restore previous state so the list doesn't disappear on error.
      state = AsyncData(previousComments);
      // Re-throw so the UI can show a snackbar or alert.
      rethrow;
    }
  }

  /// Deletes a comment with optimistic removal from the list.
  Future<void> delete(String commentId) async {
    final prev = state.value;
    if (prev == null) return;

    // 1. Optimistic remove.
    state = AsyncData(prev.where((c) => c.id != commentId).toList());

    try {
      // 2. Background delete.
      await _repo.deleteComment(commentId);
      
      // Optimistically update the parent feed's comment count
      final activePetId = ref.read(activePetControllerProvider)?.id;
      if (activePetId != null) {
        ref.read(socialControllerProvider(activePetId).notifier).decrementCommentCount(arg);
      }
    } catch (_) {
      // 3. Rollback on failure.
      state = AsyncData(prev);
    }
  }

  /// Re-fetches comments from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await _repo.fetchComments(postId: arg, activePetId: _activePetId),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
