import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/chat_message.dart';
import '../../data/repositories/matching_repository.dart';
import 'matches_inbox_controller.dart';

typedef ChatConversationArgs = ({
  String threadId,
  String? matchId,
  String actorPetId,
});

final chatConversationControllerProvider = AsyncNotifierProvider.family<
    ChatConversationController,
    List<ChatMessage>,
    ChatConversationArgs>(ChatConversationController.new);

class ChatConversationController extends AsyncNotifier<List<ChatMessage>> {
  ChatConversationController(this.arg);
  final ChatConversationArgs arg;

  String? _resolvedThreadId;

  String get effectiveThreadId => _resolvedThreadId ?? arg.threadId;

  @override
  Future<List<ChatMessage>> build() async {
    final repo = ref.watch(matchingRepositoryProvider);

    if (_resolvedThreadId == null) {
      var threadId = arg.threadId;
      if (threadId.isEmpty &&
          arg.matchId != null &&
          arg.matchId!.isNotEmpty) {
        threadId = await repo.ensureChatThreadForMatch(
          matchId: arg.matchId!,
          actorPetId: arg.actorPetId,
        );
      }
      _resolvedThreadId = threadId;
    }

    return repo.fetchMessages(_resolvedThreadId!);
  }

  Future<void> send(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final repo = ref.read(matchingRepositoryProvider);
    final threadId = effectiveThreadId;

    final previous = state.asData?.value ?? const <ChatMessage>[];
    final sent = await repo.sendMessage(threadId: threadId, content: trimmed);
    state = AsyncData([...previous, sent]);
    ref.invalidate(matchesInboxControllerProvider(arg.actorPetId));
  }
}
