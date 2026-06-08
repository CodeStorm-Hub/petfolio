# Complete breakdown of the `lib/` directory:

---

## `lib/` — Top Level

| File | Purpose |
|---|---|
| [`main.dart`](lib/main.dart) | App entry point — initializes Supabase, Firebase, Stripe, Riverpod `ProviderScope`, and runs the app |
| [`firebase_options.dart`](lib/firebase_options.dart) | Auto-generated Firebase config per platform |
| `integration_test_gate_*.dart` | Swapped at compile-time — `_io` wires real integration test bindings, `_stub` is a no-op for prod builds |
| `marionette_debug_gate_*.dart` | Same swap pattern — `_io` enables Marionette MCP debug hooks, `_stub` is no-op for prod |

---

## `lib/core/` — Shared Infrastructure

Everything here is feature-agnostic and reused across the whole app.

### `core/errors/`
- [`app_exception.dart`](lib/core/errors/app_exception.dart) — Base exception class for typed error handling across repositories

### `core/firebase/`
FCM push notification system, split by responsibility:

| File | Role |
|---|---|
| `fcm_service.dart` | Initialises FCM, requests permissions, subscribes to topics |
| `fcm_token_repository.dart` | Saves/refreshes the device FCM token to Supabase |
| `fcm_message_router.dart` | Routes incoming push payloads to the right feature (care, chat, social…) |
| `fcm_push_display.dart` | Renders local foreground notifications via `flutter_local_notifications` |
| `fcm_lifecycle.dart` | Handles app-open from a notification tap (deep-link logic) |
| `firebase_env.dart` | Reads `FIREBASE_*` dart-defines |

### `core/models/`
- [`pet.dart`](lib/core/models/pet.dart) — Lightweight shared Pet model (used by navigation/shell before the full pet_profile feature loads)

### `core/navigation/`
| File | Role |
|---|---|
| [`router.dart`](lib/core/router.dart) | **Central GoRouter** — assembles all feature route lists, defines the shell scaffold |
| `app_shell_routes.dart` | Bottom-nav shell with 5 tabs (Home, Social, Match, Care, Market) |
| `router_notifier.dart` | Riverpod `Notifier` that triggers GoRouter refresh on auth state change |
| `navigator_keys.dart` | Global navigator keys for imperative navigation (e.g. from FCM callbacks) |
| `route_overlay_dismissal.dart` | Pops modals when user navigates away |
| `router_error_screen.dart` | 404/error fallback screen |

### `core/platform/`
Platform abstractions using the `_io` / `_web` / `_stub` split pattern — the right file is imported conditionally at build time:

| Abstraction | What it does |
|---|---|
| `media_picker_*.dart` | Camera/gallery — delegates to `image_picker` on mobile, file picker on web |
| `platform_notifications_*.dart` | Local notification scheduling (uses `flutter_local_notifications` on IO, no-op on web) |
| `platform_payments.dart` | Stripe payment sheet trigger |
| `platform_location.dart` | GPS location (uses `geolocator`) |
| `platform_services.dart` | Umbrella init that bootstraps all platform services at startup |
| `web_checkout_redirect_*.dart` | On web, redirects back after Stripe hosted checkout |
| `web_push_registration_*.dart` | Registers the browser for web push (FCM web) |
| `web_push_environment_*.dart` | Reads VAPID keys for web push |
| `web_image_cache.dart` | Preloads images on web (avoids CORS flicker) |
| `web_app_url.dart` | Returns current page URL on web (used for Stripe redirect) |
| `care_fcm_reminder_sync.dart` | Syncs care task schedules → FCM scheduled notifications |

### `core/services/`
| File | Role |
|---|---|
| `location_service.dart` + `location_providers.dart` | Riverpod-wrapped GPS service |
| `notification_service.dart` | High-level notification orchestrator (wraps platform + FCM) |
| `stripe_init_service.dart` | Initialises `flutter_stripe` with publishable key |
| `secure_storage_service.dart` | Thin wrapper around `flutter_secure_storage` |
| `prefs_schema.dart` | Typed keys for `shared_preferences` |

