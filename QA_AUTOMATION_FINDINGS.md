# QA Automation Findings — Android-MCP Sweep

Date: 2026-06-24
Method: Black-box UI automation against a live debug build on an Android emulator, driven via android-mcp (taps, swipes, type, system back/home). No source-code changes were made as part of this pass — this is an issue-identification report only.

## Scope covered

Home, Care (Dashboard/Nutrition/Health/Walk/Vets), PawsFeed (Feed/Stories/Communities/My Pet, Search, Direct messages), Match (Discover/Messages/Liked), Vet Hub (Clinics → detail → service → date/time → booking confirmation modal), Alerts (Updates/Promotions), Activity (All/Orders/Appointments), Me/Account (Saved Addresses, Wishlist, Saved Posts, Dark Mode), Marketplace (Shop/Browse/Cart tabs, top app-bar cart icon, Browse Categories sheet, onboarding sheet), "All Features" sheet from Home.

---

## Critical bugs

### 1. Marketplace cart is completely unreachable
Both the bottom-tab **Cart** button and the top app-bar cart icon (shopping bag) open the **Browse Categories** sheet instead of any cart screen. There is no working path to view the cart from the Marketplace UI in this build. Reproduced via both entry points on a fresh app session.

**Files:**
- [`lib/core/navigation/shell_destinations.dart:81-91`](lib/core/navigation/shell_destinations.dart) — `marketplaceDestinations` defines Shop (`/marketplace`), Browse (`/marketplace/categories`), Cart (`/marketplace/cart`).
- [`lib/features/marketplace/marketplace_routes.dart:18-26,38-43`](lib/features/marketplace/marketplace_routes.dart) — `/marketplace/categories` and `/marketplace/cart` are registered with `parentNavigatorKey: rootKey`, i.e. as **root-navigator routes outside the shell's marketplace `StatefulShellBranch`**.
- [`lib/core/navigation/app_shell_routes.dart:140-149`](lib/core/navigation/app_shell_routes.dart) — only `/marketplace` itself is declared inside the branch; the mismatch with the root-pushed routes above likely desyncs the shell's active-tab state.
- [`lib/core/widgets/app_shell.dart:153-161,741-792`](lib/core/widgets/app_shell.dart) — `_FloatingNav`/tab-bar wiring that reads/sets the active tab index.
- [`lib/core/widgets/app_shell.dart:402-421`](lib/core/widgets/app_shell.dart) — the app-bar cart icon (`market_action_cart`) itself correctly calls `showModalBottomSheet(... CartDrawer())`, so this onTap is correct in isolation; the bug is in the tab/shell-routing layer above, not here.
- [`lib/features/marketplace/presentation/screens/marketplace_screen.dart:149,310-328`](lib/features/marketplace/presentation/screens/marketplace_screen.dart) — `_MarketHeader(onCart: _openCart)` passes a callback that `_MarketHeader.build()` never wires to a button — a dead callback, separate from the routing issue above.

