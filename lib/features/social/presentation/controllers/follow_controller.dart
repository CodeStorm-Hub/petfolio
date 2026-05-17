import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../data/repositories/social_repository.dart';
import 'social_profile_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Provides the follow status (bool) for the given [petId].
///
/// `true`  = the active pet IS following [petId].
/// `false` = the active pet is NOT following [petId].
///
/// Auto-disposes when the SocialProfileScreen is closed.
final followStatusProvider =
    AsyncNotifierProvider.family<FollowNotifier, bool, String>(
  FollowNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the follow/unfollow toggle for a given target pet ([arg] = petId).
///
/// Optimistic UI pattern:
///   1. Flip the local boolean immediately — button changes on next frame.
///   2. Await the Supabase write. On error, flip back.
///   3. On success, invalidate [petStatsProvider] so follower count refreshes.
class FollowNotifier extends AsyncNotifier<bool> {
  FollowNotifier(this.arg);
  final String arg;

  @override
  Future<bool> build() async {
    final activePet = ref.read(activePetControllerProvider);
    if (activePet == null) return false;

    // Do not show a follow state for your own pet's profile.
    if (activePet.id == arg) return false;

    return _repo.isFollowing(
      followerPetId: activePet.id,
      followingPetId: arg,
    );
  }

  SocialRepository get _repo => ref.read(socialRepositoryProvider);

  // ── Public action ─────────────────────────────────────────────────────────

  /// Toggles follow/unfollow with optimistic UI update.
  Future<void> toggle() async {
    final activePet = ref.read(activePetControllerProvider);
    if (activePet == null) return;

    final currentlyFollowing = state.value ?? false;
    final nowFollowing = !currentlyFollowing;

    // 1. Optimistic flip — button updates instantly.
    state = AsyncData(nowFollowing);

    try {
      // 2. Background write.
      if (nowFollowing) {
        await _repo.followPet(
          followerPetId: activePet.id,
          followingPetId: arg,
        );
      } else {
        await _repo.unfollowPet(
          followerPetId: activePet.id,
          followingPetId: arg,
        );
      }

      // 3. Refresh the profile stats so the follower count updates.
      ref.invalidate(petStatsProvider(arg));
    } catch (_) {
      // 4. Rollback on failure.
      state = AsyncData(currentlyFollowing);
    }
  }
}
