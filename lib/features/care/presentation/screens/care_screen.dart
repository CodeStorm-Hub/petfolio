import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';

import 'package:petfolio/core/errors/app_exception.dart';
import 'package:petfolio/core/models/pet.dart' show Pet;

import '../../data/models/care_task.dart' as dbtask;
import '../../data/models/care_task_log.dart';
import '../controllers/care_dashboard_controller.dart';
import '../utils/care_scheduled_time.dart';
import '../widgets/routine_recommendation_sheet.dart';
import '../../domain/services/care_recommendation_service.dart';

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
  bool _isGeneratingRoutine = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() => _init());
    });
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
    // careDashboardProvider auto-loads in its build() via Future.microtask.
  }

  Future<void> _generateRoutine(Pet activePet) async {
    setState(() => _isGeneratingRoutine = true);
    final hasTasks =
        ref.read(careDashboardProvider).tasks.value?.isNotEmpty == true;
    List<dbtask.CareTask>? tasks;
    Object? caught;
    try {
      final service = CareRecommendationService();
      tasks = await service.generateRecommendations(activePet);
    } catch (e) {
      caught = e;
    } finally {
      if (mounted) setState(() => _isGeneratingRoutine = false);
    }
    if (!mounted) return;
    if (caught != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate routine: $caught')),
      );
      return;
    }
    if (tasks != null) {
      RoutineRecommendationSheet.show(context, activePet, tasks,
          isRefresh: hasTasks);
    }
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

    final dashboard = ref.watch(careDashboardProvider);
    final species = activePet.speciesEnum;

    void openAddSheet() => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _CareTaskFormSheet(
            petId: activePet.id,
            petName: activePet.name,
          ),
        );

    return Scaffold(
      backgroundColor: _outdoor ? cs.surface : pt.surface1,
      floatingActionButton: FloatingActionButton(
        key: const ValueKey<String>('care_fab_add_task'),
        onPressed: openAddSheet,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeader(
              eyebrow: 'Care · ${activePet.name}',
              onOpenSwitcher: () => PetSwitcherSheet.show(context),
              onBack: Navigator.of(context).canPop()
                  ? () => Navigator.of(context).maybePop()
                  : null,
              actions: [
                AppHeaderAction(
                  iconKey: const ValueKey<String>('care_action_outdoor'),
                  icon: _outdoor
                      ? Icons.wb_sunny
                      : Icons.wb_sunny_outlined,
                  tooltip: _outdoor ? 'Indoor mode' : 'Outdoor mode',
                  filled: _outdoor,
                  onTap: () => setState(() => _outdoor = !_outdoor),
                ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 600;
                  final list = ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: [
                      _StreakBanner(
                        species: species,
                        outdoor: _outdoor,
                      ),
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: pt.line200),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowE1L,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          child: _HorizontalDatePicker(
                            selectedDate: dashboard.selectedDate,
                            onDateSelected: (d) =>
                                ref.read(careDashboardProvider.notifier).selectDate(d),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      _AiRoutineBanner(
                        activePetId: activePet.id,
                        hasNoTasks: dashboard.tasks.value?.isEmpty == true,
                        isGenerating: _isGeneratingRoutine,
                        onTap: () => _generateRoutine(activePet),
                      ),
                      _DailyTasksDashboard(
                        state: dashboard,
                        petId: activePet.id,
                        petName: activePet.name,
                        species: species,
                        onAddTask: openAddSheet,
                      ),
                      const SizedBox(height: 24),
                      _NutritionBanner(pt: pt),
                      const SizedBox(height: 12),
                      _MedicalVaultBanner(pt: pt),
                    ],
                  );
                  if (!wide) return list;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: list,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Routine Banner
// ─────────────────────────────────────────────────────────────────────────────

class _AiRoutineBanner extends StatelessWidget {
  const _AiRoutineBanner({
    required this.activePetId,
    required this.hasNoTasks,
    required this.isGenerating,
    required this.onTap,
  });

  final String activePetId;
  final bool hasNoTasks;
  final bool isGenerating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!hasNoTasks) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          onPressed: isGenerating ? null : onTap,
          icon: isGenerating
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 16),
          label: Text(isGenerating ? 'Generating…' : 'Refresh AI Routine'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isGenerating ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: isGenerating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.onPrimary),
                      )
                    : Icon(Icons.auto_awesome, color: cs.onPrimary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGenerating ? 'Generating...' : 'Generate AI Routine',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGenerating
                          ? 'Building personalized care plan...'
                          : 'Get daily, weekly & monthly tasks tailored for your pet',
                      style: TextStyle(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGenerating)
                Icon(Icons.chevron_right, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak Banner
// ─────────────────────────────────────────────────────────────────────────────

class _StreakBanner extends ConsumerWidget {
  const _StreakBanner({
    required this.species,
    required this.outdoor,
  });

  final PetSpecies species;
  final bool outdoor;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _monthShort = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  static String _letterForDate(DateTime d) => _dayLetters[d.weekday - 1];

  static List<DateTime> _weekEndingOn(DateTime endDay) {
    final end = DateUtils.dateOnly(endDay);
    return List.generate(7, (i) => end.subtract(Duration(days: 6 - i)));
  }

  static List<dbtask.CareTaskType> _distinctTypes(List<dbtask.CareTask> tasks) {
    final seen = <dbtask.CareTaskType>{};
    final out = <dbtask.CareTaskType>[];
    for (final t in tasks) {
      if (seen.add(t.taskType)) out.add(t.taskType);
    }
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(careDashboardProvider);
    final calendarToday = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(dashboard.selectedDate);
    final isViewingToday = selectedDay == calendarToday;
    final ringTasks = dashboard.tasks.value ?? [];
    final total = ringTasks.length;
    final done = ringTasks.where((t) => t.isCompleted).length;
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    final streakCount = dashboard.streak.maybeWhen(
      data: (s) => s.currentStreak,
      orElse: () => 0,
    );
    final streakNorm =
        (math.min(math.max(streakCount, 0), 28) / 28.0).clamp(0.0, 1.0);

    final weekHits = dashboard.weekGoalHit.value ?? List.filled(7, false);
    final weekDates = _weekEndingOn(selectedDay);

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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 8),
                          Text(
                            isViewingToday
                                ? 'Inner ring: tasks done today · outer: streak (28d scale)'
                                : 'Inner ring shows ${_monthShort[selectedDay.month - 1]} ${selectedDay.day}. Tasks below match this day.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(210),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(46),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isViewingToday
                                ? 'TODAY'
                                : '${_monthShort[selectedDay.month - 1]} ${selectedDay.day}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.08 * 10,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            total > 0 ? '$done / $total' : '—',
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
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    width: 158,
                    height: 158,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: streakNorm,
                            strokeWidth: 7,
                            backgroundColor: Colors.white.withAlpha(22),
                            color: Colors.white.withAlpha(100),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(13),
                          child: SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: Colors.white.withAlpha(36),
                              color: Colors.white,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ),
                        if (total > 0)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$done',
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'of $total',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(200),
                                  letterSpacing: 0.04 * 12,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              Text(
                                '$streakCount',
                                style: const TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'day streak',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(200),
                                  letterSpacing: 0.04 * 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white.withAlpha(230),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$streakCount day streak',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withAlpha(220),
                          letterSpacing: 0.04 * 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final hit = i < weekHits.length && weekHits[i];
                    final d = weekDates[i];
                    final dOnly = DateUtils.dateOnly(d);
                    final isSelectedDay = dOnly == selectedDay;
                    final isCalendarToday = dOnly == calendarToday;
                    return Column(
                      children: [
                        AnimatedContainer(
                          duration: PetfolioThemeExtension.durationSm,
                          width: isSelectedDay ? 15 : (isCalendarToday ? 13 : 11),
                          height: isSelectedDay ? 15 : (isCalendarToday ? 13 : 11),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hit
                                ? Colors.white
                                : Colors.white.withAlpha(28),
                            border: Border.all(
                              color: isSelectedDay
                                  ? Colors.white
                                  : (isCalendarToday
                                      ? Colors.white.withAlpha(220)
                                      : Colors.white.withAlpha(100)),
                              width: isSelectedDay ? 2.5 : 1,
                            ),
                            boxShadow: hit
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _letterForDate(d),
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelectedDay
                                ? Colors.white
                                : Colors.white.withAlpha(178),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (_distinctTypes(ringTasks).isNotEmpty)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _distinctTypes(ringTasks).map((tp) {
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withAlpha(90),
                          ),
                        ),
                        child: Icon(
                          dbtask.careTaskTypeIconData(tp),
                          size: 22,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
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

          final ymd =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          return Padding(
            padding: EdgeInsets.only(right: i < _totalDays - 1 ? _chipGap : 0),
            child: GestureDetector(
              key: ValueKey<String>('care_date_$ymd'),
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
    return state.tasks.when(
      loading: () => const Column(
        children: [
          _TaskCardSkeleton(),
          _TaskCardSkeleton(),
          _TaskCardSkeleton(),
        ],
      ),
      error: (err, st) => _CareErrorCard(
        error: err,
        onRetry: () => ref.read(careDashboardProvider.notifier).refresh(),
      ),
      data: (tasks) => tasks.isEmpty
          ? _EmptyRoutineState(petName: petName, date: state.selectedDate, onAddTask: onAddTask)
          : Column(
              children: tasks
                  .map(
                    (t) => _CareTaskCard(
                      task: t,
                      petId: petId,
                      petName: petName,
                      species: species,
                    ),
                  )
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
    required this.petName,
    required this.species,
  });

  final dbtask.CareTask task;
  final String petId;
  final String petName;
  final PetSpecies species;

  void _openPlanFromLog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CareTaskFormSheet(
        petId: petId,
        petName: petName,
        createSeed: task,
      ),
    );
  }

  Future<void> _confirmRemoveLog(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from this day'),
        content: Text(
          'Clear this completion for "${task.title}"? You can record it again later.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(careDashboardProvider.notifier).deleteTask(task.id);
    } catch (e) {
      AppSnackBar.showError(e);
    }
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CareTaskFormSheet(
        petId: petId,
        petName: petName,
        existing: task,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task'),
        content: Text(
          'Remove "${task.title}" from ${petName.isNotEmpty ? petName : "this pet"}\'s care plan? '
          'Logs you already saved for this activity stay in history.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(careDashboardProvider.notifier).deleteTask(task.id);
    } catch (e) {
      AppSnackBar.showError(e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final done = task.isCompleted;
    final logOnly = task.isLogDerived;

    Widget tile() {
      return GestureDetector(
        onTap: () {
          if (logOnly) {
            if (!done) return;
            ref.read(careDashboardProvider.notifier).toggleTaskCompletion(task.id, isCompleted: false);
            return;
          }
          ref.read(careDashboardProvider.notifier).toggleTaskCompletion(task.id, isCompleted: !done);
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
              AnimatedContainer(
                duration: PetfolioThemeExtension.durationSm,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: done ? species.accent.withAlpha(25) : pt.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  task.categoryIconData,
                  size: 20,
                  color: done ? species.accent : pt.ink500,
                ),
              ),
              const SizedBox(width: 12),
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
              PopupMenuButton<String>(
                key: ValueKey<String>('care_task_menu_${task.id}'),
                tooltip: 'Task options',
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded, color: pt.ink500, size: 22),
                onSelected: (value) {
                  if (logOnly) {
                    if (value == 'add_plan') {
                      _openPlanFromLog(context);
                    } else if (value == 'remove_day') {
                      _confirmRemoveLog(context, ref);
                    }
                  } else {
                    if (value == 'edit') {
                      _openEditSheet(context);
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  }
                },
                itemBuilder: (ctx) => logOnly
                    ? const [
                        PopupMenuItem(value: 'add_plan', child: Text('Add to plan')),
                        PopupMenuItem(value: 'remove_day', child: Text('Remove from day')),
                      ]
                    : const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                key: ValueKey<String>('care_task_check_${task.id}'),
                onTap: () {
                  if (logOnly) {
                    if (!done) return;
                    ref
                        .read(careDashboardProvider.notifier)
                        .toggleTaskCompletion(task.id, isCompleted: false);
                    return;
                  }
                  ref
                      .read(careDashboardProvider.notifier)
                      .toggleTaskCompletion(task.id, isCompleted: !done);
                },
                child: AnimatedContainer(
                  duration: PetfolioThemeExtension.durationSm,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: done ? AppColors.success : Colors.transparent,
                    shape: BoxShape.circle,
                    border: done ? null : Border.all(color: AppColors.ink300, width: 2),
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
    );
  }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: logOnly
          ? tile()
          : Dismissible(
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
                    .read(careDashboardProvider.notifier)
                    .toggleTaskCompletion(task.id, isCompleted: !done);
                return false;
              },
              child: tile(),
            ),
    );
  }

  String _sublabel(dbtask.CareTask t) {
    if (t.isLogDerived) return 'Activity log | This day';
    final parts = <String>[];
    if (t.scheduledTime != null) parts.add(t.scheduledTime!);
    parts.add(_frequencyLabel(t.frequency));
    if (t.gamificationPoints > 0) parts.add('+${t.gamificationPoints} pts');
    return parts.join(' | ');
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
// Care Error Card
// ─────────────────────────────────────────────────────────────────────────────

class _CareErrorCard extends StatelessWidget {
  const _CareErrorCard({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final isNetwork = error is NetworkException;
    final message = error is AppException
        ? (error as AppException).message
        : 'Could not load tasks. Check your connection and try again.';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pt.line200, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(
            isNetwork ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
            size: 40,
            color: pt.ink300,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: pt.ink500, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
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
      key: const ValueKey<String>('care_medical_vault_banner'),
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
      key: const ValueKey<String>('care_nutrition_banner'),
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

// Add / Edit Care Task Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CareTaskFormSheet extends ConsumerStatefulWidget {
  const _CareTaskFormSheet({
    required this.petId,
    required this.petName,
    this.existing,
    this.createSeed,
  });

  final String petId;
  final String petName;
  final dbtask.CareTask? existing;
  final dbtask.CareTask? createSeed;

  @override
  ConsumerState<_CareTaskFormSheet> createState() => _CareTaskFormSheetState();
}

class _CareTaskFormSheetState extends ConsumerState<_CareTaskFormSheet> {
  var _type = dbtask.CareTaskType.feeding;
  var _frequency = dbtask.CareFrequency.daily;
  late TextEditingController _titleCtrl;
  final _titleFocus = FocusNode();
  bool _titleFocused = false;
  bool _userEditedTitle = false;
  TimeOfDay? _time;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;
  bool get _isPrefilledCreate =>
      widget.existing == null && widget.createSeed != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    final seed = widget.createSeed;
    if (ex != null) {
      _type = ex.taskType;
      _frequency = ex.frequency;
      _userEditedTitle = true;
      _titleCtrl = TextEditingController(text: ex.title);
      _time = parseCareScheduledTimeOfDay(ex.scheduledTime);
    } else if (seed != null) {
      _type = seed.taskType;
      _frequency = dbtask.CareFrequency.daily;
      _userEditedTitle = true;
      _titleCtrl = TextEditingController(text: seed.title);
      _time = parseCareScheduledTimeOfDay(seed.scheduledTime);
    } else {
      _titleCtrl = TextEditingController(text: _defaultTitle(dbtask.CareTaskType.feeding));
    }
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
      final timeStr = _time != null
          ? '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'
          : null;
      final ex = widget.existing;
      if (ex != null) {
        final updated = ex.copyWith(
          taskType: _type,
          title: title,
          frequency: _frequency,
          scheduledTime: timeStr,
          updatedAt: DateTime.now(),
        );
        await ref.read(careDashboardProvider.notifier).updateTask(updated);
      } else {
        final now = DateTime.now();
        final task = dbtask.CareTask(
          id: '',
          petId: widget.petId,
          taskType: _type,
          title: title,
          frequency: _frequency,
          scheduledTime: timeStr,
          isCompleted: false,
          gamificationPoints: 10,
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(careDashboardProvider.notifier).createTask(task);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackBar.showError(e);
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
                _isEdit
                    ? 'Edit care task'
                    : (_isPrefilledCreate ? 'Add to plan' : 'New care task'),
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
                    : Text(
                        _isEdit
                            ? 'Save changes'
                            : (_isPrefilledCreate ? 'Save plan' : 'Add Task'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

