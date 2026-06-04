import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/chat_message.dart';
import '../../../pet_profile/presentation/widgets/pet_switcher_sheet.dart';
import '../controllers/chat_conversation_controller.dart';
import '../matching_navigation.dart';

// ---------------------------------------------------------------------------
// Chat item hierarchy for date-grouped rendering (L-2)
// ---------------------------------------------------------------------------

sealed class _ChatItem {
  const _ChatItem();
}

class _MessageItem extends _ChatItem {
  const _MessageItem(this.message, {this.showTime = false});
  final ChatMessage message;
  final bool showTime;
}

class _DateSeparatorItem extends _ChatItem {
  const _DateSeparatorItem(this.date);
  final DateTime date;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.actorPetId,
    this.matchId,
    this.otherPetId,
    required this.otherPetName,
  });

  final String threadId;
  final String actorPetId;
  final String? matchId;
  final String? otherPetId; // non-null for social DMs, null for match chats
  final String otherPetName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Guard: controller may have no attached ScrollPosition before the
    // ListView is built or after dispose.
    if (!_scrollController.hasClients) return;
    // reverse: true means position 0 is the bottom; maxScrollExtent is the top.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(chatConversationControllerProvider(_args).notifier)
          .loadOlderMessages();
    }
  }

  ChatConversationArgs get _args => (
        threadId: widget.threadId,
        matchId: widget.matchId,
        actorPetId: widget.actorPetId,
        otherPetId: widget.otherPetId,
      );

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatConversationControllerProvider(_args).notifier).send(text);
      _textController.clear();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      // M-2: surface send failures to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message failed to send. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final messagesAsync = ref.watch(chatConversationControllerProvider(_args));
    final myUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              eyebrow: widget.otherPetId != null ? 'Social · Chat' : 'Match · Chat',
              onOpenSwitcher: () => PetSwitcherSheet.show(context),
              onBack: () => popOrGo(context, '/matching/inbox'),
              dense: true,
              actions: const [],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.otherPetName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            Expanded(
              child: messagesAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load messages',
                        style: TextStyle(fontSize: 15, color: pt.ink500),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(
                          chatConversationControllerProvider(_args),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    final emptyHint = widget.otherPetId != null
                        ? 'Send ${widget.otherPetName} a message to start the conversation.'
                        : 'You matched with ${widget.otherPetName}. Break the ice with a friendly hello.';
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          emptyHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: pt.ink500,
                          ),
                        ),
                      ),
                    );
                  }

                  final notifier = ref.read(
                    chatConversationControllerProvider(_args).notifier,
                  );
                  final hasMore = notifier.hasMore;
                  final items = _buildChatItems(messages);
                  final n = items.length;
                  // +1 slot at the top (index n in reverse) for the load-more indicator.
                  final totalCount = n + (hasMore ? 1 : 0);

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      // The oldest-messages slot sits at the visual top (largest index).
                      if (hasMore && index == totalCount - 1) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }
                      final item = items[n - 1 - index];
                      return switch (item) {
                        _MessageItem(:final message, :final showTime) =>
                          _MessageBubble(
                            message: message,
                            isMine: message.senderId == myUserId,
                            showTime: showTime,
                          ),
                        _DateSeparatorItem(:final date) =>
                          _DateSeparator(date: date),
                      };
                    },
                  );
                },
              ),
            ),
            _Composer(
              controller: _textController,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  // L-2: Build an ascending list of chat items, inserting date separators at
  // day boundaries and showing timestamps only on the last message of each
  // sender burst (same sender, messages within 60 s of each other).
  static List<_ChatItem> _buildChatItems(List<ChatMessage> messages) {
    final items = <_ChatItem>[];
    DateTime? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final msgLocal = msg.createdAt.toLocal();

      // Date separator on day boundary.
      if (lastDate == null || !_isSameDay(lastDate, msgLocal)) {
        items.add(_DateSeparatorItem(msgLocal));
        lastDate = msgLocal;
      }

      // Show timestamp only on the last message of a sender group.
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      final isLastInGroup = next == null
          || next.senderId != msg.senderId
          || next.createdAt.difference(msg.createdAt).inSeconds > 60;

      items.add(_MessageItem(msg, showTime: isLastInGroup));
    }

    return items;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---------------------------------------------------------------------------
// Date separator widget
// ---------------------------------------------------------------------------

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final now = DateTime.now();
    final local = date.toLocal();
    final String label;
    if (_isSameDay(local, now)) {
      label = 'Today';
    } else if (_isSameDay(local, now.subtract(const Duration(days: 1)))) {
      label = 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      label = '${months[local.month - 1]} ${local.day}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: pt.ink300.withAlpha(60), thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: pt.ink300,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(child: Divider(color: pt.ink300.withAlpha(60), thickness: 1)),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour;
  final m = local.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:$m $period';
}

// ---------------------------------------------------------------------------
// Message bubble — timestamp shown only at end of sender group (L-2)
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showTime,
  });
  final ChatMessage message;
  final bool isMine;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final bg = isMine ? AppColors.coral500 : pt.surface2;
    final fg = isMine ? Colors.white : pt.ink500;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: fg,
              ),
            ),
          ),
          if (showTime) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(fontSize: 11, color: pt.ink300),
              ),
            ),
          ] else
            const SizedBox(height: 2),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Composer
// ---------------------------------------------------------------------------

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      color: pt.surface1,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey<String>('chat_message_input'),
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Message…',
                    filled: true,
                    fillColor: pt.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey<String>('chat_send_button'),
                onPressed: sending ? null : onSend,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.coral500,
                  foregroundColor: Colors.white,
                ),
                icon: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
