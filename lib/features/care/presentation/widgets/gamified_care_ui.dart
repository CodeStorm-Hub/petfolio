import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petfolio/core/theme/theme.dart';

import '../../../../core/models/pet.dart';
import '../../data/models/care_task.dart' show CareFrequency;
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _coinCtrl;
  late final AnimationController _pulseCtrl;
  late final ConfettiController _confettiCtrl;
  int? _storedLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStoredLevel();
    _coinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _confettiCtrl = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _coinCtrl.stop();
      _pulseCtrl.stop();
    } else {
      if (!_coinCtrl.isAnimating) _coinCtrl.repeat();
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _coinCtrl.stop();
      _pulseCtrl.stop();
    } else if (state == AppLifecycleState.resumed && !reduceMotion) {
      if (!_coinCtrl.isAnimating) _coinCtrl.repeat();
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coinCtrl.dispose();
    _pulseCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStoredLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('care_lvl_${widget.activePet.id}');
    if (mounted) setState(() => _storedLevel = saved ?? 0);
  }

  Future<void> _persistLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('care_lvl_${widget.activePet.id}', level);
  }

  void _checkLevelUp(int currentLevel) {
    final stored = _storedLevel;
    if (stored == null) return;
    if (stored == 0) {
      _storedLevel = currentLevel;
      _persistLevel(currentLevel);
      return;
    }
    if (currentLevel > stored) {
      _confettiCtrl.play();
      _storedLevel = currentLevel;
      _persistLevel(currentLevel);
    }
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkLevelUp(lv.level);
    });

    final tasks = widget.dashboard.tasks.value ?? [];
    final planned = tasks
        .where((t) => !t.isLogDerived && t.frequency != CareFrequency.asNeeded)
        .toList();
    final doneToday = planned.where((t) => t.isCompleted).length;
    final totalToday = planned.length;
    final pct = lv.progress.clamp(0.0, 1.0);

    return Stack(
      children: [
        Container(
          color: AppColors.tangerine,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topPad + 76),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
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
                        children: const [TextSpan(text: ' 🔥')],
                      ),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.05,
                        letterSpacing: -0.3,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.poppy,
                        AppColors.tangerine700,
                        AppColors.tangerine,
                      ],
                      stops: [0.0, 0.48, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.poppy.withAlpha(0x60),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                        spreadRadius: -12,
                      ),
                      const BoxShadow(
                        color: AppColors.shadowE1L,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
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
                            RepaintBoundary(
                              child: _StreakCoin(
                                streak: streak,
                                coinCtrl: _coinCtrl,
                                pulseCtrl: _pulseCtrl,
                              ),
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
          ),
        ),

        // Level-up confetti burst
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: ConfettiWidget(
                confettiController: _confettiCtrl,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                gravity: 0.3,
                colors: const [
                  AppColors.tangerine,
                  AppColors.sunny,
                  AppColors.poppy,
                  AppColors.mint,
                  AppColors.lilac,
                ],
                shouldLoop: false,
              ),
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
          // Expanding pulse ring — Container is const child, only Transform/Opacity change per frame
          AnimatedBuilder(
            animation: pulseCtrl,
            builder: (_, child) {
              final scale = 1.0 + pulseCtrl.value * 0.90;
              final opacity = ((1.0 - pulseCtrl.value) * 0.50).clamp(0.0, 0.50);
              return Transform.scale(
                scale: scale,
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: const SizedBox(
              width: 84,
              height: 84,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xA0FFFFFF), width: 2),
                  ),
                ),
              ),
            ),
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
                    AppColors.sunnySoft,
                    AppColors.sunny,
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
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Color(0x80C41818),
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
                          fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w700,
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
                          AppColors.sunnySoft,
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
                        colors: [AppColors.glassTopL, Colors.transparent],
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
              : '${lv.currentXp} / ${lv.levelEndXp} XP · ${lv.xpToNext} XP to "${lv.nextTitle}"',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mintSoft = isDark ? AppColors.mintSoftD : AppColors.mintSoft;
    final mint700 = isDark ? AppColors.mint700D : AppColors.mint700;

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
                    color: mintSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$hitsCount 🔥 day${hitsCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: mint700,
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
                        height: 26,
                        child: isToday
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w700,
                                      color: _colors[i],
                                      height: 1.1,
                                    ),
                                  ),
                                  const Text(
                                    '🐾',
                                    style: TextStyle(fontSize: 11, height: 1.1),
                                  ),
                                ],
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
                          fontWeight: FontWeight.w700,
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

