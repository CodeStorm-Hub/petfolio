# Petfolio — Comprehensive Codebase, Database, and UX Review

**Review date:** 2026-05-16  
**Scope:** Application code under `lib/`, Supabase SQL under `supabase/` (migrations + `schema.sql`), Edge Function `create-payment-intent`, and representative UI flows.  
**Verification run:** `flutter analyze` (no issues); `flutter test` (4 passed, 1 failed — see Testing).

This document supersedes narrative snapshots in older audits where the product has changed (e.g. matching and social feed are now largely DB-backed). It is meant as a single reference for gaps, risks, and improvements alongside `CODEBASE_REVIEW.md` and `REVIEW_FINDINGS.md`.

---

## Executive summary

Petfolio is a feature-first **Flutter + Riverpod + GoRouter** app on **Supabase** (Auth, Postgres, Storage, Realtime) with **Stripe** checkout. Care, social (posts, likes, comments, follows, notifications), marketplace, pet profiles, and matching/discovery are **substantially wired to Postgres**. Remaining problems cluster around: **dead schema surface** (tables unused by the app), **incomplete chat** (threads without a first-class message UI), **client-trusted commerce state**, **configuration defaults in source**, **orphaned UI concepts** (memorial/tributes, header actions), and **thin automated testing** beyond small care utilities.

---

## Review method

