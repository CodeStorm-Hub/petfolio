# **PetFolio `01-review-implementation` — Comprehensive Static Review**

I reviewed the `01-review-implementation` branch as a static codebase review through GitHub, Supabase/Stripe docs, and online platform research. I did **not** run `flutter analyze`, app builds, tests, or local Supabase migrations, so the remaining compile/runtime risks must still be validated locally.

## **Executive verdict**

The branch meaningfully addresses many earlier review findings. The implementation plan explicitly targeted active-pet scoping, cart persistence, realtime cleanup, care error handling, pet profile placeholder replacement, admin KYC RPCs, checkout RPCs, Stripe webhooks, and social post storage upload flow.

The strongest improvements are:

| Area | Review result |
| ----- | ----- |
| Active pet state | Improved: active pet ID is now stored with a user-scoped key like `active_pet_id_$userId`. |
| Cart persistence | Improved: cart is now persisted to `SharedPreferences`, with JSON serialization for `CartState` and `CartItem`. |
| Care RPC security | Improved: `check_daily_completion` now validates `auth.uid()` and pet ownership before running gamification/streak logic. |
| Social post creation | Improved: create-post UI, image picker, upload state, and Supabase Storage upload path were added. |
| Stripe webhook | Improved: webhook verifies signatures, handles `payment_intent.succeeded`, `payment_intent.payment_failed`, and Connect `account.updated`. |
| Admin KYC approval | Improved: approval now uses `approve_vendor_kyc` RPC with audit log and notification insert. |

However, the branch still has **serious release blockers**, especially in marketplace checkout.

## **Highest-priority blockers**

### **1\. Checkout price can be tampered with by the client**

`process_checkout` calculates `v_amount_cents` by summing `line_total_cents` from `p_cart_items`, which comes from the Flutter cart JSON. That means a modified client could send a lower `line_total_cents` and create a cheaper order.

**Fix:** In the RPC, ignore client-supplied `unit_cents` and `line_total_cents`. Fetch `products.price_cents` from the database, apply server-side subscription/discount rules, and compute totals fully server-side.

### **2\. Inventory is decremented before payment succeeds**

The checkout RPC decrements `products.inventory_count` immediately after creating a pending order. If the user cancels Stripe PaymentSheet, payment fails, or webhook never confirms, `cancelOrder()` only marks the order cancelled and does **not** restore inventory.

**Fix:** Use one of these patterns:

| Safer pattern | Recommendation |
| ----- | ----- |
| Reservation table | Create `inventory_reservations(order_id, product_id, quantity, expires_at, status)` and release on cancel/failure/expiry. |
| Decrement after payment | Create pending order first, then decrement inventory only in webhook after `payment_intent.succeeded`. |
| Atomic stock update | Use `UPDATE products SET inventory_count = inventory_count - qty WHERE id = product_id AND inventory_count >= qty RETURNING id` to avoid overselling. |

### **3\. Social image upload may fail without bucket migration**

`SocialRepository.uploadPostImage()` uploads to a `post-images` bucket, but I did not find a corresponding migration creating that bucket or its `storage.objects` RLS policies.

**Fix:** Add a migration for:

insert into storage.buckets (id, name, public)  
values ('post-images', 'post-images', true)  
on conflict (id) do nothing;

Then add authenticated insert/select policies scoped by user folder.

### **4\. `reported_posts` is used but not in the documented schema**

`SocialRepository.reportPost()` inserts into `reported_posts`, but the ERD/table summary lists identity, care, social, matching, chat, and marketplace tables without `reported_posts`.

**Fix:** Add `reported_posts` migration, RLS, unique constraint on `(post_id, reporter_id)`, and admin moderation UI.

### **5\. KYC rejection is still not transactional**

Approval uses the new RPC, but rejection still directly updates `shops` without audit trail or vendor notification.

**Fix:** Add `reject_vendor_kyc(p_shop_id, p_admin_id, p_reason)` RPC that updates the shop, inserts audit log, and creates a `kyc_rejected` notification.

