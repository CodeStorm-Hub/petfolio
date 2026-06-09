I'll run a comprehensive audit in parallel — an Explore agent to map the entire `lib/` codebase while simultaneously querying Supabase for the actual schema.

Now let me query the actual Supabase database to cross-reference with the codebase findings.

Let me read the full database schema and run additional queries to get the complete picture.

Now let me do targeted cross-reference checks for the tables that might not have UI connections.

I now have everything needed. Let me compile the complete audit report.

---

# Petfolio Comprehensive Audit Report

## Database Overview

**44 Tables · 42 Functions/RPCs · 12 Auth Users (dev data)**

---

## 1. Database Tables vs Codebase Map

### ✅ Fully Connected (table → repo → controller → UI)

| DB Table | Repository | Controller/Provider | Screen |
|----------|-----------|---------------------|--------|
| `appointments` | appointment_repository | appointmentControllerProvider | AppointmentsScreen |
| `care_logs` | care_repository | careDashboardControllerProvider | CareScreen |
| `care_streaks` | care_repository | careDashboardControllerProvider | CareScreen |
| `care_tasks` | care_repository | careDashboardControllerProvider | CareScreen |
| `care_web_reminders` | core/platform/care_fcm_reminder_sync.dart | Platform layer (no UI) | Background sync only |
| `chat_messages` | matching (datasource) | Chat controller | ChatScreen |
| `chat_threads` | matching (datasource) | matchesInboxControllerProvider | MatchesInboxScreen |
| `comment_likes` | comment_repository | social controllers | PostDetailScreen |
| `comments` | comment_repository | social controllers | PostDetailScreen |
| `communities` | community_repository | communitiesControllerProvider | CommunitiesScreen |
| `community_members` | community_repository | communities controller | CommunityDetailScreen |
| `community_post_likes` | community_repository | communities controller | CommunityDetailScreen |
| `community_posts` | community_repository | communities controller | CommunityDetailScreen |
| `health_logs` | health_repository | healthVaultControllerProvider | MedicalVaultScreen |
| `health_vitals` | health_repository | healthVaultControllerProvider | MedicalVaultScreen |
| `inventory_reservations` | order_repository | order controllers | Checkout flow |
| `marketplace_orders` | order_repository | buyerOrdersProvider / vendorOrdersControllerProvider | BuyerOrderListScreen, VendorOrderQueueScreen |
| `matches` | matching datasource | discoveryControllerProvider | MatchingScreen |
| `medical_vault` | health_repository | healthVaultControllerProvider | MedicalVaultScreen |
| `notifications` | notification service | notificationControllerProvider | NotificationsScreen |
| `pet_badges` | pet_care_repository | care gamification | CareScreen (badge display) |
| `pet_follows` | social_repository | social controllers | SocialProfileScreen |
| `pet_weight_logs` | vitals_repository | care controllers | MedicalVaultScreen |
| `pets` | pet_repository | petListProvider | ManagePetsScreen, OnboardingScreen |
| `post_likes` | social_repository | social controllers | SocialScreen, PostDetailScreen |
| `posts` | social_repository | socialControllerProvider | SocialScreen, PostDetailScreen |
| `product_reviews` | product_repository | marketplace controllers | ProductDetailScreen |
| `products` | product_repository | productListProvider | MarketplaceScreen, ProductDetailScreen |
| `promos` | promo_repository | promoListProvider | OffersScreen, NotificationsScreen |
| `reported_posts` | admin_repository | admin controllers | AdminScreen |
| `shop_deletion_requests` | admin_repository + shop_repository | shopDeletionController | AdminScreen, SellerDashboardScreen |
| `shops` | shop_repository | myShopControllerProvider | SellerDashboardScreen, ShopStorefrontScreen |
| `stories` | story_repository | story controllers | SocialScreen (story bar), StoryViewerScreen |
| `story_reactions` | story_repository | story controllers | StoryViewerScreen |
| `swipes` | matching datasource | discoveryControllerProvider | MatchingScreen (swipe cards) |
| `user_addresses` | inline in settings_routes.dart | inline widget state | SettingsScreen → Addresses |
| `user_fcm_devices` | firebase/token_repository | FCM service | Background (no UI) |
| `user_web_push_subscriptions` | core/platform/web_push_registration | Platform layer | Background (web only) |
| `users` | auth_repository | authControllerProvider | LoginScreen, RegistrationScreen |
| `vendor_ledgers` | admin_repository | ledgerController | AdminScreen |

