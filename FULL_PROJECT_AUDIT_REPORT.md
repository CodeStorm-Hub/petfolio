# PetFolio Full Codebase Audit

> **Audit Date:** 2026-05-30  
> **Auditor:** Senior Staff Mobile Engineer + Principal Backend Architect  
> **Stack:** Flutter 3.x · Riverpod 3 (code-gen) · GoRouter · Supabase (PostgreSQL + PostGIS + Realtime + Storage) · Stripe Connect  
> **Scope:** Full codebase — `lib/`, `supabase/migrations/`, `supabase/functions/`

---

## 1. Unimplemented & Incomplete Features

### 1.1 Undo Swipe — Fully Stubbed

**File:** `lib/features/matching/presentation/screens/matching_screen.dart:1092`  
**Severity:** MEDIUM

The Undo (↺ replay) dock button displays a "coming soon" snackbar. There is no swipe history buffer, no `DiscoveryNotifier.undo()` method, and no DB write to un-record a swipe. The button is permanently disabled-looking to users.

**What is required:**
1. Add a `Queue<MatchingDiscoveryRow> _history` buffer inside `DiscoveryCandidatesBuffer` (max 3 entries).
2. Push to history on every `removeFront()` call.
3. Add `undoSwipe()` to `DiscoveryNotifier`: re-insert the top of history at front, delete the `swipes` row via `MatchingRepository.deleteSwipe(petId)`.
4. Add `deleteSwipe` to `MatchingSupabaseDataSource` using a `DELETE` filtered by `(actor_id, target_id)`.
5. Wire the button `onTap` to `ref.read(discoveryNotifierProvider.notifier).undoSwipe()`.

---

### 1.2 "Treat" Dock Button — Stubbed

**File:** `lib/features/matching/presentation/screens/matching_screen.dart:1078`  
**Severity:** LOW

The treat/gift action button shows a "Treats coming soon!" snackbar. No backend table or feature spec exists. This is a product decision, not an engineering gap — but the button should be visually disabled (opacity + `AbsorbPointer`) instead of appearing interactive.

---

### 1.3 Co-carer / Share Access — UI exists, backend does not

**File:** `lib/features/pet_profile/presentation/screens/manage_pets_screen.dart:634–667`  
**Severity:** MEDIUM

The "Share access" popup menu option renders a "Co-carer invites are coming soon" snackbar. No `pet_invites` table, no RLS, no invite-acceptance flow. The menu item should be hidden (`if (false)` guarded) until the feature ships, or the popup option should be removed entirely to avoid user confusion.

---

### 1.4 Social Search — Icon exists, screen does not

**File:** `lib/core/router.dart:555` (AppHeader search action)  
**Severity:** MEDIUM

The search icon in the social feed header has `onTap: () {}`. There is no `/social/search` route, no search controller, and no Supabase full-text search integration on `posts` or `pets`. The icon should be removed or replaced with a disabled state until implemented.1q

---

### 1.5 Product Wishlist / Save — Fully Stubbed

**Files:**
- `lib/features/marketplace/presentation/screens/product_detail_screen.dart:216`
- `lib/features/marketplace/presentation/widgets/product_card.dart:206`

**Severity:** MEDIUM

Both the product detail bookmark button and the product card save button have empty `onTap: () {}` handlers. No `wishlists` table exists. Requires: DB table, RLS, `WishlistRepository`, controller, and updated UI.

---

### 1.6 Hardcoded Decorative Moments on Pet Profile

**File:** `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart:114–118`  
**Severity:** LOW

Three `_MomentPlaceholder` widgets ("bath day", "napping", "park run") are hardcoded placeholder UI with no backing data, provider, or route. Should be replaced with actual post/photo data from `social_repository.fetchPostsForPet()` once the profile media grid is wired.

---

### 1.7 Post Three-Dot Overflow Menu — Empty Handler

**File:** `lib/features/social/presentation/screens/social_screen.dart:911`  
**Severity:** LOW

Feed post cards have a three-dot icon with `onTap: () {}`. The post detail screen (`post_detail_screen.dart`) has the full `_PostOptionsSheet` implemented. The feed card should open the same sheet (passing the `postId` and `isOwner` flags).

---

### 1.8 Vendor-Only Route Guards — Missing at Router Level

