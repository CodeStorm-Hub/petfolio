# Offers Audit Report

**Audit Summary**: The offers feature is designed as a presentation wrapper screen around the marketplace promo code feature. It relies on marketplace models and controllers, avoiding redundant data layers, and leverages secure database RPCs for promo verification.

## Architecture & UI/UX

- **Feature-First Architecture**: Located in `lib/features/offers/`. It has no independent `data/` or `domain/` layer. It exposes a single presentation layer consisting of `presentation/screens/offers_screen.dart`.
- **Cross-Feature Dependencies**: Import structures reveal that `OffersScreen` relies on `Promo` from `lib/features/marketplace/data/models/promo.dart` and `promoListProvider` from `lib/features/marketplace/presentation/controllers/promo_controller.dart`.
- **Riverpod State Management**: Integrates with the global Riverpod state. It watches `promoListProvider`, `promoFilterProvider`, and `filteredPromosProvider` to select, filter, and render active discounts.
- **Routing & Navigation**: Defined in `offers_routes.dart` with a standalone route configuration, avoiding direct circular references to the master router file.

## Supabase & Data Integration

- **Shared Database Schema**: The offers screen operates entirely on the `promos` table defined in the marketplace schema. No separate `offers` table exists in Supabase.
- **Secure Processing**: Validating and applying promo codes is performed server-side inside the `process_checkout` transaction RPC (under marketplace). This prevents malicious clients from overriding checkout totals or applying expired codes.
- **RLS & Optimization**: RLS policies for promotional data are inherited from the marketplace table configuration, where they leverage proper permissions.