---

### ❌ DISCONNECTED — Table Exists in DB, Zero Dart References

| DB Table | Columns | Issue |
|----------|---------|-------|
| **`pet_care_gamification`** | 6 cols | No repository, no model, no UI. Table is populated (server triggers likely), but Flutter reads nothing from it. Pet gamification UI in `gamified_care_ui.dart` uses `pet_badges` + `care_streaks` instead. |
| **`waitlist`** | 6 cols | Complete orphan. No model, no repo, no UI. Likely a pre-launch landing page artifact never wired to the app. |
| **`audit_logs`** | 7 cols | No Flutter reads. Written by DB triggers only (`rls_auto_enable`). Admin screen does NOT display audit logs despite having an AdminScreen. |
| **`fcm_push_outbox`** | 7 cols | Server-side table. Written by DB triggers (`handle_new_chat_message`), consumed by Edge Functions for FCM delivery. Flutter never queries it directly — correct pattern, but worth documenting. |

---

### ⚠️ DB Functions/RPCs — Usage Status

**Called from Flutter (confirmed):**
- `process_checkout` → checkout flow
- `toggle_care_task` → CareScreen
- `get_care_dashboard_snapshot` (×2 overload) → CareScreen
- `matching_discovery_candidates` → MatchingScreen
- `get_chat_inbox` → MatchesInboxScreen
- `get_match_inbox` → MatchesInboxScreen
- `approve_vendor_kyc` / `reject_vendor_kyc` → AdminScreen
- `resolve_reported_post` / `resolve_shop_deletion` → AdminScreen
- `request_shop_deletion` → SellerDashboardScreen
- `vendor_update_order` → VendorOrderDetailScreen
- `cancel_order` / `confirm_order_inventory` / `release_order_inventory` → Order flow
- `get_pet_stats` / `get_pet_awards_summary` → Care gamification

**Server-side only (DB triggers / cron — Flutter never calls directly):**
- `handle_*` (7 trigger functions) — post likes, comments, follows, notifications sync
- `handle_updated_at` / `set_updated_at` — timestamp triggers
- `care_tasks_set_anchor_date` / `check_daily_completion` — care scheduling triggers
- `cleanup_expired_stories` — cron job
- `refresh_product_rating_stats` — trigger on product_reviews
- `rls_auto_enable` — admin utility
- `set_pet_location_point` — trigger on pets

**Uncalled from Flutter (no grep hits — potential dead RPCs):**
- `ensure_chat_thread_for_match` — exists but not called; `ensure_direct_chat_thread` used instead
- `get_or_create_social_thread` — no call site found in lib/
- `mark_story_viewed` — no call site found (stories viewed count may be untracked in UI)
- `dec_community_member_count` / `inc_community_member_count` — trigger-level, not called from Flutter
- `dec_community_post_count` / `inc_community_post_count` — trigger-level

---

## 2. Duplicate Code & Files

### No True Duplicates Found ✅

The codebase is clean. All apparent duplicates are intentional:

| "Duplicate" Pattern | Files | Verdict |
|--------------------|-------|---------|
| `pet.dart` in both `core/models/` and `features/pet_profile/data/models/` | 2 | ✅ Feature file is a barrel re-export only |
| `*_stub.dart` + `*_web.dart` / `*_io.dart` pairs | 5 pairs (10 files) | ✅ Dart conditional import pattern for platform branching |
| `integration_test_gate_stub/io` | 2 | ✅ Platform gate |
| `marionette_debug_gate_stub/io` | 2 | ✅ Platform gate |
| `BuyerOrderDetailScreen` routed from 2 paths | 1 screen, 2 routes | ✅ Intentional reuse |
| `AddEditProductScreen` routed from 2 paths | 1 screen, 2 routes | ✅ Intentional reuse |
| `get_care_dashboard_snapshot` RPC listed twice in DB | 2 rows | ⚠️ Overloaded function (different signatures) — check if both are needed |

---

## 3. Mock / Hardcoded Data

### Only 2 Instances Found (Both Minor)

**Instance 1 — Demo Unsplash images in CreateStoryScreen**
- **File:** [`lib/features/social/presentation/screens/create_story_screen.dart:35`](lib/features/social/presentation/screens/create_story_screen.dart)
- **What:** `_mockPetImages` — a static list of 9 Unsplash photo URLs presented as selectable story images
- **Impact:** Story creation offers fake stock photos instead of the user's actual pet photos
- **Fix:** Replace with a call to Supabase Storage bucket filtered by `auth.uid()` pets

