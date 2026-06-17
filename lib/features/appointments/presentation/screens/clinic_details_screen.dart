import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/vet_clinic.dart';
import '../../data/models/vet_service.dart';
import '../controllers/available_slots_provider.dart';
import '../controllers/clinic_list_provider.dart';
import '../controllers/vet_booking_controller.dart';
import 'booking_confirmation_sheet.dart';

class ClinicDetailsScreen extends ConsumerStatefulWidget {
  const ClinicDetailsScreen({super.key, required this.clinic});

  final VetClinic clinic;

  @override
  ConsumerState<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends ConsumerState<ClinicDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(vetBookingControllerProvider.notifier).initForClinic(widget.clinic);
      }
    });
  }

  void _openConfirmationSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BookingConfirmationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingState = ref.watch(vetBookingControllerProvider);
    final servicesAsync = ref.watch(clinicServicesProvider(widget.clinic.id));

    return Scaffold(
      backgroundColor: pt.surface1,
      appBar: AppBar(
        backgroundColor: pt.surface1,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: pt.ink950),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VETS', style: TextStyle(fontSize: 10, color: pt.ink500, letterSpacing: 1)),
            Text(
              widget.clinic.name,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: pt.ink950),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      // Sticky book button shown only when a slot is selected
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: bookingState.selectedSlot != null
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: PrimaryPillButton(
                    label: 'Book Now  →',
                    isFullWidth: true,
                    color: AppColors.sky,
                    onPressed: _openConfirmationSheet,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Clinic hero card ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ClinicHeroCard(clinic: widget.clinic, isDark: isDark, pt: pt),
          ),

          // ── Services ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(pt: pt, label: 'Services'),
          ),
          SliverToBoxAdapter(
            child: servicesAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: const SkeletonLoader(width: double.infinity, height: 72, borderRadius: 16),
                    ),
                  ),
                ),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load services.',
                    style: TextStyle(color: pt.ink500)),
              ),
              data: (services) => _ServiceList(
                services: services,
                selected: bookingState.service,
                onSelect: (s) => ref
                    .read(vetBookingControllerProvider.notifier)
                    .selectService(s),
                pt: pt,
                isDark: isDark,
              ),
            ),
          ),

          // ── Date picker (visible after service selection) ──────────────────
          if (bookingState.service != null) ...[
            SliverToBoxAdapter(
              child: _SectionLabel(pt: pt, label: 'Select Date'),
            ),
            SliverToBoxAdapter(
              child: _DateStrip(
                selectedDate: bookingState.selectedDate,
                onDateSelected: (d) => ref
                    .read(vetBookingControllerProvider.notifier)
                    .selectDate(d),
              ),
            ),
          ],

          // ── Time slots (visible after date selection) ──────────────────────
          if (bookingState.service != null && bookingState.selectedDate != null) ...[
            SliverToBoxAdapter(
              child: _SectionLabel(pt: pt, label: 'Available Times'),
            ),
            SliverToBoxAdapter(
              child: _TimeSlotsGrid(
                clinicId: widget.clinic.id,
                service: bookingState.service!,
                date: bookingState.selectedDate!,
                selectedSlot: bookingState.selectedSlot,
                onSlotSelected: (slot) => ref
                    .read(vetBookingControllerProvider.notifier)
                    .selectSlot(slot),
                pt: pt,
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// ─── Clinic hero card ─────────────────────────────────────────────────────────

class _ClinicHeroCard extends StatelessWidget {
  const _ClinicHeroCard({
    required this.clinic,
    required this.isDark,
    required this.pt,
  });

  final VetClinic clinic;
  final bool isDark;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.sky, AppColors.mint],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.sky.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinic.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  if (clinic.tagline != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      clinic.tagline!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${clinic.address}, ${clinic.city}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (clinic.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          clinic.phone!,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (clinic.avatarUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: clinic.avatarUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.white24,
                        alignment: Alignment.center,
                        child: const Text('🏥', style: TextStyle(fontSize: 28)),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.white24,
                        alignment: Alignment.center,
                        child: const Text('🏥', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🏥', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      clinic.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${clinic.reviewCount} reviews',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.pt, required this.label});
  final PetfolioThemeExtension pt;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: pt.ink500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Service list ─────────────────────────────────────────────────────────────

class _ServiceList extends StatelessWidget {
  const _ServiceList({
    required this.services,
    required this.selected,
    required this.onSelect,
    required this.pt,
    required this.isDark,
  });

  final List<VetService> services;
  final VetService? selected;
  final ValueChanged<VetService> onSelect;
  final PetfolioThemeExtension pt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: services
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServiceTile(
                    service: s,
                    isSelected: selected?.id == s.id,
                    onTap: () => onSelect(s),
                    pt: pt,
                    isDark: isDark,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.isSelected,
    required this.onTap,
    required this.pt,
    required this.isDark,
  });

  final VetService service;
  final bool isSelected;
  final VoidCallback onTap;
  final PetfolioThemeExtension pt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${service.name}, ${service.formattedPrice}',
      selected: isSelected,
      button: true,
      child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sky.withAlpha(isDark ? 45 : 22)
              : (isDark ? pt.surface2 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.sky : pt.line,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? null : pt.shadowE1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.sky.withAlpha(30)
                    : AppColors.sky.withAlpha(15),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.medical_services_rounded,
                color: AppColors.sky,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: pt.ink950,
                    ),
                  ),
                  if (service.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      service.description!,
                      style: TextStyle(fontSize: 11, color: pt.ink500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  service.formattedPrice,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.sky : pt.ink950,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.formattedDuration,
                  style: TextStyle(fontSize: 11, color: pt.ink300),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.sky,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

// ─── Date strip ───────────────────────────────────────────────────────────────

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selectedDate, required this.onDateSelected});

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final today = DateTime.now();
    final dates = List.generate(14, (i) => DateTime(today.year, today.month, today.day + i));

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = dates[i];
          final isSelected = selectedDate != null &&
              d.year == selectedDate!.year &&
              d.month == selectedDate!.month &&
              d.day == selectedDate!.day;
          final isToday = i == 0;

          return Semantics(
            label: isToday ? 'Today, ${d.day} ${_months[d.month - 1]}' : '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}',
            selected: isSelected,
            button: true,
            child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onDateSelected(d);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.sky : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.sky : pt.line,
                  width: isSelected ? 0 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'Today' : _days[d.weekday - 1],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white70 : pt.ink300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : pt.ink950,
                    ),
                  ),
                  Text(
                    _months[d.month - 1],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : pt.ink300,
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}

// ─── Time slots grid ──────────────────────────────────────────────────────────

class _TimeSlotsGrid extends ConsumerWidget {
  const _TimeSlotsGrid({
    required this.clinicId,
    required this.service,
    required this.date,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.pt,
  });

  final String clinicId;
  final VetService service;
  final DateTime date;
  final DateTime? selectedSlot;
  final ValueChanged<DateTime> onSlotSelected;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(
      availableSlotsProvider(
        AvailableSlotsRequest(clinicId: clinicId, service: service, date: date),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: slotsAsync.when(
        loading: () => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            8,
            (_) => const SkeletonLoader(width: 76, height: 36, borderRadius: 10),
          ),
        ),
        error: (_, _) => Text(
          'Could not load available slots.',
          style: TextStyle(fontSize: 13, color: pt.ink500),
        ),
        data: (slots) => slots.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No available slots for this day.',
                  style: TextStyle(fontSize: 13, color: pt.ink500),
                ),
              )
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((slot) {
                  final isSelected = selectedSlot != null &&
                      slot.hour == selectedSlot!.hour &&
                      slot.minute == selectedSlot!.minute;
                  return Semantics(
                    label: _formatSlot(slot),
                    selected: isSelected,
                    button: true,
                    child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSlotSelected(slot);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.sky : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.sky : pt.line,
                          width: isSelected ? 0 : 1,
                        ),
                      ),
                      child: Text(
                        _formatSlot(slot),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : pt.ink950,
                        ),
                      ),
                    ),
                  ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  String _formatSlot(DateTime slot) {
    final h = slot.hour % 12 == 0 ? 12 : slot.hour % 12;
    final m = slot.minute.toString().padLeft(2, '0');
    return '$h:$m ${slot.hour >= 12 ? 'PM' : 'AM'}';
  }
}
