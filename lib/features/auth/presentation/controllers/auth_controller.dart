import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(Supabase.instance.client),
);

/// Streams every [AuthState] change from Supabase Auth.
///
/// The initial value is synthesised from the current session so the router
/// redirect fires synchronously on cold start without waiting for the stream.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// Derived convenience provider — true when a valid session exists.
final isLoggedInProvider = Provider<bool>((ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.when(
    data: (s) => s.session != null,
    // Fall back to checking the cached session so the router doesn't flicker.
    loading: () => ref.read(authRepositoryProvider).currentSession != null,
    error: (_, _) => false,
  );
});

/// Derived convenience provider — the current signed-in user, if any.
final currentUserProvider = Provider<User?>((ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.when(
    data: (s) => s.session?.user,
    loading: () => ref.read(authRepositoryProvider).currentUser,
    error: (_, _) => null,
  );
});

/// Derived convenience provider — the current signed-in session, if any.
final currentSessionProvider = Provider<Session?>((ref) {
  final asyncState = ref.watch(authStateProvider);
  return asyncState.when(
    data: (s) => s.session,
    loading: () => ref.read(authRepositoryProvider).currentSession,
    error: (_, _) => null,
  );
});

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

final passwordResetProvider =
    NotifierProvider<PasswordResetNotifier, PasswordResetState>(
  PasswordResetNotifier.new,
);

class PasswordResetNotifier extends Notifier<PasswordResetState> {
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
