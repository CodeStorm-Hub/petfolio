# Multi-Vendor Marketplace — Architecture Blueprint

## Key Decisions (Resolved)

| Topic | Decision | Reason |
|---|---|---|
| Stripe payment flow | **Destination Charges** (`transfer_data.destination` + `application_fee_amount` in one PI) | Simpler than Separate Charges; platform owns customer relationship; Stripe handles split atomically |
| Vendor onboarding return | **`AppLifecycleState.resumed` polling** (`ref.invalidate(myShopProvider)`) | Zero native config; no `app_links` package or `AndroidManifest` / `Info.plist` changes needed |
| Onboarding browser | **`url_launcher`** (native browser) | Stripe explicitly requires native browser for KYC; WebView blocks identity verification SDKs |
| Checkout state | **Single `CheckoutNotifier` + `shopId` in `CheckoutState`** | Prevents two Payment Sheets opening simultaneously; Stripe SDK only supports one active sheet |
| Cart grouping | **Computed `itemsByShop` getter on `CartState`** (derive from `product.shopId`, no duplication in `CartItem`) | No data duplication; single source of truth in `Product` |
| Platform product migration | Insert "PetFolio Official" `shops` row with `is_verified=true, stripe_onboarding_complete=true, platform_fee_percent=0`, then `UPDATE products SET shop_id = petfolio_official_id` | Unifies entire data model; no special-casing platform vs vendor products |
| PetFolio Official ownership | Requires a real `auth.users` row (a service/admin account). Create one via Supabase Auth admin API before applying the products migration. | UNIQUE constraint on `shops.owner_id` references `auth.users` |
| Order statuses | **`pending → processing → shipped → delivered → cancelled`** | Matches user spec; `confirmed` removed; client sets `processing` after payment sheet succeeds (same effect, no race with webhook) |
| `confirmOrder` call | Rename to update status to `processing` (not `confirmed`) to match new status set | |
| `seller_id` column | Retained as-is on `marketplace_orders` (nullable, not populated for new orders) — `shop_id` supersedes it | Avoids breaking existing RLS/code; can be dropped in a future cleanup migration |

---

## Complete File Map

### Supabase Migrations (4 new files)

| File | Contents |
|---|---|
| `20260519000000_shops_table.sql` | `shops` table DDL, 4 RLS policies, `updated_at` trigger, indexes, grants |
| `20260519010000_products_vendor_columns.sql` | Add `shop_id`, `image_urls text[]`, `inventory_count int` to `products`; seed PetFolio Official shop; migrate 8 rows; replace old SELECT-only policy with 4 vendor write policies |
| `20260519020000_orders_vendor_columns.sql` | Add `shop_id`, `shipping_tracking_number`, `shipping_tracking_url`, `shipping_carrier`, `shipped_at` to `marketplace_orders`; migrate 1 existing row; update status CHECK to new 5-value set; update RLS (buyer + vendor policies) |
| `20260519030000_marketplace_images_bucket.sql` | Create `marketplace-images` bucket in `storage.buckets`; 3 storage object policies (public read, authenticated upload to `{userId}/*`, owner delete) |

### Edge Functions (2 new, 1 modified)

| File | Action | Key Change |
|---|---|---|
| `supabase/functions/create-payment-intent/index.ts` | **Modify** | Add `shop_id` to select; look up `shops.stripe_connect_account_id` + `platform_fee_percent` server-side; add `transfer_data`, `application_fee_amount` to PI creation; add `shop_id` to PI metadata |
| `supabase/functions/stripe-onboard-vendor/index.ts` | **Create** | Auth → verify shop ownership → create/reuse Connect Express account → generate `account_link` → return `{ accountLinkUrl }` |
| `supabase/functions/stripe-webhook/index.ts` | **Create** | Verify `Stripe-Signature`; handle `account.updated` → set `is_verified=true`; handle `payment_intent.succeeded` → set order `status='processing'`; handle `payment_intent.payment_failed` |

New Supabase secrets needed:
```bash
npx supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
npx supabase secrets set PUBLIC_APP_URL=https://jqyjvhwlcqcsuwcqgcwf.supabase.co
```

