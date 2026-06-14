import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/breeding_setup_screen.dart';
import 'presentation/screens/chat_screen.dart';

List<RouteBase> matchingRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/matching/breeding-setup',
    builder: (context, state) => const BreedingSetupScreen(),
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
        fromMatchInbox: query['fromMatch'] == 'true',
      );
    },
  ),
];
