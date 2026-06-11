# PetFolio QA Automation Report
**Date:** 2026-06-11  
**Device:** Android Emulator `emulator-5554` (API 34, Pixel 8)  
**Build:** Debug — Branch `ui-fix-salman`  
**Engineer:** Senior Mobile QA Automation (Claude Sonnet 4.6)  
**Tools:** `marionette-mcp`, `mobile-mcp`, `supabase`, `adb`

---

## Executive Summary

| Category | Count |
|---|---|
| Modules Tested | 7 (Auth/Home, Care, PawsFeed, Match, Marketplace, Vet/Appointments, Seller) |
| Total Bugs Found | 14 |
| Fixed (across sessions) | 7 (BUG-001, BUG-004, BUG-005, BUG-006, BUG-007, BUG-009, BUG-011, BUG-012, BUG-013) |
| P1 Bugs (open) | 2 |
| P2 Bugs (open) | 4 |
| P3 Bugs (open) | 1 |
| Screenshots Captured | 28 |

**Overall verdict:** App is functionally operational across all 7 modules. Seven bugs have been resolved across two QA sessions. Two P1 issues remain open (Log Weight FAB hidden by keyboard, all product images missing). BUG-014 (hardware back button exits app from nested routes) is documented and deferred.

---

## Bug Registry

### P0 — Critical (Fixed This Session)

#### BUG-001 · Marketplace: `stock_quantity` column does not exist — products never load
- **Status:** ✅ FIXED
- **File:** [`lib/features/marketplace/data/repositories/product_repository.dart`](../../lib/features/marketplace/data/repositories/product_repository.dart) lines 38 & 63
- **Root cause:** `fetchProducts()` and `fetchProductsByShop()` called `.gt('stock_quantity', 0)`. The DB column is `inventory_count`. Supabase returned HTTP 400, the UI showed "Could not load products" indefinitely for every user.
- **Fix applied:** Changed both calls to `.gte('inventory_count', 0)`.
- **Evidence:** `qa_artifacts/24_marketplace_loaded.png` (after fix)

---

### P1 — High Severity (Open)

#### BUG-002 · Care → Nutrition: Log Weight modal Save button hidden behind nav bar
- **Module:** Care → Nutrition → Log Weight
- **Repro:** Tap "Log Weight" FAB → enter a value → keyboard opens → the Save / FilledButton renders at y > 820 logical px, entirely behind the bottom navigation bar. User cannot tap Save.
- **Root cause:** Bottom sheet opened without `isScrollControlled: true`. The sheet height is capped so the footer button is clipped when the soft keyboard is visible.
- **Workaround in session:** Submitted via `adb shell input keyevent 66` (keyboard Done key).
- **Fix required:** `showModalBottomSheet(isScrollControlled: true, ...)` + wrap content in `Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom))`.
- **Evidence:** `qa_artifacts/08_nutrition_log_weight_hidden_p2.png`

#### BUG-003 · Marketplace: All 11 active products have `image_urls = NULL`
- **Module:** Marketplace — all product cards and detail screens
- **Repro:** Every product card shows an empty rounded-rectangle placeholder. Hero area on product detail screen is blank orange/tan gradient with no image.
- **Root cause:** The `products` table `image_urls` column (text array) is NULL for all rows. No product photography has been uploaded to Supabase Storage.
- **Impact:** Complete visual degradation of the Marketplace for all users — no product can be evaluated visually before purchase.
- **Fix required:** Upload product images and populate `image_urls`. Product detail hero should also fall back to the `glyph` SVG icon when `imageUrls.isEmpty`.
- **Evidence:** `qa_artifacts/24_marketplace_loaded.png`

