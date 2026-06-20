## Marketplace Files (`lib/features/marketplace/`)

**Models** (`data/models/`)
- [shop.dart](lib/features/marketplace/data/models/shop.dart) — vendor/shop entity
- [product.dart](lib/features/marketplace/data/models/product.dart), [product_variant.dart](lib/features/marketplace/data/models/product_variant.dart)
- [product_review.dart](lib/features/marketplace/data/models/product_review.dart)
- [marketplace_order.dart](lib/features/marketplace/data/models/marketplace_order.dart) (incl. `LineItem`)
- [cart_item.dart](lib/features/marketplace/data/models/cart_item.dart)
- [wishlist_item.dart](lib/features/marketplace/data/models/wishlist_item.dart)
- [user_address.dart](lib/features/marketplace/data/models/user_address.dart)
- [promo.dart](lib/features/marketplace/data/models/promo.dart)
- [prescription.dart](lib/features/marketplace/data/models/prescription.dart)
- [shipment.dart](lib/features/marketplace/data/models/shipment.dart)
- [vendor_ledger.dart](lib/features/marketplace/data/models/vendor_ledger.dart)
- (`.freezed.dart` / `.g.dart` generated counterparts for each)

**Repositories** (`data/repositories/`) — only layer touching Supabase
- [shop_repository.dart](lib/features/marketplace/data/repositories/shop_repository.dart)
- [product_repository.dart](lib/features/marketplace/data/repositories/product_repository.dart)
- [product_review_repository.dart](lib/features/marketplace/data/repositories/product_review_repository.dart)
- [order_repository.dart](lib/features/marketplace/data/repositories/order_repository.dart)
- [address_repository.dart](lib/features/marketplace/data/repositories/address_repository.dart)
- [promo_repository.dart](lib/features/marketplace/data/repositories/promo_repository.dart)
- [prescription_repository.dart](lib/features/marketplace/data/repositories/prescription_repository.dart)
- [shipment_repository.dart](lib/features/marketplace/data/repositories/shipment_repository.dart)
- [wishlist_repository.dart](lib/features/marketplace/data/repositories/wishlist_repository.dart)

**Controllers** (`presentation/controllers/`, Riverpod)
- [shop_list_controller.dart](lib/features/marketplace/presentation/controllers/shop_list_controller.dart), [shop_products_controller.dart](lib/features/marketplace/presentation/controllers/shop_products_controller.dart)
- [product_list_controller.dart](lib/features/marketplace/presentation/controllers/product_list_controller.dart), [product_variant_controller.dart](lib/features/marketplace/presentation/controllers/product_variant_controller.dart)
- [product_reviews_controller.dart](lib/features/marketplace/presentation/controllers/product_reviews_controller.dart)
- [cart_controller.dart](lib/features/marketplace/presentation/controllers/cart_controller.dart)
- [checkout_controller.dart](lib/features/marketplace/presentation/controllers/checkout_controller.dart)
- [buyer_orders_controller.dart](lib/features/marketplace/presentation/controllers/buyer_orders_controller.dart)
- [address_controller.dart](lib/features/marketplace/presentation/controllers/address_controller.dart)
- [promo_controller.dart](lib/features/marketplace/presentation/controllers/promo_controller.dart)
- [prescription_controller.dart](lib/features/marketplace/presentation/controllers/prescription_controller.dart)
- [shipment_controller.dart](lib/features/marketplace/presentation/controllers/shipment_controller.dart)
- [wishlist_controller.dart](lib/features/marketplace/presentation/controllers/wishlist_controller.dart)

