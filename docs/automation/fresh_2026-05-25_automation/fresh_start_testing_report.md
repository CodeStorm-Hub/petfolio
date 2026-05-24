# PetFolio Fresh-Start Android Automation Run

Date: 2026-05-25  
Device: `emulator-5554`  
Package: `com.example.petfolio`  
Run mode: fresh operational restart, app data retained to preserve authenticated real-data session  
Artifacts:

- Screenshots: `docs/automation/fresh_2026-05-25_automation/screenshots/`
- UI dumps: `docs/automation/fresh_2026-05-25_automation/ui-dumps/`
- Logs: `docs/automation/fresh_2026-05-25_automation/logcat_fresh_run.txt`
- Filtered logs: `docs/automation/fresh_2026-05-25_automation/logcat_findings.txt`

## Fresh-Start Method

I restarted the automation from the beginning by force-stopping PetFolio, clearing logcat, relaunching `com.example.petfolio/.MainActivity`, and capturing the initial app state before navigation. I did not clear app storage because the repo/session does not expose reusable test credentials, and clearing storage would remove the authenticated real-data session needed to test the main product surfaces.

## Validated Screens and Flows

### Home and Pet Profile

- `001_fresh_launch_initial.png` - fresh relaunch initial Home state.
- `002_home_overview_top.png`, `003_home_overview_scrolled.png` - profile overview top and scrolled content.
- `004_home_health_tab.png`, `005_home_care_tab.png`, `006_home_awards_tab.png` - profile tabs.
- `007_pet_switcher_sheet.png` - pet switcher sheet.

Runtime notes:

- Fresh launch opened authenticated real data for `Montu`, later active pet switched to `Rex`.
- Home showed active pet header, profile tabs, social CTA, seller dashboard CTA, and care/social sections.

### Care

- `021_care_top.png` - Care dashboard top for Rex.
- `022_care_mid.png`, `023_care_bottom_banners.png` - scrolled task list and resource banners.
- `024_nutrition_screen.png` - Nutrition screen for Rex.
- `026_medical_vault_screen.png` - Medical vault screen for Rex.

Runtime notes:

- Care displayed real task data, streak ring, date strip, AI routine refresh, daily tasks, nutrition banner, and medical vault banner.
- Nutrition displayed Rex-specific calorie estimate and weight trend empty state.
- Medical vault displayed grouped empty states for vaccines, medications, and vet visits.

### Social

- `030_social_feed_top.png`, `031_social_feed_scrolled.png` - feed top and scrolled feed.
- `032_create_post_screen.png` - create post screen with photo picker area, caption field, visibility summary, and disabled share state.
- `072_social_messages_to_match_inbox_clean.png` - Social header Messages deep-linked into Match Inbox.

Runtime notes:

- Feed loaded real posts and interaction controls.
- Create Post opened correctly and stayed non-mutating because no content was submitted.
- Messages action routed to Match Inbox as expected.

### Matching

- `091_matching_discovery_final.png` - Match discovery deck with real candidates.
- `092_matching_filters_final.png` - match preferences bottom sheet.
- `094_matching_inbox_final.png` - match inbox with new matches and messages.

Runtime notes:

- Discovery displayed multiple pet candidates and bottom swipe actions.
- Filters sheet exposed species chips, distance slider, and age range content.
- Inbox showed new matches and message previews.
- I did not tap pass/greet/like/super-paw because those mutate live swipe/match data.

### Marketplace

- `095_marketplace_top_final.png` - Marketplace top with search, categories, shops, subscription products.
- `096_marketplace_scrolled_final.png` - scrolled marketplace list.

Runtime notes:

- Marketplace loaded real shops/products and category filters.
- Some product/cart/shop route taps were affected by Android back-stack/system focus issues in this run; the earlier validated artifact set still has clean product/cart/shop screenshots, but this fresh folder records the false starts separately.

### Seller and Admin

- `056_seller_dashboard.png`, `057_seller_dashboard_scrolled.png` - seller dashboard and danger zone.
- `060_admin_dashboard.png` - admin dashboard.

Runtime notes:

- Seller dashboard loaded verified shop state for `PetFolio`.
- Admin dashboard loaded platform overview, active shop count, pending KYC count, revenue, and recent activity.
- I did not execute seller deletion, KYC, product deletion, order updates, or admin resolutions because they mutate real data.

## Invalid or Contaminated Captures

These screenshots/XML files are retained for traceability but should not be used as PetFolio UI evidence:

- `010_notifications_screen.png`, `012_social_profile_from_avatar.png`, `013_home_after_social_profile.png` - Android launcher/calendar focus after a back-stack escape.
- `074_matching_discovery_clean.png` through `083_admin_dashboard_clean.png` - blocked by a system `Pixel Launcher isn't responding` dialog.
- `098_cart_final.png`, `099_shop_storefront_final.png`, `100_admin_dashboard_final.png` - Android Calendar/launcher focus after an external back-stack issue.
- `034_social_messages_match_inbox.png`, `040_matching_discovery.png`, `043_matching_inbox.png`, `050_marketplace_top.png`, `052_product_detail.png`, `053_cart_screen.png`, `054_shop_storefront.png` - wrong route due to relaunch preserving prior Flutter route; superseded by later final/clean captures where available.

## Log Findings

- No PetFolio `FATAL EXCEPTION` was found in the filtered run logs.
- Supabase initialized successfully: `supabase.supabase_flutter: INFO: ***** Supabase init completed *****`.
- A system/launcher issue occurred during automation: `Pixel Launcher isn't responding`. This contaminated several captures and was handled by clearing the dialog and continuing.
- The filtered logs contain Android system/uiautomator noise such as missing `android.xr` flag package and binder warnings. These were not PetFolio crashes.

## Coverage Gaps

- Cart, product detail, and shop storefront need another clean capture pass from a stable marketplace state or an integration-test harness.
- Admin internal tabs still need a focused pass with reliable tab targeting.
- Notifications and social profile need retest because one back-stack sequence opened Android Calendar.
- Mutating flows require seeded QA data and cleanup policy:
  - task completion/edit/delete
  - post like/comment/report/delete
  - swipe/greet/like/super-paw
  - add to cart/place order/payment
  - seller product/order/shop updates
  - KYC/admin/moderation/shop deletion resolutions

## Recommendation

For the next pass, add a Flutter `integration_test/` or Marionette-driven route harness that can navigate directly to named routes and reset state between screens. ADB-only testing is useful for screenshots, but Flutter route restoration and Android launcher focus made full app traversal less deterministic.
