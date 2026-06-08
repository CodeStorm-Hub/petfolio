import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfolio/core/models/pet.dart';
import 'package:petfolio/core/router.dart';
import 'package:petfolio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:petfolio/features/auth/presentation/screens/login_screen.dart';
import 'package:petfolio/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:petfolio/main.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _fakePet = Pet(
  id: 'pet-1',
  ownerId: 'user-1',
  name: 'Buddy',
  species: 'dog',
  createdAt: DateTime(2025, 1, 1),
);

String? _redirect({
  bool isLoggedIn = true,
  bool isAdmin = false,
  List<Pet>? pets,
  String matchedLocation = '/home',
  String uriPath = '/home',
  Map<String, String> queryParameters = const {},
}) =>
    computeRedirect(
      isLoggedIn: isLoggedIn,
      isAdmin: isAdmin,
      pets: pets,
      matchedLocation: matchedLocation,
      uriPath: uriPath,
      queryParameters: queryParameters,
    );

// ── Stub for the widget smoke test ────────────────────────────────────────────

class _NoPetsNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => [];
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── Logged-out user redirect ──────────────────────────────────────────────

  group('computeRedirect — logged-out user', () {
    test('redirected to /login when accessing /home', () {
      expect(_redirect(isLoggedIn: false, matchedLocation: '/home'), '/login');
    });

    test('redirected to /login when accessing any protected route', () {
      for (final loc in ['/care', '/social', '/marketplace', '/admin', '/seller']) {
        expect(
          _redirect(isLoggedIn: false, matchedLocation: loc, uriPath: loc),
          '/login',
          reason: 'Expected /login redirect for $loc',
        );
      }
    });

    test('allowed to stay on /login', () {
      expect(
        _redirect(
          isLoggedIn: false,
          matchedLocation: '/login',
          uriPath: '/login',
        ),
        isNull,
      );
    });

    test('allowed to stay on /register', () {
      expect(
        _redirect(
          isLoggedIn: false,
          matchedLocation: '/register',
          uriPath: '/register',
        ),
        isNull,
      );
    });

    test('root path redirects to /login', () {
      expect(
        _redirect(isLoggedIn: false, matchedLocation: '/', uriPath: '/'),
        '/login',
      );
    });
  });

  // ── Logged-in user redirect ───────────────────────────────────────────────

  group('computeRedirect — logged-in user', () {
    test('no redirect when on /home with pets', () {
      expect(
        _redirect(pets: [_fakePet], matchedLocation: '/home', uriPath: '/home'),
        isNull,
      );
    });

    test('redirected to /home when visiting /login while logged in', () {
      expect(
        _redirect(
          pets: [_fakePet],
          matchedLocation: '/login',
          uriPath: '/login',
        ),
        '/home',
      );
    });

    test('redirected to /home when visiting /register while logged in', () {
      expect(
        _redirect(
          pets: [_fakePet],
          matchedLocation: '/register',
          uriPath: '/register',
        ),
        '/home',
      );
    });

    test('root path redirects to /home when logged in', () {
      expect(
        _redirect(pets: [_fakePet], matchedLocation: '/', uriPath: '/'),
        '/home',
      );
    });
  });

  // ── Onboarding redirect ───────────────────────────────────────────────────

  group('computeRedirect — onboarding', () {
    test('redirected to /onboarding when logged in but pet list is empty', () {
      expect(
        _redirect(pets: [], matchedLocation: '/home', uriPath: '/home'),
        '/onboarding',
      );
    });

    test('not redirected when already on /onboarding with empty pets', () {
      expect(
        _redirect(
          pets: [],
          matchedLocation: '/onboarding',
          uriPath: '/onboarding',
        ),
        isNull,
      );
    });

    test('not redirected when pets are still loading (null)', () {
      expect(
        _redirect(pets: null, matchedLocation: '/home', uriPath: '/home'),
        isNull,
      );
    });

    test('redirected to /care from /onboarding when pets exist and no mode=add',
        () {
      expect(
        _redirect(
          pets: [_fakePet],
          matchedLocation: '/onboarding',
          uriPath: '/onboarding',
        ),
        '/care',
      );
    });

    test('not redirected from /onboarding when mode=add is set', () {
      expect(
        _redirect(
          pets: [_fakePet],
          matchedLocation: '/onboarding',
          uriPath: '/onboarding',
          queryParameters: {'mode': 'add'},
        ),
        isNull,
      );
    });
  });

  // ── Admin route protection ────────────────────────────────────────────────

  group('computeRedirect — admin route protection', () {
    test('non-admin accessing /admin is redirected to /home', () {
      expect(
        _redirect(
          isAdmin: false,
          pets: [_fakePet],
          matchedLocation: '/admin',
          uriPath: '/admin',
        ),
        '/home',
      );
    });

    test('non-admin accessing /admin/users is redirected to /home', () {
      expect(
        _redirect(
          isAdmin: false,
          pets: [_fakePet],
          matchedLocation: '/admin/users',
          uriPath: '/admin/users',
        ),
        '/home',
      );
    });

    test('admin user accessing /admin is allowed', () {
      expect(
        _redirect(
          isAdmin: true,
          pets: [_fakePet],
          matchedLocation: '/admin',
          uriPath: '/admin',
        ),
        isNull,
      );
    });
  });

  // ── Widget smoke test: logged-out renders LoginScreen ────────────────────

  group('Router widget smoke test', () {
    testWidgets('logged-out user sees LoginScreen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isLoggedInProvider.overrideWithValue(false),
            petListProvider.overrideWith(_NoPetsNotifier.new),
          ],
          child: const PetfolioApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
