import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/pf_page_transitions.dart';
import 'presentation/screens/breeding_setup_screen.dart';
import 'presentation/screens/chat_screen.dart';
import 'presentation/screens/verification_center_screen.dart';

List<RouteBase> matchingRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/matching/breeding-setup',
    pageBuilder: (context, state) =>
        pfSharedAxisPage(state: state, child: const BreedingSetupScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/matching/verification',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: const VerificationCenterScreen(),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/matching/chat/:threadId',
    pageBuilder: (context, state) {
      final query = state.uri.queryParameters;
      final petNameRaw = query['petName'];
      return pfSharedAxisPage(
        state: state,
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