// ── Trophy Room (horizontal slider) ──────────────────────────────────────────

String _badgeProgressHint(BadgeInfo badge, PetAwardsSummary awards) {
  switch (badge.type) {
    case '3_day_streak':
      return '${awards.currentStreak}/3 days 🦴';
    case '7_day_hero':
      return '${awards.currentStreak}/7 days 🌿';
    case 'routine_master':
      return '${awards.currentStreak}/14 days ❤️';
    case '30_day_legend':
      return '${awards.currentStreak}/30 days 🌟';
    case 'care_champion':
      return '${awards.logsCount}/100 logs 👑';
    default:
      return '';
  }
}

class CareGamifiedTrophyRoom extends ConsumerWidget {
  const CareGamifiedTrophyRoom({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awardsAsync = ref.watch(petAwardsSummaryProvider(petId));
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mintSoft = isDark ? AppColors.mintSoftD : AppColors.mintSoft;
    final mint700 = isDark ? AppColors.mint700D : AppColors.mint700;

    final awards = awardsAsync.maybeWhen(
      data: (a) => a,
      orElse: () => PetAwardsSummary.empty,
    );
    final ownedCount = awards.unlockedTypes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ownedCount > 0 ? mintSoft : pt.surface2,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$ownedCount / ${kBadgeCatalog.length} earned',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ownedCount > 0 ? mint700 : pt.ink300,
              ),
            ),
          ),
        ),
        _TrophySlider(
          awards: awards,
          onTapBadge: (badge, owned, hint) =>
              _showBadgeDetail(context, pt, badge, owned, hint),
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
            Container(
              width: 96,
              height: 96,
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
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                          spreadRadius: -8,
                        )
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: owned
                  ? Text(badge.emoji, style: const TextStyle(fontSize: 44))
                  : Opacity(
                      opacity: 0.4,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.grey,
                          BlendMode.saturation,
                        ),
                        child: Text(badge.emoji,
                            style: const TextStyle(fontSize: 44)),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: owned
                    ? badge.color
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.description,
              style: TextStyle(fontSize: 14, color: pt.ink500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: owned ? badge.color.withAlpha(20) : pt.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: owned ? badge.color.withAlpha(60) : pt.line,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    owned
                        ? Icons.check_circle_rounded
                        : Icons.lock_rounded,
                    size: 16,
                    color: owned ? badge.color : pt.ink300,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    owned
                        ? 'Earned!'
                        : (hint.isNotEmpty
                            ? 'Progress: $hint'
                            : 'Keep logging care'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: owned ? badge.color : pt.ink500,
                    ),
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

// ── Trophy Slider ─────────────────────────────────────────────────────────────

class _TrophySlider extends StatefulWidget {
  const _TrophySlider({
    required this.awards,
    required this.onTapBadge,
  });

  final PetAwardsSummary awards;
  final void Function(BadgeInfo badge, bool owned, String hint) onTapBadge;

  @override
  State<_TrophySlider> createState() => _TrophySliderState();
}

class _TrophySliderState extends State<_TrophySlider> {
  late final PageController _ctrl;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.46);
    _ctrl.addListener(_onScroll);
  }

  void _onScroll() {
    final p = (_ctrl.page ?? 0).round();
    if (p != _page) setState(() => _page = p);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final ownedTypes = widget.awards.unlockedTypes;

    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _ctrl,
            padEnds: false,
            itemCount: kBadgeCatalog.length,
            itemBuilder: (context, i) {
              final badge = kBadgeCatalog[i];
              final owned = ownedTypes.contains(badge.type);
              final hint =
                  owned ? '' : _badgeProgressHint(badge, widget.awards);
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  i == 0 ? 0 : 7,
                  4,
                  i == kBadgeCatalog.length - 1 ? 8 : 7,
                  10,
                ),
                child: _TrophyCard(
                  badge: badge,
                  owned: owned,
                  progressHint: hint,
                  index: i,
                  onTap: () => widget.onTapBadge(badge, owned, hint),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(kBadgeCatalog.length, (i) {
            final badge = kBadgeCatalog[i];
            final owned = ownedTypes.contains(badge.type);
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: active ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: active
                    ? badge.color
                    : (owned
                        ? badge.color.withAlpha(90)
                        : pt.line),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Trophy Card ───────────────────────────────────────────────────────────────

class _TrophyCard extends StatefulWidget {
  const _TrophyCard({
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
  State<_TrophyCard> createState() => _TrophyCardState();
}

class _TrophyCardState extends State<_TrophyCard> with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _sheenCtrl;
  late final AnimationStatusListener _sheenListener;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3200 + widget.index * 200),
    )..repeat(reverse: true);

    final sheenDuration = Duration(milliseconds: 3800 + widget.index * 200);
    _sheenCtrl = AnimationController(vsync: this, duration: sheenDuration);

    _sheenListener = (s) {
      if (s == AnimationStatus.completed && mounted) _sheenCtrl.repeat();
    };

    if (widget.owned) {
      final delayFraction =
          (widget.index * 300 / sheenDuration.inMilliseconds).clamp(0.0, 1.0);
      _sheenCtrl.addStatusListener(_sheenListener);
      _sheenCtrl.forward(from: delayFraction);
    }
  }

  @override
  void didUpdateWidget(_TrophyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.owned && widget.owned && !_sheenCtrl.isAnimating) {
      final delayFraction =
          (widget.index * 300 / _sheenCtrl.duration!.inMilliseconds).clamp(0.0, 1.0);
      _sheenCtrl.removeStatusListener(_sheenListener);
      _sheenCtrl.addStatusListener(_sheenListener);
      _sheenCtrl.forward(from: delayFraction);
    }
  }

  @override
  void dispose() {
    _sheenCtrl.removeStatusListener(_sheenListener);
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

    final bgTop = owned
        ? Color.lerp(badge.color, Colors.white, isDark ? 0.50 : 0.82)!
        : (isDark ? AppColors.surface3D : AppColors.surface2);
    final bgBottom = owned
        ? Color.lerp(badge.color, Colors.white, isDark ? 0.24 : 0.52)!
        : (isDark ? AppColors.surface1D : pt.line.withAlpha(130));

    return Semantics(
      label: '${widget.badge.label} badge, ${widget.owned ? 'earned' : widget.progressHint}',
      button: true,
      child: GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgTop, bgBottom],
          ),
          border: Border.all(
            color:
                owned ? badge.color.withAlpha(75) : pt.line,
            width: owned ? 1.5 : 1.0,
          ),
          boxShadow: owned
              ? [
                  BoxShadow(
                    color: badge.color.withAlpha(isDark ? 55 : 40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -5,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            children: [
              // Holographic sheen sweep for owned badges
              if (owned)
                AnimatedBuilder(
                  animation: _sheenCtrl,
                  builder: (_, _) {
                    final x = _sheenCtrl.value * 3.0 - 0.7;
                    return Positioned(
                      top: 0,
                      bottom: 0,
                      left: x * 170,
                      width: 52,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.transparent,
                              AppColors.glassShineL,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Floating medal disc
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _floatCtrl,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _floatCtrl.value * -6),
                            child: child,
                          ),
                          child: _MedalDisc(badge: badge, owned: owned),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Badge name
                    Text(
                      badge.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: owned
                            ? (isDark
                                ? Color.lerp(badge.color, Colors.white, 0.30)!
                                : badge.color)
                            : pt.ink500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Progress / earned status pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: owned
                            ? badge.color.withAlpha(isDark ? 50 : 28)
                            : pt.surface2.withAlpha(200),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: owned
                              ? badge.color.withAlpha(65)
                              : pt.line,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            owned
                                ? Icons.check_circle_rounded
                                : Icons.lock_rounded,
                            size: 11,
                            color: owned ? badge.color : pt.ink300,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              owned
                                  ? 'Earned!'
                                  : (widget.progressHint.isNotEmpty
                                      ? widget.progressHint
                                      : 'Locked'),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: owned ? badge.color : pt.ink500,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lock pip top-right for locked badges
              if (!owned)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pt.surface1,
                      border: Border.all(color: pt.line),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 11,
                      color: pt.ink300,
                    ),
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

// ── Medal Disc ────────────────────────────────────────────────────────────────

class _MedalDisc extends StatelessWidget {
  const _MedalDisc({required this.badge, required this.owned});

  final BadgeInfo badge;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final iconWidget = CustomPaint(
      painter: _BadgePainter(badge.type, badge.color, owned),
    );
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: owned
            ? RadialGradient(
                center: const Alignment(-0.24, -0.40),
                radius: 0.88,
                colors: [
                  Color.lerp(badge.color, Colors.white, 0.56)!,
                  badge.color,
                  Color.lerp(badge.color, Colors.black, 0.38)!,
                ],
                stops: const [0.0, 0.55, 1.0],
              )
            : RadialGradient(
                center: const Alignment(-0.24, -0.40),
                radius: 0.88,
                colors: [
                  pt.ink300.withAlpha(100),
                  pt.ink300.withAlpha(160),
                ],
              ),
        boxShadow: owned
            ? [
                BoxShadow(
                  color: badge.color.withAlpha(100),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(22),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Concentric ring
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: owned
                        ? Colors.white.withAlpha(60)
                        : Colors.black.withAlpha(10),
                    width: 1,
                  ),
                ),
              ),
            ),
            // Specular highlight
            if (owned)
              Positioned(
                left: 4, top: 4, right: 20, bottom: 10,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white.withAlpha(90), Colors.transparent],
                    ),
                  ),
                ),
              ),
            // Custom icon
            Positioned.fill(
              child: owned
                  ? iconWidget
                  : Opacity(
                      opacity: 0.45,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                            Colors.grey, BlendMode.saturation),
                        child: iconWidget,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Icon Painter ────────────────────────────────────────────────────────

class _BadgePainter extends CustomPainter {
  _BadgePainter(this.type, this.color, this.owned);

  final String type;
  final Color color;
  final bool owned;

  Paint _fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final u = size.width / 42;
    final white = Colors.white.withAlpha(owned ? 230 : 180);

    switch (type) {
      case 'first_log':    _drawPaw(canvas, cx, cy, u, white); break;
      case '3_day_streak': _drawBone(canvas, cx, cy, u, white); break;
      case '7_day_hero':   _drawSprout(canvas, cx, cy, u, white); break;
      case 'routine_master': _drawHeartPaw(canvas, cx, cy, u, white); break;
      case '30_day_legend':  _drawStar(canvas, cx, cy, u, white); break;
      case 'care_champion':  _drawCrown(canvas, cx, cy, u, white); break;
    }
  }

  // 🐾 Paw print: palm oval + 4 toe circles
  void _drawPaw(Canvas canvas, double cx, double cy, double u, Color c) {
    final p = _fill(c);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4 * u), width: 15 * u, height: 11 * u),
      p,
    );
    canvas.drawCircle(Offset(cx - 7 * u, cy - 1 * u), 3.5 * u, p);
    canvas.drawCircle(Offset(cx - 2 * u, cy - 5.5 * u), 3.5 * u, p);
    canvas.drawCircle(Offset(cx + 3 * u, cy - 5.5 * u), 3.5 * u, p);
    canvas.drawCircle(Offset(cx + 8 * u, cy - 1 * u), 3.5 * u, p);
  }

  // 🦴 Dog bone: bar + rounded knobs each end
  void _drawBone(Canvas canvas, double cx, double cy, double u, Color c) {
    final p = _fill(c);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 24 * u, height: 7 * u),
        Radius.circular(3.5 * u),
      ),
      p,
    );
    for (final dx in [-13.0 * u, 13.0 * u]) {
      canvas.drawCircle(Offset(cx + dx, cy - 4.5 * u), 4.5 * u, p);
      canvas.drawCircle(Offset(cx + dx, cy + 4.5 * u), 4.5 * u, p);
    }
  }

  // 🌱 Sprout: curved stem + two leaves + sun bud
  void _drawSprout(Canvas canvas, double cx, double cy, double u, Color c) {
    // Stem
    final stem = Path()
      ..moveTo(cx, cy + 10 * u)
      ..cubicTo(cx, cy + 4 * u, cx - 1.5 * u, cy, cx, cy - 1.5 * u);
    canvas.drawPath(stem, _stroke(c, 2.8 * u));
    // Left leaf
    final left = Path()
      ..moveTo(cx, cy + 1 * u)
      ..cubicTo(cx - 10 * u, cy - 1 * u, cx - 10 * u, cy - 11 * u, cx, cy - 7 * u)
      ..close();
    canvas.drawPath(left, _fill(c));
    // Right leaf
    final right = Path()
      ..moveTo(cx, cy - 1 * u)
      ..cubicTo(cx + 9 * u, cy - 3 * u, cx + 9 * u, cy - 13 * u, cx, cy - 9 * u)
      ..close();
    canvas.drawPath(right, _fill(c));
    // Bud
    canvas.drawCircle(Offset(cx, cy - 13.5 * u), 3.5 * u, _fill(c));
  }

  // ❤️ Heart + mini paw inside
  void _drawHeartPaw(Canvas canvas, double cx, double cy, double u, Color c) {
    final heart = Path()
      ..moveTo(cx, cy + 9 * u)
      ..cubicTo(cx - 14 * u, cy + 1 * u, cx - 17 * u, cy - 11 * u, cx, cy - 7 * u)
      ..cubicTo(cx + 17 * u, cy - 11 * u, cx + 14 * u, cy + 1 * u, cx, cy + 9 * u);
    canvas.drawPath(heart, _fill(c));
    // Mini paw inside (white)
    final pw = Colors.white.withAlpha(owned ? 200 : 140);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 1.5 * u), width: 6.5 * u, height: 4.5 * u),
      _fill(pw),
    );
    for (final d in [Offset(-3.5 * u, -1.5 * u), Offset(-1 * u, -4 * u), Offset(1.5 * u, -4 * u), Offset(4 * u, -1.5 * u)]) {
      canvas.drawCircle(Offset(cx + d.dx, cy + d.dy), 1.5 * u, _fill(pw));
    }
  }

  // ⭐ 5-pt star + sparkle dots
  void _drawStar(Canvas canvas, double cx, double cy, double u, Color c) {
    const n = 5;
    const outerR = 14.0;
    const innerR = 5.5;
    final star = Path();
    for (int i = 0; i < n * 2; i++) {
      final angle = (i * math.pi / n) - math.pi / 2;
      final r = (i.isEven ? outerR : innerR) * u;
      final pt = Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    star.close();
    canvas.drawPath(star, _fill(c));
    // Sparkle dots
    for (final pos in [
      Offset(-16 * u, -7 * u), Offset(16 * u, 5 * u), Offset(11 * u, -15 * u)
    ]) {
      canvas.drawCircle(Offset(cx + pos.dx, cy + pos.dy), 1.8 * u, _fill(c));
    }
  }

  // 👑 Crown: 3-pointed body + gem circles + base band
  void _drawCrown(Canvas canvas, double cx, double cy, double u, Color c) {
    final crown = Path()
      ..moveTo(cx - 14 * u, cy + 7 * u)
      ..lineTo(cx + 14 * u, cy + 7 * u)
      ..lineTo(cx + 11 * u, cy - 3 * u)
      ..lineTo(cx + 4.5 * u, cy + 2.5 * u)
      ..lineTo(cx, cy - 12 * u)
      ..lineTo(cx - 4.5 * u, cy + 2.5 * u)
      ..lineTo(cx - 11 * u, cy - 3 * u)
      ..close();
    canvas.drawPath(crown, _fill(c));
    // Base band
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 9 * u), width: 28 * u, height: 5 * u),
        Radius.circular(2.5 * u),
      ),
      _fill(c),
    );
    // Gems (white circles)
    final gem = Colors.white.withAlpha(owned ? 210 : 150);
    canvas.drawCircle(Offset(cx, cy - 12 * u), 2.8 * u, _fill(gem));
    canvas.drawCircle(Offset(cx - 11 * u, cy - 3 * u), 2.2 * u, _fill(gem));
    canvas.drawCircle(Offset(cx + 11 * u, cy - 3 * u), 2.2 * u, _fill(gem));
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) =>
      old.type != type || old.color != color || old.owned != owned;
}
