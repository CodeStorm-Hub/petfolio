// Daily Pet Care & Health Dashboard
// - 7-day gamified streak banner (feed / walk / med per day)
// - Clinical vitals: weight + Body Condition Score line chart
// - Designed for outdoor legibility: high contrast text, thick strokes,
//   solid surfaces (no glass), generous touch targets.

function HealthDashboard({ active, onBack, onOpenSwitcher, outdoor, onOutdoor, onTab }) {
  const [metric, setMetric] = React.useState('weight'); // 'weight' | 'bcs'
  const week = WEEK_DATA[active.id] || WEEK_DATA.luna;
  const vitals = VITAL_DATA[active.id] || VITAL_DATA.luna;
  const todayIdx = 4; // Friday — current day in the demo data

  const bg = outdoor ? '#FFFFFF' : TOKENS.surface1;
  const cardBg = outdoor ? '#FFFFFF' : TOKENS.surface0;
  const strokeMul = outdoor ? 1.35 : 1;

  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      background: bg,
      fontFamily: 'Inter, system-ui, sans-serif',
      color: TOKENS.ink950,
    }}>
      <HealthHeader active={active} onBack={onBack} onOpenSwitcher={onOpenSwitcher}
                    outdoor={outdoor} onOutdoor={onOutdoor} />

      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 100px', display: 'flex', flexDirection: 'column', gap: 18 }}>
        <StreakBanner week={week} todayIdx={todayIdx} active={active} outdoor={outdoor} strokeMul={strokeMul} cardBg={cardBg}/>
        <TodayTasks week={week} todayIdx={todayIdx} active={active} cardBg={cardBg}/>

        <SectionLabel2 outdoor={outdoor}>Clinical Vitals</SectionLabel2>

        <VitalsTabs metric={metric} setMetric={setMetric} active={active} vitals={vitals} cardBg={cardBg}/>
        <VitalsChart metric={metric} vitals={vitals} active={active} outdoor={outdoor} strokeMul={strokeMul} cardBg={cardBg}/>
        <NextCheckup active={active} cardBg={cardBg}/>
      </div>

      <TabBarHealth onTab={onTab}/>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// Header
