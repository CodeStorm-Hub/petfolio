import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/petfolio_empty_state.dart';
import '../../../../core/widgets/tail_wag_loader.dart';
import '../../data/models/feed_post.dart';
import '../controllers/hashtag_controller.dart';

class HashtagScreen extends ConsumerWidget {
  const HashtagScreen({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(hashtagFeedProvider(tag));
    final cleanTag = tag.replaceAll('#', '');

    return Scaffold(
      appBar: AppBar(
        title: Text('#$cleanTag'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: feedAsync.when(
        loading: () => const Center(child: TailWagLoader()),
        error: (e, _) => Center(child: Text('Could not load posts: $e')),
        data: (posts) {
          if (posts.isEmpty) {
            return PetfolioEmptyState(
              icon: Icons.tag_rounded,
              title: 'No posts yet',
              subtitle: 'Be the first to post with #$cleanTag',
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                ref.read(hashtagFeedProvider(tag).notifier).loadMore(tag);
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: posts.length,
              itemBuilder: (context, i) => _PostThumb(post: posts[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PostThumb extends StatelessWidget {
  const _PostThumb({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    return GestureDetector(
      onTap: () => context.push('/social/post/${post.id}', extra: post),
      child: Container(
        color: AppColors.ink300,
        child: imageUrl != null
            ? Image.network(imageUrl, fit: BoxFit.cover)
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    post.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
      ),
    );
  }
}
