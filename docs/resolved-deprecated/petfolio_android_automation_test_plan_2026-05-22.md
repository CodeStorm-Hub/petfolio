# PetFolio Android Automation Test Plan

Date: 2026-05-22  
Repo: `G:\GitHub\petfolio`  
Scope: `lib/`, connected Android emulator, hosted Supabase project `jqyjvhwlcqcsuwcqgcwf`

## Current Runtime Facts

- Connected emulator: `emulator-5554` from `adb devices`.
- Android application id: `com.example.petfolio`.
- App entrypoint: `lib/main.dart`.
- Required runtime defines: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `STRIPE_PUBLISHABLE_KEY`.
- Navigation source of truth: `lib/core/router.dart`.
- Current test coverage: `test/care_scheduled_time_test.dart`, `test/care_task_model_crud_test.dart`, `test/widget_test.dart`; no `integration_test/` suite is present.
- Automation should use UI-tree-derived coordinates or Flutter integration-test finders, not screenshot-based hardcoded coordinates.

## Feature And Module Inventory From `lib/`

| Feature | Main responsibility | Key UI screens | Data/backend surfaces |
| --- | --- | --- | --- |
| `auth` | Login, registration, auth state redirect | `/login`, `/register` | Supabase Auth via `AuthRepository`; router guards authenticated and unauthenticated routes |
| `pet_profile` | Active pet, onboarding, profile, edit profile, pet switcher, manage pets | `/home`, `/onboarding`, `/pets/manage`, `/pet/:petId/edit` | `pets`, `health_vitals`, `pets` storage bucket, local active pet preference |
| `care` | Daily task dashboard, streaks, checklist sync, nutrition, medical vault | `/care`, `/care/nutrition`, `/care/medical-vault` | `care_tasks`, `care_logs`, `care_streaks`, `pet_badges`, `health_logs`, `medical_vault`, `medical-documents` bucket, `check_daily_completion`, `get_care_dashboard_snapshot` |
| `social` | Feed, posts, comments, likes, follows, reports, notifications | `/social`, `/social/create`, `/social/post/:postId`, `/social/notifications`, `/social/profile/:petId` | `posts`, `post_likes`, `comments`, `pet_follows`, `reported_posts`, `notifications`, `post-images` bucket, `get_pet_stats`, realtime feed/notifications |
| `matching` | Discovery deck, preferences, swipes, matches inbox, chat | `/matching`, `/matching/inbox`, `/matching/chat/:threadId` | `pets`, `swipes`, `matches`, `match_requests`, `chat_threads`, `chat_messages`, `matching_discovery_candidates`, `get_match_inbox`, `ensure_chat_thread_for_match`, `set_pet_location_point`, realtime match/chat streams |
| `marketplace` | Product discovery, cart, checkout, buyer orders, shop storefront, seller setup, products, orders, KYC | `/marketplace`, `/marketplace/product/:id`, `/marketplace/cart`, `/marketplace/order/:id`, `/profile/orders`, `/profile/orders/:id`, `/shop/:id`, `/seller`, `/seller/setup`, `/seller/onboarding`, `/seller/edit-shop`, `/seller/kyc`, `/seller/products`, `/seller/products/add`, `/seller/products/:id/edit`, `/seller/orders`, `/seller/orders/:id` | `products`, `shops`, `marketplace_orders`, `vendor_ledgers`, `shop_deletion_requests`, `inventory_reservations`, `marketplace-images`, `shops`, `kyc-documents`, `process_checkout`, `vendor_update_order`, `request_shop_deletion`, Edge Functions |
| `admin` | Admin-only dashboard, KYC review, ledger, COD orders, moderation, shop deletion | `/admin` with internal tabs | `shops`, `reported_posts`, `shop_deletion_requests`, `marketplace_orders`, `vendor_ledgers`, `audit_logs`, `approve_vendor_kyc`, `reject_vendor_kyc`, `resolve_reported_post`, `resolve_shop_deletion` |

