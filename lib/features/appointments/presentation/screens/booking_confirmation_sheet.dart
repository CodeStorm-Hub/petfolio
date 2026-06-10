import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../controllers/vet_booking_controller.dart';

class BookingConfirmationSheet extends ConsumerStatefulWidget {
  const BookingConfirmationSheet({super.key});

  @override
  ConsumerState<BookingConfirmationSheet> createState() =>
      _BookingConfirmationSheetState();
}

class _BookingConfirmationSheetState
    extends ConsumerState<BookingConfirmationSheet> {
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-select the active pet so the user rarely has to change it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final activePetId = ref.read(activePetIdProvider);
      if (activePetId != null) {
        ref.read(vetBookingControllerProvider.notifier).selectPet(activePetId);
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookingState = ref.watch(vetBookingControllerProvider);
    final petsAsync = ref.watch(petListProvider);

    // Listen for success/error transitions.
    ref.listen<VetBookingState>(vetBookingControllerProvider, (prev, next) {
      if (!mounted) return;
      if (next.status == VetBookingStatus.success) {
        Navigator.of(context).pop();
        AppSnackBar.showSuccess('Appointment booked! 🎉');
        ref.read(vetBookingControllerProvider.notifier).resetStatus();
      } else if (next.status == VetBookingStatus.error &&
          prev?.status != VetBookingStatus.error) {
        AppSnackBar.showError(next.errorMessage ?? 'Booking failed. Please try again.');
        ref.read(vetBookingControllerProvider.notifier).resetStatus();
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: isDark ? pt.surface1 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ─────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: pt.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          Text(
            'Confirm Booking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: pt.ink950,
            ),
          ),
          const SizedBox(height: 16),

          // ── Booking summary ──────────────────────────────────────────────
          _BookingSummary(state: bookingState, pt: pt, isDark: isDark),
          const SizedBox(height: 20),

          // ── Pet picker ───────────────────────────────────────────────────
          Text(
            'For which pet?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: pt.ink500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          petsAsync.when(
            loading: () => const SizedBox(
              height: 72,
              child: Center(child: TailWagLoader()),
            ),
            error: (_, _) => Text(
              'Could not load pets.',
              style: TextStyle(fontSize: 13, color: pt.ink500),
            ),
            data: (pets) => _PetPicker(
              pets: pets,
              selectedPetId: bookingState.petId,
              onSelect: (id) => ref
                  .read(vetBookingControllerProvider.notifier)
                  .selectPet(id),
              pt: pt,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),

          // ── Notes ────────────────────────────────────────────────────────
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            onChanged: (v) =>
                ref.read(vetBookingControllerProvider.notifier).setNotes(v),
            decoration: InputDecoration(
              hintText: 'Any notes for the vet? (optional)',
              hintStyle: TextStyle(color: pt.ink300, fontSize: 13),
              filled: true,
              fillColor: pt.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // ── Confirm button ────────────────────────────────────────────────
          PrimaryPillButton(
            label: 'Confirm Booking',
            isFullWidth: true,
            isLoading: bookingState.isLoading,
            color: AppColors.sky,
            onPressed: bookingState.canBook && !bookingState.isLoading
                ? () {
                    HapticFeedback.mediumImpact();
                    ref.read(vetBookingControllerProvider.notifier).book();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Booking summary card ─────────────────────────────────────────────────────

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.state,
    required this.pt,
    required this.isDark,
  });

  final VetBookingState state;
  final PetfolioThemeExtension pt;
  final bool isDark;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatSlot(DateTime dt) {
    final day = _days[dt.weekday - 1];
    final month = _months[dt.month - 1];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day, $month ${dt.day} at $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.sky.withAlpha(20)
            : AppColors.sky.withAlpha(12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sky.withAlpha(60)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Row(
            icon: Icons.local_hospital_rounded,
            label: state.clinic?.name ?? '—',
            pt: pt,
          ),
          const SizedBox(height: 10),
          _Row(
            icon: Icons.medical_services_rounded,
            label: state.service?.name ?? '—',
            sublabel: state.service != null
                ? '${state.service!.formattedDuration}  ·  ${state.service!.formattedPrice}'
                : null,
            pt: pt,
          ),
          const SizedBox(height: 10),
          _Row(
            icon: Icons.schedule_rounded,
            label: state.selectedSlot != null
                ? _formatSlot(state.selectedSlot!)
                : 'No slot selected',
            pt: pt,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.pt, this.sublabel});
  final IconData icon;
  final String label;
  final String? sublabel;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.sky),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: pt.ink950,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(fontSize: 11, color: pt.ink500),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Pet picker ───────────────────────────────────────────────────────────────

class _PetPicker extends StatelessWidget {
  const _PetPicker({
    required this.pets,
    required this.selectedPetId,
    required this.onSelect,
    required this.pt,
    required this.isDark,
  });

  final List pets;
  final String? selectedPetId;
  final ValueChanged<String> onSelect;
  final PetfolioThemeExtension pt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (pets.isEmpty) {
      return Text(
        'No pets found. Add a pet first.',
        style: TextStyle(fontSize: 13, color: pt.ink500),
      );
    }

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final pet = pets[i];
          final isSelected = pet.id == selectedPetId;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(pet.id as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.sky.withAlpha(isDark ? 40 : 18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.sky : pt.line,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PetAvatar(
                    imageUrl: pet.avatarUrl as String?,
                    species: pet.speciesEnum,
                    size: PetAvatarSize.sm,
                    showRing: isSelected,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pet.name as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.sky : pt.ink950,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
