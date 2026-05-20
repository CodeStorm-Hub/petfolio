# PetFolio — End-to-End Fix Plan (Verified Issues)

**For:** Claude Code on Claude Desktop  
**Branch:** `01-review-implementation`  
**Source of truth:** `verified-issues-01-review-implementation.md`  
**Stack:** Flutter 3.11+ · Riverpod 3 · GoRouter · Supabase (Postgres RLS · RPC · Edge Functions · Storage)

---

## Architecture decisions (read once)

These choices align with [Supabase security guidance](https://supabase.com/docs/guides/database/postgres/row-level-security), [Stripe payment status updates](https://docs.stripe.com/payments/payment-intents/verifying-status), and marketplace patterns (server-authoritative pricing, webhook as source of truth).

| Topic | Decision | Why |
|-------|----------|-----|
| **Pricing** | `process_checkout` reads `products.price_cents` / `sub_price_cents`; ignores client `unit_cents` & `line_total_cents` for `amount_cents` | Client never decides billable amount |
| **Inventory** | **Reservation table** + decrement on `payment_intent.succeeded` + release on cancel/fail/expiry | Matches Stripe PaymentSheet / 3DS delays; fixes P0-2 & P1-2 |
| **Checkout RPC** | Returns order id + server-computed `line_items` snapshot stored on order | Edge Function & webhook use DB truth |
| **RLS** | Wrap `auth.uid()` in subselect: `(select auth.uid())` | Postgres plan cache / perf (per `AGENTS.md`) |
| **Flutter** | Feature-first: `data/` → `presentation/controllers/` → `screens/` | Matches existing repo |
| **Errors** | Transient actions → `AppSnackBar.showError`; not long-lived `AsyncValue.error` on providers | Per `AGENTS.md` |
| **Migrations** | New files only; timestamp after `20260522000000_*`; apply via Supabase MCP or `npx supabase db push` | No edit of applied migrations in prod |
| **P3 subscriptions** | **Defer** real Stripe Billing to Phase 10; until then, server must still price subscribe lines from DB columns | Avoids shipping fake “subscriptions” as paid |

### Inventory reservation model (recommended)

```text
checkout RPC:
  → validate shop/products/stock (SELECT … FOR UPDATE on products)
  → insert marketplace_orders (pending)
  → insert inventory_reservations (active, expires_at = now() + 15 min)
  → NO decrement products.inventory_count

payment_intent.succeeded (webhook, service role):
  → confirm reservation → decrement inventory atomically
  → order → processing

cancelOrder / payment_failed / expiry job:
  → reservation → released
  → order → cancelled (if still pending)
```

---

## Claude Code token optimization (use every session)

Based on [CLAUDE.md context patterns](https://www.codewithseb.com/blog/claude-md-memory-persistent-context-guide) and [token budget guides](https://thepromptshelf.dev/blog/claude-md-token-budget-optimization-guide-2026/):

### Session ritual

1. **Start:** `@CLAUDE.md` `@AGENTS.md` `@verified-issues-01-review-implementation.md` `@progress.md` — only the phase section you are running.
2. **Scope:** One phase per session. Do not grep the whole repo; only paths listed in the prompt.
3. **End:** Update `progress.md` (bullets: done, contracts, next). Run `/compact` focusing on RPC signatures and file paths changed.
4. **Clear:** User runs `/remember` before the next phase (saves tokens per project rules).

### `.claudeignore` / reads

- Do not read `*.g.dart`, `android/`, `ios/`, design dumps.
- After model changes: run `build_runner` once at end of Dart phases — do not read generated files.

### Prompt rules (embed in every prompt)

- Code only — no new standalone docs unless asked.
- No inline comments / dartdocs unless business logic is non-obvious.
- Minimal diff; match existing naming and Riverpod 3 generated notifier style.
- Verify: `flutter analyze` + relevant `flutter test` before claiming done.

---

## Phase map (29 issues → 10 sessions)

| Phase | Issues | Est. | Blocker? |
|-------|--------|------|----------|
| **0** | Setup | 15 min | — |
| **1** | P0-1, P0-2, P1-2, P1-6 | 2–4 h | **Yes** |
| **2** | P0-3 | 30 min | **Yes** |
| **3** | P1-1, P1-3 | 1 h | High |
| **4** | P1-4, P1-5, P2-7, P2-11, P3-5 | 1–2 h | — |
| **5** | P2-1, P2-3, P2-4, P2-5 | 2–3 h | — |
| **6** | P2-2, P2-6, P2-8, P3-6 | 2–4 h | — |
| **7** | P2-10, P2-9 (optional view) | 2–3 h | — |
| **8** | P2-12 | 2–3 h | — |
| **9** | P3-2, P3-3, P3-8 | 2 h | — |
| **10** | P3-1, P3-4, P3-7 | Backlog | — |

---

## Phase 0 — Setup (run once)

### Manual steps

```bash
git checkout 01-review-implementation
git pull
flutter pub get
npx supabase start   # if local DB testing
```

### Claude Code prompt — Phase 0

```markdown
You are working on PetFolio branch `01-review-implementation`.

Read ONLY:
- CLAUDE.md
- AGENTS.md
- verified-issues-01-review-implementation.md
- progress.md (create if missing)

Do NOT change code. Produce a short checklist in progress.md:
- [ ] Phases 1–10 listed with issue IDs
- Note: marketplace P0 must merge before any production Stripe keys

Confirm flutter analyze passes. Report result only.
```

---

## Phase 1 — Marketplace: server pricing + inventory reservations (P0-1, P0-2, P1-2, P1-6)

**Read only:**

- `supabase/migrations/20260521120000_checkout_transaction_rpc.sql`
- `supabase/functions/stripe-webhook/index.ts`
- `supabase/functions/create-payment-intent/index.ts`
- `lib/features/marketplace/data/repositories/order_repository.dart`
- `lib/features/marketplace/presentation/controllers/checkout_controller.dart`
- `lib/features/marketplace/data/models/cart_item.dart`
- `lib/features/marketplace/data/models/product.dart`

### Deliverables

1. **Migration** `supabase/migrations/20260523100000_checkout_pricing_and_reservations.sql`:
   - Table `inventory_reservations` (`id`, `order_id`, `product_id`, `quantity`, `status` enum: `active|confirmed|released`, `expires_at`, timestamps).
   - Unique partial index: one `active` reservation per `(order_id, product_id)`.
   - RLS: no direct client writes; only via `SECURITY DEFINER` RPCs.
   - Replace `process_checkout`:
     - Input: `p_buyer_id`, `p_shop_id`, `p_cart_items` jsonb with **only** `product_id`, `quantity`, `is_subscribed`, `frequency_weeks` (ignore client prices).
     - Load products `FOR UPDATE`; compute `unit_cents` from `price_cents` / `sub_price_cents` + shop rules.
     - Validate stock: `inventory_count - active_reservations >= quantity` (or simpler: count reservations in SQL).
     - Insert order with server `amount_cents` and normalized `line_items`.
     - Insert reservations; **do not** decrement `inventory_count`.
   - Functions: `confirm_order_inventory(p_order_id)` (called from webhook), `release_order_inventory(p_order_id)` (cancel/fail).
2. **Edge:** `stripe-webhook` — on `payment_intent.succeeded`, call `confirm_order_inventory` before/at ledger insert; on `payment_intent.payment_failed`, call `release_order_inventory`.
3. **Edge:** `create-payment-intent` — use `marketplace_orders.amount_cents` from DB only (already should after RPC fix).
4. **Flutter:** `order_repository.dart` / `cart_item.dart` — send minimal cart JSON to RPC; map `INSUFFICIENT_STOCK` / `SHOP_NOT_VERIFIED` as today.
5. **Flutter:** `cancelOrder` — invoke `release_order_inventory` via RPC (not raw table update only).

### Claude Code prompt — Phase 1

```markdown
Implement Phase 1 from implementation-plan-fix-verified-issues.md for PetFolio.

Issues: P0-1, P0-2, P1-2, P1-6.

Rules:
- Feature-first; marketplace changes under lib/features/marketplace/ and supabase/.
- Server is source of truth for price and inventory lifecycle.
- Use (select auth.uid()) in new RLS policies.
- SECURITY DEFINER RPCs with explicit auth checks (buyer_id = auth.uid()).
- Do not edit old applied migrations; add 20260523100000_checkout_pricing_and_reservations.sql.
- Mirror error codes existing Dart expects (INSUFFICIENT_STOCK, SHOP_INACTIVE, etc.).
- No comments unless non-obvious.

Steps:
1. Add inventory_reservations + rewrite process_checkout (server pricing, reserve only).
2. Add confirm_order_inventory + release_order_inventory RPCs.
3. Update stripe-webhook and create-payment-intent to use RPCs / DB amount_cents only.
4. Update Flutter order_repository + checkout_controller + cart RPC payload (strip client price fields from RPC params).
5. Run flutter analyze.

After completion, update progress.md with RPC names, table schema, and manual test steps (happy path, cancel PaymentSheet, simulated webhook fail).

Do not implement P3 Stripe Billing subscriptions in this phase.
```

### Verification (you)

- [ ] Tampered `line_total_cents` in RPC params does not change `marketplace_orders.amount_cents`
- [ ] Cancel checkout restores sellable stock (reservation released)
- [ ] Webhook success decrements `inventory_count` once (idempotent replay safe)
- [ ] `npx supabase db reset` applies all migrations cleanly

---

## Phase 2 — Social storage bucket (P0-3)

**Read only:**

- `supabase/migrations/20260519030000_marketplace_images_bucket.sql`
- `lib/features/social/data/repositories/social_repository.dart` (upload path format)

### Claude Code prompt — Phase 2

```markdown
Implement Phase 2: P0-3 post-images storage bucket.

Copy the pattern from supabase/migrations/20260519030000_marketplace_images_bucket.sql:
- Bucket id: post-images, public read, 5MB, image mime types.
- Upload path: {auth.uid()}/{filename} — match social_repository.dart upload path.
- Policies: public SELECT; authenticated INSERT/UPDATE/DELETE scoped to first path segment = (select auth.uid())::text.

Add migration 20260523110000_post_images_bucket.sql only.

Verify social_repository upload path matches policy. Run flutter analyze. Update progress.md.
```

---

## Phase 3 — Admin KYC reject RPC + safe notification migration (P1-1, P1-3)

**Read only:**

- `supabase/migrations/20260520120000_admin_kyc_rpc.sql`
- `supabase/migrations/20260521130000_notifications_type_check.sql`
- `lib/features/admin/data/repositories/admin_repository.dart`
- `lib/features/admin/presentation/widgets/kyc_approvals_tab.dart` (if exists)

### Claude Code prompt — Phase 3

```markdown
Implement Phase 3: P1-1, P1-3.

1. New migration 20260523120000_reject_vendor_kyc.sql:
   - CREATE reject_vendor_kyc(p_shop_id uuid, p_admin_id uuid, p_reason text)
   - Mirror approve_vendor_kyc: is_admin(), admin_id = auth.uid(), update shops kyc_status=rejected, rejection_reason, audit_logs action kyc_rejected, notifications type kyc_rejected with metadata reason.

2. New migration 20260523120001_notifications_type_check_safe.sql (or combine):
   - ALTER TABLE ... DROP CONSTRAINT IF EXISTS notifications_type_check;
   - Re-add CHECK including like, comment, follow, kyc_approved, kyc_rejected.

3. admin_repository.rejectKyc → call RPC instead of direct shops update.

4. Ensure KYC UI passes non-empty reason on reject.

flutter analyze. Update progress.md.
```

---

## Phase 4 — Error UX batch (P1-4, P1-5, P2-7, P2-11, P3-5)

**Read only:**

- `lib/core/widgets/app_snack_bar.dart`
- `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart` (_ProfileHealthTab)
- `lib/features/care/presentation/controllers/health_vault_controller.dart`
- `lib/features/care/presentation/controllers/care_controller.dart`
- `lib/features/care/presentation/controllers/care_dashboard_controller.dart`
- `lib/features/social/presentation/controllers/social_controller.dart`

### Claude Code prompt — Phase 4

```markdown
Implement Phase 4 error UX (no schema changes):

P1-4: _ProfileHealthTab error state — add Retry button calling ref.invalidate(healthVaultControllerProvider). Match Care tab pattern.

P1-5: health_vault_controller — on add/update/deactivate failure after revert, call AppSnackBar.showError(e). Do not set StreamNotifier to permanent error for transient failures.

P2-7: care_controller CareNotifier.toggle — AppSnackBar.showError on catch (keep rollback).

P2-11: social_controller — toggleLike, updateCaption, deletePost: AppSnackBar.showError on catch (keep rollback). Do not swallow silently.

P3-5: care_dashboard_controller — surface badge/weekGoal fetch failures via AppSnackBar.showError or inline AsyncError on weekGoalHit (minimal).

flutter analyze. Update progress.md.
```

---

## Phase 5 — Pet profile: Awards, hero week bars, seller gate, activity chip (P2-1, P2-3, P2-4, P2-5)

**Read only:**

- `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`
- `lib/features/care/presentation/controllers/care_dashboard_controller.dart`
- `lib/features/care/data/repositories/pet_care_repository.dart` (`fetchPetBadgeTypes`)
- `lib/features/marketplace/presentation/controllers/my_shop_controller.dart` (or myShopProvider definition)

### Claude Code prompt — Phase 5

```markdown
Implement Phase 5 pet profile UI:

P2-1 Awards tab: Replace placeholder with list of pet badges for active pet. Reuse pet_care_repository.fetchPetBadgeTypes or expose provider from care feature. Show badge labels/icons consistent with AppSnackBar badge mapping. Loading/empty states.

P2-3 Hero weekly bars: Wire to careDashboardProvider.weekGoalHit (7 bools) for active pet — same pattern as care_screen.dart ~line 305. Keep streak number from careStreakRealtimeProvider.

P2-4 Seller card: Watch myShopProvider. No shop → /seller/setup; shop exists → /seller. Optional subtitle from KycStatus. Do not import router.dart from a file router already imports — use context.push literal paths.

P2-5 Remove hardcoded 'on a walk' chip OR derive from today's incomplete walk task on care dashboard (if walk task incomplete show 'Walk due', else hide chip).

flutter analyze. Update progress.md.
```

---

## Phase 6 — Profile overview + care legacy + timezone (P2-2, P2-6, P2-8, P3-6)

**Read only:**

- `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`
- `lib/features/care/presentation/controllers/care_controller.dart`
- `lib/features/care/presentation/controllers/care_dashboard_controller.dart`
- `lib/features/care/data/repositories/checklist_repository.dart`
- `lib/features/care/presentation/controllers/health_vault_controller.dart`

### Claude Code prompt — Phase 6

```markdown
Implement Phase 6:

P2-2 Overview tab:
- Replace hardcoded reminders with next due medical records (healthVaultControllerProvider, top 2 by sort): name + due date.
- Replace feed placeholder with latest 1–2 posts for active pet from social repository (add fetchPostsForPet(petId) if missing) or link button to /social/profile/{petId}.

P2-8 health_vault_controller sort: Primary key nextDueAt; if null use expiresAt then administeredAt; overdue items before nulls-with-future-expiry.

P2-6 Deprecate legacy 3-task CareNotifier where possible:
- Find usages of careControllerProvider; migrate UI to careDashboardProvider task list OR compute allDone from dynamic tasks for streak display.
- If family notifier still required, map CareTaskType feeding/walk/medication from dashboard tasks instead of hardcoded feed/walk/med only.

P3-6 Timezone: Use single helper careLocalDate() => DateUtils.dateOnly(DateTime.now().toLocal()) in care data layer; pass same date to RPC completion_date as logged_date. Document in progress.md only (no long comment in code).

flutter analyze. Update progress.md.
```

---

## Phase 7 — Medical documents + optional vault view (P2-10, P2-9 optional)

**Read only:**

- `lib/features/care/presentation/screens/medical_vault_screen.dart`
- `lib/features/care/data/repositories/health_repository.dart`
- `supabase/migrations/20260513192825_pet_care_health.sql`

### Claude Code prompt — Phase 7

```markdown
Implement Phase 7 medical vault attachments:

P2-10:
- Add storage bucket migration medical-documents (private, owner path {uid}/{petId}/{file}) OR reuse pattern from kyc-documents with pet owner RLS.
- health_repository: uploadDocument(file) → signed/public URL stored in document_url.
- medical_vault_screen add/edit: optional PDF/image picker, size limit, upload on save.

P2-9 (optional, only if quick):
- Add SQL view medical_vault_by_pet_active grouped by record_type OR RPC list_medical_vault — only if it reduces client filter code without N+1.

flutter analyze. Update progress.md.
```

---

## Phase 8 — Admin moderation queue (P2-12)

**Read only:**

- `supabase/migrations/20260520000000_add_reported_posts.sql`
- `lib/features/admin/presentation/screens/admin_layout.dart`
- `lib/features/social/data/repositories/social_repository.dart`

### Claude Code prompt — Phase 8

```markdown
Implement Phase 8: P2-12 admin moderation for reported_posts.

Schema (new migration if needed):
- reported_posts: add status enum pending|reviewed|dismissed, reviewed_by, reviewed_at (defaults pending).
- RLS: admins SELECT all via is_admin(); reporters keep insert/select own.

Admin:
- New tab Moderation in admin_layout.dart.
- List pending reports joined with post snippet + reporter.
- Actions: dismiss, hide post (posts.visibility or is_hidden if column exists — add migration if needed), audit_logs entry.

admin_repository: fetchPendingReports, resolveReport.

flutter analyze. Update progress.md.
```

---

## Phase 9 — Accessibility + header actions (P3-2, P3-3, P3-8)

**Read only:**

- `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`
- `lib/core/theme/app_theme.dart`
- `lib/core/router.dart` (notifications route)

### Claude Code prompt — Phase 9

```markdown
Implement Phase 9 polish:

P3-2 Accessibility on pet_profile_screen: Semantics on hero card (streak label), tab bar, seller card. Minimum 12sp for secondary labels where possible without layout break.

P3-3 Use Theme.of(context).textTheme / PetfolioThemeExtension for profile tab styles instead of raw Inter/Sora duplicates where touched.

P3-8 Wire AppHeader: notifications → /notifications (or existing route); outdoor mode → noop with tooltip 'Coming soon' OR remove button.

flutter analyze. Update progress.md.
```

---

## Phase 10 — Backlog (P3-1, P3-4, P3-7) — separate epic

Do **not** block release on Phase 10.

### P3-1 Stripe Billing (prompt stub)

```markdown
Design only (no full impl unless asked): Replace local subscribe discount with Stripe Subscription + customer portal + webhooks (customer.subscription.*). Requires new tables subscription_orders, stripe_customer_id on users. Write plan to progress.md.
```

### P3-4 Offline (prompt stub)

```markdown
Add Hive/Drift cache for social feed page 1 and health vault list per pet; sync on reconnect. Feature flags in core/cache/. Minimal scope.
```

### P3-7 Prefs versioning (prompt stub)

```markdown
Add int prefsVersion key to cart and checklist SharedPreferences; on mismatch clear key and reload from Supabase.
```

---

## Final verification session

### Claude Code prompt — Release gate

```markdown
Read progress.md phases 1–9 completion status.

Run and paste summaries:
flutter analyze
flutter test
npx supabase db reset (if local)

Manual test checklist:
1. Checkout with correct server total
2. Cancel PaymentSheet → stock available again
3. Post image upload
4. KYC reject with notification
5. Health retry, vault error snackbar, social like error snackbar
6. Awards tab badges, hero bars, seller gate

List any incomplete P3 items. Do not commit unless user asks.
```

---

## Issue → phase quick reference

| ID | Phase |
|----|-------|
| P0-1 | 1 |
| P0-2 | 1 |
| P0-3 | 2 |
| P1-1 | 3 |
| P1-2 | 1 |
| P1-3 | 3 |
| P1-4 | 4 |
| P1-5 | 4 |
| P1-6 | 1 |
| P2-1 | 5 |
| P2-2 | 6 |
| P2-3 | 5 |
| P2-4 | 5 |
| P2-5 | 5 |
| P2-6 | 6 |
| P2-7 | 4 |
| P2-8 | 6 |
| P2-9 | 7 (optional) |
| P2-10 | 7 |
| P2-11 | 4 |
| P2-12 | 8 |
| P3-1 | 10 |
| P3-2 | 9 |
| P3-3 | 9 |
| P3-4 | 10 |
| P3-5 | 4 |
| P3-6 | 6 |
| P3-7 | 10 |
| P3-8 | 9 |

---

## References (research)

| Topic | Link |
|-------|------|
| Supabase RLS & security | https://supabase.com/docs/guides/database/postgres/row-level-security |
| RPC from Flutter | https://supabase.com/docs/reference/dart/rpc |
| Stripe verify payment status | https://docs.stripe.com/payments/payment-intents/verifying-status |
| Stripe inventory / reservation discussion | https://stackoverflow.com/questions/65779944/stripe-paymentintent-best-practice-for-ensuring-inventory |
| Claude Code context / CLAUDE.md | https://www.codewithseb.com/blog/claude-md-memory-persistent-context-guide |
| Riverpod architecture | https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/ |

---

## After each phase (user action)

1. Review diff on GitHub Desktop  
2. `npx supabase db push` or MCP apply to staging  
3. Run app smoke test for that phase  
4. **`/remember`** in Claude Desktop before starting next phase  

Phase complete → update `progress.md` → save tokens before Phase N+1.