**Instance 2 — Hardcoded category metadata in MarketplaceCategoriesScreen**
- **File:** [`lib/features/marketplace/presentation/screens/marketplace_categories_screen.dart:13`](lib/features/marketplace/presentation/screens/marketplace_categories_screen.dart)
- **What:** `_allCats` — static list mapping `ProductCategory` enums to display labels, emojis, and colors
- **Impact:** None — this is static UI configuration (not data). Product counts come from Supabase.
- **Verdict:** ✅ Acceptable pattern

---

## 4. Disconnected / Improper UI-Backend Connections

### 🔴 Critical

**1. `PetProfileScreen` — Defined, Used as Reference, but Has No Route**
- **File:** [`lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`](lib/features/pet_profile/presentation/screens/pet_profile_screen.dart)
- **Evidence:** `hub_home_screen.dart:23` has a comment `// Replaces PetProfileScreen at '/home'` — this screen was the old home but was replaced by `HubHomeScreen` without being deleted or re-routed
- **Impact:** Screen is exported from `features/pet_profile/index.dart` but is unreachable by any user navigation path. Code referencing it in comments (`gamified_care_ui.dart:115`) confirms it's legacy.
- **Fix:** Delete the file, or add a `/pet/:petId/profile` route if a per-pet profile view is needed

**2. `_AddressManagementScreen` — Large Screen Baked Into Route File**
- **File:** [`lib/features/settings/settings_routes.dart`](lib/features/settings/settings_routes.dart) (230+ lines inline)
- **Impact:** Address management (`user_addresses` table) is functionally connected but architecturally misplaced — makes the route file unwieldy and untestable
- **Fix:** Extract to `lib/features/settings/presentation/screens/address_management_screen.dart`

### 🟡 Moderate

**3. Admin Route — No GoRouter Auth Guard**
- **File:** [`lib/features/admin/`](lib/features/admin/)
- **Issue:** `/admin` route is routable by any authenticated user. The `is_admin` RPC exists in DB and `adminAuthControllerProvider` exists in code, but the GoRouter `redirect:` callback does not check admin role — only the `AdminScreen` widget checks after mounting
- **Impact:** Non-admin users can navigate to `/admin`, see a brief flash of the screen, then get redirected — poor UX and minor security concern (UI data briefly exposed)
- **Fix:** Add `redirect: (ctx, state) => isAdmin ? null : '/home'` to the admin GoRoute

**4. `pet_care_gamification` Table — Backend Tracks, Frontend Ignores**
- The DB table has 6 columns and is presumably populated by server triggers, but `gamified_care_ui.dart` reads from `pet_badges` + `care_streaks` instead. Either the table is unused infrastructure or there's a planned feature that was never wired up.

**5. `ensure_chat_thread_for_match` RPC — DB Has It, App Doesn't Call It**
- The app uses `ensure_direct_chat_thread` for all chat thread creation. The match-specific variant exists in DB but has no call site. Potential dead code in DB.

---

## 5. Widget & Component Map — What the User Sees

### Shell Navigation (Always Visible)
```
AppShell (app_shell.dart)
 └── Bottom Navigation Bar (5 tabs)
      ├── Tab 1: Home      → /home
      ├── Tab 2: Care      → /care
      ├── Tab 3: Social    → /social  
      ├── Tab 4: Matching  → /matching
      └── Tab 5: Marketplace → /marketplace
```

### Core Shared Widgets (Used Across All Screens)
| Widget | File | Used In |
|--------|------|---------|
| `AppHeader` | core/widgets/app_header.dart | Almost every screen |
| `PetAvatar` | core/widgets/pet_avatar.dart | Social, Profile, Matching cards |
| `PrimaryPillButton` | core/widgets/primary_pill_button.dart | Auth, Onboarding, Care, Marketplace |
| `PetfolioEmptyState` | core/widgets/petfolio_empty_state.dart | All list screens when empty |
| `PetfolioNetworkImage` | core/widgets/petfolio_network_image.dart | All image rendering |
| `SkeletonLoader` | core/widgets/skeleton_loader.dart | All async loading states |
| `TailWagLoader` | core/widgets/tail_wag_loader.dart | Global loading spinner |
| `GlassCard` | core/widgets/glass_card.dart | Home hub bento tiles |
| `PfCard` | core/widgets/pf_card.dart | Marketplace product cards |
| `PfStatTile` | core/widgets/pf_stat_tile.dart | Pet stats, Care dashboard |
| `PfAchievementTile` | core/widgets/pf_achievement_tile.dart | Care gamification badges |
| `AppBottomSheet` | core/widgets/app_bottom_sheet.dart | All bottom sheets |
| `AppSnackBar` | core/widgets/app_snack_bar.dart | All feedback messages |
| `BoneSlider` | core/widgets/bone_slider.dart | Pet age/weight inputs |
| `PawToggle` | core/widgets/paw_toggle.dart | Preference toggles |
| `WaveHeader` | core/widgets/wave_header.dart | Care, Profile hero sections |
| `DashedCirclePainter` | core/widgets/dashed_circle_painter.dart | Profile avatar ring |
| `ResponsiveLayout` | core/widgets/responsive_layout.dart | Tablet/phone layout switch |
| `AppTutorialOverlay` | core/widgets/app_tutorial_overlay.dart | First-run onboarding hints |

