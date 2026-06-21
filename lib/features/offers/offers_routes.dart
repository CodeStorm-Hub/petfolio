import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/pf_page_transitions.dart';
import 'presentation/screens/offers_screen.dart';

List<GoRoute> offersRoutes(GlobalKey<NavigatorState> rootKey) => [
      GoRoute(
        path: '/offers',
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) =>
            pfSharedAxisPage(state: state, child: const OffersScreen()),
      ),
    ];
