# PetFolio Codebase Performance, Supabase, UX, and Feature Review

Date: 2026-05-22  
Scope: `lib/`, `supabase/`, tests, hosted Supabase project `jqyjvhwlcqcsuwcqgcwf` (`petfolio`)  
Verification: `flutter analyze` passed; `flutter test` passed; Supabase MCP advisors and recent logs reviewed.  
Browser note: the Browser/browser-use skill was loaded, but the required Node REPL browser runtime tool was not exposed in this session, so rendered browser navigation/screenshots were not available. Online research was completed through web search and Supabase MCP docs.

## Executive Summary

The app is in solid shape from a Dart analyzer and basic unit/widget-test perspective, but the hosted Supabase project currently has several high-priority security/performance advisor findings. The most important work is database hardening: revoke anonymous execution from `SECURITY DEFINER` RPCs, fix RLS policies that still call `auth.uid()` per row, add missing foreign-key indexes, consolidate duplicate permissive policies, and remove broad public storage listing policies.

The largest app-side optimization opportunities are in network/query consolidation. Care dashboard, social profile stats, matching discovery, and admin dashboard flows issue multiple small reads in quick succession. Several should move to RPCs/views with explicit filters and counts. Marketplace search and product loading are still client-side over all products/shops, which will degrade as catalog size grows.

## Highest Priority Findings

### 1. Many `SECURITY DEFINER` functions are executable by `anon`

Severity: Critical  
Area: Supabase security

Supabase Security Advisor reports anonymous execution for sensitive `SECURITY DEFINER` functions including `approve_vendor_kyc`, `reject_vendor_kyc`, `process_checkout`, `cancel_order`, `vendor_update_order`, `ensure_chat_thread_for_match`, `check_daily_completion`, `confirm_order_inventory`, `release_order_inventory`, `request_shop_deletion`, `resolve_reported_post`, `resolve_shop_deletion`, and trigger/helper functions.

Evidence:

- `supabase/migrations/20260520120000_admin_kyc_rpc.sql:132` grants `approve_vendor_kyc` to `authenticated`, but advisor shows default/public grants still allow `anon`.
- `supabase/migrations/20260523120000_reject_vendor_kyc.sql:61` grants `reject_vendor_kyc` to `authenticated`, but advisor still reports anon execution.
- `supabase/migrations/20260523100000_checkout_pricing_and_reservations.sql:34` creates `process_checkout` as `SECURITY DEFINER`.
- `supabase/migrations/20260518180000_chat_threads_race_condition.sql:1` creates `ensure_chat_thread_for_match` as `SECURITY DEFINER`.

Impact:

- Even when functions perform internal auth checks, exposing definer functions to `anon` expands the attack surface and keeps every bug in function authorization reachable through `/rest/v1/rpc/...`.
- Trigger functions such as `handle_post_like_sync()` and `handle_post_comment_sync()` should generally not be REST-callable at all.

Recommended fix:

- Add a migration that revokes public execution first, then grants only intended roles:
  - `revoke execute on function ... from public, anon;`
  - `grant execute on function ... to authenticated;` only for client-callable RPCs.
  - Do not grant trigger-only functions to API roles.
- Consider moving privileged helper functions to a private schema and exposing only narrow invoker-safe wrappers when needed.

### 2. Hosted RLS policies still have `auth.uid()` init-plan performance issues

Severity: High  
Area: Supabase performance

Supabase Performance Advisor reports `auth_rls_initplan` on `vendor_ledgers`, `pet_follows`, `comments`, `follows`, `chat_threads`, `reported_posts`, and `notifications`. Local migrations confirm several older policies still use direct `auth.uid()`.

Evidence:

- `supabase/migrations/20260514000002_add_comments_table.sql:37` uses `WITH CHECK (author_id = auth.uid())`.
- `supabase/migrations/20260514000002_add_comments_table.sql:42` uses `USING (author_id = auth.uid())`.
- `supabase/migrations/20260514000000_add_follows_table.sql:22` and `:29` use `owner_id = auth.uid()`.
- `supabase/migrations/20260520000000_add_reported_posts.sql:14` and `:18` use direct `auth.uid()`.
- `supabase/migrations/20260520120000_admin_kyc_rpc.sql:48`, `:50`, `:60`, `:62` use direct `auth.uid()`.
- `supabase/migrations/20260519040000_vendor_kyc_ledger.sql:122` uses direct `auth.uid()`.

