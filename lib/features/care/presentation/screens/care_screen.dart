import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';

import 'package:petfolio/core/errors/app_exception.dart';
import 'package:petfolio/core/models/pet.dart' show Pet;

import 'package:petfolio/features/care/data/models/care_task.dart' as dbtask;
import 'package:petfolio/features/care/data/models/care_task_log.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/utils/care_scheduled_time.dart';
import 'package:petfolio/features/care/presentation/widgets/routine_recommendation_sheet.dart';
import 'package:petfolio/features/care/domain/services/care_recommendation_service.dart';
import 'package:petfolio/features/care/presentation/widgets/gamified_care_ui.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CareScreen
// ─────────────────────────────────────────────────────────────────────────────

class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen> {
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
    final activePet = ref.watch(activePetControllerProvider);
    final themeMode = ref.watch(themeProvider);

    final petsAsync = ref.watch(petListProvider);
    if (activePet == null) {
      final body = petsAsync.when(
        skipLoadingOnReload: true,
        loading: () => const TailWagLoader(),
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
            : const TailWagLoader(),
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
      backgroundColor: pt.surface1,
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
                  iconKey: const ValueKey<String>('care_action_theme'),
                  icon: themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  tooltip: themeMode == ThemeMode.dark
                      ? 'Switch to light theme'
                      : 'Switch to dark theme',
                  onTap: () =>
                      ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 600;
                  final list = ListView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                    children: [
                      CareGamifiedHeader(
                        activePet: activePet,
                        dashboard: dashboard,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            PfSectionTitle(
                              title: 'Trophy room',
                              accent: AppColors.lilac,
                              trailing: GestureDetector(
                                onTap: () {},
                                child: const Text(
                                  'Vault →',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.lilac700,
                                  ),
                                ),
                              ),
                            ),
                            const CareGamifiedTrophyRoom(),
                            const SizedBox(height: 32),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                              child: Row(
                                children: [
                                  Text(
                                    "TODAY'S QUESTS",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.08 * 12,
                                      color: pt.ink500,
                                    ),
                                  ),
                                  const Spacer(),
                                  _DoneCounter(tasks: dashboard.tasks.value ?? []),
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
                            const SizedBox(height: 32),
                            PfSectionTitle(
                              title: 'This week',
                              accent: AppColors.mint,
                            ),
                            CareGamifiedWeeklyChart(
                              selectedDay: dashboard.selectedDate,
                              weekHits: dashboard.weekGoalHit.value ?? List.filled(7, false),
                              progressPercent: (dashboard.tasks.value != null && dashboard.tasks.value!.isNotEmpty)
                                  ? (dashboard.tasks.value!.where((t) => t.isCompleted).length / dashboard.tasks.value!.length)
                                  : 0.0,
                            ),
                            const SizedBox(height: 32),
                            _NutritionBanner(pt: pt),
                            const SizedBox(height: 16),
                            _MedicalVaultBanner(pt: pt),
                          ],
                        ),
                      ),
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
    if (!hasNoTasks) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          onPressed: isGenerating ? null : onTap,
          icon: isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.lilac,
                  ),
                )
              : const Icon(Icons.auto_awesome, size: 16, color: AppColors.lilac),
          label: Text(isGenerating ? 'Generating…' : 'Refresh AI Routine'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.lilac,
            side: const BorderSide(color: AppColors.lilac),
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
            color: AppColors.lilacSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lilac.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.lilac,
                  shape: BoxShape.circle,
                ),
                child: isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGenerating ? 'Generating...' : 'Generate AI Routine',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.lilac700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGenerating
                          ? 'Building personalized care plan...'
                          : 'Get daily, weekly & monthly tasks tailored for your pet',
                      style: const TextStyle(
                        color: AppColors.lilac700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGenerating)
                const Icon(Icons.chevron_right, color: AppColors.lilac),
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
                        : (isToday ? cs.primary.withAlpha(80) : pt.line),
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
// Done Counter
// ─────────────────────────────────────────────────────────────────────────────

class _DoneCounter extends StatelessWidget {
  const _DoneCounter({required this.tasks});
  final List<dbtask.CareTask> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    final done = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final allDone = done == total;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        key: ValueKey('$done/$total'),
        allDone ? 'All done! 🎉' : '$done/$total done',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: allDone ? AppColors.mint700 : AppColors.sunny700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Care Task Card — animated card matching JSX TaskRow design
// ─────────────────────────────────────────────────────────────────────────────

class _CareTaskCard extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<_CareTaskCard> createState() => _CareTaskCardState();
}