// ────────────────────────────────────────────────────────────────
function HealthHeader({ active, onBack, onOpenSwitcher, outdoor, onOutdoor }) {
  return (
    <div style={{
      padding: '58px 16px 12px', display: 'flex', alignItems: 'center', gap: 12,
    }}>
      <button onClick={onBack} aria-label="Back" style={{
        width: 44, height: 44, borderRadius: '50%', border: 'none', cursor: 'pointer',
        background: outdoor ? TOKENS.surface0 : TOKENS.surface0, color: TOKENS.ink700,
        boxShadow: '0 1px 2px rgba(11,18,32,0.06), 0 0 0 0.5px ' + TOKENS.line200,
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
      }}>
        <svg width="10" height="18" viewBox="0 0 10 18">
          <path d="M9 1L1 9l8 8" stroke={TOKENS.ink700} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </button>
      <button onClick={onOpenSwitcher} style={{
        flex: 1, display: 'flex', alignItems: 'center', gap: 10,
        background: 'transparent', border: 'none', padding: 0, cursor: 'pointer',
        textAlign: 'left',
      }}>
        <PetAvatar pet={active} size={36} ring={`linear-gradient(135deg, ${active.accent}, ${lighten(active.accent, 0.3)})`}/>
        <div style={{ minWidth: 0 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: TOKENS.ink500 }}>
            Health · {active.name}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <span style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 18, color: TOKENS.ink950, letterSpacing: '-0.01em' }}>
              {active.breed}
            </span>
            <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
              <path d="M3 6l5 5 5-5" stroke={TOKENS.ink500} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </div>
      </button>
      <button onClick={onOutdoor} aria-label="Outdoor mode" style={{
        width: 44, height: 44, borderRadius: '50%', border: 'none', cursor: 'pointer',
        background: outdoor ? TOKENS.ink950 : TOKENS.surface0,
        color: outdoor ? '#fff' : TOKENS.ink700,
        boxShadow: '0 1px 2px rgba(11,18,32,0.06), 0 0 0 0.5px ' + TOKENS.line200,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
          <circle cx="9" cy="9" r="3.5" stroke="currentColor" strokeWidth="1.75"/>
          <g stroke="currentColor" strokeWidth="1.75" strokeLinecap="round">
            <path d="M9 1.5v2M9 14.5v2M1.5 9h2M14.5 9h2M3.7 3.7l1.4 1.4M12.9 12.9l1.4 1.4M3.7 14.3l1.4-1.4M12.9 5.1l1.4-1.4"/>
          </g>
        </svg>
      </button>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// Streak Banner
// ────────────────────────────────────────────────────────────────
function StreakBanner({ week, todayIdx, active, outdoor, strokeMul, cardBg }) {
  const dayLabels = ['M','T','W','T','F','S','S'];
  const completedDays = week.filter((d, i) => i < todayIdx && d.feed && d.walk && d.med).length;
  const todayCount = week[todayIdx] ? [week[todayIdx].feed, week[todayIdx].walk, week[todayIdx].med].filter(Boolean).length : 0;

  return (
    <div style={{
      borderRadius: 24, overflow: 'hidden', position: 'relative',
      background: `linear-gradient(135deg, ${active.accent} 0%, ${darken(active.accent, 0.22)} 100%)`,
      padding: '18px 18px 20px',
      boxShadow: outdoor ? 'none' : '0 18px 36px -16px ' + active.accent + '88',
      color: '#fff',
    }}>
      <div style={{
        position: 'absolute', top: -50, right: -40, width: 220, height: 220, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(255,255,255,0.18) 0%, transparent 65%)',
      }}/>

      <div style={{ position: 'relative', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 14, marginBottom: 14 }}>
        <div>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', opacity: 0.9 }}>
            Care streak
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
            <span style={{ fontFamily: 'Sora', fontSize: 48, fontWeight: 700, letterSpacing: '-0.03em', lineHeight: 1 }}>
              {active.healthStreak}
            </span>
            <span style={{ fontSize: 14, opacity: 0.9 }}>days</span>
          </div>
        </div>
        <div style={{
          background: 'rgba(255,255,255,0.18)', padding: '8px 12px', borderRadius: 14,
          backdropFilter: outdoor ? 'none' : 'blur(8px)', WebkitBackdropFilter: outdoor ? 'none' : 'blur(8px)',
          textAlign: 'right',
        }}>
          <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', opacity: 0.85 }}>Today</div>
          <div style={{ fontFamily: 'Sora', fontSize: 20, fontWeight: 700, lineHeight: 1.1 }}>{todayCount} / 3</div>
        </div>
      </div>

      <div style={{ position: 'relative', display: 'flex', gap: 8, justifyContent: 'space-between' }}>
        {week.map((d, i) => (
          <DayCell key={i} day={d} label={dayLabels[i]} isToday={i === todayIdx} isPast={i < todayIdx} isFuture={i > todayIdx} strokeMul={strokeMul}/>
        ))}
      </div>

      <div style={{ position: 'relative', marginTop: 14, display: 'flex', gap: 12, fontSize: 11, fontWeight: 500, opacity: 0.95 }}>
        <LegendDot icon="feed" label="Feed"/>
        <LegendDot icon="walk" label="Walk"/>
        <LegendDot icon="med" label="Meds"/>
      </div>
    </div>
  );
}

function DayCell({ day, label, isToday, isPast, isFuture, strokeMul }) {
  // Track which tasks done: 3-segment ring around the day
  const segments = [
    { done: day.feed, icon: 'feed' },
    { done: day.walk, icon: 'walk' },
    { done: day.med,  icon: 'med' },
  ];
  const allDone = segments.every(s => s.done);

  return (
    <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
      <div style={{
        width: 38, height: 60, borderRadius: 14,
        background: isFuture ? 'rgba(255,255,255,0.10)' : (allDone ? '#fff' : 'rgba(255,255,255,0.22)'),
        boxShadow: isToday ? '0 0 0 2px #fff, 0 4px 14px -4px rgba(0,0,0,0.3)' : 'none',
        padding: 5, display: 'flex', flexDirection: 'column', gap: 3, position: 'relative',
      }}>
        {segments.map((s, i) => (
          <div key={i} style={{
            flex: 1, borderRadius: 5, position: 'relative',
            background: s.done
              ? (allDone ? 'rgba(0,0,0,0.04)' : 'rgba(255,255,255,0.95)')
              : (isFuture ? 'transparent' : 'rgba(255,255,255,0.12)'),
            border: !s.done && !isFuture ? '1px dashed rgba(255,255,255,0.28)' : 'none',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {s.done && (
              <TaskGlyph icon={s.icon} color={allDone ? '#0B1220' : '#0B1220'} size={11} strokeMul={strokeMul}/>
            )}
          </div>
        ))}
      </div>
      <div style={{
        fontSize: 11, fontWeight: 700, letterSpacing: '0.04em',
        color: isToday ? '#fff' : 'rgba(255,255,255,0.7)',
        fontFamily: 'Sora',
      }}>{label}</div>
    </div>
  );
}

function TaskGlyph({ icon, color, size = 12, strokeMul = 1 }) {
  const sw = 1.8 * strokeMul;
  if (icon === 'feed') return (
    <svg width={size} height={size} viewBox="0 0 14 14" fill="none">
      <path d="M3 2v10M3 2c0 0-1 1-1 3s1 3 1 3M3 8h0M10.5 2v4c0 1 .5 2 .5 2v4M9.5 2v4" stroke={color} strokeWidth={sw} strokeLinecap="round"/>
    </svg>
  );
  if (icon === 'walk') return (
    <svg width={size} height={size} viewBox="0 0 14 14" fill="none" stroke={color} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
      <circle cx="9" cy="2.5" r="1.3"/>
      <path d="M7.5 5l-2 3.5 2 1.4-.5 3.6M9 8l2 1.4-1.3 2.6"/>
    </svg>
  );
  if (icon === 'med') return (
    <svg width={size} height={size} viewBox="0 0 14 14" fill="none">
      <rect x="1" y="5" width="12" height="4" rx="2" stroke={color} strokeWidth={sw} transform="rotate(-30 7 7)"/>
      <path d="M4.5 3.5l5 5" stroke={color} strokeWidth={sw}/>
    </svg>
  );
  return null;
}

function LegendDot({ icon, label }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
      <div style={{
        width: 18, height: 18, borderRadius: 5,
        background: 'rgba(255,255,255,0.95)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <TaskGlyph icon={icon} color="#0B1220" size={11}/>
      </div>
      {label}
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// Today's tasks (quick toggle)
// ────────────────────────────────────────────────────────────────
function TodayTasks({ week, todayIdx, active, cardBg }) {
  const today = week[todayIdx];
  const tasks = [
    { id: 'feed',  label: 'Morning meal',  sub: '07:30 · 280 g kibble',     done: today.feed, icon: 'feed' },
    { id: 'walk',  label: 'Morning walk',  sub: '08:10 · 28 min · 2.1 km',  done: today.walk, icon: 'walk' },
    { id: 'med',   label: 'Heartworm tablet', sub: '09:00 · monthly',       done: today.med,  icon: 'med'  },
  ];
  return (
    <div style={{
      background: cardBg, borderRadius: 20, padding: '6px 6px',
      boxShadow: '0 0 0 0.5px ' + TOKENS.line200 + ', 0 1px 2px rgba(11,18,32,0.04)',
    }}>
      {tasks.map((t, i) => (
        <div key={t.id} style={{
          display: 'flex', alignItems: 'center', gap: 12, padding: '10px 12px',
          borderBottom: i < tasks.length - 1 ? '0.5px solid ' + TOKENS.line100 : 'none',
        }}>
          <div style={{
            width: 40, height: 40, borderRadius: 12,
            background: t.done ? TOKENS.meadowT : TOKENS.surface2,
            color: t.done ? TOKENS.meadow : TOKENS.ink500,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
          }}>
            <TaskGlyph icon={t.icon} color={t.done ? TOKENS.meadow : TOKENS.ink500} size={20} strokeMul={1.2}/>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{
              fontFamily: 'Sora', fontWeight: 600, fontSize: 15, color: TOKENS.ink950,
              textDecoration: t.done ? 'line-through' : 'none', opacity: t.done ? 0.55 : 1,
            }}>{t.label}</div>
            <div style={{ fontSize: 12, color: TOKENS.ink500 }}>{t.sub}</div>
          </div>
          <button aria-label={t.done ? 'Mark undone' : 'Mark done'} style={{
            width: 36, height: 36, borderRadius: '50%', border: 'none', cursor: 'pointer',
            background: t.done ? TOKENS.success : 'transparent',
            boxShadow: t.done ? 'none' : 'inset 0 0 0 2px ' + TOKENS.ink300,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {t.done && (
              <svg width="16" height="16" viewBox="0 0 16 16">
                <path d="M3 8.5l3.5 3.5L13 5" stroke="#fff" strokeWidth="2.4" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
            )}
          </button>
        </div>
      ))}
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// Vitals tabs (Weight / BCS)
// ────────────────────────────────────────────────────────────────
function VitalsTabs({ metric, setMetric, vitals, active, cardBg }) {
  const w = vitals.weight[vitals.weight.length - 1];
  const wPrev = vitals.weight[vitals.weight.length - 2];
  const bcs = vitals.bcs[vitals.bcs.length - 1];
  const dW = (w - wPrev).toFixed(1);
  const dWStr = (dW > 0 ? '+' : '') + dW;
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
      <button onClick={() => setMetric('weight')} style={vitalTabStyle(metric === 'weight', cardBg)}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: TOKENS.ink500 }}>Weight</span>
          <TrendPill delta={dW} unit="kg"/>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 8 }}>
          <span style={{ fontFamily: 'Sora', fontSize: 30, fontWeight: 700, letterSpacing: '-0.02em', color: TOKENS.ink950, fontVariantNumeric: 'tabular-nums' }}>{w.toFixed(1)}</span>
          <span style={{ fontSize: 14, color: TOKENS.ink500 }}>kg</span>
        </div>
        <Sparkline data={vitals.weight} color={metric === 'weight' ? active.accent : TOKENS.ink300}/>
      </button>
      <button onClick={() => setMetric('bcs')} style={vitalTabStyle(metric === 'bcs', cardBg)}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: TOKENS.ink500 }}>BCS</span>
          <BcsStatus bcs={bcs}/>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 8 }}>
          <span style={{ fontFamily: 'Sora', fontSize: 30, fontWeight: 700, letterSpacing: '-0.02em', color: TOKENS.ink950, fontVariantNumeric: 'tabular-nums' }}>{bcs}</span>
          <span style={{ fontSize: 14, color: TOKENS.ink500 }}>/ 9</span>
        </div>
        <Sparkline data={vitals.bcs} color={metric === 'bcs' ? active.accent : TOKENS.ink300} max={9} min={1}/>
      </button>
    </div>
  );
}

