import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import 'package:petfolio/features/care/data/models/care_task.dart';
import 'package:petfolio/features/care/data/models/medical_record.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/controllers/care_streak_stream_provider.dart';
import 'package:petfolio/features/care/data/models/pet_awards_summary.dart';
import 'package:petfolio/features/care/presentation/controllers/pet_awards_provider.dart';
import 'package:petfolio/features/care/presentation/controllers/health_vault_controller.dart';

import 'package:petfolio/features/marketplace/data/models/shop.dart';
import 'package:petfolio/features/marketplace/presentation/controllers/my_shop_controller.dart';

import '../../data/models/pet.dart';
import '../../data/models/pet_gender.dart';
import '../controllers/active_pet_controller.dart';
import '../controllers/pet_list_controller.dart';
import '../widgets/pet_switcher_sheet.dart';

class PetProfileScreen extends ConsumerWidget {
  const PetProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);
    final petsAsync = ref.watch(petListProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: pt.warmCream,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                eyebrow: 'Active pet',
                onOpenSwitcher: () => PetSwitcherSheet.show(context),
                actions: [
                  AppHeaderAction(
                    iconKey: const ValueKey<String>('home_action_outdoor'),
                    icon: Icons.wb_sunny_outlined,
                    tooltip: 'Coming soon',
                    onTap: () {},
                  ),
                  AppHeaderAction(
                    iconKey: const ValueKey<String>('home_action_notifications'),
                    icon: Icons.notifications_outlined,
                    tooltip: 'Notifications',
                    badge: true,
                    onTap: () => context.push('/social/notifications'),
                  ),
                ],
              ),
            ),
            if (activePet == null)
              SliverFillRemaining(
                child: petsAsync.when(
                  skipLoadingOnReload: true,
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (e, _) => Center(
                    child: PetfolioEmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Could not load pets',
                      subtitle: 'Check your connection and try again.',
                      action: FilledButton.icon(
                        onPressed: () => ref.invalidate(petListProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ),
                  ),
                  data: (pets) => pets.isEmpty
                      ? const _EmptyPetsState()
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
                            child: _SellerDashboardCard(),
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
                              backgroundColor: pt.warmCream,
                              tabBar: TabBar(
                                labelColor: cs.primary,
                                unselectedLabelColor: pt.ink500,
                                indicatorColor: cs.primary,
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                                unselectedLabelStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium!
                                    .copyWith(fontSize: 13),
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
                        _ProfileOverviewTab(pet: activePet),
                        const _ProfileHealthTab(),
                        const _ProfileCareTab(),
                        _ProfileAwardsTab(petId: activePet.id),
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

// ── Seller dashboard card ─────────────────────────────────────────────────────

class _SellerDashboardCard extends ConsumerWidget {
  const _SellerDashboardCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(myShopProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    final shop = shopAsync.value;
    final destination = (shop == null) ? '/seller/setup' : '/seller';

    final subtitle = shopAsync.when(
      loading: () => 'Loading shop…',
      error: (e, st) => 'Manage your shop, products, and orders',
      data: (s) {
        if (s == null) return 'Set up your seller account';
        return switch (s.kycStatus) {
          KycStatus.pending   => 'Complete your KYC to start selling',
          KycStatus.submitted => 'KYC under review',
          KycStatus.rejected  => 'KYC rejected — resubmit required',
          KycStatus.approved  => 'Manage your shop, products, and orders',
        };
      },
    );

    return Semantics(
      button: true,
      label: 'Seller Dashboard. $subtitle',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(destination),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                      Text(
                        'Seller Dashboard',
                        style: tt.titleSmall!.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: tt.bodySmall!.copyWith(color: pt.ink500),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: pt.ink300, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pet stats row ─────────────────────────────────────────────────────────────

class _PetStatsRow extends StatelessWidget {
  const _PetStatsRow({required this.pet});

  final Pet pet;

  static const _tileColors = [
    Color(0xFFFFF2E0), // cream — Breed
    Color(0xFFFEB447), // amber — Age
    AppColors.teal400,  // teal — Weight
    AppColors.lavender400, // lavender — Sex
  ];

  @override
  Widget build(BuildContext context) {
    final breed =
        (pet.breed != null && pet.breed!.trim().isNotEmpty) ? pet.breed! : '—';
    final stats = [
      (label: 'Breed', value: breed, icon: Icons.pets_rounded),
      (label: 'Age', value: _petAgeLabel(pet), icon: Icons.cake_outlined),
      (
        label: 'Weight',
        value: pet.weightKg != null
            ? '${pet.weightKg!.toStringAsFixed(pet.weightKg! >= 10 ? 0 : 1)} kg'
            : '—',
        icon: Icons.monitor_weight_outlined,
      ),
      (
        label: 'Sex',
        value: pet.gender == PetGender.unknown ? '—' : pet.gender.label,
        icon: Icons.transgender_rounded,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _BentoStatTile(
              label: stats[i].label,
              value: stats[i].value,
              icon: stats[i].icon,
              color: _tileColors[i],
            ),
          ),
        ],
      ],
    );
  }
}

class _BentoStatTile extends StatelessWidget {
  const _BentoStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.ink950D
        : color.computeLuminance() > 0.6
            ? AppColors.warmBlack
            : AppColors.surface0;

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radius2xl),
        side: BorderSide(color: pt.line200, width: 0.5),
      ),
      color: isDark ? pt.surface2 : color,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? pt.ink500 : textColor.withAlpha(180),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: tt.titleSmall!.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.15,
                fontSize: 13,
                color: isDark ? AppColors.ink950D : textColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall!.copyWith(
                letterSpacing: 0.5,
                fontSize: 9,
                color: isDark ? pt.ink500 : textColor.withAlpha(160),
              ),
            ),
          ],
        ),
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

// ── Overview tab ──────────────────────────────────────────────────────────────

class _ProfileOverviewTab extends ConsumerWidget {
  const _ProfileOverviewTab({required this.pet});

  final Pet pet;

  static IconData _iconForType(MedicalRecordType type) => switch (type) {
    MedicalRecordType.vaccine            => Icons.vaccines_rounded,
    MedicalRecordType.medication         => Icons.medication_outlined,
    MedicalRecordType.allergy            => Icons.warning_amber_outlined,
    MedicalRecordType.surgery            => Icons.local_hospital_outlined,
    MedicalRecordType.parasitePrevention => Icons.bug_report_outlined,
    MedicalRecordType.other              => Icons.medical_services_outlined,
  };

  static String _dueDateLabel(MedicalRecord r) {
    final due = r.nextDueAt ?? r.expiresAt;
    if (due == null) return r.administeredAt != null ? 'Recorded' : 'No date';
    final today = DateUtils.dateOnly(DateTime.now());
    final dueDay = DateUtils.dateOnly(due);
    final diff = dueDay.difference(today).inDays;
    if (diff < 0) return 'Overdue by ${(-diff)} day${(-diff) == 1 ? '' : 's'}';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final recordsAsync = ref.watch(healthVaultControllerProvider);

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
                  _SectionLabel(label: 'Upcoming care'),
                  const SizedBox(height: 12),
                  ...recordsAsync.when(
                    loading: () => [
                      const _ProfileRowSkeleton(),
                      const SizedBox(height: 10),
                      const _ProfileRowSkeleton(),
                    ],
                    error: (e, st) => [
                      PetfolioEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Could not load care records',
                      ),
                    ],
                    data: (records) {
                      if (records.isEmpty) {
                        return [
                          const PetfolioEmptyState(
                            icon: Icons.medical_services_outlined,
                            title: 'No upcoming care records',
                          ),
                        ];
                      }
                      final top = records.take(2).toList();
                      return [
                        for (var i = 0; i < top.length; i++) ...[
                          _ReminderCard(
                            icon: _iconForType(top[i].recordType),
                            title: top[i].name,
                            subtitle: _dueDateLabel(top[i]),
                            accentColor: pet.speciesEnum.accent,
                          ),
                          if (i < top.length - 1) const SizedBox(height: 10),
                        ],
                      ];
                    },
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'Social'),
                  const SizedBox(height: 12),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/social/profile/${pet.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.mulberry500.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.dynamic_feed_rounded,
                                  color: AppColors.mulberry500, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'View Social Profile',
                                    style: tt.titleSmall!.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Posts, likes, and activity for ${pet.name}',
                                    style: tt.bodySmall!.copyWith(color: pt.ink500),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: pt.ink300, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
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

    final weekGoalHit = ref.watch(
      careDashboardProvider.select((s) => s.weekGoalHit),
    );
    final goalsData = weekGoalHit.value;

    final todayTasks = ref.watch(
      careDashboardProvider.select((s) => s.todayTasks),
    );
    final walkDue = todayTasks.value
            ?.any((t) => t.taskType == CareTaskType.walk && !t.isCompleted) ==
        true;

    final doneTasks = todayTasks.value?.where((t) => t.isCompleted).length ?? 0;
    final totalTasks = todayTasks.value?.length ?? 0;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (walkDue) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(46),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Walk due',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.06 * 11,
                                color: Colors.white.withAlpha(220),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PetAvatar(
                        imageUrl: pet.avatarUrl,
                        size: PetAvatarSize.xl,
                        initials: pet.name.isNotEmpty ? pet.name[0] : null,
                        borderColor: Colors.white.withAlpha(180),
                        semanticLabel: pet.name,
                      ),
                      if (totalTasks > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(46),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$doneTasks/$totalTasks done',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withAlpha(220),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Semantics(
                label: '$streakLabel days on track health streak',
                excludeSemantics: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      streakLabel,
                      style: const TextStyle(
                        fontFamily: 'Fredoka',
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
              ),
              const SizedBox(height: 14),
              Row(
                children: List.generate(7, (i) {
                  final hit = goalsData != null && i < goalsData.length
                      ? goalsData[i]
                      : false;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                      height: 28,
                      decoration: BoxDecoration(
                        color: hit
                            ? Colors.white.withAlpha(217)
                            : Colors.white.withAlpha(64),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
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
    final tt = Theme.of(context).textTheme;
    return Text(
      label.toUpperCase(),
      style: tt.labelSmall!.copyWith(
        letterSpacing: 0.96,
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
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
                    style: tt.titleSmall!.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodySmall!.copyWith(color: pt.ink500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {},
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Mark done'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Care Tab ──────────────────────────────────────────────────────────

class _ProfileCareTab extends ConsumerWidget {
  const _ProfileCareTab();

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
                    (_) => const _ProfileRowSkeleton(),
                  ),
                  error: (e, _) => [
                    PetfolioEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load tasks',
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
                          const PetfolioEmptyState(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'No tasks for today',
                          ),
                        ]
                      : tasks.map((t) => _CareTaskRow(task: t)).toList(),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ── Profile Awards Tab ────────────────────────────────────────────────────────

class _BadgeDef {
  const _BadgeDef({
    required this.type,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.earnHint,
    required this.color,
  });

  final String type;
  final String name;
  final String emoji;
  final IconData icon;
  final String earnHint;
  final Color color;
}

const _badgeCatalog = [
  _BadgeDef(
    type: 'first_log',
    name: 'First Care Log',
    emoji: '🐾',
    icon: Icons.favorite_rounded,
    earnHint: 'Log your first care activity',
    color: Color(0xFFEC4899),
  ),
  _BadgeDef(
    type: '3_day_streak',
    name: '3-Day Streak',
    emoji: '🔥',
    icon: Icons.local_fire_department_rounded,
    earnHint: 'Complete care 3 days in a row',
    color: Color(0xFFF97316),
  ),
  _BadgeDef(
    type: '7_day_hero',
    name: '7-Day Hero',
    emoji: '🏆',
    icon: Icons.military_tech_rounded,
    earnHint: 'Complete care 7 days in a row',
    color: Color(0xFFF59E0B),
  ),
  _BadgeDef(
    type: 'routine_master',
    name: 'Routine Master',
    emoji: '⭐',
    icon: Icons.star_rounded,
    earnHint: 'Complete all tasks for a full week',
    color: Color(0xFF8B5CF6),
  ),
  _BadgeDef(
    type: '30_day_legend',
    name: '30-Day Legend',
    emoji: '👑',
    icon: Icons.emoji_events_rounded,
    earnHint: 'Maintain a 30-day care streak',
    color: Color(0xFF6366F1),
  ),
  _BadgeDef(
    type: 'care_champion',
    name: 'Care Champion',
    emoji: '💎',
    icon: Icons.diamond_rounded,
    earnHint: 'Unlock all other badges',
    color: Color(0xFF14B8A6),
  ),
];

class _ProfileAwardsTab extends ConsumerWidget {
  const _ProfileAwardsTab({required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awardsAsync = ref.watch(petAwardsSummaryProvider(petId));

    return Builder(builder: (ctx) {
      return CustomScrollView(
        key: const PageStorageKey<String>('pet_profile_awards'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(ctx),
          ),
          awardsAsync.when(
            loading: () => const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 100),
              sliver: SliverToBoxAdapter(child: _AwardsStatsSkeleton()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: PetfolioEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load awards',
                action: TextButton.icon(
                  onPressed: () => ref.invalidate(petAwardsSummaryProvider(petId)),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ),
            ),
            data: (summary) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _AwardsStatsRow(summary: summary),
                  const SizedBox(height: 24),
                  const _SectionLabel(label: 'Badges'),
                  const SizedBox(height: 12),
                  _BadgeGrid(
                    unlockedTypes: summary.unlockedTypes,
                    unlockedBadges: summary.unlockedBadges,
                  ),
                  if (summary.logsCount > 0) ...[
                    const SizedBox(height: 20),
                    _XpProgressCard(summary: summary),
                  ],
                ]),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _AwardsStatsRow extends StatelessWidget {
  const _AwardsStatsRow({required this.summary});

  final PetAwardsSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: [
        _AwardsStatCard(
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFF97316),
          label: 'Current Streak',
          value: '${summary.currentStreak}',
          unit: 'days',
        ),
        _AwardsStatCard(
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFFF59E0B),
          label: 'Best Streak',
          value: '${summary.bestStreak}',
          unit: 'days',
        ),
        _AwardsStatCard(
          icon: Icons.bolt_rounded,
          iconColor: const Color(0xFF8B5CF6),
          label: 'Total XP',
          value: _formatXp(summary.totalXp),
          unit: 'points',
        ),
        _AwardsStatCard(
          icon: Icons.military_tech_rounded,
          iconColor: AppColors.meadow500,
          label: 'Badges',
          value: '${summary.unlockedBadges.length}',
          unit: 'of ${_badgeCatalog.length}',
        ),
      ],
    );
  }

  static String _formatXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return '$xp';
  }
}

class _AwardsStatCard extends StatelessWidget {
  const _AwardsStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: pt.line200, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: tt.labelSmall!.copyWith(color: pt.ink500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: tt.titleLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        unit,
                        style: tt.labelSmall!.copyWith(color: pt.ink500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({
    required this.unlockedTypes,
    required this.unlockedBadges,
  });

  final Set<String> unlockedTypes;
  final List<UnlockedBadge> unlockedBadges;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: _badgeCatalog.map((def) {
        final unlocked = unlockedTypes.contains(def.type);
        final unlockedAt = unlockedBadges
            .where((b) => b.badgeType == def.type)
            .map((b) => b.unlockedAt)
            .firstOrNull;
        return _BadgeCard(
          def: def,
          unlocked: unlocked,
          unlockedAt: unlockedAt,
        );
      }).toList(),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.def,
    required this.unlocked,
    this.unlockedAt,
  });

  final _BadgeDef def;
  final bool unlocked;
  final DateTime? unlockedAt;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final iconColor = unlocked ? def.color : pt.ink300;
    final bgColor = unlocked ? def.color.withAlpha(20) : pt.surface2;
    final borderColor = unlocked ? def.color.withAlpha(60) : pt.line200;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: borderColor, width: unlocked ? 1.5 : 0.5),
      ),
      elevation: unlocked ? 0 : 0,
      shadowColor: unlocked ? def.color.withAlpha(30) : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(def.icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  def.name,
                  style: tt.labelSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: unlocked ? cs.onSurface : pt.ink300,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (unlocked && unlockedAt != null)
                  Text(
                    _formatDate(unlockedAt!),
                    style: TextStyle(
                      fontSize: 10,
                      color: def.color,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  )
                else if (!unlocked)
                  Text(
                    def.earnHint,
                    style: tt.labelSmall!.copyWith(
                        color: pt.ink300, fontSize: 9, height: 1.2),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (unlocked)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.verified_rounded, size: 14, color: def.color),
            ),
          if (!unlocked)
            Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.lock_outline_rounded, size: 12, color: pt.ink300),
            ),
        ],
      ),
    );
  }
}

class _XpProgressCard extends StatelessWidget {
  const _XpProgressCard({required this.summary});

  final PetAwardsSummary summary;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    const milestones = [100, 250, 500, 1000, 2500, 5000];
    final nextMilestone = milestones.firstWhere(
      (m) => m > summary.totalXp,
      orElse: () => summary.totalXp + 1000,
    );
    final prevMilestone = milestones
        .where((m) => m <= summary.totalXp)
        .fold(0, (a, b) => b);
    final progress = nextMilestone == prevMilestone
        ? 1.0
        : (summary.totalXp - prevMilestone) /
            (nextMilestone - prevMilestone).clamp(1, double.infinity);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: pt.line200, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 6),
                Text(
                  'XP Progress',
                  style: tt.labelMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: pt.ink500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.totalXp} / $nextMilestone XP',
                  style: tt.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: const Color(0xFF8B5CF6).withAlpha(20),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${nextMilestone - summary.totalXp} XP to next milestone',
              style: tt.labelSmall!.copyWith(color: pt.ink300),
            ),
          ],
        ),
      ),
    );
  }
}

