# PetfolioEmptyState

Centred empty-state panel with icon, title, optional subtitle, and optional CTA. Animates in with a scale + fade + slide entrance (560ms easeOutBack). Use whenever a list or feed has zero items.

## Usage

```jsx
// No pets yet
<PetfolioEmptyState
  icon="🐾"
  title="No pets yet"
  subtitle="Add your first pet to get started with care tracking, matching, and more."
  action={<PrimaryPillButton label="Add a Pet" size="md" />}
/>

// Empty feed
<PetfolioEmptyState
  icon="📸"
  title="Nothing here yet"
  subtitle="Follow other pet owners to see their posts."
/>

// No matches
<PetfolioEmptyState
  icon="💜"
  title="No matches nearby"
  subtitle="Try expanding your search radius or updating your pet's profile."
  action={<PrimaryPillButton label="Adjust Filters" variant="secondary" size="md" />}
/>
```

## Tokens used
- `--pf-ink-300` — icon colour
- `--pf-ink-950` — title colour
- `--pf-ink-700` — subtitle colour
- Padding: 24px vertical + horizontal
