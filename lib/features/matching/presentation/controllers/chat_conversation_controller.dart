import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _hasMore = true;
  bool _loadingOlder = false;

  String get effectiveThreadId => _resolvedThreadId ?? arg.threadId;
  bool get hasMore => _hasMore;

  @override
  Future<List<ChatMessage>> build() async {
    _hasMore = true;
    _loadingOlder = false;
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

    final initialMessages = await repo.fetchMessages(
      _resolvedThreadId!,
      limit: 50,
    );
    if (initialMessages.length < 50) _hasMore = false;

    final client = Supabase.instance.client;
    final channel = client
        .channel('public:chat_messages:thread:$_resolvedThreadId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: _resolvedThreadId!,
          ),
          callback: (payload) {
            final row = Map<String, dynamic>.from(payload.newRecord);
            final msg = ChatMessage.fromJson(row);
            final current = state.value;
            if (current != null && !current.any((m) => m.id == msg.id)) {
              state = AsyncValue.data([...current, msg]);
            }
          },
        )
        .subscribe();

    ref.onDispose(() {
      unawaited(channel.unsubscribe());
    });

    return initialMessages;
  }

  /// Loads the next page of older messages, prepending them to the current list.
  /// Safe to call from a scroll listener — guards against concurrent calls.
  Future<void> loadOlderMessages() async {
    if (_loadingOlder || !_hasMore) return;
    final current = state.value;
    if (current == null || current.isEmpty) return;

    _loadingOlder = true;
    try {
      final repo = ref.read(matchingRepositoryProvider);
      final oldest = current.first.createdAt;
      final older = await repo.fetchMessages(
        effectiveThreadId,
        limit: 50,
        beforeCreatedAt: oldest,
      );
      if (older.isEmpty || older.length < 50) _hasMore = false;
      if (older.isNotEmpty) {
        final existingIds = current.map((m) => m.id).toSet();
        final newOnes = older.where((m) => !existingIds.contains(m.id)).toList();
        if (newOnes.isNotEmpty) {
          state = AsyncValue.data([...newOnes, ...current]);
        }
      }
    } finally {
      _loadingOlder = false;
    }
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
