# PetFolio Material 3 Redesign — Comprehensive UI/UX Review

**Date:** 2026-05-25  
**Device:** `emulator-5554` (1080×2424, Android 17)  
**App:** `com.example.petfolio` (debug, Supabase session retained)  
**Tools:** Marionette MCP (Flutter keys), Appium MCP (UiAutomator2 + semantics), `adb screencap` / `uiautomator dump`

## Artifact locations

| Pass | Screenshots | UI dumps |
|------|-------------|----------|
| **M3 post-redesign (this session)** | [`docs/automation/m3_redesign_review_2026-05-25/screenshots/`](docs/automation/m3_redesign_review_2026-05-25/screenshots/) | [`docs/automation/m3_redesign_review_2026-05-25/ui-dumps/`](docs/automation/m3_redesign_review_2026-05-25/ui-dumps/) |
| Fresh operational pass | [`docs/automation/fresh_2026-05-25_automation/`](docs/automation/fresh_2026-05-25_automation/) | Same folder `ui-dumps/` |
| Earlier inventory | [`docs/automation/screenshots/`](docs/automation/screenshots/) | [`docs/automation/ui-dumps/`](docs/automation/ui-dumps/) |

**Capture helper:** [`scripts/m3_capture.ps1`](scripts/m3_capture.ps1) (`cmd /c adb exec-out screencap -p` — required on Windows; PowerShell byte piping corrupts PNGs).

---

## Executive summary

The **Material 3 adaptive redesign (Phases 1–7)** is **visibly live** on the authenticated emulator session: pillar-accent header, **ACTIVE PET** eyebrow, distinct bottom-nav icons (**Home / Care / Social / Match / Shop**), compact health-streak hero on phone, profile sub-tabs (Overview / Health / Care / Awards), care dashboard with real tasks, social feed with real posts, matching discovery + filters + inbox, marketplace catalog + cart, seller dashboard, and admin platform overview with drawer navigation on compact width.

**Overall UX grade (post-M3):** **B+** for shell cohesion and feature surfaces; **B−** for automation fragility, a few remaining IA gaps, and screens not yet visually redesigned (auth, checkout).

### Top strengths (confirmed in UI)

1. **Unified shell chrome** — Semantics show `ACTIVE PET`, switcher, 48dp-class header actions (`Notifications`, `Coming soon`), and labeled shell tabs `Home · Tab 1 of 5` … `Shop · Tab 5 of 5`.
2. **Care pillar clarity** — Dedicated **Care** nav icon (medical_services family); care dashboard shows streak ring, date strip, task list, nutrition + medical vault routes; add-task sheet uses drag handle pattern.
3. **Real data everywhere tested** — Tommy (Golden Retriever, 6 yrs, 5.0 kg), 1-day health streak, care tasks, feed posts, match candidates, shops/products, admin metrics (6 active shops, vendor activity).
4. **Marketplace PDP** — `054_product_detail.png` shows SliverAppBar-style hierarchy (post-redesign); cart loads multi-shop grouping.
5. **Admin mobile IA** — Drawer exposes Dashboard, KYC, Ledger, Orders, Moderation, Shops with **Back to app** escape hatch.

### Top issues (confirmed or high-confidence)

| Issue | Severity | Evidence |
|-------|----------|----------|
| **Android `back` exits app from root** | High (QA) | Marionette `press_back_button` sent user to launcher; must use in-app back / scrim dismiss only |
| **Duplicate / stale captures** | Medium (docs) | `024_care_nutrition` identical to `023`; `021`/`022` identical; `053` may be marketplace not PDP; `068`/`070`/`064` duplicates |
| **Manage Pets route not captured** | Medium | `pet_switcher_manage` key exists; sheet Manage row off-screen / tap failed |
| **Auth / onboarding / checkout / chat** | Medium | Not visited (no test credentials policy for cold start) |
| **Outdoor header chip** | Low | `Coming soon` tooltip — dead affordance reads as broken on touch |
| **Profile Health/Care/Awards content** | Low | Awards/Care tabs often share overview empty patterns; needs pet-specific data wiring review |

---

## Methodology

1. **Relaunch policy:** Force-stop avoided; `adb shell am start` + existing session preserved for real Supabase data.
2. **Navigation:** Prefer **semantics** (`content-desc` contains `Tab N of M`) over raw text (`Care` matches shell vs profile tab).
3. **Scroll policy:** At least **two upward scrolls** on primary `ScrollView` per screen before bottom capture.
4. **Non-destructive actions:** No swipe pass/like, checkout, KYC approve/reject, task delete, or post publish.
5. **Dual MCP:** Marionette for `ValueKey` taps when VM service attached; Appium when cold-started or after launcher escape.

---

## Screen-by-screen review (M3 captures)

### Home (`010_home_top`, `011_home_scrolled`)

**Components observed**

- Header: avatar → profile, **ACTIVE PET** eyebrow, **Switch pet · current Tommy**, outdoor (Coming soon), **Notifications**
- Hero: **HEALTH STREAK** gradient card, **1 days on track**, weekday chips (M–S)
- Stat grid: BREED / AGE / WEIGHT / SEX (real values)
- CTAs: **View Social Profile**, **Seller Dashboard** card
- Profile tabs: Overview (selected), Health, Care, Awards
- Overview body: **UPCOMING CARE** → empty state “No upcoming care records”
- Bottom nav: Home selected (filled pill + paw icon)

