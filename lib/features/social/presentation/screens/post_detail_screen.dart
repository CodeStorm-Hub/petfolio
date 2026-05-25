import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/comment.dart';
import '../../data/models/feed_post.dart';
import '../../data/repositories/social_repository.dart';
import '../controllers/comment_controller.dart';
import '../controllers/social_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen view for a single post, showing:
///   - The image (or gradient blob) in a carousel if multiple images.
///   - The full, un-truncated caption.
///   - A scrollable comment thread.
///   - A fixed comment input bar at the bottom.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.postId,
    this.post, // optional pre-loaded post passed via router extra
    this.autofocusComment = false,
  });

  final String postId;
  final FeedPost? post;
  final bool autofocusComment;


  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _commentFocusNode = FocusNode();
  Comment? _replyingToComment;
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    final activePet = ref.read(activePetControllerProvider);
    if (activePet == null) return;

    setState(() => _isSending = true);

    try {
      final parentId = _replyingToComment?.parentId ?? _replyingToComment?.id;
      await ref
          .read(commentListProvider(widget.postId).notifier)
          .add(
            petId: activePet.id,
            content: text,
            parentId: parentId,
          );
      
      _commentController.clear();
      setState(() => _replyingToComment = null);
      
      // Scroll to the bottom after posting.
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: ${e.toString()}'),
            backgroundColor: AppColors.coral500,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final comments = ref.watch(commentListProvider(widget.postId));

    // Try to get the post from the feed provider first (for real-time updates).
    final feedPost = ref.watch(postProvider(widget.postId));
    
    // If the feed has it, use it. Otherwise, use the one passed via extra or fetch it.
    final postAsync = feedPost != null
        ? AsyncValue.data(feedPost)
        : (widget.post != null
            ? AsyncValue.data(widget.post!)
            : ref.watch(postDetailProvider(widget.postId)));

    // Show a full-screen spinner while the post is loading from the network.
    if (postAsync.isLoading) {
      return Scaffold(
        backgroundColor: pt.surface1,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
          title: Text('Post',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (postAsync.hasError) {
      return Scaffold(
        backgroundColor: pt.surface1,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Failed to load post.')),
      );
    }

    final post = postAsync.value!;

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () => context.push('/social/profile/${post.petId}'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: post.accentColor,
                backgroundImage: post.petAvatarUrl != null
                    ? CachedNetworkImageProvider(post.petAvatarUrl!)
                    : null,
                child: post.petAvatarUrl == null
                    ? Text(
                        post.petName.isNotEmpty ? post.petName[0].toUpperCase() : '?',
                        style: tt.headlineSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                post.petName,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: pt.ink500),
            onPressed: () => _showPostOptions(context, post),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Post image
                SliverToBoxAdapter(child: _PostImages(post: post)),

                // Caption
                if (post.caption.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _Caption(post: post, pt: pt),
                  ),

                // Likes & stats bar
                SliverToBoxAdapter(
                  child: _StatsBar(post: post, pt: pt, postId: widget.postId),
                ),

                // Comments header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Comments',
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                // Comment list
                comments.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Failed to load comments',
                          style: TextStyle(color: pt.ink500),
                        ),
                      ),
                    ),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 32, horizontal: 16),
                          child: Text(
                            'No comments yet. Be the first!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: pt.ink500, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    // Pre-group replies by parentId for O(n) thread building
                    final repliesByParentId = <String, List<Comment>>{};
                    for (final c in list) {
                      if (c.parentId != null) {
                        repliesByParentId.putIfAbsent(c.parentId!, () => []).add(c);
                      }
                    }
                    final rootComments = list.where((c) => c.parentId == null).toList();
                    final displayList = <_CommentDisplayItem>[];
                    for (final root in rootComments) {
                      displayList.add(_CommentDisplayItem(comment: root, isReply: false));
                      for (final reply in repliesByParentId[root.id] ?? const <Comment>[]) {
                        displayList.add(_CommentDisplayItem(comment: reply, isReply: true));
                      }
                    }

                    return SliverList.builder(
                      itemCount: displayList.length,
                      itemBuilder: (ctx, i) {
                        final item = displayList[i];
                        return _CommentTile(
                          key: ValueKey(item.comment.id),
                          comment: item.comment,
                          postId: widget.postId,
                          isReply: item.isReply,
                          onReplyTap: (c) {
                            setState(() {
                              _replyingToComment = c;
                            });
                            _commentFocusNode.requestFocus();
                          },
                        );
                      },
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),

          // ── Fixed comment input bar with Replying Banner ──────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_replyingToComment != null)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(top: BorderSide(color: pt.line200)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Replying to ${_replyingToComment!.handle}',
                          style: tt.bodySmall?.copyWith(
                            color: pt.ink500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _replyingToComment = null),
                        child: Icon(Icons.close_rounded, size: 16, color: pt.ink300),
                      ),
                    ],
                  ),
                ),
              _CommentInputBar(
                controller: _commentController,
                focusNode: _commentFocusNode,
                isSending: _isSending,
                onSend: _sendComment,
                pt: pt,
                autofocus: widget.autofocusComment,
                replyingToHandle: _replyingToComment?.handle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostOptions(BuildContext context, FeedPost post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PostOptionsSheet(post: post),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Images (carousel for multiple, single image for one)
// ─────────────────────────────────────────────────────────────────────────────

class _PostImages extends StatefulWidget {
  const _PostImages({required this.post});
  final FeedPost post;

  @override
  State<_PostImages> createState() => _PostImagesState();
}

class _PostImagesState extends State<_PostImages> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final colors = post.gradientColors;

    if (post.imageUrls.isEmpty) {
      // Fallback: gradient blob
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors.length >= 2 ? colors : [colors.first, colors.first],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: PageView.builder(
            itemCount: post.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => CachedNetworkImage(
              imageUrl: post.imageUrls[i],
              fit: BoxFit.cover,
              memCacheWidth: 800, // Slightly higher for detail view
              maxWidthDiskCache: 1200,
              placeholder: (ctx, _) => Container(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
        // Page indicator dots
        if (post.imageUrls.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                post.imageUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPage ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? Colors.white
                        : Colors.white.withAlpha(120),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Caption
// ─────────────────────────────────────────────────────────────────────────────

class _Caption extends StatelessWidget {
  const _Caption({required this.post, required this.pt});
  final FeedPost post;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        post.caption,
        style: tt.bodySmall?.copyWith(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats bar (likes + comment count + like button)
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends ConsumerWidget {
  const _StatsBar({required this.post, required this.pt, required this.postId});
  final FeedPost post;
  final PetfolioThemeExtension pt;
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: [
          // Like button
          IconButton(
            icon: Icon(
              post.isLiked ? Icons.pets_rounded : Icons.pets_outlined,
              color: post.isLiked ? AppColors.coral500 : pt.ink500,
            ),
            onPressed: () {
              final activePet = ref.read(activePetControllerProvider);
              if (activePet == null) return;
              ref
                  .read(socialControllerProvider(activePet.id).notifier)
                  .toggleLike(postId);
            },
          ),
          Text(
            '${post.likes}',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 16),
          Icon(Icons.chat_bubble_outline_rounded, size: 22, color: pt.ink500),
          const SizedBox(width: 6),
          Text(
            '${post.comments}',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            post.timeAgo,
            style: tt.labelSmall?.copyWith(color: pt.ink500),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _CommentDisplayItem {
  const _CommentDisplayItem({required this.comment, required this.isReply});
  final Comment comment;
  final bool isReply;
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment tile
// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends ConsumerWidget {
  const _CommentTile({
    super.key,
    required this.comment,
    required this.postId,
    this.isReply = false,
    this.onReplyTap,
  });

  final Comment comment;
  final String postId;
  final bool isReply;
  final ValueChanged<Comment>? onReplyTap;

  // ── Context menu ───────────────────────────────────────────────────────────

  /// Shows the owner context menu on long-press.
  /// Silently returns if the comment belongs to another pet.
  void _showContextMenu(BuildContext context, WidgetRef ref) {
    if (!comment.isOwnComment) return;

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Preview of the comment text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  comment.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Edit action
              ListTile(
                leading: Icon(Icons.edit_rounded, color: cs.onSurface),
                title: Text(
                  'Edit Comment',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  // Small delay so the first sheet is fully dismissed first.
                  Future.delayed(const Duration(milliseconds: 120), () {
                    if (context.mounted) _showEditSheet(context, ref);
                  });
                },
              ),
              // Delete action
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.coral500),
                title: Text(
                  'Delete Comment',
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.coral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  ref
                      .read(commentListProvider(postId).notifier)
                      .delete(comment.id);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Opens an edit bottom sheet pre-filled with the current comment text.
  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final editController = TextEditingController(text: comment.content);

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true, // allows sheet to grow with keyboard
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withAlpha(60),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Edit Comment',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editController,
                    autofocus: true,
                    maxLines: 5,
                    minLines: 1,
                    style: tt.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Update your comment…',
                      hintStyle: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.coral500,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final newText = editController.text.trim();
                      if (newText.isEmpty) return;
                      Navigator.of(sheetCtx).pop();
                      ref
                          .read(commentListProvider(postId).notifier)
                          .edit(comment.id, newText);
                    },
                    child: Text(
                      'Save',
                      style: tt.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => editController.dispose());
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showContextMenu(context, ref),
      child: Padding(
        padding: EdgeInsets.only(
          left: isReply ? 52.0 : 16.0,
          right: 8.0,
          top: 8.0,
          bottom: 8.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tappable avatar → pet social profile
            GestureDetector(
              onTap: () => context.push('/social/profile/${comment.petId}'),
              child: CircleAvatar(
                radius: isReply ? 12 : 16,
                backgroundColor: AppColors.coral500.withAlpha(200),
                backgroundImage: comment.avatarUrl != null
                    ? CachedNetworkImageProvider(comment.avatarUrl!)
                    : null,
                child: comment.avatarUrl == null
                    ? Text(
                        comment.petName.isNotEmpty
                            ? comment.petName[0].toUpperCase()
                            : '?',
                        style: tt.titleSmall?.copyWith(
                          fontSize: isReply ? 9 : 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Tappable pet name → pet social profile
                      GestureDetector(
                        onTap: () =>
                            context.push('/social/profile/${comment.petId}'),
                        child: Text(
                          comment.petName,
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        comment.timeAgo,
                        style: tt.labelSmall?.copyWith(color: pt.ink500),
                      ),
                      // "• edited" hint for visual feedback after an edit
                      if (comment.isOwnComment) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· hold to edit',
                          style: tt.labelSmall?.copyWith(
                            color: pt.ink500.withAlpha(120),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.content,
                    style: tt.bodySmall?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  // Actions row — like count + Reply link only
                  Row(
                    children: [
                      if (comment.likeCount > 0) ...[
                        Text(
                          '${comment.likeCount} ${comment.likeCount == 1 ? 'like' : 'likes'}',
                          style: tt.labelSmall?.copyWith(
                            color: pt.ink500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      GestureDetector(
                        onTap: () => onReplyTap?.call(comment),
                        child: Text(
                          'Reply',
                          style: tt.labelSmall?.copyWith(
                            color: pt.ink500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Like button (paw icon) on the right
            IconButton(
              icon: Icon(
                comment.isLiked ? Icons.pets_rounded : Icons.pets_outlined,
                size: 16,
                color: comment.isLiked ? AppColors.coral500 : pt.ink300,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              onPressed: () {
                ref
                    .read(commentListProvider(postId).notifier)
                    .toggleLike(comment.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Comment input bar (fixed at bottom)

// ─────────────────────────────────────────────────────────────────────────────

class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.pt,
    this.autofocus = false,
    this.focusNode,
    this.replyingToHandle,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final PetfolioThemeExtension pt;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? replyingToHandle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: pt.line200)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: pt.surface1,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: pt.line200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: autofocus,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: replyingToHandle != null
                      ? 'Reply to $replyingToHandle...'
                      : 'Add a comment...',
                  hintStyle: TextStyle(color: pt.ink300, fontSize: 14),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSending
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    key: const ValueKey('send'),
                    icon: Icon(
                      Icons.send_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: onSend,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post options bottom sheet (Edit / Delete / Report)
// ─────────────────────────────────────────────────────────────────────────────

class _PostOptionsSheet extends ConsumerWidget {
  const _PostOptionsSheet({required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.read(activePetControllerProvider);
    final isOwnPost = activePet?.id == post.petId;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwnPost) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Caption'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context, ref, post);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.coral500),
                title: Text('Delete Post',
                    style: TextStyle(color: AppColors.coral500)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, post);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report Post'),
                onTap: () {
                  final repo = ref.read(socialRepositoryProvider);
                  Navigator.pop(context);
                  _showReportDialog(context, repo, post);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, FeedPost post) {
    final ctrl = TextEditingController(text: post.caption);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final activePet = ref.read(activePetControllerProvider);
              if (activePet == null) return;
              ref
                  .read(socialControllerProvider(activePet.id).notifier)
                  .updateCaption(post.id, ctrl.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FeedPost post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content:
            const Text('This will permanently delete your post. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral500),
            onPressed: () async {
              Navigator.pop(ctx);
              final activePet = ref.read(activePetControllerProvider);
              if (activePet == null) return;
              await ref
                  .read(socialControllerProvider(activePet.id).notifier)
                  .deletePost(post.id);
              if (context.mounted) context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(
    BuildContext context,
    SocialRepository repo,
    FeedPost post,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _ReportPostDialog(repo: repo, post: post),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Post dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ReportPostDialog extends StatefulWidget {
  const _ReportPostDialog({required this.repo, required this.post});
  final SocialRepository repo;
  final FeedPost post;

  @override
  State<_ReportPostDialog> createState() => _ReportPostDialogState();
}

class _ReportPostDialogState extends State<_ReportPostDialog> {
  static const _reasons = [
    'Spam or misleading',
    'Inappropriate content',
    'Harassment or bullying',
    'Animal abuse or neglect',
    'Other',
  ];

  String? _selected;
  bool _loading = false;

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      await widget.repo.reportPost(
        postId: widget.post.id,
        reason: _selected!,
      );
      if (mounted) Navigator.pop(context);
      AppSnackBar.show('Report submitted. Thank you.');
    } on AppException catch (e) {
      if (mounted) Navigator.pop(context);
      AppSnackBar.showError(e);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      AppSnackBar.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Post'),
      content: SingleChildScrollView(
        child: RadioGroup<String>(
          groupValue: _selected,
          onChanged: (v) { if (!_loading) setState(() => _selected = v); },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _reasons
                .map(
                  (r) => RadioListTile<String>(
                    value: r,
                    title: Text(r),
                    contentPadding: EdgeInsets.zero,
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_selected == null || _loading) ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
