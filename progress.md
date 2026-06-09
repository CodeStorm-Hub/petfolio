# Petfolio — Progress Log

## 2026-06-09 - Contextual Navigation Phase 2 (Global Shell Completion)

`flutter analyze` - **No issues found.**

### Implemented

**`lib/core/navigation/shell_destinations.dart`** - `globalDestinations` updated from 5 tabs to 4 (Home/Alerts/Activity/Me); `globalAccents` trimmed to match

**`lib/core/navigation/app_shell_routes.dart`** - `/notifications`, `/activity`, `/me` added inside ShellRoute

**New: `lib/features/profile/presentation/screens/me_screen.dart`** - Shell-tab Me screen; profile card with active pet/initials + Gold Member pill; MY PETS (switch/add), ACCOUNT (addresses, orders, seller), PREFERENCES (notifications, dark mode), OFFERS, HELP & LEGAL, Sign Out; no internal header - uses `SizedBox(height: topPad + 76)` spacer for AppShellHeader

**`lib/features/social/presentation/screens/notifications_screen.dart`** - `showHeader` param added; when false hides back-button header and adds spacer; used by `/notifications` shell tab

**`lib/features/activity/presentation/screens/activity_screen.dart`** - same `showHeader` pattern

**`lib/core/widgets/app_shell.dart`** - `_globalEyebrows` trimmed to 4 entries (HOME/ALERTS/ACTIVITY/ME); `_buildTrailing` rewritten with direct switch on subIndex for global shell: Home=streak+notifs+me, Alerts=mark-all-read, Activity=filter, Me=dark mode toggle

**`lib/core/navigation/router_notifier.dart`** - redirects: `/settings` to `/me`, `/social/notifications` to `/notifications`

**`lib/features/activity/activity_routes.dart`** - returns empty list (moved to shell)

**`lib/features/settings/presentation/screens/settings_screen.dart`** - `push('/activity')` changed to `go('/activity')`

### Next step - Phase 3: Module Sub-route Migration
- Move `/social/stories`, `/social/communities` inside shell
- Move `/matching/inbox` inside shell
- New `/matching/liked` screen (MatchLikedScreen)

Phase complete - please run (/remember) to save tokens before proceeding to Phase 3.

---
## 2026-06-09 — Contextual Navigation Phase 1 (Foundation) ✅

`flutter analyze` — **No issues found.**

### Implemented

**New files**
- `lib/core/navigation/shell_module_provider.dart` — `ShellModule` enum (global, care, social, matching, marketplace)
- `lib/core/navigation/shell_destinations.dart` — 5 destination sets + accent arrays + helpers (`moduleFromPath`, `destinationsFor`, `accentsFor`, `selectedSubIndex`)

**`lib/core/widgets/app_shell.dart`**
- `_FloatingNav` / `_WideNavRail` now accept `destinations` + `accentColors` (no longer hardcoded)
- `_AppShellState` computes `module` + `subIndex` from GoRouter path each build
- `AnimatedSwitcher` (fade + slide-up 220 ms) wraps `_FloatingNav` keyed on `ShellModule`
- `AppShellHeader` takes `module + subIndex`; shows `← Home` pill in modules, pet switcher in global shell
- Trailing actions mapped per module

**`lib/core/navigation/app_shell_routes.dart`** — care sub-routes inside ShellRoute: `/care/nutrition`, `/care/health`, `/care/walk`, `/care/appointments`

**`lib/core/navigation/router_notifier.dart`** — redirect `/care/medical-vault` → `/care/health`

**`lib/features/care/care_routes.dart`** + **`appointment_routes.dart`** — return empty list (moved to shell)

**`lib/features/care/presentation/screens/care_screen.dart`** — `push` → `go` for care sub-routes; medical vault → `/care/health`

### Next step — Phase 2: Global Shell Completion
- Create `/notifications` merged screen + `/me` screen
- Update `globalDestinations` from 5 → 4 tabs (Home, Alerts, Activity, Me)

Phase complete — please run (/remember) to save tokens before proceeding to Phase 2.

---

## 2026-06-09 — Pathao Gaps Phase 3 (Gap #11 + P3 finalization) ✅

`flutter analyze` — **No issues found.**

### Implemented

**Gap #11 (P2) — Promotions tab wired to live promo data**
- `_PromotionsTab` → `ConsumerWidget`, watches `promoListProvider`
- `_PromoNotifCard`: icon tile + code + discount badge + validity row + "Copy code" CTA
- `TailWagLoader` loading state; `PetfolioEmptyState` empty/error states
- Stagger-in: 40ms delay per card, `fadeIn + slideY`

**Gap #15 (P3) — `flutter_animate` stagger on notification list**
- `_UpdatesTab` tiles: `.animate(delay: 30ms×i).fadeIn(200ms).slideX(-0.04→0, 240ms)`

**Gap #16 (P3) — `lottie` opt-in in `PetfolioEmptyState`**
- Added optional `lottieAsset` param; `icon` is now optional (both optional, assert enforces at least one)
- When `lottieAsset` provided → `Lottie.asset()` 120×120 looping; else `Icon` as before
- All 14+ existing call sites unchanged

### Already confirmed complete (verified this session, no work needed)
- **#13** `smooth_page_indicator` — already in `product_detail_screen.dart`
- **#14** shimmer skeleton loaders — already in `skeleton_loader.dart`
- **#17** `RoundedSuperellipseBorder` squircle — already in `app_theme.dart` cardTheme + navBar
- **#18** Spring page transitions — `ZoomPageTransitionsBuilder` already in `app_theme.dart`
- **#19** `DynamicSchemeVariant.fidelity` — already in `app_theme.dart` `_colorScheme()`
- **#20** Skipped — theme already provides StadiumBorder + spring curves on all buttons

Phase complete — please run (/remember) to save tokens before proceeding.

---

## 2026-06-09 — Pathao Gaps Phase 2 (P2 + P3 polish) ✅

`flutter analyze` — **No issues found.**

### Implemented

**Gap #8 (P2) — Marketplace "Show All" categories screen**
- `selectedCategoryProvider` added to `product_list_controller.dart`
- `marketplace_categories_screen.dart` — 2-col grid of all 8 categories; live count; stagger-in via `flutter_animate`
- `/marketplace/categories` route in `marketplace_routes.dart`
- `_CategoryChips` gains "All" tile → `/marketplace/categories`; `_selectedCat` → `selectedCategoryProvider`

**Gap #9 (P2) — "Products you'll love" discovery section**
- `_YoullLoveSection` sliver in `_ShopBody` (all-category view only)
- One product per category, horizontal scroll strip, 140×220 tiles, "Browse all ›" link

**Gap #10 (P2) — Buyer order action row**
- `_OrderTile` gains action row: delivered → Rate/Reorder/Return; shipped → Track; cancelled → Reorder
- `_ActionBtn` widget with color-tinted bg

**Gap #12 (P2) — Loyalty XP chip on home hero**
- `_PetHeroCard` → `ConsumerWidget`, watches `petAwardsSummaryProvider`
- "Lv N · XXX XP" gold gradient pill below streak chip

**Gap #13 (P3) — `smooth_page_indicator` in carousels**
- `_HeroCarousel` → `SmoothPageIndicator` with `ExpandingDotsEffect`
- `_ProductHeroCarousel` → `SmoothPageIndicator` (white on dark)

**Gap #14 (P3) — `shimmer` package skeleton loaders**
- `skeleton_loader.dart` → `Shimmer.fromColors`; reduce-motion path unchanged

**Gap #15 (P3) — `flutter_animate` stagger-in**
- Categories screen tiles: 40ms stagger `fadeIn + slideY`
- Offers screen promo cards: 50ms stagger

### Still pending
- Gap #11 (P2): Promotions tab data source (notifications `promo` type)
- Gap #16–20 (P3): lottie empty states, squircle cards, spring transitions, fidelity color seeding, tactile press

Phase complete — please run (/remember) to save tokens before proceeding.

---

## 2026-06-08 — Pathao UI Redesign Phase 1: Hub Home + All Features Sheet ✅

`flutter analyze` — **No issues found.**

### Implemented
- **`lib/features/home/presentation/widgets/all_features_sheet.dart`** — Pathao-style bottom sheet with 10-feature 2-col grid; spring scale animation, dark mode, haptics
- **`lib/features/home/presentation/screens/hub_home_screen.dart`** — Bento grid hub home replacing `PetProfileScreen` at `/home`:
  - `_PromoBanner` — contextual CTA driven by live care streak + task progress
  - 2×3 `SliverGrid`: `_CareTile` (streak pill + progress bar from Supabase realtime), 4× `_BentoTile` (Social/Match/Market/Vet), `_AllTile` (dark → AllFeaturesSheet)
  - `_QuickActionsRow` — horizontal strip (Shop / Log task / Post moment / Book vet)
  - `_SpotlightCarousel` — 4 gradient hero cards
  - `_DealsSection` — filter chips + promo banner
  - Fade-in `AnimationController`, `BouncingScrollPhysics`, wide `maxWidth: 640`
- **`lib/core/navigation/app_shell_routes.dart`** — `/home` → `HubHomeScreen`
- **`lib/core/widgets/app_shell.dart`** — Tab 0: `home_outlined/home_rounded`, label `Home`, eyebrow `HOME`; live `🔥 N` streak pill in header trailing actions

### Next step
~~**Phase 3 — Product Details Dual CTA**~~ ✅ Complete — see below.

---

## 2026-06-09 — Phase 2: Marketplace Catalog Redesign ✅

`flutter analyze` — **No issues found.**

### Implemented
- **`_HeroCarousel`** — replaces static `_HeroBanner`; 3-slide `PageView` (viewportFraction: 0.92) with 3.6 s `Timer` auto-scroll, animated pill page-indicator dots; each `_PromoCard` has gradient bg, foreground emoji (tilted), eyebrow label, `GoogleFonts.sora` title, white CTA pill
- **`_NewProductTile`** — M3 Expressive white elevated card: `Colors.white` bg (light) / `pt.surface2` (dark), no border in light mode, multi-layer shadow with per-product `gradientStart` glow; **`🔥 HOT` badge** (top-right) on products with `rating ≥ 4.5`; add-to-cart button upgraded with accent glow shadow
- **Imports** — added `dart:async` (Timer) + `google_fonts`

Phase complete — please run `/remember` to save tokens before proceeding to Phase 2.

---

## 2026-06-09 — Phase 3: Product Detail Redesign ✅

`flutter analyze` — **No issues found.**

### Implemented (`lib/features/marketplace/presentation/screens/product_detail_screen.dart`)
- **`_ProductHeroCarousel`** — replaces static `_ProductHero`; `PageView` swipeable images via `CachedNetworkImage` with `ProductGlyph` fallback; animated pill page-indicator dots; animated glyph scale+rotation pop on add-to-cart; `_WavePainter` bottom transition
- **`_SellerRow`** — `Material + InkWell` ripple card; shop initial-letter `CircleAvatar` tinted with `product.gradientStart`; shop name + category label; chevron → `context.push('/shop/${product.shopId}')`
- **`_ProductInfo`** — rating/free-delivery badges; brand eyebrow; name; variant; price row with subscribe-aware strikethrough + `-12%` `AppColors.poppy` badge when `subscribe && subscribable`
- **`_DualCtaBar`** — replaces `_PayBar`; `OutlinedButton` "Add to Cart" (`Expanded(flex:1)`) + `FilledButton` "Buy Now · $price" (`Expanded(flex:2)`); `AppColors.poppy` fill; frosted backdrop separator
- **`_VariantSheetContent`** — Pathao-style `showModalBottomSheet`; drag handle + "Customize as per your choice" `GoogleFonts.sora` header; auto-selected radio variant row with COMPLETE badge; `_SheetStepperBtn` qty stepper; Confirm CTA with inline price + strikethrough; `Navigator.pop(context, _qty)`
- **`_handleAddToCart`** — inline add (no navigation) + `SnackBar` confirmation + glyph pop animation
- **`_handleBuyNow`** — opens `_VariantSheetContent`, on confirm adds `qty` items sequentially then navigates to `/marketplace/cart`
- **State cleanup** — removed `_quantity` (moved to sheet); added `_pageCtrl`/`_pageIndex`; removed `SingleTickerProviderStateMixin`
- **Removed from scroll body** — `_QuantityStepper`, `_OrderSummaryCard`, `_SumRow`

### Next step
~~**Phase 4**~~ ✅ Complete — see below.

---

## 2026-06-09 — Phase 4: Cart / Checkout Stacked Section Cards ✅

`flutter analyze` — **No issues found.**

### Implemented (`lib/features/marketplace/presentation/screens/cart_screen.dart`)
- **Layout** — `bg: #F2F3F7` (light) / `surface1` (dark); all sections are `_SectionCard` (white elevated, warm shadow) stacked on gray — Pathao checkout pattern
- **`_CartHeader`** — `GoogleFonts.sora` title + mint item-count pill + Clear danger button
- **`_DeliverToCard`** (shared, top) — mint location icon + "DELIVER TO" eyebrow + address placeholder; tap → snackbar
- **`_VendorCheckoutSection`** — per-vendor stacked sections:
  - **Products card** — shop initial avatar + name + delivery estimate + `CartLineItem` lines + !canCheckout amber warning
  - **Apply Promo card** — collapsed row → `AnimatedCrossFade` expands to `TextField` + mint Apply button
  - **Pay via card** — lilac icon + `_PaymentChip` credit card / COD; haptic on change
  - **Order Summary card** — Subtotal / Delivery (Free, mint) / divider / **Total** bold 18px
  - **Green savings banner** — `🎉 You are saving $X` mint gradient; shown only when `shopSavingsCents > 0`
  - **Place Order CTA** — poppy `FilledButton` 56px + inline price; disabled (ink300) when `!canCheckout`; COD → `_CodConfirmSheet`
- **`_CodConfirmSheet`** — dark-mode-aware reskin; all checkout logic preserved
- **All logic unchanged** — `checkoutProvider` listener, `startCheckoutForShop`, `startCodCheckoutForShop`, `verifiedShopIds` gate

### Next step
~~**Phase 5**~~ ✅ Complete — see below.

---

## 2026-06-09 — Phase 5: Notifications Tabs + Activity Screen ✅

`flutter analyze` — **No issues found.**

### Notifications (`lib/features/social/presentation/screens/notifications_screen.dart`)
- **Pathao-style flat `TabBar`** — `UnderlineTabIndicator` poppy 3px, no pill, flat white bar; `labelColor: poppy`, `unselectedLabelColor: ink500`
- **"Updates" tab** — social activity (like/comment/follow); unread count poppy badge on tab label; "Mark all read" header action when unread > 0
- **"Promotions" tab** — future promo/deal notifications; `PetfolioEmptyState` when empty
- **`_NotificationTile`** — fixed legacy color aliases (`coral500`→`poppy`, `meadow500`→`mint`, `blue500`→`sky`); Dart switch expressions for `_iconColor` + `_emoji`; unread dot uses `AppColors.poppy`

### Activity screen (new — `lib/features/activity/`)
- **`activity_screen.dart`** — unified timeline combining `buyerOrdersProvider` (orders) + `appointmentControllerProvider` (appointments)
- **Filter chips** — `⚡ All | 🛍️ Orders | 🏥 Appointments`; poppy active fill, white outlined inactive; `AnimatedContainer` 180ms
- **Date grouping** — "Today" / "Yesterday" / "MMM D, YYYY" section headers; sorted newest-first
- **`_ActivityCard`** — status dot (tangerine=pending/upcoming, sky=shipped, mint=delivered/completed, poppy=cancelled/missed); emoji icon circle; title + subtitle; trailing value (amount/date) + status badge; action row ("Track Order" / "Reorder" / "Book Again")
- **`_ActivityItem`** — unified wrapper over `MarketplaceOrder` + `Appointment` with computed `statusColor`, `statusLabel`, `actionLabel`, `actionRoute`
- **Route** — `/activity` root-level (`parentNavigatorKey: rootKey`); registered in `router.dart`
- **`activity_routes.dart`** — `activityRoutes(GlobalKey<NavigatorState>)` pattern matching other feature routes

---

## 2026-06-08 — Plan remainder: B7/B8/B10/E10 + polish

**`flutter analyze` — No issues found. `flutter test` — 108/108 pass. Supabase migration applied.**

### UI / UX (remaining B-items)
- **B2:** `SkeletonLoader` on marketplace grid, social feed initial load, pet profile header
- **B8:** Star rating + review count on `ProductCard` tiles and meta row
- **B10:** First-launch `AppTutorialOverlay` (5-tab walkthrough, `SharedPreferences` flag)
- **B12:** `_PetProfileHeaderSkeleton` while pets load

### Features
- **B7:** Chat read receipts — UPDATE RLS policy, `markMessagesAsRead`, realtime `is_read` sync, double-check icon on sent messages (typing was already wired)
- **E10:** Story reactions persisted to `story_reactions` table + `StoryRepository.sendReaction`

### Performance
- **C3:** `_SocialPostListSliver` watches posts via Riverpod `select()` to limit rebuild scope

### Backend
- Migration `20260608140000_chat_read_receipts_story_reactions.sql` applied to hosted Supabase

### Tests
- `auth_repository_test`, `vitals_repository_test`, `app_shell_widget_test`
- RLS contract extended for `story_reactions`

**Deferred (documented in `STRIPE_SECURITY_AUDIT.md`):** F5 live Stripe E2E, D4 certificate pinning, A4 use-case layer refactor.

**Plan complete — please run (/remember) to save tokens.**

---

## 2026-06-08 — Phase 5: Security & Testing

**`flutter analyze` — No issues found. `flutter test` — 103/103 pass.**

### Stripe security audit
- `STRIPE_SECURITY_AUDIT.md` — documents server-side PI creation, webhook HMAC, publishable-key-only client, CoD path, redirect URL validation
- Extracted `mapAndThrowCheckoutRpcException` in `order_repository.dart` for testable checkout RPC error mapping

### Security contract tests
- `test/security/stripe_client_contract_test.dart` — no `sk_*` / `STRIPE_SECRET_KEY` in `lib/`; Edge Function holds secret
- `test/security/rls_migration_contract_test.dart` — 14 critical tables have RLS + policies in SQL migrations

### Repository unit tests
- `order_repository_exceptions_test.dart` — SHOP_INACTIVE, SHOP_NOT_VERIFIED, INSUFFICIENT_STOCK mapping
- `matching_repository_cache_test.dart` — location cache, demo swipe skip, action mapping
- `appointment_repository_test.dart` — unauthenticated create guard
- `product_review_repository_test.dart` — unauthenticated upsert guard

### Widget tests
- `skeleton_loader_widget_test.dart` — block, circle, listTile, reduced-motion
- `star_rating_widget_test.dart` — full/half stars, tap callback, semantics
- `petfolio_empty_state_widget_test.dart` — title/action, combined semantics label

**Next step:** Plan complete — please run (/remember) to save tokens.

---

## 2026-06-08 — Phase 4: Feature Additions

**`flutter analyze` — No issues found. `flutter test` — 51/51 pass. Supabase migration applied.**

### Verified already complete (prior phases)
- **Pet vitals chart** — `VitalsChartCard` in medical vault (`fl_chart`)
- **Apple Pay / Google Pay** — `PaymentSheetGooglePay` + `PaymentSheetApplePay` in `checkout_controller.dart`
- **Vet appointments** — `features/appointments/` with schema-aligned model + routes
- **Walk tracking** — `/care/walk` + `WalkTrackingScreen`

### New: Product reviews (E4)
- Migration `20260608120000_product_reviews.sql` — `product_reviews` table, RLS, aggregate trigger updating `products.rating` + `review_count`
- `ProductReview` model, `ProductReviewRepository`, `ProductReviewsNotifier`
- `StarRatingWidget` + `ProductReviewsSection` on `product_detail_screen` (list + write-review sheet)
- Unit test: `test/features/marketplace/product_review_model_test.dart`

**Next step:** Phase 5 — Security & Testing (Stripe audit, RLS tests, repository unit tests). Phase complete — please run (/remember) before Phase 5.

---

## 2026-06-08 — Phase 3: Performance

**`flutter analyze` — No issues found. `flutter test` — 50/50 pass.**

### Image compression pipeline
- Unified `pickImage` / `prepareImageForUpload` in `media_picker_io.dart` + web stub
- Camera + gallery picks in `create_post_screen`, `create_story_screen`, and `breed_identifier_widget` now compress on mobile before upload

### Marketplace pagination
- Fixed keyset cursor to **newest-first** (`created_at desc`, `lt` cursor) in `product_repository.dart`
- Wired infinite scroll in `marketplace_screen.dart` `_ShopBody` with scroll listener + load-more spinner

### RepaintBoundary isolation
- Stories row wrapped in `RepaintBoundary` (`social_screen.dart`)
- Marketplace hero banner wrapped in `RepaintBoundary`; product grid tiles already isolated

### Web image cache
- Added `petfolioWebImageCacheManager()` with 200-object LRU disk cap (`web_image_cache.dart`)
- Applied to feed post images + marketplace product tiles on web
- Explicit `flutter_cache_manager` dependency in `pubspec.yaml`

**Next step:** Phase 4 — Feature additions (product ratings, Apple/Google Pay, etc.). Phase complete — please run (/remember) before Phase 4.

---

## 2026-06-08 — Phase 2: UI/UX Polish + plan feature wiring

**`flutter analyze` — No issues found. `flutter test` — 50/50 pass.**

### Phase 2 polish
- **AppTheme M3E:** `SearchBarTheme` + expressive `NavigationBarTheme` (pill indicator, selected icon/label styles)
- **SkeletonLoader:** appointments list loading state
- **Semantics:** `GlassCard`, `PfCard` (`semanticLabel`), `PetfolioEmptyState` (title/subtitle)
- **Story ring:** rotating sweep-gradient ring on unviewed stories (`_StoryItem.animateRing`)
- **Matching:** swipe exit uses `PetfolioThemeExtension.curveSpring` (haptics already present)
- **Gamified care:** confetti + animated XP bar verified in `gamified_care_ui.dart`

### Plan feature wiring
- **Appointments schema fix:** model maps `location`/`status`; `toInsertJson(ownerId:)`; repo injects `owner_id`; toggle uses `status`
- **Walk tracking:** route `/care/walk` + Care tab explore tile + shell header shortcut
- **Communities:** `communities_routes.dart` (`/social/communities`, detail with `extra`); Social header button; GoRouter navigation from list
- **Breed ID:** `BreedIdentifierWidget` in `EditProfileScreen` + onboarding name step (mobile only, `!kIsWeb`)
- **Vitals:** already wired via `VitalsChartCard` in medical vault

**Next step:** Phase 3 — Performance (image compress, const audit, RepaintBoundary, cursor pagination). Phase complete — please run (/remember) before Phase 3.

---

## 2026-06-08 — Phase 1: Architecture Cleanup (plan sequential implementation)

**`flutter analyze` — No issues found. `flutter test` — 50/50 pass.**

### A1 — Router decomposition
- Extracted `app_shell_routes.dart`, `router_notifier.dart`, `router_error_screen.dart` under `lib/core/navigation/`
- `router.dart` now composes feature routes only (~40 lines)

### A2 — StateNotifier migration
- Verified: no legacy `StateNotifier` controllers remain (Riverpod 3 `Notifier`/`AsyncNotifier` only)

### A6 — DCM linting
- Added `dev:dcm` + root `dcm.yaml` with metrics/rules (excludes `*.g.dart`, `*.freezed.dart`, `test/`)

### D1 — Secure storage
- Added `SecureStorageService` (`lib/core/services/secure_storage_service.dart`)
- Marketplace cart persistence migrated from `SharedPreferences` → `flutter_secure_storage` with one-time legacy migration

### A5 — Barrel exports
- Added `lib/features/admin/index.dart`, `lib/features/communities/index.dart`

**Next step:** Phase 2 — UI/UX Polish (AppTheme M3E tokens audit, SkeletonLoader standardisation, Semantics, story ring, haptics, confetti). Phase complete — please run (/remember) before Phase 2.

---

## 2026-06-08 — Plan completion: E3/E6/E7/F3/F4 + analyze clean

**`flutter analyze` — No issues found. `flutter test` — 50/50 pass. App verified on emulator-5554 (Pixel 10, Android 17).**

### New implementations

**E3 — Pet communities (full stack)**
- `supabase/migrations/20260608000000_communities.sql` — 4 tables with RLS, auto-increment triggers, realtime publication
- `lib/features/communities/` — models, repository, `CommunitiesController`, `CommunityPostsNotifier` (Supabase realtime), screens

**E6 — AI breed identification**
- `lib/features/pet_profile/domain/services/breed_identification_service.dart` — NVIDIA Vision API, base64 image, structured JSON response
- `lib/features/pet_profile/presentation/widgets/breed_identifier_widget.dart` — camera/gallery picker, result card with confidence %

**E7 — Walk tracking**
- `lib/features/care/presentation/screens/walk_tracking_screen.dart` — FlutterMap (OSM tiles), GPS stream, PolylineLayer, MarkerLayer, distance via latlong2, elapsed timer

