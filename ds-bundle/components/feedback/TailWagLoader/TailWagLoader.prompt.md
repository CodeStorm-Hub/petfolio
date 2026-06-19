# TailWagLoader

Petfolio's branded full-screen / section loading indicator. Renders an SVG cartoon dog whose tail wags on a 500ms alternating CSS animation. Use instead of a generic spinner whenever context allows personality.

## Usage

```jsx
// Default — tangerine dog, no label
<TailWagLoader />

// With label
<TailWagLoader label="Finding matches…" />

// Pillar-coloured
<TailWagLoader color="var(--pf-mint)" label="Checking health records…" />
<TailWagLoader color="var(--pf-lilac)" label="Loading matches…" />

// Large hero loader
<TailWagLoader size={96} label="Setting up your profile…" />

// Centred in a screen
<div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 1, minHeight: 300 }}>
  <TailWagLoader label="Loading feed…" />
</div>
```

## Tokens used
- `--pf-tangerine` — default dog colour
- Label: 13px Inter Bold, 0.3px tracking, same colour as dog
