# Petfolio — Consolidated review findings

**Date:** 2026-05-16  
**Sources:** Full-project pass (architecture, responsive layout, analyzer/tests, Supabase) + `code-reviewer` subagent scan of `lib/` and migrations.

Existing narrative audit: `CODEBASE_REVIEW.md` (2026-05-15).

---

## Severity summary

| Severity | Topic | Location / notes |
|----------|--------|------------------|
| Critical | Supabase URL, anon JWT, and Stripe publishable key as `String.fromEnvironment` **defaults** in shipping builds | `lib/main.dart` |
| ~~Critical~~ **Fixed** | `chat_threads` now maps **`participant_1_id` / `participant_2_id`**, filters by auth user + **`match_requests`** for active pet | `chat_thread.dart`, `chat_threads_controller.dart` |
| ~~Critical~~ **Fixed** | Public feed no longer filters with **`post_likes.pet_id`**; `isLiked` from embedded `post_likes` only | `social_repository.dart` |
| High | `widget_test` pumps `PetfolioApp` without `ProviderScope`; counter template does not match app | `test/widget_test.dart` |
| ~~High~~ **Fixed** | `/pet/:petId/edit` safe lookup + **`_PetEditMissingScreen`** | `lib/core/router.dart` |
| High | Order **confirmed client-side** after payment sheet; **no Stripe webhook** attestation | `checkout_controller.dart`, `order_repository.dart` (see `CLAUDE.md`) |
| Medium | **Migrations** omit or under-spec `chat_threads` vs hosted schema — drift easy to miss | `supabase/migrations/` |
| Medium | **`analysis_options.yaml`** — no `strict-casts` / `strict-inference` / `strict-raw-types` | Root `analysis_options.yaml` |
| Medium | **`riverpod_annotation` / `riverpod_generator` in pubspec** — not dominant pattern in `lib/` | `pubspec.yaml` |
| Medium | No **`FlutterError.onError` / zone guards / crash reporting** in `main.dart` | `lib/main.dart` |
| Medium | Duplicate **`Pet`** concepts (care vs pet profile) — consolidation pending | `progress.md`, models |

---

## Architecture (`flutter-apply-architecture-best-practices`)

- Feature-first layout under `lib/features/*` with data/presentation split is sound.
- Domain/use-case layer is thin; rules cluster in repositories and large widgets.
- Repositories are mostly concrete classes without interfaces — heavier to mock and swap.

---

## Responsive & adaptive UI (`flutter-build-responsive-layout`, `flutter-adaptive-ui`)

- **`AppShell`** branches on `MediaQuery.sizeOf(context).width >= 600` (rail vs bottom bar) — constraint-based, not device labels.
- **Gap:** single breakpoint; adaptive guidance often adds a **medium** tier (e.g. 840dp).
- **Gap:** wide layout uses full **`Expanded`** content width — reading surfaces may need **`maxWidth` + `Center`** per screen.

---

## Flutter / Dart quality (`flutter-dart-code-review`)

- Default **flutter_lints** only; stricter analyzer options not enabled.
- **Tests:** aside from care utilities, coverage is thin; default widget test is invalid for Riverpod app.
- **Dependencies:** optional cleanup of unused generator packages if codegen path is unused.

---

## UI / UX (`flutter-ui-ux`)

- Theme extensions and shared widgets (`AppHeader`, snack bars) support consistency.
- Residual risk: mixed hardcoded colors vs tokens on older screens; social optimistic updates with rollback are a good pattern.

---

## Supabase & Postgres (`supabase`, `supabase-postgres-best-practices`)

- **RLS** assumed on tables; verify **indexes on foreign keys** with project advisors after schema changes.
- **Social:** feed implementation queries `posts`; empty table yields empty feed (not a mock list).
- **Matching:** discovery inserts `match_requests` with user + pet columns matching DB; **chat** client model/stream now follow **`participant_*_id`** and `match_request_id`.

---

## Prioritized follow-ups

1. **Strip or gate** default secrets in `main.dart` for release; fail fast without defines when appropriate.
2. Replace **`widget_test`** with `ProviderScope` + realistic smoke or subtree tests.
3. Plan **Stripe webhook** (or backend confirmation) before treating orders as paid.
4. With **Docker Desktop** running, use **`npx supabase db pull <name> --yes`** to generate drift migrations; on Windows, `db pull` currently fails without Docker (shadow DB).

## App ↔ database cross-check (2026-05-16)

Tables touched from `lib/`: `users`, `pets`, `care_tasks`, `care_logs`, `care_streaks`, `pet_badges`, `health_logs`, `medical_vault`, `posts`, `post_likes`, `comments`, `notifications`, `pet_follows`, `match_requests`, `chat_threads`, `products`, `marketplace_orders`, storage **`pets`**, **`post-images`**. RPC **`check_daily_completion`** referenced from care layer.  
**Verified:** `post_likes` unique `(post_id, pet_id)` and `pet_follows` unique `(follower_pet_id, following_pet_id)` match app `upsert` targets.  
**Operational:** `npx supabase migration list` now shows **local = remote** for all files under `supabase/migrations/` after `migration repair` (MCP-applied versions were reverted in history; objects unchanged). **`npx supabase db pull`** requires Docker on this host.

## Supabase CLI convention

Use **`npx`** (e.g. `npx supabase migration list`, `npx supabase db pull`, `npx supabase migration repair`) so the project-local CLI version is used consistently.

---

## PR 4 / Copilot follow-ups (already addressed in tree)

- Web-safe Marionette gate via conditional imports (`lib/marionette_debug_gate_*.dart`).
- `PetListNotifier.unarchive` sort order; care migration dedupe before unique index; `.gitignore` entries for local hook state / dumps; related Dart fixes — see `progress.md` and recent commits.