Impact:

- RLS expressions may execute auth helper functions per touched row instead of once per statement. Supabase docs call this out as a major scale bottleneck.

Recommended fix:

- Replace stable auth checks in RLS with `(select auth.uid())`, `(select auth.jwt())`, or `(select is_admin())` where the value does not depend on the row.
- Add explicit `TO authenticated` to owner-only policies so `anon` requests do not run unnecessary auth logic.

### 3. Missing foreign-key indexes on active tables

Severity: High  
Area: Supabase performance

Performance Advisor reports unindexed FKs on:

- `audit_logs.admin_id`
- `comments.pet_id`
- `match_requests.requester_pet_id`
- `match_requests.target_pet_id`
- `notifications.actor_pet_id`
- `notifications.post_id`
- `notifications.recipient_user_id`
- `post_likes.pet_id`
- `reported_posts.reporter_id`
- `reported_posts.reviewed_by`
- `shop_deletion_requests.owner_id`

Impact:

- Slower joins, deletes, RLS checks, notification reads, moderation reads, and social profile counts as data grows.

Recommended fix:

- Add targeted indexes, preferably matching actual query order/filter patterns. Examples:
  - `comments(post_id, created_at)` for comment lists plus `comments(pet_id)` for FK/advisor.
  - `notifications(recipient_user_id, created_at desc)` plus FK indexes for `actor_pet_id` and `post_id`.
  - `post_likes(post_id, pet_id)` or existing unique index plus `post_likes(pet_id)`.
  - `reported_posts(status, created_at desc)` plus FK indexes.

### 4. Duplicate permissive RLS policies increase execution cost and review risk

Severity: High  
Area: Supabase policy hygiene

Performance Advisor reports multiple permissive policies on `shop_deletion_requests`, `chat_threads`, `marketplace_orders`, `pet_follows`, `posts`, `reported_posts`, `shops`, `users`, and `vendor_ledgers`.

Impact:

- Multiple permissive policies for the same role/action are evaluated separately and are harder to reason about. This raises both performance cost and authorization review risk.

Recommended fix:

- Consolidate policies by table/action/role. For example, one `SELECT TO authenticated` policy on `shops` can combine public active verified, owner, and admin access with a single expression.
- Drop legacy duplicate policies after confirming coverage with role-based tests.

### 5. Public storage buckets allow broad object listing

Severity: High  
Area: Supabase storage security/privacy

Security Advisor reports broad SELECT policies on public buckets:

- `marketplace-images`
- `pets`
- `post-images`
- `shops`

Evidence:

- `supabase/migrations/20260519030000_marketplace_images_bucket.sql:23` uses `USING (bucket_id = 'marketplace-images')`.
- `supabase/migrations/20260523110000_post_images_bucket.sql:15` uses `USING (bucket_id = 'post-images')`.

Impact:

- Public URL reads may be acceptable, but broad object SELECT policies let clients list bucket contents. That can expose file names, folder structure, user IDs embedded in paths, and asset inventory.

Recommended fix:

- Remove broad list policies where public object URLs are enough.
- If SELECT is needed, constrain by folder/owner and `TO authenticated`, or use signed URLs for sensitive content.

### 6. `inventory_reservations` has RLS enabled but no policy

Severity: Medium  
Area: Supabase security/maintainability

Security Advisor reports `public.inventory_reservations` has RLS enabled and no policies.

Evidence:

- `supabase/migrations/20260523100000_checkout_pricing_and_reservations.sql:27` enables RLS.
- Same migration says writes should go through `SECURITY DEFINER` RPCs.

Impact:

- If this is intentional internal-only state, it should be documented and protected by revoked direct grants. If not intentional, clients will see confusing access failures.

Recommended fix:

- Keep no client policies if RPC-only is intended, but explicitly revoke table privileges from `anon`/`authenticated` and document the design.
- Otherwise add narrow read policies for buyers/vendors/admins.

