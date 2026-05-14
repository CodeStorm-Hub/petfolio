import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/pet_profile/data/models/pet.dart';
import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';

import '../../data/models/care_task.dart' as dbtask;
import '../../data/models/care_task_type.dart';
import '../controllers/care_controller.dart';
import '../controllers/care_dashboard_controller.dart';

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
  bool _onboardingSuccessHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_onboardingSuccessHandled) return;
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['onboardingComplete'] != '1') return;
    _onboardingSuccessHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pet = ref.read(activePetControllerProvider);
      final name = pet?.name.trim();
      final msg = (name != null && name.isNotEmpty)
          ? 'Pet setup complete — welcome! Start tracking daily care for $name here.'
          : 'Pet setup complete — welcome! Start tracking daily care here.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      if (!mounted) return;
      if (GoRouterState.of(context).uri.queryParameters['onboardingComplete'] == '1') {
        context.go('/care');
      }
    });
  }

  Future<void> _init() async {
    final pet = ref.read(activePetControllerProvider);
    if (pet == null) return;
    final ctrl = ref.read(careControllerProvider(pet.id).notifier);
    await ctrl.loadLocal();
    ctrl.refresh();
    // careDashboardProvider auto-loads in its build() — no manual init needed.
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final activePet = ref.watch(activePetControllerProvider);

    final petsAsync = ref.watch(petListProvider);
    if (activePet == null) {
      final body = petsAsync.when(
        skipLoadingOnReload: true,
        loading: () => const CircularProgressIndicator.adaptive(),
        error: (_, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
            const SizedBox(height: 12),
            Text('Could not load pets', style: TextStyle(fontSize: 15, color: pt.ink500)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(petListProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
        data: (pets) => pets.isEmpty
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets_outlined, size: 48, color: pt.ink300),
                  const SizedBox(height: 12),
                  Text('Add a pet to track care',
                      style: TextStyle(fontSize: 15, color: pt.ink500)),
                ],
              )
            : const CircularProgressIndicator.adaptive(),
      );
      return Scaffold(backgroundColor: pt.surface1, body: Center(child: body));
    }

    final care = ref.watch(careControllerProvider(activePet.id));
    final dashboard = ref.watch(careDashboardProvider(activePet.id));
    final species = activePet.speciesEnum;

    void openAddSheet() => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _AddCareTaskSheet(petId: activePet.id, petName: activePet.name),
        );

    return Scaffold(
      backgroundColor: _outdoor ? cs.surface : pt.surface1,
      floatingActionButton: FloatingActionButton(
        onPressed: openAddSheet,
        child: const Icon(Icons.add_rounded),
      ),
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
                  _StreakBanner(care: care, dashboard: dashboard, species: species, outdoor: _outdoor),
                  const SizedBox(height: 20),
                  _HorizontalDatePicker(
                    selectedDate: dashboard.selectedDate,
                    onDateSelected: (d) =>
                        ref.read(careDashboardProvider(activePet.id).notifier).selectDate(d),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                    child: Row(
                      children: [
                        Text(
                          'DAILY TASKS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.08 * 12,
                            color: _outdoor ? AppColors.ink700 : pt.ink500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Swipe to complete',
                          style: TextStyle(fontSize: 12, color: pt.ink300),
                        ),
                      ],
                    ),
                  ),
                  _DailyTasksDashboard(
                    state: dashboard,
                    petId: activePet.id,
                    petName: activePet.name,
                    species: species,
                    onAddTask: openAddSheet,
                  ),
                  const SizedBox(height: 20),
                  _NutritionBanner(pt: pt),
                  const SizedBox(height: 12),
                  _MedicalVaultBanner(pt: pt),
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
          _CircleButton(
            onTap: () => Navigator.of(context).maybePop(),
            child: CustomPaint(
              size: const Size(10, 18),
              painter: _ChevronPainter(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
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
                          'CARE · ${pet.name.toUpperCase()}',
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
                            Icon(Icons.keyboard_arrow_down, size: 16, color: pt.ink500),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
  const _CircleButton({required this.onTap, required this.child, this.filled = false});

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
            BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: const Offset(0, 1)),
            BoxShadow(color: pt.line200.withAlpha(128), blurRadius: 0, spreadRadius: 0.5),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak Banner (backed by ChecklistRepository — real data)
// ─────────────────────────────────────────────────────────────────────────────

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({
    required this.care,
    required this.dashboard,
    required this.species,
    required this.outdoor,
  });

  final CareState care;
  final DailyRoutineState dashboard;
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
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withAlpha(46), Colors.transparent],
                  stops: const [0, 0.65],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                style: TextStyle(fontSize: 14, color: Colors.white, height: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Builder(builder: (_) {
                      final tasks = dashboard.tasks.valueOrNull ?? [];
                      final total = tasks.length;
                      final done = tasks.where((t) => t.isCompleted).length;
                      final label = total > 0 ? '$done / $total' : '${care.todayCount} / 3';
                      return Container(
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
                              label,
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
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 14),
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
  String _dayLabel(int i) => _dayLabels[care.week[i].date.weekday - 1];
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
                      const BoxShadow(color: Colors.white, blurRadius: 0, spreadRadius: 2),
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
                          : (isFuture ? Colors.transparent : Colors.white.withAlpha(30)),
                      borderRadius: BorderRadius.circular(5),
                      border: !done && !isFuture
                          ? Border.all(color: Colors.white.withAlpha(71), width: 1)
                          : null,
                    ),
                    child: done
                        ? Center(
                            child: CustomPaint(
                              size: const Size(11, 11),
                              painter: _TaskGlyphPainter(task: t, color: AppColors.ink950),
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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal Date Picker
// ─────────────────────────────────────────────────────────────────────────────

class _HorizontalDatePicker extends StatefulWidget {
  const _HorizontalDatePicker({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_HorizontalDatePicker> createState() => _HorizontalDatePickerState();
}

class _HorizontalDatePickerState extends State<_HorizontalDatePicker> {
  late final ScrollController _scroll;

  static const _chipW = 52.0;
  static const _chipGap = 8.0;
  static const _daysBack = 7;
  static const _daysAhead = 6;
  static const _totalDays = _daysBack + 1 + _daysAhead;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (!_scroll.hasClients) return;
    final screenW = context.size?.width ?? 360;
    final todayOffset =
        _daysBack * (_chipW + _chipGap) - (screenW / 2 - _chipW / 2) + 16;
    _scroll.jumpTo(todayOffset.clamp(0.0, _scroll.position.maxScrollExtent));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final today = DateUtils.dateOnly(DateTime.now());

    return SizedBox(
      height: 76,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: _totalDays,
        itemBuilder: (context, i) {
          final date = today.subtract(Duration(days: _daysBack - i));
          final isSelected = DateUtils.dateOnly(widget.selectedDate) == date;
          final isToday = date == today;
          final isFuture = date.isAfter(today);

          return Padding(
            padding: EdgeInsets.only(right: i < _totalDays - 1 ? _chipGap : 0),
            child: GestureDetector(
              onTap: () => widget.onDateSelected(date),
              child: AnimatedContainer(
                duration: PetfolioThemeExtension.durationSm,
                width: _chipW,
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary
                      : (isToday ? cs.primary.withAlpha(15) : pt.surface2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isToday ? cs.primary.withAlpha(80) : pt.line200),
                    width: isToday && !isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayLetters[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isSelected
                            ? Colors.white.withAlpha(200)
                            : (isFuture ? pt.ink300 : pt.ink500),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 1,
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                ? cs.primary
                                : (isFuture ? pt.ink300 : cs.onSurface)),
                      ),
                    ),
                    if (isToday && !isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Tasks Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class _DailyTasksDashboard extends ConsumerWidget {
  const _DailyTasksDashboard({
    required this.state,
    required this.petId,
    required this.petName,
    required this.species,
    this.onAddTask,
  });

  final DailyRoutineState state;
  final String petId;
  final String petName;
  final PetSpecies species;
  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return state.tasks.when(
      loading: () => const Column(
        children: [
          _TaskCardSkeleton(),
          _TaskCardSkeleton(),
          _TaskCardSkeleton(),
        ],
      ),
      error: (err, st) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pt.line200, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: pt.ink300),
            const SizedBox(height: 10),
            Text(
              'Could not load tasks',
              style: TextStyle(fontSize: 15, color: pt.ink500),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.read(careDashboardProvider(petId).notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (tasks) => tasks.isEmpty
          ? _EmptyRoutineState(petName: petName, date: state.selectedDate, onAddTask: onAddTask)
          : Column(
              children: tasks
                  .map((t) => _CareTaskCard(task: t, petId: petId, species: species))
                  .toList(),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Care Task Card — Dismissible + checkbox
// ─────────────────────────────────────────────────────────────────────────────

class _CareTaskCard extends ConsumerWidget {
  const _CareTaskCard({
    required this.task,
    required this.petId,
    required this.species,
  });

  final dbtask.CareTask task;
  final String petId;
  final PetSpecies species;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final done = task.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.startToEnd,
        background: AnimatedContainer(
          duration: PetfolioThemeExtension.durationSm,
          decoration: BoxDecoration(
            color: done ? pt.surface2 : AppColors.success,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 22),
          child: Icon(
            done ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
            color: done ? pt.ink300 : Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (_) async {
          ref
              .read(careDashboardProvider(petId).notifier)
              .toggleTask(task.id, isCompleted: !done);
          return false;
        },
        child: AnimatedContainer(
          duration: PetfolioThemeExtension.durationSm,
          decoration: BoxDecoration(
            color: done ? pt.surface2 : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: pt.line200, width: 0.5),
            boxShadow: done
                ? null
                : [
                    BoxShadow(
                      color: pt.line200.withAlpha(128),
                      blurRadius: 0,
                      spreadRadius: 0.5,
                    ),
                    const BoxShadow(
                      color: AppColors.shadowE1L,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon chip
                AnimatedContainer(
                  duration: PetfolioThemeExtension.durationSm,
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: done ? species.accent.withAlpha(25) : pt.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _taskTypeIcon(task.taskType),
                    size: 20,
                    color: done ? species.accent : pt.ink500,
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
                          color: done ? pt.ink300 : cs.onSurface,
                          decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationColor: pt.ink300,
                        ),
                        child: Text(task.title, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _sublabel(task),
                        style: TextStyle(fontSize: 12, color: pt.ink500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Checkbox button
                GestureDetector(
                  onTap: () => ref
                      .read(careDashboardProvider(petId).notifier)
                      .toggleTask(task.id, isCompleted: !done),
                  child: AnimatedContainer(
                    duration: PetfolioThemeExtension.durationSm,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: done ? AppColors.success : Colors.transparent,
                      shape: BoxShape.circle,
                      border: done
                          ? null
                          : Border.all(color: AppColors.ink300, width: 2),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sublabel(dbtask.CareTask t) {
    final parts = <String>[];
    if (t.scheduledTime != null) parts.add(t.scheduledTime!);
    parts.add(_frequencyLabel(t.frequency));
    if (t.gamificationPoints > 0) parts.add('+${t.gamificationPoints} pts');
    return parts.join(' · ');
  }

  String _frequencyLabel(dbtask.CareFrequency f) {
    switch (f) {
      case dbtask.CareFrequency.once:       return 'Once';
      case dbtask.CareFrequency.daily:      return 'Daily';
      case dbtask.CareFrequency.twiceDaily: return 'Twice daily';
      case dbtask.CareFrequency.weekly:     return 'Weekly';
      case dbtask.CareFrequency.biweekly:   return 'Every 2 weeks';
      case dbtask.CareFrequency.monthly:    return 'Monthly';
      case dbtask.CareFrequency.asNeeded:   return 'As needed';
    }
  }
}

IconData _taskTypeIcon(dbtask.CareTaskType type) {
  switch (type) {
    case dbtask.CareTaskType.feeding:    return Icons.restaurant_menu_rounded;
    case dbtask.CareTaskType.walk:       return Icons.directions_walk_rounded;
    case dbtask.CareTaskType.grooming:   return Icons.content_cut_rounded;
    case dbtask.CareTaskType.medication: return Icons.medication_rounded;
    case dbtask.CareTaskType.vetVisit:   return Icons.local_hospital_rounded;
    case dbtask.CareTaskType.training:   return Icons.school_rounded;
    case dbtask.CareTaskType.playtime:   return Icons.sports_tennis_rounded;
    case dbtask.CareTaskType.dental:     return Icons.medical_services_rounded;
    case dbtask.CareTaskType.nailTrim:   return Icons.cut_rounded;
    case dbtask.CareTaskType.bath:       return Icons.water_drop_rounded;
    case dbtask.CareTaskType.other:      return Icons.star_outline_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Card Skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _TaskCardSkeleton extends StatelessWidget {
  const _TaskCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pt.line200, width: 0.5),
          boxShadow: [
            const BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            const SkeletonLoader(width: 40, height: 40, borderRadius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SkeletonLoader(width: 140, height: 14),
                  SizedBox(height: 6),
                  SkeletonLoader(width: 100, height: 11),
                ],
              ),
            ),
            const SkeletonLoader(width: 36, height: 36, borderRadius: 999),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Routine State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyRoutineState extends StatelessWidget {
  const _EmptyRoutineState({required this.petName, required this.date, this.onAddTask});

  final String petName;
  final DateTime date;
  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final isToday = DateUtils.dateOnly(date) == DateUtils.dateOnly(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: pt.surface2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.task_alt_rounded, size: 32, color: pt.ink300),
          ),
          const SizedBox(height: 16),
          Text(
            isToday ? 'No tasks for today' : 'No tasks for this day',
            style: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isToday
                  ? 'Add care tasks for ${petName.isNotEmpty ? petName : 'your pet'} to start tracking daily routines.'
                  : 'Completed tasks from this day appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: pt.ink500, height: 1.4),
            ),
          ),
          if (isToday && onAddTask != null) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add first task'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task type helpers (shared by card + sheet)
// ─────────────────────────────────────────────────────────────────────────────

String _typeLabel(dbtask.CareTaskType type) {
  switch (type) {
    case dbtask.CareTaskType.feeding:    return 'Feeding';
    case dbtask.CareTaskType.walk:       return 'Walk';
    case dbtask.CareTaskType.grooming:   return 'Grooming';
    case dbtask.CareTaskType.medication: return 'Meds';
    case dbtask.CareTaskType.vetVisit:   return 'Vet Visit';
    case dbtask.CareTaskType.training:   return 'Training';
    case dbtask.CareTaskType.playtime:   return 'Playtime';
    case dbtask.CareTaskType.dental:     return 'Dental';
    case dbtask.CareTaskType.nailTrim:   return 'Nail Trim';
    case dbtask.CareTaskType.bath:       return 'Bath';
    case dbtask.CareTaskType.other:      return 'Other';
  }
}

String _defaultTitle(dbtask.CareTaskType type) {
  switch (type) {
    case dbtask.CareTaskType.feeding:    return 'Feeding time';
    case dbtask.CareTaskType.walk:       return 'Walk';
    case dbtask.CareTaskType.grooming:   return 'Grooming session';
    case dbtask.CareTaskType.medication: return 'Medication';
    case dbtask.CareTaskType.vetVisit:   return 'Vet visit';
    case dbtask.CareTaskType.training:   return 'Training';
    case dbtask.CareTaskType.playtime:   return 'Playtime';
    case dbtask.CareTaskType.dental:     return 'Dental care';
    case dbtask.CareTaskType.nailTrim:   return 'Nail trim';
    case dbtask.CareTaskType.bath:       return 'Bath time';
    case dbtask.CareTaskType.other:      return 'New task';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Medical vault & nutrition entry banners
// ─────────────────────────────────────────────────────────────────────────────

class _MedicalVaultBanner extends StatelessWidget {
  const _MedicalVaultBanner({required this.pt});

  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/care/medical-vault'),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              BorderRadius.circular(PetfolioThemeExtension.radiusLg),
          border: Border.all(color: pt.pillarHealth.withAlpha(80)),
          boxShadow: pt.shadowE1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pt.pillarHealth.withAlpha(30),
                borderRadius: BorderRadius.circular(
                    PetfolioThemeExtension.radiusMd),
              ),
              child: Icon(Icons.folder_special_outlined,
                  color: pt.pillarHealth, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automated medical vault',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vaccines · Medications · Vet visits',
                    style: TextStyle(fontSize: 13, color: pt.ink300),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: pt.ink300),
          ],
        ),
      ),
    );
  }
}

class _NutritionBanner extends StatelessWidget {
  const _NutritionBanner({required this.pt});

  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/care/nutrition'),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              BorderRadius.circular(PetfolioThemeExtension.radiusLg),
          border: Border.all(color: pt.pillarHealth.withAlpha(80)),
          boxShadow: pt.shadowE1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: pt.pillarHealth.withAlpha(30),
                borderRadius: BorderRadius.circular(
                    PetfolioThemeExtension.radiusMd),
              ),
              child: Icon(Icons.monitor_weight_outlined,
                  color: pt.pillarHealth, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Nutrition & Weight',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track weight history · View caloric needs',
                    style: TextStyle(fontSize: 13, color: pt.ink300),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: pt.ink300),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Care Task Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddCareTaskSheet extends ConsumerStatefulWidget {
  const _AddCareTaskSheet({required this.petId, required this.petName});

  final String petId;
  final String petName;

  @override
  ConsumerState<_AddCareTaskSheet> createState() => _AddCareTaskSheetState();
}

class _AddCareTaskSheetState extends ConsumerState<_AddCareTaskSheet> {
  var _type = dbtask.CareTaskType.feeding;
  var _frequency = dbtask.CareFrequency.daily;
  late final TextEditingController _titleCtrl;
  final _titleFocus = FocusNode();
  bool _titleFocused = false;
  bool _userEditedTitle = false;
  TimeOfDay? _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: _defaultTitle(dbtask.CareTaskType.feeding));
    _titleFocus.addListener(() {
      if (mounted) setState(() => _titleFocused = _titleFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _onTypeSelected(dbtask.CareTaskType t) {
    setState(() {
      _type = t;
      if (!_userEditedTitle) _titleCtrl.text = _defaultTitle(t);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final task = dbtask.CareTask(
        id: '',
        petId: widget.petId,
        taskType: _type,
        title: title,
        frequency: _frequency,
        scheduledTime: _time != null
            ? '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'
            : null,
        isCompleted: false,
        gamificationPoints: 10,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(careDashboardProvider(widget.petId).notifier).createTask(task);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save task. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: pt.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, math.max(bottom, 24) + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: pt.line200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'New care task',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: cs.onSurface,
                ),
              ),
            ),

            // ── Task type ───────────────────────────────────────────────────
            _SheetLabel('Task type', pt),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 72,
              ),
              itemCount: dbtask.CareTaskType.values.length,
              itemBuilder: (_, i) {
                final t = dbtask.CareTaskType.values[i];
                final selected = t == _type;
                return GestureDetector(
                  onTap: () => _onTypeSelected(t),
                  child: AnimatedContainer(
                    duration: PetfolioThemeExtension.durationSm,
                    decoration: BoxDecoration(
                      color: selected ? cs.primary : pt.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? Colors.transparent : pt.line200,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_taskTypeIcon(t), size: 22,
                            color: selected ? Colors.white : pt.ink500),
                        const SizedBox(height: 5),
                        Text(
                          _typeLabel(t),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : pt.ink500,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────────────────────
            _SheetLabel('Title', pt),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: PetfolioThemeExtension.durationSm,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _titleFocused
                    ? [BoxShadow(color: cs.primary.withAlpha(30), blurRadius: 8)]
                    : [],
              ),
              child: TextField(
                controller: _titleCtrl,
                focusNode: _titleFocus,
                onChanged: (_) => _userEditedTitle = true,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 15, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'e.g. Morning feeding',
                  filled: true,
                  fillColor: _titleFocused ? cs.surface : pt.surface2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: pt.line200, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Frequency ────────────────────────────────────────────────────
            _SheetLabel('How often?', pt),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dbtask.CareFrequency.values.map((f) {
                  final selected = f == _frequency;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _frequency = f),
                      child: AnimatedContainer(
                        duration: PetfolioThemeExtension.durationSm,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? cs.primary : pt.surface2,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: selected ? Colors.transparent : pt.line200,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          _freqLabel(f),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : pt.ink500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Time (optional) ──────────────────────────────────────────────
            _SheetLabel('Time (optional)', pt),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _time ?? TimeOfDay.now(),
                );
                if (picked != null && mounted) setState(() => _time = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: pt.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pt.line200, width: 0.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 18, color: pt.ink500),
                    const SizedBox(width: 10),
                    Text(
                      _time != null ? _time!.format(context) : 'No time set',
                      style: TextStyle(
                        fontSize: 15,
                        color: _time != null ? cs.onSurface : pt.ink300,
                      ),
                    ),
                    const Spacer(),
                    if (_time != null)
                      GestureDetector(
                        onTap: () => setState(() => _time = null),
                        child: Icon(Icons.close_rounded, size: 16, color: pt.ink300),
                      )
                    else
                      Icon(Icons.chevron_right_rounded, size: 18, color: pt.ink300),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Add Task',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _freqLabel(dbtask.CareFrequency f) {
    switch (f) {
      case dbtask.CareFrequency.once:       return 'Once';
      case dbtask.CareFrequency.daily:      return 'Daily';
      case dbtask.CareFrequency.twiceDaily: return 'Twice daily';
      case dbtask.CareFrequency.weekly:     return 'Weekly';
      case dbtask.CareFrequency.biweekly:   return 'Every 2 wks';
      case dbtask.CareFrequency.monthly:    return 'Monthly';
      case dbtask.CareFrequency.asNeeded:   return 'As needed';
    }
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text, this.pt);
  final String text;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08 * 12,
          color: pt.ink500,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

class _TaskGlyphPainter extends CustomPainter {
  const _TaskGlyphPainter({
    required this.task,
    required this.color,
  });

  final CareTaskType task;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final s = size.width / 14;

    switch (task) {
      case CareTaskType.feed:
        canvas.drawLine(Offset(3 * s, 2 * s), Offset(3 * s, 12 * s), paint);
        canvas.drawLine(Offset(3 * s, 2 * s), Offset(2 * s, 5 * s), paint);
        canvas.drawLine(Offset(3 * s, 5 * s), Offset(2 * s, 5 * s), paint);
        canvas.drawLine(Offset(10.5 * s, 2 * s), Offset(10.5 * s, 6 * s), paint);
        canvas.drawLine(Offset(10.5 * s, 6 * s), Offset(10.5 * s, 12 * s), paint);
        canvas.drawLine(Offset(9.5 * s, 2 * s), Offset(9.5 * s, 6 * s), paint);
      case CareTaskType.walk:
        canvas.drawCircle(
            Offset(9 * s, 2.5 * s), 1.3 * s, paint..style = PaintingStyle.stroke);
        paint.style = PaintingStyle.stroke;
        canvas.drawPath(
          Path()
            ..moveTo(7.5 * s, 5 * s)
            ..lineTo(5.5 * s, 8.5 * s)
            ..lineTo(7.5 * s, 9.9 * s)
            ..lineTo(7 * s, 13.5 * s),
          paint,
        );
        canvas.drawLine(Offset(9 * s, 8 * s), Offset(11 * s, 9.4 * s), paint);
        canvas.drawLine(Offset(11 * s, 9.4 * s), Offset(9.7 * s, 12 * s), paint);
      case CareTaskType.med:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(7 * s, 7 * s), width: 12 * s, height: 4 * s),
          Radius.circular(2 * s),
        );
        final matrix = Matrix4.identity()
          ..translateByDouble(7 * s, 7 * s, 0, 1)
          ..rotateZ(-math.pi / 6)
          ..translateByDouble(-7 * s, -7 * s, 0, 1);
        canvas.save();
        canvas.transform(matrix.storage);
        canvas.drawRRect(rect, paint);
        canvas.drawLine(Offset(7 * s, 5 * s), Offset(7 * s, 9 * s), paint);
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TaskGlyphPainter old) => old.task != task || old.color != color;
}

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
