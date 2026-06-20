import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/chat_conversation_controller.dart';
import '../../data/repositories/matching_repository.dart';

class PlaydateSchedulerSheet extends ConsumerStatefulWidget {
  const PlaydateSchedulerSheet({
    super.key,
    required this.args,
    required this.matchId,
    required this.actorPetId,
    required this.otherPetName,
  });

  final ChatConversationArgs args;
  final String matchId;
  final String actorPetId;
  final String otherPetName;

  static Future<void> show(
    BuildContext context, {
    required ChatConversationArgs args,
    required String matchId,
    required String actorPetId,
    required String otherPetName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlaydateSchedulerSheet(
        args: args,
        matchId: matchId,
        actorPetId: actorPetId,
        otherPetName: otherPetName,
      ),
    );
  }

  @override
  ConsumerState<PlaydateSchedulerSheet> createState() =>
      _PlaydateSchedulerSheetState();
}

class _PlaydateSchedulerSheetState
    extends ConsumerState<PlaydateSchedulerSheet> {
  final _location = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _saving = false;

  static const _suggestedPlaces = [
    'Dhanmondi Lake park',
    'Gulshan Lake Park',
    'Banani Park',
    'A pet-friendly café',
  ];

  @override
  void dispose() {
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 16, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  DateTime? get _scheduledAt {
    if (_date == null || _time == null) return null;
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
  }

  Future<void> _submit() async {
    final when = _scheduledAt;
    if (when == null) {
      AppSnackBar.showInfo('Pick a date and time first');
      return;
    }
    setState(() => _saving = true);
    final location = _location.text.trim();
    try {
      await ref.read(matchingRepositoryProvider).proposePlaydate(
            matchId: widget.matchId,
            proposedByPetId: widget.actorPetId,
            scheduledAt: when,
            locationName: location.isEmpty ? null : location,
          );
      final whenLabel = _formatWhen(when);
      final placePart = location.isEmpty ? '' : ' at $location';
      await ref
          .read(chatConversationControllerProvider(widget.args).notifier)
          .send('📅 Playdate proposed for $whenLabel$placePart');
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.showSuccess('Playdate proposed');
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plan a playdate', style: tt.titleLarge),
          const SizedBox(height: 4),
          Text(
            'with ${widget.otherPetName}',
            style: tt.bodyMedium?.copyWith(color: pt.ink500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(_date == null
                      ? 'Pick date'
                      : '${_date!.day}/${_date!.month}/${_date!.year}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule_outlined, size: 18),
                  label: Text(_time == null
                      ? 'Pick time'
                      : _time!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final place in _suggestedPlaces)
                ActionChip(
                  label: Text(place),
                  onPressed: () => setState(() => _location.text = place),
                ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryPillButton(
            label: 'Propose playdate',
            isFullWidth: true,
            isLoading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }

  String _formatWhen(DateTime when) {
    final h = when.hour % 12 == 0 ? 12 : when.hour % 12;
    final m = when.minute.toString().padLeft(2, '0');
    final ampm = when.hour < 12 ? 'AM' : 'PM';
    return '${when.day}/${when.month}/${when.year} at $h:$m $ampm';
  }
}
