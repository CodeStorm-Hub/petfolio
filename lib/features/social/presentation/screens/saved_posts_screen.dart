import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/petfolio_empty_state.dart';
import '../../../../core/widgets/tail_wag_loader.dart';
import '../../data/models/feed_post.dart';
import '../controllers/saved_posts_controller.dart';

class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved posts'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: async.when(
        loading: () => const Center(child: TailWagLoader()),
        error: (e, _) => Center(child: Text('Could not load saves: $e')),
        data: (posts) {
          if (posts.isEmpty) {
            return const PetfolioEmptyState(
              icon: Icons.bookmark_outline_rounded,
              title: 'Nothing saved yet',
              subtitle: 'Tap the bookmark on any post to save it here',
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                ref.read(savedPostsProvider.notifier).loadMore();
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
              itemBuilder: (context, i) => _SavedThumb(post: posts[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SavedThumb extends ConsumerWidget {
  const _SavedThumb({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    return GestureDetector(
      onTap: () => context.push('/social/post/${post.id}', extra: post),
      onLongPress: () => _confirmUnsave(context, ref),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
          Positioned(
            top: 4,
            right: 4,
            child: Icon(
              Icons.bookmark_rounded,
              size: 16,
              color: Colors.white.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmUnsave(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove bookmark?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(savedPostsProvider.notifier).unsave(post.id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
