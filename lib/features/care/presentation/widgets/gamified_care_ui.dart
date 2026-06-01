import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../../../../core/models/pet.dart';
import '../../data/models/care_task_log.dart';
import '../../data/models/pet_awards_summary.dart';
import '../../data/models/pet_level.dart';
import '../controllers/care_dashboard_controller.dart';
import '../controllers/pet_awards_provider.dart';

// ── Compact Hero Header ────────────────────────────────────────────────────────

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
  late final AnimationController _coinCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _coinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _coinCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    final streak = widget.dashboard.streak.maybeWhen(
      data: (s) => s.currentStreak,
      orElse: () => 0,
    );
    final awardsAsync = ref.watch(petAwardsSummaryProvider(widget.activePet.id));
    final lv = awardsAsync.maybeWhen(
      data: (a) => PetLevel.fromXp(a.totalXp),
      orElse: () => PetLevel.fromXp(0),
    );

    final tasks = widget.dashboard.tasks.value ?? [];
    final planned = tasks.where((t) => !t.isLogDerived).toList();
    final doneToday = planned.where((t) => t.isCompleted).length;
    final totalToday = planned.length;
    final pct = lv.progress.clamp(0.0, 1.0);

    // ── WaveHeader pattern (matches Home/Pets screen architecture) ──────────
    // AppShellHeader overlays at Positioned(top:0) with height = topPad + 76.
    // We reserve that space at top, then show greeting, then let the hero
    // card float at the wave boundary — exactly how PetProfileScreen works.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        WaveHeader(
          color: AppColors.tangerine,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Clear AppShellHeader ───────────────────────────────────
              SizedBox(height: topPad + 76),

              // ── Care greeting — unique copy, never duplicates hero card ──
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.activePet.name}\'s care plan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(210),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text.rich(
                      TextSpan(
                        text: streak > 1
                            ? '$streak days strong!'
                            : 'Let\'s crush today!',
                        children: const [
                          TextSpan(text: ' 🔥'),
                        ],
                      ),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.05,
                        letterSpacing: -0.3,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Breathing room: greeting height (~44px) + 33px gap + card top
              // card_top = waveHeight + 28 - 115 must be > greetingEnd
              // waveHeight = topPad + 76 + 44(greeting) + SizedBox
              // SizedBox = 120 → gap ≈ 33px on all device topPad values
              const SizedBox(height: 120),
            ],
          ),
        ),

        // ── Floating hero card (streak coin + XP bar) ─────────────────────
        // Positioned at bottom:-28 so it straddles the wave edge, matching
        // the same floating-card pattern used in PetProfileScreen.
        Positioned(
          left: 16,
          right: 16,
          bottom: -28,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF2E2E),
                  Color(0xFFFF5830),
                  AppColors.tangerine,
                ],
                stops: [0.0, 0.48, 1.0],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x60FF3D3D),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                  spreadRadius: -12,
                ),
                BoxShadow(
                  color: Color(0x20000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // Decorative paw watermark
                Positioned(
                  right: -6,
                  top: -8,
                  child: Opacity(
                    opacity: 0.16,
                    child: Transform.rotate(
                      angle: 18 * math.pi / 180,
                      child: const Icon(Icons.pets_rounded, size: 96, color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _StreakCoin(
                        streak: streak,
                        coinCtrl: _coinCtrl,
                        pulseCtrl: _pulseCtrl,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: awardsAsync.when(
                          loading: () => _HeroLevelContent(
                            lv: PetLevel.fromXp(0),
                            pct: 0,
                            doneToday: 0,
                            totalToday: totalToday,
                          ),
                          error: (_, _) => _HeroLevelContent(
                            lv: PetLevel.fromXp(0),
                            pct: 0,
                            doneToday: doneToday,
                            totalToday: totalToday,
                          ),
                          data: (_) => _HeroLevelContent(
                            lv: lv,
                            pct: pct,
                            doneToday: doneToday,
                            totalToday: totalToday,
                          ),
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

// ── Streak Coin ────────────────────────────────────────────────────────────────

class _StreakCoin extends StatelessWidget {
  const _StreakCoin({
    required this.streak,
    required this.coinCtrl,
    required this.pulseCtrl,
  });

  final int streak;
  final Animation<double> coinCtrl;
  final Animation<double> pulseCtrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding pulse ring
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, _) {
              final scale = 1.0 + pulseCtrl.value * 0.90;
              final opacity = ((1.0 - pulseCtrl.value) * 0.50).clamp(0.0, 0.50);
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(160),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // 3D Y-rotation coin
          AnimatedBuilder(
            animation: coinCtrl,
            builder: (_, child) {
              final angle = math.sin(coinCtrl.value * 2 * math.pi) * 20 * math.pi / 180;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateY(angle),
                child: child,
              );
            },
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.28, -0.42),
                  radius: 0.88,
                  colors: [
                    Color(0xFFFFF0B0),
                    Color(0xFFFFD234),
                    AppColors.tangerine,
                    AppColors.tangerine700,
                  ],
                  stops: [0.0, 0.32, 0.68, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tangerine700.withAlpha(210),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                    spreadRadius: -10,
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Specular sheen highlight
                  Positioned(
                    left: 5,
                    top: 5,
                    right: 26,
                    bottom: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withAlpha(120),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Concentric inner ring for depth
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 22, height: 1.0)),
                      const SizedBox(height: 1),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Color(0x80961400),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'DAY STREAK',
                        style: TextStyle(
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                          height: 1.3,
                        ),
                      ),
                    ],
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

// ── Hero Level Content (right side of hero card) ───────────────────────────────

class _HeroLevelContent extends StatelessWidget {
  const _HeroLevelContent({
    required this.lv,
    required this.pct,
    required this.doneToday,
    required this.totalToday,
  });

  final PetLevel lv;
  final double pct;
  final int doneToday;
  final int totalToday;

  @override
  Widget build(BuildContext context) {
    final allDone = totalToday > 0 && doneToday == totalToday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Lv ${lv.level}',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      '· ${lv.title}',
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withAlpha(220),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Show chip only when there are tasks and progress has started
            if (totalToday > 0)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey('$doneToday/$totalToday'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: allDone
                        ? AppColors.mint.withAlpha(220)
                        : Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    allDone ? 'All done! 🎉' : '$doneToday/$totalToday tasks',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: allDone ? Colors.white : AppColors.poppy700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // XP progress bar with top-shine shimmer
        Container(
          height: 13,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.black.withAlpha(45),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFE08A),
                          AppColors.sunny,
                          AppColors.tangerine,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                // Top shine overlay
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x99FFFFFF), Colors.transparent],
                        stops: [0.0, 0.55],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          lv.isMaxLevel
              ? '${lv.currentXp} XP — Max level! 👑'
              : '${lv.currentXp} / ${lv.levelEndXp} XP · ${lv.xpToNext} XP to Lv ${lv.level + 1}',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xDDFFFFFF),
            letterSpacing: 0.1,
          ),
          overflow: TextOverflow.ellipsis,
        ),
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

    final today = DateUtils.dateOnly(DateTime.now());
    final anchor = DateUtils.dateOnly(selectedDay);
    final weekStart = anchor.subtract(const Duration(days: 6));

    int hitsCount = 0;
    for (int i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      if (dayDate.isAfter(today)) break;
      if (i < weekHits.length && weekHits[i]) hitsCount++;
    }
    if (anchor == today && progressPercent >= 1.0) {
      final todaySlot = today.difference(weekStart).inDays;
      if (todaySlot >= 0 &&
          todaySlot < weekHits.length &&
          !weekHits[todaySlot]) {
        hitsCount++;
      }
    }
    final totalDaysSoFar =
        (today.difference(weekStart).inDays + 1).clamp(1, 7);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radius2xl),
        border: Border.all(color: pt.line),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '$hitsCount/$totalDaysSoFar goals this week',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pt.ink500,
                ),
              ),
              const Spacer(),
              if (hitsCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$hitsCount 🔥',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mint700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final dayDate = weekStart.add(Duration(days: i));
                final isFuture = dayDate.isAfter(today);
                final isToday = dayDate == today;

                final hit = i < weekHits.length ? weekHits[i] : false;
                final h = isFuture
                    ? 0.08
                    : isToday
                        ? progressPercent.clamp(0.06, 1.0)
                        : (hit ? 0.88 : 0.22);

                final color = isFuture
                    ? pt.line
                    : (hit || isToday ? _colors[i] : pt.ink300);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 18,
                        child: isToday
                            ? const Align(
                                alignment: Alignment.bottomCenter,
                                child:
                                    Text('🐾', style: TextStyle(fontSize: 13)),
                              )
                            : null,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: h,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: (!hit && !isFuture && !isToday)
                                    ? Border.all(
                                        color: pt.line,
                                        width: 1,
                                        strokeAlign: BorderSide.strokeAlignInside,
                                      )
                                    : (isToday && !isFuture && progressPercent < 0.06)
                                        ? Border.all(
                                            color: _colors[i].withAlpha(160),
                                            width: 1.5,
                                          )
                                        : null,
                                boxShadow: (isToday && !isFuture && progressPercent >= 0.06)
                                    ? [
                                        BoxShadow(
                                          color: color.withAlpha(100),
                                          blurRadius: 14,
                                          offset: const Offset(0, 5),
                                          spreadRadius: -4,
                                        ),
                                      ]
                                    : null,
                                gradient: isFuture || (!hit && !isToday)
                                    ? null
                                    : LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color.lerp(color, Colors.white, 0.28)!,
                                          color,
                                        ],
                                      ),
                                color: isFuture
                                    ? pt.surface2
                                    : (!hit && !isToday ? pt.surface2 : null),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dayLetters[dayDate.weekday - 1],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isToday
                              ? _colors[i]
                              : (isFuture ? pt.ink300 : pt.ink500),
                        ),
                      ),
                      Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? _colors[i]
                              : (isFuture ? pt.ink300 : pt.ink300),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trophy Room (real badges) ─────────────────────────────────────────────────

