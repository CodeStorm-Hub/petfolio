import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfolio/core/providers/supabase_provider.dart';

import '../../data/repositories/auth_repository.dart';

part 'auth_controller.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dependency injection & State Providers
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
}

/// Streams every [AuthState] change from Supabase Auth.
///
/// The initial value is synthesised from the current session so the router
/// redirect fires synchronously on cold start without waiting for the stream.
@Riverpod(keepAlive: true)
Stream<AuthState> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
}

/// Derived convenience provider — true when a valid session exists.
@Riverpod(keepAlive: true)
bool isLoggedIn(Ref ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.when(
    data: (s) => s.session != null,
    // Fall back to checking the cached session so the router doesn't flicker.
    loading: () => ref.read(authRepositoryProvider).currentSession != null,
    error: (_, _) => false,
  );
}

/// Derived convenience provider — the current signed-in user, if any.
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.when(
    data: (s) => s.session?.user,
    loading: () => ref.read(authRepositoryProvider).currentUser,
    error: (_, _) => null,
  );
}

/// Derived convenience provider — the current signed-in session, if any.
@Riverpod(keepAlive: true)
Session? currentSession(Ref ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.when(
    data: (s) => s.session,
    loading: () => ref.read(authRepositoryProvider).currentSession,
    error: (_, _) => null,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Password reset
// ─────────────────────────────────────────────────────────────────────────────

enum PasswordResetStatus { idle, loading, sent, failure }

class PasswordResetState {
  const PasswordResetState({
    this.status = PasswordResetStatus.idle,
    this.error,
  });

  final PasswordResetStatus status;
  final String? error;

  bool get isLoading => status == PasswordResetStatus.loading;
  bool get isSent => status == PasswordResetStatus.sent;

  PasswordResetState copyWith({
    PasswordResetStatus? status,
    String? error,
    bool clearError = false,
  }) =>
      PasswordResetState(
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
      );
}

@riverpod
class PasswordReset extends _$PasswordReset {
  @override
  PasswordResetState build() => const PasswordResetState();

  Future<void> send(String email) async {
    state = const PasswordResetState(status: PasswordResetStatus.loading);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      state = const PasswordResetState(status: PasswordResetStatus.sent);
    } on AuthException catch (e) {
      state = PasswordResetState(
        status: PasswordResetStatus.failure,
        error: e.message,
      );
    } catch (e) {
      state = PasswordResetState(
        status: PasswordResetStatus.failure,
        error: e.toString(),
      );
    }
  }

  void reset() => state = const PasswordResetState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Error consolidation helper
// ─────────────────────────────────────────────────────────────────────────────

extension AuthFriendlyError on Object {
  String toFriendlyAuthError() {
    final raw = this is AuthException ? (this as AuthException).message : toString();
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
    if (lower.contains('user already registered') ||
        lower.contains('email already') ||
        lower.contains('already registered')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('over_email_send_rate_limit') ||
        lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (lower.contains('weak password') ||
        lower.contains('password should be')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    return raw;
  }
}
