Reading all docs and images in parallel with an online research sweep.

Now let me visualize the key Pathao screenshots and do codebase exploration + online research in parallel.

Now let me do a focused codebase scan of the key feature directories.

Now let me do a quick online search for the latest Flutter M3 Expressive design patterns.

Here is the complete, prioritized gap analysis:

---

## Petfolio Gap Analysis — Full Findings

### P0 — Critical UX Gaps (blocking flows)

**1. Address Management — Missing entire feature**
- `lib/features/marketplace/presentation/screens/address_screen.dart` does not exist
- Cart `_DeliverToCard` shows a snackbar placeholder instead of a real address selector
- Pathao pattern (`19_address_selection_screen.png`, `21_add_address_sheet.png`): bottom sheet with full address text field → City/Zone/Area breadcrumb dropdown → label tiles (Home/Work/Campus/Other) → "Set As Default" toggle → "Confirm Address" `FilledButton`
- Supabase `user_addresses` table + Riverpod provider needed before this can be wired

**2. Receipt Breakdown in Checkout — Missing**
- Pathao `35_checkout_receipt_details.png` shows a "Receipt" card: **Total item price (N Items) / Store Discount / Subtotal / Delivery Charge / Total** — each line itemized
- Current `cart_screen.dart` `_SumRow` only shows a flat subtotal; no delivery charge line, no item count label

---

### P1 — High-Impact UX Gaps (affects key journeys)

**3. Shop Intro / Onboarding Screen — Missing**
- `lib/features/marketplace/presentation/screens/shop_intro_screen.dart` does not exist
- Pathao `13_shop_intro_screen.png`: illustration + "Introducing Pathao Shop" + 3 value props (Authentic Products / Pay Conveniently / Track Your Order) + "Let's explore" `FilledButton`
- Should trigger on first visit to `/marketplace` via `shared_preferences` flag

**4. Offers/Promos Screen — Missing feature**
- `lib/features/offers/` directory does not exist
- Pathao `03_offers_screen.png`: "Offers" top title, **"Available Promos" (pill) + "Point Deals"** tab pair, filter chips (All / Food / Bike), card list per promo with code + description + "Valid till" date + "Add promo" `TextButton`
- Marketplace currently has no dedicated promos browsing surface

