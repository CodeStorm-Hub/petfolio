This is a large-scale comprehensive audit across 9 dimensions. I'll orchestrate it with parallel review agents across the codebase, followed by web research for upgrade planning and Supabase MCP for DB analysis.

The 9-agent workflow is running in parallel. While it runs, I'll simultaneously do the **Supabase database review** via MCP.

Project ID: `jqyjvhwlcqcsuwcqgcwf`. Running all DB analysis calls in parallel.

Rich DB findings coming in. Let me read the full tables schema while I wait for the workflow.

Excellent — Supabase DB review is fully gathered. Here's the **database analysis** while the main workflow is still running:

---

## Supabase Database Review

**Project:** `petfolio` (ap-northeast-1, PostgreSQL 17.6, ACTIVE_HEALTHY)
**Tables:** 44 in `public` schema | **Migrations:** 97 since May 12, 2026 (very rapid pace — sometimes 5/day)
**Edge Functions:** 10 active

---

### Schema Coverage (44 tables)

| Domain | Tables |
|--------|--------|
| Core | `users`, `pets` |
| Social | `posts`, `comments`, `comment_likes`, `post_likes`, `pet_follows`, `stories`, `story_reactions` |
| Communities | `communities`, `community_members`, `community_posts`, `community_post_likes` |
| Care/Health | `care_tasks`, `care_logs`, `care_streaks`, `care_web_reminders`, `pet_badges`, `pet_care_gamification`, `medical_vault`, `health_logs`, `health_vitals`, `pet_weight_logs`, `appointments` |
| Matching | `swipes`, `matches`, `chat_threads`, `chat_messages` |
| Marketplace | `products`, `shops`, `marketplace_orders`, `inventory_reservations`, `vendor_ledgers`, `product_reviews`, `promos` |
| Admin | `audit_logs`, `reported_posts`, `shop_deletion_requests` |
| Notifications | `notifications`, `fcm_push_outbox`, `user_fcm_devices`, `user_web_push_subscriptions` |
| Auth-adjacent | `user_addresses`, `waitlist` |

**RLS Status:** ✅ All 44 tables have RLS enabled — **except `fcm_push_outbox` has 0 policies** (RLS on, no rules = nobody can access it via API).

---

### 🔴 Security Issues

**CRITICAL:**
| Issue | Detail |
|-------|--------|
| `toggle_care_task` callable by `anon` | Unauthenticated users can invoke this RPC via `/rest/v1/rpc/toggle_care_task`. Should be `authenticated` only. |
| `get_care_dashboard_snapshot` callable by `anon` | Pet health data RPC accessible without authentication. |
| Community count trigger fns (`inc/dec_community_member_count`, etc.) exposed as RPCs callable by `anon` | Trigger functions should not be callable directly via REST. |
| `refresh_product_rating_stats` callable by `anon` | Data mutation RPC accessible to unauthenticated users. |
| FCM edge fns without JWT (`send-fcm-notification`, `process-fcm-outbox`, `process-care-fcm-reminders`) | `verify_jwt: false` — must verify via service role key in fn body, not just skip auth entirely. |

**HIGH — Good news confirmed:** Admin RPCs (`approve_vendor_kyc`, `reject_vendor_kyc`, `resolve_reported_post`, `resolve_shop_deletion`) **all call `is_admin()` check internally** and raise an exception immediately if the caller isn't an admin. Supabase advisor flagged them but they're properly guarded. ✅

**MEDIUM:**
| Issue | Detail |
|-------|--------|
| `fcm_push_outbox` — RLS with 0 policies | Table inaccessible via direct Supabase API; only reachable from edge functions/trigger context. Intentional? Needs a comment/documentation. |
| Mutable `search_path` | 5 functions: `get_care_dashboard_snapshot`, `toggle_care_task`, `process_checkout`, `private.fcm_data_to_text_map`, `care_tasks_set_anchor_date` — add `SET search_path = public, pg_catalog` |
| Leaked password protection disabled | Enable in Supabase Auth → Password security settings |

