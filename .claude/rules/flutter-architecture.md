# Flutter Architecture Rules — Petfolio

## Feature-first folder structure (strict)

```
lib/features/<feature_name>/
  data/
    models/          # Freezed/JsonSerializable DTOs, fieldRename: FieldRename.snake
    repositories/     # ONLY layer allowed to call Supabase.instance.client directly
    datasources/      # optional: raw query/RPC wrappers used by repositories
  domain/
    services/         # business logic, pure Dart — no Flutter/widget imports
  presentation/
    controllers/      # @riverpod / @notifier providers — all feature state lives here
    screens/           # route-level widgets, one per GoRoute
    widgets/            # feature-local reusable widgets
  <feature>_routes.dart # GoRoute definitions for this feature, merged into the app shell
  index.dart            # barrel export for the feature's public surface
```

Shared, cross-feature code lives in `lib/core/` (`theme/`, `navigation/`, `widgets/`, `services/`, `platform/`) — never duplicate a widget or service that already exists there.

## State management — Riverpod Generator only

- All app state is a `@riverpod` function provider or `@riverpod class X extends _$X` (Notifier). Run `dart run build_runner build --delete-conflicting-outputs` after adding or changing any annotated class.
- Forbidden for app state: `ChangeNotifier`, `ValueNotifier` + `ValueListenableBuilder`, `StreamBuilder`, `setState`, the `provider` package, manual `InheritedWidget` state.
- `setState` is permitted **only** for purely ephemeral, non-persisted visual state scoped to a single widget (e.g. a local "is expanded" toggle) — never for anything a controller could own or that another widget needs to read.
- Do not hand-write boilerplate the generator already produces (manual `StateNotifier` subclasses, manual `ChangeNotifier` wrappers, manual provider plumbing).

## Layering rules

- `presentation/screens` and `presentation/widgets` read state via `ref.watch` / `ref.read` on a controller — never call a repository or `Supabase.instance.client` directly from a widget.
- `domain/services` contain business logic only and must be unit-testable without a Flutter dependency.
- `data/repositories` are the only layer permitted to talk to Supabase. See `.claude/rules/supabase-backend.md` for the backend contract.

## Routing

- All navigation is GoRouter, configured in `lib/core/router.dart`. New routes are declared in the owning feature's `<feature>_routes.dart` and merged into the shell — do not add ad-hoc `Navigator.push` routes for anything deep-linkable.

## Dart/style conventions (formatting, naming, testing, lints)

See `.claude/rules/flutter-rules.md` for line-length, naming, lint, and testing conventions. This file governs structure and state management; that file governs code style.
