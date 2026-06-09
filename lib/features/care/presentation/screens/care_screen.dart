import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/models/pet.dart' show Pet;
import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/care/data/models/care_task.dart' as dbtask;
import 'package:petfolio/features/care/presentation/controllers/ai_routine_controller.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/widgets/care_banners.dart';
import 'package:petfolio/features/care/presentation/widgets/care_daily_tasks_dashboard.dart';
import 'package:petfolio/features/care/presentation/widgets/care_date_picker.dart';
import 'package:petfolio/features/care/presentation/widgets/care_task_form_sheet.dart';
import 'package:petfolio/features/care/presentation/widgets/gamified_care_ui.dart';
import 'package:petfolio/features/care/presentation/widgets/routine_recommendation_sheet.dart';
import 'package:petfolio/features/care/presentation/widgets/web_push_enable_banner.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/pet_list_controller.dart';

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
  bool _shouldAutoTriggerAi = false;
  CareFilter _careFilter = CareFilter.all;

  static const _filterChips = [
    (CareFilter.all, 'All', '🐾'),
    (CareFilter.medical, 'Medical', '💊'),
    (CareFilter.nutrition, 'Nutrition', '🍖'),
    (CareFilter.grooming, 'Grooming', '✂️'),
    (CareFilter.walk, 'Walk', '🦮'),
  ];

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
          builder: (_) => CareTaskFormSheet(
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
                            CareDatePicker(
                              selectedDate: dashboard.selectedDate,
                              onDateSelected: (d) => ref
                                  .read(careDashboardProvider.notifier)
                                  .selectDate(d),
                            ),
                            const SizedBox(height: 16.0),
                            // ── Category filter chips ──────────────────────
                            SizedBox(
                              height: 38,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: _filterChips.map((chip) {
                                  final active = _careFilter == chip.$1;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _careFilter = chip.$1);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 160),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: active ? AppColors.poppy : Colors.transparent,
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: active ? AppColors.poppy : pt.line,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(chip.$3, style: const TextStyle(fontSize: 13)),
                                            const SizedBox(width: 5),
                                            Text(
                                              chip.$2,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: active ? Colors.white : pt.ink950,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 16.0),
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
                            DailyTasksDashboard(
                              state: dashboard,
                              petId: activePet.id,
                              petName: activePet.name,
                              species: species,
                              onAddTask: openAddSheet,
                              categoryFilter: _careFilter,
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
                            CareUtilityBanner(pt: pt),
                            const SizedBox(height: 12),
                            CareExploreRow(pt: pt),
                            const SizedBox(height: 12),
                            CareAppointmentsBanner(pt: pt),
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

