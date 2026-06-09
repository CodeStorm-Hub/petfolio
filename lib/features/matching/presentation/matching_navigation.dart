import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_snack_bar.dart';
import '../data/repositories/matching_repository.dart';

Future<void> openMatchChat(
  BuildContext context,
  WidgetRef ref, {
  required String matchId,
  required String actorPetId,
  required String otherPetName,
  String? threadId,
}) async {
  try {
    final repo = ref.read(matchingRepositoryProvider);
    final resolved = threadId ??
        await repo.ensureChatThreadForMatch(
          matchId: matchId,
          actorPetId: actorPetId,
        );
    if (!context.mounted) return;
    final name = Uri.encodeComponent(otherPetName);
    context.push(
      '/matching/chat/$resolved?matchId=$matchId&petName=$name&actorPetId=$actorPetId',
    );
  } catch (e, st) {
    debugPrint('[openMatchChat] ensureChatThreadForMatch failed: $e\n$st');
    if (context.mounted) {
      AppSnackBar.showError('Could not open chat. Try again.');
    }
  }
}

void openMatchesInbox(BuildContext context) {
  context.go('/matching/inbox');
}

void popOrGo(BuildContext context, String fallbackLocation) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackLocation);
  }
}

/// Opens (or creates) a direct message thread between [actorPetId] and [otherPetId].
/// Safe to call from any widget — handles errors with a snack bar.
Future<void> openDirectChat(
  BuildContext context,
  WidgetRef ref, {
  required String actorPetId,
  required String otherPetId,
  required String otherPetName,
}) async {
  try {
    final threadId = await ref.read(matchingRepositoryProvider).ensureDirectChatThread(
      actorPetId: actorPetId,
      otherPetId: otherPetId,
    );
    if (!context.mounted) return;
    final encodedName = Uri.encodeComponent(otherPetName);
    context.push(
      '/matching/chat/$threadId'
      '?otherPetId=$otherPetId'
      '&petName=$encodedName'
      '&actorPetId=$actorPetId',
    );
  } catch (e, st) {
    debugPrint('[openDirectChat] failed: $e\n$st');
    if (context.mounted) {
      AppSnackBar.showError('Could not open chat. Please try again.');
    }
  }
}