---

# **Module and feature inventory from `lib/`**

## **1\. Core module**

**Main responsibilities:** app bootstrap, environment config, routing, theme, global widgets, notifications, app shell.

Key files and functions:

| Area | Details |
| ----- | ----- |
| `main.dart` | Reads `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `STRIPE_PUBLISHABLE_KEY`; initializes Stripe, Supabase, notifications, Riverpod `ProviderScope`, and `MaterialApp.router`. |
| Router | Uses `GoRouter`, auth redirects, onboarding redirect, admin guard, shell navigation, adaptive `NavigationRail` / `NavigationBar`. |
| Theme/widgets | Project docs describe `core` as the shared theme/widgets/error layer, with feature-first `data` and `presentation` split. |

## **2\. Auth module**

**Screens:** login, registration.  
**Backend:** Supabase Auth.  
**Flow:** unauthenticated users redirect to `/login`; logged-in users with no pets redirect to `/onboarding`.

No major auth implementation changes were included in this branch. Password reset and OAuth remain useful future enhancements.

## **3\. Pet Profile module**

**Features implemented:**

| Feature | Status |
| ----- | ----- |
| Active pet selection | User-scoped SharedPreferences key implemented. |
| Home profile screen | Active pet hero, stats, seller dashboard entry, social profile link, Health/Care/Awards tabs. |
| Care tab | Now reads real care dashboard tasks with loading skeleton, empty state, and retry. |
| Health tab | Now reads `healthVaultControllerProvider` and displays medical records. |

Remaining issues: Awards is still a placeholder, and the hero weekly bars are still visually hardcoded instead of using `weekGoalHit`.

## **4\. Care / Health module**

**Features:** care tasks, logs, streaks, medical vault, gamification, badges, reminders.

| Layer | Details |
| ----- | ----- |
| Repository | Fetches tasks by pet/date, merges care logs with task definitions, toggles completion, creates/updates/deletes tasks, fetches badges/streaks. |
| Controller | Uses `AsyncValue` for tasks, today tasks, streak, and weekly goal state; optimistic toggle rollback and snackbars were added. |
| Database RPC | `check_daily_completion` validates authenticated owner, calculates streaks, awards points, and unlocks badges. |

Remaining issues: some repository methods still use `PGRST116` handling in create/update/toggle paths, and some badge/week-goal fetch failures are debug-printed instead of surfaced to the UI.

## **5\. Social module**

**Features:** feed, post detail, create post, likes, comments count updates, follows, pet profile, notifications, reporting.

| Feature | Status |
| ----- | ----- |
| Feed | Paginated feed, joined with pet/user data and `post_likes`. |
| Realtime | `ref.onDispose()` now unsubscribes the Supabase realtime channel. |
| Create post | Image picker, caption, upload overlay, submit flow, success snackbar. |
| Storage upload | Validates image type/size, uploads to `post-images`, inserts post with image URL. |

Remaining issues: storage bucket/policies need migration; `reported_posts` needs migration; optimistic like/edit/delete failures are mostly silent rollback without user-visible error.

## **6\. Matching / Chat module**

**Screens/routes:** matching deck, matches inbox, chat screen.

**Database tables:** `swipes`, `matches`, `match_requests`, `chat_threads`, `chat_messages`. The ERD shows user/pet relationships, match requests, chat participants, messages, and indexes.

Recommended next improvement: use real location radius matching with PostGIS, pet preference filters, safety controls, and match/report moderation.

## **7\. Marketplace module**

**Features:** product catalog, product detail, cart, checkout, buyer orders, seller dashboard, shop storefront, vendor products, vendor orders, KYC, Stripe onboarding.

| Area | Current implementation |
| ----- | ----- |
| Product model | Includes vendor shop fields, image URLs, inventory count, subscription pricing helper, storage JSON. |
| Product repository | Fetches active products with `shops!inner(shop_name)`. |
| Cart | Persistent SharedPreferences cart with per-shop grouping. |
| Orders | `insertPendingOrder()` now calls `process_checkout`; Stripe PaymentIntent creation is moved to Edge Function. |
| Checkout UI logic | Per-vendor Stripe checkout and COD checkout exist. |
| Stripe webhook | Handles successful/failed payments and Connect account updates. |

Major remaining work: secure pricing, inventory reservations, real Stripe subscriptions, shipping/tax calculation, product reviews, refunds, cancellation flow, and order status notifications.

## **8\. Admin module**

**Features:** KYC approvals, KYC document signed URLs, COD reconciliation, vendor ledgers, payouts, overview metrics.

The approval flow is significantly improved by the new RPC and audit log table.

Remaining work: KYC rejection RPC, moderation dashboard, reported post review, payout history, refund dispute handling.

---

# **Database and migration review**

The database documentation describes 25 RLS-enabled tables across identity, care/health, social, matching, chat, and marketplace domains.

Important marketplace tables include `shops`, `products`, `marketplace_orders`, and `vendor_ledgers`, with indexes for buyer, seller, shop, order status, and Stripe PaymentIntent.

New branch migrations:

| Migration | Purpose | Review |
| ----- | ----- | ----- |
| `20260520120000_admin_kyc_rpc.sql` | Adds audit logs, user notifications, and `approve_vendor_kyc` RPC. | Good direction; add rejection RPC and make constraints safer. |
| `20260521120000_checkout_transaction_rpc.sql` | Adds `process_checkout` RPC. | Structurally useful but currently unsafe for pricing and inventory. |
| `20260521130000_notifications_type_check.sql` | Adds KYC notification types. | Risk: drops constraint without `IF EXISTS`; may fail in drifted environments. |
| `20260522000000_fix_daily_completion_gamification.sql` | Fixes/extends care gamification RPC. | Good security improvement; validates pet ownership. |

Existing marketplace migration defines payment method/status enums, vendor ledger, admin helper, KYC storage bucket, and RLS policies.

---

# **Stripe review**

The branch correctly moves order confirmation away from “client says payment succeeded” and toward webhook-driven confirmation. That aligns with Stripe’s own recommendation to use webhooks for payment completion because a customer can close the app/browser before client callbacks run, and some payment methods confirm asynchronously.

Stripe Connect destination charges are also conceptually aligned: the app uses `transfer_data.destination` and `application_fee_amount`, which Stripe documents for marketplace-style destination charges.

But subscriptions are still not truly implemented. The product/cart code has `isSubscribed`, `frequencyWeeks`, and a local 12% discount, but there is no Stripe Billing `Subscription`, subscription table, renewal webhook, customer portal, or cancellation flow. Stripe Billing requires server-created subscriptions, storing subscription status, and listening to subscription lifecycle webhooks. For connected-account subscriptions, Stripe supports application fees through `application_fee_percent` and subscription webhooks.

---

# **UI/UX screen inventory**

Main shell tabs:

| Tab | Screen |
| ----- | ----- |
| Pets | `PetProfileScreen` |
| Care | `CareScreen` |
| Social | `SocialScreen` |
| Match | `MatchingScreen` |
| Market | `MarketplaceScreen` |

Full-screen routes include login, registration, onboarding, manage pets, edit profile, nutrition, medical vault, product detail, cart, order confirmation, buyer order list/detail, shop storefront, seller dashboard, seller setup, Stripe onboarding, shop edit, manual KYC, vendor product CRUD, vendor order queue/detail, admin, create post, post detail, notifications, social profile, matching inbox, and chat.

UI improvements added in this branch:

| UI area | Improvement |
| ----- | ----- |
| Create post | Much stronger image/caption UX with upload overlay. |
| Pet profile | Health and Care tabs now use real providers instead of pure placeholders. |
| Care screen | Better loading/error handling through dashboard state. |
| Cart | Persistent cart state improves UX across app restarts. |

UX gaps still visible:

* Add Retry action to Health tab error state.  
* Replace Awards placeholder with real `pet_badges`.  
* Replace hardcoded weekly hero bars with `weekGoalHit`.  
* Add empty states for “no image bucket / upload failed” cases.  
* Add visible error snackbars for social like/edit/delete failures.  
* Add checkout inventory conflict UI before user opens PaymentSheet.

---

# **Similar platform research and improvement ideas**

Chewy’s strength is recurring commerce: Autoship and essential categories like food/medicine drive resilience and most projected sales. PetFolio’s marketplace should therefore prioritize real recurring orders, product reviews, reorder flows, pharmacy/vet-prescribed item support, and reliable delivery/subscription management. ([Barron's](https://www.barrons.com/articles/chewy-ceo-consumers-stretched-stock-2dd398a5?utm_source=chatgpt.com))

Rover, Wag, and BorrowMyDoggy show that pet-care marketplaces need trust and safety, not just listings. Rover-style services cover sitting, boarding, day care, walking, drop-ins, house sitting, and training; Wag’s 2025 bankruptcy also shows that on-demand pet services can struggle without sustainable unit economics; BorrowMyDoggy emphasizes ID checks, insurance, vet helpline, local matching, and messaging. ([Wikipedia](https://en.wikipedia.org/wiki/Rover_%28American_company%29?utm_source=chatgpt.com))

For PetFolio, that means the next major module could be a **Pet Services Marketplace** with sitter/walker profiles, verification, service pricing, booking calendar, GPS/QR walk logs, incident reports, insurance/KYC status, in-app chat, and escrow-style payouts.

Dog training/wellness apps such as Woofz combine training plans, wellness dashboards, check-ins, activity/nutrition tracking, reminders, and multi-profile support. PetFolio already has care streaks and medical vaults, so the best improvement is to turn Care into a richer wellness system: vitals trends, weight charts, vaccine timeline, vet-share PDF, training routines, and family/caregiver permissions. ([Wikipedia](https://en.wikipedia.org/wiki/Woofz?utm_source=chatgpt.com))

---

# **Prioritized action plan**

## **Must fix before merge/release**

1. Rework `process_checkout` so pricing is calculated server-side from `products.price_cents`.  
2. Stop decrementing inventory on pending Stripe orders, or add reservation/release logic.  
3. Add `post-images` bucket \+ storage policies migration.  
4. Add `reported_posts` table \+ RLS migration or remove `reportPost()` until ready.  
5. Add `reject_vendor_kyc` RPC with audit log and notification.  
6. Run `flutter analyze`, generated code rebuild, and Supabase local migration reset.

## **Next 2–4 weeks**

1. Add widget/unit tests for cart persistence, checkout controller, care dashboard, social create post, and RPC error handling.  
2. Add Stripe webhook event log table for idempotency and replay safety.  
3. Add product reviews/ratings and seller reviews.  
4. Add real Stripe Billing subscriptions instead of local subscription toggles.  
5. Wire Awards tab to `pet_badges`.  
6. Add Health tab retry, week-goal hero state, and more accessible loading/error UI.

## **Longer-term product roadmap**

1. Pet services marketplace: walkers, sitters, groomers, vet visits, booking calendar.  
2. Trust/safety: verified badges, insurance/KYC status, report center, moderation queue.  
3. Care intelligence: reminders, health trend charts, vaccination expiry alerts, vet-share records.  
4. Matching: PostGIS distance matching, compatibility filters, safety/reporting tools.  
5. Marketplace operations: refunds, returns, tax/shipping rules, vendor analytics, payout reconciliation.

## **Final assessment**

This branch is a **solid implementation pass**, but it is not production-ready yet. The biggest wins are state persistence, RPC-based backend workflows, webhook-driven payment confirmation, and a real social post creation UX. The biggest remaining risk is the marketplace checkout pipeline: pricing and inventory must be moved fully under trusted server/database control before this can safely handle real payments.

