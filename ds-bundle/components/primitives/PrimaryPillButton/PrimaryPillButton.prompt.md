# PrimaryPillButton

Petfolio's core action button. Stadium (pill) shape, 5 variants × 5 sizes. The primary variant has a signature 3D shadow: a hard colored offset + a diffused glow, both in tangerine.

## Sizes

| size   | height | font  | use case                        |
|--------|--------|-------|---------------------------------|
| `sm`   | 36px   | 13px  | inline actions, chips           |
| `md`   | 44px   | 15px  | secondary CTAs                  |
| `lg`   | 52px   | 16px  | **default** — primary CTAs      |
| `xl`   | 60px   | 17px  | hero CTAs, onboarding           |
| `walk` | 64px   | 17px  | sticky bottom walk-through bars |

## Variants

| variant       | use case                                    |
|---------------|---------------------------------------------|
| `primary`     | Main action — tangerine fill + 3D shadow    |
| `secondary`   | Subordinate action — white fill + border    |
| `ghost`       | Tertiary — transparent, tangerine text      |
| `soft`        | Subtle — tangerine-soft fill, no shadow     |
| `destructive` | Delete / danger — poppy fill                |

## Usage

```jsx
// Primary CTA
<PrimaryPillButton label="Adopt Biscuit" onPress={handleAdopt} />

// Full-width onboarding
<PrimaryPillButton label="Get Started" size="xl" isFullWidth />

// With leading icon
<PrimaryPillButton label="Add Pet" leadingIcon={<span>＋</span>} size="md" />

// Secondary action
<PrimaryPillButton label="View Profile" variant="secondary" size="md" />

// Danger
<PrimaryPillButton label="Delete Post" variant="destructive" size="sm" />

// Custom pillar color
<PrimaryPillButton label="Find a Vet" color="var(--pf-mint)" />

// Loading state
<PrimaryPillButton label="Saving…" isLoading />
```

## Tokens used
- `--pf-tangerine` — primary fill
- `--pf-tangerine-700` — shadow hard stop
- `--pf-tangerine-soft` — soft fill
- `--pf-danger` / `--pf-poppy-700` — destructive
- `--pf-radius-pill` — shape
- `--pf-font-display` (Sora w700) — label
