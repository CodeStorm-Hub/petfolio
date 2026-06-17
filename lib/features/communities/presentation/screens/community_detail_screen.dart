import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_ago.dart' show formatTimeAgo;
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/petfolio_empty_state.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/models/community.dart';
import '../../data/models/community_post.dart';
import '../controllers/communities_controller.dart';

export '../controllers/communities_controller.dart'
    show communityPostsProvider, setActiveCommunity, PostsState;

class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({super.key, required this.community});
  final Community community;

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState
    extends ConsumerState<CommunityDetailScreen> {
  final _postCtrl = TextEditingController();
  bool _composerVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setActiveCommunity(ref, widget.community.id);
    });
  }

  @override
  void dispose() {
    _postCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _postCtrl.text.trim();
    if (text.isEmpty) return;
    _postCtrl.clear();
    setState(() => _composerVisible = false);
    try {
      await ref.read(communityPostsProvider.notifier).createPost(text);
    } catch (e) {
      if (mounted) AppSnackBar.showError('Could not post. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsState = ref.watch(communityPostsProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.community.name),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'New post',
            icon: Icon(
              Icons.add_rounded,
              color: AppColors.lilac,
            ),
            onPressed: () =>
                setState(() => _composerVisible = !_composerVisible),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_composerVisible) _PostComposer(ctrl: _postCtrl, onSubmit: _submit, pt: pt),
          Expanded(
            child: _buildFeed(postsState, pt, tt),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(
      PostsState postsState, PetfolioThemeExtension pt, TextTheme tt) {
    if (postsState.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) =>
              const SkeletonLoader(width: double.infinity, height: 100),
      );
    }
    if (postsState.error != null) {
      return PetfolioEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load posts',
        subtitle: 'Pull to refresh or tap retry.',
        action: PrimaryPillButton(
          label: 'Retry',
          onPressed: () =>
              ref.read(communityPostsProvider.notifier).reload(),
        ),
      );
    }
    final posts = postsState.posts;
    if (posts.isEmpty) {
      return const PetfolioEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No posts yet',
        subtitle: 'Start the conversation!',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _PostCard(post: posts[i]),
    );
  }
}

class _PostComposer extends StatelessWidget {
  const _PostComposer({
    required this.ctrl,
    required this.onSubmit,
    required this.pt,
  });
  final TextEditingController ctrl;
  final VoidCallback onSubmit;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: pt.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: 4,
              minLines: 2,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Share something with the community…',
                hintStyle: TextStyle(color: pt.ink300),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pt.line),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lilac,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});
  final CommunityPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pt.line, width: 1),
        boxShadow: pt.shadowE1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PetAvatar(avatarUrl: post.authorAvatarUrl),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorPetName ?? 'Unknown',
                        style: tt.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      formatTimeAgo(post.createdAt),
                      style: tt.labelSmall?.copyWith(color: pt.ink300),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.content, style: tt.bodyMedium),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Semantics(
                label: post.isLiked ? 'Unlike post' : 'Like post',
                button: true,
                child: GestureDetector(
                onTap: () => ref
                    .read(communityPostsProvider.notifier)
                    .toggleLike(post),
                child: Row(
                  children: [
                    Icon(
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: post.isLiked ? AppColors.poppy : pt.ink300,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: tt.labelSmall?.copyWith(
                          color: post.isLiked ? AppColors.poppy : pt.ink300),
                    ),
                  ],
                ),
              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({this.avatarUrl});
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.lilac.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.pets_rounded,
          size: 16, color: AppColors.lilac),
    );
  }
}
