import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/pet_mutual_match.dart';
import '../../data/models/pet_swipe.dart';
import '../../data/repositories/matching_repository.dart';

class LikedPetItem {
  const LikedPetItem({
    required this.petId,
    required this.petName,
    this.avatarUrl,
    this.breed,
    required this.isMutual,
    this.matchId,
    required this.likedAt,
  });

  final String petId;
  final String petName;
  final String? avatarUrl;
  final String? breed;
  final bool isMutual;
  final String? matchId;
  final DateTime likedAt;
}

class MatchLikedSnapshot {
  const MatchLikedSnapshot({required this.mutual, required this.pending});

  final List<LikedPetItem> mutual;
  final List<LikedPetItem> pending;

  bool get isEmpty => mutual.isEmpty && pending.isEmpty;
}

final matchLikedControllerProvider = AsyncNotifierProvider.family<
    MatchLikedController, MatchLikedSnapshot, String>(
  MatchLikedController.new,
);

class MatchLikedController extends AsyncNotifier<MatchLikedSnapshot> {
  MatchLikedController(this.petId);
  final String petId;

  @override
  Future<MatchLikedSnapshot> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    return _load(repo);
  }

  Future<MatchLikedSnapshot> _load(MatchingRepository repo) async {
    final results = await Future.wait([
      repo.fetchSwipesByActor(petId),
      repo.fetchMutualMatches(petId),
    ]);

    final swipes = results[0] as List<PetSwipe>;
    final matches = results[1] as List<PetMutualMatch>;

    final likedSwipes = swipes
        .where((s) =>
            s.action == SwipeTableAction.like ||
            s.action == SwipeTableAction.superPaw)
        .toList();

    final matchMap = <String, String>{};
    for (final m in matches) {
      final otherId = m.petAId == petId ? m.petBId : m.petAId;
      matchMap[otherId] = m.id;
    }

    final allPetIds = <String>{...likedSwipes.map((s) => s.targetId)};
    for (final otherId in matchMap.keys) {
      allPetIds.add(otherId);
    }

    if (allPetIds.isEmpty) {
      return const MatchLikedSnapshot(mutual: [], pending: []);
    }

    final petProfiles = await repo.fetchPetsByIds(allPetIds.toList());

    final mutual = <LikedPetItem>[];
    final pending = <LikedPetItem>[];
    final seenPetIds = <String>{};

    for (final swipe in likedSwipes) {
      final targetId = swipe.targetId;
      seenPetIds.add(targetId);
      final profile = petProfiles[targetId];
      final item = LikedPetItem(
        petId: targetId,
        petName: profile?['name'] as String? ?? 'Pet',
        avatarUrl: profile?['avatar_url'] as String?,
        breed: profile?['breed'] as String?,
        isMutual: matchMap.containsKey(targetId),
        matchId: matchMap[targetId],
        likedAt: swipe.createdAt,
      );
      if (item.isMutual) {
        mutual.add(item);
      } else {
        pending.add(item);
      }
    }

    // Mutual matches with no corresponding outgoing swipe (edge case)
    for (final entry in matchMap.entries) {
      if (!seenPetIds.contains(entry.key)) {
        final profile = petProfiles[entry.key];
        final match = matches.firstWhere((m) => m.id == entry.value);
        mutual.add(LikedPetItem(
          petId: entry.key,
          petName: profile?['name'] as String? ?? 'Pet',
          avatarUrl: profile?['avatar_url'] as String?,
          breed: profile?['breed'] as String?,
          isMutual: true,
          matchId: entry.value,
          likedAt: match.createdAt,
        ));
      }
    }

    mutual.sort((a, b) => b.likedAt.compareTo(a.likedAt));
    pending.sort((a, b) => b.likedAt.compareTo(a.likedAt));

    return MatchLikedSnapshot(mutual: mutual, pending: pending);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
