import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/appointment.dart';
import '../../data/models/vet_service.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/vet_repository.dart';
import '../controllers/appointment_controller.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final petId = ref.watch(activePetIdProvider) ?? '';

    final topInset = MediaQuery.paddingOf(context).top + 76.0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: pt.surface1,
        body: Column(
          children: [
            SizedBox(height: topInset),
            const SizedBox(height: 16),
            ColoredBox(
              color: pt.surface1,
              child: TabBar(
                labelColor: AppColors.mint,
                unselectedLabelColor: pt.ink500,
                indicatorColor: AppColors.mint,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  KeepAliveTab(child: _AppointmentsTabList(past: false)),
                  KeepAliveTab(child: _AppointmentsTabList(past: true)),
                ],
              ),
            ),
          ],
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
        initialDate: DateTime.now(),
      ),
    );
  }
}

// ─── List Tab View ────────────────────────────────────────────────────────────

class _AppointmentsTabList extends ConsumerWidget {
  const _AppointmentsTabList({required this.past});
  final bool past;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final appointmentsAsync = ref.watch(past ? pastAppointmentsProvider : upcomingAppointmentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        if (past) {
          await ref.read(pastAppointmentsProvider.notifier).refresh();
        } else {
          await ref.read(upcomingAppointmentsProvider.notifier).refresh();
        }
      },
      child: appointmentsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => const SkeletonLoader(width: double.infinity, height: 80),
        ),
        error: (err, _) => Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Could not load appointments: $err',
                  style: TextStyle(color: pt.ink500),
                ),
              ),
            ),
          ),
        ),
        data: (appointments) {
          if (appointments.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                PetfolioEmptyState(
                  icon: Icons.event_available_rounded,
                  title: past ? 'No past appointments' : 'No upcoming appointments',
                  subtitle: past
                      ? 'Your completed or cancelled visits will show up here.'
                      : 'Tap + to book a new appointment.',
                ),
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            physics: const AlwaysScrollableScrollPhysics(),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final appt = appointments[i];
              return AppointmentCardWidget(appointment: appt);
            },
          );
        },
      ),
    );
  }
}

// ─── Reusable Appointment Card ───────────────────────────────────────────────

class AppointmentCardWidget extends ConsumerWidget {
  const AppointmentCardWidget({super.key, required this.appointment});
  final Appointment appointment;

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final month = months[local.month - 1];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, ${local.year} at $h:$m $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color badgeBg;
    final Color badgeText;
    switch (appointment.status) {
      case 'confirmed':
        badgeBg = AppColors.mint.withAlpha(isDark ? 50 : 25);
        badgeText = AppColors.mint;
        break;
      case 'cancelled':
        badgeBg = AppColors.poppy.withAlpha(isDark ? 50 : 25);
        badgeText = AppColors.poppy;
        break;
      case 'completed':
        badgeBg = pt.ink300.withAlpha(50);
        badgeText = pt.ink700;
        break;
      case 'pending':
      default:
        badgeBg = AppColors.tangerine.withAlpha(isDark ? 50 : 25);
        badgeText = AppColors.tangerine;
        break;
    }

