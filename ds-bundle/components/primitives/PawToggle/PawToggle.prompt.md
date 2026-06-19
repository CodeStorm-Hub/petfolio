# PawToggle

Branded toggle switch with a 🐾 paw thumb and spring-overshoot slide animation. 56×32px track, tangerine active fill, easeOutBack slide curve.

## Usage

```jsx
// Controlled toggle
const [active, setActive] = React.useState(false);
<PawToggle value={active} onChanged={setActive} semanticLabel="Enable notifications" />

// Pillar-colored
<PawToggle value={true} activeColor="var(--pf-mint)" semanticLabel="Health tracking on" />

// Read-only display (no onChanged)
<PawToggle value={true} />
```

## Tokens used
- `--pf-tangerine` — default active track
- `--pf-radius-pill` — track shape
