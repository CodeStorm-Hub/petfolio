import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/errors/app_exception.dart';
import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/features/care/data/models/care_task.dart' as dbtask;
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/utils/care_scheduled_time.dart';
import 'package:petfolio/features/care/presentation/widgets/care_coverflow_carousel.dart';
import 'package:petfolio/features/care/presentation/widgets/care_task_card.dart';
import 'package:petfolio/features/pet_profile/data/models/pet_species.dart';

enum CareFilter { all, medical, nutrition, grooming, walk }

class DailyTasksDashboard extends ConsumerStatefulWidget {
  const DailyTasksDashboard({
    super.key,
    required this.state,
    required this.petId,
    required this.petName,
    required this.species,
    this.onAddTask,
    this.categoryFilter = CareFilter.all,
  });

  final DailyRoutineState state;
  final String petId;
  final String petName;
  final PetSpecies species;
  final VoidCallback? onAddTask;
  final CareFilter categoryFilter;

  @override
  ConsumerState<DailyTasksDashboard> createState() => _DailyTasksDashboardState();
}

class _DailyTasksDashboardState extends ConsumerState<DailyTasksDashboard> {
  int _tab = 0;

  static const _tabLabels = ['Daily', 'Weekly', 'Less Often'];

  List<dbtask.CareTask> _applyFilter(List<dbtask.CareTask> tasks) {
    final f = widget.categoryFilter;
    if (f == CareFilter.all) return tasks;
    final types = switch (f) {
      CareFilter.medical   => {dbtask.CareTaskType.medication, dbtask.CareTaskType.vetVisit},
      CareFilter.nutrition => {dbtask.CareTaskType.feeding},
      CareFilter.grooming  => {dbtask.CareTaskType.grooming, dbtask.CareTaskType.bath, dbtask.CareTaskType.nailTrim, dbtask.CareTaskType.dental},
      CareFilter.walk      => {dbtask.CareTaskType.walk},
      CareFilter.all       => <dbtask.CareTaskType>{},
    };
    return tasks.where((t) => types.contains(t.taskType)).toList();
  }

  List<List<dbtask.CareTask>> _groupTasks(List<dbtask.CareTask> tasks) {
    final filtered = _applyFilter(tasks);
    return [
      filtered.where((t) =>
        t.frequency == dbtask.CareFrequency.daily ||
        t.frequency == dbtask.CareFrequency.twiceDaily ||
        t.frequency == dbtask.CareFrequency.once ||
        t.isLogDerived).toList(),
      filtered.where((t) => t.frequency == dbtask.CareFrequency.weekly).toList(),
      filtered.where((t) =>
        t.frequency == dbtask.CareFrequency.biweekly ||
        t.frequency == dbtask.CareFrequency.monthly ||
        t.frequency == dbtask.CareFrequency.asNeeded).toList(),
    ];
  }

  List<dbtask.CareTask> _sortGroup(List<dbtask.CareTask> tasks) =>
      [...tasks]..sort((a, b) {
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

  @override
  Widget build(BuildContext context) {
    return widget.state.tasks.when(
      loading: () => const Column(
        children: [CareTaskCardSkeleton(), CareTaskCardSkeleton(), CareTaskCardSkeleton()],
      ),
      error: (err, _) => _CareErrorCard(
        error: err,
        onRetry: () => ref.read(careDashboardProvider.notifier).refresh(),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return _EmptyRoutineState(
            petName: widget.petName,
            date: widget.state.selectedDate,
            onAddTask: widget.onAddTask,
          );
        }

        final groups  = _groupTasks(tasks);
        final tab     = _tab.clamp(0, 2);
        final sorted  = _sortGroup(groups[tab]);

        final planned = tasks.where((t) =>
            !t.isLogDerived && t.frequency != dbtask.CareFrequency.asNeeded).toList();
        final allDone = planned.isNotEmpty && planned.every((t) => t.isCompleted);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FreqTabBar(
              selected: tab,
              labels: _tabLabels,
              counts: groups.map((g) => g.length).toList(),
              doneCounts: groups.map((g) => g.where((t) => t.isCompleted).length).toList(),
              onSelect: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 8),
            if (allDone) _AllDoneBanner(tasks: planned),
            if (sorted.isNotEmpty)
              CoverFlowCarousel(
                key: ValueKey('cf_${widget.petId}_$tab'),
                tasks: sorted,
                petId: widget.petId,
                petName: widget.petName,
                species: widget.species,
              ),
            if (sorted.isEmpty)
              _EmptyTabState(
                tabLabel: _tabLabels[tab],
                onAddTask: widget.onAddTask,
              ),
          ],
        );
      },
    );
  }
}

class _FreqTabBar extends StatelessWidget {
  const _FreqTabBar({
    required this.selected,
    required this.labels,
    required this.counts,
    required this.doneCounts,
    required this.onSelect,
  });

  final int selected;
  final List<String> labels;
  final List<int> counts;
  final List<int> doneCounts;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mintSoft = isDark ? AppColors.mintSoftD : AppColors.mintSoft;
    final sunnySoft = isDark ? AppColors.sunnySoftD : AppColors.sunnySoft;
    final mint700 = isDark ? AppColors.mint700D : AppColors.mint700;
    final sunny700 = isDark ? AppColors.sunny700D : AppColors.sunny700;

    return Row(
      children: List.generate(labels.length, (i) {
        final active   = i == selected;
        final count    = counts[i];
        final done     = doneCounts[i];
        final allDone  = count > 0 && done == count;
        final hasCount = count > 0;

        return Expanded(
          child: Semantics(
            label: hasCount ? '${labels[i]}, $done of $count done' : labels[i],
            selected: active,
            button: true,
            child: GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: PetfolioThemeExtension.durationSm,
              margin: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                color: active ? cs.primary : pt.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? Colors.transparent : pt.line,
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : pt.ink500,
                      height: 1.2,
                    ),
                  ),
                  if (hasCount) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withAlpha(40)
                            : (allDone ? mintSoft : sunnySoft),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        allDone ? '$done/$count ✓' : '$done/$count',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : (allDone ? mint700 : sunny700),
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        );
      }),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({required this.tabLabel, this.onAddTask});

  final String tabLabel;
  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 28, color: pt.ink300),
          const SizedBox(height: 8),
          Text(
            'No $tabLabel tasks',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: pt.ink500,
            ),
          ),
          if (onAddTask != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Add task'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllDoneBanner extends StatelessWidget {
  const _AllDoneBanner({required this.tasks});
  final List<dbtask.CareTask> tasks;

  @override
  Widget build(BuildContext context) {
    final totalXp = tasks.fold<int>(
      0, (sum, t) => sum + t.gamificationPoints,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mintSoft = isDark ? AppColors.mintSoftD : AppColors.mintSoft;
    final sunnySoft = isDark ? AppColors.sunnySoftD : AppColors.sunnySoft;
    final mint700 = isDark ? AppColors.mint700D : AppColors.mint700;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mintSoft, sunnySoft],
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
                Text(
                  'All done for today!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: mint700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You earned $totalXp XP today ⭐',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: mint700,
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
