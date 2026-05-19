# PetFolio — Verified Issues Report

**Date:** 2026-05-19  
**Branch reviewed:** multi-vendor-marketplace (local `g:\GitHub\petfolio`)  
**Sources cross-checked:**
- `Issues and Improvement Suggestions for PetFolio.md`
- `PetFolio-deep-research.md`
- `REVIEW_FINDINGS.md`
- Full codebase pass (`lib/`, `test/`, `supabase/`)

**Method:** Each finding below was checked against source files. Status labels:

| Status | Meaning |
|--------|---------|
| **Verified** | Confirmed in current code |
| **Partial** | Partly true or implemented only in a subset |
| **Incorrect (doc)** | Claimed in audit docs but not true in codebase |
| **Stale (doc)** | Was true or referenced an older revision |

---

## Executive summary

| Category | Verified issues | Partial | Doc corrections |
|----------|-----------------|---------|-----------------|
| Core | 4 | 2 | 1 (dark mode) |
| Auth | 4 | 0 | 0 |
| Pet profile | 5 | 1 | 1 (discoverability UI) |
| Care | 6 | 2 | 0 |
| Marketplace | 10 | 2 | 2 (search shops, vendor CRUD) |
| Matching | 8 | 2 | 1 (pagination) |
| Social | 7 | 2 | 1 (follow system) |
| General | 5 | 1 | 2 (tests, webhooks) |
| **Security / payments** | **3 critical** | 1 | 1 (dotenv vs dart-define) |

**Test run (2026-05-19):** `flutter test` → **4 passed**, **1 failed** (`test/widget_test.dart`).

---

## Corrections to prior audit documents

These items appear in `Issues and Improvement Suggestions for PetFolio.md` or `PetFolio-deep-research.md` but **do not match** the current codebase. Do not prioritize fixing “missing” features that already exist.

| Prior claim | Actual state | Evidence |
|-------------|--------------|----------|
| No dark mode | **System dark/light supported** | `main.dart`: `theme`, `darkTheme`, `themeMode: ThemeMode.system`; `AppTheme.dark()` |
| No UI for `isDiscoverable` | **Toggle on edit profile** | `edit_profile_screen.dart`, `discovery_visibility_controller.dart` |
| No follower/following system | **Pet-level follow implemented** | `pet_follows` table usage in `social_repository.dart`; `follow_controller.dart`; UI on `social_profile_screen.dart` |
| Discover Shops is static | **Loaded from Supabase** | `shop_list_controller.dart` → `fetchAllActiveShops()` |
| Vendors cannot create/edit products | **Vendor CRUD exists** | `add_edit_product_screen.dart`, `vendor_product_list_screen.dart`, routes in `router.dart` |
| Matching has no pagination | **Offset paging + buffer replenish** | `discovery_candidates_controller.dart` (`_discoveryPageSize = 20`) |
| No test files / 0% coverage | **3 test files** | `test/care_*.dart` pass; only default widget test fails |
| Keys loaded via dotenv in main | **Uses `String.fromEnvironment`** | `main.dart` (`--dart-define` at build time) |
| No Stripe webhook | **Edge function exists** | `supabase/functions/stripe-webhook/index.ts` |
| flutter_stripe ^11.5 / SDK conflict | **Likely stale** | `pubspec.yaml`: SDK `^3.11.5`, `flutter_stripe: ^12.6.0` |

---

## P0 — Critical (security & payments)