### `core/theme/`
| File | Role |
|---|---|
| `app_colors.dart` | All brand color tokens |
| `app_theme.dart` | Material 3 `ThemeData` factory using `app_colors` |
| `theme.dart` | Barrel re-export |
| `theme_notifier.dart` | Riverpod notifier for light/dark toggle |

### `core/widgets/`
Shared, reusable UI components used across features:

| Widget | Description |
|---|---|
| `app_shell.dart` | Bottom nav scaffold wrapper |
| `app_header.dart` | Consistent top app bar |
| `app_bottom_sheet.dart` | Styled modal bottom sheet base |
| `app_snack_bar.dart` | Themed snackbar helper |
| `app_tutorial_overlay.dart` | First-run tooltip overlay system |
| `pet_avatar.dart` | Circular pet photo with fallback initials |
| `petfolio_network_image.dart` | Cached network image with shimmer placeholder |
| `petfolio_empty_state.dart` | Lottie + text empty state widget |
| `skeleton_loader.dart` | Shimmer skeleton for loading states |
| `tail_wag_loader.dart` | Custom paw-print loading animation |
| `glass_card.dart` | Frosted-glass card container |
| `pf_card.dart` | Standard M3 card with brand radius |
| `pf_stat_tile.dart` | Stat row (label + value) |
| `pf_achievement_tile.dart` | Achievement/badge tile |
| `primary_pill_button.dart` | Main CTA button (pill shape) |
| `paw_toggle.dart` | Paw-icon toggle switch |
| `bone_slider.dart` | Themed slider (bone shape) |
| `responsive_layout.dart` | Breakpoint layout helper |
| `wave_header.dart` | Decorative wave header painter |
| `dashed_circle_painter.dart` / `dashed_rect_painter.dart` | Custom painters for dashed borders |

---

## `lib/features/` — Feature Modules

Every feature follows the same internal structure:
```
feature_name/
  feature_routes.dart       ← GoRouter routes for this feature
  index.dart                ← Barrel exports
  data/
    models/                 ← Freezed + JsonSerializable DTOs
    repositories/           ← Supabase queries
  presentation/
    controllers/            ← Riverpod AsyncNotifiers / providers
    screens/                ← Full-page widgets
    widgets/                ← Feature-specific reusable widgets
```

---

### `features/auth/` — Authentication
**Flow:** Login → Registration → GoRouter redirects unauthenticated users here

| File | Role |
|---|---|
| `auth_repository.dart` | Supabase `signIn`, `signUp`, `signOut`, `onAuthStateChange` stream |
| `auth_controller.dart` | Riverpod notifier wrapping auth repo; feeds `router_notifier.dart` |
| `login_screen.dart` | Email/password + Google OAuth login UI |
| `registration_screen.dart` | Multi-step signup form |
| `auth_widgets.dart` | Shared form fields, social login buttons |

**Connection:** `auth_controller` → `router_notifier` → `router.dart` (redirects)

---

### `features/pet_profile/` — Pet Management & Onboarding
**Flow:** After auth, user creates/selects a pet — stored as "active pet" shared app-wide

| File | Role |
|---|---|
| `pet.dart` (model) | Full Pet DTO (species, breed, birthday, photo, visibility flags) |
| `pet_repository.dart` | CRUD for `pets` Supabase table |
| `pet_list_controller.dart` | Stream of the user's pets list |
| `active_pet_controller.dart` | **Global state** — currently selected pet, read by most features |
| `edit_profile_controller.dart` | Handles pet photo upload + field edits |
| `discovery_visibility_controller.dart` | Toggles whether pet appears in matching discovery |
| `onboarding_screen.dart` | First-run pet creation wizard |
| `manage_pets_screen.dart` | Switch/add/delete pets |
| `pet_profile_screen.dart` | Public pet profile (viewed by others) |
| `edit_profile_screen.dart` | Edit pet details |
| `breed_identification_service.dart` | Calls NVIDIA Vision API to identify breed from photo |
| `breed_identifier_widget.dart` | Camera capture + breed ID result card |
| `pet_switcher_sheet.dart` | Bottom sheet to swap active pet |
| `pet_activity_options.dart` | Activity level selector chips |

