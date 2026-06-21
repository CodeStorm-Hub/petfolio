import 'package:go_router/go_router.dart';

import '../../core/navigation/pf_page_transitions.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/registration_screen.dart';

List<RouteBase> authRoutes() => [
  GoRoute(
    path: '/login',
    pageBuilder: (context, state) => pfFadeThroughPage(
      state: state,
      child: const LoginScreen(),
    ),
  ),
  GoRoute(
    path: '/register',
    pageBuilder: (context, state) => pfSharedAxisPage(
      state: state,
      child: const RegistrationScreen(),
    ),
  ),
];
