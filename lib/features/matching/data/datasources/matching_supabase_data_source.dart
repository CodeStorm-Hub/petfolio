import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../models/matching_discovery_row.dart';
import '../models/match_inbox_item.dart';
import '../models/pet_mutual_match.dart';
import '../models/pet_swipe.dart';

class MatchingSupabaseDataSource {
  MatchingSupabaseDataSource(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<bool> petHasLocation(String petId) async {
    final uid = currentUserId;
    if (uid == null) return false;

    final row = await _client
        .from('pets')
        .select('id')
        .eq('id', petId)
        .eq('owner_id', uid)
        .not('location', 'is', null)
        .maybeSingle();
    return row != null;
  }

  Future<List<MatchingDiscoveryRow>> fetchDiscoveryCandidates({
    required String actorPetId,
    required double radiusMeters,
    int limit = 20,
    int offset = 0,
    List<String>? speciesFilters,
    int? minAgeYears,
    int? maxAgeYears,
  }) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final params = <String, dynamic>{
      'p_actor_pet_id': actorPetId,
      'p_radius_meters': radiusMeters,
      'p_limit': limit,
      'p_offset': offset,
      'p_min_age_years': minAgeYears,
      'p_max_age_years': maxAgeYears,
    };
    if (speciesFilters != null && speciesFilters.isNotEmpty) {
      params['p_species'] = speciesFilters;
    }

    final raw = await _client.rpc(
      'matching_discovery_candidates',
      params: params,
    );
    if (raw == null) return [];
    final list = raw as List;
    return list
        .map(
          (row) => MatchingDiscoveryRow.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<void> insertSwipe({
    required String actorPetId,
    required String targetPetId,
    required SwipeTableAction action,
  }) async {
    await _client.from('swipes').upsert(
      {
        'actor_id': actorPetId,
        'target_id': targetPetId,
        'action': action == SwipeTableAction.like ? 'LIKE' : 'PASS',
      },
      onConflict: 'actor_id,target_id',
    );
  }

  Future<List<PetMutualMatch>> fetchMatchesForPet(String petId) async {
    final rows = await _client
        .from('matches')
        .select()
        .or('pet_a_id.eq.$petId,pet_b_id.eq.$petId')
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(PetMutualMatch.fromJson)
        .toList(growable: false);
  }

  Future<List<PetSwipe>> fetchSwipesByActor(String actorPetId) async {
    final rows = await _client
        .from('swipes')
        .select()
        .eq('actor_id', actorPetId)
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(PetSwipe.fromJson)
        .toList(growable: false);
  }

  Future<void> setPetLocationPoint({
    required String petId,
    required double latitude,
    required double longitude,
  }) async {
    await _client.rpc(
      'set_pet_location_point',
      params: {
        'p_pet_id': petId,
        'p_longitude': longitude,
        'p_latitude': latitude,
      },
    );
  }

  Stream<List<Map<String, dynamic>>> chatThreadStream() {
    return _client
        .from('chat_threads')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> fetchParticipantThreads() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final rows = await _client
        .from('chat_threads')
        .select()
        .or('participant_1_id.eq.$uid,participant_2_id.eq.$uid')
        .order('last_message_at', ascending: false, nullsFirst: false);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, Map<String, dynamic>>> fetchPetsByIds(
    List<String> petIds,
  ) async {
    if (petIds.isEmpty) return {};
    final rows = await _client
        .from('pets')
        .select('id, name, breed, avatar_url, owner_id')
        .inFilter('id', petIds);

    final out = <String, Map<String, dynamic>>{};
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      out[map['id'] as String] = map;
    }
    return out;
  }

  Future<MatchInboxSnapshot> fetchMatchInboxSnapshot(String actorPetId) async {
    final uid = currentUserId;
    if (uid == null) {
      return const MatchInboxSnapshot(newMatches: [], conversations: []);
    }

    final matches = await fetchMatchesForPet(actorPetId);
    if (matches.isEmpty) {
      return const MatchInboxSnapshot(newMatches: [], conversations: []);
    }

    final otherPetIds = <String>[];
    for (final m in matches) {
      otherPetIds.add(m.petAId == actorPetId ? m.petBId : m.petAId);
    }

    final petsById = await fetchPetsByIds(otherPetIds);
    final threadRows = await fetchParticipantThreads();
    final threadsByMatchId = <String, Map<String, dynamic>>{};
    for (final row in threadRows) {
      final mid = row['mutual_match_id'] as String?;
      if (mid != null) threadsByMatchId[mid] = row;
    }

    final threadIdsWithMessages = threadRows
        .where((r) => r['last_message_at'] != null)
        .map((r) => r['id'] as String)
        .toList();

    final previewByThread = await _latestMessagePreviews(threadIdsWithMessages);

    final items = <MatchInboxItem>[];
    for (final match in matches) {
      final otherPetId =
          match.petAId == actorPetId ? match.petBId : match.petAId;
      final pet = petsById[otherPetId];
      final thread = threadsByMatchId[match.id];
      final threadId = thread?['id'] as String?;
      final lastAtRaw = thread?['last_message_at'] as String?;
      final lastAt =
          lastAtRaw != null ? DateTime.tryParse(lastAtRaw) : null;
      final preview =
          threadId != null ? previewByThread[threadId] : null;

      items.add(
        MatchInboxItem(
          matchId: match.id,
          otherPetId: otherPetId,
          otherPetName: pet?['name'] as String? ?? 'Pet',
          otherPetAvatarUrl: pet?['avatar_url'] as String?,
          otherPetBreed: pet?['breed'] as String?,
          matchedAt: match.createdAt,
          threadId: threadId,
          lastMessageAt: lastAt,
          lastMessagePreview: preview,
        ),
      );
    }

    items.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));

    final newMatches = <MatchInboxItem>[];
    final conversations = <MatchInboxItem>[];
    for (final item in items) {
      if (item.isNewMatch) {
        newMatches.add(item);
      } else {
        conversations.add(item);
      }
    }

    conversations.sort((a, b) {
      final at = a.lastMessageAt ?? a.matchedAt;
      final bt = b.lastMessageAt ?? b.matchedAt;
      return bt.compareTo(at);
    });

    return MatchInboxSnapshot(
      newMatches: newMatches,
      conversations: conversations,
    );
  }