**Connection:** `active_pet_controller` is a global dependency — `care`, `matching`, `social`, `marketplace` all read from it.

---

### `features/home/` — Hub Home Screen
| File | Role |
|---|---|
| `hub_home_screen.dart` | Bento-grid home with quick-access tiles to all features |
| `all_features_sheet.dart` | "See all" sheet listing every app feature |

---

### `features/social/` — Social Feed
**Like Instagram for pets**

| File | Role |
|---|---|
| `feed_post.dart` / `comment.dart` / `story.dart` | Post, comment, story DTOs |
| `pet_stats.dart` | Follower/following counts |
| `pet_search_result.dart` | Search result DTO |
| `app_notification.dart` | In-app notification DTO (likes, follows, comments) |
| `social_repository.dart` | Feed posts CRUD, likes, search, follow/unfollow |
| `comment_repository.dart` | Comments CRUD |
| `story_repository.dart` | Stories upload + expiry |
| `notification_repository.dart` | Notification read/unread stream |
| `social_controller.dart` | Feed pagination provider |
| `social_profile_controller.dart` | Another user's profile + posts |
| `create_post_controller.dart` | Post creation with media upload |
| `comment_controller.dart` | Comment list + add |
| `follow_controller.dart` | Follow/unfollow state |
| `story_controller.dart` | Story upload + view tracking |
| `notification_controller.dart` | Notification list + mark-read |
| `social_screen.dart` | Main feed (stories row + posts list) |
| `social_profile_screen.dart` | Another pet's profile page |
| `create_post_screen.dart` | Post composer with media |
| `create_story_screen.dart` | Story camera/gallery picker |
| `post_detail_screen.dart` | Single post with comments |
| `story_viewer_screen.dart` | Full-screen story with progress bar |
| `notifications_screen.dart` | Tabbed notification center |
| `post_comments_bottom_sheet.dart` | Slide-up comment sheet |
| `reaction_burst.dart` | Animated heart burst on like |

---

### `features/matching/` — Pet Matching (Tinder-style)
**Flow:** Swipe on discovery candidates → mutual match → chat

| File | Role |
|---|---|
| `discovery_candidate.dart` / `pet_swipe.dart` / `pet_mutual_match.dart` | Match DTOs |
| `chat_message.dart` / `chat_thread.dart` / `match_inbox_item.dart` | Chat DTOs |
| `pet_geo_point.dart` | Location-based filtering DTO |
| `matching_discovery_row.dart` | Raw Supabase row from the discovery RPC |
| `matching_supabase_data_source.dart` | Raw Supabase calls (RPC `get_discovery_candidates`, swipe upsert) |
| `matching_repository.dart` | Business logic on top of data source |
| `discovery_controller.dart` | Swipe card deck state |
| `discovery_candidates_controller.dart` | Fetches + paginates candidates |
| `match_preference_controller.dart` + `match_preferences_state.dart` | Filter prefs (distance, species, size) |
| `matches_inbox_controller.dart` | List of mutual matches |
| `chat_conversation_controller.dart` | Real-time chat via Supabase Realtime |
| `mutual_match_realtime_provider.dart` | Stream that fires when a new mutual match occurs |
| `matching_screen.dart` | Swipe card stack UI |
| `matches_inbox_screen.dart` | List of matches |
| `chat_screen.dart` | Conversation screen |
| `match_celebration_overlay.dart` | Confetti animation on new match |
| `match_preferences_sheet.dart` | Filter sheet |
| `matching_navigation.dart` | Internal nav helper (swipe → inbox → chat) |

---

### `features/care/` — Pet Care Dashboard
**The health tracking core: tasks, streaks, nutrition, vitals, medical records, walk tracking, AI routines**

