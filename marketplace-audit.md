# Marketplace Module Audit

**Branch**: `accessibility-fix-salman-2`  
**Scope**: `lib/features/marketplace/` — all data, domain, presentation layers  
**Status**: Functional but has moderate reliability and UX issues; critical silent error handlers must be fixed before production payment flows are considered safe.

---

## Summary

| Category | Count | Severity | Priority |
|---|---|---|---|
| Silent `catch (_) {}` blocks | 6 | CRITICAL | P0 |
| Missing data validation | 8+ | HIGH | P1 |
| Stale cache / timing bugs | 3+ | HIGH | P1 |
| Race conditions | 4+ | HIGH | P1 |
| Missing loading/empty states | 3+ | MEDIUM | P2 |
| Accessibility gaps | Partial | MEDIUM | P2 |
| Pagination inconsistencies | 2 | LOW | P3 |
| Code duplication / magic numbers | 3+ | LOW | P3 |

---

## P0 — Critical (Silent Error Swallowing)

Six locations where exceptions are silently discarded. Each hides a production failure from logs and from the user.

### P0-1 · `order_repository.dart` (cancelOrder)
```dart
} catch (_) {}   // inventory release failure silently ignored
```
If restoring inventory stock fails after a cancel, the item remains oversold with no alert.  
**Fix**: `log('cancelOrder inventory release failed', error: e, stackTrace: s)` + rethrow or surface to caller.

### P0-2 · `checkout_controller.dart` (resumeWebCheckoutIfNeeded)
```dart
} catch (_) {}   // web checkout resumption failure silently ignored
```
A payment webhook bounce on app-resume is invisible. The user may believe they paid but the order stays `pending`.  
**Fix**: Catch typed exceptions, emit `CheckoutState.error(...)`, log.

### P0-3 · `order_confirmation_screen.dart` (payment polling)
```dart
} catch (_) {}   // payment confirmation poll silently fails
```
If `pollOrderConfirmation` throws, the spinner runs forever (no timeout feedback).  
**Fix**: Show `"Payment confirmation timed out — please check Orders"` after 45 s or on error.

### P0-4 · `cart_controller.dart` (cart JSON deserialization)
```dart
} catch (_) {}   // corrupt cart data lost silently
```
If stored cart JSON is malformed (schema migration, app update), cart clears without any user notice.  
**Fix**: Log the raw JSON + exception; optionally show "Cart reset after update" snackbar.

### P0-5 · `buyer_order_detail_screen.dart` (cancel order button)
No confirmation dialog, no loading state, and the exception path uses `catch (_) {}`.  
**Fix**: Add `AlertDialog` confirmation, `CircularProgressIndicator` during cancel, surface error.

### P0-6 · `address_controller.dart` (default address selection)
```dart
} catch (_) { return list.first; }
```
`list.first` throws `StateError` on empty list. If addresses list is empty after a sign-out race this crashes.  
**Fix**: Use `list.firstOrNull` and guard against null; log the original catch.

---

## P1 — High

### P1-1 · Missing Data Validation

| Model | Field | Problem |
|---|---|---|
| `Product` | `priceCents` | Can be negative |
| `ProductVariant` | `priceCents`, `stock` | Can be negative |
| `CartItem` | `frequencyWeeks` | Can be 0 or negative (div-by-zero risk) |
| `UserAddress` | `fullAddress`, `city`, `zone`, `area` | Can be empty strings |
| `Promo` | `discountValue` | No bounds check |
| `ProductReview` | `rating` | Should be 1–5; not enforced |
| `Prescription` | `filePath` | No validation |

**Fix**: Add `assert` guards in debug builds and throw `ValidationException` in release for boundary values.

### P1-2 · Subscription Discount Duplication

`0.88` (12% discount multiplier) appears independently in both `CartItem.lineTotalCents` and `Product.subPriceCents`. If the business rule changes, one copy will be missed.  
**Fix**: Extract to `lib/features/marketplace/data/models/pricing_constants.dart`:
```dart
const double kSubscriptionDiscountMultiplier = 0.88;
const int kSubscriptionDiscountPercent = 12;
```

### P1-3 · `Promo.isExpired` Uses `DateTime.now()`

Cached `Promo` objects computed at fetch time will have a stale `isExpired` as time passes. A promo that was valid when cached may still appear valid hours later.  
**Fix**: Compare server timestamp in `promo_repository.dart` SQL (`valid_until > NOW()`); remove the client-side `isExpired` property or recompute lazily.

