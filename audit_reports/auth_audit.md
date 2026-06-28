# PetFolio Auth Feature Audit

## Architecture & UI/UX

### Feature-First Architecture
The `auth` feature conforms nicely to the Feature-First Architecture rules. It is located under `lib/features/auth/` and divided into:
- **Presentation**: `controllers/auth_controller.dart` for state, `screens/login_screen.dart` and `screens/registration_screen.dart` for UI, and `widgets/auth_widgets.dart` for reusable components.
- **Data**: `repositories/auth_repository.dart` which encapsulates direct interactions with the Supabase client.
- **Domain**: Auth models and business rules are handled directly through Supabase Auth (e.g. `User`, `Session`, `AuthState`).

### State Management & Riverpod
- State management relies on Riverpod.
- Key providers include `authRepositoryProvider`, `authStateProvider`, `isLoggedInProvider`, `currentUserProvider`, and `currentSessionProvider`.
- It uses manual Riverpod providers (like `Provider`, `StreamProvider`, and `Notifier` with `NotifierProvider`) instead of the `@riverpod` code generation system. Although correct, a future migration to Riverpod 2/3 code-generated notifiers would keep it aligned with modern styles.
- It completely avoids the deprecated `provider` package.

### Widget Structure & UX
- `LoginScreen` and `RegistrationScreen` are implemented as `ConsumerStatefulWidget`s, correctly utilizing stateful hooks for local UI validation and controllers (e.g., email/password inputs, animations, obscurity states).
- Error handling is extremely robust: `_friendlyAuthError` intercepts and converts verbose database/network errors (like `AuthRetryableFetchException` or `ClientException`) into user-friendly strings.
- Accessibility semantics are integrated for CTA buttons (e.g. `Semantics(label: 'Sign in', button: true)`).
- Routing is defined in `auth_routes.dart` using `GoRoute` and custom page transitions (`pfFadeThroughPage`, `pfSharedAxisPage`).
- No circular imports were detected.

---

## Supabase & Data Integration

### Schema & Mirrors
- Supabase Auth manages standard user authentication natively under the `auth.users` table.
- A mirroring system is established to sync profiles. A trigger `on_auth_user_created` in `auth.users` fires a `SECURITY DEFINER` function `private.handle_new_user()` which inserts a corresponding profile row into the public profiles table `public.users`.
- This function is secure: it runs in the `private` schema and uses `SET search_path = public` to prevent search path injection attacks.

### Row Level Security (RLS)
- The mirroring table `public.users` has Row Level Security enabled.
- The RLS policies on `public.users` have been consolidated in `20260531100400_consolidate_rls_policies.sql` to avoid multi-policy permissive overhead.
- Select policies permit authenticated users to read basic profile info.
- Performance: Auth check policies wrap standard `auth.uid()` calls inside a subselect `(select auth.uid())` which forces the PostgreSQL query optimizer to cache the plan/result, eliminating performance degradation on large tables.

### Client-Side Join Risk (N+1 Query)
- Auth handles session management and single-user profile operations. No client-side joining risks or N+1 query patterns were detected in the auth repository or controllers.
