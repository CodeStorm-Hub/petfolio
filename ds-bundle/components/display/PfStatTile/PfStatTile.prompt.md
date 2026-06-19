# PfStatTile

Compact coloured stat tile: icon (top-left), large numeric value, small bold label. Used in the home screen quick-stats trio and care dashboard. 22px border-radius, 14px vertical / 12px horizontal padding.

## Usage

```jsx
// Standard trio — use pillar soft fills as backgroundColor
<div style={{ display: 'flex', gap: 12 }}>
  <PfStatTile
    icon={<span>🐾</span>}
    value="3"
    label="Pets"
    backgroundColor="var(--pf-tangerine-soft)"
    textColor="var(--pf-tangerine-700)"
  />
  <PfStatTile
    icon={<span>🔥</span>}
    value="7"
    label="Day streak"
    backgroundColor="var(--pf-sunny-soft)"
    textColor="var(--pf-sunny-700)"
  />
  <PfStatTile
    icon={<span>💜</span>}
    value="12"
    label="Matches"
    backgroundColor="var(--pf-lilac-soft)"
    textColor="var(--pf-lilac-700)"
  />
</div>
```

## Pillar pairings

| pillar   | backgroundColor           | textColor               |
|----------|---------------------------|-------------------------|
| Pets     | `--pf-tangerine-soft`     | `--pf-tangerine-700`    |
| Care     | `--pf-sunny-soft`         | `--pf-sunny-700`        |
| Social   | `--pf-poppy-soft`         | `--pf-poppy-700`        |
| Match    | `--pf-lilac-soft`         | `--pf-lilac-700`        |
| Health   | `--pf-mint-soft`          | `--pf-mint-700`         |
| Market   | `--pf-sky-soft`           | `--pf-sky-700`          |
