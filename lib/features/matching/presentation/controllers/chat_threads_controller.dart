import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/chat_thread.dart';
import '../../data/repositories/matching_repository.dart';

final chatThreadsProvider =
    StreamProvider.family<List<ChatThread>, String>((ref, petId) {
  final repo = ref.watch(matchingRepositoryProvider);
  final client = Supabase.instance.client;

  return repo.chatThreadStream().asyncMap((rows) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return <ChatThread>[];

    final matchIds = <String>{};
    for (final r in rows) {
      final mid = r['match_request_id'] as String?;
      if (mid != null) matchIds.add(mid);
    }
    if (matchIds.isEmpty) return <ChatThread>[];

    final idList = matchIds.toList();
    final mrRows = await client
        .from('match_requests')
        .select('id')
        .inFilter('id', idList)
        .or('requester_pet_id.eq.$petId,target_pet_id.eq.$petId');

    final allowed =
        (mrRows as List).map((e) => (e as Map)['id'] as String).toSet();

    final out = <ChatThread>[];
    for (final r in rows) {
      final mid = r['match_request_id'] as String?;
      if (mid == null || !allowed.contains(mid)) continue;
      final p1 = r['participant_1_id'] as String?;
      final p2 = r['participant_2_id'] as String?;
      if (p1 == null || p2 == null) continue;
      if (p1 != uid && p2 != uid) continue;
      out.add(
        ChatThread.fromJson(
          Map<String, dynamic>.from(r),
          myUserId: uid,
          activePetId: petId,
        ),
      );
    }
    return out;
  });
});
