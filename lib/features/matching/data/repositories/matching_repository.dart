import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final matchingRepositoryProvider = Provider<MatchingRepository>(
  (ref) => MatchingRepository(Supabase.instance.client),
);

/// Repository for the Playdates (Discovery) feature.
///
/// Write path — optimistic in the UI:
///   1. [DiscoveryNotifier] removes the card from the deck immediately.
///   2. [recordSwipe] is called with `unawaited`; network failures are silent.
///   3. When action == 'match' | 'superPaw', also upserts into `matches`
///      and `chat_threads` — the Realtime channel on `chat_threads` then
///      pushes the new thread to [chatThreadsProvider] automatically.
class MatchingRepository {
  MatchingRepository(this._client);

  final SupabaseClient _client;

  // ── Swipe recording ───────────────────────────────────────────────────────

  /// Records a swipe and, for match actions, creates the match + chat thread.
  /// Silently swallows errors (offline; demo pet IDs not in DB).
  Future<void> recordSwipe({
    required String swiperPetId,
    required String swipedPetId,
    required String action,
  }) async {
    try {
      if (_client.auth.currentUser == null) return;

      // Skip demo pets that don't exist in the database.
      if (swipedPetId.startsWith('demo-')) return;

      await _client.from('swipes').upsert(
        {
          'swiper_pet_id': swiperPetId,
          'swiped_pet_id': swipedPetId,
          'action': action,
        },
        onConflict: 'swiper_pet_id, swiped_pet_id',
      );

      if (action == 'match' || action == 'superPaw') {
        await _createMatchAndThread(swiperPetId, swipedPetId);
      }
    } catch (e) {
      debugPrint('[MatchingRepository] recordSwipe failed: $e');
    }
  }

  Future<void> _createMatchAndThread(String petId1, String petId2) async {
    try {
      // Upsert match — idempotent if the user somehow swipes twice.
      final matchRow = await _client.from('matches').upsert(
        {'pet_id_1': petId1, 'pet_id_2': petId2},
        onConflict: 'pet_id_1, pet_id_2',
      ).select('id').single();

      // Upsert chat thread — INSERT triggers Realtime, which pushes the new
      // row to every subscriber of chatThreadsProvider(petId1 or petId2).
      await _client.from('chat_threads').upsert(
        {
          'match_id': matchRow['id'],
          'pet_id_1': petId1,
          'pet_id_2': petId2,
        },
        onConflict: 'match_id',
      );
    } catch (e) {
      debugPrint('[MatchingRepository] _createMatchAndThread failed: $e');
    }
  }

  // ── Realtime stream ───────────────────────────────────────────────────────

  /// Returns a live stream of all rows from `chat_threads`.
  ///
  /// Supabase `.stream()` uses the Realtime engine internally: any INSERT,
  /// UPDATE, or DELETE on `chat_threads` immediately pushes a new list.
  /// The caller filters to the relevant [petId] client-side.
  Stream<List<Map<String, dynamic>>> chatThreadStream() {
    return _client
        .from('chat_threads')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }
}
