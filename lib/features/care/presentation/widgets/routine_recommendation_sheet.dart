import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petfolio/core/models/pet.dart';
import 'package:petfolio/features/care/data/models/care_task.dart';
import 'package:petfolio/features/care/presentation/controllers/ai_routine_controller.dart';
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/core/widgets/app_snack_bar.dart';
import 'package:petfolio/core/theme/theme.dart';

class RoutineRecommendationSheet extends ConsumerStatefulWidget {
  const RoutineRecommendationSheet({super.key, required this.pet});

  final Pet pet;

  static Future<void> show(BuildContext context, Pet pet) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineRecommendationSheet(pet: pet),
    );
  }

  @override
  ConsumerState<RoutineRecommendationSheet> createState() =>
      _RoutineRecommendationSheetState();
}

class _RoutineRecommendationSheetState
    extends ConsumerState<RoutineRecommendationSheet> {
  bool _isSaving = false;
  final Map<String, TextEditingController> _titleEdits = {};

  @override
  void dispose() {
    for (final c in _titleEdits.values) { c.dispose(); }
    super.dispose();
  }

  String _resolvedTitle(AiSuggestion s) {
    final edited = _titleEdits[s.task.id]?.text.trim() ?? '';
    return edited.isNotEmpty ? edited : s.task.title;
  }

  List<AiSuggestion> get _suggestions =>
      ref.read(aiRoutineProvider).suggestions;

  bool get _hasSelections =>
      _suggestions.any((s) => s.isSelected && !s.isDuplicate);

  Future<bool> _confirmDismiss() async {
    if (!_hasSelections) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard suggestions?'),
        content: const Text(
            'You have selected tasks. Are you sure you want to close without adding them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep reviewing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  Future<void> _save() async {
    final toSave = _suggestions
        .where((s) => s.isSelected && !s.isDuplicate)
        .map((s) {
          final title = _resolvedTitle(s);
          if (title == s.task.title) return s.task;
          return s.task.copyWith(title: title);
        })
        .toList();

    if (toSave.isEmpty) {
      if (mounted) context.pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(careDashboardProvider.notifier)
          .bulkCreateTasks(toSave, isAiSuggested: true);
      if (!mounted) return;
      ref.read(aiRoutineProvider.notifier).invalidateCache();
      // ignore: use_build_context_synchronously
      context.pop();
      AppSnackBar.show(
        toSave.length == 1
            ? '1 task added to ${widget.pet.name}\'s routine!'
            : '${toSave.length} tasks added to ${widget.pet.name}\'s routine!',
      );
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          'Failed to save routine. Tap to retry.',
          onRetry: _save,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Frequency grouping ─────────────────────────────────────────────────────

  static const _groupOrder = ['Daily', 'Twice Daily', 'Weekly', 'As Needed', 'Monthly', 'One-Time', 'Other'];

  Map<String, List<AiSuggestion>> _groupByFrequency(List<AiSuggestion> suggestions) {
    final groups = <String, List<AiSuggestion>>{for (final g in _groupOrder) g: []};
    for (final s in suggestions) {
      switch (s.task.frequency) {
        case CareFrequency.daily:
          groups['Daily']!.add(s);
        case CareFrequency.twiceDaily:
          groups['Twice Daily']!.add(s);
        case CareFrequency.weekly:
        case CareFrequency.biweekly:
          groups['Weekly']!.add(s);
        case CareFrequency.asNeeded:
          groups['As Needed']!.add(s);
        case CareFrequency.monthly:
          groups['Monthly']!.add(s);
        case CareFrequency.once:
          groups['One-Time']!.add(s);
      }
    }
    return groups;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final aiState = ref.watch(aiRoutineProvider);
    final suggestions = aiState.suggestions;
    final groups = _groupByFrequency(suggestions);

    final notifier = ref.read(aiRoutineProvider.notifier);
    final allSelectableCount =
        suggestions.where((s) => !s.isDuplicate).length;
    final selectedCount = suggestions.where((s) => s.isSelected && !s.isDuplicate).length;
    final allSelected = allSelectableCount > 0 && selectedCount == allSelectableCount;

    final listChildren = <Widget>[];
    for (final groupLabel in _groupOrder) {
      final items = groups[groupLabel];
      if (items == null || items.isEmpty) continue;
      listChildren.add(_FrequencyGroupHeader(label: groupLabel));
      for (final suggestion in items) {
        listChildren.add(_TaskSuggestionCard(
          suggestion: suggestion,
          titleController: suggestion.isDuplicate
              ? null
              : (_titleEdits[suggestion.task.id] ??= TextEditingController(text: suggestion.task.title)),
          onToggle: suggestion.isDuplicate
              ? null
              : (_) => setState(() => notifier.toggleSelection(suggestion.task.id)),
        ));
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDismiss();
        // ignore: use_build_context_synchronously
        if (ok && mounted) context.pop();
      },
      child: Container(
        height: size.height * 0.9,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(PetfolioThemeExtension.radius2xl)),
          boxShadow: theme.extension<PetfolioThemeExtension>()!.shadowE4,
        ),
        child: Column(
          children: [
            _buildHeader(theme, suggestions, selectedCount, allSelected, allSelectableCount, notifier),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: listChildren,
              ),
            ),
            _buildFooter(theme, selectedCount),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    List<AiSuggestion> suggestions,
    int selectedCount,
    bool allSelected,
    int allSelectableCount,
    AiRoutineNotifier notifier,
  ) {
    final hasDuplicates = suggestions.any((s) => s.isDuplicate);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested Routine',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'AI-personalized for ${widget.pet.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (allSelectableCount > 0)
                TextButton(
                  onPressed: () => setState(
                    () => allSelected ? notifier.deselectAll() : notifier.selectAll(),
                  ),
                  child: Text(allSelected ? 'Deselect all' : 'Select all'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _RoutineSummaryChips(suggestions: suggestions),
          if (hasDuplicates) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tasks marked "Already in routine" are skipped when you save.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, int selectedCount) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(PetfolioThemeExtension.radiusLg)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    selectedCount == 0
                        ? 'Tap tasks above to select'
                        : 'Add $selectedCount Task${selectedCount == 1 ? '' : 's'} to Routine',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Summary chips ──────────────────────────────────────────────────────────────

class _RoutineSummaryChips extends StatelessWidget {
  const _RoutineSummaryChips({required this.suggestions});

  final List<AiSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    int daily = 0, twiceDaily = 0, weekly = 0, monthly = 0, asNeeded = 0, once = 0;
    for (final s in suggestions) {
      switch (s.task.frequency) {
        case CareFrequency.daily:
          daily++;
        case CareFrequency.twiceDaily:
          twiceDaily++;
        case CareFrequency.weekly:
        case CareFrequency.biweekly:
          weekly++;
        case CareFrequency.monthly:
          monthly++;
        case CareFrequency.asNeeded:
          asNeeded++;
        case CareFrequency.once:
          once++;
      }
    }
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (daily > 0)
          _SummaryChip(
              label: '$daily daily',
              color: Colors.blue.shade600,
              icon: Icons.wb_sunny_rounded),
        if (twiceDaily > 0)
          _SummaryChip(
              label: '$twiceDaily twice daily',
              color: Colors.indigo.shade600,
              icon: Icons.brightness_auto_rounded),
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
        if (asNeeded > 0)
          _SummaryChip(
              label: '$asNeeded as needed',
              color: Colors.teal.shade600,
              icon: Icons.pending_actions_rounded),
        if (once > 0)
          _SummaryChip(
              label: '$once one-time',
              color: Colors.orange.shade600,
              icon: Icons.looks_one_rounded),
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
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ── Frequency group header ─────────────────────────────────────────────────────

class _FrequencyGroupHeader extends StatelessWidget {
  const _FrequencyGroupHeader({required this.label});

  final String label;

  static IconData _iconFor(String label) {
    switch (label) {
      case 'Daily':
        return Icons.wb_sunny_rounded;
      case 'Twice Daily':
        return Icons.brightness_auto_rounded;
      case 'Weekly':
        return Icons.calendar_view_week_rounded;
      case 'Monthly':
        return Icons.calendar_month_rounded;
      case 'As Needed':
        return Icons.pending_actions_rounded;
      case 'One-Time':
        return Icons.looks_one_rounded;
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
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
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

// ── Task suggestion card ───────────────────────────────────────────────────────

class _TaskSuggestionCard extends StatelessWidget {
  const _TaskSuggestionCard({
    required this.suggestion,
    required this.onToggle,
    this.titleController,
  });

  final AiSuggestion suggestion;
  final ValueChanged<bool?>? onToggle;
  final TextEditingController? titleController;

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
    final isDuplicate = suggestion.isDuplicate;
    final isSelected = suggestion.isSelected;

    final Color accentColor;
    if (isDuplicate) {
      accentColor = theme.colorScheme.outline.withValues(alpha: 0.5);
    } else if (isSelected) {
      accentColor = theme.colorScheme.primary;
    } else {
      accentColor = theme.colorScheme.outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: isDuplicate ? 0.55 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected && !isDuplicate
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : theme.cardColor,
            border: Border.all(
                color: accentColor.withValues(alpha: isDuplicate ? 0.2 : 0.3),
                width: 1.5),
            borderRadius:
                BorderRadius.circular(PetfolioThemeExtension.radiusLg),
            boxShadow: isSelected && !isDuplicate
                ? theme.extension<PetfolioThemeExtension>()!.shadowE1
                : null,
          ),
          child: CheckboxListTile(
            value: isDuplicate ? false : isSelected,
            onChanged: isDuplicate ? null : onToggle,
            activeColor: theme.colorScheme.primary,
            checkColor: theme.colorScheme.onPrimary,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              children: [
                Icon(suggestion.task.categoryIconData,
                    size: 20, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: titleController != null
                      ? TextField(
                          controller: titleController,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          maxLines: 1,
                        )
                      : Text(
                          suggestion.task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDuplicate
                                ? theme.colorScheme.onSurfaceVariant
                                : isSelected
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                if (isDuplicate) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                          PetfolioThemeExtension.radiusXl),
                    ),
                    child: Text(
                      'Already in routine',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.repeat_rounded,
                        size: 13,
                        color: accentColor.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      suggestion.task.scheduledTime != null
                          ? '${_frequencyLabel(suggestion.task.frequency)} at ${suggestion.task.scheduledTime}'
                          : _frequencyLabel(suggestion.task.frequency),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accentColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.star_rounded,
                        size: 12, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      '+${suggestion.task.gamificationPoints} pts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (suggestion.task.notes != null &&
                    suggestion.task.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(
                          PetfolioThemeExtension.radiusSm),
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
                            suggestion.task.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSecondaryContainer,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isDuplicate && suggestion.conflictTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Matches existing: "${suggestion.conflictTitle}"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
