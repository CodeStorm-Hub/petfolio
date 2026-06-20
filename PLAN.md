# Marketplace Module — UX Audit, Backend Mapping Check, De-dup, Back-Gesture Pass

## Context
The user (acting as Customer/Buyer) wants a full health check of the Marketplace module: UX issues, UI<->Supabase mismatches, duplicated code, and consistent native back-gesture support across all marketplace screens. Three Explore agents read every file under `lib/features/marketplace/` (screens, widgets, controllers, repositories, models, routes) and cross-checked the live Supabase schema for project `petfolio` (`jqyjvhwlcqcsuwcqgcwf`). Findings below are confirmed against actual table columns, not assumed.

**Correction from research:** one agent flagged `product_repository.dart`'s `.eq('active', true)` as a schema mismatch (guessing the column was `is_active`). Verified directly against the live schema (`list_tables` verbose) — `products.active` is the real column (`boolean`, default `true`). False positive, no fix needed. The rest of the data-layer audit found zero real table/column mismatches: every repository's `.from()` table/columns match the live schema, RPC param naming (`p_buyer_id`, `p_shop_id`, etc.) is consistent, no mock data or stubbed logic anywhere. So the "backend mismatch" ask is satisfied by documenting it was verified clean — effort goes into the UX/code-quality issues instead, which is where the real problems are.

## Confirmed Issues

### A. Back-gesture / navigation (explicit user ask)
7 screens have no `PopScope` / back-gesture handling and rely only on a custom AppBar back `IconButton`:
- presentation/screens/product_detail_screen.dart
- presentation/screens/wishlist_screen.dart
- presentation/screens/shipment_tracking_screen.dart
- presentation/screens/prescription_upload_screen.dart
- presentation/screens/customer/buyer_order_list_screen.dart
- presentation/screens/customer/buyer_order_detail_screen.dart
- presentation/screens/customer/shop_storefront_screen.dart

### B. UI/UX inconsistencies
- 4 screens (wishlist, shipment tracking, buyer order list, buyer order detail) show raw/unstyled error text with no retry, while marketplace_screen.dart already has a correct styled error+retry pattern.
- Inconsistent empty states across screens (_NoResultsState, _EmptyWishlist, ad-hoc text) — no shared component.
- Several icon back-buttons are 40x40/44x44, below the 48x48 minimum touch target.
- PrescriptionUploadScreen and BuyerOrderDetailScreen have no "continue shopping / back to shop" CTA.
- Hardcoded Colors.xxx bypassing the theme extension in places (dark-mode risk).

### C. Duplicated code
- A private back-button widget is reimplemented independently in 5+ screens (marketplace_screen, cart_screen, product_detail_screen, wishlist_screen, order screens).
- Currency formatting `'$${(cents / 100).toStringAsFixed(2)}'` duplicated across 4+ screens/widgets.
- checkout_controller.dart: 3 checkout methods (startCheckoutForShop, startCodCheckoutForShop, startSslcommerzCheckoutForShop) repeat near-identical try/catch error-handling blocks.
- 3 list controllers (buyer_orders_controller.dart, shop_list_controller.dart, shop_products_controller.dart) each hand-roll an identical refresh() pattern.

### D. Routes / orphans
None — all 13 screens have matching GoRoutes or are reachable via modal/shell; no orphaned screens, no missing route params.

## Implementation Plan

### Phase 1 — Shared building blocks
In lib/features/marketplace/presentation/widgets/:
1. marketplace_back_button.dart — single MarketplaceBackButton widget (48x48 tap target, themed, context.pop() with fallback to context.go() if !context.canPop()). Replaces all duplicated back-button implementations.
2. marketplace_state_views.dart — MarketplaceErrorView (styled message + Retry button via onRetry callback) and MarketplaceEmptyView (icon + message + optional CTA). Compose on top of existing lib/core/widgets/ (app_snack_bar.dart, primary_pill_button.dart) rather than re-styling from scratch.

New currency formatter (path matching domain/services convention from flutter-architecture.md):
3. lib/features/marketplace/domain/services/currency_formatter.dart — formatCents(int cents, {String currency}) helper.

### Phase 2 — Back-gesture consistency
For each of the 7 screens in section A: wrap the screen body in PopScope (canPop:true for simple cases; canPop:false + onPopInvokedWithResult only where there's real unsaved state, e.g. mid-upload in PrescriptionUploadScreen) and swap the local back-icon implementation for MarketplaceBackButton, so hardware/gesture back and the visible button always agree. Spot-check the screens not flagged (marketplace_screen, cart_screen, checkout, order_confirmation) and only touch them if testing shows a real problem.

### Phase 3 — UX consistency fixes
- Swap per-screen error widgets for MarketplaceErrorView (wishlist, shipment tracking, buyer order list, buyer order detail) — adds retry for free.
- Swap empty states for MarketplaceEmptyView (marketplace_screen, wishlist_screen, buyer_order_list_screen).
- Add "Continue shopping / Back to shop" CTA to PrescriptionUploadScreen and BuyerOrderDetailScreen (via context.go to the relevant marketplace/shop route already in marketplace_routes.dart).
- Replace flagged hardcoded Colors.xxx with Theme.of(context)/AppColors/PetfolioThemeExtension.
- Bump sub-48x48 icon buttons to 48x48 (MarketplaceBackButton sets the standard).

### Phase 4 — De-duplication in controllers
- checkout_controller.dart: extract one private error-handling helper used by all 3 checkout methods instead of 3 copies of the same catch blocks.
- buyer_orders_controller.dart, shop_list_controller.dart, shop_products_controller.dart: factor the repeated refresh() body into one shared helper (keep each controller's generated provider boilerplate untouched — behavior-neutral cleanup only).

### Phase 5 — Verification
- flutter analyze (must stay clean per CLAUDE.md).
- flutter test.
- Manually trace: Marketplace -> Shop -> Product detail -> Add to cart -> Cart -> Checkout -> Order confirmation -> Buyer order list -> Buyer order detail -> Shipment tracking, plus Wishlist and Prescription-upload side paths — confirm back gesture matches the back button at every step, and error/empty states render the new shared widgets.
- No backend/schema changes in this pass (data layer already verified correctly mapped) — no migration step needed.

## Files Touched (representative)
- New: lib/features/marketplace/presentation/widgets/marketplace_back_button.dart, marketplace_state_views.dart
- New: lib/features/marketplace/domain/services/currency_formatter.dart
- Edited: the 7 screens in section A (PopScope + back button swap)
- Edited: wishlist_screen.dart, shipment_tracking_screen.dart, buyer_order_list_screen.dart, buyer_order_detail_screen.dart, prescription_upload_screen.dart (error/empty states + CTAs)
- Edited: checkout_controller.dart, buyer_orders_controller.dart, shop_list_controller.dart, shop_products_controller.dart (de-dup)
- No changes to repositories/models — backend mapping already verified correct.