class _AwardsStatsSkeleton extends StatelessWidget {
  const _AwardsStatsSkeleton();

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: List.generate(
        4,
        (_) => Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: pt.line200, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const SkeletonLoader(width: 36, height: 36, borderRadius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SkeletonLoader(width: 60, height: 10),
                      SizedBox(height: 6),
                      SkeletonLoader(width: 40, height: 18),
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
}

// ── Profile Health Tab ────────────────────────────────────────────────────────

class _ProfileHealthTab extends ConsumerWidget {
  const _ProfileHealthTab();

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
                    (_) => const _ProfileRowSkeleton(),
                  ),
                  error: (e, _) => [
                    PetfolioEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load health records',
                      action: TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(healthVaultControllerProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                  data: (records) => records.isEmpty
                      ? [
                          const PetfolioEmptyState(
                            icon: Icons.medical_services_outlined,
                            title: 'No medical records yet',
                          ),
                        ]
                      : records
                          .map((r) => _HealthRecordRow(record: r))
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
  const _CareTaskRow({required this.task});
  final CareTask task;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final accent = task.isCompleted ? AppColors.meadow500 : cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: pt.line200, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      style: tt.titleSmall!.copyWith(fontWeight: FontWeight.w600),
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
                      style: tt.bodySmall!.copyWith(color: pt.ink500),
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
      ),
    );
  }
}