**File:** `lib/core/router.dart:410–445`  
**Severity:** MEDIUM

Routes under `/seller/*` have no router-level guard. Any authenticated user can deep-link to `/seller/products/add` and see the vendor UI. Individual screens render their own checks but there is no unified redirect. A `redirect` guard checking `myShopProvider` (or a simple `isVendorProvider` flag) should be added to the seller route subtree.

---

## 2. Critical Bugs & Security Vulnerabilities

### 2.1 🔴 CRITICAL — `confirm_order_inventory` Callable by Any Authenticated User

**Files:**
- `supabase/migrations/20260524000000_performance_security_fixes.sql:222`
- `supabase/migrations/20260524000001_function_grants_fix.sql:43`
- `supabase/functions/stripe-webhook/index.ts` (intended-only caller)

**The Bug:**
```sql
-- CURRENT (DANGEROUS):
GRANT EXECUTE ON FUNCTION public.confirm_order_inventory(uuid) TO authenticated;
```
`confirm_order_inventory` is a `SECURITY DEFINER` function that decrements `products.inventory_count` and marks an order's reservations as `confirmed`. It was designed to be called exclusively by the Stripe webhook via the `service_role` key. Because it is also granted to `authenticated`, **any logged-in user can call it directly** via the Supabase auto-generated RPC endpoint:

```bash
# Attacker script — free goods exploit
curl -X POST https://<project>.supabase.co/rest/v1/rpc/confirm_order_inventory \
  -H "Authorization: Bearer <valid_user_jwt>" \
  -H "Content-Type: application/json" \
  -d '{"order_id": "<their_pending_order_id>"}'
```

The function does not verify that Stripe collected payment. An attacker who has gone through `process_checkout` (which creates a valid reservation) can confirm their own order without paying, decrement inventory, and receive fulfillment confirmation — all without a Stripe payment intent succeeding.

**Fix — new migration:**
```sql
-- supabase/migrations/20260530000001_revoke_confirm_inventory_from_authenticated.sql
REVOKE EXECUTE ON FUNCTION public.confirm_order_inventory(uuid) FROM authenticated;
-- The function remains callable by the service_role key used in the webhook.
-- Also add a payment guard inside the function itself as defence-in-depth:
CREATE OR REPLACE FUNCTION public.confirm_order_inventory(p_order_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_payment_status text;
BEGIN
  -- Defence-in-depth: only confirm orders that Stripe has already stamped
  SELECT payment_status INTO v_payment_status
  FROM public.marketplace_orders
  WHERE id = p_order_id;

  IF v_payment_status IS DISTINCT FROM 'paid' THEN
    RAISE EXCEPTION 'ORDER_NOT_PAID: order % has payment_status=%', p_order_id, v_payment_status;
  END IF;

  UPDATE public.products p
  SET inventory_count = p.inventory_count - ir.quantity
  FROM public.inventory_reservations ir
  WHERE ir.order_id = p_order_id
    AND ir.product_id = p.id
    AND ir.status = 'active';

  UPDATE public.inventory_reservations
  SET status = 'confirmed'
  WHERE order_id = p_order_id AND status = 'active';
END;
$$;
```

> **Deploy immediately.** This is an active payment bypass vulnerability.

---

### 2.2 HIGH — `ref.listen` Inside `build()` Registers Duplicate Listeners on Every Rebuild

**Files:**
- `lib/features/care/presentation/controllers/care_controller.dart:111`
- `lib/features/marketplace/presentation/controllers/cart_controller.dart:29`

**The Bug:**
In Riverpod 3, when a `Notifier.build()` method runs (on first creation AND on any watched dependency change), calling `ref.listen(...)` inside it registers **an additional listener** without removing the previous one. After N rebuilds, N listeners are active and the callback fires N times per event.

```dart
// care_controller.dart — CURRENT (BUG):
@override
DailyRoutineState build() {
  // This registers a NEW listener every time build() runs
  ref.listen<DailyRoutineState>(careDashboardProvider, (prev, next) {
    _syncFromDashboard(next);
  });
  return const DailyRoutineState();
}
```

