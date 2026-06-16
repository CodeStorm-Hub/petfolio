import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/care/data/models/care_task.dart' as dbtask;
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/utils/care_scheduled_time.dart';
import 'package:petfolio/features/care/presentation/widgets/care_task_card.dart';
import 'package:petfolio/features/care/presentation/widgets/care_task_form_sheet.dart';

Color _cfColor(dbtask.CareTaskType t) {
  switch (t) {
    case dbtask.CareTaskType.feeding:
    case dbtask.CareTaskType.training:
      return AppColors.tangerine;
    case dbtask.CareTaskType.medication:
      return AppColors.poppy;
    case dbtask.CareTaskType.walk:
      return AppColors.mint;
    case dbtask.CareTaskType.playtime:
      return AppColors.sunny;
    case dbtask.CareTaskType.dental:
    case dbtask.CareTaskType.grooming:
    case dbtask.CareTaskType.nailTrim:
      return AppColors.lilac;
    case dbtask.CareTaskType.vetVisit:
    case dbtask.CareTaskType.bath:
      return AppColors.sky;
    case dbtask.CareTaskType.other:
      return AppColors.sunny;
  }
}

String _cfEmoji(dbtask.CareTaskType t) {
  switch (t) {
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

String _cfSublabel(dbtask.CareTask task) {
  if (task.isLogDerived) return 'Activity log';
  if (task.scheduledTime != null) {
    final tod = parseCareScheduledTimeOfDay(task.scheduledTime);
    if (tod != null) {
      final h      = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
      final m      = tod.minute.toString().padLeft(2, '0');
      final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
      final label  = '$h:$m $period';
      return (!task.isCompleted && task.isDueToday) ? '● Due $label' : label;
    }
  }
  switch (task.frequency) {
    case dbtask.CareFrequency.once:       return 'Once';
    case dbtask.CareFrequency.daily:      return 'Daily';
    case dbtask.CareFrequency.twiceDaily: return 'Twice daily';
    case dbtask.CareFrequency.weekly:     return 'Weekly';
    case dbtask.CareFrequency.biweekly:   return 'Every 2 wks';
    case dbtask.CareFrequency.monthly:    return 'Monthly';
    case dbtask.CareFrequency.asNeeded:   return 'As needed';
  }
}

class CoverFlowCarousel extends ConsumerStatefulWidget {
  const CoverFlowCarousel({
    super.key,
    required this.tasks,
    required this.petId,
    required this.petName,
    required this.species,
  });

  final List<dbtask.CareTask> tasks;
  final String petId;
  final String petName;
  final PetSpecies species;

  @override
  ConsumerState<CoverFlowCarousel> createState() => _CoverFlowCarouselState();
}

class _CoverFlowCarouselState extends ConsumerState<CoverFlowCarousel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  late List<dbtask.CareTask> _ordered;
  double _page = 0;
  double _dragDelta = 0;
  String? _xpBurstId;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    )..addListener(_onTick);
    _buildOrdered();
    final firstPending = _ordered.indexWhere((t) => !t.isCompleted);
    _page = (firstPending < 0 ? 0 : firstPending).toDouble();
    _anim = AlwaysStoppedAnimation(_page);
  }

  void _onTick() {
    if (mounted) setState(() => _page = _anim.value);
  }

  @override
  void didUpdateWidget(CoverFlowCarousel old) {
    super.didUpdateWidget(old);
    if (old.tasks != widget.tasks) {
      final byId = {for (final t in widget.tasks) t.id: t};
      for (int i = 0; i < _ordered.length; i++) {
        final updated = byId[_ordered[i].id];
        if (updated != null) _ordered[i] = updated;
      }
    }
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _buildOrdered() {
    final done     = widget.tasks.where((t) => t.isCompleted).toList();
    final duePend  = widget.tasks
        .where((t) => !t.isCompleted && t.isDueToday && t.scheduledTime != null)
        .toList()
      ..sort(_timeSort);
    final pend     = widget.tasks
        .where((t) => !t.isCompleted && !(t.isDueToday && t.scheduledTime != null))
        .toList()
      ..sort(_timeSort);
    _ordered = [...done, ...duePend, ...pend];
  }

  int _timeSort(dbtask.CareTask a, dbtask.CareTask b) {
    final at = parseCareScheduledTimeOfDay(a.scheduledTime);
    final bt = parseCareScheduledTimeOfDay(b.scheduledTime);
    if (at != null && bt != null) {
      return (at.hour * 60 + at.minute).compareTo(bt.hour * 60 + bt.minute);
    }
    if (at != null) return -1;
    if (bt != null) return 1;
    return a.title.compareTo(b.title);
  }

  void _goTo(int index) {
    _ctrl.stop();
    final from = _page;
    final to   = index.clamp(0, _ordered.length - 1).toDouble();
    _anim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward(from: 0);
  }

  int get _currentIdx => _page.round().clamp(0, _ordered.length - 1);

  void _onToggle(int index) {
    final task    = _ordered[index];
    final nowDone = !task.isCompleted;
    HapticFeedback.mediumImpact();
    ref.read(careDashboardProvider.notifier)
        .toggleTaskCompletion(task.id, isCompleted: nowDone);
    if (nowDone && task.gamificationPoints > 0) {
      setState(() => _xpBurstId = task.id);
      Future.delayed(const Duration(milliseconds: 1250), () {
        if (mounted) setState(() => _xpBurstId = null);
      });
    }
  }

  void _showContextMenu(BuildContext ctx, dbtask.CareTask task) {
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
                await _cfConfirmDialog(
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
                await _cfConfirmDialog(
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

  Future<void> _cfConfirmDialog(
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
    final total = _ordered.length;
    if (total == 0) return const SizedBox.shrink();

    final entries = _ordered.asMap().entries.toList()
      ..sort((a, b) {
        final ad = (a.key.toDouble() - _page).abs();
        final bd = (b.key.toDouble() - _page).abs();
        return bd.compareTo(ad);
      });

    return Column(
      children: [
        Semantics(
          hint: 'Swipe left or right to browse tasks',
          child: SizedBox(
          height: 242,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (d) => _dragDelta += d.delta.dx,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              final dx = _dragDelta;
              _dragDelta = 0;
              if (v < -100 || dx < -40) _goTo(_currentIdx + 1);
              if (v > 100 || dx > 40)  _goTo(_currentIdx - 1);
            },
            onHorizontalDragCancel: () => _dragDelta = 0,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: entries.map((e) {
                final i    = e.key;
                final task = e.value;
                final offset = i.toDouble() - _page;
                final abs    = offset.abs();
                if (abs > 3.4) return const SizedBox.shrink();

                final sign    = offset > 0 ? 1.0 : (offset < 0 ? -1.0 : 0.0);
                final scale   = (1.0 - abs * 0.15).clamp(0.60, 1.0);
                final opacity = (1.0 - abs * 0.36).clamp(0.20, 1.0);
                final rotY    = sign * (abs * 0.88).clamp(0.0, 1.12);
                final tx      = abs < 0.02
                    ? 0.0
                    : sign * (abs * 78.0).clamp(0.0, 220.0);

                return Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(tx, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(rotY),
                        child: Semantics(
                          label: '${task.title}${task.isCompleted ? ", completed" : ""}',
                          button: abs < 0.35,
                          child: GestureDetector(
                          onTap: abs > 0.35 ? () => _goTo(i) : null,
                          child: _CoverFlowCard(
                            task: task,
                            isCenter: abs < 0.35,
                            xpBurstId: _xpBurstId,
                            onToggle: () => _onToggle(i),
                            onLongPress: () => _showContextMenu(context, task),
                          ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavArrow(
                icon: Icons.chevron_left_rounded,
                onTap: _currentIdx > 0 ? () => _goTo(_currentIdx - 1) : null,
              ),
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 5,
                    children: List.generate(
                      math.min(total, 12),
                      (i) {
                        final sel = i == _currentIdx;
                        final t   = _ordered[i];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          width: sel ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: sel
                                ? Theme.of(context).colorScheme.primary
                                : t.isCompleted
                                    ? AppColors.mint.withAlpha(140)
                                    : Theme.of(context)
                                        .extension<PetfolioThemeExtension>()!
                                        .line,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              _NavArrow(
                icon: Icons.chevron_right_rounded,
                onTap: _currentIdx < total - 1
                    ? () => _goTo(_currentIdx + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoverFlowCard extends StatelessWidget {
  const _CoverFlowCard({
    required this.task,
    required this.isCenter,
    required this.xpBurstId,
    required this.onToggle,
    required this.onLongPress,
  });

  final dbtask.CareTask task;
  final bool isCenter;
  final String? xpBurstId;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final pt    = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs    = Theme.of(context).colorScheme;
    final done  = task.isCompleted;
    final due   = !done && task.isDueToday && task.scheduledTime != null;
    final color = _cfColor(task.taskType);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        GestureDetector(
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            width: 198,
            height: 220,
            decoration: BoxDecoration(
              color: done
                  ? Color.alphaBlend(color.withAlpha(22), cs.surface)
                  : cs.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: done
                    ? color.withAlpha(190)
                    : due
                        ? AppColors.poppy.withAlpha(200)
                        : pt.line,
                width: done || due ? 2.0 : 1.0,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              boxShadow: isCenter
                  ? [
                      BoxShadow(
                        color: color.withAlpha(done ? 50 : 26),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                        spreadRadius: -8,
                      ),
                      ...pt.shadowE1,
                    ]
                  : pt.shadowE2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? color : color.withAlpha(40),
                        boxShadow: done
                            ? [
                                BoxShadow(
                                  color: color.withAlpha(115),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                  spreadRadius: -4,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 230),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: done
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white,
                                size: 30,
                                key: ValueKey('c'))
                            : Text(
                                _cfEmoji(task.taskType),
                                key: const ValueKey('e'),
                                style: const TextStyle(
                                    fontSize: 30, height: 1.0),
                              ),
                      ),
                    ),
                    if (due)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.poppy,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: done ? pt.ink500 : cs.onSurface,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: pt.ink300,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                  child: Text(
                    task.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _cfSublabel(task),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: due ? AppColors.poppy700 : pt.ink500,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: done ? AppColors.mintSoft : AppColors.sunnySoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: done
                              ? AppColors.mint.withAlpha(80)
                              : AppColors.sunny.withAlpha(80),
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
                              color: done
                                  ? AppColors.mint700
                                  : AppColors.sunny700,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text('⭐',
                              style: TextStyle(fontSize: 10, height: 1)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SpringCheckButton(
                      done: done,
                      color: color,
                      line: pt.line,
                      surface: cs.surface,
                      onTap: onToggle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (xpBurstId == task.id)
          const Positioned(
            top: -22,
            child: _XpBurst(),
          ),
      ],
    );
  }
}

class _XpBurst extends StatefulWidget {
  const _XpBurst();

  @override
  State<_XpBurst> createState() => _XpBurstState();
}

class _XpBurstState extends State<_XpBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y, _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _y = Tween<double>(begin: 0, end: -62).animate(
      CurvedAnimation(parent: _ctrl, curve: const Cubic(0.2, 0.8, 0.2, 1.0)),
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 56),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 32),
    ]).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Opacity(
        opacity: _opacity.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, _y.value),
          child: const Text(
            '+XP ⭐',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.sunny700,
              shadows: [
                Shadow(
                    color: AppColors.sunny,
                    blurRadius: 10,
                    offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final pt     = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final active = onTap != null;
    return Semantics(
      label: icon == Icons.chevron_left_rounded ? 'Previous task' : 'Next task',
      button: true,
      enabled: active,
      child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? cs.primary.withAlpha(22) : Colors.transparent,
          border: Border.all(
            color: active ? cs.primary.withAlpha(65) : pt.line.withAlpha(90),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 22,
          color: active ? cs.primary : pt.ink300,
        ),
      ),
    ),
    );
  }
}

class _SpringCheckButton extends StatefulWidget {
  const _SpringCheckButton({
    required this.done,
    required this.color,
    required this.line,
    required this.surface,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final Color line;
  final Color surface;
  final VoidCallback onTap;

  @override
  State<_SpringCheckButton> createState() => _SpringCheckButtonState();
}

class _SpringCheckButtonState extends State<_SpringCheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 230),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.done ? widget.color : widget.surface,
            border: Border.all(
              color: widget.done ? widget.color : widget.line,
              width: widget.done ? 0 : 2,
            ),
            boxShadow: widget.done
                ? [
                    BoxShadow(
                      color: widget.color.withAlpha(90),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      spreadRadius: -3,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: widget.done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}
