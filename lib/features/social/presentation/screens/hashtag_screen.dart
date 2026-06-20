import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/post_grid.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/hashtag_controller.dart';

class HashtagScreen extends ConsumerWidget {
  const HashtagScreen({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cleanTag = tag.replaceAll('#', '');
    final feedAsync = ref.watch(hashtagFeedProvider(tag));

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: pt.line,
        title: Text('#$cleanTag'),
      ),
      body: CustomScrollView(
        slivers: [
          PostGrid(
            postsAsync: feedAsync,
            onTap: (post) => context.push('/social/post/${post.id}', extra: post),
            onLoadMore: () => ref.read(hashtagFeedProvider(tag).notifier).loadMore(tag),
          ),
        ],
      ),
    );
  }
}
