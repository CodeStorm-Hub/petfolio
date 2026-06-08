# Handoff

## State
Branch: `ui-material-3-expresive`. Phase 1 (Hub Home Screen) and Phase 2 (Marketplace Catalog) complete. `flutter analyze` — no issues.
- `lib/features/home/presentation/screens/hub_home_screen.dart` — Pathao-style asymmetric bento grid (Care 2× tall, Social+Match stacked, Market+Vet row, All footer). Stack-based tile layout (title top-left, emoji bottom-right). Scroll-driven glass header via `homeScrollProgressProvider` in `lib/core/providers/shell_scroll_provider.dart`.
- `lib/features/marketplace/presentation/screens/marketplace_screen.dart` — `_HeroCarousel` (3-slide PageView, auto-scroll Timer), M3 Expressive white product cards, `🔥 HOT` badge for rating ≥ 4.5.

## Next
1. **Phase 3** — Product Details Dual CTA: `lib/features/marketplace/presentation/screens/product_detail_screen.dart` — sticky bottom bar with "Add to Cart" + "Buy Now" side-by-side CTAs.
2. **Phase 4** — Checkout Stacked Cards: `lib/features/marketplace/presentation/screens/cart_screen.dart`.
3. **Phase 5** — Universal Filter Chips (marketplace + care screens).

## Context
- Riverpod 3.x — `StateProvider` removed; use `Notifier` + `NotifierProvider` (see `shell_scroll_provider.dart` for pattern).
- `AppColors.tangerineSoftD` uncertain — use `AppColors.tangerine.withAlpha(35)` for dark mode tints on tangerine.
- `_BentoTile` uses `Stack` not `Row` for title/emoji — avoids wrapping on narrow half-width tiles.