---

### Tab 1: Home (`/home` → `HubHomeScreen`)

```
HubHomeScreen
 ├── WaveHeader (animated pet avatar + stats)
 ├── Bento Grid Tiles (GlassCard):
 │    ├── [Care tile]         → navigates to /care
 │    ├── [Social tile]       → navigates to /social
 │    ├── [Matching tile]     → navigates to /matching
 │    ├── [Marketplace tile]  → navigates to /marketplace
 │    ├── [Activity tile]     → navigates to /activity
 │    ├── [Offers tile]       → navigates to /offers
 │    └── [All Features tile] → shows AllFeaturesSheet (bottom sheet)
 └── AllFeaturesSheet
      └── Grid of all app features with icons → respective routes
```

### Tab 2: Care (`/care` → `CareScreen`)

```
CareScreen
 ├── GamifiedCareUI (gamified_care_ui.dart)
 │    ├── Pet level badge + XP bar (reads pet_badges, care_streaks)
 │    ├── Daily task checklist (care_tasks table)
 │    └── Achievement tiles (PfAchievementTile)
 ├── Quick-nav cards:
 │    ├── → /care/nutrition       (NutritionScreen)
 │    ├── → /care/medical-vault   (MedicalVaultScreen)
 │    ├── → /care/walk            (WalkTrackingScreen)
 │    └── → /care/appointments    (AppointmentsScreen)
 └── RPC: get_care_dashboard_snapshot
```

### Tab 3: Social (`/social` → `SocialScreen`)

```
SocialScreen
 ├── StoryBar (horizontal scroll of active stories)
 │    └── tap → /social/stories (StoryViewerScreen)
 ├── Feed list (posts from followed pets + own)
 │    └── tap → /social/post/:postId (PostDetailScreen)
 ├── FAB: Create Post → /social/create-post (CreatePostScreen)
 ├── App bar actions:
 │    ├── Notifications icon → /social/notifications (NotificationsScreen)
 │    └── Community icon → /social/communities (CommunitiesScreen)
 └── SocialProfileScreen accessed by tapping any pet avatar → /social/profile/:petId
```

### Tab 4: Matching (`/matching` → `MatchingScreen`)

```
MatchingScreen
 ├── Swipe card stack (discovery candidates)
 │    └── RPC: matching_discovery_candidates
 ├── Like/Pass/Super-like buttons
 ├── Inbox FAB → /matching/inbox (MatchesInboxScreen)
 │    └── tap thread → /matching/chat/:threadId (ChatScreen)
 └── Swipe gesture → records to swipes + matches tables
```

### Tab 5: Marketplace (`/marketplace` → `MarketplaceScreen`)

```
MarketplaceScreen
 ├── Search bar + featured products
 ├── Category chips → /marketplace/categories (MarketplaceCategoriesScreen)
 ├── Product grid → /marketplace/product/:id (ProductDetailScreen)
 │    └── "Add to Cart" → cartControllerProvider → /marketplace/cart (CartScreen)
 │         └── Checkout → /marketplace/order/:id (OrderConfirmationScreen)
 ├── Shop banner → /shop/:id (ShopStorefrontScreen)
 └── Profile menu:
      ├── My Orders → /profile/orders (BuyerOrderListScreen)
      │    └── → /profile/orders/:id (BuyerOrderDetailScreen)
      └── Sell on Petfolio → /seller (SellerDashboardScreen)
```

### Seller Flow (from Marketplace → Sell)