### V-SEC-01: Default Supabase and Stripe keys embedded in app binary

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Critical |
| **File** | `lib/main.dart` |
| **Issue** | `String.fromEnvironment` for `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `STRIPE_PUBLISHABLE_KEY` includes **hard-coded default values**. Release builds without `--dart-define` ship real project credentials. |
| **Risk** | Credential leakage, unauthorized API use, compliance failure. |
| **Recommendation** | Remove defaults for release; fail fast if defines missing; use CI inject only. |

### V-PAY-01: Checkout success trusts client Payment Sheet, not webhook

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Critical |
| **Files** | `lib/features/marketplace/presentation/controllers/checkout_controller.dart`, `supabase/functions/stripe-webhook/index.ts` |
| **Issue** | After `Stripe.instance.presentPaymentSheet()` succeeds, app clears cart and sets `CheckoutStatus.success` without confirming server `payment_status` via webhook or polling. Webhook handler exists but client does not wait on it. |
| **Risk** | Paid UI shown when server never recorded payment; reconciliation gaps. |
| **Recommendation** | Treat webhook (or Edge Function poll) as source of truth; UI success only after order row is `succeeded`. |

### V-PAY-02: Anon key client-side (expected) — RLS must enforce all access

| Field | Detail |
|-------|--------|
| **Status** | Verified (pattern) |
| **Severity** | High (if RLS gaps exist) |
| **Issue** | Supabase anon JWT is public by design; security depends entirely on Row Level Security and Edge Function auth. |
| **Recommendation** | Periodic RLS audit; never rely on client-only checks for admin/vendor data. |

---

## Core

### V-CORE-01: No runtime accent / user-controlled theming

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low |
| **Files** | `lib/core/theme/app_theme.dart`, `lib/main.dart` |
| **Issue** | Design tokens are fixed; no setting to change accent color or override theme beyond system light/dark. |
| **Note** | Dark mode **is** supported via `ThemeMode.system` — prior doc claim “no dark mode” is **incorrect**. |

### V-CORE-02: Limited accessibility (semantics, text scaling)

| Field | Detail |
|-------|--------|
| **Status** | Partial |
| **Severity** | Medium |
| **Files** | Various; examples: `pet_avatar.dart`, `matching_screen.dart`, `primary_pill_button.dart` |
| **Issue** | Some widgets use `Semantics` / `semanticLabel`; not applied consistently. No app-wide `MediaQuery.textScaler` / respect for system font size. |
| **Recommendation** | Audit interactive controls; enable text scaling on `MaterialApp`. |

### V-CORE-03: Router lacks offline / maintenance mode guard

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low |
| **File** | `lib/core/router.dart` |
| **Issue** | Redirects cover auth, empty pets, onboarding, admin role only. No global “offline” or “maintenance” route. |

### V-CORE-04: Errors often logged with `debugPrint` only

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |
| **Files** | `matching_repository.dart`, `care_controller.dart`, `checklist_repository.dart`, `health_vault_controller.dart`, etc. |
| **Issue** | Failures (e.g. location sync, swipe insert) may not surface user-visible errors. |
| **Recommendation** | Map to `AppSnackBar` / `AppException` consistently in controllers. |

### V-CORE-05: No global `FlutterError.onError` / crash reporting

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |
| **File** | `lib/main.dart` |
| **Issue** | No zone guards, Sentry, or structured logging in app entry. |

---

## Authentication

### V-AUTH-01: Email/password only

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |
| **File** | `lib/features/auth/data/repositories/auth_repository.dart` |
| **Issue** | Only `signInWithPassword` / sign-up paths; no Google, Apple, Facebook, or anonymous auth. |

### V-AUTH-02: No password reset UI

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High |
| **Issue** | No “Forgot password?” screen; no `resetPasswordForEmail` usage in `lib/`. |

### V-AUTH-03: No MFA / phone verification

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low (product choice) |

### V-AUTH-04: Registration does not collect notification/marketing consent

| Field | Detail |
|-------|--------|
| **Status** | Verified (by absence) |
| **Severity** | Low |

---

## Pet profile

### V-PET-01: Duplicate `Pet` models (profile vs care)

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High (maintainability) |
| **Files** | `lib/features/pet_profile/data/models/pet.dart`, `lib/features/care/data/models/pet.dart` |
| **Issue** | Two types with overlapping but diverging fields (`isDiscoverable`, `isPublic`, `archivedAt`, `activityLevel` enum vs string, etc.). Risk of conversion bugs across modules. |
| **Recommendation** | Single shared model or explicit mapper layer. |

### V-PET-02: Species not editable after onboarding

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low |
| **File** | `lib/features/pet_profile/presentation/screens/edit_profile_screen.dart` |
| **Issue** | `_SpeciesChip` displays species with lock icon; breed is editable, species is not. |

### V-PET-03: No microchip / vaccination fields on profile

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |
| **Issue** | Onboarding labels health/vaccinations as “later”; no dedicated profile fields. |

### V-PET-04: Photo upload without crop/edit

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low |
| **Issue** | `image_picker` only; no crop package in `pubspec.yaml`. |

### V-PET-05: Limited privacy controls

| Field | Detail |
|-------|--------|
| **Status** | Partial |
| **Severity** | Medium |
| **Issue** | `isPublic`, `isDiscoverable` exist; no granular “hide age/breed” or per-field privacy UI. |

### V-PET-06: Discoverability toggle (NOT an issue)

| Field | Detail |
|-------|--------|
| **Status** | Incorrect (doc) |
| **Note** | Audit claimed no UI; **implemented** on edit profile with `discovery_visibility_controller.dart`. |

---

## Care & wellness

### V-CARE-01: Daily checklist offline via SharedPreferences only

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Info (by design) |
| **File** | `lib/features/care/data/repositories/checklist_repository.dart` |
| **Issue** | Other care data (tasks beyond checklist sync, vault, logs) requires network. |

### V-CARE-02: No local/push notification scheduling for reminders

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High (for wellness product) |
| **Issue** | No `flutter_local_notifications` or equivalent in project. |

### V-CARE-03: No medical record export for vets

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |

### V-CARE-04: No AI / symptom trend analysis

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low (future feature) |

### V-CARE-05: Care dashboard ≠ full wellness dashboard

| Field | Detail |
|-------|--------|
| **Status** | Partial |
| **Files** | `care_dashboard_controller.dart`, `care_screen.dart` |
| **Issue** | Daily routine, streaks, badges exist; no unified symptom log + weight anomaly + guidance surface as described in industry comparisons. |

### V-CARE-06: Gamification not linked to marketplace rewards

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low |

### V-CARE-07: Recurring task limitations

| Field | Detail |
|-------|--------|
| **Status** | Partial |
| **Issue** | Task engine exists; custom notification triggers, skip-with-partial-credit, species-based suggestions not found. |

---

## Marketplace

### V-MKT-01: Cart is in-memory only

| Field | Detail |
|-------|--------|
| **Status** | Verified (intentional) |
| **Severity** | Medium (UX) |
| **File** | `lib/features/marketplace/presentation/controllers/cart_controller.dart` |
| **Issue** | Comment states intentional: cart cleared on app restart; Supabase order is truth after checkout. Users lose cart on kill. |
| **Recommendation** | Persist to SharedPreferences or document UX warning on first add. |

### V-MKT-02: Marketplace search bar is decorative

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High |
| **File** | `lib/features/marketplace/presentation/screens/marketplace_screen.dart` |
| **Issue** | `_SearchBar` is non-interactive; filtering is category chips only. |

### V-MKT-03: No sort (price, popularity) or advanced filters

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |

### V-MKT-04: Currency hard-coded to USD in UI

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |
| **Files** | `product.dart`, `cart_item.dart`, `cart_screen.dart`, `product_detail_screen.dart`, etc. |
| **Issue** | `priceFormatted` uses `'$${...}'` literals; `MarketplaceOrder.currency` field exists but UI does not localize. |

### V-MKT-05: No cart-level tax, shipping calculation, or coupons

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High |
| **Issue** | Checkout subtotal only; `shipping_policy` on shop is text, not computed rate. |

### V-MKT-06: Subscription frequency in weeks only

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low |
| **Files** | `cart_item.dart`, order `LineItem.frequencyWeeks` |

### V-MKT-07: No pause/resume subscription management UI

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |

### V-MKT-08: No product or shop ratings/reviews

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High (trust) |

### V-MKT-09: No bKash / regional wallets / Apple Pay / Google Pay

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium (market-dependent) |
| **Note** | Stripe + COD implemented. |

### V-MKT-10: COD flow present

| Field | Detail |
|-------|--------|
| **Status** | Verified (positive) |
| **Files** | `marketplace_order.dart` (`PaymentMethod.cod`), `cart_screen.dart`, `checkout_controller.dart` (`startCodCheckoutForShop`) |

### V-MKT-11: Vendor product CRUD present (NOT an issue)

| Field | Detail |
|-------|--------|
| **Status** | Incorrect (doc) |
| **Files** | `add_edit_product_screen.dart`, seller routes |

### V-MKT-12: Discover shops dynamic (NOT static)

| Field | Detail |
|-------|--------|
| **Status** | Incorrect (doc) |
| **File** | `shop_list_controller.dart` |

### V-MKT-13: Admin panel without social content moderation

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |
| **Files** | `lib/features/admin/` |
| **Issue** | KYC, COD reconciliation, ledger, dashboard exist; no flag/review queue for posts or users. |

---

## Matching

### V-MATCH-01: Boost control is a non-functional placeholder

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low |
| **File** | `lib/features/matching/presentation/screens/matching_screen.dart` |
| **Issue** | `onTap: null` with comment “Boost — premium feature placeholder”. |

### V-MATCH-02: Location sync failures swallowed

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High |
| **File** | `lib/features/matching/data/repositories/matching_repository.dart` |
| **Issue** | `syncActorLocationFromDevice` catches errors and `debugPrint`s only. |

### V-MATCH-03: RPC/auth failures can present as empty discovery

| Field | Detail |
|-------|--------|
| **Status** | Partial |
| **Files** | `matching_supabase_data_source.dart` (returns `[]` on null RPC), `discovery_candidates_controller.dart` |
| **Issue** | No user-facing error on failed `matching_discovery_candidates`; empty stack feels like “no pets nearby”. |

### V-MATCH-04: Discovery filters: species, distance, age (no personality/behavior)

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Low (product roadmap) |

### V-MATCH-05: No map view of nearby pets

| Field | Detail |
|-------|--------|
| **Status** | Verified |

### V-MATCH-06: Chat lacks media, typing indicators, read receipts

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **File** | `lib/features/matching/presentation/screens/chat_screen.dart` |

### V-MATCH-07: No block/report for users in matching

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Note** | “Blocked” strings refer to **location permission**, not user blocking. |

### V-MATCH-08: Discovery pagination exists (doc overstated gap)

| Field | Detail |
|-------|--------|
| **Status** | Partial / doc correction |
| **File** | `discovery_candidates_controller.dart` |
| **Issue** | Page size 20, offset, replenish — still no infinite scroll UX on social-style feed, but matching discovery is not unpaginated. |

---

## Social

### V-SOC-01: Feed capped at 50 posts, no load-more

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | Medium |
| **File** | `lib/features/social/data/repositories/social_repository.dart` |
| **Issue** | `.limit(50)` on feed queries; no offset/cursor pagination in UI. |

### V-SOC-02: Create post: single image only

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **File** | `lib/features/social/presentation/screens/create_post_screen.dart` |

### V-SOC-03: Display supports multiple images (create does not)

| Field | Detail |
|-------|--------|
| **Status** | Partial |
| **Files** | `social_repository.dart` (`image_urls`), `post_detail_screen.dart` (carousel) |
| **Issue** | Schema and detail UI support multiple URLs; composer only picks one image. |

### V-SOC-04: No comment threading or @mentions

| Field | Detail |
|-------|--------|
| **Status** | Verified |

### V-SOC-05: “Report Post” is UI stub only

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High (safety) |
| **File** | `lib/features/social/presentation/screens/post_detail_screen.dart` |
| **Issue** | Report `ListTile` only calls `Navigator.pop`; no API or moderation queue. |

### V-SOC-06: No post visibility (public/friends) in UI

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Issue** | Feed query filters `visibility = 'public'` only. |

### V-SOC-07: Follow system implemented (NOT missing)

| Field | Detail |
|-------|--------|
| **Status** | Incorrect (doc) |
| **Files** | `follow_controller.dart`, `social_repository.dart` (`pet_follows`), `social_profile_screen.dart` |

### V-SOC-08: Notifications for like/comment/follow

| Field | Detail |
|-------|--------|
| **Status** | Verified (positive) |
| **File** | `notification_repository.dart` |

---

## General / platform

### V-GEN-01: No internationalization (i18n)

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High |
| **Issue** | English strings hard-coded; no `flutter_localizations`, no `l10n.yaml` or ARB files in app. |

### V-GEN-02: Offline-first architecture absent

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High |
| **Issue** | Most features require live Supabase; only checklist (and active-pet id) use local persistence. |

### V-GEN-03: Test suite thin; default widget test broken

| Field | Detail |
|-------|--------|
| **Status** | Verified |
| **Severity** | High |
| **Files** | `test/widget_test.dart`, `test/care_*.dart` |
| **Issue** | Widget test pumps `PetfolioApp` without `ProviderScope` and expects counter UI from Flutter template. Care utility tests pass. |
| **Fix** | Replace with `ProviderScope` + minimal smoke route or remove counter assertions. |

### V-GEN-04: No rate limiting / abuse detection in client

| Field | Detail |
|-------|--------|
| **Status** | Verified (client); server policies not audited here |
| **Severity** | Medium |

### V-GEN-05: Dependency / codegen hygiene

| Field | Detail |
|-------|--------|
| **Status** | Partial |
| **Issue** | `riverpod_annotation` / `riverpod_generator` in `pubspec.yaml` but most providers are hand-written `NotifierProvider`s. |

---

## Verified positive capabilities (not issues)

Use this list to avoid duplicate work:

| Area | Capability |
|------|------------|
| Navigation | GoRouter shell: Home, Care, Social, Matching, Marketplace |
| Theme | Light + dark via system setting |
| Marketplace | Multi-vendor cart grouped by `shopId`, Stripe + COD, Connect onboarding |
| Marketplace | Vendor shop setup, KYC upload, product add/edit, order queues |
| Admin | KYC approval, COD delivered orders, financial ledger |
| Matching | PostGIS discovery RPC, swipes, mutual matches, chat threads |
| Social | Likes, comments, follow, notifications, public feed |
| Care | Tasks, streaks, badges, medical vault routes, checklist offline sync |
| Backend | Supabase migrations, Edge Functions (`create-payment-intent`, `stripe-webhook`, `stripe-onboard-vendor`) |

---

## Recommended fix order

### P0 (before production)
1. V-SEC-01 — Remove default API keys from release builds  
2. V-PAY-01 — Webhook-aligned payment confirmation  
3. V-GEN-03 — Fix or replace `widget_test.dart`  

### P1 (high user/revenue impact)
4. V-MKT-02 — Implement marketplace search  
5. V-MKT-05 — Tax/shipping/promo engine (or minimum shipping line item)  
6. V-MKT-08 — Reviews/ratings  
7. V-AUTH-02 — Password reset  
8. V-PET-01 — Unify `Pet` models  
9. V-MATCH-02 / V-MATCH-03 — Surface matching/location errors in UI  
10. V-SOC-05 — Real report/moderation pipeline  

### P2 (competitive / growth)
11. V-GEN-01 — i18n + locale currency  
12. V-CARE-02 — Reminder notifications  
13. V-MKT-01 — Optional cart persistence  
14. V-MATCH-01 — Boost / IAP  
15. V-SOC-01 — Feed pagination  

---

## Appendix: Key file references

| Topic | Path |
|-------|------|
| App entry & secrets | `lib/main.dart` |
| Router | `lib/core/router.dart` |
| Cart | `lib/features/marketplace/presentation/controllers/cart_controller.dart` |
| Checkout | `lib/features/marketplace/presentation/controllers/checkout_controller.dart` |
| Marketplace UI | `lib/features/marketplace/presentation/screens/marketplace_screen.dart` |
| Matching repo | `lib/features/matching/data/repositories/matching_repository.dart` |
| Social feed | `lib/features/social/data/repositories/social_repository.dart` |
| Pet models | `lib/features/pet_profile/data/models/pet.dart`, `lib/features/care/data/models/pet.dart` |
| Tests | `test/widget_test.dart`, `test/care_scheduled_time_test.dart`, `test/care_task_model_crud_test.dart` |
| Stripe webhook | `supabase/functions/stripe-webhook/index.ts` |
| Prior internal review | `REVIEW_FINDINGS.md` |

---

*This document should be updated when issues are fixed. Mark items with PR links or commit SHAs when resolved.*
