import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:petfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petfolio/features/matching/data/models/discovery_candidate.dart';
import 'package:petfolio/features/matching/data/models/matching_discovery_row.dart';
import 'package:petfolio/features/matching/data/repositories/matching_repository.dart';
import 'package:petfolio/features/matching/presentation/controllers/discovery_candidates_controller.dart';
import 'package:petfolio/features/matching/presentation/controllers/discovery_controller.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/active_pet_controller.dart';

// ── Fake repo ─────────────────────────────────────────────────────────────────

class _FakeMatchingRepository implements MatchingRepository {
  _FakeMatchingRepository({
    List<MatchingDiscoveryRow> candidates = const [],
    bool throwOnSwipe = false,
  })  : _candidates = candidates,
        _throwOnSwipe = throwOnSwipe;

  final List<MatchingDiscoveryRow> _candidates;
  final bool _throwOnSwipe;

  @override
  Future<List<MatchingDiscoveryRow>> fetchCandidates({
    required String activePetId,
    int limit = 20,
    DateTime? cursorCreatedAt,
    String? cursorPetId,
    double radiusMeters = 80467,
    List<String>? speciesFilters,
    int? minAgeYears,
    int? maxAgeYears,
  }) async =>
      _candidates;

  @override
  Future<bool> actorPetHasLocation(String petId) async => true;

  @override
  Future<void> recordSwipe({
    required String swiperPetId,
    required String swipedPetId,
    required String swipedOwnerUserId,
    required String action,
  }) async {
    if (_throwOnSwipe) throw Exception('network error');
  }

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ── Fake candidate ────────────────────────────────────────────────────────────

DiscoveryCandidate _fakeCandidate(String id) => DiscoveryCandidate(
      petId: id,
      name: 'Buddy',
      age: '2yr',
      species: 'dog',
      breed: 'Mixed',
      distance: '1.2 km away',
      ownerInitial: 'A',
      verified: false,
      traits: const [],
      bio: '',
      playStyle: '',
      energy: '',
      bestWith: '',
      vaccinated: false,
      gradientColors: const [Color(0xFFFFFFFF)],
      subjectColor: const Color(0xFF000000),
    );

// ── Helpers ───────────────────────────────────────────────────────────────────

ProviderContainer _container({
  bool isLoggedIn = true,
  String? activePetId = 'pet-1',
  MatchingRepository? repo,
}) =>
    ProviderContainer(
      overrides: [
        isLoggedInProvider.overrideWithValue(isLoggedIn),
        activePetIdProvider.overrideWithValue(activePetId),
        matchingRepositoryProvider
            .overrideWithValue(repo ?? _FakeMatchingRepository()),
      ],
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('DiscoveryCandidatesController', () {
    test('returns empty buffer when user is not logged in', () async {
      final c = _container(isLoggedIn: false);
      addTearDown(c.dispose);

      final buffer =
          await c.read(discoveryCandidatesControllerProvider.future);
      expect(buffer.candidates, isEmpty);
      expect(buffer.mayHaveMore, isFalse);
    });

    test('returns empty buffer when activePetId is null', () async {
      final c = _container(activePetId: null);
      addTearDown(c.dispose);

      final buffer =
          await c.read(discoveryCandidatesControllerProvider.future);
      expect(buffer.candidates, isEmpty);
      expect(buffer.mayHaveMore, isFalse);
    });

    test('returns candidates when logged in with active pet', () async {
      final row = MatchingDiscoveryRow(
        id: 'pet-2',
        ownerId: 'owner-2',
        name: 'Max',
        species: 'dog',
        owner: const MatchingDiscoveryOwner(id: 'owner-2', username: 'alice'),
      );
      final c = _container(repo: _FakeMatchingRepository(candidates: [row]));
      addTearDown(c.dispose);

      final buffer =
          await c.read(discoveryCandidatesControllerProvider.future);
      expect(buffer.candidates, hasLength(1));
      expect(buffer.candidates.first.petId, 'pet-2');
    });
  });

  group('DiscoveryNotifier — swipe error handling', () {
    test('posts to swipeErrorProvider when recordSwipe throws', () async {
      final throwingRepo = _FakeMatchingRepository(throwOnSwipe: true);

      final candidateBuffer = DiscoveryCandidatesBuffer(
        candidates: [_fakeCandidate('pet-2')],
      );

      final c = ProviderContainer(
        overrides: [
          isLoggedInProvider.overrideWithValue(true),
          activePetIdProvider.overrideWithValue('pet-1'),
          matchingRepositoryProvider.overrideWithValue(throwingRepo),
          discoveryCandidatesControllerProvider
              .overrideWith(() => _FakeCandidatesNotifier(candidateBuffer)),
        ],
      );
      addTearDown(c.dispose);

      // Capture any non-null transition — the state clears itself via
      // addPostFrameCallback, so we listen before reading.
      String? captured;
      final sub = c.listen<String?>(
        swipeErrorProvider,
        (_, next) {
          if (next != null) captured = next;
        },
        fireImmediately: false,
      );
      addTearDown(sub.close);

      c.read(discoveryControllerProvider('pet-1'));

      // Ensure the async build() resolves before swipe() reads the buffer.
      await c.read(discoveryCandidatesControllerProvider.future);

      c
          .read(discoveryControllerProvider('pet-1').notifier)
          .swipe(SwipeAction.pass);

      // Yield to microtask queue so the catchError handler fires.
      await Future<void>.microtask(() {});
      await Future<void>.microtask(() {});

      expect(captured, isNotNull);
      expect(captured, contains('swipe'));
    });
  });
}

// ── Fake notifiers ────────────────────────────────────────────────────────────

class _FakeCandidatesNotifier extends DiscoveryCandidatesController {
  _FakeCandidatesNotifier(this._initial);
  final DiscoveryCandidatesBuffer _initial;

  @override
  Future<DiscoveryCandidatesBuffer> build() async => _initial;
}
