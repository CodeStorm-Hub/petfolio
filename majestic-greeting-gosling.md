# Petfolio — Screen Consolidation & Redesign Plan

## Context

The current codebase has 63 screens across 15 modules. Analysis revealed significant duplication:
- Identical UI patterns implemented twice (hashtag grid = saved-posts grid, social DM = match chat)
- Split screens that belong together (me + settings, shop-setup + edit-shop)
- Full-screen routes for content that fits a modal (order confirmation, stripe onboarding)
- Redundant list screens subsumed by existing hub screens (buyer-order-list ⊂ activity, vet-clinics ⊂ vet-hub)

**Target:** 63 → 46 screens (−17), zero regressions, with a comprehensive redesign pass applied to every affected screen using the 4 loaded skills:
- `frontend-design` → bold aesthetic direction, purposeful layouts, distinctive details
- `flutter-ui-ux` → widget composition, animation patterns, 60fps interactions
- `flutter-build-responsive-layout` → LayoutBuilder-based adaptive layouts, no orientation locks
- `accessibility-review` → WCAG 2.1 AA throughout, Semantics, 44dp touch targets

---

## Design Direction (from frontend-design skill)

**Aesthetic**: Warm-editorial. Petfolio's palette (tangerine, poppy, mint, lilac, sunny, sky) maps 1:1 to its 5 modules — this pillar-color system is the brand's superpower and must be amplified, not diluted.

**Typography contract** (already in AppTheme — enforce consistently):
- Display/headline: `GoogleFonts.sora` (weight 600–800)
- Body/label: `Inter` (weight 400–700)
- Never use system fonts or Arial

**Signature patterns to preserve and extend:**
1. `WaveHeader` — species-tinted wave on every module entry screen
2. Bento grid on home — keep, improve touch affordance
3. `TailWagLoader` — use on every loading state, never `CircularProgressIndicator` alone
4. `PetAvatar` with rainbow ring — upgrade with `Hero` tag on every avatar → profile transition

**New design rules for redesigned screens:**
- Minimum 8px outer padding on all content
- Section headers use `label` text style (11px, semibold, letter-spaced, ink500)
- Card radius: `radiusMd` (12dp) for inner cards, `radiusLg` (16dp) for full-width panels
- All list items min height 56dp, divider = `line` color
- Dark-mode: `surface1D` body background, `surface0D` card surface

---

## Accessibility Baseline (WCAG 2.1 AA)

Apply to every redesigned screen:

| Rule | Implementation |
|---|---|
| 1.4.3 Contrast ≥4.5:1 | `ink950` on `surface0` = 12.6:1 ✅; `ink500` on `surface1` must be verified per screen |
| 2.5.5 Touch targets ≥44dp | `PrimaryPillButton.md` = 44dp ✅; all `IconButton` must have `iconSize` + padding |
| 4.1.2 Semantics | Every interactive widget wraps with `Semantics(label:, button: true)` |
| 2.4.7 Focus indicator | `FocusTraversalGroup` on all forms; `FocusNode` explicit ordering |
| 2.1.1 Keyboard | All tappable elements reachable via tab; `onKeyEvent` on swipe cards |
| 1.1.1 Alt text | `PetAvatar(semanticLabel: pet.name)` everywhere; `CachedNetworkImage` with `semanticLabel` |
| 3.3.1 Error ID | All form errors shown inline with `_ErrorBanner`, never just color |

Add `ExcludeSemantics` to all decorative widgets (`WaveHeader` wave path, `TailWagLoader`, `_FloatingPaws`).

---

## Responsive Breakpoints (from flutter-build-responsive-layout skill)

```
mobile  < 600dp   → bottom nav, single column
tablet  600–1024  → NavigationRail sidebar (72dp), 2-column content
desktop > 1024dp  → NavigationRail (200dp extended), 3-column content, max 840dp center
```

