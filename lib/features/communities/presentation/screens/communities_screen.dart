import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/petfolio_empty_state.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/models/community.dart';
import '../controllers/communities_controller.dart';
import 'community_detail_screen.dart';

class CommunitiesScreen extends ConsumerWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communitiesControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: state.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) =>
              const SkeletonLoader(width: double.infinity, height: 88),
        ),
        error: (e, _) => Center(child: Text('$e')),
        data: (communities) {
          if (communities.isEmpty) {
            return const PetfolioEmptyState(
              icon: Icons.pets_rounded,
              title: 'No communities yet',
              subtitle: 'Be the first to create one!',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: communities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _CommunityCard(community: communities[i]),
          );
        },
      ),
    );
  }
}

class _CommunityCard extends ConsumerWidget {
  const _CommunityCard({required this.community});
  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(community: community),
      )),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: pt.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pt.line, width: 1),
        ),
        child: Row(
          children: [
            _Avatar(community: community),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(community.name,
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (community.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      community.description!,
                      style: tt.bodySmall?.copyWith(color: pt.ink500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.group_rounded,
                          size: 12, color: pt.ink300),
                      const SizedBox(width: 4),
                      Text('${community.memberCount}',
                          style: tt.labelSmall
                              ?.copyWith(color: pt.ink300)),
                      const SizedBox(width: 10),
                      Icon(Icons.article_rounded,
                          size: 12, color: pt.ink300),
                      const SizedBox(width: 4),
                      Text('${community.postCount}',
                          style: tt.labelSmall
                              ?.copyWith(color: pt.ink300)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _JoinButton(community: community),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.community});
  final Community community;

  @override
  Widget build(BuildContext context) {
    if (community.avatarUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: community.avatarUrl!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        ),
      );
    }
    final color = AppColors.lilac;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.pets_rounded, color: color, size: 24),
    );
  }
}

class _JoinButton extends ConsumerWidget {
  const _JoinButton({required this.community});
  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMember = community.isMember;
    return FilledButton(
      onPressed: () => ref
          .read(communitiesControllerProvider.notifier)
          .toggleMembership(community),
      style: FilledButton.styleFrom(
        backgroundColor:
            isMember ? AppColors.lilac.withValues(alpha: 0.15) : AppColors.lilac,
        foregroundColor: isMember ? AppColors.lilac : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(isMember ? 'Joined' : 'Join',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
