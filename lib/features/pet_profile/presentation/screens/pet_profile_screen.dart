import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import 'package:petfolio/features/care/data/models/care_task.dart';
import 'package:petfolio/features/care/data/models/medical_record.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/controllers/care_streak_stream_provider.dart';
import 'package:petfolio/features/care/presentation/controllers/health_vault_controller.dart';

import '../../data/models/pet.dart';
import '../../data/models/pet_gender.dart';
import '../controllers/active_pet_controller.dart';
import '../controllers/pet_list_controller.dart';
import '../widgets/pet_switcher_sheet.dart';
// AppHeader (shell-wide top bar) is exported from core widgets.
// Pet switcher sheet is wired locally so the core widget stays feature-free.

/// The main "Home" tab — shows the active pet header and daily summary.
///
/// All content is keyed on [activePetControllerProvider] so switching pets
/// via the switcher sheet instantly re-renders this screen.
class PetProfileScreen extends ConsumerWidget {
  const PetProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);
    final petsAsync = ref.watch(petListProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        bottom: false, // Prevents duplicate padding above the navigation bar
        child: CustomScrollView(
          slivers: [
            // ── Unified shell header ──────────────────────────────────
            SliverToBoxAdapter(
              child: AppHeader(
                eyebrow: 'Active pet',
                onOpenSwitcher: () => PetSwitcherSheet.show(context),
                actions: [
                  AppHeaderAction(
                    iconKey: const ValueKey<String>('home_action_outdoor'),
                    icon: Icons.wb_sunny_outlined,
                    tooltip: 'Outdoor mode',
                    onTap: () {},
                  ),
                  AppHeaderAction(
                    iconKey: const ValueKey<String>('home_action_notifications'),
                    icon: Icons.notifications_outlined,
                    tooltip: 'Notifications',
                    badge: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            if (activePet == null)
              // Loading / error / no-pets state
              SliverFillRemaining(
                child: petsAsync.when(
                  skipLoadingOnReload: true,
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 48, color: pt.ink300),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load pets',
                            style: const TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Check your connection and try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: pt.ink500),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () =>
                                ref.invalidate(petListProvider),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (pets) => pets.isEmpty
                      ? _EmptyPetsState(pt: pt)
                      // Pets loaded but ActivePetController is still restoring
                      // the saved selection from SharedPreferences — brief shimmer.
                      : const Center(child: CircularProgressIndicator.adaptive()),
                ),
              )
            else
              SliverFillRemaining(
                child: DefaultTabController(
                  length: 4,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      final cs = Theme.of(context).colorScheme;
                      return [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: _HeroCard(pet: activePet),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: _PetStatsRow(pet: activePet),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: PrimaryPillButton(
                              isFullWidth: true,
                              leadingIcon:
                                  const Icon(Icons.dynamic_feed_rounded),
                              label: 'View Social Profile',
                              onPressed: () => context.push(
                                '/social/profile/${activePet.id}',
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                            child: _SellerDashboardCard(pt: pt),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverOverlapAbsorber(
                          handle:
                              NestedScrollView.sliverOverlapAbsorberHandleFor(
                                  context),
                          sliver: SliverPersistentHeader(
                            pinned: true,
                            delegate: _PetProfileTabBarDelegate(
                              backgroundColor: pt.surface1,
                              tabBar: TabBar(
                                labelColor: cs.primary,
                                unselectedLabelColor: pt.ink500,
                                indicatorColor: cs.primary,
                                labelStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                                tabs: const [
                                  Tab(text: 'Overview'),
                                  Tab(text: 'Health'),
                                  Tab(text: 'Care'),
                                  Tab(text: 'Awards'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ];
                    },
                    body: TabBarView(
                      children: [
                        _ProfileOverviewTab(pet: activePet, pt: pt),
                        _ProfileHealthTab(pt: pt),
                        _ProfileCareTab(pt: pt),
                        _ProfilePlaceholderTab(
                          title: 'Awards',
                          pt: pt,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SellerDashboardCard extends StatelessWidget {
  const _SellerDashboardCard({required this.pt});

  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/seller'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: pt.line200, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowE1L,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.meadow500.withAlpha(34),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.meadow500, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seller Dashboard',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your shop, products, and orders',
                    style: TextStyle(fontSize: 13, color: pt.ink500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: pt.ink300, size: 22),
          ],
        ),
      ),
    );
  }
}

class _PetStatsRow extends StatelessWidget {
  const _PetStatsRow({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final breed =
        (pet.breed != null && pet.breed!.trim().isNotEmpty) ? pet.breed! : '—';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pt.line200, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowE1L,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(label: 'Breed', value: breed),
          ),
          Expanded(
            child: _StatChip(label: 'Age', value: _petAgeLabel(pet)),
          ),
          Expanded(
            child: _StatChip(
              label: 'Weight',
              value: pet.weightKg != null
                  ? '${pet.weightKg!.toStringAsFixed(pet.weightKg! >= 10 ? 0 : 1)} kg'
                  : '—',
            ),
          ),
          Expanded(
            child: _StatChip(
              label: 'Sex',
              value: pet.gender == PetGender.unknown ? '—' : pet.gender.label,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06 * 10,
              color: pt.ink500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

String _petAgeLabel(Pet pet) {
  final dob = pet.dateOfBirth;
  if (dob == null) return '—';
  final today = DateTime.now();
  var years = today.year - dob.year;
  var months = today.month - dob.month;
  if (today.day < dob.day) months -= 1;
  if (months < 0) {
    years -= 1;
    months += 12;
  }
  if (years < 0) return '—';
  if (years > 0) return years == 1 ? '1 yr' : '$years yrs';
  if (months > 0) return '$months mo';
  final days = today.difference(dob).inDays.clamp(0, 365);
  return '${days}d';
}

class _PetProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PetProfileTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: overlapsContent ? 0.5 : 0,
      shadowColor: AppColors.shadowE1L,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PetProfileTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _ProfileOverviewTab extends StatelessWidget {
  const _ProfileOverviewTab({
    required this.pet,
    required this.pt,
  });

  final Pet pet;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey<String>('pet_profile_overview'),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionLabel(label: 'Today'),
                  const SizedBox(height: 12),
                  _ReminderCard(
                    icon: Icons.medication_outlined,
                    title: 'Heartworm tablet',
                    subtitle: '9:00 AM · Daily',
                    accentColor: pet.speciesEnum.accent,
                  ),
                  const SizedBox(height: 10),
                  _ReminderCard(
                    icon: Icons.directions_walk_outlined,
                    title: 'Evening walk with ${pet.name}',
                    subtitle: '2 / 3 walks today',
                    accentColor: AppColors.meadow500,
                    isPrimary: true,
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'From the feed'),
                  const SizedBox(height: 12),
                  _FeedPlaceholder(pt: pt),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfilePlaceholderTab extends StatelessWidget {
  const _ProfilePlaceholderTab({
    required this.title,
    required this.pt,
  });

  final String title;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: PageStorageKey<String>('pet_profile_tab_$title'),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  '$title — coming soon',
                  style: TextStyle(fontSize: 15, color: pt.ink500),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = pet.speciesEnum.accent;
    final streakAsync = ref.watch(careStreakRealtimeProvider(pet.id));
    final streakLabel = streakAsync.maybeWhen(
      data: (s) => '${s.currentStreak}',
      orElse: () => '0',
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.18)!],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(136),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background blob
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33FFFFFF), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HEALTH STREAK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1 * 12,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(46),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'on a walk',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.06 * 11,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    streakLabel,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'days on track',
                    style: TextStyle(
                        fontSize: 16, color: Colors.white.withAlpha(230)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Weekly bars
              Row(
                children: List.generate(7, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                      height: 28,
                      decoration: BoxDecoration(
                        color: i < 6
                            ? Colors.white.withAlpha(217)
                            : Colors.white.withAlpha(64),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Day labels
              Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                  return Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(217),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08 * 12,
        color: pt.ink500,
      ),
    );
  }
}

// ── Reminder card ─────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pt.line200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowE1L,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(34),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: pt.ink500),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isPrimary ? accentColor : pt.surface2,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: accentColor.withAlpha(170),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              isPrimary ? 'Start walk' : 'Mark done',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isPrimary ? Colors.white : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed placeholder ──────────────────────────────────────────────────────────

class _FeedPlaceholder extends StatelessWidget {
  const _FeedPlaceholder({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pt.line200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Color.lerp(AppColors.mulberry500, Colors.white, 0.3)!,
                      AppColors.mulberry500,
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '@parkside_corgi_club',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text('0.4 km · 2 hr ago',
                          style:
                              TextStyle(fontSize: 12, color: pt.ink500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coral500.withAlpha(30),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Nearby',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.coral500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 160,
            color: pt.surface2,
            child: Center(
              child: Text(
                '[feed photo]',
                style: TextStyle(fontSize: 12, color: pt.ink300),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Sunday meetup at Highbury — 6 corgis confirmed.',
              style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Care Tab ──────────────────────────────────────────────────────────

class _ProfileCareTab extends ConsumerWidget {
  const _ProfileCareTab({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasks = ref.watch(
      careDashboardProvider.select((s) => s.todayTasks),
    );

    return Builder(builder: (ctx) {
      return CustomScrollView(
        key: const PageStorageKey<String>('pet_profile_care'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(ctx),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                todayTasks.when(
                  loading: () => List.generate(
                    3,
                    (_) => _ProfileRowSkeleton(pt: pt),
                  ),
                  error: (e, _) => [
                    _ProfileTabEmptyMessage(
                      icon: Icons.cloud_off_rounded,
                      label: 'Could not load tasks',
                      pt: pt,
                      action: TextButton.icon(
                        onPressed: () =>
                            ref.read(careDashboardProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                  data: (tasks) => tasks.isEmpty
                      ? [
                          _ProfileTabEmptyMessage(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'No tasks for today',
                            pt: pt,
                          ),
                        ]
                      : tasks
                          .map((t) => _CareTaskRow(task: t, pt: pt))
                          .toList(),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ── Profile Health Tab ────────────────────────────────────────────────────────

class _ProfileHealthTab extends ConsumerWidget {
  const _ProfileHealthTab({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(healthVaultControllerProvider);

    return Builder(builder: (ctx) {
      return CustomScrollView(
        key: const PageStorageKey<String>('pet_profile_health'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(ctx),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                recordsAsync.when(
                  loading: () => List.generate(
                    3,
                    (_) => _ProfileRowSkeleton(pt: pt),
                  ),
                  error: (e, _) => [
                    _ProfileTabEmptyMessage(
                      icon: Icons.cloud_off_rounded,
                      label: 'Could not load health records',
                      pt: pt,
                    ),
                  ],
                  data: (records) => records.isEmpty
                      ? [
                          _ProfileTabEmptyMessage(
                            icon: Icons.medical_services_outlined,
                            label: 'No medical records yet',
                            pt: pt,
                          ),
                        ]
                      : records
                          .map((r) => _HealthRecordRow(record: r, pt: pt))
                          .toList(),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ── Care task row ─────────────────────────────────────────────────────────────

class _CareTaskRow extends StatelessWidget {
  const _CareTaskRow({required this.task, required this.pt});
  final CareTask task;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = task.isCompleted ? AppColors.meadow500 : cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: pt.line200, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(task.categoryIconData, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.frequency.name
                        .replaceAllMapped(
                          RegExp(r'([A-Z])'),
                          (m) => ' ${m[0]!.toLowerCase()}',
                        )
                        .trim()
                        .capitalize(),
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                  ),
                ],
              ),
            ),
            Icon(
              task.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: task.isCompleted ? AppColors.meadow500 : pt.ink300,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Health record row ─────────────────────────────────────────────────────────

class _HealthRecordRow extends StatelessWidget {
  const _HealthRecordRow({required this.record, required this.pt});
  final MedicalRecord record;
  final PetfolioThemeExtension pt;

  static const typeIcons = {
    MedicalRecordType.vaccine: Icons.vaccines_rounded,
    MedicalRecordType.medication: Icons.medication_rounded,
    MedicalRecordType.allergy: Icons.warning_amber_rounded,
    MedicalRecordType.surgery: Icons.healing_rounded,
    MedicalRecordType.parasitePrevention: Icons.pest_control_rounded,
    MedicalRecordType.other: Icons.folder_open_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (statusLabel, statusColor) = switch (true) {
      _ when record.isOverdue => ('Overdue', AppColors.coral500),
      _ when record.isExpiringSoon => ('Due soon', const Color(0xFFF59E0B)),
      _ => ('Active', AppColors.meadow500),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: pt.line200, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                typeIcons[record.recordType] ?? Icons.folder_open_rounded,
                color: cs.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.name,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    record.recordType.name
                        .replaceAllMapped(
                          RegExp(r'([A-Z])'),
                          (m) => ' ${m[0]!.toLowerCase()}',
                        )
                        .trim()
                        .capitalize(),
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(26),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared tab helpers ────────────────────────────────────────────────────────

class _ProfileRowSkeleton extends StatelessWidget {
  const _ProfileRowSkeleton({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SkeletonLoader(width: 40, height: 40, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: double.infinity, height: 14),
                const SizedBox(height: 6),
                SkeletonLoader(width: 80, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SkeletonLoader(width: 22, height: 22, borderRadius: 999),
        ],
      ),
    );
  }
}

class _ProfileTabEmptyMessage extends StatelessWidget {
  const _ProfileTabEmptyMessage({
    required this.icon,
    required this.label,
    required this.pt,
    this.action,
  });

  final IconData icon;
  final String label;
  final PetfolioThemeExtension pt;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 40, color: pt.ink300),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: pt.ink500),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPetsState extends StatelessWidget {
  const _EmptyPetsState({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐾', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No pets yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pet to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: pt.ink500),
            ),
          ],
        ),
      ),
    );
  }
}
