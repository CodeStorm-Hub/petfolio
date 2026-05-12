import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/theme/app_colors.dart';
import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/pet_profile/data/models/pet.dart';
import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';

import '../../data/models/care_task_type.dart';
import '../controllers/care_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CareScreen
// ─────────────────────────────────────────────────────────────────────────────

class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen> {
  bool _outdoor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final pet = ref.read(activePetControllerProvider);
    if (pet == null) return;
    // Load local immediately, then merge remote in background.
    final ctrl = ref.read(careControllerProvider(pet.id).notifier);
    await ctrl.loadLocal();
    ctrl.refresh(); // fire-and-forget
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final activePet = ref.watch(activePetControllerProvider);

    final petsAsync = ref.watch(petListProvider);
    if (activePet == null) {
      return Scaffold(
        backgroundColor: pt.surface1,
        body: Center(
          child: petsAsync.isLoading
              ? const CircularProgressIndicator.adaptive()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pets_outlined, size: 48, color: pt.ink300),
                    const SizedBox(height: 12),
                    Text(
                      'Add a pet to track care',
                      style: TextStyle(fontSize: 15, color: pt.ink500),
                    ),
                  ],
                ),
        ),
      );
    }

    final care = ref.watch(careControllerProvider(activePet.id));
    final species = activePet.speciesEnum;

    return Scaffold(
      backgroundColor: _outdoor ? cs.surface : pt.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              pet: activePet,
              species: species,
              outdoor: _outdoor,
              onOutdoor: () => setState(() => _outdoor = !_outdoor),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                children: [
                  _StreakBanner(
                    care: care,
                    species: species,
                    outdoor: _outdoor,
                  ),
                  const SizedBox(height: 16),
                  _TodayTasksCard(
                    care: care,
                    petId: activePet.id,
                    outdoor: _outdoor,
                  ),
                  const SizedBox(height: 8),
                  _SectionLabel(
                    label: 'Clinical Vitals',
                    actionLabel: 'Add reading',
                    outdoor: _outdoor,
                    onAction: () {},
                  ),
                  const SizedBox(height: 8),
                  _VitalsTabs(species: species),
                  const SizedBox(height: 12),
                  _VitalsChart(species: species, outdoor: _outdoor),
                  const SizedBox(height: 12),
                  _NextCheckupCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({
    required this.pet,
    required this.species,
    required this.outdoor,
    required this.onOutdoor,
  });

  final Pet pet;
  final PetSpecies species;
  final bool outdoor;
  final VoidCallback onOutdoor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // Back button
          _CircleButton(
            onTap: () => Navigator.of(context).maybePop(),
            child: CustomPaint(
              size: const Size(10, 18),
              painter: _ChevronPainter(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),

          // Pet switcher
          Expanded(
            child: GestureDetector(
              onTap: () => PetSwitcherSheet.show(context),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  PetAvatar(
                    imageUrl: pet.avatarUrl,
                    size: PetAvatarSize.sm,
                    initials: pet.name.isNotEmpty ? pet.name[0] : null,
                    borderColor: species.accent,
                    semanticLabel: pet.name,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HEALTH · ${pet.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.08 * 11,
                            color: pt.ink500,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              pet.breed ?? species.label,
                              style: const TextStyle(
                                fontFamily: 'Sora',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                letterSpacing: -0.18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down,
                                size: 16, color: pt.ink500),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Outdoor mode toggle
          _CircleButton(
            onTap: onOutdoor,
            filled: outdoor,
            child: Icon(
              Icons.wb_sunny_outlined,
              size: 18,
              color: outdoor ? Colors.white : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.onTap,
    required this.child,
    this.filled = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: filled ? AppColors.ink950 : cs.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowE1L,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: pt.line200.withAlpha(128),
              blurRadius: 0,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak Banner
// ─────────────────────────────────────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({
    required this.care,
    required this.species,
    required this.outdoor,
  });

  final CareState care;
  final PetSpecies species;
  final bool outdoor;

  @override
  Widget build(BuildContext context) {
    final accent = species.accent;
    final darkAccent = Color.lerp(accent, Colors.black, 0.22)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, darkAccent],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: outdoor
            ? null
            : [
                BoxShadow(
                  color: accent.withAlpha(136),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                  spreadRadius: -16,
                ),
              ],
      ),
      child: Stack(
        children: [
          // Radial glow
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withAlpha(46),
                  Colors.transparent,
                ], stops: const [0, 0.65]),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: streak count + today count
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CARE STREAK',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1 * 11,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${care.streak}',
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.03 * 48,
                                  height: 1,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'days',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    height: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Today badge
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(46),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'TODAY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.08 * 10,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${care.todayCount} / 3',
                            style: const TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 7-day cells
                Row(
                  children: List.generate(7, (i) {
                    final d = care.week[i];
                    final isToday = i == 6;
                    final isPast = i < 6;
                    return Expanded(
                      child: _DayCell(
                        day: d,
                        label: _dayLabel(i),
                        isToday: isToday,
                        isPast: isPast,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // Legend
                Row(
                  children: [
                    _LegendDot(task: CareTaskType.feed),
                    const SizedBox(width: 12),
                    _LegendDot(task: CareTaskType.walk),
                    const SizedBox(width: 12),
                    _LegendDot(task: CareTaskType.med),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _dayLabel(int i) {
    final dayOfWeek = care.week[i].date.weekday; // 1=Mon … 7=Sun
    return _dayLabels[dayOfWeek - 1];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.label,
    required this.isToday,
    required this.isPast,
  });

  final DayData day;
  final String label;
  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final allDone = day.allDone;
    final isFuture = !isToday && !isPast;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 60,
            decoration: BoxDecoration(
              color: isFuture
                  ? Colors.white.withAlpha(25)
                  : (allDone ? Colors.white : Colors.white.withAlpha(56)),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 0,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(76),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(5),
            child: Column(
              children: CareTaskType.values.map((t) {
                final done = day.isDone(t);
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 1.5),
                    decoration: BoxDecoration(
                      color: done
                          ? (allDone
                              ? Colors.black.withAlpha(10)
                              : Colors.white.withAlpha(242))
                          : (isFuture
                              ? Colors.transparent
                              : Colors.white.withAlpha(30)),
                      borderRadius: BorderRadius.circular(5),
                      border: !done && !isFuture
                          ? Border.all(
                              color: Colors.white.withAlpha(71), width: 1)
                          : null,
                    ),
                    child: done
                        ? Center(
                            child: CustomPaint(
                              size: const Size(11, 11),
                              painter:
                                  _TaskGlyphPainter(task: t, color: AppColors.ink950),
                            ),
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.04 * 11,
              color: isToday ? Colors.white : Colors.white.withAlpha(178),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.task});
  final CareTaskType task;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(242),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(11, 11),
              painter: _TaskGlyphPainter(task: task, color: AppColors.ink950),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          task.name[0].toUpperCase() + task.name.substring(1),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's Tasks Card
// ─────────────────────────────────────────────────────────────────────────────

class _TodayTasksCard extends ConsumerWidget {
  const _TodayTasksCard({
    required this.care,
    required this.petId,
    required this.outdoor,
  });

  final CareState care;
  final String petId;
  final bool outdoor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: pt.line200.withAlpha(128), blurRadius: 0, spreadRadius: 0.5),
          const BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        children: CareTaskType.values.mapIndexed((i, task) {
          final done = care.today.isDone(task);
          final isLast = i == CareTaskType.values.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  children: [
                    // Icon chip
                    AnimatedContainer(
                      duration: PetfolioThemeExtension.durationSm,
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: done ? task.iconTint : pt.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(20, 20),
                          painter: _TaskGlyphPainter(
                            task: task,
                            color: done ? task.iconColor : pt.ink500,
                            strokeWidth: 2.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Labels
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: PetfolioThemeExtension.durationSm,
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: cs.onSurface,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: cs.onSurface,
                            ),
                            child: Text(task.label),
                          ),
                          Text(
                            task.sublabel,
                            style:
                                TextStyle(fontSize: 12, color: pt.ink500),
                          ),
                        ],
                      ),
                    ),

                    // Check button
                    GestureDetector(
                      onTap: () => ref
                          .read(careControllerProvider(petId).notifier)
                          .toggle(task),
                      child: AnimatedContainer(
                        duration: PetfolioThemeExtension.durationSm,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: done ? AppColors.success : Colors.transparent,
                          shape: BoxShape.circle,
                          boxShadow: done
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.ink300,
                                    blurRadius: 0,
                                    spreadRadius: 0,
                                    offset: Offset.zero,
                                  ),
                                ],
                          border: done
                              ? null
                              : Border.all(
                                  color: AppColors.ink300, width: 2),
                        ),
                        child: done
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: pt.line100,
                  indent: 18,
                  endIndent: 18,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label with action
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.actionLabel,
    required this.outdoor,
    required this.onAction,
  });

  final String label;
  final String actionLabel;
  final bool outdoor;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08 * 12,
              color: outdoor ? AppColors.ink700 : pt.ink500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.blue600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vitals Tabs (Weight + BCS)
// ─────────────────────────────────────────────────────────────────────────────

class _VitalsTabs extends StatefulWidget {
  const _VitalsTabs({required this.species});
  final PetSpecies species;

  @override
  State<_VitalsTabs> createState() => _VitalsTabsState();
}

class _VitalsTabsState extends State<_VitalsTabs> {
  bool _showWeight = true;

  static const _weights = [20.4, 20.1, 19.8, 19.6, 19.4, 19.3, 19.5, 19.7, 19.6, 19.4, 19.2, 19.1];
  static const _bcs    = [6, 6, 5, 5, 5, 5, 5, 5, 4, 4, 5, 5];

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final accent = widget.species.accent;

    final wLast = _weights.last;
    final wPrev = _weights[_weights.length - 2];
    final wDelta = wLast - wPrev;
    final bcsLast = _bcs.last;

    return Row(
      children: [
        Expanded(
          child: _VitalCard(
            selected: _showWeight,
            onTap: () => setState(() => _showWeight = true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'WEIGHT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08 * 11,
                        color: pt.ink500,
                      ),
                    ),
                    const Spacer(),
                    _TrendPill(delta: wDelta, unit: 'kg'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      wLast.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02 * 30,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('kg', style: TextStyle(fontSize: 14, color: pt.ink500)),
                  ],
                ),
                const SizedBox(height: 4),
                _Sparkline(
                  data: _weights.map((v) => v).toList(),
                  color: _showWeight ? accent : pt.ink300,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _VitalCard(
            selected: !_showWeight,
            onTap: () => setState(() => _showWeight = false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'BCS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.08 * 11,
                        color: pt.ink500,
                      ),
                    ),
                    const Spacer(),
                    _BcsStatus(bcs: bcsLast),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$bcsLast',
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.02 * 30,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('/ 9', style: TextStyle(fontSize: 14, color: pt.ink500)),
                  ],
                ),
                const SizedBox(height: 4),
                _Sparkline(
                  data: _bcs.map((v) => v.toDouble()).toList(),
                  color: !_showWeight ? accent : pt.ink300,
                  min: 1,
                  max: 9,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VitalCard extends StatelessWidget {
  const _VitalCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationSm,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.blue500.withAlpha(85),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: AppColors.blue500,
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(color: pt.line200.withAlpha(128), blurRadius: 0, spreadRadius: 0.5),
                  const BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: Offset(0, 1)),
                ],
        ),
        child: child,
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.delta, required this.unit});

  final double delta;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final neutral = delta.abs() < 0.05;
    final positive = delta > 0;
    final color = neutral
        ? pt.ink500
        : (positive ? AppColors.warning : AppColors.success);
    final bg = neutral
        ? pt.surface2
        : (positive
            ? const Color(0xFFFBE7D0)
            : const Color(0xFFDAEBE0));
    final str = '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} $unit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(str,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _BcsStatus extends StatelessWidget {
  const _BcsStatus({required this.bcs});
  final int bcs;

  @override
  Widget build(BuildContext context) {
    final ideal = bcs >= 4 && bcs <= 5;
    final color = ideal ? AppColors.success : AppColors.warning;
    final bg = ideal ? const Color(0xFFDAEBE0) : const Color(0xFFFBE7D0);
    final label = ideal ? 'Ideal' : (bcs < 4 ? 'Lean' : 'Overweight');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.data, required this.color, this.min, this.max});

  final List<double> data;
  final Color color;
  final double? min;
  final double? max;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          color: color,
          minOverride: min,
          maxOverride: max,
        ),
        size: Size.infinite,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vitals Chart
// ─────────────────────────────────────────────────────────────────────────────

class _VitalsChart extends StatefulWidget {
  const _VitalsChart({required this.species, required this.outdoor});
  final PetSpecies species;
  final bool outdoor;

  @override
  State<_VitalsChart> createState() => _VitalsChartState();
}

class _VitalsChartState extends State<_VitalsChart> {
  bool _showWeight = true;

  static const _weights = [20.4, 20.1, 19.8, 19.6, 19.4, 19.3, 19.5, 19.7, 19.6, 19.4, 19.2, 19.1];
  static const _bcs    = [6, 6, 5, 5, 5, 5, 5, 5, 4, 4, 5, 5];
  static const _labels = ['Mar 1','Mar 15','Apr 1','Apr 15','May 1','May 15'];

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final accent = widget.species.accent;

    final data = _showWeight
        ? _weights.map((v) => v).toList()
        : _bcs.map((v) => v.toDouble()).toList();
    final isWeight = _showWeight;
    final lastVal = data.last;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: pt.line200.withAlpha(128), blurRadius: 0, spreadRadius: 0.5),
          const BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isWeight
                          ? 'Weight · last 12 weeks'
                          : 'Body Condition · last 12 weeks',
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isWeight
                          ? 'Target range shaded'
                          : 'Ideal: 4–5 / 9 (Purina chart)',
                      style: TextStyle(fontSize: 12, color: pt.ink500),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: pt.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '12W',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink700,
                    letterSpacing: 0.02 * 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 340 / 200,
            child: CustomPaint(
              painter: _VitalsChartPainter(
                data: data,
                labels: _labels,
                accent: accent,
                isWeight: isWeight,
                outdoor: widget.outdoor,
                lastLabel: isWeight
                    ? '${lastVal.toStringAsFixed(1)} kg'
                    : '${lastVal.toInt()} / 9',
              ),
            ),
          ),
          // BCS scale bar
          if (!isWeight) ...[
            const SizedBox(height: 8),
            _BcsScaleBar(current: _bcs.last),
          ],
        ],
      ),
    );
  }
}

class _BcsScaleBar extends StatelessWidget {
  const _BcsScaleBar({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: pt.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(9, (i) {
          final n = i + 1;
          final ideal = n >= 4 && n <= 5;
          final isCurrent = n == current;
          return Expanded(
            child: AnimatedContainer(
              duration: PetfolioThemeExtension.durationSm,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: ideal
                    ? AppColors.meadow500
                    : (n < 4 ? AppColors.blue200 : AppColors.apricot500),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isCurrent
                    ? [const BoxShadow(
                        color: AppColors.ink950, blurRadius: 0, spreadRadius: 2)]
                    : null,
              ),
              child: isCurrent
                  ? Center(
                      child: Text(
                        '$n',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Next Checkup Card
// ─────────────────────────────────────────────────────────────────────────────

class _NextCheckupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: pt.line200.withAlpha(128), blurRadius: 0, spreadRadius: 0.5),
          const BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // Calendar chip
          Container(
            width: 48,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'JUN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.08 * 9,
                    color: AppColors.blue600,
                  ),
                ),
                Text(
                  '18',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Annual wellness check',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Highbury Vets · 10:40 AM · 37 days',
                  style: TextStyle(fontSize: 12, color: pt.ink500),
                ),
              ],
            ),
          ),

          // Details button
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: pt.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                'Details',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

/// Task glyphs: feed (fork + knife), walk (person), med (capsule)
class _TaskGlyphPainter extends CustomPainter {
  const _TaskGlyphPainter({
    required this.task,
    required this.color,
    this.strokeWidth = 1.8,
  });

  final CareTaskType task;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.width / 14; // scale factor (design is 14×14)

    switch (task) {
      case CareTaskType.feed:
        // Fork-like: vertical stem + left prongs
        canvas.drawLine(
            Offset(3 * s, 2 * s), Offset(3 * s, 12 * s), paint);
        canvas.drawLine(
            Offset(3 * s, 2 * s), Offset(2 * s, 5 * s), paint);
        canvas.drawLine(
            Offset(3 * s, 5 * s), Offset(2 * s, 5 * s), paint);
        // Right prong (spoon bowl)
        canvas.drawLine(
            Offset(10.5 * s, 2 * s), Offset(10.5 * s, 6 * s), paint);
        canvas.drawLine(
            Offset(10.5 * s, 6 * s), Offset(10.5 * s, 12 * s), paint);
        canvas.drawLine(
            Offset(9.5 * s, 2 * s), Offset(9.5 * s, 6 * s), paint);

      case CareTaskType.walk:
        // Simple walking person glyph
        canvas.drawCircle(
            Offset(9 * s, 2.5 * s), 1.3 * s, paint..style = PaintingStyle.stroke);
        paint.style = PaintingStyle.stroke;
        // Body path
        final path = Path()
          ..moveTo(7.5 * s, 5 * s)
          ..lineTo(5.5 * s, 8.5 * s)
          ..lineTo(7.5 * s, 9.9 * s)
          ..lineTo(7 * s, 13.5 * s);
        canvas.drawPath(path, paint);
        // Arm
        canvas.drawLine(
            Offset(9 * s, 8 * s), Offset(11 * s, 9.4 * s), paint);
        canvas.drawLine(
            Offset(11 * s, 9.4 * s), Offset(9.7 * s, 12 * s), paint);

      case CareTaskType.med:
        // Capsule (rotated rectangle with diagonal divider)
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(7 * s, 7 * s), width: 12 * s, height: 4 * s),
          Radius.circular(2 * s),
        );
        final matrix = Matrix4.identity()
          ..translate(7 * s, 7 * s)
          ..rotateZ(-math.pi / 6)
          ..translate(-7 * s, -7 * s);
        canvas.save();
        canvas.transform(matrix.storage);
        canvas.drawRRect(rect, paint);
        canvas.drawLine(
            Offset(7 * s, 5 * s), Offset(7 * s, 9 * s), paint);
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TaskGlyphPainter old) =>
      old.task != task || old.color != color;
}

/// Mini sparkline for vitals tabs
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.data,
    required this.color,
    this.minOverride,
    this.maxOverride,
  });

  final List<double> data;
  final Color color;
  final double? minOverride;
  final double? maxOverride;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final lo = minOverride ?? (data.reduce(math.min) - 0.5);
    final hi = maxOverride ?? (data.reduce(math.max) + 0.5);
    final range = hi - lo;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - lo) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.color != color;
}

