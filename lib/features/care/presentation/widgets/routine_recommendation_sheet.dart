import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petfolio/core/models/pet.dart';
import 'package:petfolio/features/care/data/models/care_task.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/core/widgets/app_snack_bar.dart';
import 'package:petfolio/core/theme/theme.dart';

class RoutineRecommendationSheet extends ConsumerStatefulWidget {
  const RoutineRecommendationSheet({
    super.key,
    required this.pet,
    required this.recommendedTasks,
    this.isRefresh = false,
  });

  final Pet pet;
  final List<CareTask> recommendedTasks;
  final bool isRefresh;

  static Future<void> show(
    BuildContext context,
    Pet pet,
    List<CareTask> tasks, {
    bool isRefresh = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineRecommendationSheet(
        pet: pet,
        recommendedTasks: tasks,
        isRefresh: isRefresh,
      ),
    );
  }

  @override
  ConsumerState<RoutineRecommendationSheet> createState() =>
      _RoutineRecommendationSheetState();
}

class _RoutineRecommendationSheetState
    extends ConsumerState<RoutineRecommendationSheet> {
  final _selectedIds = <String>{};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.recommendedTasks.map((t) => t.id));
  }

  Future<void> _save() async {
    if (_selectedIds.isEmpty) {
      context.pop();
      return;
    }
    setState(() => _isSaving = true);

    final tasksToSave = widget.recommendedTasks
        .where((t) => _selectedIds.contains(t.id))
        .toList();

    try {
      await ref
          .read(careDashboardProvider.notifier)
          .bulkCreateTasks(tasksToSave, isAiSuggested: true);
      if (mounted) {
        context.pop();
        AppSnackBar.show(widget.isRefresh
            ? 'Routine refreshed with ${tasksToSave.length} new tasks!'
            : 'Personalized routine created!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError('Failed to save routine');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, List<CareTask>> _groupByFrequency() {
    final groups = <String, List<CareTask>>{
      'Daily': [],
      'Weekly': [],
      'Monthly': [],
      'Other': [],
    };
    for (final task in widget.recommendedTasks) {
      switch (task.frequency) {
        case CareFrequency.daily:
        case CareFrequency.twiceDaily:
        case CareFrequency.asNeeded:
          groups['Daily']!.add(task);
        case CareFrequency.weekly:
        case CareFrequency.biweekly:
          groups['Weekly']!.add(task);
        case CareFrequency.monthly:
          groups['Monthly']!.add(task);
        case CareFrequency.once:
          groups['Other']!.add(task);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final groups = _groupByFrequency();

    final children = <Widget>[];
    for (final entry in groups.entries) {
      if (entry.value.isEmpty) continue;
      children.add(_FrequencyGroupHeader(label: entry.key));
      for (final task in entry.value) {
        children.add(_TaskRecommendationCard(
          task: task,
          isSelected: _selectedIds.contains(task.id),
          onToggle: (val) => setState(() {
            if (val == true) {
              _selectedIds.add(task.id);
            } else {
              _selectedIds.remove(task.id);
            }
          }),
        ));
      }
    }

    return Container(
      height: size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(PetfolioThemeExtension.radius2xl)),
        boxShadow: theme.extension<PetfolioThemeExtension>()!.shadowE4,
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: children,
            ),
          ),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome,
                    color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isRefresh
                          ? 'Refreshed Routine'
                          : 'Suggested Routine',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'AI-personalized for ${widget.pet.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  if (_selectedIds.length ==
                      widget.recommendedTasks.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(
                        widget.recommendedTasks.map((t) => t.id));
                  }
                }),
                child: Text(
                  _selectedIds.length == widget.recommendedTasks.length
                      ? 'Deselect all'
                      : 'Select all',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RoutineSummaryChips(tasks: widget.recommendedTasks),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: (_isSaving || _selectedIds.isEmpty) ? null : _save,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusLg)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    _selectedIds.isEmpty
                        ? 'Select tasks to add'
                        : 'Add ${_selectedIds.length} Tasks to Routine',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RoutineSummaryChips extends StatelessWidget {
  const _RoutineSummaryChips({required this.tasks});

  final List<CareTask> tasks;

  @override
  Widget build(BuildContext context) {
    int daily = 0, weekly = 0, monthly = 0;
    for (final t in tasks) {
      switch (t.frequency) {
        case CareFrequency.daily:
        case CareFrequency.twiceDaily:
        case CareFrequency.asNeeded:
          daily++;
        case CareFrequency.weekly:
        case CareFrequency.biweekly:
          weekly++;
        case CareFrequency.monthly:
          monthly++;
        case CareFrequency.once:
          break;
      }
    }
    return Wrap(
      spacing: 8,
      children: [
        if (daily > 0)
          _SummaryChip(
              label: '$daily daily',
              color: Colors.blue.shade600,
              icon: Icons.wb_sunny_rounded),
        if (weekly > 0)
          _SummaryChip(
              label: '$weekly weekly',
              color: Colors.green.shade600,
              icon: Icons.calendar_view_week_rounded),
        if (monthly > 0)
          _SummaryChip(
              label: '$monthly monthly',
              color: Colors.purple.shade600,
              icon: Icons.calendar_month_rounded),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip(
      {required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _FrequencyGroupHeader extends StatelessWidget {
  const _FrequencyGroupHeader({required this.label});

  final String label;

  static IconData _iconFor(String label) {
    switch (label) {
      case 'Daily':
        return Icons.wb_sunny_rounded;
      case 'Weekly':
        return Icons.calendar_view_week_rounded;
      case 'Monthly':
        return Icons.calendar_month_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(_iconFor(label), size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRecommendationCard extends StatelessWidget {
  const _TaskRecommendationCard({
    required this.task,
    required this.isSelected,
    required this.onToggle,
  });

  final CareTask task;
  final bool isSelected;
  final ValueChanged<bool?> onToggle;

  String _frequencyLabel(CareFrequency f) {
    switch (f) {
      case CareFrequency.daily:
        return 'Every day';
      case CareFrequency.twiceDaily:
        return 'Twice a day';
      case CareFrequency.weekly:
        return 'Once a week';
      case CareFrequency.biweekly:
        return 'Every 2 weeks';
      case CareFrequency.monthly:
        return 'Once a month';
      case CareFrequency.asNeeded:
        return 'As needed';
      case CareFrequency.once:
        return 'One time';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.cardColor,
          border:
              Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusLg),
          boxShadow: isSelected ? theme.extension<PetfolioThemeExtension>()!.shadowE1 : null,
        ),
        child: CheckboxListTile(
          value: isSelected,
          onChanged: onToggle,
          activeColor: theme.colorScheme.primary,
          checkColor: theme.colorScheme.onPrimary,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              Icon(task.categoryIconData, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.repeat_rounded,
                      size: 13, color: color.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Text(
                    task.scheduledTime != null
                        ? '${_frequencyLabel(task.frequency)} at ${task.scheduledTime}'
                        : _frequencyLabel(task.frequency),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    '+${task.gamificationPoints} pts',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (task.notes != null && task.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 13,
                          color: theme.colorScheme.onSecondaryContainer
                              .withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