    return GlassCard(
      child: InkWell(
        onTap: appointment.status == 'cancelled' || appointment.status == 'completed'
            ? null
            : () => _showActionsBottomSheet(context, ref, appointment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      appointment.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: pt.ink950,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appointment.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (appointment.clinicName != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.local_hospital_rounded, size: 14, color: pt.ink500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appointment.clinicName!,
                        style: TextStyle(fontSize: 13, color: pt.ink700, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: pt.ink500),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(appointment.scheduledAt),
                    style: TextStyle(fontSize: 12, color: pt.ink500, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: pt.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Reason: ${appointment.reason}',
                    style: TextStyle(fontSize: 11, color: pt.ink700, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showActionsBottomSheet(BuildContext context, WidgetRef ref, Appointment appt) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: pt.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Appointment Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: pt.ink950,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded, color: AppColors.sky),
                title: const Text('Reschedule Appointment', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Change the date and time of this appointment'),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  _rescheduleFlow(context, ref, appt);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: AppColors.poppy),
                title: const Text('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Cancel this appointment (24h notice recommended)'),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  _cancelFlow(context, ref, appt);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.event_note_rounded, color: AppColors.mint),
                title: const Text('Add to Calendar', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Add a reminder to your device calendar'),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  _addToCalendar(appt);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Reschedule Flow ────────────────────────────────────────────────────────

  Future<void> _rescheduleFlow(BuildContext context, WidgetRef ref, Appointment appt) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: appt.scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !context.mounted) return;

    if (appt.clinicId != null && appt.serviceId != null) {
      _showTimeSlotPickerSheet(context, ref, appt, pickedDate);
    } else {
      _rescheduleWithStandardTimePicker(context, ref, appt, pickedDate);
    }
  }

  void _showTimeSlotPickerSheet(BuildContext context, WidgetRef ref, Appointment appt, DateTime date) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (slotCtx) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(slotCtx).bottom + 24),
          child: FutureBuilder<List<DateTime>>(
            future: _fetchSlotsForReschedule(ref, appt, date),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: TailWagLoader()),
                );
               }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(
                  height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No available slots for this date.',
                        style: TextStyle(color: pt.ink500),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(slotCtx).pop();
                          _rescheduleWithStandardTimePicker(context, ref, appt, date);
                        },
                        child: const Text('Pick Standard Time'),
                      ),
                    ],
                  ),
                );
              }

              final slots = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: pt.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Time Slot',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: pt.ink950,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (ctx, index) {
                        final slot = slots[index];
                        final formattedTime = _formatTimeOnly(slot);
                        return InkWell(
                          onTap: () async {
                            Navigator.of(slotCtx).pop();
                            await _rescheduleAction(context, ref, appt, date, formattedTime);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.sky.withAlpha(20),
                              border: Border.all(color: AppColors.sky),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              formattedTime,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sky,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatTimeOnly(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Future<List<DateTime>> _fetchSlotsForReschedule(WidgetRef ref, Appointment appt, DateTime date) async {
    if (appt.clinicId == null || appt.serviceId == null) {
      return [];
    }
    try {
      final serviceRow = await Supabase.instance.client
          .from('vet_services')
          .select()
          .eq('id', appt.serviceId!)
          .single();
      final service = VetService.fromJson(Map<String, dynamic>.from(serviceRow as Map));

      return await ref.read(vetRepositoryProvider).fetchAvailableSlots(
        clinicId: appt.clinicId!,
        service: service,
        date: date,
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> _rescheduleWithStandardTimePicker(
    BuildContext context,
    WidgetRef ref,
    Appointment appt,
    DateTime date,
  ) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appt.scheduledAt),
    );
    if (pickedTime != null && context.mounted) {
      final timeSlot = '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      await _rescheduleAction(context, ref, appt, date, timeSlot);
    }
  }

  Future<void> _rescheduleAction(
    BuildContext context,
    WidgetRef ref,
    Appointment appt,
    DateTime date,
    String timeSlot,
  ) async {
    try {
      await ref.read(appointmentRepositoryProvider).rescheduleAppointment(appt.id, date, timeSlot);
      if (context.mounted) {
        AppSnackBar.showSuccess('Appointment rescheduled! 🎉');
      }
      ref.invalidate(upcomingAppointmentsProvider);
      ref.invalidate(pastAppointmentsProvider);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError('Could not reschedule: $e');
      }
    }
  }

  // ─── Cancel Flow ────────────────────────────────────────────────────────────

  Future<void> _cancelFlow(BuildContext context, WidgetRef ref, Appointment appt) async {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: pt.surface1,
          title: Text(
            'Cancel Appointment?',
            style: TextStyle(fontWeight: FontWeight.w700, color: pt.ink950),
          ),
          content: Text(
            'Are you sure you want to cancel this appointment?\n\n'
            'Cancellation policy: Please provide at least 24 hours notice if you need to cancel or reschedule.',
            style: TextStyle(color: pt.ink700),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Keep It', style: TextStyle(color: pt.ink500)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                try {
                  await ref.read(appointmentRepositoryProvider).updateAppointmentStatus(appt.id, 'cancelled');
                  if (context.mounted) {
                    AppSnackBar.showSuccess('Appointment cancelled.');
                  }
                  ref.invalidate(upcomingAppointmentsProvider);
                  ref.invalidate(pastAppointmentsProvider);
                } catch (e) {
                  if (context.mounted) {
                    AppSnackBar.showError('Could not cancel: $e');
                  }
                }
              },
              child: const Text(
                'Cancel Appointment',
                style: TextStyle(color: AppColors.poppy, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Calendar Flow ──────────────────────────────────────────────────────────

  void _addToCalendar(Appointment appt) {
    try {
      final Event event = Event(
        title: appt.title,
        description: appt.notes ?? 'Vet booking appointment.',
        location: appt.clinicName ?? '',
        startDate: appt.scheduledAt,
        endDate: appt.scheduledAt.add(const Duration(minutes: 30)),
      );
      Add2Calendar.addEvent2Cal(event);
    } catch (e) {
      AppSnackBar.showError('Could not add to calendar: $e');
    }
  }
}

// ─── Add Appointment Sheet (Legacy/FAB) ───────────────────────────────────────

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
        status: 'pending',
      );
      await ref.read(appointmentControllerProvider.notifier).add(appt);
      ref.invalidate(upcomingAppointmentsProvider);
      ref.invalidate(pastAppointmentsProvider);
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
      child: SingleChildScrollView(
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
                fontWeight: FontWeight.w700,
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
