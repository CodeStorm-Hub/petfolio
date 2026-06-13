import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/transitions.dart';
import 'presentation/screens/chat_screen.dart';

List<RouteBase> matchingRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/matching/chat/:threadId',
    pageBuilder: (context, state) {
      final query = state.uri.queryParameters;
      final petNameRaw = query['petName'];
      return pushPage(
        key: state.pageKey,
        child: ChatScreen(
          threadId: state.pathParameters['threadId']!,
          actorPetId: query['actorPetId'] ?? '',
          matchId: query['matchId'],
          otherPetId: query['otherPetId'],
          otherPetName: petNameRaw != null
              ? Uri.decodeComponent(petNameRaw)
              : 'Match',
          fromMatchInbox: query['fromMatch'] == 'true',
        ),
      );
    },
  ),
];
