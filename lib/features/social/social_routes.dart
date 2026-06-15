import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../communities/data/models/community.dart';
import '../communities/presentation/screens/community_detail_screen.dart';
import 'data/models/feed_post.dart';
import 'presentation/screens/create_content_screen.dart';
import 'presentation/screens/hashtag_screen.dart';
import 'presentation/screens/notifications_screen.dart';
import 'presentation/screens/post_detail_screen.dart';
import 'presentation/screens/saved_posts_screen.dart';
import 'presentation/screens/social_dm_screen.dart';
import 'presentation/screens/social_profile_screen.dart';

List<RouteBase> socialRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/create-post',
    builder: (context, state) {
      final mode = state.uri.queryParameters['mode'] == 'story'
          ? ContentMode.story
          : ContentMode.post;
      return CreateContentScreen(initialMode: mode);
    },
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
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/hashtag/:tag',
    builder: (context, state) =>
        HashtagScreen(tag: state.pathParameters['tag']!),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/saved',
    builder: (context, state) => const SavedPostsScreen(),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/dm/:userId',
    builder: (context, state) => SocialDmScreen(
      otherUserId: state.pathParameters['userId']!,
      otherDisplayName:
          (state.extra as Map<String, String>?)?['displayName'] ?? 'User',
    ),
  ),
];
