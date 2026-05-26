import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfolio/core/errors/app_exception.dart';
import 'package:petfolio/core/services/location_providers.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:petfolio/core/domain/controllers/active_pet_controller.dart';
import '../../data/models/discovery_candidate.dart';
import '../../data/models/matching_discovery_row.dart';
import '../../data/repositories/matching_repository.dart';
import 'match_preference_controller.dart';
import 'match_preferences_state.dart';

const int _discoveryPageSize = 20;
const int _discoveryBufferMin = 5;
const Duration _prefsDebounceDuration = Duration(milliseconds: 450);

// One-shot error bus for location-sync failures.  The controller posts here
// when syncActorLocationFromDevice throws; the screen listens and shows a
// snackbar, then the notifier auto-clears via a microtask so the next error
// can fire independently.
final locationSyncErrorProvider =
    NotifierProvider<_LocationSyncErrorNotifier, AppException?>(
  _LocationSyncErrorNotifier.new,
);

class _LocationSyncErrorNotifier extends Notifier<AppException?> {
  @override
  AppException? build() => null;

  void post(AppException e) {
    state = e;
    Future.microtask(() {
      if (ref.mounted) state = null;
    });
  }
}

final discoveryCandidatesControllerProvider =
    AsyncNotifierProvider<DiscoveryCandidatesController, DiscoveryCandidatesBuffer>(
  DiscoveryCandidatesController.new,
);

class DiscoveryCandidatesBuffer {
  const DiscoveryCandidatesBuffer({
    this.candidates = const [],
    this.nextOffset = 0,
    this.mayHaveMore = true,
  });

  final List<DiscoveryCandidate> candidates;
  final int nextOffset;
  final bool mayHaveMore;

  DiscoveryCandidatesBuffer copyWith({
    List<DiscoveryCandidate>? candidates,
    int? nextOffset,
    bool? mayHaveMore,
  }) =>
      DiscoveryCandidatesBuffer(
        candidates: candidates ?? this.candidates,
        nextOffset: nextOffset ?? this.nextOffset,
        mayHaveMore: mayHaveMore ?? this.mayHaveMore,
      );
}

class DiscoveryCandidatesController extends AsyncNotifier<DiscoveryCandidatesBuffer> {
  int _epoch = 0;
  bool _replenishLocked = false;
  Timer? _prefsDebounce;

  @override
  Future<DiscoveryCandidatesBuffer> build() async {
    ref.onDispose(() => _prefsDebounce?.cancel());

    ref.listen<MatchPreferencesState>(
      matchPreferenceControllerProvider,
      (previous, next) {
        if (previous == next) return;
        _prefsDebounce?.cancel();
        _prefsDebounce = Timer(_prefsDebounceDuration, () {
          if (ref.mounted) {
            ref.invalidateSelf();
          }
        });
      },
    );

    final myEpoch = ++_epoch;
    final loggedIn = ref.watch(isLoggedInProvider);
    if (!loggedIn) {
      return const DiscoveryCandidatesBuffer(mayHaveMore: false);
    }

    final petId = ref.watch(activePetIdProvider);
    if (petId == null) {
      return const DiscoveryCandidatesBuffer(
        mayHaveMore: false,
      );
    }

    ref.listen(deviceLatLngProvider, (previous, next) {
      if (previous == next) return;
      if (next case AsyncData()) {
        ref.invalidateSelf();
      }
    });

    final prefs = ref.read(matchPreferenceControllerProvider);
    final repo = ref.read(matchingRepositoryProvider);

    var buffer = await _fetchPage(
      repo: repo,
      petId: petId,
      prefs: prefs,
      offset: 0,
    );
    if (buffer.candidates.isEmpty) {
      final hasLocation = await repo.actorPetHasLocation(petId);
      if (!hasLocation) {
        try {
          await repo.syncActorLocationFromDevice(petId);
        } on AppException catch (e) {
          ref.read(locationSyncErrorProvider.notifier).post(e);
        }
      }
    }
    if (kDebugMode) {
      debugPrint(
        '[DiscoveryCandidates] pet=$petId count=${buffer.candidates.length}',
      );
    }
    if (myEpoch != _epoch) {
      return buffer;
    }

    buffer = await _ensureDepth(
      repo: repo,
      petId: petId,
      prefs: prefs,
      buffer: buffer,
      epoch: myEpoch,
    );

    if (myEpoch == _epoch) {
      unawaited(_replenishIfLow(petId, prefs, myEpoch));
    }
    return buffer;
  }