| File | Role |
|---|---|
| `care_task.dart` / `care_streak.dart` | Daily task + streak DTOs |
| `medical_record.dart` | Vet visit / vaccination DTO |
| `pet_awards_summary.dart` / `pet_level.dart` | Gamification: XP, level, awards |
| `care_repository.dart` | Tasks CRUD + streak calculation |
| `health_repository.dart` | Medical records CRUD |
| `pet_care_repository.dart` | Umbrella repo coordinating tasks + streaks |
| `vitals_repository.dart` | Weight, temperature, heart-rate time series |
| `care_recommendation_service.dart` | Calls NVIDIA API for AI-generated care routine suggestions |
| `care_dashboard_controller.dart` | Home care screen state (today's tasks, streak, level) |
| `care_streak_stream_provider.dart` | Real-time streak stream |
| `health_vault_controller.dart` | Medical records list + upload |
| `nutrition_controller.dart` | Meal log + nutrition goals |
| `vitals_controller.dart` | Vitals chart data |
| `ai_routine_controller.dart` | Triggers + caches AI routine generation |
| `pet_awards_provider.dart` | XP / awards stream |
| `care_screen.dart` | Main care dashboard (task checklist, streak banner, gamified UI) |
| `medical_vault_screen.dart` | Medical records list + PDF viewer |
| `nutrition_screen.dart` | Meal tracker |
| `walk_tracking_screen.dart` | GPS walk recorder with map |
| `gamified_care_ui.dart` | XP bar, level badge, achievement tiles |
| `routine_recommendation_sheet.dart` | AI routine result sheet |
| `vitals_chart_widget.dart` | Line chart for vitals over time |
| `web_push_enable_banner.dart` | Prompts web users to enable push reminders |
| `care_scheduled_time.dart` | Time parsing util for task schedules |

---

### `features/marketplace/` — E-Commerce
**Full buyer+vendor marketplace with Stripe, KYC, cart, orders, reviews**

#### Data Models
| Model | Description |
|---|---|
| `product.dart` | Product DTO (name, price, images, variants, inventory) |
| `shop.dart` | Shop DTO (name, logo, verified status) |
| `cart_item.dart` | Cart line item DTO |
| `marketplace_order.dart` | Order DTO (items, status, payment method) |
| `product_review.dart` | Star rating + text review DTO |
| `user_address.dart` | Delivery address DTO |
| `vendor_ledger.dart` | Vendor earnings / payout DTO |
| `promo.dart` | Promo code / discount DTO |

#### Repositories
| Repository | Supabase Table(s) |
|---|---|
| `product_repository.dart` | `products`, search RPC |
| `shop_repository.dart` | `shops` |
| `order_repository.dart` | `orders`, `order_items` |
| `address_repository.dart` | `user_addresses` |
| `product_review_repository.dart` | `product_reviews` |
| `promo_repository.dart` | `promos` |
| `kyc_repository.dart` | `kyc_documents`, Stripe Connect |
| `vendor_product_repository.dart` | Vendor-scoped product CRUD |

#### Controllers (Riverpod)
| Controller | Role |
|---|---|
| `cart_controller.dart` | Cart state (add/remove/quantity) |
| `checkout_controller.dart` | Stripe payment intent + order creation |
| `buyer_orders_controller.dart` | Buyer's order history + status |
| `shop_list_controller.dart` | Browse all shops |
| `shop_products_controller.dart` | Products in a specific shop |
| `product_list_controller.dart` | Category/search filtered products |
| `my_shop_controller.dart` | Vendor's own shop state |
| `vendor_orders_controller.dart` | Incoming orders for vendor |
| `vendor_products_controller.dart` | Vendor's product list |
| `address_controller.dart` | Saved addresses CRUD |
| `promo_controller.dart` | Promo code validation |
| `edit_shop_controller.dart` | Shop settings edit |
| `manual_kyc_controller.dart` | KYC doc upload state |
| `product_reviews_controller.dart` | Reviews list + submit |
| `deletion_request_controller.dart` | Vendor shop deletion request |

#### Screens — Customer
| Screen | Description |
|---|---|
| `marketplace_screen.dart` | Home: featured shops, categories, search |
| `marketplace_categories_screen.dart` | Browse by category |
| `shop_storefront_screen.dart` | Shop page with products grid |
| `shop_intro_screen.dart` | Vendor intro / about page |
| `product_detail_screen.dart` | Product carousel, variants, reviews, dual CTA |
| `cart_screen.dart` | Cart with stacked vendor cards, savings banner |
| `order_confirmation_screen.dart` | Post-payment success + receipt |
| `buyer_order_list_screen.dart` | Order history list |
| `buyer_order_detail_screen.dart` | Single order detail + tracking |

#### Screens — Vendor
| Screen | Description |
|---|---|
| `shop_setup_screen.dart` | Create new shop wizard |
| `seller_dashboard_screen.dart` | Vendor home: revenue, orders, products |
| `add_edit_product_screen.dart` | Product form (images, variants, price) |
| `vendor_product_list_screen.dart` | Vendor's product management list |
| `vendor_order_queue_screen.dart` | Incoming orders queue |
| `vendor_order_detail_screen.dart` | Order detail + fulfill/reject actions |
| `edit_shop_screen.dart` | Edit shop info/branding |
| `stripe_onboarding_screen.dart` | Stripe Connect onboarding webview |
| `manual_kyc_screen.dart` | Upload ID docs for KYC verification |

---

### `features/communities/` — Pet Communities
| File | Role |
|---|---|
| `community.dart` / `community_post.dart` | Community + post DTOs |
| `community_repository.dart` | Join/leave, post, list communities from Supabase |
| `communities_controller.dart` | Community list + membership state |
| `communities_screen.dart` | Browse/search communities |
| `community_detail_screen.dart` | Community feed + member list |
| `create_community_sheet.dart` | Create new community bottom sheet |

---

### `features/appointments/` — Vet Appointments
| File | Role |
|---|---|
| `appointment.dart` | Appointment DTO (vet, date, notes, status) |
| `appointment_repository.dart` | Supabase `appointments` CRUD |
| `appointment_controller.dart` | Appointment list provider |
| `appointments_screen.dart` | Calendar view + appointment list |

---

### `features/admin/` — Admin Panel
| File | Role |
|---|---|
| `admin_dashboard_controller.dart` | Dashboard stats (users, orders, revenue) |
| `moderation_controller.dart` | Review/remove flagged posts |
| `kyc_review_controller.dart` | Approve/reject vendor KYC documents |
| `cod_orders_controller.dart` | Cash-on-delivery order management |
| `ledger_controller.dart` | Platform financial ledger |
| `shop_deletion_controller.dart` | Process vendor shop deletion requests |
| `admin_auth_controller.dart` | Admin-only auth gate |
| `admin_layout.dart` | Tab-based admin layout |
| `admin_screen.dart` | Admin entry screen |
| Various `*_tab.dart` widgets | Each admin tab: dashboard, moderation, KYC, orders, shops, ledger |

---

### `features/activity/` — Activity Hub
| File | Role |
|---|---|
| `activity_screen.dart` | Timeline of cross-feature activity (walk records, care tasks done, matches) |

---

### `features/offers/` — Promotions
| File | Role |
|---|---|
| `offers_screen.dart` | Promo codes and active discount offers |

---

### `features/settings/` — Settings
| File | Role |
|---|---|
| `settings_screen.dart` | Profile settings, notification preferences, theme toggle, account management |

---

## How Everything Connects

```
main.dart
  └─ ProviderScope (Riverpod root)
       └─ MaterialApp.router (GoRouter from core/router.dart)
            ├─ router_notifier ←── auth_controller ←── auth_repository (Supabase auth)
            └─ AppShell (bottom nav)
                 ├─ [Tab 1] Home ──────── hub_home_screen
                 ├─ [Tab 2] Social ─────── social_screen ←── social_controller ←── social_repository
                 ├─ [Tab 3] Match ──────── matching_screen ←── discovery_controller ←── matching_repository
                 ├─ [Tab 4] Care ───────── care_screen ←── care_dashboard_controller ←── care_repository
                 └─ [Tab 5] Marketplace ── marketplace_screen ←── shop_list_controller ←── shop_repository

Global state shared across ALL features:
  active_pet_controller (pet_profile) → read by care, matching, social, marketplace
  auth_controller (auth) → read by router, all repositories for user ID
  theme_notifier (core/theme) → read by MaterialApp
```

**Key dependency chain per feature:**
`Screen → Controller (Riverpod AsyncNotifier) → Repository (Supabase client) → Supabase DB`

The `platform/` layer abstracts anything that differs between mobile and web (notifications, payments, camera, location) so screens and controllers never import `dart:io` directly.