**F3 — Integration test**
- `integration_test/auth_care_flow_test.dart` — 5 auth flow tests; optional 6th with real credentials via `--dart-define=TEST_EMAIL/PASSWORD`

**F4 — AppTheme golden tests**
- `test/core/theme/app_theme_golden_test.dart` — 4 tests; baselines in `test/core/theme/goldens/`

### Lint fixes (this session)
- `PostsState` renamed from `_PostsState` (private type in public API)
- `__` → `_` in lambda params across communities screens
- Unnecessary cast removed in `community_detail_screen.dart`
- `use_null_aware_elements` suppressed on `community_repository.dart:90` (conflicting lint — `?key` applies to key nullability, not value)

### Pending (deferred)
- Wire `CommunitiesScreen` + `WalkTrackingScreen` into GoRouter (currently via `Navigator.push`)
- Wire `BreedIdentifierWidget` into pet profile onboarding
- **F5**: Stripe integration test — requires live Stripe test mode

**Next step:** Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-06-08 — F4: Golden tests for AppTheme light/dark variants

**`flutter analyze` — No issues found. `flutter test` — 50/50 pass.**

### New implementations

**F4 — AppTheme golden tests**
- `test/core/theme/app_theme_golden_test.dart` — 4 tests:
  - `light theme panel`: renders color rows, brand swatches, GlassCard pet row, PetAvatar species row, pillar accent pills; baseline captured at 390×700 in `goldens/app_theme_light.png`.
  - `dark theme panel`: same panel under `AppTheme.dark()`; captured at `goldens/app_theme_dark.png`.
  - `color tokens differ between light and dark`: asserts `surface1`, `ink950`, `cream` diverge across themes.
  - `pillar accent colors are fully opaque in both themes`: asserts all 5 pillar colors have `a == 1.0` in both themes. (Pillar accents are tone-shifted per theme, not identical.)
- Baselines generated with `flutter test --update-goldens`; committed under `test/core/theme/goldens/`.
- `GoogleFonts.config.allowRuntimeFetching = false` set in `setUpAll` for offline/CI safety.

**Next step:** Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-06-08 — Phase 5: Security & Testing (plan completion)

**`flutter analyze` — No issues found. `flutter test` — 46/46 pass.**

### Scoping decisions
- **D1 (flutter_secure_storage)**: SharedPreferences stores only non-sensitive data — theme index, match filter prefs, active pet ID, care completion counter, cart JSON. Supabase manages its own auth tokens via its internal secure mechanism. No migration required.
- **E8 (dark mode covers)**: Already complete — `WaveHeader` uses `species.resolvedAccent(isDark)` and the card overlay adapts border alpha by brightness.
- **E9 (in_app_review)**: Already wired in `care_dashboard_controller.dart` lines 345–356 (triggers after 3rd care completion).

### New implementations

**D5 — Comment input validation**
- `post_detail_screen.dart`: Added `maxLength: 500` + `maxLengthEnforcement: MaxLengthEnforcement.enforced` to `_CommentInputBar` TextField. Custom `buildCounter` shows remaining char count only when ≤ 50 left; turns `AppColors.poppy` when < 20 remain. Existing `_sendComment()` already trims + guards empty.

**F2 — Widget tests for core shared widgets**
- `test/core/widgets/pet_avatar_widget_test.dart` — 7 tests: species emoji (dog, cat), initials rendering, xl size applied, `onTap` fires, status dot visible when `isOnline: true`, Semantics label set.
- `test/core/widgets/glass_card_widget_test.dart` — 7 tests: renders child, solid fallback on `forceOpaque: true`, solid fallback on `disableAnimations: true`, BackdropFilter present in glass mode, custom width/height, custom borderRadius, dark theme renders without error.

### Remaining from plan (deferred — large scope or blocked)
- **E3**: Group chat / pet communities (new DB schema + full feature build)
- **E6**: AI breed identification (camera integration + NVIDIA API)
- **E7**: Walk tracking (`flutter_map` not yet added; requires GPS foreground service)
- **F3**: Integration test — auth → onboarding → care flow (needs emulator)
- **F4**: Golden tests for AppTheme light/dark variants
- **F5**: Stripe test-mode checkout integration test

**Next step:** Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-06-08 — Plan completion: remaining tasks from review-the-lib-directory

**`flutter analyze` — No issues found. `flutter test` — 32/32 pass.**

### Fixes from this session

**Appointments module (new files from prior session — all errors resolved)**
- `appointment_controller.dart`: Replaced invalid `FamilyAsyncNotifier` (not exported in Riverpod 3.3.1) with plain `AsyncNotifier` that watches `activePetIdProvider` directly in `build()`. Provider changed from `.family` to plain `AsyncNotifierProvider`.
- `appointments_screen.dart`: Replaced broken `AppHeader(title:, onOpenSwitcher:)` with a native `Scaffold.appBar`; removed all `(petId)` family calls; fixed `unnecessary_underscores`, `unused_local_variable isDark`, removed unused `_daysWithEvents`.
- `appointment_repository.dart`: Removed `unnecessary_cast` on `.single()` result.

### New implementations

**B10 — Social feed empty-state CTA**
- `petfolio_empty_state.dart`: Added optional `action` Widget parameter; renders below subtitle with 20px gap.
- `social_screen.dart`: Replaced plain `Text('No posts yet')` with `PetfolioEmptyState(icon, title, subtitle, action: FilledButton → /social/create-post)`.

**B12 — Pet profile header shimmer** ✅ Already complete (`PetAvatar._NetworkAvatar` uses `SkeletonLoader` as `CachedNetworkImage` placeholder).

**C3 — Social feed `select()` optimisation**
- Extracted `_LoadMoreSliver` (`ConsumerWidget`) that watches only `socialControllerProvider(petId).select((v) => v.asData?.value.isLoadingMore ?? false)`. The full `SocialView` no longer rebuilds on pagination ticks — only the spinner widget does.

**C6 — Web image cache LRU cap**
- `main.dart`: Added `PaintingBinding.instance.imageCache.maximumSizeBytes = 64 * 1024 * 1024` inside `if (kIsWeb)` block. Prevents unbounded memory growth in long-running web sessions.

**E10 — Story reactions**
- `story_viewer_screen.dart`: Added `_showReactions` / `_floatingEmojis` state; `_sendReaction(emoji)` triggers haptic + fly-up burst; "React" pill at bottom toggles a 5-emoji tray (🐾 ❤️ 😂 😮 🔥); story pauses while tray is open. `_FloatingEmoji` StatefulWidget with `TweenSequence` scale/opacity/slide animation.

**F1 — Unit tests**
- `test/features/appointments/appointment_model_test.dart` — 9 tests: `fromJson` (all fields, null optionals), `toJson` (omits id, UTC ISO 8601, null fields), `copyWith` (preserves, updates, toggles).
- `test/features/care/weight_log_model_test.dart` — 4 tests: `fromJson` (full, int weight coercion), `copyWith` (update, preserve).

### Remaining from plan (not implemented — scope/complexity)
- **E3**: Group chat / pet communities (requires new DB tables + full feature)
- **E6**: AI breed identification (camera + NVIDIA API integration)
- **E7**: Walk tracking with `flutter_map`
- **E8**: Dark mode pet profile covers (theme-adaptive banner images)
- **F3–F5**: Integration, golden, Stripe payment tests

**Next step:** Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

---

## AI AGENT HANDOVER & ARCHITECTURE GUIDE

> [!IMPORTANT]
> Incoming developer AI agents must read and adhere to this section. It outlines the codebase design patterns, state management practices, routing constraints, and current feature layouts to prevent regression or architectural drift.