### 7. Recent logs show repeated matching/location calls and one chat thread constraint error

Severity: Medium  
Area: Matching performance/functionality

Recent API logs show repeated `pets?select=id...location=not.is.null` calls and multiple `matching_discovery_candidates` RPC calls close together. Postgres logs show `new row for relation "chat_threads" violates check constraint "no_self_thread"` after a `POST /rpc/ensure_chat_thread_for_match` returned 400.

Evidence:

- `lib/features/matching/data/datasources/matching_supabase_data_source.dart:16` calls `petHasLocation`.
- `lib/features/matching/data/datasources/matching_supabase_data_source.dart:30` calls `matching_discovery_candidates`.
- `lib/features/matching/data/datasources/matching_supabase_data_source.dart:223` calls `ensure_chat_thread_for_match`.

Impact:

- Location/status checks are being repeated in bursts.
- `ensure_chat_thread_for_match` can still hit self-thread data or stale/invalid match data and fail with a database constraint error.

Recommended fix:

- Cache `petHasLocation` per active pet during a matching session and invalidate after location sync.
- Add a precondition in `ensure_chat_thread_for_match` to return a typed error before insert when participants collapse to the same owner/pet, and surface a friendly UI message.
- Consider logging structured function errors into `audit_logs` for matching edge cases.

## App-Side Performance and Feature Findings

### 8. Social feed fetch embeds all likes for each post

Severity: High  
Area: Social feed query scaling

Evidence:

- `lib/features/social/data/repositories/social_repository.dart:47` selects posts plus `post_likes(pet_id)`.
- `lib/features/social/data/repositories/social_repository.dart:56` fetches nested `post_likes(pet_id)` for every feed post.

Impact:

- As posts become popular, each feed row can carry a growing nested likes payload just to compute `isLiked` for the active pet. This inflates response size and RLS work.

Recommended fix:

- Move feed shaping to an RPC/view that returns a boolean `liked_by_active_pet`, counts, author/pet metadata, and first image URL.
- Avoid returning all `post_likes`; use `exists(...)` in SQL against the active pet.

### 9. Social profile stats issue three count queries per profile

Severity: Medium  
Area: Social/profile performance

Evidence:

- `lib/features/social/data/repositories/social_repository.dart:280` runs three parallel count queries for posts, followers, and following.

Impact:

- Profile screen opens produce extra round trips and will become noisy in list/profile navigation.

Recommended fix:

- Add `get_pet_social_stats(p_pet_id)` RPC or a stats view/materialized counters updated by triggers.

### 10. Marketplace product and shop discovery are unpaginated and client-filtered

Severity: High  
Area: Marketplace scaling/UX

Evidence:

- `lib/features/marketplace/data/repositories/product_repository.dart:24` fetches all active products.
- `lib/features/marketplace/presentation/controllers/product_list_controller.dart:30` filters all products by category and search in memory.
- `lib/features/marketplace/data/repositories/shop_repository.dart:25` fetches all active verified shops.
- `lib/features/marketplace/presentation/screens/marketplace_screen.dart:395` renders all discovered shops in a horizontal list.

Impact:

- Catalog search, initial marketplace load, and memory use will degrade as vendors/products grow.

Recommended fix:

- Add server-side paginated/search RPCs or views:
  - `search_products(q, category, cursor, limit)`
  - `discover_shops(cursor, limit)`
- Use full-text/trigram indexes for name/brand/shop search.
- Keep client providers keyed by query/category/cursor instead of one global all-products provider.

### 11. Admin dashboard counts fetch rows and count locally

Severity: Medium  
Area: Admin performance

Evidence:

- `lib/features/admin/data/repositories/admin_repository.dart:184` fetches shop IDs and returns list length.
- `lib/features/admin/data/repositories/admin_repository.dart:190` fetches all paid platform fees and folds client-side.
- `lib/features/admin/data/repositories/admin_repository.dart:222` fetches rows for overview metrics and counts locally.

Impact:

- Admin screens will become expensive with order/ledger growth.

Recommended fix:

- Move overview to one RPC such as `get_admin_overview_metrics()` returning counts and sums from SQL.
- Use `count(CountOption.exact)` only when the exact count is needed and row payload is not.

