import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum PillButtonSize { sm, md, lg, xl, walk }
enum PillButtonVariant { primary, secondary, ghost, destructive, soft }

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
    this.trailingIcon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillButtonSize size;
  final PillButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final Color? color;

  @override
  State<PrimaryPillButton> createState() => _PrimaryPillButtonState();
}

class _PrimaryPillButtonState extends State<PrimaryPillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _shadowShift;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PetfolioThemeExtension.durationXs,       // 80 ms press
      reverseDuration: const Duration(milliseconds: 480), // spring release
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut, // M3E spring bounce-back
      ),
    );
    _shadowShift = Tween<double>(begin: 1.0, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  void _down(PointerDownEvent _) {
    if (!_isEnabled) return;
    setState(() => _pressed = true);
    FocusManager.instance.primaryFocus?.unfocus();
    if (!MediaQuery.of(context).disableAnimations) _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _up(PointerUpEvent _) {
    setState(() => _pressed = false);
    _controller.reverse();
    if (_isEnabled) widget.onPressed?.call();
  }

  void _cancel(PointerCancelEvent _) {
    setState(() => _pressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = _resolveSizes();
    final colors = _resolveColors(isDark);

    Widget button = Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedOpacity(
          opacity: _isEnabled ? 1.0 : 0.45,
          duration: PetfolioThemeExtension.durationSm,
          child: AnimatedBuilder(
            animation: _shadowShift,
            builder: (context, child) => _buildVisual(context, isDark, s, colors),
          ),
        ),
      ),
    );

    return widget.isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildVisual(BuildContext context, bool isDark, _SizeTokens s, _BtnColors colors) {
    final shadowOffset = _pressed ? 2.0 : 6.0;
    final shadowY = _pressed ? 2.0 : 6.0;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.label,
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationXs,
        height: s.height,
        constraints: BoxConstraints(minWidth: s.minWidth),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
          boxShadow: widget.variant == PillButtonVariant.primary
              ? [
                  BoxShadow(
                    offset: Offset(0, shadowY),
                    blurRadius: 0,
                    color: colors.shadow,
                  ),
                  BoxShadow(
                    offset: Offset(0, shadowOffset + 8),
                    blurRadius: 20,
                    spreadRadius: -6,
                    color: colors.background.withAlpha(150),
                  ),
                ]
              : widget.variant == PillButtonVariant.secondary
                  ? [BoxShadow(color: colors.background.withAlpha(80), blurRadius: 0, offset: Offset(0, shadowY))]
                  : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.hPad),
          child: _buildContent(colors, s),
        ),
      ),
    );
  }

  Widget _buildContent(_BtnColors colors, _SizeTokens s) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(colors.foreground),
          ),
        ),
      );
    }

    final label = Text(
      widget.label,
      style: GoogleFonts.sora(
        fontSize: s.fontSize,
        fontWeight: FontWeight.w700,
        color: colors.foreground,
        height: 1.0,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final children = <Widget>[
      if (widget.leadingIcon != null) ...[
        IconTheme(data: IconThemeData(color: colors.foreground, size: 20), child: widget.leadingIcon!),
        const SizedBox(width: 8),
      ],
      label,
      if (widget.trailingIcon != null) ...[
        const SizedBox(width: 8),
        IconTheme(data: IconThemeData(color: colors.foreground, size: 18), child: widget.trailingIcon!),
      ],
    ];

    if (children.length == 1) return Center(child: label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  _SizeTokens _resolveSizes() => switch (widget.size) {
    PillButtonSize.sm   => const _SizeTokens(height: 36, minWidth: 72,  hPad: 14, fontSize: 13),
    PillButtonSize.md   => const _SizeTokens(height: 44, minWidth: 96,  hPad: 18, fontSize: 15),
    PillButtonSize.lg   => const _SizeTokens(height: 52, minWidth: 120, hPad: 22, fontSize: 16),
    PillButtonSize.xl   => const _SizeTokens(height: 60, minWidth: 160, hPad: 26, fontSize: 17),
    PillButtonSize.walk => const _SizeTokens(height: 64, minWidth: 160, hPad: 26, fontSize: 17),
  };

  _BtnColors _resolveColors(bool isDark) {
    final customBg = widget.color;
    if (customBg != null) {
      return _BtnColors(
        background: customBg,
        foreground: Colors.white,
        shadow: HSLColor.fromColor(customBg).withLightness(
          (HSLColor.fromColor(customBg).lightness - 0.18).clamp(0.0, 1.0),
        ).toColor(),
      );
    }

    return switch (widget.variant) {
      PillButtonVariant.primary => _BtnColors(
        background: isDark ? AppColors.tangerineD : AppColors.tangerine,
        foreground: Colors.white,
        shadow: isDark ? AppColors.tangerine700D : AppColors.tangerine700,
      ),
      PillButtonVariant.soft => _BtnColors(
        background: isDark ? AppColors.tangerineSoftD : AppColors.tangerineSoft,
        foreground: isDark ? AppColors.tangerine700D : AppColors.tangerine700,
        shadow: Colors.transparent,
      ),
      PillButtonVariant.secondary => _BtnColors(
        background: isDark ? AppColors.surface0D : AppColors.surface0,
        foreground: isDark ? AppColors.ink950D : AppColors.ink950,
        shadow: isDark ? AppColors.lineD : AppColors.line2,
      ),
      PillButtonVariant.ghost => _BtnColors(
        background: Colors.transparent,
        foreground: isDark ? AppColors.tangerineD : AppColors.tangerine700,
        shadow: Colors.transparent,
      ),
      PillButtonVariant.destructive => _BtnColors(
        background: isDark ? AppColors.dangerD : AppColors.danger,
        foreground: Colors.white,
        shadow: isDark ? AppColors.poppy700D : AppColors.poppy700,
      ),
    };
  }
}

class _SizeTokens {
  const _SizeTokens({required this.height, required this.minWidth, required this.hPad, required this.fontSize});
  final double height;
  final double minWidth;
  final double hPad;
  final double fontSize;
}

class _BtnColors {
  const _BtnColors({required this.background, required this.foreground, required this.shadow});
  final Color background;
  final Color foreground;
  final Color shadow;
}
