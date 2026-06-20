import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/tail_wag_loader.dart';
import '../../../messaging/presentation/screens/chat_screen.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../controllers/social_dm_controller.dart';

class SocialDmScreen extends ConsumerWidget {
  const SocialDmScreen({
    super.key,
    required this.otherUserId,
    required this.otherDisplayName,
  });

  final String otherUserId;
  final String otherDisplayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadAsync = ref.watch(socialDmThreadProvider(otherUserId));
    final activePet = ref.watch(activePetControllerProvider);

    return threadAsync.when(
      loading: () => const Scaffold(
        body: Center(child: TailWagLoader()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Could not open conversation: $e')),
      ),
      data: (threadId) => UnifiedChatScreen(
        threadId: threadId,
        actorPetId: activePet?.id ?? '',
        otherDisplayName: otherDisplayName,
        showPlaydateScheduler: false,
      ),
    );
  }
}
