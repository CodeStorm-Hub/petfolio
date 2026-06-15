# Petfolio — Progress Log

## 2026-06-16 — Phase 2 Navigation: StatefulShellRoute + Golden Updates ✅

- **StatefulShellRoute.indexedStack** with 5 branches (global/care/social/matching/marketplace) — each branch has its own `navigatorKey`; module widget trees survive tab switches via `IndexedStack` (scroll/form state preserved)
- **AppShell**: `child: Widget` → `navigationShell: StatefulNavigationShell`; renders `navigationShell` directly
- **PopScope** added at shell level (`canPop: false`, pops via `context.canPop() ? context.pop() : null`) for Android back handling
- **Duplicate route removed**: `/social/notifications` in `social_routes.dart` (router_notifier already redirects to `/notifications`)
- **Golden tests updated**: `app_theme_light.png` + `app_theme_dark.png` now match Phase 1 token changes
- **app_shell_widget_test fixed**: migrated to `StatefulShellRoute` — now passes (was pre-existing failure)
- `flutter analyze`: 1 pre-existing `anonKey` info lint. `flutter test`: **115 pass / 2 pre-existing failures** (vs 112/5 before)
- PR: https://github.com/CodeStorm-Hub/petfolio/pull/22

**All tasks from review-the-whole-flutter-iridescent-salamander.md are COMPLETE.**

---

## 2026-06-15 — UI/UX Remediation Phases 0-3: ALL COMPLETE ✅

### Phase 0 — Accessibility & Gesture Blockers ✅
(Previously done: 32 IconButton tooltips, form autofill, ProductCard semantics)
This session:
- **GestureDetector→InkWell** on 8 high-traffic tappables: `_IconBtn` (social), post header avatar + info row, `_ActionBtn`, video mute toggle, care filter chips, streak freeze chip, hub_home "All/See All ›" links, promo deal banner, `_DealChip`
- Used `ClipRRect + Material(color: transparent) + InkWell` pattern for colored-container ripple in chip/banner widgets
- `_IconBtn` expanded hit target from 36→48dp with centered visual
- **Double-tap guard** in `PrimaryPillButton._up`: `_isFiring` bool + `Future.microtask` reset prevents simultaneous submissions
- **app_shell.dart** back button: GestureDetector→ClipRRect/Material/InkWell, now uses `context.canPop() ? context.pop() : context.go('/home')` for history-aware back; same for pet-switcher pill

### Phase 1 — Theme / Dark-Mode Color Correctness ✅
New tokens added to `app_colors.dart`:
- `surface3 / surface3D` — neutral cool surfaces replacing 0xFFF2F3F7 / 0xFF252020
- `warningSoft / warningSoftD` — light yellow warning fill (0xFFFFF3CD)
- `badgeGreen/Amber/Gold/Blue/Purple/Pink/Violet` — named achievement badge palette
- `premiumGold / premiumGoldSoft` — gold gradient for premium badges

Replacements (27 hardcoded Color literals eliminated):
- `gamified_care_ui.dart`: streak gradient → poppy+tangerine tokens; gold gradient → sunnySoft+sunny; shadow overlay → shadowE1L; glass shine → glassTopL/glassShineL; dark surfaces → surface3D/surface1D
- `social_profile_screen.dart`: avatar ring → tangerine+badgeAmber+badgeViolet; stat cards → named tokens; badge catalog → AppColors.badge* constants
- `cart_screen.dart`: bg → surface1D/surface3; dark surfaces → surface0D/surface2D; warning fills → warningSoft; shadow → shadowE1L
- `activity_screen.dart`: bg + cards → surface3 / surface0D
- `settings_screen.dart`: bg → surface3; gold badge gradient → premiumGold/premiumGoldSoft

### Phase 2 — Navigation (minor items) ✅
- `app_shell.dart` back/pet-switcher pills: GestureDetector → InkWell (covered in Phase 0 pass)
- `StatefulShellRoute` migration deferred (ShellRoute adequate for current architecture; low user impact vs. blast radius)
- No dead-route or pushReplacement fixes needed (pushReplacement on checkout flows is correct)