class _CareTaskCardState extends ConsumerState<_CareTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _xpCtrl;
  bool _showBurst = false;

  @override
  void initState() {
    super.initState();
    _xpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _showBurst = false);
          _xpCtrl.reset();
        }
      });
  }

  @override
  void dispose() {
    _xpCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    final nowDone = !widget.task.isCompleted;
    ref.read(careDashboardProvider.notifier)
        .toggleTaskCompletion(widget.task.id, isCompleted: nowDone);
    if (nowDone && widget.task.gamificationPoints > 0) {
      setState(() => _showBurst = true);
      _xpCtrl.forward(from: 0);
    }
  }

  Color get _color {
    switch (widget.task.taskType) {
      case dbtask.CareTaskType.feeding:    return AppColors.tangerine;
      case dbtask.CareTaskType.medication: return AppColors.poppy;
      case dbtask.CareTaskType.walk:       return AppColors.mint;
      case dbtask.CareTaskType.playtime:   return AppColors.sunny;
      case dbtask.CareTaskType.dental:     return AppColors.lilac;
      case dbtask.CareTaskType.grooming:   return AppColors.lilac;
      case dbtask.CareTaskType.vetVisit:   return AppColors.mint;
      case dbtask.CareTaskType.training:   return AppColors.tangerine;
      case dbtask.CareTaskType.nailTrim:   return AppColors.lilac;
      case dbtask.CareTaskType.bath:       return AppColors.sky;
      case dbtask.CareTaskType.other:      return AppColors.sunny;
    }
  }

  String get _emoji {
    switch (widget.task.taskType) {
      case dbtask.CareTaskType.feeding:    return '🥩';
      case dbtask.CareTaskType.walk:       return '🦮';
      case dbtask.CareTaskType.grooming:   return '✂️';
      case dbtask.CareTaskType.medication: return '💊';
      case dbtask.CareTaskType.vetVisit:   return '🏥';
      case dbtask.CareTaskType.training:   return '🎓';
      case dbtask.CareTaskType.playtime:   return '🎾';
      case dbtask.CareTaskType.dental:     return '🦷';
      case dbtask.CareTaskType.nailTrim:   return '💅';
      case dbtask.CareTaskType.bath:       return '🛁';
      case dbtask.CareTaskType.other:      return '⭐';
    }
  }

  bool get _isWeeklyish =>
      widget.task.frequency == dbtask.CareFrequency.weekly ||
      widget.task.frequency == dbtask.CareFrequency.biweekly ||
      widget.task.frequency == dbtask.CareFrequency.monthly;

  String get _sublabel {
    final t = widget.task;
    if (t.isLogDerived) return 'Activity log · Today';
    if (t.scheduledTime != null) {
      return (!t.isCompleted && t.isDueToday)
          ? 'Due ${t.scheduledTime}'
          : t.scheduledTime!;
    }
    switch (t.frequency) {
      case dbtask.CareFrequency.once:       return 'Once';
      case dbtask.CareFrequency.daily:      return 'Daily';
      case dbtask.CareFrequency.twiceDaily: return 'Twice daily';
      case dbtask.CareFrequency.weekly:     return 'Weekly';
      case dbtask.CareFrequency.biweekly:   return 'Every 2 weeks';
      case dbtask.CareFrequency.monthly:    return 'Monthly';
      case dbtask.CareFrequency.asNeeded:   return 'As needed';
    }
  }

  void _showContextMenu(BuildContext ctx) {
    final task = widget.task;
    final logOnly = task.isLogDerived;
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskContextMenu(
        taskTitle: task.title,
        logOnly: logOnly,
        onAddPlan: logOnly
            ? () {
                Navigator.pop(ctx);
                showModalBottomSheet<void>(
                  context: ctx,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _CareTaskFormSheet(
                    petId: widget.petId,
                    petName: widget.petName,
                    createSeed: task,
                  ),
                );
              }
            : null,
        onRemoveDay: logOnly
            ? () async {
                Navigator.pop(ctx);
                await _confirmDialog(
                  ctx,
                  title: 'Remove from this day',
                  body: 'Clear this completion for "${task.title}"?',
                  confirmLabel: 'Remove',
                  onConfirmed: () => ref
                      .read(careDashboardProvider.notifier)
                      .deleteTask(task.id),
                );
              }
            : null,
        onEdit: !logOnly
            ? () {
                Navigator.pop(ctx);
                showModalBottomSheet<void>(
                  context: ctx,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _CareTaskFormSheet(
                    petId: widget.petId,
                    petName: widget.petName,
                    existing: task,
                  ),
                );
              }
            : null,
        onDelete: !logOnly
            ? () async {
                Navigator.pop(ctx);
                await _confirmDialog(
                  ctx,
                  title: 'Delete task',
                  body: 'Remove "${task.title}" from ${widget.petName}\'s care plan?',
                  confirmLabel: 'Delete',
                  onConfirmed: () => ref
                      .read(careDashboardProvider.notifier)
                      .deleteTask(task.id),
                );
              }
            : null,
      ),
    );
  }

  Future<void> _confirmDialog(
    BuildContext ctx, {
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() onConfirmed,
  }) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(d).colorScheme.error),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok != true || !ctx.mounted) return;
    try {
      await onConfirmed();
    } catch (e) {
      AppSnackBar.showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final task = widget.task;
    final done = task.isCompleted;
    final due = !done && task.isDueToday;
    final color = _color;

    final yAnim = Tween<double>(begin: 0.0, end: -72.0).animate(
      CurvedAnimation(parent: _xpCtrl, curve: const Cubic(0.2, 0.8, 0.2, 1.0)),
    );
    final opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_xpCtrl);

    Widget card = GestureDetector(
      onTap: _toggle,
      onLongPress: () => _showContextMenu(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: done
              ? Color.alphaBlend(color.withAlpha(36), cs.surface)
              : cs.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: done ? color : pt.line,
            width: 2,
          ),
          boxShadow: due
              ? [BoxShadow(color: AppColors.poppy.withAlpha(64), blurRadius: 0, spreadRadius: 4)]
              : pt.shadowE1,
        ),
        child: Row(
          children: [
            // ── Icon box ──────────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: done ? color : color.withAlpha(48),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  key: ValueKey(done),
                  done ? '✅' : _emoji,
                  style: const TextStyle(fontSize: 26, height: 1.0),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: done ? pt.ink500 : cs.onSurface,
                            decoration: done ? TextDecoration.lineThrough : null,
                            decorationColor: pt.ink300,
                          ),
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_isWeeklyish) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lilacSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            task.frequency == dbtask.CareFrequency.monthly
                                ? 'MONTHLY'
                                : 'WEEKLY',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.lilac700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: due ? AppColors.poppy700 : pt.ink500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── XP chip + check button ────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: done ? AppColors.mintSoft : AppColors.sunnySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${task.gamificationPoints}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: done
                              ? AppColors.mint700
                              : AppColors.sunny700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Text('⭐',
                          style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _toggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? color : cs.surface,
                      border: Border.all(
                        color: done ? color : pt.line,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: done
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // ── XP burst overlay ─────────────────────────────────────────────────
    card = Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        if (_showBurst)
          Positioned(
            right: 14,
            bottom: 52,
            child: AnimatedBuilder(
              animation: _xpCtrl,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, yAnim.value),
                child: Opacity(
                  opacity: opacityAnim.value.clamp(0.0, 1.0),
                  child: Text(
                    '+${task.gamificationPoints} XP ⭐',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.sunny700,
                      shadows: [
                        Shadow(
                          color: AppColors.sunny,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    // ── Swipe-to-toggle (Dismissible) for non-log tasks ──────────────────
    if (!task.isLogDerived) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Dismissible(
          key: ValueKey('d_${task.id}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            decoration: BoxDecoration(
              color: done ? pt.surface2 : AppColors.success,
              borderRadius: BorderRadius.circular(22),
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
            _toggle();
            return false;
          },
          child: card,
        ),
      );
    }

    return Padding(padding: const EdgeInsets.only(bottom: 10), child: card);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Context Menu (long-press sheet)
// ─────────────────────────────────────────────────────────────────────────────

class _TaskContextMenu extends StatelessWidget {
  const _TaskContextMenu({
    required this.taskTitle,
    required this.logOnly,
    this.onAddPlan,
    this.onRemoveDay,
    this.onEdit,
    this.onDelete,
  });

  final String taskTitle;
  final bool logOnly;
  final VoidCallback? onAddPlan;
  final VoidCallback? onRemoveDay;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: pt.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.paddingOf(context).bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: pt.line,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          Text(taskTitle,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface)),
          const SizedBox(height: 12),
          if (onAddPlan != null)
            _MenuTile(
                icon: Icons.add_task_rounded,
                label: 'Add to plan',
                onTap: onAddPlan!),
          if (onRemoveDay != null)
            _MenuTile(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Remove from day',
                onTap: onRemoveDay!),
          if (onEdit != null)
            _MenuTile(
                icon: Icons.edit_outlined,
                label: 'Edit task',
                onTap: onEdit!),
          if (onDelete != null)
            _MenuTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete task',
                color: cs.error,
                onTap: onDelete!),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(
      {required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// XP Progress Bar (shown between streak and date picker)
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
          border: Border.all(color: pt.line, width: 0.5),
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
        border: Border.all(color: pt.line, width: 0.5),
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
                  decoration: BoxDecoration(color: pt.line, borderRadius: BorderRadius.circular(2)),
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
                        color: selected ? Colors.transparent : pt.line,
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
                    borderSide: BorderSide(color: pt.line, width: 0.5),
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
                            color: selected ? Colors.transparent : pt.line,
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
                  border: Border.all(color: pt.line, width: 0.5),
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