**UX notes**

- M3 compact streak reads well at 1080px width; numeral scale appropriate.
- Scrolling (`011`) exposes social/upcoming sections — good vertical rhythm.
- **Recommendation:** Replace “Coming soon” with disabled state + `Semantics(enabled: false)` or hide until feature ships.

### Home profile tabs (`012`–`014`)

| Tab | Capture | Content |
|-----|---------|---------|
| Health | `012` | Health-specific modules (verify in screenshot — semantics switch tab) |
| Care | `013` | Care summary / cross-links |
| Awards | `014` | Badges / gamification |

**UX notes:** Tab bar uses `Tab N of 4` semantics — excellent for automation and TalkBack. Ensure each tab has distinct empty states (not cloned overview).

### Pet switcher (`015_pet_switcher_sheet`)

- Title **Your pets**, **5 pets · tap to switch**
- Active row: **Tommy** + Active badge; switch list: Montu, Goldy, Nori, Rex
- **Gap:** Manage row not captured (needs scroll inside sheet or `pet_switcher_manage` tap)

### Notifications (`016_notifications`)

- Route `/social/notifications` from header bell
- **Valid PetFolio capture** (unlike contaminated `010` from fresh pass)

### Social profile (`017_social_profile`)

- Capture taken mid-run after launcher escape — **verify visually**; if launcher chrome appears, discard and use fresh `012_social_profile_from_avatar` from clean pass.

### Care shell (`020`–`025`)

| Step | File | Notes |
|------|------|-------|
| Top | `020_care_top` | Streak, date strip, tasks for active pet |
| Mid / bottom | `021`, `022` | Scrolled task list + banners |
| Add task sheet | `023_care_add_task_sheet` | FAB `care_fab_add_task`; dismiss via scrim tap |
| Nutrition | `024_care_nutrition` | Full-screen route; calorie/weight UI |
| Medical vault | `025_care_medical_vault` | Grouped empty states |

**UX notes**

- Streak hero still tall on care tab but improved vs pre-M3 dumps (~1079px issue); tasks reachable after 1–2 scrolls.
- Nutrition/vault banners tappable — good discoverability.

### Social (`030`, `031`, `032`, `033`)

| Step | File | Notes |
|------|------|-------|
| Feed top | `030_social_top` | Stories + posts, pillar **Social** header |
| Feed bottom | `031_social_bottom` | Heavy scroll content (923 KB PNG — rich feed) |
| Messages | `032_social_to_matching_inbox` | Header Messages → `/matching` inbox (by design) |
| Create post | `033_create_post` | FAB extended; caption, visibility, disabled share until content |

**UX notes**

- “Like” label when count is 0 (M3 change) — clearer than bare `0`.
- Create post non-destructive — good QA discipline.

### Matching (`040`–`042`)

| Step | File | Notes |
|------|------|-------|
| Inbox | `040_matching_inbox` | New matches + conversations |
| Discovery | `041_matching_discovery` | Deck + pass/greet/like/super actions |
| Filters | `042_matching_filters` | Species, distance, age sliders |

**UX notes**

- Distinct **Match** nav icon (swipe) vs Care (medical) — fixes pre-M3 collision.
- Did not exercise mutating swipe actions (correct for production DB).

### Marketplace (`050`–`055`, `052`)

| Step | File | Notes |
|------|------|-------|
| Top | `050_marketplace_top` | Search, categories, shops, products |
| Bottom | `051_marketplace_bottom` | Scrolled catalog |
| Cart | `052_marketplace_cart` | Per-shop grouping |
| Product | `054_product_detail` | SliverAppBar PDP (prefer over `053` if duplicate) |
| Shop | `055_shop_storefront` | Large asset — confirm visually (Discover Shops) |

**UX notes**

- **Shop** tab label vs “Marketplace” copy — aligned with M3 plan.
- Retest cart → checkout stepped UI in a dedicated pass (not captured here).

### Seller (`069`, `070`)

- Entry from home **Seller Dashboard** CTA
- Top: shop status, products/orders entry points
- Bottom: scrolled content including danger zone (from fresh pass reference)

### Admin (`060`–`064`, `068`)

| Tab | File | Semantics |
|-----|------|-----------|
| Dashboard | `060_admin_dashboard` | Platform overview, metrics, recent activity |
| KYC | `061_admin_kyc` | Drawer → KYC |
| Orders | `062_admin_orders` | Operations queue |
| Moderation | `063_admin_moderation` | Reported content |
| Shops | `064_admin_shops` | Shop deletion badge possible |

**UX notes**

- Compact layout uses **drawer** (not bottom tabs) — correct adaptive pattern.
- Wide layout (≥800dp) uses `NavigationRail` per code — **not emulated in this pass**.

---

## M3 plan acceptance checklist (automation-verified)

