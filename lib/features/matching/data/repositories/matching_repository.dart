import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfolio/core/services/lat_lng.dart';
import 'package:petfolio/core/services/location_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/matching_supabase_data_source.dart';
import '../models/chat_message.dart';
import '../models/matching_discovery_row.dart';
import '../models/pet_mutual_match.dart';
import '../models/pet_swipe.dart';

final matchingRepositoryProvider = Provider<MatchingRepository>(
  (ref) => MatchingRepository(
    ref,
    MatchingSupabaseDataSource(Supabase.instance.client),
  ),
);

class MatchingRepository {
  MatchingRepository(this._ref, this._dataSource);

  final Ref _ref;
  final MatchingSupabaseDataSource _dataSource;

  Future<bool> actorPetHasLocation(String petId) =>
      _dataSource.petHasLocation(petId);

  Future<void> syncActorLocationFromDevice(String activePetId) async {
    final cached = _ref.read(deviceLatLngProvider);
    final LatLng? coords = switch (cached) {
      AsyncData(:final value) => value,
      _ => null,
    };
    try {
      final resolved = coords ??
          await _ref
              .read(deviceLatLngProvider.future)
              .timeout(const Duration(seconds: 4));
      await _dataSource.setPetLocationPoint(
        petId: activePetId,
        latitude: resolved.latitude,
        longitude: resolved.longitude,
      );
    } catch (e, st) {
      debugPrint('[MatchingRepository] setPetLocationPoint failed: $e $st');
    }
  }

  Future<List<MatchingDiscoveryRow>> fetchCandidates({
    required String activePetId,
    int limit = 20,
    int offset = 0,
    double radiusMeters = 80467,
    List<String>? speciesFilters,
    int? minAgeYears,
    int? maxAgeYears,
  }) async {
    final uid = _dataSource.currentUserId;
    if (uid == null) return [];

    final hasStoredLocation = await _dataSource.petHasLocation(activePetId);
    if (!hasStoredLocation) {
      unawaited(syncActorLocationFromDevice(activePetId));
    }

    final species =
        (speciesFilters == null || speciesFilters.isEmpty) ? null : speciesFilters;

    return _dataSource.fetchDiscoveryCandidates(
      actorPetId: activePetId,
      radiusMeters: radiusMeters,
      limit: limit,
      offset: offset,
      speciesFilters: species,
      minAgeYears: minAgeYears,
      maxAgeYears: maxAgeYears,
    );
  }

  Future<void> recordSwipe({
    required String swiperPetId,
    required String swipedPetId,
    required String swipedOwnerUserId,
    required String action,
  }) async {
    try {
      if (_dataSource.currentUserId == null) return;
      if (swipedPetId.startsWith('demo-')) return;

      final swipeAction = switch (action) {
        'pass' => SwipeTableAction.pass,
        'greet' => SwipeTableAction.greet,
        'superPaw' => SwipeTableAction.superPaw,
        _ => SwipeTableAction.like,
      };

      await _dataSource.insertSwipe(
        actorPetId: swiperPetId,
        targetPetId: swipedPetId,
        action: swipeAction,
      );
    } catch (e) {
      debugPrint('[MatchingRepository] recordSwipe failed: $e');
    }
  }

  Future<List<PetMutualMatch>> fetchMutualMatches(String petId) =>
      _dataSource.fetchMatchesForPet(petId);

  Future<List<PetSwipe>> fetchSwipesByActor(String actorPetId) =>
      _dataSource.fetchSwipesByActor(actorPetId);

  Future<void> setActivePetLocation({
    required String petId,
    required double latitude,
    required double longitude,
  }) =>
      _dataSource.setPetLocationPoint(
        petId: petId,
        latitude: latitude,
        longitude: longitude,
      );

  Stream<List<Map<String, dynamic>>> chatThreadStream() =>
      _dataSource.chatThreadStream();

  Future<MatchInboxSnapshot> fetchMatchInbox(String activePetId) =>
      _dataSource.fetchMatchInboxSnapshot(activePetId);

  Future<String> ensureChatThreadForMatch({
    required String matchId,
    required String actorPetId,
  }) =>
      _dataSource.ensureChatThreadForMatch(
        matchId: matchId,
        actorPetId: actorPetId,
      );

  Future<List<ChatMessage>> fetchMessages(String threadId) =>
      _dataSource.fetchMessages(threadId);

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String content,
  }) =>
      _dataSource.sendMessage(threadId: threadId, content: content);
}
