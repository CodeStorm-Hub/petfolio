import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/matches_inbox_screen.dart';

List<RouteBase> matchingRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/matching/inbox',
    builder: (context, state) => const MatchesInboxScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/matching/chat/:threadId',
    builder: (context, state) {
      final query = state.uri.queryParameters;
      final petNameRaw = query['petName'];
      return ChatScreen(
        threadId: state.pathParameters['threadId']!,
        actorPetId: query['actorPetId'] ?? '',
        matchId: query['matchId'],
        otherPetId: query['otherPetId'],
        otherPetName: petNameRaw != null
            ? Uri.decodeComponent(petNameRaw)
            : 'Match',
      );
    },
  ),
];
