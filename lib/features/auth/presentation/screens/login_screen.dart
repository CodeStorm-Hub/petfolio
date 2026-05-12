import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: PetfolioThemeExtension.durationMd,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      if (_isSignUp) {
        await repo.signUp(email: email, password: password);
      } else {
        await repo.signIn(email: email, password: password);
      }
      // GoRouter's redirect handles navigation after the auth state changes.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggle() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
    });
    _fadeController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),

                // ── Brand mark ───────────────────────────────────────────
                Text(
                  'PetFolio',
                  style: tt.titleLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Headline ─────────────────────────────────────────────
                Text(
                  _isSignUp ? 'Create account' : 'Welcome back',
                  style: tt.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'One home for every pet in your life.'
                      : 'Sign in to continue.',
                  style: tt.bodyLarge,
                ),
                const SizedBox(height: 36),

                // ── Email ────────────────────────────────────────────────
                _AuthInputField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),

                // ── Password ─────────────────────────────────────────────
                _AuthInputField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: pt.ink300,
                      ),
                    ),
                  ),
                ),

                // ── Error banner ─────────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(
                          PetfolioThemeExtension.radiusMd),
                    ),
                    child: Text(
                      _error!,
                      style:
                          TextStyle(color: cs.onErrorContainer, fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // ── Primary CTA ──────────────────────────────────────────
                PrimaryPillButton(
                  label: _isSignUp ? 'Create account' : 'Sign in',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  size: PillButtonSize.xl,
                ),
                const SizedBox(height: 20),

                // ── Toggle sign-in ↔ sign-up ──────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _toggle,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text.rich(
                        TextSpan(
                          text: _isSignUp
                              ? 'Already have an account?  '
                              : "Don't have an account?  ",
                          style: TextStyle(color: pt.ink500, fontSize: 15),
                          children: [
                            TextSpan(
                              text: _isSignUp ? 'Sign in' : 'Create one',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared input field ────────────────────────────────────────────────────────

class _AuthInputField extends StatefulWidget {
  const _AuthInputField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  State<_AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<_AuthInputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: PetfolioThemeExtension.durationSm,
        height: 60,
        decoration: BoxDecoration(
          color: pt.surface2,
          borderRadius:
              BorderRadius.circular(PetfolioThemeExtension.radiusMd),
          border: Border.all(
            color: _focused ? cs.primary : pt.line200,
            width: _focused ? 1.5 : 1.0,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          onSubmitted: widget.onSubmitted,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(color: pt.ink500),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            suffixIcon: widget.suffixIcon,
          ),
        ),
      ),
    );
  }
}
