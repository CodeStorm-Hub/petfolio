# Marketplace Audit Report

**Audit Summary**: The marketplace feature conforms to feature-first design with clean presentation, domain, and data layers. Supabase queries are well-optimized using inner joins and RPCs to prevent N+1 queries, and RLS policies are consolidated to use cached subselect checks.

## Architecture & UI/UX

- **Feature-First Architecture**: The marketplace codebase under `lib/features/marketplace/` is correctly divided into:
  - `presentation/`: Houses controllers (e.g., `cart_controller.dart`, `checkout_controller.dart`), screens (e.g., `cart_screen.dart`, `product_detail_screen.dart`, `shop_storefront_screen.dart`), and widgets (`product_card.dart`, `address_sheet.dart`).
  - `domain/`: Contains services like `currency_formatter.dart`.
  - `data/`: Houses repositories (`product_repository.dart`, `order_repository.dart`) and models (`product.dart`, `marketplace_order.dart`).
- **Riverpod State Management**: Uses modern Riverpod notifiers including generated code (`wishlist_controller.g.dart`, `prescription_controller.g.dart`). Old `provider` package imports are entirely avoided.
- **Routing & Import Hygiene**: Configured cleanly in `marketplace_routes.dart`. It returns a standalone `List<RouteBase>` and relies on GoRouter paths (e.g., `/marketplace/product/:id`) to prevent circular import loops back to `router.dart`.
- **UI Constraints & Visuals**: Leverages the dedicated `PetfolioThemeExtension` and custom widgets like `TailWagLoader` and `PetfolioEmptyState` for a cohesive look.

## Supabase & Data Integration

- **N+1 Query Avoidment**: The `ProductRepository` uses Supabase inner joins: `.select('*, shops!inner(shop_name)')` to retrieve shop information in a single database roundtrip, preventing client-side loops.
- **Database Joins vs. Client Joins**: Pending checkout logic is delegated entirely to the database via the `process_checkout` RPC, avoiding multiple client-side writes and reads.
- **Row Level Security (RLS) policies**: Consolidated in `20260531100400_consolidate_rls_policies.sql` to merge overlapping policies. User security validations correctly utilize the plan-cached `(select auth.uid())` subselect to prevent severe optimizer degradation.
- **Indexing**: Covers foreign keys like `idx_shops_stripe_account`. An explicit restrictive policy exists on `inventory_reservations` to deny all direct client access, forcing interactions to occur securely through database transaction RPCs.
