import 'package:go_router/go_router.dart';

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/registration_screen.dart';

List<RouteBase> authRoutes() => [
  GoRoute(
    path: '/login',
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: '/register',
    builder: (context, state) => const RegistrationScreen(),
  ),
];