**Fix:**
```dart
// care_controller.dart — FIXED:
@override
DailyRoutineState build() {
  // ref.listen IS safe inside build() in Riverpod 3 — the framework
  // automatically removes the listener when the provider is rebuilt.
  // HOWEVER, verify your riverpod version: in riverpod ^2.x this was NOT
  // the case. If on Riverpod 2.x, replace with ref.watch + reaction:
  final dashboard = ref.watch(careDashboardProvider);
  // Use a side-effect via ref.listenSelf or restructure to derive state:
  Future.microtask(() => _syncFromDashboard(dashboard));
  return const DailyRoutineState();
}
```

> **Note:** Riverpod 3 (`riverpod_annotation ^2.x`) does safely scope `ref.listen` calls inside `build()` — they are tied to the provider's lifetime and replaced on rebuild. Verify this is actually Riverpod 3 by checking `pubspec.yaml`'s `flutter_riverpod` version. If `^2.x`, the bug is active and must be fixed.

---

### 2.3 HIGH — Vendor Route Deep-Link Bypasses Shop Guard

**File:** `lib/core/router.dart:410–445`

**The Bug:** Any authenticated user (non-vendor) who knows the URL `/seller/products/add` can navigate there. The `VendorProductAddScreen` calls `ref.watch(myShopProvider)` but does not redirect — it shows a loading spinner indefinitely when the shop is null.

**Fix (non-breaking, additive redirect):**
```dart
// router.dart — add to the /seller route subtree:
GoRoute(
  path: '/seller',
  redirect: (context, state) async {
    final shop = await ref.read(myShopProvider.future);
    if (shop == null && state.matchedLocation != '/seller/setup') {
      return '/seller/setup';
    }
    return null;
  },
  // ... existing routes unchanged
)
```

---

### 2.4 HIGH — `BuildContext` Used After `async` Gap Without `mounted` Guard

**Files (selected):**
- `lib/features/marketplace/presentation/screens/cart_screen.dart:312`
- `lib/features/care/presentation/screens/care_screen.dart:412`
- `lib/features/social/presentation/screens/create_post_screen.dart:198`

**The Bug:**
```dart
// cart_screen.dart — CURRENT (BUG):
Future<void> _startCheckout() async {
  await ref.read(checkoutProvider.notifier).startCheckoutForShop(shopId);
  context.push('/orders/${controller.lastOrderId}'); // context may be stale
}
```

If the widget is disposed while the `await` is pending, `context` is invalid and `context.push()` throws or navigates on a dead tree.

**Fix:**
```dart
Future<void> _startCheckout() async {
  await ref.read(checkoutProvider.notifier).startCheckoutForShop(shopId);
  if (!mounted) return;
  context.push('/orders/${controller.lastOrderId}');
}
```

Run this search to find all instances:
```bash
rg -n "await " lib/ --type dart -A1 | grep -v "mounted" | grep "context\."
```

---

### 2.5 MEDIUM — `is_admin` Read From Client-Side JWT `appMetadata`

**File:** `lib/features/admin/presentation/controllers/admin_auth_controller.dart:9`

**The Bug:**
```dart
data: (s) => s.session?.user.appMetadata['is_admin'] == true,
```
JWT `appMetadata` is only refreshed on token rotation (~55 minutes). An admin whose privilege is revoked retains admin access on the client for up to 55 minutes. The server-side `is_admin()` function is authoritative, but the Flutter router redirect and the admin UI gate both use the stale client value.

**Fix:** The router guard should also be backed by a server-side check (an RPC or a Supabase Edge Function returning the current admin status), or at minimum, `authStateChanges` should force a `supabase.auth.refreshSession()` before evaluating the admin gate. Low operational risk since `is_admin()` is enforced on every RPC, but it creates a window for privilege confusion.

---

### 2.6 MEDIUM — `pollOrderConfirmation` Busy-Polls the Database (7–8 Round-Trips Per Checkout)

**File:** `lib/features/marketplace/data/repositories/order_repository.dart:196–213`

**The Bug:**
```dart
// CURRENT — polling every 2s for up to 15s:
while (DateTime.now().isBefore(deadline)) {
  final order = await fetchOrder(orderId);
  if (order.status == OrderStatus.confirmed) return order;
  await Future<void>.delayed(interval); // 2 second interval
}
```
This generates up to 8 DB round-trips per user checkout. Under load (many simultaneous checkouts), this becomes a significant database read amplifier. It also holds the Flutter async context open for 15 seconds.

