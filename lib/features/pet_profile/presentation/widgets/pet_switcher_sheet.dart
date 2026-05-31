import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';
import 'package:petfolio/features/auth/presentation/controllers/auth_controller.dart';

import '../../data/models/pet.dart';
import '../controllers/active_pet_controller.dart';
import '../controllers/pet_list_controller.dart';

/// Shows the pet switcher as a drag-to-dismiss modal bottom sheet.
///
/// Call this from any screen that shows the active pet header:
/// ```dart
/// PetSwitcherSheet.show(context);
/// ```
class PetSwitcherSheet extends ConsumerWidget {
  const PetSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        barrierColor: const Color(0x6B0B1220),
        useSafeArea: true,
        builder: (_) => const PetSwitcherSheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petListProvider);
    final activePet = ref.watch(activePetControllerProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.72, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(PetfolioThemeExtension.radius2xl),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowE4L,
                blurRadius: 60,
                offset: const Offset(0, -20),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: pt.ink300.withAlpha(80),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),

              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your pets',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.22,
                            ),
                          ),
                          petsAsync.when(
                            data: (pets) => Text(
                              '${pets.length} pet${pets.length == 1 ? '' : 's'} · tap to switch',
                              style: TextStyle(
                                  fontSize: 13, color: pt.ink500),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: pt.surface2,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable pet list ───────────────────────────────────
              Expanded(
                child: petsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                  error: (e, st) {
                    debugPrint('Pet switcher sheet load failure: $e\n$st');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Could not load pets',
                              style: TextStyle(color: pt.ink500)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref.invalidate(petListProvider),
                            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                  },
                  data: (pets) => ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    children: [
                      // Active pet — pinned at top
                      if (activePet != null)
                        _PetRow(
                          pet: activePet,
                          isActive: true,
                          onTap: () => Navigator.of(context).pop(),
                        ),

                      // Section label
                      if (pets.any((p) => p.id != activePet?.id)) ...[
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(8, 16, 8, 8),
                          child: Text(
                            'SWITCH TO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.08 * 11,
                              color: pt.ink500,
                            ),
                          ),
                        ),
                        // Other pets
                        for (final pet in pets.where(
                            (p) => p.id != activePet?.id))
                          _PetRow(
                            pet: pet,
                            isActive: false,
                            onTap: () async {
                              await ref
                                  .read(activePetControllerProvider.notifier)
                                  .setActivePet(pet);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                      ],

                      // Add another pet
                      const SizedBox(height: 8),
                      _AddPetButton(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/onboarding?mode=add');
                        },
                      ),

                      // Manage row
                      const SizedBox(height: 14),
                      _ManageRow(
                        pt: pt,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/pets/manage');
                        },
                      ),
                      const SizedBox(height: 10),
                      _SignOutRow(pt: pt),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Pet row ───────────────────────────────────────────────────────────────────

class _PetRow extends StatelessWidget {
  const _PetRow({
    required this.pet,
    required this.isActive,
    required this.onTap,
  });

  final Pet pet;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final species = pet.speciesEnum;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: PetfolioThemeExtension.durationSm,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isActive ? species.tint : cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? species.accent : pt.line,
              width: isActive ? 2 : 0.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: species.accent.withAlpha(70),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              PetAvatar(
                imageUrl: pet.avatarUrl,
                size: PetAvatarSize.xl,
                initials: pet.name.isNotEmpty ? pet.name[0] : null,
                borderColor: isActive ? species.accent : null,
                semanticLabel: pet.name,
              ),
              const SizedBox(width: 14),

              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: species.accent.withAlpha(85),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.08 * 10,
                                color: species.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (pet.breed != null)
                      Text(
                        pet.breed!,
                        style: TextStyle(fontSize: 13, color: pt.ink500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Trailing indicator
              if (isActive)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: species.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                )
              else
                Icon(Icons.chevron_right, color: pt.ink300, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add pet button ─────────────────────────────────────────────────────────

class _AddPetButton extends StatelessWidget {
  const _AddPetButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      key: const ValueKey<String>('pet_switcher_add_pet'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedRoundedBorderPainter(
          color: AppColors.blue400,
          radius: 18,
          strokeWidth: 1.5,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.blue50,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add another pet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Name, breed, photo — 30 seconds',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: pt.ink500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Manage row ────────────────────────────────────────────────────────────────

class _ManageRow extends StatelessWidget {
  const _ManageRow({required this.pt, required this.onTap});
  final PetfolioThemeExtension pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      key: const ValueKey<String>('pet_switcher_manage'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: pt.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.settings_outlined, size: 18, color: pt.ink500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Reorder, share access, archive a pet',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
            Text(
              'Manage',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: pt.ink300),
          ],
        ),
      ),
    );
  }
}

// ── Sign-out row ──────────────────────────────────────────────────────────────

class _SignOutRow extends ConsumerWidget {
  const _SignOutRow({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      key: const ValueKey<String>('pet_switcher_sign_out'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _confirmSignOut(context, ref),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.coral500.withAlpha(14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.logout_rounded, size: 18, color: AppColors.coral500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sign out',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.coral500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral500,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop();
      await ref.read(authRepositoryProvider).signOut();
    }
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
  });
  final Color color;
  final double radius;
  final double strokeWidth;
  static const double _dashLength = 8;
  static const double _gapLength = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final half = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(half, half, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = (start + _dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
