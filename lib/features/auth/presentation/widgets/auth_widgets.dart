import 'package:flutter/material.dart';

import 'package:petfolio/core/theme/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared auth-screen widgets
// ─────────────────────────────────────────────────────────────────────────────

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.blue400, AppColors.blue600],
            ),
            borderRadius:
                BorderRadius.circular(PetfolioThemeExtension.radiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue500.withAlpha(80),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.pets, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          'PetFolio',
          style: tt.displaySmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your pet\'s world, beautifully organized.',
          style: tt.bodyMedium?.copyWith(color: pt.ink500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// White solid card — §4.2 spec, radius2xl.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            BorderRadius.circular(PetfolioThemeExtension.radius2xl),
        border: Border.all(color: pt.line),
        boxShadow: pt.shadowE2,
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthField — outline input that properly notches the floating label and
// animates a focus glow ring.  Validation errors show inline below the field.
// ─────────────────────────────────────────────────────────────────────────────

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
    this.autocorrect = true,
    this.autofillHints,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final bool autocorrect;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final focused = _focus.hasFocus;

    final radius = BorderRadius.circular(PetfolioThemeExtension.radiusMd);

    return AnimatedContainer(
      duration: PetfolioThemeExtension.durationSm,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: focused
            ? [
                BoxShadow(
                  color: cs.primary.withAlpha(30),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: Offset.zero,
                )
              ]
            : [],
      ),
      child: TextFormField(
        focusNode: _focus,
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        autocorrect: widget.autocorrect,
        autofillHints: widget.autofillHints,
        enableSuggestions: !widget.obscureText,
        validator: widget.validator,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: pt.ink500,
            fontSize: 16,
          ),
          floatingLabelStyle: TextStyle(
            color: focused ? cs.primary : pt.ink500,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          // ── Fill ───────────────────────────────────────────────────────────
          filled: true,
          fillColor: focused ? cs.surface : pt.surface2,
          // ── Borders — OutlineInputBorder correctly notches the floating label
          border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: pt.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: pt.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: cs.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: cs.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: cs.error, width: 2),
          ),
          // ── Layout ────────────────────────────────────────────────────────
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          suffixIcon: widget.suffixIcon,
          // ── Inline validation errors ──────────────────────────────────────
          errorStyle: TextStyle(
            color: cs.error,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          errorMaxLines: 2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VisibilityToggle
// ─────────────────────────────────────────────────────────────────────────────

class VisibilityToggle extends StatelessWidget {
  const VisibilityToggle({
    super.key,
    required this.obscure,
    required this.onTap,
    required this.color,
  });

  final bool obscure;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscure ? 'Show password' : 'Hide password',
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: color,
      ),
      onPressed: onTap,
      splashRadius: 20,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthErrorBanner — shown for server/auth-level errors (wrong password, etc.)
// ─────────────────────────────────────────────────────────────────────────────

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius:
            BorderRadius.circular(PetfolioThemeExtension.radiusMd),
        border: Border.all(color: cs.error.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthToggleLink
// ─────────────────────────────────────────────────────────────────────────────

class AuthToggleLink extends StatelessWidget {
  const AuthToggleLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text.rich(
            TextSpan(
              text: '$question  ',
              style: TextStyle(color: pt.ink500, fontSize: 15),
              children: [
                TextSpan(
                  text: actionLabel,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
