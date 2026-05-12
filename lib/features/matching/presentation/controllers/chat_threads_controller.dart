import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_thread.dart';
import '../../data/repositories/matching_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chat-threads Realtime stream
// ─────────────────────────────────────────────────────────────────────────────

/// Live list of chat threads for [petId], powered by Supabase Realtime.
///
/// [MatchingRepository.chatThreadStream] subscribes to the `chat_threads`
/// table via `.stream()`.  When [DiscoveryNotifier.swipe] records a `match`
/// or `superPaw`, [_createMatchAndThread] INSERTs into `chat_threads` and
/// Realtime immediately pushes the new row here — no manual refresh needed.
///
/// Filtering is done client-side: only rows where pet_id_1 == petId OR
/// pet_id_2 == petId are kept.
final chatThreadsProvider =
    StreamProvider.family<List<ChatThread>, String>((ref, petId) {
  final repo = ref.watch(matchingRepositoryProvider);

  return repo.chatThreadStream().map(
        (rows) => rows
            .where(
              (r) => r['pet_id_1'] == petId || r['pet_id_2'] == petId,
            )
            .map((r) => ChatThread.fromJson(r, myPetId: petId))
            .toList(),
      );
});