### 2. "Browse Categories" sheet is a dead end with no in-app exit
Category cards (Food, Treats, Toys, Beds, Apparel, Grooming, Gear, Health) only toggle a single-select checkmark — tapping a card (or its chevron) does not navigate to a product list. There is no Apply/Done/Continue button anywhere on the sheet. The sheet also cannot be dismissed by:
- tapping outside the sheet (scrim tap did nothing)
- swiping down on the sheet or its handle
- the system back gesture acting as a modal dismiss (see #3)

**Files:**
- [`lib/features/marketplace/presentation/screens/marketplace_categories_screen.dart`](lib/features/marketplace/presentation/screens/marketplace_categories_screen.dart) — class `MarketplaceCategoriesSheet` (line 32).
  - `show()` (lines 35-43): `showModalBottomSheet<void>(isScrollControlled: true, useSafeArea: true, ...)`.
  - `_CategoryTile.onTap` (lines 105-110): calls `ref.read(selectedCategoryProvider.notifier).select(...)` then immediately `context.pop()` — every tap both toggles selection AND closes the sheet, with no Apply/Done button rendered anywhere in the widget tree.

### 3. Back button from the trapped sheet exits the entire app
Pressing system back while the Browse Categories sheet is open does not close the modal or return to the previous screen — it exits the whole app to the Android launcher. Reproduced 3 times. Because the Flutter engine process stays alive in the background, relaunching the app icon resumes directly into the same stuck sheet (no fresh navigation state). The only way out during testing was **Force Stop via Android Settings → Apps → petfolio**.

**Files:**
- [`lib/features/marketplace/presentation/screens/marketplace_categories_screen.dart:36`](lib/features/marketplace/presentation/screens/marketplace_categories_screen.dart) — `MarketplaceCategoriesSheet` is presented via plain `showModalBottomSheet` with no `PopScope`/back-handling inside the sheet itself.
- [`lib/features/marketplace/marketplace_routes.dart:19-26`](lib/features/marketplace/marketplace_routes.dart) — combined with #1, `/marketplace/categories` is reached as a **root-level pushed route** rather than a sheet over the shell, so system back can pop past the shell entirely.
- [`lib/core/widgets/app_shell.dart:74-83`](lib/core/widgets/app_shell.dart) (`didPopRoute`) and [`:95-100`](lib/core/widgets/app_shell.dart) (`_onBranchPop`) — `context.go('/home')` when popping a branch root; if categories/cart aren't recognized as shell branch roots, back navigation falls through toward app exit instead.

### 4. Marketplace "Shop"/"Browse" bottom tabs are effectively non-functional
"Browse" opens the same broken Categories trap as the cart icon (#1). Only "Shop" (the default landing tab) renders the expected screen. Net effect: only 1 of 3 bottom tabs in the Marketplace module does anything useful.

**Files:**
- [`lib/core/navigation/shell_destinations.dart:81-91`](lib/core/navigation/shell_destinations.dart) — `marketplaceDestinations` (the 3 tabs) and `marketplaceAccents`.
- [`lib/core/widgets/app_shell.dart:153-161`](lib/core/widgets/app_shell.dart) (`_FloatingNav`, mobile) and [`:172-179`](lib/core/widgets/app_shell.dart) (`_WideNavRail`, wide layout) — both call `onSelect: (i) => context.go(dests[i].path)`; per-tab tap target in `_NavTab`/`_FloatingNav` at lines 742-792.

---

## Other confirmed bugs

### 5. Activity module completely broken
The Activity screen — reachable via bottom-nav "Activity" and via Me → "My Orders & Activity" — immediately shows **"Failed to load activity"** with a Retry button. Reproducible across all three sub-tabs (All, Orders, Appointments) and persists after tapping Retry.

**Files:**
- [`lib/features/activity/presentation/screens/activity_screen.dart:36-42`](lib/features/activity/presentation/screens/activity_screen.dart) — `hasError = ordersAsync.hasError || appointmentsAsync.hasError`; a boolean OR across both providers means either one failing triggers the error state for all three filter tabs, since they share one error flag.
- [`lib/features/activity/presentation/screens/activity_screen.dart:123-153`](lib/features/activity/presentation/screens/activity_screen.dart) — error UI + Retry button (140-144) only calls `ref.invalidate(buyerOrdersProvider)` / `ref.invalidate(appointmentControllerProvider)`; won't help if the underlying call fails persistently rather than transiently.
- [`lib/features/marketplace/presentation/controllers/buyer_orders_controller.dart:12-25`](lib/features/marketplace/presentation/controllers/buyer_orders_controller.dart) — `buyerOrdersProvider` → `OrderRepository.fetchBuyerOrders()`.
- [`lib/features/appointments/presentation/controllers/appointment_controller.dart:8`](lib/features/appointments/presentation/controllers/appointment_controller.dart) — `appointmentControllerProvider`. Recommend checking these repositories'/RPC calls and Supabase RLS policies for the actual failure.

### 6. Back-navigation skips a screen after the Activity failure path
When Activity is reached via Me → "My Orders & Activity", pressing back lands on **Home**, skipping the Me screen that was actually the previous route. Confirmed this is not generic back-stack behavior — Me → Saved Addresses → back correctly returns to Me in a separate test. The skip is specific to the path through the broken Activity screen.

**Files:**
- [`lib/features/profile/presentation/screens/account_screen.dart:56-60`](lib/features/profile/presentation/screens/account_screen.dart) — "My Orders & Activity" tile calls `onTap: () => context.go('/home/activity')`.
- [`lib/core/navigation/app_shell_routes.dart:43-47`](lib/core/navigation/app_shell_routes.dart) — `/home/activity` is declared as a **child route of `/home`** inside the global `StatefulShellBranch`, not a child of `/home/me`.
- [`lib/features/activity/presentation/screens/activity_screen.dart:67-74`](lib/features/activity/presentation/screens/activity_screen.dart) — back button calls `context.pop()`, which pops within the `/home` branch stack back to `/home` rather than to `/home/me`, since Activity was never pushed on top of Me — it's a sibling route under `/home`.

### 7. Expired promotion still displayed as active
The "TOYS10" 10%-off coupon in Alerts → Promotions shows "Valid till Jun 22, 2026" while the system date is 2026-06-24 (2 days past expiry), yet it appears in the active promo list with the same "Copy code" affordance as valid promos — no expired badge or greying. Flagged from display-layer evidence only; whether the code is actually rejected at checkout was not verified.

**Files:**
- [`lib/features/marketplace/data/repositories/promo_repository.dart:15-22`](lib/features/marketplace/data/repositories/promo_repository.dart) — `fetchActivePromos()` filters only `.eq('is_active', true)`, with no filter on `valid_until`/expiry date at the query level.
- [`lib/features/marketplace/data/models/promo.dart:30-31`](lib/features/marketplace/data/models/promo.dart) — an `isExpired` getter exists but is never called by the repository or controller below.
- [`lib/features/marketplace/presentation/controllers/promo_controller.dart:25-36`](lib/features/marketplace/presentation/controllers/promo_controller.dart) — `filteredPromosProvider`/`PromoListNotifier.build()` — neither filters out expired promos.
- [`lib/features/social/presentation/screens/notifications_screen.dart:250-296`](lib/features/social/presentation/screens/notifications_screen.dart) — `_PromotionsTab` renders directly off `promoListProvider` with no client-side expiry filtering either.

---

## Worth a product/design-intent check (not asserted as bugs)

### 8. PawsFeed "Direct messages" routes into the Match module
The top-bar "Direct messages" icon on PawsFeed opens the Match module's Messages/Liked/Discover screen (header reads "MATCH · MESSAGES") rather than a PawsFeed-specific DM inbox. This may be an intentional unified-messaging design (DM your matched pets), so it's flagged for confirmation rather than logged as a bug.

**Files:**
- [`lib/core/widgets/app_shell.dart:382-393`](lib/core/widgets/app_shell.dart) — within the `ShellModule.social` header-actions case: `_HeaderIconBtn(icon: Icons.send_rounded, tooltip: 'Direct messages', onTap: () => context.go('/matching/inbox'))`.
- [`lib/core/navigation/app_shell_routes.dart:126-129`](lib/core/navigation/app_shell_routes.dart) — `/matching/inbox` resolves to `MatchesInboxScreen`, confirming it's the Match module's inbox; no PawsFeed-specific DM route currently exists in the routes file.

---

## Confirmed working correctly

- **Care**: Vets sub-tab empty states, "New" appointment button. (Note: "Mark complete" on Today's Quests carousel was found unresponsive via touch in an earlier pass — overlapping card bounding boxes near the affordance are a plausible cause; not re-verified in this pass.)
- **PawsFeed**: Feed post rendering, reactions, Comments sheet (empty state + working add/send), Communities tab, hashtag search (works once the search field is explicitly tapped to focus before typing).
- **Match**: Discover empty state with mode toggle and swipe-action buttons, Liked/"Mutual Matches" grid with working Chat buttons, Messages inbox — sent and received a real test chat message end-to-end.
- **Vet Hub**: Full booking flow — clinic list → clinic detail → service selection → date picker → time-slot grid → "Book Now" → "Confirm Booking" modal (pet selector, urgency, complaint tags, photo attach, notes). Final submit was deliberately not tapped to avoid creating a real booking record.
- **Alerts**: Updates tab (notifications list, "Mark all read").
- **Me/Account**: Saved Addresses, Wishlist (empty state), Saved Posts (empty state), Dark Mode toggle — confirmed full screen re-theme via screenshot, label correctly flips to "Light Mode".
- **Walk Tracker**: Map renders correctly, Distance/Duration timer increments, "Stop Walk" correctly reverts to "Start Walk". Minor non-blocking gap: no save/summary dialog appears after stopping a walk — stats panel just freezes at the last value.
- **"All Features" sheet** (Home): Properly dismissible via a visible Close (X) button — contrast this with the Browse Categories sheet (#2/#3), which has no equivalent.

---

## Suggested priority order

1. Fix Marketplace cart/browse navigation wiring (#1, #4) — currently makes the core purchase flow unusable.
2. Fix Browse Categories sheet dismissal and add a real category → product-list action (#2, #3) — this is also an app-stability/UX trap, not just a missing feature.
3. Fix Activity data loading (#5) and the associated back-stack skip (#6).
4. Add expiry filtering/badging to Promotions (#7).
5. Confirm PawsFeed → Match DM routing intent (#8).
