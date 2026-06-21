import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../matching/data/models/chat_message.dart';
import '../../../matching/presentation/controllers/chat_conversation_controller.dart';
import '../../../matching/presentation/matching_navigation.dart';
import '../../../matching/presentation/widgets/playdate_scheduler_sheet.dart';
import '../../../pet_profile/presentation/widgets/pet_switcher_sheet.dart';

// ─── Chat item hierarchy ──────────────────────────────────────────────────────

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

// ─── Screen ───────────────────────────────────────────────────────────────────

class UnifiedChatScreen extends ConsumerStatefulWidget {
  const UnifiedChatScreen({
    super.key,
    required this.threadId,
    required this.actorPetId,
    required this.otherDisplayName,
    this.matchId,
    this.otherPetId,
    this.showPlaydateScheduler = false,
    this.fallbackPath,
  });

  final String threadId;
  final String actorPetId;
  final String otherDisplayName;
  final String? matchId;
  final String? otherPetId;
  final bool showPlaydateScheduler;
  final String? fallbackPath;

  @override
  ConsumerState<UnifiedChatScreen> createState() => _UnifiedChatScreenState();
}

class _UnifiedChatScreenState extends ConsumerState<UnifiedChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  ChatConversationArgs get _args => (
        threadId: widget.threadId,
        matchId: widget.matchId,
        actorPetId: widget.actorPetId,
        otherPetId: widget.otherPetId,
      );

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(chatConversationControllerProvider(_args).notifier)
          .loadOlderMessages();
    }
  }

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
      await ref
          .read(chatConversationControllerProvider(_args).notifier)
          .send(text);
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

  void _handleBack() {
    if (widget.fallbackPath != null) {
      popOrGo(context, widget.fallbackPath!);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final messagesAsync = ref.watch(chatConversationControllerProvider(_args));
    final myUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              eyebrow: widget.showPlaydateScheduler ? 'Match · Chat' : 'Messages',
              onOpenSwitcher: () => PetSwitcherSheet.show(context),
              onBack: _handleBack,
              dense: true,
              actions: [
                if (widget.showPlaydateScheduler && widget.matchId != null)
                  AppHeaderAction(
                    tooltip: 'Plan playdate',
                    icon: Icons.event_available_outlined,
                    onTap: () => PlaydateSchedulerSheet.show(
                      context,
                      args: _args,
                      matchId: widget.matchId!,
                      actorPetId: widget.actorPetId,
                      otherPetName: widget.otherDisplayName,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Text(
                    widget.otherDisplayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: messagesAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: TailWagLoader()),
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
                        onPressed: () => ref
                            .invalidate(chatConversationControllerProvider(_args)),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Send ${widget.otherDisplayName} a message to start the conversation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 1.45, color: pt.ink500),
                        ),
                      ),
                    );
                  }
                  final notifier = ref
                      .read(chatConversationControllerProvider(_args).notifier);
                  final hasMore = notifier.hasMore;
                  final items = _buildChatItems(messages);
                  final n = items.length;
                  final totalCount = n + (hasMore ? 1 : 0);

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: totalCount,
                    itemBuilder: (context, index) {
                      if (hasMore && index == totalCount - 1) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2),
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
            _TypingIndicator(args: _args, otherName: widget.otherDisplayName),
            _Composer(
              args: _args,
              controller: _textController,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  static List<_ChatItem> _buildChatItems(List<ChatMessage> messages) {
    final items = <_ChatItem>[];
    DateTime? lastDate;
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final msgLocal = msg.createdAt.toLocal();
      if (lastDate == null || !_isSameDay(lastDate, msgLocal)) {
        items.add(_DateSeparatorItem(msgLocal));
        lastDate = msgLocal;
      }
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      final isLastInGroup = next == null ||
          next.senderId != msg.senderId ||
          next.createdAt.difference(msg.createdAt).inSeconds > 60;
      items.add(_MessageItem(msg, showTime: isLastInGroup));
    }
    return items;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Date separator ───────────────────────────────────────────────────────────

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
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
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
                  letterSpacing: 0.5),
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

// ─── Message bubble ───────────────────────────────────────────────────────────

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
            constraints:
                BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              style: TextStyle(fontSize: 15, height: 1.4, color: fg),
            ),
          ),
          if (showTime) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(fontSize: 11, color: pt.ink300),
                  ),
                  if (isMine && message.isRead) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.done_all_rounded, size: 13, color: pt.ink300),
                  ],
                ],
              ),
            ),
          ] else
            const SizedBox(height: 2),
        ],
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour;
  final m = local.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour12 = h % 12 == 0 ? 12 : h % 12;
  return '$hour12:$m $period';
}

// ─── Composer ─────────────────────────────────────────────────────────────────

class _Composer extends ConsumerWidget {
  const _Composer({
    required this.args,
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final ChatConversationArgs args;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        horizontal: 18, vertical: 12),
                  ),
                  onChanged: (_) => ref
                      .read(chatConversationControllerProvider(args).notifier)
                      .broadcastTyping(),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey<String>('chat_send_button'),
                tooltip: 'Send message',
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
                            strokeWidth: 2, color: Colors.white),
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

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends ConsumerWidget {
  const _TypingIndicator({required this.args, required this.otherName});
  final ChatConversationArgs args;
  final String otherName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTyping = ref.watch(
      chatTypingStateProvider.select((m) => m[args.threadId] ?? false),
    );
    if (!isTyping) return const SizedBox.shrink();
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          _DotDotDot(color: pt.ink300),
          const SizedBox(width: 8),
          Text('$otherName is typing…',
              style: TextStyle(fontSize: 12, color: pt.ink300)),
        ],
      ),
    );
  }
}

class _DotDotDot extends StatefulWidget {
  const _DotDotDot({required this.color});
  final Color color;

  @override
  State<_DotDotDot> createState() => _DotDotDotState();
}

class _DotDotDotState extends State<_DotDotDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (((_ctrl.value * 3) - i) % 3 + 3) % 3;
          final opacity =
              phase < 1 ? phase : phase < 2 ? 1.0 : 3 - phase;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: opacity.clamp(0.2, 1.0)),
              ),
            ),
          );
        }),
      ),
    );
  }
}
