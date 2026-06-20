# Design-sync notes — Petfolio

## Setup
- Shape: `package` (manual bundle — no JS dist; Petfolio is Flutter-native)
- Bundle authored by hand from Flutter source: CSS tokens, self-contained HTML preview cards, `_ds_bundle.js` as a thin IIFE exporting `window.petfolio.*`
- No `@types/react`, no esbuild converter run — previews are self-contained HTML, not compiled `.tsx`
- No playwright render check run (self-contained cards render independently of the bundle)
- Google Fonts (Sora + Inter) loaded via inline `@import` in each card's `<style>` block — not via `extraFonts`; `[FONT_MISSING]` is expected and acceptable here

## Component inventory (2026-06-19)
- **Primitives**: PfCard, GlassCard, PrimaryPillButton, PawToggle
- **Display**: PetAvatar, SectionHeader, PfStatTile, PfBadgeTile, PfDailyQuestRow
- **Feedback**: SkeletonLoader, PetfolioEmptyState, TailWagLoader
- **Foundations** (preview-only, no `.d.ts`): Colors, Typography, Spacing, Shadows

## Re-sync risks
- `_ds_sync.json` is a simplified stub (no `styleSha`/`renderHashes`/`sourceKeys`) — the next re-sync will have no diff anchor and must re-verify all components from scratch
- Card HTML files are self-contained (inline styles + Google Fonts CDN) — any token changes in `tokens/*.css` must be manually mirrored inside each card's `<style>` block too
- `_ds_bundle.js` is hand-authored; `window.petfolio.*` exports are not derived from Flutter source automatically — add new components manually on each re-sync
- Google Fonts CDN dependency: cards require internet access to render with correct typography (Sora, Inter)

## Known render warns
None — render check not run (self-contained cards).