**5. Settings / Profile Screen — Missing feature**
- `lib/features/settings/` does not exist — no settings screen at all
- Pathao `06_profile_screen.png` + `06_profile_screen_bottom.png` pattern:
  - Gold loyalty tier card: avatar + phone + rating, XP progress bar to next tier, "Point deals / Partner benefits" chevron links
  - Grouped sections: **ACCOUNT** (Saved Address), **OFFERS** (Promos, Refer & Get Discounts), **SETTINGS** (Language, Permissions), **HELP & LEGAL** (Safety `NEW` badge, Emergency Support, Help, Support Requests, Policies), **MORE** (What's New dot badge)
- Users cannot manage account, addresses, or preferences from anywhere in the app

**6. Activity Screen Not Reachable from Home**
- `/activity` route exists but no `_QuickActionsRow` button in `hub_home_screen.dart` links to it
- Pathao `04_activity_screen.png`: Activity is a first-class bottom nav item
- Users can only reach Activity via direct deep link — no in-app path

**7. Care Screen Filter Chips — Missing**
- `care_screen.dart` has no filter chips (All | Medical | Nutrition | Grooming | Walk)
- All care tasks render in a flat undifferentiated list; no way to focus on one pillar

---

### P2 — Medium-Impact UX Gaps (polish & completeness)

**8. Marketplace "Show All" Categories Page — Missing**
- `marketplace_screen.dart` has category rows but no dedicated `/marketplace/categories` page
- Pathao `13_shop_screen.png`: "Show All" chevron link triggers full categories grid

**9. "Products You'll Love" Section on Marketplace Main Screen — Missing**
- Pathao `13_shop_screen_bottom.png`: horizontal product cards with percent-off badges under "Shops you'll love" and "Products you'll love" sections
- Current `marketplace_screen.dart` only has shop/vendor listing, no product-level discovery surface

**10. Buyer Order Actions — Return / Request Again / Rate**
- Pathao `04_activity_screen_bottom.png`: each activity card has an action row: **Return | Request Again | RATE NOW**
- `activity_screen.dart` `_ActivityCard` has a generic action row via `TextButton` but does not implement these three specific CTAs for orders

**11. Promotions Tab Always Empty**
- `notifications_screen.dart` Promotions tab filters `!{'like','comment','follow'}` — always zero items
- `AppNotification.type` only ever receives `'like'|'comment'|'follow'` from Supabase
- Backend needs a `'promo'` notification type or the tab needs a separate promotions feed query

**12. Home Hero — No Loyalty Points / Wallet Balance Chip**
- Pathao `01_home_screen_top.png`: "152 Points" pill + "Pathao Pay ৳0" balance banner in hero area
- `hub_home_screen.dart` `_WaveHeroSection` shows streak + tasks but no XP/points metric visible to the user at a glance

---

### P3 — Low-Impact / Polish Gaps

**13. Missing `smooth_page_indicator` for carousels**
- Product detail carousel (`_ProductHeroCarousel`) and marketplace hero carousel both use manual dot indicators built with `Container` + `AnimationController`
- `smooth_page_indicator` (pub.dev) provides `WormEffect`, `JumpingDotEffect`, `ScaleEffect` — animated, accessible, zero-boilerplate

**14. Missing `shimmer` for skeleton loaders**
- `lib/core/widgets/skeleton_loader.dart` exists but uses plain grey `Container`s — no shimmer gradient sweep
- `shimmer` package (pub.dev) provides `Shimmer.fromColors()` — the standard expectation for loading states in 2025 apps

**15. Missing `flutter_animate` for stagger-in effects**
- No package for staggered list-item animations anywhere in the codebase (`flutter_animate` not in `pubspec.yaml`)
- Pathao and all M3E reference apps use stagger-in (each card fades + slides in 80ms apart) on list reveals
- `flutter_animate` provides `.animate().fadeIn().slideY()` with chainable delays; minimal boilerplate

**16. Missing `lottie` for empty state illustrations**
- Pathao `05_inbox_screen.png`: animated 3D mailbox illustration for empty inbox
- Petfolio `PetfolioEmptyState` uses an `Icon` — flat, non-animated
- `lottie` package enables JSON-driven animations from LottieFiles without bundling video

**17. `RoundedSuperellipseBorder` (M3 Expressive squircle shape) — Not used**
- M3 Expressive spec ([Building with M3 Expressive](https://m3.material.io/blog/building-with-m3-expressive)) mandates superellipse ("squircle") corners on cards, sheets, FABs
- Flutter 3.27+ ships `RoundedSuperellipseBorder` natively; Petfolio uses `RoundedRectangleBorder` everywhere
- `PfCard`, `_SectionCard` in cart, `_ActivityCard` — all should migrate to `RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(20))`

**18. No Page Transition Spring Animations**
- `GoRouter` uses the default `MaterialPage` transition; no `ZoomPageTransitionsBuilder` or `Curves.easeOutBack` / `ElasticOutCurve`
- M3E motion spec: push transitions should use spatial springs (zoom + fade), not flat slide
- Can be set globally in `ThemeData.pageTransitionsTheme`

**19. `DynamicSchemeVariant.fidelity` Color Seeding — Not configured**
- `app_theme.dart` uses a static `ColorScheme.fromSeed()`; Petfolio doesn't use `DynamicSchemeVariant.fidelity` or `.tonalSpot`
- M3E recommends `DynamicSchemeVariant.fidelity` for richer, more saturated color mapping that preserves brand hues under dark mode

**20. `m3e_buttons` / `m3e_expandable` — Not adopted**
- Community packages ([m3e_buttons](https://pub.dev/packages/m3e_buttons), [m3e_expandable](https://pub.dev/packages/m3e_expandable)) provide spring-physics button press feedback and expand/collapse animations per the M3E spec
- Current buttons use plain `FilledButton` with no tactile spring radius/shape animation on press

---

### Summary Table

| # | Area | Gap | Priority |
|---|------|-----|----------|
| 1 | Marketplace | Address management screen (entire feature missing) | P0 |
| 2 | Marketplace | Receipt breakdown (delivery charge, item count, store discount) | P0 |
| 3 | Marketplace | Shop intro/onboarding screen on first visit | P1 |
| 4 | Marketplace | Offers/Promos screen (tab + filter chips + promo cards) | P1 |
| 5 | Global | Settings/Profile screen (account, saved address, promos, refer) | P1 |
| 6 | Navigation | Activity not reachable from Home quick actions | P1 |
| 7 | Care | Filter chips (All/Medical/Nutrition/Grooming/Walk) | P1 |
| 8 | Marketplace | "Show All" categories page | P2 |
| 9 | Marketplace | "Products you'll love" discovery section | P2 |
| 10 | Activity | Order action row (Return / Request Again / Rate) | P2 |
| 11 | Notifications | Promotions tab has no data source | P2 |
| 12 | Home | Loyalty points / XP chip in hero section | P2 |
| 13 | Global | `smooth_page_indicator` for carousels | P3 |
| 14 | Global | `shimmer` gradient for skeleton loaders | P3 |
| 15 | Global | `flutter_animate` for stagger-in list animations | P3 |
| 16 | Global | `lottie` for animated empty state illustrations | P3 |
| 17 | Global (M3E) | `RoundedSuperellipseBorder` squircle shape on cards/sheets | P3 |
| 18 | Global (M3E) | Spring page transition animations | P3 |
| 19 | Global (M3E) | `DynamicSchemeVariant.fidelity` color seeding | P3 |
| 20 | Global (M3E) | `m3e_buttons`/`m3e_expandable` tactile press feedback | P3 |

---

**Phase complete — please run `/remember` to save tokens before proceeding to the next phase.**

Which gap(s) would you like to implement first?

Sources:
- [Start building with Material 3 Expressive - Material Design](https://m3.material.io/blog/building-with-m3-expressive)
- [smooth_page_indicator | Flutter package](https://pub.dev/packages/smooth_page_indicator)
- [m3e_buttons | Flutter package](https://pub.dev/packages/m3e_buttons)
- [m3e_expandable | Flutter package](https://pub.dev/packages/m3e_expandable)
- [Shimmer Loading Effects in Flutter](https://blog.openreplay.com/shimmer-loading-effects-in-flutter/)