### 12. Care dashboard loads several related resources as separate requests

Severity: Medium  
Area: Care dashboard performance

Evidence:

- `lib/features/care/presentation/controllers/care_dashboard_controller.dart:151` fetches selected-date tasks.
- `:154` may fetch today tasks separately.
- `:155` fetches badges.
- `:156` fetches week goal state.
- Logs show `care_tasks`, `care_logs`, `pet_badges`, `care_streaks`, and `medical_vault` requests clustering during screen/profile loads.

Impact:

- On slower mobile networks, care/profile startup will feel busy and may show staggered loading states.

Recommended fix:

- Add a dashboard RPC such as `get_care_dashboard_snapshot(p_pet_id, p_selected_date)` returning tasks, today tasks, week goal, streak, and badges in one round trip.
- Keep the existing realtime listener for streak updates.

### 13. `toggleTaskCompletion` optimistically updates then reloads everything

Severity: Medium  
Area: Care interaction latency/network

Evidence:

- `lib/features/care/presentation/controllers/care_dashboard_controller.dart:252` performs optimistic update.
- `:271` calls repository toggle.
- `:298` calls `_load(...)` after success.

Impact:

- The immediate UI feels responsive, but every toggle forces the full dashboard query set again. Repeated checkbox taps can create request bursts.

Recommended fix:

- Let `toggleCompletion` return enough state to patch the local dashboard without a full reload.
- Debounce or coalesce follow-up reloads when badges/streak data must refresh.

### 14. Product/shop images use `Image.network` in several marketplace/admin views

Severity: Medium  
Area: UI smoothness/bandwidth

Evidence:

- `lib/features/marketplace/presentation/screens/marketplace_screen.dart:444`
- `lib/features/marketplace/presentation/screens/vendor/seller_dashboard_screen.dart:443`
- `lib/features/marketplace/presentation/screens/vendor/edit_shop_screen.dart:345`
- `lib/features/marketplace/presentation/screens/customer/shop_storefront_screen.dart:134` and `:168`
- `lib/features/admin/presentation/widgets/kyc_approvals_tab.dart:406`

Impact:

- `Image.network` lacks the app's existing disk/memory caching and decode sizing patterns used by `PetAvatar`/social images.

Recommended fix:

- Standardize remote image rendering with a shared cached image widget using `CachedNetworkImage`, size-aware cache widths, placeholders, and error states.

### 15. `fetchMyShop` uses two queries for a common path

Severity: Low/Medium  
Area: Marketplace seller startup

Evidence:

- `lib/features/marketplace/data/repositories/shop_repository.dart:43` queries active shop.
- `:51` falls back to all shops if none active.

Impact:

- Seller surfaces and profile shop widgets may do two round trips for inactive/deleted shops.

Recommended fix:

- Use one query ordered by `is_active desc, created_at desc` and `limit(1)`.

### 16. `myShopProvider.refreshAfterOnboarding` can still set long-lived error state in some cases

Severity: Low  
Area: Marketplace UX consistency

Evidence:

- `lib/features/marketplace/presentation/controllers/my_shop_controller.dart:105` catches refresh errors.
- `:106` sets `AsyncValue.error` when the previous state has no value.

Impact:

- This mostly follows the learned preference when previous data exists, but first-load transient failures can still replace the shop surface with a long-lived error.

Recommended fix:

- For one-off onboarding refresh, prefer retaining prior/empty state and surfacing `AppSnackBar.showError`, then allow explicit retry.

### 17. Architecture rule is not strictly feature-first

Severity: Medium  
Area: Architecture consistency

Evidence:

- Shared code exists under `lib/core/` for router, theme, widgets, services, and models.
- `lib/core/models/pet.dart` duplicates the canonical `lib/features/pet_profile/data/models/pet.dart` concept.

Impact:

- The project's AGENTS rule says all code should live under `lib/features/<feature>/`. The current `core` layer is useful but violates that written rule and can encourage cross-feature coupling.

Recommended fix:

- Either update AGENTS architecture guidance to explicitly allow `lib/core/` for app shell/design-system primitives, or migrate shared services into feature-owned APIs with narrow public exports.
- Remove or deprecate duplicate pet models once no longer referenced.

