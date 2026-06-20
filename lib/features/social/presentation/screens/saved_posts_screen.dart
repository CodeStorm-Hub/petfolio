import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/post_grid.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/saved_posts_controller.dart';

class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final postsAsync = ref.watch(savedPostsProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: pt.line,
        title: const Text('Saved Posts'),
      ),
      body: CustomScrollView(
        slivers: [
          PostGrid(
            postsAsync: postsAsync,
            onTap: (post) => context.push('/social/post/${post.id}', extra: post),
            onLoadMore: () => ref.read(savedPostsProvider.notifier).loadMore(),
          ),
        ],
      ),
    );
  }
}
