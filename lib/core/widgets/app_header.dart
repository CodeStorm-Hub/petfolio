
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/pet_avatar.dart';
import 'package:petfolio/core/widgets/skeleton_loader.dart';
import 'package:petfolio/core/domain/models/pet.dart';
import 'package:petfolio/core/domain/controllers/active_pet_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppHeader — the single, shell-wide top bar.
// ─────────────────────────────────────────────────────────────────────────────
//
// One component, used identically across Home / Care / Social / Match / Market
// so the eye never has to re-learn where the pet switcher, screen label, or
// notification bell live. Inspired by Material 3 "small top app bar" anatomy
// (leading · content · trailing) but skinned to PetFolio tokens.
//
// Layout (left → right):
//   [optional back]  [avatar | eyebrow over name▾ cluster]   [actions…]
//
// Slot rules:
//   • Avatar opens the Pets tab (`/home`) for the active pet profile. Name +
//     chevron opens the PetSwitcherSheet.
//   • [eyebrow] is the screen's section label (CARE, PACK, MATCH, MARKET).
//     "Home" intentionally uses "ACTIVE PET" to keep focus on the pet.
//   • Up to two trailing [AppHeaderAction]s; primary action goes last (right
//     edge) because that is the natural thumb-rest position.
//   • An optional 1-px hairline under the bar separates it from scrolled
//     content without competing with the streak/hero card colors.

class AppHeader extends ConsumerWidget {
  const AppHeader({
    super.key,
    required this.eyebrow,
    required this.onOpenSwitcher,
    this.onBack,
    this.actions = const [],
    this.showDivider = true,
    this.dense = false,
  });

  /// Small uppercase label sitting above the active pet's name (e.g. "CARE",
  /// "PACK"). Use "ACTIVE PET" for the home / pet-profile tab.
  final String eyebrow;

  /// Opens the pet switcher sheet. Injected by the caller to keep this widget
  /// free of feature-level imports (avoids a `core → feature → core` cycle).
  final VoidCallback onOpenSwitcher;

  /// Optional back button. When provided, a circular back chip is rendered
  /// before the pet switcher.
  final VoidCallback? onBack;

  /// 0-2 trailing actions. Anything beyond two should move into an overflow
  /// sheet rather than crowding the bar.
  final List<AppHeaderAction> actions;

  /// Renders a faint divider under the bar. Disable for screens whose hero
  /// card already provides its own separation (or when the header is over a
  /// dark/outdoor background).
  final bool showDivider;

  /// Tighter vertical padding for screens with limited vertical real estate
  /// (e.g. matching swipe deck).
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final pet = ref.watch(activePetControllerProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: pt.line, width: 0.5))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, dense ? 8 : 12, 12, dense ? 8 : 12),
        child: Row(
          children: [
            if (onBack != null) ...[
              _CircleChip(onTap: onBack!, child: const _BackGlyph()),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _PetSwitcherTrigger(
                eyebrow: eyebrow,
                pet: pet,
                onTap: onOpenSwitcher,
              ),
            ),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _ActionButton(action: actions[i]),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppHeaderAction — declarative action description so screens don't have to
// repeat the chip styling. Use [badge] for an unread-count or notification dot.
// ─────────────────────────────────────────────────────────────────────────────

class AppHeaderAction {
  const AppHeaderAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge,
    this.filled = false,
    this.iconKey,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  /// Optional badge payload: a count ([badge] as int) renders a pill with the
  /// number; `true` renders a single notification dot.
  final Object? badge;

  /// When true, the chip uses ink950 fill (used for the Care outdoor toggle).
  final bool filled;

  /// Key plumbed to the inner button so widget tests / Marionette can target
  /// the specific action.
  final Key? iconKey;
}

// ── Pet switcher trigger ──────────────────────────────────────────────────────

class _PetSwitcherTrigger extends StatelessWidget {
  const _PetSwitcherTrigger({
    required this.eyebrow,
    required this.pet,
    required this.onTap,
  });

  final String eyebrow;
  final Pet? pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final species = pet?.speciesEnum ?? PetSpecies.dog;

    final avatarTap = pet != null
        ? () => context.push('/social/profile/${pet!.id}')
        : null;

    return Row(
      children: [
        GestureDetector(
          key: const ValueKey<String>('app_header_pet_profile'),
          behavior: HitTestBehavior.opaque,
          onTap: avatarTap,
          child: Semantics(
            button: pet != null,
            label:
                pet != null ? 'View ${pet!.name} profile' : 'Loading pet profile',
            child: pet != null
                ? PetAvatar(
                    imageUrl: pet!.avatarUrl,
                    size: PetAvatarSize.md,
                    initials: pet!.name.isNotEmpty ? pet!.name[0] : null,
                    borderColor: species.accent,
                    semanticLabel: pet!.name,
                  )
                : const SkeletonLoader(width: 40, height: 40, borderRadius: 999),
          ),
        ),
        SizedBox(width: AppTheme.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08 * 11,
                  color: pt.ink500,
                ),
              ),
              SizedBox(height: AppTheme.spacing.xs / 2),
              GestureDetector(
                key: const ValueKey<String>('app_header_pet_switcher'),
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Semantics(
                  button: true,
                  label: pet != null
                      ? 'Switch pet · current ${pet!.name}'
                      : 'Choose a pet',
                  child: Row(
                    children: [
                      Flexible(
                        child: pet != null
                            ? Text(
                                pet!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.sora(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 19,
                                  letterSpacing: -0.2,
                                  color: cs.onSurface,
                                ),
                              )
                            : const SkeletonLoader(width: 90, height: 19),
                      ),
                      SizedBox(width: AppTheme.spacing.xs),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Color.alphaBlend(
                          cs.onSurfaceVariant.withValues(alpha: 0.38),
                          cs.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final AppHeaderAction action;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final isFilled = action.filled;
    final iconColor = isFilled ? Colors.white : cs.onSurfaceVariant;

    Widget icon = Icon(action.icon, size: 20, color: iconColor);
    final badge = action.badge;
    if (badge != null) {
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(top: -4, right: -6, child: _BadgePill(value: badge, pt: pt)),
        ],
      );
    }

    return Tooltip(
      message: action.tooltip,
      child: _CircleChip(
        key: action.iconKey,
        onTap: action.onTap,
        filled: isFilled,
        child: icon,
      ),
    );
  }
}

class _CircleChip extends StatelessWidget {
  const _CircleChip({
    super.key,
    required this.onTap,
    required this.child,
    this.filled = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: filled ? AppColors.ink950 : cs.surface,
          shape: BoxShape.circle,
          boxShadow: [
            const BoxShadow(
              color: AppColors.shadowE1L,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: pt.line.withAlpha(128),
              blurRadius: 0,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.value, required this.pt});
  final Object value;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    if (value is int && (value as int) > 0) {
      final n = value as int;
      final label = n > 99 ? '99+' : '$n';
      return Container(
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.coral500,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: pt.surface1, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      );
    }
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: AppColors.coral500,
        shape: BoxShape.circle,
        border: Border.all(color: pt.surface1, width: 1.5),
      ),
    );
  }
}

class _BackGlyph extends StatelessWidget {
  const _BackGlyph();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Icon(Icons.chevron_left_rounded, size: 24, color: cs.onSurfaceVariant);
  }
}
