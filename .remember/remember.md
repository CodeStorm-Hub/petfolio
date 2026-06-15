# Handoff

## State
Phases 1–4 complete. Phase 4 (Commerce) fully landed: product_variants, wishlists, prescriptions (private bucket), shipments, variant picker on product detail, wishlist screen, prescription upload screen, shipment tracking screen, 3 new routes.
`flutter analyze` clean (1 pre-existing `anonKey` info lint). 112 tests pass; 5 pre-existing failures unchanged.

## Next
1. **Phase 5 — Payments**: bKash/Nagad/COD via SSLCommerz (per `research-implementation-plan.md`).
2. Phase 6 — Security hardening.

## Context
- DB migrations applied directly to Supabase project `jqyjvhwlcqcsuwcqgcwf` (no branch; user-approved).
- `AppSnackBar.show(String message)` — positional only, no context param.
- `state.asData?.value ?? []` — not `.valueOrNull`. Family notifiers: `late String _field` in `build()`.
- `ProductCard` requires `onTap` (named, required param) — don't pass it without one.
- `(_, _)` for two-discard lambda params (Dart 3.x); `__` triggers `unnecessary_underscores` lint.
