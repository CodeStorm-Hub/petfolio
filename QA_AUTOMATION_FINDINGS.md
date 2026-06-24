# QA Automation Findings — Android-MCP Sweep

Date: 2026-06-24
Method: Black-box UI automation against a live debug build on an Android emulator, driven via android-mcp (taps, swipes, type, system back/home). No source-code changes were made as part of this pass — this is an issue-identification report only.

## Scope covered

Home, Care (Dashboard/Nutrition/Health/Walk/Vets), PawsFeed (Feed/Stories/Communities/My Pet, Search, Direct messages), Match (Discover/Messages/Liked), Vet Hub (Clinics → detail → service → date/time → booking confirmation modal), Alerts (Updates/Promotions), Activity (All/Orders/Appointments), Me/Account (Saved Addresses, Wishlist, Saved Posts, Dark Mode), Marketplace (Shop/Browse/Cart tabs, top app-bar cart icon, Browse Categories sheet, onboarding sheet), "All Features" sheet from Home.

---

## Critical bugs

### 1. Marketplace cart is completely unreachable
Both the bottom-tab **Cart** button and the top app-bar cart icon (shopping bag) open the **Browse Categories** sheet instead of any cart screen. There is no working path to view the cart from the Marketplace UI in this build. Reproduced via both entry points on a fresh app session.

### 2. "Browse Categories" sheet is a dead end with no in-app exit
Category cards (Food, Treats, Toys, Beds, Apparel, Grooming, Gear, Health) only toggle a single-select checkmark — tapping a card (or its chevron) does not navigate to a product list. There is no Apply/Done/Continue button anywhere on the sheet. The sheet also cannot be dismissed by:
- tapping outside the sheet (scrim tap did nothing)
- swiping down on the sheet or its handle
- the system back gesture acting as a modal dismiss (see #3)

### 3. Back button from the trapped sheet exits the entire app
Pressing system back while the Browse Categories sheet is open does not close the modal or return to the previous screen — it exits the whole app to the Android launcher. Reproduced 3 times. Because the Flutter engine process stays alive in the background, relaunching the app icon resumes directly into the same stuck sheet (no fresh navigation state). The only way out during testing was **Force Stop via Android Settings → Apps → petfolio**.

### 4. Marketplace "Shop"/"Browse" bottom tabs are effectively non-functional
"Browse" opens the same broken Categories trap as the cart icon (#1). Only "Shop" (the default landing tab) renders the expected screen. Net effect: only 1 of 3 bottom tabs in the Marketplace module does anything useful.

---

## Other confirmed bugs

### 5. Activity module completely broken
The Activity screen — reachable via bottom-nav "Activity" and via Me → "My Orders & Activity" — immediately shows **"Failed to load activity"** with a Retry button. Reproducible across all three sub-tabs (All, Orders, Appointments) and persists after tapping Retry.

### 6. Back-navigation skips a screen after the Activity failure path
When Activity is reached via Me → "My Orders & Activity", pressing back lands on **Home**, skipping the Me screen that was actually the previous route. Confirmed this is not generic back-stack behavior — Me → Saved Addresses → back correctly returns to Me in a separate test. The skip is specific to the path through the broken Activity screen.

### 7. Expired promotion still displayed as active
The "TOYS10" 10%-off coupon in Alerts → Promotions shows "Valid till Jun 22, 2026" while the system date is 2026-06-24 (2 days past expiry), yet it appears in the active promo list with the same "Copy code" affordance as valid promos — no expired badge or greying. Flagged from display-layer evidence only; whether the code is actually rejected at checkout was not verified.

---

## Worth a product/design-intent check (not asserted as bugs)

### 8. PawsFeed "Direct messages" routes into the Match module
The top-bar "Direct messages" icon on PawsFeed opens the Match module's Messages/Liked/Discover screen (header reads "MATCH · MESSAGES") rather than a PawsFeed-specific DM inbox. This may be an intentional unified-messaging design (DM your matched pets), so it's flagged for confirmation rather than logged as a bug.

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
