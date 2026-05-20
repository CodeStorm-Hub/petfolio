import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/post_report.dart';
import '../../data/repositories/admin_repository.dart';

final moderationProvider =
    AsyncNotifierProvider<ModerationNotifier, List<PostReport>>(
  ModerationNotifier.new,
);

class ModerationNotifier extends AsyncNotifier<List<PostReport>> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  Future<List<PostReport>> build() => _repo.fetchPendingReports();

  Future<void> resolve(
    String reportId, {
    required bool dismiss,
    required bool hidePost,
  }) async {
    await _repo.resolveReport(reportId, dismiss: dismiss, hidePost: hidePost);
    state = AsyncData(
      state.requireValue.where((r) => r.id != reportId).toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.fetchPendingReports);
  }
}
