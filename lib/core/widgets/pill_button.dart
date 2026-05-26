import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

enum PillButtonVariant {
  primary,
  soft,
  ghost,
  outline,
  dark,
}

enum PillButtonSize {
  sm,
  md,
  lg,
  xl,
}

class PillButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final PillButtonSize size;
  final Widget? icon;
  final Widget? iconRight;
  final bool isFullWidth;
  final Color? color;
  final bool disabled;

  const PillButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.size = PillButtonSize.md,
    this.icon,
    this.iconRight,
    this.isFullWidth = false,
    this.color,
    this.disabled = false,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _isPressed = false;

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.disabled || widget.onPressed == null) return;
    setState(() => _isPressed = true);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (widget.disabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (widget.disabled || widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<PetfolioThemeExtension>() ?? PetfolioThemeExtension.light;
    final colors = theme.extension<PetFolioColors>() ?? PetFolioColors.light;

    final isDisabled = widget.disabled || widget.onPressed == null;

    double height;
    double px;
    double fontSize;
    switch (widget.size) {
      case PillButtonSize.sm:
        height = 36.0;
        px = 14.0;
        fontSize = 14.0;
        break;
      case PillButtonSize.md:
        height = 48.0;
        px = 22.0;
        fontSize = 16.0;
        break;
      case PillButtonSize.lg:
        height = 56.0;
        px = 26.0;
        fontSize = 17.0;
        break;
      case PillButtonSize.xl:
        height = 64.0;
        px = 30.0;
        fontSize = 18.0;
        break;
    }

    Color bg;
    Color fg;
    Color? hardShadowColor;
    Color? blurShadowColor;
    bool isOutline = false;

    switch (widget.variant) {
      case PillButtonVariant.primary:
        bg = widget.color ?? colors.tangerine;
        fg = Colors.white;
        hardShadowColor = colors.tangerine700;
        blurShadowColor = bg.withValues(alpha: 0.6);
        break;
      case PillButtonVariant.soft:
        bg = colors.tangerineSoft;
        fg = colors.tangerine700;
        break;
      case PillButtonVariant.ghost:
        bg = Colors.transparent;
        fg = ext.ink950;
        break;
      case PillButtonVariant.outline:
        bg = theme.colorScheme.surface;
        fg = ext.ink950;
        isOutline = true;
        break;
      case PillButtonVariant.dark:
        bg = ext.ink950;
        fg = ext.cream;
        hardShadowColor = Colors.black;
        blurShadowColor = Colors.black.withValues(alpha: 0.4);
        break;
    }

    final hasShadow = hardShadowColor != null;

    final boxStyle = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: isOutline ? Border.all(color: ext.line2, width: 2) : null,
      boxShadow: (hasShadow && !isDisabled)
          ? [
              BoxShadow(
                color: hardShadowColor,
                offset: Offset(0, _isPressed ? 2 : 6),
              ),
              if (blurShadowColor != null)
                BoxShadow(
                  color: blurShadowColor,
                  offset: Offset(0, _isPressed ? 12 : 14),
                  blurRadius: 24,
                  spreadRadius: -10,
                ),
            ]
          : [],
    );

    Widget contentChild = widget.child;
    if (widget.icon != null || widget.iconRight != null) {
      contentChild = Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: 8),
          ],
          Flexible(child: widget.child),
          if (widget.iconRight != null) ...[
            const SizedBox(width: 8),
            widget.iconRight!,
          ],
        ],
      );
    }

    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      foregroundColor: WidgetStateProperty.all(fg),
      overlayColor: WidgetStateProperty.all(fg.withValues(alpha: 0.1)),
      shadowColor: WidgetStateProperty.all(Colors.transparent),
      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      elevation: WidgetStateProperty.all(0),
      padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: px)),
      shape: WidgetStateProperty.all(const StadiumBorder()),
      minimumSize: WidgetStateProperty.all(
        Size(widget.isFullWidth ? double.infinity : 0, height),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStateProperty.all(
        GoogleFonts.nunito(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );

    Widget button;
    if (isOutline) {
      button = OutlinedButton(
        style: buttonStyle.copyWith(
          side: WidgetStateProperty.all(BorderSide.none),
        ),
        onPressed: isDisabled ? null : widget.onPressed,
        child: contentChild,
      );
    } else {
      button = FilledButton(
        style: buttonStyle,
        onPressed: isDisabled ? null : widget.onPressed,
        child: contentChild,
      );
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      height: height,
      transform: Matrix4.translationValues(0, _isPressed && !isDisabled ? 2.0 : 0.0, 0.0),
      decoration: boxStyle,
      child: button,
    );

    if (isDisabled) {
      content = Opacity(
        opacity: 0.5,
        child: content,
      );
    }

    if (widget.isFullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    return RepaintBoundary(
      child: Listener(
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: content,
      ),
    );
  }
}
