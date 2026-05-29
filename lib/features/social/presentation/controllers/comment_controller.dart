import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/comment.dart';
import '../../data/repositories/comment_repository.dart';
import 'social_controller.dart';

part 'comment_controller.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the comment list for a single post (identified by [postId]).
///
/// Optimistic UI pattern on [delete] and [toggleLike].
///
/// [add] is non-optimistic because we need the server-generated
/// timestamp and ID to display the comment correctly.
@riverpod
class CommentList extends _$CommentList {
  @override
  FutureOr<List<Comment>> build(String postId) {
    final activePetId = ref.read(activePetControllerProvider)?.id ?? '';
    return ref.read(commentRepositoryProvider).fetchComments(postId: postId, activePetId: activePetId);
  }

  CommentRepository get _repo => ref.read(commentRepositoryProvider);

  String get _activePetId =>
      ref.read(activePetControllerProvider)?.id ?? '';

  // ── Public actions ────────────────────────────────────────────────────────

  /// Submits a new comment (optionally a reply under [parentId]) and appends it to the local list on success.
  Future<void> add({
    required String petId,
    required String content,
    String? parentId,
  }) async {
    if (content.trim().isEmpty) return;

    final previousComments = state.value ?? [];
    state = const AsyncLoading();

    try {
      final newComment = await _repo.addComment(
        postId: postId,
        petId: petId,
        content: content,
        activePetId: petId, // the new comment is always "own"
        parentId: parentId,
      );

      state = AsyncData([...previousComments, newComment]);
      
      // Optimistically update the parent feed's comment count
      ref.read(socialControllerProvider(petId).notifier).incrementCommentCount(postId);
      
      // Invalidate the post detail cache to refresh stats if loaded standalone
      ref.invalidate(postDetailProvider(postId));
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
        ref.read(socialControllerProvider(activePetId).notifier).decrementCommentCount(postId);
      }
      
      // Invalidate the post detail cache to refresh stats if loaded standalone
      ref.invalidate(postDetailProvider(postId));
    } catch (e) {
      // 3. Rollback on failure.
      state = AsyncData(prev);
      AppSnackBar.showError(e);
    }
  }

  /// Edits the content of a comment with an optimistic text swap.
  ///
  /// Rolls back to the previous text and shows a snackbar on failure.
  /// No-op when [newContent] is blank.
  Future<void> edit(String commentId, String newContent) async {
    final prev = state.value;
    if (prev == null || newContent.trim().isEmpty) return;

    // Optimistic content swap — no AsyncLoading so the list doesn't flicker.
    final updated = prev
        .map((c) => c.id == commentId ? c.copyWithContent(newContent.trim()) : c)
        .toList();
    state = AsyncData(updated);

    try {
      await _repo.updateComment(commentId, newContent);
    } catch (e) {
      // Rollback on failure.
      state = AsyncData(prev);
      AppSnackBar.showError(e);
    }
  }

  /// Likes or unlikes a comment with optimistic feedback.
  Future<void> toggleLike(String commentId) async {
    final prev = state.value;
    if (prev == null) return;

    final activePetId = ref.read(activePetControllerProvider)?.id;
    if (activePetId == null || activePetId.isEmpty) return;

    final idx = prev.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;

    final comment = prev[idx];
    final nowLiked = !comment.isLiked;

    // Optimistic toggle
    final updated = List<Comment>.from(prev)
      ..[idx] = comment.copyWithLike(liked: nowLiked);
    state = AsyncData(updated);

    try {
      await _repo.toggleCommentLike(
        commentId: commentId,
        petId: activePetId,
        liked: nowLiked,
      );
    } catch (e) {
      // Rollback on failure
      state = AsyncData(prev);
      AppSnackBar.showError(e);
    }
  }

  /// Re-fetches comments from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await _repo.fetchComments(postId: postId, activePetId: _activePetId),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
