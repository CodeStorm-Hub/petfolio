import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/matching_supabase_data_source.dart';
import '../../data/repositories/matching_repository.dart';

final matchesInboxControllerProvider =
    AsyncNotifierProvider.family<MatchesInboxController, MatchInboxSnapshot, String>(
  MatchesInboxController.new,
);

class MatchesInboxController extends AsyncNotifier<MatchInboxSnapshot> {
  MatchesInboxController(this.arg);
  final String arg;

  @override
  Future<MatchInboxSnapshot> build() async {
    final repo = ref.watch(matchingRepositoryProvider);
    return repo.fetchMatchInbox(arg);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
