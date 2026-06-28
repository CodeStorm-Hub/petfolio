# PetFolio Profile Feature Audit

## Architecture & UI/UX

### Feature-First Architecture
The `profile` feature is structured under `lib/features/profile/` and contains only presentation screens:
- `presentation/screens/account_screen.dart`
- `presentation/screens/me_screen.dart`
There is no separate `data` or `domain` layer in this directory, because this feature aggregates profiles, settings, and other services. It directly consumes:
- `authRepositoryProvider` from `lib/features/auth/`
- `PetSwitcherSheet` from `lib/features/pet_profile/`
- `themeProvider` from the core theme module.

### State Management & Riverpod
- Leverages Riverpod for dependency injection and state management.
- Watches the theme provider (`themeProvider`) to toggle between Light and Dark mode.
- Accesses `authRepositoryProvider` for signing out the user.

### Widget Structure & UX
- `MeScreen` is a simple stateless wrapper that yields `AccountScreen`.
- `AccountScreen` is a `ConsumerWidget` that renders a `CustomScrollView` representing the user's dashboard (My Pets, Account, Store, Social, Appearance, Help, and Sign Out).
- It handles wide screen sizes gracefully using a `LayoutBuilder` which constrains the content width to a maximum of `640px` when on desktop/tablet.
- Accessibility is integrated (e.g. `Semantics(label: 'Switch to light/dark mode', excludeSemantics: true)`).
- Page navigation is routed via `GoRouter` redirects (`context.push(...)`).
- Import paths do not introduce circular dependencies.

---

## Supabase & Data Integration

### Schema & RLS
- The database table that corresponds to user profiles is `public.users` defined in `supabase/schema.sql`.
- It mirrors metadata from `auth.users` on user registration via the database trigger `on_auth_user_created`.
- Row Level Security (RLS) is enabled on `public.users`.
- Policies on `public.users` allow authenticated users to select (read) basic profile details (consolidated in `20260531100400_consolidate_rls_policies.sql`).
- Policies are fully optimized: auth checks wrap calls to `auth.uid()` in a subselect, such as `(select auth.uid())`, which allows Postgres to cache the plan and speed up execution.

### Client-Side Join Risk (N+1 Query)
- The profile screen operates as a presentation list of links and local toggles. It does not fetch relational tables on the client side. No N+1 queries or client-side joins are executed.
