import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/models/feed_post.dart';
import '../../data/models/pet_stats.dart';
import '../../data/repositories/social_repository.dart';

/// Fetches posts authored by a specific pet.
final socialProfilePostsProvider =
    FutureProvider.family<List<FeedPost>, String>((ref, petId) async {
  final repo = ref.watch(socialRepositoryProvider);
  final viewerPetId = ref.watch(activePetIdProvider);
  return repo.fetchPostsForPet(petId, activePetId: viewerPetId);
});

final petStatsProvider = FutureProvider.family<PetStats, String>((ref, petId) {
  return ref.read(socialRepositoryProvider).fetchPetStats(petId);
});