### Flutter — Models (create/modify)

| File | Action | Contents |
|---|---|---|
| `data/models/shop.dart` | **Create** | Plain Dart class: `id, ownerId, shopName, slug, description, logoUrl?, bannerUrl?, isActive, isVerified, stripeConnectAccountId?, stripeOnboardingComplete, platformFeePercent, createdAt`. `fromJson`/`toJson`/`copyWith` |
| `data/models/order_status.dart` | **Create** | Enum: `pending, processing, shipped, delivered, cancelled`. `fromString(String)` with `pending` fallback. `label` getter |
| `data/models/line_item.dart` | **Create** | `productId, productName, quantity, unitCents, lineTotalCents`. `fromJson`/`toJson` |
| `data/models/marketplace_order.dart` | **Create** | Typed model replacing raw `Map`: `id, buyerId, shopId?, shopName?, title, amountCents, currency, status (OrderStatus), lineItems (List<LineItem>), trackingNumber?, trackingUrl?, carrier?, shippedAt?, createdAt, updatedAt`. `fromJson`/`copyWith` |
| `data/models/product.dart` | **Modify** | Add `shopId (String?)`, `shopName (String?)`, `imageUrls (List<String>)`, `inventoryCount (int)`. Add `copyWith`. Update `fromJson` for all 4 new fields |
| `data/models/cart_item.dart` | **Modify** | `CartItem.toJson()` adds `'shop_id': product.shopId`. `CartState` gains `itemsByShop` getter (`Map<String?, List<CartItem>>`), `totalCentsForShop(String?)`. `CartNotifier` gains `clearShop(String shopId)` |

### Flutter — Repositories (create/modify)

| File | Action | Key Methods |
|---|---|---|
| `data/repositories/shop_repository.dart` | **Create** | `fetchAllActiveShops()`, `fetchShopById(id)`, `fetchMyShop()`, `createShop(name, desc)`, `updateShop(id, {...})`, `startStripeOnboarding(shopId) → String (url)` |
| `data/repositories/vendor_product_repository.dart` | **Create** | `fetchMyProducts(shopId)`, `createProduct(shopId, data)`, `updateProduct(id, data)`, `deleteProduct(id)` |
| `data/repositories/product_repository.dart` | **Modify** | Add `fetchProductsByShop(shopId)`. Update `fetchProducts()` to `.select('*, shops!shop_id(shop_name)')` and map shop join into `Product.shopName` |
| `data/repositories/order_repository.dart` | **Modify** | `insertPendingOrder` — add `shopId` param, filter items by shop, use `totalCentsForShop`. `confirmOrder` → sets status `'processing'`. Add `fetchBuyerOrders()`, `fetchVendorOrders(shopId)`, `updateOrderTracking(id, {num?, url?, carrier?})`, `updateOrderStatus(id, status)`. `fetchOrder` → returns `MarketplaceOrder` (not raw Map) |

### Flutter — Controllers (create/modify)

| File | Action | Contents |
|---|---|---|
| `controllers/my_shop_controller.dart` | **Create** | `AsyncNotifierProvider<MyShopNotifier, Shop?>`. `build()` → `fetchMyShop()`. Methods: `createShop()`, `updateShop()`, `startOnboarding()` (calls repo, returns url, invalidates `shopListProvider`) |
| `controllers/shop_list_controller.dart` | **Create** | `AsyncNotifierProvider<ShopListNotifier, List<Shop>>`. `build()` → `fetchAllActiveShops()` |
| `controllers/shop_products_controller.dart` | **Create** | `AsyncNotifierProvider.family<ShopProductsNotifier, List<Product>, String>`. `build(shopId)` → `fetchProductsByShop(shopId)` |
| `controllers/vendor_products_controller.dart` | **Create** | `AsyncNotifierProvider<VendorProductsNotifier, List<Product>>`. Watches `myShopProvider`. Methods: `createProduct()`, `updateProduct()`, `deleteProduct()` |
| `controllers/vendor_orders_controller.dart` | **Create** | `AsyncNotifierProvider<VendorOrdersNotifier, List<MarketplaceOrder>>`. Watches `myShopProvider`. Methods: `updateTracking()`, `updateStatus()` |
| `controllers/buyer_orders_controller.dart` | **Create** | `AsyncNotifierProvider<BuyerOrdersNotifier, List<MarketplaceOrder>>`. `build()` → `fetchBuyerOrders()` |
| `controllers/checkout_controller.dart` | **Modify** | `CheckoutState` gains `activeShopId (String?)`. Add `startCheckoutForShop(String shopId)`. Keep existing `startCheckout()` for backward compat. Add `clearShop` call on success |