**Rules (no exceptions):**
- Use `LayoutBuilder` for all breakpoint decisions — never `MediaQuery.orientationOf`
- Lists on tablet → `GridView.builder(SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 400))`
- Forms/feeds on desktop → `ConstrainedBox(maxWidth: 640)` centered
- Chat on tablet → master-detail `Row` (inbox 320dp | chat Expanded)
- Do NOT lock screen orientation

---

## Phase 1 — Design Token Hardening (Day 1)

**Goal:** Enforce design rules app-wide before touching screens.

### Files to modify
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/app_colors.dart`

### Changes
1. Add missing spacing tokens to `PetfolioThemeExtension`:
   ```dart
   // Add to extension
   static const double spaceXs = 4, spaceSm = 8, spaceMd = 16, spaceLg = 24, spaceXl = 32;
   ```
2. Add semantic shadow elevation tokens (`shadowE1`–`E4`) if missing — already present per exploration, verify they're used consistently.
3. Add a `textLabelCaps` helper style (11px, `FontWeight.w700`, `letterSpacing: 0.8`, `ink500`) to text theme for section headers.
4. Verify all pillar colors meet 4.5:1 contrast on both `surface0` (light) and `surface0D` (dark) — if any fail, darken by 8% in dark mode variant.
5. Add `const` annotation to every static color declaration that is missing it.

### Verification
```bash
flutter analyze lib/core/theme/
```

---

## Phase 2 — Core Widget Library Upgrades (Days 2–3)

**Goal:** Build/upgrade shared widgets that will be reused across all redesigned screens.

### 2a. `WaveHeader` — add `compact` size variant
**File:** `lib/core/widgets/wave_header.dart`

Add `WaveHeaderSize { compact (80dp), regular (140dp), hero (220dp) }` enum param.  
`compact` is used on sub-screens (chat, order detail).  
`hero` is used on home hub and pet profile.  
Keep existing default as `regular`.

### 2b. New: `PostGridScreen` shared widget
**New file:** `lib/core/widgets/post_grid.dart`

```dart
class PostGrid extends ConsumerWidget {
  const PostGrid({required this.postsAsync, required this.onLoadMore, required this.onTap});
  final AsyncValue<List<FeedPost>> postsAsync;
  final VoidCallback onLoadMore;
  final void Function(FeedPost) onTap;
  // 3-col SliverGrid with SkeletonLoader.productCard() placeholders
  // NotificationListener<ScrollNotification> for loadMore at 200dp from bottom
}
```

Used by: `HashtagScreen`, `SavedPostsScreen`, `SocialProfileScreen` (post grid section).

### 2c. New: `SectionHeader` widget
**New file:** `lib/core/widgets/section_header.dart`

```dart
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.label, this.action});
  final String label;  // Rendered as textLabelCaps style
  final Widget? action; // Optional trailing button
}
```

Used by every merged screen's section groups.

### 2d. Upgrade `PetAvatar` — add `heroTag` param
**File:** `lib/core/widgets/pet_avatar.dart`

Add `String? heroTag` param. When non-null, wraps in `Hero(tag: heroTag, child: ...)`.  
Standard tag pattern: `'pet-avatar-${pet.id}'`  
Used in: SocialFeed → SocialProfile, PetProfile → EditProfile.

### 2e. Upgrade `SkeletonLoader` — ensure `accountTile`, `settingsTile` variants exist
**File:** `lib/core/widgets/skeleton_loader.dart`

Add two factory constructors:
- `SkeletonLoader.settingsTile()` — 56dp height tile with leading 20dp icon circle + 2 text lines
- `SkeletonLoader.chatBubble(bool isMine)` — right/left-aligned bubble

### Verification
```bash
flutter analyze lib/core/widgets/
dart run build_runner build --delete-conflicting-outputs
```

---

## Phase 3 — Screen Merges (Days 4–7)

Execute each sub-phase in order. Each sub-phase ends with `flutter analyze`.

### 3a. `me_screen` + `settings_screen` → `AccountScreen`

**New file:** `lib/features/profile/presentation/screens/account_screen.dart`  
**Delete:** `lib/features/settings/presentation/screens/settings_screen.dart`  
**Modify:** `lib/features/profile/presentation/screens/me_screen.dart` (replace with AccountScreen or rename)

**Layout design (frontend-design):**
```
WaveHeader(compact, color: pt.pillarPets)
  └─ _ProfileHeroCard  (avatar initials + email + active pet name + avatar)
