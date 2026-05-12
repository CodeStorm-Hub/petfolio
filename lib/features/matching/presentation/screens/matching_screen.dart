import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../data/models/discovery_candidate.dart';
import '../controllers/discovery_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class MatchingScreen extends ConsumerWidget {
  const MatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetControllerProvider);
    if (pet != null) return _DiscoveryView(petId: pet.id);

    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final petsAsync = ref.watch(petListProvider);
    return Scaffold(
      backgroundColor: pt.surface1,
      body: Center(
        child: petsAsync.when(
          skipLoadingOnReload: true,
          loading: () => const CircularProgressIndicator.adaptive(),
          error: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
              const SizedBox(height: 12),
              Text('Connection error',
                  style: TextStyle(fontSize: 15, color: pt.ink500)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(petListProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
          data: (_) => const CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoveryView extends ConsumerWidget {
  const _DiscoveryView({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryControllerProvider(petId));
    final notifier = ref.read(discoveryControllerProvider(petId).notifier);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _DiscoveryHeader(state: state),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _DiscoveryStack(state: state, notifier: notifier),
              ),
            ),
            _ActionDock(state: state, notifier: notifier),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({required this.state});
  final DiscoveryState state;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Location chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: pt.surface2,
              borderRadius:
                  BorderRadius.circular(PetfolioThemeExtension.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: pt.ink500),
                const SizedBox(width: 4),
                Text(
                  'Nearby',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: pt.ink500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text('Playdates', style: tt.headlineMedium),
          const Spacer(),
          // Filter button
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.tune_rounded, color: pt.ink500),
            style: IconButton.styleFrom(
              backgroundColor: pt.surface2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  PetfolioThemeExtension.radiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card stack
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoveryStack extends StatelessWidget {
  const _DiscoveryStack({required this.state, required this.notifier});
  final DiscoveryState state;
  final DiscoveryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    if (state.topCard == null) return const _EmptyDeck();

    // As the top card is dragged, the next card scales up to fill its place.
    final dragProgress =
        (state.dragOffset.dx.abs().clamp(0.0, 90.0)) / 90.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (state.afterCard != null)
          _StackCard(
            candidate: state.afterCard!,
            scale: 0.88,
            offsetY: 24,
          ),
        if (state.nextCard != null)
          _StackCard(
            candidate: state.nextCard!,
            scale: 0.94 + 0.06 * dragProgress,
            offsetY: 12.0 - 12.0 * dragProgress,
          ),
        _SwipeCard(state: state, notifier: notifier),
      ],
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck();

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets_rounded, size: 64, color: pt.ink300),
          const SizedBox(height: 16),
          Text(
            'No more profiles nearby',
            style: tt.titleMedium?.copyWith(color: pt.ink500),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back soon!',
            style: tt.bodySmall?.copyWith(color: pt.ink300),
          ),
        ],
      ),
    );
  }
}

