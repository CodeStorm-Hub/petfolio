import 'package:go_router/go_router.dart';

import '../../core/router/transitions.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/registration_screen.dart';

List<RouteBase> authRoutes() => [
  GoRoute(
    path: '/login',
    pageBuilder: (context, state) => modalPage(
      key: state.pageKey,
      child: const LoginScreen(),
    ),
  ),
  GoRoute(
    path: '/register',
    pageBuilder: (context, state) => pushPage(
      key: state.pageKey,
      child: const RegistrationScreen(),
    ),
  ),
];
