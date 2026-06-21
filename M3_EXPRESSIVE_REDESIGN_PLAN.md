# Petfolio — Material 3 Expressive Redesign Plan

> Research basis: live codebase audit (`lib/core/theme`, `lib/core/router.dart`, `lib/core/widgets`, 12 feature folders, 45+ screens) + Material 3 Expressive official guidelines (m3.material.io, May 2025 update) + Flutter M3 implementation references, June 2026.

---

## 1. Where Petfolio stands today

**Strengths already in place** (don't rip these out — extend them):

- `useMaterial3: true`, custom `PetfolioThemeExtension` with 50+ tokens: ink scale, 4-tier surface layers, 6 pillar accent colors (Pets/Tangerine, Care/Sunny, Social/Poppy, Match/Lilac, Health/Mint, Market/Sky), glass-morphism tokens, 4-tier shadow system (E1–E4).
- Two-font system: Sora (headings) + Inter (body) via `google_fonts`.
- `StatefulShellRoute` with 5 branches (Home, Care, Social, Matching, Marketplace) and a custom floating pill bottom nav with spring physics (mass/stiffness/damping) already mimicking M3 Expressive motion springs.
- Squircle (`RoundedSuperellipseBorder`) adoption on `PfCard` and social post cards.
- Adaptive shell: `NavigationRail` ≥600dp, floating pill nav on mobile, full-width bar on web.

**Gaps vs. Material 3 Expressive (May 2025 spec)** — this is the actual redesign opportunity:

| Area | Current state | M3 Expressive gap |
|---|---|---|
| App bars | Custom `AppShellHeader` (blur + gradient veil) — good, but not standardized to **medium-flexible / large-flexible** app bar patterns on detail screens | No subtitle support, no left/center text alignment option, large screens (pet profile, vet clinic detail) lack a flexible collapsing header |
| Shapes | Mixed radii: 18, 20, 22, 24 dp scattered ad hoc; squircle only on `PfCard` + post cards | No unified shape **scale**, no **shape morphing** on press/select (buttons, FAB, chips) |
| Buttons | Standard `FilledButton`/`ElevatedButton`, no size variants beyond default | M3 Expressive defines 5 sizes (XS–XL) + shape-morph on press/selection; not used anywhere |
| FAB | One `FloatingActionButton.extended` (Social only) | No FAB on Care, Marketplace, Matching; no FAB menu for multi-action surfaces (e.g. Care: log medical / log weight / log walk) |
| Navigation | Custom pill nav (good motion) but **not** Flutter's `NavigationBar`/`NavigationRail` M3 widgets — hand-rolled, harder to theme-sync | Could keep custom visual language but rebuild atop `NavigationBar` theming tokens for consistency with `NavigationRail` desktop variant |
| Color | Static seed + pillar accents, no **dynamic/content-based color** | Tonal containers (primary/secondary/tertiary **container**) not used for low-emphasis surfaces; cards use raw alpha-blended fills instead of M3 tonal roles |
| Typography | Two-tier (Sora/Inter), but display scale capped ~36px | M3 Expressive pushes emphasized/larger display type for hero moments (up to 57px display) — home hero, onboarding, empty states under-use this |
| Motion | Cubic-emphasized curves + one spring config (nav) | No shared-axis/fade-through page transitions; no shape-morph transitions; spring motion not reused on cards, chips, FAB |
| Cards | `BorderRadius`/`RoundedSuperellipseBorder` mixed across screens; bottom sheets use plain `BorderRadius`, not squircle | Inconsistent corner language between cards (squircle) and sheets/dialogs (round rect) breaks the "shape system" cohesion M3 Expressive is built around |
| Admin | Plain `AdminPanelScaffold`/status chips, utilitarian | Lowest priority but still inconsistent with consumer-facing pillar theming |

---

## 2. Material 3 Expressive — what's actually new (May 2025 spec)

Five pillars: **color, shape, size, motion, containment.**

1. **Shape**: 35 new shapes + shape-morphing in the Material Shapes library. New corner tokens: Large → 20dp, Extra-large → 32dp, **new Extra-extra-large → 48dp**, "full" replaces 50%-of-size for pill shapes.
2. **Buttons & icon buttons**: 5 sizes (XS/S/M/L/XL), round-or-square shape options, shape **morphs on press and on selection** (toggle state).
3. **Button groups**: new component — standard + connected button groups replace segmented buttons (now deprecated in favor of nav rail or connected button groups).
4. **FAB**: added **medium** size; **small FAB deprecated**; added Secondary/Tertiary container color tones; surface-color FAB deprecated.
5. **Extended FAB**: 3 sizes (small 56dp / medium 80dp / large 96dp), larger type; baseline extended FAB deprecated.
6. **FAB menu**: new component replacing speed-dial / stacked small FABs — single menu pairs with any FAB size.
7. **App bars**: renamed "top app bar" → "app bar." New **search app bar**. **Medium-flexible** and **large-flexible** app bars replace plain medium/large (larger title, subtitle, left/center text, text wrap, flexible imagery slot). Small app bar gains subtitle + center-align option too.
8. **Motion**: spring-based system — *spatial springs* (mirror real object physics for movement) and *effects springs* (color/opacity transitions). Use sparingly, reserved for key moments.
9. **Color**: emphasis on **color roles** over fixed hex (dynamic/content-based color sources), tonal palettes (13-tone scale per key color) for automatic contrast.
10. **Typography**: emphasized/variable type styles for emotional range, larger editorial display sizes.

---

## 3. Redesign direction by module

### 3.1 Navigation shell & app-wide chrome
- Rebuild the floating pill nav's *theming* on top of Flutter's `NavigationBar`/`NavigationRail` M3 token system (keep the existing spring animation curve/physics — it already matches M3 Expressive's spatial-spring intent) so badges, indicator pill, and selected-icon color come from `NavigationBarThemeData` instead of hand-coded alpha math.
- Promote `AppShellHeader` to support the **large-flexible app bar** pattern on scrollable hub/detail screens (pet profile, vet clinic detail, product detail): collapses from large title + subtitle on scroll down to a small centered title, reusing the existing backdrop-blur/gradient-veil mechanics already built.
- Introduce a **search app bar** variant for Marketplace and Social (replacing the current icon-only search affordance) — opens a dedicated search view component instead of inline filtering.

### 3.2 Shape & component system (cross-cutting)
- Define one shape **scale** in `PetfolioThemeExtension`: `xs(8) · sm(12) · md(16) · lg(20) · xl(24) · xxl(32) · xxxl(48) · full`. Map every card/sheet/dialog/chip to this scale instead of ad-hoc 18/20/22/24 values.
- Migrate all elevated cards (`PfCard`, post cards, product cards, care task cards) to `RoundedSuperellipseBorder` at `lg`/`xl`, and **bottom sheets/dialogs** to the same squircle language (currently plain rounded-rect) so containment reads as one system.
- Add **shape-morph press states** to primary buttons, chips, and the nav pill's active indicator — square↔rounded morph on press/selection using `AnimatedContainer`/`ShapeDecoration` lerp, consistent with the M3 shape-morph spec.

### 3.3 Buttons, FABs, chips
- Adopt the 5-size button scale (XS–XL) for context: XS/S for inline card actions (react, save), M default, L/XL for primary CTAs (checkout, book appointment, post).
- Replace the single Social FAB with **per-feature FABs**: Marketplace (quick "add product to wishlist"/seller "add listing"), Care (**FAB menu**: log weight / log medical event / log walk / add reminder — exactly the speed-dial-replacement use case M3 Expressive ships), Matching (boost profile / send super-like).
- Replace category/segmented filter chips (Care, Marketplace) — currently plain `FilterChip` rows — with the new **connected button group** pattern where selection is mutually exclusive (Care task filters, Marketplace category bar), reserving classic chips for multi-select facets.

### 3.4 Color & containment
- Introduce explicit **tonal container** roles (primary/secondary/tertiary-container) for medium-emphasis surfaces — e.g. selected category chip fill, achievement badge background, "AI suggestion" banners — replacing the current raw alpha-blended pillar-accent fills with proper container/on-container token pairs (keeps contrast correct in dark mode automatically).
- Keep the 6 pillar accents (they're a strong brand differentiator already aligned with M3's "personalization" pillar) but route them through the tonal-palette generator so each pillar accent gets a full 13-tone ramp (used today only as single hex + manual alpha blends) — fixes the dark-mode contrast inconsistencies flagged in the audit.
- For Pet Profile, consider **content-based color**: derive an accent tint from the pet's photo/breed-color for that pet's profile screen and switcher pill — directly matches M3 Expressive's "content-based source" guidance and reinforces "this is MY pet's space."

### 3.5 Typography & hero moments
- Reserve emphasized, larger display type (40–57px Sora) for: onboarding screens, empty states, hub home hero greeting, and celebration overlays (match celebration, achievement unlock) — currently capped around 36px. These are the "emotionally impactful" moments M3 Expressive research specifically targets.
- Standardize the all-caps tracked label style (currently used ad hoc as `SectionHeader`) as the only eyebrow/label pattern app-wide.

### 3.6 Motion
- Extend the nav-pill spring config into a shared `PetfolioMotion.spring` token and reuse it for: card press feedback, FAB menu expand, reaction picker, achievement unlock, match celebration overlay — right now the spring is implemented once, inline, only in the nav.
- Add shared-axis (horizontal) transitions for shell-branch switches and fade-through for modal→content swaps (e.g. cart → checkout), replacing default `MaterialPageRoute` fades where GoRouter custom transitions aren't yet defined.
- Add shape-morph transitions where a chip/button expands into a sheet or dialog (e.g. category chip → filter sheet, FAB → FAB menu) — visually ties the shape system and motion system together per the spec.

### 3.7 Per-feature highlights

**Home (Hub):** Keep the bento grid (it's already a strong differentiator) — apply shape scale to bento tiles uniformly, add shape-morph to the "All Features" CTA, route streak/quick-action pills through tonal-container colors.

**Care:** FAB menu for logging (see 3.3). Convert task-filter chips to connected button group. Use medium-flexible app bar for the Care dashboard scroll header showing pet streak in the subtitle.

**Social:** Search app bar for discovery. Standardize PostCard squircle radius to the new `xl` token. Extend FAB shape-morph (square idle → rounded on scroll-to-top reveal, matching M3's morph-on-state-change idea).

**Matching:** FAB menu for boost actions. Match-celebration overlay gets the emphasized display type treatment + spring-based scale-in (effects spring on color, spatial spring on the celebratory card).

**Marketplace:** Search app bar replacing icon button. Cart badge and "fly to cart" animation reuse the shared spring token. Category bar → connected button group. Product cards → unified squircle `lg`.

**Pet Profile / Appointments / Messaging:** Large-flexible app bar with pet-photo-derived content-based color tint (pet profile), subtitle showing next appointment/vet name (appointments), and a search app bar for vet/clinic discovery.

**Admin:** Lowest priority — bring `AdminPanelScaffold` onto the same shape/typography scale for visual consistency, but no need for expressive motion/FAB work here (utility surface, not a "moment").

---

## 4. Component upgrade checklist (quick reference)

- [ ] Unify corner-radius tokens into one shape scale (`xs`→`full`) in `PetfolioThemeExtension`
- [ ] Migrate bottom sheets/dialogs to squircle to match cards
- [ ] Add shape-morph press/selection states to buttons, chips, nav indicator
- [ ] Adopt 5-size button scale (XS–XL) by context
- [ ] Add FAB menus: Care (logging), Matching (boost/actions)
- [ ] Add FABs to Marketplace, keep/extend Social FAB with morph-on-scroll
- [ ] Replace exclusive-selection chip rows with connected button groups (Care filters, Marketplace categories)
- [ ] Introduce tonal-container color roles for medium-emphasis surfaces (replace raw alpha blends)
- [ ] Generate full 13-tone ramps for the 6 pillar accents (fix dark-mode contrast)
- [ ] Content-based color tint on Pet Profile from pet photo
- [ ] Large-flexible / medium-flexible app bar pattern on: Pet Profile, Appointments, Care dashboard, Product detail
- [ ] Search app bar on Social and Marketplace
- [ ] Larger emphasized display type for hero/celebration/empty-state moments
- [ ] Shared `PetfolioMotion.spring` token reused across nav, cards, FAB menu, celebrations
- [ ] Shared-axis / fade-through route transitions for shell branches and modal flows
- [ ] Bring Admin surfaces onto unified shape/type scale

---

## 5. Suggested phasing

1. **Foundation (theme-only, low risk):** shape scale token, tonal-container roles, pillar-accent tonal ramps, shared motion-spring token. No screen-level changes yet — everything downstream depends on these.
2. **Navigation & chrome:** app bar variants (flexible/search), nav bar re-theming, bottom sheet/dialog squircle migration.
3. **Component layer:** button size scale + shape-morph, FAB menus, connected button groups, chip migration.
4. **Per-feature polish:** hero typography, content-based pet color, celebration motion, page transitions.
5. **Admin parity pass** (cosmetic only, no new interaction patterns needed).

Each phase should follow the project's standard sequencing (SQL → models → repositories → controllers → UI is N/A here since this is presentation-only; instead: theme tokens → shared widgets → feature screens, one feature confirmed at a time per `CLAUDE.md` sequential-execution rule).

---

## Sources

- [Material 3 Expressive — Start building](https://m3.material.io/blog/building-with-m3-expressive)
- [Material 3 — Get started](https://m3.material.io/get-started)
- [Material 3 Expressive: New Components, Motion, Shapes, and More](https://supercharge.design/blog/material-3-expressive)
- [Material 3 Expressive deep dive — Android Authority](https://www.androidauthority.com/google-material-3-expressive-features-changes-availability-supported-devices-3556392/)
- [Google launches Material 3 Expressive — Android/Wear OS](https://blog.google/products-and-platforms/platforms/android/material-3-expressive-android-wearos-launch/)
- [Material Design for Flutter](https://docs.flutter.dev/ui/design/material)
- [Material Design 3 for Flutter](https://m3.material.io/develop/flutter)
- Local Material 3 knowledge base (`material3-kb` MCP): app-bars, buttons, FAB, FAB-menu, button-groups, shape, color overviews
- Live codebase audit: `lib/core/theme/`, `lib/core/router.dart`, `lib/core/widgets/`, all `lib/features/*/presentation/`
