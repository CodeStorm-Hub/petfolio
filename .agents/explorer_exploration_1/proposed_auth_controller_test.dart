import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfolio/features/auth/data/repositories/auth_repository.dart';
import 'package:petfolio/features/auth/presentation/controllers/auth_controller.dart';
import '../../helpers/fake_supabase_client.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    this.session,
    this.user,
    this.stream,
    this.signUpError,
    this.signInError,
    this.resetPasswordError,
  });

  final Session? session;
  final User? user;
  final Stream<AuthState>? stream;
  final Object? signUpError;
  final Object? signInError;
  final Object? resetPasswordError;

  bool resetPasswordCalled = false;
  String? resetPasswordEmail;

  @override
  Session? get currentSession => session;

  @override
  User? get currentUser => user;

  @override
  Stream<AuthState> get onAuthStateChange => stream ?? const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    if (signUpError != null) throw signUpError!;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {
    resetPasswordCalled = true;
    resetPasswordEmail = email;
    if (resetPasswordError != null) throw resetPasswordError!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Auth Controller & State Providers Tests', () {
    test('isLoggedInProvider is false when session is null', () {
      final mockRepo = MockAuthRepository(session: null);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isLoggedInProvider), isFalse);
    });

    test('isLoggedInProvider is true when session exists', () {
      // Mock session and user
      final mockRepo = MockAuthRepository(
        session: FakeSession(),
        user: FakeUser(),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isLoggedInProvider), isTrue);
    });

    test('passwordResetProvider flow success', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(passwordResetProvider).status, PasswordResetStatus.idle);

      final notifier = container.read(passwordResetProvider.notifier);
      final future = notifier.send('test@petfolio.com');

      expect(container.read(passwordResetProvider).status, PasswordResetStatus.loading);

      await future;

      expect(container.read(passwordResetProvider).status, PasswordResetStatus.sent);
      expect(mockRepo.resetPasswordCalled, isTrue);
      expect(mockRepo.resetPasswordEmail, 'test@petfolio.com');
    });

    test('passwordResetProvider flow error', () async {
      final mockRepo = MockAuthRepository(
        resetPasswordError: const AuthException('Could not send email'),
      );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(passwordResetProvider.notifier);
      await notifier.send('test@petfolio.com');

      expect(container.read(passwordResetProvider).status, PasswordResetStatus.failure);
      expect(container.read(passwordResetProvider).error, 'Could not send email');
    });
  });
}

class FakeSession implements Session {
  @override
  User get user => FakeUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeUser implements User {
  @override
  String get id => 'user-123';

  @override
  String get email => 'test@petfolio.com';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
