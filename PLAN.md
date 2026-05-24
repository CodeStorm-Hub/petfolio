# PetFolio Full-App Material 3 Adaptive Redesign Plan

## Summary

PetFolio already has strong functional coverage across pet profile, care, social, matching, marketplace, seller, and admin areas, but the current UI reads as a collection of locally designed feature screens rather than one cohesive product. Confirmed evidence comes from the valid emulator reports and screenshots in `docs/automation/`; invalid launcher/calendar captures from the fresh run are excluded.

Key redesign direction: keep the existing feature-first Riverpod/GoRouter architecture, introduce a shared PetFolio Material 3 design system, and progressively replace duplicated screen-local cards, headers, empty states, forms, sheets, and grids with adaptive reusable components.

Research anchors:
Flutter Material 3 is the correct baseline because Flutter now treats Material 3 as the default and calls out adaptive, accessible, large-screen-ready experiences. ([docs.flutter.dev](https://docs.flutter.dev/ui/design/material)) Flutter’s adaptive guidance recommends abstracting shared data, measuring with `MediaQuery.sizeOf` or `LayoutBuilder`, then branching by available window size, not device type. ([docs.flutter.dev](https://docs.flutter.dev/ui/adaptive-responsive/general)) Android window size classes define compact `<600dp`, medium `600-839dp`, expanded `840-1199dp`, large `1200-1599dp`, and extra-large `>=1600dp`, and explicitly warn that window class can change during orientation, split-screen, and folding. ([developer.android.com](https://developer.android.com/develop/adaptive-apps/guides/use-window-size-classes)) Large-screen guidance recommends canonical layouts such as list-detail, feed, and supporting pane. ([developer.android.google.cn](https://developer.android.google.cn/guide/topics/large-screens?hl=en)) WCAG 2.2 requires at least 4.5:1 normal text contrast, text resizing up to 200%, reflow without two-dimensional scrolling for normal content, and pointer target minimums; PetFolio should use a stronger 48dp mobile target floor. ([w3.org](https://www.w3.org/TR/WCAG22/)) ([w3.org](https://www.w3.org/TR/WCAG22/)) ([w3.org](https://www.w3.org/TR/WCAG22/)) Stripe and Baymard support keeping checkout concise, responsive, transparent, and information-rich enough for mobile shoppers to avoid unnecessary product-detail visits. ([stripe.com](https://stripe.com/gb/resources/more/mobile-checkout-ui?__=&__previewId=)) ([baymard.com](https://baymard.com/research/checkout-usability)) ([baymard.com](https://baymard.com/mcommerce-usability/benchmark/mobile-page-types/product-list/19137-cb2))

## Confirmed Current UX Problems

- **Cohesion:** Home, care, matching, marketplace, seller, and admin use similar rounded white cards but different density, icon treatment, hero cards, CTAs, and visual language.
- **Visual hierarchy:** Large decorative gradient cards dominate care, matching, marketplace, and admin, sometimes pushing practical next actions below the fold.
- **Information density:** Seller/admin screens are plain operational lists on phones, while marketplace and care screens are visually rich; PetFolio needs a unified hierarchy for both lifestyle and operations.
- **Empty states:** Cart, nutrition trend, medical vault categories, care sections, and no-candidate states are functional but often passive; they need next-step CTAs and clear recovery paths.
- **Adaptive risk:** Current shell already has `NavigationBar` and `NavigationRail`, but most feature screens still look phone-first. Product grids, inbox/chat, admin tabs, seller orders, medical records, and post detail need master-detail or multi-column layouts.
- **Accessibility risks:** Some low-contrast text appears over orange/green gradients; emoji/species chips and icon-only actions need semantic labels; dense horizontal chips and floating actions need 48dp hit targets and keyboard traversal.
- **Component duplication:** Product cards, shop cards, metric cards, task cards, dashboard stat cards, bottom sheets, and empty states exist as screen-local implementations that should become shared feature/core components.

## Screen Inventory And Redesign Recommendations

### Auth And Onboarding
- Use a calm full-screen `Scaffold` with constrained content: max width `420dp` compact/medium, centered pane on expanded.
- Login/register: `TextFormField` with persistent labels, password visibility toggle, inline validation, `FilledButton` primary CTA, `TextButton` secondary links.
- First pet/add pet onboarding: convert to a stepped flow with visible progress, saved draft state, species cards, photo/avatar step, health basics, and completion screen.
- Validation: on-blur field errors, submit-time summary at top, screen-reader announced errors, no placeholder-only labels.

### Home / Pet Profile
- Replace the current dominant health-streak hero with a balanced “Active Pet Snapshot”: avatar/photo, name, species/breed, age/weight, today’s care status, discovery/social status.
- Keep tabs: Overview, Health, Care, Awards. Use `TabBar` compact; on medium/expanded, use a left-side section rail or two-column content with sticky section nav.
- Move Social Profile and Seller Dashboard into secondary action cards below the snapshot; do not make Seller Dashboard compete with daily pet-care actions.
- Add richer empty states: “No upcoming care records” should include “Add care task” and “View care dashboard”.

### Care
- Care dashboard top should summarize “0/5 done today”, streak, and next due task in one compact card. Keep the ring, but make explanatory text optional/help affordance instead of permanent body copy.
- Date strip: use fixed-height horizontal date selector on compact; on expanded, show mini calendar/month context in a supporting pane.
- Daily task cards: create one reusable `CareTaskCard` with icon, title, time/frequency, points, completion state, and overflow menu. Swipe-to-complete must also have a visible checkbox/action for accessibility.
- Add/edit task and AI routine: use shared `PetFolioBottomSheet`; full-screen dialog on compact if content exceeds 70% height, side sheet on expanded.
- Nutrition and Medical Vault banners should become compact resource cards with status summaries, not just navigation banners.

### Nutrition
- Weight trend: reserve a real chart area with empty-state CTA “Log first weight”; show two-point minimum guidance below the CTA.
- Calorie card: keep calculation transparency, but reduce gradient dominance and surface assumptions as rows: weight, activity, species.
- Add history list with grouped dates, edit/delete guarded behind menus, and skeleton loading.
- Expanded layout: chart left, calorie recommendation and log form/history right.

### Medical Vault
- Use three segmented sections: Vaccines, Medications, Vet Visits. On compact, segmented control or tabs; on expanded, list-detail.
- Empty states need action buttons: “Add vaccine”, “Add medication”, “Add vet visit”, “Upload document”.
- Add record flow: bottom sheet/full-screen form with record type, date, provider, notes, reminders, attachments.
- Document upload: show file type/size rules, upload progress, retry/remove, and private-document trust copy.

### Social
- Feed: reduce oversized blank media areas by using aspect-ratio placeholders, skeletons, and collapsed text states.
- Stories entry: convert “Your story” to a horizontal story rail with accessible add-story CTA and consistent avatars.
- Post cards: reusable `FeedPostCard` with avatar, pet name, handle/time, optional media, caption, like/comment/share/report actions, and visible counts.
- Create post: keep current good structure, but improve spacing, validation, image previews, disabled Share reason, and discard confirmation.
- Post detail/comments: list-detail on medium/expanded; comment composer sticky at bottom; report action in overflow.
- Notifications/social pet profile need fresh valid screenshots before final pixel QA.

### Matching
- Discovery deck: current visual direction is strong, but candidate image/avatar quality and text contrast over gradients need improvement.
- Candidate card: photo first when available; fallback pet illustration in a contained avatar area; chips should be consistent filter/assist chips.
- Actions: five circular actions are visually clear; add labels/tooltips on long press/hover and semantics for pass/greet/like/super-paw.
- Preferences: bottom sheet is good; make selected chips visually distinct, add Apply/Reset controls if changes are no longer immediate, and use side sheet on expanded.
- Empty states: no-location, no-candidates, and not-discoverable states should have a single primary fix action and a secondary learn-more/settings action.
- Inbox/chat: compact uses list then chat route; medium/expanded uses list-detail with selected thread, new matches rail, and persistent composer.

### Marketplace
- Marketplace home: preserve search, categories, shops, subscription products. Improve product cards with real image area, vendor, title, price, subscription price, add button, and stock/subscription badges.
- Search/filter: use Material 3 `SearchBar`/`SearchAnchor` pattern where possible; filters in modal sheet compact, side sheet expanded.
- Discover Shops: current shop cards are too generic; add logo/photo, shop name, verified badge, rating/order count if available, and category tags.
- Product detail: current sticky “Add to cart” is strong. Add image carousel, trust badges, subscription summary, quantity, delivery frequency, seller card, and details.
- Cart: empty state should include “Browse marketplace” primary CTA and “View shops” secondary CTA. Full cart should group by shop because the app supports per-shop checkout.
- Checkout: use per-shop checkout steps: cart review, shipping/contact, delivery, payment via existing Stripe flow, confirmation. Keep PaymentSheet/Stripe-owned payment UI where applicable.
- Order confirmation/buyer orders: show status timeline, shop contact, items, delivery/payment summary.

### Seller
- Seller dashboard: preserve simple operations feel, but add “Today” summary row, shop health status, pending tasks, and primary CTA hierarchy.
- Shop setup/edit shop/manual KYC: use stepper forms with persistent progress and document upload cards.
- Stripe onboarding: clear status card with “Continue Stripe onboarding”; transient failures via `AppSnackBar.showError`, not long-lived provider errors.
- Product list/add/edit: responsive product management grid/list; compact cards, expanded table/list-detail editor.
- Vendor orders/order detail: compact status cards, expanded master-detail; status updates require confirmation and visible audit/status feedback.
- Shop deletion: current danger zone is good; require confirmation dialog with typed shop name or explicit review-copy, since action triggers admin review.

### Admin
- Dashboard: current navy platform overview is high contrast but too visually heavy. Redesign as neutral operations dashboard with 3-4 KPI cards, alerts, and recent activity.
- KYC/orders/moderation/ledger/shops: compact uses tabs plus stacked case cards; expanded uses permanent sidebar and list-detail.
- Destructive/resolution actions: confirmation dialogs with reason fields where relevant, undo only for reversible actions, clear success/error snackbars.
- Financial ledger: avoid dense tables on compact; use grouped payout cards, filters in sheet, CSV/export actions only on expanded if supported.
- Admin internal tabs need another clean capture pass before final redesign QA.

## Material 3 Adaptive Layout Strategy

- **Breakpoints:** Compact `<600dp`; medium `600-839dp`; expanded `840-1199dp`; large `1200-1599dp`; extra-large `>=1600dp`.
- **Shell navigation:** Compact uses `NavigationBar`; medium uses `NavigationRail`; expanded/large uses extended rail or permanent drawer/sidebar depending on route group. Android guidance maps compact to bottom navigation, medium to rail, expanded to rail or persistent drawer. ([developer.android.com](https://developer.android.com/develop/ui/views/layout/build-responsive-navigation?hl=en))
- **Content max widths:** Reading/forms max `560dp`; care/profile content max `720dp`; marketplace/admin grids max by `SliverGridDelegateWithMaxCrossAxisExtent`, not hardcoded device classes.
- **Canonical layouts:** Inbox/chat, seller orders, admin cases, product management, medical records use list-detail when enough width exists. Android describes list-detail as a dual-pane list plus selected details layout. ([developer.android.com](https://developer.android.com/develop/ui/compose/layouts/adaptive/list-detail))
- **Foldables/landscape:** Do not portrait-lock. Foldables need alternate layouts, not just responsive scaling, because folded/unfolded screens can differ too much for one layout. ([developer.android.com](https://developer.android.com/develop/ui/compose/layouts/adaptive/foldables/learn-about-foldables))
- **Scrolling:** Compact favors vertical scrolling with sticky bottom actions. Expanded uses supporting panes and avoids stretching cards/text across full width.
- **Input:** Add hover/focus states, keyboard traversal, and shortcuts for web/desktop while preserving touch-first controls.

## PetFolio Component System

- **Color:** Use seed-based Material 3 with PetFolio blue as primary, care green as secondary, warm coral/orange as tertiary, neutral slate surfaces, semantic success/warning/error/info tokens. Avoid large single-hue gradient blocks; use gradients sparingly for hero/stat emphasis only.
- **Typography:** Material 3 text scale. Use titleLarge/small for screen sections, bodyLarge for primary text, labelLarge for buttons/chips. No all-caps body text except short eyebrow labels.
- **Shape:** 8dp for standard cards/buttons; 12dp for prominent cards/sheets; 16dp only for hero cards and large media. Avoid oversized pill shapes for everything.
- **Spacing:** 4/8/12/16/24/32dp scale. Compact page horizontal padding 16dp, medium 24dp, expanded 32dp with max-width containers.
- **Surfaces:** Prefer filled/outlined Material cards. Reduce custom glass effects in admin/operations screens.
- **Icons:** One icon style across app. Use Material/lucide-equivalent line icons; pet-specific illustrations only for empty states or species avatars.
- **Core widgets to create/update:** `PetFolioScaffold`, `PetFolioAdaptiveScaffold`, `PetFolioAppHeader`, `PetAvatar`, `ActivePetSwitcher`, `PetFolioSectionHeader`, `PetFolioMetricCard`, `PetFolioEmptyState`, `PetFolioErrorRetry`, `PetFolioSkeleton`, `PetFolioBottomSheet`, `PetFolioConfirmDialog`, `PetFolioFormField`, `PetFolioPrimaryButton`, `PetFolioDestructiveButton`.
- **Feature widgets:** `PetSnapshotCard`, `CareTaskCard`, `CareStreakCard`, `HealthMetricCard`, `AchievementBadge`, `FeedPostCard`, `MatchCandidateCard`, `ProductCard`, `ShopCard`, `CartShopGroupCard`, `SellerActionCard`, `AdminCaseCard`, `AdminStatCard`.

## Screenshot Critique Table

| Screenshot | Feature | Confirmed Issues | Redesign Recommendation | Priority |
|---|---|---|---|---|
| `002_home_overview_top.png` | Home/Profile | Hero streak dominates; seller CTA competes with pet care; empty care state passive | Balanced pet snapshot, compact care summary, action hierarchy, empty CTA | P1 |
| `003_home_overview_scrolled.png` | Home/Profile | Sections rely on scroll with weak landmarks | Sticky/clear section headers, stronger cards, next-step CTAs | P2 |
| `004_home_health_tab.png` | Profile Health | Needs clearer metric grouping | Health metric cards with trend/status and add-log actions | P2 |
| `005_home_care_tab.png` | Profile Care | Empty/list states need action clarity | Reuse care task cards and add task CTA | P2 |
| `006_home_awards_tab.png` | Awards | Likely sparse gamification hierarchy | Badge grid, progress card, locked/unlocked states | P2 |
| `007_pet_switcher_sheet.png` | Pet switcher | Good pattern, needs adaptive behavior | Shared bottom sheet compact, dialog/side sheet expanded | P1 |
| `008_manage_pets.png` / `007_manage_pets_screen.png` | Manage pets | Operational list likely plain | Pet rows with avatar/status/actions; expanded list-detail | P2 |
| `021_care_top.png` | Care | Gradient card too tall; explanatory text consumes prime space; FAB overlaps task area | Compact status card, visible completion controls, reposition FAB/sticky add | P1 |
| `022_care_mid.png`, `023_care_bottom_banners.png` | Care | Dense task/resource scroll; banners may be too decorative | Task groups, resource summary cards, sticky date strip | P1 |
| `023_care_add_task_sheet.png` | Care Sheet | Good task grid; content nearly full height; horizontal frequency clips | Full-screen sheet when tall, wrap chips, fixed footer, validation | P1 |
| `024_nutrition_screen.png` / `087_nutrition_screen_verified.png` | Nutrition | Empty trend lacks primary CTA in card; large blank lower area | Add CTA in empty chart, history list, chart/detail split on wide | P1 |
| `026_medical_vault_screen.png` / `089_medical_vault_screen_verified.png` | Medical Vault | Three passive empty boxes; FAB is distant from sections | Section-specific add buttons and typed add-record flow | P1 |
| `030_social_feed_top.png` | Social Feed | Post media placeholder huge/blank; story label truncated | Aspect-ratio media placeholders, story rail, post card polish | P1 |
| `031_social_feed_scrolled.png` | Social Feed | Feed card rhythm needs consistency | Reusable post cards, skeleton/media states, clearer actions | P2 |
| `032_create_post_screen.png` | Create Post | Solid base; disabled Share lacks reason; field area oversized | Inline validation, image preview, character/helper states | P1 |
| `072_social_messages_to_match_inbox_clean.png` | Social->Inbox | Deep link works | Preserve route; redesign inbox as list-detail on wide | P2 |
| `091_matching_discovery_final.png` | Matching | Strong deck; fallback art and dark gradient reduce trust/photo value | Photo-first candidate card, contrast-safe overlay, semantic actions | P1 |
| `092_matching_filters_final.png` | Matching Sheet | Good sheet; needs selected chip states/actions | Add Reset/Apply, side sheet expanded, accessible slider labels | P1 |
| `094_matching_inbox_final.png` | Match Inbox | Needs wide layout planning | New matches rail + thread list + detail pane | P1 |
| `095_marketplace_top_final.png` | Marketplace | Product images are abstract placeholders; horizontal content clipped | Better product cards, applied filters, responsive grid, shop metadata | P1 |
| `096_marketplace_scrolled_final.png` | Marketplace | Product comparison is hard on compact | Product info hierarchy, badges, consistent price/subscription row | P1 |
| `064_product_detail.png` / `097_product_detail_final.png` | Product Detail | Strong sticky CTA; image area generic; order summary below fold | Media carousel, seller trust, subscription explanation, detail sections | P1 |
| `052_marketplace_cart.png` | Cart | Empty state lacks visible recovery CTA | Add Browse Marketplace primary CTA and Discover Shops secondary | P1 |
| `066_shop_storefront.png` | Shop Storefront | Good grid; generic shop identity; products need richer info | Shop header, verified/trust metadata, adaptive product grid | P2 |
| `056_seller_dashboard.png` | Seller | Clear but sparse; operations lack priority/status | Shop health summary, task-first quick actions, improved KPI cards | P2 |
| `057_seller_dashboard_scrolled.png` | Seller | Danger zone visible but needs confirmation detail | Destructive confirmation dialog and review-state messaging | P1 |
| `060_admin_dashboard.png` | Admin | Heavy navy/glass card; KPI cards low contrast; tabs not captured | Neutral dashboard, accessible KPI cards, focused admin tab pass | P1 |
| `072_admin_dashboard.png` and `073-076_admin_*` | Admin | Earlier tab taps unreliable | Retest with UI-tree targeting; then redesign each tab as case cards/list-detail | P1 |

Excluded as evidence: fresh `010`, `012`, `013`, `074-083`, `098-100`, and superseded/wrong-route `034`, `040`, `043`, `050`, `052`, `053`, `054` per the fresh testing report.

## Implementation Roadmap

- **Phase 1: Global Theme And Shared Components**
  - Update `lib/core/theme` with finalized Material 3 tokens, contrast-checked semantic colors, typography, shape, spacing, and component themes.
  - Build shared core widgets listed above. Keep generated/Riverpod conventions intact.
  - Add golden/widget tests for core states: loading, empty, error, disabled, destructive, dynamic text.

- **Phase 2: Navigation/Header/Pet Switcher**
  - Create shared destination model for shell nav so `NavigationBar`, `NavigationRail`, and expanded sidebar use one source.
  - Refine `AppHeader` and `PetSwitcherSheet`; avoid router import cycles by using literal paths/query strings where needed.
  - Validate compact, medium, expanded, landscape, and dynamic text.

- **Phase 3: Care/Profile Redesign**
  - Replace profile hero/cards/tabs and care dashboard/task/sheet/nutrition/medical vault surfaces.
  - Preserve providers: `activePetIdProvider`, `careDashboardProvider`, `healthVaultControllerProvider`, and existing RPC-backed behavior.
  - Add non-mutating widget tests and emulator screenshots for redesigned states.

- **Phase 4: Social/Matching Redesign**
  - Introduce `FeedPostCard`, create-post improvements, matching candidate card, preferences sheet, inbox/chat adaptive list-detail.
  - Keep mutating swipe/post/comment flows behind current repositories and QA-data validation.

- **Phase 5: Marketplace Redesign**
  - Replace marketplace home cards, search/filter, product detail, cart, shop storefront, buyer orders, and checkout presentation.
  - Preserve per-shop cart/checkout model and Stripe/PaymentSheet-backed payment flow.

- **Phase 6: Seller/Admin Redesign**
  - Redesign seller dashboard/setup/KYC/products/orders and admin dashboard/case tabs as operations-first adaptive layouts.
  - Use confirmation dialogs and `AppSnackBar.showError` for transient action failures.

- **Phase 7: Accessibility And QA Polish**
  - Run `flutter analyze`, widget tests, and compact/medium/expanded screenshot pass.
  - Add emulator capture pass for missing/invalid flows and update `progress.md` after each distinct care, marketplace, or backend phase.

## Additional Screenshots And Test Flows Needed

- Clean auth: login, registration, password reset, first pet onboarding, add another pet.
- Notifications and social pet profile, because fresh captures were contaminated.
- Product detail/cart/shop storefront from fresh stable route, because final fresh captures were contaminated; earlier clean captures can guide design but need recapture after redesign.
- Admin internal tabs with reliable tab IDs/UI-tree targeting.
- Full checkout with QA data and Stripe test mode only.
- Seller setup/edit shop/manual KYC/product add/edit/vendor order detail.
- Medical add record and document upload.
- Matching no-location, no-candidates, match celebration, chat detail.
- Dynamic type, landscape, tablet/foldable, keyboard/focus traversal, screen reader labels.

## Flutter Implementation Guidance

- Use `CustomScrollView`/slivers for profile, care, social, and marketplace pages with sticky headers where needed.
- Use `LayoutBuilder` for local card/grid reflow and `MediaQuery.sizeOf` for app-shell navigation decisions.
- Use `SliverGridDelegateWithMaxCrossAxisExtent` for marketplace/products/awards/admin cards.
- Use `NavigationBar`, `NavigationRail`, `Drawer`/permanent sidebar, `SearchBar`/`SearchAnchor`, `SegmentedButton`, `FilterChip`, `ChoiceChip`, `FilledButton`, `OutlinedButton`, `Card`, `Badge`, `SnackBar`, `Dialog`, and `BottomSheet` before custom controls.
- Do not introduce `provider`; keep Riverpod generated notifiers and feature-first `lib/features/<feature>/presentation|domain|data`.
- UI-only state such as selected tab, expanded filter section, pending form step, local image preview, and transient sheet state should stay local or in short-lived Riverpod UI controllers. Domain state stays in existing feature providers/repositories.
- Keep destructive backend actions out of visual QA unless seeded QA data and cleanup are explicit.

## Acceptance Checklist

- PetFolio uses one cohesive Material 3 theme across all screens.
- Compact uses bottom navigation; medium uses rail; expanded uses rail/sidebar and multi-pane layouts where useful.
- No redesigned screen is phone UI merely stretched to tablet width.
- All primary touch targets are at least 48dp; icon-only actions have semantic labels/tooltips.
- Text passes contrast guidance and supports large font settings without clipping.
- Empty/loading/error states are reusable and actionable.
- Care, marketplace, seller, and admin destructive or mutating actions have confirmation/error patterns.
- Product/cart/checkout supports per-shop checkout and existing Stripe flow.
- Matching/social mutating actions remain non-destructive during design validation.
- `flutter analyze` and relevant widget/golden tests pass.
- Emulator screenshots are recaptured for compact phone plus at least one medium/expanded viewport.
- Reports distinguish confirmed screenshot evidence from assumptions.
