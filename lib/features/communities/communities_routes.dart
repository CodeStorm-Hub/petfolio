import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/models/community.dart';
import 'presentation/screens/communities_screen.dart';
import 'presentation/screens/community_detail_screen.dart';

List<RouteBase> communitiesRoutes(GlobalKey<NavigatorState> rootKey) => [
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/social/communities',
        builder: (context, state) => const CommunitiesScreen(),
        routes: [
          GoRoute(
            parentNavigatorKey: rootKey,
            path: ':communityId',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is Community) {
                return CommunityDetailScreen(community: extra);
              }
              return const Scaffold(
                body: Center(child: Text('Community not found')),
              );
            },
          ),
        ],
      ),
    ];
