# PetFolio Android Automation Inventory and QA Pass

Date: 2026-05-25  
Device: `emulator-5554`, Android 17 API 37, app package `com.example.petfolio`  
Backend project: `jqyjvhwlcqcsuwcqgcwf`  
Artifacts: screenshots in `docs/automation/screenshots/`, UI dumps in `docs/automation/ui-dumps/`

## Scope

This pass combined source inventory from `lib/`, live Supabase inspection, and emulator traversal against the signed-in app state. It prioritized read-only UI/UX capture and non-destructive actions. Destructive actions such as deleting pets, resolving admin cases, charging payment flows, KYC approval/rejection, archiving shops, and permanent post/product deletion should run only against dedicated QA data.

## Source Inventory

### Feature modules

- `auth`: login, registration, password reset, Supabase auth stream, redirect integration.
- `pet_profile`: active pet selection, onboarding, pet switching, manage pets, edit profile, discovery visibility, profile overview/health/care/awards tabs.
- `care`: care dashboard, daily tasks, task completion/menu actions, AI routine recommendations, nutrition/weight tracking, medical vault, health logs, care streaks, badges.
- `social`: feed, stories entry point, post creation, post detail, comments, likes, follows, reports, notifications, social pet profile.
- `matching`: discovery, location empty state, preferences sheet, pass/greet/like/super-paw actions, match celebration, inbox, chat.
- `marketplace`: product browsing, shop discovery/storefronts, product details, cart, checkout, buyer orders, seller dashboard, shop setup/editing, KYC, vendor products/orders, Stripe onboarding.
- `admin`: dashboard, KYC approvals, order operations, moderation, financial ledger, shops/deletion requests.
- `core`: router, app shell, shared header, snackbars, theme, location/notification services.

### Routes from `lib/core/router.dart`

- Shell tabs: `/home`, `/care`, `/social`, `/matching`, `/marketplace`.
- Auth/onboarding: `/login`, `/register`, `/onboarding`.
- Pets: `/pets/manage`, `/pet/:petId/edit`.
- Care: `/care/nutrition`, `/care/medical-vault`.
- Marketplace buyer: `/marketplace/product/:id`, `/marketplace/cart`, `/marketplace/order/:id`, `/marketplace/orders/:id`, `/profile/orders`, `/profile/orders/:id`, `/shop/:id`.
- Seller: `/seller`, `/seller/setup`, `/seller/onboarding`, `/seller/edit-shop`, `/seller/kyc`, `/seller/products`, `/seller/products/add`, `/seller/products/:id/edit`, `/seller/orders`, `/seller/orders/:id`.
- Admin: `/admin`.
- Social: `/social/create`, `/social/post/:postId`, `/social/notifications`, `/social/profile/:petId`.
- Matching: `/matching/inbox`, `/matching/chat/:threadId`.

### Stable UI anchors found in code/runtime

- Shell nav: `shell_nav__home`, `shell_nav__care`, `shell_nav__social`, `shell_nav__matching`, `shell_nav__marketplace`.
- App header: `app_header_pet_profile`, `app_header_pet_switcher`.
- Pet switcher/manage: `pet_switcher_add_pet`, `pet_switcher_manage`, `pet_switcher_sign_out`, `manage_pets_back`, `manage_pets_add_button`, `manage_pet_row_<id>`, `manage_pet_menu_<id>`, `manage_pets_empty_add`.
- Auth: `login_cta`, `register_cta`.
- Home/profile: `home_action_outdoor`, `home_action_notifications`.
- Care: `care_fab_add_task`, `care_action_outdoor`, `care_date_<yyyy-mm-dd>`, `care_task_menu_<id>`, `care_task_check_<id>`, `care_medical_vault_banner`, `care_nutrition_banner`.
- Social: `social_action_messages`, post detail `send`, follow buttons `follow` / `following`.
- Matching: `match_action_inbox`, `match_action_filter`, `match_action_pass`, `match_action_greet`, `match_action_like`, `match_action_super`, `matches_inbox_discover`, `new_match_<id>`, `conversation_<id>`, `chat_message_input`, `chat_send_button`, `match_prefs_close`, `match_prefs_distance_slider`, `match_prefs_age_slider`.
- Marketplace/admin: `market_action_admin`, `market_action_cart`, `load_test_document`.

## Live Supabase Inventory

### Public tables

`audit_logs`, `care_logs`, `care_streaks`, `care_tasks`, `chat_messages`, `chat_threads`, `comments`, `follows`, `health_logs`, `health_vitals`, `inventory_reservations`, `marketplace_orders`, `match_requests`, `matches`, `medical_vault`, `notifications`, `pet_badges`, `pet_care_gamification`, `pet_follows`, `pets`, `post_likes`, `posts`, `products`, `reported_posts`, `shop_deletion_requests`, `shops`, `swipes`, `users`, `vendor_ledgers`.

### RPCs/functions

