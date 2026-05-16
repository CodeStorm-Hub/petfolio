import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfolio/core/services/location_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasources/matching_supabase_data_source.dart';
import '../models/discovery_candidate.dart';
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

  Future<List<DiscoveryCandidate>> fetchCandidates({
    required String activePetId,
    int limit = 20,
    int offset = 0,
    double radiusMeters = 80467,
    List<String>? speciesFilters,
    int? minAgeYears,
    int? maxAgeYears,
  }) async {
    if (_dataSource.currentUserId == null) return [];

    final device = _ref.read(deviceLatLngProvider);
    if (device case AsyncData(:final value)) {
      try {
        await _dataSource.setPetLocationPoint(
          petId: activePetId,
          latitude: value.latitude,
          longitude: value.longitude,
        );
      } catch (e, st) {
        debugPrint('[MatchingRepository] setPetLocationPoint failed: $e $st');
      }
    }

    final species =
        (speciesFilters == null || speciesFilters.isEmpty) ? null : speciesFilters;

    final rows = await _dataSource.fetchDiscoveryCandidates(
      actorPetId: activePetId,
      radiusMeters: radiusMeters,
      limit: limit,
      offset: offset,
      speciesFilters: species,
      minAgeYears: minAgeYears,
      maxAgeYears: maxAgeYears,
    );

    return rows.map(_discoveryRowToCandidate).toList(growable: false);
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

  DiscoveryCandidate _discoveryRowToCandidate(MatchingDiscoveryRow r) {
    final owner = r.owner;
    final ownerName =
        (owner?.displayName?.trim().isNotEmpty ?? false)
            ? owner!.displayName!
            : (owner?.username ?? '?');
    final ownerInitial =
        ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?';

    final species = r.species.toLowerCase();
    final (gradient, subject) = _paletteFor(species);

    return DiscoveryCandidate(
      petId: r.id,
      ownerUserId: owner?.id,
      name: r.name,
      age: _ageString(r.dateOfBirth),
      species: species,
      breed: r.breed ?? _defaultBreed(species),
      distance: _distanceLabel(r.distanceMeters),
      ownerInitial: ownerInitial,
      verified: false,
      traits: _traitsFor(species),
      bio: r.bio ?? _defaultBio(species),
      playStyle: _defaultPlayStyle(species),
      energy: _defaultEnergy(species),
      bestWith: _defaultBestWith(species),
      vaccinated: true,
      gradientColors: gradient,
      subjectColor: subject,
      avatarUrl: r.avatarUrl,
    );
  }

  static String _distanceLabel(double? meters) {
    if (meters == null || meters.isNaN) return 'Nearby';
    final mi = meters / 1609.34;
    if (mi <= 0.5) return 'Within 0.5 miles';
    if (mi <= 1) return 'Within 1 mile';
    if (mi <= 2) return 'Within 2 miles';
    if (mi <= 5) return 'Within 5 miles';
    if (mi <= 10) return 'Within 10 miles';
    return 'Over 10 miles';
  }

  static String _ageString(DateTime? dob) {
    if (dob == null) return '';
    final now = DateTime.now();
    final years = now.year -
        dob.year -
        ((now.month < dob.month ||
                (now.month == dob.month && now.day < dob.day))
            ? 1
            : 0);
    if (years < 1) {
      final months = (now.year - dob.year) * 12 + now.month - dob.month;
      return '${months}mo';
    }
    return '${years}yr';
  }

  static (List<Color>, Color) _paletteFor(String species) {
    switch (species) {
      case 'cat':
        return (
          [const Color(0xFFDDD3C3), const Color(0xFFB8A78F), const Color(0xFF7C6750)],
          const Color(0xFF5C4A36),
        );
      case 'rabbit':
        return (
          [const Color(0xFFE3F1E9), const Color(0xFF9CCDB3), const Color(0xFF6BAF92)],
          const Color(0xFF4F8C72),
        );
      default:
        return (
          [const Color(0xFFF4B57A), const Color(0xFFE89669), const Color(0xFFBC6249)],
          const Color(0xFF6B3F2A),
        );
    }
  }

  static String _defaultBreed(String species) => switch (species) {
        'cat' => 'Domestic Shorthair',
        'rabbit' => 'Mixed Breed',
        _ => 'Mixed Breed',
      };

  static String _defaultBio(String species) => switch (species) {
        'cat' => 'Loves sunny windowsills and the occasional treat.',
        'rabbit' => 'Binkies on demand. Very photogenic.',
        _ => 'Always ready for an adventure (and a nap after).',
      };

  static List<String> _traitsFor(String species) => switch (species) {
        'cat' => ['Indoor', 'Treat-motivated', 'Calm energy'],
        'rabbit' => ['Gentle', 'Curious', 'Kid-friendly'],
        _ => ['Friendly', 'Playful', 'Good on lead'],
      };

  static String _defaultPlayStyle(String species) => switch (species) {
        'cat' => 'Wand toys, gentle chase',
        'rabbit' => 'Explore and binky',
        _ => 'Fetch, chase, or parallel walks',
      };

  static String _defaultEnergy(String species) => switch (species) {
        'cat' => 'Low – Medium',
        'rabbit' => 'Medium · bursts of energy',
        _ => 'Medium · 45–60 min daily',
      };

  static String _defaultBestWith(String species) => switch (species) {
        'cat' => 'Other calm cats',
        'rabbit' => 'Calm pets, gentle kids',
        _ => 'Most dogs, supervised with small pets',
      };
}
