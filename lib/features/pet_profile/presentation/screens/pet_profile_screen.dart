import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../../data/models/pet.dart';
import '../controllers/active_pet_controller.dart';
import '../controllers/pet_list_controller.dart';
import '../widgets/pet_switcher_sheet.dart';

/// The main "Home" tab — shows the active pet header and daily summary.
///
/// All content is keyed on [activePetControllerProvider] so switching pets
/// via the switcher sheet instantly re-renders this screen.
class PetProfileScreen extends ConsumerWidget {
  const PetProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetControllerProvider);
    final petsAsync = ref.watch(petListProvider);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Active pet header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: _ActivePetHeader(
                activePet: activePet,
                onOpenSwitcher: () => PetSwitcherSheet.show(context),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            if (activePet == null)
              // Loading / error / no-pets state
              SliverFillRemaining(
                child: petsAsync.when(
                  skipLoadingOnReload: true,
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 48, color: pt.ink300),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load pets',
                            style: const TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Check your connection and try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: pt.ink500),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () =>
                                ref.invalidate(petListProvider),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (pets) => pets.isEmpty
                      ? _EmptyPetsState(pt: pt)
                      // Pets loaded but ActivePetController is still restoring
                      // the saved selection from SharedPreferences — brief shimmer.
                      : const Center(child: CircularProgressIndicator.adaptive()),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeroCard(pet: activePet),
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Today'),
                    const SizedBox(height: 12),
                    _ReminderCard(
                      icon: Icons.medication_outlined,
                      title: 'Heartworm tablet',
                      subtitle: '9:00 AM · Daily',
                      accentColor: activePet.speciesEnum.accent,
                    ),
                    const SizedBox(height: 10),
                    _ReminderCard(
                      icon: Icons.directions_walk_outlined,
                      title: 'Evening walk with ${activePet.name}',
                      subtitle: '2 / 3 walks today',
                      accentColor: AppColors.meadow500,
                      isPrimary: true,
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'From the feed'),
                    const SizedBox(height: 12),
                    _FeedPlaceholder(pt: pt),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Active pet header ─────────────────────────────────────────────────────────

class _ActivePetHeader extends StatelessWidget {
  const _ActivePetHeader({
    required this.activePet,
    required this.onOpenSwitcher,
  });

  final Pet? activePet;
  final VoidCallback onOpenSwitcher;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      child: Row(
        children: [
          // Pet selector — avatar + name + chevron
          Expanded(
            child: GestureDetector(
              onTap: onOpenSwitcher,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  activePet != null
                      ? PetAvatar(
                          imageUrl: activePet!.avatarUrl,
                          size: PetAvatarSize.lg,
                          initials: activePet!.name.isNotEmpty
                              ? activePet!.name[0]
                              : null,
                          borderColor: activePet!.speciesEnum.accent,
                          semanticLabel: activePet!.name,
                          onTap: onOpenSwitcher,
                        )
                      : SkeletonLoader(
                          width: 48,
                          height: 48,
                          borderRadius: 999,
                        ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active pet',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.08 * 11,
                          color: pt.ink500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          activePet != null
                              ? Text(
                                  activePet!.name,
                                  style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22,
                                    letterSpacing: -0.2,
                                  ),
                                )
                              : SkeletonLoader(width: 100, height: 22),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18, color: pt.ink500),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Outdoor-mode toggle (placeholder — no state yet)
          _HeaderChip(
            child: Icon(Icons.wb_sunny_outlined, size: 18, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 0),

          // Notification bell
          _HeaderChip(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, size: 20, color: cs.onSurfaceVariant),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.coral500,
                      shape: BoxShape.circle,
                      border: Border.all(color: pt.surface1, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowE1L,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(color: pt.line200, blurRadius: 0, spreadRadius: 0.5),
        ],
      ),
      child: Center(child: child),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final accent = pet.speciesEnum.accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.18)!],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(136),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background blob
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33FFFFFF), Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HEALTH STREAK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1 * 12,
                      color: Colors.white.withAlpha(230),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(46),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'on a walk',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.06 * 11,
                        color: Colors.white.withAlpha(220),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '28',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'days on track',
                    style: TextStyle(
                        fontSize: 16, color: Colors.white.withAlpha(230)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Weekly bars
              Row(
                children: List.generate(7, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 6 ? 6 : 0),
                      height: 28,
                      decoration: BoxDecoration(
                        color: i < 6
                            ? Colors.white.withAlpha(217)
                            : Colors.white.withAlpha(64),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Day labels
              Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                  return Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(217),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08 * 12,
        color: pt.ink500,
      ),
    );
  }
}

// ── Reminder card ─────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pt.line200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowE1L,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(34),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: pt.ink500),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isPrimary ? accentColor : pt.surface2,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: accentColor.withAlpha(170),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              isPrimary ? 'Start walk' : 'Mark done',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isPrimary ? Colors.white : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed placeholder ──────────────────────────────────────────────────────────

class _FeedPlaceholder extends StatelessWidget {
  const _FeedPlaceholder({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pt.line200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Color.lerp(AppColors.mulberry500, Colors.white, 0.3)!,
                      AppColors.mulberry500,
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '@parkside_corgi_club',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text('0.4 km · 2 hr ago',
                          style:
                              TextStyle(fontSize: 12, color: pt.ink500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.coral500.withAlpha(30),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Nearby',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.coral500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 160,
            color: pt.surface2,
            child: Center(
              child: Text(
                '[feed photo]',
                style: TextStyle(fontSize: 12, color: pt.ink300),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Sunday meetup at Highbury — 6 corgis confirmed.',
              style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyPetsState extends StatelessWidget {
  const _EmptyPetsState({required this.pt});
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐾', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No pets yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first pet to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: pt.ink500),
            ),
          ],
        ),
      ),
    );
  }
}