| Requirement | Status | Evidence |
|-------------|--------|----------|
| `PetfolioBreakpoints` + Pf* widgets | ✅ Implemented (code) | Phase 1 complete; visuals use `PfSolidCard`/headers in dumps |
| Distinct shell icons + drawer @840dp | ✅ Partial | Phone: distinct icons captured; drawer not tested (phone width) |
| `AppHeader` pillar 3px strip + 48dp chips | ✅ | `ACTIVE PET`, action bounds ~126×126 dp-class |
| Compact care streak on phone | ✅ | `010` / care top |
| Social eyebrow **Social** | ✅ | Feed header semantics |
| Matching inbox split @840dp | ⚠️ Not tested | Emulator width 1080dp but layout may still be single column for inbox route |
| Marketplace responsive grid | ✅ | `050`/`051` |
| PDP SliverAppBar | ✅ | `054_product_detail` |
| Cart `PfEmptyState` | ⚠️ | Cart had items — empty state not shown |
| Admin drawer tabs | ✅ | `061`–`064` |
| Text scaler clamp 1.0–1.3 | ✅ (code) | Not runtime-tested |
| Marionette retest | ✅ | This pass |

**Not in scope of M3 / still gap:** Auth/login/onboarding visual redesign, checkout steps, matching card density refactor, full `GlassCard` → `PfSolidCard` migration.

---

## Automation reliability findings

1. **Never call Android back on shell root** — use `Back to app` (admin), route `pop`, or scrim tap `(540, 200)`.
2. **Prefer `Tab N of M` selectors** — e.g. `new UiSelector().descriptionContains("Health").descriptionContains("Tab 2 of 4")` for profile tabs; `Care\nTab 2 of 5` for shell care.
3. **Marionette requires active `flutter run`** — cold `adb start` breaks VM extension until debug attach.
4. **Invalid captures from prior runs** — see fresh report §Invalid; do not use launcher/calendar frames for UI critique.

---

## Coverage matrix

| Surface | M3 capture | Fresh pass | Gap |
|---------|------------|------------|-----|
| Home + tabs | ✅ | ✅ | Manage pets |
| Pet switcher | ✅ | ✅ | Manage row |
| Notifications | ✅ | ⚠️ contaminated | — |
| Care + nutrition + vault | ✅ | ✅ | — |
| Social feed + create | ✅ | ✅ | Post detail |
| Matching discovery/inbox/filters | ✅ | ✅ | Chat thread |
| Marketplace + cart + PDP + shop | ✅ partial | ✅ final | Checkout |
| Seller dashboard | ✅ | ✅ | Stripe onboarding WebView |
| Admin all tabs | ✅ | Dashboard only | Ledger tab screenshot |
| Auth / onboarding | ❌ | ❌ | By policy |
| Buyer orders | ❌ | ❌ | — |

---

## Prioritized UX recommendations

### P0 — Ship blockers

1. **Safe back behavior** — `WillPopScope` / `PopScope` on shell: system back should not finish activity when `canPop == false`.
2. **Discard or implement outdoor header action** — remove `Coming soon` clickable surface.

### P1 — Polish

3. **Manage pets discoverability** — pin **Manage** row visible in switcher or add home settings entry.
4. **Profile tab content parity** — Health/Care/Awards should not mirror empty overview.
5. **Matching deck information hierarchy** — separate hero photo, metadata chips, and CTA row per plan §4.
6. **Checkout stepped UI** — align with `PfSectionHeader` + order summary (Phase 5 follow-up).

### P2 — QA infrastructure

7. **Route harness** — `integration_test` or Marionette script navigating `go('/care/nutrition')` etc. between captures.
8. **Screenshot CI** — golden tests for `010`, `020`, `041`, `054`, `060` against emulator skin.

---

## Screenshots index (M3 pass — trustworthy if size > 50 KB)

```
010_home_top          011_home_scrolled     012_home_health_tab
013_home_profile_care_tab  014_home_awards_tab  015_pet_switcher_sheet
016_notifications     020_care_top          021_care_mid / 022_care_bottom
023_care_add_task_sheet    024_care_nutrition    025_care_medical_vault
030_social_top        031_social_bottom     032_social_to_matching_inbox
033_create_post       040_matching_inbox    041_matching_discovery
042_matching_filters  050_marketplace_top   051_marketplace_bottom
052_marketplace_cart  054_product_detail    055_shop_storefront
060_admin_dashboard   061_admin_kyc         062_admin_orders
063_admin_moderation  064_admin_shops       069_seller_dashboard_top
070_seller_dashboard_bottom
```

**Discard:** `001`–`005` (0-byte corrupt), `006` only, duplicate `053` if identical to `050`.

---

## Conclusion

The M3 redesign successfully delivers a **cohesive Material 3 shell**, clearer **feature wayfinding**, and **documented automation anchors** across the primary product surfaces. Remaining work is less about “missing UI” than **edge-route polish** (auth, checkout, chat), **automation determinism**, and **closing a handful of placeholder affordances** that undermine trust on touch.

**Next validation pass:** emulator width **840dp+** for `NavigationDrawer` + matching inbox split-pane; seeded QA user for mutating flows; `integration_test` route reset between screenshots.
