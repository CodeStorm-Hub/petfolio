import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/petfolio_empty_state.dart';
import '../../../../core/widgets/primary_pill_button.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../widgets/create_community_sheet.dart';
import '../../data/models/community.dart';
import '../controllers/communities_controller.dart';

class CommunitiesScreen extends ConsumerWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communitiesControllerProvider);

    return Scaffold(
      floatingActionButton: state.maybeWhen(
        data: (communities) => communities.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => showCreateCommunitySheet(context, ref),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create community'),
              ),
        orElse: () => null,
      ),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + 76.0),
          const SizedBox(height: 16),
          Expanded(
            child: state.when(
        loading: () => LayoutBuilder(
          builder: (_, constraints) => constraints.maxWidth >= 600
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, _) =>
                      const SkeletonLoader(width: double.infinity, height: 88),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, _) =>
                      const SkeletonLoader(width: double.infinity, height: 88),
                ),
        ),
        error: (e, _) => PetfolioEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load communities',
          subtitle: 'Check your connection and try again.',
          action: PrimaryPillButton(
            label: 'Retry',
            onPressed: () =>
                ref.invalidate(communitiesControllerProvider),
          ),
        ),
        data: (communities) {
          if (communities.isEmpty) {
            return PetfolioEmptyState(
              icon: Icons.pets_rounded,
              title: 'No communities yet',
              subtitle: 'Be the first to create one!',
              action: PrimaryPillButton(
                label: 'Create community',
                leadingIcon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: () => showCreateCommunitySheet(context, ref),
              ),
            );
          }
          return LayoutBuilder(
            builder: (_, constraints) {
              final isWide = constraints.maxWidth >= 600;
              if (isWide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3.2,
                      ),
                      itemCount: communities.length,
                      itemBuilder: (context, i) =>
                          _CommunityCard(community: communities[i]),
                    ),
                  ),
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
          );
        },
          ),
          ),
        ],
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
      onTap: () => context.push(
        '/social/communities/${community.id}',
        extra: community,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pt.line, width: 1),
          boxShadow: pt.shadowE1,
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
                  Semantics(
                    label: '${community.memberCount} ${community.memberCount == 1 ? 'member' : 'members'}, ${community.postCount} ${community.postCount == 1 ? 'post' : 'posts'}',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        Icon(Icons.group_rounded, size: 14, color: pt.ink500),
                        const SizedBox(width: 4),
                        Text(
                          '${community.memberCount}',
                          style: tt.labelSmall?.copyWith(
                            color: pt.ink500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.article_rounded, size: 14, color: pt.ink500),
                        const SizedBox(width: 4),
                        Text(
                          '${community.postCount}',
                          style: tt.labelSmall?.copyWith(
                            color: pt.ink500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isMember) {
      return Semantics(
        button: true,
        label: 'Leave ${community.name}',
        child: OutlinedButton(
          onPressed: () => ref
              .read(communitiesControllerProvider.notifier)
              .toggleMembership(community),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.lilac700D : AppColors.lilac700,
            side: BorderSide(color: AppColors.lilac.withValues(alpha: 0.55)),
            backgroundColor:
                isDark ? AppColors.lilacSoftD : AppColors.lilacSoft,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Joined',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Join ${community.name}',
      child: FilledButton(
        onPressed: () => ref
            .read(communitiesControllerProvider.notifier)
            .toggleMembership(community),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lilac,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('Join',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
