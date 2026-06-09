Let me read the screenshots, the current router and shell, then research the design pattern in parallel.

Let me get the right food screen and read the shell + home in parallel with web research.

I now have everything. Let me read the current AppShell to fully understand the existing implementation before writing the plan.

Now I have the complete picture. I can see the current AppShell already has a beautiful custom floating pill nav with spring physics. Let me now write the full analysis and implementation plan.

---

# Petfolio — Contextual Navigation Redesign Plan

## What the Pathao Screenshots Tell Us

**Home Screen (global shell):**
- Bottom nav: `Home | Offers | Activity | Inbox` — 4 utility-level tabs
- These are always present regardless of what you're doing
- Home tab = the launcher hub (bento grid of services)

**Food Screen (module shell):**
- Bottom nav completely **replaced** with: `Food | Pick-up | Offers | Favorites | Reorder` — 5 feature-level tabs
- A `← back arrow` appears in the AppBar to escape back to the global Home hub
- The global 4-tab nav is **gone** while inside the module

**The Core Pattern:** Two-tier navigation — a lean global shell for utility, and a rich module-specific shell for each major feature. The hub is the gateway, not a peer of the features.

---

## Current Petfolio Architecture (What Exists Now)

```
AppShell (FloatingNav — 5 equal tabs)
  ├── /home       → HubHomeScreen       [Tab 1 - Home]
  ├── /care       → CareScreen          [Tab 2 - Care]
  ├── /social     → SocialScreen        [Tab 3 - Social]
  ├── /matching   → MatchingScreen      [Tab 4 - Match]
  └── /marketplace → MarketplaceScreen  [Tab 5 - Market]

Root Navigator (outside shell — pushed on top):
  ├── /care/nutrition, /care/walk, /care/medical-vault, /care/appointments
  ├── /social/stories, /social/create-post, /social/communities, /social/notifications
  ├── /matching/inbox, /matching/chat/:id
  ├── /marketplace/product/:id, /marketplace/cart, /seller, etc.
  ├── /activity, /offers, /settings  ← NO SHELL, buried in AllFeaturesSheet
  └── /onboarding, /login, /register
```

**The Problem:**
- Care sub-screens (Nutrition, Walk, Medical, Vets) are pushed _over_ the shell — user loses Care tab context
- Activity, Offers, and Settings have zero navigation entry points visible to a normal user
- Social Notifications, Communities, Matching Inbox — only reachable via hidden AppBar icons
- All 5 tabs are equal weight, but Home is really a hub (launcher), not a peer feature
- The existing `_FloatingNav` (spring animated, pill-shaped) is already excellent — needs configuration swapping, not a rebuild

---

## Proposed Architecture: Contextual Shell

```
AppShell (path-aware, renders the correct FloatingNav config)
  │
  ├── GLOBAL SHELL  (when at /home, /notifications, /activity, /me)
  │    FloatingNav: Home | Notifs | Activity | Me
  │
  ├── CARE MODULE   (when at /care or any /care/* path)
  │    FloatingNav: Dashboard | Nutrition | Health | Walk | Vets
  │    AppBar: ← Home
  │
  ├── SOCIAL MODULE (when at /social or any /social/* path)
  │    FloatingNav: Feed | Stories | Communities | Profile
  │    AppBar: ← Home
  │
  ├── MATCH MODULE  (when at /matching or any /matching/* path)
  │    FloatingNav: Discover | Inbox | Liked
  │    AppBar: ← Home
  │
  └── MARKET MODULE (when at /marketplace or any /marketplace/* path,
                     or /seller/*, /shop/*)
       FloatingNav: Shop | Categories | Cart | Sell
       AppBar: ← Home
```

---

## Proposed Bottom Navigation — Per Module

### Global Shell (4 tabs)
> **Shown when:** at `/home`, `/notifications`, `/activity`, `/me`

| # | Icon | Label | Route | Accent | What's Here |
|---|------|-------|-------|--------|-------------|
| 1 | `home_rounded` | **Home** | `/home` | Tangerine | HubHomeScreen — bento grid launcher |
| 2 | `notifications_rounded` | **Alerts** | `/notifications` | Sunny | Combined: social notifs + system notifs + promos |
| 3 | `receipt_long_rounded` | **Activity** | `/activity` | Poppy | Order history + appointment history |
| 4 | `manage_accounts_rounded` | **Me** | `/me` | Lilac | Pet profile, Settings, Addresses, Theme toggle |

> **How to reach a module:** Tap any tile in the Home bento grid (Care tile → enters Care module). AllFeaturesSheet remains as a "see everything" overlay from Home.

---

