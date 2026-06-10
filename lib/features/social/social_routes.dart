import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    builder: (context, state) => const CreatePostScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/create-story',
    builder: (context, state) => const CreateStoryScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/post/:postId',
    builder: (context, state) => PostDetailScreen(
      postId: state.pathParameters['postId']!,
      post: state.extra as FeedPost?,
      autofocusComment: state.uri.queryParameters['focus'] == 'true',
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/notifications',
    builder: (context, state) => const NotificationsScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/profile/:petId',
    builder: (context, state) => SocialProfileScreen(
      petId: state.pathParameters['petId']!,
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/communities/:communityId',
    builder: (context, state) {
      final extra = state.extra;
      if (extra is Community) return CommunityDetailScreen(community: extra);
      return const Scaffold(body: Center(child: Text('Community not found')));
    },
  ),
];
