import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(Supabase.instance.client),
);

/// Repository for the Social Feed feature.
///
/// Both [toggleLike] and [toggleCandle] **throw** on failure so that
/// [SocialNotifier] can catch the error and roll back the optimistic update.
class SocialRepository {
  SocialRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw Exception('Not authenticated');
    return id;
  }

  // ── Paw likes ─────────────────────────────────────────────────────────────

  Future<void> toggleLike({
    required String postId,
    required String petId,
    required bool liked,
  }) async {
    if (liked) {
      await _client.from('post_likes').upsert(
        {'post_id': postId, 'pet_id': petId, 'user_id': _uid},
        onConflict: 'post_id, pet_id',
      );
    } else {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('pet_id', petId);
    }
  }

  // ── Memorial candles ──────────────────────────────────────────────────────

  Future<void> toggleCandle({
    required String postId,
    required String petId,
    required bool lit,
  }) async {
    if (lit) {
      await _client.from('post_candles').upsert(
        {'post_id': postId, 'pet_id': petId, 'user_id': _uid},
        onConflict: 'post_id, pet_id',
      );
    } else {
      await _client
          .from('post_candles')
          .delete()
          .eq('post_id', postId)
          .eq('pet_id', petId);
    }
  }
}