### Care Module (5 tabs)
> **Shown when:** on `/care`, `/care/nutrition`, `/care/medical-vault`, `/care/walk`, `/care/appointments`
> **Back to Home:** `←` in AppBar → `context.go('/home')`

| # | Icon | Label | Route (bring inside shell) | Accent |
|---|------|-------|--------------------------|--------|
| 1 | `local_fire_department` | **Dashboard** | `/care` | Sunny |
| 2 | `restaurant_rounded` | **Nutrition** | `/care/nutrition` | Mint |
| 3 | `medical_services_rounded` | **Health** | `/care/health` | Poppy |
| 4 | `directions_walk_rounded` | **Walk** | `/care/walk` | Tangerine |
| 5 | `event_available_rounded` | **Vets** | `/care/appointments` | Lilac |

> **Note:** `/care/medical-vault` → rename route to `/care/health` for clarity. Sub-screens like Edit vitals, Add record stay as `context.push` over this shell.

---

### Social Module (4 tabs)
> **Shown when:** on `/social`, `/social/stories`, `/social/communities`, `/social/profile/:id`
> **Back to Home:** `←` in AppBar → `context.go('/home')`

| # | Icon | Label | Route | Accent |
|---|------|-------|-------|--------|
| 1 | `dynamic_feed_rounded` | **Feed** | `/social` | Poppy |
| 2 | `auto_stories_rounded` | **Stories** | `/social/stories` | Sunny |
| 3 | `groups_rounded` | **Community** | `/social/communities` | Lilac |
| 4 | `pets_rounded` | **My Pet** | `/social/profile/me` | Tangerine |

> **Create Post FAB:** Stays as floating action button on Feed and Stories tabs (not a nav item).
> **Social notifications:** Moved to global Alerts tab — no longer buried behind an AppBar icon.

---

### Match Module (3 tabs)
> **Shown when:** on `/matching`, `/matching/inbox`, `/matching/chat/:id`
> **Back to Home:** `←` in AppBar → `context.go('/home')`

| # | Icon | Label | Route | Accent |
|---|------|-------|-------|--------|
| 1 | `auto_awesome_rounded` | **Discover** | `/matching` | Lilac |
| 2 | `chat_bubble_rounded` | **Messages** | `/matching/inbox` | Tangerine |
| 3 | `favorite_rounded` | **Liked** | `/matching/liked` | Poppy |

> **Note:** `/matching/liked` is a new screen to surface mutual matches / liked profiles. Chat screen (`/matching/chat/:id`) stays as a push _over_ the shell (full-screen, no nav bar — correct UX pattern like any messaging app).

---

### Marketplace Module (4 tabs)
> **Shown when:** on `/marketplace`, `/marketplace/categories`, `/marketplace/cart`, `/seller`, `/shop/:id`
> **Back to Home:** `←` in AppBar → `context.go('/home')`

| # | Icon | Label | Route | Accent | Badge |
|---|------|-------|-------|--------|-------|
| 1 | `storefront_rounded` | **Shop** | `/marketplace` | Mint | — |
| 2 | `category_rounded` | **Browse** | `/marketplace/categories` | Tangerine | — |
| 3 | `shopping_cart_rounded` | **Cart** | `/marketplace/cart` | Poppy | Item count |
| 4 | `sell_rounded` | **Sell** | `/seller` | Sunny | — |

> **My Orders:** Accessible from the global **Activity** tab (not buried in Marketplace).
> **Cart badge:** Item count dot shown on Cart tab icon when `cartProvider.itemCount > 0`.

---

## How to Get Back to Home from Any Module

Three consistent back-to-home entry points — users can always escape:

1. **AppBar back arrow `←`** (most visible): Every module screen shows `← Home` in top-left. `context.go('/home')` resets to global shell.
2. **Long-press any nav tab** (power user): Long-pressing the first module tab pops to its root route (standard GoRouter `initialLocation: true`).
3. **Double-tap Home tile (from AllFeaturesSheet)**: When already in a module, tapping the Home tile in AllFeaturesSheet = `context.go('/home')`.

> There is **no persistent "Home" tab inside module navs** (unlike the current design where Home is always tab 1). This is intentional — it's cleaner and matches the Pathao mental model. The back arrow is unambiguous.

---

## Technical Implementation Plan

### Architecture Approach: Path-Aware Single Shell (Option A — Recommended)

Keeps the existing `ShellRoute` and the beautiful `_FloatingNav` widget. Only adds:
1. A `shellModuleProvider` (Riverpod `StateProvider`)
2. Multiple `AppShellDestinationSet` configs
3. `AnimatedSwitcher` wrapping the nav bar
4. Path-to-module mapping in `AppShell._moduleFromPath()`