function vitalTabStyle(selected, cardBg) {
  return {
    background: cardBg, border: 'none', cursor: 'pointer',
    textAlign: 'left', padding: '14px 14px 10px',
    borderRadius: 18,
    boxShadow: selected
      ? '0 0 0 2px ' + TOKENS.blue500 + ', 0 4px 12px -4px ' + TOKENS.blue500 + '55'
      : '0 0 0 0.5px ' + TOKENS.line200 + ', 0 1px 2px rgba(11,18,32,0.04)',
    display: 'flex', flexDirection: 'column', gap: 0,
    fontFamily: 'Inter',
  };
}

function TrendPill({ delta, unit }) {
  const positive = delta > 0;
  const neutral = Math.abs(delta) < 0.05;
  const c = neutral ? TOKENS.ink500 : (positive ? TOKENS.warning : TOKENS.success);
  const bg = neutral ? TOKENS.surface2 : (positive ? '#FBE7D0' : TOKENS.meadowT);
  const str = (delta > 0 ? '+' : '') + delta + ' ' + unit;
  return (
    <span style={{
      fontSize: 11, fontWeight: 700, padding: '3px 7px', borderRadius: 999,
      color: c, background: bg, fontVariantNumeric: 'tabular-nums',
    }}>{str}</span>
  );
}

