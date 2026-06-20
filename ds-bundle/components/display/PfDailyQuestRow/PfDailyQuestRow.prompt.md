# PfDailyQuestRow

Quest / care task row for the home screen's "Today's Tasks" preview. 42×42 icon box, bold label, time string, and a pill XP chip trailing right.

## States

| prop    | visual change                                                        |
|---------|----------------------------------------------------------------------|
| default | cream2 icon box, ink label, ink-500 time, sunny XP chip             |
| `done`  | mint-soft box, ✅ emoji, strikethrough label, mint XP chip           |
| `due`   | poppy-soft box, "Due {time}" in poppy-700, otherwise same as default |

## Usage

```jsx
<PfDailyQuestRow icon="💊" label="Morning medication" time="8:00 AM" xp={15} />
<PfDailyQuestRow icon="🦮" label="Walk Biscuit"       time="5:30 PM" xp={30} done />
<PfDailyQuestRow icon="🛁" label="Bath time"          time="7:00 PM" xp={20} due />
```

## Tokens used
- `--pf-cream2` / `--pf-mint-soft` / `--pf-poppy-soft` — icon box fill
- `--pf-sunny-soft` / `--pf-mint-soft` — XP chip fill
- `--pf-sunny-700` / `--pf-mint-700` — XP chip text
- `--pf-poppy-700` — overdue time text
