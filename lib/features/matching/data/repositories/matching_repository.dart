import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfolio/core/errors/app_exception.dart';
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

  /// Syncs the device's current GPS position to the pet's `location` column.
  ///
  /// Always acquires a fresh fix directly from [LocationService] — bypasses
  /// the cached [deviceLatLngProvider] to avoid stale-future and double-timeout
  /// issues (the provider's 4 s outer wrapper fires before the GPS's 12 s limit
  /// on devices that need more time, particularly emulators).
  ///
  /// Throws [ValidationException] when location permission is denied or the
  /// GPS read fails, and [DatabaseException] on a Supabase write failure.
  Future<void> syncActorLocationFromDevice(String activePetId) async {
    final coords =
        await _ref.read(locationServiceProvider).acquireCurrentLatLng();

    try {
      await _dataSource.setPetLocationPoint(
        petId: activePetId,
        latitude: coords.latitude,
        longitude: coords.longitude,
      );
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
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
      // Best-effort background sync — errors are surfaced by the controller
      // layer (DiscoveryCandidatesController) which awaits a separate call.
      unawaited(
        syncActorLocationFromDevice(activePetId).catchError((_) {}),
      );
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
