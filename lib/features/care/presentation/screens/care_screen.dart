import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/pet_list_controller.dart';

import 'package:petfolio/core/errors/app_exception.dart';
import 'package:petfolio/core/models/pet.dart' show Pet;

import 'package:petfolio/features/care/data/models/care_task.dart' as dbtask;
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/utils/care_scheduled_time.dart';
import 'package:petfolio/features/care/presentation/widgets/routine_recommendation_sheet.dart';
import 'package:petfolio/features/care/presentation/controllers/ai_routine_controller.dart';
import 'package:petfolio/features/care/presentation/widgets/gamified_care_ui.dart';
import 'package:petfolio/features/care/presentation/widgets/web_push_enable_banner.dart';

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
  // Set after onboarding completes; triggers background AI pre-warm in build().
  bool _shouldAutoTriggerAi = false;

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
        // Mark that we should pre-warm AI as soon as the pet is available.
        setState(() => _shouldAutoTriggerAi = true);
        context.go('/care');
      }
    });
  }

  Future<void> _init() async {
    // careDashboardProvider auto-loads in its build() via Future.microtask.
  }

  // Called by banner tap and post-onboarding auto-trigger.
  // Uses cache if valid — no redundant API call.
  Future<void> _generateRoutine(Pet activePet) async {
    final current = ref.read(aiRoutineProvider);

    // Already generating (e.g. background pre-warm) — nothing to do;
    // the banner reflects the loading state via aiState.isLoading.
    if (current.isLoading) return;

    // Results cached and still valid — open sheet immediately.
    if (current.hasResults && current.isCacheValid(activePet.id)) {
      if (mounted) await RoutineRecommendationSheet.show(context, activePet);
      return;
    }

    // Fresh call — generate then show sheet.
    final existingTasks =
        ref.read(careDashboardProvider).tasks.value ?? const [];
    await ref
        .read(aiRoutineProvider.notifier)
        .generate(activePet, existingTasks);
    if (!mounted) return;
    final aiState = ref.read(aiRoutineProvider);
    if (aiState.isConfigError) return;
    if (aiState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aiState.error ?? 'Could not generate suggestions.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (aiState.hasResults) {
      // ignore: use_build_context_synchronously
      await RoutineRecommendationSheet.show(context, activePet);
    }
  }

  // Called by the compact refresh icon — always discards cache and regenerates.
  Future<void> _forceRefreshRoutine(Pet activePet) async {
    final existingTasks =
        ref.read(careDashboardProvider).tasks.value ?? const [];
    await ref
        .read(aiRoutineProvider.notifier)
        .forceRefresh(activePet, existingTasks);
    if (!mounted) return;
    final aiState = ref.read(aiRoutineProvider);
    if (aiState.isConfigError) return;
    if (aiState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aiState.error ?? 'Could not generate suggestions.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (aiState.hasResults) {
      // ignore: use_build_context_synchronously
      await RoutineRecommendationSheet.show(context, activePet);
    }
  }

  // Silently pre-warms AI generation in background (no sheet shown).
  // Called once after onboarding; clears the flag immediately to prevent
  // re-triggering on subsequent build() calls.
  void _autoPrewarmAi(Pet activePet) {
    _shouldAutoTriggerAi = false;
    final existingTasks =
        ref.read(careDashboardProvider).tasks.value ?? const [];
    ref
        .read(aiRoutineProvider.notifier)
        .generate(activePet, existingTasks);
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final activePet = ref.watch(activePetControllerProvider);

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
    final aiState = ref.watch(aiRoutineProvider);
    final species = activePet.speciesEnum;

    // Post-onboarding: silently pre-warm AI as soon as pet is confirmed
    // available. We do this in a postFrameCallback so it doesn't run during
    // build, and only when the notifier is fully idle.
    if (_shouldAutoTriggerAi && !aiState.isLoading && !aiState.hasResults) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) { if (mounted) _autoPrewarmAi(activePet); },
      );
    }

    void openAddSheet() => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          useRootNavigator: true,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;
          final list = ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
            children: [
              CareGamifiedHeader(
                activePet: activePet,
                dashboard: dashboard,
              ),
              const WebPushEnableBanner(),
              Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Space for floating hero card overlap (card at bottom:-28) ──
                            const SizedBox(height: 44.0),
                            // ── Date picker ────────────────────────────────
                            _HorizontalDatePicker(
                              selectedDate: dashboard.selectedDate,
                              onDateSelected: (d) => ref
                                  .read(careDashboardProvider.notifier)
                                  .selectDate(d),
                            ),
                            const SizedBox(height: 24.0),
                            // ── TODAY'S QUESTS header with AI refresh ──────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Today's Quests",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                      color: pt.ink500,
                                    ),
                                  ),
                                  const Spacer(),
                                  _DoneCounter(tasks: dashboard.tasks.value ?? []),
                                  const SizedBox(width: 6),
                                  // AI Routine refresh — 44×44 accessible touch target
                                  Tooltip(
                                    message: aiState.isLoading
                                        ? 'Generating AI Routine…'
                                        : 'Refresh AI Routine',
                                    child: InkWell(
                                      onTap: aiState.isLoading
                                          ? null
                                          : () => _forceRefreshRoutine(activePet),
                                      borderRadius: BorderRadius.circular(22),
                                      child: AnimatedContainer(
                                        duration: PetfolioThemeExtension.durationSm,
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.lilacSoft,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.lilac.withAlpha(50),
                                            width: 1,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: aiState.isLoading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.lilac,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.auto_awesome_rounded,
                                                size: 18,
                                                color: AppColors.lilac,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ── Config error — persistent banner ──────────
                            if (aiState.isConfigError)
                              _AiConfigErrorBanner(),
                            // ── AI empty-state full banner ─────────────────
                            if (dashboard.tasks.value?.isEmpty == true &&
                                !aiState.isConfigError)
                              _AiRoutineBanner(
                                activePetId: activePet.id,
                                hasNoTasks: true,
                                isGenerating: aiState.isLoading,
                                hasResults: aiState.hasResults,
                                onTap: () => _generateRoutine(activePet),
                              ),
                            _DailyTasksDashboard(
                              state: dashboard,
                              petId: activePet.id,
                              petName: activePet.name,
                              species: species,
                              onAddTask: openAddSheet,
                            ),
                            const SizedBox(height: 28),
                            PfSectionTitle(
                              title: 'This week',
                              accent: AppColors.mint,
                            ),
                            const SizedBox(height: 8),
                            CareGamifiedWeeklyChart(
                              selectedDay: dashboard.selectedDate,
                              weekHits: dashboard.weekGoalHit.value ?? List.filled(7, false),
                              progressPercent: () {
                                final all = dashboard.tasks.value;
                                if (all == null || all.isEmpty) return 0.0;
                                final planned = all.where((t) =>
                                    !t.isLogDerived &&
                                    t.frequency != dbtask.CareFrequency.asNeeded).toList();
                                if (planned.isEmpty) return 0.0;
                                return planned.where((t) => t.isCompleted).length / planned.length;
                              }(),
                            ),
                            const SizedBox(height: 28),
                            _UtilityBanner(pt: pt),
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
    required this.hasResults,
    required this.onTap,
  });

  final String activePetId;
  final bool hasNoTasks;
  final bool isGenerating;
  final bool hasResults;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!hasNoTasks) return const SizedBox.shrink();

    final String title;
    final String subtitle;
    if (isGenerating) {
      title = 'Preparing your routine…';
      subtitle = 'Analysing ${activePetId.isNotEmpty ? "your pet's" : "your"} profile, health records & meds';
    } else if (hasResults) {
      title = 'Your AI Routine is Ready!';
      subtitle = 'Tap to review and add personalised care tasks';
    } else {
      title = 'Generate AI Routine';
      subtitle = 'Get daily, weekly & monthly tasks tailored for your pet';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isGenerating ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasResults
                ? AppColors.lilac.withAlpha(30)
                : AppColors.lilacSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasResults
                  ? AppColors.lilac.withAlpha(120)
                  : AppColors.lilac.withAlpha(60),
              width: hasResults ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasResults ? AppColors.lilac : AppColors.lilac,
                  shape: BoxShape.circle,
                ),
                child: isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        hasResults
                            ? Icons.check_circle_outline_rounded
                            : Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.lilac700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