**Fix — replace with Realtime subscription:**
```dart
// order_repository.dart — FIXED:
Future<MarketplaceOrder> waitForOrderConfirmation(String orderId) async {
  final completer = Completer<MarketplaceOrder>();
  final channel = _client
      .channel('order-$orderId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'marketplace_orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: orderId,
        ),
        callback: (payload) {
          final updated = MarketplaceOrder.fromJson(payload.newRecord);
          if (updated.status == OrderStatus.confirmed ||
              updated.status == OrderStatus.cancelled) {
            if (!completer.isCompleted) completer.complete(updated);
          }
        },
      )
      .subscribe();

  try {
    return await completer.future.timeout(const Duration(seconds: 30));
  } finally {
    await channel.unsubscribe();
  }
}
```

---

## 3. Architecture & State Management Debt

### 3.1 Unbounded Supabase Queries — Memory Exhaustion Risk

**Severity:** HIGH  
The following repository methods fetch **all matching rows** with no `.limit()`. For active users/shops these will grow unbounded and eventually cause OOM errors, slow cold starts, and timeouts.

| File | Method | Table | Risk |
|---|---|---|---|
| `order_repository.dart:161` | `fetchBuyerOrders()` | `marketplace_orders` | All historical orders |
| `order_repository.dart:171` | `fetchVendorOrders()` | `marketplace_orders` | All shop orders |
| `shop_repository.dart:28` | `fetchAllActiveShops()` | `shops` | All active shops |
| `matching_datasource.dart:87` | `fetchMatchesForPet()` | `matches` | All matches (popular pets) |
| `matching_datasource.dart:131` | `fetchParticipantThreads()` | `chat_threads` | All threads |
| `health_repository.dart:50` | `fetchLogsForPet()` | `health_logs` | All health logs |

**Fix pattern (apply to all six):**
```dart
// order_repository.dart — FIXED fetchBuyerOrders:
Future<List<MarketplaceOrder>> fetchBuyerOrders({int limit = 30, int offset = 0}) async {
  final rows = await _client
      .from('marketplace_orders')
      .select()
      .eq('buyer_id', _uid)
      .order('created_at', ascending: false)
      .range(offset, offset + limit - 1); // ADD THIS
  return rows.map(MarketplaceOrder.fromJson).toList();
}
```

Update callers to pass `limit/offset` and implement load-more in the corresponding controllers (`buyerOrdersProvider`, `vendorOrdersProvider`, `shopListProvider`).

---

### 3.2 Widespread `.select()` Over-Fetching on Sensitive Tables

**Severity:** MEDIUM  
`shop_repository.dart` uses bare `.select()` (all 22+ columns) across 8 call sites. The `shops` table contains sensitive vendor fields: `trade_license_url`, `national_id_url`, `bank_account_details` (jsonb), `stripe_connect_account_id`. These are returned to the Flutter client on every shop listing load.

**Fix — scope columns for public-facing queries:**
```dart
// shop_repository.dart — public shop listing:
static const _publicShopColumns =
    'id,shop_name,tagline,logo_url,banner_url,is_verified,payout_method,kyc_status,created_at';

Future<List<Shop>> fetchAllActiveShops() async {
  final rows = await _client
      .from('shops')
      .select(_publicShopColumns) // was .select()
      .eq('is_active', true)
      .eq('is_verified', true)
      .order('created_at')
      .limit(50);
  return rows.map(Shop.fromJson).toList();
}
```

Keep the full `.select()` only for `fetchMyShop()` (vendor sees their own data) and admin queries.

---

### 3.3 `HealthVaultController` Stream Has No Row Limit

**File:** `lib/features/care/presentation/controllers/health_vault_controller.dart:25`  
**Severity:** MEDIUM

```dart
// CURRENT — unbounded Realtime stream:
Supabase.instance.client
    .from('medical_vault')
    .stream(primaryKey: ['id'])
    .eq('pet_id', petId)
    // .limit() MISSING
    .map(...)
```

Every Realtime event (any record insert/update for the pet) triggers a re-fetch of all medical records. For older pets with decades of records this accumulates.

**Fix:**
```dart
.stream(primaryKey: ['id'])
.eq('pet_id', petId)
.limit(100) // reasonable medical history cap
.order('administered_at', ascending: false)
```