class CareGamifiedTrophyRoom extends ConsumerWidget {
  const CareGamifiedTrophyRoom({super.key, required this.petId});

  final String petId;

  String _progressHint(BadgeInfo badge, PetAwardsSummary awards) {
    switch (badge.type) {
      case '3_day_streak':
        return '${awards.currentStreak}/3 days 🔥';
      case '7_day_hero':
        return '${awards.currentStreak}/7 days 🦸';
      case 'routine_master':
        return '${awards.currentStreak}/14 days 💯';
      case '30_day_legend':
        return '${awards.currentStreak}/30 days 👑';
      case 'care_champion':
        return '${awards.logsCount}/100 logs 🏆';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awardsAsync = ref.watch(petAwardsSummaryProvider(petId));
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    final awards = awardsAsync.maybeWhen(
      data: (a) => a,
      orElse: () => PetAwardsSummary.empty,
    );
    final ownedTypes = awards.unlockedTypes;
    final ownedCount = ownedTypes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ownedCount > 0 ? AppColors.mintSoft : pt.surface2,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$ownedCount / ${kBadgeCatalog.length} earned',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: ownedCount > 0 ? AppColors.mint700 : pt.ink300,
              ),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: kBadgeCatalog.length,
          itemBuilder: (context, i) {
            final badge = kBadgeCatalog[i];
            final owned = ownedTypes.contains(badge.type);
            final hint = owned ? '' : _progressHint(badge, awards);
            return _BadgeMedal(
              badge: badge,
              owned: owned,
              progressHint: hint,
              index: i,
              onTap: () => _showBadgeDetail(context, pt, badge, owned, hint),
            );
          },
        ),
      ],
    );
  }

  void _showBadgeDetail(
    BuildContext context,
    PetfolioThemeExtension pt,
    BadgeInfo badge,
    bool owned,
    String hint,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: pt.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 0, 24, MediaQuery.paddingOf(context).bottom + 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: pt.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Medal in sheet
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: owned
                    ? RadialGradient(
                        center: const Alignment(-0.24, -0.4),
                        radius: 0.85,
                        colors: [
                          Color.lerp(badge.color, Colors.white, 0.55)!,
                          badge.color,
                          Color.lerp(badge.color, Colors.black, 0.4)!,
                        ],
                        stops: const [0.0, 0.58, 1.0],
                      )
                    : null,
                color: owned ? null : pt.surface2,
                border: owned ? null : Border.all(color: pt.line),
                boxShadow: owned
                    ? [
                        BoxShadow(
                          color: badge.color.withAlpha(120),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: -8,
                        )
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: owned
                  ? Text(badge.emoji, style: const TextStyle(fontSize: 40))
                  : Opacity(
                      opacity: 0.4,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        ),
                        child:
                            Text(badge.emoji, style: const TextStyle(fontSize: 40)),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 14,
                color: pt.ink500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: owned ? AppColors.mintSoft : pt.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                owned
                    ? '✅ Earned!'
                    : (hint.isNotEmpty ? 'Progress: $hint' : 'Keep logging care'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: owned ? AppColors.mint700 : pt.ink500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Medal (circular 3D medal style) ─────────────────────────────────────

class _BadgeMedal extends StatefulWidget {
  const _BadgeMedal({
    required this.badge,
    required this.owned,
    required this.progressHint,
    required this.index,
    required this.onTap,
  });

  final BadgeInfo badge;
  final bool owned;
  final String progressHint;
  final int index;
  final VoidCallback onTap;

  @override
  State<_BadgeMedal> createState() => _BadgeMedalState();
}

class _BadgeMedalState extends State<_BadgeMedal> with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _sheenCtrl;

  @override
  void initState() {
    super.initState();
    final delayMs = widget.index * 300;
    _floatCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3200 + widget.index * 200),
    )..repeat(reverse: true);
    _sheenCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3800 + widget.index * 200),
    )..forward(from: (delayMs / (3800 + widget.index * 200)).clamp(0.0, 1.0));

    _sheenCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) _sheenCtrl.repeat();
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final owned = widget.owned;
    final badge = widget.badge;
    final labelColor = isDark ? AppColors.ink950D : AppColors.ink950;

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Float bob animation wrapper
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floatCtrl.value * -5),
              child: child,
            ),
            child: SizedBox(
              width: 82,
              height: 82,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring derived from _floatCtrl (no separate controller)
                  if (owned)
                    AnimatedBuilder(
                      animation: _floatCtrl,
                      builder: (_, _) {
                        final t = math.sin(_floatCtrl.value * math.pi);
                        return Transform.scale(
                          scale: 0.92 + t * 0.14,
                          child: Opacity(
                            opacity: (0.50 + t * 0.38).clamp(0.0, 1.0),
                            child: Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: badge.color,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Medal disc
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: owned
                          ? RadialGradient(
                              center: const Alignment(-0.24, -0.4),
                              radius: 0.85,
                              colors: [
                                Color.lerp(badge.color, Colors.white, 0.55)!,
                                badge.color,
                                Color.lerp(badge.color, Colors.black, 0.4)!,
                              ],
                              stops: const [0.0, 0.58, 1.0],
                            )
                          : RadialGradient(
                              center: const Alignment(-0.24, -0.4),
                              radius: 0.85,
                              colors: [
                                pt.ink300.withAlpha(160),
                                pt.ink300,
                              ],
                            ),
                      boxShadow: owned
                          ? [
                              BoxShadow(
                                color: Colors.black.withAlpha(77),
                                blurRadius: 0,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: badge.color.withAlpha(120),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                                spreadRadius: -8,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withAlpha(46),
                                blurRadius: 0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Concentric depth rings
                          Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: owned
                                      ? Colors.white.withAlpha(77)
                                      : Colors.black.withAlpha(15),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: owned
                                      ? Colors.white.withAlpha(46)
                                      : Colors.black.withAlpha(8),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          // Badge emoji
                          owned
                              ? Text(
                                  badge.emoji,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    shadows: [
                                      Shadow(
                                        color: Color(0x47000000),
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                )
                              : Opacity(
                                  opacity: 0.65,
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.grey,
                                      BlendMode.saturation,
                                    ),
                                    child: Text(
                                      badge.emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                          // Holographic sheen sweep (owned)
                          if (owned)
                            AnimatedBuilder(
                              animation: _sheenCtrl,
                              builder: (_, _) {
                                final x = _sheenCtrl.value * 2.6 - 0.6;
                                return Transform.translate(
                                  offset: Offset(x * 72, 0),
                                  child: Container(
                                    width: 72 * 0.45,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Color(0xA6FFFFFF),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Lock pip for locked badges
                  if (!owned)
                    Positioned(
                      right: 5,
                      bottom: 5,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pt.surface1,
                          border: Border.all(color: pt.line),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: pt.ink300,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: labelColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            owned ? '✓ earned' : widget.progressHint,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: owned ? AppColors.mint700 : pt.ink300,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