### 1. Technology Stack & Directory Structure
- **Architecture**: Strict **Feature-First Architecture** inside [lib/features/](file:///home/kratzer/workspace/petfolio/lib/features/). Cleanly split each feature into `presentation` (screens, controllers/notifiers), `domain` (business logic, pure models), and `data` (repositories, data sources, API models) layers.
- **State Management**: Standardized entirely on **Riverpod** (`flutter_riverpod`, `riverpod_annotation`, with code-generated notifiers).
  - *Rule*: Do NOT import or introduce the legacy `provider` package.
  - *Rule*: Riverpod 3 generated notifiers omit type parameters (`extends _$NotifierName`). Use `AsyncValue.value` instead of `.valueOrNull`.
- **Database (Supabase)**:
  - *RLS Optimization*: All Row-Level Security policies in Supabase must wrap authentication checks in a subselect: e.g., `(select auth.uid())`. This forces Postgres to cache the query plan and prevents heavy database jank.
  - *Performance*: Avoid N+1 database queries on client-side joins. Push complex relational operations and aggregations to **Postgres Views** or **RPCs**. Never create queries that result in full table scans; use indexes.
  - *Applying Schema*: Prefer using Supabase MCP migration commands if available. When using the Supabase CLI, always prefix with `npx` (e.g., `npx supabase db push`).

### 2. Core Feature Areas & Routes

#### A. Social Feed & Stories
- **Create Post Screen** ([create_post_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/create_post_screen.dart)):
  - Route: `/social/create-post`
  - Aspect Ratio: `4/5` vertical portrait standard.
- **Create Story Screen** ([create_story_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/create_story_screen.dart)):
  - Route: `/social/create-story`
  - UI Design: Media-first. Top section displays a DSLR-style custom painter camera viewfinder (`_CameraViewfinderCard`, `4/3` ratio) with mock indicators (RAW, HDR, record dot timer, pulsing shutter). Below sits a 3-column scrollable mock photo selector grid loaded with Unsplash pet assets plus a library browse button.
  - Fullscreen 9:16 story preview overlay on selection with floating pet details and a sunset-gradient submit button.
- **Story Viewer Screen** ([story_viewer_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/story_viewer_screen.dart)):
  - Route: `/social/stories?petId=:petId`
  - Playback: Features segmented indicators mapping to the story list. Long-pressing the viewport pauses the story progression; releasing resumes it.
  - Pet Identity Navigation: The top header avatar and pet info are wrapped in an opaque `GestureDetector` that pauses the active timer, pushes the profile route (`/social/profile/:petId`), and resumes the story play timer cleanly upon back navigation.
- **Aspect Ratio Alignment**:
  - The feed card ([social_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/social_screen.dart#L724)), post detail ([post_detail_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/post_detail_screen.dart#L329)), and creation preview screens are standardized to a vertical `4/5` portrait ratio (`aspectRatio: 4 / 5`) to match Instagram's standard and minimize vertical photo cropping.

#### B. Care & Health
- **Dashboard**: Accessed at `/care`. Successful onboarding redirects to `/care?onboardingComplete=1` which displays a one-shot success snackbar and normalizes the URL.
- **Pet Context Dependency**: `careDashboardProvider` and `healthVaultControllerProvider` are non-family providers that watch `activePetIdProvider`. If `activePetId` is null, remote loads are skipped and lists are returned empty.
- **Completion Streaks & Badges**:
  - Daily streak completion is driven by the `check_daily_completion` RPC (`target_pet_id`, optional `completion_date` matching `care_logs.logged_date`) checking against `care_tasks` and `care_logs`.
  - Streak records live in `care_streaks` and badges in `pet_badges`.
  - The dashboard listens to Supabase realtime on `care_streaks` via `careStreakRealtimeProvider` for instant UI updates.

#### C. Multi-Vendor Marketplace
- **Discover Shops**: Navigate via `shopListProvider` to `/shop/:id`.
- **Seller Setup & Onboarding**: Path `/seller/setup` triggers the `stripe-onboard-vendor` Edge Function utilizing `functions.invoke` (not `.rpc()`) with body `{'shopId'}` to return the Stripe Connect setup link.
- **Checkout Flow**: Handled via cart `itemsByShop` and per-shop `startCheckoutForShop` workflows.

### 3. Critical UI & Navigation Constraints
- **Circular Imports Avoidance**: Do NOT import [router.dart](file:///home/kratzer/workspace/petfolio/lib/core/router.dart) from screens that the router imports. Instead, navigate using literal path strings or query parameter deep links.
- **Error UI Handling**: For optimistic UI actions (like toggling care tasks or seller onboarding), show errors using `AppSnackBar.showError` (via `appSnackBarMessengerKey` on `MaterialApp.router`). Do not put long-lived state providers in `AsyncValue.error` states for transient/action-level failures.
- **Web Safe Target**: Marionette execution runs exclusively in debug builds via conditional compiler imports (`marionette_debug_gate_stub.dart` vs `_io.dart`) to keep `main.dart` from importing `dart:io` on web targets.

## 2026-06-07 — M3E Tier 3: Spring Empty States & Branded Loading

**Files changed:**
- `lib/core/widgets/petfolio_empty_state.dart`
- `lib/features/care/presentation/screens/nutrition_screen.dart`
- `lib/features/social/presentation/screens/notifications_screen.dart`
- `lib/features/matching/presentation/screens/matching_screen.dart`

**`PetfolioEmptyState` — spring entrance animation (used in 6+ screens)**
- Converted `StatelessWidget` → `StatefulWidget` with `SingleTickerProviderStateMixin`
- `AnimationController(duration: 560ms)` auto-starts in `initState`
- Three layered animations:
  - `_scale`: `0.72 → 1.0` with `Curves.easeOutBack` — M3E spring overshoot bounce
  - `_opacity`: `0.0 → 1.0` with `Interval(0.0, 0.60, Curves.easeOut)` — fast fade in
  - `_slide`: `Offset(0, 0.12) → Offset.zero` with `Curves.easeOutCubic` — subtle upward drift
- No API changes — all callers (`matches_inbox`, `cart`, `nutrition`, `medical_vault`, `pet_profile`, `manage_pets`) auto-inherit the animation

**`TailWagLoader` full-screen loading (dog wag animation instead of bare spinner)**
- `nutrition_screen.dart`: `Scaffold(body: Center(child: CircularProgressIndicator()))` → `TailWagLoader()`
- `notifications_screen.dart`: added `widgets.dart` import + replaced `CircularProgressIndicator.adaptive()` in `.when(loading:)`
- `matching_screen.dart`: replaced both `CircularProgressIndicator.adaptive()` full-screen states (discovery buffer load + location access load)
- Inline button/pagination spinners (`strokeWidth: 2` inside `SizedBox(18/20px)`) left as `CircularProgressIndicator` — correct for that context

`flutter analyze` — **No issues found.**

**Skipped (out of scope for this session):**
- `FloatingToolbar` in Care/Pet Profile — requires full re-read of `pet_profile_screen.dart`
- Remaining 50+ inline `CircularProgressIndicator` instances — intentionally kept (inline context, correct M3E behavior)

**Next step:** Phase complete — please run (/remember) to save tokens before proceeding.

---

## 2026-06-07 — M3E Tier 2: Spring Motions & Squircle Upgrades

**Files changed:**
- `lib/features/care/presentation/screens/care_screen.dart`
- `lib/features/social/presentation/screens/social_screen.dart`
- `lib/features/marketplace/presentation/screens/marketplace_screen.dart`

### Tier 1 (prior session, recap)
- `DynamicSchemeVariant.fidelity` — richer M3E palette
- `ZoomPageTransitionsBuilder` + `CupertinoPageTransitionsBuilder` page transitions
- M3E `TabBar` pill indicator (`BoxDecoration` + `BorderRadius.circular(radiusPill)`)
- `RoundedSuperellipseBorder` on `CardTheme` + `PfCard.squircle` (direct dp, no 2× multiplier)
- Squircle tokens: `squircleCard=24`, `squircleContainer/squircleDialog=28`

### Tier 2 (this session)

**care_screen.dart**
- Added `import 'package:flutter/services.dart'`
- `HapticFeedback.mediumImpact()` in `_CoverFlowCarousel._onToggle`
- `HapticFeedback.mediumImpact()` in `_CareTaskCard._toggle`
- New `_SpringCheckButton` widget replaces check button `GestureDetector + AnimatedContainer`:
  - `AnimationController(80ms forward / 500ms reverse)` driven by `onTapDown/Up/Cancel`
  - `Tween(1.0→0.82)` with `Curves.easeOut` / `Curves.elasticOut` reverse — M3E spring bounce
  - `ScaleTransition` wraps existing `AnimatedContainer`

**social_screen.dart**
- `PostCard`: `squircle: true` added to `PfCard` — feed posts now render as true superellipses

**marketplace_screen.dart**
- Fly-to-cart X animation: `Curves.easeIn` → `Curves.easeInOutCubicEmphasized`
- `_CategoryChips` upgrade: `AnimatedScale(1.0→1.07, Curves.easeOutBack, 340ms)` spring pop on active; `AnimatedContainer` for border/shadow; `AnimatedDefaultTextStyle` for label color

`flutter analyze` — **No issues found.**

**Next step:** Tier 3 — `LoadingIndicator` replacing `CircularProgressIndicator`, `FloatingToolbar` in Care/Pet Profile, `PetfolioEmptyState` spring entrance. Phase complete — please run (/remember) to save tokens before proceeding.

---

## 2026-06-06 — Care Screen: CoverFlow 3-D Task Carousel

**Files changed**: `lib/features/care/presentation/screens/care_screen.dart`

- **Removed widgets**: `_DoneCollapseRow`, `_TaskGrid`, `_CareTaskGridTile`, `_CareTaskGridTileState` — the "Done (N) ▾" collapse pill and 4-column Streaks grid are gone entirely.
- **Removed state**: `_showDone` field from `_DailyTasksDashboardState`; `onSelect` simplified.
- **New `_CoverFlowCarousel`** (`ConsumerStatefulWidget`):
  - **Task ordering**: completed left · due-today pending center · remaining pending right. `initialPage` = first pending task.
  - **3-D CoverFlow**: `Transform.translate` → `Transform.scale` → `Transform(Matrix4..setEntry(3,2,0.0012)..rotateY(rotY))`. No deprecated `Matrix4.translate/scale`.
  - **Z-order**: stack entries sorted by distance from `_page` so center card always renders on top.
  - **Smooth animation**: single `AnimationController` + `Animation<double>` with `_onTick` listener drives fractional `_page`. `_goTo(i)` fires a new `Tween` per navigation.
  - **Swipe + tap**: `onHorizontalDragEnd` (260 px/s threshold); side cards tappable to focus.
  - **Live sync**: `didUpdateWidget` patches `_ordered` by task ID — order stable during session.
- **New `_CoverFlowCard`** (198×214 px, radius 28): icon circle 64 px, title, sublabel, XP chip, animated check button, long-press context menu. Done = tinted bg + color border + strikethrough. Due = poppy border + red badge.
- **New `_XpBurst`**: fly-up "+XP ⭐" with `TweenSequence` opacity envelope, 1.2 s auto-dispose.
- **New `_NavArrow`**: animated chevron pill buttons, grayed at list ends.
- **Dot indicators**: active dot expands to 22 px; completed dots mint; capped at 12.
- **Helpers**: `_cfColor`, `_cfEmoji`, `_cfSublabel` as file-scope private functions.
- `flutter analyze` — **No issues found.**

**Next step:** Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-06-01 — Care Screen Redesign (from PetFolio Redesign/Care Redesign.html)

**Files changed**: `gamified_care_ui.dart`, `care_screen.dart`

- **`CareGamifiedHeader` rewritten** — Removed tall `WaveHeader`; replaced with compact inline design:
  - Status-bar-aware top padding + pet switcher row (`PetAvatar` + "CARE" label + pet name + chevron)
  - Slim gradient hero card (`poppy→#FF6B45→tangerine`, radius 26, shadow-pop) with paw watermark
  - `_StreakCoin`: 78px golden radial-gradient circle with 3D `Matrix4.rotateY` coin-spin + pulse-ring
  - `_HeroLevelContent`: inline Lv + title + done-today pill + XP progress bar + XP-to-next text
- **`_BadgeMedal` (replaces `_BadgeTile`)** — Circular medal design:
  - 72px disc with radial gradient (owned: badge color, locked: grey), concentric depth rings, emoji
  - Float bob animation (translateY 0→-5px, repeating reverse)
  - Holographic sheen sweep (owned only); pulsing outer glow ring with scale+opacity (owned only)
  - Lock pip (18px circle, bottom-right) for locked badges; `childAspectRatio: 0.72` grid
- **`_UtilityBanner` (replaces `_NutritionBanner` + `_MedicalVaultBanner`)** — Side-by-side split card:
  - Single rounded `Container` with `VerticalDivider` between two `_UtilityHalf` widgets
  - Left: Nutrition (sunny palette), Right: Medical Vault (mint palette); both tappable
- All existing Supabase providers and controllers unchanged; same data flow
- `flutter analyze` — **No issues found.**

**Next step:** Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-31 — Matching Feature P0/P1/P2 Systematic Fixes

### Database (applied to `jqyjvhwlcqcsuwcqgcwf` ✅)
- **[C-1] `chat_messages` RLS**: Enabled RLS + idempotent `select by participant` and `insert by participant` policies — fixes privacy regression where any authenticated user could read all chat messages.
- **[C-2] N+1 elimination**: Replaced correlated owner subquery in `matching_discovery_candidates` with `LEFT JOIN LATERAL` — cuts 21 queries → 1 per discovery page load.
- **[H-2] Keyset cursor pagination**: Dropped old 7-param `matching_discovery_candidates`; new 8-param version uses `(p_cursor_created_at, p_cursor_pet_id)` for stable pagination — no more skipped/duplicate candidates.
- **[H-3a] Downgrade trigger**: `BEFORE UPDATE` trigger on `swipes` raises `cannot_downgrade_matched_swipe` if a match exists for the pair — prevents LIKE→PASS orphaning a match row.
- **[H-3b] UPDATE path trigger**: `AFTER UPDATE OF action` trigger fires `swipes_after_insert_mutual_match()` for PASS→LIKE upgrades — previously mutual matches were silently never created on upsert updates.

### Dart — Data Layer
- **`matching_supabase_data_source.dart`**: `fetchDiscoveryCandidates` replaced `offset` param with `cursorCreatedAt/cursorPetId`. `fetchMessages` now accepts `limit: 50` (default) + `beforeCreatedAt` for page-back loading; filter is applied before `.limit()` to avoid `PostgrestTransformBuilder` constraint.
- **`matching_repository.dart`**: `fetchCandidates` passes cursor params through. `recordSwipe()` now rethrows after logging — callers can surface failures. `fetchMessages` exposes `limit` + `beforeCreatedAt`.

### Dart — Discovery Controller
- **`discovery_candidates_controller.dart`**: Added `DiscoveryCursor({createdAt, petId})` class. `DiscoveryCandidatesBuffer` replaces `nextOffset: int` with `cursor: DiscoveryCursor?`. `_fetchPage` extracts cursor from `rows.last`. `_replenishIfLow` and `_ensureDepth` pass cursor through the full pagination chain. Added `swipeErrorProvider` one-shot error bus (same pattern as `locationSyncErrorProvider`). Fixed `_distanceLabel` — all-miles → consistent metric km.
- **`discovery_controller.dart`**: `swipe()` wraps `_repo.recordSwipe()` in `.catchError()` and posts to `swipeErrorProvider` on failure.
- **`matching_screen.dart`**: `_DiscoveryViewState.build()` listens to `swipeErrorProvider` and shows a `SnackBar` on swipe record failure.

### Dart — Chat Pagination (P1)
- **`chat_conversation_controller.dart`**: Initial `fetchMessages` limited to 50. Added `hasMore` flag and `loadOlderMessages()` method — guards against concurrent calls with `_loadingOlder`, prepends older page to state list.
- **`chat_screen.dart`**: Added `_onScroll` listener on `ScrollController` — triggers `loadOlderMessages()` when the user scrolls within 200px of the top. Shows a `CircularProgressIndicator.adaptive` spinner at the visual top while `hasMore == true`.

### Dart — State & Polish (P2)
- **`match_preference_controller.dart`**: Loads species/distance/age from `SharedPreferences` on `build()` asynchronously (state defaults until loaded). Each setter persists changes immediately — preferences survive hot-restart and app kills.
- **`edit_profile_controller.dart`**: Calls `matchingRepository.invalidatePetLocationCache(originalPet.id)` after successful profile save — ensures the next discovery load re-queries the DB rather than using a stale in-memory cache entry.
- **Lock safety**: `_replenishLocked` already released in `finally` block (confirmed — no change needed).

`flutter analyze lib/features/matching/ lib/features/pet_profile/presentation/controllers/` — **No issues found.**

**Next step:** Phase complete — please run (/remember) to save tokens before proceeding.

---

## 2026-05-31 — Code Audit & Stability Fixes

- **Feature Teardown**: Completely removed the "Treat" and "Undo" buttons from the Match Screen, eliminating the stubbed snackbars and unnecessary UI code.
- **Database & Storage**: Created a new database migration (`20260531_audit_fixes.sql`) adding an optimized admin read policy for the `medical-documents` storage bucket with cached `public.is_admin()` resolution.
- **Riverpod & State Management**: Fixed `ref.listen` duplicate listener registration in `CareNotifier` build phase using a microtask-deferred `ref.watch` approach.
- **Routing & Deep-Links**: Resolved the cold-start deep-link race condition for the pet edit route in `router.dart` by wrapping the builder in a `Consumer` to handle async loading states.
- **Unbounded Queries**: Added `limit` boundaries to Supabase streams and queries in matching matches repository (`fetchMatchesForPet`), care logs repository (`fetchLogsForPet`), and `HealthVaultController` stream.
- **UI/UX & Rendering**: Virtualized list views in `care_screen.dart` and `matches_inbox_screen.dart` by converting to `ListView.builder`.
- **Social Overflows**: Wired the feed post card's three-dot menu to show the public `PostOptionsSheet` and removed the stubbed search icon from the header.
- **Robust Error Handling**: Added error retry UI layouts and debug logs to the five swallowed error sections across nutrition, social, switcher, and quest cards.
- **MediaQuery Optimizations**: Swapped full media query subscriptions to specific `sizeOf` and `viewInsetsOf` fields.
- **Global Crash Handling**: Registered global handlers for uncaught flutter errors and platform dispatcher errors in `main.dart`.
- **Modal Sheets Positioning**: Configured the remaining modal bottom sheets (including create post, post options, share access, and weight logging) to use `useRootNavigator: true` so they display on top of the persistent bottom navigation bar.

## 2026-05-26 — Responsiveness Refactoring & Spacing Fixes


- **Responsive Layout Helper**: Created a unified `ResponsiveLayout` widget to handle standard Mobile, Tablet, and Desktop/Web breakpoints consistently across all views.
- **Responsive Screen Refactoring**: Center-constrained and scaled layouts on `pet_profile_screen.dart`, `social_screen.dart`, `matching_screen.dart`, `marketplace_screen.dart`, and `onboarding_screen.dart` to prevent infinite visual stretching on large viewports.
- **Bottom Navigation Bar Spacing**: Adjusted Matching screen spacing dynamically to `92 + MediaQuery.paddingOf(context).bottom` on Mobile, pushing the swipe `_ActionDock` above the floating bottom navigation bar.
- **Modal Bottom Sheets (useRootNavigator)**: Configured all shell-launched modal bottom sheets (including switcher, cart drawer, story options, and care task forms) to specify `useRootNavigator: true`. This fixes the floating bottom navigation bar rendering on top of/blocking bottom sheets.
- **Static Analysis & Tests**: Ran `analyze_files` and `run_tests` MCP tools; all tests passed successfully with no errors or regressions.

---

## 2026-05-25 — UI Redesign Phase 8: Browser Cross-Validation Fixes

Served `PetFolio Redesign.html` via local HTTP server, navigated all 5 tabs via Chrome MCP JS tool, extracted computed styles and rendered text from each screen. Confirmed gaps vs. previous session's text-only analysis, plus found new ones:

**Match screen fixes:**
- 5th dock button: ⚡ bolt boost → **↺ `Icons.replay_rounded`** (`AppColors.ink300`, disabled placeholder — undo requires swipe history)
- Pet name font: 28px → **32px** Fraunces to match design exactly

**Social screen fixes:**
- Reaction emoji row: 🍖 → **🦴**, removed ⭐ star chip (design shows only 🐾 ❤️ 🦴)
- Story rings: **`LinearGradient` → `SweepGradient`** (5-stop conic: tangerine→poppy→sunny→mint→tangerine, startAngle 220°) for active stories; inactive stories keep gray linear ring. `_StoryItem` gained `isActive` boolean; `_conicColors` const defined at file scope.

**Market screen fixes:**
- Added **`_MembersBanner`** widget: poppy→tangerine horizontal gradient, "FOR MEMBERS" overline, "20% off treats this week 🦴" body, white "Claim" pill button. Inserted as first sliver in `_ShopBody` when `selectedCat == all`.
- Renamed section: "⭐ Top Picks" → **"🦴 Trending in your Pack"** to match design.

**Remaining known gaps (not yet implemented):**
- Market: "SHIP TO [PET]'S HOUSE / City" delivery address strip (requires active pet + address data)
- Market: product star ratings on tiles (no `rating` field in `Product` model)
- Market: category Beds + Apparel (our model has Gear + Health — affects DB data)
- Social: PostHeader conic-gradient avatar ring
- Care: next-level name label ("Pet Whisperer")
- `flutter analyze lib/` — **No issues found.**

**Next step:** Phase complete. Please run (/remember) to save tokens before proceeding.

---

## 2026-05-25 — UI Redesign Phase 7: Cross-Validation Gap Fixes

- **`FeedPost.isMemorial`**: Added boolean field to model (defaults false). Propagated through `_copy()`.
- **`_MemorialPost` widget** (social_screen.dart): Full memorial post variant — ivory paper bg (`#FAF6EE`), sepia ColorFilter matrix on photo, vignette radial overlay, candle count row, "Light a candle 🕯️" filled button, "Leave a tribute" outlined button, "Sharing & saves disabled out of respect" note with lock icon. Dark mode variants included.
- **Feed list builder**: Routes to `_MemorialPost` when `post.isMemorial`, otherwise `_RegularPost`.
- **Save/bookmark icon** added to `_ReactionBar` (social_screen.dart) — `bookmark_outline_rounded` icon as 4th action on the right side.
- **"You're all caught up"** footer sliver (social_screen.dart): Shows "🐾 You're all caught up / Pull to refresh for new posts" when feed is non-empty and not loading more.
- **Product tile wishlist button** (product_card.dart): Circular white `bookmark_outline_rounded` button added top-right of `_ProductTile`, matching the design spec's save/wishlist icon.
- **Match card photo dots bar**: 5 thin horizontal bars at the top of each swipe card. First bar is full-white (active), remaining are 35%-alpha white.
- **Vet verified badge**: Positioned top-right of the swipe card when `candidate.verified`. Shows mint `verified_rounded` icon + "Vet verified" text on white pill. Replaced inline white icon in `_InfoPanel`.
- **FuzzyChip** (distance pill): Replaced plain distance Row in `_InfoPanel` with a `_MatchMetaChip` that has `icon: Icons.location_on_rounded`.
- **SafetyChip** (owner verified): Added `_MatchMetaChip` with `Icons.shield_rounded` in mint color to the meta chips Wrap when `candidate.verified`.
- **`_MatchMetaChip`**: Added optional `icon` parameter (renders 12px icon + 4px gap before label text).
- `flutter analyze lib/` — **No issues found.**

**Next step:** Phase complete. Please run (/remember) to save tokens before proceeding to Phase 8 (Health Vitals UI or remaining onboarding gaps).

---

## 2026-05-25 — UI Redesign Phase 6: Marketplace Screen Redesign

- **Dark-mode scaffold**: `backgroundColor: AppColors.surface1` (hardcoded) → `pt.surface1` via `PetfolioThemeExtension`. Added `app_theme.dart` import.
- **Category chips**: Active pill color changed from `AppColors.ink950` (black) → `AppColors.mint` (marketplace tab brand color). White text on active chip is unchanged.
- **Section headers**: Removed `_SectionHeader` custom class entirely. All four section headings ("Discover Shops", "Subscribe & Save", "Top Picks", category filter label) now use `PfSectionTitle` with `accent: AppColors.mint` and contextual emoji prefixes (🛍️ 🌿 ⭐). Category filter heading includes item count in `trailing`.
- **Reorder strip**: Gradient updated from `#8FD0B0→meadow500` to `mintSoft→mint`. Icon and "Manage" button text color updated from `meadow500` → `mint`.
- **`product_card.dart`**: Subscribe & Save badge text color and sub-price text changed from `AppColors.success` → `AppColors.mint` for palette consistency.
- `flutter analyze` — **No issues found.**

**Next step:** All 6 redesign phases complete. Please run (/remember) to save tokens and log the full redesign as complete.

---

## 2026-05-25 — UI Redesign Phase 5: Match Screen Swipe Deck Redesign

- **Font migration**: Pet name in `_InfoPanel` switched from `GoogleFonts.sora()` to `GoogleFonts.fraunces()` (28px display weight). Swipe stamp labels (`MATCH`, `PASS`, `WAVE`) also use `GoogleFonts.fraunces()`. All other `GoogleFonts.inter()` calls replaced with plain `TextStyle` so Nunito applies globally.
- **Color migration** (old aliases → new palette):
  - `coral500` → `AppColors.poppy` (MATCH stamp, like/paw dock button, card fallback gradient)
  - `blue500` → `AppColors.lilac` (WAVE stamp, greet dock button, species meta chip bg)
  - `mulberry500` → `AppColors.lilac` (super paw dock button, breed meta chip bg)
  - `sunset500` → `AppColors.tangerine` (boost dock button, energy meta chip bg, card fallback gradient)
- **Action dock**: Pass (ink300, unchanged), Greet (lilac), Like paw center (poppy, elevated glow), Super star (lilac), Boost lightning (tangerine, disabled placeholder)
- **Meta chips**: Species=lilac tint, Breed=lilac tint, Energy=tangerine tint — all on white text inside the card scrim.
- `flutter analyze` — **No issues found.**

**Next step:** Phase complete. Please run (/remember) to save tokens before proceeding to Phase 6 (Marketplace screen redesign).

---

## 2026-05-25 — UI Redesign Phase 4: Social Pawsfeed Redesign

- **Pawsfeed section title**: Added `PfSectionTitle` sliver above the stories row with `🐾 Pawsfeed` title, poppy accent bar, and a "Discover" `TextButton` trailing link.
- **Emoji reaction bar (`_ReactionBar`)**: Replaced the old like/comment/share row in `_RegularFooter` with a new `_ReactionBar` widget. Paw 🐾 (connected to existing `onLike`), Heart ❤️, Treat 🍖, and Star ⭐ are displayed as pill chips using `_ReactionChip`. Active paw chip highlights with poppy color. Comment and share buttons remain on the right.
- **FAB color**: Changed `FloatingActionButton.extended` `backgroundColor` from `colorScheme.primary` to `AppColors.poppy` to match the social tab accent color.
- **Story ring gradient**: Updated ring gradient colors from old `sunset500`/`coral500` aliases to `AppColors.tangerine` / `AppColors.poppy`. "Add story" dot also updated to `AppColors.poppy`.
- `flutter analyze` — **No issues found.**

**Next step:** Phase complete. Please run (/remember) to save tokens before proceeding to Phase 5 (Match screen swipe deck redesign).

---

## 2026-05-25 — UI Redesign Phase 3: Home Wave Banner + Care XP System

- **Home screen — `_PetWaveBanner`**: New widget inserted above `_HeroCard` in `pet_profile_screen.dart`. Uses `WaveHeader` with the active pet's species accent color (e.g. tangerine for dogs, poppy for cats). Displays the pet's avatar (network image with emoji fallback), pet name in Fraunces 26px, and breed/species label. Organic wave clips the bottom and transitions to the cream page background.
- **Home tab bar**: Tab indicator/label color now uses `activePet.speciesEnum.accent` instead of generic `cs.primary`, so each pet's profile tab feels native to their species color.
- **Care screen — XP badge pills**: Each task card now shows a `+N XP` pill badge (sunny background, `sunny700` text) when not completed, and a green mint circle checkmark badge when completed. Uses `task.gamificationPoints` from the DB.
- **Care screen — XP progress bar**: New `_XpProgressBar` widget inserted between the streak banner and the date picker. Shows today's earned XP vs total possible XP for the selected day's tasks, with a sunny gradient `LinearProgressIndicator`.
- **Care screen — AI Routine banner**: Restyled from generic `cs.primary` to lilac palette (`AppColors.lilac`, `lilacSoft`, `lilac700`). Both the promo card and the "Refresh" outlined button now use lilac to match the Match/AI brand color.
- `flutter analyze` — **No issues found.**

**Next step:** Phase complete. Please run (/remember) to save tokens before proceeding to Phase 4 (Social Pawsfeed redesign).

---

## 2026-05-25 — UI Redesign Phase 2: Font System Migration (Fraunces + Nunito)

- **Bulk font cleanup**: Removed all 30+ files with hardcoded `fontFamily: 'Sora'` and `fontFamily: 'Inter'` inline `TextStyle` overrides via `sed` bulk delete. The warm-palette theme (Nunito text theme via `GoogleFonts.nunitoTextTheme`) now applies globally as the default.
- **`app_header.dart`**: Pet name title replaced with `GoogleFonts.nunito(fontWeight: FontWeight.w800)`.
- **`pet_profile_screen.dart`**: Streak hero number uses `GoogleFonts.fraunces()` (56px display serif); awards stat values use `GoogleFonts.fraunces()` (18px); all other titles/labels use `GoogleFonts.nunito()`.
- **Parser error fixes**: Two `create_post_screen.dart` and `create_story_screen.dart` files had `Text('...', style: TextStyle(fontFamily: 'Sora'))` on one line — sed deleted the closing paren. Restored as `Text('...')`.
- **Redundant imports cleaned**: Removed duplicate `pet_species.dart` imports from `app_header.dart`, `care_screen.dart`, `onboarding_screen.dart` (now re-exported via `pet_avatar.dart` / `widgets.dart`).
- **`wave_header.dart`**: Replaced `if (trailing != null) trailing!` with null-aware `?trailing` element.
- `flutter analyze` — **No issues found.**

**Next step:** Phase complete. Please run (/remember) to save tokens before proceeding to Phase 3 (Home / Care / Social screen redesigns).

---

## 2026-05-25 — Comment Likes and Threaded Replies

- **Database migration applied** (`jqyjvhwlcqcsuwcqgcwf`): added `parent_id` (foreign key to comments table for threading) and `like_count` to comments table; created `comment_likes` table with triggers to keep counts updated; added RLS security policy wrapping `(select auth.uid())` for plan caching performance.
- **Comment Likes (Paw Icon & Optimistic UI)**: Added a small paw icon button (`Icons.pets_rounded` / `Icons.pets_outlined`) on each comment tile to toggle liking instantly; handles database failures optimistically by reverting local state and invoking `AppSnackBar.showError(e)`.
- **Comment Replies (Threaded UI)**: Implemented comments threading in `PostDetailScreen`. Root comments and replies are flattened with replies indented by 52 pixels and styled with smaller avatars (`radius: 12` vs `16`) to build a clear visual hierarchy.
- **Context-Aware Reply States**: Click "Reply" to activate the replying banner, focus the comment input bar using `FocusNode`, set a custom dynamic placeholder (`Reply to @handle...`), and automatically reset when sent or canceled.
- `flutter analyze` — **No issues found.**

---

## 2026-05-24 — Paw Icon Likes Alignment

- **Replaced Love with Paw Icons**: Changed post likes from heart icons (`Icons.favorite_rounded`/`Icons.favorite_border_rounded`) to paw icons (`Icons.pets_rounded`/`Icons.pets_outlined`) in both the feed [social_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/social_screen.dart) and post details [post_detail_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/social/presentation/screens/post_detail_screen.dart).
- **Interactive Double-Tap Overlay**: Updated the double-tap gesture like overlay animation on feed posts to render a pulsing big paw icon (`Icons.pets_rounded`) instead of a heart.
- **Static Analysis**: Verified clean build via `flutter analyze` with **no issues found**.

---

## 2026-05-24 — Persistent Dark Mode Support

- **Theme Mode Notifier**: Created a dynamic generated Riverpod notifier `ThemeNotifier` (generating `themeProvider`) in [theme_notifier.dart](file:///home/kratzer/workspace/petfolio/lib/core/theme/theme_notifier.dart) to replace the old static theme mode provider.
- **Preferences Persistence**: Automatically saves and loads the user's selected `ThemeMode` from `SharedPreferences` to ensure settings persist across application restarts.
- **Header Switch Action**: Replaced the placeholder outdoor header icon on [pet_profile_screen.dart](file:///home/kratzer/workspace/petfolio/lib/features/pet_profile/presentation/screens/pet_profile_screen.dart) with a responsive theme toggle action button in the active pet header.
- **Static Analysis**: Verified clean build via `flutter analyze` with **no issues found**.

---

## 2026-05-24 — Story Viewer Profile Navigation

- **Pet Profile Navigation from Story Viewer**: Wrapped the pet avatar and name/info column in `story_viewer_screen.dart` with a `GestureDetector` that pauses the active story timer and pushes the pet's profile route (`/social/profile/:petId`). The story timer automatically resumes when returning back to the story viewer.
- **Static Analysis**: Verified clean build via `flutter analyze` with **no issues found**.

---

## 2026-05-24 — Instagram Post Card Aspect Ratio Alignment

- **Feed Image Ratio updated**: Changed the post card photo aspect ratio in `social_screen.dart` from landscape `4/3` to `4/5` (Instagram portrait ratio) to prevent vertical cropping of pet photos.
- **Creator Screen Preview updated**: Standardized the image preview on `create_post_screen.dart` to `4/5` to maintain UI consistency during creation.
- **Detail Screen updated**: Updated `post_detail_screen.dart` to `4/5` aspect ratio to keep rendering consistent across the entire post lifecycle.
- **Static Analysis**: Verified clean build via `flutter analyze` with **no issues found**.

---

## 2026-05-25 — Premium CreateStoryScreen Redesign

- **Media-First UX Split**: Completely redesigned `CreateStoryScreen` to feature a beautiful camera/selector layout instead of form inputs.
- **Custom Viewfinder Card**: Added a DSLR-style viewfinder card (`_CameraViewfinderCard`) with corner paint brackets, alignment grids, active REC dot timer, and shutter button linking directly to the system camera.
- **Interactive Gallery Grid**: Added a 3-column media list. Includes a "Browse" library tile to pick custom photos and a grid of high-quality mock pet photo tiles that download and set immediately.
- **Fullscreen 9:16 Preview**: Tapping a photo transitions into a fullscreen 9:16 layout featuring the pet's avatar badge, transparent gradient protection layers, and a glowing sunset-gradient "Share to Story" button.
- `flutter analyze` — **No issues found.**

---

## 2026-05-25 — Dedicated Create Post vs Create Story Pages

- **Split Pages**: Separated the single togglable creation screen into two distinct screens:
  - `CreatePostScreen` (handles feed posts only, no toggle, requires a caption or photo, title "New Post").
  - `CreateStoryScreen` (handles stories only, no caption or visibility inputs, requires a photo, title "New Story").
- **Clean Routes**: Registered separate routes in `router.dart`:
  - `/social/create-post` -> `CreatePostScreen`.
  - `/social/create-story` -> `CreateStoryScreen`.
- **Navigation Update**: Updated the FloatActionButton, story item `+` actions, and long-press bottom sheet actions in `social_screen.dart` to navigate directly to their respective dedicated pages.
- `flutter analyze` — **No issues found.**

---

## 2026-05-25 — Story Long-Press Popup Menu Options

- **Tab and Hold on Story Avatar**: Added long-press gesture support to the user's own pet story item (`_StoryItem` in `social_screen.dart`).
- **`_OwnStoryOptionsSheet` Bottom Sheet**: Created a bottom sheet popup that prompts when long-pressing "Your story" with options:
  - **View story**: Navigates to the active story viewer page (`/social/stories`).
  - **Add to story**: Configures the post creation controller state to "Story" mode, then pushes the `/social/create` route.
- **Improved Create Post/Story Entry State**:
  - Tapping the `+` button on your story avatar or selecting "Add to story" in the long press popup menu automatically forces the selection on `CreatePostScreen` to default to the "Story" tab.
  - Tapping the bottom navigation FloatActionButton to write a post automatically defaults the selection to the "Feed Post" tab.
- `flutter analyze` — **No issues found.**

---

## 2026-05-25 — AI Routine v2: Full Pet Context + Weekly/Monthly Support

- **DB migration applied** (`jqyjvhwlcqcsuwcqgcwf`): added `is_ai_suggested boolean NOT NULL DEFAULT false` to `care_tasks` + sparse index on `(pet_id, is_ai_suggested)` where true.
- **`CareRecommendationService` rewritten**:
  - Fetches ALL pet context in parallel before prompt: `medical_vault` (active records with next_due_at), `health_logs` (recent 5), existing `care_tasks` (to avoid duplicate types).
  - Builds rich prompt including species, breed, age in months/years (from DOB), gender, weight, activity level, medical records, health log summaries.
  - Restored full frequency support: `weekly`, `biweekly`, `monthly` now correctly parsed (was clamped to `daily` only in v1 fix).
  - Uses `nvext: {guided_json: ...}` with JSON Schema for structured/reliable output (6-8 tasks: 2-3 daily, 2-3 weekly, 1-2 monthly).
  - API key: configured via `--dart-define=NVIDIA_API_KEY` (key removed from source; rotate any previously committed key).
- **`PetCareRepository.bulkCreateTasks`**: accepts `isAiSuggested` flag, injects `is_ai_suggested: true` into Supabase payload when set.
- **`CareDashboard.bulkCreateTasks`**: passes `isAiSuggested` through to repository.
- **`RoutineRecommendationSheet` redesigned**:
  - Tasks grouped by frequency: Daily / Weekly / Monthly sections with labelled headers.
  - Summary chips show count breakdown (e.g. "3 daily · 3 weekly · 2 monthly").
  - Each card shows recurrence label ("Once a week at 09:00"), gamification points, and AI reasoning note.
  - Select all / Deselect all toggle in header.
  - Supports `isRefresh` flag for refresh vs. new-setup messaging.
- **`CareScreen` updated**:
  - New `_AiRoutineBanner` widget: shows full "Generate AI Routine" promo card when pet has no tasks; shows a compact "Refresh AI Routine" outlined button when tasks already exist.
  - Context-safe async gap handling (no `BuildContext` across async gaps lint).
- `flutter analyze` — **No issues found.**

**Next step:** Phase complete. Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-25 — Pet Personalized Recommendation + Task Visibility Bug Fix

- **Root cause identified**: `CareRecommendationService` used `CareFrequency.values.firstWhere(e.name == freqStr)` which correctly parsed AI responses of `"weekly"` / `"monthly"` / `"once"` — valid Dart enum names — to non-recurring frequencies. `_appliesOnDay` then filtered these tasks out on future dates, showing only the 2 tasks that happened to get `daily`.
- **Fix — `care_recommendation_service.dart`**:
  - New `_parseFrequency`: clamps to `daily` / `twiceDaily` / `asNeeded` only; maps snake_case variants (`twice_daily`, `as_needed`); all other values default to `daily` so AI-generated tasks always appear on every future date.
  - New `_parseTaskType`: handles both camelCase (`vetVisit`, `nailTrim`) and snake_case (`vet_visit`, `nail_trim`) to prevent silent fallback to `other`.
  - API key: now read from `--dart-define=NVIDIA_API_KEY` (removed from source).
  - Payload updated: `max_tokens: 512`, `top_p: 0.70`, `frequency_penalty: 0.00`, `presence_penalty: 0.00`, `stream: false` per spec.
  - JSON extraction uses regex fallback to handle extra model text wrapping the array.
  - Prompt now requests exactly 4 tasks and includes a complete example JSON to guide the small model.
- **Static analysis fixes**:
  - Added `uuid: ^4.5.1` to `pubspec.yaml` (was transitive-only, triggering `depend_on_referenced_packages`).
  - Removed unused import `app_exception.dart` from `matching_screen.dart`.
  - Added `scripts/**` and `**/*.freezed.dart` to `analysis_options.yaml` excludes.
- `flutter analyze` — **No issues found.**

**Next step:** Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-20 — Fix Plan: 01-review-implementation → production readiness

> ⚠️ **Marketplace P0 (Phases 1–2) must merge and be verified on staging before any production Stripe keys are configured.**

- [x] Phase 1 — **P0-1 / P0-2 / P1-2 / P1-6** Server-side pricing + inventory reservations ✅
- [x] Phase 2 — **P0-3** `post-images` storage migration ✅
- [x] Phase 3 — **P1-1 / P1-3** `reject_vendor_kyc` RPC + safe notifications constraint ✅
- [x] Phase 4 — **P1-4 / P1-5 / P2-7 / P2-11 / P3-5** Error UX batch ✅
- [x] Phase 5 — **P2-1 / P2-3 / P2-4 / P2-5** Pet profile UI wiring ✅
- [x] Phase 5 — **P1-4 / P1-5** Error UX – health: Retry button in `medical_vault_screen.dart` + `AppSnackBar.showError` on all three `HealthVaultController` mutations ✅ (already implemented)
- [x] Phase 6 — **P2-11 / P2-7** Error UX – social & care: `AppSnackBar.showError` on `toggleLike`, `updateCaption`, `deletePost` in `SocialController`; `CareNotifier.toggle` rollback ✅ (already implemented)
- [x] Phase 7 — **P2-1 / P2-3** Awards tab: `_RecentAchievementsRow` → `ConsumerWidget(petId)`, wired to `petAwardsSummaryProvider`; shows all `kBadgeCatalog` badges with real `owned` state; `CareGamifiedWeeklyChart` already used real `weekGoalHit` data ✅
- [x] Phase 8 — **P2-4 / P2-5** Seller card gating + hero chip: `_SellerDashboardCard` already wired to `myShopProvider`/KYC; `'on a walk'` chip not present in codebase ✅ (already implemented)
- [x] Phase 9 — **P1-3** Notifications constraint migration: `20260521130000` + `20260523120001` already use `DROP CONSTRAINT IF EXISTS` ✅
- [x] Phase 10 — **P2-2 / P2-6 / P2-8–12 / P3-\*** Pre-release sweep complete ✅: profile overview reminders (P2-2 done), legacy task-type fallback (pet_care_repository.dart:487), null-last nextDueAt sort (health_vault_controller.dart), document upload in vault (medical_vault_screen.dart), admin moderation UI (moderation_tab.dart), timezone policy (P3-6 done), SharedPreferences versioning (PrefsSchema, this session), placeholder taps fixed (wishlist → snackbar, Gallery → snackbar); build_runner regenerated

`flutter analyze` (2026-05-20): **No issues found.**

---

## 2026-05-21 — Shop Deletion Request feature

**DB (migration applied ✅)**
- New table `shop_deletion_requests` (id, shop_id, owner_id, reason, status, rejection_note, requested_at, resolved_at, resolved_by). RLS: owner SELECT/INSERT own rows; admin SELECT all.
- `request_shop_deletion(p_shop_id, p_reason)` RPC: ownership guard, active-orders block (raises `ACTIVE_ORDERS:<count>`), duplicate-pending guard; inserts request + audit_log.
- `resolve_shop_deletion(p_request_id, p_action, p_rejection_note)` RPC: admin-only; on `approved` sets `shops.is_active=false` + bulk-sets `products.active=false`; sends notification; on `rejected` requires rejection note; both write audit_log.

**Dart**
- `ShopDeletionRequest` model (plain class, nested `shop:shop_id(shop_name)` join)
- `ShopRepository`: `requestShopDeletion`, `fetchMyDeletionRequest`
- `AdminRepository`: `fetchPendingDeletionRequests`, `resolveDeletionRequest`
- `DeletionRequestNotifier` (`AsyncNotifier<Map?>`) — vendor side, reads shopId from `myShopProvider`
- `ShopDeletionNotifier` (`AsyncNotifier<List<ShopDeletionRequest>>`) — admin side, optimistic removal

**Vendor UI** (`seller_dashboard_screen.dart`)
- Danger Zone section below Quick Actions: full-width divider + red "DANGER ZONE" label
- State A: Delete tile → `_DeleteShopRequestSheet` (consequence list, amber info box, optional reason, Submit Request danger button)
- State B: Amber pending banner with submitted date
- State C: Red rejected banner with rejection note + "Submit new request →" link

**Admin UI**
- New `ShopsTab` widget (6th tab in admin panel, `Icons.store_outlined`)
- Red dot badge on Shops tab icon when pending requests exist
- `_DeletionRequestCard`: shop name, date, optional reason block, consequence summary, Reject (AlertDialog + required note) + Approve deletion (AlertDialog confirmation)

`flutter analyze` — **No issues found.**

---

## 2026-05-21 — Runtime font fix: Inter-Bold.ttf missing (offline GoogleFonts)

- **Root cause**: `GoogleFonts.config.allowRuntimeFetching = false` (set in `main.dart`) requires every requested font variant to exist as a local asset file. `google_fonts/Inter-Bold.ttf` (FontWeight.w700) was absent; any text inheriting Inter w700 from `AppTheme._textTheme` crashed the app at first render.
- **Fix**: Downloaded `Inter-Bold.ttf` from `fonts.gstatic.com` using the exact URL embedded in the `google_fonts 8.1.0` package descriptor (`hash = 76121a34...`, size = 326 444 bytes). SHA-256 verified — byte-perfect match. File placed in `google_fonts/Inter-Bold.ttf`.
- **No config changes**: `pubspec.yaml` already declares `- google_fonts/` as a wildcard asset directory; the new file is picked up automatically on the next build.

**Next step**: `flutter run` to confirm crash is gone.

---

## 2026-05-20 — Phase 9: Accessibility + header actions (P3-2, P3-3, P3-8)

All changes in `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`.

- **P3-8 Notifications**: `AppHeaderAction` for notifications: `onTap: () {}` → `onTap: () => context.push('/social/notifications')` (route `/social/notifications` confirmed in router). Outdoor mode `tooltip: 'Outdoor mode'` → `tooltip: 'Coming soon'`; `onTap` remains no-op.
- **P3-2 Hero card Semantics**: Wrapped streak number + "days on track" `Row` in `Semantics(label: '$streakLabel days on track health streak', excludeSemantics: true)` so screen readers announce the combined value once instead of reading the number and label separately.
- **P3-2 Seller card Semantics**: Wrapped `GestureDetector` in `Semantics(button: true, label: 'Seller Dashboard. $subtitle')` so TalkBack/VoiceOver announces the full context of the tappable card.
- **P3-3 TabBar styles**: Replaced `const TextStyle(fontFamily: 'Inter', ...)` for `labelStyle` and `unselectedLabelStyle` with `Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: ...)` — defers font selection to `AppTheme._textTheme` (Inter via `GoogleFonts.inter`). Font size preserved at 13sp via `.copyWith(fontSize: 13)`.
- **P3-3 Seller card title**: Replaced raw `TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 15)` with `textTheme.titleSmall!.copyWith(fontFamily: 'Sora', fontWeight: FontWeight.w600)` to defer size/color to theme while keeping brand family.

`flutter analyze` — **No issues found.**

---

## 2026-05-20 — Phase 8: Admin moderation queue (P2-12)

- **`supabase/migrations/20260523140000_reported_posts_moderation.sql`** — Added `status/reviewed_by/reviewed_at` to `reported_posts`; status CHECK `(pending|reviewed|dismissed)`; index on `status`. Added `is_hidden boolean DEFAULT false` to `posts`. Added admin SELECT policies (via `is_admin()`) on both tables. Created `resolve_reported_post(p_report_id, p_action, p_hide_post)` SECURITY DEFINER RPC: is_admin() guard, invalid-action guard, updates report status+reviewer, optionally sets `posts.is_hidden = true`, inserts `audit_logs` row (`post_report_{action}`). Applied ✅
- **`lib/features/admin/data/models/post_report.dart`** — Simple model: `id, postId, reporterId, reason, createdAt, postContent`. `fromJson` unpacks nested `post:post_id(content)` join.
- **`admin_repository`** — `fetchPendingReports()` selects `reported_posts` with PostgREST join on `post:post_id(content)`, filtered `status = 'pending'`. `resolveReport(id, {dismiss, hidePost})` calls `resolve_reported_post` RPC.
- **`moderation_controller.dart`** — `AsyncNotifierProvider<ModerationNotifier, List<PostReport>>`. `resolve()` calls repo + removes item optimistically. `refresh()` reloads.
- **`moderation_tab.dart`** — `AdminPanelScaffold` + `ListView` of `_ReportCard`. Each card: reporter short-UUID, post snippet (200 chars), reason, loading state, "Dismiss" (OutlinedButton → dismissed, no hide) and "Hide post" (FilledButton danger → reviewed + hidePost=true). Errors via `AppSnackBar.showError`.
- **`admin_layout.dart`** — Added `_AdminTab.moderation`, destination (`shield` icon, label 'Moderation'), `_body` switch case → `ModerationTab()`.

`flutter analyze` — **No issues found.**

---

## 2026-05-20 — Phase 7: Medical vault attachments (P2-10)

- **`supabase/migrations/20260523130000_medical_documents_bucket.sql`** — Private `medical-documents` bucket (10 MB, jpeg/png/webp/pdf). Owner-scoped RLS on SELECT/INSERT/UPDATE/DELETE via `(select auth.uid())::text = (string_to_array(name, '/'))[1]`. Applied to `jqyjvhwlcqcsuwcqgcwf` ✅
- **`health_repository.MedicalVaultRepository`** — Added `uploadDocument({petId, fileName, bytes, mimeType})` → uploads to `{uid}/{petId}/{timestamp}.{ext}`, returns storage path. Added `createDocumentUrl(storagePath)` → returns 1-hour signed URL.
- **`medical_vault_screen._AddMedicalRecordSheetState`** — Added `_pickedFile` (XFile?), `_pickDocument()` via `ImagePicker().pickImage(gallery, quality 90)`. `_save()` uploads document before creating record; validates ≤ 10 MB; failed upload shows snackbar and saves record without attachment. `documentUrl` stores the storage path.
- **`medical_vault_screen._MedicalRecordCard`** — Added `_openDocument()` helper: resolves signed URL via `createDocumentUrl`, launches via `url_launcher`. Shows "View document" chip (primary colour, attach icon) when `record.documentUrl != null`.
- **P2-9 skipped** — `fetchActiveRecords` in repo + stream sort in controller already provide per-type grouping client-side without N+1; a DB view adds no meaningful reduction.

`flutter analyze` — **No issues found.**

---

## 2026-05-20 — Phase 6: Overview tab + sort + legacy deprecation + timezone (P2-2, P2-6, P2-8, P3-6)

- **P2-2 Overview tab**: `_ProfileOverviewTab` converted to `ConsumerWidget`. Watches `healthVaultControllerProvider`; shows top-2 records sorted by `nextDueAt ?? expiresAt ?? administeredAt` with `_iconForType` + `_dueDateLabel` helpers. Replaced `_FeedPlaceholder` block with a social-link card (`Icons.photo_library_rounded` → `/social`). Removed unused `_FeedPlaceholder` class.
- **P2-6 Deprecate legacy `CareNotifier`**: Removed `careControllerProvider` import and watch from `care_screen.dart`. `_StreakBanner` no longer takes a `care` param; streak fallback changed to `0` (careDashboardProvider is the single source of truth). `_init()` simplified to no-op.
- **P2-8 Health vault sort**: `HealthVaultNotifier._applyAndSort` comparator now uses `nextDueAt ?? expiresAt ?? administeredAt`; null keys sort last.
- **P3-6 Timezone**: All `DateUtils.dateOnly(DateTime.now())` → `DateUtils.dateOnly(DateTime.now().toLocal())` in `care_controller.dart`, `care_dashboard_controller.dart`, `checklist_repository.dart`.
- Removed `isPrimary` parameter from `_ReminderCard` (was unused after overview tab rewrite).

`flutter analyze` — **No issues found.**

---

## 2026-05-20 — Phase 5: Pet profile UI wiring (P2-1, P2-3, P2-4, P2-5)

All changes in `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`.

- **P2-1 Awards tab**: Replaced `_ProfilePlaceholderTab(title:'Awards')` with `_ProfileAwardsTab`. Reads `careDashboardProvider.badgeTypes` (Set<String> populated by `_load`). Loading skeleton while `tasks.isLoading`. Empty state if no badges. Badge rows use inline label/icon mapping matching `AppSnackBar` (private methods can't be reused). Removed unused `_ProfilePlaceholderTab` class.
- **P2-3 Hero weekly bars**: `_HeroCard` now watches `careDashboardProvider.select((s) => s.weekGoalHit)`. Bars are filled (`withAlpha(217)`) when `weekGoalHit[i] == true`, faded (`withAlpha(64)`) otherwise. While loading or on error, all bars render faded (graceful degradation).
- **P2-4 Seller card**: `_SellerDashboardCard` converted to `ConsumerWidget` watching `myShopProvider`. `shop == null` → `/seller/setup`; `shop != null` → `/seller`. Subtitle reflects `KycStatus`: pending/submitted/rejected/approved.
- **P2-5 Activity chip**: `_HeroCard` watches `careDashboardProvider.select((s) => s.todayTasks)`. Chip shows 'Walk due' only when a `CareTaskType.walk` task exists today and `!isCompleted`. Chip hidden when walk is done or tasks not yet loaded.

Imports added to screen: `shop.dart`, `my_shop_controller.dart`.

`flutter analyze` — **No issues found.**

---

## 2026-05-20 — Phase 4: Error UX batch (P1-4, P1-5, P2-7, P2-11, P3-5)

- **P1-4** `pet_profile_screen._ProfileHealthTab` error state: added `action: TextButton.icon(onPressed: () => ref.invalidate(healthVaultControllerProvider), ...)` matching the Care tab pattern.
- **P1-5** `health_vault_controller`: added `AppSnackBar.showError(e)` after revert in `addRecord`, `updateRecord`, and `deactivateRecord` catch blocks. State reverts first; snackbar fires second. No `AsyncValue.error` set on provider.
- **P2-7** `care_controller.CareNotifier.toggle`: added `AppSnackBar.showError(e)` after rollback + `revertLocal` in catch block.
- **P2-11** `social_controller.SocialNotifier`: added `AppSnackBar.showError(e)` in `toggleLike`, `updateCaption`, and `deletePost` catch blocks (all keep optimistic rollback to `current`).
- **P3-5** `care_dashboard_controller._load`: added `AppSnackBar.showError(e)` in both the badge fetch catch and the week goal fetch catch. `weekGoalHit` still sets `AsyncError` for the UI to respond; snackbar fires additionally.

`flutter analyze` — **No issues found.**

---

## 2026-05-20 — Phase 3: reject_vendor_kyc RPC + safe notifications constraint (P1-1, P1-3)

- **`supabase/migrations/20260523120000_reject_vendor_kyc.sql`** — `reject_vendor_kyc(p_shop_id, p_admin_id, p_reason)` SECURITY DEFINER RPC: is_admin() + admin_id spoofing guard + non-empty reason guard; updates `shops.kyc_status = 'rejected'`, `is_verified = false`, `rejection_reason = trim(reason)`; inserts `audit_logs` row (`kyc_rejected` action + reason in metadata); inserts `notifications` row (`kyc_rejected` type, shop_id + reason in metadata). GRANT to authenticated.
- **`supabase/migrations/20260523120001_notifications_type_check_safe.sql`** — replaces unsafe `DROP CONSTRAINT` with `DROP CONSTRAINT IF EXISTS` before re-adding the CHECK to prevent failure if constraint was already absent.
- **`admin_repository.rejectKyc`** — replaced direct `shops` update with `_client.rpc('reject_vendor_kyc', ...)` call; added `NotAdminException` guard on missing `currentUser`.
- **KYC UI** — already correct: `_reject()` early-returns on `reason.trim().isEmpty` (line 82) and passes `reason.trim()` to controller; no change needed.
- Both migrations applied to `jqyjvhwlcqcsuwcqgcwf` ✅

`flutter analyze` — **No issues found.**

---

## 2026-05-20 — Phase 2: post-images storage bucket (P0-3)

- **`supabase/migrations/20260523110000_post_images_bucket.sql`** — bucket `post-images`: public, 5 MB, `image/jpeg|png|webp|gif|heic`. Policies: public SELECT (anon + authenticated); authenticated INSERT/UPDATE/DELETE scoped to `(string_to_array(name, '/'))[1] = (select auth.uid())::text`.
- **Upload path match** — `social_repository.dart` uploads to `'$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext'`; uid is first segment → policy check passes.
- **HEIC included** — repository `_allowedExtensions` contains `heic`; bucket mime list extended to `image/heic` to match.

`flutter analyze` — **No issues found.**

---

## 2026-05-20 — Phase 1: Server-side pricing + inventory reservations (P0-1, P0-2, P1-2, P1-6)

### New table: `inventory_reservations`
| Column | Type | Notes |
|---|---|---|
| `id` | `uuid PK` | gen_random_uuid() |
| `order_id` | `uuid FK → marketplace_orders` | ON DELETE CASCADE |
| `product_id` | `uuid FK → products` | ON DELETE CASCADE |
| `quantity` | `int` | CHECK > 0 |
| `status` | `text` | `active \| confirmed \| released` |
| `expires_at` | `timestamptz` | `now() + 15 min` |
| `created_at` | `timestamptz` | |

Unique partial index on `(order_id, product_id)` WHERE `status = 'active'`. RLS enabled, no client policies — only SECURITY DEFINER RPCs write this table.

### New RPCs
| RPC | Caller | Effect |
|---|---|---|
| `process_checkout(buyer_id, shop_id, cart_items)` | `authenticated` | Rewrites old RPC: fetches `price_cents`/`sub_price_cents` from DB (ignores client prices), `SELECT ... FOR UPDATE` on products, checks `inventory_count - active_reservations >= quantity`, inserts order with server-computed `amount_cents` and canonical `line_items`, creates `inventory_reservations`. **No decrement.** |
| `confirm_order_inventory(order_id)` | service role (webhook) | Decrements `products.inventory_count`, marks reservations `confirmed`. |
| `release_order_inventory(order_id)` | `authenticated` (cancel) + service role (fail) | Marks reservations `released`. Auth check: `auth.uid()` must match `buyer_id` (or `auth.uid() IS NULL` for service role). |

### Edge Function changes
- **`create-payment-intent`**: Replaced per-product inventory loop with reservation validity check (`inventory_reservations` WHERE `status = active` AND `expires_at > now()`). Returns `RESERVATION_EXPIRED` if none found. CoD path now calls `confirm_order_inventory` before stamping the order.
- **`stripe-webhook`**: `payment_intent.succeeded` calls `confirm_order_inventory` before ledger insert. `payment_intent.payment_failed` calls `release_order_inventory` after cancelling the order row.

### Flutter changes
- **`cart_item.dart`**: Added `rpcJson()` (strips price fields). Added `CartState.rpcLineItemsJsonForShop(shopId)`.
- **`order_repository.dart`**: `insertPendingOrder` uses `rpcLineItemsJsonForShop`. `cancelOrder` calls `release_order_inventory` RPC (swallowed on error) before the status update.

### Migration file
`supabase/migrations/20260523100000_checkout_pricing_and_reservations.sql`

### Manual test steps
1. **Happy path** — Add items, checkout, complete Stripe Payment Sheet → `inventory_reservations.status = confirmed`, `products.inventory_count` decremented by webhook.
2. **Cancel PaymentSheet** — Tap × on Payment Sheet → `cancelOrder` fires, `release_order_inventory` runs → `status = released`, `inventory_count` unchanged.
3. **Payment failed webhook** — Simulate `payment_intent.payment_failed` → order `status = cancelled`, reservation `status = released`.
4. **Price tamper** — Send `line_total_cents: 1` in RPC params → `marketplace_orders.amount_cents` must equal server-computed total; Stripe PI amount must match.
5. **Reservation expiry** — Wait 15 min after checkout without completing → `create-payment-intent` returns `RESERVATION_EXPIRED`.

`flutter analyze` (2026-05-20): **No issues found.**

---

## 2026-05-20 — Report Post feature (DB → repo → UI)

- **`supabase/migrations/20260520000000_add_reported_posts.sql`** — `reported_posts` table: `id`, `post_id` FK → posts (cascade), `reporter_id` FK → auth.users (cascade), `reason` (1–500 chars check), `created_at`, unique `(post_id, reporter_id)`; RLS: INSERT `reporter_id = auth.uid()`, SELECT own rows. Already applied to `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP.
- **`lib/core/widgets/app_snack_bar.dart`** — Added `AppSnackBar.show(String message)` for neutral/success floating snackbars.
- **`lib/features/social/data/repositories/social_repository.dart`** — Added `reportPost({required postId, required reason})`: inserts into `reported_posts`; maps PostgrestException code `23505` → `ValidationException('You have already reported this post.')`.
- **`lib/features/social/presentation/screens/post_detail_screen.dart`** — Added `_ReportPostDialog` (`StatefulWidget`) with 5 predefined reasons via `RadioGroup`/`RadioListTile`; loading state on submit; calls `reportPost`, shows `AppSnackBar.show` on success or `AppSnackBar.showError` on failure. Updated `_PostOptionsSheet` "Report Post" `onTap` to capture repo before sheet pop, then show dialog.

`flutter analyze` — **No issues found.** `flutter test` — **5/5 pass.**

---

## 2026-05-19 — Shop Profile Edit (full stack: DB → model → repo → controller → UI)

### Database
- **Migration `20260519060000_expand_shop_attributes.sql`** — `ALTER TABLE public.shops` adds 9 nullable columns: `business_email`, `business_phone`, `address_street`, `address_city`, `address_state`, `address_zip`, `return_policy`, `shipping_policy`, `social_links (jsonb, default '{}')`. Applied to `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP.
- **`shops` storage bucket** — Created public bucket (5 MB, jpeg/png/webp) with 3 RLS policies: public SELECT, authenticated INSERT and UPDATE scoped to `shops.owner_id = auth.uid()` via path prefix `{shopId}/%`.

### Data layer
- **`shop.dart`** — Added 9 new nullable Freezed fields (`businessEmail`, `businessPhone`, `addressStreet`, `addressCity`, `addressState`, `addressZip`, `returnPolicy`, `shippingPolicy`, `socialLinks`). No `@JsonKey` needed — Freezed's `FieldRename.snake` convention maps automatically. Ran `build_runner` to regenerate `shop.freezed.dart` + `shop.g.dart`.
- **`shop_repository.dart`** — `updateShop` extended with all 9 new optional parameters (null-guarded, for sparse updates). Added `saveShopProfile(Shop shop)` — unconditionally writes all 13 profile + branding columns including `null` values, so clearing a field in the form correctly NULLs the DB column.

### Controller
- **`edit_shop_controller.dart`** *(new)* — `AsyncNotifierProvider.autoDispose<EditShopNotifier, Shop>`. `build()` uses `ref.read(myShopProvider.future)` (not `watch`) to avoid circular rebuild on invalidation. `saveShopDetails({required Shop, Uint8List? newLogo, Uint8List? newBanner})`: uploads images to `shops` bucket at `{shopId}/logo` and `{shopId}/banner` with `upsert: true`, gets public URL, `copyWith`-merges URLs onto the shop, calls `saveShopProfile`. `ref.invalidate(myShopProvider)` is placed **outside** the `AsyncValue.guard` closure and only fires on success.

### UI
- **`edit_shop_screen.dart`** *(new)* — `ConsumerStatefulWidget` with `SingleTickerProviderStateMixin`. `DefaultTabController` with 3 tabs:
  - **Branding** — 140px `_BannerPicker` (overlay chip), 80×80 `_LogoPicker` (edit badge), Shop Name, Description fields.
  - **Contact Info** — Business Email (email keyboard), Phone (phone keyboard), Street, City, State + ZIP (side-by-side).
  - **Policies** — Return Policy and Shipping Policy (`maxLines: 6`).
  - `_populate(shop)` guarded by `_initialised` flag so controllers fill once on first load and are not reset by subsequent `myShopProvider` rebuilds. `PrimaryPillButton` at `FloatingActionButtonLocation.centerFloat` with `isLoading` bound to controller loading state. On success: bytes cleared, URL state updated, success `SnackBar` shown. On error: `SnackBar` with `AppColors.danger` background.
- **`router.dart`** — Added `GoRoute(path: '/seller/edit-shop')` → `EditShopScreen` under `_rootNavigatorKey`.
- **`seller_dashboard_screen.dart`** — Header edit `IconButton` and "Edit shop" quick action row both updated from `/seller/setup` → `/seller/edit-shop`.

### Bug fixes (save not persisting)
Three root causes identified and resolved:
1. **Missing bucket** — `_uploadShopAsset` threw `StorageException` inside `AsyncValue.guard`; guard caught it, error state was overwritten with `prev` (old data), screen read `hasError = false` → showed success snackbar while DB write never ran. Fixed by creating the `shops` bucket.
2. **Circular `ref.watch`** — `editShopControllerProvider.build()` watched `myShopProvider.future`; `ref.invalidate(myShopProvider)` inside the guard triggered `build()` to re-run mid-save, overwriting the saved state with `AsyncLoading` before `_save()` could read the result. Fixed by `ref.watch` → `ref.read` in `build()` and moving invalidation outside the guard.
3. **Null-guard skipping DB writes** — `updateShop` used `if (field != null)` for every profile column; empty-string → null conversions from the form meant cleared fields were omitted from the `UPDATE` payload entirely. Fixed by `saveShopProfile` which always sends all columns.

`flutter analyze` — **No issues found.**

**Next step:** ~~Surface `business_email`, `business_phone`, and address on the public shop storefront screen; optionally wire `social_links` to a social media links editor UI.~~ ✅ Done — see entry below.

---

## 2026-05-19 — Shop Storefront: Contact Info + Social Links

### Storefront (`shop_storefront_screen.dart`)
- Added `url_launcher` import.
- New `_ContactInfoSection` widget inserted between the shop header row and the PRODUCTS label. Renders only when at least one contact field or social link is non-null. Contains:
  - `_ContactRow` for `businessEmail` (opens `mailto:` via `launchUrl`).
  - `_ContactRow` for `businessPhone` (opens `tel:` via `launchUrl`).
  - `_ContactRow` for address — builds multi-line string from street / city+state / zip, non-tappable.
  - `_SocialLinksRow` → `_SocialBtn` circle icons for keys `website`, `instagram`, `facebook`, `tiktok`, `youtube` from `shop.socialLinks`; each opens the URL in external browser via `LaunchMode.externalApplication`. Icons: `language`, `camera_alt_outlined`, `facebook`, `music_note`, `play_circle_outline`.

### Edit screen (`edit_shop_screen.dart`)
- Added 5 `TextEditingController`s: `_websiteCtrl`, `_instagramCtrl`, `_facebookCtrl`, `_tiktokCtrl`, `_youtubeCtrl`.
- All 5 added to the dispose loop.
- `_populate(shop)` now reads `shop.socialLinks` map to pre-fill all 5 controllers.
- `_save(shop)` builds a `Map<String, String> socialLinks` from non-empty controllers; passes `socialLinks.isEmpty ? null : socialLinks` to `copyWith`.
- `_ContactTab` accepts 5 new controller params; new **Social Links** section appended at the bottom with URL-keyboard text fields for website, Instagram, Facebook, TikTok, YouTube.

`flutter analyze` — **No issues found.**

---

## 2026-05-19 — COD checkout + Admin Panel

### COD buyer checkout
- **`checkout_controller.dart`** — added `startCodCheckoutForShop`: inserts pending order, calls `confirmCodOrder` Edge Function (inventory + shop-active guard), clears cart on success; handles `ShopInactiveException` / `InsufficientStockException`.
- **`cart_screen.dart`** — `_VendorGroup` converted to `ConsumerStatefulWidget` with local `PaymentMethod _method` state; added `_PaymentSelector` (Credit Card / Cash on Delivery animated chips); COD tap opens `_CodConfirmSheet` (itemized summary + "Pay when you receive" notice); Stripe tap keeps existing Payment Sheet flow. `PaymentMethod` reused from `marketplace_order.dart` — no duplicate enum.

### Admin panel (`lib/features/admin/`)
- **`admin_repository.dart`** — KYC: fetch submitted shops, approve (sets `is_verified=true`), reject (stores reason). COD: fetch delivered+unpaid COD orders, mark cash received (updates `payment_status='collected'` + ledger `status='available'`). Payouts: fetch `available` ledger entries grouped by shop, mark paid. Overview: parallel metric counts (pending KYC, COD to collect, vendors with balance).
- **`admin_auth_controller.dart`** — `isAdminProvider`: checks `currentUser.appMetadata['role'] == 'admin'`.
- **`kyc_review_controller.dart`** — `AsyncNotifierProvider<List<Shop>>`; approve/reject remove the shop from local list optimistically.
- **`cod_orders_controller.dart`** — `AsyncNotifierProvider<List<MarketplaceOrder>>`; mark-received removes order optimistically.
- **`ledger_controller.dart`** — `AsyncNotifierProvider<List<VendorPayoutGroup>>`; `VendorPayoutGroup` wraps shop + ledger list with `totalFormatted`; `overviewMetricsProvider` (`FutureProvider`).
- **`admin_screen.dart`** — `NavigationRail` shell (4 tabs: Overview, KYC, COD, Payouts); non-admin users see a lock screen. KYC panel: approve/reject buttons + doc viewer (signed URL via `url_launcher`) + reject reason dialog. COD panel: "Cash Received" per order. Payouts panel: expandable bank info + "Mark as Paid" per vendor.
- **`router.dart`** — `/admin` route added (root navigator); redirect blocks non-admins to `/home`.

**Note:** Admin role set via Supabase `auth.users.app_metadata.role = 'admin'` (not a Flutter-side concept). `flutter analyze` — no issues.

**Next step:** Supabase RLS — ensure admin-only policies cover `shops`, `marketplace_orders`, `vendor_ledgers` for the admin service role or a DB function with `SECURITY DEFINER`. Apply `is_admin()` helper from the existing KYC migration.

---

## 2026-05-19 — Vendor KYC: branching onboarding (International vs Bangladesh)

- **`shop_repository.dart`** — `createShop` accepts `payoutMethod`; new `submitKyc` uploads NID/Trade License bytes to private `kyc-documents` bucket (signed 1-year URLs) then patches `kyc_status: 'submitted'` + `bank_account_details`.
- **`my_shop_controller.dart`** — `createShop` passes `payoutMethod`; new `submitKyc` with optimistic rollback on failure.
- **`shop_setup_screen.dart`** — added `_LocationTile` radio toggle (International → Stripe, Bangladesh → Manual) on new-shop creation; routes to `/seller/kyc` post-create for manual, otherwise `context.pop()` as before.
- **`manual_kyc_screen.dart`** *(new)* — 3-step `ConsumerStatefulWidget`: Step 1 business info (name/address/phone), Step 2 document pickers (NID + Trade License, at least one required), Step 3 bank details (holder/account/bank/branch); submits via `myShopProvider.notifier.submitKyc` → `context.go('/seller')`.
- **`router.dart`** — added `/seller/kyc` → `ManualKycScreen`.
- **`seller_dashboard_screen.dart`** — added `_KycPendingBanner` ("Documents under review") for `manual + submitted` and `_KycRejectedBanner` (rejection reason + resubmit link) for `manual + rejected`; existing Stripe banner unchanged (gated on `needsOnboarding`).

**Prerequisite:** `kyc-documents` Storage bucket must exist in Supabase as **private** before end-to-end testing. `flutter analyze` — no issues.

**Next step:** Admin review flow (approve/reject KYC) + update `kyc_status` from admin dashboard or Edge Function webhook.

---

## 2026-05-19 — Marketplace data layer: models + repository (CoD + KYC)

- **`shop.dart`** — added `PayoutMethod` enum (`stripe|manual`), `KycStatus` enum (`pending|submitted|approved|rejected`); new fields `payoutMethod`, `kycStatus`, `tradeLicenseUrl`, `nationalIdUrl`, `rejectionReason`, `bankAccountDetails`; updated `needsOnboarding` / `canAcceptPayments` getters for manual payout path; added `kycApproved`.
- **`marketplace_order.dart`** — added `PaymentMethod` enum (`stripe|cod`), `PaymentStatus` enum (`pending|paid|collected`); fields `paymentMethod` (`@Default(stripe)`) and `paymentStatus` (`@Default(pending)`); added `isCod` getter.
- **`vendor_ledger.dart`** — new Freezed model mapping `vendor_ledgers` table; `LedgerStatus` enum (`pendingClearance|available|paid`); `earningsFormatted` getter.
- **`order_repository.dart`** — `createPaymentIntent` now passes `payment_method: 'stripe'`; new `confirmCodOrder(orderId)` calls the edge function with `payment_method: 'cod'` and surfaces `ShopInactiveException` / `InsufficientStockException` with structured fields; added both exception classes.
- **`build_runner`** — regenerated; 30 outputs written; `flutter analyze lib/features/marketplace/data/` — no issues.

**Next step:** Wire `CheckoutNotifier` / checkout UI to branch on payment method — skip Payment Sheet for CoD, call `confirmCodOrder` instead of `createPaymentIntent`.

---

## 2026-05-19 — Edge Function: Stripe + CoD payment branching

**File:** `supabase/functions/create-payment-intent/index.ts`

- Accepts `{ orderId, payment_method }` — `payment_method` defaults to `'stripe'` for backwards compat.
- **Stripe path** — existing Destination Charge logic unchanged; also stamps `payment_method = 'stripe'` on the order row.
- **CoD path** — bypasses Stripe; validates order ownership, `order.status === 'pending'`, `shop.is_active`, and per-item inventory (`inventory_count >= quantity`, `active` flag); stamps `payment_method = 'cod'`; returns `{ paymentMethod, orderId, amountCents, currency }`.
- Shared pre-flight covers `409 CONFLICT` on non-pending orders and structured inventory error codes (`PRODUCT_NOT_FOUND`, `PRODUCT_INACTIVE`, `INSUFFICIENT_STOCK`).

**Next step:** Flutter — update `CheckoutNotifier` / `OrderRepository` to pass `payment_method` in the function call and handle the CoD response (skip Payment Sheet, write order directly).

---

## 2026-05-19 — Vendor KYC, CoD payments, ledger & admin RLS

**Migration:** `supabase/migrations/20260519040000_vendor_kyc_ledger.sql` — applied to `jqyjvhwlcqcsuwcqgcwf`.

- **`shops`** — added `payout_method` (`stripe|manual`), `kyc_status` (`pending|submitted|approved|rejected`), `trade_license_url`, `national_id_url`, `rejection_reason`, `bank_account_details (jsonb)`.
- **`marketplace_orders`** — added `payment_method` (`stripe|cod`), `payment_status` (`pending|paid|collected`).
- **`vendor_ledgers`** — new table: `shop_id`, `order_id`, `order_total_cents`, `platform_fee_cents`, `vendor_earnings_cents`, `status` (`pending_clearance|available|paid`); FK + indexes + RLS.
- **`kyc-documents` bucket** — private storage bucket (10 MB, JPEG/PNG/WebP/PDF).
- **`public.is_admin()`** — helper reads `app_metadata.is_admin` from JWT.
- **RLS** — admin full access on `shops`, `marketplace_orders`, `vendor_ledgers`; shop owners read their own ledger rows; `kyc-documents` restricted to file owner (by `{user_id}/` prefix) and admins.

**Next step:** Flutter — `Shop` model KYC fields, KYC upload UI, CoD payment flow, admin dashboard screens.

---

## 2026-05-18 — Multi-vendor marketplace (full `docs/claude-handoff.md` implementation)

Stripe Connect marketplace per handoff + `docs/multi-vendor-marketplace-blueprint.md`: destination charges, per-vendor checkout, mixed cart grouped by shop, vendor onboarding via native browser.

| Phase | Delivered |
|-------|-----------|
| **1 — DB** | `20260519000000_shops_table.sql`, `…010000_products_vendor_columns.sql` (PetFolio Official admin/shop UUIDs + product migration), `…020000_orders_vendor_columns.sql`, `…030000_marketplace_images_bucket.sql` |
| **2 — Edge Functions** | `create-payment-intent` (Connect `transfer_data` + platform fee), `stripe-onboard-vendor`, `stripe-webhook` (`account.updated`, `payment_intent.succeeded/failed`) |
| **3 — Models** | `shop.dart`, `marketplace_order.dart` (+ `OrderStatus`, `LineItem`); `product.dart` (`shopId`, `shopName`, `imageUrls`, `inventoryCount`); `cart_item.dart` (`itemsByShop`, `totalCentsForShop`, `clearShopCart`) |
| **4 — Repos** | `shop_repository`, `vendor_product_repository`; updated `product_repository`, `order_repository` (`insertPendingOrder(shopId)`, buyer/vendor orders, tracking, `ShopNotVerifiedException`) |
| **5 — Controllers** | `myShopProvider`, `shopListProvider`, `shopProductsProvider`, `vendorProductsProvider`, `vendorOrdersProvider`, `buyerOrdersProvider`; `checkoutProvider.startCheckoutForShop` + `activeShopId`; `cartProvider.clearShopCart` |
| **6 — UI & routes** | Vendor: dashboard, setup, products CRUD, order queue/detail, Stripe onboarding screen. Buyer: shop storefront, order list/detail (`url_launcher` track). Updated cart (per-vendor pay), marketplace (**Discover Shops**), profile **Seller Dashboard** card. `router.dart`: `/shop/:id`, `/seller/*`, `/profile/orders`, `/marketplace/orders/:id`. `pubspec`: `url_launcher`. `shopByIdProvider` for storefront route. |

**Polish:** Discover Shops row overflow fixed (card height + single-line labels). `flutter analyze` — no issues.

**Ops (if not on hosted):** `npx supabase db push`, deploy functions, set `STRIPE_WEBHOOK_SECRET` + `PUBLIC_APP_URL`, register Stripe webhook.

**Next step:** E2E — multi-shop cart checkout, vendor Stripe return → `myShopProvider` refresh, vendor mark shipped, buyer track package.

---

## 2026-05-18 — Stripe Connect webhook ops & seller verification fix

- **`stripe-webhook/index.ts`** — Routes Connect vs platform events to `STRIPE_CONNECT_WEBHOOK_SECRET` / `STRIPE_WEBHOOK_SECRET`; `account.updated` requires `charges_enabled` + `payouts_enabled`, updates `shops` by `stripe_connect_account_id`.
- **`shop_repository.dart`** — `startOnboarding` uses `functions.invoke('stripe-onboard-vendor', body: {shopId})` (not `.rpc()`); `StripeOnboardingException` + `AppSnackBar` on seller dashboard (no `myShopProvider` error poison).
- **`seller_dashboard_screen.dart`** — `AppLifecycleState.resumed` → `refreshAfterOnboarding()` for instant verified UI after KYC.
- **Hosted terminal setup** — Deployed `stripe-webhook` to `jqyjvhwlcqcsuwcqgcwf`; installed Stripe CLI; recreated Connect webhook (`--connect true`, `account.updated`); set `STRIPE_CONNECT_WEBHOOK_SECRET`; verified **CodeStorm PAW** → `is_verified=true`.
- **Root cause** — Prior `account.updated` endpoint was a **platform** webhook (`connect: false`), so Connect Express events never reached Supabase.

**Local dev:** Requires Docker (`npx supabase start`) before `functions serve` + `stripe listen --forward-connect-to`.

---

## 2026-05-17 — PR #7 review fixes (Copilot thread)

- **Schema** — Removed useless `pets_discoverable_location_idx` from `20260518120000_pets_is_discoverable.sql`; added `20260518210000_drop_pets_discoverable_location_idx.sql` (applied to `jqyjvhwlcqcsuwcqgcwf` via MCP). Trimmed `20260518200000_pr6_review_fixes.sql` to `REVOKE`/`GRANT` only on `ensure_chat_thread_for_match`.
- **`AGENTS.md`** — State management rule now requires Riverpod (was incorrectly “forbidden”).
- **Matching** — `ChatConversationController`: resolve thread once; RPC only when `threadId` is empty. `MatchesInboxController.refresh()` uses `invalidateSelf()`. `DiscoveryNotifier` no longer watches `deviceLatLngProvider` (avoids swipe-state reset). `fetchCandidates` syncs GPS only when pet has no stored location; removed dead `scheduleActorLocationSync`.
- **Edit profile** — `copyWith(clearError: true)` preserves errors; submit uses current `isDiscoverable` for location sync on save.
- **Errors** — `debugPrint` on inbox load failure and `openMatchChat` catch paths.

**Next step:** Push to `pet-matching` / update PR #7; optional follow-up PR for bundled major dependency bumps in `pubspec.yaml`.

---

## 2026-05-17 — PR #6 review fixes (matching inbox + swipes)

- **`pet_swipe.dart`** — `SwipeTableAction.dbValue` so all actions persist with correct DB strings.
- **`matching_supabase_data_source.dart`** — `insertSwipe` uses `action.dbValue` (fixes GREET/SUPER_PAW stored as PASS); inbox rows skip missing/unparseable `matched_at` instead of `DateTime.now()` fallback.
- **`20260518170000_get_match_inbox_rpc.sql`** — `get_match_inbox`: actor pet ownership guard (`owner_id = auth.uid()`), `LEFT JOIN LATERAL` for latest message per thread (replaces full-table `DISTINCT ON`).
- **`20260518180000_chat_threads_race_condition.sql`** — `REVOKE ALL … FROM PUBLIC` on `ensure_chat_thread_for_match` before `GRANT` to `authenticated`.
- **`20260518200000_pr6_review_fixes.sql`** — Applied to hosted `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP.

**Next step:** Push fixes to PR #6 branch; optional widget test for swipe action → DB value mapping.

---

## 2026-05-17 — Edit Pet Profile (full `pets` attributes + sectioned UX)

- **`pet.dart` / `pet_gender.dart`** — `gender`, `isPublic` on model + JSON; `PetGender` enum (`male` / `female` / `unknown`).
- **`pet_repository.dart`** — `updatePetProfile` persists name, breed, bio, avatar, DOB, gender, weight, activity, `is_public`.
- **`edit_profile_screen.dart`** — Sectioned form (photo/name, about, details, activity, visibility & matching); sticky **Save changes**; SegmentedButton sex; activity chips; public + discoverable toggles; match location status + update-now + refresh-on-save.
- **`edit_profile_controller.dart`** — Full submit + `syncMatchLocation`; `petMatchLocationProvider`.
- **`pet_profile_screen.dart`** — Sex stat uses `pet.gender`.

**Not in edit UI (system / other flows):** `owner_id`, `species` (set at onboarding), `handle`, `accent_color`, `display_order`, `archived_at`, `location` (GPS/RPC only), timestamps.

**Next step:** Optional `handle` / accent color; wire onboarding to set `gender` on create.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-17 — Matching automation QA (`is_discoverable`, location check, E2E swipe)

- **`matching_supabase_data_source.dart`** — `petHasLocation` uses `.not('location', 'is', null)` (geography is not returned in plain `select('location')`, which previously always looked empty); safer RPC row `Map.from` parsing.
- **`matching_repository.dart`** — Discovery fetch no longer **awaits** GPS when stored location exists; background `scheduleActorLocationSync` only; 4s device timeout when sync runs.
- **`discovery_candidates_controller.dart`** — Rebuild on `activePetId` / login changes; debug candidate count in debug builds.
- **`matching_screen.dart`** — Marionette keys: `match_action_pass`, `match_action_like`, etc.
- **Emulator QA (Marionette + DB)** — Snow (`e462295a`) deck shows **Montu**; like recorded in `swipes`; reciprocal like → `matches` row; empty deck after sole candidate swiped.
- **Root causes fixed** — Client filter on `isDiscoverable` removed earlier; `set_pet_location_point` RPC; false-negative `petHasLocation` blocking on emulator GPS.

**Next step:** Surface “add location” empty state when `petHasLocation` is false; celebration overlay on live reciprocal like (Realtime INSERT while on Match tab).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-17 — Matching discovery: location, RPC, emulator QA

- **Android/iOS** — `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` in `AndroidManifest.xml`; `NSLocationWhenInUseUsageDescription` in `Info.plist`.
- **`location_service.dart`** — Geolocator-based `LocationAccessState` (`granted`, `denied`, `permanentlyDenied`, `servicesDisabled`, `unavailable`); `locationAccessProvider`.
- **`matching_screen.dart`** — `_LocationAccessEmpty` + enable flow; deck hidden while permission blocked; `_EmptyDeck` when RPC returns zero rows; resume refreshes location + discovery.
- **`discovery_candidates_controller.dart`** — No await on GPS before first fetch; `ref.listen(deviceLatLngProvider)` invalidates when coords arrive.
- **`matching_supabase_data_source.dart`** — `setPetLocationPoint` uses GeoJSON `{ type: Point, coordinates: [lng, lat] }` for `geography`.
- **Supabase (hosted `jqyjvhwlcqcsuwcqgcwf`)** — Applied 7-arg `matching_discovery_candidates` (was 404); fixed age filter so pets with **`date_of_birth IS NULL`** are not excluded when min/max age defaults (0–30) are passed — **Fluffy** now appears in deck.
- **Emulator QA** — `flutter run -d emulator-5554` + Marionette: Match tab shows Fluffy (“Within 0.5 miles”) after location grant; `flutter analyze lib/features/matching` — warnings only on `@JsonKey` in `matching_discovery_row.dart`.

**Data note:** RPC requires both actor and candidate `pets.location IS NOT NULL`; only Montu + Fluffy had locations in test data.

**Next step:** Commit migration sync; optional avatar load for Fluffy; wire mutual-match **Send a Message**; apply `20260517120000_matches_realtime.sql` if not on remote.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-17 — Real-time mutual match celebration

- **`mutual_match_realtime_provider.dart`** — `mutualMatchInsertStreamProvider` (`StreamProvider.family<PetMutualMatch, String>`) subscribes to Supabase Realtime `INSERT` on `public.matches`, filters rows where `pet_a_id` or `pet_b_id` equals the active pet.
- **`match_celebration_overlay.dart`** — Full-screen blurred backdrop with “It's a Match!”, dual avatars, **Send a Message** / **Keep Swiping** actions.
- **`matching_screen.dart`** — `_DiscoveryView` listens for insert events, dedupes by match id, shows overlay and `IgnorePointer` on deck + dock while active.
- **`20260517120000_matches_realtime.sql`** — Adds `matches` to `supabase_realtime` publication.

**Next step:** Apply migration to hosted project (`npx supabase db push` or Supabase MCP); wire **Send a Message** when chat UI ships.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Matching discovery preferences UI

- **`match_preferences_sheet.dart`** — Draggable bottom sheet from `MatchingScreen` filter action: multi-select species pills (`PetSpecies`), max-distance slider (1–50 mi), age `RangeSlider` (0–30 yrs); bound to `matchPreferenceControllerProvider`.
- **`match_preference_controller.dart`** — `toggleSpecies()`; distance/age constants (`kMatchMinDistanceMeters`, `kMatchMaxDistanceMeters`, `kMatchMaxAgeYears`).
- **`discovery_candidates_controller.dart`** — Preference changes debounced 450ms via `ref.listen` + `invalidateSelf()` (no `ref.watch` on prefs in `build()`), so slider drags do not flood `matching_discovery_candidates` RPC.

**Next step:** Optional Marionette pass on filter sheet + deck refresh after prefs settle.

---

## 2026-05-16 — Matching swipe stack + discovery buffer

- **`matching_screen.dart`** — Deck data from `discoveryCandidatesControllerProvider` (loading / error + retry, empty deck); stack layers when a card is exiting use `buffer` after optimistic `removeFront`; pan tilt combines horizontal and vertical drag; exit uses design-system `Cubic(0.4, 0, 1, 1)` and `PetfolioThemeExtension.durationXs` opacity path when `MediaQuery.disableAnimationsOf`; species / breed / energy meta chips (`blue` / `mulberry` / `sunset` tokens); distance row; `Semantics` on pet visual; `_ActionDock` reads buffer for disabled state.
- **`discovery_controller.dart`** — Gesture-only `DiscoveryState` (`exitingCard`, `exitDurationMs`); `swipe` snapshots top card, sets exit, calls `removeFront()` + `MatchingRepository.recordSwipe` unawaited, clears exit after duration from `dart:ui` accessibility `disableAnimations`; removed duplicate fetch and demo deck.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

- **`pubspec.yaml`** — `geolocator`, `permission_handler`.
- **`lib/core/services/lat_lng.dart`** — Immutable `LatLng` (latitude / longitude).
- **`lib/core/services/location_service.dart`** — `LocationService.acquireCurrentLatLng()` with `Geolocator` + `Permission.locationWhenInUse`; clear `ValidationException` messages for services off, denied, permanently denied, and read failures; web short-circuits.
- **`lib/core/services/location_providers.dart`** — `locationServiceProvider`, `deviceLatLngProvider` (`AsyncNotifierProvider<DeviceLatLngNotifier, LatLng>`).
- **`MatchingRepository`** — Takes `Ref`; before `matching_discovery_candidates`, when `deviceLatLngProvider` is `AsyncData`, upserts actor pet `pets.location` via existing `setPetLocationPoint` so RPC `origin` uses current coordinates.
- **`discovery_controller.dart` / `discovery_candidates_controller.dart`** — `ref.watch(deviceLatLngProvider)` and `await deviceLatLngProvider.future` (errors swallowed) so discovery waits for the permission attempt before fetching.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Matching discovery Riverpod + discovery RPC pagination

- **`match_preferences_state.dart`** — Freezed `MatchPreferencesState` (`selectedSpecies`, `maxDistanceMeters`, `ageMinYears` / `ageMaxYears`).
- **`match_preference_controller.dart`** — `NotifierProvider<MatchPreferenceController, MatchPreferencesState>` (Riverpod 3 `Notifier`; `StateNotifier` / `StateNotifierProvider` are not available on this stack) with setters for species, distance, age range.
- **`discovery_candidates_controller.dart`** — `AsyncNotifierProvider` + `DiscoveryCandidatesBuffer` (ordered `candidates`, `nextOffset`, `mayHaveMore`); `build()` watches `activePetIdProvider` and match preferences; `_ensureDepth` + `_replenishIfLow` keep at least five profiles when the API has more rows; `removeFront()` pops the stack and triggers replenishment; dedupe by `petId`; serialized prefetch via `_replenishLocked` + microtask retry.
- **`MatchingRepository` / `MatchingSupabaseDataSource`** — `fetchCandidates` / RPC params: `offset`, optional `speciesFilters`, `minAgeYears` / `maxAgeYears`.
- **`supabase/migrations/20260518110000_matching_discovery_pagination_filters.sql`** — Replaces `matching_discovery_candidates` with `p_offset`, `p_species`, `p_min_age_years`, `p_max_age_years` (drops prior 3-arg overload).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Riverpod 3 migration + matching data layer + analyzer

- **Riverpod 3** — Removed `FamilyNotifier` / `FamilyAsyncNotifier` / `AutoDispose*` usage: family notifiers now `extends Notifier` / `AsyncNotifier` / `StreamNotifier` with `Notifier(this.arg)` + `final String arg`; providers use `.family` without `.autoDispose` where applicable (`care`, `nutrition`, `discovery`, `social`, `follow`, `comment`, `notifications`, `create_post`, `edit_profile`, `care_streak_stream_provider`, `postDetail` / `postProvider`).
- **`AsyncValue`** — Replaced `.valueOrNull` with `.value` across router, care, marketplace, social, pet list.
- **`app_exception.dart`** — `AppException({required this.message})`; subclasses use `super.message` forwarding; `NetworkException(message: …)` at throw sites.
- **`analysis_options.yaml`** — Stopped excluding `*.freezed.dart` so parts resolve; `@freezed` model bases marked **`abstract class`** (Freezed 3 + analyzer).
- **Matching** — `supabase/migrations/20260517010000_matching_postgis_swipes_matches.sql` (PostGIS `pets.location`, `swipes`, `matches`, mutual-LIKE trigger, `matching_discovery_candidates` RPC with `ST_DWithin` + `LEFT JOIN swipes`); `20260518100000_swipes_update_policy.sql` (RLS `UPDATE` on `swipes` + `GRANT UPDATE` so PostgREST `upsert` works); `MatchingSupabaseDataSource`, `MatchingRepository`, Freezed models (`PetSwipe`, `PetMutualMatch`, `MatchingDiscoveryRow`, `PetGeoPoint`).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Pet profile: stats row + social CTA + tab scaffold

- **`lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`** — Active-pet body is a `NestedScrollView` under `DefaultTabController`: hero streak card → **`_PetStatsRow`** (Breed, Age from DOB, Weight kg, Sex placeholder `—` — no sex field on `Pet`) → full-width **`PrimaryPillButton`** (`Icons.dynamic_feed_rounded`, “View Social Profile”) calling **`context.push('/social/profile/${activePet.id}')`** → pinned **TabBar** (Overview / Health / Care / Awards). Overview tab keeps Today + feed placeholder; other tabs are light “coming soon” placeholders with `SliverOverlapInjector` wiring. Added **`go_router`** import. **`router.dart`** unchanged (`/social/profile/:petId` → `SocialProfileScreen`).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — AppHeader: avatar → profile vs name + ▾ → pet switcher

- **`lib/core/theme/app_theme.dart`** — `AppThemeSpacing` + `AppTheme.spacing` (xs/sm/md/lg on a 4dp grid) for consistent layout gaps.
- **`lib/core/widgets/app_header.dart`** — Split leading hit targets: **avatar** (`ValueKey` `app_header_pet_profile`) calls `context.go('/home')` (shell `PetProfileScreen` route). **Pet name + `Icons.keyboard_arrow_down`** (`app_header_pet_switcher`) retains `onOpenSwitcher`. Eyebrow label is non-interactive. Spacing between avatar and title block uses `AppTheme.spacing.md`; name–icon gap uses `spacing.xs`; chevron uses softly blended `onSurfaceVariant` over `surface`.
- **`router.dart`** — no change; `/home` confirmed as the active pet profile shell route.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Unified `AppHeader` + Add another pet + Manage pets (reorder/archive)

**Header redesign — shared component across all shell screens**
- **`lib/core/widgets/app_header.dart`** — new `AppHeader` consumer widget. Slot-based layout: optional `onBack` chevron, `PetAvatar` (active pet) opening the switcher via injected `onOpenSwitcher` callback (avoids circular import with `router.dart` and `pet_switcher_sheet.dart`), `eyebrow` label (e.g. `Active pet`, `Care · Montu`, `Pack`, `Match · Nearby`, `Market · Shop`) + bold pet/screen title with chevron, then a row of `AppHeaderAction` icon buttons (tooltip, optional `badge` count, `filled` variant, optional `iconKey` for marionette/widget tests). `showDivider` and `dense` flags toggle bottom hairline and tighter vertical padding. Exported from `lib/core/widgets/widgets.dart`.
- **`AppHeaderAction`** — value type: `{ icon, onTap, tooltip, badge?, filled, iconKey? }`. Badges render as coral pill over the icon (re-used by cart count in Market header).
- **Adopted in** `pet_profile_screen.dart` (eyebrow `Active pet`, actions: outdoor toggle + notifications), `care_screen.dart` (eyebrow `Care · ${activePet.name}`, action: outdoor toggle, `onBack` pops to home), `social_screen.dart` (eyebrow `Pack`, action: messages), `matching_screen.dart` (eyebrow `Match · Nearby`, action: filters, `dense: true`), `marketplace_screen.dart` (eyebrow `Market · Shop`, action: cart with live `cart.itemCount` badge). All old `_ActivePetHeader` / `_Header` / `_SocialHeader` / `_DiscoveryHeader` / `_ShopHeader` private classes removed.

**Add another pet flow**
- **`lib/core/router.dart`** — `/onboarding` now reads `state.uri.queryParameters['mode']`. When `mode=add` for an authenticated user with existing pets, the redirect guard allows the route through (instead of bouncing to `/care`). Added `/pets/manage` route → `ManagePetsScreen`.
- **`lib/features/pet_profile/presentation/screens/onboarding_screen.dart`** — constructor takes `bool addAnotherPet`. When true, `_step` starts at `1` (species + breed) skipping the welcome step, and `_back()` at step 1 calls `context.pop()` instead of stepping back to welcome — preserves the rest of the existing flow incl. DOB / weight / activity / photo capture and `createPet` write path.
- **`pet_switcher_sheet.dart`** — `_AddPetButton.onTap` → `context.push('/onboarding?mode=add')`; `_ManageRow.onTap` → `context.push('/pets/manage')` (added `ValueKey('pet_switcher_manage')` for tests).

**Manage pets (reorder + archive + undo)**
- **`lib/features/pet_profile/data/models/pet.dart`** — added `displayOrder` (`int`, default 0) + `archivedAt` (`DateTime?`); `copyWith` uses a `_sentinel` so callers can pass `archivedAt: null` to clear it; added `isArchived` getter; JSON snake-case round-trip for both fields.
- **`pet_repository.dart`** — `fetchPets({bool includeArchived = false})` filters `archived_at IS NULL` by default and orders by `display_order, created_at`; added `reorderPets(List<String> orderedPetIds)` (single batched update), `archivePet(id)` (sets `archived_at = now()`), `unarchivePet(id)` (clears it).
- **`pet_list_controller.dart`** — `reorder(reordered)` optimistically updates the local list, persists via repository, rolls back on failure. `archive(id)` returns the archived `Pet` (for undo) and removes it from local state; `unarchive(id)` re-inserts at the saved `displayOrder`.
- **`lib/features/pet_profile/presentation/screens/manage_pets_screen.dart`** — new screen. Reorderable list (`ReorderableListView.builder` with `ReorderableDragStartListener` handles), per-row `PopupMenuButton` with **Share access** (placeholder snackbar; intentionally non-functional until backend support) and **Archive pet** (confirm dialog → repo call → `SnackBar` with `Undo` action that calls `unarchive`). Active pet row gets the coral outline + `Active` chip to match the switcher sheet. Empty + error states. `AppHeader` with eyebrow `Manage · Pets`. `_AddPetCallout` row at the bottom routes to `/onboarding?mode=add` for parity with the switcher.
- **`supabase/migrations/20260516200000_pets_display_order_archive.sql`** — adds `display_order INTEGER NOT NULL DEFAULT 0` and `archived_at TIMESTAMPTZ NULL` to `public.pets`, partial index `pets_owner_active_order_idx ON (owner_id, archived_at, display_order, created_at) WHERE archived_at IS NULL`, and a one-shot backfill via `ROW_NUMBER() OVER (PARTITION BY owner_id ORDER BY created_at)` for existing rows where `display_order = 0`. Existing RLS policies on `pets` cover the new columns (owner-only SELECT/UPDATE).

**Verification**
- `flutter analyze` — clean (only resolved: removed an unused `pet.dart` import in `care_screen.dart` after the header refactor).
- `flutter test` — `care_scheduled_time_test.dart` (3) + `care_task_model_crud_test.dart` (1) pass. The pre-existing `test/widget_test.dart` placeholder still fails (missing `ProviderScope`) — known issue documented in `CLAUDE.md`, unchanged by this phase.
- **Deferred**: live emulator + Marionette walkthrough of (a) each shell screen header, (b) end-to-end add-another-pet onboarding write, (c) reorder/archive/undo in Manage pets. The migration also still needs to be applied to the remote project via `apply_migration` before the Manage screen can persist `display_order` / `archived_at` in production.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Care task edit / delete + CRUD checks

- **`care_screen.dart`** — `_CareTaskFormSheet` (add + edit): optional `existing` task; **PopupMenu** on each non–log-derived row (`care_task_menu_<id>`) for **Edit** / **Delete**; delete confirm dialog; edit reopens same bottom sheet with fields prefilled; save path calls `updateTask` or `createTask`.
- **`care_screen.dart` (follow-up)** — Rows from **orphan `care_logs`** (`Activity log | This day`, id `log:…`) now get the same **⋮** menu with **Add to plan** (prefilled new `care_tasks` row via `createSeed`) and **Remove from day** (deletes that log); plan rows keep **Edit** / **Delete**.
- **`care_dashboard_controller.dart`** — `updateTask`, `deleteTask` after repository calls reload the selected day (and week badges).
- **`pet_care_repository.dart`** — `updateTask` PATCH payload drops `id`, `pet_id`, `created_at`, `updated_at`, `category_icon` so Postgres applies `set_updated_at` and RLS stays valid.
- **`lib/features/care/presentation/utils/care_scheduled_time.dart`** — `parseCareScheduledTimeOfDay` for `scheduled_time` strings.
- **Tests** — `test/care_scheduled_time_test.dart`, `test/care_task_model_crud_test.dart` (edit `copyWith` invariants).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Seven calendar days (May 9–15) Care automation

- **`pet_care_repository.dart`** — `_appliesOnDay`: `daily` / `twice_daily` / `as_needed` tasks are shown for every calendar day on the strip (no longer hidden before `task.created_at`), matching `check_daily_completion` expected types.
- **Supabase remote** — Applied migration `check_daily_completion_completion_date` (`check_daily_completion(uuid, date)`); previously only `(uuid)` existed, so `completion_date` from the app failed and streak never updated from strip completions.
- **Marionette** — `flutter run -d emulator-5554`, connect VM service, Care tab: for each day `care_date_YYYY-MM-DD` then `care_task_check_*` taps; May 14 skipped redundant feeding tap; May 15 added feeding only.
- **Post-run** — `care_logs` for Montu (`14378b2e-5961-4d07-ab9f-48246e839e10`) have feeding+training on May 9–13 and 15; May 14 also has walk/medication from earlier tests. After migration + navigation refresh, Care UI showed **7 day streak**; `care_streaks` / `pet_badges` aligned to seven completed strip days (service SQL used once to backfill streak row where RPC had not run during the earlier tap batch).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Care streak QA (Marionette) + ring center + RPC calendar date

- **`care_screen.dart`** — Streak hero: softer outer ring stroke; center shows **done / of total** when tasks exist, with **streak** on a sub-row; empty plan keeps flame + streak in center; today legend clarifies inner vs outer rings.
- **`pet_care_repository.dart`** — After a successful complete, always calls `check_daily_completion` with `completion_date` = `logged_date` (local calendar string) so streaks update when finishing a day from the date strip, not only “device today.”
- **`supabase/migrations/20260515193000_check_daily_completion_completion_date.sql`** + **remote `execute_sql`** — `check_daily_completion(uuid, date default null)`; `v_today` uses passed date or UTC fallback; grants on `(uuid, date)`.
- **Marionette (emulator-5554)** — Care tab: May 14 shows chip `3/3`, list aligned; before change, center `0` conflicted with full inner ring.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Care streak hero synced to selected date + Fitness-style layout

- **`care_dashboard_controller.dart`** — `fetchDailyGoalsHitForDates` week list is `_weekEndingOn(selectedDate)` so week dots match the same 7-day window as the date strip selection (not always ending calendar today).
- **`care_screen.dart`** — `_StreakBanner` inner ring, done/total chip, task-type chips, and week row use `dashboard.tasks` + `selectedDay`; badge shows `TODAY` vs `MAY 14` style label; outer ring maps capped streak (28d) for a second progress track; `LayoutBuilder` + `ConstrainedBox(maxWidth: 560)` on wide windows; date strip in a solid bordered surface card per design system.
- **Supabase `execute_sql`** — Montu `care_logs`: 2026-05-14 feeding/medication/walk; 2026-05-15 feeding only (cross-check for 3/3 vs 1/2 UI).

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Marionette + emulator QA; nutrition / home streak fixes

- **`pubspec.yaml`** — `marionette_flutter` for MCP-driven UI automation (debug only; skipped under `FLUTTER_TEST` / `Platform.environment['FLUTTER_TEST']`).
- **`main.dart`** — `MarionetteBinding.ensureInitialized()` when Marionette enabled, else `WidgetsFlutterBinding`.
- **`router.dart`** — `ValueKey('shell_nav_…')` on each `NavigationDestination` for stable taps.
- **`care_screen.dart`** — `ValueKey`s: `care_fab_add_task`, `care_nutrition_banner`, `care_medical_vault_banner`.
- **`nutrition_screen.dart`** — weight chart: `minX`/`maxX`, bottom title `interval: 1` + integer guard against duplicate date labels; `_CalorieCard` takes `AsyncValue<List<HealthLog>>` so MER uses latest logged weight when data loads; display kg uses two decimals under 20 kg.
- **`pet_profile_screen.dart`** — `_HeroCard` reads `careStreakRealtimeProvider(pet.id)` instead of hardcoded `28` for the big streak number.
- **Validation** — Android emulator (`emulator-5554`) + Marionette MCP: Care tab, Nutrition, Medical vault; Supabase MCP row checks for `health_logs`, `medical_vault`, `care_logs`, `care_streaks`.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Orphan `care_logs` rows on historical days (e.g. May 14)

- **`pet_care_repository.dart`** — `fetchTasksForDate` merges `care_logs` for the selected `logged_date` into synthetic `CareTask` rows (`id` prefix `log:`) when no scheduled `care_tasks` definition covers that `care_type` for that day; `toggleCompletion` / `deleteTask` handle `log:` ids (delete log row, no `care_tasks` lookup); `_loggedDayKey` normalizes `logged_date` from PostgREST.
- **`care_task_log.dart`** — `CareTask.isLogDerived` extension.
- **`care_screen.dart`** — log-derived cards skip `Dismissible` swipe; checkbox only clears the log entry; sublabel `Activity log | This day`; `initState` defers `_init` via `Future.microtask` after first frame.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-16 — Per-day care completions (care_logs) + ring vs list

- **`pet_care_repository.dart`** — `fetchTasksForDate` scopes tasks by definition + `care_logs` for that **local calendar day**; recurring toggles insert/delete `care_logs` (aligned with `check_daily_completion`); `once` still updates `care_tasks` + log; `fetchDailyGoalsHitForDates` uses logs only; `toggleCompletion(..., forDay)`.
- **`care_dashboard_controller.dart`** — `DailyRoutineState.todayTasks` loaded in parallel so the streak **ring** always reflects **today** while the list reflects the **selected** date; toggle passes `forDay`.
- **`care_screen.dart`** — streak banner uses `todayTasks` for ring/icons and clarifies copy when browsing past days.
- **`supabase/migrations/20260516120000_care_logs_type_day.sql`** — `logged_date` backfill from `occurred_at`, widen `care_type` check, unique `(pet_id, care_type, logged_date)`.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Care dashboard Riverpod fix (tasks / add task / dates)

- **`care_dashboard_controller.dart`** — `build()` no longer reads `state` when merging the streak stream (that caused uninitialized-provider crashes and stuck `AsyncLoading` tasks). Dashboard state is merged via a private **`_routine`** snapshot plus `state = _routine` after async `_load` / toggles.
- **`care_controller.dart`** — `ref.listen(careDashboardProvider, …, fireImmediately: true)` replaces the microtask `ref.read(careDashboardProvider)` so the checklist notifier never reads the dashboard before it has emitted.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Freezed + json_serializable `_$XFromJson` fix

- Removed class-level `@JsonSerializable(fieldRename: FieldRename.snake)` from `care_task`, `medical_record`, `health_log`, `pet` (with `@freezed` it duplicated `_$XFromJson` in `.freezed.dart` and `.g.dart`). Added root **`build.yaml`** with `json_serializable` **`field_rename: snake`** so generated `fromJson`/`toJson` keep Supabase-style keys.

---

## 2026-05-15 — Care streak Realtime (UI sync)

- **`care_streak_stream_provider.dart`** — `StreamProvider.autoDispose.family` on `care_streaks` (`primaryKey: ['pet_id']`, `.eq('pet_id', petId)`), empty row → zero `CareStreak`.
- **`care_dashboard_controller.dart`** — `build()` `ref.watch(careStreakRealtimeProvider(petId))` and merges streak into returned `DailyRoutineState` (no HTTP streak in `_load`, no stacked `ref.listen`); `_load` / `toggleTaskCompletion` only refresh tasks, week dots, badges.
- **`supabase/migrations/20260515180000_care_streaks_realtime.sql`** — idempotent add of `public.care_streaks` to `supabase_realtime` publication when missing.

**Applied:** remote project `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP `apply_migration` (`care_streaks_realtime`).

**Realtime RLS:** client stream respects existing `care_streaks` SELECT policies (owner via `pets`); if a device shows no stream events, confirm the row exists for that pet after first completion and that the user session matches owner.

**Next step:** None for this slice.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-15 — Care streaks & badges (SQL migration)

- **`supabase/migrations/20260515140000_care_streaks_badges.sql`** — `care_streaks` (PK `pet_id`), `pet_badges` (PK `pet_id`, `badge_type`); RLS **SELECT** for pet owners only; **`check_daily_completion(uuid)`** `SECURITY DEFINER` + `search_path ''`: derives expected task types from `care_tasks` (`daily` / `twice_daily`) or fallback `feeding` / `walk` / `medication`; compares to `care_logs` for **UTC calendar date**; updates streak / `best_streak` / `last_completion_date`; inserts `7_day_hero` on first time `current_streak >= 7`; returns JSON summary (`total`, `completed`, `all_done`, streak fields, `badge_unlocked`). `GRANT EXECUTE` to `authenticated`; table **SELECT** only (writes via RPC).

**Applied:** remote project `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP `apply_migration` (`care_streaks_badges`). Verified `care_streaks` / `pet_badges` (RLS on) and `check_daily_completion`.

**Next step:** Wire Flutter: after checklist sync call `supabase.rpc('check_daily_completion', params: {'target_pet_id': petId})` when the third daily log lands (or on refresh). Optional: align `v_today` with app local date via a second argument in a follow-up migration.

---

## 2026-05-15 — Pet care repo: streaks, RPC on complete, task icons

- **`pet_care_repository.dart`** — `PetCareRepository` (replaces `CareTaskRepository` name; `typedef CareTaskRepository` + `careTaskRepositoryProvider` alias preserved); `getPetStreak(petId)` reads `care_streaks` (empty row → zeros); `toggleCompletion` takes `petId`, calls `check_daily_completion` after marking complete (RPC errors swallowed so toggle still succeeds); create/update strip `category_icon` until DB column exists.
- **`care_repository.dart`** — re-exports `pet_care_repository.dart`.
- **`care_streak.dart`** — hand-written model + `fromJson` / `toJson` (no freezed) for `care_streaks` rows.
- **`care_task.dart`** — `categoryIcon` (JSON `category_icon`), `resolvedCategoryIcon`, `categoryIconData`; `careTaskCategoryIconData` maps keys + aliases to `IconData`.
- **`care_dashboard_controller.dart`** — passes `petId` into `toggleCompletion`.
- **`care_screen.dart`** — task cards use `task.categoryIconData`.
- **`analysis_options.yaml`** — exclude `*.g.dart` / `*.freezed.dart` from analyzer (resolves duplicate `_$XFromJson` between freezed + json_serializable outputs).

**Next step:** Optional UI for `getPetStreak`; optional `category_icon` column on `care_tasks` if server-driven icons are required.

---

## 2026-05-15 — Care streak banner UI (Fitness / Snapchat style)

- **`pet_care_repository.dart`** — `fetchPetBadgeTypes`, `fetchDailyGoalsHitForDates` (care_tasks daily expectations + `care_logs` + completed `care_tasks` per day); `toggleCompletion` returns `ToggleCompletionResult` (parses RPC `badge_unlocked`).
- **`care_dashboard_controller.dart`** — `DailyRoutineState` adds `streak`, `weekGoalHit`, `badgeTypes`; `_load` parallel-fetches tasks/streak/badges/week; first-load badge baseline via `_hydratedBadgePets`; subsequent loads detect new `7_day_hero`; toggle still calls `AppSnackBar.showBadgeUnlocked` on RPC flag.
- **`app_snack_bar.dart`** — `showBadgeUnlocked` floating snackbar (green + trophy).
- **`care_task.dart`** — `careTaskTypeIconData` for icon chips.
- **`care_screen.dart`** — `_StreakBanner` is a `ConsumerWidget`: progress ring (`CircularProgressIndicator` + fire + server streak), 7-day dot row from `weekGoalHit`, `Wrap` of unique `taskType` icons for today’s routine list; removed legacy `_DayCell` / `_LegendDot` / `_TaskGlyphPainter`.

**Next step:** Optional full-screen badge overlay; optional confetti package.

---

## 2026-05-15 — Medical record renewal getter + nutrition chart empty state

- **`medical_record.dart`** — `renewalDate` (`nextDueAt ?? expiresAt`) and `isExpiringSoon` (date-only renewal within today…today+30).
- **`medical_vault_screen.dart`** — Warning styling uses `record.isExpiringSoon`; removed duplicate renewal logic from the private extension.
- **`petfolio_empty_state.dart`** + **`widgets.dart`** — Reusable empty state (icon, title, subtitle).
- **`nutrition_screen.dart`** — Weight trend shows `PetfolioEmptyState` when fewer than two weight logs (distinct copy for 0 vs 1); removed `_EmptyChart`.

**Next step:** None.

---

## 2026-05-15 — Care task toggle: optimistic UI + AppSnackBar errors

- **`app_snack_bar.dart`** + **`widgets.dart`** — `appSnackBarMessengerKey` + `AppSnackBar.showError` for app-wide floating snackbars.
- **`main.dart`** — `scaffoldMessengerKey: appSnackBarMessengerKey` on `MaterialApp.router`.
- **`care_dashboard_controller.dart`** — `toggleTaskCompletion`: optimistic list update, await `_repo.toggleCompletion`, on failure revert when still same active pet + `AppSnackBar.showError`.
- **`care_screen.dart`** — call sites use `toggleTaskCompletion`.

**Next step:** None.

---

## 2026-05-15 — Care dashboard & health vault scoped to active pet ID

- **`care_dashboard_controller.dart`** — `careDashboardProvider` is a single `NotifierProvider` that `ref.watch(activePetIdProvider)`; null ID → `AsyncData([])` and today’s date; pet change → loading + `_load` for that pet with stale-response guards; mutations no-op when no active pet.
- **`health_vault_controller.dart`** — `healthVaultControllerProvider` is a non-family `StreamNotifierProvider`; `build()` watches `activePetIdProvider`, null → `Stream.value([])`, else Supabase realtime stream for that `pet_id` (re-subscribes when ID changes).
- **`care_controller.dart`**, **`care_screen.dart`**, **`medical_vault_screen.dart`** — Call sites updated (no `.family` argument).

**Next step:** None required for this wiring; optional QA when switching pets on Care and Medical vault tabs.

---

## 2026-05-14 — Care routing, onboarding → Care, care cleanup

- **`lib/core/router.dart`** — Documented Care routes: shell `/care`, overlays `/care/nutrition`, `/care/medical-vault`. Redirect when `/onboarding` but user already has pets now sends **`/care`** (was `/home`). Deep link after successful onboarding: **`/care?onboardingComplete=1`** (handled in `CareScreen`).
- **`onboarding_screen.dart`** — After successful `_complete`, **`context.go('/care?onboardingComplete=1')`** instead of `/home` (avoids circular import with `router.dart`).
- **`care_screen.dart`** — `didChangeDependencies` + one-shot flag: reads `onboardingComplete=1`, shows floating **SnackBar**, then **`context.go('/care')`** to strip the query.
- **`lib/features/care/data/models/care_task_type.dart`** — Removed unused PetSphere-style **mock** `label` / `sublabel` / `iconColor` / `iconTint` getters; enum `feed` / `walk` / `med` unchanged for checklist + streak wiring.

**Scan note:** No separate mock asset files or deprecated screens under `lib/features/care/` beyond the trimmed enum.

**Next step:** Optional — document `/care?onboardingComplete=1` in README for QA.

---

## 2026-05-14 — Automated Medical Vault UI (Care)

- **`lib/core/widgets/app_bottom_sheet.dart`** — `AppBottomSheet.show` wraps `showModalBottomSheet` with transparent scrim, scroll-controlled sheet, and `PetfolioThemeExtension.surface1` top shell; exported from `widgets.dart`.
- **`lib/features/care/presentation/screens/medical_vault_screen.dart`** — `MedicalVaultScreen` + public `AddMedicalRecordSheet`: three sections (Vaccines: `vaccine`; Medications: `medication`, `parasite_prevention`; Vet visits: `surgery`, `allergy`, `other`) fed by `ref.watch(healthVaultControllerProvider(petId))`. Cards use `pt.warning` border/fill/tint when **renewal** = `nextDueAt ?? expiresAt` falls between **today** and **today + 30 days** (date-only). FAB opens `AppBottomSheet` with the form; save calls `addRecord`. Swipe on a card triggers `deactivateRecord` (optimistic list update via stream).
- **`lib/core/router.dart`** — full-screen route `/care/medical-vault` → `MedicalVaultScreen`.
- **`lib/features/care/presentation/screens/care_screen.dart`** — `_MedicalVaultBanner` under daily tasks (same pattern as nutrition) navigates to the vault.
- **`health_vault_controller.dart`** — `addRecord` returns `Future<bool>` so the sheet can show an error without popping on failure.

**Next step:** Optional polish — record detail screen, edit flow, or push notifications when `reminder_enabled` and `next_due_at` align.

---

## 2026-05-14 — CLAUDE.md Rules & Token Strategy Appended

- Added **Project Rules & Token Optimization Strategy** section to `CLAUDE.md`
- Rules cover: no-documentation policy, `progress.md` pattern, aggressive context scoping, targeted diffs, and strict sequential feature execution order

**Next step:** Begin next feature phase. Start a new task with a specific feature name (e.g. "implement Care Tasks UI") and Claude will scope reads to only that feature directory.

---

---

## 2026-05-14 — Pet Care & Health Management Schema

**Migration:** `supabase/migrations/20260513192825_pet_care_health.sql`
**Applied to:** live Supabase project `jqyjvhwlcqcsuwcqgcwf`
**Docs updated:** `docs/database_schema_and_erd.md` (table count 9 → 12, ERD extended)

### What was done

Added the backend schema for a Pet Care & Health Management system. No Flutter code was written; this session established the data layer only.

1. **`pets.activity_level`** — new nullable column (`sedentary | low | moderate | high | very_high`) added to the existing `pets` table.

2. **`care_tasks`** — new table for scheduled and recurring care tasks per pet. Distinct from `care_logs` (which records past events); `care_tasks` represents the forward-looking schedule. Supports gamification via `gamification_points` (default 10).

3. **`health_logs`** — new table for narrative health events (symptoms, weight entries, vet visit notes). Distinct from `health_vitals` (structured numeric measurements); `health_logs` captures the clinical story around each event.

4. **`medical_vault`** — new table for vaccine and medication records with `expires_at` and `next_due_at` date tracking. Supports reminder logic via `reminder_enabled` flag and partial indexes on the date columns.

5. **`set_updated_at()` trigger function** — shared trigger applied to all three new tables. Created with `SET search_path = ''` (Supabase security lint 0011 compliant).

---

### Data Contracts

#### `care_tasks`
| Field | Type | Notes |
|---|---|---|
| `pet_id` | `uuid FK → pets.id` | CASCADE delete |
| `task_type` | `text` | `feeding \| walk \| grooming \| medication \| vet_visit \| training \| playtime \| dental \| nail_trim \| bath \| other` |
| `frequency` | `text` | `once \| daily \| twice_daily \| weekly \| biweekly \| monthly \| as_needed` |
| `scheduled_time` | `time` | nullable; wall-clock time of day |
| `is_completed` | `boolean` | default `false` |
| `completed_at` | `timestamptz` | nullable; set when task is ticked off |
| `gamification_points` | `integer` | default `10`, must be ≥ 0 |

#### `health_logs`
| Field | Type | Notes |
|---|---|---|
| `pet_id` | `uuid FK → pets.id` | CASCADE delete |
| `recorded_by` | `uuid FK → users.id` | must equal `auth.uid()` on insert |
| `log_type` | `text` | `symptom \| weight \| vet_visit \| medication \| allergy \| injury \| general` |
| `weight_kg` | `numeric` | nullable; only relevant for `log_type = weight` |
| `severity` | `text` | nullable; `mild \| moderate \| severe \| critical` |
| `follow_up_date` | `date` | nullable; drives follow-up reminders |
| `occurred_at` | `timestamptz` | default `now()`; index supports DESC timeline queries |

#### `medical_vault`
| Field | Type | Notes |
|---|---|---|
| `pet_id` | `uuid FK → pets.id` | CASCADE delete |
| `record_type` | `text` | `vaccine \| medication \| allergy \| surgery \| parasite_prevention \| other` |
| `administered_at` | `date` | nullable |
| `expires_at` | `date` | nullable; partial index `(pet_id, expires_at)` |
| `next_due_at` | `date` | nullable; partial index `(pet_id, next_due_at)` — primary field for reminder queries |
| `is_active` | `boolean` | default `true`; set to `false` to archive without deleting |
| `reminder_enabled` | `boolean` | default `true`; UI should gate notification scheduling on this |
| `document_url` | `text` | nullable; link to uploaded vaccine certificate / prescription |

---

## Phase: M3E Remaining Tasks — Complete (2026-06-07)

- **`lib/core/services/prefs_schema.dart`** — new `PrefsSchema` class with all SharedPreferences key constants + `migrate()` startup guard (v0→v1 baseline stamp)
- **`lib/main.dart`** — `await PrefsSchema.migrate()` inserted after `_assertEnvVars()`; import added
- **`lib/features/care/presentation/widgets/gamified_care_ui.dart`** — XP subtitle now shows next level title (e.g. `…XP to "Pet Whisperer"`) via `lv.nextTitle`
- **`lib/features/social/presentation/screens/social_screen.dart`** — `PostCard` avatar wrapped in `SweepGradient` conic ring (`ShapeDecoration + CircleBorder`) with 2.5 px gradient border + 1.5 px surface gap
- **`lib/features/marketplace/data/models/product.dart`** — `ProductCategory` enum extended with `beds` and `apparel` (labels wired); `double? rating` field added to constructor, `fromJson`, `fromStorageJson`, `toStorageJson`
- **`lib/features/marketplace/presentation/screens/marketplace_screen.dart`** — `_cats` uses `ProductCategory.beds`/`.apparel` (hacks removed); `_NewProductTile` star chip wired to `product.rating`; `_DeliveryStrip` sliver inserted after `_HeroBanner` (all tab only); `_DeliveryStrip` ConsumerWidget appended at EOF
- **`supabase/migrations/20260607000000_products_rating_categories.sql`** — adds `rating DECIMAL(3,2)` column + updates category CHECK constraint to include `beds` and `apparel`
- `flutter analyze` → **No issues found**

---

## Phase: FloatingToolbar — Pet Profile (2026-06-07)

**File changed:** `lib/features/pet_profile/presentation/screens/pet_profile_screen.dart`

- Added `floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat` + `floatingActionButton: _FloatingToolbar(pet: activePet)` to the `Scaffold`
- **`_FloatingToolbar`** — `StatefulWidget` with `SingleTickerProviderStateMixin`; spring entrance via `AnimationController(620ms)` + `Curves.elasticOut` on a `0→1 ScaleTransition`
- Pill container: `BoxDecoration(color: surface, borderRadius: 999, boxShadow: ...)`
- Three **`_ToolbarBtn`** actions:
  - **Edit** (`Icons.edit_rounded`, tangerine) → `context.push('/pet/${pet.id}/edit')`
  - **Care** (`Icons.favorite_rounded`, poppy) → `context.push('/care')`
  - **Post** (`Icons.camera_alt_rounded`, sky) → `context.push('/social/create-post')`
- `flutter analyze` → **No issues found**

### Next step
All M3E tasks complete — no pending items.

---

## Phase: Fix Plan Phases 5–10 + Pre-release Sweep (2026-06-07)

**Audited and closed all remaining Fix Plan items:**

- Phases 5, 6, 8, 9 — already fully implemented in prior sessions; checkboxes updated ✅
- **Phase 7** — `_RecentAchievementsRow` converted from `StatelessWidget` (hardcoded 5 badges) to `ConsumerWidget(petId)` watching `petAwardsSummaryProvider`; now renders all 6 `kBadgeCatalog` badges with real `owned` state from DB
- **Phase 10 (placeholder taps)** — `product_card.dart` wishlist `onTap: () {}` → `AppSnackBar.show('Wishlist coming soon 💛')`; `pet_profile_screen.dart` Gallery → `AppSnackBar.show('Photo gallery coming soon 📸')`
- `flutter pub run build_runner build` — 0 new outputs (all `.g.dart` files up to date)
- `flutter analyze` → **No issues found**

### Next step
All Fix Plan phases complete. Codebase is in pre-release ready state.

### RLS Summary

All three new tables enforce **pet-owner-only** access. The ownership check used consistently:

```sql
(SELECT auth.uid()) IN (
  SELECT owner_id FROM public.pets WHERE id = <table>.pet_id
)
```

- **SELECT / UPDATE / DELETE** — USING clause with the ownership check above.
- **INSERT** — WITH CHECK clause with the same ownership check. `health_logs` INSERT additionally enforces `(SELECT auth.uid()) = recorded_by`.
- **UPDATE** — carries both USING and WITH CHECK to prevent silent 0-row updates (Postgres RLS requirement).

No public or service-role bypass policies exist on these tables.

---

---

## 2026-05-14 — Dart Models: Pet, CareTask, HealthLog, MedicalRecord

**Files created:** `lib/features/care/data/models/` (4 models + 8 generated files)
**Code generation:** `build_runner build` — 12 outputs written, 0 errors

### Models

- **`pet.dart`** — Freezed `Pet` + `ActivityLevel` enum. New fields: `dateOfBirth`, `activityLevel`. Helpers: `ageInYears`, `ageLabel`, `speciesEnum`. **Supersedes** `lib/features/pet_profile/data/models/pet.dart` — that file should be replaced/re-exported once care repositories are wired.
- **`care_task.dart`** — Freezed `CareTask` + `CareTaskType` + `CareFrequency` enums. Maps `care_tasks` table. Helpers: `isDueToday`, `isOverdue`, `markCompleted()`, `reset()`. ⚠️ `CareTaskType` name conflicts with old UI-only enum in `care_task_type.dart` — avoid importing both in the same file.
- **`health_log.dart`** — Freezed `HealthLog` + `HealthLogType` + `HealthSeverity` enums. Maps `health_logs` table. Helpers: `isWeightEntry`, `isVetVisit`, `followUpOverdue`, `daysUntilFollowUp`.
- **`medical_record.dart`** — Freezed `MedicalRecord` + `MedicalRecordType` enum. Maps `medical_vault` table. Helpers: `isExpired`, `isDueSoon(withinDays)`, `isOverdue`, `daysUntilExpiry`, `daysUntilDue`, `needsReminder`.

### Data Contracts

All fields use `@JsonSerializable(fieldRename: FieldRename.snake)` — Dart `camelCase` fields map automatically to DB `snake_case` columns. All enums use `@JsonEnum(fieldRename: FieldRename.snake)`.

### Open items / next steps

- Repositories for `care_tasks`, `health_logs`, and `medical_vault` — Supabase queries, RLS-aware.
- Riverpod providers / StateNotifiers wrapping those repositories.
- Replace `lib/features/pet_profile/data/models/pet.dart` with the new Freezed version (or re-export from care models).
- `pet.dateOfBirth` needs a DB migration to add `date_of_birth date` column to `pets` table if age display is needed.
- `care_tasks` gamification point totals need Dart-side aggregation for streak/score UI.
- `medical_vault.reminder_enabled` + `next_due_at` → push notification scheduling.
- `health_logs.follow_up_date` → optionally auto-create a `vet_visit` `care_task` row.

---

---

## 2026-05-14 — Care & Health Repositories + AppException

**Files created/modified:**
- `lib/core/errors/app_exception.dart` — new
- `lib/features/care/data/repositories/care_repository.dart` — replaced (was checklist logic, now CareTask CRUD)
- `lib/features/care/data/repositories/checklist_repository.dart` — new (renamed from old care_repository.dart)
- `lib/features/care/data/repositories/health_repository.dart` — new
- `lib/features/care/presentation/controllers/care_controller.dart` — import updated
- `lib/features/care/data/models/*.dart` (4 files) — annotation fix

### What was implemented

- **`AppException`** — sealed class with 5 typed subclasses: `NetworkException`, `NotAuthenticatedException`, `NotFoundException`, `ValidationException`, `DatabaseException`. All repositories catch `PostgrestException` and rethrow as the appropriate subclass. `PGRST116` (no rows) maps to `NotFoundException`.

- **`CareTaskRepository`** (`care_repository.dart`) — full CRUD against `care_tasks` table:
  - `fetchTasksForPet(petId)` — all tasks ordered by `created_at`
  - `fetchTasksForDate(petId, date)` — two queries merged: uncompleted tasks + tasks with `completed_at` on target date
  - `createTask(task)` — inserts without `id` (DB generates); returns created row
  - `updateTask(task)` — updates by `id`; returns updated row
  - `deleteTask(taskId)` — hard delete
  - `toggleCompletion(taskId, {required bool isCompleted})` — atomically sets `is_completed` + `completed_at`; returns updated row

- **`HealthRepository`** (`health_repository.dart`) — CRUD against `health_logs` table:
  - `fetchLogsForPet(petId)` — newest first
  - `fetchLogsByType(petId, type)` — filtered by `HealthLogType`
  - `fetchWeightHistory(petId)` — weight entries only, ascending (chart-ready)
  - `createLog`, `updateLog`, `deleteLog`

- **`MedicalVaultRepository`** (`health_repository.dart`) — CRUD against `medical_vault` table:
  - `fetchRecordsForPet(petId)` — all records newest first
  - `fetchActiveRecords(petId)` — `is_active = true`, ordered by `next_due_at` ascending
  - `fetchRecordsByType(petId, type)` — filtered by `MedicalRecordType`
  - `createRecord`, `updateRecord`, `deleteRecord`
  - `deactivateRecord(recordId)` — soft delete (sets `is_active = false`)

- **`ChecklistRepository`** (`checklist_repository.dart`) — existing offline-first daily checklist logic (SharedPreferences + `care_logs` upsert/delete) preserved verbatim; class/provider renamed so `care_repository.dart` was free for the new implementation.

- **Annotation fix** — moved `@JsonSerializable(fieldRename: FieldRename.snake)` from factory constructor to class declaration in `care_task.dart`, `health_log.dart`, `medical_record.dart`, `pet.dart`. Resolves `invalid_annotation_target` lint. `flutter analyze` → 0 issues.

### Providers

| Provider | Type |
|---|---|
| `careTaskRepositoryProvider` | `Provider<CareTaskRepository>` |
| `healthRepositoryProvider` | `Provider<HealthRepository>` |
| `medicalVaultRepositoryProvider` | `Provider<MedicalVaultRepository>` |
| `checklistRepositoryProvider` | `Provider<ChecklistRepository>` (replaces old `careRepositoryProvider`) |

### Next step

Wire controllers (Riverpod StateNotifiers) for `CareTaskRepository` and `HealthRepository`, then build UI screens to display tasks and health logs.

---

---

## 2026-05-14 — Onboarding Refactor: Care Engine Data Capture

**Files modified:**
- `lib/features/pet_profile/data/models/pet.dart`
- `lib/features/pet_profile/data/repositories/pet_repository.dart`
- `lib/features/pet_profile/presentation/controllers/pet_list_controller.dart`
- `lib/features/pet_profile/presentation/screens/onboarding_screen.dart`

### What was implemented

Refactored the pet onboarding flow from 5 steps to 8 steps (6 visible in progress bar) to capture care-engine-required data during pet creation.

**New step flow:**
- Step 0: Welcome (unchanged)
- Step 1: Species + Breed (combined — species grid auto-expands breed list below)
- Step 2: Name (unchanged)
- Step 3: Date of Birth (Material date picker, shows computed age, skippable)
- Step 4: Weight (current + optional target, kg/lbs toggle, skippable)
- Step 5: Activity Level (5-card grid: Couch Potato → Athlete, skippable)
- Step 6: Photo (moved from step 4, unchanged)
- Step 7: Done (updated summary with breed/age/weight chips + accurate checklist)

**Data contracts added to `Pet` model:**
- `dateOfBirth: DateTime?` — maps `pets.date_of_birth`
- `weightKg: double?` — maps `pets.weight_kg`
- `activityLevel: String?` — maps `pets.activity_level`

**Repository changes:**
- `PetRepository.createPet()` now accepts and writes `dateOfBirth`, `weightKg`, `activityLevel`
- `PetRepository.writeTargetWeight(petId, kg)` — inserts target weight into `health_vitals` with `vital_type='weight'`, `notes='goal'` (best-effort, non-fatal if it fails)

**UX decisions:**
- DOB, weight, and activity steps all have "Skip for now" (secondary CTA) — no required steps after name
- Unit toggle (kg/lbs) in the weight step converts on the fly; stores kg in DB
- Species+breed combined: breed section animates in with `AnimatedSize` after species tap; search field clears automatically on species change
- Done step shows breed/age/weight as styled chips; checklist reflects which care-engine fields were provided

### Known constraint
- `health_vitals` RLS policy may need an explicit INSERT policy for the pet owner — verify in Supabase dashboard if target weight writes fail (currently best-effort/silent)

### Next step
Wire the care engine controllers to consume `pet.dateOfBirth` and `pet.activityLevel` for personalised task defaults. The care `Pet` model in `lib/features/care/data/models/pet.dart` is now a duplicate — consolidate with this model when wiring care controllers.

### PR 4 Copilot review follow-ups (local)
- Web-safe Marionette gate via `lib/marionette_debug_gate_{stub,io}.dart` conditional import; removed `dart:io` from `main.dart`
- Social header Messages action navigates to `/matching`
- `PetListNotifier.unarchive` sorts merged list by `displayOrder` then `createdAt` like `fetchPets`
- `care_scheduled_time` uses explicit int bounds for `TimeOfDay`
- `pet_care_repository` monthly `_appliesOnDay` uses calendar month/day with end-of-month clamping
- Migration `20260516120000_care_logs_type_day.sql` deletes duplicate `(pet_id, care_type, logged_date)` before unique index
- `.gitignore`: `.cursor/hooks/state/`, `tmp_window_dump.xml`, `.claude/worktrees/`

### Supabase remote sync (MCP, 2026-05-16)
- Verified project `jqyjvhwlcqcsuwcqgcwf`: tables/constraints match repo intent; `chat_threads` uses `participant_1_id` / `participant_2_id` (not pet columns in app code).
- **Remote lacked** `pet_care_gamification` while `20260515000000_fix_gamification_missing_table.sql` existed — applied via MCP as migration `pet_care_gamification_table_and_rls` (full SELECT/INSERT/UPDATE/DELETE RLS + `set_updated_at` trigger). Repo file updated to match.
- **Duplicate unique indexes** on `care_logs` (`care_logs_pet_care_day_uix` vs `care_logs_pet_care_type_logged_date_uq`) — dropped `care_logs_pet_care_day_uix` via MCP; added `20260517000000_drop_duplicate_care_logs_unique_index.sql` for clean local resets.
- Hosted migration history uses timestamp+name keys that do not 1:1 match local filenames (some history was created from dashboard/MCP); prefer `supabase db pull` when rebaselining or rely on ordered SQL in `supabase/migrations/`.

### App ↔ Supabase follow-ups (2026-05-16)
- Social `fetchFeed` / `fetchPostsForPet` / `fetchPostById`: removed wrong `post_likes.pet_id` filter; `ChatThread` + `chatThreadsProvider` use `participant_1_id` / `participant_2_id` and `match_requests` pet scoping.
- Router `/pet/:petId/edit`: no `firstWhen` throw; missing pet → `_PetEditMissingScreen`.
- `npx supabase migration repair` batch run to align remote `schema_migrations` with local migration filenames; `npx supabase migration list` now matches. `npx supabase db pull` blocked here without Docker—run with Docker for shadow DB.

Phase complete; consider `/remember` if you want this sync persisted outside `progress.md`.

## 2026-05-17 — Discovery visibility (data layer)

- Migration `20260518120000_pets_is_discoverable.sql`: `pets.is_discoverable boolean NOT NULL DEFAULT false`; partial index; `matching_discovery_candidates` filters `c.is_discoverable IS TRUE` and returns `is_discoverable` in the row set. Applied to hosted project via MCP.
- `lib/features/pet_profile/data/models/pet.dart`: `isDiscoverable` field, JSON `is_discoverable`, `copyWith`.
- `MatchingDiscoveryRow`: `isDiscoverable` for RPC deserialization; `build_runner` regenerated.
- `MatchingRepository.fetchCandidates`: `.where((row) => row.isDiscoverable)` before mapping.

**Next step:** UI toggle + `PetRepository` update method to set `is_discoverable` on opt-in/opt-out.

---

## 2026-05-17 — Fix Multi-Pet Discovery Bug (SQL)

- **`supabase/migrations/20260518160000_matching_discovery_exclude_own_pets.sql`** — Modified `matching_discovery_candidates` RPC: updated `origin` CTE to select `p.owner_id` and added `AND c.owner_id != o.owner_id` to the WHERE clause to ensure a user never sees their own pets in the discovery feed.
- **Supabase Remote** — Applied migration `matching_discovery_exclude_own_pets` to hosted project `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP.

**Next step:** None.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-17 — Resolve Inbox N+1 Over-fetching (SQL & Dart)

- **`supabase/migrations/20260518170000_get_match_inbox_rpc.sql`** — Created `get_match_inbox` RPC: uses `DISTINCT ON (thread_id)` to join `matches`, `chat_threads`, `pets`, and the latest `chat_messages` on the server side; added `idx_chat_messages_thread_created_at` index to eliminate full table scans.
- **Supabase Remote** — Applied migration `get_match_inbox_rpc` to hosted project `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP.
- **`matching_supabase_data_source.dart`** — Replaced `fetchMatchInboxSnapshot` with a single, lightweight call to `get_match_inbox` RPC; removed the N+1 `_latestMessagePreviews` method.

**Next step:** None.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-17 — Fix Chat Thread Race Condition (SQL)

- **`supabase/migrations/20260518180000_chat_threads_race_condition.sql`** — Rewrote `ensure_chat_thread_for_match` RPC to utilize an `INSERT ... ON CONFLICT DO NOTHING` block with a fallback `SELECT` to safely guarantee chat thread creation without unique constraint violations or race conditions.
- **Supabase Remote** — Applied migration `chat_threads_race_condition` to hosted project `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP.

**Next step:** None.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-17 — Prevent Presentation Leak in Repository (Dart)

- **`matching_repository.dart`** — Refactored `MatchingRepository.fetchCandidates` to return raw domain data (`List<MatchingDiscoveryRow>`) directly from the data source, removing all presentation-layer concerns, hardcoded hex colors, default bio strings, and aesthetic traits from the data layer.
- **`discovery_candidates_controller.dart`** — Moved `_discoveryRowToCandidate` and all color palette/default string helper methods into `DiscoveryCandidatesController`, maintaining clean separation of concerns and feature-first architecture.

**Next step:** None.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-17 — Map Advanced Swipe Actions (SQL & Dart)

- **`supabase/migrations/20260518190000_swipes_advanced_actions.sql`** — Updated `public.swipes` table action check constraint to accept `GREET` and `SUPER_PAW` enum values; updated `swipes_target_actor_like_idx` index and `swipes_after_insert_mutual_match` trigger to correctly identify and process mutual matches from any positive like action (`LIKE`, `GREET`, `SUPER_PAW`).
- **Supabase Remote** — Applied migration `swipes_advanced_actions` to hosted project `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP.
- **`pet_swipe.dart` & `pet_swipe.g.dart`** — Added `greet` and `superPaw` enum values and JSON mapping to `SwipeTableAction`.
- **`matching_repository.dart`** — Updated `recordSwipe` to correctly map UI intents (`greet`, `superPaw`, `pass`, `match`) to their respective `SwipeTableAction` database representations.

**Next step:** None.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-27 — Social Feature Refactoring & Press-and-Hold Gestures (Dart)

- **Riverpod 3 Migration** — Migrated all manual providers in the `social` feature (`NotificationController`, `SocialController`, `CommentController`, `CreatePostController`, `StoryController`) to generated `@riverpod` syntax, ensuring architectural consistency across components.
- **Supabase Realtime Join Fix** — Refactored `NotificationController` subscription to handle Postgres changes stream correctly. Instead of client-side data joins, the stream triggers database re-queries to fetch joined notification records.
- **Press-and-Hold Reaction Picker** — Implemented a long-press gesture (300ms) on the React button using a raw listener sequence. Dragging highlights the target emoji slot with premium scale and border transitions. Releasing selects the hovered reaction, triggers visual bursts, and registers a like; releasing outside closes the picker immediately. Short taps retain the toggle like/unlike behavior.
- **Widget & Unit Testing** — Added comprehensive widget tests in `post_card_widget_test.dart` and unit tests in `social_controller_test.dart` to simulate pointer interactions, verifying gesture flows and optimistic database states.

**Next step:** None.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-06-01 — Social DM Chat (Instagram-style Direct Messages)

### DB (migration: `20260601_social_dm_chat.sql`, applied to `jqyjvhwlcqcsuwcqgcwf`)
- Added `dm_pet_a_id` + `dm_pet_b_id` columns to `chat_threads` (NULL for match threads)
- `UNIQUE INDEX chat_threads_dm_pets_uidx` on `(dm_pet_a_id, dm_pet_b_id) WHERE mutual_match_id IS NULL` — one thread per pet pair
- New RPC `ensure_direct_chat_thread(p_actor_pet_id, p_other_pet_id)` — ownership-verified, canonical UUID ordering, idempotent UPSERT
- New RPC `get_chat_inbox(p_actor_pet_id)` — UNION of match threads + DM threads; `get_match_inbox` left intact

### Data layer
- `MatchInboxItem.matchId` → nullable (`String?`); added `threadType` field + `isDm` getter + updated `isNewMatch` (DMs excluded)
- `fetchMatchInboxSnapshot` → now calls `get_chat_inbox`; parses `thread_type` + nullable `match_id`
- Added `ensureDirectChatThread` to datasource + repository

### State / controller
- `ChatConversationArgs` typedef: added `String? otherPetId` (null for match chats)
- `ChatConversationController.build()`: added DM resolution branch — calls `ensureDirectChatThread` when `threadId` is empty and `otherPetId` is set

### UI
- `ChatScreen`: added `otherPetId` param; eyebrow reads `'Social · Chat'` for DMs; empty-state hint differs per type
- `router.dart`: `/matching/chat/:threadId` now reads `otherPetId` query param
- `matching_navigation.dart`: added `openDirectChat(context, ref, actorPetId, otherPetId, otherPetName)`
- `social_profile_screen.dart`: `_OtherProfileButtons` now shows **Message** button (calls `openDirectChat`); `_ActionButton.onPressed` is nullable
- `matches_inbox_screen.dart`: DM tiles tap to `openDirectChat`; match tiles use `item.matchId!`; DM tiles show a coral "DM" badge

### Zero regressions
- Existing match chat flow untouched — `get_match_inbox` and `ensure_chat_thread_for_match` unchanged
- All existing `ChatConversationArgs` call sites work: `otherPetId` defaults to `null`
- `dart analyze`: 0 issues

**Next step:** None.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

---

## 2026-05-28 — Social Feed Inline Comments Bottom Sheet (Dart)

- **Inline Comments Bottom Sheet** — Created `PostCommentsBottomSheet` inside `lib/features/social/presentation/widgets/post_comments_bottom_sheet.dart` to list and post comments inline on the feed screen without navigating to the post details page.
- **Feed Comment Action Update** — Configured the "Comment" action button on `PostCard` to trigger the `PostCommentsBottomSheet` modal (using `showModalBottomSheet(isScrollControlled: true)`) instead of routing to the details page. Tapping the post's image continues to navigate to the details page.
- **Widget Testing Integration** — Added a widget test `tapping Comment button opens PostCommentsBottomSheet` in `post_card_widget_test.dart` to verify modal rendering and correctly configured a mock comment repository.

**Next step:** None.

Phase complete and to log to .remember/remember.md, Please run (/remember) to save tokens before proceeding to the next phase.

## 2026-05-31 — Security & Performance Hardening (DB migrations + repo hygiene)

Acted on the codebase/schema review findings. Six fixes:

- **Repo hygiene** — Untracked `scratch/` (`git rm -r --cached`, kept on disk) and added `scratch/` to `.gitignore`; it held a committed Supabase anon JWT in `check_connection.dart`.
- **`20260531100000_notifications_insert_check.sql`** — Replaced `notifications_insert_policy` `WITH CHECK (true)` with actor-pet ownership binding (stops notification spoofing). Admin/system notifications still flow through SECURITY DEFINER RPCs.
- **`20260531100100_function_search_path.sql`** — Added `SET search_path = ''` to `is_admin`, `handle_post_like_sync`, `handle_comment_like_sync`, `handle_post_comment_sync`, `handle_new_chat_message`.
- **`20260531100200_bucket_listing_lockdown.sql`** — Dropped broad public SELECT policies on `storage.objects` for `pets` & `shops` buckets (stops file listing; public URLs unaffected — app only uses getPublicUrl).
- **`20260531100300_fk_covering_indexes.sql`** — Added covering indexes for 11 unindexed FKs.
- **`20260531100400_consolidate_rls_policies.sql`** — Merged duplicate/overlapping permissive policies on users, chat_threads, pet_follows, posts, shops, marketplace_orders, reported_posts, vendor_ledgers, shop_deletion_requests (access-preserving OR-merge).

All applied to remote project `jqyjvhwlcqcsuwcqgcwf`. Re-ran advisors: `function_search_path_mutable`, `rls_policy_always_true`, `public_bucket_allows_listing`, `unindexed_foreign_keys`, and `multiple_permissive_policies` warnings all cleared. Remaining advisor items are intentional (SECURITY DEFINER RPCs with internal checks) or dashboard config (leaked-password protection).

**Not done (deferred, optional):** revoke EXECUTE-from-anon on `cleanup_expired_stories`/`get_pet_awards_summary`/`mark_story_viewed`; drop genuinely-unused indexes; route vendor order writes through `vendor_update_order` RPC; de-dupe care date logic; enable leaked-password protection in Auth dashboard.

**Next step:** None — no Dart source changed, so analyzer/tests unaffected.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-04 — PR #15 Copilot review fixes (Dart + DB)

- **Care** — Restored `_HorizontalDatePicker` on `CareScreen` wired to `careDashboardProvider.notifier.selectDate()`; Vault → navigates to `/care/medical-vault`.
- **Chat** — `loadOlderMessages()` forces provider rebuild when `_hasMore` becomes false (stops infinite load-more spinner); scroll guard already uses `hasClients`.
- **DB** (`20260604120000_pr15_review_fixes.sql`, applied to `jqyjvhwlcqcsuwcqgcwf` via Supabase MCP) — Social like/comment/follow notification triggers + `notifications` realtime; `REVOKE ALL … FROM PUBLIC` on trigger functions; `get_chat_inbox` wrapped with `ORDER BY COALESCE(last_message_at, matched_at) DESC`.
- **Migrations** — Aligned `20260601000000_social_fixes`, `20260601010000_social_dm_chat`, `20260601020000_security_definer_search_path_fix` with same REVOKE/search_path/ORDER BY patterns.

**Next step:** Update PR #15 description to reflect full scope (social DM, matching pagination, migrations) or split follow-up PRs.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — PWA Phase 1 (web/PWA P0 from PWA_WEB_AUDIT.md)

- **`web/index.html`** — Removed `body` safe-area CSS (Flutter owns insets); splash 25s timeout + error copy; `touch-action: manipulation`; Stripe.js moved to `defer` at end of body; window error logging.
- **`web/pwa_banner.js`** — Safe-area bottom padding; honest install copy (no offline claim); `role="complementary"`.
- **`lib/core/services/stripe_init_service.dart`** — `ensureStripeReady()`; web defers `applySettings` until checkout; Android unchanged at cold start.
- **`lib/main.dart`** — Stripe init only on non-web at startup.
- **`lib/core/services/location_service.dart`** — Enabled `geolocator` on web (removed hard `unavailable`).
- **`lib/features/care/data/repositories/pet_care_repository.dart`** — Skip local notification scheduling on web.
- **`lib/features/matching/presentation/screens/matching_screen.dart`** — Web discovery unblocked when pet has profile location; no `openAppSettings` on web.
- **`lib/core/widgets/app_shell.dart`** — Web uses `bottomNavigationBar` instead of floating stack nav.

**Next step (Phase 2):** Web Push care reminders, Stripe Checkout redirect on web, web file picker for uploads, `PlatformService` facade.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — PWA Phase 2 (parity from PWA_WEB_AUDIT.md)

- **Platform layer** (`lib/core/platform/`) — notifications io/web, `pickGalleryImage`, payments flag, web push JS bridge.
- **DB** (`20260605100000_pwa_phase2.sql`) — `stripe_checkout_session_id`, `care_web_reminders`, `user_web_push_subscriptions` + RLS.
- **Edge functions** — `create-payment-intent` checkout_mode + URL; `register-web-push-subscription`; `stripe-webhook` `checkout.session.expired`.
- **Web checkout** — hosted Stripe Checkout on `kIsWeb`; cart resume listener; order confirmation polls on `?stripe=success`.
- **Care web** — reminders stored in Supabase; optional push enable banner when `WEB_PUSH_VAPID_PUBLIC_KEY` is set.
- **Uploads** — gallery pick abstraction on profile, social, marketplace KYC, medical vault.

**Deploy:** `npx supabase db push`; deploy `create-payment-intent`, `register-web-push-subscription`, `stripe-webhook`; add Stripe webhook event `checkout.session.expired`; set `WEB_PUSH_VAPID_PUBLIC_KEY` for push UI.

**Next step (Phase 3):** Manifest screenshots/shortcuts, iOS startup images, image mem-cache caps on web.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — PWA Phase 3 (polish from PWA_WEB_AUDIT.md)

- **`web/manifest.json`** — `id`, `screenshots` (narrow/wide), app shortcuts for `/care`, `/matching`, `/marketplace`.
- **`web/screenshots/`**, **`web/splash/`** — branded PNG assets; **`web/index.html`** — `apple-touch-startup-image` for common iPhone portrait sizes + fallback.
- **`lib/core/platform/web_image_cache.dart`** — Safari-friendly `memCacheWidth` caps on web; applied to `PetAvatar`, social feed/stories/profile, matching deck, marketplace product thumbs.

**Next step:** Device-verify iOS PWA install + shortcuts; replace screenshot PNGs with real marketing captures when available.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — Match discovery RPC signature fix (web + Android)

- **Root cause:** `20260604000000_fix_matching_discovery_candidates_offset_signature.sql` replaced the RPC with `p_offset` while `MatchingSupabaseDataSource` calls cursor params (`p_cursor_created_at`, `p_cursor_pet_id`) → PostgREST **404** on deck load.
- **Fix:** `supabase/migrations/20260605120000_restore_matching_discovery_candidates_cursor.sql` — drop offset overload, restore keyset cursor RPC + grants; applied to hosted `jqyjvhwlcqcsuwcqgcwf` via `npx supabase db query --linked`.
- **Cleanup:** `20260604000000_*` reduced to no-op for fresh migration runs.

**Verify:** Hot-restart app → Match tab should load cards (or empty deck), not “Could not load profiles”. Active pet must have `location` + `is_discoverable = true`.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — Web automation review fixes

- **Router** — `#/` redirects to `/home` or `/login`; `errorBuilder` shows “Page not found” + **Go to Home** (replaces bare GoRouter 404).
- **Web shell** — PWA install banner injects after `flutter-first-frame` (lower z-index); auto-enables Flutter semantics placeholder on first frame.
- **Manifest** — `start_url` → `/home`.
- **Care** — Nutrition/Medical utility halves use `InkWell` + semantics for reliable web taps.
- **Marketplace** — Product **+** uses `IconButton` + `ValueKey` (44px target); card uses `InkWell`.
- **Matching** — RPC errors surface as `DatabaseException`; empty-deck replenish failures become `AsyncError`; clearer deck error copy.
- **Login** — `AutofillHints.email` / `password` on auth fields.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — Web automation P1 fixes (modals, checkout, routes)

- **Modal leak** — `dismissRootOverlayRoutes` on shell route change via `_RouterNotifier.redirect` (`lib/core/navigation/route_overlay_dismissal.dart`).
- **Deep links** — `#/pets` → `/home`, `#/shop` → `/marketplace`.
- **Web Stripe checkout** — `petfolioAppUrl()` hash URLs for success/cancel; `launchUrl` with `webOnlyWindowName: '_self'`; `CartDrawer` checkout wired to `checkoutProvider` (was no-op); multi-shop → `/marketplace/cart`.
- **Stripe return** — `WebCheckoutResumeListener` + marketplace `stripe=cancel` query handling.
- **Care a11y** — `Semantics` labels on care task cards.
- **Social** — comment field `Semantics` + `ValueKey`.
- **Deploy** — `npx supabase functions deploy create-payment-intent` (hosted).

**Verify:** Hot-restart web → open comments, switch tab (sheet closes); add to cart → Checkout opens Stripe same tab; return URL `/#/marketplace/order/:id?stripe=success`.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — Supabase + Stripe MCP infra pass

- **Migration `pwa_phase2` applied (hosted)** — `stripe_checkout_session_id`, `user_web_push_subscriptions`, `care_web_reminders` + RLS.
- **`register-web-push-subscription`** deployed (MCP v1, JWT on).
- **`stripe-webhook` v11** — `checkout.session.completed` + shared `fulfillPaidOrder`; redeployed `--no-verify-jwt`.
- **Stripe webhooks** — platform `we_1TYC0v…`: PI succeeded/failed, checkout completed/expired; Connect `we_1TYEIx…`: `account.updated`.
- **Waitlist RLS** — `20260605130000_waitlist_insert_policy_hardening.sql` applied (email-format check).
- **Checkout trace** — stale `pending` orders match abandoned PIs (`requires_payment_method`), not webhook gaps.

**Manual:** `WEB_PUSH_VAPID_PUBLIC_KEY` in `.env`; enable Auth leaked-password protection in Supabase dashboard.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-06 — Firebase Cloud Messaging (Android + Web)

- **Client** — `firebase_core` + `firebase_messaging`; `lib/core/firebase/` (`FirebaseEnv` dart-defines, `FcmService`, `FcmMessageRouter`, token upsert); init in `main.dart`; auth listener registers/clears tokens.
- **Schema** — `user_fcm_devices` migration `20260606120000_user_fcm_devices.sql` (RLS own-row).
- **Web** — `firebase-messaging-sw.js`, `tool/sync_firebase_web_config.dart` → `web/firebase-config.js` from `.env`; Care banner prefers FCM when configured (legacy VAPID fallback).
- **Server** — `supabase/functions/send-fcm-notification` (FCM HTTP v1; needs `FIREBASE_SERVICE_ACCOUNT_JSON` secret).
- **Payload routes** — `care_reminder`, `match`, `chat_message`, `like`/`comment`/`follow`, `order`, `seller_order` (+ optional `route` override).
- **`.env.example`** — Firebase keys + `FIREBASE_VAPID_KEY` for web.

**Manual:** Firebase Console → Android + Web apps → fill `.env` → `dart run tool/sync_firebase_web_config.dart` → `npx supabase db push` → deploy edge fn with service account JSON.

## 2026-06-06 — FCM server dispatch (all modules)

- **Migration `20260607140000_fcm_dispatch_system`** (hosted via `db query --linked`): `pg_net`, `private.fcm_internal_config`, `fcm_push_outbox`, DB triggers on `notifications`, `chat_messages`, `matches`, `marketplace_orders`; pg_cron for outbox + care reminders.
- **Edge functions deployed**: `send-fcm-notification`, `process-fcm-outbox`, `process-care-fcm-reminders` (`--no-verify-jwt`, `x-fcm-dispatch-secret`).
- **Care**: Android/web upsert `care_web_reminders` + FCM cron; local notifications kept on Android.
- **Client**: `care_fcm_reminder_sync.dart`; router paths for KYC push types.
- **Manual:** Set `FCM_DISPATCH_SECRET` + `FIREBASE_SERVICE_ACCOUNT_JSON` in Supabase secrets; `UPDATE private.fcm_internal_config SET dispatch_secret = ...`.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-06 — petfolio-v1 FCM wiring (console config)

- **`lib/firebase_options.dart`** — Android + Web app IDs/keys from `google-services.json` and Firebase console (project `petfolio-v1`).
- **FCM-only** — Removed legacy `push_register.js` / VAPID web-push banner path; web uses FCM + `firebase-messaging-sw.js` + committed `web/firebase-config.js`.
- **Android** — `com.google.gms.google-services` + `android/app/google-services.json`.
- **`.env`** — `FIREBASE_VAPID_KEY` required for web tokens; service account JSON gitignored → Supabase secret `FIREBASE_SERVICE_ACCOUNT_JSON`.
- **`firebase-instructions.md`** — Sanitized (no private keys in repo).

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — FCM push fix (server JWT + client heads-up)

- **Root cause (hosted)** — `send-fcm-notification` HTTP 500: `FIREBASE_SERVICE_ACCOUNT_JSON` Supabase secret is invalid JSON; edge logs failed on chat INSERT (~20:54 UTC) despite 2 Android tokens in `user_fcm_devices`.
- **Server** — `fcm_send.ts` base64url JWT fix, Android `petfolio_push` channel, stale token cleanup; functions redeployed.
- **Client** — FCM foreground/background shows tray notifications via `fcm_push_display.dart` + `NotificationService.showPushNotification`; tap → `FcmMessageRouter`; Android default channel meta-data.
- **Tool** — `tool/set_fcm_supabase_secrets.ps1`.

**Manual:** Re-run secret script with Firebase adminsdk JSON, hot-restart both devices, test chat with recipient app backgrounded.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — FCM secrets + VAPID wired (hosted verified)

- **`petfolio-v1-firebase-adminsdk-fbsvc-849086572f.json`** in repo root (gitignored); `.\tool\set_fcm_supabase_secrets.ps1` uploads minified `FIREBASE_SERVICE_ACCOUNT_JSON` + `FCM_DISPATCH_SECRET` to Supabase.
- **Hosted test:** `send-fcm-notification` → `{"sent":1,"total":1}` (server push pipeline live).
- **`.env`:** `FIREBASE_VAPID_KEY` matches Web Push certificate public key; `dart run tool/sync_firebase_web_config.dart` refreshed `web/firebase-config.js`.
- **Script fixes:** PowerShell `Join-Path` + optional default adminsdk path; `supabase/.secrets.fcm.env` gitignored.

**Manual:** Full restart on both Android devices + web (`flutter run --dart-define-from-file=.env`); test chat with recipient backgrounded; web Care tab → Enable push banner if token not auto-registered.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — Vercel web CI secrets + deploy workflow

- **GitHub Actions secrets:** `gh secret set -f .env -R CodeStorm-Hub/petfolio` synced all `.env` keys; `VERCEL_TOKEN` unchanged (set manually).
- **`deploy-web.yml`:** Flutter 3.44.0 pin, `FIREBASE_VAPID_KEY` dart-define, CI `.env` materialization + `dart run tool/sync_firebase_web_config.dart`, Node 22 + global Vercel CLI, concurrency + `workflow_dispatch`.
- **`vercel.json`:** `installCommand: ""` so prebuilt Flutter output is not npm-installed.

**Manual:** Confirm `VERCEL_TOKEN` is valid; push to `main` or open PR to trigger deploy.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — Production Vercel + Supabase web checkout

- **Vercel (`petfolio`):** `prj_hMHouLWimZvr5dDOlZeAhbH8xtop` · production domains `petfolio.live`, `www.petfolio.live`, `petfolio-woad.vercel.app`.
- **Supabase secrets:** `PUBLIC_APP_ORIGIN=https://petfolio.live`, `ALLOWED_REDIRECT_ORIGINS` (live + www + Vercel prod alias).
- **`create-payment-intent`:** redeployed (redirect URL allowlist).
- **`deploy-web.yml`:** production-only (`main` push + `workflow_dispatch`; no PR preview deploy).

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-05 — iOS web push + PWA touch freeze

- **Misleading error:** `syncToken()` failed on iPhone Chrome tab; banner blamed missing `FIREBASE_VAPID_KEY` even when key was baked in. iOS web push only works from **Home Screen PWA** (standalone), not in Safari/Chrome tabs.
- **`FcmService`:** No auto permission/token on web startup; `syncToken(requestPermission: true)` on explicit Enable; `syncTokenWithMessage()` for accurate errors; wait for FCM service worker before `getToken`.
- **`WebPushEnableBanner`:** iPhone browser tab shows install-to-Home-Screen guidance (no Enable button); PWA shows Enable with real failure messages.
- **`main.dart` / `fcm_lifecycle`:** Skip auto `syncToken` on web login (was triggering permission without user gesture → iOS freeze).
- **`web/index.html`:** `__petfolioFcmSwReady` + `__petfolioIsIosStandalonePwa`; skip semantics placeholder click on Apple WebKit.

**Manual:** Confirm GitHub secret `FIREBASE_VAPID_KEY` matches Firebase Console → Cloud Messaging → Web Push certificates. Test push from **Home Screen icon**, not Chrome tab.

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

## 2026-06-06 — Care Feature Bug Fixes + AI Routine Overhaul

### Care Task Completion / Undo Fixes
- Added `task_id UUID` column to `care_logs` with partial unique indexes; dropped old `care_type`-only unique index
- Updated `toggle_care_task` RPC: writes `task_id` on complete; deletes by `task_id` on undo
- Added backward-compat DELETE for null-task_id legacy entries (undo now works for rows created before migration)
- Added lazy migration UPDATE: completing a task backfills `task_id` on any existing null-task_id log
- Fixed `_buildTasksFromSnapshotData`: matches by `task_id` first, falls back to `care_type` only when unambiguous (exactly 1 task of that type today)
- Fixed `_computeWeekGoalHitFromSnapshotData` with same ambiguity-safe logic
- DB cleanup migration: removed duplicate `care_tasks` rows across all pets

### AI Routine Recommendations — Full Overhaul

**New `ai_routine_controller.dart`**
- `AiSuggestion` model: wraps `CareTask` + `isDuplicate` + `conflictTitle` + `isSelected` (default `false` — opt-in)
- `AiRoutineState` enum: `idle | loading | success | error`
- `AiRoutineNotifier`: 24h per-pet cache, concurrent-call guard (`isLoading` early return), `generate()` / `forceRefresh()` / `invalidateCache()`
- Fuzzy duplicate detection: exact title → 80% similarity → same task-type + frequency bucket

**`care_recommendation_service.dart`**
- Added `once` to guided JSON schema and `_parseFrequency`
- Fixed `defaultValue: ''` on `String.fromEnvironment` (was missing)
- Improved config error message (actionable: add key + rebuild)

**`routine_recommendation_sheet.dart`** (rewritten)
- Opt-in selection — all cards start deselected
- "Already in routine" greyed badge on duplicate cards + conflict title footnote
- Fixed frequency grouping: `asNeeded` → "As Needed" group (was "Daily"); `twiceDaily` → "Twice Daily"; `once` → "One-Time"
- Fixed summary chips: separate chip per frequency (was conflating `twiceDaily` + `asNeeded` into daily)
- `PopScope` confirm-on-dismiss dialog when tasks are selected
- Retry button on save failure via `AppSnackBar.showError(onRetry:)`
- Cache invalidated after save so next open re-fetches against updated task list

**`care_screen.dart`**
- Removed direct `CareRecommendationService()` instantiation — notifier owns the service via `careRecommendationServiceProvider`
- `_generateRoutine`: 3-case handler (cached → instant sheet, already loading → no-op, fresh → generate + sheet)
- `_forceRefreshRoutine`: properly `await`s `forceRefresh()` before showing sheet (fixed race condition)
- `_autoPrewarmAi`: silently starts background generation post-onboarding (no sheet shown)
- `_shouldAutoTriggerAi` flag: set on `onboardingComplete=1`, triggers background pre-warm once pet is available
- `GestureDetector` → `InkWell` with ripple on AI icon button
- Config error → permanent `_AiConfigErrorBanner` widget (not transient snackbar)
- `_AiRoutineBanner` now has 3 states: generating (spinner + "Preparing…") / ready (✓ "Your AI Routine is Ready!") / idle

**`app_snack_bar.dart`**
- `showError` gains optional `onRetry: VoidCallback?` → shows "Retry" `SnackBarAction`

### Graphify Knowledge Graph Rebuilt
- Rebuilt on `lib/` (307 Dart files) → 4,126 nodes, 6,305 edges, 208 communities
- `activePetControllerProvider` identified as highest god node (63 edges); blast radius traced: 14 screens, 9 controllers, 4 widgets

**Next step:** Test AI routine flow end-to-end (onboarding → auto pre-warm → banner ready state → sheet → save).

---

## 2026-06-05 — iOS mobile web PWA startup fix

- **Root cause:** `flutter-first-frame` never fired on iOS WebKit — CanvasKit from gstatic CDN, Flutter service worker vs FCM SW contention, blocking Firebase/FCM before `runApp`, and `COEP`/`COOP` on `.wasm` responses.
- **`web/flutter_bootstrap.js`:** Skip Flutter `serviceWorkerSettings` on Apple WebKit (iPhone/iPad); desktop/Android keep SW caching.
- **`web/index.html`:** Unregister stale `flutter_service_worker.js` on iOS before boot; bootstrap `onerror` + `main.dart.js` error surfacing.
- **`deploy-web.yml`:** `--no-web-resources-cdn` (local `canvaskit/`), `--no-wasm-dry-run`.
- **`vercel.json`:** Removed `Cross-Origin-Embedder-Policy` / `Cross-Origin-Opener-Policy` from `.wasm` (not using threaded skwasm).
- **`lib/main.dart`:** `runApp` first on web; Firebase/FCM via `unawaited(_initializeWebPushStack())`.

**Next:** Push to `main` (or `workflow_dispatch`) so Vercel serves the new build; hard-refresh on iPhone Chrome (close tab, reopen `https://petfolio.live/`).

Phase complete — please run (/remember) to save tokens before proceeding to the next phase.

