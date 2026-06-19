# GlassCard

Glassmorphism container: frosted-glass fill + backdrop blur + top specular highlight + gradient rim border. Per spec §4.1, place only over a photographic image, a solid neutral surface, or a scrim of ≥35% opacity.

## When to use
- Hero sections with a pet photo background.
- Floating overlays (match cards, location badges).
- Stats / quick-action panels over the map or camera feed.

**Do not** use over plain `surface-0` — there is nothing to blur and the card looks flat. Use `PfCard` instead.

## Usage

```jsx
// Over a photo background
<div style={{ position: 'relative' }}>
  <img src={petPhoto} style={{ width: '100%', height: 220, objectFit: 'cover', borderRadius: 24 }} />
  <GlassCard style={{ position: 'absolute', bottom: 12, left: 12, right: 12 }}>
    <h3>Biscuit — 3 yrs</h3>
    <p>Golden Retriever · Sydney</p>
  </GlassCard>
</div>

// Floating badge
<GlassCard borderRadius={12} padding={10}>
  <span>📍 2.4 km away</span>
</GlassCard>
```

## Tokens used
- `--pf-glass-fill` — `rgba(255,255,255,.62)` light / `rgba(42,24,32,.55)` dark
- `--pf-glass-blur` — `24px` light / `28px` dark
- `--pf-glass-top-border` — specular top rim
- `--pf-shadow-glass` — ambient diffusion shadow