/// Full vitals line chart with area, ideal zone, axis labels, last-value badge
class _VitalsChartPainter extends CustomPainter {
  const _VitalsChartPainter({
    required this.data,
    required this.labels,
    required this.accent,
    required this.isWeight,
    required this.outdoor,
    required this.lastLabel,
  });

  final List<double> data;
  final List<String> labels;
  final Color accent;
  final bool isWeight;
  final bool outdoor;
  final String lastLabel;

  static const _padL = 40.0;
  static const _padR = 14.0;
  static const _padT = 20.0;
  static const _padB = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    final innerW = size.width - _padL - _padR;
    final innerH = size.height - _padT - _padB;

    final lo = isWeight ? data.reduce(math.min) - 1 : 1.0;
    final hi = isWeight ? data.reduce(math.max) + 1 : 9.0;
    final range = hi - lo;

    double xAt(int i) => _padL + (i / (data.length - 1)) * innerW;
    double yAt(double v) => _padT + innerH - ((v - lo) / range) * innerH;

    final gridPaint = Paint()
      ..color = AppColors.line200
      ..strokeWidth = 1;
    final gridDash = Paint()
      ..color = AppColors.line200
      ..strokeWidth = 1;

    // Y grid lines + labels
    const yTicks = 4;
    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
      color: outdoor ? AppColors.ink700 : AppColors.ink500,
    );

    for (var i = 0; i <= yTicks; i++) {
      final v = lo + (i / yTicks) * range;
      final y = yAt(v);
      final isSolid = i == 0 || i == yTicks;

      if (isSolid) {
        canvas.drawLine(Offset(_padL, y), Offset(size.width - _padR, y), gridPaint);
      } else {
        _drawDashedLine(canvas, Offset(_padL, y), Offset(size.width - _padR, y), gridDash);
      }

      final valStr = isWeight ? v.toStringAsFixed(1) : v.round().toString();
      _drawText(canvas, valStr, Offset(_padL - 8, y + 4), labelStyle, TextAlign.right);
    }

    // Ideal zone
    final idealPaint = Paint()
      ..color = AppColors.meadow500.withAlpha(outdoor ? 46 : 33)
      ..style = PaintingStyle.fill;

    if (isWeight) {
      final idealMid = 19.5;
      final lo2 = yAt(idealMid * 1.03);
      final hi2 = yAt(idealMid * 0.97);
      canvas.drawRect(
          Rect.fromLTWH(_padL, lo2, innerW, hi2 - lo2), idealPaint);
    } else {
      final top = yAt(5.0);
      final bot = yAt(4.0);
      canvas.drawRect(Rect.fromLTWH(_padL, top, innerW, bot - top), idealPaint);
    }

    // Area fill
    final pts = List.generate(data.length, (i) => Offset(xAt(i), yAt(data[i])));
    final areaPath = Path()
      ..moveTo(_padL, _padT + innerH)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath
      ..lineTo(pts.last.dx, _padT + innerH)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..color = accent.withAlpha(20)
        ..style = PaintingStyle.fill,
    );

    // Line
    final linePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Data points
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final isLast = i == pts.length - 1;

      if (isLast) {
        // Pulse ring
        canvas.drawCircle(p, 11, Paint()..color = accent.withAlpha(38));
      }
      canvas.drawCircle(
          p,
          isLast ? 5 : 3,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          p,
          isLast ? 5 : 3,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = isLast ? 3 : 2);
    }

    // Last value badge
    final last = pts.last;
    const badgeW = 70.0, badgeH = 22.0;
    final badgeLeft = (last.dx - badgeW / 2).clamp(_padL, size.width - _padR - badgeW);
    final badgeTop = last.dy - 30;
    final badgeRect =
        RRect.fromRectAndRadius(Rect.fromLTWH(badgeLeft, badgeTop, badgeW, badgeH), const Radius.circular(6));
    canvas.drawRRect(badgeRect, Paint()..color = accent);
    _drawText(
      canvas,
      lastLabel,
      Offset(badgeLeft + badgeW / 2, badgeTop + 15),
      const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Inter'),
      TextAlign.center,
    );

    // X labels (show every other + last)
    for (var i = 0; i < labels.length; i++) {
      final xi = (i / (labels.length - 1)) * (data.length - 1);
      final x = xAt(xi.round());
      if (i % 2 != 0 && i != labels.length - 1) continue;
      _drawText(canvas, labels[i], Offset(x, size.height - 8), labelStyle, TextAlign.center);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 2.0, gap = 4.0;
    final total = (to - from).distance;
    final dir = (to - from) / total;
    var pos = 0.0;
    while (pos < total) {
      final end = math.min(pos + dash, total);
      canvas.drawLine(from + dir * pos, from + dir * end, paint);
      pos += dash + gap;
    }
  }

  void _drawText(Canvas canvas, String text, Offset anchor,
      TextStyle style, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        align == TextAlign.right
            ? anchor.dx - tp.width
            : align == TextAlign.center
                ? anchor.dx - tp.width / 2
                : anchor.dx,
        anchor.dy - tp.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_VitalsChartPainter old) =>
      old.data != data || old.accent != accent || old.outdoor != outdoor;
}

/// Narrow left-pointing chevron (same as onboarding back button)
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Iterable.mapIndexed extension (used in TodayTasksCard)
// ─────────────────────────────────────────────────────────────────────────────

extension _IterableX<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T item) fn) {
    var i = 0;
    return map((item) => fn(i++, item));
  }
}
