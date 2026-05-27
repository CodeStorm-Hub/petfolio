import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/models/pet.dart';
import '../../../../core/widgets/pf_achievement_tile.dart';
import '../controllers/care_dashboard_controller.dart';
import '../controllers/pet_badges_provider.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';

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

    // Gentle vertical bob — 2.4s ease-in-out infinite (mirrors pf-bounce-soft)
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    // Expanding + fading ring — 2s ease-out infinite (mirrors pf-pulse-ring)
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
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    final streak = widget.dashboard.streak.maybeWhen(
      data: (s) => s.currentStreak,
      orElse: () => 0,
    );

    final tasks = widget.dashboard.tasks.value ?? [];
    final earned = tasks
        .where((t) => t.isCompleted && t.gamificationPoints > 0)
        .fold(0, (sum, t) => sum + t.gamificationPoints);
    const petXp = 482;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sunnySoft, cs.surface],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Streak flame circle with bounce + pulse ring
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding pulse ring
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseScale.value,
                    child: Opacity(
                      opacity: _pulseOpacity.value,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.tangerine,
                        width: 3,
                      ),
                    ),
                  ),
                ),
                // Floating flame circle
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

          // XP & level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Lv 7',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Caretaker',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: pt.ink500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${petXp + earned} / 600 XP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: pt.ink500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: cs.surface,
                    border: Border.all(color: pt.line),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ((petXp + earned) / 600).clamp(0.0, 1.0),
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
                Text.rich(
                  TextSpan(
                    text: '${600 - (petXp + earned)} XP to ',
                    style: TextStyle(
                      fontSize: 11,
                      color: pt.ink500,
                      fontWeight: FontWeight.w700,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Lv 8 · Pet Whisperer',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
  // Demo heights matching the JSX design (indices 0-5 = Mon-Sat, index 6 = today/dynamic)
  static const _demoHeights = [0.86, 0.94, 0.70, 1.0, 0.88, 0.60];
  static const _colors = [
    AppColors.tangerine, AppColors.poppy, AppColors.mint,
    AppColors.sunny, AppColors.lilac, AppColors.tangerine, AppColors.poppy,
  ];

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

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
            final isToday = i == 6;
            final h = isToday
                ? progressPercent.clamp(0.15, 1.0)
                : _demoHeights[i];
            final color = _colors[i];

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Paw above today bar — reserve 20px for it
                  SizedBox(
                    height: 20,
                    child: isToday
                        ? const Align(
                            alignment: Alignment.bottomCenter,
                            child: Text('🐾', style: TextStyle(fontSize: 13)),
                          )
                        : null,
                  ),
                  // Bar
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
                            boxShadow: isToday
                                ? [
                                    BoxShadow(
                                      color: color.withAlpha(100),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                      spreadRadius: -4,
                                    )
                                  ]
                                : null,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color,
                                Color.lerp(color, Colors.white, 0.45)!,
                              ],
                            ),
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
                      color: isToday ? AppColors.ink950 : pt.ink500,
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

class CareGamifiedTrophyRoom extends ConsumerWidget {
  const CareGamifiedTrophyRoom({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);
    if (activePet == null) return const SizedBox.shrink();

    final badgesAsync = ref.watch(petBadgesProvider(activePet.id));

    return badgesAsync.when(
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator.adaptive())),
      error: (_, _) => const SizedBox(height: 100, child: Center(child: Text('Failed to load badges'))),
      data: (badges) {
        if (badges.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'No badges earned yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
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
          itemCount: badges.length,
          itemBuilder: (context, i) => PfAchievementTile(
            emoji: badges[i].emoji,
            color: badges[i].color,
            label: badges[i].title,
            owned: true,
            index: i,
          ),
        );
      },
    );
  }
}