---

### 🟡 Performance Issues

**15+ RLS policies re-evaluating `auth.uid()` per row** (should be `(select auth.uid())`):
- `appointments` (all 4 policies), `community_posts`, `communities`, `community_members`, `community_post_likes`, `pet_weight_logs`, `user_addresses` (all 4)

**Fix pattern:**
```sql
-- Change: using auth.uid() = owner_id
-- To:     using (select auth.uid()) = owner_id
```

**Multiple permissive policies on `chat_messages`:**
- 2 overlapping SELECT policies + 2 overlapping INSERT policies — consolidate into one each.

**10 unindexed foreign keys** needing covering indexes:
`appointments.owner_id`, `chat_threads.dm_pet_b_id`, `communities.created_by`, `community_members.pet_id`, `community_post_likes.pet_id`, `community_posts.author_pet_id`, `community_posts.community_id`, `fcm_push_outbox.user_id`, `product_reviews.user_id`, `story_reactions.user_id`

**28 unused indexes** — candidates for removal (all on tables with < 200 rows currently, likely pre-production):
`idx_appointments_scheduled_at`, `pets_owner_active_order_idx`, `pets_location_gix`, `idx_products_shop_id`, `vendor_ledgers_*` (3), `idx_posts_*` (2), `idx_chat_messages_sender`, and more.

---

### Edge Functions

