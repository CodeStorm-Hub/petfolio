# Petfolio — UI/UX, Accessibility, Gesture & Navigation Remediation Plan

## Context

A full review of Petfolio (68 screens / 15 features) found a **strong Material 3 foundation** (custom `PetfolioThemeExtension`, dual light/dark themes, `useMaterial3: true`, full component theming) undermined by **execution gaps** in three areas:

1. **Accessibility** — sparse coverage: ~32 of 37 `IconButton`s have no tooltip/label, 173 `GestureDetector`s vs only 24 `InkWell`s (no ripple feedback / no semantic role), `0` uses of `SemanticsService.announce`, only `1` `PopScope` (Android system back unhandled), and most `TextField`s missing `keyboardType` / `textInputAction` / `autofillHints`.
2. **Dark-mode correctness** — 505+ hardcoded `Color(0x…)` literals bypass the theme; the worst break dark mode outright (achievement badges, gold "premium" gradients, `0xFFF2F3F7`/`0xFF2A1820` surfaces) across social profile, care gamification, marketplace, activity, account, settings.
3. **Navigation** — plain `ShellRoute` loses scroll/tab state on every switch, `VetHubScreen` runs a local `IndexedStack` outside the shell, `pushReplacement` on shell routes destroys back history, duplicate notification routes, and dead-route redirects mask stale links.

Goal: a **phased remediation** that fixes correctness/a11y blockers first, then dark mode, then the navigation architecture (including `StatefulShellRoute`), then polish — each phase independently shippable and verifiable. Per project rules: no comments/dartdoc, Riverpod generator only, no hardcoded colors, run `flutter analyze` + `flutter test` after each phase, and update `progress.md` per phase.

---

## Phase 0 — Accessibility & Gesture Blockers (P0)

Highest user impact, lowest risk. No architectural change.

**Icon-only controls & semantics**
- Add `tooltip:` to every bare `IconButton` (32 missing). Primary offenders: `lib/core/widgets/app_shell.dart` (header/back/cart actions), `lib/core/widgets/app_header.dart`, social/marketplace/care app-bar actions.
- Add `semanticLabel` to decorative-but-meaningful images/avatars (`PetAvatar`, `PetfolioNetworkImage`); wrap purely decorative custom painters (`TailWagLoader`, `WaveHeader`, `DashedCircle`) in `ExcludeSemantics`.
- Reusable fix: extend `lib/core/widgets/pet_avatar.dart` and `petfolio_network_image.dart` to accept/forward a `semanticLabel`.

**Gesture feedback & touch targets**
- Convert tappable `GestureDetector`s that represent buttons/list rows to `InkWell`/`InkResponse` (or wrap in `Material`) so they get ripple + semantic button role + focus. Prioritize high-traffic surfaces: feed post actions (`social_screen.dart`), product/cart tiles (`marketplace_screen.dart`, `product_card.dart`), care task tiles, home bento tiles (`hub_home_screen.dart`). Leave genuinely custom gestures (swipe/drag/story tap zones) as `GestureDetector`.
- Enforce 48×48dp minimum (M3 `foundations_designing_structure` "Touch and pointer target sizes") on small icon taps — wrap with `IconButton`'s built-in `constraints`/padding or `SizedBox(48,48)`. Audit `IconButton(iconSize: <small>)` and custom 24–40dp tappables.

**Forms / input** (`auth/login`, `registration`, onboarding, marketplace checkout, create-content, edit-profile)
- Add `keyboardType`, `textInputAction`, and `autofillHints` to the 43 fields (only 22/9/5 currently set). Email → `TextInputType.emailAddress` + `AutofillHints.email`; password → `obscureText` + `AutofillHints.password` + visibility toggle; phone/number/address fields likewise.
- Ensure focus traversal (`onFieldSubmitted` → next focus) and inline validation error display.

