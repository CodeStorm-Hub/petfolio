# PetFolio Settings Feature Audit

## Architecture & UI/UX

### Feature-First Architecture
The `settings` feature resides in `lib/features/settings/` and is purely presentation-focused:
- `settings_routes.dart` (which contains `_AddressManagementScreen` and `_AddressCard`)
- `presentation/screens/settings_screen.dart`
It does not contain domain models, repositories, or services of its own. It serves as a visual wrapper that integrates services and data structures from other features:
- `currentUserProvider` and `authRepositoryProvider` from `lib/features/auth/`
- `addressListProvider` and `selectedAddressProvider` from the `marketplace` feature.

### State Management & Riverpod
- State is managed via Riverpod.
- It consumes `addressListProvider` (and its notifier for default set/delete operations) and `selectedAddressProvider` directly from the marketplace feature context.
- It uses manual Riverpod providers.

### Widget Structure & UX
- `SettingsScreen` is a `ConsumerWidget` that uses a `CustomScrollView` to display grouped lists of settings (Saved Addresses, My Orders, Promos, Referrals, Notifications, Appearance, Help, and Sign Out).
- `_AddressManagementScreen` is a `ConsumerWidget` that renders a list of saved delivery addresses. It features an empty state if no addresses exist, lists them via `ListView.separated`, and allows interactions (default selection, delete) via a `PopupMenuButton`.
- It uses custom transitions (`pfSharedAxisPage`) for entering the address management context.
- Layouts are responsive and leverage the custom theme extension `PetfolioThemeExtension` for styling.
- Import paths do not introduce circular dependencies.

---

## Supabase & Data Integration

### Schema & RLS
- The settings feature does not define database tables or migrations of its own.
- The address management system utilizes the tables and RLS defined under the marketplace module.
- Authentication checks in the marketplace tables/functions are fully optimized with `(select auth.uid())` subselects to bypass PostgreSQL plan caching overhead.

### Client-Side Join Risk (N+1 Query)
- No client-side joining risks exist within the settings feature itself, as it relies on clean Riverpod providers to listen to marketplace and auth state directly.
