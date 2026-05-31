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
    DateTime? cursorCreatedAt,
    String? cursorPetId,
    List<String>? speciesFilters,
    int? minAgeYears,
    int? maxAgeYears,
  }) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final raw = await _client.rpc(
      'matching_discovery_candidates',
      params: <String, dynamic>{
        'p_actor_pet_id': actorPetId,
        'p_radius_meters': radiusMeters,
        'p_limit': limit,
        'p_cursor_created_at': cursorCreatedAt?.toUtc().toIso8601String(),
        'p_cursor_pet_id': cursorPetId,
        'p_species': (speciesFilters != null && speciesFilters.isNotEmpty)
            ? speciesFilters
            : null,
        'p_min_age_years': minAgeYears,
        'p_max_age_years': maxAgeYears,
      },
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
        'action': action.dbValue,
      },
      onConflict: 'actor_id,target_id',
    );
  }

  Future<List<PetMutualMatch>> fetchMatchesForPet(String petId) async {
    final rows = await _client
        .from('matches')
        .select()
        .or('pet_a_id.eq.$petId,pet_b_id.eq.$petId')
        .order('created_at', ascending: false)
        .limit(100);

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

    final raw = await _client.rpc(
      'get_match_inbox',
      params: {'p_actor_pet_id': actorPetId},
    );
    if (raw == null) {
      return const MatchInboxSnapshot(newMatches: [], conversations: []);
    }

    final list = raw as List;
    final items = <MatchInboxItem>[];
    for (final row in list) {
      final map = Map<String, dynamic>.from(row as Map);
      final matchedAtRaw = map['matched_at'] as String?;
      if (matchedAtRaw == null) continue;
      final matchedAt = DateTime.tryParse(matchedAtRaw);
      if (matchedAt == null) continue;
      final lastAtRaw = map['last_message_at'] as String?;
      items.add(
        MatchInboxItem(
          matchId: map['match_id'] as String,
          otherPetId: map['other_pet_id'] as String,
          otherPetName: map['other_pet_name'] as String? ?? 'Pet',
          otherPetAvatarUrl: map['other_pet_avatar_url'] as String?,
          otherPetBreed: map['other_pet_breed'] as String?,
          matchedAt: matchedAt,
          threadId: map['thread_id'] as String?,
          lastMessageAt: lastAtRaw != null ? DateTime.tryParse(lastAtRaw) : null,
          lastMessagePreview: map['last_message_preview'] as String?,
        ),
      );
    }

    final newMatches = <MatchInboxItem>[];
    final conversations = <MatchInboxItem>[];
    for (final item in items) {
      if (item.isNewMatch) {
        newMatches.add(item);
      } else {
        conversations.add(item);
      }
    }

    newMatches.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
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

  Future<List<ChatMessage>> fetchMessages(
    String threadId, {
    int limit = 50,
    DateTime? beforeCreatedAt,
  }) async {
    var builder = _client
        .from('chat_messages')
        .select()
        .eq('thread_id', threadId);

    if (beforeCreatedAt != null) {
      builder = builder.lt(
        'created_at',
        beforeCreatedAt.toUtc().toIso8601String(),
      );
    }

    final rows = await builder
        .order('created_at', ascending: false)
        .limit(limit);

    final messages = (rows as List)
        .map((row) => ChatMessage.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
    return messages.reversed.toList(growable: false);
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
