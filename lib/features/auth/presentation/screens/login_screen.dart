import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/core/theme/theme.dart';
import 'package:petfolio/core/widgets/widgets.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // GoRouter's authStateProvider listener triggers redirect to /home.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyAuthError(e.message));
    } catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Maps verbose Supabase / Dart network errors to a short user-facing
  /// message.  Supabase wraps `ClientException` /`SocketException` inside
  /// `AuthRetryableFetchException extends AuthException`, so the raw
  /// `e.message` ends up being a 200-character stack-trace-y blob — useless
  /// for the user.
  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('failed host lookup') ||
        lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('no address associated')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (lower.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    }
    if (lower.contains('invalid login') ||
        lower.contains('invalid_grant') ||
        lower.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    return raw;
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
                        Text('Welcome back', style: tt.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue.',
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
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
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

                        // Error banner
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          AuthErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 28),

                        // CTA
                        PrimaryPillButton(
                          label: 'Sign in',
                          onPressed: _isLoading ? null : _submit,
                          isLoading: _isLoading,
                          isFullWidth: true,
                          size: PillButtonSize.xl,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Register link ────────────────────────────────────────
                AuthToggleLink(
                  question: "Don't have an account?",
                  actionLabel: 'Create one',
                  onTap: () => context.go('/register'),
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