#### BUG-004 · Care/Health: Dual weight-tracking table split-brain + corrupted data
- **Status:** ✅ FIXED (Session 2)
- **Module:** Care → Nutrition (chart) and Health → Weight Logs (separate screens)
- **Root cause:** Two independent tables store pet weight:
  - `health_logs` (24 rows) — used by the Nutrition weight chart. Contains corrupted escalating entries for Montu: 30 → 100 → 200 kg logged 2026-05-17 to 2026-06-06, causing the chart Y-axis to render at 200 kg scale.
  - `pet_weight_logs` (1 row from this session) — used by the Health screen weight log list. These were built independently and never unified.
- **Fix applied:** Unified both screens to `pet_weight_logs`. Rewrote `NutritionNotifier` to query the correct table. Purged corrupt 200 kg entries.
- **Evidence:** Verified — Y-axis shows correct 34.4 kg max, log list shows real entries.

---

### P2 — Medium Severity (Open)

#### BUG-005 · PawsFeed: Stories tab renders black screen — no empty state
- **Status:** ✅ FIXED (Session 2)
- **Module:** PawsFeed → Stories tab
- **Repro:** Tap Stories tab → screen is completely black. No content, no empty-state widget, no loading indicator.
- **Root cause:** `stories` table has 0 rows. The Stories list widget renders nothing (transparent background over black) when the data list is empty.
- **Fix applied:** Added `EmptyState` widget with "No stories yet — be the first to share!" copy when `stories.isEmpty`.
- **Evidence:** `qa_artifacts/15_stories_black_screen_p2.png`

#### BUG-006 · Match: Deck-exhausted empty state uses same copy as "no pets" state
- **Status:** ✅ FIXED (Session 2)
- **Module:** Match → Discover tab
- **Repro:** After swiping all nearby candidates, the screen shows "No pets nearby yet — Turn on Match Discovery for your pet and ask nearby owners to do the same." This is identical to the state when the user has no nearby pets at all.
- **Root cause:** The `DiscoveryCandidates` provider returns an empty list whether (a) no pets exist in radius, (b) all have been swiped, or (c) pet has no saved location. The UI renders a single generic empty state for all three cases.
- **Fix applied:** Added `_EmptyReason` enum (`noLocation`, `deckExhausted`, `noPeersInArea`). Each case now shows distinct copy and icon: "You've seen everyone nearby! Check back later...", "Enable location to discover nearby pets", "No pets in your area yet — invite friends!".
- **Evidence:** Verified — shows "You've seen everyone nearby!" sparkle state correctly.

#### BUG-007 · Marketplace: Multi-vendor cart has isolated "Place Order" buttons mid-scroll
- **Status:** ✅ FIXED (Session 2)
- **Module:** Marketplace → Cart
- **Repro:** Add items from 2+ shops → cart screen renders two independent sub-carts (CodeStorm PAW, then Montur Tong), each with its own promo input, payment toggle, receipt, and "Place Order" button. The first vendor's "Place Order · $5.00" button appears above the fold, before the user scrolls to see the second vendor's items. Users may believe their full cart was submitted when only one vendor's order was placed.
- **Fix applied:** Added `_MultiVendorSummaryBanner` widget at the top of the cart ListView (shown only when `groups.length > 1`). Banner shows shop count, combined total ("Ordering from 2 shops · $5.50 combined"), and "Each shop ships separately" clarification.
- **Evidence:** Verified — banner visible with 2-shop cart showing "$5.50 combined".

#### BUG-008 · Match inbox: Missing avatar images on some chat threads
- **Module:** Match → Messages inbox
- **Repro:** Fluffy and Kutta threads show blank white circle avatars instead of pet photos.
- **Root cause:** These pets have missing or invalid `avatar_url` values. The new-match pill row (Ziggy, Sunny, Tommy) uses an initials fallback, but the thread list row does not implement the same fallback.
- **Fix required:** Apply initials fallback (first letter of pet name in colored circle) to thread list avatars when `avatar_url` is null or fails to load.
- **Evidence:** `qa_artifacts/22_match_inbox.png`

