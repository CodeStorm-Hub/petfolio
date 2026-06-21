import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/pf_search_app_bar.dart';
import '../../../../core/widgets/petfolio_empty_state.dart';
import '../controllers/hashtag_controller.dart';

class HashtagSearchScreen extends ConsumerWidget {
  const HashtagSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final results = ref.watch(hashtagSearchProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: PfSearchAppBar(
          hintText: 'Search hashtags…',
          autofocus: true,
          onQueryChanged: (q) =>
              ref.read(hashtagSearchProvider.notifier).search(q),
        ),
        titleSpacing: 8,
      ),
      body: results.isEmpty
          ? const PetfolioEmptyState(
              icon: Icons.tag_rounded,
              title: 'Find hashtags',
              subtitle: 'Search for topics to discover posts from the community.',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: pt.line),
              itemBuilder: (context, i) {
                final tag = results[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: pt.surface2,
                    child: Text('#', style: TextStyle(fontWeight: FontWeight.w800, color: pt.ink500)),
                  ),
                  title: Text('#${tag.tag}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${tag.postCount} posts', style: TextStyle(color: pt.ink500)),
                  onTap: () => context.push('/social/hashtag/${tag.tag}'),
                );
              },
            ),
    );
  }
}
