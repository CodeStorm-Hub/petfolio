import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/pf_page_transitions.dart';
import '../communities/data/models/community.dart';
import '../communities/presentation/screens/community_detail_screen.dart';
import 'data/models/feed_post.dart';
import 'presentation/screens/create_content_screen.dart';
import 'presentation/screens/hashtag_screen.dart';
import 'presentation/screens/hashtag_search_screen.dart';
import 'presentation/screens/post_detail_screen.dart';
import 'presentation/screens/saved_posts_screen.dart';
import 'presentation/screens/social_dm_screen.dart';
import 'presentation/screens/social_profile_screen.dart';

List<RouteBase> socialRoutes(GlobalKey<NavigatorState> rootKey) => [
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/create-post',
    pageBuilder: (context, state) {
      final mode = state.uri.queryParameters['mode'] == 'story'
          ? ContentMode.story
          : ContentMode.post;
      return pfFadeThroughPage(
        state: state,
        child: CreateContentScreen(initialMode: mode),
      );
    },
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/post/:postId',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: PostDetailScreen(
        postId: state.pathParameters['postId']!,
        post: state.extra as FeedPost?,
        autofocusComment: state.uri.queryParameters['focus'] == 'true',
      ),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/profile/:petId',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
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
      final child = extra is Community
          ? CommunityDetailScreen(community: extra)
          : const Scaffold(
              body: Center(child: Text('Community not found')),
            );
      return pfSharedAxisPage(state: state, child: child);
    },
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/hashtag/:tag',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: HashtagScreen(tag: state.pathParameters['tag']!),
    ),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/search',
    pageBuilder: (context, state) =>
        pfSharedAxisPage(state: state, child: const HashtagSearchScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/saved',
    pageBuilder: (context, state) =>
        pfSharedAxisPage(state: state, child: const SavedPostsScreen()),
  ),
  GoRoute(
    parentNavigatorKey: rootKey,
    path: '/social/dm/:userId',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: SocialDmScreen(
        otherUserId: state.pathParameters['userId']!,
        otherDisplayName:
            (state.extra as Map<String, String>?)?['displayName'] ?? 'User',
      ),
    ),
  ),
];
