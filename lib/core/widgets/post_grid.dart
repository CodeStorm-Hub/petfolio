import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/social/data/models/feed_post.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'skeleton_loader.dart';

class PostGrid extends ConsumerWidget {
  const PostGrid({
    super.key,
    required this.postsAsync,
    required this.onTap,
    this.onLoadMore,
  });

  final AsyncValue<List<FeedPost>> postsAsync;
  final void Function(FeedPost post) onTap;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return postsAsync.when(
      loading: () => SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: 9,
        itemBuilder: (_, _) => const SkeletonLoader.imageBanner(bannerHeight: double.infinity),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(
          child: Text('$e', style: TextStyle(color: pt.ink500)),
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return const SliverFillRemaining(child: _EmptyPostGrid());
        }
        return SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            if (onLoadMore != null && i == posts.length - 3) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore!());
            }
            return _PostThumbnail(post: posts[i], onTap: () => onTap(posts[i]));
          },
        );
      },
    );
  }
}

class _PostThumbnail extends StatelessWidget {
  const _PostThumbnail({required this.post, required this.onTap});

  final FeedPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;

    return Semantics(
      label: post.caption.isNotEmpty ? post.caption : 'Post by ${post.petName}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => const SkeletonLoader.imageBanner(bannerHeight: double.infinity),
                errorWidget: (_, _, _) => _GradientFallback(post: post),
              )
            else
              _GradientFallback(post: post),
            if (post.isCarousel)
              const Positioned(
                top: 6,
                right: 6,
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  const _GradientFallback({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final colors = post.gradientColors.length >= 2
        ? post.gradientColors
        : [AppColors.tangerine, AppColors.poppy];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        post.petName.isNotEmpty ? post.petName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyPostGrid extends StatelessWidget {
  const _EmptyPostGrid();

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_library_outlined, size: 48, color: pt.ink300),
        const SizedBox(height: 12),
        Text('No posts yet', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: pt.ink700)),
        const SizedBox(height: 4),
        Text('Posts will appear here', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: pt.ink500)),
      ],
    );
  }
}