class _StackCard extends StatelessWidget {
  const _StackCard({
    required this.candidate,
    required this.scale,
    required this.offsetY,
  });
  final DiscoveryCandidate candidate;
  final double scale;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: _CardSurface(candidate: candidate),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe card — top of stack, handles gestures and exit animation
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({required this.state, required this.notifier});
  final DiscoveryState state;
  final DiscoveryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final top = state.topCard!;
    return state.isExiting
        ? _buildExitAnimation(top, size)
        : _buildDraggable(context, top, size);
  }

  Widget _buildDraggable(
    BuildContext context,
    DiscoveryCandidate top,
    Size size,
  ) {
    // Rotation: max ±25° clamped
    final angle =
        (state.dragOffset.dx / (size.width * 0.75)).clamp(-0.44, 0.44);

    final matchOpacity = (state.dragOffset.dx / 80).clamp(0.0, 1.0);
    final passOpacity = (-state.dragOffset.dx / 80).clamp(0.0, 1.0);
    final greetOpacity = (-state.dragOffset.dy / 80).clamp(0.0, 1.0);

    return Transform.translate(
      offset: state.dragOffset,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
        onPanUpdate: (d) => notifier.onDragUpdate(d.delta),
        onPanEnd: (_) => notifier.onDragEnd(),
        onPanCancel: notifier.onDragCancel,
        child: Stack(
          children: [
            _CardSurface(
              candidate: top,
              isExpanded: state.isExpanded,
              onToggleExpand: notifier.toggleExpand,
            ),
            if (matchOpacity > 0.05)
              Positioned(
                top: 36,
                left: 20,
                child: Opacity(
                  opacity: matchOpacity,
                  child: _SwipeLabel(
                    label: 'MATCH',
                    color: AppColors.coral500,
                  ),
                ),
              ),
            if (passOpacity > 0.05)
              Positioned(
                top: 36,
                right: 20,
                child: Opacity(
                  opacity: passOpacity,
                  child: _SwipeLabel(
                    label: 'PASS',
                    color: AppColors.ink500,
                  ),
                ),
              ),
            if (greetOpacity > 0.05)
              Positioned(
                top: 36,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: greetOpacity,
                    child: _SwipeLabel(
                      label: 'WAVE  👋',
                      color: AppColors.blue500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildExitAnimation(DiscoveryCandidate top, Size size) {
    final (exitOffset, exitAngle) = _exitParams(state.exitAction!, size);

    return TweenAnimationBuilder<double>(
      key: ValueKey(state.exitAction),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeIn,
      builder: (ctx, t, child) => Transform.translate(
        offset: exitOffset * t,
        child: Transform.rotate(
          angle: exitAngle * t,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: _CardSurface(candidate: top),
    );
  }

  static (Offset, double) _exitParams(SwipeAction action, Size size) {
    return switch (action) {
      SwipeAction.pass => (
          Offset(-size.width * 1.45, size.height * 0.06),
          -math.pi / 10,
        ),
      SwipeAction.match => (
          Offset(size.width * 1.45, size.height * 0.06),
          math.pi / 10,
        ),
      SwipeAction.greet => (
          Offset(0, -size.height * 1.2),
          0.0,
        ),
      SwipeAction.superPaw => (
          Offset(size.width * 0.4, -size.height * 1.2),
          math.pi / 20,
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card surface — gradient photo + blob illustration + info panel
// ─────────────────────────────────────────────────────────────────────────────

class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.candidate,
    this.isExpanded = false,
    this.onToggleExpand,
  });
  final DiscoveryCandidate candidate;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final colors = candidate.gradientColors;
    final gradColors = [
      if (colors.isNotEmpty) colors[0],
      if (colors.length > 1) colors[1],
      if (colors.length > 2) colors[2] else if (colors.isNotEmpty) colors.last,
    ];

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(PetfolioThemeExtension.radius2xl),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradColors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pet blob (centred in the upper portion)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              bottom: 160,
              child: Center(child: _PetBlob(candidate: candidate)),
            ),
            // Scrim — fade to black for info readability
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1.0],
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            // Info panel pinned to the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _InfoPanel(
                candidate: candidate,
                isExpanded: isExpanded,
                onToggle: onToggleExpand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pet blob illustration
// ─────────────────────────────────────────────────────────────────────────────

class _PetBlob extends StatelessWidget {
  const _PetBlob({required this.candidate});
  final DiscoveryCandidate candidate;

  static const _blobRadius = BorderRadius.only(
    topLeft: Radius.circular(120),
    topRight: Radius.circular(100),
    bottomLeft: Radius.circular(80),
    bottomRight: Radius.circular(140),
  );

  @override
  Widget build(BuildContext context) {
    final emoji = switch (candidate.species) {
      'cat' => '🐱',
      'rabbit' => '🐰',
      _ => '🐶',
    };

    return LayoutBuilder(
      builder: (_, constraints) {
        // Scale the blob with the available area, clamped for small/large screens.
        final w = (constraints.maxWidth * 0.52).clamp(120.0, 220.0);
        final h = w * 1.1;
        final emojiSize = w * 0.44;

        final blobDecoration = BoxDecoration(
          color: candidate.subjectColor.withAlpha(180),
          borderRadius: _blobRadius,
        );

        // When a real pet photo is available, show it inside the blob shape.
        // Fall back to the emoji illustration on network error or absence.
        final hasPhoto = candidate.avatarUrl != null &&
            candidate.avatarUrl!.isNotEmpty;

        if (hasPhoto) {
          return ClipRRect(
            borderRadius: _blobRadius,
            child: CachedNetworkImage(
              imageUrl: candidate.avatarUrl!,
              width: w,
              height: h,
              fit: BoxFit.cover,
              // Placeholder: show the coloured blob while the image loads.
              placeholder: (_, _) => Container(
                width: w,
                height: h,
                decoration: blobDecoration,
                alignment: Alignment.center,
                child: Text(emoji,
                    style: TextStyle(fontSize: emojiSize)),
              ),
              // Error: fall back to emoji blob — never a broken-image icon.
              errorWidget: (_, _, _) => Container(
                width: w,
                height: h,
                decoration: blobDecoration,
                alignment: Alignment.center,
                child: Text(emoji,
                    style: TextStyle(fontSize: emojiSize)),
              ),
            ),
          );
        }

        return Container(
          width: w,
          height: h,
          decoration: blobDecoration,
          alignment: Alignment.center,
          child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info panel
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.candidate,
    required this.isExpanded,
    this.onToggle,
  });
  final DiscoveryCandidate candidate;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: PetfolioThemeExtension.durationMd,
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Name + age + expand toggle ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    candidate.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  candidate.age,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white.withAlpha(190),
                  ),
                ),
                if (candidate.verified) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
                const Spacer(),
                if (onToggle != null)
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(60),
                        ),
                      ),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // ── Breed + distance ────────────────────────────────────────
            Row(
              children: [
                Text(
                  candidate.breed,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(120),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Icon(
                  Icons.location_on_rounded,
                  size: 13,
                  color: Colors.white.withAlpha(180),
                ),
                const SizedBox(width: 2),
                Text(
                  candidate.distance,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Traits ──────────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final trait in candidate.traits) _TraitChip(label: trait),
              ],
            ),
            // ── Expanded bio ─────────────────────────────────────────────
            if (isExpanded) ...[
              const SizedBox(height: 14),
              Text(
                candidate.bio,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withAlpha(215),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.directions_walk_rounded,
                label: 'Play style',
                value: candidate.playStyle,
              ),
              const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.bolt_rounded,
                label: 'Energy',
                value: candidate.energy,
              ),
              const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.people_outline_rounded,
                label: 'Best with',
                value: candidate.bestWith,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action dock — 5 buttons from the design spec
// ─────────────────────────────────────────────────────────────────────────────

class _ActionDock extends StatelessWidget {
  const _ActionDock({required this.state, required this.notifier});
  final DiscoveryState state;
  final DiscoveryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final disabled = state.isExiting || state.topCard == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _DockButton(
            size: 56,
            color: AppColors.ink300,
            icon: Icons.close_rounded,
            iconSize: 26,
            onTap: disabled ? null : () => notifier.swipe(SwipeAction.pass),
          ),
          _DockButton(
            size: 48,
            color: AppColors.blue500,
            icon: Icons.waving_hand_rounded,
            iconSize: 22,
            onTap: disabled ? null : () => notifier.swipe(SwipeAction.greet),
          ),
          _DockButton(
            size: 64,
            color: AppColors.coral500,
            icon: Icons.pets_rounded,
            iconSize: 30,
            elevated: true,
            onTap: disabled ? null : () => notifier.swipe(SwipeAction.match),
          ),
          _DockButton(
            size: 48,
            color: AppColors.mulberry500,
            icon: Icons.star_rounded,
            iconSize: 22,
            onTap: disabled
                ? null
                : () => notifier.swipe(SwipeAction.superPaw),
          ),
          _DockButton(
            size: 56,
            color: AppColors.sunset500,
            icon: Icons.bolt_rounded,
            iconSize: 26,
            onTap: null, // Boost — premium feature placeholder
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeLabel extends StatelessWidget {
  const _SwipeLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2.5),
        borderRadius:
            BorderRadius.circular(PetfolioThemeExtension.radiusSm),
        color: color.withAlpha(25),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _TraitChip extends StatelessWidget {
  const _TraitChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius:
            BorderRadius.circular(PetfolioThemeExtension.radiusPill),
        border: Border.all(color: Colors.white.withAlpha(70)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white.withAlpha(150)),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withAlpha(180),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withAlpha(215),
            ),
          ),
        ),
      ],
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.size,
    required this.color,
    required this.icon,
    required this.iconSize,
    required this.onTap,
    this.elevated = false,
  });
  final double size;
  final Color color;
  final IconData icon;
  final double iconSize;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: PetfolioThemeExtension.durationSm,
        opacity: isDisabled ? 0.38 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: elevated
                ? color
                : (isDark ? AppColors.surface0D : AppColors.surface0),
            border: elevated
                ? null
                : Border.all(color: color.withAlpha(90), width: 1.5),
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: elevated ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
