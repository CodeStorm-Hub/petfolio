# Petfolio Design System — Agent Conventions

## Setup and wrapping

No root provider or theme wrapper required. Components are available directly from `window.petfolio.*` after `_ds_bundle.js` loads. All styling is driven by CSS custom properties defined in `styles.css` (and its imports). Light mode is the default; apply `data-theme="dark"` to `<html>` or any ancestor for dark mode.

Load order: `styles.css` → `_ds_bundle.js` → mount components.

## Styling idiom — CSS custom properties

All design decisions are expressed as `var(--pf-*)` tokens. Never hardcode hex values; always reference a token.

**Key token families:**

| family | examples |
|---|---|
| Pillar accents | `--pf-tangerine`, `--pf-poppy`, `--pf-mint`, `--pf-sunny`, `--pf-lilac`, `--pf-sky` |
| Soft fills | `--pf-tangerine-soft`, `--pf-mint-soft`, `--pf-lilac-soft` |
| Ink / text | `--pf-ink-950` (headings), `--pf-ink-700` (body), `--pf-ink-500` (muted), `--pf-ink-300` (placeholder) |
| Surfaces | `--pf-surface-0` (#fff), `--pf-surface-1` (cream), `--pf-surface-2`, `--pf-surface-3` |
| Lines | `--pf-line` (#F4E2CB warm border), `--pf-line2` |
| Radius | `--pf-radius-sm/md/lg/xl/2xl/3xl/pill`, `--pf-squircle-card` (24px) |
| Spacing | `--pf-space-xs/sm/md/lg/xl/2xl/3xl` (4→64px) |
| Shadows | `--pf-shadow-e1` through `--pf-shadow-e4`, `--pf-shadow-glass` |
| Fonts | `--pf-font-display` (Sora, headings), `--pf-font-sans` (Inter, body) |

## Where the truth lives

- Token definitions: `styles.css` transitive imports (`tokens/colors.css`, `tokens/typography.css`, `tokens/spacing.css`, `tokens/shadows.css`)
- Component API: each `components/<group>/<Name>/<Name>.prompt.md`
- Component CSS: `_ds_bundle.css` — class names are `pf-card`, `pf-btn`, `pf-avatar`, etc.

## Components

### Foundations
| Name | Group | Description |
|---|---|---|
| Colors | Foundations | Full warm-brand palette — pillar, ink, surface, semantic, glass |
| Typography | Foundations | Sora (display/headline/title) + Inter (body/label) type scale |
| Spacing | Foundations | 4–96px spacing scale + xs–pill radius tokens |
| Shadows | Foundations | e1–e4 elevation levels + 3D button shadow + glass shadow |

### Primitives
| Name | Group | Description |
|---|---|---|
| PfCard | Primitives | Squircle surface container, 3 elevation modes |
| GlassCard | Primitives | Glassmorphism card — blur + fill + specular highlight |
| PrimaryPillButton | Primitives | 5 variants × 5 sizes, 3D tangerine shadow, loading state |
| PawToggle | Primitives | Branded 🐾 toggle, spring-overshoot animation |

### Display
| Name | Group | Description |
|---|---|---|
| PetAvatar | Display | Circular avatar — 5 sizes, species discs, status dot, rainbow ring |
| SectionHeader | Display | All-caps caps-label with optional trailing action |
| PfStatTile | Display | Coloured stat tile — icon + large value + label |
| PfBadgeTile | Display | Achievement badge — owned (gradient glow) or locked (greyscale) |
| PfDailyQuestRow | Display | Quest row — default / done / overdue states + XP chip |

### Feedback
| Name | Group | Description |
|---|---|---|
| SkeletonLoader | Feedback | Shimmer placeholder — rect, circle, composable presets |
| PetfolioEmptyState | Feedback | Centred empty state — icon + title + subtitle + optional CTA |
| TailWagLoader | Feedback | Branded SVG dog loader with wagging tail animation |

## Idiomatic build example

```jsx
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