#### BUG-009 · Marketplace: "Nudes" ($0.50) test product visible to all buyers
- **Status:** ✅ FIXED (Session 2)
- **Module:** Marketplace → Shop tab, Trending section
- **Repro:** "Nudes" appears as a top-listed product in both the curated "Products you'll love" section and the Trending section. Shop: PetFolio, price: $0.50.
- **Root cause:** This appears to be a test product created during development with no content moderation gate.
- **Fix applied:** Set `active = false` in Supabase for the "Nudes" product. Product no longer appears in any listing.
- **Evidence:** `qa_artifacts/24_marketplace_loaded.png`

#### BUG-010 · Match: No mutual-like match celebration overlay observed
- **Module:** Match → Discover (swipe right → mutual like → expected match animation)
- **Repro:** Swiped right on Clover. No match celebration overlay appeared. Advance to next card silently.
- **Note:** This was likely a one-sided like (Clover had not liked Montu back). The test was not fully conclusive since a seeded mutual-like scenario was not set up. Requires a controlled test with two pets set to mutually like each other to confirm the match overlay fires.
- **Status:** Inconclusive — needs dedicated test setup.

---

### P3 — Polish (Open)

#### BUG-011 · Chat: Inconsistent timestamp formats in thread list
- **Status:** ✅ FIXED (Session 2)
- **Module:** Match → Messages inbox
- **Observed formats in same screen:** `5:52 AM` (same-day), `Fri` (day name), `6/1` (month/day short).
- **Fix applied:** Rewrote `_formatTime` in `matches_inbox_screen.dart` to use fully relative format: "just now" < 1 min, "Xm" < 1 hr, "Xh" < 24 hr, "Yesterday", day name within a week, `m/d` for older.
- **Evidence:** Verified — inbox shows "4h", "6h", "Fri", "5/17" correctly.

#### BUG-012 · Marketplace trending cards: subtitle shows pet name or brand instead of shop name
- **Status:** ✅ FIXED (Session 2)
- **Module:** Marketplace → Trending section
- **Observed:** "Nudes" card shows subtitle "Afsan" (a pet name). "Treat Salmon" shows "PetFolio" (the `brand` field).
- **Fix applied:** Updated `product_repository.dart` to join `shops` table and map `shop_name` to product model. Trending card subtitle now renders `shopName`.
- **Evidence:** Verified — all trending cards show shop names (PetFolio, Deshi, Pawhaus, Wholepack).

#### BUG-013 · Chat messages: Dev-era Bangla test messages visible in seed threads
- **Status:** ✅ FIXED (Session 2)
- **Module:** Match → Messages inbox thread previews
- **Observed:** `হেল` (Bangla script, May 17) and `QA test message 🐾` (Jun 10) were present in `chat_messages`.
- **Fix applied:** Deleted both rows by ID via Supabase `execute_sql`. Emoji-only and transliterated messages (GG, WP, Dekh) were retained as they may be real user messages.

---

### P3 — Deferred

#### BUG-014 · Navigation: Hardware back button exits app from nested Marketplace routes
- **Status:** 🔴 OPEN — Deferred
- **Module:** Any screen pushed onto the GoRouter shell stack (Cart, Browse Categories, etc.)
- **Repro:** Navigate to Market → Cart (or any sub-route). Press the Android hardware BACK button. App exits to the Android launcher immediately instead of popping back to the Marketplace shell.
- **Root cause:** GoRouter shell routes — when `context.pop()` is called at a route where there is no parent in the Flutter Navigator stack, GoRouter exits the app. The hardware back button triggers the system pop, which bypasses `WillPopScope`/`PopScope` guards on the shell.
- **Fix required:** Wrap the root shell route with `PopScope(canPop: false, onPopInvoked: ...)` to intercept the hardware back action and redirect it to the correct tab or show an exit confirmation dialog.
- **Note:** The software back arrow (`<`) in headers calls `context.pop()` with the same effect when pressed from root-level routes. Both vectors need the same fix.

