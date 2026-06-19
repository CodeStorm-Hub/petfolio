# Petfolio Design System — Agent Conventions

## Setup and wrapping

No root provider or theme wrapper required. Components are available directly from `window.petfolio.*` after `_ds_bundle.js` loads. All styling is driven by CSS custom properties defined in `styles.css` (and its imports). Light mode is the default; apply `data-theme="dark"` to `<html>` or any ancestor for dark mode.

Load order: `styles.css` → `_ds_bundle.js` → mount components.

```html
<link rel="stylesheet" href="styles.css">
<script src="_ds_bundle.js"></script>
```

## Styling idiom — CSS custom properties

All design decisions are expressed as `var(--pf-*)` tokens. Never hardcode hex values; always reference a token. The full token vocabulary is in `tokens/colors.css`, `tokens/typography.css`, `tokens/spacing.css`, and `tokens/shadows.css`.

**Key token families:**

| family | examples |
|---|---|
| Pillar accents | `--pf-tangerine`, `--pf-poppy`, `--pf-mint`, `--pf-sunny`, `--pf-lilac`, `--pf-sky` |
| Soft fills | `--pf-tangerine-soft`, `--pf-mint-soft`, `--pf-lilac-soft` (light tinted backgrounds) |
| Ink / text | `--pf-ink-950` (headings), `--pf-ink-700` (body), `--pf-ink-500` (muted), `--pf-ink-300` (placeholder) |
| Surfaces | `--pf-surface-0` (#fff), `--pf-surface-1` (cream), `--pf-surface-2`, `--pf-surface-3` |
| Lines | `--pf-line` (#F4E2CB warm border), `--pf-line2` (slightly darker) |
| Radius | `--pf-radius-sm/md/lg/xl/2xl/3xl/pill`, `--pf-squircle-card` (24px) |
| Spacing | `--pf-space-xs/sm/md/lg/xl/2xl/3xl` (4→64px) |
| Shadows | `--pf-shadow-e1` through `--pf-shadow-e4`, `--pf-shadow-glass` |
| Typography | `--pf-font-display` (Sora), `--pf-font-sans` (Inter) |

**For layout glue** (dividers, gaps, padding) use spacing tokens. For component fills, always pick from the pillar or surface palette.

## Where the truth lives

- **Token reference**: read `styles.css` and its `@import` chain before writing any colour, spacing, or shadow value.
- **Component API**: each component folder has a `<Name>.prompt.md` with props table, state guide, and usage snippets.
- **Component CSS classes**: defined in `_ds_bundle.css` — `pf-card`, `pf-btn`, `pf-avatar`, etc.

## Idiomatic build example

```jsx
// Pet profile card — uses PfCard + PetAvatar + PrimaryPillButton + SectionHeader
function PetProfileCard({ pet }) {
  return (
    <div style={{ background: 'var(--pf-surface-1)', minHeight: '100vh' }}>
      <SectionHeader label="Your Pets" action={<span style={{ color: 'var(--pf-tangerine)', fontSize: 13, fontWeight: 600 }}>Edit</span>} />
      <div style={{ padding: '0 var(--pf-space-md)' }}>
        <PfCard elevated padding={16}>
          <div style={{ display: 'flex', gap: 'var(--pf-space-md)', alignItems: 'center' }}>
            <PetAvatar species="dog" size="xl" showRing />
            <div>
              <div style={{ fontFamily: 'var(--pf-font-display)', fontSize: 20, fontWeight: 700, color: 'var(--pf-ink-950)' }}>Biscuit</div>
              <div style={{ fontSize: 14, color: 'var(--pf-ink-500)', marginTop: 2 }}>Golden Retriever · 3 yrs</div>
            </div>
          </div>
          <div style={{ marginTop: 'var(--pf-space-md)' }}>
            <PrimaryPillButton label="View Care Routine" isFullWidth />
          </div>
        </PfCard>
      </div>
    </div>
  );
}
```