SectionHeader('MY PETS')
  ├─ _AccountTile(Switch Active Pet)
  └─ _AccountTile(Add New Pet)
SectionHeader('ACCOUNT')
  ├─ _AccountTile(Saved Addresses)
  └─ _AccountTile(My Orders → /activity?filter=orders)
SectionHeader('STORE')
  ├─ _AccountTile(My Shop)
  └─ _AccountTile(Wishlist)
SectionHeader('SOCIAL')
  └─ _AccountTile(Saved Posts)
SectionHeader('APPEARANCE')
  └─ _ThemeToggleRow (dark/light switch — keep existing themeNotifierProvider)
SectionHeader('OFFERS')
  ├─ _AccountTile(Promos → /offers)
  └─ _AccountTile(Refer & Get Discounts)
_SignOutRow (destructive styling, danger color)
```

**Accessibility:** Each `_AccountTile` wraps its `GestureDetector` in `Semantics(button: true, label: tile.label)`. Min height 56dp.

**Route change:** `/me` and `/settings` both redirect to `/account` in the router. Remove `/settings` route.

---

### 3b. `create_post_screen` + `create_story_screen` → `CreateContentScreen`

**New file:** `lib/features/social/presentation/screens/create_content_screen.dart`  
**Delete:** `lib/features/social/presentation/screens/create_story_screen.dart`  
**Modify:** `lib/features/social/presentation/screens/create_post_screen.dart` (replace contents)

**Layout design:**
```
AppBar
  └─ SegmentedButton(Post | Story)  ← mode toggle (replaces separate screens)

_PetIdentityRow (shared)

_ImageWell (shared — same picker logic for both modes)
  └─ for Story mode: show 9:16 aspect ratio crop guide overlay

_CaptionCard (Post mode only — hidden in Story mode)

_VisibilityInfo (Post mode only)

