import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/care/data/models/care_task.dart' as dbtask;
import 'package:petfolio/features/care/presentation/controllers/care_dashboard_controller.dart';
import 'package:petfolio/features/care/presentation/utils/care_scheduled_time.dart';

class CareTaskFormSheet extends ConsumerStatefulWidget {
  const CareTaskFormSheet({
    super.key,
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
  ConsumerState<CareTaskFormSheet> createState() => _CareTaskFormSheetState();
}

class _CareTaskFormSheetState extends ConsumerState<CareTaskFormSheet> {
  var _type = dbtask.CareTaskType.feeding;
  var _frequency = dbtask.CareFrequency.daily;
  late TextEditingController _titleCtrl;
  final _titleFocus = FocusNode();
  bool _titleFocused = false;
  bool _userEditedTitle = false;
  TimeOfDay? _time;
  bool _saving = false;
  String? _titleError;

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
    if (title.isEmpty) {
      setState(() => _titleError = 'Please enter a task name');
      _titleFocus.requestFocus();
      return;
    }
    if (_saving) return;
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
                return Semantics(
                  label: _typeLabel(t),
                  selected: selected,
                  button: true,
                  child: GestureDetector(
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
                ),
                );
              },
            ),
            const SizedBox(height: 20),

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
                onChanged: (_) {
                  _userEditedTitle = true;
                  if (_titleError != null) setState(() => _titleError = null);
                },
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 15, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'e.g. Morning feeding',
                  filled: true,
                  fillColor: _titleFocused ? cs.surface : pt.surface2,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  errorText: _titleError,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _titleError != null ? cs.error : pt.line,
                      width: _titleError != null ? 1.5 : 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.error, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.error, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _SheetLabel('How often?', pt),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: dbtask.CareFrequency.values.map((f) {
                  final selected = f == _frequency;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Semantics(
                      label: _freqLabel(f),
                      selected: selected,
                      button: true,
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
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            _SheetLabel('Time (optional)', pt),
            const SizedBox(height: 10),
            Semantics(
              label: _time != null ? 'Time set to ${_time!.format(context)}, tap to change' : 'Set task time',
              button: true,
              child: GestureDetector(
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
                      Semantics(
                        label: 'Clear time',
                        button: true,
                        child: GestureDetector(
                          onTap: () => setState(() => _time = null),
                          child: Icon(Icons.close_rounded, size: 16, color: pt.ink300),
                        ),
                      )
                    else
                      Icon(Icons.chevron_right_rounded, size: 18, color: pt.ink300),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: 28),

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
