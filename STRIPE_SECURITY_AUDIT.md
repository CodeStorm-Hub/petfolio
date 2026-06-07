# Stripe Security Audit — Petfolio Marketplace Checkout

**Date:** 2026-06-08  
**Scope:** Flutter client, Supabase Edge Functions, Postgres checkout RPCs  
**Verdict:** **PASS** — secret keys stay server-side; client receives only publishable key and PaymentIntent client secrets.

---

## 1. Client-side key handling

| Check | Result |
|---|---|
| `STRIPE_SECRET_KEY` / `sk_live` / `sk_test` in `lib/` | **None found** |
| Publishable key source | `String.fromEnvironment('STRIPE_PUBLISHABLE_KEY')` in `main.dart` and `checkout_controller.dart` |
| Hardcoded fallback secret in Dart | **None** |

The Flutter app initializes `flutter_stripe` with the **publishable** key only. Production builds must supply `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_...` (or `.env` via `--dart-define-from-file`).

---

## 2. Payment Intent creation (server-side)

**Edge Function:** `supabase/functions/create-payment-intent/index.ts`

- Requires a valid Supabase JWT (`Authorization` header forwarded to anon client).
- Loads order + shop from Postgres using the authenticated user's context.
- Creates Stripe PaymentIntent / Checkout Session with `STRIPE_SECRET_KEY` from Deno env (Supabase secret).
- Returns only `clientSecret` or `checkoutUrl` to the client — never the secret key.

**Dart caller:** `OrderRepository.createPaymentIntent()` / `createCheckoutSession()` invoke the Edge Function via `_client.functions.invoke('create-payment-intent', ...)`.

---

## 3. Order lifecycle & inventory

| Step | Where | Notes |
|---|---|---|
| Reserve stock + create pending order | Postgres RPC `process_checkout` | Called from `OrderRepository.insertPendingOrder` |
| Present Payment Sheet | Flutter + `clientSecret` | No amount tampering — PI amount set server-side |
| Confirm payment | Stripe → webhook | Client `confirmOrder()` is a **no-op**; webhook drives status |
| Release on cancel | RPC `release_order_inventory` | `OrderRepository.cancelOrder` |

Post-checkout RPC errors are mapped to typed exceptions via `mapAndThrowCheckoutRpcException` (shop inactive, not verified, insufficient stock).

---

## 4. Webhook verification

**Edge Function:** `supabase/functions/stripe-webhook/index.ts`

- No Supabase JWT — **Stripe HMAC signature only** (`STRIPE_WEBHOOK_SECRET`, `STRIPE_CONNECT_WEBHOOK_SECRET`).
- Handles `payment_intent.succeeded`, `checkout.session.completed`, Connect `account.updated`, etc.
- Uses service-role Supabase client for order/inventory transitions after signature verification.

---

## 5. CoD (cash on delivery) path

Same Edge Function accepts `payment_method: 'cod'`. Server validates shop + inventory and stamps the order — client cannot skip validation.

---

## 6. Redirect URL hardening (web Checkout)

`create-payment-intent` validates `success_url` / `cancel_url` against `ALLOWED_REDIRECT_ORIGINS` or `PUBLIC_APP_ORIGIN`. Localhost is allowed for dev.

---

## 7. RLS & auth boundaries

- Checkout RPCs run as authenticated user; order rows scoped by buyer/seller policies.
- Product reviews, appointments, communities, care tables have RLS enabled in migrations (see `test/security/rls_migration_contract_test.dart`).

---

## 8. Recommendations (non-blocking)

1. **Rotate secrets** via Supabase Dashboard if any test key was ever committed to git history.
2. **Restrict CORS** on Edge Functions in production if Supabase project settings allow origin pinning.
3. **F5 integration test** (deferred): end-to-end Stripe test-mode checkout against emulator — requires live test keys and network.
4. **Migrate legacy RLS** policies that use bare `auth.uid()` to `(select auth.uid())` when those migrations are next touched (performance best practice).
5. **Certificate pinning (D4):** Deferred for production hardening — recommend `http_certificate_pinning` or platform network security config when shipping to app stores; not enabled in dev builds to avoid breaking Supabase/Stripe certificate rotations.

---

## 10. Plan completion status (2026-06-08)

| Area | Status |
|---|---|
| Phases 1–5 (router, M3E, perf, features, security/tests) | **Complete** |
| B7 Chat read receipts + typing | **Complete** (typing existed; read receipts + UPDATE policy added) |
| B8 Product card ratings | **Complete** |
| B10 First-launch tutorial | **Complete** (`AppTutorialOverlay`) |
| E10 Story reactions | **Complete** (persisted to `story_reactions`) |
| B3 Video / B4 Hashtags | **Already present** in social feed |
| F3 Integration test | **Present** (`integration_test/auth_care_flow_test.dart`) |
| F5 Stripe E2E | **Deferred** — requires live Stripe test-mode + device |
| D4 Cert pinning | **Deferred** — see recommendation above |
| A4 Use-case layer | **Deferred** — optional refactor; not required for plan verify |

---

## 9. Automated contract tests

- `test/security/stripe_client_contract_test.dart` — scans `lib/` for forbidden Stripe secret patterns.
- `test/security/rls_migration_contract_test.dart` — asserts critical tables have RLS + policies in SQL migrations.
- `test/features/marketplace/order_repository_exceptions_test.dart` — checkout RPC error mapping.