| Function | JWT Required | Purpose |
|----------|-------------|---------|
| `create-payment-intent` | ✅ Yes | Stripe payment initiation |
| `stripe-onboard-vendor` | ✅ Yes | Stripe Connect vendor onboarding |
| `stripe-webhook` | ❌ No | Stripe event handler (correct — Stripe can't send JWT) |
| `cleanup-stories` | ❌ No | Cron-triggered story expiry |
| `generate-care-routine` | ✅ Yes | NVIDIA AI care routine generation |
| `recommend-care-tasks` | ✅ Yes | AI task recommendations |
| `register-web-push-subscription` | ✅ Yes | Web push registration |
| `send-fcm-notification` | ❌ No | FCM dispatcher (⚠️ needs internal auth) |
| `process-fcm-outbox` | ❌ No | FCM outbox processor (⚠️ needs internal auth) |
| `process-care-fcm-reminders` | ❌ No | FCM care reminders (⚠️ needs internal auth) |

---

### Migration Health

97 migrations in ~28 days — excellent granularity. Latest: `fix_process_checkout_enriched_line_items` (Jun 8). Notable recent batch: checkout pricing fixes (multiple passes on `process_checkout` RPC suggests iterative production debugging).

---

The main workflow is still running (6 code analysis + 3 web research + 1 synthesis agent). I'll post the full consolidated report when it completes. Use `/workflows` to watch live progress.

Workflow complete. Reading the full report now.

---

# PetFolio App — Comprehensive Review Report

**Overall Score: 7.5 / 10** | Android (primary) + Web PWA (petfolio.live)

---

## Executive Summary

| Area | Score | Status | Key Risk |
|------|-------|--------|----------|
| Architecture | 6.8 / 10 | 🟡 Needs Work | God-node provider, absent domain layer, zero tests |
| Auth & Security | 7.8 / 10 | 🟡 Good with Gaps | Firebase keys in source, 6-char password |
| UI/UX | 8.4 / 10 | 🟢 Strong | Raw TextStyle literals, thin Semantics coverage |
| Notifications & Location | 8.2 / 10 | 🟢 Strong | Duplicate syncToken calls, iOS bundle ID |
| Core User Flows | 6.1 / 10 | 🔴 Significant Gaps | 8/15 flows have gaps; 3 routes crash at runtime |
| Commerce Flows | 7.1 / 10 | 🟡 Good with Gaps | No coupon UI, no buyer cancellation, no vendor earnings |
| **Overall** | **7.5 / 10** | 🟡 **Solid Foundation** | Beta-ready after P0; P1 required before production |

---

## Top 5 Critical Issues

1. **Firebase API keys committed in plain source** — `lib/firebase_options.dart` contains three hardcoded platform keys permanently in git history. iOS `iosBundleId` is still `com.example.petfolio`, which **breaks all APNs push delivery** on any production iOS build.

2. **3 GoRouter routes unregistered** — `me_screen.dart` calls `context.push('/settings/addresses')`, `context.push('/offers')`, and `context.go('/seller')` — none exist in the router. Any user tapping these (including the vendor onboarding path) gets a runtime crash.

3. **`activePetControllerProvider` god-node with 73+ dependents** — manages SharedPreferences, session restore, cross-pet switching, and list sync for the entire app. Every state change triggers full rebuilds across AppShell, CareDashboard, Marketplace, Matching, and 10+ other screens.

4. **Domain layer missing from 9 of 10 features** — `PetCareRepository` alone is 700+ lines mixing DB access, business rules, date math, badge logic, and notification scheduling. None of it is unit-testable without a live Supabase connection.

5. **Promo/coupon UI completely absent despite full backend** — `promoListProvider`, `filteredPromosProvider`, and `Promo` model all exist. `CartScreen` has no promo field, no validation, no discount line. Users cannot apply codes.

---

## Top 5 Strengths

1. **Exceptional design token system** — `PetfolioThemeExtension` defines 30+ typed tokens (ink shades, pillar accents, soft fills, shadow tiers, glass tokens, motion curves, radius scale, button heights, durations) — correctly paired for light/dark with animated `lerp()`.

2. **Production-grade Supabase security** — All credentials via `String.fromEnvironment()`, RLS on every table with `USING`/`WITH CHECK`, all `SECURITY DEFINER` functions with `REVOKE ALL FROM PUBLIC`, financial mutations behind server-side RPCs.

3. **FCM stack is feature-complete** — `@pragma('vm:entry-point')` background handler, both `onMessageOpenedApp` + `getInitialMessage` wired, Firebase Messaging v1 API with service-account JWT, web push first-class with VAPID key plumbing.

4. **Cart persistence is production-grade** — `flutter_secure_storage` keyed per user UID, auto-migration from legacy SharedPreferences on first post-login load, per-vendor cart grouping preventing cross-vendor payment collisions.

5. **Dual-platform Stripe cleanly split** — `kIsWeb` routes to `PaymentSheet` (mobile) or hosted Checkout (web). `WebCheckoutResumeListener` polls for webhook confirmation on app resume. No secret key exposure anywhere.

---

## 1. Architecture (6.8 / 10)

### Strengths
- Feature-first `data/domain/presentation` scaffold respected across 10+ features
- `AppException` sealed class hierarchy used uniformly in repositories
- Single-RPC dashboard snapshot (`get_care_dashboard_snapshot`) replaces 4 round-trips
- Optimistic updates with rollback in `PetListNotifier` and care toggle-completion
- `ShellRoute` with `NavRail` on wide screens correctly adapts to 5 modules
- Auth guard in `RouterNotifier` checks `isLoggedInProvider` → `petListProvider` → `isAdminProvider` sequentially with no race conditions
- Platform conditional code via conditional imports (media_picker_io/web, platform_notifications_io/web)

### Findings

**[HIGH] `Supabase.instance.client` called directly in 46 files — DI bypassed**
60 call-sites across `CartNotifier`, `social_screen.dart`, `story_controller.dart`, `pet_care_repository.dart`, `matching_repository.dart` and 41 more. Mock injection is impossible; multi-tenancy is structurally broken.
**Fix:** Define `supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client)` in `lib/core/services/` and inject everywhere via `ref.read(supabaseClientProvider)`.

**[HIGH] Domain layer missing in 9 of 10 features**
Business rules — streak computation, badge awards, price calculations, eligibility checks — live inside repositories. `PetCareRepository` exceeds 700 lines. None testable without Supabase.
**Fix:** Extract `ToggleCareTaskUseCase`, `PlaceOrderUseCase`, `SyncPetLocationUseCase` into `domain/usecases/`.

**[HIGH] Cross-feature direct imports violate feature boundaries**
`pet_list_controller.dart` imports `care/data/repositories/pet_care_repository.dart`; `edit_profile_controller.dart` imports `matching/data/repositories/matching_repository.dart`; `hub_home_screen.dart` imports 4 care-feature internals.
**Fix:** Create a `core/contracts/` or `core/ports/` layer. Features should depend on `core`, not each other.

**[MEDIUM] Mixed Riverpod code-gen and manual providers with no convention**
`@riverpod` annotations in theme/care/social vs. manual `NotifierProvider` in active-pet/cart/admin. Different `autoDispose` behavior, no documented policy.

**[MEDIUM] `RouterNotifier` extends `ChangeNotifier` — legacy pattern**
Cannot be tested with `ProviderContainer`, breaks unidirectional dependency model.

**[MEDIUM] Error swallowing in `CartNotifier._loadFromPrefs`**
Bare `catch (_) {}` silently produces empty cart on JSON parse errors or storage denials. Same pattern in `_autoGenerateRoutines`.

**[LOW] Two `Pet` models** — `core/models/pet.dart` imports from `features/pet_profile/` (inversion). Different files import from different locations.

**[LOW] Zero test coverage** — `flutter_test` and `integration_test` are in dev_dependencies but no tests exist.

---

## 2. Authentication & Security (7.8 / 10)

### Strengths
- Supabase credentials only via `String.fromEnvironment()` with startup assertions
- RLS on every table; all `SECURITY DEFINER` functions have `REVOKE ALL FROM PUBLIC`
- Admin access triple-guarded: GoRouter redirect + `AdminScreen` lock + server-side `is_admin()` in every RPC
- Cart migrated from `SharedPreferences` → `flutter_secure_storage` with legacy key cleanup
- Checkout/order mutations use SECURITY DEFINER RPCs (`process_checkout`, `cancel_order`, `vendor_update_order`) preventing column injection

### Findings

**[HIGH] Firebase API keys hardcoded in `lib/firebase_options.dart`**
Permanently in git history. `iosBundleId = com.example.petfolio` breaks APNs on any production iOS build.
**Immediate:** Restrict keys in Firebase Console (HTTP referrer + app restrictions). Add `firebase_options.dart` to `.gitignore`. Change iOS bundle ID.

**[MEDIUM] 6-character minimum password with no complexity requirement**
`registration_screen.dart:152`, `login_screen.dart:326` — `v.length < 6`. NIST SP 800-63B recommends 8 minimum.

**[MEDIUM] `anon` role has SELECT on users, pets, posts**
`supabase/schema.sql` lines 534, 538, 546 — unauthenticated clients can enumerate all public profiles without friction.

**[MEDIUM] `markCashReceived` and `markShopPaid` use direct table UPDATE**
Unlike `cancel_order`/`vendor_update_order`, these two admin financial mutations bypass the project's own security pattern.

**[LOW] NVIDIA API key in app binary**
`NVIDIA_API_KEY` via `--dart-define` can be extracted from Android APKs. Already edge-function-routed on web (`kIsWeb` branch) — apply same pattern to mobile.

**[LOW] No rate-limit error mapping on login screen**
HTTP 429 / `over_email_send_rate_limit` returns raw Supabase error text.

---

## 3. UI/UX & Design System (8.4 / 10)

### M3 Compliance Status
- `useMaterial3: true` with `ColorScheme.fromSeed + DynamicSchemeVariant.fidelity` — textbook M3 color generation
- `RoundedSuperellipseBorder` (Flutter 3.32+ true superellipse) on cards, nav indicator, SearchBar, chips
- Spring-physics nav tab with `SpringSimulation` provides authentic M3 Expressive overshoot
- Typography covers all 15 `TextTheme` slots with proper `height`/`letterSpacing` using Sora/Inter

### Findings

**[HIGH] Inline TextStyle literals dominate feature screens**
`hub_home_screen.dart` alone has 74 occurrences of raw `TextStyle()/fontWeight:/fontSize:`. A `displaySmall` change won't propagate.
**Fix:** Replace with nearest `TextTheme` slot using `.copyWith()` for one-offs. Add `avoid_hardcoded_font_sizes` custom lint rule.

**[HIGH] Bento grid tiles use `GestureDetector + AnimatedScale` instead of M3 `InkWell`**
`_CareTile`, `_BentoTile`, `_AllTile`, `_QuickActionCard`, `_SpotlightCard` — no state layer, no ripple, no hover affordance on web.
**Fix:** Replace with `InkWell` wrapped in `Material`.

**[HIGH] Accessibility Semantics coverage is thin**
`Semantics` found in only 22 files / 33 call-sites across 100+ screen/widget files. Entire bento grid, `_HeaderIconBtn`, spotlight carousel, `TailWagLoader` custom painter have no semantic labels.

**[MEDIUM] `Colors.white` / `Colors.black` used directly in 31+ overlay contexts**
Will fail contrast if wave color changes to a light species accent.
**Fix:** Replace with `colorScheme.onPrimary` or a computed `contrastFor(Color)` utility.

**[MEDIUM] No web hover states** — `MouseRegion(cursor: SystemMouseCursors.click)` in only 13 files. All `GestureDetector` cards show default arrow cursor on petfolio.live.

**[MEDIUM] `_SpotlightCarousel` and `_DealsSection` contain hardcoded placeholder data**
Violates CLAUDE.md "No Mock Data" rule.

**[MEDIUM] `pillarHealth` and `pillarMarket` share the same mint color**
One-line fix: assign `AppColors.sky`/`skyD` to `pillarMarket` in `PetfolioThemeExtension`.

**[MEDIUM] `AppThemeSpacing` missing steps above 24dp**
`xs=4, sm=8, md=12, lg=16, xl=24` — codebase uses hardcoded 28, 32, 40, 48, 64, 72, 100dp.

**[LOW] `_WideNavRail` passes `indicatorColor: Colors.transparent`**
Disables the themed squircle indicator entirely on desktop. Remove the override.

**[LOW] XP gradient uses hardcoded `Color(0xFFD4AF37)` / `Color(0xFFF5D56E)` — no dark mode adaptation.**

---

## 4. Notifications & Location (8.2 / 10)

### Status Summary
FCM stack is production-grade. Background handler correctly uses `@pragma('vm:entry-point')`. Both `onMessageOpenedApp` and `getInitialMessage` wired. `FcmMessageRouter` correctly uses `router.push()` for details and `router.go()` for top-level tabs. Token lifecycle complete (upsert on login, delete on sign-out, refresh via `onTokenRefresh`). Location requests only `whileInUse` with `LocationAccuracy.medium`, battery-considerate, with `getLastKnownPosition` tried first.

### Findings

**[HIGH] Duplicate `syncToken` calls on every auth state change**
Both `main.dart` lines 145–151 and `FcmLifecycle` lines 21–29 listen to `authStateProvider`. Every startup fires two concurrent upserts; sign-out fires two concurrent deletes.
**Fix:** Remove the `authStateProvider` listener from `PetfolioApp.build()` in `main.dart`.

**[MEDIUM] `scheduleTaskReminder()` missing iOS `DarwinNotificationDetails`**
Care reminders on iOS will use defaults and may be silent if default presentation is suppressed.

**[MEDIUM] `process-fcm-outbox` silently discards per-row errors — infinite retry on malformed rows**
`processed_at` is never set on failure. A corrupt row is retried on every cron invocation forever.
**Fix:** Add `retry_count` column; skip rows above threshold (e.g., 5).

**[MEDIUM] Notification permission requested at cold launch before user context**
On Android 13+ / iOS, the system permission dialog fires immediately on cold start before the user interacts with any notification-relevant feature.

**[MEDIUM] Chat messages on iOS may be silenced in background**
APNs payload missing `content-available: 1` for chat message type — messages may not arrive when the iOS app is terminated.

**[LOW] Location stored server-side without explicit privacy consent dialog**
`syncActorLocationFromDevice()` writes GPS to Supabase with no in-app disclosure that it's stored and visible to other users.

**[LOW] `_setLocalTimezone` uses fragile offset-matching heuristic**
Can select the wrong timezone during DST transitions. Use `flutter_timezone` package instead.

---

## 5. User Stories & Flows

### 5.1 Auth & Onboarding
✅ Email sign-up/sign-in, password reset, session restore, auto-redirect to `/onboarding` for new users
**Gap:** Registration uses raw Supabase error text (no `_friendlyAuthError` mapping). No Google/Apple sign-in.

### 5.2 Pet Profile Management
✅ 5-step animated onboarding, multi-pet add, edit profile, avatar upload, `PetSwitcherSheet`
**Gap:** No avatar upload during onboarding. AI breed detection disabled on web (`kIsWeb`). Step 0 "skip" text confusing for `mode=add` flow.

### 5.3 Social (Feed, Posts, Stories, Communities)
✅ Infinite-scroll feed, 4-reaction emoji picker, double-tap like, comments, create post, stories, communities, follow/unfollow
**Gaps:**
- **Share and Save are UI-only stubs** — `_ActionBtn` taps are silently ignored
- **Stories have no TTL/expiry mechanism** — accumulate indefinitely
- No Followers/Following list screen — stats are non-navigating
- Post creation supports only single image despite `imageUrls` being a list
- No location tagging in `CreatePostScreen`
- Post visibility chevron is a no-op
- No image sending or read receipts in chat

### 5.4 Care & Health
✅ Daily tasks with category filter, mark-complete with gamification, AI routine generation, medical vault, vitals chart, weight logging, calendar appointments
**Gaps:**
- **NutritionScreen is misnamed** — tracks weight only, no calorie/meal logging
- **No appointment notification system** — appointments created but no FCM/local notification scheduled
- No re-trigger for AI routine after initial dismissal
- No edit/delete for appointments (add only)

### 5.5 Pet Discovery & Matching
✅ Location-based swipe discovery, match preferences, mutual-match celebration via Realtime, chat inbox, liked pets grid
**Gaps:**
- Location required with no fallback for permanently-denied permission
- No "who liked me" reverse view
- No image sending or read receipts in chat

### 5.6 Marketplace — Buyer Journey
✅ Browse with category + search, product detail carousel, add-to-cart with fly animation, per-vendor checkout, Stripe PaymentSheet (mobile) + hosted Checkout (web), order history
**Gaps:**
- **"Set address" tap in delivery strip is a no-op** (`GestureDetector(onTap: () {})`)
- **No buyer-facing order cancellation** despite `cancelOrder` RPC existing
- **No coupon apply UI** despite full backend scaffolding
- Cart shows hardcoded "ships to Brooklyn"
- No product sort control
- Single-variant only (no S/M/L, flavors)

### 5.7 Vendor Journey
✅ 3-step KYC wizard, resubmit on rejection, product management, order status updates, Stripe Connect onboarding with auto-refresh
**Gaps:**
- **No vendor earnings/ledger screen** — Quick Actions has no Earnings entry
- **No product image upload** in `AddEditProductScreen`
- **`/seller` route not registered** in router — `MeScreen` tap crashes

### 5.8 Order Management
✅ PaymentSheet (mobile) + hosted Checkout (web), admin KYC review, vendor order status lifecycle
**Gaps:**
- No checkout address-confirmation step
- Web Stripe return path idempotency needs verification

---

## 6. Dependency Upgrade Plan

### Flutter & Dart SDK

| Item | Current | Latest | Priority |
|------|---------|--------|----------|
| Flutter SDK | 3.22.0 | **3.44.0** | **High** |
| Dart SDK | ^3.11.5 | **3.12.0** | **High** |

**Flutter 3.44 migration steps:**
1. `flutter upgrade`
2. Test `TailWagLoader` and `GlassCard` custom painters under mandatory Impeller (Android 10+)
3. Migrate Android to AGP 9 / Kotlin DSL
4. Check iOS plugins for Swift Package Manager compatibility (`permission_handler`, `flutter_stripe`)
5. Replace `Color.withOpacity()` with `.withValues(alpha: 0.x)` across codebase

### Package Upgrades

| Package | Current | Latest | Priority | Notes |
|---------|---------|--------|----------|-------|
| `supabase_flutter` | 2.9.0 | 2.12.0 | **High** | Audit `SupabaseAuth.instance.onAuthChange` usages before upgrade |
| `firebase_messaging` | 15.2.10 | 16.1.0 | **High** | Major bump — test background handling on both platforms |
| `cached_network_image` | 3.4.1 | Unmaintained | **High** | Migrate to `cached_network_image_ce` (drop-in community fork, fixes memory leaks + scroll perf) |
| `google_fonts` | 8.1.0 | 8.x | **Medium** | Requires Flutter 3.35+/Dart 3.9 — resolves after SDK upgrade |
| `image_picker` | 1.1.2 | 1.2.1 | **Medium** | New `pickMultiVideo` + `limit` param |
| `video_player` | 2.9.3 | 2.10.0 | **Medium** | Java 17 compat required in `build.gradle` |
| `build_runner` | 2.4.15 | 2.11.1 | **Medium** | Dev dep only |
| `flutter_stripe` | 12.6.0 | 12.6.0 | **Medium** | Already latest; ensure `proguard-rules.pro` contains Stripe keep rules |
| `geolocator` | 14.0.0 | 14.0.2 | **Low** | Bug fixes |
| `permission_handler` | 12.0.0 | 12.0.0+1 | **Low** | Patch fix |
| `flutter_animate` | 4.5.0 | 4.5.2 | **Low** | |
| `shared_preferences` | 2.5.3 | 2.5.4 | **Low** | |
| `json_serializable` | 6.9.4 | 6.10.x | **Low** | Dev dep only |
| `flutter_riverpod` / `go_router` / `freezed` | latest | latest | — | Already on latest stable |

### M3 Expressive Readiness
M3 Expressive is **not yet in Flutter's core framework** — shipping via standalone `material_ui` package (announced Google I/O 2026, monitor pub.dev/packages/material_ui). When stable, prioritize: Expressive `NavigationBar`, Expressive Buttons, `BottomSheet` expanded/peek states. PetFolio already uses `RoundedSuperellipseBorder` (Flutter 3.32+), putting it ahead of most apps.

**Flutter Web WASM:** Enable with `flutter build web --wasm` for 2–3x faster JS execution on petfolio.live. iOS browsers automatically receive the JS fallback.

---

## 7. Action Plan

### P0 — Critical (This Week)
> Fix these before any marketing push or expanded beta testing.

1. **Restrict Firebase API keys** — Firebase Console: add HTTP referrer restrictions (web key) + app restrictions (Android/iOS). Begin migration of `firebase_options.dart` out of source control.
2. **Fix iOS bundle ID** — Change `com.example.petfolio` → real production bundle ID. APNs push dead until this is done.
3. **Register 3 missing GoRouter routes** — Add `/settings/addresses`, `/offers`, `/seller` to `app_shell_routes.dart`, OR remove the tapping surfaces from [`me_screen.dart`](lib/features/profile/presentation/screens/me_screen.dart).
4. **Fix registration error messages** — Apply `_friendlyAuthError()` in [`registration_screen.dart`](lib/features/auth/presentation/screens/registration_screen.dart) `_submit()`.
5. **Remove duplicate `syncToken` listener** — Delete `authStateProvider` listener from `PetfolioApp.build()` in [`main.dart`](lib/main.dart).
6. **Fix "Set address" no-op** — Replace `GestureDetector(onTap: () {})` with `showModalBottomSheet(builder: (_) => AddressSheet())` in [`marketplace_screen.dart`](lib/features/marketplace/presentation/screens/marketplace_screen.dart).

### P1 — High (This Sprint)
1. Add buyer order cancellation to `BuyerOrderDetailScreen` (status == pending only)
2. Wire promo/coupon UI in `CartScreen` → `filteredPromosProvider`
3. Add `expires_at` to `stories` table + pg_cron cleanup + filter in `storiesProvider`
4. Implement or visually disable Share/Save actions on `PostCard`
5. Add vendor earnings screen to seller dashboard Quick Actions
6. Rename `NutritionScreen` to "Weight & Health Tracker" or implement meal logging
7. Wire appointment notifications (local `scheduleTaskReminder` + FCM)
8. Move NVIDIA API calls to Edge Functions (apply existing web pattern to mobile)
9. Increase password minimum to 8 characters (both screens + Supabase Auth policy)
10. Upgrade `supabase_flutter` to 2.12.0

### P2 — Medium (Next Sprint)
1. Extract domain use-cases from `PetCareRepository` (start: `ToggleCareTaskUseCase`, `PetBadgeService`)
2. Create `core/providers/` facade layer for cross-feature state access
3. Split `activePetControllerProvider` into metadata + persistence layers
4. Define `supabaseClientProvider` and inject across 46 files
5. Replace `GestureDetector + AnimatedScale` with `InkWell + Material` in bento grid; create `TappableCard`
6. Audit and replace raw `TextStyle` literals (start: `hub_home_screen.dart` — 74 occurrences)
7. Add `Semantics` coverage to bento grid, `_HeaderIconBtn`, `TailWagLoader`
8. Add product image upload to `AddEditProductScreen`
9. Wire Followers/Following list navigation in `SocialProfileScreen`
10. Remove `indicatorColor: Colors.transparent` from `_WideNavRail`
11. Assign `AppColors.sky` to `pillarMarket` (one-line fix in `app_theme.dart`)
12. Extend `AppThemeSpacing` above 24dp (add `2xl=32, 3xl=48, 4xl=64, 5xl=96`)
13. Upgrade `firebase_messaging` 15→16 with FlutterFire migration
14. Migrate `cached_network_image` → `cached_network_image_ce`
15. Add `DarwinNotificationDetails` to `scheduleTaskReminder()` for iOS care reminders
16. Fix `process-fcm-outbox` dead-letter mechanism

### P3 — Backlog
- Add Google Sign-In (significant signup friction reduction)
- Replace `AppColors.blue*` aliases with correct semantic tokens
- Add `AppColors.gold/goldLight` tokens; remove hardcoded `Color(0xFFD4AF37)`
- Standardize `flutter_animate` usage or remove it (currently in 1 file)
- Add product sort control to marketplace (`filteredProductsProvider`)
- Add post location tagging in `CreatePostScreen`
- Replace `_setLocalTimezone` heuristic with `flutter_timezone` package
- Use stable hash (CRC32) for notification IDs
- Add `admin_users` table cross-check for admin RPCs (defence-in-depth)
- Wrap `markCashReceived`/`markShopPaid` in SECURITY DEFINER RPCs
- Add `content-available: 1` to iOS chat FCM messages
- Add privacy consent dialog before first `syncActorLocationFromDevice()` call
- Start unit test coverage (care date math, `CartNotifier`, `RouterNotifier.redirect`)
- Medical vault PDF export

---