## Route Inventory

### Shell Routes

These routes share the app shell and bottom navigation on phone-sized layouts:

| Route | Screen | Primary automation coverage |
| --- | --- | --- |
| `/home` | `PetProfileScreen` | Header, pet switcher, profile tabs, scroll to bottom of Overview/Health/Care/Awards |
| `/care` | `CareScreen` | Daily care dashboard, date selector, task toggles, add/edit/delete task, nutrition and medical-vault banners, scroll to bottom |
| `/social` | `SocialScreen` | Feed load, create post entry, messages action, like/comment/profile/report actions, scroll feed |
| `/matching` | `MatchingScreen` | Discovery deck, preferences sheet, pass/greet/like/super actions, inbox navigation, location-denied/service-off states |
| `/marketplace` | `MarketplaceScreen` | Search, categories, shop discovery, product cards, cart/admin actions, scroll product/shop lists |

### Full-Screen Routes

| Route | Screen | Primary automation coverage |
| --- | --- | --- |
| `/login` | `LoginScreen` | Email/password entry, validation errors, successful login |
| `/register` | `RegistrationScreen` | Account creation validation; destructive only in disposable QA project |
| `/onboarding` | `OnboardingScreen` | First pet creation, multi-step form, add-another-pet mode |
| `/pets/manage` | `ManagePetsScreen` | Reorder, active pet selection, archive/delete confirmation, add pet, edit pet entry |
| `/pet/:petId/edit` | `EditProfileScreen` | Profile fields, avatar, health metadata, public/discoverable toggles |
| `/care/nutrition` | `NutritionScreen` | Meal logging, hydration, supplements, notes, scroll all sections |
| `/care/medical-vault` | `MedicalVaultScreen` | Add/edit/delete medical record, reminders, document upload path |
| `/social/create` | `CreatePostScreen` | Text/media post creation and validation |
| `/social/post/:postId` | `PostDetailScreen` | Comment, like, report, delete/confirm where owned |
| `/social/notifications` | `NotificationsScreen` | Notification list, mark/read behavior if exposed |
| `/social/profile/:petId` | `SocialProfileScreen` | Follow/unfollow, stats, owner/public post list |
| `/matching/inbox` | `MatchesInboxScreen` | New matches, conversation list, discover action |
| `/matching/chat/:threadId` | `ChatScreen` | Message input/send, realtime update, scroll conversation |
| `/marketplace/product/:id` | `ProductDetailScreen` | Quantity, subscription toggle if present, add to cart |
| `/marketplace/cart` | `CartScreen` | Per-shop cart grouping, quantity, remove, checkout per shop |
| `/marketplace/order/:id` | `OrderConfirmationScreen` | Order success state, navigation to orders/marketplace |
| `/marketplace/orders/:id` and `/profile/orders/:id` | `BuyerOrderDetailScreen` | Buyer status timeline, tracking, cancel if supported |
| `/profile/orders` | `BuyerOrderListScreen` | Order list states and detail navigation |
| `/shop/:id` | `ShopStorefrontScreen` | Shop header, product list, product detail links |
| `/seller` | `SellerDashboardScreen` | Seller KPIs, shop setup/onboarding/product/order links, deletion request |
| `/seller/setup` | `ShopSetupScreen` | Shop creation form and validation |
| `/seller/onboarding` | `StripeOnboardingScreen` | External Stripe onboarding launch/return handling |
| `/seller/edit-shop` | `EditShopScreen` | Branding, contact info, policies tabs and save |
| `/seller/kyc` | `ManualKycScreen` | KYC form, document upload, submit |
| `/seller/products` | `VendorProductListScreen` | Product list, edit, delete, add |
| `/seller/products/add` | `AddEditProductScreen` | Product creation form, category, stock, active switch |
| `/seller/products/:id/edit` | `AddEditProductScreen` | Product update and validation |
| `/seller/orders` | `VendorOrderQueueScreen` | Vendor order list and filters |
| `/seller/orders/:id` | `VendorOrderDetailScreen` | Status updates, tracking fields, refund/cancel edge cases |
| `/admin` | `AdminScreen` / `AdminLayout` | Admin tabs: Dashboard, KYC, Ledger, Orders, Moderation, Shops |