  DiscoveryCandidatesBuffer? _bufferOrNull() => switch (state) {
        AsyncData(:final value) => value,
        _ => null,
      };

  Future<void> removeFront() async {
    final snap = _bufferOrNull();
    if (snap == null || snap.candidates.isEmpty) return;
    final petId = ref.read(activePetIdProvider);
    final prefs = ref.read(matchPreferenceControllerProvider);
    if (petId == null) return;

    state = AsyncData(
      snap.copyWith(candidates: snap.candidates.skip(1).toList(growable: false)),
    );
    unawaited(_replenishIfLow(petId, prefs, _epoch));
  }

  Future<void> _replenishIfLow(
    String petId,
    MatchPreferencesState prefs,
    int epoch,
  ) async {
    if (_replenishLocked) {
      Future.microtask(() => unawaited(_replenishIfLow(petId, prefs, epoch)));
      return;
    }
    _replenishLocked = true;
    final repo = ref.read(matchingRepositoryProvider);
    try {
      for (;;) {
        if (epoch != _epoch) return;
        final snap = _bufferOrNull();
        if (snap == null) return;
        if (snap.candidates.length >= _discoveryBufferMin) return;
        if (!snap.mayHaveMore) return;

        DiscoveryCandidatesBuffer more;
        try {
          more = await _fetchPage(
            repo: repo,
            petId: petId,
            prefs: prefs,
            offset: snap.nextOffset,
          );
        } catch (_) {
          if (epoch == _epoch) {
            final cur = _bufferOrNull();
            if (cur != null) {
              state = AsyncData(cur.copyWith(mayHaveMore: false));
            }
          }
          return;
        }

        if (epoch != _epoch) return;

        final current = _bufferOrNull();
        if (current == null) return;

        final existing = current.candidates.map((e) => e.petId).toSet();
        final newOnes = more.candidates.where((c) => !existing.contains(c.petId)).toList();
        if (newOnes.isEmpty) {
          state = AsyncData(current.copyWith(mayHaveMore: false));
          return;
        }

        final merged = [...current.candidates, ...newOnes];

        state = AsyncData(
          DiscoveryCandidatesBuffer(
            candidates: merged,
            nextOffset: more.nextOffset,
            mayHaveMore: more.candidates.length >= _discoveryPageSize,
          ),
        );
      }
    } finally {
      _replenishLocked = false;
    }
  }

  Future<DiscoveryCandidatesBuffer> _ensureDepth({
    required MatchingRepository repo,
    required String petId,
    required MatchPreferencesState prefs,
    required DiscoveryCandidatesBuffer buffer,
    required int epoch,
  }) async {
    var out = buffer;
    while (epoch == _epoch &&
        out.candidates.length < _discoveryBufferMin &&
        out.mayHaveMore) {
      final more = await _fetchPage(
        repo: repo,
        petId: petId,
        prefs: prefs,
        offset: out.nextOffset,
      );
      if (epoch != _epoch) return out;
      final existing = out.candidates.map((e) => e.petId).toSet();
      final newOnes = more.candidates.where((c) => !existing.contains(c.petId)).toList();
      if (newOnes.isEmpty) {
        out = out.copyWith(mayHaveMore: false);
        break;
      }
      out = DiscoveryCandidatesBuffer(
        candidates: [...out.candidates, ...newOnes],
        nextOffset: more.nextOffset,
        mayHaveMore: more.candidates.length >= _discoveryPageSize,
      );
    }
    return out;
  }

  Future<DiscoveryCandidatesBuffer> _fetchPage({
    required MatchingRepository repo,
    required String petId,
    required MatchPreferencesState prefs,
    required int offset,
  }) async {
    final rows = await repo.fetchCandidates(
      activePetId: petId,
      limit: _discoveryPageSize,
      offset: offset,
      radiusMeters: prefs.maxDistanceMeters,
      speciesFilters: prefs.selectedSpecies,
      minAgeYears: prefs.ageMinYears,
      maxAgeYears: prefs.ageMaxYears,
    );
    final candidates = rows.map(_discoveryRowToCandidate).toList(growable: false);
    return DiscoveryCandidatesBuffer(
      candidates: candidates,
      nextOffset: offset + rows.length,
      mayHaveMore: rows.length >= _discoveryPageSize,
    );
  }

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
