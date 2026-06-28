// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'ce7db43be4d84e1b6c75777fd2d02f381b8b0695';

/// Streams every [AuthState] change from Supabase Auth.
///
/// The initial value is synthesised from the current session so the router
/// redirect fires synchronously on cold start without waiting for the stream.

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// Streams every [AuthState] change from Supabase Auth.
///
/// The initial value is synthesised from the current session so the router
/// redirect fires synchronously on cold start without waiting for the stream.

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  /// Streams every [AuthState] change from Supabase Auth.
  ///
  /// The initial value is synthesised from the current session so the router
  /// redirect fires synchronously on cold start without waiting for the stream.
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'f9315cea2594a31a43b1c72a8ff4998e7bbf1b9a';

/// Derived convenience provider — true when a valid session exists.

@ProviderFor(isLoggedIn)
final isLoggedInProvider = IsLoggedInProvider._();

/// Derived convenience provider — true when a valid session exists.

final class IsLoggedInProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Derived convenience provider — true when a valid session exists.
  IsLoggedInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isLoggedInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isLoggedInHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isLoggedIn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isLoggedInHash() => r'74ea517e0aaed269c22e267cb3c8014421882978';

/// Derived convenience provider — the current signed-in user, if any.

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// Derived convenience provider — the current signed-in user, if any.

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
  /// Derived convenience provider — the current signed-in user, if any.
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  User? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$currentUserHash() => r'aa71f72bea237d05865f15c517a010227b95b466';

/// Derived convenience provider — the current signed-in session, if any.

@ProviderFor(currentSession)
final currentSessionProvider = CurrentSessionProvider._();

/// Derived convenience provider — the current signed-in session, if any.

final class CurrentSessionProvider
    extends $FunctionalProvider<Session?, Session?, Session?>
    with $Provider<Session?> {
  /// Derived convenience provider — the current signed-in session, if any.
  CurrentSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSessionHash();

  @$internal
  @override
  $ProviderElement<Session?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Session? create(Ref ref) {
    return currentSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Session? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Session?>(value),
    );
  }
}

String _$currentSessionHash() => r'0283536774ec4013d6c2f6d5adb8b5793f3e98e8';

@ProviderFor(PasswordReset)
final passwordResetProvider = PasswordResetProvider._();

final class PasswordResetProvider
    extends $NotifierProvider<PasswordReset, PasswordResetState> {
  PasswordResetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordResetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordResetHash();

  @$internal
  @override
  PasswordReset create() => PasswordReset();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PasswordResetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PasswordResetState>(value),
    );
  }
}

String _$passwordResetHash() => r'bf0c7805aee80bfb608b30c05c65c18362fb0741';

abstract class _$PasswordReset extends $Notifier<PasswordResetState> {
  PasswordResetState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PasswordResetState, PasswordResetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PasswordResetState, PasswordResetState>,
              PasswordResetState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