PrimaryPillButton('Post' / 'Add to Story')
```

**Controller:** Extend `createPostControllerProvider` to accept a `ContentMode { post, story }` enum. Already shares Supabase Storage upload path — just routes to `feed_posts` or `stories` table on submit.

**Route change:** `/social/create-post` and `/social/create-story` both map to `CreateContentScreen` with `mode` query param.

---

### 3c. `hashtag_screen` + `saved_posts_screen` → parameterized `PostGridScreen`

**Modify:** `lib/features/social/presentation/screens/hashtag_screen.dart` (refactor to use shared `PostGrid`)  
**Modify:** `lib/features/social/presentation/screens/saved_posts_screen.dart` (same)  
**Reuse:** `PostGrid` widget from Phase 2b

Both screens keep their own file but reduce to ~40 lines each:
```dart
class HashtagScreen extends ConsumerWidget {
  final String tag;
  // Scaffold + AppBar('#$tag') + PostGrid(postsAsync: hashtagFeedProvider(tag), ...)
}
```

No route changes. Just internal implementation uses shared `PostGrid`.

---

### 3d. `social_dm_screen` + `chat_screen` → unified `ChatScreen`

**New file:** `lib/features/messaging/presentation/screens/chat_screen.dart`  
(Move to a new `messaging` feature folder — both social DM and match chat belong here)  
**Delete:** `lib/features/social/presentation/screens/social_dm_screen.dart`  
**Modify:** `lib/features/matching/presentation/screens/chat_screen.dart` (replace with unified version)

**Constructor:**
```dart
class ChatScreen extends ConsumerWidget {
  const ChatScreen({required this.threadId, this.otherDisplayName, this.showPlaydateScheduler = false});
  final String threadId;
  final String? otherDisplayName;
  final bool showPlaydateScheduler; // true for match chat, false for social DM
}
```

**Unified feature set** (best of both screens):
- Reverse `ListView` ✓
- Date separators (`_DateSeparator`) ✓ (was missing in social DM — add it)
- Typing indicator (`_DotDotDot`) ✓ (was missing in social DM — add it)
- Read receipts ✓ (match chat feature, bring to social DM)
- `WaveHeader(compact)` with other pet's avatar
- `PlaydateSchedulerSheet` FAB (only when `showPlaydateScheduler: true`)

**Tablet layout (flutter-build-responsive-layout):**
```dart
LayoutBuilder(builder: (ctx, constraints) {
  if (constraints.maxWidth > 600) {
    return Row(children: [
      SizedBox(width: 320, child: _InboxPanel()),   // matches inbox on left
      Expanded(child: _ChatPanel(threadId)),         // chat on right
    ]);
  }
  return _ChatPanel(threadId);  // mobile: full screen
})
```

**Route changes:**  
- `/social/dm/:userId` → creates/gets thread then pushes `/chat/:threadId?mode=social`  
- `/match/chat/:threadId` → pushes `/chat/:threadId?mode=match&showPlaydate=true`

---

### 3e. `matches_inbox_screen` + `match_liked_screen` → `MatchHubScreen`

**New file:** `lib/features/matching/presentation/screens/match_hub_screen.dart`  
**Delete:** `lib/features/matching/presentation/screens/matches_inbox_screen.dart`  
**Delete:** `lib/features/matching/presentation/screens/match_liked_screen.dart`

**Layout design (same pattern as VetHubScreen):**
```dart
IndexedStack(index: _tab, children: [
  _InboxTab(),   // mutual matches list → tap → ChatScreen
  _LikesTab(),   // inbound swipes grid
])
// FloatingTabBar at bottom: Messages | Liked
```

**WaveHeader(compact, color: pt.pillarMatch)** at top.

**Tablet layout:** `Row(SizedBox(320, _InboxTab) | Expanded(_LikesTab))` — two panels visible simultaneously.

**Route change:** `/matching/inbox` and `/matching/liked` both map to `MatchHubScreen` with an initial tab index.

---

### 3f. `breeding_setup_screen` + `verification_center_screen` → `MatchProfileSettings`

**New file:** `lib/features/matching/presentation/screens/match_profile_settings_screen.dart`  
**Delete:** both originals

**Layout:**
```dart
DefaultTabController(length: 2,
  child: Scaffold(
    appBar: AppBar(title: 'Match Profile', bottom: TabBar(tabs: ['Breeding', 'Verification'])),
    body: TabBarView(children: [_BreedingTab(), _VerificationTab()]),
  ))
