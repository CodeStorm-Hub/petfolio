# PetAvatar

Circular pet avatar. Shows a photo (with skeleton loader placeholder while loading) or a species-coloured emoji disc. Supports status dot, rainbow ring, and five sizes.

## Sizes

| size  | dp   | use case                         |
|-------|------|----------------------------------|
| `sm`  | 32px | dense lists, comment threads     |
| `md`  | 40px | feed cards, nav items (**default**) |
| `lg`  | 48px | profile headers                  |
| `xl`  | 56px | match cards, expanded tiles      |
| `xxl` | 72px | hero profile, onboarding         |

## Species disc colors (fallback when no image)

| species  | gradient                        |
|----------|---------------------------------|
| `dog`    | tangerine-soft → tangerine      |
| `cat`    | lilac-soft → lilac              |
| `bird`   | sky-soft → sky                  |
| `rabbit` | mint-soft → mint                |
| `other`  | sunny-soft → sunny              |

## Usage

```jsx
// Photo avatar, medium
<PetAvatar imageUrl={pet.photoUrl} species="dog" size="md" semanticLabel="Biscuit's avatar" />

// Species emoji disc, large, online
<PetAvatar species="cat" size="lg" isOnline={true} />

// Initials fallback
<PetAvatar initials="BK" species="dog" size="xl" />

// Rainbow ring (social / story highlight)
<PetAvatar imageUrl={pet.photoUrl} size="xxl" showRing />

// Solid pillar-coloured ring
<PetAvatar imageUrl={pet.photoUrl} size="lg" borderColor="var(--pf-mint)" />
```

## Tokens used
- Species gradient fills from `--pf-*-soft` and `--pf-*` pairs
- `--pf-mint` / `--pf-ink-300` — online / offline status dot
- Rainbow: `--pf-tangerine`, `--pf-poppy`, `--pf-sunny`, `--pf-mint`
