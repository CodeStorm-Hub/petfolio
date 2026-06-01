// care3d.jsx — PetFolio Care screen, compact redesign + 3D depth
const { useState, useRef, useEffect, useContext, createContext, useCallback } = React;

// ─────────────────────────────────────────────────────────────
// Theme / depth context (self-contained tweaks)
// ─────────────────────────────────────────────────────────────
const DepthCtx = createContext(1);

// ─────────────────────────────────────────────────────────────
// 3D tilt hook — pointer/drag driven rotateX/Y + glare position
// ─────────────────────────────────────────────────────────────
function useTilt({ max = 9, lift = 1.0 } = {}) {
  const depth = useContext(DepthCtx);
  const ref = useRef(null);
  const [t, setT] = useState({ rx: 0, ry: 0, on: false, px: 50, py: 50, press: false });

  const move = useCallback((e) => {
    const el = ref.current; if (!el || depth === 0) return;
    const r = el.getBoundingClientRect();
    const x = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width));
    const y = Math.min(1, Math.max(0, (e.clientY - r.top) / r.height));
    const m = max * depth;
    setT(s => ({ ...s, rx: (0.5 - y) * m * 2, ry: (x - 0.5) * m * 2, on: true, px: x * 100, py: y * 100 }));
  }, [depth, max]);

  const leave = useCallback(() => setT(s => ({ ...s, rx: 0, ry: 0, on: false, px: 50, py: 50, press: false })), []);
  const down = useCallback(() => setT(s => ({ ...s, press: true })), []);
  const up = useCallback(() => setT(s => ({ ...s, press: false })), []);

  const transform = depth === 0
    ? (t.press ? 'scale(0.97)' : 'none')
    : `perspective(640px) rotateX(${t.rx}deg) rotateY(${t.ry}deg) translateZ(0) scale(${t.press ? 0.965 : (t.on ? 1.012 * lift : 1)})`;

  const bind = {
    ref,
    onPointerMove: move, onPointerLeave: leave, onPointerDown: down,
    onPointerUp: up, onPointerCancel: leave,
  };
  return { bind, t, transform };
}

// Glare overlay used inside tilt cards
function Glare({ t, r = 24, strength = 0.5 }) {
  const depth = useContext(DepthCtx);
  if (depth === 0) return null;
  return (
    <div style={{
      position: 'absolute', inset: 0, borderRadius: r, pointerEvents: 'none',
      background: `radial-gradient(220px circle at ${t.px}% ${t.py}%, rgba(255,255,255,${t.on ? strength : 0}), transparent 60%)`,
      transition: 'background 160ms ease', mixBlendMode: 'soft-light',
    }}/>
  );
}