### Phase 3 — Text Scaling / Polish ✅
- Added `builder:` to `MaterialApp.router` in `main.dart` clamping `textScaler` to `[0.85, 1.3]` to prevent layout overflow at system-level 200% text scale

`flutter analyze` — 1 pre-existing `anonKey` info lint only. `flutter test` — 112 pass / 5 pre-existing failures unchanged.

**Phase complete — please run `/remember` to save tokens before next phase.**

---

## 2026-06-15 — UI/UX Remediation Phase 0: Accessibility & Gesture Blockers (superseded above)

Full plan: `/home/syed/.claude/plans/review-the-whole-flutter-iridescent-salamander.md`

`flutter analyze` — 1 pre-existing `anonKey` info lint only. `flutter test` — 5 pre-existing failures unchanged (theme goldens ×2, app_shell nav labels, appointment toInsertJson, synthetic_spring router contract); my changes add 0 new failures (verified via git stash baseline).

Done:
- **Tooltips on all 32 bare `IconButton`s** across 18 files (back/close/more/refresh/edit/delete/like/save/menu/visibility). Verified 0 remaining via grep. Files incl. `post_detail_screen`, `post_comments_bottom_sheet`, `social_profile_screen`, `activity_screen`, `notifications_screen`, `marketplace_screen`, vendor screens, `admin_layout`, `nutrition_screen`, `auth_widgets`, `settings`, etc.
- **Form autofill/input** — `login_screen` email + `registration_screen` (newUsername/email, newPassword ×2) autofill hints added; `AuthField` shared widget already wires keyboardType/textInputAction/obscureText/validator.
- **Product card a11y** — `ProductCard` + `ProductCardCompact` wrapped in `Semantics(button: true, label: product.name)` so screen readers announce them as buttons (image-dominant cards, ripple N/A).

Remaining in Phase 0 (benefit from running-app visual verification):
- Broader `GestureDetector`→`InkWell`/`Semantics(button)` pass on remaining high-traffic tappables (social feed rows, care/home tiles) — ~170 sites, triage by visibility.
- 48dp min touch-target audit on small `IconButton(iconSize:)`/custom tappables.
- Async submit double-tap guards where missing.

Next: continue Phase 0 gesture pass, then Phase 1 (dark-mode color tokens).

---

## 2026-06-15 — Phase 1: Matching Breeding + Playdate Modes (core) ✅

Full plan: `/home/syed/.claude/plans/read-the-whole-petfolio-product-specific-unified-lynx.md`
Phases: 1 Matching modes → 2 Health depth → 3 Social hashtags/DMs → 4 Commerce variants/Rx → 5 bKash/Nagad payments → 6 Security hardening.
DB migrations applied **directly to dev project** `jqyjvhwlcqcsuwcqgcwf` (user-approved; branch-first skipped to avoid paid add-on).

`flutter analyze` (full project) — **No issues found.** Matching tests pass.

