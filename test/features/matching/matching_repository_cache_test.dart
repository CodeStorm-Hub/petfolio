import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/features/matching/data/datasources/matching_supabase_data_source.dart';
import 'package:petfolio/features/matching/data/models/pet_swipe.dart';
import 'package:petfolio/features/matching/data/repositories/matching_repository.dart';
import '../../helpers/fake_supabase_client.dart';

class _TrackingDataSource extends MatchingSupabaseDataSource {
  _TrackingDataSource() : super(FakeSupabaseClient());

  int petHasLocationCalls = 0;
  bool hasLocation = false;
  final List<({String actor, String target, SwipeTableAction action})> swipes =
      [];

  @override
  Future<bool> petHasLocation(String petId) async {
    petHasLocationCalls++;
    return hasLocation;
  }

  @override
  String? get currentUserId => 'user-1';

  @override
  Future<void> insertSwipe({
    required String actorPetId,
    required String targetPetId,
    required SwipeTableAction action,
  }) async {
    swipes.add((actor: actorPetId, target: targetPetId, action: action));
  }
}

void main() {
  group('MatchingRepository', () {
    late ProviderContainer container;
    late _TrackingDataSource dataSource;
    late MatchingRepository repository;

    setUp(() {
      dataSource = _TrackingDataSource();
      container = ProviderContainer();
      repository = container.read(
        Provider((ref) => MatchingRepository(ref, dataSource)),
      );
    });

    tearDown(() => container.dispose());

    test('caches positive pet location lookups', () async {
      dataSource.hasLocation = true;

      expect(await repository.actorPetHasLocation('pet-a'), isTrue);
      expect(await repository.actorPetHasLocation('pet-a'), isTrue);
      expect(dataSource.petHasLocationCalls, 1);
    });

    test('does not cache negative pet location lookups', () async {
      dataSource.hasLocation = false;

      expect(await repository.actorPetHasLocation('pet-b'), isFalse);
      expect(await repository.actorPetHasLocation('pet-b'), isFalse);
      expect(dataSource.petHasLocationCalls, 2);
    });

    test('invalidatePetLocationCache forces refetch', () async {
      dataSource.hasLocation = true;
      await repository.actorPetHasLocation('pet-c');
      repository.invalidatePetLocationCache('pet-c');
      await repository.actorPetHasLocation('pet-c');
      expect(dataSource.petHasLocationCalls, 2);
    });

    test('recordSwipe skips demo pets', () async {
      await repository.recordSwipe(
        swiperPetId: 'pet-1',
        swipedPetId: 'demo-card',
        swipedOwnerUserId: 'owner-1',
        action: 'like',
      );
      expect(dataSource.swipes, isEmpty);
    });

    test('recordSwipe maps action strings to SwipeTableAction', () async {
      await repository.recordSwipe(
        swiperPetId: 'pet-1',
        swipedPetId: 'pet-2',
        swipedOwnerUserId: 'owner-2',
        action: 'pass',
      );
      expect(dataSource.swipes.single.action, SwipeTableAction.pass);
    });
  });
}
