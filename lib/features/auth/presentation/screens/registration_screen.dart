import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_widgets.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() =>
      _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: PetfolioThemeExtension.durationMd,
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // GoRouter redirects to /home or /onboarding after auth state changes.
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

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // ── Brand ────────────────────────────────────────────────
                const AuthBrand(),
                const SizedBox(height: 40),

                // ── Form card ────────────────────────────────────────────
                AuthCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Create account', style: tt.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'One home for every pet in your life.',
                          style: tt.bodyMedium?.copyWith(color: pt.ink500),
                        ),
                        const SizedBox(height: 28),

                        // Email
                        AuthField(
                          controller: _emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!_emailRegex.hasMatch(v.trim())) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password
                        AuthField(
                          controller: _passwordController,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          suffixIcon: VisibilityToggle(
                            obscure: _obscurePassword,
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            color: pt.ink300,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 6) {
                              return 'Must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Confirm password
                        AuthField(
                          controller: _confirmController,
                          label: 'Confirm password',
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          suffixIcon: VisibilityToggle(
                            obscure: _obscureConfirm,
                            onTap: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            color: pt.ink300,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        // Error banner
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          AuthErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 28),

                        Semantics(
                          label: 'Create account',
                          button: true,
                          child: PrimaryPillButton(
                            key: const ValueKey('register_cta'),
                            label: 'Create account',
                            onPressed: _isLoading ? null : _submit,
                            isLoading: _isLoading,
                            isFullWidth: true,
                            size: PillButtonSize.xl,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Login link ───────────────────────────────────────────
                AuthToggleLink(
                  question: 'Already have an account?',
                  actionLabel: 'Sign in',
                  onTap: () => context.go('/login'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
