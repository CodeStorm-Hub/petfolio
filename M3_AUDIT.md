# Material 3 Audit & Remediation Checklist

Reviewed against: local `material3-kb` M3 docs + codebase focus on `lib/core/theme/app_theme.dart`, `lib/core/widgets/app_shell.dart`, `lib/core/navigation/shell_destinations.dart`, `lib/main.dart`.

## P0 — Fix these before the next UI cycle

- [ ] **Replace direct surface fills with M3 surface roles**
  - Files: `lib/core/theme/app_theme.dart`, `lib/core/widgets/app_shell.dart`, feature screens under `lib/features/*/presentation/screens/`
  - Issue: current theme maps `surface0/surface1/surface2/cream*` into `scaffoldBackgroundColor`, cards, dialogs, bottom sheets, and custom containers. M3 docs say the main body should use `surface`/`surfaceContainer*`, and overlapping containers should differ by role.
  - Action: migrate shell/card/dialog/bottom-sheet fills to `ColorScheme.surface`, `surfaceContainer`, `surfaceContainerHigh`, etc., and keep brand colors only for accents/primary.

- [ ] **Unify mobile shell bottom-nav placement**
  - File: `lib/core/widgets/app_shell.dart:156-201`
  - Issue: web uses `Scaffold.bottomNavigationBar`, but mobile uses a custom absolutely-positioned floating nav.
  - Action: move the compact/mobile nav into `Scaffold.bottomNavigationBar` with safe-area padding, matching the web path.

- [ ] **Stop bypassing `ColorScheme` with hard-coded brand fills**
  - Files: `lib/core/theme/app_theme.dart`, `lib/core/widgets/app_shell.dart`
  - Issue: call sites use `AppColors.tangerine/surface0/...` directly for backgrounds and overlays.
  - Action: prefer `Theme.of(context).colorScheme.*` roles in widgets; reserve `AppColors` for brand accents only.

- [ ] **Explicitly map filled/tonal/outlined/text emphasis in theme guidance**
  - File: `lib/core/theme/app_theme.dart`
  - Issue: only filled/outlined/text/icon themes are configured; tonal/elevated are missing as first-class patterns.
  - Action: add tonal/elevated button themes and document when each emphasis level is used.

## P1 — Do in the next design-system pass

- [ ] **Add large-screen supporting pane structure**
  - File: `lib/core/widgets/app_shell.dart:124-153`
  - Issue: wide layout is `rail + content` only. M3 suggests supporting panes for medium+ sizes.
  - Action: define a left-rail region vs content region with distinct surface roles, then add optional pane slot where needed.

- [ ] **Make FAB placement width-aware**
  - File: `lib/core/widgets/app_shell.dart`
  - Issue: no documented FAB strategy by window class.
  - Action: compact => bottom trailing embedded in content area; expanded => rail-adjacent or upper-left primary action region.

- [ ] **Audit custom glass/overlay colors for semantic roles**
  - File: `lib/core/theme/app_theme.dart`, `lib/core/widgets/app_shell.dart:237`
  - Issue: glass overlays use fixed `Colors.white.withAlpha(...)` instead of surface roles with opacity.
  - Action: derive overlays from `surfaceContainerHigh` or `surfaceBright` plus alpha, with contrast checks.

## P2 — Follow-up hygiene

- [ ] **Reduce custom `ThemeExtension` token sprawl**
  - File: `lib/core/theme/app_theme.dart:8-306`
  - Issue: `PetfolioThemeExtension` duplicates many things M3 already encodes in `ColorScheme`.
  - Action: keep extension only for non-tokenized brand tokens (pillar accents, glass tokens), migrate the rest to roles.

- [ ] **Create theme usage guide**
  - New file: `lib/core/theme/M3_USAGE.md`
  - Content: when to use primary/secondary/tertiary, surface vs surfaceContainer, filled vs tonal vs outlined, rail vs bottom bar breakpoints, and FAB placement rules.

- [ ] **Add visual regression checks for shell breakpoints**
  - Target: `lib/core/widgets/app_shell.dart`
  - Action: capture golden shots for compact/medium/expanded shell states to prevent regression after theme refactor.

## File Target Map

| File | Issue(s) |
| --- | --- |
| `lib/core/theme/app_theme.dart` | surface role mapping, button emphasis, theme extension cleanup |
| `lib/core/widgets/app_shell.dart` | nav placement, wide layout, FAB placement, overlay colors |
| `lib/main.dart` | entrypoint is fine; use as reference for clean theme wiring |
| `lib/core/navigation/shell_destinations.dart` | review destinations after layout changes |
