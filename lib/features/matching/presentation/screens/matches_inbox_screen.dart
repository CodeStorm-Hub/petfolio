import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/widgets/pet_switcher_sheet.dart';
import '../../data/models/match_inbox_item.dart';
import '../controllers/matches_inbox_controller.dart';
import '../matching_navigation.dart';

class MatchesInboxScreen extends ConsumerWidget {
  const MatchesInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetControllerProvider);
    if (pet != null) return _MatchesInboxView(pet: pet);

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
              Text('Connection error',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: pt.ink500)),
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

class _MatchesInboxView extends ConsumerWidget {
  const _MatchesInboxView({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final inboxAsync = ref.watch(matchesInboxControllerProvider(pet.id));

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              eyebrow: 'Match · Inbox',
              onOpenSwitcher: () => PetSwitcherSheet.show(context),
              onBack: () => popOrGo(context, '/matching'),
              actions: [
                AppHeaderAction(
                  iconKey: const ValueKey<String>('matches_inbox_discover'),
                  icon: Icons.style_rounded,
                  tooltip: 'Discover',
                  onTap: () => context.go('/matching'),
                ),
              ],
            ),
            Expanded(
              child: inboxAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: TailWagLoader()),
                error: (error, stackTrace) {
                  debugPrint(
                    '[MatchesInboxScreen] fetchMatchInbox failed: $error\n$stackTrace',
                  );
                  return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load matches',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: pt.ink500),
                      ),
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
                  final empty = snapshot.newMatches.isEmpty &&
                      snapshot.conversations.isEmpty;
                  if (empty) {
                    return PetfolioEmptyState(
                      icon: Icons.favorite_rounded,
                      title: 'No matches yet',
                      subtitle:
                          'When you and another pet like each other, they will show up here.',
                    );
                  }

                  final newMatches = snapshot.newMatches;
                  final conversations = snapshot.conversations;
                  final hasNewMatches = newMatches.isNotEmpty;
                  final hasConversations = conversations.isNotEmpty;

                  final List<Widget> listItems = [];
                  if (hasNewMatches) {
                    listItems.add(const _SectionTitle(label: 'New matches'));
                    listItems.add(const SizedBox(height: 12));
                    listItems.add(
                      SizedBox(
                        height: 108,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: newMatches.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final item = newMatches[index];
                            return _NewMatchAvatar(
                              item: item,
                              onTap: () => openMatchChat(
                                context,
                                ref,
                                matchId: item.matchId!, // non-null: isNewMatch implies isDm==false
                                actorPetId: pet.id,
                                otherPetName: item.otherPetName,
                                threadId: item.threadId,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                    listItems.add(const SizedBox(height: 28));
                  }
                  if (hasConversations) {
                    listItems.add(const _SectionTitle(label: 'Messages'));
                    listItems.add(const SizedBox(height: 8));
                  }

                  final int baseCount = listItems.length;
                  final int totalCount = baseCount + conversations.length;

                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(matchesInboxControllerProvider(pet.id).notifier)
                        .refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: totalCount,
                      itemBuilder: (context, index) {
                        if (index < baseCount) {
                          return listItems[index];
                        }
                        final item = conversations[index - baseCount];
                        final onTap = item.isDm
                            ? () => openDirectChat(
                                  context,
                                  ref,
                                  actorPetId: pet.id,
                                  otherPetId: item.otherPetId,
                                  otherPetName: item.otherPetName,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
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

class _NewMatchAvatar extends StatelessWidget {
  const _NewMatchAvatar({required this.item, required this.onTap});
  final MatchInboxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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

    return Material(
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
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (item.isDm) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.poppy.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.poppy.withAlpha(60),
                                    ),
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
                              ],
                            ],
                          ),
                        ),
                        Text(
                          timeLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: pt.ink300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: pt.ink500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);
    if (diff.inDays == 0) {
      final h = local.hour;
      final m = local.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final hour12 = h % 12 == 0 ? 12 : h % 12;
      return '$hour12:$m $period';
    }
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[local.weekday - 1];
    }
    return '${local.month}/${local.day}';
  }
}
