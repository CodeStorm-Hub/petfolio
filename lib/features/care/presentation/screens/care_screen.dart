import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/widgets/pet_switcher_sheet.dart';

import 'package:petfolio/features/pet_profile/data/models/pet.dart' show Pet;

import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/widgets/care_routine_generator_button.dart';
import 'package:petfolio/features/care/presentation/widgets/care_task_form_sheet.dart';
import 'package:petfolio/features/care/presentation/widgets/care_task_list.dart';
import 'package:petfolio/features/care/presentation/widgets/gamified_care_ui.dart';
import 'package:petfolio/features/care/presentation/widgets/routine_recommendation_sheet.dart';

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
      // Intentionally NOT calling context.go('/care') here — it would dismiss
      // the SnackBar before the user can read it. The flag above prevents replay.
    });
  }

  Future<void> _generateRoutine(Pet activePet) async {
    final hasTasks =
        ref.read(careDashboardProvider).tasks.value?.isNotEmpty == true;
    try {
      final tasks = await ref
          .read(careDashboardProvider.notifier)
          .generateRoutine(activePet);
      if (!mounted || tasks == null) return;
      RoutineRecommendationSheet.show(context, activePet, tasks,
          isRefresh: hasTasks);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate routine: $e')),
      );
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
            Text('Could not load pets',
                style: TextStyle(fontSize: 15, color: pt.ink500)),
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
      return Scaffold(
          backgroundColor: pt.surface1, body: Center(child: body));
    }

    final dashboard = ref.watch(careDashboardProvider);
    final species = activePet.speciesEnum;

    void openAddSheet() => CareTaskFormSheet.show(
          context,
          petId: activePet.id,
          petName: activePet.name,
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
                  onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                ),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 600;
                  final list = ListView(
                    padding: EdgeInsets.fromLTRB(
                        0, 0, 0, MediaQuery.paddingOf(context).bottom + 120),
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
                              padding:
                                  const EdgeInsets.fromLTRB(4, 0, 4, 8),
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
                                  CareTaskDoneCounter(
                                      tasks: dashboard.tasks.value ?? []),
                                ],
                              ),
                            ),
                            CareRoutineGeneratorButton(
                              hasNoTasks:
                                  dashboard.tasks.value?.isEmpty == true,
                              isGenerating: dashboard.isGeneratingRoutine,
                              onTap: () => _generateRoutine(activePet),
                            ),
                            CareTaskList(
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
                              weekHits: dashboard.weekGoalHit.value ??
                                  List.filled(7, false),
                              progressPercent: (dashboard.tasks.value !=
                                          null &&
                                      dashboard.tasks.value!.isNotEmpty)
                                  ? (dashboard.tasks.value!
                                          .where((t) => t.isCompleted)
                                          .length /
                                      dashboard.tasks.value!.length)
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
