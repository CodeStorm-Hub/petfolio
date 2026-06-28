import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return ref.read(profileRepositoryProvider).fetchProfile(user.id);
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await ref.read(profileRepositoryProvider).updateProfile(profile);
    });
  }
}
