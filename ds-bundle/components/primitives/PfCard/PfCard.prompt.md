# PfCard

Surface container for grouping related content. Uses the Petfolio warm-cream brand feel: `surface-0` (#FFF) background, warm `line` border (`#F4E2CB`), and squircle-card radius (24px) — the M3 Expressive superellipse shape used throughout the app.

## When to use
- Any time content needs a raised, bordered surface: pet profile cards, product cards, feed posts, settings panels.
- Use `elevated` for cards that need more visual lift (modals, overlays).
- Use `flat` for cards embedded inside another card or tinted section.

## Usage

```jsx
<PfCard padding={16}>
  <p>Basic card content</p>
</PfCard>

// Elevated (e2 shadow)
<PfCard elevated padding={20}>
  <h3>Pet Profile</h3>
</PfCard>

// Flat / borderless variant inside a tinted section
<PfCard flat borderRadius={16} backgroundColor="var(--pf-tangerine-soft)">
  <span>Soft tinted panel</span>
</PfCard>

// Custom radius
<PfCard borderRadius={12} padding="12px 16px">
  <span>Tighter card</span>
</PfCard>
```

## Tokens used
- `--pf-surface-0` — background
- `--pf-line` — border (`#F4E2CB`)
- `--pf-squircle-card` (24px) — default border-radius
- `--pf-shadow-e1`, `--pf-shadow-e2` — elevation levels