**Async action feedback**
- Add double-tap/in-flight protection on submit buttons (disable while `AsyncValue.isLoading`); keep existing `HapticFeedback` (44 uses) consistent on primary actions. Use existing `AppSnackBar` for success/error.

**Files (representative):** `lib/core/widgets/{app_shell,app_header,pet_avatar,petfolio_network_image,primary_pill_button}.dart`, `lib/features/auth/presentation/screens/*.dart`, `lib/features/social/presentation/screens/social_screen.dart`, `lib/features/marketplace/presentation/{screens,widgets}/*.dart`, `lib/features/care/presentation/{screens,widgets}/*.dart`, `lib/features/home/presentation/screens/hub_home_screen.dart`.

---

## Phase 1 — Theme / Dark-Mode Color Correctness (P1)

Eliminate hardcoded colors that break dark mode. Centralize first, then replace.

**Add token families** in `lib/core/theme/app_colors.dart` + expose via `PetfolioThemeExtension` (`app_theme.dart`):
- `badge*` / `badge*D` for the 6 achievement colors hardcoded in `social_profile_screen.dart:609-614` (and the stat-card colors at `:489-510`).
- `premiumGold` / `premiumGoldSoft` (+ dark) for the gold gradients duplicated in `hub_home_screen.dart:519`, `cart_screen.dart`, `account_screen.dart`, `settings_screen.dart`.
- Confirm shadow tokens `shadowE1..E4` (+D) exist and replace raw `Color(0x..000000)` shadows.

**Replace hardcoded surfaces** with `pt.surface1` / `pt.surface1D` etc.:
- `Color(0xFFF2F3F7)` → `pt.surface1` in `activity_screen.dart`, `cart_screen.dart`, `account_screen.dart`, `settings_screen.dart`, `offers_screen.dart`.
- `Color(0xFF2A1820)` / `0xFF1A1014` → `pt.surface*D`.
- `gamified_care_ui.dart` red/orange streak gradients → `pillarHealth`/`tangerine`/`poppy` tokens with dark variants.

**Method:** grep `Color(0x` per feature; replace literal → nearest semantic token; verify with light/dark golden coverage. Reuse existing golden test harness (`app_theme_golden_test.dart`).

**Files:** `lib/core/theme/{app_colors,app_theme}.dart`; `lib/features/social/presentation/screens/social_profile_screen.dart`; `lib/features/care/presentation/widgets/gamified_care_ui.dart`; `lib/features/marketplace/presentation/screens/{cart_screen,marketplace_screen,product_detail_screen}.dart` + `widgets/product_card.dart`; `activity/`, `home/`, `profile/`, `settings/`, `offers/` screens listed above.

---

## Phase 2 — Navigation Architecture (P2)

Largest blast radius — do after P0/P1 are green. Migrate to `StatefulShellRoute` for per-tab state preservation.

**Convert `appShellRoute()` (`lib/core/navigation/app_shell_routes.dart`) to `StatefulShellRoute.indexedStack`:**
- Each shell module (global / care / social / matching / marketplace — defined in `shell_destinations.dart`) becomes a `StatefulShellBranch` with its own `navigatorKey`, preserving scroll/form/focus state across tab switches.
- Update `AppShell` (`lib/core/widgets/app_shell.dart`) to drive navigation via `navigationShell.goBranch(index)` instead of `context.go(path)`, and render `navigationShell` as the body. Keep the floating-nav (mobile) / `NavigationRail` (wide) split.
- Replace the generic "back → `/home`" in the shell header (`app_shell.dart:389-419`) with history-aware pop (`context.canPop()` ? `context.pop()` : branch root).

