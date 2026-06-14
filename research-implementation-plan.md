# PetFolio — Gap Analysis & Refactor / Feature Plan

## Context

The PetFolio Flutter + Supabase app was reviewed against the *Product Specification Report* (4-pillar pet super-app for Bangladesh), the `lib/` codebase, and the live Supabase project (`jqyjvhwlcqcsuwcqgcwf`, 46 tables, 30+ RPCs, RLS on every table).

**Key finding:** the app is far more mature than a greenfield gap-exercise would assume. All four pillars (Social, Matching, Health/Care, Commerce) are built, Supabase-wired with Freezed models, Riverpod controllers, and real repositories — no mock data. The actual gaps are three kinds:

1. **Bangladesh-localization deviations** from the report's thesis (payments are Stripe-only; no bKash/Nagad).
2. **Feature-depth holes** versus the spec (matching has no breeding mode; health lacks meds/vaccines/reminders; social lacks hashtags/general DMs; commerce lacks variants/Rx).
3. **Security/quality debt** flagged by Supabase advisors.

This plan closes the gaps the user selected: **bKash/Nagad/COD payments**, **all four feature-depth builds**, and **security hardening (deferred to a later phase)**. Bengali i18n and phone-OTP auth are explicitly **deferred** per user direction.

Execution follows the repo's mandated order (CLAUDE.md §5): **SQL schema/RLS → Freezed models → repositories → controllers → UI**, and the **no-documentation / no-inline-comment** rule. Each phase ends with `flutter analyze` + `flutter test`, an update to `progress.md`, and a `/remember` prompt.

---

## Current State Summary (verified)

| Pillar | Status | Tables present |
|---|---|---|
| Social | Built | `posts, post_likes, comments, comment_likes, stories, story_reactions, pet_follows, notifications, communities, community_*` |
| Matching | Built (generic) | `swipes, matches, chat_threads, chat_messages` |
| Health/Care | Built | `care_tasks, care_logs, care_streaks, pet_badges, pet_care_gamification, health_logs, health_vitals, medical_vault, pet_weight_logs, appointments, vet_clinics, vet_services, care_web_reminders` |
| Commerce | Built | `products, shops, marketplace_orders, product_reviews, promos, user_addresses, vendor_ledgers, inventory_reservations, shop_deletion_requests, audit_logs` |
| Cross-cutting | Partial | `users, user_fcm_devices, user_web_push_subscriptions, fcm_push_outbox, waitlist` |

Payments today: **Stripe + COD** via Edge Functions `create-payment-intent`, `stripe-onboard-vendor`. i18n: **none**. Offline DB: **none**. Auth: **email/password only**.

---

## Phase 1 — Matching: Breeding + Playdate Modes
*Spec §6. Today only a generic swipe/match deck exists.*

**Schema (new migration):**
- `match_profiles` (pet_id, mode `breeding|playdate`, is_active, play_style, energy_level, preferred_size, availability)
- `pet_pedigree` (pet_id, sire_ref, dam_ref, registry_name, registry_id, titles)
- `pet_health_certs` (pet_id, cert_type, file_path, verified, verified_by, expires_at)
- `playdates` (match_id, scheduled_at, location_name, geog, status)
- `verifications` (user_id, type, status, reviewed_at)
- Add `mode` column to `swipes`/`matches`; extend `matching_discovery_candidates` RPC with `p_mode` + breeding species/breed restriction + vaccination-cert gating.
- New bucket `health-certs` (private, signed URLs).

**Dart:** Freezed models per table → extend `matching_repository.dart` / `matching_supabase_data_source.dart` → mode-toggle controller + playdate scheduler controller → UI: mode toggle on `matching_screen.dart`, breeding profile editor, playdate scheduler, verification center, expanded cert view on match card.

**Reuse:** existing swipe/match flow, `location_service.dart`, `flutter_map` for playdate location suggestions.

---

## Phase 2 — Health: Medications, Vaccines, Reminders, Summaries
*Spec §7. Care tasks/streaks/vault exist; clinical depth missing.*

**Schema:**
- `medications` (pet_id, name, dose, frequency, times[], start_date, end_date) + `medication_logs` (medication_id, given_at, given_by) — overdose-guard via unique-per-window.
- `vaccinations` (pet_id, vaccine, date_given, next_due, vet, cert_path).
- Generalize reminders: extend existing `care_web_reminders` or add `reminders` (pet_id, ref_type, ref_id, fire_at, channel, sent) wired to `NotificationService.scheduleTaskReminder` + FCM.
- `streak_freezes` count on `care_streaks` (add column) — humane, configurable.

**Dart:** models → extend `health_repository.dart` / `pet_care_repository.dart` → medication + vaccination controllers, reminder scheduler → UI: medications list/add, vaccination schedule, reminder editor, **symptom checker** (multi-step, non-diagnostic disclaimers, never blocks emergency), **shareable health summary** (PDF via existing `share_plus`).

**Reuse:** `fl_chart` (already used for vitals), `medical_vault` patterns, local-notification stack.

---

## Phase 3 — Social: Hashtags, General DMs, Saves
*Spec §5. Feed/stories/comments/follows/communities exist; discovery + messaging thin.*

