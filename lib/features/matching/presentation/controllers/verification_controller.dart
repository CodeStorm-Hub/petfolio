import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/verification.dart';
import '../../data/repositories/matching_repository.dart';

final verificationControllerProvider =
    AsyncNotifierProvider<VerificationController, List<Verification>>(
  VerificationController.new,
);

class VerificationController extends AsyncNotifier<List<Verification>> {
  @override
  Future<List<Verification>> build() {
    return ref.read(matchingRepositoryProvider).fetchVerifications();
  }

  Future<void> request(VerificationType type) async {
    await ref.read(matchingRepositoryProvider).requestVerification(type);
    state = AsyncData(
      await ref.read(matchingRepositoryProvider).fetchVerifications(),
    );
  }
}