---

### 3.4 Silent Error Swallowing — Five `SizedBox.shrink()` Error States

**Severity:** MEDIUM  
These error handlers silently hide failures from the user. The screens appear empty with no feedback, no retry button, and no logging.

| File | Context | Impact |
|---|---|---|
| `nutrition_screen.dart:633` | Weight chart load failure | Chart disappears silently |
| `social_screen.dart:334` | Stories strip load failure | No stories shown, no feedback |
| `social_profile_screen.dart:100` | Awards load failure | Awards tab blank |
| `pet_switcher_sheet.dart:101` | Pet list load failure | Switcher shows nothing |
| `pet_profile_screen.dart:378` | Today's task chip failure | Chip disappears silently |

**Fix pattern (apply to all five):**
```dart
// Replace:
error: (err, st) => const SizedBox.shrink(),

// With:
error: (err, st) => _ErrorChip(onRetry: () => ref.invalidate(theProvider)),
// or for non-critical UI:
error: (err, st) {
  debugPrint('$runtimeType error: $err\n$st');
  return const SizedBox.shrink(); // at least log it
},
```

---

### 3.5 `ref.read(petListProvider)` Inside GoRouter `builder` — Cold-Start Race

**File:** `lib/core/router.dart:318–322`  
**Severity:** MEDIUM

```dart
// CURRENT — races on cold start:
builder: (context, state) {
  final pets = ref.read(petListProvider).value ?? []; // null if still loading
  final pet = pets.firstWhereOrNull((p) => p.id == petId);
  return pet != null ? EditProfileScreen(pet: pet) : const _PetEditMissingScreen();
},
```

On a cold-start deep-link to `/pet/:petId/edit`, `petListProvider` is still `AsyncLoading`. `value` returns `null`, the pet is not found, and `_PetEditMissingScreen` is shown incorrectly.

**Fix:**
```dart
builder: (context, state) {
  return Consumer(
    builder: (context, ref, _) {
      final petsAsync = ref.watch(petListProvider);
      return petsAsync.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => const _PetEditMissingScreen(),
        data: (pets) {
          final pet = pets.firstWhereOrNull((p) => p.id == petId);
          return pet != null ? EditProfileScreen(pet: pet) : const _PetEditMissingScreen();
        },
      );
    },
  );
},
```

---

### 3.6 `isFollowing()` Fetches Full Row to Check Existence

**File:** `lib/features/social/data/repositories/social_repository.dart:356`  
**Severity:** LOW

```dart
// CURRENT — over-fetches:
final result = await _client
    .from('pet_follows')
    .select()         // fetches all columns
    .eq('follower_pet_id', followerId)
    .eq('followed_pet_id', followedId)
    .maybeSingle();
return result != null;
```

**Fix:**
```dart
final result = await _client
    .from('pet_follows')
    .select('follower_pet_id') // minimal column
    .eq('follower_pet_id', followerId)
    .eq('followed_pet_id', followedId)
    .maybeSingle();
return result != null;
```

---

## 4. UI/UX & Performance Bottlenecks

### 4.1 `Image.network` Without Caching — 6 Locations

**Severity:** MEDIUM  
The app uses `CachedNetworkImage` correctly in most places, but these 6 locations use the uncached `Image.network`, causing images to re-download on every rebuild/navigation:

| File | Line | Context |
|---|---|---|
| `kyc_approvals_tab.dart` | 406 | KYC document thumbnails |
| `shop_storefront_screen.dart` | 135 | Shop logo |
| `shop_storefront_screen.dart` | 168 | Shop banner |
| `edit_shop_screen.dart` | 345 | Logo picker preview |
| `edit_shop_screen.dart` | 423 | Banner picker preview |
| `seller_dashboard_screen.dart` | 440 | Dashboard shop logo |

**Fix (uniform pattern):**
```dart
// Replace:
Image.network(url, fit: BoxFit.cover)

// With:
CachedNetworkImage(
  imageUrl: url,
  fit: BoxFit.cover,
  placeholder: (context, url) => const _ShimmerBox(),
  errorWidget: (context, url, err) => const Icon(Icons.broken_image_rounded),
)
```

---

### 4.2 Non-Lazy `ListView` — 8 Locations