**Schema:**
- `hashtags` + `post_hashtags` (tag, post_id); `pg_trgm` index for search.
- General DM: reuse existing `get_or_create_social_thread` RPC + `chat_threads`/`chat_messages` (already present) — extend to non-match owner-to-owner threads.
- `saved_posts` (user_id, post_id) for bookmarks.

**Dart:** models → extend `social_repository.dart` → hashtag/search controller, DM inbox controller (generalize matching chat controllers) → UI: hashtag page, unified search bar, DM inbox/conversation, save/bookmark action + saved screen. Optionally seed `reels` as a `posts.type` value.

**Reuse:** matching `chat_screen.dart` + chat controllers (generalize, don't duplicate), `flutter_linkify` for hashtag rendering.

---

## Phase 4 — Commerce: Variants, Wishlist, Rx, Shipments
*Spec §8. Catalog/orders/KYC/payouts strong; depth missing.*

**Schema:**
- `product_variants` (product_id, attributes jsonb, price, stock, sku); refactor `process_checkout` + `inventory_reservations` to variant granularity.
- `wishlists`/`wishlist_items`.
- `prescriptions` (order_item_id, file_path, vet_info, status); `products.is_rx` gating in checkout (hold order until verified).
- `shipments` (order_id, courier, tracking_id, status) — promote tracking fields off `marketplace_orders`.
- `coupons` separate from `promos` if needed.

**Dart:** models → extend `product_repository.dart` / `order_repository.dart` → variant selector, wishlist, prescription-upload, checkout RX-hold controllers → UI: variant picker on product detail, wishlist screen, prescription upload, shipment tracking. Bucket `prescriptions` (private).

**Reuse:** cursor-pagination pattern in `product_repository.dart`, existing cart/checkout controllers, admin KYC-review pattern for Rx verification.

---

## Phase 5 — Payments: bKash / Nagad / COD (Bangladesh)
*Spec §8, user-selected. Today: Stripe + COD only.*

- New Edge Function(s): SSLCommerz aggregator (covers bKash, Nagad, Rocket, cards in one integration) — `create-sslcommerz-session` + webhook handler with **idempotent** payment confirmation and reconciliation.
- Extend `marketplace_orders.payment_method` enum: add `bkash`, `nagad`, `sslcommerz`.
- Dart: extend `MarketplaceOrder` enums + `order_repository.dart` + checkout controller; add payment-method selector and webview/redirect handling (mirror existing Stripe `web_checkout_redirect` pattern).
- Keep Stripe path intact for global/card.

**Reuse:** existing `create-payment-intent` Edge Function structure, `web_checkout_resume_listener.dart`, COD flow already present.

---

## Phase 6 — Security Hardening (deferred, per user)
*From Supabase advisors — [linter docs](https://supabase.com/docs/guides/database/database-linter).*

- Revoke `EXECUTE` from `anon` on `SECURITY DEFINER` RPCs not meant to be public (`dec/inc_community_*_count`, `get_care_dashboard_snapshot`, `toggle_care_task`, `refresh_product_rating_stats`); keep `authenticated` only where intended.
- Set explicit `search_path` on `private.fcm_data_to_text_map` (and audit all functions).
- Add an RLS policy (or disable RLS appropriately) on `fcm_push_outbox` (RLS enabled, no policy).
- Tighten `appointment-media` public bucket — remove broad listing SELECT policy.
- Enable **leaked-password protection** in Auth settings.
- Re-run `get_advisors(security)` + `get_advisors(performance)` to confirm clean.

---

## Cross-Cutting (apply throughout)
- Every new table: **RLS policies** (per-owner / per-pet), FKs with `on delete cascade`, `created_at timestamptz default now()`, UUID PKs.
- Private buckets via **signed URLs** (`health-certs`, `prescriptions`).
- After each `@freezed`/`@riverpod` change: `dart run build_runner build --delete-conflicting-outputs`.
- No inline comments / dartdocs (CLAUDE.md rule). Use `AppTheme`/`AppColors`, no hardcoded colors.

---

## Verification (per phase)
1. `dart run build_runner build --delete-conflicting-outputs`
2. `flutter analyze` — zero issues
3. `flutter test`
4. Apply migrations to a Supabase **branch** first (`create_branch`), validate with `execute_sql`, then `merge_branch`.
5. Manual run via `flutter run --dart-define-from-file=.env`; exercise the new flow on emulator.
6. After schema changes, re-run `get_advisors` to catch new RLS gaps.
7. Update `progress.md`; prompt user to run `/remember`.

## Critical files
- Matching: `lib/features/matching/data/{datasources,repositories}/`, `presentation/screens/matching_screen.dart`
- Health: `lib/features/care/data/repositories/{health_repository,pet_care_repository}.dart`, `presentation/screens/`
- Social: `lib/features/social/data/repositories/social_repository.dart`, reuse `lib/features/matching/presentation/screens/chat_screen.dart`
- Commerce: `lib/features/marketplace/data/repositories/{product_repository,order_repository}.dart`
- Payments: Supabase Edge Functions + `order_repository.dart` + `lib/core/platform/web_checkout_redirect*.dart`
- Router: `lib/core/router.dart` + per-feature `*_routes.dart`

## Suggested sequencing
Phases are independent; recommended order = **1 → 2 → 3 → 4 → 5 → 6** (highest feature value first, payments once commerce depth lands, security hardening last per user). Each phase is one `/remember` cycle.