### P1-4 · Payment Flow Edge Cases

| Flow | Issue |
|---|---|
| Stripe Hosted (web) | Cancel URL handled; mobile `presentPaymentSheet()` cancel is not explicitly caught |
| CoD | Assumes Edge Function response shape; no fallback on malformed response |
| SSLCommerz | Relies on IPN webhook only; no client-side timeout / fallback poll |

**Fix**: Add explicit cancel/error branches for all three payment methods; wrap Edge Function calls with schema validation.

### P1-5 · `startOnboarding()` Response Fragile

```dart
final accountLinkUrl = map['account_link_url'];
```
No null/empty check. If the Stripe Edge Function changes its response key name, `accountLinkUrl` is null and navigation silently fails.  
**Fix**: Throw a descriptive `ValidationException` if key is missing.

### P1-6 · `productListProvider` Client-Side Search

Search filtering currently re-scans all loaded products on every keystroke. For large catalogs this degrades to O(n) per character.  
**Fix**: Debounce search input (300 ms) and move filtering to a SQL `ilike` query in `product_repository.dart`.

---

## P2 — Medium

### P2-1 · Missing Loading Skeletons

| Screen | Current | Recommended |
|---|---|---|
| `MarketplaceScreen` product grid | `CircularProgressIndicator` | `Shimmer` card skeleton |
| `ShopStorefrontScreen` products | `CircularProgressIndicator` | Product card skeletons |
| `ProductDetailScreen` hero image | `CachedNetworkImage` placeholder | Shimmer while first frame loads |
| `CartScreen` | Instant render | Skeleton during cart hydration from storage |

### P2-2 · Accessibility Gaps

- Cart quantity `+` / `−` buttons have no `Semantics` label (screen readers read "button").
- `StarRatingWidget` interactive variant missing `Semantics(slider: true)` / value label.
- `ProductCard` wishlist heart icon missing semantic label ("Add to wishlist" / "Remove from wishlist").
- `SubscriptionToggle` switch lacks `Semantics` description of subscription frequency.
- Some `Icon` widgets in order detail have no `tooltip` or `Semantics`.

**Fix**: Add `Semantics(label: '...', button: true)` / `Tooltip` to all interactive elements; run Flutter accessibility inspector.

### P2-3 · Empty State Coverage

`ShopProductsController` returns an empty list with no UI feedback when a shop has no products. User sees a blank scrollable area.  
**Fix**: Check `products.isEmpty` in `ShopStorefrontScreen` and render `MarketplaceEmptyView`.

### P2-4 · Prescription Upload UX

- File picker cancellation leaves `_pickedFile` unchanged (old file stays selected).
- No file size validation — user can pick a 100 MB image.
- Upload progress not shown (just a spinner).

**Fix**:
```dart
final result = await FilePicker.platform.pickFiles(...);
if (result == null) return;    // explicit cancel guard
if (result.files.single.size > 10 * 1024 * 1024) {
  // show "File too large" snackbar
  return;
}
```

### P2-5 · Wishlist Remove Ignores Variant

`WishlistRepository.removeFromWishlist(productId)` does not pass `variantId`. If a product has multiple variants, removing one removes all.  
**Fix**: Thread `variantId` through `WishlistScreen` → `wishlist_controller.dart` → `wishlist_repository.dart` and filter on both columns.

### P2-6 · Stale Review Cache

After a user submits a review via `ProductReviewsNotifier`, only the local reviews list is updated. The aggregate `rating` / `reviewCount` on the parent product is not refreshed.  
**Fix**: After upsert, call `ref.invalidate(productListProvider)` or emit a targeted update on the product's rating summary.

### P2-7 · Order Cancel UX

`BuyerOrderDetailScreen` has no confirmation dialog before cancellation and no loading overlay. The action fires immediately on tap.  
**Fix**:
```dart
final confirmed = await showAdaptiveDialog<bool>(..., content: const Text('Cancel this order?'));
if (confirmed != true) return;
// show loading overlay
// call cancel
// handle error
```

### P2-8 · Promo Filter Persistence

`promoFilterProvider` state survives app restarts via the provider ref lifecycle. A filter set in a previous session persists unexpectedly.  
**Fix**: Reset `promoFilterProvider` in `build()` to a sensible default, or use `autoDispose`.

---

## P3 — Low

### P3-1 · Pagination Inconsistency