```
/seller → SellerDashboardScreen
 ├── (new seller) → /seller/setup → ShopSetupScreen
 │    └── → /seller/onboarding → StripeOnboardingScreen (external Stripe URL)
 ├── (existing seller):
 │    ├── /seller/edit-shop → EditShopScreen
 │    ├── /seller/kyc → ManualKycScreen
 │    ├── /seller/products → VendorProductListScreen
 │    │    ├── /seller/products/add → AddEditProductScreen
 │    │    └── /seller/products/:id/edit → AddEditProductScreen
 │    └── /seller/orders → VendorOrderQueueScreen
 │         └── /seller/orders/:id → VendorOrderDetailScreen
```

---

## 6. Screens NOT Visible / Not Easily Reachable by User

| Screen | Route | Problem | Severity |
|--------|-------|---------|----------|
| **PetProfileScreen** | ❌ None | No route defined. Orphaned legacy screen. | 🔴 Dead code |
| **AdminScreen** | `/admin` | No navigation link from any user-facing UI. Must know and type the route directly. Only reachable by deep-link or URL bar. Auth check is post-mount, not pre-route. | 🔴 Hidden + auth gap |
| **OnboardingScreen** | `/onboarding` | Only shown during first-run flow (router_notifier redirects). Not accessible after first pet is created — user cannot reach "create new pet" flow from normal navigation. `ManagePetsScreen` at `/pets/manage` handles post-onboarding pet management, but how the user gets there from the app is unclear. | 🟡 Navigation gap |
| **ShopIntroScreen** | `/marketplace/intro` | Entry point unclear — it's routed but no visible "New to Shop?" button in `MarketplaceScreen` explicitly navigates here first-time. | 🟡 May be bypassed |
| **ActivityScreen** | `/activity` | Accessible only from Home bento tile or AllFeaturesSheet. Not in bottom nav. Users who don't tap the tile never discover it. | 🟡 Low discoverability |
| **OffersScreen** | `/offers` | Same as Activity — only in AllFeaturesSheet. No notification badge or push-driven entry. The promos data is connected but the screen is buried. | 🟡 Low discoverability |
| **SettingsScreen** | `/settings` | No visible Settings gear in the main shell or app bar. Only reachable via AllFeaturesSheet. Standard expectation: Settings icon in top-right of home or profile drawer. | 🟡 Hard to find |
| **CommunitiesScreen** | `/social/communities` | Accessible from Social tab app bar icon. Not obvious to new users — icon competes with notification bell. | 🟡 Moderate discoverability |
| **SocialProfileScreen** | `/social/profile/:petId` | Only reachable by tapping a pet avatar in the Social feed. No dedicated "profile" tab or back-link from home. Own-pet profile not accessible from home. | 🟡 Own profile unreachable |
| **ManageKycScreen** | `/seller/kyc` | Only shown to sellers with pending KYC status. Normal users never see it. Conditionally rendered inside SellerDashboard. | 🟢 Correct (conditional) |
| **StoryViewerScreen** | `/social/stories` | Requires an active story to be visible in the story bar. If no stories exist (low-activity state), the entry point disappears. | 🟡 State-dependent |

---

## Summary of Action Items

### 🔴 High Priority
1. **Delete `PetProfileScreen`** — orphaned legacy screen with no route (`lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`)
2. **Add GoRouter auth guard to `/admin`** — check `is_admin` RPC in the redirect callback, not just after screen mount
3. **Add `SettingsScreen` entry point** — place a settings icon in the home hub app bar or shell (users expect it top-right)
4. **Replace mock Unsplash images in `CreateStoryScreen`** — wire to actual Supabase Storage pet photos

### 🟡 Medium Priority
5. **Extract `_AddressManagementScreen`** out of `settings_routes.dart` into its own file
6. **Add "My Pets" / own profile navigation** — `SocialProfileScreen` for the authenticated user's own pet has no clear entry point
7. **Surface ActivityScreen and OffersScreen** — add badges/icons in shell or hub for discoverability
8. **Audit `pet_care_gamification` table** — either wire it to `gamified_care_ui.dart` or drop the table
9. **Investigate `mark_story_viewed` RPC** — no call site found; story view counts may be silently untracked

### 🟢 Low Priority
10. **Drop `waitlist` table** — completely orphaned, 6 columns, no code references
11. **Verify `ensure_chat_thread_for_match` vs `ensure_direct_chat_thread`** — DB has both; only one is called. Consider dropping the unused RPC.
12. **Review `get_care_dashboard_snapshot` dual overload** — two DB functions with same name but different signatures; confirm both are intentionally called