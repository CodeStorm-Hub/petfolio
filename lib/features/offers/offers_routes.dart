import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/transitions.dart';
import 'presentation/screens/offers_screen.dart';

List<GoRoute> offersRoutes(GlobalKey<NavigatorState> rootKey) => [
      GoRoute(
        path: '/offers',
        parentNavigatorKey: rootKey,
        pageBuilder: (_, state) => pushPage(
          key: state.pageKey,
          child: const OffersScreen(),
        ),
      ),
    ];