**Severity:** MEDIUM  
These `ListView(children: [...])` calls instantiate all children immediately, bypassing Flutter's virtualization. The care task list and matches inbox are the highest-priority fixes.

| File | List Type | Why It Matters |
|---|---|---|
| `care_screen.dart:165` | Care tasks | Grows with AI-generated tasks |
| `matches_inbox_screen.dart:127` | Match list | Can have 100s of matches |
| `marketplace_screen.dart:752` | Product listing | Fallback non-paginated list |
| `cart_screen.dart:91` | Cart items | Lower risk (bounded) |
| `pet_switcher_sheet.dart:133` | Pet list | Lower risk (bounded) |
| `routine_recommendation_sheet.dart:148` | AI recommendations | 6–8 items — low risk |

**Fix pattern:**
```dart
// Replace:
ListView(children: tasks.map((t) => TaskCard(t)).toList())

// With:
ListView.builder(
  itemCount: tasks.length,
  itemBuilder: (context, i) => TaskCard(tasks[i]),
)
```

---

### 4.3 `MediaQuery.of(context)` — Full Subscription to All MediaQuery Changes

**Severity:** LOW  
These locations subscribe to the full `MediaQueryData` object when they only need one field, causing unnecessary rebuilds on keyboard appear/disappear, text scale changes, etc.

| File | Current | Fix |
|---|---|---|
| `onboarding_screen.dart:310` | `.of(context).size.width` | `MediaQuery.sizeOf(context).width` |
| `onboarding_screen.dart:311` | `.of(context).size.height` | `MediaQuery.sizeOf(context).height` |
| `nutrition_screen.dart:793` | `.of(context).viewInsets.bottom` | `MediaQuery.viewInsetsOf(context).bottom` |

---

### 4.4 Social Profile Posts — No Pagination Beyond Initial 50-Row Fetch

**File:** `lib/features/social/data/repositories/social_repository.dart:96`  
**Severity:** LOW

`fetchPostsForPet` fetches up to 50 posts on profile open. `SocialProfileController` has no `loadMore()`. For prolific pets this loads 50 post thumbnail URLs at once (potentially 50 network requests for images). Implementing cursor-based pagination with `PhotoGridView`'s scroll listener is recommended.

---

### 4.5 Missing Global Crash Handler

**File:** `lib/main.dart`  
**Severity:** LOW

There is no `FlutterError.onError` or `PlatformDispatcher.instance.onError` registered. Uncaught widget-build exceptions and unhandled async errors are only visible in the debug console and will be lost silently in production builds.

**Fix (add to `main()` before `runApp`):**
```dart
void main() async {
  // Add before runApp:
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO: fire to Sentry / Crashlytics:
    // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    // TODO: fire to Sentry / Crashlytics
    debugPrint('Unhandled async error: $error\n$stack');
    return true;
  };
  // ... rest of existing main()
}
```

---

### 4.6 Outdated Dependencies With Breaking Version Gaps

**Severity:** LOW  
The following dependencies have major-version updates with breaking changes that should be scheduled for a dedicated upgrade sprint:

| Package | Current | Latest | Risk |
|---|---|---|---|
| `flutter_local_notifications` | `^18.0.1` | `^21.0.0` | HIGH — API breaking |
| `geolocator` | `^13.0.4` | `^14.0.2` | MEDIUM — method renames |
| `permission_handler` | `^11.4.0` | `^12.0.2` | MEDIUM — API changes |
| `supabase_flutter` | `^2.9.0` | `^2.10.x` | LOW — patch/minor fixes |
| `timezone` | `^0.9.4` | `^0.11.0` | LOW |

---

### 4.7 CORS Wildcard on Payment Edge Functions

**Files:**
- `supabase/functions/create-payment-intent/index.ts:27`
- `supabase/functions/stripe-onboard-vendor/index.ts:31`

**Severity:** LOW (mobile-only risk is minimal; risk increases if web build ships)

```ts
// CURRENT:
'Access-Control-Allow-Origin': '*',
```

For a web build, this allows any origin to call these endpoints. Since auth is JWT-gated this is not a direct exploit, but it enables phishing-style cross-origin Stripe interactions. When the web build ships, replace with:
```ts
'Access-Control-Allow-Origin': 'https://app.petfolio.com',
```

