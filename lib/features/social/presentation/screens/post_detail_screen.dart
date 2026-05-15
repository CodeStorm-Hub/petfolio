import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/comment.dart';
import '../../data/models/feed_post.dart';
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
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
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
      await ref
          .read(commentListProvider(widget.postId).notifier)
          .add(petId: activePet.id, content: text);
      
      _commentController.clear();
      
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
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              )),
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
        title: Row(
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
                      style: GoogleFonts.sora(
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
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
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
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
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
                  data: (list) => list.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 32, horizontal: 16),
                            child: Text(
                              'No comments yet. Be the first!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: pt.ink500, fontSize: 14),
                            ),
                          ),
                        )
                      : SliverList.builder(
                          itemCount: list.length,
                          itemBuilder: (ctx, i) => _CommentTile(
                            comment: list[i],
                            postId: widget.postId,
                          ),
                        ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),

          // ── Fixed comment input bar ─────────────────────────────────────
          _CommentInputBar(
            controller: _commentController,
            isSending: _isSending,
            onSend: _sendComment,
            pt: pt,
            autofocus: widget.autofocusComment,
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
        aspectRatio: 1,
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
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: post.imageUrls.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => CachedNetworkImage(
              imageUrl: post.imageUrls[i],
              fit: BoxFit.cover,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: post.petName,
              style: GoogleFonts.sora(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            TextSpan(text: '  '),
            TextSpan(
              text: post.caption,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
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
              post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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

// ─────────────────────────────────────────────────────────────────────────────
// Comment tile
// ─────────────────────────────────────────────────────────────────────────────

class _CommentTile extends ConsumerWidget {
  const _CommentTile({required this.comment, required this.postId});
  final Comment comment;
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.coral500.withAlpha(200),
            backgroundImage: comment.avatarUrl != null
                ? CachedNetworkImageProvider(comment.avatarUrl!)
                : null,
            child: comment.avatarUrl == null
                ? Text(
                    comment.petName.isNotEmpty
                        ? comment.petName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.petName,
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      comment.timeAgo,
                      style: tt.labelSmall?.copyWith(color: pt.ink500),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: tt.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          // Delete button (only for own comments)
          if (comment.isOwnComment)
            GestureDetector(
              onTap: () => ref
                  .read(commentListProvider(postId).notifier)
                  .delete(comment.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.close_rounded, size: 16, color: pt.ink300),
              ),
            ),
        ],
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
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final PetfolioThemeExtension pt;
  final bool autofocus;

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
                  hintText: 'Add a comment...',
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
                onTap: () => Navigator.pop(context),
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
}
