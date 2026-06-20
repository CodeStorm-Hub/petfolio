# PfBadgeTile

Achievement badge tile for the trophy room. Owned badges show a diagonal gradient fill + glow shadow. Locked badges render greyscale + 45% opacity using a CSS `grayscale` filter.

## Usage

```jsx
// Grid of badges
<div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
  <PfBadgeTile emoji="🔥" label="3-Day Streak"  color="#FF9800" owned />
  <PfBadgeTile emoji="🏆" label="7-Day Hero"    color="#FFCC00" owned />
  <PfBadgeTile emoji="👑" label="30-Day Legend" color="#D4AF37" owned={false} />
  <PfBadgeTile emoji="💎" label="Care Champion" color="#2196F3" owned={false} />
</div>
```

## Badge color guide (from AppColors)

| badge       | color     |
|-------------|-----------|
| First log   | `#4CAF50` |
| 3-day       | `#FF9800` |
| 7-day       | `#FFCC00` |
| 30-day      | `#D4AF37` |
| Care champ  | `#2196F3` |
| Social star | `#E91E63` |
| Match maker | `#7B61FF` |
