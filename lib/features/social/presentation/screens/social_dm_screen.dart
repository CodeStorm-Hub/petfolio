import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/tail_wag_loader.dart';
import '../../../matching/data/models/chat_message.dart';
import '../controllers/social_dm_controller.dart';

class SocialDmScreen extends ConsumerStatefulWidget {
  const SocialDmScreen({
    super.key,
    required this.otherUserId,
    required this.otherDisplayName,
  });

  final String otherUserId;
  final String otherDisplayName;

  @override
  ConsumerState<SocialDmScreen> createState() => _SocialDmScreenState();
}

class _SocialDmScreenState extends ConsumerState<SocialDmScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(socialDmThreadProvider(widget.otherUserId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherDisplayName),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: threadAsync.when(
        loading: () => const Center(child: TailWagLoader()),
        error: (e, _) => Center(child: Text('Could not open conversation: $e')),
        data: (threadId) => _Conversation(
          threadId: threadId,
          scrollCtrl: _scrollCtrl,
          textCtrl: _ctrl,
        ),
      ),
    );
  }
}

class _Conversation extends ConsumerWidget {
  const _Conversation({
    required this.threadId,
    required this.scrollCtrl,
    required this.textCtrl,
  });

  final String threadId;
  final ScrollController scrollCtrl;
  final TextEditingController textCtrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(socialDmConversationProvider(threadId));

    return Column(
      children: [
        Expanded(
          child: stream.when(
            loading: () => const Center(child: TailWagLoader()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(
                  child: Text('Send the first message!'),
                );
              }
              return ListView.builder(
                controller: scrollCtrl,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (_, i) => _MessageBubble(message: messages[i]),
              );
            },
          ),
        ),
        _InputBar(threadId: threadId, ctrl: textCtrl),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.senderId ==
        (context.findAncestorWidgetOfExactType<SocialDmScreen>()?.otherUserId ?? '');
    // For DM bubble direction: message.isRead / senderId drive alignment in the
    // matching chat; here we reuse the same visual but need the user's own ID.
    // Since ChatMessage doesn't track "isMine", rely on bubble colour only.
    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : AppColors.poppy,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isMine
                ? Theme.of(context).colorScheme.onSurface
                : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends ConsumerWidget {
  const _InputBar({required this.threadId, required this.ctrl});

  final String threadId;
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message…',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(ref),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded),
              color: AppColors.poppy,
              onPressed: () => _send(ref),
            ),
          ],
        ),
      ),
    );
  }

  void _send(WidgetRef ref) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    ctrl.clear();
    ref
        .read(socialDmConversationProvider(threadId).notifier)
        .send(text);
  }
}