| Provider | Strategy |
|---|---|
| `productListProvider` | Cursor pagination (keyset) ✅ |
| `shopProductsProvider` | All-at-once ✗ |
| `productReviewsProvider` | Hard limit 50 ✗ |

**Fix**: Add cursor-based pagination to `ShopProductsController` and `ProductReviewsNotifier`.

### P3-2 · `currencyFormatter.dart` USD-Only Bug

```dart
if (currency.toLowerCase() == 'usd') return '\$${...}';
// else: return '${currency.toUpperCase()} ${...}'  ← no symbol for BDT, EUR, GBP etc.
```
BDT (Bangladeshi Taka) gets formatted as `"BDT 120.00"` instead of `"৳120"`.  
**Fix**: Use a proper currency-symbol map or the `intl` package's `NumberFormat.currency(locale:, symbol:)`.

### P3-3 · Magic Numbers / Hardcoded IDs

| Value | Locations |
|---|---|
| `0.88` (subscription discount) | `CartItem`, `Product` |
| `4` (default sub frequency weeks) | `ProductDetailScreen` |
| `'cccccccc-0000-0000-0000-cccccccccccc'` (official shop ID) | Multiple files |
| `3600` (signed URL TTL) | `prescription_repository.dart` |
| `45` (poll timeout seconds) | `order_repository.dart` |

**Fix**: Move to `lib/features/marketplace/marketplace_constants.dart`.

### P3-4 · Dead Code

`order_repository.dart` contains a `confirmOrder()` method that is a no-op:
```dart
Future<void> confirmOrder(String orderId) async {
  // nothing
}
```
Safe to delete.

### P3-5 · `_petfolioOfficialShopId` Duplication

This UUID literal appears in at least 3 files. Extract to `MarketplaceConstants.officialShopId`.

### P3-6 · Signed URL Expiry Too Short

`prescription_repository.dart` generates signed URLs with 3600 s (1 hour) TTL. Archived/old order prescriptions viewed days later will return 403.  
**Fix**: Use 7-day TTL (`604800`) or generate on-demand when user taps the prescription link.

### P3-7 · `shop_storefront_screen.dart` — No Infinite Scroll

All shop products loaded in a single query. A shop with 200+ products loads everything upfront.  
**Fix**: Add `ScrollController` + cursor pagination matching `productListProvider` pattern.

### P3-8 · `product_variant.dart` Untyped Attributes Map

```dart
final Map<String, dynamic> attributes;
```
Any key can be inserted. Typed variant attribute keys (color, size, weight) should be an enum or sealed class.

---

## File-Level Notes

### `marketplace_screen.dart`
- `_flyingItems` list never cleared on `dispose()` — accumulates on hot reload.
- `ShopIntroScreen.shouldShow()` called with `mounted` check above but no inner recheck after `await`.

### `product_detail_screen.dart`
- `_subscribe = widget.product!.subscribable` set in `initState`, but `cart.addItem()` call (line 82) passes `subscribe: false` regardless — toggle state not wired to add-to-cart.
- `_selectedVariantId` lost on screen pop; user loses choice if they navigate back and forward.

### `cart_screen.dart`
- No indication of which promo code is currently applied.
- No validation that all shops in the cart have verified payment setup before enabling checkout.

### `order_confirmation_screen.dart`
- No timeout feedback — if webhook takes > 45 s, user sees an infinite spinner.

### `prescription_upload_screen.dart`
- `_uploading` flag is local state; not synchronized with `prescriptionControllerProvider` async state.

### `wishlist_screen.dart`
- Remove uses `productId` only; variant-level wishlist entries share the same product.

---

## Recommended Fix Order

```
P0  Silent catch blocks (6 locations)           — payment integrity
P1  Data validation layer                        — data integrity
P1  Promo cache expiry fix (SQL-side)            — discount correctness
P1  Payment flow edge cases (Stripe/CoD/SSL)    — checkout reliability
P1  startOnboarding() null guard                 — vendor onboarding
P2  Skeleton loaders (3 screens)                 — perceived performance
P2  Accessibility audit pass                     — a11y compliance
P2  Wishlist variant fix                         — data correctness
P2  Cancel order dialog + loading               — UX
P2  Prescription upload guards                   — reliability
P3  Pagination for shop products + reviews       — scalability
P3  currencyFormatter BDT fix                    — i18n correctness
P3  Extract constants                            — maintainability
P3  Delete dead confirmOrder()                   — cleanup
```
