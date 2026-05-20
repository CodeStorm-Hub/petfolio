# PetFolio — Verified Issues (`01-review-implementation`)

**Branch:** `01-review-implementation`  
**Verified:** 2026-05-20 (static code review + `flutter analyze` — no issues)  
**Sources:** `Comprehensive Code Review for PetFolio (01‑review‑implementation branch).md`, `PetFolio 01-review-implementation — Comprehensive Static Review.md`, cross-checked against current codebase.

---

## Summary

| Severity | Count | Theme |
|----------|-------|--------|
| P0 — Release blocker | 3 | Marketplace checkout trust + inventory |
| P1 — High | 6 | Storage, KYC, inventory lifecycle, error UX |
| P2 — Medium | 12 | Placeholders, gating, legacy care, social errors |
| P3 — Lower / product | 8 | Accessibility, offline, subscriptions, moderation |

**Production-ready for beta (non-payment):** auth, pet profiles, care dashboard + gamification RPC, medical vault CRUD, social feed/create/report, matching (PostGIS + preferences), admin KYC approval UI, cart persistence.

**Not safe for real payments until P0 items are fixed.**

---

## P0 — Release blockers

### P0-1. Checkout totals are client-controlled (price tampering)

**Status:** Confirmed  
**Location:** `supabase/migrations/20260521120000_checkout_transaction_rpc.sql`, `lib/features/marketplace/data/models/cart_item.dart`, `lib/features/marketplace/data/repositories/order_repository.dart`

`process_checkout` sums `line_total_cents` from the Flutter cart JSON. It does not read `products.price_cents` from the database. A modified client can send lower line totals.

**Fix:** In the RPC, ignore client `unit_cents` / `line_total_cents` for billing. Fetch `products.price_cents` (and server-side subscription rules), compute totals server-side.

---

### P0-2. Inventory decremented before payment succeeds

**Status:** Confirmed  
**Location:** `supabase/migrations/20260521120000_checkout_transaction_rpc.sql` (step 4 decrements stock), `lib/features/marketplace/data/repositories/order_repository.dart` (`cancelOrder`), `supabase/functions/stripe-webhook/index.ts`

- Stock is reduced when the pending order is created (during checkout RPC).
- `cancelOrder()` only sets `status: 'cancelled'` — does not restore `inventory_count`.
- `payment_intent.payment_failed` webhook cancels the order — does not restore inventory.
- `payment_intent.succeeded` updates order/ledger only — inventory was already reduced at checkout.

**Fix (choose one):** reservation table with expiry/release; decrement only after `payment_intent.succeeded`; or atomic `UPDATE ... WHERE inventory_count >= qty` with explicit release on cancel/failure.

---

### P0-3. Missing `post-images` storage bucket migration

**Status:** Confirmed  
**Location:** `lib/features/social/data/repositories/social_repository.dart` (`uploadPostImage` → `post-images` bucket)

No migration under `supabase/` creates the `post-images` bucket or `storage.objects` RLS policies (unlike `marketplace-images` in `20260519030000_marketplace_images_bucket.sql`). Fresh environments will fail post image uploads.

**Fix:** Add migration: bucket insert + authenticated insert/select policies scoped by user folder.

---

## P1 — High priority

### P1-1. KYC rejection is not transactional (no RPC / audit / notification)

**Status:** Confirmed  
**Location:** `lib/features/admin/data/repositories/admin_repository.dart` (`rejectKyc` direct `shops` update)

Approval uses `approve_vendor_kyc` RPC with audit log. Rejection updates `shops` directly without audit trail or vendor notification (though `kyc_rejected` is in `notifications_type_check`).

**Fix:** Add `reject_vendor_kyc(p_shop_id, p_admin_id, p_reason)` RPC mirroring approval flow.

---

### P1-2. No inventory restore on payment cancel / failure / dismissed PaymentSheet

**Status:** Confirmed (same root as P0-2)  
**Location:** `checkout_controller.dart` → `cancelOrder`, stripe-webhook `payment_intent.payment_failed`

Users who abandon PaymentSheet or fail payment can leave inventory permanently reduced.

---

### P1-3. `notifications_type_check` migration may fail on drifted DBs

**Status:** Confirmed  
**Location:** `supabase/migrations/20260521130000_notifications_type_check.sql`

Uses `DROP CONSTRAINT notifications_type_check` without `IF EXISTS`.

**Fix:** Use `DROP CONSTRAINT IF EXISTS` or defensive migration pattern.

---

### P1-4. Health tab error state has no Retry action

**Status:** Confirmed  
**Location:** `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart` (`_ProfileHealthTab`)

Care tab shows Retry via `careDashboardProvider.notifier.refresh()`. Health tab error only shows “Could not load health records” with no retry button.

**Fix:** Add Retry (e.g. `ref.invalidate(healthVaultControllerProvider)`).

---

### P1-5. Medical vault controller errors are silent (debugPrint only)

**Status:** Confirmed  
**Location:** `lib/features/care/presentation/controllers/health_vault_controller.dart`

