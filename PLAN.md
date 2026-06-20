file_path: C:\Users\syedr\.claude\plans\for-the-petfolio-whole-snuggly-cupcake.md
content: # Petfolio Marketplace — Cross-Stack Audit & Remediation Plan

## Context

The Marketplace module spans three surfaces that must work together: the Flutter app (`lib/features/marketplace/`, buyer-facing), the web dashboard (`J:\GitHub\petfolio-dashboard`, vendor + admin-facing), and the shared Supabase backend. No one has audited these together before. The goal here is to surface every correctness, security, UX, and architectural gap across all three, then sequence the fixes so the highest-risk item (an unauthenticated checkout RPC) lands first, followed by feature-completeness gaps that block real vendor/admin usage, then polish.

Three Explore-style audits were run in parallel (Flutter marketplace code, the dashboard repo, and the live Supabase schema via MCP). Findings are consolidated below by severity.

---

## Findings

### 🔴 P0 — Security / Data-Integrity Critical

1. **`process_checkout(p_buyer_id, p_shop_id, p_cart_items, p_promo_code)` RPC is exploitable.**
   - `SECURITY DEFINER`, no pinned `search_path` (flagged `function_search_path_mutable`), and **executable by `anon`** (unauthenticated).
   - This is the live checkout path called from [`order_repository`](lib/features/marketplace/data/repositories) for promo-code orders. An unauthenticated caller could invoke it directly via the Supabase REST/RPC endpoint to create orders, reserve inventory, or apply promos without ever logging in.
   - The older 3-arg overload (no promo code) is correctly pinned — only the newer 4-arg one regressed.
   - **Fix:** `ALTER FUNCTION ... SET search_path = public`; `REVOKE EXECUTE ... FROM anon`; `GRANT EXECUTE ... TO authenticated`. Verify the 3-arg overload as the template.

2. **Dashboard `.env` has an empty `SUPABASE_SERVICE_ROLE_KEY`.**
   - Any admin-side server action that needs to bypass RLS (KYC approval, payout approval, vendor fee edits) is either silently failing or — worse — those actions are running on RLS-restricted client/anon credentials in a way that may already be a workaround masking a different vuln. Needs the real key populated from the Supabase project settings, and an audit of which admin actions currently assume it's set.

3. **KYC documents (`trade_license_url`, `national_id_url`) are linked with raw/unsigned URLs in `vendors-view.tsx`**, unlike the prescriptions page which correctly uses 10-minute signed URLs. If the storage bucket is private, this is broken; if public, it's a PII leak (national ID images reachable by URL guessing/sharing).

### 🟠 P1 — Functional Gaps Blocking Real Usage

4. **No mobile vendor flow at all.** Every `/seller/*` route in the Flutter app (`lib/features/marketplace/marketplace_routes.dart`) renders `VendorWebRedirectScreen`, which just launches an external browser to the dashboard. Vendors cannot fulfill orders, update tracking, or manage products from the app — only from the web dashboard. Confirm with the user whether this is intentional (web-only vendor ops) or a gap to close.

5. **Dashboard has dead-end navigation links**: `/admin/vendors/{id}`, `/vendor/orders/{id}`, `/admin/orders/{id}`, and `/unauthorized` are all linked from existing pages but have no corresponding `page.tsx`. Clicking through from the vendor list, order overview, etc. currently 404s.

6. **Duplicate/dead RLS policies and missing indexes in Supabase:**
   - `shop_deletion_requests` has two identical INSERT policies and two identical SELECT policies (leftover from an incomplete migration).
   - 11 foreign-key columns have no supporting index (`disputes.order_id`, `disputes.raised_by`, `inventory_reservations.variant_id`, `payout_requests.resolved_by`, `payout_requests.shop_id`, `prescriptions.reviewer_id`, `product_reviews.user_id`, `promos.shop_id`, `vendor_ledgers.payout_request_id`, `wishlist_items.product_id`, `wishlist_items.variant_id`).
   - `multiple_permissive_policies` advisor flags real per-row overhead on `disputes`, `marketplace_orders`, `payout_requests`, `prescriptions`, `promos`, `shipments`.
   - `user_addresses` INSERT policy uses raw `auth.uid()` instead of `(select auth.uid())`, causing per-row re-evaluation instead of plan-time caching.

7. **Pagination silently fails in the Flutter app.** `ProductListNotifier.loadMore()` catches exceptions but never surfaces an error state — a network blip during infinite-scroll just stops loading more products with no feedback.

8. **Checkout confirmation race condition.** `pollOrderConfirmation()` throws `PaymentTimeoutException` after a fixed 15s even though the card may have already been charged and the order row just hasn't caught up to the webhook. No retry/backoff; user is told to "check Orders" with no guarantee the order is visible yet.

### 🟡 P2 — UX / Consistency Issues