```

Each tab body is the exact content of the original screen. No logic changes — just shared chrome.

**Route:** `/matching/profile-settings?tab=breeding` or `?tab=verification`

---

### 3g. `shop_setup_screen` + `edit_shop_screen` → `ShopProfileScreen`

**New file:** `lib/features/marketplace/presentation/screens/vendor/shop_profile_screen.dart`  
**Delete:** `shop_setup_screen.dart`, `edit_shop_screen.dart`

**Dual-mode logic:**
```dart
class ShopProfileScreen extends ConsumerStatefulWidget {
  const ShopProfileScreen({this.isNew = false});
  final bool isNew;
  // isNew=true: shows only name/slug/description/payout in a single-step form
  // isNew=false: shows full 3-tab edit (Branding | Contact | Policies)
}
```

When `isNew=true`: single-step form → submit → activates 3-tab mode in-place (no navigation).  
Reuse all existing `TextEditingController`s and `editShopControllerProvider`.

**Route:** `/seller/setup` → `ShopProfileScreen(isNew: true)`; `/seller/edit` → `ShopProfileScreen(isNew: false)`

---

### 3h. `admin_screen` — fold gate into `AdminLayout`

**Modify:** `lib/features/admin/presentation/screens/admin_layout.dart`  
**Delete:** `lib/features/admin/presentation/screens/admin_screen.dart`

Add to top of `AdminLayout.build()`:
```dart
final isAdmin = ref.watch(isAdminProvider);
if (!isAdmin) return _AdminGate();  // the lock widget, inlined from admin_screen.dart
```

**Route:** `/admin` maps directly to `AdminLayout`.

---

## Phase 4 — Sheet/Dialog Conversions (Day 8)

### 4a. `shop_intro_screen` → `ShopIntroSheet`

**Modify:** `lib/features/marketplace/presentation/screens/shop_intro_screen.dart`  
Convert `ShopIntroScreen` to `ShopIntroSheet.show(context)` static method.  
Internally: `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, ...)`.  
Remove `/marketplace/intro` route.  
**Call site:** `MarketplaceScreen._maybeShowIntro()` replaces `context.push` with `ShopIntroSheet.show(context)`.

### 4b. `marketplace_categories_screen` → `MarketplaceCategoriesSheet`

**Modify:** `lib/features/marketplace/presentation/screens/marketplace_categories_screen.dart`  
Wrap existing `_CategoryCard` grid in a `DraggableScrollableSheet`.  
Remove `/marketplace/categories` route.  
**Call site:** Marketplace header Categories button calls `showModalBottomSheet`.

### 4c. `order_confirmation_screen` → `OrderSuccessSheet`

**Modify:** `lib/features/marketplace/presentation/screens/order_confirmation_screen.dart`  
Keep existing `AnimationController` logic — it works identically inside a sheet.  
Remove `/marketplace/order/:id` confirmation route.  
**Call site:** `checkoutProvider` listener in `CartScreen` replaces `context.pushReplacement` with `OrderSuccessSheet.show(context, orderId)`. After dismiss → `context.go('/activity?filter=orders')`.

### 4d. `stripe_onboarding_screen` → `StripeOnboardingDialog`

**Modify:** `lib/features/marketplace/presentation/screens/vendor/stripe_onboarding_screen.dart`  
Convert to `AlertDialog` with title, explanation text, and "Open Stripe" button.  
`WidgetsBindingObserver` moves to `SellerDashboardScreen` (it already has one for `refreshAfterOnboarding`).  
Remove `/seller/stripe-onboarding` route.  
**Call site:** `ShopProfileScreen` shows dialog inline after shop creation instead of pushing.

---

## Phase 5 — Screen Deletions & Route Cleanup (Day 9)

### 5a. Remove `buyer_order_list_screen`

**Delete:** `lib/features/marketplace/presentation/screens/customer/buyer_order_list_screen.dart`  
**Modify:** `lib/core/router.dart` — remove route.  
**Modify:** All navigation call sites that push `/marketplace/orders` → replace with `context.go('/activity?filter=orders')`.  
`ActivityScreen` already accepts `showHeader` flag — add `initialFilter` constructor param to pre-select Orders chip.

### 5b. Remove standalone `vet_clinics_screen`

**Delete:** `lib/features/appointments/presentation/screens/vet_clinics_screen.dart`  
VetHubScreen's `_ClinicsGridTab` already contains identical content.  
Remove `/appointments/clinics` standalone route.  
All entry points route to `/appointments` (VetHub) instead.

### 5c. Remove standalone `appointments_screen`

**Delete:** `lib/features/appointments/presentation/screens/appointments_screen.dart`  
VetHubScreen's `_AppointmentsHistoryTab` already contains identical content.  
The `add_appointment` FAB logic moves into VetHub's AppBar action.  
Remove `/care/appointments` standalone route if present.

### 5d. Remove Notifications "Promotions" tab

**Modify:** `lib/features/social/presentation/screens/notifications_screen.dart`  
Remove `TabBar` and `_PromotionsTab` — simplify to single `_UpdatesTab` scroll view.  
Promo notifications (type=promo) in `app_notifications` table: render as `_NotificationTile` with a tag chip "Offer" and deeplink to `/offers` on tap.

### 5e. Router cleanup

**Modify:** `lib/core/router.dart`

Remove routes: `/settings`, `/me` (keep as alias → `/account`), `/social/create-story`, `/matching/inbox`, `/matching/liked`, `/marketplace/intro`, `/marketplace/categories`, `/seller/stripe-onboarding`, `/marketplace/orders`, `/care/appointments` (standalone)

Add/update routes:
- `/account` → `AccountScreen`
- `/social/create?mode=post|story` → `CreateContentScreen`
- `/matching/hub?tab=0|1` → `MatchHubScreen`
- `/matching/profile-settings` → `MatchProfileSettings`
- `/chat/:threadId` → unified `ChatScreen`
- `/seller/profile` → `ShopProfileScreen`
- `/admin` → `AdminLayout` directly

Update legacy redirects: `/me` → `/account`, `/settings` → `/account`

---

## Phase 6 — Responsive Layout Overhaul (Days 10–11)

Apply `flutter-build-responsive-layout` patterns to these screens:

| Screen | Mobile | Tablet (≥600dp) | Desktop (≥1024dp) |
|---|---|---|---|
| `MarketplaceScreen` | 2-col grid | 3-col grid | `ConstrainedBox(840)` 4-col |
| `SocialScreen` (feed) | single column | `ConstrainedBox(560)` centered | same |
| `AdminLayout` | `BottomNavigationBar` | `NavigationRail(extended:false)` | `NavigationRail(extended:true)` |
| `AccountScreen` | single list | 2-col: nav list \| content panel | same |
| `MatchHubScreen` (chat) | full screen chat | inbox 320dp \| chat expanded | same |
| `CommunitiesScreen` | list | 2-col card grid | `ConstrainedBox(840)` |
| `VetHubScreen` | floating pill tab bar | side `NavigationRail` | same |

**Pattern for every screen:** Replace any existing `MediaQuery.sizeOf(context).width > X` checks with `LayoutBuilder(builder: (ctx, constraints) { if (constraints.maxWidth > 600) ... })`.

---

## Phase 7 — Animation & Micro-interaction Polish (Days 12–13)

Apply `flutter-ui-ux` animation patterns:

### Hero transitions
**File:** `lib/core/widgets/pet_avatar.dart` (already modified in Phase 2d)

Add `Hero(tag: 'pet-avatar-${pet.id}')` in:
- `SocialScreen` post card avatar → `SocialProfileScreen`
- `PetProfileScreen` avatar → `EditProfileScreen`
- `MatchingScreen` card surface avatar → `SocialProfileScreen`

### WaveHeader consistency
Every module entry screen must have a `WaveHeader`. Apply to screens missing it:
- `MatchingScreen` → add `WaveHeader(color: pt.pillarMatch)`
- `CommunitiesScreen` → add `WaveHeader(color: pt.pillarSocial)`
- `AccountScreen` → add `WaveHeader(compact, color: pt.pillarPets)`
- `MatchHubScreen` → add `WaveHeader(compact, color: pt.pillarMatch)`

### Tab transition animations
All `IndexedStack`-based hub screens (VetHub, MatchHub): wrap child in `AnimatedSwitcher(duration: 200ms, transitionBuilder: FadeTransition)` for smooth tab body crossfade.

### Loading state consistency
Replace all bare `CircularProgressIndicator` with `TailWagLoader`:
- `lib/features/admin/` tabs — currently use bare `CircularProgressIndicator.adaptive()`
- `lib/features/marketplace/presentation/screens/vendor/seller_dashboard_screen.dart`

### Haptic feedback
Add `HapticFeedback.selectionClick()` where missing:
- Every `FilterChip` tap in Care, Offers, Activity screens
- Every `TabBar` tab selection in VetHub, AppointmentsScreen
- Story viewer advance gesture

---

## Phase 8 — Accessibility Hardening (Day 14)

Apply `accessibility-review` WCAG 2.1 AA checklist:

### Semantics wrappers (add to each screen during its redesign phase)

```dart
// Pattern for every interactive tile
Semantics(
  label: tile.label,
  hint: tile.subtitle,
  button: true,
  child: tile,
)
```

**Priority files:**
- `lib/features/matching/presentation/screens/matching_screen.dart` — swipe cards need `Semantics(label: '${pet.name}, ${pet.breed}', hint: 'Swipe right to match, left to pass')`
- `lib/features/social/presentation/screens/social_screen.dart` — `PostCard` reaction button needs `Semantics(label: 'React to post')`
- `lib/core/widgets/wave_header.dart` — add `ExcludeSemantics(child: _WavePainter(...))`

### Touch target audit
All `IconButton` in AppBars must have explicit `constraints: BoxConstraints(minWidth: 44, minHeight: 44)`.  
`_AccountTile` min height: 56dp (already planned).

### Form labels
All `TextField` without visible labels must add `Semantics(label: hintText)` or convert to `TextFormField` with `labelText`.  
Key screens: `CreateContentScreen` caption field, `ShopProfileScreen` fields, `AddEditProductScreen`.

### Focus traversal
Wrap all multi-field forms in `FocusTraversalGroup(policy: OrderedTraversalPolicy())`.

### Color contrast spot-check
- `AppColors.ink500` (#B4A99E approx) on `surface1` (light) — verify meets 4.5:1. If not, darken ink500 to `#9E917E`.
- Promo card: white code text on `AppColors.tangerine` — verify 3:1 minimum for large text.