function BcsStatus({ bcs }) {
  const ideal = bcs >= 4 && bcs <= 5;
  const c = ideal ? TOKENS.success : TOKENS.warning;
  const bg = ideal ? TOKENS.meadowT : '#FBE7D0';
  return (
    <span style={{
      fontSize: 11, fontWeight: 700, padding: '3px 7px', borderRadius: 999,
      color: c, background: bg,
    }}>{ideal ? 'Ideal' : (bcs < 4 ? 'Lean' : 'Overweight')}</span>
  );
}

function Sparkline({ data, color, min, max }) {
  const w = 130, h = 30;
  const lo = min != null ? min : Math.min(...data) - 0.5;
  const hi = max != null ? max : Math.max(...data) + 0.5;
  const pts = data.map((v, i) => {
    const x = (i / (data.length - 1)) * w;
    const y = h - ((v - lo) / (hi - lo)) * h;
    return `${x.toFixed(1)},${y.toFixed(1)}`;
  }).join(' ');
  return (
    <svg width="100%" height={h} viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" style={{ marginTop: 8, display: 'block' }}>
      <polyline points={pts} fill="none" stroke={color} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

// ────────────────────────────────────────────────────────────────
// Big vitals chart
// ────────────────────────────────────────────────────────────────
function VitalsChart({ metric, vitals, active, outdoor, strokeMul, cardBg }) {
  const W = 340, H = 200;
  const PAD = { l: 36, r: 14, t: 18, b: 26 };
  const innerW = W - PAD.l - PAD.r;
  const innerH = H - PAD.t - PAD.b;

  const data = metric === 'weight' ? vitals.weight : vitals.bcs;
  const labels = vitals.labels;
  const isWeight = metric === 'weight';

  const lo = isWeight ? Math.min(...data) - 1 : 1;
  const hi = isWeight ? Math.max(...data) + 1 : 9;
  const range = hi - lo;
  const yTicks = isWeight ? 4 : 4;

  const xAt = (i) => PAD.l + (i / (data.length - 1)) * innerW;
  const yAt = (v) => PAD.t + innerH - ((v - lo) / range) * innerH;
  const linePts = data.map((v, i) => `${xAt(i)},${yAt(v)}`).join(' ');
  const areaPts = `${PAD.l},${PAD.t + innerH} ${linePts} ${PAD.l + innerW},${PAD.t + innerH}`;

  // BCS ideal zone (4-5)
  const bcsIdealTop = yAt(5);
  const bcsIdealBot = yAt(4);

  // Target zone for weight (ideal range ±5%)
  const wIdealMid = isWeight ? (active.id === 'mochi' ? 5.4 : (active.id === 'hopper' ? 1.8 : 19.5)) : null;
  const wIdealLo  = isWeight ? wIdealMid * 0.97 : null;
  const wIdealHi  = isWeight ? wIdealMid * 1.03 : null;

  const last = data.length - 1;
  const stroke = active.accent;

  return (
    <div style={{
      background: cardBg, borderRadius: 20, padding: '16px 14px 8px',
      boxShadow: '0 0 0 0.5px ' + TOKENS.line200 + ', 0 1px 2px rgba(11,18,32,0.04)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 4px 8px' }}>
        <div>
          <div style={{ fontFamily: 'Sora', fontWeight: 600, fontSize: 16, color: TOKENS.ink950 }}>
            {isWeight ? 'Weight · last 12 weeks' : 'Body Condition · last 12 weeks'}
          </div>
          <div style={{ fontSize: 12, color: TOKENS.ink500, marginTop: 2 }}>
            {isWeight ? 'Target range shaded' : 'Ideal: 4–5 / 9 (Purina chart)'}
          </div>
        </div>
        <div style={{
          padding: '6px 10px', borderRadius: 10, background: TOKENS.surface2,
          fontSize: 11, fontWeight: 600, color: TOKENS.ink700, letterSpacing: '0.02em',
        }}>12W</div>
      </div>

      <svg width="100%" viewBox={`0 0 ${W} ${H}`} style={{ display: 'block', overflow: 'visible' }}>
        {/* Y grid */}
        {Array.from({ length: yTicks + 1 }).map((_, i) => {
          const v = lo + (i / yTicks) * range;
          const y = yAt(v);
          return (
            <g key={i}>
              <line x1={PAD.l} y1={y} x2={W - PAD.r} y2={y} stroke={TOKENS.line200} strokeWidth="1" strokeDasharray={i === 0 || i === yTicks ? '' : '2 4'}/>
              <text x={PAD.l - 8} y={y + 4} textAnchor="end"
                    fontSize="10" fontWeight="500" fontFamily="Inter"
                    fill={outdoor ? TOKENS.ink700 : TOKENS.ink500}
                    style={{ fontVariantNumeric: 'tabular-nums' }}>
                {isWeight ? v.toFixed(1) : Math.round(v)}
              </text>
            </g>
          );
        })}

        {/* Ideal zone */}
        {isWeight ? (
          <rect x={PAD.l} y={yAt(wIdealHi)}
                width={innerW} height={yAt(wIdealLo) - yAt(wIdealHi)}
                fill={TOKENS.meadow} fillOpacity={outdoor ? 0.18 : 0.13}/>
        ) : (
          <rect x={PAD.l} y={bcsIdealTop}
                width={innerW} height={bcsIdealBot - bcsIdealTop}
                fill={TOKENS.meadow} fillOpacity={outdoor ? 0.18 : 0.13}/>
        )}

        {/* Area */}
        <polygon points={areaPts} fill={stroke} fillOpacity="0.08"/>

        {/* Line */}
        <polyline points={linePts} fill="none" stroke={stroke}
                  strokeWidth={3 * strokeMul} strokeLinecap="round" strokeLinejoin="round"/>

        {/* Data points */}
        {data.map((v, i) => {
          const cx = xAt(i), cy = yAt(v);
          const isLast = i === last;
          return (
            <g key={i}>
              {isLast && (
                <circle cx={cx} cy={cy} r="11" fill={stroke} opacity="0.15"/>
              )}
              <circle cx={cx} cy={cy} r={isLast ? 5 : 3} fill="#fff" stroke={stroke} strokeWidth={isLast ? 3 : 2}/>
            </g>
          );
        })}

        {/* Last value label */}
        <g transform={`translate(${xAt(last) - 36}, ${yAt(data[last]) - 28})`}>
          <rect width="68" height="22" rx="6" fill={stroke}/>
          <text x="34" y="15" textAnchor="middle" fontSize="11" fontWeight="700" fontFamily="Inter" fill="#fff" style={{ fontVariantNumeric: 'tabular-nums' }}>
            {isWeight ? `${data[last].toFixed(1)} kg` : `${data[last]} / 9`}
          </text>
        </g>

        {/* X labels */}
        {labels.map((lab, i) => {
          if (i % 2 !== 0 && i !== labels.length - 1) return null;
          return (
            <text key={i} x={xAt(i)} y={H - 8} textAnchor="middle"
                  fontSize="10" fontWeight="500" fontFamily="Inter"
                  fill={outdoor ? TOKENS.ink700 : TOKENS.ink500}
                  style={{ fontVariantNumeric: 'tabular-nums' }}>{lab}</text>
          );
        })}
      </svg>

      {/* Footnote: BCS scale legend */}
      {!isWeight && (
        <div style={{
          marginTop: 8, padding: '8px 10px', borderRadius: 10, background: TOKENS.surface2,
          display: 'flex', alignItems: 'center', gap: 8, fontSize: 11, color: TOKENS.ink700,
        }}>
          <div style={{ display: 'flex', gap: 2, flex: 1 }}>
            {Array.from({ length: 9 }).map((_, i) => {
              const n = i + 1;
              const ideal = n >= 4 && n <= 5;
              const isCurrent = n === data[last];
              return (
                <div key={n} style={{
                  flex: 1, height: 18, borderRadius: 4,
                  background: ideal ? TOKENS.meadow : (n < 4 ? TOKENS.blue200 : TOKENS.apricot),
                  opacity: isCurrent ? 1 : 0.42,
                  boxShadow: isCurrent ? '0 0 0 2px ' + TOKENS.ink950 : 'none',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: isCurrent ? '#fff' : 'transparent',
                  fontSize: 10, fontWeight: 700,
                }}>{n}</div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// Next checkup
// ────────────────────────────────────────────────────────────────
function NextCheckup({ active, cardBg }) {
  return (
    <div style={{
      background: cardBg, borderRadius: 18, padding: '14px 16px',
      display: 'flex', alignItems: 'center', gap: 14,
      boxShadow: '0 0 0 0.5px ' + TOKENS.line200 + ', 0 1px 2px rgba(11,18,32,0.04)',
    }}>
      <div style={{
        width: 48, height: 56, borderRadius: 10, background: TOKENS.blue50,
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0, padding: '4px 0',
      }}>
        <div style={{ fontSize: 9, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: TOKENS.blue600 }}>Jun</div>
        <div style={{ fontFamily: 'Sora', fontSize: 22, fontWeight: 700, color: TOKENS.blue700, lineHeight: 1 }}>18</div>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Sora', fontWeight: 600, fontSize: 15, color: TOKENS.ink950 }}>Annual wellness check</div>
        <div style={{ fontSize: 12, color: TOKENS.ink500, marginTop: 2 }}>Highbury Vets · 10:40 AM · 37 days</div>
      </div>
      <button style={{
        height: 36, padding: '0 14px', borderRadius: 10, border: 'none', cursor: 'pointer',
        background: TOKENS.surface2, color: TOKENS.ink950,
        fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
      }}>Details</button>
    </div>
  );
}

function SectionLabel2({ children, outdoor }) {
  return (
    <div style={{
      marginTop: 6, paddingLeft: 6, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    }}>
      <div style={{
        fontSize: 12, fontWeight: 700, letterSpacing: '0.08em',
        textTransform: 'uppercase', color: outdoor ? TOKENS.ink700 : TOKENS.ink500,
      }}>{children}</div>
      <button style={{
        background: 'transparent', border: 'none', cursor: 'pointer',
        fontSize: 13, fontWeight: 600, color: TOKENS.blue600, fontFamily: 'Inter',
      }}>Add reading</button>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// Tab bar — Health tab active
// ────────────────────────────────────────────────────────────────
function TabBarHealth({ onTab }) {
  const tabs = [
    { id: 'home', label: 'Home', icon: (c) => <path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-5v-7h-6v7H4a1 1 0 01-1-1V11z" stroke={c} strokeWidth="1.75" strokeLinejoin="round" fill="none"/> },
    { id: 'feed', label: 'Social', icon: (c) => <><circle cx="12" cy="12" r="9" stroke={c} strokeWidth="1.75" fill="none"/><circle cx="12" cy="9" r="2.5" stroke={c} strokeWidth="1.75" fill="none"/><path d="M6 18c1-3 3-4 6-4s5 1 6 4" stroke={c} strokeWidth="1.75" fill="none"/></> },
    { id: 'match', label: 'Match', icon: (c) => <path d="M12 21s-8-5-8-11a5 5 0 019-3 5 5 0 019 3c0 6-8 11-8 11z" stroke={c} strokeWidth="1.75" fill="none" strokeLinejoin="round"/> },
    { id: 'health', label: 'Health', icon: (c) => <path d="M4 12l3 6 5-13 4 8h4" stroke={c} strokeWidth="1.75" fill="none" strokeLinejoin="round"/> },
    { id: 'shop', label: 'Shop', icon: (c) => <path d="M5 7h14l-1.5 12a2 2 0 01-2 1.7h-7a2 2 0 01-2-1.7L5 7zM9 7V5a3 3 0 016 0v2" stroke={c} strokeWidth="1.75" fill="none" strokeLinejoin="round"/> },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, paddingBottom: 26,
      background: 'linear-gradient(180deg, rgba(250,251,253,0) 0%, rgba(250,251,253,0.92) 40%, ' + TOKENS.surface1 + ' 100%)',
    }}>
      <div style={{
        margin: '0 12px', height: 64, borderRadius: 24,
        background: TOKENS.surface0,
        boxShadow: '0 0 0 0.5px ' + TOKENS.line200 + ', 0 12px 28px -10px rgba(11,18,32,0.14)',
        display: 'flex', alignItems: 'center', padding: '0 4px',
      }}>
        {tabs.map((t) => {
          const active = t.id === 'health';
          const c = active ? TOKENS.blue500 : TOKENS.ink500;
          return (
            <button key={t.id} onClick={() => onTab && onTab(t.id)} aria-label={t.label} style={{
              flex: 1, height: '100%', border: 'none', background: 'transparent', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
              padding: '8px 0',
            }}>
              <svg width="24" height="24" viewBox="0 0 24 24">{t.icon(c)}</svg>
              <span style={{ fontSize: 10, fontWeight: 600, color: c, letterSpacing: '0.02em' }}>{t.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ────────────────────────────────────────────────────────────────
// Seed data per pet
// ────────────────────────────────────────────────────────────────
const WEEK_DATA = {
  luna: [
    { feed: true, walk: true,  med: true  },
    { feed: true, walk: true,  med: true  },
    { feed: true, walk: true,  med: true  },
    { feed: true, walk: true,  med: true  },
    { feed: true, walk: true,  med: false }, // today — Friday
    { feed: false, walk: false, med: false },
    { feed: false, walk: false, med: false },
  ],
  mochi: [
    { feed: true, walk: false, med: true  },
    { feed: true, walk: false, med: true  },
    { feed: true, walk: false, med: true  },
    { feed: true, walk: false, med: true  },
    { feed: true, walk: false, med: false }, // today
    { feed: false, walk: false, med: false },
    { feed: false, walk: false, med: false },
  ],
  hopper: [
    { feed: true, walk: false, med: false },
    { feed: true, walk: false, med: false },
    { feed: true, walk: false, med: false },
    { feed: false, walk: false, med: false },
    { feed: true, walk: false, med: false },
    { feed: false, walk: false, med: false },
    { feed: false, walk: false, med: false },
  ],
};

const VITAL_DATA = {
  luna: {
    labels: ['Mar 1','Mar 15','Apr 1','Apr 15','May 1','May 15'],
    weight: [20.4, 20.1, 19.8, 19.6, 19.4, 19.3, 19.5, 19.7, 19.6, 19.4, 19.2, 19.1],
    bcs:    [6, 6, 5, 5, 5, 5, 5, 5, 4, 4, 5, 5],
  },
  mochi: {
    labels: ['Mar 1','Mar 15','Apr 1','Apr 15','May 1','May 15'],
    weight: [5.1, 5.2, 5.3, 5.3, 5.4, 5.5, 5.5, 5.6, 5.7, 5.6, 5.5, 5.4],
    bcs:    [5, 5, 5, 6, 6, 6, 6, 7, 7, 6, 6, 5],
  },
  hopper: {
    labels: ['Mar 1','Mar 15','Apr 1','Apr 15','May 1','May 15'],
    weight: [1.6, 1.6, 1.7, 1.7, 1.7, 1.8, 1.8, 1.8, 1.9, 1.9, 1.9, 1.8],
    bcs:    [3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 4, 4],
  },
};

Object.assign(window, { HealthDashboard, WEEK_DATA, VITAL_DATA });
