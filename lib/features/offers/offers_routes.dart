import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/offers_screen.dart';

List<GoRoute> offersRoutes(GlobalKey<NavigatorState> rootKey) => [
      GoRoute(
        path: '/offers',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const OffersScreen(),
      ),
    ];