This avoids a full GoRouter restructure to `StatefulShellRoute` (which would require rewriting all 12 route files and break the redirect system).

---

### Phase 1 — New Provider & Destination Sets
**New file:** `lib/core/navigation/shell_module_provider.dart`

```dart
enum ShellModule { global, care, social, matching, marketplace }

final shellModuleProvider = StateProvider<ShellModule>(
  (ref) => ShellModule.global,
);
```

**New file:** `lib/core/navigation/shell_destinations.dart`

Define 5 `List<AppShellDestination>` constants:
- `globalDestinations` — 4 tabs (Home, Alerts, Activity, Me)
- `careDestinations` — 5 tabs (Dashboard, Nutrition, Health, Walk, Vets)
- `socialDestinations` — 4 tabs (Feed, Stories, Community, My Pet)
- `matchingDestinations` — 3 tabs (Discover, Messages, Liked)
- `marketplaceDestinations` — 4 tabs (Shop, Browse, Cart, Sell)

Each set also carries `accentColors[]` and `moduleName` (for AppBar eyebrow).

---

### Phase 2 — Update AppShell

**Changes to `lib/core/widgets/app_shell.dart`:**

1. **`_moduleFromPath(String location) → ShellModule`**
   ```
   /care*        → ShellModule.care
   /social*      → ShellModule.social
   /matching*    → ShellModule.matching
   /marketplace*, /seller*, /shop*  → ShellModule.marketplace
   default       → ShellModule.global
   ```

2. **`_selectedSubIndex(ShellModule module, String location) → int`**
   Returns which tab within the current module's destination set is active.
   - E.g., `/care/nutrition` → careDestinations index 1

3. **Wrap `_FloatingNav` with `AnimatedSwitcher`:**
   ```dart
   AnimatedSwitcher(
     duration: const Duration(milliseconds: 220),
     transitionBuilder: (child, anim) => FadeTransition(
       opacity: anim,
       child: SlideTransition(
         position: Tween(begin: Offset(0, 0.15), end: Offset.zero)
           .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
         child: child,
       ),
     ),
     child: _FloatingNav(
       key: ValueKey(currentModule), // ← triggers AnimatedSwitcher on module change
       destinations: _destinationsFor(currentModule),
       selectedIndex: _selectedSubIndex(currentModule, location),
       onSelect: (i) => context.go(_destinationsFor(currentModule)[i].path),
       accentColors: _accentColorsFor(currentModule),
     ),
   ),
   ```

4. **Module AppBar back-arrow:** When `currentModule != ShellModule.global`, the `AppShellHeader` left side shows `← Home` button instead of the pet switcher pill. The pet switcher moves to the right side.

---

### Phase 3 — Route Restructure

**Move sub-routes inside the ShellRoute** (so they keep the module nav bar visible):

| Route | Current | Proposed |
|-------|---------|----------|
| `/care/nutrition` | root push (loses nav) | inside ShellRoute ✅ |
| `/care/medical-vault` | root push | inside ShellRoute ✅ |
| `/care/walk` | root push | inside ShellRoute ✅ |
| `/care/appointments` | root push | inside ShellRoute ✅ |
| `/social/stories` | root push | inside ShellRoute ✅ |
| `/social/communities` | root push | inside ShellRoute ✅ |
| `/social/notifications` | root push | → merge into `/notifications` in global shell |
| `/matching/inbox` | root push | inside ShellRoute ✅ |
| `/activity` | root push (no nav) | inside ShellRoute, global tab ✅ |
| `/offers` | root push (no nav) | → merge into `/notifications` as a tab or sub-section |
| `/settings` | root push (no nav) | → `/me` screen inside ShellRoute global tab ✅ |

**Keep as root pushes** (full-screen modal behavior — correct):
- `/social/create-post`, `/social/create-story` — creation flows
- `/matching/chat/:id` — immersive chat (like WhatsApp — no bottom nav)
- `/social/post/:id` — full-screen post detail
- `/marketplace/product/:id`, `/marketplace/order/:id` — detail screens
- `/onboarding`, `/login`, `/register` — pre-auth

---

### Phase 4 — New Screens to Create

| Screen | Route | Why |
|--------|-------|-----|
| `NotificationsScreen` (merged) | `/notifications` | Unify social notifs + system notifs + promos into one global Alerts tab |
| `MeScreen` | `/me` | Replaces `/settings` — adds pet management, theme, addresses, logout |
| `MatchLikedScreen` | `/matching/liked` | Surfaces mutual matches / liked pets (using existing `matches` + `swipes` tables) |

---

### Phase 5 — AppShellHeader Adaptation

The header currently switches its trailing icons per tab index (0–4). With contextual nav, it needs to:

