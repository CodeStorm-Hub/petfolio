# Petfolio — Material 3 Design Review
> Generated 2026-06-14 · Based on codebase scan of `lib/` + M3 knowledge base audit

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Color System](#2-color-system)
3. [Typography](#3-typography)
4. [Shape & Elevation](#4-shape--elevation)
5. [Navigation & Shell](#5-navigation--shell)
6. [Motion & Transitions](#6-motion--transitions)
7. [Component Audit](#7-component-audit)
8. [Accessibility](#8-accessibility)
9. [Adaptive Layout](#9-adaptive-layout)
10. [Interaction States](#10-interaction-states)
11. [Refactoring Priorities](#11-refactoring-priorities)

---

## 1. Executive Summary

Petfolio has a strong foundation: `useMaterial3: true`, a full `ColorScheme.fromSeed` with `DynamicSchemeVariant.fidelity`, proper M3 expressive motion tokens, `RoundedSuperellipseBorder` squircle shapes, and a `PetfolioThemeExtension` that maps cleanly to brand pillars.

**What works well**
- `ColorScheme` fully defined with all 45 roles (no missing mappings)
- `PetfolioThemeExtension` with correct `lerp()` and `copyWith()` for proper theme interpolation
- Motion curves aligned to M3 expressive (`easeInOutCubicEmphasized`, `easeOutBack`)
- Spring physics in nav tab animation (M3 Expressive physics system)
- `ZoomPageTransitionsBuilder` with `allowEnterRouteSnapshotting: true`
- All theme components (`navigationBarTheme`, `cardTheme`, `chipTheme`, etc.) overridden globally
- `RoundedSuperellipseBorder` used correctly for cards, search bar, nav indicator

**Critical gaps**
- Custom `_FloatingNav` bypasses `NavigationBar` widget — loses M3 a11y semantics and `Badge` integration
- `GestureDetector` used instead of `InkWell`/`Material` in shell header (no ripple, no a11y)
- `AppShellHeader` icons have no `Semantics` labels beyond `tooltip`
- Missing `Semantics` wrappers on custom components: `PawToggle`, `BoneSlider`, `GlassCard`, `TailWagLoader`
- No `tonal` button variant — M3 recommends 5 button levels; only filled/outlined/text used
- Backward-compat color aliases (`blue50`–`blue900D`, `sunset500`, `coral500`, etc.) still live in `AppColors` — risk of accidental use
- Snackbar `duration` not enforced (M3 requires ≥ 4 s, auto-dismiss snackbars must meet WCAG 2.1 §2.2.1)

---

## 2. Color System

### What M3 Requires
M3 defines 45 color roles across Primary, Secondary, Tertiary, Error, Surface, Inverse, Fixed, and Scrim groups. Each role has a `color` + `onColor` pair to guarantee ≥ 3:1 contrast. Surface roles (`surfaceContainer`, `surfaceContainerLow`, etc.) encode elevation without `surfaceTintColor`.

### Current State
```dart
// app_theme.dart — ColorScheme
ColorScheme.fromSeed(
  seedColor: AppColors.tangerine,
  dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
)
```
All 45 roles are explicitly overridden in `_colorScheme()` — this is correct.

### Issues & Fixes

#### 2.1 Deprecated `surfaceTintColor: Colors.transparent`
**Severity: Medium**

`surfaceTintColor` was deprecated in Flutter 3.22. Remove all instances.

```dart
// BEFORE — in cardTheme, bottomSheetTheme, dialogTheme, navigationBarTheme
surfaceTintColor: Colors.transparent,

// AFTER — just remove the line; elevation tinting is now handled by surfaceContainer roles
// (no replacement needed — set the right surface color role instead)
```

#### 2.2 Backward-compat aliases must be deleted
**Severity: Medium**

`AppColors` contains ~20 stale aliases (`blue50`, `sunset500`, `coral500`, `apricot500`, `mulberry500`, `line200`, `line100`). These are dead weight — they can silently re-introduce old color values if a developer uses them without checking. Run a grep to find all usages and migrate to canonical names, then delete the alias block.

```bash
# Find usages
grep -rn "AppColors\.blue\|AppColors\.sunset\|AppColors\.coral\|AppColors\.meadow\|AppColors\.apricot\|AppColors\.mulberry\|AppColors\.line200\|AppColors\.line100" lib/
```

#### 2.3 Missing `sky700D` in `AppColors`
**Severity: Low**

`sky700D` is not defined (only `skyD` exists). If any widget uses `sky700` logic on dark, it may fall through to a wrong value. Add:
```dart
static const sky700D = Color(0xFF5AB4E8);
```

#### 2.4 No Dynamic Color support for pet avatar
**Severity: Low / Enhancement**

M3 supports **content-based dynamic color** — extracting a seed from a loaded image (e.g., the pet's avatar photo) to drive the module accent color. This would make each pet's card/screen feel uniquely themed. Implement via:
```dart
// In active_pet_controller
final paletteAsync = ref.watch(petPaletteProvider(pet.avatarUrl));
final accent = paletteAsync.maybeWhen(
  data: (p) => p.dominantColor?.color ?? AppColors.tangerine,
  orElse: () => AppColors.tangerine,
);
```
Use `palette_generator` package (already ecosystem-compatible).

---

## 3. Typography

### What M3 Requires
M3 has 15 baseline type styles (`displayLarge` → `labelSmall`) and 15 new *emphasized* styles (M3 Expressive). Emphasized styles add `fontStyle: FontStyle.italic` + heavier weight for hero moments (splash screens, card CTAs).

### Current State
The `_textTheme()` uses Sora (headings) + Inter (body/label) — a deliberate dual-font system. All 15 baseline styles are defined. Correct.

### Issues & Fixes

#### 3.1 `displaySmall` and `headlineLarge` overlap
**Severity: Low**

Both are `fontSize: 24`. M3 expects a clear step between these roles. Consider:
```dart
displaySmall: GoogleFonts.sora(fontSize: 26, ...),  // was 24
headlineLarge: GoogleFonts.sora(fontSize: 22, ...),  // was 24
```

#### 3.2 Emphasized type styles not defined
**Severity: Enhancement**

M3 Expressive introduces emphasized tokens (bold variant for hero moments). Add emphasized extensions to `PetfolioThemeExtension`:
```dart
// M3 Expressive emphasized styles — use on hero numbers, streak counts, match % 
static TextStyle displayEmphasized(BuildContext context) =>
    GoogleFonts.sora(fontSize: 36, fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic, letterSpacing: -0.5);

static TextStyle headlineEmphasized(BuildContext context) =>
    GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic);
```

#### 3.3 Direct `TextStyle` usage in `AppShellHeader`
**Severity: Medium**

`AppShellHeader` hardcodes text styles inline:
```dart
// BEFORE — lib/core/widgets/app_shell.dart:249
style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)

// AFTER — use theme
style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)
```
Inline styles bypass responsive text scaling and theme switching. Audit all `const TextStyle(...)` calls across the codebase.

#### 3.4 `GoogleFonts.inter().fontFamily` in `ThemeData.fontFamily`
**Severity: Low**

```dart
fontFamily: GoogleFonts.inter().fontFamily, // triggers a network request at startup
```
Use the preloaded variant instead:
```dart
fontFamily: 'Inter', // assumes preloaded via GoogleFonts.config.allowRuntimeFetching = false
```
And preload in `main.dart`:
```dart
await GoogleFonts.pendingFonts([
  GoogleFonts.sora(),
  GoogleFonts.inter(),
]);
```

---

## 4. Shape & Elevation

### What M3 Requires
M3 shape scale: None (0dp) → Extra Small (4dp) → Small (8dp) → Medium (12dp) → Large (16dp) → Extra Large (28dp) → Full. Elevation uses `surfaceContainer` color roles, not `surfaceTintColor`. Shadows are optional expressive additions.

### Current State
`PetfolioThemeExtension` defines custom radius tokens (`radiusXs=6` through `radiusPill=999`) and M3 expressive squircle tokens (`squircleCard=24`, `squircleContainer=28`). This is solid.

### Issues & Fixes

#### 4.1 `radiusXs = 6dp` deviates from M3 Extra Small (4dp)
**Severity: Low**

M3 Extra Small = 4dp. Using 6dp is fine for brand expression but should be documented as an intentional deviation (like the snackbar comment already does for shape). Add a comment:
```dart
// Brand deviation: M3 ExtraSmall = 4dp; Petfolio uses 6dp for softer micro-elements
static const double radiusXs = 6.0;
```

#### 4.2 FAB shape uses `radius2xl = 28dp` (correct) but `elevation: 4` bypasses M3 elevation system
**Severity: Low**

M3 FABs use elevation level 3 (default) and level 4 (hovered). The current `elevation: 4` with `highlightElevation: 6` is above spec. Correct values:
```dart
floatingActionButtonTheme: FloatingActionButtonThemeData(
  elevation: 3,           // M3 level 3
  highlightElevation: 4,  // M3 level 4 on pressed/hovered
  ...
)
```

#### 4.3 Custom `GlassCard` elevation not using M3 surface roles
**Severity: Medium**

`glass_card.dart` uses hardcoded `BoxDecoration` with `BoxShadow`. While glassmorphism is a brand style, the surface color should still map to an M3 surface container role for dark/light consistency:
```dart
// Instead of glassFill (custom), consider layering on surfaceContainerHigh
color: ElevationOverlay.applySurfaceTint(
  Theme.of(context).colorScheme.surfaceContainerHigh,
  Theme.of(context).colorScheme.primary,
  2.0,
), // then apply blur filter on top
```

#### 4.4 `bottomSheetTheme` uses `RoundedRectangleBorder`, should use squircle
**Severity: Low**

For visual consistency with cards and dialogs, bottom sheets should also use `RoundedSuperellipseBorder`:
```dart
bottomSheetTheme: BottomSheetThemeData(
  shape: RoundedSuperellipseBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(PetfolioThemeExtension.squircleContainer),
    ),
  ),
  ...
)
```

---

## 5. Navigation & Shell

### What M3 Requires
- Use `NavigationBar` (not `BottomNavigationBar`) for compact/medium windows
- 3–5 destinations of equal importance
- `NavigationRail` for medium/expanded windows (600dp+)
- `NavigationDrawer` for expanded windows (840dp+)
- Active indicator: pill shape (default) with `indicatorColor = primaryContainer`
- All destinations must be accessible with screen reader semantics

### Current State
The app implements a **custom `_FloatingNav` pill** widget with spring animation, bypassing Flutter's `NavigationBar`. The `_WideNavRail` wraps a proper `NavigationRail`. Shell uses a 600dp breakpoint.

### Issues & Fixes

#### 5.1 Custom `_FloatingNav` bypasses `NavigationBar` — loses a11y semantics
**Severity: High**

`NavigationBar` provides built-in `Semantics` roles (`role: tab`, `selected: true/false`). The custom `GestureDetector`-based `_NavTab` provides none.

**Option A (Recommended):** Keep the custom floating pill visual but wrap each tab in proper `Semantics`:
```dart
// In _NavTab.build()
Semantics(
  label: widget.destination.label,
  selected: widget.isSelected,
  button: true,
  onTap: widget.onTap,
  child: ExcludeSemantics( // exclude child icons from double-announcing
    child: GestureDetector(...),
  ),
)
```

**Option B:** Refactor to use `NavigationBar` with a custom `indicator` and animated `icon` builder — maintains all a11y and adds `Badge` widget support.

#### 5.2 `GestureDetector` in `AppShellHeader` — no ink / no a11y
**Severity: High**

The header's back-to-home button and pet switcher pill both use `GestureDetector`. Replace with `InkWell`:
```dart
// BEFORE — lib/core/widgets/app_shell.dart:392
GestureDetector(
  onTap: () => context.go('/home'),
  child: Container(...)
)

// AFTER
InkWell(
  onTap: () => context.go('/home'),
  borderRadius: BorderRadius.circular(999),
  child: Semantics(
    label: 'Back to Home',
    button: true,
    child: Container(...)
  ),
)
```

#### 5.3 `NavigationBar` breakpoint — M3 says `NavigationRail` at 600dp, not 840dp
**Severity: Medium**

M3 spec: use `NavigationBar` < 600dp; `NavigationRail` 600–840dp; `NavigationDrawer` > 840dp.

Current code uses `isWide = width >= 600` (correct threshold), which renders `_WideNavRail`. However for widths 840dp+ (expanded), M3 recommends `NavigationDrawer` (a permanent sidebar). Consider adding:
```dart
if (width >= 840) return _buildDrawerLayout(context); // modal or permanent drawer
if (width >= 600) return _buildRailLayout(context);
return _buildBottomNavLayout(context);
```

#### 5.4 Module switching — should use `NavigationDrawer` or `ModalBottomSheet`, not custom `AppShellHeader` back button
**Severity: Medium**

The current "back to HOME" pill in the header is a custom module-switcher. M3's canonical pattern for switching between major sections is either `NavigationDrawer` (permanent, for expanded) or a top-level `NavigationBar` with 5 module tabs.

**Recommendation:** Add a `NavigationDrawer` variant for tablets that lists all 5 modules. Keep the floating pill for compact.

#### 5.5 Badge counts in nav should use `Badge` widget
**Severity: Low**

The custom badge in `_NavTab` is a `Container` with inline text. Flutter's `Badge` widget (M3 built-in) handles all size variants automatically:
```dart
Badge(
  count: widget.badgeCount,
  isLabelVisible: widget.badgeCount > 0,
  child: Icon(widget.destination.icon),
)
```

---

## 6. Motion & Transitions

### What M3 Requires
M3 Expressive (2025) migrated from easing/duration tokens to a **motion physics system** using springs. The six transition patterns: Container Transform, Forward/Backward, Lateral, Top Level, Enter/Exit, Skeleton Loaders.

### Current State
`PetfolioThemeExtension` defines M3-aligned motion tokens (`curveEmphasis`, `curveEnter`, `curveExit`, `curveSpring`). The `_NavTab` uses `SpringSimulation` for selection (correct). `AnimatedSwitcher` in `AppShell` uses `SlideTransition + FadeTransition` (correct for module switching).

### Issues & Fixes

#### 6.1 Page transitions not wired to route types
**Severity: Medium**

`ZoomPageTransitionsBuilder` is set globally but M3 recommends different patterns per route:
- **Push (drill-down):** Forward/Backward (slide + fade)
- **Modal:** Enter/Exit (fade up from bottom)
- **Top-level tab switch:** Lateral (cross-fade or slide lateral)

Use GoRouter's `pageBuilder` to apply the right transition per route:
```dart
GoRoute(
  path: '/care/medical',
  pageBuilder: (context, state) => CustomTransitionPage(
    child: const MedicalVaultScreen(),
    transitionsBuilder: (ctx, anim, secondaryAnim, child) =>
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim,
            curve: PetfolioThemeExtension.curveEnter,
          )),
          child: child,
        ),
  ),
)
```

#### 6.2 `AnimatedSwitcher` in `AppShell` missing `layoutBuilder`
**Severity: Low**

Without a `layoutBuilder`, `AnimatedSwitcher` can cause brief layout jumps when nav modules switch. Add:
```dart
AnimatedSwitcher(
  layoutBuilder: (currentChild, previousChildren) => Stack(
    alignment: Alignment.bottomCenter,
    children: [...previousChildren, if (currentChild != null) currentChild],
  ),
  ...
)
```

#### 6.3 `TailWagLoader` should be a `CircularProgressIndicator` with M3 theme
**Severity: Low**

M3 provides `CircularProgressIndicator` with stroke, track color, and loading indicator component. The custom `TailWagLoader` is charming but should at minimum wrap the M3 widget or use `ProgressIndicatorThemeData` already defined:
```dart
// Brand-themed but M3-backed
CircularProgressIndicator(
  color: Theme.of(context).colorScheme.primary,
  strokeCap: StrokeCap.round,
)
```

#### 6.4 Skeleton loaders not using M3 shimmer pattern
**Severity: Low**

M3's skeleton loader transition pattern specifies: render placeholder shapes that match the final content shape, then fade/morph to real content. The current `skeleton_loader.dart` likely uses a static shimmer. Consider the `shimmer` package or an `AnimatedContainer` fade approach consistent with `durationMd` + `curveEnter`.

---

## 7. Component Audit

### 7.1 Buttons

| M3 Level | Widget | Status |
|---|---|---|
| High: FAB | `FloatingActionButton` | ✅ Themed |
| High: Filled | `FilledButton` | ✅ Themed |
| Medium: **Tonal** | `FilledButton.tonal` | ❌ **Missing** |
| Medium: Elevated | `ElevatedButton` | ❌ Not themed |
| Medium: Outlined | `OutlinedButton` | ✅ Themed |
| Low: Text | `TextButton` | ✅ Themed |
| Low: Icon | `IconButton` | ✅ Themed |

**Fix:** Add `FilledButton.tonal` for secondary actions (e.g., "Add to favourites", "Share", "Follow"). M3 spec: use tonal for supporting actions that don't need full primary weight.
```dart
// In app_theme.dart — add filledButtonTonalTheme via ButtonStyle override or global
// Use in widgets:
FilledButton.tonal(
  onPressed: onFollow,
  child: const Text('Follow'),
)
```

Also add `ElevatedButtonThemeData`:
```dart
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ButtonStyle(
    backgroundColor: WidgetStateProperty.all(
      isDark ? AppColors.surface1D : AppColors.surface1,
    ),
    foregroundColor: WidgetStateProperty.all(
      isDark ? AppColors.tangerineD : AppColors.tangerine700,
    ),
    elevation: WidgetStateProperty.resolveWith((states) =>
      states.contains(WidgetState.pressed) ? 2.0 : 1.0,
    ),
    minimumSize: const WidgetStatePropertyAll(Size(96, PetfolioThemeExtension.btnHeightMd)),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
  ),
),
```

### 7.2 Cards

M3 defines three card variants: **Elevated** (default shadow), **Filled** (tonal surface), **Outlined** (border).

| Variant | Petfolio |
|---|---|
| Elevated | `pf_card.dart` (elevation=0 + border → effectively Outlined) |
| Filled | Not explicit |
| Outlined | `cardTheme` with `BorderSide` ✅ |

**Fix:** Rename/alias card usage to make intent clear. Use M3 card variants semantically:
```dart
// Product card — use Elevated for prominence
Card.elevated(child: ProductCard(...))

// Settings list item — use Filled (tonal background, no border)
Card.filled(child: ListTile(...))

// Post card — use Outlined (current default)
Card(child: PostCard(...))
```

### 7.3 Chips

Current chip theme uses `StadiumBorder` and `backgroundColor: tangerineSoft` — correct shape, but all chips use the same visual style regardless of type (filter, input, suggestion, assist).

**Fix:** Use semantic chip types:
```dart
// Category filters in marketplace — FilterChip
FilterChip(
  label: Text(category.name),
  selected: isSelected,
  onSelected: onToggle,
  // M3: shows checkmark when selected, no need for custom icon logic
)

// Pet species tags — AssistChip (not clickable)
Chip(label: Text(pet.species.name))

// Search query tokens — InputChip (removable)
InputChip(
  label: Text(tag),
  onDeleted: () => removeTag(tag),
)
```

Also: chip `trailing icon` 48dp touch target requirement — ensure the delete icon on InputChip has `materialTapTargetSize: MaterialTapTargetSize.padded`.

### 7.4 Snackbar

**Severity: High**

M3 snackbar guidelines (and WCAG 2.1 §2.2.1) require auto-dismissing snackbars to be visible for **at least 4 seconds** (recommended 4–10 s). The current `AppSnackBar` or `ScaffoldMessenger.showSnackBar()` calls likely use Flutter's default 4 s, but should be audited.

Additionally, M3 says snackbars must have:
1. A clear action button (if actionable)
2. Sufficient contrast (already correct — using `ink950` on light, `surface0` on dark)
3. `SnackBarBehavior.floating` ✅ (already set)

```dart
// Enforce minimum duration globally in app_snack_bar.dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(message),
    duration: duration.clamp(const Duration(seconds: 4), const Duration(seconds: 10)),
    behavior: SnackBarBehavior.floating,
  ),
);
```

**Web note:** M3 says auto-dismissing snackbars are inaccessible on web for users with low vision. On `kIsWeb`, either use `duration: Duration(days: 1)` with a manual dismiss action, or switch to a `Dialog`/`Banner`.

### 7.5 Bottom Sheets

All bottom sheets use `showModalBottomSheet()` — correct for blocking secondary content. Ensure:
- `isScrollControlled: true` for tall sheets ✅ (used in cart drawer)
- `useDragHandle: true` — the theme sets `showDragHandle: true` ✅
- `constraints: BoxConstraints(maxWidth: 560)` for tablet ✅ (used in cart)

**Missing:** For sheets that are not full-screen on tablet (e.g., `MatchPreferencesSheet`, `PetSwitcherSheet`), add `maxWidth: 480` constraint to prevent sheets spanning the full tablet width.

### 7.6 Dialogs

Current `dialogTheme` uses `RoundedRectangleBorder(radius: 28dp)` — M3 spec is 28dp (correct). However, dialogs on large screens should switch to a simpler variant. Add in routes or dialog callers:
```dart
showAdaptiveDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    // On mobile: full-screen. On tablet: centered dialog.
    ...
  ),
);
```

### 7.7 Search Bar

`searchBarTheme` uses `RoundedSuperellipseBorder` — correct. However, the M3 `SearchBar` widget has a built-in suggestions panel (`SearchAnchor`) that replaces custom search-with-overlay patterns. Consider migrating marketplace/vet search screens to `SearchAnchor` + `SearchBar`:
```dart
SearchAnchor(
  builder: (context, controller) => SearchBar(
    controller: controller,
    hintText: 'Search products...',
    leading: const Icon(Icons.search),
    onTap: () => controller.openView(),
  ),
  suggestionsBuilder: (context, controller) => [...],
)
```

### 7.8 Text Fields

`inputDecorationTheme` uses `OutlineInputBorder` with `radiusPill` — this creates a pill-shaped text field, which is a brand decision. However:
- M3 text fields should be `OutlineInputBorder` (outlined) or `UnderlineInputBorder` (filled), not pill-shaped, per strict spec. The app's choice is valid as a brand deviation.
- **Issue:** `focusedBorder` uses tangerine stroke (correct primary color) but `errorBorder` is not defined — it will fall back to the theme default red, which may clash with the app's poppy/danger colors.

```dart
// Add to inputDecorationTheme
errorBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
  borderSide: BorderSide(color: isDark ? AppColors.dangerD : AppColors.danger, width: 1.5),
),
focusedErrorBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
  borderSide: BorderSide(color: isDark ? AppColors.dangerD : AppColors.danger, width: 2),
),
```

### 7.9 Progress Indicators

`progressIndicatorTheme` is correctly defined. However:
- `strokeWidth: 3.0` — M3 default is 4dp for circular, 4dp for linear. Consider 4dp.
- **Missing indeterminate state color for `LinearProgressIndicator`** in care streak/loading states. Use `linearTrackColor: tangerineSoft` ✅ (already set).
- M3 Expressive introduces a **Loading Indicator** with shape morphing. Consider using the new `CircularProgressIndicator` with `strokeCap: StrokeCap.round` for the tail-wag loader enhancement.

### 7.10 Tooltips

`tooltipTheme` is defined with correct `radiusSm (8dp)` shape. However:
- `waitDuration: 600ms` — M3 suggests 500ms. Minor.
- Tooltips should not appear on mobile touch (M3 spec: tooltips are for pointer/keyboard users). The current implementation fires on long-press which is correct for mobile, but ensure `preferBelow: false` is set when near screen edges.

---

## 8. Accessibility

### What M3 Requires
- All interactive elements ≥ 48×48dp touch target
- `Semantics` on all custom components
- Minimum 3:1 contrast for non-text, 4.5:1 for text (WCAG AA)
- Screen reader verbalizations for state changes
- Focus traversal order matches visual order

### Issues by Priority

#### P0 — Critical

**8.1 Custom nav tabs have no semantics role**

`_NavTab` uses `GestureDetector` with no `Semantics` wrapper. TalkBack/VoiceOver will announce nothing.

```dart
// Wrap each _NavTab
Semantics(
  label: '${widget.destination.label}, tab',
  selected: widget.isSelected,
  button: true,
  child: GestureDetector(...),
)
```

**8.2 `PawToggle` — custom toggle with no `SwitchListTile` or `Semantics`**

Custom-drawn toggles must manually declare:
```dart
Semantics(
  toggled: value,
  label: semanticLabel, // e.g., 'Grooming reminder'
  onTap: onChanged != null ? () => onChanged!(!value) : null,
  child: PawToggle(...)
)
```

**8.3 `BoneSlider` — custom slider with no `SliderTheme` or `Semantics`**

```dart
Semantics(
  slider: true,
  label: semanticLabel, // e.g., 'Daily walk goal'
  value: '${(value * 100).round()}%',
  onIncrease: () => onChanged(value + step),
  onDecrease: () => onChanged(value - step),
  child: BoneSlider(...),
)
```

**8.4 `_HeaderIconBtn` — `tapTargetSize: shrinkWrap` reduces target below 48dp**

```dart
// BEFORE — app_shell.dart:528
tapTargetSize: MaterialTapTargetSize.shrinkWrap,

// AFTER — remove this line; let the default padded target apply
// The IconButton with constraints: BoxConstraints(minWidth: 48, minHeight: 48)
// already handles the visual; shrinkWrap shrinks the *tap* area below 48dp
```

#### P1 — Important

**8.5 `petfolio_network_image.dart` — missing `semanticLabel`**

```dart
Image.network(
  url,
  semanticLabel: semanticLabel ?? 'Pet photo', // add parameter
)
```
Or via `CachedNetworkImage`:
```dart
CachedNetworkImage(
  imageUrl: url,
  imageBuilder: (ctx, provider) => Semantics(
    label: semanticLabel,
    image: true,
    child: Image(image: provider),
  ),
)
```

**8.6 `StreakPill` in header — no semantic announcement on streak change**

When the streak count changes (e.g., after completing a task), TalkBack should announce it. Add a `LiveRegion`:
```dart
Semantics(
  liveRegion: true,
  label: '$streak day streak',
  child: streakPillWidget,
)
```

**8.7 `AnimatedSwitcher` transitions — screen readers may miss content change**

Wrap screens shown by `AnimatedSwitcher` with `Semantics(container: true)` to force focus re-traversal.

#### P2 — Enhancement

**8.8 Contrast check for `ink300` on `cream` background**

`ink300 = Color(0xFFD6C2B0)` on `cream = Color(0xFFFFF4E6)` — this is approximately 1.5:1 contrast, which fails WCAG AA for both normal (4.5:1) and large (3:1) text. Never use `ink300` for readable text; it's for decorative/placeholder use only. Add a comment:
```dart
// ink300 — decorative use only (placeholder, divider hint). FAILS WCAG AA for text.
static const ink300 = Color(0xFFD6C2B0);
```

**8.9 `glassFill` overlays — may reduce contrast of underlying text**

Glassmorphism by definition reduces contrast. Any text rendered over `GlassCard` should use `onSurface` colors and be tested at the blend alpha. Minimum: add a test for WCAG at the glass fill opacity.

---

## 9. Adaptive Layout

### What M3 Requires
| Breakpoint | Width | Nav Component | Layout |
|---|---|---|---|
| Compact | < 600dp | NavigationBar (bottom) | Single pane |
| Medium | 600–839dp | NavigationRail (side) | Single or 2-pane |
| Expanded | 840–1199dp | NavigationDrawer (permanent) | 2-pane |
| Large | 1200–1599dp | NavigationDrawer | 2-pane + detail |
| Extra-large | ≥ 1600dp | NavigationDrawer | 3-pane |

### Current State
The app handles compact (`_FloatingNav`) and medium/expanded (`_WideNavRail`) with a single 600dp breakpoint.

### Issues & Fixes

#### 9.1 Flat 600dp breakpoint — no expanded/large handling
**Severity: Medium**

```dart
// BEFORE — app_shell.dart:91
final isWide = MediaQuery.sizeOf(context).width >= 600;

// AFTER — 3-tier breakpoints
final width = MediaQuery.sizeOf(context).width;
final isCompact   = width < 600;    // phone portrait
final isMedium    = width < 840;    // tablet portrait, foldable
final isExpanded  = width >= 840;   // tablet landscape, desktop
```

#### 9.2 `responsive_layout.dart` not used by most feature screens
**Severity: Medium**

The core `responsive_layout.dart` widget exists but individual feature screens (`marketplace_screen.dart`, `social_screen.dart`, etc.) likely use fixed padding and `ListView` without adaptive column counts.

**Recommendation:** Audit feature screens for 600dp+ layouts. Key screens that should adapt:
- `marketplace_screen.dart` — product grid should go from 2 → 3 → 4 columns
- `social_screen.dart` — feed should center-clamp at `maxWidth: 680`
- `vet_clinics_screen.dart` — clinic list should become a list-detail pane at 840dp+

```dart
// Grid adaption pattern
SliverGrid(
  delegate: SliverChildBuilderDelegate(
    (context, i) => ProductCard(products[i]),
    childCount: products.length,
  ),
  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 220, // auto-computes columns from screen width
    childAspectRatio: 0.75,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
)
```

#### 9.3 Dialog full-screen on mobile vs. centered on tablet
**Severity: Low**

M3 adaptive pattern: `full-screen dialog → basic dialog` at larger breakpoints. Use:
```dart
// In feature dialogs
showAdaptiveDialog(context: context, builder: (ctx) => AlertDialog(...));
// Or manually:
if (MediaQuery.sizeOf(context).width < 600) {
  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
    fullscreenDialog: true, builder: (_) => FullScreenDialog(),
  ));
} else {
  showDialog(context: context, builder: (_) => AlertDialog(...));
}
```

#### 9.4 Bottom sheets should become side sheets at 840dp+
**Severity: Enhancement**

M3 introduces `SideSheet` for expanded windows. `MatchPreferencesSheet`, `CartDrawer`, `PetSwitcherSheet` should all become side sheets (anchored to the trailing edge) on tablet:
```dart
// Pattern
if (MediaQuery.sizeOf(context).width >= 840) {
  // Show as NavigationDrawer or side pane
} else {
  showModalBottomSheet(context: context, builder: (_) => Sheet());
}
```

---

## 10. Interaction States

### What M3 Requires
M3 interaction states: **Enabled → Hovered (8%) → Focused (10%) → Pressed (10%) → Dragged (16%) → Selected → Activated → Error → Disabled (38%)**. State layers use the `onSurface` color at the specified opacity over the component's background.

### Current State
`filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`, `iconButtonTheme` all use `overlayColor` via `WidgetStateProperty.resolveWith` — correct pattern.

### Issues & Fixes

#### 10.1 `overlayColor` uses `withAlpha(24)` uniformly — should differ by state
**Severity: Low**

M3 state layer opacities: hover 8%, focus 10%, pressed 10%. `withAlpha(24)` ≈ 9.4% — close but not differentiated. Fix:
```dart
overlayColor: WidgetStateProperty.resolveWith((states) {
  final base = isDark ? AppColors.tangerineD : AppColors.tangerine;
  if (states.contains(WidgetState.pressed)) return base.withAlpha(26);  // 10%
  if (states.contains(WidgetState.focused)) return base.withAlpha(26);  // 10%
  if (states.contains(WidgetState.hovered)) return base.withAlpha(20);  // 8%
  return null;
}),
```

#### 10.2 `GestureDetector` — no pressed state visual on custom interactive elements
**Severity: Medium**

Any `GestureDetector` that wraps a non-button widget (e.g., post cards in social feed, product cards in marketplace) should use `InkWell` or `InkResponse` to show the M3 ripple state layer:
```dart
// BEFORE
GestureDetector(onTap: onTap, child: Card(...))

// AFTER
Card(
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(PetfolioThemeExtension.squircleCard),
    child: Padding(padding: ..., child: content),
  ),
)
```
Note: put `InkWell` *inside* the `Card` so the ripple is clipped by the card's shape.

#### 10.3 Missing disabled states on custom `PrimaryPillButton`
**Severity: Medium**

Check `primary_pill_button.dart` for `onPressed: null` handling. If using a `FilledButton` internally, the theme handles disabled via `WidgetState.disabled` — confirm `backgroundColor.resolve([WidgetState.disabled])` returns the correct 38% opacity value (currently set to `withAlpha(102)` ≈ 40%, correct).

---

## 11. Refactoring Priorities

### Priority Matrix

| Priority | Area | Effort | Impact |
|---|---|---|---|
| **P0** | Add `Semantics` to `_NavTab`, `PawToggle`, `BoneSlider`, header buttons | Low | A11y critical |
| **P0** | Replace `GestureDetector` with `InkWell` + `Semantics` in `AppShellHeader` | Low | A11y + ripple |
| **P0** | Fix `_HeaderIconBtn` `tapTargetSize: shrinkWrap` → remove | Trivial | Touch target |
| **P0** | Enforce snackbar `duration >= 4s`; add `kIsWeb` persistent fallback | Low | A11y + WCAG |
| **P1** | Add `FilledButton.tonal` theme + adopt across secondary actions | Medium | M3 button hierarchy |
| **P1** | Add `errorBorder` + `focusedErrorBorder` to `inputDecorationTheme` | Low | Visual completeness |
| **P1** | Migrate `FilterChip`/`InputChip`/`AssistChip` usage in marketplace & search | Medium | M3 chip semantics |
| **P1** | Replace `GestureDetector` → `InkWell` in all product/post cards | Medium | Interaction states |
| **P1** | Add `semanticLabel` param to `PetfolioNetworkImage` | Low | A11y images |
| **P2** | Remove deprecated `surfaceTintColor: Colors.transparent` (all files) | Low | Future-proofing |
| **P2** | Delete backward-compat color aliases from `AppColors` (after migration) | Medium | Code hygiene |
| **P2** | Three-tier breakpoints (`< 600 / < 840 / ≥ 840`) in `AppShell` | Medium | Adaptive layout |
| **P2** | `SliverGridDelegateWithMaxCrossAxisExtent` for product/vet grids | Medium | Adaptive grid |
| **P2** | `bottomSheetTheme` → `RoundedSuperellipseBorder` for shape consistency | Low | Visual polish |
| **P2** | Add `elevatedButtonTheme` to `AppTheme._build()` | Low | Button coverage |
| **P3** | `SearchAnchor` + `SearchBar` for marketplace/vet search screens | High | M3 search pattern |
| **P3** | Side sheet pattern for 840dp+ (cart, preferences, pet switcher) | High | Adaptive sheets |
| **P3** | Content-based dynamic color from pet avatar (palette_generator) | High | M3 Expressive |
| **P3** | Emphasized type style tokens (M3 Expressive italic/bold moments) | Medium | Typography depth |
| **P3** | Container transform transition for card → detail navigation | High | Motion richness |

### Quick-Win Script
Run these greps to find the most impactful locations immediately:

```bash
# Find all GestureDetector usages (replace with InkWell or Semantics)
grep -rn "GestureDetector(" lib/ --include="*.dart" | grep -v ".g.dart"

# Find inline const TextStyle (replace with theme references)
grep -rn "const TextStyle(" lib/ --include="*.dart" | grep -v ".g.dart"

# Find deprecated surfaceTintColor
grep -rn "surfaceTintColor" lib/ --include="*.dart"

# Find backward-compat color aliases in use
grep -rn "AppColors\.blue\|AppColors\.sunset\|AppColors\.coral\|AppColors\.meadow" lib/ --include="*.dart"

# Find missing error border in text fields
grep -rn "TextFormField\|TextField" lib/ --include="*.dart" | grep -v ".g.dart"

# Find snackbar durations
grep -rn "showSnackBar\|SnackBar(" lib/ --include="*.dart"
```

---

## Appendix: M3 vs Petfolio Token Mapping

| M3 Token | Petfolio Value | Notes |
|---|---|---|
| `md.sys.color.primary` | `tangerine (#FF8A4C)` | ✅ |
| `md.sys.color.primaryContainer` | `tangerineSoft (#FFE0CB)` | ✅ |
| `md.sys.color.secondary` | `poppy (#FF3D3D)` | ✅ |
| `md.sys.color.tertiary` | `mint (#2FCBA0)` | ✅ |
| `md.sys.color.surface` | `surface0 (#FFFFFF)` | ✅ |
| `md.sys.color.surfaceContainer` | `cream (#FFF4E6)` | ✅ |
| `md.sys.shape.corner.extraSmall` | `radiusXs = 6dp` | ⚠️ M3 = 4dp (intentional brand deviation) |
| `md.sys.shape.corner.small` | `radiusSm = 8dp` | ✅ |
| `md.sys.shape.corner.medium` | `radiusMd = 12dp` | ✅ |
| `md.sys.shape.corner.large` | `radiusLg = 16dp` | ✅ |
| `md.sys.shape.corner.extraLarge` | `radius2xl = 28dp` | ✅ |
| `md.sys.shape.corner.full` | `radiusPill = 999dp` | ✅ |
| `md.sys.motion.duration.short1` | `durationXs = 80ms` | ✅ |
| `md.sys.motion.duration.medium2` | `durationMd = 220ms` | ✅ |
| `md.sys.motion.duration.long2` | `durationLg = 320ms` | ✅ |
| `md.sys.motion.easing.emphasized` | `curveEmphasis = easeInOutCubicEmphasized` | ✅ |
| `md.sys.motion.easing.standard.decelerate` | `curveEnter = easeOutCubic` | ✅ |
| `md.sys.motion.easing.standard.accelerate` | `curveExit = easeInCubic` | ✅ |
| `md.comp.navigation-bar.height` | `72dp` | ✅ M3 = 80dp, 72dp acceptable |
| `md.comp.card.color` | `surface0 (elevation 0)` | ✅ |
| `md.comp.fab.shape` | `radius2xl = 28dp (rounded square)` | ✅ |
| `md.comp.filled-button.height` | `btnHeightLg = 52dp` | ⚠️ M3 = 40dp; 52dp is intentional brand choice |

---

*This document was generated by reviewing all files under `lib/` and cross-referencing the Material 3 knowledge base (components, foundations, styles). Re-run after major refactors to track compliance delta.*