**Screens** (`presentation/screens/`)
- [marketplace_screen.dart](lib/features/marketplace/presentation/screens/marketplace_screen.dart), [marketplace_categories_screen.dart](lib/features/marketplace/presentation/screens/marketplace_categories_screen.dart)
- [shop_intro_screen.dart](lib/features/marketplace/presentation/screens/shop_intro_screen.dart), [customer/shop_storefront_screen.dart](lib/features/marketplace/presentation/screens/customer/shop_storefront_screen.dart)
- [product_detail_screen.dart](lib/features/marketplace/presentation/screens/product_detail_screen.dart)
- [cart_screen.dart](lib/features/marketplace/presentation/screens/cart_screen.dart)
- [order_confirmation_screen.dart](lib/features/marketplace/presentation/screens/order_confirmation_screen.dart)
- [customer/buyer_order_list_screen.dart](lib/features/marketplace/presentation/screens/customer/buyer_order_list_screen.dart), [customer/buyer_order_detail_screen.dart](lib/features/marketplace/presentation/screens/customer/buyer_order_detail_screen.dart)
- [shipment_tracking_screen.dart](lib/features/marketplace/presentation/screens/shipment_tracking_screen.dart)
- [wishlist_screen.dart](lib/features/marketplace/presentation/screens/wishlist_screen.dart)
- [prescription_upload_screen.dart](lib/features/marketplace/presentation/screens/prescription_upload_screen.dart)
- [vendor_web_redirect_screen.dart](lib/features/marketplace/presentation/screens/vendor_web_redirect_screen.dart)

**Widgets** (`presentation/widgets/`)
- [product_card.dart](lib/features/marketplace/presentation/widgets/product_card.dart), [product_glyph.dart](lib/features/marketplace/presentation/widgets/product_glyph.dart)
- [cart_line_item.dart](lib/features/marketplace/presentation/widgets/cart_line_item.dart)
- [address_sheet.dart](lib/features/marketplace/presentation/widgets/address_sheet.dart)
- [subscription_toggle.dart](lib/features/marketplace/presentation/widgets/subscription_toggle.dart)
- [product_reviews_section.dart](lib/features/marketplace/presentation/widgets/product_reviews_section.dart), [star_rating_widget.dart](lib/features/marketplace/presentation/widgets/star_rating_widget.dart)
- [web_checkout_resume_listener.dart](lib/features/marketplace/presentation/widgets/web_checkout_resume_listener.dart) (Stripe web checkout return handling)

**Wiring**
- [marketplace_routes.dart](lib/features/marketplace/marketplace_routes.dart) — GoRouter routes for the feature
- [index.dart](lib/features/marketplace/index.dart) — barrel export

---

## Related Supabase Tables (project `petfolio`, `jqyjvhwlcqcsuwcqgcwf`)

| Table | Rows | Purpose |
|---|---|---|
| `shops` | 7 | vendor/shop profiles (owner_id, kyc_status, stripe_connect_account_id, payout fields) |
| `products` | 14 | catalog items per shop |
| `product_variants` | 0 | SKU/variant-level stock & price |
| `product_reviews` | 1 | buyer ratings/reviews per product |
| `marketplace_orders` | 43 | orders (buyer_id, seller_id, shop_id, line_items, payment/status, Stripe & SSLCommerz fields) |
| `inventory_reservations` | 28 | stock holds tied to orders/products/variants during checkout |
| `wishlists` / `wishlist_items` | 2 / 0 | saved-for-later items |
| `user_addresses` | 2 | shipping addresses |
| `promos` | 7 | discount codes (per-shop) |
| `prescriptions` | 0 | Rx uploads gating restricted product orders |
| `shipments` | 4 | tracking/courier info per order |
| `vendor_ledgers` | 17 | seller earnings/payout ledger entries |
| `payout_requests` | 0 | vendor payout requests |
| `disputes` | 0 | order disputes |
| `shop_deletion_requests` | 2 | vendor shop deletion workflow |
| `vendor_announcements` | 0 | platform → vendor announcements |
| `platform_settings` | 0 | global marketplace config (fees, etc.) |

All tables have RLS enabled. Foreign keys observed (e.g. `marketplace_orders_buyer_id_fkey`, `marketplace_orders_shop_id_fkey`, `products_shop_id_fkey`, `inventory_reservations_product_id_fkey`/`_variant_id_fkey`/`_order_id_fkey`, `vendor_ledgers_shop_id_fkey`/`_order_id_fkey`, `prescriptions_order_id_fkey`, `shipments_order_id_fkey`, `wishlist_items_product_id_fkey`/`_variant_id_fkey`) confirm the relational chain: `shops → products → product_variants`, and `marketplace_orders → inventory_reservations / shipments / prescriptions / vendor_ledgers`.