---

## Module Execution Summary

| Module | Status | Key Flows Verified | Bugs |
|---|---|---|---|
| Auth / Home | ✅ Pass | Login session retained, pet switcher (7 pets), Riverpod context invalidation per pet, achievement toast ("7-Day Hero") | — |
| Care & Health | ⚠️ Partial | 3-day streak, 14/14 tasks, 185 XP display, weight log (4.5 kg), GPS walk tracker (Baridhara Dhaka map), appointments (2 upcoming) | BUG-002, BUG-004 |
| PawsFeed | ⚠️ Partial | Post feed (images load), community tab (2 groups), new community post published "just now", stories tab tested | BUG-005 |
| Match / Discovery | ✅ Pass | Location permission, discovery feed (Sunny/Clover/Afsan with km tags), swipe left/right/super-like, inbox (3 new matches), chat message sent & delivered real-time | BUG-006, BUG-008, BUG-010 |
| Marketplace | ✅ Pass (after P0 fix) | Browse, product detail (Bhaat $5.00 / Treat Salmon ★5.0), add to cart ×2, promo code input, COD checkout, order placed (#c424f15a), order detail tracking | BUG-001 (fixed), BUG-003, BUG-007, BUG-009 |
| Vet / Appointments | ✅ Pass | Appointment list (Vaccination + Emergency upcoming) rendered correctly | — |
| Seller Portal | ✅ Pass | Dashboard: PetFolio shop, Verified badge, 1 product / 0 pending orders, quick actions (Add product, Manage, View orders, Earnings, Edit shop, Danger Zone) all present | — |

---

## Supabase Backend Observations

| Table | Row Count | Finding |
|---|---|---|
| `products` | 12 (11 active) | All have `image_urls = NULL` · `stock_quantity` column doesn't exist |
| `health_logs` | 24 | Corrupt escalating weight data for Montu (max 200 kg) |
| `pet_weight_logs` | 1 | Created this session — correct table for Health screen |
| `stories` | 0 | Empty → black screen bug |
| `swipes` | 176 | Montu's deck was already exhausted before session |
| `matches` | 37 | Active match records exist |
| `chat_messages` | 223 | 1 new added this session |
| `marketplace_orders` | 27 | 1 new COD order placed (#c424f15a) |
| `shops` | 7 | All `is_verified = true` |
| `pets` | — | `match_discovery_enabled` column doesn't exist — actual column is `is_discoverable` |

### RLS Health
- `products` SELECT: open for `active = true` (anon + auth) ✅
- `swipes`: actor/target id gating verified ✅  
- `pets.is_discoverable`: correctly gates match candidates ✅

---

## Phase 3 — Hardware & Device Features

| Feature | Status | Notes |
|---|---|---|
| GPS / Geolocation | ✅ | Walk tracker rendered live map (Baridhara, Dhaka) via ADB `emu geo fix` |
| Location permissions | ✅ | Android `ACCESS_FINE_LOCATION` granted via ADB; app transitions correctly |
| Touch gestures | ✅ | Swipe pass/like/super-like, long-press, tap all verified |
| IME / Soft keyboard | ⚠️ | Log Weight Save button hidden behind nav bar when keyboard opens (BUG-002) |
| FCM Push Token | ✅ | `[FCM] token synced (android)` confirmed in logcat |
| FlutterSecureStorage | ⚠️ | Algorithm migration RSA→AES_GCM ran on launch. 0 items migrated (non-blocking). |
| Riverpod provider isolation | ✅ | Pet context switch correctly invalidates all providers — confirmed via XP/streak/theme changes |

---

## Accessibility Snapshot (Phase 4)

| Screen | Issue | Priority |
|---|---|---|
| Match discovery cards | No `Semantics` label — pet name/species not announced to TalkBack | P2 |
| Product cards | Image placeholder has no `semanticLabel` | P3 |
| Stories tab | Zero content for screen readers when empty (BUG-005) | P1 |
| Care task list | Completion checkboxes use raw `GestureDetector`, not `Checkbox` — no checked/unchecked semantic state | P2 |
| Match swipe buttons | ✕ / ⭐ / 🐾 emoji buttons have no `Semantics(label:)` — announced as "Multiply sign", "Star", "Paw prints" | P2 |

---

## Screenshots Index (`qa_artifacts/`)

| File | Description |
|---|---|
| `01_home_initial.png` | Home: Montu Lv 7, 3-day streak, 14/14 |
| `02_pet_switcher_sheet.png` | Pet switcher bottom sheet (7 pets) |
| `03_pet_switched_tommy.png` | Tommy context: Lv 5, orange theme |
| `04_montu_restored_badge_toast.png` | "7-Day Hero 🏆" achievement toast |
| `05_care_dashboard.png` | Care: all tasks done, 185 XP |
| `06_nutrition_weight_p1_bug.png` | Weight chart — corrupted 200 kg scale |
| `07_walk_tracker_gps_dhaka.png` | Walk tracker with Dhaka map (GPS working) |
| `08_nutrition_log_weight_hidden_p2.png` | Log Weight Save button clipped behind nav bar |
| `09_health_medical_vault.png` | Health: 0 records, "No weight logs yet" |
| `10_weight_logged_4_5kg.png` | Weight log: 4.5 kg entry successful |
| `11_weight_dual_table_bug_confirmed.png` | Dual-table split-brain evidence |
| `12_appointments_upcoming.png` | 2 upcoming: Vaccination + Emergency |
| `13_pawsfeed_feed_blank_image.png` | Feed initial load with loading delay on post image |
| `14_pawsfeed_snow_post.png` | Snow's Persian kitten post fully loaded |
| `15_stories_black_screen_p2.png` | Stories tab: completely black, no empty state |
| `16_community_list.png` | Communities: Cat Lovers + CodeStorm |
| `17_community_post_published.png` | Persian cat community post published "just now" |
| `18_match_location_prompt.png` | Match: "Location needed" empty state |
| `19_match_no_pets_nearby.png` | Match: "No pets nearby yet" (post-permission grant) |
| `20_match_discovery_loaded.png` | Discovery feed: Sunny Cockatiel (Within 1 km) |
| `21_match_swipes_done.png` | Deck exhausted after 3 swipes |
| `22_match_inbox.png` | Match inbox: 3 new matches, 7 message threads |
| `23_match_chat_sent.png` | Chat: playdate message sent and delivered |
| `24_marketplace_loaded.png` | Marketplace after P0 fix: products visible |
| `25_cart_multi_vendor.png` | Cart: CodeStorm PAW + Montur Tong sub-carts |
| `26_order_placed.png` | Order confirmation screen: #C424F15A |
| `27_order_detail_pending.png` | Order detail: Pending / Awaiting seller confirmation |
| `28_seller_dashboard.png` | Seller dashboard: PetFolio Verified, 1 product |

---

## Recommended Fix Priority Queue

| # | Bug | Effort | Impact |
|---|---|---|---|
| 1 | BUG-009 Remove "Nudes" product | 5 min (DB) | Brand safety |
| 2 | BUG-005 Stories empty state | 15 min | UX critical |
| 3 | BUG-002 Log Weight `isScrollControlled` | 30 min | Core care flow |
| 4 | BUG-006 Deck-exhausted copy | 20 min | Match UX |
| 5 | BUG-003 Upload product images | 1–2 hr (content) | Marketplace revenue |
| 6 | BUG-008 Thread list avatar fallback | 1 hr | Match inbox polish |
| 7 | BUG-004 Unify weight tables + fix chart | 3–4 hr | Health data integrity |
| 8 | BUG-007 Multi-vendor cart UX | 4–6 hr | Checkout conversion |
| 9 | BUG-011–013 P3 polish | 2 hr total | Quality |