`addRecord`, `updateRecord`, `deactivateRecord` revert optimistically but only `debugPrint` on failure — no `AppSnackBar.showError`.

**Fix:** Surface failures with `AppSnackBar.showError` (match care dashboard pattern).

---

### P1-6. `create-payment-intent` trusts order amount from checkout RPC

**Status:** Confirmed  
**Location:** `supabase/functions/create-payment-intent/index.ts`

Re-validates inventory at PaymentIntent time but order `amount_cents` still comes from the tamperable checkout path.

**Fix:** Resolved by P0-1 server-side pricing.

---

## P2 — Medium priority

### P2-1. Awards tab is still a placeholder (badges not shown)

**Status:** Confirmed  
**Location:** `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`

Awards tab shows “coming soon”. `pet_badges` is fetched in `care_dashboard_controller.dart` but not wired to profile Awards tab.

**Fix:** Wire Awards tab to `pet_badges` / badge types from care repository.

---

### P2-2. Profile Overview uses hardcoded reminders and feed placeholder

**Status:** Confirmed  
**Location:** `pet_profile_screen.dart` (`_ProfileOverviewTab`)

Static `_ReminderCard` entries and `_FeedPlaceholder` — not backed by care reminders or social feed.

---

### P2-3. Hero weekly bars are hardcoded (not `weekGoalHit` / streak data)

**Status:** Confirmed  
**Location:** `pet_profile_screen.dart` (`_HeroCard`)

Seven bars use fixed opacity (`i < 6` vs today) instead of real per-day completion from `care_streaks` / dashboard week goal.

Streak **number** uses `careStreakRealtimeProvider`; bar chart does not.

---

### P2-4. Seller dashboard card has no vendor / shop gate

**Status:** Confirmed  
**Location:** `pet_profile_screen.dart` (`_SellerDashboardCard`)

Always navigates to `/seller` — no check for existing shop, KYC status, or vendor role.

**Fix:** Gate on `myShopProvider` / shop state; route to setup vs dashboard.

---

### P2-5. Hero “on a walk” chip is hardcoded

**Status:** Confirmed  
**Location:** `pet_profile_screen.dart` (`_HeroCard`)

Displays static label `'on a walk'` — not tied to pet activity or care state.

---

### P2-6. Legacy `CareNotifier` assumes exactly three task types (feed / walk / med)

**Status:** Confirmed  
**Location:** `lib/features/care/presentation/controllers/care_controller.dart`

`DayData` and `allDone` require feed + walk + med. Adding/reordering task types in `care_tasks` can desync streak UI from RPC-based gamification.

**Note:** `care_dashboard_controller` uses dynamic `care_tasks`; legacy notifier still used in some flows.

---

### P2-7. `CareNotifier.toggle` failures only debugPrint (no snackbar)

**Status:** Confirmed  
**Location:** `lib/features/care/presentation/controllers/care_controller.dart`

Toggle rollback works but user gets no feedback. (`care_dashboard_controller` does use `AppSnackBar.showError` for dashboard actions.)

---

### P2-8. Health vault: null `nextDueAt` sorted to end of list

**Status:** Confirmed  
**Location:** `lib/features/care/presentation/controllers/health_vault_controller.dart`

Sort returns `1` when `nextDueAt == null`, pushing records without due dates to the bottom. May hide overdue items that only have `expires_at` / `administered_at`.

**Fix:** Consider sorting nulls by `expires_at` or `administered_at`.

---

### P2-9. Health vault: client-side filtering/grouping only

**Status:** Confirmed  
**Location:** `health_vault_controller.dart` streams all records; `medical_vault_screen.dart` groups into vaccines / medications / vet in UI.

Works but transfers full record set; server view/RPC could reduce payload for large vaults.

---

### P2-10. Medical record `document_url` exists but create UI never uploads

**Status:** Confirmed  
**Location:** `medical_record.dart` (`documentUrl`), `medical_vault_screen.dart` (create sets `documentUrl: null`)

Schema supports attachments; no file picker / Supabase storage upload in add-record flow.

---

### P2-11. Social like / edit / delete failures roll back silently

**Status:** Confirmed  
**Location:** `lib/features/social/presentation/controllers/social_controller.dart`

`toggleLike`, `updateCaption`, delete paths use `catch (_)` and revert state without `AppSnackBar.showError`.

Create post **does** show inline `state.error` — asymmetric UX.

---

### P2-12. No admin moderation UI for `reported_posts`

**Status:** Confirmed  
**Location:** `reported_posts` table + RLS exist (`20260520000000_add_reported_posts.sql`); report UI on `post_detail_screen.dart`

No admin tab/queue to review reports. Doc 2 “table missing” is **outdated** — table exists, moderation UI does not.

---

## P3 — Lower priority / product & tech debt

### P3-1. Stripe subscriptions are client-only (not Stripe Billing)

**Status:** Confirmed  
**Location:** `cart_item.dart`, `product.dart` (`subPriceCents`, `isSubscribed`)

Local subscribe-and-save discount in cart; no Stripe Subscription, renewal webhooks, or customer portal.

---

