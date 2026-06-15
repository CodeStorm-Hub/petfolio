import 'package:flutter/widgets.dart';

import '../../../messaging/presentation/screens/chat_screen.dart';

export '../../../messaging/presentation/screens/chat_screen.dart'
    show UnifiedChatScreen;

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.actorPetId,
    required this.otherPetName,
    this.matchId,
    this.otherPetId,
    this.fromMatchInbox = false,
  });

  final String threadId;
  final String actorPetId;
  final String? matchId;
  final String? otherPetId;
  final String otherPetName;
  final bool fromMatchInbox;

  @override
  Widget build(BuildContext context) => UnifiedChatScreen(
        threadId: threadId,
        actorPetId: actorPetId,
        otherDisplayName: otherPetName,
        matchId: matchId,
        otherPetId: otherPetId,
        showPlaydateScheduler: matchId != null,
        fallbackPath: '/matching/inbox',
      );
}
