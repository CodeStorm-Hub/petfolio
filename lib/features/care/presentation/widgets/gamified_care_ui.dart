import 'package:petfolio/features/care/data/models/care_task_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../../../../core/models/pet.dart';
import '../../data/models/pet_awards_summary.dart';
import '../../data/models/pet_level.dart';
import '../controllers/care_dashboard_controller.dart';
import '../controllers/pet_awards_provider.dart';

// ── Gamified Care Header (Slim Hero) ──────────────────────────────────────────

class CareGamifiedHeader extends ConsumerWidget {
  const CareGamifiedHeader({
    super.key,
    required this.activePet,
    required this.dashboard,
  });

  final Pet activePet;
  final DailyRoutineState dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petId = activePet.id;

    final streak = dashboard.streak.maybeWhen(
      data: (s) => s.currentStreak,
      orElse: () => 0,
    );

    final awardsAsync = ref.watch(petAwardsSummaryProvider(petId));
    final totalXp = awardsAsync.maybeWhen(
      data: (a) => a.totalXp,
      orElse: () => 0,
    );
    final lv = PetLevel.fromXp(totalXp);

    final tasks = dashboard.tasks.value ?? [];
    final planned = tasks.where((t) => !t.isLogDerived).toList();
    final doneToday = planned.where((t) => t.isCompleted).length;
    final totalToday = planned.length;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activePet.speciesEnum.resolvedAccent(isDark);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        WaveHeader(
          color: color,
          child: Column(
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top + 76.0),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                child: Row(
                  children: [
                    _StreakCoin(streak: streak),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Lv ${lv.level}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
                              const SizedBox(width: 6),
                              Expanded(child: Text('· ${lv.title}', maxLines: 1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white70, overflow: TextOverflow.ellipsis))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                                child: Text('$doneToday/$totalToday today', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: color)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 13,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: lv.progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: AppColors.sunny,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text('${lv.currentXp} / ${lv.levelEndXp} XP · ${lv.xpToNext} XP to Lv ${lv.level + 1}', maxLines: 1, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white70, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 75.0),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakCoin extends StatelessWidget {
  const _StreakCoin({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.sunnySoft,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.sunny.withAlpha(80)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20, height: 1)),
          const SizedBox(height: 2),
          Text(
            '$streak', 
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w800, 
              color: AppColors.sunny700, 
              height: 1,
            )
          ),
        ],
      ),
    );
  }
}

// ── Weekly Activity Chart (Compact) ──────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
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
      if (todaySlot >= 0 && todaySlot < weekHits.length && !weekHits[todaySlot]) hitsCount++;
    }

    return Container(
      decoration: BoxDecoration(
        color: pt.surface1,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pt.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('$hitsCount / 7 goals this week', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: pt.ink500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(999)),
                child: Text('$hitsCount 🔥', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.mint700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 78,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final dayDate = weekStart.add(Duration(days: i));
                final isFuture = dayDate.isAfter(today);
                final isToday = dayDate == today;

                final hit = i < weekHits.length ? weekHits[i] : false;
                final h = isFuture ? 0.10 : (isToday ? progressPercent.clamp(0.16, 1.0) : (hit ? 0.85 : 0.30));
                final color = isToday ? AppColors.poppy : (hit ? AppColors.mint : pt.ink300);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isToday) const Padding(padding: EdgeInsets.only(bottom: 2), child: Text('🐾', style: TextStyle(fontSize: 11, height: 1))),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: h,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isFuture || (!hit && !isToday) ? pt.surface2 : color,
                                border: isToday ? Border.all(color: AppColors.poppy700, width: 1.5) : ((!hit && !isToday && !isFuture) ? Border.all(color: pt.line, strokeAlign: BorderSide.strokeAlignInside) : null),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_dayLetters[dayDate.weekday - 1], style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: isToday ? AppColors.poppy700 : pt.ink300, height: 1)),
                      const SizedBox(height: 3),
                      Text('${dayDate.day}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: pt.ink300, height: 1)),
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

// ── Trophy Room (TrophyCarousel) ──────────────────────────────────────────────

class CareGamifiedTrophyRoom extends ConsumerWidget {
  const CareGamifiedTrophyRoom({super.key, required this.petId});
  final String petId;

  String _progressHint(BadgeInfo badge, PetAwardsSummary awards) {
    switch (badge.type) {
      case '3_day_streak': return '${awards.currentStreak}/3 days 🔥';
      case '7_day_hero': return '${awards.currentStreak}/7 days 🦸';
      case 'routine_master': return '${awards.currentStreak}/14 days 💯';
      case '30_day_legend': return '${awards.currentStreak}/30 days 👑';
      case 'care_champion': return '${awards.logsCount}/100 logs 🏆';
      default: return 'unlocked';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awardsAsync = ref.watch(petAwardsSummaryProvider(petId));
    final awards = awardsAsync.maybeWhen(data: (a) => a, orElse: () => PetAwardsSummary.empty);
    final ownedTypes = awards.unlockedTypes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 4,
          childAspectRatio: 0.8,
        ),
        itemCount: kBadgeCatalog.length,
        itemBuilder: (context, i) {
          final badge = kBadgeCatalog[i];
          final owned = ownedTypes.contains(badge.type);
          final hint = _progressHint(badge, awards);
          
          Color rimColor;
          switch (badge.type) {
            case 'first_log': rimColor = const Color(0xFF1A9970); break;
            case '3_day_streak': rimColor = const Color(0xFFB85A1A); break;
            case '7_day_hero': rimColor = const Color(0xFF8A1010); break;
            case 'routine_master': rimColor = const Color(0xFF9A6500); break;
            case '30_day_legend': rimColor = const Color(0xFF4A2FA0); break;
            case 'care_champion': rimColor = const Color(0xFF2060A8); break;
            default: rimColor = Colors.black26; break;
          }

          return GestureDetector(
            onTap: () => _showBadgeDetail(context, badge, owned, hint, rimColor),
            child: PfAchievementTile(
              emoji: badge.emoji,
              color: badge.color,
              label: badge.label,
              owned: owned,
              index: i,
            ),
          );
        },
      ),
    );
  }
  
  void _showBadgeDetail(BuildContext context, BadgeInfo badge, bool owned, String hint, Color rim) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: pt.surface1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, -10))],
        ),
        padding: EdgeInsets.fromLTRB(22, 12, 22, MediaQuery.paddingOf(context).bottom + 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 38, height: 4, decoration: BoxDecoration(color: pt.line, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 18)),
            Container(
              width: 84, height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: owned ? badge.color.withValues(alpha: 0.15) : pt.surface2,
                border: owned ? Border.all(color: badge.color, width: 2) : Border.all(color: pt.line),
              ),
              alignment: Alignment.center,
              child: Opacity(opacity: owned ? 1.0 : 0.5, child: Text(badge.emoji, style: const TextStyle(fontSize: 40))),
            ),
            const SizedBox(height: 12),
            Text(badge.label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: pt.ink950)),
            const SizedBox(height: 4),
            Text(owned ? 'You unlocked this badge — nice work keeping up the routine!' : 'Keep logging care to unlock this badge.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pt.ink500)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: owned ? AppColors.mintSoft : pt.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(owned ? '✅ Earned!' : 'Progress: $hint', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: owned ? AppColors.mint700 : pt.ink500)),
            ),
          ],
        ),
      ),
    );
  }
}