## UI Component And Action Inventory

### Shared Components

- `AppHeader`: active pet profile button (`app_header_pet_profile`), pet switcher button (`app_header_pet_switcher`), optional action buttons.
- `PetSwitcherSheet`: add pet (`pet_switcher_add_pet`), manage pets (`pet_switcher_manage`), sign out (`pet_switcher_sign_out`), active pet rows.
- `AppShell`: bottom navigation keys `shell_nav__home`, `shell_nav__care`, `shell_nav__social`, `shell_nav__matching`, `shell_nav__marketplace`.
- Common states to assert on every major screen: loading skeleton, empty state, populated state, error retry, snackbars.

### Stable Automation Anchors Already In Code

- Home/profile: `home_action_outdoor`, `home_action_notifications`.
- Care: `care_fab_add_task`, `care_action_outdoor`, `care_date_<yyyy-mm-dd>`, `care_task_menu_<id>`, `care_task_check_<id>`, `care_medical_vault_banner`, `care_nutrition_banner`.
- Matching: `match_action_inbox`, `match_action_filter`, `match_action_pass`, `match_action_greet`, `match_action_like`, `match_action_super`, `match_prefs_close`, `match_prefs_distance_slider`, `match_prefs_age_slider`, `matches_inbox_discover`, `new_match_<id>`, `conversation_<id>`, `chat_message_input`, `chat_send_button`.
- Pet management: `manage_pets_back`, `manage_pet_row_<id>`, `manage_pet_menu_<id>`, `manage_pets_add_button`, `manage_pets_empty_add`.
- Marketplace: `market_action_admin`, `market_action_cart`.
- Social: `social_action_messages`, post/comment send key `send`.

## Live Supabase Inventory

The hosted project is reachable through Supabase MCP. Current live table inventory:

| Table | Rows | RLS |
| --- | ---: | --- |
| `users` | 9 | on |
| `pets` | 19 | on |
| `care_logs` | 29 | on |
| `health_vitals` | 3 | on |
| `posts` | 10 | on |
| `match_requests` | 16 | on |
| `chat_threads` | 15 | on |
| `chat_messages` | 32 | on |
| `marketplace_orders` | 8 | on |
| `products` | 11 | on |
| `post_likes` | 26 | on |
| `care_tasks` | 22 | on |
| `health_logs` | 14 | on |
| `medical_vault` | 1 | on |
| `pet_follows` | 0 | on |
| `care_streaks` | 1 | on |
| `pet_badges` | 2 | on |
| `comments` | 27 | on |
| `notifications` | 4 | on |
| `pet_care_gamification` | 1 | on |
| `swipes` | 105 | on |
| `matches` | 17 | on |
| `follows` | 4 | on |
| `shops` | 6 | on |
| `vendor_ledgers` | 0 | on |
| `reported_posts` | 0 | on |
| `audit_logs` | 6 | on |
| `inventory_reservations` | 0 | on |
| `shop_deletion_requests` | 2 | on |

Storage buckets:

| Bucket | Public | Use in app |
| --- | --- | --- |
| `kyc-documents` | no | Seller KYC documents and admin signed URLs |
| `marketplace-images` | yes | Product images |
| `medical-documents` | no | Medical vault document uploads |
| `pets` | yes | Pet avatars |
| `post-images` | yes | Social post media |
| `shops` | yes | Shop branding images |

Public RPCs/functions used or relevant:

- Care: `check_daily_completion`, `get_care_dashboard_snapshot`.
- Social: `get_pet_stats`, `get_or_create_social_thread`.
- Matching/chat: `matching_discovery_candidates`, `get_match_inbox`, `ensure_chat_thread_for_match`, `set_pet_location_point`.
- Marketplace/order: `process_checkout`, `cancel_order`, `confirm_order_inventory`, `release_order_inventory`, `vendor_update_order`.
- Admin/moderation: `approve_vendor_kyc`, `reject_vendor_kyc`, `resolve_reported_post`, `request_shop_deletion`, `resolve_shop_deletion`.
- Triggers/helpers: `handle_new_chat_message`, `handle_post_comment_sync`, `handle_post_like_sync`, `handle_updated_at`, `set_updated_at`, `is_admin`, `rls_auto_enable`.

Edge Functions:

| Function | JWT | Automation handling |
| --- | --- | --- |
| `create-payment-intent` | required | Use Stripe test mode; assert PaymentSheet launch and order state without real charges |
| `stripe-onboard-vendor` | required | Treat as external handoff; verify URL generation and return behavior |
| `stripe-webhook` | not required | Do not hit directly from UI tests; verify effects through order/shop status after Stripe test events |

## Test Data Policy

Use real app data structures, but isolate test rows.

1. Prefer a Supabase branch or dedicated QA project for full destructive coverage.
2. If testing against `jqyjvhwlcqcsuwcqgcwf`, create named QA users, pets, shops, products, posts, and orders with a predictable prefix such as `QA_AUTOMATION_20260522`.
3. Split automation into:
   - Read-only traversal: safe on hosted data.
   - Reversible mutations: create/edit/delete only rows owned by QA users.
   - External money/KYC flows: Stripe test mode only; no real vendor onboarding or irreversible admin approvals without a fixture reset.
4. Before each run, seed or verify:
   - Buyer user with at least one active pet.
   - Seller user with shop, products, one pending KYC state, and orders.
   - Admin user with `app_metadata.role = admin`.
   - Two matching pets with discoverable enabled and non-null locations.
   - Existing feed post with comments and a separate post owned by the QA user for delete/report testing.
5. After each run, clean by QA prefix and IDs, not by broad deletes.

## Automation Harness Plan

### Phase 0: Environment And Health Checks

- Run `adb devices`; require `emulator-5554` in `device` state.
- Confirm emulator network can resolve `jqyjvhwlcqcsuwcqgcwf.supabase.co`; prior sessions saw emulator DNS failure, so this must fail fast.
- Build with `flutter run` or `flutter test integration_test` using `--dart-define-from-file=.env`.
- Clear app data before clean-room login: `adb -s emulator-5554 shell pm clear com.example.petfolio`.
- Capture logcat per scenario and save screenshots on failure.
- Fail the run if login credentials are supplied but the app does not reach shell landmarks such as the `Pets`, `Care`, `Social`, `Match`, and `Market` navigation destinations.

### Phase 1: Read-Only Full Navigation Traversal

Goal: prove every route opens, renders its non-error state, and can scroll to the end.

Flow:

1. Launch app and login as QA buyer.
2. Visit `/home`, `/care`, `/social`, `/matching`, `/marketplace` through bottom navigation.
3. For each shell screen:
   - Assert header and active pet switcher.
   - Dump UI tree.
   - Scroll to bottom until no further movement is detected.
   - Tap all safe navigation links and return.
4. Deep-link or navigate to every full-screen route that has available fixture IDs.
5. For screens with tabs, visit each tab and scroll each tab body to bottom.
6. Record missing routes, empty states, permission blocks, and unhandled exceptions.

### Phase 2: Auth And First-Run Scenarios

Scenarios:

- Existing buyer logs in, reaches `/home`, signs out from pet switcher, returns to `/login`.
- Invalid login shows validation/server error and does not enter the shell.
- New disposable user registration reaches `/onboarding`.
- First pet onboarding creates a pet and lands on `/care?onboardingComplete=1`, then URL normalizes to `/care`.
- Add-another-pet mode from pet switcher opens `/onboarding?mode=add` and returns to the prior workflow after save.

### Phase 3: Pet Profile And Pet Management