`approve_vendor_kyc`, `cancel_order`, `check_daily_completion`, `confirm_order_inventory`, `ensure_chat_thread_for_match`, `get_care_dashboard_snapshot`, `get_match_inbox`, `get_or_create_social_thread`, `get_pet_awards_summary`, `get_pet_stats`, `handle_new_chat_message`, `handle_post_comment_sync`, `handle_post_like_sync`, `handle_updated_at`, `is_admin`, `matching_discovery_candidates`, `process_checkout`, `reject_vendor_kyc`, `release_order_inventory`, `request_shop_deletion`, `resolve_reported_post`, `resolve_shop_deletion`, `rls_auto_enable`, `set_pet_location_point`, `set_updated_at`, `vendor_update_order`.

### Storage buckets

- `pets` public.
- `post-images` public, 10 MB, image formats including HEIC.
- `marketplace-images` public, 5 MB.
- `shops` public, 5 MB.
- `medical-documents` private, 10 MB, image/PDF.
- `kyc-documents` private, 10 MB, image/PDF.

### Edge Functions

- `create-payment-intent` with JWT verification.
- `stripe-onboard-vendor` with JWT verification.
- `stripe-webhook` without JWT verification.

## Automation Test Plan

### Foundation

1. Confirm connected emulator with `adb devices` and Flutter device with `flutter devices`.
2. Launch `com.example.petfolio/.MainActivity`.
3. Capture every screen with both `screencap` and `uiautomator dump`.
4. Use UI-tree-derived bounds for tapping; avoid screenshot-only coordinate guesses.
5. Split runs into read-only capture and mutating QA-data runs.

### Real-life scenario flows

- Returning owner: open home, inspect active pet, switch pet, manage pets, view social profile, inspect all profile tabs, scroll to bottom.
- Daily caregiver: open Care, inspect streak/date strip/tasks, complete a task only in QA data, open task menu, add/edit task sheet, nutrition, medical vault, AI routine sheet.
- Social user: browse feed, scroll posts, open post detail, like/comment/report on QA post, create post draft, open image source options, discard draft, inspect notifications and social profile.
- Matching user: open discovery, handle location/no-candidates state, open filters, adjust sliders in QA, open inbox, open chat, send QA message only in seeded thread.
- Shopper: browse marketplace, filter/search categories, open shop, open product detail, adjust subscription/frequency/quantity, add to cart in QA, inspect cart and checkout fields.
- Seller: open seller dashboard, inspect quick actions, open products/orders/edit shop/KYC, submit only QA documents or provided test document.
- Admin: open dashboard, inspect KYC/orders/moderation/ledger/shops tabs, resolve only seeded QA requests.

## Emulator Execution Evidence

Captured screenshots:

- Home/profile: `000_launch.png`, `001_home_overview_top.png`, `002_home_overview_bottom.png`, `003_home_health_tab.png`, `004_home_care_tab.png`, `005_home_awards_tab.png`, `006_pet_switcher_sheet.png`, `007_manage_pets_screen.png`, `009_social_profile_from_avatar.png`, `011_relaunch_home.png`.
- Care: `020_care_top.png`, `021_care_mid.png`, `022_care_bottom.png`, `023_care_add_task_sheet.png`, `024_care_after_add_sheet.png`, `087_nutrition_screen_verified.png`, `089_medical_vault_screen_verified.png`.
- Social/matching: `030_social_feed_top.png`, `031_social_feed_bottom.png`, `032_social_messages_to_matching.png`, `040_matching_top.png`, `043_matching_inbox.png`, `060_social_top_again.png`, `061_create_post_screen.png`.
- Marketplace/seller/admin: `050_marketplace_top.png`, `051_marketplace_bottom.png`, `052_marketplace_cart.png`, `054_admin_or_market_action.png`, `064_product_detail.png`, `066_shop_storefront.png`, `069_seller_dashboard.png`, `070_seller_dashboard_bottom.png`, `072_admin_dashboard.png`.

Runtime notes:

- The app was already authenticated and loaded real backend-backed data for pets including Montu/Rex.
- Social Messages correctly deep-linked to Match Inbox.
- Marketplace Admin opened Admin Dashboard for the current account, confirming admin access.
- Match discovery showed a real empty state: no nearby pets and guidance to enable discovery/location.
- Marketplace cart was empty.
- Seller dashboard showed a verified shop state for `PetFolio`.
- Recent logcat sample did not show a PetFolio fatal crash; observed Android system noise only.

## Gaps and Follow-up

- Admin tab switching did not expose distinct tab screens through bottom-coordinate taps in this pass; use UI-tree targeting from admin layout or a widget/integration harness for tab IDs.
- Legacy captures `025_care_nutrition_screen.png` and `026_care_medical_vault_screen.png` were mislabeled during the first pass; use verified replacements `087_nutrition_screen_verified.png` and `089_medical_vault_screen_verified.png`.
- Destructive workflows need seeded QA rows and explicit cleanup: archive pet, delete task, delete post, report resolution, KYC reject/approve, shop deletion approval, product deletion, order status changes, checkout/payment.
- Add an `integration_test/` harness with stable keys for screens that Flutter semantics compress too aggressively for adb-only traversal.
