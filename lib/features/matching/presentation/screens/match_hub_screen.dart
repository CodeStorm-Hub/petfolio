import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../data/models/match_inbox_item.dart';
import '../controllers/match_liked_controller.dart';
import '../controllers/matches_inbox_controller.dart';
import '../matching_navigation.dart';

class MatchHubScreen extends ConsumerStatefulWidget {
  const MatchHubScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<MatchHubScreen> createState() => _MatchHubScreenState();
}

class _MatchHubScreenState extends ConsumerState<MatchHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final pet = ref.watch(activePetControllerProvider);

    if (pet == null) return _PetGuard(pt: pt);

    final topInset = MediaQuery.paddingOf(context).top + 76.0;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topInset),
          const SizedBox(height: 16),
          Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: pt.pillarMatch,
                unselectedLabelColor: pt.ink300,
                indicatorColor: pt.pillarMatch,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Messages'),
                  Tab(text: 'Liked'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  KeepAliveTab(child: _InboxTab(pet: pet)),
                  KeepAliveTab(child: _LikedTab(petId: pet.id)),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

// ─── Pet guard ────────────────────────────────────────────────────────────────

class _PetGuard extends ConsumerWidget {
  const _PetGuard({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Text('Connection error',
                  style: TextStyle(fontSize: 15, color: pt.ink500)),
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

// ─── Inbox tab ────────────────────────────────────────────────────────────────

class _InboxTab extends ConsumerWidget {
  const _InboxTab({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final inboxAsync = ref.watch(matchesInboxControllerProvider(pet.id));

    return inboxAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: TailWagLoader()),
      error: (error, stackTrace) {
        debugPrint('[MatchHubScreen] fetchMatchInbox failed: $error\n$stackTrace');
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
              const SizedBox(height: 12),
              Text('Could not load matches',
                  style: TextStyle(fontSize: 15, color: pt.ink500)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref
                    .read(matchesInboxControllerProvider(pet.id).notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      },
      data: (snapshot) {
        final empty = snapshot.newMatches.isEmpty && snapshot.conversations.isEmpty;
        if (empty) {
          return const PetfolioEmptyState(
            icon: Icons.favorite_rounded,
            title: 'No matches yet',
            subtitle: 'When you and another pet like each other, they will show up here.',
          );
        }

        final newMatches = snapshot.newMatches;
        final seenKeys = <String>{};
        final conversations = snapshot.conversations.where((item) {
          return seenKeys.add(item.matchId ?? item.otherPetId);
        }).toList();
        final List<Widget> header = [];

        if (newMatches.isNotEmpty) {
          header.add(const _SectionLabel(label: 'New matches'));
          header.add(const SizedBox(height: 12));
          header.add(SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: newMatches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final item = newMatches[i];
                return _NewMatchAvatar(
                  item: item,
                  onTap: () => openMatchChat(
                    context,
                    ref,
                    matchId: item.matchId!,
                    actorPetId: pet.id,
                    otherPetName: item.otherPetName,
                    threadId: item.threadId,
                  ),
                );
              },
            ),
          ));
          header.add(const SizedBox(height: 28));
        }

        if (conversations.isNotEmpty) {
          header.add(const _SectionLabel(label: 'Messages'));
          header.add(const SizedBox(height: 8));
        }

        final baseCount = header.length;
        final totalCount = baseCount + conversations.length;

        return RefreshIndicator(
          onRefresh: () => ref
              .read(matchesInboxControllerProvider(pet.id).notifier)
              .refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: totalCount,
            itemBuilder: (_, index) {
              if (index < baseCount) return header[index];
              final item = conversations[index - baseCount];
              final onTap = item.isDm
                  ? () => openDirectChat(
                        context,
                        ref,
                        actorPetId: pet.id,
                        otherPetId: item.otherPetId,
                        otherPetName: item.otherPetName,
                        fromMatchInbox: true,
                      )
                  : () => openMatchChat(
                        context,
                        ref,
                        matchId: item.matchId!,
                        actorPetId: pet.id,
                        otherPetName: item.otherPetName,
                        threadId: item.threadId,
                      );
              return _ConversationTile(item: item, onTap: onTap);
            },
          ),
        );
      },
    );
  }
}

// ─── Liked tab ────────────────────────────────────────────────────────────────

class _LikedTab extends ConsumerWidget {
  const _LikedTab({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final likedAsync = ref.watch(matchLikedControllerProvider(petId));

    return likedAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: TailWagLoader()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
            const SizedBox(height: 12),
            Text('Could not load liked pets',
                style: TextStyle(fontSize: 15, color: pt.ink500)),
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
          return const PetfolioEmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No likes yet',
            subtitle: "Swipe right on pets you like — they'll show up here.",
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref
              .read(matchLikedControllerProvider(petId).notifier)
              .refresh(),
          child: _LikedContent(snapshot: snapshot, petId: petId),
        );
      },
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
        if (hasMutual) ...[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
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
          const SliverPadding(padding: EdgeInsets.only(top: 24)),
        if (hasPending) ...[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
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
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}

// ─── Shared section labels ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: pt.ink500,
          ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.label, required this.icon, required this.color});
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

// ─── Inbox widgets ────────────────────────────────────────────────────────────

class _NewMatchAvatar extends StatelessWidget {
  const _NewMatchAvatar({required this.item, required this.onTap});
  final MatchInboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'New match: ${item.otherPetName}',
      button: true,
      child: GestureDetector(
      key: ValueKey<String>('new_match_${item.matchId}'),
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.coral500,
                    AppColors.sunset500.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: PetAvatar(
                imageUrl: item.otherPetAvatarUrl,
                initials: item.otherPetName,
                semanticLabel: item.otherPetName,
                size: PetAvatarSize.lg,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.otherPetName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.item, required this.onTap});
  final MatchInboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final timeLabel = _formatTime(item.lastMessageAt ?? item.matchedAt);
    final preview = item.lastMessagePreview?.trim().isNotEmpty == true
        ? item.lastMessagePreview!
        : 'Say hello';

    return Semantics(
      label: '${item.otherPetName}, $preview',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('conversation_${item.matchId ?? item.otherPetId}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                PetAvatar(
                  imageUrl: item.otherPetAvatarUrl,
                  initials: item.otherPetName,
                  semanticLabel: item.otherPetName,
                  size: PetAvatarSize.md,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.otherPetName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (item.isDm) ...[
                                  const SizedBox(width: 6),
                                  ExcludeSemantics(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.poppy.withAlpha(20),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppColors.poppy.withAlpha(60)),
                                      ),
                                      child: const Text(
                                        'DM',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.poppy,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: pt.ink300),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: pt.ink500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[local.weekday - 1];
    }
    return '${local.month}/${local.day}';
  }
}

// ─── Liked card widgets ───────────────────────────────────────────────────────

class _LikedCard extends StatelessWidget {
  const _LikedCard({super.key, required this.item, required this.onTap});
  final LikedPetItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      label: item.petName,
      button: onTap != null,
      child: Material(
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
                        isMutual: item.isMutual),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.petName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700, color: pt.ink500),
                          ),
                          if (item.breed != null && item.breed!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.breed!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.labelSmall
                                  ?.copyWith(color: pt.ink300),
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
                                      fontWeight: FontWeight.w700),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: onTap,
                                icon: const Icon(
                                    Icons.chat_bubble_rounded,
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
                        color: AppColors.poppy, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_rounded,
                        size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardAvatar extends StatelessWidget {
  const _CardAvatar(
      {required this.avatarUrl,
      required this.petName,
      required this.isMutual});
  final String? avatarUrl;
  final String petName;
  final bool isMutual;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            _AvatarPlaceholder(petName: petName, isMutual: isMutual),
        errorWidget: (_, _, _) =>
            _AvatarPlaceholder(petName: petName, isMutual: isMutual),
      );
    }
    return _AvatarPlaceholder(petName: petName, isMutual: isMutual);
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder(
      {required this.petName, required this.isMutual});
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
            fontSize: 40, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