### 18. Generated Riverpod annotations are not consistently used

Severity: Low/Medium  
Area: Maintainability

Evidence:

- Many providers are manual `Provider`, `NotifierProvider`, or `AsyncNotifierProvider` declarations even though `riverpod_annotation` and generator are configured.
- Examples: `lib/features/marketplace/presentation/controllers/product_list_controller.dart:10`, `lib/features/social/presentation/controllers/social_controller.dart:46`, `lib/features/care/presentation/controllers/care_dashboard_controller.dart:46`.

Impact:

- Manual providers are valid, but mixed styles reduce consistency and make provider naming/family changes more error-prone.

Recommended fix:

- Gradually migrate feature controllers/repositories to generated Riverpod where it improves consistency. Keep manual providers only where there is a clear reason.

## UX Improvement Opportunities

1. Marketplace search should become server-backed with loading, empty, and typo-friendly states. The current client filter is fast for small catalogs but does not scale.
2. Care dashboard should avoid full spinner resets for partial failures. Keep last-known tasks visible and show inline retry/snackbar for badges or weekly goal failures.
3. Matching should show a specific message when chat-thread creation fails because of invalid/self match data, instead of surfacing a generic failure.
4. Admin screens should use paginated tables/lists for KYC, reports, deletion requests, COD reconciliation, and ledgers.
5. Use consistent cached image placeholders across marketplace, social, pet profile, and admin document preview surfaces.
6. Add visible progress and retry affordances around Stripe onboarding return/check status rather than relying only on refresh behavior.

## Supabase Remediation Plan

Recommended order:

1. Create a migration to revoke `SECURITY DEFINER` function execution from `public`/`anon`; grant only needed RPCs to `authenticated`.
2. Patch RLS policies flagged by `auth_rls_initplan` to use `(select auth.uid())`, `(select is_admin())`, and explicit `TO authenticated`.
3. Add missing FK indexes reported by Performance Advisor.
4. Consolidate duplicate permissive policies table by table.
5. Remove broad storage object listing policies on public buckets.
6. Decide and document the `inventory_reservations` access model.
7. Rerun Supabase Security and Performance Advisors.
8. Add SQL tests for privileged RPCs, owner policies, admin policies, and anonymous-denied cases.

## App Optimization Plan

Recommended order:

1. Replace social feed nested `post_likes` payload with a feed RPC/view that returns `liked_by_active_pet`.
2. Replace care dashboard fan-out with one `get_care_dashboard_snapshot` RPC.
3. Replace admin dashboard client-side counts/sums with `get_admin_overview_metrics`.
4. Add marketplace server-side search/pagination.
5. Add matching session caching for `petHasLocation` and guard `ensure_chat_thread_for_match` against self-thread inserts.
6. Standardize cached remote image widgets.
7. Add integration/widget tests for marketplace search, care toggle optimistic rollback, social feed like state, matching chat creation error, and seller onboarding refresh.

## Verification Performed

- `flutter analyze`: passed, no analyzer issues.
- `flutter test`: passed, 5 tests.
- Supabase Security Advisor: reviewed; multiple critical/warn findings listed above.
- Supabase Performance Advisor: reviewed; multiple FK/RLS/multiple-policy/unused-index findings listed above.
- Supabase API logs: reviewed; observed repeated matching/location/care/social request bursts and one `ensure_chat_thread_for_match` 400.
- Supabase Postgres logs: reviewed; observed `chat_threads` `no_self_thread` constraint violation.
- Edge Function logs: requested through app connector, but connector required reauthentication.

## Online Research Sources

- Flutter performance docs: https://docs.flutter.dev/perf
- Riverpod rebuild reduction/select docs: https://riverpod.dev/docs/how_to/select
- Supabase Database Advisors docs: https://supabase.com/docs/guides/database/database-advisors
- Supabase Row Level Security docs: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Storage Access Control docs: https://supabase.com/docs/guides/storage/security/access-control
- Supabase RLS performance docs: https://supabase.com/docs/guides/troubleshooting/rls-performance-and-best-practices-Z5Jjwv

