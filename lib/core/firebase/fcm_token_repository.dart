import 'package:supabase_flutter/supabase_flutter.dart';

class FcmTokenRepository {
  FcmTokenRepository(this._client);

  final SupabaseClient _client;

  Future<void> upsertToken({
    required String token,
    required String platform,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('user_fcm_devices').upsert(
      {
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'fcm_token',
    );
  }

  Future<void> deleteToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('user_fcm_devices')
        .delete()
        .eq('user_id', userId)
        .eq('fcm_token', token);
  }
}
