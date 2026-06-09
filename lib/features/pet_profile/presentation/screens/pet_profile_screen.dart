import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import 'package:petfolio/features/care/data/models/care_task.dart';
import 'package:petfolio/features/care/data/models/pet_level.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/controllers/care_streak_stream_provider.dart';
import 'package:petfolio/features/care/presentation/controllers/pet_awards_provider.dart';

import '../../data/models/pet.dart';
import '../controllers/active_pet_controller.dart';
import '../controllers/pet_list_controller.dart';


class PetProfileScreen extends ConsumerWidget {
  const PetProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);
    final petsAsync = ref.watch(petListProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    if (activePet == null) {
      return Scaffold(
        backgroundColor: pt.surface1,
        body: Center(
          child: petsAsync.when(
            skipLoadingOnReload: true,
            loading: () => const _PetProfileHeaderSkeleton(),
            error: (e, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
                const SizedBox(height: 16),
                const Text('Could not load pets', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(petListProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
            data: (pets) => pets.isEmpty
                ? const PetfolioEmptyState(
                    icon: Icons.pets_outlined,
                    title: 'No pets found',
                    subtitle: 'Add a pet to get started.',
                  )
                : const TailWagLoader(),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= ResponsiveLayout.mobileMax;

    final view = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeroGamifiedBanner(pet: activePet),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuickStatsTrio(pet: activePet),
                const SizedBox(height: 18),
                
                // Today's care preview
                PfSectionTitle(
                  title: "Today's quests",
                  accent: AppColors.sunny,
                  trailing: TextButton(
                    onPressed: () => context.push('/care'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.tangerine700,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('See all →'),
                  ),
                ),
                _DailyQuestsCard(petId: activePet.id),
                
                const SizedBox(height: 18),

                // Recent moments
                PfSectionTitle(
                  title: "Recent moments",
                  accent: AppColors.poppy,
                  trailing: TextButton(
                    onPressed: () => AppSnackBar.show('Photo gallery coming soon 📸'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.poppy700,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Gallery →'),
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: _MomentPlaceholder(label: 'bath day', color: AppColors.poppy, soft: AppColors.poppySoft, emoji: '🛁')),
                    const SizedBox(width: 8),
                    Expanded(child: _MomentPlaceholder(label: 'napping', color: AppColors.lilac, soft: AppColors.lilacSoft, emoji: '💤')),
                    const SizedBox(width: 8),
                    Expanded(child: _MomentPlaceholder(label: 'park run', color: AppColors.mint, soft: AppColors.mintSoft, emoji: '🌳')),
                  ],
                ),
                
                const SizedBox(height: 18),

                // Recent achievements
                const PfSectionTitle(
                  title: "Recent achievements",
                  accent: AppColors.lilac,
                ),
                _RecentAchievementsRow(petId: activePet.id),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: pt.surface1,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _FloatingToolbar(pet: activePet),
      body: isWide
          ? Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: view,
              ),
            )
          : view,
    );
  }
}

class _HeroGamifiedBanner extends ConsumerWidget {
  const _HeroGamifiedBanner({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sp = pet.speciesEnum;
    final color = sp.resolvedAccent(isDark);
    
    final streakAsync = ref.watch(careStreakRealtimeProvider(pet.id));
    final streakLabel = streakAsync.maybeWhen(
      data: (s) => '${s.currentStreak}',
      orElse: () => '0',
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        WaveHeader(
          color: color,
          child: Column(
            children: [
              // Spacer for fixed AppShell status header
              SizedBox(height: MediaQuery.paddingOf(context).top + 76.0),
              
              // Big hero greeting
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning, ${pet.name} 💛', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white.withAlpha(216))),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          text: '${pet.name} is feeling\n',
                          children: const [
                            TextSpan(text: 'cuddly today.', style: TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.05,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 75.0),
            ],
          ),
        ),
        
        // Pet card peeking on header, positioned outside Clipper
        Positioned(
          left: 18,
          right: 18,
          bottom: -32,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: AppColors.shadowE2L, blurRadius: 30, offset: Offset(0, 16), spreadRadius: -12)],
            ),
            child: Row(
              children: [
                PetAvatar(
                  imageUrl: pet.avatarUrl,
                  species: sp,
                  size: PetAvatarSize.xl,
                  showRing: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: pt.ink950)),
                      Text('${pet.breed ?? sp.label} · ${pet.ageLabel}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pt.ink500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7), // Pale yellow background
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        streakLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706), // Orange text
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



class _QuickStatsTrio extends ConsumerWidget {
  const _QuickStatsTrio({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(careStreakRealtimeProvider(pet.id));
    final streakLabel = streakAsync.maybeWhen(data: (s) => '${s.currentStreak}', orElse: () => '0');
    final awardsAsync = ref.watch(petAwardsSummaryProvider(pet.id));
    final xpLabel = awardsAsync.maybeWhen(data: (s) => '${s.totalXp}', orElse: () => '0');
    final logsLabel = awardsAsync.maybeWhen(data: (s) => '${s.logsCount}', orElse: () => '0');

    return Row(
      children: [
        Expanded(child: _StatTile(color: AppColors.sunnySoft, textColor: AppColors.sunny700, icon: const Text('🔥', style: TextStyle(fontSize: 20)), value: streakLabel, label: 'day streak')),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(color: AppColors.lilacSoft, textColor: AppColors.lilac700, icon: const Icon(Icons.star_rounded, color: AppColors.lilac700, size: 20), value: xpLabel, label: 'XP earned')),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(color: AppColors.mintSoft, textColor: AppColors.mint700, icon: const Icon(Icons.check_rounded, color: AppColors.mint700, size: 20), value: logsLabel, label: 'care logs')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.color, required this.textColor, required this.icon, required this.value, required this.label});
  final Color color;
  final Color textColor;
  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(isDark ? 30 : 100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(margin: const EdgeInsets.only(bottom: 2), child: icon),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).extension<PetfolioThemeExtension>()!.ink950, height: 1)),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }
}

class _DailyQuestsCard extends ConsumerWidget {
  const _DailyQuestsCard({required this.petId});
  final String petId;

  String emojiForTaskType(CareTaskType t) {
    switch (t) {
      case CareTaskType.feeding: return '🥩';
      case CareTaskType.walk: return '🦮';
      case CareTaskType.grooming: return '✂️';
      case CareTaskType.medication: return '💊';
      case CareTaskType.vetVisit: return '🏥';
      case CareTaskType.training: return '🎓';
      case CareTaskType.playtime: return '🎾';
      case CareTaskType.dental: return '🦷';
      case CareTaskType.nailTrim: return '💅';
      case CareTaskType.bath: return '🛁';
      case CareTaskType.other: return '⭐';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasks = ref.watch(careDashboardProvider.select((s) => s.todayTasks));
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    
    return PfCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: todayTasks.when(
        data: (tasks) {
          if (tasks.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No quests today.'));
          return Column(
            children: tasks.take(3).map((t) => Column(
              children: [
                _DailyQuestRow(
                  icon: emojiForTaskType(t.taskType),
                  label: t.title,
                  done: t.isCompleted,
                  time: t.isDueToday ? 'Due today' : 'Anytime',
                  xp: t.gamificationPoints,
                  due: !t.isCompleted && t.isDueToday,
                ),
                if (t != tasks.take(3).last) Container(height: 1, color: pt.line, margin: const EdgeInsets.symmetric(horizontal: 4)),
              ],
            )).toList(),
          );
        },
        loading: () => const CircularProgressIndicator.adaptive(),
        error: (e, st) {
          debugPrint('Today quests load failure: $e\n$st');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.poppy, size: 16),
                const SizedBox(width: 8),
                Text('Could not load quests', style: TextStyle(color: pt.ink500, fontSize: 12)),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ref.read(careDashboardProvider.notifier).refresh(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DailyQuestRow extends StatelessWidget {
  const _DailyQuestRow({required this.icon, required this.label, required this.time, required this.xp, required this.done, required this.due});
  final String icon;
  final String label;
  final String time;
  final int xp;
  final bool done;
  final bool due;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final ink950 = pt.ink950;
    final ink500 = pt.ink500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: done ? AppColors.mint : due ? AppColors.poppySoft : pt.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                : Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink950, decoration: done ? TextDecoration.lineThrough : TextDecoration.none).copyWith(color: done ? ink950.withAlpha(140) : ink950)),
                Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: due ? AppColors.poppy700 : ink500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: done ? AppColors.mintSoft : AppColors.sunnySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Text('+$xp ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: done ? AppColors.mint700 : AppColors.sunny700)),
                Icon(Icons.star_rounded, size: 12, color: done ? AppColors.mint700 : AppColors.sunny700),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentPlaceholder extends StatelessWidget {
  const _MomentPlaceholder({required this.label, required this.color, required this.soft, required this.emoji});
  final String label;
  final Color color;
  final Color soft;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [soft, Color.lerp(soft, color, 0.35)!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Subtle paw watermark in the bottom right corner
          Positioned(
            right: 10,
            bottom: 10,
            child: Opacity(
              opacity: 0.15,
              child: const Icon(Icons.pets_rounded, size: 28, color: Colors.white),
            ),
          ),
          // Centered emoji icon
          Center(
            child: Text(
              emoji,
              style: const TextStyle(
                fontSize: 32,
                shadows: [
                  Shadow(
                    color: Colors.black12,
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAchievementsRow extends ConsumerWidget {
  const _RecentAchievementsRow({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awardsAsync = ref.watch(petAwardsSummaryProvider(petId));
    final unlockedTypes = awardsAsync.maybeWhen(
      data: (a) => a.unlockedTypes,
      orElse: () => const <String>{},
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (int i = 0; i < kBadgeCatalog.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: 86,
                child: PfAchievementTile(
                  color: kBadgeCatalog[i].color,
                  emoji: kBadgeCatalog[i].emoji,
                  label: kBadgeCatalog[i].label,
                  owned: unlockedTypes.contains(kBadgeCatalog[i].type),
                  index: i,
                  boxSize: 76,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating toolbar
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingToolbar extends StatefulWidget {
  const _FloatingToolbar({required this.pet});
  final Pet pet;

  @override
  State<_FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<_FloatingToolbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 28,
              offset: Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarBtn(
              icon: Icons.edit_rounded,
              label: 'Edit',
              color: AppColors.tangerine,
              onTap: () => context.push('/pet/${widget.pet.id}/edit'),
            ),
            const SizedBox(width: 4),
            _ToolbarBtn(
              icon: Icons.favorite_rounded,
              label: 'Care',
              color: AppColors.poppy,
              onTap: () => context.push('/care'),
            ),
            const SizedBox(width: 4),
            _ToolbarBtn(
              icon: Icons.camera_alt_rounded,
              label: 'Post',
              color: AppColors.sky,
              onTap: () => context.push('/social/create-post'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(24),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetProfileHeaderSkeleton extends StatelessWidget {
  const _PetProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonLoader(
                width: double.infinity,
                height: MediaQuery.paddingOf(context).top + 220,
                borderRadius: 0,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                              child: SkeletonLoader(
                                width: double.infinity,
                                height: 72,
                                borderRadius: PetfolioThemeExtension.radiusMd,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const SkeletonLoader(width: 140, height: 16),
                    const SizedBox(height: 12),
                    SkeletonLoader.listTile(),
                    const SizedBox(height: 8),
                    SkeletonLoader.listTile(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