Scenarios:

- On `/home`, traverse Overview, Health, Care, Awards tabs and scroll each tab to bottom.
- Open pet switcher, switch active pet, verify downstream screens use the new active pet.
- Manage pets:
  - Open `/pets/manage`.
  - Verify row rendering and overflow menus.
  - Add pet via `manage_pets_add_button`.
  - Edit pet fields via `/pet/:petId/edit`.
  - Toggle public/discoverable settings.
  - Archive/delete only QA-created secondary pets and verify confirmation dialogs.
- Edit profile:
  - Change name, breed, bio, weight, date of birth, gender/activity if available.
  - Upload avatar only from a test asset if the harness supports file injection.
  - Verify saved changes survive app restart.

### Phase 4: Care, Nutrition, And Medical Vault

Scenarios:

- Care dashboard:
  - Select dates with `care_date_<yyyy-mm-dd>`.
  - Toggle an incomplete task with `care_task_check_<id>` and verify optimistic state plus backend persistence in `care_logs`.
  - Open task menu, edit a QA task, delete a QA task, and verify list refresh.
  - Use `care_fab_add_task` to create feeding, medication, grooming, exercise, or custom tasks.
  - Scroll past streaks, badges, today plan, banners, and bottom resources.
- Nutrition:
  - Open `/care/nutrition` from banner and deep link.
  - Add meal/water/supplement note with realistic values.
  - Validate empty required fields and long notes.
  - Scroll to all sections and return to care.
- Medical vault:
  - Open `/care/medical-vault`.
  - Create vaccination/medication/visit record.
  - Toggle reminder.
  - Edit and delete the QA-created record.
  - For document uploads, use a small test PDF/image and verify storage path in `medical-documents`.

### Phase 5: Social Feed

Scenarios:

- Feed:
  - Load `/social`, scroll several posts, open post detail, return.
  - Like and unlike a post; verify count and `post_likes`.
  - Open author profile and follow/unfollow.
  - Tap Messages header action and verify navigation to `/matching`.
- Create post:
  - Open `/social/create`.
  - Submit empty content and assert validation.
  - Create a QA post with realistic text and optional image.
  - Verify the post appears in feed and detail.
- Comments:
  - Open post detail, add comment, delete own comment if exposed, verify realtime/list update.
- Notifications:
  - Open `/social/notifications`, scroll list, verify empty/populated states.
- Moderation:
  - Report a non-owned QA post and verify `reported_posts` row.

### Phase 6: Matching And Chat

Preconditions:

- QA actor pet is discoverable.
- Candidate pets have `is_discoverable = true` and non-null `location`.
- Emulator location permission and service state are controlled.

Scenarios:

- Matching deck:
  - Open `/matching`; handle location prompt.
  - If location denied/services off, verify the empty/error state.
  - With location enabled, verify cards from `matching_discovery_candidates`.
  - Use preferences sheet: move distance and age sliders, select species where available, close, verify deck refresh does not thrash.
  - Perform pass, greet, like, and super actions on fixture candidates.
- Mutual match:
  - Seed reciprocal swipe or use second QA user to create match.
  - Verify celebration overlay and realtime insert behavior.
- Inbox:
  - Open `/matching/inbox`, inspect new matches and conversations.
  - Open `/matching/chat/:threadId`.
- Chat:
  - Send realistic message with `chat_message_input` and `chat_send_button`.
  - Verify message appears, persists in `chat_messages`, and realtime updates after second-user reply.

### Phase 7: Marketplace Buyer

Scenarios:

- Marketplace discovery:
  - Open `/marketplace`, search products, filter/category if exposed, scroll products and shops.
  - Open product detail from a product card.
  - Open shop storefront from Discover Shops.
- Product detail/cart:
  - Change quantity.
  - Toggle subscription if visible.
  - Add to cart.
  - Open cart via `market_action_cart`.
  - Verify per-shop grouping (`itemsByShop`) and quantity/remove behavior.
