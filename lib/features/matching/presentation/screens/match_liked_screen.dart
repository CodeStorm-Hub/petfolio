import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/widgets/pet_switcher_sheet.dart';
import '../controllers/match_liked_controller.dart';
import '../matching_navigation.dart';

class MatchLikedScreen extends ConsumerWidget {
  const MatchLikedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetControllerProvider);
    if (pet != null) return _LikedView(petId: pet.id);

    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final petsAsync = ref.watch(petListProvider);
    return Scaffold(
      backgroundColor: pt.surface1,
      body: Center(
        child: petsAsync.when(
          skipLoadingOnReload: true,
          loading: () => const TailWagLoader(),
          error: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
              const SizedBox(height: 12),
              Text(
                'Connection error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: pt.ink500),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(petListProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
          data: (_) => const TailWagLoader(),
        ),
      ),
    );
  }
}

class _LikedView extends ConsumerWidget {
  const _LikedView({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final likedAsync = ref.watch(matchLikedControllerProvider(petId));

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              eyebrow: 'Match · Liked',
              onOpenSwitcher: () => PetSwitcherSheet.show(context),
              onBack: () => popOrGo(context, '/matching'),
              actions: [
                AppHeaderAction(
                  iconKey: const ValueKey<String>('liked_discover'),
                  icon: Icons.style_rounded,
                  tooltip: 'Discover',
                  onTap: () => popOrGo(context, '/matching'),
                ),
              ],
            ),
            Expanded(
              child: likedAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: TailWagLoader()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load liked pets',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: pt.ink500),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(matchLikedControllerProvider(petId).notifier)
                            .refresh(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (snapshot) {
                  if (snapshot.isEmpty) {
                    return PetfolioEmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'No likes yet',
                      subtitle:
                          'Swipe right on pets you like — they\'ll show up here.',
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(matchLikedControllerProvider(petId).notifier)
                        .refresh(),
                    child: _LikedContent(
                      snapshot: snapshot,
                      petId: petId,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikedContent extends ConsumerWidget {
  const _LikedContent({required this.snapshot, required this.petId});
  final MatchLikedSnapshot snapshot;
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMutual = snapshot.mutual.isNotEmpty;
    final hasPending = snapshot.pending.isNotEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(child: const SizedBox.shrink()),
        ),
        if (hasMutual) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                label: 'Mutual Matches',
                icon: Icons.favorite_rounded,
                color: AppColors.poppy,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.76,
              ),
              itemCount: snapshot.mutual.length,
              itemBuilder: (context, i) {
                final item = snapshot.mutual[i];
                return _LikedCard(
                  key: ValueKey<String>('mutual_${item.petId}'),
                  item: item,
                  onTap: item.matchId != null
                      ? () => openMatchChat(
                            context,
                            ref,
                            matchId: item.matchId!,
                            actorPetId: petId,
                            otherPetName: item.petName,
                          )
                      : null,
                );
              },
            ),
          ),
        ],
        if (hasMutual && hasPending)
          const SliverPadding(
            padding: EdgeInsets.only(top: 24),
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        if (hasPending) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _SectionHeader(
                label: 'You Liked',
                icon: Icons.pets_rounded,
                color: AppColors.lilac,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: snapshot.pending.length,
              itemBuilder: (context, i) {
                final item = snapshot.pending[i];
                return _LikedCard(
                  key: ValueKey<String>('pending_${item.petId}'),
                  item: item,
                  onTap: null,
                );
              },
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: pt.ink500,
              ),
        ),
      ],
    );
  }
}

class _LikedCard extends StatelessWidget {
  const _LikedCard({
    super.key,
    required this.item,
    required this.onTap,
  });
  final LikedPetItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: pt.surface2,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _CardAvatar(
                    avatarUrl: item.avatarUrl,
                    petName: item.petName,
                    isMutual: item.isMutual,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: pt.ink500,
                          ),
                        ),
                        if (item.breed != null &&
                            item.breed!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.breed!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelSmall?.copyWith(color: pt.ink300),
                          ),
                        ],
                        if (item.isMutual && onTap != null) ...[
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 28,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.poppy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: onTap,
                              icon: const Icon(Icons.chat_bubble_rounded,
                                  size: 12),
                              label: const Text('Chat'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (item.isMutual)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.poppy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardAvatar extends StatelessWidget {
  const _CardAvatar({
    required this.avatarUrl,
    required this.petName,
    required this.isMutual,
  });
  final String? avatarUrl;
  final String petName;
  final bool isMutual;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) => _AvatarPlaceholder(
          petName: petName,
          isMutual: isMutual,
        ),
        errorWidget: (_, _, _) => _AvatarPlaceholder(
          petName: petName,
          isMutual: isMutual,
        ),
      );
    }
    return _AvatarPlaceholder(petName: petName, isMutual: isMutual);
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.petName, required this.isMutual});
  final String petName;
  final bool isMutual;

  @override
  Widget build(BuildContext context) {
    final color = isMutual ? AppColors.poppy : AppColors.lilac;
    final initials = petName.isNotEmpty ? petName[0].toUpperCase() : '?';
    return Container(
      color: color.withAlpha(40),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