### Flutter — Screens (create/modify)

| File | Route | Action |
|---|---|---|
| `screens/shop_storefront_screen.dart` | `/shop/:id` | **Create** — `SliverAppBar` with banner, shop info section, verified badge, product `SliverGrid` via `shopProductsProvider(id)` |
| `screens/buyer_order_list_screen.dart` | `/profile/orders` | **Create** — list of buyer orders from `buyerOrdersProvider` |
| `screens/buyer_order_detail_screen.dart` | `/profile/orders/:id` | **Create** — status stepper, line items, tracking section with `url_launcher` "Track Package" button |
| `screens/seller_dashboard_screen.dart` | `/seller` | **Create** — shop overview, stats, Stripe onboarding button, nav to products/orders. `AppLifecycleState.resumed` → `ref.invalidate(myShopProvider)` |
| `screens/shop_setup_screen.dart` | `/seller/setup` | **Create** — create/edit shop form (name, description, logo URL, banner URL) |
| `screens/vendor_product_list_screen.dart` | `/seller/products` | **Create** — list from `vendorProductsProvider`, FAB to add, delete confirmation dialog |
| `screens/add_edit_product_screen.dart` | `/seller/products/new`, `/seller/products/:id/edit` | **Create** — create/edit product form with image URL fields, inventory count, category dropdown |
| `screens/vendor_order_queue_screen.dart` | `/seller/orders` | **Create** — orders from `vendorOrdersProvider`, status filter chips |
| `screens/vendor_order_detail_screen.dart` | `/seller/orders/:id` | **Create** — order detail, status update, tracking via `AppBottomSheet` |
| `screens/cart_screen.dart` | existing | **Modify** — replace flat ListView with `itemsByShop`-grouped `_VendorGroup` widgets, per-vendor pay button, unverified shop banner |
| `screens/marketplace_screen.dart` | existing | **Modify** — add horizontal "Discover Shops" section reading `shopListProvider` |
| `screens/product_detail_screen.dart` | existing | **Modify** — update `cartProvider.notifier.add()` to pass shop context |
| `widgets/product_card.dart` | — | **Modify** — same `add()` call update |
| `features/pet_profile/.../pet_profile_screen.dart` | existing | **Modify** — add "Seller Dashboard" entry card |
| `lib/core/router.dart` | — | **Modify** — add 10 new routes (all `parentNavigatorKey: _rootNavigatorKey`) |

### pubspec.yaml

Add one package:
```yaml
url_launcher: ^6.3.1
```

---

## Phased Build Sequence

| Phase | Work |
|---|---|
| **1 — DB** | Create service admin user in Supabase Auth → apply 4 migrations → verify schema sync |
| **2 — Edge Functions** | Update `create-payment-intent`; create `stripe-onboard-vendor`; create `stripe-webhook`; set secrets; deploy; register webhook URL in Stripe Dashboard |
| **3 — Models** | `Shop`, `OrderStatus`, `LineItem`, `MarketplaceOrder`, extend `Product`, extend `CartItem`/`CartState` |
| **4 — Repositories** | `ShopRepository`, `VendorProductRepository`, extend `ProductRepository`, extend `OrderRepository` |
| **5 — Controllers** | 6 new controllers + extend `CheckoutNotifier` + `CartNotifier.clearShop` |
| **6 — Screens & Router** | 9 new screens + 5 modified + 10 new routes |

---

I recommend implementing in this exact sequence — each phase has no forward dependencies (schema before Edge Functions, models before repos, repos before controllers, controllers before screens).

