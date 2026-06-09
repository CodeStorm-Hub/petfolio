import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/appointment.dart';
import '../controllers/appointment_controller.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final petId = ref.watch(activePetIdProvider) ?? '';
    final appointmentsAsync = ref.watch(appointmentControllerProvider);

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: pt.surface1,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: pt.ink950),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CARE · CALENDAR',
              style: TextStyle(fontSize: 10, color: pt.ink500, letterSpacing: 1),
            ),
            Text(
              'Appointments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: pt.ink950),
            ),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) =>
              const SkeletonLoader(width: double.infinity, height: 72),
        ),
        error: (_, e) => const Center(child: Text('Could not load appointments')),
        data: (appointments) => _Body(
          appointments: appointments,
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          petId: petId,
          onDaySelected: (selected, focused) => setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          }),
        ),
      ),
      floatingActionButton: petId.isEmpty
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey<String>('add_appointment_fab'),
              onPressed: () => _showAddSheet(context, petId),
              backgroundColor: AppColors.mint,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New'),
            ),
    );
  }

  void _showAddSheet(BuildContext context, String petId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _AddAppointmentSheet(
        petId: petId,
        initialDate: _selectedDay ?? DateTime.now(),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({
    required this.appointments,
    required this.focusedDay,
    required this.selectedDay,
    required this.petId,
    required this.onDaySelected,
  });

  final List<Appointment> appointments;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final String petId;
  final void Function(DateTime, DateTime) onDaySelected;

  List<Appointment> _forDay(DateTime day) => appointments
      .where((a) => isSameDay(a.scheduledAt, day))
      .toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final dayAppts = selectedDay != null ? _forDay(selectedDay!) : <Appointment>[];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TableCalendar<Appointment>(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            focusedDay: focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, selectedDay),
            eventLoader: (day) => _forDay(day),
            onDaySelected: onDaySelected,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.mint.withAlpha(60),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppColors.tangerine,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: pt.ink950),
              weekendTextStyle: TextStyle(color: pt.ink500),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: pt.ink950,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: pt.ink500),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: pt.ink500),
              decoration: BoxDecoration(color: pt.surface1),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: pt.ink500, fontSize: 12),
              weekendStyle: TextStyle(color: pt.ink300, fontSize: 12),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (ctx2, day, events) => events.isEmpty
                  ? null
                  : Positioned(
                      bottom: 2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              selectedDay != null
                  ? _headerLabel(selectedDay!)
                  : 'Select a day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: pt.ink500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        if (dayAppts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: PetfolioEmptyState(
                icon: Icons.event_available_rounded,
                title: 'No appointments',
                subtitle: 'Tap + to schedule a vet visit for this day.',
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context2, i) => _AppointmentTile(
                appointment: dayAppts[i],
                petId: petId,
              ),
              childCount: dayAppts.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  String _headerLabel(DateTime day) {
    final now = DateTime.now();
    if (isSameDay(day, now)) return 'TODAY';
    if (isSameDay(day, now.add(const Duration(days: 1)))) return 'TOMORROW';
    const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return '${months[day.month - 1]} ${day.day}, ${day.year}';
  }
}

// ─── Appointment tile ─────────────────────────────────────────────────────────

class _AppointmentTile extends ConsumerWidget {
  const _AppointmentTile({required this.appointment, required this.petId});

  final Appointment appointment;
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final time = _formatTime(appointment.scheduledAt);

    return Dismissible(
      key: ValueKey(appointment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.poppy,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => ref
          .read(appointmentControllerProvider.notifier)
          .remove(appointment.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: GlassCard(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: GestureDetector(
              onTap: () => ref
                  .read(appointmentControllerProvider.notifier)
                  .toggleComplete(appointment.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: appointment.isCompleted
                      ? AppColors.mint
                      : AppColors.mint.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  appointment.isCompleted
                      ? Icons.check_rounded
                      : Icons.medical_services_rounded,
                  color: appointment.isCompleted ? Colors.white : AppColors.mint,
                  size: 18,
                ),
              ),
            ),
            title: Text(
              appointment.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: pt.ink950,
                decoration: appointment.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appointment.vetName != null)
                  Text(
                    appointment.vetName!,
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                  ),
                if (appointment.clinicName != null)
                  Text(
                    appointment.clinicName!,
                    style: TextStyle(fontSize: 12, color: pt.ink500),
                  ),
              ],
            ),
            trailing: Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: pt.ink300,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
}

// ─── Add appointment sheet ────────────────────────────────────────────────────

class _AddAppointmentSheet extends ConsumerStatefulWidget {
  const _AddAppointmentSheet({required this.petId, required this.initialDate});

  final String petId;
  final DateTime initialDate;

  @override
  ConsumerState<_AddAppointmentSheet> createState() =>
      _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends ConsumerState<_AddAppointmentSheet> {
  final _titleCtrl = TextEditingController();
  final _vetCtrl = TextEditingController();
  final _clinicCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _vetCtrl.dispose();
    _clinicCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final scheduled = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final appt = Appointment(
        id: '',
        petId: widget.petId,
        title: _titleCtrl.text.trim(),
        scheduledAt: scheduled,
        isCompleted: false,
        createdAt: DateTime.now(),
        vetName: _vetCtrl.text.trim().isEmpty ? null : _vetCtrl.text.trim(),
        clinicName:
            _clinicCtrl.text.trim().isEmpty ? null : _clinicCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await ref.read(appointmentControllerProvider.notifier).add(appt);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError('Could not save appointment: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: pt.ink300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'New Appointment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: pt.ink950,
            ),
          ),
          const SizedBox(height: 16),
          _Field(controller: _titleCtrl, hint: 'Title (e.g. Annual check-up)', icon: Icons.medical_services_rounded),
          const SizedBox(height: 10),
          _Field(controller: _vetCtrl, hint: 'Vet name (optional)', icon: Icons.person_rounded),
          const SizedBox(height: 10),
          _Field(controller: _clinicCtrl, hint: 'Clinic (optional)', icon: Icons.local_hospital_rounded),
          const SizedBox(height: 10),
          _Field(controller: _notesCtrl, hint: 'Notes (optional)', icon: Icons.notes_rounded, maxLines: 2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(_dateLabel(_selectedDate)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) setState(() => _selectedTime = picked);
                  },
                  icon: const Icon(Icons.access_time_rounded, size: 16),
                  label: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryPillButton(
            label: 'Save Appointment',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            color: AppColors.mint,
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: pt.ink300),
        filled: true,
        fillColor: pt.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