---

## Phase 9 — Code Generation & Final Verification (Day 15)

```bash
# Regenerate all Riverpod + Freezed code
dart run build_runner build --delete-conflicting-outputs

# Static analysis (must pass clean)
flutter analyze

# Tests
flutter test

# Build check
flutter build apk --debug
```

### Manual verification checklist
- [ ] Auth flow: login → onboarding → care screen
- [ ] `/me` and `/settings` both redirect to `/account`
- [ ] PawsFeed stories → story viewer → back to feed (no state loss)
- [ ] Create Content: post mode and story mode both publish correctly
- [ ] Social profile → Message → unified ChatScreen opens with correct thread
- [ ] Match chat → ChatScreen(showPlaydateScheduler: true) shows Playdate FAB
- [ ] Matching → MatchHubScreen tabs: Inbox | Liked both load
- [ ] Marketplace → shop intro shown only on first visit (SharedPreferences)
- [ ] Cart checkout → OrderSuccessSheet animates → Activity screen
- [ ] Seller: create shop → ShopProfileScreen(isNew:true) → full edit tabs unlock
- [ ] Admin: non-admin user sees lock gate; admin sees full AdminLayout
- [ ] VetHub: /appointments/clinics and /care/appointments both route to VetHub
- [ ] Activity: /marketplace/orders routes to ActivityScreen(initialFilter: orders)
- [ ] Tablet (600dp): NavigationRail visible, chat shows inbox+chat side-by-side
- [ ] Desktop (1024dp): marketplace shows 4-column grid, constrained to 840dp

---

## File Change Summary

| Action | Count | Key Files |
|---|---|---|
| New files | 6 | `account_screen.dart`, `create_content_screen.dart`, `post_grid.dart`, `match_hub_screen.dart`, `match_profile_settings_screen.dart`, `shop_profile_screen.dart`, `section_header.dart` |
| Modified files | ~20 | `router.dart`, `admin_layout.dart`, `chat_screen.dart`, `notifications_screen.dart`, `activity_screen.dart`, `wave_header.dart`, `pet_avatar.dart`, `skeleton_loader.dart` + phase-specific screens |
| Deleted files | 11 | `settings_screen.dart`, `create_story_screen.dart`, `matches_inbox_screen.dart`, `match_liked_screen.dart`, `breeding_setup_screen.dart`, `verification_center_screen.dart`, `shop_setup_screen.dart`, `edit_shop_screen.dart`, `admin_screen.dart`, `vet_clinics_screen.dart`, `buyer_order_list_screen.dart` |
| Sheet conversions | 4 | `shop_intro_screen.dart`, `marketplace_categories_screen.dart`, `order_confirmation_screen.dart`, `stripe_onboarding_screen.dart` |

**Result: 63 screens → 46 screens (−17)**
