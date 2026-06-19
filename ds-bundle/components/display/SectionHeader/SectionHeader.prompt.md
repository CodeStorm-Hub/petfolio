# SectionHeader

All-caps section label — 11px Inter Bold, 0.8px tracking, `ink-500`. Built-in padding: 24px top, 16px sides, 8px bottom. Optionally shows a trailing action (e.g. "See all" link).

## Usage

```jsx
// Simple label
<SectionHeader label="Your Pets" />

// With trailing action
<SectionHeader
  label="Recent Activity"
  action={<PrimaryPillButton label="See all" variant="ghost" size="sm" />}
/>

// Inside a feed section
<SectionHeader label="Nearby Matches" action={<span style={{ color: 'var(--pf-tangerine)', fontSize: 13 }}>Filter</span>} />
```

## Tokens used
- `--pf-ink-500` — label colour (`#957762`)
- `--pf-text-caps-*` — 11px / w700 / 0.8px tracking
- `--pf-space-lg` (24px) top · `--pf-space-md` (16px) sides · `--pf-space-sm` (8px) bottom
