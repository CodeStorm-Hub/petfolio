# SkeletonLoader

Animated shimmer placeholder for loading states. `surface-3` base with a sweeping highlight. Respects `prefers-reduced-motion` (static when active). Compose primitives to match any skeleton layout.

## Named presets (compose from primitives)

```jsx
// Circle (avatar)
<SkeletonLoader shape="circle" width={44} height={44} />

// Full-width image banner
<SkeletonLoader width="full" height={220} borderRadius={12} />

// Text line
<SkeletonLoader width={160} height={13} />

// List-tile skeleton
<div style={{ display: 'flex', gap: 12, padding: '10px 16px', alignItems: 'center' }}>
  <SkeletonLoader shape="circle" width={44} height={44} />
  <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6 }}>
    <SkeletonLoader width="full" height={13} />
    <SkeletonLoader width={120} height={11} />
  </div>
</div>

// Feed-card skeleton
<div style={{ display: 'flex', flexDirection: 'column', gap: 10, padding: '8px 16px' }}>
  <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
    <SkeletonLoader shape="circle" width={36} height={36} />
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <SkeletonLoader width={100} height={12} />
      <SkeletonLoader width={64} height={10} />
    </div>
  </div>
  <SkeletonLoader width="full" height={220} />
  <SkeletonLoader width="full" height={12} />
  <SkeletonLoader width={180} height={12} />
</div>
```

## Tokens used
- `--pf-surface-3` — base fill (`#F2F3F7`)
- `--pf-radius-md` (12px) — default corner radius
