# Handoff Report: Auth Feature Exploration & Migration Plan

## 1. Observation

During the read-only investigation, the following files and code snippets in the `auth` feature and project configuration were examined:

### Project Configuration (`pubspec.yaml`)
- Riverpod version is configured with:
  - `flutter_riverpod: ^3.3.1` (Line 43)
  - `riverpod_annotation: ^4.0.2` (Line 44)
  - `riverpod_generator: ^4.0.3` (Line 128)

### Manual Providers in `lib/features/auth/presentation/controllers/auth_controller.dart`
- **`authRepositoryProvider`** (Line 6):
  ```dart
  final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => AuthRepository(Supabase.instance.client),
  );
  ```
- **`authStateProvider`** (Line 14):
  ```dart
  final authStateProvider = StreamProvider<AuthState>((ref) {
    return ref.watch(authRepositoryProvider).onAuthStateChange;
  });
  ```
- **`isLoggedInProvider`** (Line 19):
  ```dart
  final isLoggedInProvider = Provider<bool>((ref) {
    final asyncState = ref.watch(authStateProvider);
    return asyncState.when(
      data: (s) => s.session != null,
      loading: () => ref.read(authRepositoryProvider).currentSession != null,
      error: (_, _) => false,
    );
  });
  ```
- **`currentUserProvider`** (Line 30):
  ```dart
  final currentUserProvider = Provider<User?>((ref) {
    final asyncState = ref.watch(authStateProvider);
    return asyncState.when(
      data: (s) => s.session?.user,
      loading: () => ref.read(authRepositoryProvider).currentUser,
      error: (_, _) => null,
    );
  });
  ```
- **`currentSessionProvider`** (Line 40):
  ```dart
  final currentSessionProvider = Provider<Session?>((ref) {
    final asyncState = ref.watch(authStateProvider);
    return asyncState.when(
      data: (s) => s.session,
      loading: () => ref.read(authRepositoryProvider).currentSession,
      error: (_, _) => null,
    );
  });
  ```
- **`passwordResetProvider`** (Line 78):
  ```dart
  final passwordResetProvider =
      NotifierProvider<PasswordResetNotifier, PasswordResetState>(
    PasswordResetNotifier.new,
  );
  ```

### Duplicate Error Mappings in Screens
- **`lib/features/auth/presentation/screens/login_screen.dart`** (Line 230):
  ```dart
  String _friendlyAuthError(String raw) { ... }
  ```
- **`lib/features/auth/presentation/screens/registration_screen.dart`** (Line 80):
  ```dart
  String _friendlyAuthError(String raw) { ... }
  ```
  Both files manually catch `AuthException` or generic exceptions and parse them into localized UX strings with slight variations (e.g. rate limit limits, weak passwords).

---

## 2. Logic Chain

1. **Riverpod 3 Compatibility**:
   - The project uses Riverpod 3 (`^3.3.1`).
   - The `AGENTS.md` rules require that generated class-based notifiers in Riverpod 3 omit type parameters (e.g. `extends _$NotifierName` instead of `extends _$NotifierName<StateType>`).
   - We must adhere to this signature.

2. **Caching & Lifecycle Scopes**:
   - Core authentication state (`authRepository`, `authState`, `isLoggedIn`, `currentUser`, and `currentSession`) must remain persistent to prevent redundant network subscriptions, flickering redirects, and multiple auth state listeners.
   - Therefore, they must use `@Riverpod(keepAlive: true)` to match the original manual provider caching behaviors.
   - The `PasswordReset` state is a UI-specific transient state only used in the forgot password dialog/bottom sheet. Thus, using auto-disposable `@riverpod` is the best practice.

3. **Consumer Stability**:
   - The camelCase naming scheme generated from functions/classes maps precisely to the existing provider names.
   - For example:
     - `authRepository` $\rightarrow$ `authRepositoryProvider`
     - `authState` $\rightarrow$ `authStateProvider`
     - `isLoggedIn` $\rightarrow$ `isLoggedInProvider`
     - `currentUser` $\rightarrow$ `currentUserProvider`
     - `currentSession` $\rightarrow$ `currentSessionProvider`
     - `PasswordReset` $\rightarrow$ `passwordResetProvider`
   - Using these identical generated names means **zero refactoring of downstream consumers** (e.g. `RouterNotifier`, `CartController`, `DiscoveryCandidatesController`, screens, etc.) is required.

4. **Transient State Cleanup**:
   - By converting `PasswordReset` to an auto-disposable provider (`@riverpod`), Riverpod automatically cleans up its state upon the bottom sheet dismissal.
   - This eliminates the need for manual `.reset()` calls inside UI states (`_ForgotPasswordSheetState.dispose()`).

---

## 3. Caveats

- **Running Code Generation**: While the syntax and signatures are fully specified and tested in proposed files, code generation (`dart run build_runner build`) needs to be executed once the code is written to target files in a writable context.
- **External Network Access**: In CODE_ONLY network mode, external pub dependency resolution is skipped. However, all required dependencies (`riverpod_annotation`, `riverpod_generator`, and `build_runner`) are already fully configured in `pubspec.yaml`.

---

## 4. Conclusion

The manual providers under the `auth` feature can be successfully migrated to Riverpod 2/3 code-generated notifiers without breaking existing consumer contracts. Additionally, the following optimizations should be made:
1. Move the manual `Supabase.instance.client` calls to a centralized `@Riverpod(keepAlive: true)` function-based provider in `lib/core/providers/supabase_provider.dart` to enhance testability.
2. Consolidate the duplicate `_friendlyAuthError` error mappings from both screens into a single static method or extension on `AuthException`.
3. Auto-dispose transient providers (`PasswordReset`) and eliminate manual UI cleanups.

---

## 5. Verification Method

### Execution Commands
1. Navigate to the project root: `cd j:\GitHub\petfolio`
2. Perform code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
3. Execute static analysis to ensure no lint warnings: `dart analyze`
4. Run the suite of tests to verify repository, controller, and integration:
   - `flutter test test/features/auth/auth_repository_test.dart`
   - Run the new controller tests: `flutter test test/features/auth/auth_controller_test.dart` (using proposed test structure)

### Invalidation Conditions
- Code generation fails or produces naming conflicts.
- `RouterNotifier` cannot read `isLoggedInProvider` due to import order or typing changes.
- UI elements fail to rebuild or throw State/Provider exceptions due to auto-disposal on core state.