---

### 4.8 `medical-documents` Storage Bucket — No Admin Read Policy

**File:** `supabase/migrations/20260523130000_medical_documents_bucket.sql`  
**Severity:** LOW

The `kyc-documents` bucket has `kyc_admin_read` and `kyc_admin_delete` policies. The `medical-documents` bucket has only owner-scoped policies. Admins cannot review medical documents in moderation scenarios. Add an admin read policy consistent with the KYC bucket pattern.

---

## 5. Recommended Execution Order

Issues are ordered by **severity × blast radius**. Each item includes the files to hand to Claude Code for implementation.

---

### Phase 1 — Deploy Immediately (Security & Data Integrity)

| # | Issue | File(s) | Action |
|---|---|---|---|
| 1 | **CRITICAL:** `confirm_order_inventory` callable by all users | New migration | Write & apply `20260530000001_revoke_confirm_inventory.sql` — REVOKE + add payment guard |
| 2 | **HIGH:** `mounted` guards missing on async context usage | `cart_screen.dart`, `care_screen.dart`, `create_post_screen.dart` | Add `if (!mounted) return;` after every `await` before `context.*` call |

---

### Phase 2 — Fix Before Next Feature Sprint (Stability & Correctness)

| # | Issue | File(s) | Action |
|---|---|---|---|
| 3 | Unbounded queries — orders, shops, matches | `order_repository.dart`, `shop_repository.dart`, `matching_supabase_data_source.dart`, `health_repository.dart` | Add `.limit()` + pagination to all 6 methods; update controllers |
| 4 | Polling checkout replaced with Realtime | `order_repository.dart:196–213`, `checkout_controller.dart` | Replace `pollOrderConfirmation` with Realtime channel |
| 5 | Cold-start race in pet edit route | `router.dart:318–322` | Wrap in `Consumer` with `AsyncValue.when` |
| 6 | Silent error swallowing — 5 `SizedBox.shrink()` errors | `nutrition_screen.dart`, `social_screen.dart`, `social_profile_screen.dart`, `pet_switcher_sheet.dart`, `pet_profile_screen.dart` | Replace with minimal error widget + `debugPrint` |
| 7 | Vendor route deep-link bypass | `router.dart` | Add seller subtree `redirect` guard |

---

### Phase 3 — Performance & UX Polish

| # | Issue | File(s) | Action |
|---|---|---|---|
| 8 | `Image.network` → `CachedNetworkImage` | `kyc_approvals_tab.dart`, `shop_storefront_screen.dart`, `edit_shop_screen.dart`, `seller_dashboard_screen.dart` | Swap 6 occurrences |
| 9 | Non-lazy `ListView` → `ListView.builder` | `care_screen.dart`, `matches_inbox_screen.dart`, `marketplace_screen.dart` | Swap 3 priority occurrences |
| 10 | `.select()` scoping on `shops` table | `shop_repository.dart` | Add `_publicShopColumns` const, update 8 call sites |
| 11 | `HealthVaultController` stream limit | `health_vault_controller.dart:25` | Add `.limit(100).order(...)` to stream |
| 12 | `MediaQuery.of` → `MediaQuery.sizeOf/viewInsetsOf` | `onboarding_screen.dart`, `nutrition_screen.dart` | 3 line changes |

---

### Phase 4 — Product Completeness

| # | Issue | File(s) | Action |
|---|---|---|---|
| 13 | Undo swipe implementation | `matching_screen.dart`, `discovery_candidates_controller.dart`, `matching_supabase_data_source.dart` | History buffer + `deleteSwipe` RPC |
| 14 | Product wishlist | New migration + `WishlistRepository` + controller + UI | Full feature |
| 15 | Social search | New `/social/search` route + full-text search RPC | Full feature |
| 16 | Co-carer invite | Hide menu item until backend exists | 1-line guard |
| 17 | Post feed three-dot menu | `social_screen.dart:911` | Wire to existing `_PostOptionsSheet` |
| 18 | Global crash handler | `main.dart` | Add `FlutterError.onError` + `PlatformDispatcher.onError` |
| 19 | Dependency upgrades | `pubspec.yaml` | Scheduled upgrade sprint |

---

*End of audit. Total issues: 1 Critical · 4 High · 9 Medium · 10 Low.*