**Fix navigation bugs:**
- Replace `context.pushReplacement('/marketplace/order/...')` with `context.go(...)` in `marketplace_screen.dart` / `cart_screen.dart` (pushReplacement on shell routes destroys history).
- Refactor `VetHubScreen` (`vet_hub_screen.dart:20-93`) off its local `IndexedStack`+`setState` — either fold its tabs into the care branch as real routes or keep internal tabs but stop shadowing shell routing; remove the "Coming Soon" dead tabs from deep-link reach.
- Remove the duplicate `/social/notifications` route (`social_routes.dart`) now that `router_notifier.dart:47` redirects it — and delete the other dead-route redirects (`/pets`, `/shop`, `/care/medical-vault`, `/settings`) at `router_notifier.dart:43-47`, fixing the few call-sites that still emit them instead.

**Android back / deep links:**
- Add `PopScope` at the shell/branch level (currently only 1 in the whole app) so the system back button pops within-branch before exiting; add confirm-on-exit at branch roots.
- Add a `messaging_routes.dart` (or consolidate messaging into matching) so `lib/features/messaging/chat_screen.dart` is reachable, not orphaned.
- Standardize object passing on `state.extra` (already used for `Product`/`Community`/`MarketplaceOrder`); keep query params only for primitive flags.

**Files:** `lib/core/navigation/{app_shell_routes,router_notifier,shell_destinations}.dart`, `lib/core/router.dart`, `lib/core/widgets/app_shell.dart`, `lib/features/appointments/presentation/screens/vet_hub_screen.dart`, `lib/features/marketplace/presentation/screens/{marketplace_screen,cart_screen}.dart`, `lib/features/social/social_routes.dart`, new `lib/features/messaging/messaging_routes.dart`.

---

## Phase 3 — Consistency & Polish (P3)

- **Spacing:** consolidate the duplicated `AppThemeSpacing` (4/8/12/16/24/32/48…) vs static `space*` tokens in `app_theme.dart` into one source; sweep magic numbers (5/7/10/12) in `gamified_care_ui.dart`, `social_profile_screen.dart`, `care_screen.dart` to tokens.
- **Loading states:** adopt the existing `SkeletonLoader` variants for paginated reveals (social feed, marketplace grid) instead of full-screen spinner→content jumps.
- **Responsive:** apply existing `ResponsiveLayout`/breakpoints to mobile-only screens (`social_screen.dart`, `activity_screen.dart`); add ≥600dp tablet branches (grid columns / nav rail already themed).
- **Text scaling:** verify no fixed `fontSize` clips at large text scale; clamp extreme `textScaler` at `MaterialApp` builder if layouts break.
- **Component gaps:** add a branded dialog wrapper (mirror `AppSnackBar`) and a `FormField` wrapper to stop raw `TextFormField` repetition.

---

## Verification (run after each phase)

1. **Static + tests:** `flutter analyze` (zero new issues) and `flutter test` (incl. `app_theme_golden_test.dart`) after every phase.
2. **Codegen:** if any `@riverpod`/`@freezed`/route changes, `dart run build_runner build --delete-conflicting-outputs`.
3. **Accessibility (Phase 0):** run the device with TalkBack; confirm every actionable control announces a label and role; verify 48dp targets via Flutter Inspector. Use the `accessibility-review` skill checklist for the WCAG AA pass.
4. **Dark mode (Phase 1):** toggle light/dark on social profile, care, marketplace, activity, account — confirm no white-on-white / black-on-black; golden tests cover both brightnesses.
5. **Navigation (Phase 2):** drive the running app (Marionette/`flutter_driver`) — switch tabs and confirm scroll position persists; Android hardware back pops within-branch; deep-link each route incl. `/marketplace/order/...`, messaging, and (removed) dead routes 404 cleanly; cart→order flow keeps a working back stack.
6. **Per phase:** update `progress.md`, then prompt the user to `/remember` before the next phase.

## Sequencing & risk

P0 → P1 → P2 → P3. P0/P1 are low-risk, mostly mechanical, and independently shippable. **P2 is the only high-blast-radius phase** (touches every tab + `AppShell`); land it behind P0/P1 green builds and verify tab-state + back behavior on a real device before merging. P3 is opportunistic cleanup.
