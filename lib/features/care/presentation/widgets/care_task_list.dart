import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../pet_profile/data/models/pet_species.dart' show PetSpecies;
import '../../data/models/care_task.dart' as dbtask;
import '../../data/models/care_task_log.dart';
import '../controllers/care_dashboard_controller.dart';
import 'care_task_form_sheet.dart';

class CareTaskList extends ConsumerWidget {
  const CareTaskList({
    super.key,
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
      error: (err, _) => _CareErrorCard(
        error: err,
        onRetry: () => ref.read(careDashboardProvider.notifier).refresh(),
      ),
      data: (tasks) => tasks.isEmpty
          ? _EmptyRoutineState(
              petName: petName,
              date: state.selectedDate,
              onAddTask: onAddTask,
            )
          : Column(
              children: tasks
                  .map((t) => _CareTaskCard(
                        task: t,
                        petId: petId,
                        petName: petName,
                        species: species,
                      ))
                  .toList(),
            ),
    );
  }
}

class CareTaskDoneCounter extends StatelessWidget {
  const CareTaskDoneCounter({super.key, required this.tasks});
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
// Care Task Card
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
    ref
        .read(careDashboardProvider.notifier)
        .toggleTaskCompletion(widget.task.id, isCompleted: nowDone);
    if (nowDone && widget.task.gamificationPoints > 0) {
      setState(() => _showBurst = true);
      _xpCtrl.forward(from: 0);
    }
  }

  Color get _color {
    switch (widget.task.taskType) {
      case dbtask.CareTaskType.feeding:
        return AppColors.tangerine;
      case dbtask.CareTaskType.medication:
        return AppColors.poppy;
      case dbtask.CareTaskType.walk:
        return AppColors.mint;
      case dbtask.CareTaskType.playtime:
        return AppColors.sunny;
      case dbtask.CareTaskType.dental:
        return AppColors.lilac;
      case dbtask.CareTaskType.grooming:
        return AppColors.lilac;
      case dbtask.CareTaskType.vetVisit:
        return AppColors.mint;
      case dbtask.CareTaskType.training:
        return AppColors.tangerine;
      case dbtask.CareTaskType.nailTrim:
        return AppColors.lilac;
      case dbtask.CareTaskType.bath:
        return AppColors.sky;
      case dbtask.CareTaskType.other:
        return AppColors.sunny;
    }
  }

  String get _emoji {
    switch (widget.task.taskType) {
      case dbtask.CareTaskType.feeding:
        return '🥩';
      case dbtask.CareTaskType.walk:
        return '🦮';
      case dbtask.CareTaskType.grooming:
        return '✂️';
      case dbtask.CareTaskType.medication:
        return '💊';
      case dbtask.CareTaskType.vetVisit:
        return '🏥';
      case dbtask.CareTaskType.training:
        return '🎓';
      case dbtask.CareTaskType.playtime:
        return '🎾';
      case dbtask.CareTaskType.dental:
        return '🦷';
      case dbtask.CareTaskType.nailTrim:
        return '💅';
      case dbtask.CareTaskType.bath:
        return '🛁';
      case dbtask.CareTaskType.other:
        return '⭐';
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
      case dbtask.CareFrequency.once:
        return 'Once';
      case dbtask.CareFrequency.daily:
        return 'Daily';
      case dbtask.CareFrequency.twiceDaily:
        return 'Twice daily';
      case dbtask.CareFrequency.weekly:
        return 'Weekly';
      case dbtask.CareFrequency.biweekly:
        return 'Every 2 weeks';
      case dbtask.CareFrequency.monthly:
        return 'Monthly';
      case dbtask.CareFrequency.asNeeded:
        return 'As needed';
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
                CareTaskFormSheet.show(
                  ctx,
                  petId: widget.petId,
                  petName: widget.petName,
                  createSeed: task,
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
                CareTaskFormSheet.show(
                  ctx,
                  petId: widget.petId,
                  petName: widget.petName,
                  existing: task,
                );
              }
            : null,
        onDelete: !logOnly
            ? () async {
                Navigator.pop(ctx);
                await _confirmDialog(
                  ctx,
                  title: 'Delete task',
                  body:
                      'Remove "${task.title}" from ${widget.petName}\'s care plan?',
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
      CurvedAnimation(
          parent: _xpCtrl, curve: const Cubic(0.2, 0.8, 0.2, 1.0)),
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
              ? [
                  BoxShadow(
                      color: AppColors.poppy.withAlpha(64),
                      blurRadius: 0,
                      spreadRadius: 4)
                ]
              : pt.shadowE1,
        ),
        child: Row(
          children: [
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
                            decoration:
                                done ? TextDecoration.lineThrough : null,
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
                            task.frequency ==
                                    dbtask.CareFrequency.monthly
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
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                          color: done ? AppColors.mint700 : AppColors.sunny700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Text('⭐', style: TextStyle(fontSize: 11)),
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
              done
                  ? Icons.replay_rounded
                  : Icons.check_circle_outline_rounded,
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
// Supporting widgets
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
                    color: pt.line, borderRadius: BorderRadius.circular(2)),
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
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label,
          style: TextStyle(color: c, fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

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
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadowE1L,
                blurRadius: 2,
                offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          children: const [
            SkeletonLoader(width: 40, height: 40, borderRadius: 12),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonLoader(width: 140, height: 14),
                  SizedBox(height: 6),
                  SkeletonLoader(width: 100, height: 11),
                ],
              ),
            ),
            SkeletonLoader(width: 36, height: 36, borderRadius: 999),
          ],
        ),
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
  const _EmptyRoutineState(
      {required this.petName, required this.date, this.onAddTask});

  final String petName;
  final DateTime date;
  final VoidCallback? onAddTask;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final isToday =
        DateUtils.dateOnly(date) == DateUtils.dateOnly(DateTime.now());

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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
