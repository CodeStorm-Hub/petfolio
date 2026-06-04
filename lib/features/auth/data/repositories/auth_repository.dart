import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/firebase/fcm_service.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signUp({required String email, required String password}) =>
      _client.auth.signUp(email: email, password: password);

  Future<void> signOut() async {
    await FcmService.instance.clearTokenForSignOut();
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());
}
