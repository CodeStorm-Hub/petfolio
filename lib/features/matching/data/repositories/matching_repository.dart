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

  // Cache only confirmed-true results (location set is stable; "no location" can change).
  final Map<String, bool> _petLocationCache = {};

  Future<bool> actorPetHasLocation(String petId) async {
    if (_petLocationCache[petId] == true) return true;
    final hasLoc = await _dataSource.petHasLocation(petId);
    if (hasLoc) _petLocationCache[petId] = true;
    return hasLoc;
  }

  void invalidatePetLocationCache(String petId) {
    _petLocationCache.remove(petId);
  }

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
      _petLocationCache[activePetId] = true;
    } on PostgrestException catch (e) {
      throw DatabaseException.fromPostgrest(e);
    }
  }

  Future<List<MatchingDiscoveryRow>> fetchCandidates({
    required String activePetId,
    int limit = 20,
    DateTime? cursorCreatedAt,
    String? cursorPetId,
    double radiusMeters = 80467,
    List<String>? speciesFilters,
    int? minAgeYears,
    int? maxAgeYears,
  }) async {
    final uid = _dataSource.currentUserId;
    if (uid == null) return [];

    final hasStoredLocation = await actorPetHasLocation(activePetId);
    if (!hasStoredLocation) {
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
      cursorCreatedAt: cursorCreatedAt,
      cursorPetId: cursorPetId,
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
    if (_dataSource.currentUserId == null) return;
    if (swipedPetId.startsWith('demo-')) return;

    final swipeAction = switch (action) {
      'pass' => SwipeTableAction.pass,
      'greet' => SwipeTableAction.greet,
      'superPaw' => SwipeTableAction.superPaw,
      _ => SwipeTableAction.like,
    };

    try {
      await _dataSource.insertSwipe(
        actorPetId: swiperPetId,
        targetPetId: swipedPetId,
        action: swipeAction,
      );
    } catch (e) {
      debugPrint('[MatchingRepository] recordSwipe failed: $e');
      rethrow;
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
  }) async {
    await _dataSource.setPetLocationPoint(
      petId: petId,
      latitude: latitude,
      longitude: longitude,
    );
    _petLocationCache[petId] = true;
  }

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

  Future<List<ChatMessage>> fetchMessages(
    String threadId, {
    int limit = 50,
    DateTime? beforeCreatedAt,
  }) =>
      _dataSource.fetchMessages(
        threadId,
        limit: limit,
        beforeCreatedAt: beforeCreatedAt,
      );

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String content,
  }) =>
      _dataSource.sendMessage(threadId: threadId, content: content);
}