1. Read `supabase/schema.sql` and all files under `supabase/migrations/` for table and policy intent.  
2. Grepped `lib/` for `.from('...')`, `.rpc(`, and storage bucket usage to map the app to tables.  
3. Spot-checked high-risk areas: matching, social, checkout, care repositories, home (`PetProfileScreen`), and `main.dart`.  
4. Cross-checked claims in `docs/flutter_supabase_full_app_review_2026-05-13.md` against current code (several items are **fixed** or **outdated**).  
5. Ran `flutter analyze` and `flutter test`.  
6. Summarized **Flutter + Supabase** guidance from public sources (Supabase docs, community write-ups on RLS and Realtime); see [External references](#external-references-best-practices).

---

## Database inventory (authoritative picture)

**Base schema (`supabase/schema.sql`)** defines core social/commerce primitives: `users`, `pets`, `care_logs`, `health_vitals`, `posts`, `match_requests`, `chat_threads`, `chat_messages`, `marketplace_orders`, plus RLS patterns and triggers.

**Migrations extend / alter** that baseline. Observed additions include (non-exhaustive but representative):

| Area | Objects |
|------|---------|
| Marketplace | `products`; `marketplace_orders` stripe + line_items columns |
| Care | `care_tasks`; `care_logs` append **`logged_date`**, expanded `care_type`, uniqueness on `(pet_id, care_type, logged_date)`; RPC-style daily completion path used from Dart (`check_daily_completion`) |
| Health | `health_logs`, `medical_vault` |
| Gamification | `care_streaks`, `pet_badges`, `pet_care_gamification` |
| Social | `post_likes`, `notifications`, `comments`, `pet_follows` |
| Cleanup | Drop `post_candles` and memorial column on `posts` (`20260514000001_remove_memorial_feature.sql`) |

**Drift risk:** `schema.sql` in-repo is not automatically the full picture; **migrations are the source of truth** for what production should contain. Keep `schema.sql` regenerated or treat it as documentation-only to avoid false confidence.

---

## Application ↔ database mapping

Tables (and buckets/RPC) referenced from `lib/` (from static search):

| Supabase object | Primary features |
|-----------------|------------------|
| `users`, `pets` | Auth-adjacent profiles, onboarding, discovery |
| `care_tasks`, `care_logs`, `care_streaks`, `pet_badges` | Care dashboard, tasks, streaks, badges |
| `check_daily_completion` (RPC) | Daily completion / streak logic |
| `health_logs`, `medical_vault` | Health vault / structured logs |
| `health_vitals` | Target weight write from pet profile flow |
| `posts`, `post_likes`, `comments`, `pet_follows`, `notifications` | Social feed, profile, notifications |
| Storage `pets`, `post-images` | Avatars, post media |
| `match_requests`, `chat_threads` | Discovery swipes → requests; thread list + realtime stream |
| `products`, `marketplace_orders` | Catalog, orders, Edge Function payment intent |

**Not referenced in `lib/` (potential dead or future-only schema):**

- `chat_messages` — no app queries found; messaging UX is not implemented end-to-end.  
- `pet_care_gamification` — table exists in migrations; **no Dart usage** located.  
- Legacy memorial persistence — `post_candles` removed in SQL; UI may still carry vestigial labels or fields.

---

## Mismatches and disconnects

### High impact

1. **Chat threads vs messages**  
   `MatchingRepository.chatThreadStream()` and `chatThreadsProvider` correctly align with `participant_1_id` / `participant_2_id` and `match_request_id`, filtered by active pet via `match_requests`. There is **no** `chat_messages` layer in the Flutter codebase, so users cannot send/receive messages in-app despite the table and RLS existing in SQL.

2. **Order payment truth**  
   Checkout promotes orders using **client-side** success from the Stripe Payment Sheet (`checkout_controller.dart` pattern). There is **no** app-side enforcement that server/webhook confirmed payment before treating inventory or fulfillment as final. The Edge Function correctly uses the **service role** for order lookup and stresses JWT ownership checks — good — but **Stripe webhooks** (or a server-confirmed status) remain the production-grade source of truth.

3. **Default environment values in `main.dart`**  
   `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `STRIPE_PUBLISHABLE_KEY` use `String.fromEnvironment` **with real project defaults**. Anon/publishable keys are not secret, but **shipping one project’s keys as compile-time defaults** invites wrong-environment bugs and accidental coupling. Prefer failing fast in release builds when defines are missing, or flavor-specific config.

4. **Widget test invalid for Riverpod app**  
   `test/widget_test.dart` pumps `PetfolioApp` **without** `ProviderScope` and still asserts the counter template. **`flutter test` fails** this file (confirmed 2026-05-16).

### Medium impact

5. **Dual “health” models**  
   `health_vitals` (schema baseline) is used for **target weight** in `pet_repository.dart`. **`health_logs`** and **`medical_vault`** back the care health UX. Product and engineering clarity (one mental model for owners) is split across three surfaces.

6. **Memorial / tributes mismatch**  
   Migration removed **`post_candles`** and memorial flags. `FeedPost` still exposes **`tributes`** (defaults to 0); `social_screen.dart` still has a “Memorial post” section comment. Social controller comments mention “candle” but only **like** is implemented. Risk: misleading UX or future dead code.

7. **Discovery deck fallback**  
   `DiscoveryNotifier` seeds a **sample deck** then replaces with Supabase candidates; failures keep the sample deck. Users may **not distinguish** demo cards from real pets without careful UX (demo IDs are skipped in `recordSwipe`, which is good, but the deck can still look “full” when offline).

8. **Swipe / match_requests semantics**  
   Positive swipes always insert **`pending`** `match_requests`. “Pass” writes nothing (by design — no rejections table). Duplicate pending requests for the same pet pair may depend on **DB constraints**; if missing unique partial indexes, duplicates are possible.

9. **Edge Function CORS**  
   `create-payment-intent` uses `Access-Control-Allow-Origin: *`. Acceptable for some mobile-origin POST patterns but worth tightening if browser clients ever call it.

### Lower impact / housekeeping

10. **`schema.sql` vs migrations**  
    Readers of **`schema.sql` alone** may miss `products`, `care_tasks`, `post_likes`, etc. Document or regenerate.

11. **Analyzer strictness**  
    Current `flutter analyze` is clean with default lints; stricter modes (`strict-casts`, `strict-inference`, `strict-raw-types`) are not enabled — acceptable, but caps long-term safety.

---

## Feature-area review

### Auth

- Supabase email/password flow; session drives GoRouter redirects.  
- **Recommendation:** Ensure deep links and OAuth (if added later) follow Supabase’s [Flutter guide](https://supabase.com/docs/guides/auth/native-mobile-deep-linking) (PKCE, redirect URLs).

### Pet profile and home (`PetProfileScreen` at `/home`)

- Uses active pet + list providers; integrates care streak realtime elsewhere in app.  
- **UX gaps:** header **Outdoor mode** and **Notifications** actions use **empty** `onTap` while showing badges/tooltips — visually active, functionally inert.

### Care

- Rich Supabase integration: tasks, logs with `logged_date`, streaks, badges, RPC completion, optional realtime on streaks.  
- **Strength:** typed repository errors (`AppException` hierarchy) in `PetCareRepository`.  
- **Watch:** ensure all devices use consistent **timezone semantics** for `logged_date` (UTC vs local) in edge cases.

### Social

- Feed loads **`posts`** with joins to `pets` and `users`; **`post_likes`** embedded for `isLiked`; realtime subscription updates **counts** on `posts`.  
- Comments and notifications repositories exist; create post + storage upload path present.  
- **Gap:** memorial/candle product surface removed at DB level; UI/model remnants should be removed or re-spec’d.

### Matching

- **Repository** uses real `pets` + `match_requests` (no `swipes`/`matches` tables).  
- **Chat thread model** matches DB columns.  
- **Gap:** no message sending; thread list only.

### Marketplace

- `ProductRepository.fetchProducts()` throws on failure — **no silent demo catalog** in current `ProductListNotifier` (improvement vs older reviews).  
- Stripe Payment Sheet + Edge Function idempotency commentary is sound; **server confirmation** still recommended.

---

## UI / UX assessment

**Strengths**

- Cohesive **theme extensions** (`PetfolioThemeExtension`), shared header (`AppHeader`), glass/surface language, adaptive shell (rail vs bottom nav at 600 dp).  
- Social **optimistic** like with rollback on failure is the right pattern.  
- `GoogleFonts.config.allowRuntimeFetching = false` in `main.dart` avoids emulator DNS meltdown — pragmatic.

**Issues**

- **False affordances:** home header actions with **no behavior**; any control that looks tappable should navigate, toggle state, or be disabled with explanation.  
- **Breakpoint strategy:** single 600 dp split; large tablets/desktops may need **max content width** and an intermediate breakpoint (e.g. 840 dp) per common adaptive guidance.  
- **Accessibility:** audit **icon-only** controls and password fields for labels; ensure dynamic type / text scaling on dense cards (feed, discovery).  
- **Consistency:** prefer theme tokens over scattered `TextStyle` / raw colors on older widgets.

---

## Security and Supabase posture

| Topic | Observation |
|-------|-------------|
| RLS | Assumed on all user data tables per migrations; policies should always use `auth.uid()` / `(select auth.uid())`, separate policies per command, and **`WITH CHECK` on `UPDATE`** (see Supabase security guidance). |
| Keys | Never ship **service_role** to the client (Edge Function pattern here uses env — correct). |
| Auth hardening | Enable **leaked-password protection** and strong MFA options in Supabase Auth if not already (called out in historical project notes). |
| Storage | Validate **`post-images`** and **`pets`** bucket policies match app paths; public read buckets need abuse awareness (size limits, content types). |

---

## Testing and quality gates

| Check | Result (2026-05-16) |
|-------|---------------------|
| `flutter analyze` | Pass — **no issues found** |
| `flutter test` | **4 passed**, **1 failed** (`test/widget_test.dart` — missing `ProviderScope`, wrong template assertions) |
| Integration / E2E | Not reviewed as part of this pass |

**Recommendations:** replace default widget test with **scoped** tests (e.g. login shell with mocked `Supabase` / `ProviderScope`), add repository tests with `PostgrestException` paths, and consider `integration_test` for checkout and care toggles.

---

## External references (best practices)

- **Supabase + Flutter (official):** [Flutter quickstart / user management](https://supabase.com/docs/guides/getting-started/quickstarts/flutter) — auth persistence, initialization, listening to auth state.  
- **RLS patterns:** Prefer explicit **`TO authenticated`**, avoid broad `USING (true)` on sensitive data, and never “fix” bugs by disabling RLS. Ali Wajdan’s 2026 write-up on RLS in Flutter ([Medium](https://aliwajdan.medium.com/supabase-row-level-security-in-flutter-the-policy-pattern-i-use-so-users-never-see-each-others-7c72fe87ed89)) aligns with defense-in-depth.for multi-tenant mobile apps.  
- **Realtime:** Ensure tables have appropriate **`REPLICA IDENTITY`** and publication membership; filter channels to minimize payload and respect RLS ([community overview](https://supabase.com/docs/guides/realtime)).  
- **Mobile payments:** Stripe’s guidance (via general best practices) — confirm **webhooks** for `payment_intent.succeeded` before irreversible side effects.

---

## Prioritized recommendations

1. **Fix `test/widget_test.dart`** — wrap with `ProviderScope`, drop counter template, or delete in favor of real smoke tests.  
2. **Remove or complete dead UX** — home header actions, memorial/tributes remnants, or wire them to real routes (`/social/notifications`, etc.).  
3. **Chat MVP** — read/write `chat_messages` with RLS-safe queries, optimistic send, and thread `last_message_at` updates (trigger or RPC).  
4. **Commerce hardening** — Stripe webhook → update `marketplace_orders.status` / `stripe_payment_intent_id` server-side; client only reflects confirmed state.  
5. **Config hygiene** — no production defaults for Supabase/Stripe in source; use flavors + CI-injected defines.  
6. **Schema documentation** — regenerate `schema.sql` from migrations or add a CI check that migrations apply cleanly.  
7. **Indexed constraints on `match_requests`** — unique pending pair if product rules require one row per pet pair.  
8. **Consolidate health modeling** — document when to use `health_vitals` vs `health_logs` vs `medical_vault`, or merge concepts in the UI.  
9. **Stricter Dart analysis** — enable optional strictness lints incrementally.  
10. **Operational observability** — `FlutterError.onError` / crash reporting for release builds.

---

## Changelog vs older reviews

| Topic | `docs/flutter_supabase_full_app_review_2026-05-13.md` said | Current state (this review) |
|-------|----------------------------------|-----------------------------|
| Social feed | Mock `_demoPosts()` | **`posts` fetched**; Realtime on counts |
| Matching tables | Writes to nonexistent `swipes`/`matches` | **`match_requests` + real pet query** |
| Chat mapping | Pet-based columns | **`participant_*` + `match_request_id`** aligned |
| Marketplace fallback | Silent demo catalog | **Fetch throws**; list driven by `AsyncNotifier` (verify error UI where used) |

---

*End of report.*
