import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../matching/data/models/chat_message.dart';
import '../../data/repositories/social_dm_repository.dart';

part 'social_dm_controller.g.dart';

// ── Thread resolver ───────────────────────────────────────────────────────────

@riverpod
Future<String> socialDmThread(Ref ref, String otherUserId) async {
  final repo = ref.read(socialDmRepositoryProvider);
  return repo.getOrCreateThread(otherUserId);
}

// ── Conversation stream ───────────────────────────────────────────────────────

@riverpod
class SocialDmConversation extends _$SocialDmConversation {
  late String _threadId;

  @override
  Stream<List<ChatMessage>> build(String threadId) {
    _threadId = threadId;
    final repo = ref.read(socialDmRepositoryProvider);
    return repo.streamMessages(threadId);
  }

  Future<void> send(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final repo = ref.read(socialDmRepositoryProvider);
    await repo.sendMessage(threadId: _threadId, content: trimmed);
  }
}
