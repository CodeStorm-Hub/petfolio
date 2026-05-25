# Petfolio — Progress Log

---

## 2026-05-25 — UI/UX Foundation: M3 Theme Toggle + Adaptive Shell (Phase 0)

- **`lib/core/theme/theme_mode_provider.dart`** (NEW) — `ThemeModeNotifier extends Notifier<ThemeMode>` with `toggle()` / `setMode()`; `themeModeProvider` (`NotifierProvider`). Starts on `ThemeMode.system`; toggle cycles between light ↔ dark.
- **`lib/core/theme/theme.dart`** — Exports `theme_mode_provider.dart`.
- **`lib/main.dart`** — `themeMode:` now watches `themeModeProvider` instead of the hardcoded `ThemeMode.system`.
- **`lib/core/theme/app_theme.dart`** — Added `NavigationDrawerThemeData` to `_build()`: surface/indicator colors aligned with existing blue-primary tokens; `WidgetStateProperty` icon/label colors match the NavigationBar/Rail pattern.
- **`lib/core/router.dart`** — `AppShell` promoted to `ConsumerWidget`; split into three layout builders keyed on screen width:
  - **Compact** (`< 600 dp`): `NavigationBar` (bottom) + `FloatingActionButton.small` (theme toggle, `miniEndFloat`, `heroTag: 'shell_theme_toggle'`).
  - **Medium** (`600–1199 dp`): `NavigationRail` + `IconButton.filledTonal` in `trailing` (theme toggle).
  - **Expanded** (`≥ 1200 dp`): Persistent `NavigationDrawer` in a `Row`, header row carries app icon + name + `IconButton.filledTonal` theme toggle; divider separates sidebar from content.
- **Nav icons fixed**: Care now uses `health_and_safety_outlined` / `health_and_safety`; duplicate heart icon between Care and Match resolved.
- `flutter analyze` — **No issues found.**

**Next step:** Phase complete. Please run (/remember) to save tokens before proceeding to the next phase (individual feature screen redesigns).

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
- [ ] Phase 5 — **P1-4 / P1-5** Error UX – health: add Retry button to `_ProfileHealthTab` error state; surface `addRecord` / `updateRecord` / `deactivateRecord` failures via `AppSnackBar.showError`
- [ ] Phase 6 — **P2-11 / P2-7** Error UX – social & care: add `AppSnackBar.showError` to `toggleLike`, `updateCaption`, delete in `SocialController`; same for `CareNotifier.toggle`
- [ ] Phase 7 — **P2-1 / P2-3** Awards tab + hero week bars: wire Awards tab to `pet_badges` / badge types; replace hardcoded 7-bar opacity in `_HeroCard` with real `weekGoalHit` data
- [ ] Phase 8 — **P2-4 / P2-5** Seller card gating + hero chip: gate `_SellerDashboardCard` on `myShopProvider` / KYC status; replace hardcoded `'on a walk'` chip with real activity/care state
- [ ] Phase 9 — **P1-3** Notifications constraint migration: change `DROP CONSTRAINT notifications_type_check` to `DROP CONSTRAINT IF EXISTS`
- [ ] Phase 10 — **P2-2 / P2-6 / P2-8–12 / P3-\*** Remaining medium/low issues + pre-release sweep: profile overview reminders, legacy `CareNotifier` task types, null `nextDueAt` sort, document upload in vault, admin moderation UI, accessibility, timezone policy, SharedPreferences schema versioning, placeholder header taps; run `flutter pub run build_runner build --delete-conflicting-outputs` + `npx supabase db reset` / push

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
