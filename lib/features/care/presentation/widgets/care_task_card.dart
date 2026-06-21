import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/care/data/models/care_task.dart' as dbtask;
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/utils/care_scheduled_time.dart';
import 'package:petfolio/features/care/presentation/widgets/care_task_form_sheet.dart';

class CareTaskCard extends ConsumerStatefulWidget {
  const CareTaskCard({
    super.key,
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
  ConsumerState<CareTaskCard> createState() => _CareTaskCardState();
}

class _CareTaskCardState extends ConsumerState<CareTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _xpCtrl;
  late Animation<double> _yAnim;
  late Animation<double> _opacityAnim;
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
    _yAnim = Tween<double>(begin: 0.0, end: -72.0).animate(
      CurvedAnimation(parent: _xpCtrl, curve: const Cubic(0.2, 0.8, 0.2, 1.0)),
    );
    _opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_xpCtrl);
  }

  @override
  void dispose() {
    _xpCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    final nowDone = !widget.task.isCompleted;
    HapticFeedback.mediumImpact();
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
      builder: (_) => CareTaskContextMenu(
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
                  builder: (_) => CareTaskFormSheet(
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
                  builder: (_) => CareTaskFormSheet(
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
    final pt   = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs   = Theme.of(context).colorScheme;
    final task = widget.task;
    final done = task.isCompleted;
    final due  = !done && task.isDueToday && task.scheduledTime != null;
    final color = _color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lilacSoft = isDark ? AppColors.lilacSoftD : AppColors.lilacSoft;
    final lilac700 = isDark ? AppColors.lilac700D : AppColors.lilac700;
    final poppy700 = isDark ? AppColors.poppy700D : AppColors.poppy700;
    final mintSoft = isDark ? AppColors.mintSoftD : AppColors.mintSoft;
    final sunnySoft = isDark ? AppColors.sunnySoftD : AppColors.sunnySoft;
    final mint700 = isDark ? AppColors.mint700D : AppColors.mint700;
    final sunny700 = isDark ? AppColors.sunny700D : AppColors.sunny700;

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: done
                ? Color.alphaBlend(color.withAlpha(28), cs.surface)
                : cs.surface,
            borderRadius: BorderRadius.circular(16),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
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
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                            spreadRadius: -3,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    key: ValueKey(done),
                    done ? '✅' : _emoji,
                    style: const TextStyle(fontSize: 18, height: 1.0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                              fontSize: 13,
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
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: lilacSoft,
                              borderRadius: const BorderRadius.all(Radius.circular(999)),
                            ),
                            child: Text(
                              _frequencyPill(task.frequency),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: lilac700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (due)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.poppy,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            _sublabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: due ? poppy700 : pt.ink500,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: done ? mintSoft : sunnySoft,
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
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: done ? mint700 : sunny700,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Text('⭐', style: TextStyle(fontSize: 10, height: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: done ? 'Mark ${task.title} incomplete' : 'Mark ${task.title} complete',
                    button: true,
                    child: GestureDetector(
                    key: ValueKey('care_task_check_${task.id}'),
                    onTap: _toggle,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done ? color : cs.surface,
                            border: Border.all(
                              color: done ? color : pt.line,
                              width: done ? 0 : 2,
                            ),
                            boxShadow: done
                                ? [
                                    BoxShadow(
                                      color: color.withAlpha(80),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                      spreadRadius: -2,
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ],
          ),
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
            bottom: 38,
            child: AnimatedBuilder(
              animation: _xpCtrl,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _yAnim.value),
                child: Opacity(
                  opacity: _opacityAnim.value.clamp(0.0, 1.0),
                  child: Text(
                    '+${task.gamificationPoints} XP ⭐',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.only(bottom: 8),
        child: Dismissible(
          key: ValueKey('d_${task.id}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            decoration: BoxDecoration(
              color: done ? pt.surface2 : AppColors.success,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 18),
            child: Icon(
              done ? Icons.replay_rounded : Icons.check_circle_outline_rounded,
              color: done ? pt.ink300 : Colors.white,
              size: 24,
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

    return Padding(padding: const EdgeInsets.only(bottom: 8), child: card);
  }
}

class CareTaskContextMenu extends StatelessWidget {
  const CareTaskContextMenu({
    super.key,
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
                  fontWeight: FontWeight.w700,
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

class CareTaskCardSkeleton extends StatelessWidget {
  const CareTaskCardSkeleton({super.key});

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
            BoxShadow(color: AppColors.shadowE1L, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: const Row(
          children: [
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
