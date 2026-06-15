import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  final _reasonCtrl = TextEditingController();

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
    _reasonCtrl.dispose();
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
      child: SingleChildScrollView(
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
            const SizedBox(height: 20),

            // ── Intake Triage & Urgency ─────────────────────────────────────
            Text(
              'Urgency Level',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: pt.ink500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['Routine', 'Soon', 'Urgent'].map((level) {
                final isSelected = bookingState.urgency == level;
                final Color activeColor;
                if (level == 'Urgent') {
                  activeColor = AppColors.poppy;
                } else if (level == 'Soon') {
                  activeColor = AppColors.tangerine;
                } else {
                  activeColor = AppColors.mint;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        ref
                            .read(vetBookingControllerProvider.notifier)
                            .selectUrgency(level);
                      }
                    },
                    selectedColor: activeColor.withAlpha(isDark ? 50 : 25),
                    backgroundColor: pt.surface2,
                    labelStyle: TextStyle(
                      color: isSelected ? activeColor : pt.ink500,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? activeColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Chief Complaint ─────────────────────────────────────────────
            Text(
              'Chief Complaint / Reason',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: pt.ink500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonCtrl,
              maxLines: 1,
              onChanged: (v) => ref
                  .read(vetBookingControllerProvider.notifier)
                  .selectReason(v),
              decoration: InputDecoration(
                hintText: 'Describe symptoms or reason for visit...',
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ['Vaccination', 'Checkup', 'Limping', 'Fever', 'Injury']
                  .map((chip) => ActionChip(
                        label: Text(chip),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _reasonCtrl.text = chip;
                          ref
                              .read(vetBookingControllerProvider.notifier)
                              .selectReason(chip);
                        },
                        backgroundColor: pt.surface2,
                        labelStyle: TextStyle(
                          color: pt.ink700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide.none,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),

            // ── Media Upload ────────────────────────────────────────────────
            Text(
              'Attach Photo / Video',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: pt.ink500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            if (bookingState.selectedMedia != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: pt.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: pt.line),
                ),
                child: Row(
                  children: [
                    Icon(
                      bookingState.selectedMedia!.name.toLowerCase().endsWith('.mp4') ||
                              bookingState.selectedMedia!.name.toLowerCase().endsWith('.mov')
                          ? Icons.videocam_rounded
                          : Icons.image_rounded,
                      color: AppColors.sky,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bookingState.selectedMedia!.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: pt.ink700,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: pt.ink500,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(vetBookingControllerProvider.notifier)
                            .selectMedia(null);
                      },
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    ref
                        .read(vetBookingControllerProvider.notifier)
                        .selectMedia(picked);
                  }
                },
                icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                label: const Text('Add Photo/Video'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: pt.line),
                  foregroundColor: pt.ink700,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // ── Notes ────────────────────────────────────────────────────────
            Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: pt.ink500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              onChanged: (v) =>
                  ref.read(vetBookingControllerProvider.notifier).setNotes(v),
              decoration: InputDecoration(
                hintText: 'Any other notes for the vet? (optional)',
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
            const SizedBox(height: 24),

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
          if (state.service != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Colors.black12),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED DURATION',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: pt.ink500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.service!.formattedDuration,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: pt.ink950,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL PRICE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: pt.ink500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.service!.formattedPrice,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.sky,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.pt});
  final IconData icon;
  final String label;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.sky),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: pt.ink950,
            ),
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
