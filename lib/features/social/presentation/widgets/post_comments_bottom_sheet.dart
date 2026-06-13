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
import '../controllers/comment_controller.dart';

class PostCommentsBottomSheet extends ConsumerStatefulWidget {
  const PostCommentsBottomSheet({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<PostCommentsBottomSheet> createState() => _PostCommentsBottomSheetState();
}

class _PostCommentsBottomSheetState extends ConsumerState<PostCommentsBottomSheet> {
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  final _scrollController = ScrollController();
  Comment? _replyingToComment;
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    final activePet = ref.read(activePetControllerProvider);
    if (activePet == null) {
      AppSnackBar.showError(const ValidationException(message: 'Please select an active pet to comment.'));
      return;
    }

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
      
      // Scroll to bottom after adding a comment
      if (_scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } on AppException catch (e) {
      AppSnackBar.showError(e);
    } catch (e) {
      AppSnackBar.showError(ValidationException(message: e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final commentsAsync = ref.watch(commentListProvider(widget.postId));

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drag handle and header
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comments',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable comments list
            Expanded(
              child: commentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Failed to load comments',
                      style: TextStyle(color: pt.ink500),
                    ),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No comments yet. Be the first!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: pt.ink500, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  // Group replies by parentId
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

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: displayList.length,
                    itemBuilder: (ctx, i) {
                      final item = displayList[i];
                      return _CommentTile(
                        key: ValueKey(item.comment.id),
                        comment: item.comment,
                        postId: widget.postId,
                        parentContext: context,
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
            ),

            // Fixed input bar at bottom
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingToComment != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(top: BorderSide(color: pt.line)),
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
                  replyingToHandle: _replyingToComment?.handle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentDisplayItem {
  const _CommentDisplayItem({required this.comment, required this.isReply});
  final Comment comment;
  final bool isReply;
}

class _CommentTile extends ConsumerWidget {
  const _CommentTile({
    super.key,
    required this.comment,
    required this.postId,
    required this.parentContext,
    this.isReply = false,
    this.onReplyTap,
  });

  final Comment comment;
  final String postId;
  final BuildContext parentContext;
  final bool isReply;
  final ValueChanged<Comment>? onReplyTap;

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    if (!comment.isOwnComment) return;

    final tt = Theme.of(parentContext).textTheme;
    final cs = Theme.of(parentContext).colorScheme;

    showModalBottomSheet<void>(
      context: parentContext,
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
              ListTile(
                leading: Icon(Icons.edit_rounded, color: cs.onSurface),
                title: Text(
                  'Edit Comment',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  final ctx = parentContext;
                  Future.delayed(const Duration(milliseconds: 120), () {
                    if (ctx.mounted) {
                      _showEditSheet(ctx, ref);
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.coral500),
                title: Text(
                  'Delete Comment',
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.coral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  ref.read(commentListProvider(postId).notifier).delete(comment.id);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return _EditCommentSheet(
          comment: comment,
          postId: postId,
        );
      },
    );
  }

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
                        comment.petName.isNotEmpty ? comment.petName[0].toUpperCase() : '?',
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: GestureDetector(
                          onTap: () => context.push('/social/profile/${comment.petId}'),
                          child: Text(
                            comment.petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        comment.timeAgo,
                        style: tt.labelSmall?.copyWith(color: pt.ink500),
                      ),
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
                ref.read(commentListProvider(postId).notifier).toggleLike(comment.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentInputBar extends StatefulWidget {
  const _CommentInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.pt,
    this.focusNode,
    this.replyingToHandle,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final PetfolioThemeExtension pt;
  final FocusNode? focusNode;
  final String? replyingToHandle;

  @override
  State<_CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<_CommentInputBar> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(covariant _CommentInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pt = widget.pt;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: pt.line.withAlpha(180))),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isFocused ? Theme.of(context).colorScheme.surface : pt.surface1,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isFocused ? primary : pt.line,
                  width: _isFocused ? 1.5 : 1.0,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: primary.withAlpha(20),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Semantics(
                textField: true,
                label: widget.replyingToHandle != null
                    ? 'Reply to ${widget.replyingToHandle}'
                    : 'Add a comment',
                child: TextField(
                key: const ValueKey<String>('social_comment_input'),
                controller: widget.controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  hintText: widget.replyingToHandle != null
                      ? 'Reply to ${widget.replyingToHandle}...'
                      : 'Add a comment...',
                  hintStyle: TextStyle(color: pt.ink300, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.isSending
                ? const SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.coral500),
                      ),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('send'),
                    onTap: widget.onSend,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: widget.controller.text.trim().isNotEmpty
                            ? primary
                            : pt.surface2,
                        shape: BoxShape.circle,
                        boxShadow: widget.controller.text.trim().isNotEmpty
                            ? [
                                BoxShadow(
                                  color: primary.withAlpha(50),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: widget.controller.text.trim().isNotEmpty
                            ? Colors.white
                            : pt.ink300,
                        size: 20,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EditCommentSheet extends ConsumerStatefulWidget {
  const _EditCommentSheet({
    required this.comment,
    required this.postId,
  });

  final Comment comment;
  final String postId;

  @override
  ConsumerState<_EditCommentSheet> createState() => _EditCommentSheetState();
}

class _EditCommentSheetState extends ConsumerState<_EditCommentSheet> {
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            controller: _editController,
            autofocus: true,
            maxLines: 5,
            minLines: 1,
            style: tt.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Update your comment…',
              hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              final newText = _editController.text.trim();
              if (newText.isEmpty) return;
              Navigator.of(context).pop();
              ref.read(commentListProvider(widget.postId).notifier).edit(widget.comment.id, newText);
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
  }
}
