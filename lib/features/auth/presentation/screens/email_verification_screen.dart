import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:petfolio/core/theme/theme.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_widgets.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  static const _cooldownSeconds = 60;

  int _remaining = 0;
  Timer? _timer;
  bool _isResending = false;
  String? _resendError;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _remaining = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _remaining <= 1) {
        t.cancel();
        if (mounted) setState(() => _remaining = 0);
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _resendError = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resendVerificationEmail(widget.email);
      if (mounted) _startCooldown();
    } on AuthException catch (e) {
      if (mounted) setState(() => _resendError = e.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _resendError = 'Failed to resend. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final canResend = _remaining == 0 && !_isResending;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const AuthBrand(),
              const SizedBox(height: 40),

              AuthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(
                              PetfolioThemeExtension.radiusXl),
                        ),
                        child: Icon(Icons.mark_email_unread_outlined,
                            color: cs.primary, size: 28),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Check your email',
                      style: tt.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    Text.rich(
                      TextSpan(
                        text: 'We sent a confirmation link to\n',
                        style: tt.bodyMedium?.copyWith(color: pt.ink500),
                        children: [
                          TextSpan(
                            text: widget.email,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    if (_resendError != null) ...[
                      AuthErrorBanner(message: _resendError!),
                      const SizedBox(height: 16),
                    ],

                    OutlinedButton(
                      onPressed: canResend ? _resend : null,
                      child: Text(
                        _remaining > 0
                            ? 'Resend in ${_remaining}s'
                            : _isResending
                                ? 'Sending…'
                                : 'Resend confirmation email',
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: pt.surface2,
                        borderRadius: BorderRadius.circular(
                            PetfolioThemeExtension.radiusMd),
                      ),
                      child: Text(
                        "Didn't get it? Check your spam folder, then tap Resend.",
                        style: tt.bodySmall?.copyWith(color: pt.ink500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AuthToggleLink(
                question: 'Already verified?',
                actionLabel: 'Sign in',
                onTap: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