- Checkout:
  - Start checkout for one shop.
  - Use Stripe test mode/payment sheet.
  - Verify `process_checkout` order creation, order confirmation route, cart cleanup for that shop only, and buyer order detail.
- Buyer orders:
  - Open `/profile/orders`, scroll order list, open detail, verify status/tracking.

### Phase 8: Marketplace Seller

Scenarios:

- Seller dashboard:
  - Open `/seller` from marketplace/admin action where available.
  - Verify KPIs, product/order/shop links, scroll to bottom.
- Shop setup/edit:
  - If seller has no shop, create one through `/seller/setup`.
  - Edit shop branding, contact info, policies in `/seller/edit-shop`.
  - Verify image upload to `shops` bucket if using asset injection.
- Stripe onboarding:
  - Start onboarding; verify `stripe-onboard-vendor` returns `accountLinkUrl`.
  - Do not complete real external onboarding in the default run; record external URL and return handling separately.
- KYC:
  - Fill manual KYC form, upload test document to `kyc-documents`, submit.
- Products:
  - Open `/seller/products`.
  - Add product with name, price, inventory, category, image, active switch.
  - Edit product; delete only QA-created product.
- Orders:
  - Open `/seller/orders`, open detail.
  - Update status/tracking with realistic carrier and URL.
  - Verify buyer detail reflects update.
- Deletion request:
  - Submit shop deletion request only for disposable QA shop.

### Phase 9: Admin

Precondition: login as admin user.

Scenarios:

- Open `/admin`; verify non-admin users are redirected to `/home`.
- Dashboard tab: verify metrics and scroll.
- KYC tab: open signed document, approve/reject QA KYC.
- Ledger tab: inspect vendor ledger entries and export/filter if exposed.
- Orders tab: view COD/order list, open detail, perform allowed status action.
- Moderation tab: resolve QA reported post with hide/no-hide variants.
- Shops tab: approve/reject QA shop deletion request.

## Execution Strategy

1. Add `integration_test/` with a thin app driver that uses the real app entrypoint and `--dart-define-from-file=.env`.
2. Prefer Flutter finders for widgets with keys and text labels; use adb/uiautomator only for launch, permissions, screenshots, OS dialogs, and external handoffs.
3. Build scenario helpers:
   - `loginAs(role)`.
   - `tapBottomNav(routeKey)`.
   - `scrollToEndAndAssertStable()`.
   - `openPetSwitcher()`.
   - `seedOrVerifyFixture(role)`.
   - `expectNoFlutterErrorOrCrashLog()`.
4. Use Supabase MCP/SQL for fixture verification before UI runs and cleanup after runs.
5. Tag tests by risk:
   - `smoke`: auth + shell navigation.
   - `read_only`: all screens and scrolls.
   - `mutating`: create/edit/delete app-owned QA rows.
   - `payments`: Stripe test checkout.
   - `admin`: admin-only workflows.
6. Store evidence:
   - UI tree dumps per failed step.
   - Screenshots on failure.
   - App logcat.
   - Supabase before/after row snapshots for mutating scenarios.

## Priority Order

1. Emulator/network/auth health.
2. Smoke navigation across shell routes.
3. Full read-only route traversal with scroll-to-bottom checks.
4. Pet profile and care mutations.
5. Social and matching realtime flows.
6. Marketplace buyer checkout.
7. Seller workflows.
8. Admin workflows.
9. Regression pipeline packaging for repeated runs.

## Open Risks To Resolve Before Implementation

- Decide whether destructive scenarios run against a Supabase branch, a QA project, or the hosted project with QA-prefixed cleanup.
- Confirm QA credentials for buyer, seller, second matching user, and admin.
- Confirm whether the emulator can resolve and reach `jqyjvhwlcqcsuwcqgcwf.supabase.co`; prior review work found emulator DNS failures.
- Decide how test media/documents will be injected into Android file pickers.
- Confirm Stripe test account state for Connect onboarding and PaymentSheet.

