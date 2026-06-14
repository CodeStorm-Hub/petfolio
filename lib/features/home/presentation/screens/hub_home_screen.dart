import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/care/data/models/care_task.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/data/models/pet_level.dart';
import 'package:petfolio/features/care/presentation/controllers/care_streak_stream_provider.dart';
import 'package:petfolio/features/care/presentation/controllers/pet_awards_provider.dart';
import 'package:petfolio/features/pet_profile/data/models/pet.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';

import '../widgets/all_features_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HubHomeScreen — Pathao-inspired bento grid hub for PetFolio.
// Replaces PetProfileScreen at '/home'. PetProfileScreen remains accessible
// at '/social/profile/:id' and via the pet avatar in AppHeader.
// ─────────────────────────────────────────────────────────────────────────────

class HubHomeScreen extends ConsumerStatefulWidget {
  const HubHomeScreen({super.key});

  @override
  ConsumerState<HubHomeScreen> createState() => _HubHomeScreenState();
}

class _HubHomeScreenState extends ConsumerState<HubHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  int _selectedDealChip = 0;

  static const _dealChips = ['All', 'Food', 'Grooming', 'Health', 'Toys'];

  // Hero: 140dp greeting area + 38dp pet-card bleed below wave.
  static const _heroContentHeight = 140.0 + 38.0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePet = ref.watch(activePetControllerProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activePet == null) {
      return Scaffold(
        backgroundColor: pt.surface1,
        body: const Center(child: TailWagLoader()),
      );
    }

    final streakAsync = ref.watch(careStreakRealtimeProvider(activePet.id));
    final streak = streakAsync.maybeWhen(
      data: (s) => s.currentStreak,
      orElse: () => 0,
    );

    final todayTasksAsync = ref.watch(
      careDashboardProvider.select((s) => s.todayTasks),
    );
    final todayTasks = todayTasksAsync.maybeWhen(
      data: (t) => t,
      orElse: () => <CareTask>[],
    );
    final doneTasks = todayTasks.where((t) => t.isCompleted).length;
    final totalTasks = todayTasks.length;

    return FadeTransition(
      opacity: _fadeAnim,
      child: PfModuleScaffold(
        expandedHeight: pfHeroHeight(context, _heroContentHeight),
        heroContent: _WaveHeroSection(
          pet: activePet,
          streak: streak,
          doneTasks: doneTasks,
          totalTasks: totalTasks,
          isDark: isDark,
          pt: pt,
        ),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          SliverToBoxAdapter(
            child: _SectionHeader(
              pt: pt,
              title: 'Services',
              trailing: GestureDetector(
                onTap: () => AllFeaturesSheet.show(context),
                child: Text(
                  'All ›',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tangerine,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _BentoGrid(
              doneTasks: doneTasks,
              totalTasks: totalTasks,
              streak: streak,
              isDark: isDark,
              pt: pt,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(child: _SectionHeader(pt: pt, title: 'Quick Actions')),
          SliverToBoxAdapter(child: _QuickActionsRow(pet: activePet)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: _SectionHeader(
              pt: pt,
              title: 'Pet Spotlight',
              trailing: GestureDetector(
                onTap: () => context.go('/social'),
                child: Text(
                  'See All ›',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tangerine,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _SpotlightCarousel(isDark: isDark, pt: pt)),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverToBoxAdapter(
            child: _SectionHeader(
              pt: pt,
              title: 'Exclusive Deals',
              trailing: GestureDetector(
                onTap: () => context.go('/marketplace'),
                child: Text(
                  'See All ›',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tangerine,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _DealsSection(
              chips: _dealChips,
              selectedIndex: _selectedDealChip,
              onChipTap: (i) => setState(() => _selectedDealChip = i),
              isDark: isDark,
              pt: pt,
              onTap: () => context.go('/marketplace'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wave Hero Section — species-colored wave + greeting + floating pet card
// ─────────────────────────────────────────────────────────────────────────────

class _WaveHeroSection extends StatelessWidget {
  const _WaveHeroSection({
    required this.pet,
    required this.streak,
    required this.doneTasks,
    required this.totalTasks,
    required this.isDark,
    required this.pt,
  });

  final Pet pet;
  final int streak;
  final int doneTasks;
  final int totalTasks;
  final bool isDark;
  final PetfolioThemeExtension pt;

  String _greeting() {
    final hour = DateTime.now().hour;
    final name = pet.name;
    if (hour < 5) return 'Up late, $name? 🌙';
    if (hour < 12) return 'Good morning, $name! 🌅';
    if (hour < 17) return 'Good afternoon, $name! ☀️';
    if (hour < 21) return 'Good evening, $name! 🌆';
    return 'Good night, $name! 🌙';
  }

  String _moodLine() {
    final remaining = totalTasks - doneTasks;
    if (totalTasks > 0 && remaining == 0) return '${pet.name} is well cared for ✨';
    if (streak >= 30) return '${pet.name} is legendary! 🏆';
    if (streak >= 7) return '${pet.name} is on a winning streak 🔥';
    if (streak > 0 && remaining > 0) return '${pet.name} has $remaining tasks left 🎯';
    if (streak > 0) return '${pet.name} is thriving today 🌟';
    if (remaining > 0) return '${pet.name} has $remaining tasks today 📋';
    return '${pet.name} is ready for a new day 🌱';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final waveColor = pet.speciesEnum.resolvedAccent(isDark);
    // pet emoji watermark in top-right of wave
    final speciesEmoji = pet.speciesEnum.emoji;

    const cardH = 84.0;
    const cardOverlap = 38.0;
    final waveH = topPad + kShellHeaderHeight + 140.0;

    return SizedBox(
      height: waveH + cardOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Species-colored wave background ────────────────────────────
          WaveHeader(
            color: waveColor,
            height: waveH,
            child: Stack(
              children: [
                // Watermark emoji
                Positioned(
                  right: 16,
                  top: topPad + kShellHeaderHeight + 4,
                  child: Opacity(
                    opacity: 0.18,
                    child: Text(
                      speciesEmoji,
                      style: const TextStyle(fontSize: 96),
                    ),
                  ),
                ),
                // Greeting content
                Padding(
                  padding: EdgeInsets.fromLTRB(20, topPad + kShellHeaderHeight + 14, 120, 50),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(210),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _moodLine(),
                        style: GoogleFonts.sora(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Floating pet card — straddles the wave boundary ────────────
          Positioned(
            top: waveH - cardH + cardOverlap,
            left: 16,
            right: 16,
            child: _PetHeroCard(
              pet: pet,
              streak: streak,
              doneTasks: doneTasks,
              totalTasks: totalTasks,
              isDark: isDark,
              pt: pt,
              accentColor: waveColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pet Hero Card — white card floating at the wave boundary
// ─────────────────────────────────────────────────────────────────────────────

class _PetHeroCard extends ConsumerWidget {
  const _PetHeroCard({
    required this.pet,
    required this.streak,
    required this.doneTasks,
    required this.totalTasks,
    required this.isDark,
    required this.pt,
    required this.accentColor,
  });

  final Pet pet;
  final int streak;
  final int doneTasks;
  final int totalTasks;
  final bool isDark;
  final PetfolioThemeExtension pt;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awardsAsync = ref.watch(petAwardsSummaryProvider(pet.id));
    final petLevel = awardsAsync.maybeWhen(
      data: (a) => PetLevel.fromXp(a.totalXp),
      orElse: () => null,
    );
    final ageYears = pet.ageInYears;
    final agePart = ageYears != null
        ? '$ageYears ${ageYears == 1 ? 'year' : 'years'}'
        : null;
    final subLabel = [
      pet.speciesEnum.label,
      ?agePart,
    ].join(' · ');

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? pt.surface2 : AppColors.surface0,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowE3D : AppColors.shadowE3L,
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: accentColor.withAlpha(isDark ? 35 : 25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          PetAvatar(
            imageUrl: pet.avatarUrl,
            species: pet.speciesEnum,
            size: PetAvatarSize.lg,
            showRing: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pet.name,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: pt.ink950,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: pt.ink500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Streak pill (primary) or task progress (fallback)
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.sunnySoftD : AppColors.sunnySoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.sunny.withAlpha(isDark ? 80 : 55),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sunny700,
                        ),
                      ),
                    ],
                  ),
                )
              else if (totalTasks > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(isDark ? 45 : 28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$doneTasks/$totalTasks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              if (petLevel != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFF5D56E)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Lv ${petLevel.level} · ${petLevel.currentXp} XP',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.pt,
    required this.title,
    this.trailing,
  });

  final PetfolioThemeExtension pt;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: pt.ink500,
              letterSpacing: 0.8,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card decoration — white elevated (light) / surface2 (dark)
// ─────────────────────────────────────────────────────────────────────────────

BoxDecoration _bentoCardDecoration(
  bool isDark,
  PetfolioThemeExtension pt, {
  Color? glow,
}) =>
    BoxDecoration(
      color: isDark ? pt.surface2 : Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: isDark ? Border.all(color: Colors.white.withAlpha(14)) : null,
      boxShadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withAlpha(55),
                blurRadius: 18,
                offset: const Offset(0, 5),
                spreadRadius: -3,
              ),
            ]
          : [
              BoxShadow(
                color: AppColors.shadowE3L,
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              if (glow != null)
                BoxShadow(
                  color: glow.withAlpha(22),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
            ],
    );

// ─────────────────────────────────────────────────────────────────────────────
// Bento Grid — Pathao-inspired asymmetric layout
//   Care (2× tall, left) | Social + Match stacked (right)
//   Market | Vet
//   All Features (full-width footer)
// ─────────────────────────────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  const _BentoGrid({
    required this.doneTasks,
    required this.totalTasks,
    required this.streak,
    required this.isDark,
    required this.pt,
  });

  final int doneTasks;
  final int totalTasks;
  final int streak;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    const rowH = 148.0;
    const careH = rowH * 2 + gap;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: careH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CareTile(
                    doneTasks: doneTasks,
                    totalTasks: totalTasks,
                    streak: streak,
                    isDark: isDark,
                    pt: pt,
                    onTap: () => context.go('/care'),
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _BentoTile(
                          label: 'PawsFeed',
                          sub: 'Social & stories',
                          emoji: '🐾',
                          accent: AppColors.poppy,
                          isDark: isDark,
                          pt: pt,
                          onTap: () => context.go('/social'),
                        ),
                      ),
                      const SizedBox(height: gap),
                      Expanded(
                        child: _BentoTile(
                          label: 'Match',
                          sub: 'Find playmates',
                          emoji: '💛',
                          accent: AppColors.lilac,
                          isDark: isDark,
                          pt: pt,
                          onTap: () => context.go('/matching'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: gap),
          SizedBox(
            height: rowH,
            child: Row(
              children: [
                Expanded(
                  child: _BentoTile(
                    label: 'Market',
                    sub: 'Shop for pets',
                    emoji: '🛍️',
                    accent: AppColors.mint,
                    isDark: isDark,
                    pt: pt,
                    onTap: () => context.go('/marketplace'),
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: _BentoTile(
                    label: 'Vet',
                    sub: 'Book a vet',
                    emoji: '🩺',
                    accent: AppColors.sky,
                    isDark: isDark,
                    pt: pt,
                    onTap: () => context.push('/appointments'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: gap),
          _AllTile(
            isDark: isDark,
            pt: pt,
            onTap: () => AllFeaturesSheet.show(context),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Care Tile — 2× tall white elevated card, live streak + progress
// ─────────────────────────────────────────────────────────────────────────────

class _CareTile extends StatelessWidget {
  const _CareTile({
    required this.doneTasks,
    required this.totalTasks,
    required this.streak,
    required this.isDark,
    required this.pt,
    required this.onTap,
  });

  final int doneTasks;
  final int totalTasks;
  final int streak;
  final bool isDark;
  final PetfolioThemeExtension pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = totalTasks == 0
        ? 0.0
        : (doneTasks / totalTasks).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          decoration: _bentoCardDecoration(isDark, pt, glow: AppColors.sunny),
          child: Stack(
            children: [
              // Emoji — vertically centered on the right, behind text
              Positioned(
                top: 0,
                bottom: 0,
                right: 14,
                child: Center(
                  child: Opacity(
                    opacity: isDark ? 0.28 : 0.82,
                    child: const Text('🔥', style: TextStyle(fontSize: 88)),
                  ),
                ),
              ),
              // Content — badge top, title+data bottom
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.sunny,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '🔥 $streak day${streak == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.sunny.withAlpha(28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Start streak',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sunny700,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      'Care',
                      style: GoogleFonts.sora(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: pt.ink950,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      totalTasks > 0
                          ? '$doneTasks/$totalTasks done today'
                          : 'Daily routines',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: pt.ink500,
                      ),
                    ),
                    if (totalTasks > 0) ...[
                      const SizedBox(height: 10),
                      // Constrain width to leave room for emoji
                      FractionallySizedBox(
                        widthFactor: 0.62,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: AppColors.sunny.withAlpha(28),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sunny),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento Tile — white elevated card with large emoji illustration
// ─────────────────────────────────────────────────────────────────────────────

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.label,
    required this.sub,
    required this.emoji,
    required this.accent,
    required this.isDark,
    required this.pt,
    required this.onTap,
  });

  final String label;
  final String sub;
  final String emoji;
  final Color accent;
  final bool isDark;
  final PetfolioThemeExtension pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          decoration: _bentoCardDecoration(isDark, pt, glow: accent),
          child: Stack(
            children: [
              Positioned(
                bottom: 10,
                right: 10,
                child: Opacity(
                  opacity: isDark ? 0.28 : 0.82,
                  child: Text(emoji, style: const TextStyle(fontSize: 56)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.sora(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: pt.ink950,
                        height: 1.0,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// All Tile — full-width tangerine-tinted CTA to AllFeaturesSheet
// ─────────────────────────────────────────────────────────────────────────────

class _AllTile extends StatelessWidget {
  const _AllTile({required this.isDark, required this.pt, required this.onTap});
  final bool isDark;
  final PetfolioThemeExtension pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.tangerine.withAlpha(35)
                : AppColors.tangerineSoft,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.tangerine.withAlpha(isDark ? 45 : 38),
            ),
          ),
          child: Row(
            children: [
              Text(
                'All Features',
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tangerine,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.tangerine, size: 20),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tangerine.withAlpha(28),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.grid_view_rounded,
                    color: AppColors.tangerine, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Row — horizontal pill cards for common tasks
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _QuickAction(
        icon: Icons.storefront_rounded,
        label: 'Shop for ${pet.name}',
        sub: 'Pet food & supplies',
        color: AppColors.mint,
        soft: isDark ? AppColors.mintSoftD : AppColors.mintSoft,
        route: '/marketplace',
      ),
      _QuickAction(
        icon: Icons.add_task_rounded,
        label: 'Log a task',
        sub: 'Add to today\'s care',
        color: AppColors.sunny,
        soft: isDark ? AppColors.sunnySoftD : AppColors.sunnySoft,
        route: '/care',
      ),
      _QuickAction(
        icon: Icons.camera_alt_rounded,
        label: 'Post a moment',
        sub: 'Share to PawsFeed',
        color: AppColors.poppy,
        soft: isDark ? AppColors.poppySoftD : AppColors.poppySoft,
        route: '/social/create-post',
        push: true,
      ),
      _QuickAction(
        icon: Icons.medical_services_rounded,
        label: 'Book a vet',
        sub: 'Nearby clinics',
        color: AppColors.sky,
        soft: isDark ? AppColors.skySoftD : AppColors.skySoft,
        route: '/appointments',
        push: true,
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'My Activity',
        sub: 'Orders & appointments',
        color: AppColors.tangerine,
        soft: isDark ? AppColors.tangerineSoftD : AppColors.tangerineSoft,
        route: '/activity',
      ),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _QuickActionCard(action: actions[i]),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          if (action.push) {
            context.push(action.route);
          } else {
            context.go(action.route);
          }
        },
        child: Container(
          width: 175,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: action.soft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: action.color.withAlpha(40)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: action.color.withAlpha(40),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(action.icon, color: action.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: pt.ink950,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.soft,
    required this.route,
    this.push = false,
  });
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final Color soft;
  final String route;
  final bool push;
}

// ─────────────────────────────────────────────────────────────────────────────
// Spotlight Carousel — horizontal pet/activity highlight cards
// ─────────────────────────────────────────────────────────────────────────────

class _SpotlightCarousel extends StatelessWidget {
  const _SpotlightCarousel({required this.isDark, required this.pt});
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SpotlightCard(
        emoji: '🐕',
        title: 'Nearby Matches',
        sub: 'Find playmates today',
        gradient: [AppColors.lilac, AppColors.sky],
        onTap: () => context.go('/matching'),
      ),
      _SpotlightCard(
        emoji: '🛍️',
        title: 'Pet Food Sale',
        sub: 'Up to 30% off brands',
        gradient: [AppColors.tangerine, AppColors.sunny],
        onTap: () => context.go('/marketplace'),
      ),
      _SpotlightCard(
        emoji: '🐾',
        title: 'Trending Posts',
        sub: 'See what\'s popular',
        gradient: [AppColors.poppy, AppColors.lilac],
        onTap: () => context.go('/social'),
      ),
      _SpotlightCard(
        emoji: '🏥',
        title: 'Book a Vet',
        sub: 'Clinics near you',
        gradient: [AppColors.mint, AppColors.sky],
        onTap: () => context.push('/appointments'),
      ),
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.gradient,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String sub;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 155,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -8,
                child: Opacity(
                  opacity: 0.25,
                  child: Text(emoji, style: const TextStyle(fontSize: 72)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Deals Section — filter chips + deal banner
// ─────────────────────────────────────────────────────────────────────────────

class _DealsSection extends StatelessWidget {
  const _DealsSection({
    required this.chips,
    required this.selectedIndex,
    required this.onChipTap,
    required this.isDark,
    required this.pt,
    required this.onTap,
  });

  final List<String> chips;
  final int selectedIndex;
  final ValueChanged<int> onChipTap;
  final bool isDark;
  final PetfolioThemeExtension pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Filter chips ───────────────────────────────────────────────
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _DealChip(
              label: chips[i],
              selected: selectedIndex == i,
              onTap: () => onChipTap(i),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Promo deal banner ──────────────────────────────────────────
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [AppColors.tangerine, AppColors.lilac],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tangerine.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -12,
                    top: -12,
                    child: Opacity(
                      opacity: 0.2,
                      child: Text(
                        '🎁',
                        style: const TextStyle(fontSize: 100),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Limited Time Offer',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '30% OFF Pet Food & Treats 🎉',
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DealChip extends StatelessWidget {
  const _DealChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.tangerine : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.tangerine
                : AppColors.ink300.withAlpha(100),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.ink500,
          ),
        ),
      ),
    );
  }
}