### P3-2. Accessibility gaps on pet profile

**Status:** Confirmed  
**Location:** `pet_profile_screen.dart`

Small text (11–13px), limited `Semantics` on hero/gradient card; contrast may be insufficient in places. Some screens (e.g. `manage_pets_screen.dart`) do use `semanticLabel` on avatars.

---

### P3-3. Inconsistent typography (Inter, Sora, mixed sizes)

**Status:** Confirmed  
**Location:** Multiple features; profile screen mixes Sora/Inter and 11–56px sizes.

---

### P3-4. No unified offline strategy

**Status:** Confirmed  

- Persisted: active pet, cart, care checklist (`SharedPreferences`)
- Not persisted: social feed, marketplace beyond cart, health vault stream cache

---

### P3-5. Care dashboard: some badge/week-goal fetch failures only debugPrint

**Status:** Confirmed  
**Location:** `lib/features/care/presentation/controllers/care_dashboard_controller.dart`

Badge and week-goal fetch errors logged, not always surfaced to UI.

---

### P3-6. Timezone handling for daily care tasks

**Status:** Likely issue (not fully traced)  
**Location:** `care_controller.dart`, `DateUtils.dateOnly(DateTime.now())`

Tasks keyed to local `DateTime.now()` without explicit timezone policy; travelers may see wrong “today” vs server `logged_date` / RPC UTC date.

---

### P3-7. SharedPreferences care/cart data: no encryption or schema versioning

**Status:** Confirmed  
**Location:** `checklist_repository.dart`, `cart_controller.dart`

Local data is plain JSON; schema changes could corrupt or misread old prefs (cart catches decode errors; care may not everywhere).

---

### P3-8. Placeholder / no-op UI actions on home header

**Status:** Confirmed  
**Location:** `pet_profile_screen.dart` (`AppHeader` outdoor + notifications `onTap: () {}`)

---

## Verified improvements (not issues — for context)

These were flagged in older reviews but are **fixed or implemented** on this branch:

| Item | Evidence |
|------|----------|
| User-scoped active pet key | `active_pet_id_$userId` in `active_pet_controller.dart` |
| Cart persistence | `cart_$uid` in `cart_controller.dart` |
| `check_daily_completion` auth + ownership | `20260522000000_fix_daily_completion_gamification.sql` |
| Real social feed (not mock) | `SocialController` → `fetchFeed` |
| Realtime channel cleanup | `ref.onDispose` → `_channel?.unsubscribe()` |
| Create post + upload flow | `create_post_screen.dart`, `CreatePostController` |
| Stripe webhook (signature, PI success/fail, Connect) | `supabase/functions/stripe-webhook/index.ts` |
| Admin KYC approval RPC + UI | `approve_vendor_kyc`, `admin_layout.dart` |
| Health/Care profile tabs use real providers | `healthVaultControllerProvider`, `careDashboardProvider` |
| Badge unlock snackbars | `AppSnackBar.showBadgeUnlocked` |
| Matching: DB swipes + duplicate prevention | `swipes` upsert `onConflict: 'actor_id,target_id'` |
| Matching: filters (species, age, radius) | `matching_repository.dart`, `match_preferences_sheet.dart` |
| Post report UI + table | `post_detail_screen.dart`, `20260520000000_add_reported_posts.sql` |
| Medical vault RLS (owner-only) | `20260513192825_pet_care_health.sql` |
| `confirmOrder` delegated to webhook | `order_repository.dart` no-op + webhook updates |
| `flutter analyze` clean | Run 2026-05-20: no issues |

---

## Outdated review claims (do not treat as open issues)

| Claim (older docs) | Actual state on branch |
|--------------------|-------------------------|
| Social feed is entirely mock | Real Supabase feed |
| Cart only in memory | SharedPreferences per user |
| No admin panel | `admin_layout.dart` with KYC tab |
| No report post UI | Report dialog on post detail |
| No matching filters | Preferences sheet + RPC params |
| Swipe deck 120px threshold | Button-based actions; no 120px drag threshold found |
| `reported_posts` table missing | Migration `20260520000000_add_reported_posts.sql` exists |
| Chat uses wrong participant schema | `swipes`/`matches` + PostGIS discovery per `AGENTS.md` |

---

## Recommended fix order

1. **P0-1** — Server-side pricing in `process_checkout`
2. **P0-2 / P1-2** — Inventory reservation or post-payment decrement + restore on cancel/failure
3. **P0-3** — `post-images` storage migration
4. **P1-1** — `reject_vendor_kyc` RPC
5. **P1-4, P1-5, P2-11** — Error UX (Health retry, vault snackbars, social snackbars)
6. **P2-1, P2-3, P2-4** — Awards tab, hero week bars, seller card gating
7. **P1-3** — Safer notifications constraint migration
8. Before release: `flutter pub run build_runner build --delete-conflicting-outputs`, Supabase local migration reset / push

---

## Verification commands (repeat before merge)

```bash
flutter analyze
flutter pub run build_runner build --delete-conflicting-outputs
flutter test
npx supabase db reset   # or push to staging and verify migrations
```