9. Multi-vendor cart checkout silently creates **separate orders per shop** with no warning to the buyer about split shipping/costs.
10. No debounce on marketplace search — fires a query per keystroke.
11. No "no results" empty state for product search (just an empty grid).
12. `MarketplaceCategoriesScreen` hardcodes 8 categories/emojis in Dart; dashboard also hardcodes the same category list in its product form. **No shared `categories` table** — both `products.category` and `promos.category` are free-text columns with no canonical source, so the two surfaces can drift independently.
13. Hardcoded "3–5 business days" delivery estimate in `order_confirmation_screen.dart` instead of derived from shop/shipping data.
14. Dashboard: bulk product delete/deactivate has no confirmation dialog.
15. Dashboard: large tables (orders, disputes, payouts) have no pagination or search/filter UI, unlike the products table.
16. Naming drift between "shop" (table/columns) and "vendor" (function names, `is_vendor()`, `vendor_ledgers`) for what's currently a 1:1 entity — confusing but not currently a bug.
17. `marketplace_orders.seller_id` (nullable) appears redundant with `shop_id` (NOT NULL) — same entity reachable two ways; `idx_orders_seller` is flagged as an unused index, suggesting `seller_id` is vestigial and safe to deprecate after confirming no code path reads it.

### ⚪ P3 — Polish

18. FlyToCart add-to-cart animation has no Semantics label (screen-reader silent).
19. Inventory shown as a raw count with no low-stock urgency messaging.
20. Wishlist doesn't pass `variantId` when adding from `ProductCard`, risking duplicate wishlist entries per variant.
21. No unit/widget tests anywhere in `lib/features/marketplace/`.
22. Several unused indexes flagged by advisors (`idx_orders_seller`, `idx_shops_kyc_status`, `idx_products_shop_id`, `vendor_ledgers_order_id_idx`, `vendor_ledgers_status_idx`, `idx_shop_deletion_requests_owner_id`) — candidates for removal once confirmed against real query patterns, not blind deletion.
23. Platform-wide (non-marketplace) advisor items noted for awareness, out of scope here: `auth_leaked_password_protection` disabled; several other `SECURITY DEFINER` functions (community counters, care dashboard, matching) are also anon/authenticated-executable.

---

## Remediation Plan (sequenced)

**Phase 1 — Security lockdown (do first, per your priority call)**
- Fix `process_checkout` 4-arg overload: pin `search_path`, revoke `anon` execute, grant `authenticated` only. Diff against the already-correct 3-arg overload as the reference.
- Populate `SUPABASE_SERVICE_ROLE_KEY` in the dashboard env (pull from Supabase project API settings — coordinate with whoever holds project access, this is a secret and should go through `vercel env`/local `.env`, never committed).
- Switch KYC document links in `vendors-view.tsx` to signed URLs (mirror the existing pattern in `prescriptions-view.tsx`, 10-min expiry).

**Phase 2 — Close functional gaps**
- Implement the missing dashboard pages: `/admin/vendors/[id]`, `/vendor/orders/[id]`, `/admin/orders/[id]`, `/unauthorized`. Use existing table/detail patterns already established elsewhere in the app (e.g. `BuyerOrderDetailScreen`'s data shape as a reference for what an order detail view needs).
- Fix Supabase RLS/index issues: drop duplicate `shop_deletion_requests` policies, add the 11 missing FK indexes, consolidate the `multiple_permissive_policies` tables, wrap `auth.uid()` in `(select ...)` on `user_addresses`.
- Add error state surfacing to `ProductListNotifier.loadMore()`.
- Add retry/backoff to `pollOrderConfirmation()` instead of a hard 15s timeout-to-failure.
- Decide (ask user) whether mobile vendor flow is in-scope; if yes, scope as a separate follow-up plan — it's a large addition, not a quick fix.

**Phase 3 — UX/consistency**
- Introduce a real `categories` table (or at minimum a single shared constants source) consumed by both the Flutter app and the dashboard product form, replacing the two independently hardcoded lists.
- Add search debounce + "no results" state in the Flutter marketplace search.
- Add confirmation dialogs for destructive bulk actions in the dashboard.
- Add pagination/search to admin orders/disputes/payouts tables, matching the existing products table pattern.
- Surface per-shop split-shipping warning in the multi-vendor cart UI.

**Phase 4 — Polish**
- Semantics label for FlyToCart animation; low-stock messaging; fix wishlist variant scoping; add baseline widget/unit test coverage for checkout and cart logic; clean up confirmed-unused indexes after verifying against query logs.

## Verification
- Phase 1: Re-run Supabase advisors (`get_advisors`) to confirm `process_checkout` and `user_addresses` findings clear; manually attempt an anon RPC call against `process_checkout` (e.g. via `curl` with the anon key, no auth header) before/after to confirm it's rejected post-fix.
- Phase 2: Click through the previously-dead dashboard links to confirm pages render; trigger a pagination failure (e.g. via airplane mode/throttling in the Flutter app) to confirm the new error state appears; run `flutter analyze` after any Dart changes.
- Phase 3/4: Manual UI walkthrough of search, bulk actions, and cart checkout in both the Flutter app and dashboard; `flutter test` for new widget tests.