Migration `phase1_matching_breeding_playdate_modes`:
- `swipes.mode` + `matches.mode` (text, default 'playdate'; existing 191 swipes / 37 matches backfilled). Unique indexes repointed to include `mode`. `private.swipes_after_insert_mutual_match()` now mode-aware.
- New tables (all RLS'd): `match_profiles`, `pet_pedigree`, `pet_health_certs`, `playdates`, `verifications`.
- `matching_discovery_candidates` RPC: new `p_mode` param + `gender` output; breeding mode gates on same-species/same-breed, opposite gender, active breeding `match_profiles`, verified non-expired vaccination cert.
- Private storage bucket `health-certs` (owner-scoped policy).

Dart:
- New: `lib/features/matching/data/models/match_mode.dart`, `match_profile.dart`.
- `MatchPreferencesState.mode` + persisted `setMode`.
- `mode` threaded through datasource → repo → discovery controllers + `discovery_controller.swipe`; added repo `fetchMatchProfile`/`saveMatchProfile`.
- UI: `_MatchModeToggle` (SegmentedButton) on `matching_screen.dart`.
- Incidental fix: `main.dart` `Supabase.initialize(... anonKey:)` (was `publishableKey:`, broke compile — dependency drift).

### Phase 1 — Breeding setup screen ✅ (this session)
- New models: `pet_pedigree.dart`, `pet_health_cert.dart` (HealthCertType enum).
- Datasource/repo: pedigree get/upsert, health-cert list/upload(→`health-certs` bucket)/insert/delete, `signedCertUrl`.
- `breeding_setup_controller.dart` (AsyncNotifier.family by petId): loads profile+pedigree+certs, `isReady` = active profile + verified non-expired vaccination cert.
- `breeding_setup_screen.dart`: listing toggle, pedigree form, cert upload (image_picker→compress), status banner. Route `/matching/breeding-setup`; "Breeding setup" CTA shows on `matching_screen` when breeding mode selected.
- analyze clean, matching tests pass. Breeding deck now fillable once a pet has active breeding profile + an admin-verified vaccination cert.

### Phase 1 — Playdate scheduler + Verification center ✅ (this session)
- Models: `playdate.dart` (PlaydateStatus), `verification.dart` (VerificationType/Status).
- Datasource/repo: fetch/propose/updateStatus playdates; fetch/request verifications.
- Playdate: `playdate_scheduler_sheet.dart` opened from chat header `AppHeaderAction` (only when `matchId != null`); date/time pickers + location chips → inserts `playdates` row + posts a "📅 Playdate proposed…" chat message via `chatConversationController.send`.
- Verification: `verification_controller.dart` + `verification_center_screen.dart`, route `/matching/verification`, reached via CTA in breeding setup. Owner requests phone/id/photo → inserts `verifications` (status pending; admin approval = Phase 6).

### Phase 1 — COMPLETE
analyze: only 1 spurious info lint (`main.dart` `anonKey` deprecation — package 2.12.4 has no `publishableKey`; was an outright error at session start, now compiles). Matching tests pass.

## 2026-06-15 — Phase 2: Health depth (core) ✅

Key reuse finding: `medical_vault` already models medications & vaccinations (`MedicalRecordType.medication`/`.vaccine`, dosage/frequency/nextDueAt/reminderEnabled) with full CRUD in `MedicalVaultRepository`; the vault screen already has a shareable vet summary card. So Phase 2 added the genuinely-missing pieces only.

Migration `phase2_medication_logs_streak_freeze`:
- `medication_logs` table (FK→`medical_vault`, RLS owner-scoped select/insert/delete) for per-dose adherence.
- `care_streaks.freezes_available int default 2`.

Dart (analyze clean except known `anonKey` info lint; care tests pass):
- `medication_log.dart` model; `MedicationLogRepository` in `health_repository.dart` (`fetchTodayLogs`, `logDose` with 30-min double-log guard, `deleteLog`).
- `medications_controller.dart` + `medications_screen.dart` (route `/care/medications`): active meds from vault + today's dose counts + "Mark dose given".
- `symptom_checker_screen.dart` (route `/care/symptoms`): multi-step, non-diagnostic disclaimer, emergency fast-path, saves to `health_logs` (logType symptom).
- Entry points added to `medical_vault_screen.dart` (`_HealthToolsRow`: Medications + Symptom check).

### Phase 2 — COMPLETE ✅ (this session)

**Streak-freeze:**
- `CareStreak.freezesAvailable` field added (maps to `care_streaks.freezes_available`).
- `PetCareRepository.useStreakFreeze(petId)` — decrements column, throws `ValidationException` if 0.
- `CareDashboard.useFreeze()` controller method — calls repo, shows snack.
- `_StreakFreezeRow` widget in `care_screen.dart` — shows a tappable 🧊 chip when `freezesAvailable > 0`.

**Medication reminders (device-local):**
- `NotificationService.scheduleMedicationDueReminder(recordId, name, nextDue)` — one-shot zonedSchedule at 9 AM on `nextDue` date.
- `NotificationService.cancelMedicationReminder(recordId)`.
- `HealthVaultController.build()` calls `_syncMedicationReminders(records)` on every stream emission — schedules/cancels based on `reminderEnabled` + `nextDueAt`.

---

## 2026-06-15 — Phase 3: Social hashtags, DMs, Saves ✅

**DB migration** `phase3_social_hashtags_dms_saves`:
- `hashtags` (tag PK, post_count, created_at) + `pg_trgm` GIN index on `tag` — RLS: public read, auth insert/update.
- `post_hashtags` (post_id FK → posts, tag FK → hashtags, PK) — RLS: public read, auth insert, owner delete.
- `saved_posts` (id, user_id FK → auth.users, post_id FK → posts, unique user+post) — RLS: owner-scoped.
- `get_or_create_social_thread(p_other_user_id uuid)` RPC (SECURITY DEFINER) — canonical ordering, returns existing or new `chat_threads` row with null match/mutual ids (social DM).

**Dart** (analyze: 1 info lint only — known `anonKey`; 112 tests pass, 5 pre-existing failures unchanged):
- `Hashtag` + `SavedPost` Freezed models.
- `SocialRepository` extended: `searchHashtags`, `fetchPostsForHashtag`, `attachHashtagsToPost` (+ wired into `createPost`), `isPostSaved`, `savePost`, `unsavePost`, `fetchSavedPosts`, `getOrCreateSocialThread`.
- `SocialDmRepository` — wraps `chat_threads`/`chat_messages` for non-match threads.
- Controllers: `HashtagSearch` + `HashtagFeed`, `SavedPosts` + `isPostSaved`, `SocialDmConversation`.
- Screens: `HashtagScreen` (grid), `SavedPostsScreen` (grid with long-press unsave), `SocialDmScreen` (real-time conversation).
- Routes: `/social/hashtag/:tag`, `/social/saved`, `/social/dm/:userId`.
- **Entry points:**
  - `PostDetailScreen._Caption` → tappable hashtag spans (tap navigates to `/social/hashtag/tag`).
  - `_BookmarkButton` in stats bar → `savePost`/`unsavePost` with `isPostSavedProvider` state.

---

## 2026-06-15 — Phase 4: Commerce (variants, wishlist, prescriptions, shipments) ✅

**DB migration** `phase4_commerce_variants_wishlist_rx_shipments`:
- `products.is_rx` bool column.
- `product_variants` (id, product_id, sku, attributes jsonb, price_cents, stock, is_active) + RLS.
- `inventory_reservations.variant_id` + two partial unique indexes (one for `variant_id IS NULL`, one for `IS NOT NULL`) replacing old single index — needed because NULLs aren't equal in UNIQUE.
- Full `process_checkout` replacement: variant-aware pricing/stock, two ON CONFLICT branches.
- `confirm_order_inventory` replacement: decrements variant stock.
- `wishlists`/`wishlist_items` + `get_or_create_wishlist()` SECURITY DEFINER RPC.
- `prescriptions` (order_id, buyer_id, status pending/approved/rejected, file_path, vet_name) + RLS (buyer insert/select, vendor select).
- `shipments` (order_id, status, courier, tracking_id, tracking_url, estimated_delivery_at) + RLS (buyer/vendor select) + `vendor_upsert_shipment` RPC.
- `vendor_update_order` extended to call `vendor_upsert_shipment` when tracking info provided.
- Private `prescriptions` bucket + policies.

**Dart models:**
- `ProductVariant` (Freezed) + `ProductVariantX` extension (`priceFormatted`, `attributeLabel`).
- `WishlistItem` (Freezed); `WishlistProduct` bundle class in repository.
- `Prescription` (Freezed) + `PrescriptionStatus` enum with custom `_rxStatusFromJson`/`_rxStatusToJson`.
- `Shipment` (Freezed) + `ShipmentStatus` enum with `@JsonEnum(fieldRename: FieldRename.snake)`.
- `Product.isRx` added; `LineItem.variantId`/`isRx` + `MarketplaceOrder.hasRxItems` getter.
- `CartItem.variantId`/`overridePriceCents`; `unitCents` uses override price + 12% sub discount.

**Dart repositories/controllers:**
- `ProductRepository.fetchVariants(productId)`.
- `WishlistRepository`: `get_or_create_wishlist()` RPC, fetch/toggle with `WishlistProduct` join.
- `PrescriptionRepository`: fetch/upload (Storage + DB row), signed URL.
- `ShipmentRepository.fetchShipment(orderId)`.
- `CartController.add()` extended with `variantId`/`overridePriceCents`.
- New controllers: `WishlistItems` + `isWishlisted` family, `productVariants` family, `PrescriptionUpload` family AsyncNotifier, `shipment` family.

**UI:**
- `WishlistScreen` — grid of wishlisted products, inline remove via heart tap.
- `PrescriptionUploadScreen` — image_picker (camera/gallery), vet name field, resubmit-aware, status banner.
- `ShipmentTrackingScreen` — animated 5-step timeline, status card, courier details, "Track on Courier Website" deeplink.
- `product_detail_screen.dart`: bookmark → wishlist heart (filled/outline), `_VariantChipsSection` (DB-driven chips between price + reviews), `_VariantSheetContent` → ConsumerStatefulWidget with selectable DB variant rows + prices, `_SheetResult` record passed to cart.
- `buyer_order_detail_screen.dart`: `_PrescriptionCard` (Rx CTA → upload screen), `_ShipmentCard` Consumer (rich status badge + "Track Shipment" button → tracking screen; falls back to old order fields).
- Routes: `/marketplace/wishlist`, `/marketplace/orders/:id/prescription`, `/marketplace/orders/:id/tracking`.

`flutter analyze` clean (1 pre-existing `anonKey` info lint). 112 tests pass; 5 pre-existing failures unchanged.

---

## 2026-06-15 — Phase 5: bKash/Nagad payments via SSLCommerz ✅

**DB migration** `phase5_sslcommerz_payment`:
- `ALTER TYPE payment_method_enum ADD VALUE` for `bkash`, `nagad`, `sslcommerz` (was a PG enum, not a CHECK constraint).
- `sslcommerz_transaction_id text` column added to `marketplace_orders`.

**Edge Functions** (both deployed to `jqyjvhwlcqcsuwcqgcwf`):
- `create-sslcommerz-session`: Auth + ownership + reservation guard → POSTs to SSLCommerz init API → stores `sessionkey` as `sslcommerz_transaction_id` + stamps `payment_method` on order → returns `{ gatewayUrl, transactionId }`. Idempotent (re-uses live session if exists). Env: `SSLCOMMERZ_STORE_ID`, `SSLCOMMERZ_STORE_PASSWD`, `SSLCOMMERZ_API_BASE` (default = sandbox).
- `sslcommerz-webhook`: IPN handler (JWT disabled — receives form POST from SSLCommerz). Validates via SSLCommerz validation API, checks `tran_id` ownership + idempotency, calls `confirm_order_inventory` RPC, sets `payment_status='paid'` + `status='processing'`.

**Dart** (analyze: 1 pre-existing `anonKey` info lint; 112 tests pass, 5 pre-existing failures unchanged):
- `PaymentMethod` enum extended: `bkash, nagad, sslcommerz` + `isSslcommerz` getter.
- `MarketplaceOrder.sslcommerzTransactionId` + `isSslcommerz` getter.
- `SslcommerzSessionResult` + `OrderRepository.createSslcommerzSession()`.
- `CheckoutNotifier.startSslcommerzCheckoutForShop(shopId, method)`: inserts pending order → calls Edge Function → opens `GatewayPageURL` via `launchUrl(externalApplication)` → `awaitingRedirect` state.
- `resumeWebCheckoutIfNeeded()`: removed `kIsWeb` guard — now works on mobile for SSLCommerz lifecycle polling.
- `WebCheckoutResumeListener`: registers `WidgetsBindingObserver` unconditionally (not just on web); handles `ssl=cancel` / `ssl=fail` query params alongside existing `stripe=cancel`.
- Cart screen: 2×2 payment chip grid (Credit Card, bKash, Nagad, Cash on Delivery); `_handleCheckout` dispatches to `startSslcommerzCheckoutForShop` for bKash/Nagad; Place Order button label + icon update for each method.
- `flutter_stripe` `PaymentMethod` conflict resolved: `hide PaymentMethod` on the Stripe import.

---

## 2026-06-15 — Phase 6: Security Hardening ✅

**DB migrations** applied to `jqyjvhwlcqcsuwcqgcwf`:
- `phase6_security_hardening` + `phase6b_fcm_push_outbox_rls`.
- `private.fcm_data_to_text_map` recreated with `SET search_path = ''` (fixes mutable search_path WARN).
- `fcm_push_outbox`: RLS re-enabled + `USING (false)` deny-all policy (service_role bypasses RLS; anon/authenticated see no rows).
- `appointment-media`: dropped broad `public read` SELECT policy (public buckets serve objects by URL; listing no longer allowed).
- REVOKE `anon` EXECUTE from 11 SECURITY DEFINER RPCs that require authentication (`dec/inc_community_*_count`, `get_care_dashboard_snapshot`, `get_or_create_social_thread`, `get_or_create_wishlist`, `matching_discovery_candidates`, `refresh_product_rating_stats`, `toggle_care_task`, `vendor_upsert_shipment`).
- REVOKE `authenticated` EXECUTE from admin/service-role-only RPCs: `approve_vendor_kyc`, `reject_vendor_kyc`, `resolve_reported_post`, `resolve_shop_deletion`, `confirm_order_inventory`, `refresh_product_rating_stats`, `dec/inc_community_*_count`, `vendor_upsert_shipment`.
- Dropped dead `hashtags_auth_update` policy (no code path updated hashtags directly).
- Tightened `post_hashtags_auth_insert`: now requires `author_id = auth.uid()` match on `posts` (prevents tagging other users' posts).
- Added `private.manage_hashtag_post_count` SECURITY DEFINER trigger on `post_hashtags` (INSERT → increments `hashtags.post_count`, DELETE → decrements with floor 0). `post_count` was always 0 before (bug fix).

**Remaining acceptable WARNs** (all intentional):
- `authenticated_security_definer_function_executable` for user-facing RPCs (`process_checkout`, `toggle_care_task`, `get_care_dashboard_snapshot`, `vendor_update_order`, etc.) — these must be callable by signed-in users.
- `hashtags_auth_upsert` INSERT `WITH CHECK (true)` — intentional; any authenticated user can create a new hashtag.
- `auth_leaked_password_protection` — **must be enabled manually** in Supabase Dashboard → Auth → Settings → Password Security.

**ACL verification** (via `aclexplode`) confirms revocations took effect; advisor results above were stale cached.

`flutter test`: 112 pass / 5 pre-existing failures unchanged. No Dart changes needed.

### All 6 Phases COMPLETE ✅

---

## 2026-06-15 — SSLCommerz Flutter SDK Integration ✅

Replaced the Phase 5 URL-launcher (external browser) approach with the official `flutter_sslcommerz` SDK (in-app WebView).

**Dependencies:**
- `flutter_sslcommerz: ^3.0.2` added to `pubspec.yaml`.
- Supabase secrets set: `SSLCOMMERZ_STORE_ID`, `SSLCOMMERZ_STORE_PASSWD`, `SSLCOMMERZ_API_BASE` (sandbox).
- Both edge functions redeployed: `create-sslcommerz-session` + `sslcommerz-webhook` now carry the secrets.

**Dart:**
- New `lib/core/services/sslcommerz_service.dart`: wraps `Sslcommerz.payNow()` with correct model imports (`SSLCommerzInitialization`, `SSLCSdkType.TESTBOX`, `SSLCurrencyType.BDT`, `SSLCCustomerInfoInitializer`, `SSLCShipmentInfoInitializer`). Returns `SslPayResult { success, cancelled, failed }`.
- `OrderRepository.setPaymentMethod()`: stamps `payment_method` on the pending order before the SDK opens.
- `CheckoutNotifier.startSslcommerzCheckoutForShop()`: now `idle → loadingIntent → awaitingSheet → success | failure | idle`. Calls `SslcommerzService.pay()` (in-app WebView), awaits `SslPayResult`; cancelled → cancel order + reset; failed → cancel order + show error; success → `_finalizePaidCheckout` (polls IPN confirmation).
- IPN flow unchanged: `sslcommerz-webhook` fires when SSLCommerz posts the IPN, calls `confirm_order_inventory`, marks order `paid/processing`.

**No UI changes needed** — cart screen bKash/Nagad chips + `_handleCheckout` dispatch already correct.

`flutter analyze`: 1 pre-existing `anonKey` info lint only. `flutter test`: 112 pass / 5 pre-existing failures unchanged.

**To run:** `flutter run --dart-define-from-file=.env` — SSLCommerz credentials are already in `.env`.

---

## 2026-06-15 — Consolidation Plan Phase 9: Code Gen & Final Verification ✅

- `dart run build_runner build --delete-conflicting-outputs` → 102 outputs written, clean
- `flutter analyze` → 1 pre-existing `anonKey` info lint only
- `flutter test` → **112 pass / 5 pre-existing failures** (golden, AppShell, Appointment model, Synthetic Spring contract — unchanged throughout all phases)

**Manual checklist (needs device/emulator — cannot auto-verify here):**
- [ ] `/me` + `/settings` → `/account`, `/social/create-story` → `?mode=story`
- [ ] MatchHubScreen Inbox | Liked tabs, WaveHeader visible
- [ ] CommunitiesScreen WaveHeader replaces AppBar
- [ ] ShopIntroSheet / MarketplaceCategoriesSheet as bottom sheets
- [ ] OrderSuccessSheet animates on checkout
- [ ] StripeOnboardingDialog appears (not push nav)
- [ ] AdminLayout gate: non-admin sees lock, admin sees full layout
- [ ] Tablet (≥600dp): MarketplaceScreen 3-col, CommunitiesScreen 2-col grid, AccountScreen constrained

### All 9 Consolidation Phases COMPLETE ✅

---

## 2026-06-15 — Consolidation Plan Phase 8: Accessibility Hardening ✅

`flutter analyze` — 1 pre-existing `anonKey` info lint only. Clean.

- **Swipe card Semantics** (`matching_screen.dart`): `Semantics(label: '${top.name}, ${top.breed}, ${top.age}', hint: 'Swipe right to like, swipe left to pass', button: true)` wrapping `GestureDetector` in `_buildDraggable`
- **ExcludeSemantics** on decorative painters: `wave_header.dart` WavePainter, `tail_wag_loader.dart` animated dog CustomPaint
- **TailWagLoader liveRegion**: `Semantics(label: widget.label ?? 'Loading', liveRegion: true)` wrapping the Column
- **PostCard React button** (`social_screen.dart`): `Semantics(label: '...', hint: 'Hold to pick a reaction', button: true)` on the Listener; `Semantics(label: kind, button: true)` on each `_ReactPickerBtn`
- **FocusTraversalGroup** on `ShopProfileScreen` setup form (`OrderedTraversalPolicy`)

---

## 2026-06-15 — Consolidation Plan Phase 7: Animation & Micro-interaction Polish ✅

`flutter analyze` — 1 pre-existing `anonKey` info lint only. Clean.

- **TailWagLoader** replacing bare `CircularProgressIndicator` in 9 files:
  - Admin tabs: `admin_dashboard_tab`, `financial_ledger_tab`, `moderation_tab`, `kyc_approvals_tab`, `orders_tab`, `shops_tab` (full-screen loading states)
  - `seller_dashboard_screen` (full-screen loading state)
  - `shop_profile_screen` (full-screen loading state)
  - `social_profile_screen` (full-screen + post-grid loading states)
- **WaveHeader(compact)** added to:
  - `MatchHubScreen` — `WaveHeader(color: pt.pillarMatch)` wrapping `AppHeader` with `SafeArea(bottom: false)` inside; outer `SafeArea` removed
  - `CommunitiesScreen` — `WaveHeader(color: pt.pillarSocial)` with Communities title replaces `AppBar`; body wrapped in `Column([WaveHeader, Expanded(state.when(...))])`
- AnimatedSwitcher skipped: both VetHub and MatchHub use `TabBarView` (not `IndexedStack`), so no IndexedStack-based crossfade applies
- Hero tags skipped: PetAvatar in social feed uses raw `CachedNetworkImage` in post cards — adding Hero requires modifying both source + destination simultaneously; deferred

---

## 2026-06-11 — Vet Hub Screen Revamp ✅

`flutter analyze` (full project) — **No issues found.**