  Future<Map<String, String>> _latestMessagePreviews(
    List<String> threadIds,
  ) async {
    if (threadIds.isEmpty) return {};

    final rows = await _client
        .from('chat_messages')
        .select('thread_id, content, created_at')
        .inFilter('thread_id', threadIds)
        .order('created_at', ascending: false);

    final out = <String, String>{};
    for (final row in rows as List) {
      final map = Map<String, dynamic>.from(row as Map);
      final tid = map['thread_id'] as String;
      if (out.containsKey(tid)) continue;
      final content = (map['content'] as String?)?.trim() ?? '';
      if (content.isNotEmpty) out[tid] = content;
    }
    return out;
  }

  Future<String> ensureChatThreadForMatch({
    required String matchId,
    required String actorPetId,
  }) async {
    final raw = await _client.rpc(
      'ensure_chat_thread_for_match',
      params: {
        'p_match_id': matchId,
        'p_actor_pet_id': actorPetId,
      },
    );
    return raw as String;
  }

  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    final rows = await _client
        .from('chat_messages')
        .select()
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);

    return (rows as List)
        .map((row) => ChatMessage.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String content,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Not authenticated');
    }

    final row = await _client
        .from('chat_messages')
        .insert({
          'thread_id': threadId,
          'sender_id': uid,
          'content': content,
        })
        .select()
        .single();

    return ChatMessage.fromJson(Map<String, dynamic>.from(row));
  }
}

class MatchInboxSnapshot {
  const MatchInboxSnapshot({
    required this.newMatches,
    required this.conversations,
  });

  final List<MatchInboxItem> newMatches;
  final List<MatchInboxItem> conversations;
}
