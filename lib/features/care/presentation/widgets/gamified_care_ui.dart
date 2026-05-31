import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../../../../core/models/pet.dart';
import '../../data/models/pet_level.dart';
import '../controllers/care_dashboard_controller.dart';
import '../controllers/pet_awards_provider.dart';

// ── Gamified Care Header ──────────────────────────────────────────────────────

class CareGamifiedHeader extends ConsumerStatefulWidget {
  const CareGamifiedHeader({
    super.key,
    required this.activePet,
    required this.dashboard,
  });

  final Pet activePet;
  final DailyRoutineState dashboard;

  @override
  ConsumerState<CareGamifiedHeader> createState() => _CareGamifiedHeaderState();
}

class _CareGamifiedHeaderState extends ConsumerState<CareGamifiedHeader>
    with TickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _bounceAnim;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.40).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.75, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petId = widget.activePet.id;

    // Real streak from realtime stream already in dashboard state.
    final streak = widget.dashboard.streak.maybeWhen(
      data: (s) => s.currentStreak,
      orElse: () => 0,
    );

    // Real XP + level from Supabase RPC (same provider used by profile screen).
    final awardsAsync = ref.watch(petAwardsSummaryProvider(petId));
    final totalXp = awardsAsync.maybeWhen(
      data: (a) => a.totalXp,
      orElse: () => 0,
    );
    final lv = PetLevel.fromXp(totalXp);

    final sp = widget.activePet.speciesEnum;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color headerColor = sp.resolvedAccent(isDark);
    final dbAccent = widget.activePet.accentColor;
    if (dbAccent != null && dbAccent.isNotEmpty && dbAccent != '#FF6B9D') {
      try {
        final hex = dbAccent.replaceAll('#', '');
        if (hex.length == 6) {
          headerColor = Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          headerColor = Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
    }

    return WaveHeader(
      color: headerColor,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + 76.0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Streak flame circle ─────────────────────────────────────
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseScale.value,
                          child: Opacity(opacity: _pulseOpacity.value, child: child),
                        ),
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.tangerine, width: 3),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _bounceCtrl,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _bounceAnim.value),
                          child: child,
                        ),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment(0, 0.2),
                              radius: 0.7,
                              colors: [AppColors.sunny, AppColors.tangerine],
                              stops: [0.0, 0.7],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.tangerine,
                                blurRadius: 28,
                                offset: Offset(0, 14),
                                spreadRadius: -8,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 36, height: 1.0)),
                              const SizedBox(height: 2),
                              Text(
                                '$streak',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const Text(
                                'DAY STREAK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // ── XP & level (real data) ───────────────────────────────────
                Expanded(
                  child: awardsAsync.when(
                    loading: () => _LevelSkeleton(),
                    error: (e, st) => _LevelContent(lv: PetLevel.fromXp(0)),
                    data: (_) => _LevelContent(lv: lv),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 55.0),
        ],
      ),
    );
  }
}

class _LevelContent extends StatelessWidget {
  const _LevelContent({required this.lv});
  final PetLevel lv;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Lv ${lv.level}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              lv.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white.withAlpha(200),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${lv.currentXp} / ${lv.levelEndXp} XP',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withAlpha(200),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withAlpha(56),
            border: Border.all(color: Colors.white.withAlpha(40)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: lv.progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  colors: [AppColors.sunny, AppColors.tangerine, AppColors.poppy],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!lv.isMaxLevel)
          Text.rich(
            TextSpan(
              text: '${lv.xpToNext} XP to ',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withAlpha(200),
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: 'Lv ${lv.level + 1} · ${lv.nextTitle}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'Max level reached!',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withAlpha(200),
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class _LevelSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: const [
        SkeletonLoader(width: 100, height: 22, borderRadius: 8),
        SizedBox(height: 8),
        SkeletonLoader(width: 80, height: 12, borderRadius: 6),
        SizedBox(height: 8),
        SkeletonLoader(width: double.infinity, height: 12, borderRadius: 999),
        SizedBox(height: 8),
        SkeletonLoader(width: 130, height: 11, borderRadius: 6),
      ],
    );
  }
}

// ── Weekly Activity Chart (real weekGoalHit data) ─────────────────────────────

class CareGamifiedWeeklyChart extends StatelessWidget {
  const CareGamifiedWeeklyChart({
    super.key,
    required this.selectedDay,
    required this.weekHits,
    required this.progressPercent,
  });

  final DateTime selectedDay;
  final List<bool> weekHits;
  final double progressPercent;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _colors = [
    AppColors.tangerine, AppColors.poppy, AppColors.mint,
    AppColors.sunny, AppColors.lilac, AppColors.tangerine, AppColors.poppy,
  ];

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    // weekHits is 7 bools Mon→Sun. The last entry covers today.
    // Use real hit bools to drive bar heights.
    final today = DateUtils.dateOnly(DateTime.now());
    final todayWeekday = today.weekday; // 1=Mon .. 7=Sun
    final weekStart = today.subtract(Duration(days: todayWeekday - 1));

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radius2xl),
        border: Border.all(color: pt.line),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: SizedBox(
        height: 128,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final dayDate = weekStart.add(Duration(days: i));
            final isFuture = dayDate.isAfter(today);
            final isToday = dayDate == today;

            // For past/today: use real hit bool; future: show faint placeholder.
            final hit = i < weekHits.length ? weekHits[i] : false;
            final h = isFuture
                ? 0.15
                : isToday
                    ? progressPercent.clamp(0.15, 1.0)
                    : (hit ? 0.85 : 0.20);

            final color = isFuture ? pt.line : (hit || isToday ? _colors[i] : pt.ink300);

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 20,
                    child: isToday
                        ? const Align(
                            alignment: Alignment.bottomCenter,
                            child: Text('🐾', style: TextStyle(fontSize: 13)),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: h,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: isToday
                                ? Border.all(color: AppColors.ink950, width: 2)
                                : null,
                            boxShadow: (isToday && !isFuture)
                                ? [
                                    BoxShadow(
                                      color: color.withAlpha(100),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                      spreadRadius: -4,
                                    )
                                  ]
                                : null,
                            gradient: isFuture
                                ? null
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      color,
                                      Color.lerp(color, Colors.white, 0.45)!,
                                    ],
                                  ),
                            color: isFuture ? pt.surface2 : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dayLetters[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isToday
                          ? AppColors.ink950
                          : (isFuture ? pt.ink300 : pt.ink500),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Trophy Room (real badges) ─────────────────────────────────────────────────

class CareGamifiedTrophyRoom extends ConsumerWidget {
  const CareGamifiedTrophyRoom({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awardsAsync = ref.watch(petAwardsSummaryProvider(petId));

    final ownedTypes = awardsAsync.maybeWhen(
      data: (a) => a.unlockedTypes,
      orElse: () => <String>{},
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: kBadgeCatalog.length,
      itemBuilder: (context, i) {
        final badge = kBadgeCatalog[i];
        return PfAchievementTile(
          emoji: badge.emoji,
          color: badge.color,
          label: badge.label,
          owned: ownedTypes.contains(badge.type),
          index: i,
        );
      },
    );
  }
}
