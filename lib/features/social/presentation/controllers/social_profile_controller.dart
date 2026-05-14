import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/feed_post.dart';
import '../../data/models/pet_stats.dart';
import '../../data/repositories/social_repository.dart';

/// Fetches posts authored by a specific pet.
final socialProfilePostsProvider =
    FutureProvider.family<List<FeedPost>, String>((ref, petId) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.fetchPostsForPet(petId, activePetId: petId);
});

final petStatsProvider = FutureProvider.family<PetStats, String>((ref, petId) {
  return ref.read(socialRepositoryProvider).fetchPetStats(petId);
});
