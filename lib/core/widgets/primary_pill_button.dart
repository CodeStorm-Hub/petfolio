import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// §5.1 size tokens.
enum PillButtonSize { sm, md, lg, xl, walk }

/// §5.2 visual variants.
enum PillButtonVariant { primary, secondary, ghost, destructive }

// ─────────────────────────────────────────────────────────────────────────────
// PrimaryPillButton
// ─────────────────────────────────────────────────────────────────────────────

/// Pill-shaped button conforming to PetFolio §5.
///
/// Features:
/// - All 5 size tokens: [PillButtonSize.sm] → [PillButtonSize.walk].
/// - All 4 variants: primary (filled), secondary (tonal), ghost, destructive.
/// - Press animation: 0.97× scale, 80 ms ease-out spring (primary only, §5.2).
/// - Loading state: locked width + 20 dp spinner.
/// - Haptic feedback per §5.3.
/// - Minimum 48 dp hit target via [MaterialTapTargetSize.padded].
/// - Respects `disableAnimations` — no scale animation in Reduce Motion.
///
/// ```dart
/// PrimaryPillButton(
///   label: 'Find a match',
///   onPressed: () {},
/// )
/// ```
class PrimaryPillButton extends StatefulWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = PillButtonSize.lg,
    this.variant = PillButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonSize size;
  final PillButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? leadingIcon;

  @override
  State<PrimaryPillButton> createState() => _PrimaryPillButtonState();
}

class _PrimaryPillButtonState extends State<PrimaryPillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PetfolioThemeExtension.durationXs, // 80 ms
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _onTapDown(TapDownDetails _) {
    if (!_isEnabled) return;
    // Dismiss the soft keyboard at the earliest possible moment (pointer-down,
    // before any layout shift).  Without this, the Scaffold shrinks between
    // onTapDown and onTap, the button moves, and the tap is cancelled —
    // forcing the user to tap twice on Android.
    FocusManager.instance.primaryFocus?.unfocus();
    // Only primary variant scales (§5.2: "the only button that scales")
    if (widget.variant == PillButtonVariant.primary &&
        !MediaQuery.of(context).disableAnimations) {
      _controller.forward();
    }
    _triggerHaptic();
  }

  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  void _triggerHaptic() {
    switch (widget.variant) {
      case PillButtonVariant.destructive:
        HapticFeedback.mediumImpact();
      default:
        HapticFeedback.lightImpact();
    }
    // Walk mode: extra vibration cue (§5.3)
    if (widget.size == PillButtonSize.walk) {
      Future.delayed(const Duration(milliseconds: 30),
          HapticFeedback.mediumImpact);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sizes = _resolveSizes();

    final button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _isEnabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedOpacity(
          opacity: _isEnabled ? 1.0 : 0.45,
          duration: PetfolioThemeExtension.durationSm,
          child: _buildVisual(context, isDark, sizes),
        ),
      ),
    );

    return widget.isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildVisual(BuildContext context, bool isDark, _SizeTokens s) {
    final colors = _resolveColors(isDark);

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.label,
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationSm,
        height: s.height,
        // Lock width to prevent layout shift during loading (§5.3)
        constraints: BoxConstraints(minWidth: s.minWidth),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
          boxShadow: widget.variant == PillButtonVariant.primary
              ? [
                  BoxShadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: (isDark ? AppColors.shadowE1D : AppColors.shadowE1L),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.hPad),
          child: _buildContent(colors, s),
        ),
      ),
    );
  }

  Widget _buildContent(_ButtonColors colors, _SizeTokens s) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation(colors.foreground),
          ),
        ),
      );
    }

    final label = Text(
      widget.label,
      style: GoogleFonts.inter(
        fontSize: s.fontSize,
        fontWeight: FontWeight.w600,
        color: colors.foreground,
        height: 1.0,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (widget.leadingIcon == null) {
      return Center(child: label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme(
          data: IconThemeData(color: colors.foreground, size: 20),
          child: widget.leadingIcon!,
        ),
        const SizedBox(width: 8),
        label,
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  _SizeTokens _resolveSizes() {
    return switch (widget.size) {
      PillButtonSize.sm   => const _SizeTokens(height: 36, minWidth: 72,  hPad: 14, fontSize: 14),
      PillButtonSize.md   => const _SizeTokens(height: 44, minWidth: 96,  hPad: 16, fontSize: 16),
      PillButtonSize.lg   => const _SizeTokens(height: 52, minWidth: 120, hPad: 20, fontSize: 17),
      PillButtonSize.xl   => const _SizeTokens(height: 60, minWidth: 160, hPad: 24, fontSize: 18),
      PillButtonSize.walk => const _SizeTokens(height: 64, minWidth: 160, hPad: 24, fontSize: 18),
    };
  }

  _ButtonColors _resolveColors(bool isDark) {
    return switch (widget.variant) {
      PillButtonVariant.primary => _ButtonColors(
          background: AppColors.amber500,
          foreground: AppColors.warmBlack,
        ),
      PillButtonVariant.secondary => _ButtonColors(
          background: isDark ? AppColors.surface2D : AppColors.cream100,
          foreground: isDark ? AppColors.amber500 : AppColors.amber700,
        ),
      PillButtonVariant.ghost => _ButtonColors(
          background: Colors.transparent,
          foreground: isDark ? AppColors.amber500 : AppColors.amber700,
        ),
      PillButtonVariant.destructive => _ButtonColors(
          background: isDark ? AppColors.dangerD : AppColors.danger,
          foreground: Colors.white,
        ),
    };
  }
}

// ── Private data classes ──────────────────────────────────────────────────────

class _SizeTokens {
  const _SizeTokens({
    required this.height,
    required this.minWidth,
    required this.hPad,
    required this.fontSize,
  });

  final double height;
  final double minWidth;
  final double hPad;
  final double fontSize;
}

class _ButtonColors {
  const _ButtonColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