// ── Health record row ─────────────────────────────────────────────────────────

class _HealthRecordRow extends StatelessWidget {
  const _HealthRecordRow({required this.record});
  final MedicalRecord record;

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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final (statusLabel, statusColor) = switch (true) {
      _ when record.isOverdue      => ('Overdue', AppColors.coral500),
      _ when record.isExpiringSoon => ('Due soon', const Color(0xFFF59E0B)),
      _                            => ('Active', AppColors.meadow500),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: pt.line200, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      style: tt.titleSmall!.copyWith(fontWeight: FontWeight.w600),
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
                      style: tt.bodySmall!.copyWith(color: pt.ink500),
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
      ),
    );
  }
}

// ── Shared tab helpers ────────────────────────────────────────────────────────

class _ProfileRowSkeleton extends StatelessWidget {
  const _ProfileRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SkeletonLoader(width: 40, height: 40, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: double.infinity, height: 14),
                SizedBox(height: 6),
                SkeletonLoader(width: 80, height: 11),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonLoader(width: 22, height: 22, borderRadius: 999),
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
  const _EmptyPetsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PetfolioEmptyState(
        icon: Icons.pets_rounded,
        title: 'No pets yet',
        subtitle: 'Add your first pet to get started.',
        action: FilledButton.icon(
          onPressed: () => context.go('/onboarding'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add a pet'),
        ),
      ),
    );
  }
}