// ─────────────────────────────────────────────────────────────
// Tiny icon set
// ─────────────────────────────────────────────────────────────
const Ico = {
  paw: (s = 22, f = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none"><ellipse cx="6" cy="9" rx="2.1" ry="2.6" fill={f}/><ellipse cx="10" cy="5.6" rx="2" ry="2.5" fill={f}/><ellipse cx="14" cy="5.6" rx="2" ry="2.5" fill={f}/><ellipse cx="18" cy="9" rx="2.1" ry="2.6" fill={f}/><path d="M12 10c-3.6 0-6.2 3-6.2 5.7 0 2.1 1.7 3.3 3.5 3.3 1.2 0 1.7-.6 2.7-.6s1.5.6 2.7.6c1.8 0 3.5-1.2 3.5-3.3 0-2.7-2.6-5.7-6.2-5.7z" fill={f}/></svg>),
  pawO: (s = 22, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.7"><ellipse cx="6" cy="9" rx="2.1" ry="2.6"/><ellipse cx="10" cy="5.6" rx="2" ry="2.5"/><ellipse cx="14" cy="5.6" rx="2" ry="2.5"/><ellipse cx="18" cy="9" rx="2.1" ry="2.6"/><path d="M12 10c-3.6 0-6.2 3-6.2 5.7 0 2.1 1.7 3.3 3.5 3.3 1.2 0 1.7-.6 2.7-.6s1.5.6 2.7.6c1.8 0 3.5-1.2 3.5-3.3 0-2.7-2.6-5.7-6.2-5.7z"/></svg>),
  heartO: (s = 22, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinejoin="round"><path d="M12 21s-7.5-4.7-9.5-9.4C1 8 3.2 4 7 4c2 0 3.6 1.1 5 3 1.4-1.9 3-3 5-3 3.8 0 6 4 4.5 7.6C19.5 16.3 12 21 12 21z"/></svg>),
  flame: (s = 22, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinejoin="round"><path d="M12 22c4.4 0 7-3.2 7-7 0-3.4-2.4-5.6-3.5-8.2-.6-1.4-.5-3.3-2-4.8-.6 2.3-1.7 2.6-3.3 4.8C8.6 8.9 5 10.6 5 15c0 3.8 2.6 7 7 7z"/></svg>),
  bone: (s = 22, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill={c}><path d="M5.5 4.5a2.6 2.6 0 0 1 4.7 1.5l3.6 3.6a2.6 2.6 0 1 1 1.7 4.4l-3.6 3.6a2.6 2.6 0 1 1-4.4 1.7 2.6 2.6 0 1 1-1.7-4.4l3.6-3.6A2.6 2.6 0 1 1 5.5 4.5z"/></svg>),
  cart: (s = 22, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M3 4h2l2.4 11.4a2 2 0 0 0 2 1.6h8.7a2 2 0 0 0 2-1.6L21 9H7"/><circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/></svg>),
  check: (s = 22, c = '#fff') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12l5 5 9-11"/></svg>),
  chevDown: (s = 16, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M6 9l6 6 6-6"/></svg>),
  chevR: (s = 16, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M9 6l6 6-6 6"/></svg>),
  lock: (s = 12, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>),
  moon: (s = 20, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill={c}><path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z"/></svg>),
  sun: (s = 20, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5L19 19M19 5l-1.5 1.5M6.5 17.5L5 19"/></svg>),
  sparkle: (s = 18, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill={c}><path d="M12 2l1.8 5.4L19 9l-5.2 1.6L12 16l-1.8-5.4L5 9l5.2-1.6z"/><circle cx="18.5" cy="17.5" r="1.6"/></svg>),
  refresh: (s = 16, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.1" strokeLinecap="round" strokeLinejoin="round"><path d="M3 12a9 9 0 0 1 15-6.7L21 8M21 3v5h-5"/><path d="M21 12a9 9 0 0 1-15 6.7L3 16M3 21v-5h5"/></svg>),
  scale: (s = 22, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><rect x="4" y="4" width="16" height="16" rx="4"/><path d="M9 9.5h6"/><circle cx="12" cy="14" r="0.6" fill={c}/></svg>),
  vault: (s = 22, c = 'currentColor') => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M3 7l8-4 8 4v6c0 5-3.5 7.5-8 8.5C6.5 20.5 3 18 3 13z"/><path d="M9.5 12l2 2 3.5-4"/></svg>),
};

// ─────────────────────────────────────────────────────────────
// Pet avatar (gradient disc + emoji + species ring)
// ─────────────────────────────────────────────────────────────
function Avatar({ size = 40, ring = true, emoji = '🐱', soft = 'var(--poppy-soft)', color = 'var(--poppy)' }) {
  const inner = size - (ring ? 6 : 0);
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%', flexShrink: 0,
      background: ring ? 'conic-gradient(from 210deg, var(--tangerine), var(--poppy), var(--sunny), var(--mint), var(--tangerine))' : 'transparent',
      padding: ring ? 3 : 0, display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    }}>
      <div style={{
        width: inner, height: inner, borderRadius: '50%',
        background: `radial-gradient(circle at 32% 28%, ${soft}, ${color} 92%)`,
        border: ring ? '2px solid var(--surface)' : 'none',
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: inner * 0.52,
      }}>{emoji}</div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────
function SectionLabel({ accent, children, right }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 2px 9px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
        <div style={{ width: 5, height: 19, borderRadius: 3, background: accent }}/>
        <h3 className="display" style={{ fontSize: 16.5, fontWeight: 800, color: 'var(--ink-950)', whiteSpace: 'nowrap' }}>{children}</h3>
      </div>
      {right}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// 3D streak flame medallion
// ─────────────────────────────────────────────────────────────
function StreakCoin({ streak }) {
  const depth = useContext(DepthCtx);
  return (
    <div style={{ width: 78, height: 78, flexShrink: 0, position: 'relative', perspective: 520 }}>
      <div style={{ position: 'absolute', inset: -3, borderRadius: '50%', border: '2.5px solid rgba(255,255,255,0.55)', animation: depth ? 'pf-pulse-ring 2.2s ease-out infinite' : 'none' }}/>
      <div style={{
        width: '100%', height: '100%', borderRadius: '50%', transformStyle: 'preserve-3d',
        animation: depth ? 'pf-coin-spin 4.5s ease-in-out infinite' : 'none',
      }}>
        <div style={{
          position: 'absolute', inset: 0, borderRadius: '50%',
          background: 'radial-gradient(circle at 38% 30%, #FFE9A8, var(--sunny) 42%, var(--tangerine) 86%)',
          boxShadow: 'inset 0 -8px 14px rgba(180,70,10,0.45), inset 0 7px 12px rgba(255,255,255,0.65), 0 12px 22px -8px rgba(224,101,30,0.8)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 0,
          overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', overflow: 'hidden' }}>
            <div style={{ position: 'absolute', top: 0, bottom: 0, width: '38%', background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.7), transparent)', animation: depth ? 'pf-sheen 3.8s ease-in-out infinite' : 'none' }}/>
          </div>
          <div style={{ fontSize: 26, lineHeight: 1, marginTop: 2, animation: depth ? 'pf-flame-bob 1.8s ease-in-out infinite' : 'none', filter: 'drop-shadow(0 2px 3px rgba(150,40,0,0.4))' }}>🔥</div>
          <div className="display" style={{ fontSize: 21, fontWeight: 800, color: '#fff', lineHeight: 1, textShadow: '0 2px 4px rgba(150,40,0,0.5)' }}>{streak}</div>
          <div style={{ fontSize: 7, fontWeight: 900, color: '#fff', letterSpacing: 0.2, opacity: 0.95 }}>DAY STREAK</div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Slim hero (streak + level + XP) — replaces tall wave header
// ─────────────────────────────────────────────────────────────
function Hero({ pet, doneToday, totalToday }) {
  const pct = (pet.xp / pet.xpMax) * 100;
  return (
    <div style={{
      position: 'relative', margin: '0 14px', borderRadius: 26, padding: '15px 16px 16px', overflow: 'hidden',
      background: 'linear-gradient(135deg, var(--poppy) 0%, #FF6B45 55%, var(--tangerine) 100%)',
      boxShadow: 'var(--shadow-pop)',
    }}>
      {/* decorative paws */}
      <div style={{ position: 'absolute', right: -6, top: -8, opacity: 0.16, transform: 'rotate(18deg)' }}>{Ico.paw(96, '#fff')}</div>
      <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 14 }}>
        <StreakCoin streak={pet.streak}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8 }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, minWidth: 0 }}>
              <span className="display" style={{ fontSize: 25, fontWeight: 800, color: '#fff', lineHeight: 1, flexShrink: 0 }}>Lv {pet.level}</span>
              <span style={{ fontSize: 12.5, fontWeight: 800, color: 'rgba(255,255,255,0.92)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>· {pet.title}</span>
            </div>
            <span style={{ fontSize: 10.5, fontWeight: 900, color: 'var(--poppy-700)', background: '#fff', padding: '3px 9px', borderRadius: 999, whiteSpace: 'nowrap', flexShrink: 0 }}>{doneToday}/{totalToday} today</span>
          </div>
          <div style={{ marginTop: 10, height: 13, borderRadius: 999, background: 'rgba(0,0,0,0.16)', position: 'relative', overflow: 'hidden', boxShadow: 'inset 0 1px 2px rgba(0,0,0,0.2)' }}>
            <div style={{ height: '100%', width: `${pct}%`, borderRadius: 999, background: 'linear-gradient(90deg, var(--sunny), #FFE08A)', boxShadow: '0 0 10px rgba(255,216,110,0.9)', position: 'relative' }}>
              <div style={{ position: 'absolute', inset: 0, borderRadius: 999, background: 'linear-gradient(180deg, rgba(255,255,255,0.55), transparent 60%)' }}/>
            </div>
          </div>
          <div style={{ marginTop: 7, fontSize: 10.5, fontWeight: 800, color: 'rgba(255,255,255,0.92)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{pet.xp} / {pet.xpMax} XP · {pet.xpMax - pet.xp} XP to Lv {pet.level + 1}</div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Compact horizontal date strip
// ─────────────────────────────────────────────────────────────
function DateStrip() {
  const days = [
    { l: 'T', n: 26 }, { l: 'W', n: 27 }, { l: 'T', n: 28 }, { l: 'F', n: 29 },
    { l: 'S', n: 30, hit: true }, { l: 'S', n: 31, hit: true }, { l: 'M', n: 1, today: true },
    { l: 'T', n: 2, fut: true }, { l: 'W', n: 3, fut: true },
  ];
  return (
    <div style={{ display: 'flex', gap: 7, overflowX: 'auto', padding: '0 14px 2px', scrollSnapType: 'x proximity' }}>
      {days.map((d, i) => (
        <div key={i} style={{
          flex: '0 0 auto', width: 46, height: 58, borderRadius: 16, scrollSnapAlign: 'center',
          background: d.today ? 'linear-gradient(160deg, var(--tangerine), var(--poppy))' : 'var(--surface)',
          border: d.today ? 'none' : '1px solid var(--line)',
          boxShadow: d.today ? '0 8px 16px -7px var(--poppy)' : 'var(--shadow-soft)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 2,
          color: d.today ? '#fff' : (d.fut ? 'var(--ink-300)' : 'var(--ink-950)'),
        }}>
          <span style={{ fontSize: 10, fontWeight: 800, opacity: d.today ? 0.92 : 0.7 }}>{d.l}</span>
          <span className="display" style={{ fontSize: 17, fontWeight: 800, lineHeight: 1 }}>{d.n}</span>
          {d.hit && !d.today ? <div style={{ width: 5, height: 5, borderRadius: '50%', background: 'var(--mint)' }}/> :
            d.today ? <div style={{ width: 14, height: 3, borderRadius: 2, background: '#fff' }}/> : <div style={{ height: 5 }}/>}
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Pet-character SVG icons for each badge
// ─────────────────────────────────────────────────────────────
const BIco = {
  // Paw print + star burst
  firstLog: (s=36) => (
    <svg width={s} height={s} viewBox="0 0 40 40" fill="none">
      <ellipse cx="10" cy="12" rx="3.5" ry="4.2" fill="#fff" opacity="0.95"/>
      <ellipse cx="17" cy="7.5" rx="3" ry="3.8" fill="#fff" opacity="0.95"/>
      <ellipse cx="24" cy="7.5" rx="3" ry="3.8" fill="#fff" opacity="0.95"/>
      <ellipse cx="30" cy="12" rx="3.5" ry="4.2" fill="#fff" opacity="0.95"/>
      <path d="M20 14c-5.8 0-9.8 4.6-9.8 8.8 0 3.4 2.6 5.2 5.8 5.2 1.8 0 2.6-.9 4-.9s2.2.9 4 .9c3.2 0 5.8-1.8 5.8-5.2 0-4.2-4-8.8-9.8-8.8z" fill="#fff" opacity="0.95"/>
      <path d="M34 6l1.2 3 3.2 1.2-3.2 1.2L34 14.6l-1.2-3.2-3.2-1.2 3.2-1.2z" fill="#fff" opacity="0.8"/>
      <circle cx="5" cy="7" r="1.5" fill="#fff" opacity="0.7"/>
    </svg>
  ),
  // Cat face with flame crown
  streak3: (s=36) => (
    <svg width={s} height={s} viewBox="0 0 40 40" fill="none">
      {/* flame */}
      <path d="M20 4C16 9 14 13 15 17c1-2 2.5-3 4-3s3 1 4 3c1-4-1-8-3-13z" fill="#fff" opacity="0.7"/>
      {/* cat head */}
      <circle cx="20" cy="25" r="10" fill="#fff" opacity="0.92"/>
      {/* ears */}
      <path d="M12 18l3 5h-5z" fill="#fff" opacity="0.92"/>
      <path d="M28 18l-3 5h5z" fill="#fff" opacity="0.92"/>
      {/* inner ears */}
      <path d="M12.8 19.5l1.8 3h-3z" fill="rgba(0,0,0,0.12)"/>
      <path d="M27.2 19.5l-1.8 3h3z" fill="rgba(0,0,0,0.12)"/>
      {/* eyes */}
      <ellipse cx="16.5" cy="25" rx="1.6" ry="1.8" fill="rgba(0,0,0,0.35)"/>
      <ellipse cx="23.5" cy="25" rx="1.6" ry="1.8" fill="rgba(0,0,0,0.35)"/>
      <circle cx="17" cy="24.5" r="0.6" fill="#fff"/>
      <circle cx="24" cy="24.5" r="0.6" fill="#fff"/>
      {/* nose + mouth */}
      <path d="M19 28.5 q1 1 2 0" stroke="rgba(0,0,0,0.3)" strokeWidth="1.2" fill="none" strokeLinecap="round"/>
      <ellipse cx="20" cy="28" rx="1" ry="0.7" fill="rgba(0,0,0,0.2)"/>
    </svg>
  ),
  // Dog face with superhero star
  hero7: (s=36) => (
    <svg width={s} height={s} viewBox="0 0 40 40" fill="none">
      {/* star badge */}
      <path d="M20 3l2.4 7.4H30l-6.2 4.5 2.4 7.4L20 18l-6.2 4.3 2.4-7.4L10 10.4h7.6z" fill="#fff" opacity="0.9"/>
      {/* dog head */}
      <ellipse cx="20" cy="31" rx="9" ry="8" fill="#fff" opacity="0.92"/>
      {/* floppy ears */}
      <ellipse cx="12" cy="28" rx="3.5" ry="5.5" fill="#fff" opacity="0.85" transform="rotate(-10 12 28)"/>
      <ellipse cx="28" cy="28" rx="3.5" ry="5.5" fill="#fff" opacity="0.85" transform="rotate(10 28 28)"/>
      {/* eyes */}
      <circle cx="17" cy="30" r="2" fill="rgba(0,0,0,0.35)"/>
      <circle cx="23" cy="30" r="2" fill="rgba(0,0,0,0.35)"/>
      <circle cx="17.6" cy="29.4" r="0.7" fill="#fff"/>
      <circle cx="23.6" cy="29.4" r="0.7" fill="#fff"/>
      {/* snout */}
      <ellipse cx="20" cy="34.5" rx="3.5" ry="2.5" fill="rgba(0,0,0,0.1)"/>
      <ellipse cx="20" cy="33.5" rx="1.4" ry="1" fill="rgba(0,0,0,0.28)"/>
    </svg>
  ),
  // Clipboard with paw checkmark
  routineMaster: (s=36) => (
    <svg width={s} height={s} viewBox="0 0 40 40" fill="none">
      <rect x="8" y="10" width="24" height="27" rx="4" fill="#fff" opacity="0.92"/>
      <rect x="14" y="6" width="12" height="7" rx="3.5" fill="#fff"/>
      {/* paw checkmark rows */}
      <ellipse cx="15" cy="20" rx="2" ry="2.5" fill="rgba(0,0,0,0.22)"/>
      <path d="M20 18l4 4-5 5.5" stroke="rgba(0,0,0,0.25)" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
      <rect x="14" y="28" width="12" height="2" rx="1" fill="rgba(0,0,0,0.12)"/>
      <rect x="14" y="32" width="8" height="2" rx="1" fill="rgba(0,0,0,0.08)"/>
    </svg>
  ),
  // Crown with paw-print peak tips
  legend30: (s=36) => (
    <svg width={s} height={s} viewBox="0 0 40 40" fill="none">
      {/* crown base */}
      <path d="M6 30h28v4a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2v-4z" fill="#fff" opacity="0.95"/>
      {/* crown body */}
      <path d="M6 30L10 14l10 10 10-10 4 16z" fill="#fff" opacity="0.92"/>
      {/* paw tips on peaks */}
      <ellipse cx="10" cy="13" rx="2.8" ry="3.2" fill="#fff" opacity="0.9"/>
      <ellipse cx="20" cy="8" rx="3.2" ry="3.6" fill="#fff" opacity="0.9"/>
      <ellipse cx="30" cy="13" rx="2.8" ry="3.2" fill="#fff" opacity="0.9"/>
      {/* toe beans */}
      <ellipse cx="8.5" cy="11" rx="1" ry="1.2" fill="rgba(0,0,0,0.15)"/>
      <ellipse cx="11.5" cy="11" rx="1" ry="1.2" fill="rgba(0,0,0,0.15)"/>
      <ellipse cx="18.5" cy="6" rx="1.1" ry="1.3" fill="rgba(0,0,0,0.15)"/>
      <ellipse cx="21.5" cy="6" rx="1.1" ry="1.3" fill="rgba(0,0,0,0.15)"/>
      <ellipse cx="28.5" cy="11" rx="1" ry="1.2" fill="rgba(0,0,0,0.15)"/>
      <ellipse cx="31.5" cy="11" rx="1" ry="1.2" fill="rgba(0,0,0,0.15)"/>
      {/* gem */}
      <path d="M20 22l3.5 4h-7z" fill="rgba(0,0,0,0.15)"/>
      <circle cx="20" cy="21" r="2.5" fill="rgba(0,0,0,0.18)"/>
    </svg>
  ),
  // Trophy with heart-paw
  champion: (s=36) => (
    <svg width={s} height={s} viewBox="0 0 40 40" fill="none">
      {/* trophy cup */}
      <path d="M12 8h16v12a8 8 0 0 1-16 0V8z" fill="#fff" opacity="0.95"/>
      {/* handles */}
      <path d="M12 10H7a4 4 0 0 0 4 8M28 10h5a4 4 0 0 1-4 8" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" fill="none" opacity="0.85"/>
      {/* stem */}
      <rect x="17" y="28" width="6" height="5" rx="1" fill="#fff" opacity="0.9"/>
      <rect x="13" y="33" width="14" height="3" rx="1.5" fill="#fff" opacity="0.92"/>
      {/* heart-paw in cup */}
      <path d="M20 22c0 0-5-3-5-6 0-1.6 1.8-3 5-1.4C23.2 13 25 14.4 25 16c0 3-5 6-5 6z" fill="rgba(0,0,0,0.18)"/>
      <ellipse cx="17.5" cy="16.5" rx="1.2" ry="1.5" fill="rgba(0,0,0,0.12)"/>
      <ellipse cx="22.5" cy="16.5" rx="1.2" ry="1.5" fill="rgba(0,0,0,0.12)"/>
    </svg>
  ),
};

// Badge data with custom rim colors and float timing
const BADGES = [
  { id:'firstLog',  l:'First Log',       c:'var(--mint)',       rim:'#1a9970', owned:true,  hint:'unlocked',  delay:0,    dur:3.4 },
  { id:'streak3',   l:'3-Day Streak',     c:'var(--tangerine)', rim:'#b85a1a', owned:false, hint:'1/3 days',  delay:0.5,  dur:3.8 },
  { id:'hero7',     l:'7-Day Hero',       c:'var(--poppy)',      rim:'#8a1010', owned:false, hint:'1/7 days',  delay:0.9,  dur:3.2 },
  { id:'routineMaster', l:'Routine Pro',  c:'var(--sunny)',     rim:'#9a6500', owned:false, hint:'1/14 days', delay:0.3,  dur:4.0 },
  { id:'legend30',  l:'30-Day Legend',    c:'var(--lilac)',     rim:'#4a2fa0', owned:false, hint:'1/30 days', delay:0.7,  dur:3.6 },
  { id:'champion',  l:'Care Champ',       c:'var(--sky)',       rim:'#2060a8', owned:false, hint:'6/100 logs',delay:0.15, dur:3.5 },
];

const ICON_MAP = {
  firstLog: BIco.firstLog, streak3: BIco.streak3, hero7: BIco.hero7,
  routineMaster: BIco.routineMaster, legend30: BIco.legend30, champion: BIco.champion,
};

// ─────────────────────────────────────────────────────────────
// 3D Trophy badge card — medal-style, floating animation
// ─────────────────────────────────────────────────────────────
function BadgeMedal({ b, idx, onTap }) {
  const depth = useContext(DepthCtx);
  const { bind, t, transform } = useTilt({ max: 16, lift: 1.06 });
  const IconComponent = ICON_MAP[b.id];
  const floatAnim = depth ? `pf-badge-float ${b.dur}s ease-in-out ${b.delay}s infinite` : 'none';

  return (
    <div onClick={() => onTap(b)} style={{ cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5, animation: floatAnim }} >
      {/* tilt wrapper */}
      <div {...bind} style={{
        transform, transformStyle: 'preserve-3d',
        transition: t.on ? 'transform 80ms ease-out' : 'transform 400ms cubic-bezier(.2,.9,.25,1)',
        position: 'relative', width: 72, height: 72,
      }}>
        {/* outer glow ring (owned only) */}
        {b.owned && (
          <div style={{
            position: 'absolute', inset: -5, borderRadius: '50%',
            border: `2.5px solid ${b.c}`,
            animation: depth ? `pf-badge-glow 2.4s ease-in-out ${b.delay}s infinite` : 'none',
          }}/>
        )}
        {/* medal body */}
        <div style={{
          width: 72, height: 72, borderRadius: '50%', position: 'relative', overflow: 'hidden',
          background: b.owned
            ? `radial-gradient(circle at 38% 28%, color-mix(in oklab,${b.c} 55%, white), ${b.c} 58%, color-mix(in oklab,${b.c} 60%, black) 100%)`
            : 'radial-gradient(circle at 38% 28%, #D8C8C0, #B0A099 100%)',
          boxShadow: b.owned
            ? `0 8px 0 0 ${b.rim}, inset 0 -8px 14px rgba(0,0,0,0.3), inset 0 7px 12px rgba(255,255,255,0.55), 0 14px 24px -8px ${b.c}`
            : `0 5px 0 0 #8A7870, inset 0 -4px 8px rgba(0,0,0,0.22), inset 0 4px 8px rgba(255,255,255,0.3)`,
          border: b.owned ? `3px solid color-mix(in oklab,${b.c} 70%, white)` : '2px solid var(--line)',
        }}>
          {/* concentric ring for depth */}
          <div style={{ position: 'absolute', inset: 6, borderRadius: '50%', border: `1.5px solid ${b.owned ? 'rgba(255,255,255,0.3)' : 'rgba(0,0,0,0.06)'}` }}/>
          <div style={{ position: 'absolute', inset: 11, borderRadius: '50%', border: `1px solid ${b.owned ? 'rgba(255,255,255,0.18)' : 'rgba(0,0,0,0.04)'}` }}/>
          {/* icon */}
          <div style={{
            position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
            filter: b.owned ? 'drop-shadow(0 3px 5px rgba(0,0,0,0.28))' : 'opacity(0.7)',
            transform: 'translateZ(18px)',
          }}>
            {IconComponent ? <IconComponent s={34}/> : <span style={{ fontSize: 28 }}>{b.e}</span>}
          </div>
          {/* holographic sheen (owned) */}
          {b.owned && (
            <div style={{
              position: 'absolute', top: 0, bottom: 0, width: '45%',
              background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.65), transparent)',
              animation: depth ? `pf-holo-sweep ${b.dur + 1}s ease-in-out ${b.delay}s infinite` : 'none',
              borderRadius: '50%', pointerEvents: 'none',
            }}/>
          )}
          {/* lock pip */}
          {!b.owned && (
            <div style={{ position: 'absolute', right: 5, bottom: 5, width: 18, height: 18, borderRadius: '50%', background: 'var(--surface)', border: '1px solid var(--line)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--ink-300)' }}>{Ico.lock(9)}</div>
          )}
          <Glare t={t} r={999} strength={0.45}/>
        </div>
      </div>
      {/* label */}
      <div style={{ fontSize: 10, fontWeight: 800, color: 'var(--ink-950)', textAlign: 'center', lineHeight: 1.2, maxWidth: 78, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{b.l}</div>
      <div style={{ fontSize: 9, fontWeight: 700, color: b.owned ? 'var(--mint-700)' : 'var(--ink-300)', marginTop: -3 }}>{b.owned ? '✓ earned' : b.hint}</div>
    </div>
  );
}

function TrophyCarousel({ onTap }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '8px 4px', padding: '6px 14px 4px' }}>
      {BADGES.map((b, i) => <BadgeMedal key={b.id} b={b} idx={i} onTap={onTap}/>)}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Quest task card — denser 2-line, tilt + press-depth + confetti
// ─────────────────────────────────────────────────────────────
const TASK_META = {
  feeding:  { e: '🥩', c: 'var(--tangerine)', soft: 'var(--tangerine-soft)' },
  playtime: { e: '🎾', c: 'var(--sunny)', soft: 'var(--sunny-soft)' },
  training: { e: '🎓', c: 'var(--poppy)', soft: 'var(--poppy-soft)' },
  walk:     { e: '🦮', c: 'var(--mint)', soft: 'var(--mint-soft)' },
};

function TaskCard({ task, onToggle }) {
  const { bind, t, transform } = useTilt({ max: 6 });
  const m = TASK_META[task.type] || TASK_META.feeding;
  const done = task.done;
  return (
    <div {...bind} style={{ transform, transition: t.on ? 'transform 80ms ease-out' : 'transform 320ms cubic-bezier(.2,.9,.25,1)', transformStyle: 'preserve-3d', marginBottom: 9 }}>
      <div style={{
        position: 'relative', borderRadius: 20, padding: '11px 12px', display: 'flex', alignItems: 'center', gap: 12, overflow: 'hidden',
        background: done ? `color-mix(in oklab, ${m.c} 12%, var(--surface))` : 'var(--surface)',
        border: `1.5px solid ${task.due && !done ? m.c : (done ? `color-mix(in oklab, ${m.c} 45%, var(--line))` : 'var(--line)')}`,
        boxShadow: task.due && !done ? `0 0 0 3px color-mix(in oklab, ${m.c} 20%, transparent), var(--shadow-soft)` : 'var(--shadow-soft)',
        opacity: done ? 0.92 : 1,
      }}>
        <div style={{
          width: 44, height: 44, borderRadius: 14, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 23,
          background: done ? m.c : m.soft, transform: 'translateZ(16px)',
          boxShadow: done ? `0 6px 12px -5px ${m.c}` : 'inset 0 -3px 6px rgba(0,0,0,0.06)',
        }}>{done ? Ico.check(22, '#fff') : m.e}</div>
        <div style={{ flex: 1, minWidth: 0, transform: 'translateZ(10px)' }}>
          <div style={{ fontSize: 14.5, fontWeight: 800, color: 'var(--ink-950)', textDecoration: done ? 'line-through' : 'none', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{task.title}</div>
          <div style={{ fontSize: 11.5, fontWeight: 700, color: done ? 'var(--mint-700)' : (task.due ? 'var(--poppy-700)' : 'var(--ink-500)') }}>{done ? 'Completed' : (task.due ? `Due ${task.time}` : task.time)}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, transform: 'translateZ(12px)' }}>
          <span style={{ fontSize: 11, fontWeight: 900, color: done ? 'var(--mint-700)' : 'var(--sunny-700)', background: done ? 'var(--mint-soft)' : 'var(--sunny-soft)', padding: '4px 8px', borderRadius: 999, display: 'inline-flex', alignItems: 'center', gap: 2 }}>+{task.xp}<span style={{ fontSize: 9 }}>⭐</span></span>
          <button onClick={(e) => { e.stopPropagation(); onToggle(task, e.currentTarget); }} style={{
            width: 32, height: 32, borderRadius: '50%', cursor: 'pointer', flexShrink: 0,
            border: `2px solid ${done ? m.c : 'var(--line-2)'}`, background: done ? m.c : 'var(--surface)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{done && Ico.check(17, '#fff')}</button>
        </div>
        <Glare t={t} r={20} strength={0.35}/>
      </div>
    </div>
  );
}

function FreqDivider({ label }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 4px 8px' }}>
      <div style={{ flex: 1, height: 1, background: 'var(--line)' }}/>
      <span style={{ fontSize: 10, fontWeight: 800, letterSpacing: 1, color: 'var(--ink-300)', whiteSpace: 'nowrap' }}>{label}</span>
      <div style={{ flex: 1, height: 1, background: 'var(--line)' }}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Compact weekly chart
// ─────────────────────────────────────────────────────────────
function WeeklyChart() {
  const bars = [
    { l: 'T', n: 26, h: 0.3, miss: true }, { l: 'W', n: 27, h: 0.3, miss: true },
    { l: 'T', n: 28, h: 0.3, miss: true }, { l: 'F', n: 29, h: 0.3, miss: true },
    { l: 'S', n: 30, h: 0.3, miss: true }, { l: 'S', n: 31, h: 0.85, c: 'var(--mint)' },
    { l: 'M', n: 1, h: 0.16, c: 'var(--poppy)', today: true },
  ];
  return (
    <div style={{ background: 'var(--surface)', borderRadius: 22, border: '1px solid var(--line)', padding: '12px 14px 12px', boxShadow: 'var(--shadow-card)' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
        <span style={{ fontSize: 12, fontWeight: 800, color: 'var(--ink-500)', whiteSpace: 'nowrap' }}>1 / 7 goals this week</span>
        <span style={{ fontSize: 11, fontWeight: 800, color: 'var(--mint-700)', background: 'var(--mint-soft)', padding: '3px 9px', borderRadius: 999 }}>1 🔥</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 7, height: 78 }}>
        {bars.map((b, i) => (
          <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, height: '100%', justifyContent: 'flex-end' }}>
            {b.today && <span style={{ fontSize: 11, marginBottom: -2 }}>🐾</span>}
            <div style={{
              width: '100%', height: `${b.h * 100}%`, borderRadius: 8,
              background: b.miss ? 'var(--surface-2)' : `linear-gradient(180deg, ${b.c}, color-mix(in oklab, ${b.c} 55%, white))`,
              border: b.miss ? '1px dashed var(--line-2)' : (b.today ? '2px solid var(--poppy-700)' : 'none'),
              boxShadow: b.today ? '0 6px 12px -4px var(--poppy)' : 'none',
            }}/>
            <span style={{ fontSize: 9.5, fontWeight: 800, color: b.today ? 'var(--poppy-700)' : 'var(--ink-300)' }}>{b.l}</span>
            <span style={{ fontSize: 9, fontWeight: 700, color: 'var(--ink-300)', marginTop: -3 }}>{b.n}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Merged utility banner (Nutrition | Medical Vault)
// ─────────────────────────────────────────────────────────────
function UtilityBanner() {
  const half = (icon, bg, icColor, title, line1, line2) => (
    <div style={{ flex: 1, padding: '13px 13px', display: 'flex', flexDirection: 'column', gap: 8, cursor: 'pointer' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ width: 36, height: 36, borderRadius: 12, background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', color: icColor }}>{icon}</div>
        {Ico.chevR(15, 'var(--ink-300)')}
      </div>
      <div>
        <div style={{ fontSize: 13, fontWeight: 800, color: 'var(--ink-950)', lineHeight: 1.15 }}>{title}</div>
        <div style={{ fontSize: 11, fontWeight: 700, color: icColor, marginTop: 3 }}>{line1}</div>
        <div style={{ fontSize: 10.5, fontWeight: 600, color: 'var(--ink-500)', marginTop: 1 }}>{line2}</div>
      </div>
    </div>
  );
  return (
    <div style={{ display: 'flex', borderRadius: 22, overflow: 'hidden', background: 'var(--surface)', border: '1px solid var(--line)', boxShadow: 'var(--shadow-card)' }}>
      {half(Ico.scale(20), 'var(--sunny-soft)', 'var(--sunny-700)', 'Nutrition', '4.2 kg · May 28', '~280 kcal / day')}
      <div style={{ width: 1, background: 'var(--line)' }}/>
      {half(Ico.vault(20), 'var(--mint-soft)', 'var(--mint-700)', 'Medical Vault', '1 due soon', 'Checkup · 3 wks')}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Bottom nav
// ─────────────────────────────────────────────────────────────
function BottomNav() {
  const tabs = [
    { id: 'pets', label: 'Pets', icon: Ico.pawO, c: 'var(--tangerine)' },
    { id: 'care', label: 'Care', icon: Ico.flame, c: 'var(--tangerine-700)', active: true },
    { id: 'social', label: 'Social', icon: Ico.heartO, c: 'var(--poppy)' },
    { id: 'match', label: 'Match', icon: Ico.bone, c: 'var(--lilac)' },
    { id: 'market', label: 'Market', icon: Ico.cart, c: 'var(--mint-700)' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 22, left: 12, right: 12, height: 62, borderRadius: 30,
      background: 'color-mix(in oklab, var(--surface) 86%, transparent)', backdropFilter: 'blur(14px)', WebkitBackdropFilter: 'blur(14px)',
      border: '1px solid var(--line)', boxShadow: '0 -2px 0 0 var(--line), 0 18px 34px -12px rgba(120,60,20,0.22)',
      display: 'flex', alignItems: 'center', padding: '0 6px', zIndex: 30,
    }}>
      {tabs.map(t => (
        <button key={t.id} style={{ flex: 1, height: 54, border: 'none', background: 'transparent', cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 3, color: t.active ? t.c : 'var(--ink-500)' }}>
          <div style={{ padding: '4px 14px', borderRadius: 999, background: t.active ? 'color-mix(in oklab, var(--sunny) 26%, transparent)' : 'transparent' }}>{t.icon(22, t.active ? t.c : 'currentColor')}</div>
          <span style={{ fontSize: 10.5, fontWeight: t.active ? 800 : 600 }}>{t.label}</span>
        </button>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Confetti + XP burst overlay
// ─────────────────────────────────────────────────────────────
function Burst({ burst }) {
  if (!burst) return null;
  const colors = ['var(--tangerine)', 'var(--poppy)', 'var(--mint)', 'var(--sunny)', 'var(--lilac)'];
  return (
    <div style={{ position: 'absolute', left: burst.x, top: burst.y, pointerEvents: 'none', zIndex: 40 }}>
      <div className="display" style={{ fontSize: 22, fontWeight: 800, color: 'var(--sunny-700)', animation: 'pf-float-up 1000ms cubic-bezier(.2,.8,.2,1) forwards', textShadow: '0 4px 10px rgba(255,197,61,0.7)', '--dx': '0px', '--rot': '0deg' }}>+{burst.xp} XP</div>
      {Array.from({ length: 14 }).map((_, i) => {
        const dx = (Math.random() - 0.5) * 130;
        const rot = Math.random() * 720;
        const dl = Math.random() * 120;
        const c = colors[i % colors.length];
        return <div key={i} style={{ position: 'absolute', left: 0, top: 0, width: 7, height: 9, borderRadius: 2, background: c, '--cdx': `${dx}px`, '--crot': `${rot}deg`, animation: `pf-confetti ${900 + Math.random() * 500}ms cubic-bezier(.2,.6,.4,1) forwards`, animationDelay: `${dl}ms` }}/>;
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Badge detail sheet
// ─────────────────────────────────────────────────────────────
function BadgeSheet({ badge, onClose }) {
  if (!badge) return null;
  return (
    <div onClick={onClose} style={{ position: 'absolute', inset: 0, zIndex: 60, display: 'flex', alignItems: 'flex-end', background: 'rgba(20,8,2,0.4)', backdropFilter: 'blur(2px)' }}>
      <div onClick={e => e.stopPropagation()} style={{ width: '100%', background: 'var(--surface)', borderRadius: '28px 28px 0 0', padding: '12px 22px 34px', boxShadow: '0 -10px 40px rgba(0,0,0,0.2)' }}>
        <div style={{ width: 38, height: 4, borderRadius: 2, background: 'var(--line-2)', margin: '0 auto 18px' }}/>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
        <div style={{ width: 84, height: 84, borderRadius: '50%', marginBottom: 6, display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: badge.owned ? `radial-gradient(circle at 38% 28%, color-mix(in oklab,${badge.c} 55%, white), ${badge.c} 58%, color-mix(in oklab,${badge.c} 60%, black) 100%)` : 'var(--surface-2)',
            border: badge.owned ? `3px solid color-mix(in oklab,${badge.c} 70%, white)` : '1px solid var(--line)',
            boxShadow: badge.owned ? `0 8px 0 0 ${badge.rim||'rgba(0,0,0,0.2)'}, 0 16px 30px -10px ${badge.c}` : 'none',
            filter: badge.owned ? 'none' : 'grayscale(1)', opacity: badge.owned ? 1 : 0.5 }}>
          {(() => { const IC = ICON_MAP[badge.id]; return IC ? <IC s={40}/> : null; })()}
        </div>
          <div className="display" style={{ fontSize: 20, fontWeight: 800, color: 'var(--ink-950)', whiteSpace: 'nowrap' }}>{badge.l}</div>
          <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink-500)', textAlign: 'center', maxWidth: 260 }}>{badge.owned ? 'You unlocked this badge — nice work keeping up the routine!' : 'Keep logging care to unlock this badge.'}</div>
          <div style={{ marginTop: 10, fontSize: 12.5, fontWeight: 800, padding: '7px 16px', borderRadius: 12, color: badge.owned ? 'var(--mint-700)' : 'var(--ink-500)', background: badge.owned ? 'var(--mint-soft)' : 'var(--surface-2)' }}>{badge.owned ? '✅ Earned!' : `Progress: ${badge.hint}`}</div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Tweaks panel (self-contained)
// ─────────────────────────────────────────────────────────────
function TweaksPanel({ open, onClose, depth, setDepth, dark, setDark, reduce, setReduce }) {
  if (!open) return null;
  const seg = (val, cur, set, opts) => (
    <div style={{ display: 'flex', gap: 4, background: 'var(--surface-2)', padding: 4, borderRadius: 12 }}>
      {opts.map(o => (
        <button key={o.v} onClick={() => set(o.v)} style={{ flex: 1, padding: '7px 4px', borderRadius: 9, border: 'none', cursor: 'pointer', fontSize: 11.5, fontWeight: 800, fontFamily: 'inherit',
          background: cur === o.v ? 'var(--surface)' : 'transparent', color: cur === o.v ? 'var(--poppy-700)' : 'var(--ink-500)', boxShadow: cur === o.v ? 'var(--shadow-soft)' : 'none' }}>{o.l}</button>
      ))}
    </div>
  );
  return (
    <div onClick={onClose} style={{ position: 'absolute', inset: 0, zIndex: 70, display: 'flex', alignItems: 'flex-end', background: 'rgba(20,8,2,0.35)' }}>
      <div onClick={e => e.stopPropagation()} style={{ width: '100%', background: 'var(--surface)', borderRadius: '28px 28px 0 0', padding: '12px 20px 30px' }}>
        <div style={{ width: 38, height: 4, borderRadius: 2, background: 'var(--line-2)', margin: '0 auto 14px' }}/>
        <div className="display" style={{ fontSize: 18, fontWeight: 800, color: 'var(--ink-950)', marginBottom: 14 }}>Tweaks</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div><div style={{ fontSize: 12, fontWeight: 800, color: 'var(--ink-500)', marginBottom: 6 }}>3D depth</div>{seg(depth, depth, setDepth, [{ v: 0, l: 'Off' }, { v: 0.5, l: 'Subtle' }, { v: 1, l: 'Full' }])}</div>
          <div><div style={{ fontSize: 12, fontWeight: 800, color: 'var(--ink-500)', marginBottom: 6 }}>Appearance</div>{seg(dark, dark, setDark, [{ v: false, l: '☀︎ Light' }, { v: true, l: '☾ Dark' }])}</div>
          <div><div style={{ fontSize: 12, fontWeight: 800, color: 'var(--ink-500)', marginBottom: 6 }}>Motion</div>{seg(reduce, reduce, setReduce, [{ v: false, l: 'Animated' }, { v: true, l: 'Reduced' }])}</div>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Care screen
// ─────────────────────────────────────────────────────────────
const PET = { name: 'Jhontu', level: 2, title: 'Curious Pup', xp: 100, xpMax: 250, streak: 1 };
const INITIAL_TASKS = [
  { id: 't1', title: 'Morning Feeding', type: 'feeding', time: '8:00 AM', xp: 12, due: true, done: false, freq: 'daily' },
  { id: 't2', title: 'Evening Feeding', type: 'feeding', time: '6:00 PM', xp: 12, due: true, done: false, freq: 'daily' },
  { id: 't3', title: 'Interactive Playtime', type: 'playtime', time: 'Daily', xp: 20, done: false, freq: 'daily' },
  { id: 't4', title: 'Clicker Training', type: 'training', time: 'As needed', xp: 15, done: false, freq: 'less' },
  { id: 't5', title: 'Laser Pointer Chase', type: 'playtime', time: 'As needed', xp: 15, done: false, freq: 'less' },
];

function CareScreen({ onSparkle, onMoon, dark }) {
  const [tasks, setTasks] = useState(INITIAL_TASKS);
  const [burst, setBurst] = useState(null);
  const [badge, setBadge] = useState(null);
  const scrollRef = useRef(null);

  const daily = tasks.filter(t => t.freq === 'daily');
  const less = tasks.filter(t => t.freq === 'less');
  const doneToday = daily.filter(t => t.done).length;

  function toggle(task, btnEl) {
    const nowDone = !task.done;
    setTasks(ts => ts.map(t => t.id === task.id ? { ...t, done: nowDone, due: nowDone ? false : t.due } : t));
    if (nowDone && btnEl && scrollRef.current) {
      const br = btnEl.getBoundingClientRect();
      const pr = scrollRef.current.getBoundingClientRect();
      setBurst({ x: br.left - pr.left + br.width / 2 - 20, y: br.top - pr.top + scrollRef.current.scrollTop - 4, xp: task.xp });
      setTimeout(() => setBurst(null), 1100);
    }
  }

  return (
    <div style={{ position: 'absolute', inset: 0, background: 'var(--cream)' }}>
      <div ref={scrollRef} style={{ position: 'absolute', inset: 0, overflowY: 'auto', paddingTop: 52, paddingBottom: 92 }}>
        {/* App bar */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '4px 16px 12px' }}>
          <button style={{ display: 'flex', alignItems: 'center', gap: 9, background: 'transparent', border: 'none', cursor: 'pointer', padding: 0 }}>
            <Avatar size={40}/>
            <div style={{ textAlign: 'left' }}>
              <div style={{ fontSize: 9, fontWeight: 800, letterSpacing: 0.7, color: 'var(--ink-300)' }}>CARE</div>
              <div style={{ fontSize: 16, fontWeight: 800, color: 'var(--ink-950)', display: 'flex', alignItems: 'center', gap: 3 }}>{PET.name} {Ico.chevDown(15, 'var(--ink-500)')}</div>
            </div>
          </button>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={onSparkle} style={{ width: 40, height: 40, borderRadius: '50%', border: '1px solid var(--line)', background: 'var(--surface)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--lilac-700)', boxShadow: 'var(--shadow-soft)' }}>{Ico.sparkle(18, 'currentColor')}</button>
            <button onClick={onMoon} style={{ width: 40, height: 40, borderRadius: '50%', border: '1px solid var(--line)', background: 'var(--surface)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--ink-700)', boxShadow: 'var(--shadow-soft)' }}>{dark ? Ico.sun(19, 'var(--sunny-700)') : Ico.moon(19, 'currentColor')}</button>
          </div>
        </div>

        <Hero pet={PET} doneToday={doneToday} totalToday={daily.length}/>

        <div style={{ height: 16 }}/>
        <DateStrip/>

        <div style={{ height: 18 }}/>
        <div style={{ padding: '0 16px' }}>
          <SectionLabel accent="var(--lilac)" right={<button style={{ background: 'transparent', border: 'none', color: 'var(--lilac-700)', fontWeight: 800, fontSize: 12.5, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 2 }}>Vault {Ico.chevR(13, 'var(--lilac-700)')}</button>}>
            Trophy room
          </SectionLabel>
        </div>
        <div style={{ padding: '0 2px', marginTop: -2 }}>
          <div style={{ padding: '0 14px 4px' }}><span style={{ fontSize: 11, fontWeight: 800, color: 'var(--mint-700)', background: 'var(--mint-soft)', padding: '3px 10px', borderRadius: 999 }}>1 / 6 earned</span></div>
          <TrophyCarousel onTap={setBadge}/>
        </div>

        <div style={{ height: 14 }}/>
        <div style={{ padding: '0 16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 2px 10px' }}>
            <span style={{ fontSize: 12, fontWeight: 800, letterSpacing: 1, color: 'var(--ink-500)' }}>TODAY'S QUESTS</span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 11, fontWeight: 800, color: doneToday === daily.length ? 'var(--mint-700)' : 'var(--sunny-700)', background: doneToday === daily.length ? 'var(--mint-soft)' : 'var(--sunny-soft)', padding: '4px 10px', borderRadius: 999 }}>{doneToday === daily.length ? 'All done! 🎉' : `${doneToday}/${daily.length} done`}</span>
              <button style={{ width: 30, height: 30, borderRadius: '50%', border: 'none', background: 'var(--lilac-soft)', color: 'var(--lilac-700)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{Ico.sparkle(15, 'currentColor')}</button>
            </div>
          </div>
          <FreqDivider label="DAILY"/>
          {daily.map(t => <TaskCard key={t.id} task={t} onToggle={toggle}/>)}
          <FreqDivider label="LESS OFTEN"/>
          {less.map(t => <TaskCard key={t.id} task={t} onToggle={toggle}/>)}
        </div>

        <div style={{ height: 22 }}/>
        <div style={{ padding: '0 16px' }}>
          <SectionLabel accent="var(--mint)">This week</SectionLabel>
          <WeeklyChart/>
        </div>

        <div style={{ height: 18 }}/>
        <div style={{ padding: '0 16px' }}>
          <UtilityBanner/>
        </div>

        <Burst burst={burst}/>
      </div>

      <BottomNav/>
      <BadgeSheet badge={badge} onClose={() => setBadge(null)}/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Root
// ─────────────────────────────────────────────────────────────
function App() {
  const [depth, setDepth] = useState(1);
  const [dark, setDark] = useState(false);
  const [reduce, setReduce] = useState(false);
  const [tweaksOpen, setTweaksOpen] = useState(false);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light');
  }, [dark]);
  useEffect(() => {
    document.body.classList.toggle('reduce-motion', reduce);
  }, [reduce]);

  return (
    <DepthCtx.Provider value={reduce ? 0 : depth}>
      <IOSDevice width={402} height={874} dark={dark}>
        <CareScreen onSparkle={() => setTweaksOpen(true)} onMoon={() => setDark(d => !d)} dark={dark}/>
        <TweaksPanel open={tweaksOpen} onClose={() => setTweaksOpen(false)} depth={depth} setDepth={setDepth} dark={dark} setDark={setDark} reduce={reduce} setReduce={setReduce}/>
      </IOSDevice>
    </DepthCtx.Provider>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