| Context | Left side | Right side |
|---------|-----------|------------|
| Global/Home | Pet switcher pill | 🔥streak + 🔔 → /notifications + ⚙ → /me |
| Global/Alerts | "ALERTS" label | Mark-all-read button |
| Global/Activity | "ACTIVITY" label | Filter icon |
| Global/Me | "MY PROFILE" label | — |
| Care module | `← Home` + "CARE" | Walk shortcut + Dark mode toggle |
| Social module | `← Home` + "PAWSFEED" | Search + Create (FAB instead?) |
| Match module | `← Home` + "MATCH" | Preferences filter |
| Market module | `← Home` + "MARKET" | Cart badge button |

---

### Phase 6 — Accent Color & Visual Consistency

Each module has a "pillar color" already defined in the current codebase:
| Module | Color | `AppColors` |
|--------|-------|-------------|
| Home | Tangerine | `AppColors.tangerine` |
| Care | Sunny | `AppColors.sunny` |
| Social | Poppy | `AppColors.poppy` |
| Match | Lilac | `AppColors.lilac` |
| Marketplace | Mint | `AppColors.mint` |

The `_FloatingNav` already uses `tabAccentColors[]`. With contextual nav, each module's 3–5 tabs will all use that module's pillar color for selected state — consistent with the existing spring animation system.

---

## What Doesn't Change

- The `_FloatingNav` widget + spring animation system — **no rebuild needed**
- GoRouter redirect/auth logic in `RouterNotifier` — untouched
- All 47 screen widgets — no changes to their internal code
- All repositories, controllers, providers — untouched
- The `_WideNavRail` for tablet — just needs the same destination config update
- `AppShellDestination` class — unchanged

---

## File Change Summary

| File | Change Type | Description |
|------|------------|-------------|
| `lib/core/navigation/shell_destinations.dart` | **NEW** | 5 destination set configs |
| `lib/core/navigation/shell_module_provider.dart` | **NEW** | `ShellModule` enum + Riverpod provider |
| `lib/core/widgets/app_shell.dart` | **MODIFY** | Path→module mapping, AnimatedSwitcher nav, header adaptation |
| `lib/core/router.dart` | **MODIFY** | Move 8 sub-routes inside ShellRoute; add `/notifications`, `/me`, `/matching/liked` |
| `lib/core/navigation/app_shell_routes.dart` | **MODIFY** | Add Care/Social/Matching/Marketplace sub-routes inside shell |
| `lib/features/social/social_routes.dart` | **MODIFY** | `/social/notifications` → delegates to `/notifications` |
| `lib/features/settings/settings_routes.dart` | **MODIFY** | `/settings` → `/me` |
| `lib/features/offers/offers_routes.dart` | **MODIFY** | Merge into `/notifications` tab |
| `lib/features/home/presentation/screens/hub_home_screen.dart` | **MINOR** | Care/Social/Match/Market tiles navigate _into_ module root (already do) |
| `lib/features/notifications/` | **NEW FEATURE** | `NotificationsScreen` (merged alerts + promos) |
| `lib/features/profile/` | **NEW FEATURE** | `MeScreen` (profile hub: pets, settings, addresses) |
| `lib/features/matching/presentation/screens/match_liked_screen.dart` | **NEW** | Liked/mutual matches screen |

**Total new files: ~8 | Modified files: ~9 | Deleted/merged routes: 3**

---

## Implementation Sequence (5 Phases — Confirm Before Each)

```
Phase 1 — Foundation
  → Create shell_module_provider.dart + shell_destinations.dart
  → Update app_shell.dart with path→module detection + AnimatedSwitcher
  → Update app_shell_routes.dart with sub-routes inside shell
  ✅ Confirm: nav swaps correctly when navigating to /care, /social, etc.

Phase 2 — Global Shell Completion
  → Create /notifications (merged) screen
  → Create /me screen (profile + settings hub)
  → Update AppShellHeader for module back-arrow
  ✅ Confirm: global 4-tab nav works, notifications and Me screens load

Phase 3 — Module Sub-route Migration
  → Move care sub-routes inside shell
  → Move social/stories + communities inside shell
  → Move matching/inbox inside shell
  ✅ Confirm: sub-screens retain the module nav bar

Phase 4 — New Screens
  → MatchLikedScreen for /matching/liked
  → MeScreen sub-sections (pet switcher, settings, addresses)
  ✅ Confirm: new tabs are functional

Phase 5 — Polish
  → AnimatedSwitcher slide/fade tuning
  → Wide screen NavigationRail context-awareness
  → AppBar eyebrow text updates per module
  → Cart badge on Marketplace nav tab
  ✅ Final review
```

---

Ready to start Phase 1 on your confirmation. Which phase would you like to begin with?