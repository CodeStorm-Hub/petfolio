import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/matching_discovery_row.dart';
import '../models/pet_mutual_match.dart';
import '../models/pet_swipe.dart';

class MatchingSupabaseDataSource {
  MatchingSupabaseDataSource(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

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
    return (raw as List)
        .cast<Map<String, dynamic>>()
        .map(MatchingDiscoveryRow.fromJson)
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
    await _client.from('pets').update({
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
    }).eq('id', petId);
  }

  Stream<List<Map<String, dynamic>>> chatThreadStream() {
    return _client
        .from('chat_threads')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }
}
