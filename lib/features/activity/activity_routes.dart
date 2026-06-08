import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/activity_screen.dart';

List<GoRoute> activityRoutes(GlobalKey<NavigatorState> rootKey) => [
      GoRoute(
        path: '/activity',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ActivityScreen(),
      ),
    ];
