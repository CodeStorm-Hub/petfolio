import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/discovery_candidate.dart';
import '../../data/repositories/matching_repository.dart';
import 'match_preference_controller.dart';
import 'match_preferences_state.dart';

const int _discoveryPageSize = 20;
const int _discoveryBufferMin = 5;

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

  @override
  Future<DiscoveryCandidatesBuffer> build() async {
    final myEpoch = ++_epoch;
    final petId = ref.watch(activePetIdProvider);
    ref.watch(matchPreferenceControllerProvider);
    if (petId == null) {
      return const DiscoveryCandidatesBuffer(
        mayHaveMore: false,
      );
    }

    final prefs = ref.read(matchPreferenceControllerProvider);
    final repo = ref.read(matchingRepositoryProvider);

    var buffer = await _fetchPage(
      repo: repo,
      petId: petId,
      prefs: prefs,
      offset: 0,
    );
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
    return DiscoveryCandidatesBuffer(
      candidates: rows,
      nextOffset: offset + rows.length,
      mayHaveMore: rows.length >= _discoveryPageSize,
    );
  }
}
