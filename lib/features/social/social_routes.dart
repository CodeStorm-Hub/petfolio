import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/transitions.dart';
import '../communities/data/models/community.dart';
import '../communities/presentation/screens/community_detail_screen.dart';
import 'data/models/feed_post.dart';
import 'presentation/screens/create_post_screen.dart';
import 'presentation/screens/create_story_screen.dart';
import 'presentation/screens/notifications_screen.dart';
import 'presentation/screens/post_detail_screen.dart';
import 'presentation/screens/social_profile_screen.dart';

List<RouteBase> socialRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/create-post',
    pageBuilder: (context, state) => modalPage(
      key: state.pageKey,
      child: const CreatePostScreen(),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/create-story',
    pageBuilder: (context, state) => modalPage(
      key: state.pageKey,
      child: const CreateStoryScreen(),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/post/:postId',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: PostDetailScreen(
        postId: state.pathParameters['postId']!,
        post: state.extra as FeedPost?,
        autofocusComment: state.uri.queryParameters['focus'] == 'true',
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/notifications',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: const NotificationsScreen(),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/profile/:petId',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: SocialProfileScreen(
        petId: state.pathParameters['petId']!,
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/communities/:communityId',
    pageBuilder: (context, state) {
      final extra = state.extra;
      return pushPage(
        key: state.pageKey,
        child: extra is Community
            ? CommunityDetailScreen(community: extra)
            : const Scaffold(body: Center(child: Text('Community not found'))),
      );
    },
  ),
];