// AI Config Error Banner (missing NVIDIA key)
// ─────────────────────────────────────────────────────────────────────────────

class _AiConfigErrorBanner extends StatelessWidget {
  const _AiConfigErrorBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.key_off_rounded,
                size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI suggestions require an NVIDIA API key. '
                'Add NVIDIA_API_KEY to your .env and rebuild.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
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

    return ClipRect(
      child: SizedBox(
        height: 76,
        child: Stack(
          children: [
            ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _totalDays,
              itemBuilder: (context, i) {
                final date = today.subtract(Duration(days: _daysBack - i));
                final isSelected =
                    DateUtils.dateOnly(widget.selectedDate) == date;
                final isToday = date == today;
                final isFuture = date.isAfter(today);

                final ymd =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                return Padding(
                  padding: EdgeInsets.only(
                      right: i < _totalDays - 1 ? _chipGap : 0),
                  child: GestureDetector(
                    key: ValueKey<String>('care_date_$ymd'),
                    onTap: isFuture ? null : () => widget.onDateSelected(date),
                    child: AnimatedContainer(
                      duration: PetfolioThemeExtension.durationSm,
                      width: _chipW,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cs.primary
                            : (isToday
                                ? cs.primary.withAlpha(15)
                                : pt.surface2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isToday
                                  ? cs.primary.withAlpha(80)
                                  : pt.line),
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
                                      : (isFuture
                                          ? pt.ink300
                                          : cs.onSurface)),
                            ),
                          ),
                          if (isToday && !isSelected) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle),
                            ),
                          ],
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
      data: (tasks) {
        if (tasks.isEmpty) {
          return _EmptyRoutineState(
            petName: petName,
            date: state.selectedDate,
            onAddTask: onAddTask,
          );
        }

        // Check if all scheduled/repeating tasks are done (exclude asNeeded)
        final planned = tasks
            .where((t) => !t.isLogDerived && t.frequency != dbtask.CareFrequency.asNeeded)
            .toList();
        final allDone = planned.isNotEmpty &&
            planned.every((t) => t.isCompleted);

        // Group tasks by frequency bucket
        final daily = tasks
            .where((t) =>
                t.frequency == dbtask.CareFrequency.daily ||
                t.frequency == dbtask.CareFrequency.twiceDaily ||
                t.frequency == dbtask.CareFrequency.once ||
                t.isLogDerived)
            .toList();
        final weekly = tasks
            .where((t) => t.frequency == dbtask.CareFrequency.weekly)
            .toList();
        final lessOften = tasks
            .where((t) =>
                t.frequency == dbtask.CareFrequency.biweekly ||
                t.frequency == dbtask.CareFrequency.monthly ||
                t.frequency == dbtask.CareFrequency.asNeeded)
            .toList();

        final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // All-done celebration banner
            if (allDone)
              _AllDoneBanner(tasks: planned),
            // Daily tasks
            if (daily.isNotEmpty) ..._frequencyGroup(
              context, pt, 'DAILY', daily, petId, petName, species,
            ),
            // Weekly tasks
            if (weekly.isNotEmpty) ..._frequencyGroup(
              context, pt, 'WEEKLY', weekly, petId, petName, species,
            ),
            // Bi-weekly / Monthly / As-needed
            if (lessOften.isNotEmpty) ..._frequencyGroup(
              context, pt, 'LESS OFTEN', lessOften, petId, petName, species,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _frequencyGroup(
    BuildContext context,
    PetfolioThemeExtension pt,
    String label,
    List<dbtask.CareTask> tasks,
    String petId,
    String petName,
    PetSpecies species,
  ) {
    // Sort: scheduled-time tasks ascending, then no-time tasks alphabetically
    final sorted = [...tasks]..sort((a, b) {
        final aTime = parseCareScheduledTimeOfDay(a.scheduledTime);
        final bTime = parseCareScheduledTimeOfDay(b.scheduledTime);
        if (aTime != null && bTime != null) {
          return (aTime.hour * 60 + aTime.minute)
              .compareTo(bTime.hour * 60 + bTime.minute);
        }
        if (aTime != null) return -1;
        if (bTime != null) return 1;
        return a.title.compareTo(b.title);
      });

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: Row(
          children: [
            Expanded(child: Divider(color: pt.line, thickness: 1, endIndent: 10)),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.08 * 10,
                color: pt.ink300,
              ),
            ),
            Expanded(child: Divider(color: pt.line, thickness: 1, indent: 10)),
          ],
        ),
      ),
      ...sorted.map((t) => _CareTaskCard(
            task: t,
            petId: petId,
            petName: petName,
            species: species,
          )),
    ];
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
    // Exclude log-derived entries and asNeeded tasks from the daily quest count
    final planned = tasks
        .where((t) => !t.isLogDerived && t.frequency != dbtask.CareFrequency.asNeeded)
        .toList();
    if (planned.isEmpty) return const SizedBox.shrink();
    final done = planned.where((t) => t.isCompleted).length;
    final total = planned.length;
    final allDone = done == total;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('$done/$total'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: allDone ? AppColors.mintSoft : AppColors.sunnySoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          allDone ? 'All done! 🎉' : '$done/$total done',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: allDone ? AppColors.mint700 : AppColors.sunny700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All-done Celebration Banner
// ─────────────────────────────────────────────────────────────────────────────

class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner({required this.tasks});
  final List<dbtask.CareTask> tasks;

  @override
  Widget build(BuildContext context) {
    final totalXp = tasks.fold<int>(
      0, (sum, t) => sum + t.gamificationPoints,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mintSoft, AppColors.sunnySoft],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.mint.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All done for today!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mint700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You earned $totalXp XP today ⭐',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mint700,
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
      // Format as HH:MM AM/PM — strip seconds
      final tod = parseCareScheduledTimeOfDay(t.scheduledTime);
      if (tod != null) {
        final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
        final m = tod.minute.toString().padLeft(2, '0');
        final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
        final formatted = '$h:$m $period';
        return (!t.isCompleted && t.isDueToday)
            ? 'Due $formatted'
            : formatted;
      }
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
      useRootNavigator: true,
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
                  useRootNavigator: true,
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
                  useRootNavigator: true,
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
    // Only flag as urgently due when a specific scheduled time exists
    final due = !done && task.isDueToday && task.scheduledTime != null;
    final color = _color;

    final yAnim = Tween<double>(begin: 0.0, end: -72.0).animate(
      CurvedAnimation(parent: _xpCtrl, curve: const Cubic(0.2, 0.8, 0.2, 1.0)),
    );
    final opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_xpCtrl);

    final taskLabel = done
        ? '${task.title}, completed'
        : '${task.title}, $_sublabel, mark complete';

    Widget card = Semantics(
      button: true,
      label: taskLabel,
      child: GestureDetector(
      onTap: _toggle,
      onLongPress: () => _showContextMenu(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: done
              ? Color.alphaBlend(color.withAlpha(28), cs.surface)
              : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done
                ? color.withAlpha(180)
                : (due ? AppColors.poppy.withAlpha(160) : pt.line),
            width: done ? 1.5 : (due ? 1.5 : 1),
          ),
          boxShadow: due
              ? [
                  BoxShadow(
                    color: AppColors.poppy.withAlpha(40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                  ...pt.shadowE1,
                ]
              : pt.shadowE2,
        ),
        child: Row(
          children: [
            // ── Icon box ──────────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: done
                      ? [color, Color.lerp(color, Colors.white, 0.28)!]
                      : [color.withAlpha(55), color.withAlpha(22)],
                ),
                boxShadow: done
                    ? [
                        BoxShadow(
                          color: color.withAlpha(90),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                          spreadRadius: -3,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
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
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w700,
                            color: done ? pt.ink500 : cs.onSurface,
                            decoration: done ? TextDecoration.lineThrough : null,
                            decorationColor: pt.ink300,
                            height: 1.2,
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
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lilacSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _frequencyPill(task.frequency),
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                              color: AppColors.lilac700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (due) ...[
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: const BoxDecoration(
                            color: AppColors.poppy,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      Flexible(
                        child: Text(
                          _sublabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: due ? AppColors.poppy700 : pt.ink500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: done
                          ? [AppColors.mintSoft, AppColors.mintSoft]
                          : [AppColors.sunnySoft, AppColors.sunnySoft],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: done
                          ? AppColors.mint.withAlpha(80)
                          : AppColors.sunny.withAlpha(80),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${task.gamificationPoints}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                          color: done ? AppColors.mint700 : AppColors.sunny700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text('⭐', style: TextStyle(fontSize: 10, height: 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  key: ValueKey('care_task_check_${task.id}'),
                  onTap: _toggle,
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? color : cs.surface,
                      border: Border.all(
                        color: done ? color : pt.line,
                        width: done ? 0 : 2,
                      ),
                      boxShadow: done
                          ? [BoxShadow(color: color.withAlpha(80), blurRadius: 8, offset: const Offset(0, 3), spreadRadius: -2)]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: done
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
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

String _frequencyPill(dbtask.CareFrequency f) {
  switch (f) {
    case dbtask.CareFrequency.monthly:    return 'MONTHLY';
    case dbtask.CareFrequency.biweekly:   return 'BIWEEKLY';
    case dbtask.CareFrequency.weekly:     return 'WEEKLY';
    case dbtask.CareFrequency.twiceDaily: return '2× DAILY';
    case dbtask.CareFrequency.daily:      return 'DAILY';
    case dbtask.CareFrequency.once:       return 'ONCE';
    case dbtask.CareFrequency.asNeeded:   return 'AS NEEDED';
  }
}

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

// ── Merged utility banner (Nutrition | Medical Vault side-by-side) ────────────

class _UtilityBanner extends StatelessWidget {
  const _UtilityBanner({required this.pt});

  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pt.line),
        boxShadow: pt.shadowE1,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UtilityHalf(
              key: const ValueKey<String>('care_nutrition_banner'),
              icon: Icons.monitor_weight_outlined,
              iconBg: AppColors.sunnySoft,
              iconColor: AppColors.sunny700,
              title: 'Nutrition',
              subtitle: 'Weight & caloric needs',
              detail: 'Track daily feeding',
              onTap: () => context.push('/care/nutrition'),
            ),
            VerticalDivider(width: 1, thickness: 1, color: pt.line),
            _UtilityHalf(
              key: const ValueKey<String>('care_medical_vault_banner'),
              icon: Icons.folder_special_outlined,
              iconBg: AppColors.mintSoft,
              iconColor: AppColors.mint700,
              title: 'Medical Vault',
              subtitle: 'Vaccines · Meds · Vet',
              detail: 'View health records',
              onTap: () => context.push('/care/medical-vault'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UtilityHalf extends StatelessWidget {
  const _UtilityHalf({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Expanded(
      child: Semantics(
        button: true,
        label: '$title. $subtitle',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 15, color: pt.ink300),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: pt.ink950,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  height: 1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: pt.ink500,
                  height: 1,
                ),
              ),
            ],
              ),
            ),
          ),
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
