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
    loading: () => Supabase.instance.client.auth.currentSession != null,
    error: (_, __) => false,
  );
});
