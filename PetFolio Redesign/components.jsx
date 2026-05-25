// components.jsx — Shared building blocks for PetFolio

// ─── Iconography (stroke + filled) ─────────────────────────
const I = {
  paw: (size = 22, fill = 'currentColor') => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <ellipse cx="6" cy="9" rx="2.1" ry="2.6" fill={fill}/>
      <ellipse cx="10" cy="5.6" rx="2" ry="2.5" fill={fill}/>
      <ellipse cx="14" cy="5.6" rx="2" ry="2.5" fill={fill}/>
      <ellipse cx="18" cy="9" rx="2.1" ry="2.6" fill={fill}/>
      <path d="M12 10c-3.6 0-6.2 3-6.2 5.7 0 2.1 1.7 3.3 3.5 3.3 1.2 0 1.7-.6 2.7-.6s1.5.6 2.7.6c1.8 0 3.5-1.2 3.5-3.3 0-2.7-2.6-5.7-6.2-5.7z" fill={fill}/>
    </svg>
  ),
  pawOutline: (size = 22, color = 'currentColor') => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.8">
      <ellipse cx="6" cy="9" rx="2.1" ry="2.6"/>
      <ellipse cx="10" cy="5.6" rx="2" ry="2.5"/>
      <ellipse cx="14" cy="5.6" rx="2" ry="2.5"/>
      <ellipse cx="18" cy="9" rx="2.1" ry="2.6"/>
      <path d="M12 10c-3.6 0-6.2 3-6.2 5.7 0 2.1 1.7 3.3 3.5 3.3 1.2 0 1.7-.6 2.7-.6s1.5.6 2.7.6c1.8 0 3.5-1.2 3.5-3.3 0-2.7-2.6-5.7-6.2-5.7z"/>
    </svg>
  ),
  heart: (size = 22, fill = 'currentColor') => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill}><path d="M12 21s-7.5-4.7-9.5-9.4C1 8 3.2 4 7 4c2 0 3.6 1.1 5 3 1.4-1.9 3-3 5-3 3.8 0 6 4 4.5 7.6C19.5 16.3 12 21 12 21z"/></svg>
  ),
  heartOutline: (size = 22, color = 'currentColor') => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.9" strokeLinejoin="round"><path d="M12 21s-7.5-4.7-9.5-9.4C1 8 3.2 4 7 4c2 0 3.6 1.1 5 3 1.4-1.9 3-3 5-3 3.8 0 6 4 4.5 7.6C19.5 16.3 12 21 12 21z"/></svg>
  ),
  bone: (size = 22, color = 'currentColor') => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={color}>
      <path d="M5.5 4.5a2.6 2.6 0 0 1 4.7 1.5l3.6 3.6a2.6 2.6 0 1 1 1.7 4.4l-3.6 3.6a2.6 2.6 0 1 1-4.4 1.7 2.6 2.6 0 1 1-1.7-4.4l3.6-3.6A2.6 2.6 0 1 1 5.5 4.5z"/>
    </svg>
  ),
  flame: (size = 22) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path d="M12 22c4.4 0 7-3.2 7-7 0-3.4-2.4-5.6-3.5-8.2-.6-1.4-.5-3.3-2-4.8-.6 2.3-1.7 2.6-3.3 4.8C8.6 8.9 5 10.6 5 15c0 3.8 2.6 7 7 7z" fill="#FF6B2C"/>
      <path d="M12 19.6c2.4 0 4.2-1.8 4.2-4.2 0-1.9-1.5-3-2.1-4.5-.4-.9 0-1.9-1-3-.4 1.4-1 1.6-2 3-.8 1.1-3.1 2.1-3.1 4.5 0 2.4 1.7 4.2 4 4.2z" fill="#FFC53D"/>
    </svg>
  ),
  star: (size = 22, fill = '#FFC53D') => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={fill}><path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4l-5.9 3.1 1.2-6.5L2.5 9.4l6.6-.9z"/></svg>
  ),
  trophy: (size = 22) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path d="M6 4h12v3a6 6 0 0 1-12 0V4z" fill="#FFC53D"/>
      <path d="M5 5h-2a2 2 0 0 0 2 4M19 5h2a2 2 0 0 1-2 4" stroke="#FFC53D" strokeWidth="1.6" fill="none"/>
      <path d="M9 13h6v3H9z M8 19h8v2H8z" fill="#E0651E"/>
    </svg>
  ),
  bell: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 7 3 9H3c0-2 3-2 3-9z"/><path d="M10 21a2 2 0 0 0 4 0"/></svg>,
  back: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 6l-6 6 6 6"/></svg>,
  chevron: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 6l6 6-6 6"/></svg>,
  chevronDown: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 9l6 6 6-6"/></svg>,
  close: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round"><path d="M6 6l12 12M18 6L6 18"/></svg>,
  plus: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round"><path d="M12 5v14M5 12h14"/></svg>,
  check: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12l5 5 9-11"/></svg>,
  comment: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12c0 4.4-4 8-9 8-1.4 0-2.8-.3-4-.8L3 21l1.4-4.4C3.5 15.2 3 13.6 3 12c0-4.4 4-8 9-8s9 3.6 9 8z"/></svg>,
  share: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="12" r="2.6"/><circle cx="18" cy="6" r="2.6"/><circle cx="18" cy="18" r="2.6"/><path d="M8.2 10.8l7.6-3.6M8.2 13.2l7.6 3.6"/></svg>,
  bookmark: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M6 4h12v17l-6-4-6 4z"/></svg>,
  search: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round"><circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4-4"/></svg>,
  filter: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round"><circle cx="7" cy="7" r="2.2"/><circle cx="17" cy="17" r="2.2"/><path d="M9 7h11M4 17h11"/></svg>,
  cart: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M3 4h2l2.4 11.4a2 2 0 0 0 2 1.6h8.7a2 2 0 0 0 2-1.6L21 9H7"/><circle cx="9" cy="20" r="1.6"/><circle cx="18" cy="20" r="1.6"/></svg>,
  syringe: (s=22) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="var(--mint-700)" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M18 3l3 3M14 7l3-3 3 3-3 3-3-3z"/><path d="M14 7l-9 9-1 4 4-1 9-9"/><path d="M8 13l3 3"/></svg>,
  pill: (s=22) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none"><rect x="3" y="9" width="18" height="6" rx="3" fill="var(--poppy)"/><rect x="3" y="9" width="9" height="6" rx="3" fill="var(--poppy-soft)"/><rect x="3" y="9" width="18" height="6" rx="3" stroke="var(--poppy-700)" strokeWidth="1.2" fill="none"/></svg>,
  stethoscope: (s=22) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke="var(--mint-700)" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M5 3v6a4 4 0 0 0 8 0V3"/><path d="M9 13v2a5 5 0 0 0 10 0v-2"/><circle cx="19" cy="9" r="2"/></svg>,
  send: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M3 11l18-8-8 18-2-8z"/></svg>,
  spark: (s=18) => <svg width={s} height={s} viewBox="0 0 24 24" fill="none"><path d="M12 2v6M12 16v6M2 12h6M16 12h6M5 5l4 4M15 15l4 4M5 19l4-4M15 9l4-4" stroke="var(--sunny)" strokeWidth="2" strokeLinecap="round"/></svg>,
  location: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M12 21c-4-5-7-8.5-7-12a7 7 0 0 1 14 0c0 3.5-3 7-7 12z"/><circle cx="12" cy="9" r="2.4"/></svg>,
  settings: (s=22,c='currentColor') => <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></svg>,
};

// ─── Species (the 6 supported pet classes) ─────────────────
const SPECIES = [
  { id: 'dog', label: 'Dog',   emoji: '🐶', color: 'var(--tangerine)', soft: 'var(--tangerine-soft)' },
  { id: 'cat', label: 'Cat',   emoji: '🐱', color: 'var(--poppy)', soft: 'var(--poppy-soft)' },
  { id: 'rabbit', label: 'Rabbit', emoji: '🐰', color: 'var(--lilac)',  soft: 'var(--lilac-soft)' },
  { id: 'bird', label: 'Bird', emoji: '🐦', color: 'var(--sky)',       soft: 'var(--sky-soft)' },
  { id: 'fish', label: 'Fish', emoji: '🐠', color: 'var(--mint)',      soft: 'var(--mint-soft)' },
  { id: 'reptile', label: 'Reptile', emoji: '🦎', color: 'var(--sunny)', soft: 'var(--sunny-soft)' },
];

// ─── Pet avatar — gradient disc + emoji, optional ring ─────
function PetAvatar({ size = 48, species = 'cat', ring = false, glow = false, style }) {
  const sp = SPECIES.find(s => s.id === species) || SPECIES[0];
  const inner = size - (ring ? 6 : 0);
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: ring ? `conic-gradient(from 220deg, var(--tangerine), var(--poppy), var(--sunny), var(--mint), var(--tangerine))` : 'transparent',
      padding: ring ? 3 : 0,
      boxShadow: glow ? `0 8px 22px -8px ${sp.color}` : 'none',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      flexShrink: 0,
      ...style,
    }}>
      <div style={{
        width: inner, height: inner, borderRadius: '50%',
        background: `radial-gradient(circle at 30% 30%, ${sp.soft}, ${sp.color} 90%)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: inner * 0.55, lineHeight: 1,
        border: ring ? '2px solid var(--surface)' : 'none',
      }}>
        <span style={{ filter: 'drop-shadow(0 1px 1px rgba(0,0,0,0.1))' }}>{sp.emoji}</span>
      </div>
    </div>
  );
}

// ─── Pill button (primary / secondary / ghost / soft) ───────
function Pill({ children, variant = 'primary', onClick, disabled, size = 'md', icon, iconRight, full, style, color }) {
  const heights = { sm: 36, md: 48, lg: 56, xl: 64 };
  const pads = { sm: 14, md: 22, lg: 26, xl: 30 };
  const fs = { sm: 14, md: 16, lg: 17, xl: 18 };
  const palette = {
    primary: { bg: color || 'var(--tangerine)', fg: '#fff', sh: '0 6px 0 0 var(--tangerine-700), 0 14px 24px -10px rgba(255,138,76,0.6)' },
    soft:    { bg: 'var(--tangerine-soft)', fg: 'var(--tangerine-700)', sh: 'none' },
    ghost:   { bg: 'transparent', fg: 'var(--ink-950)', sh: 'none' },
    outline: { bg: 'var(--surface)', fg: 'var(--ink-950)', sh: 'inset 0 0 0 2px var(--line-2)' },
    dark:    { bg: 'var(--ink-950)', fg: 'var(--cream)', sh: '0 6px 0 0 #000, 0 12px 24px -10px rgba(0,0,0,0.4)' },
  };
  const p = palette[variant] || palette.primary;
  return (
    <button onClick={onClick} disabled={disabled} style={{
      height: heights[size], padding: `0 ${pads[size]}px`,
      borderRadius: 999, border: 'none', cursor: 'pointer',
      background: p.bg, color: p.fg,
      fontSize: fs[size], fontWeight: 800, letterSpacing: 0.1,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
      boxShadow: p.sh,
      width: full ? '100%' : 'auto',
      opacity: disabled ? 0.5 : 1,
      transition: 'transform 120ms ease, box-shadow 120ms ease',
      fontFamily: 'inherit',
      ...style,
    }}
      onPointerDown={e => { e.currentTarget.style.transform = 'translateY(2px)'; e.currentTarget.style.boxShadow = p.sh ? p.sh.replace('6px', '2px') : 'none'; }}
      onPointerUp={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = p.sh; }}
      onPointerLeave={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = p.sh; }}
    >
      {icon}
      {children}
      {iconRight}
    </button>
  );
}

// ─── Round icon button ─────────────────────────────────────
function IconBtn({ children, onClick, size = 44, bg = 'var(--surface)', color = 'var(--ink-950)', shadow = true, style }) {
  return (
    <button onClick={onClick} style={{
      width: size, height: size, borderRadius: '50%',
      background: bg, color, border: 'none', cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: shadow ? 'var(--shadow-soft)' : 'none',
      flexShrink: 0,
      ...style,
    }}>{children}</button>
  );
}

// ─── Wave header — organic top SVG ─────────────────────────
function WaveHeader({ color = 'var(--tangerine)', height = 140, children, style }) {
  return (
    <div style={{ position: 'relative', background: color, paddingBottom: 28, ...style }}>
      {children}
      <svg viewBox="0 0 412 60" preserveAspectRatio="none" style={{
        position: 'absolute', left: 0, right: 0, bottom: -1, width: '100%', height: 56, display: 'block',
      }}>
        <path d="M0,40 C90,10 160,70 220,40 C280,15 340,60 412,30 L412,60 L0,60 Z" fill="var(--cream)"/>
      </svg>
    </div>
  );
}

// ─── Squircle card ─────────────────────────────────────────
function Card({ children, style, onClick, color = 'var(--surface)', pad = 18, r = 28 }) {
  return (
    <div onClick={onClick} style={{
      background: color, borderRadius: r, padding: pad,
      boxShadow: 'var(--shadow-card)',
      border: '1px solid var(--line)',
      ...style,
    }}>{children}</div>
  );
}

// ─── Paw toggle (custom switch shaped like a paw track) ────
function PawToggle({ checked, onChange, color = 'var(--tangerine)' }) {
  return (
    <button onClick={() => onChange(!checked)} style={{
      width: 54, height: 30, borderRadius: 999, border: 'none', cursor: 'pointer',
      background: checked ? color : 'var(--line-2)',
      position: 'relative', padding: 3,
      transition: 'background 200ms ease',
      boxShadow: 'inset 0 1px 3px rgba(0,0,0,0.08)',
    }}>
      <div style={{
        width: 24, height: 24, borderRadius: '50%',
        background: '#fff',
        position: 'absolute', top: 3, left: checked ? 27 : 3,
        transition: 'left 200ms cubic-bezier(.5,1.7,.5,1)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 2px 6px rgba(0,0,0,0.15)',
      }}>
        {I.paw(14, checked ? color : 'var(--ink-300)')}
      </div>
    </button>
  );
}

// ─── Bone slider ───────────────────────────────────────────
function BoneSlider({ value = 50, onChange, min = 0, max = 100, color = 'var(--tangerine)' }) {
  const pct = ((value - min) / (max - min)) * 100;
  return (
    <div style={{ position: 'relative', height: 28, padding: '8px 0' }}>
      <div style={{ height: 8, borderRadius: 999, background: 'var(--line-2)', position: 'relative' }}>
        <div style={{
          position: 'absolute', left: 0, top: 0, bottom: 0, width: `${pct}%`,
          background: `linear-gradient(90deg, ${color}, var(--poppy))`,
          borderRadius: 999,
        }}/>
      </div>
      <div style={{
        position: 'absolute', left: `calc(${pct}% - 18px)`, top: -2,
        width: 36, height: 32,
        transform: 'rotate(-15deg)',
      }}>
        {/* Bone-shaped thumb */}
        <svg viewBox="0 0 36 28" width="36" height="28">
          <g fill="#fff" stroke={color} strokeWidth="2">
            <circle cx="6" cy="8" r="5"/>
            <circle cx="6" cy="20" r="5"/>
            <circle cx="30" cy="8" r="5"/>
            <circle cx="30" cy="20" r="5"/>
            <rect x="8" y="9" width="20" height="10" rx="3"/>
          </g>
        </svg>
      </div>
      <input type="range" min={min} max={max} value={value} onChange={e => onChange(+e.target.value)} style={{
        position: 'absolute', inset: 0, opacity: 0, cursor: 'pointer', width: '100%',
      }}/>
    </div>
  );
}

// ─── Tail-wag loader ───────────────────────────────────────
function TailWagLoader({ size = 70, label }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10 }}>
      <div style={{ position: 'relative', width: size, height: size }}>
        {/* Body */}
        <div style={{
          position: 'absolute', left: '20%', top: '30%', width: '60%', height: '55%',
          borderRadius: '50% 60% 55% 50% / 60% 50% 60% 70%',
          background: 'var(--tangerine)',
        }}/>
        {/* Head */}
        <div style={{
          position: 'absolute', left: '10%', top: '15%', width: '38%', height: '42%',
          borderRadius: '50%',
          background: 'var(--tangerine)',
        }}/>
        {/* Ear */}
        <div style={{
          position: 'absolute', left: '8%', top: '5%', width: '18%', height: '24%',
          borderRadius: '60% 40% 50% 50%',
          background: 'var(--tangerine-700)',
          transform: 'rotate(-25deg)',
        }}/>
        {/* Eye */}
        <div style={{
          position: 'absolute', left: '28%', top: '28%', width: 5, height: 5, borderRadius: '50%',
          background: '#fff',
        }}/>
        {/* Tail (wagging) */}
        <div style={{
          position: 'absolute', right: '8%', top: '32%', width: '24%', height: '10%',
          borderRadius: '60% 40% 50% 50%',
          background: 'var(--tangerine)',
          transformOrigin: '0% 50%',
          animation: 'pf-tail-wag 350ms ease-in-out infinite',
        }}/>
      </div>
      {label && <div style={{ fontSize: 13, color: 'var(--ink-500)', fontWeight: 700 }}>{label}</div>}
    </div>
  );
}

// ─── Reaction burst (paws/hearts/treats flying up) ─────────
function ReactionBurst({ items, kind = 'paw' }) {
  if (!items || items.length === 0) return null;
  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'visible' }}>
      {items.map(it => {
        const dx = (Math.random() - 0.5) * 60;
        const rot = (Math.random() - 0.5) * 60;
        const delay = Math.random() * 80;
        const k = it.kind || kind;
        const glyph = k === 'heart' ? '❤️' : k === 'treat' ? '🦴' : k === 'star' ? '⭐' : '🐾';
        return (
          <div key={it.id} style={{
            position: 'absolute', left: it.x - 14, top: it.y - 14, fontSize: 26,
            '--dx': `${dx}px`, '--rot': `${rot}deg`,
            animation: `pf-float-up 900ms cubic-bezier(.2,.8,.2,1) forwards`,
            animationDelay: `${delay}ms`,
          }}>{glyph}</div>
        );
      })}
    </div>
  );
}

// ─── Bottom nav (5 tabs) ───────────────────────────────────
function BottomNav({ active, onChange, motif = 'confident' }) {
  const tabs = [
    { id: 'home',   label: 'Pets',   icon: I.pawOutline, iconActive: I.paw,         color: 'var(--tangerine)' },
    { id: 'care',   label: 'Care',   icon: (s,c)=>I.flame(s),         iconActive: s=>I.flame(s),       color: 'var(--sunny-700)' },
    { id: 'social', label: 'Social', icon: I.heartOutline,  iconActive: I.heart,    color: 'var(--poppy)' },
    { id: 'match',  label: 'Match',  icon: (s,c)=>I.bone(s,c), iconActive: s=>I.bone(s,'var(--lilac)'), color: 'var(--lilac)' },
    { id: 'market', label: 'Market', icon: I.cart,                iconActive: (s,c)=>I.cart(s,'var(--mint-700)'), color: 'var(--mint-700)' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 10, left: 12, right: 12,
      height: 64, borderRadius: 32,
      background: 'var(--surface)',
      boxShadow: '0 -2px 0 0 var(--line), 0 20px 36px -12px rgba(120,60,20,0.18)',
      border: '1px solid var(--line)',
      display: 'flex', alignItems: 'center', justifyContent: 'space-around',
      padding: '0 4px',
      zIndex: 30,
    }}>
      {tabs.map(t => {
        const isActive = active === t.id;
        return (
          <button key={t.id} onClick={() => onChange(t.id)} style={{
            flex: 1, height: 56, border: 'none', background: 'transparent', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
            gap: 2, position: 'relative',
            color: isActive ? t.color : 'var(--ink-500)',
          }}>
            <div style={{
              padding: '4px 14px', borderRadius: 999,
              background: isActive ? `color-mix(in oklab, ${t.color} 14%, transparent)` : 'transparent',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              transition: 'background 200ms',
            }}>
              {isActive
                ? (typeof t.iconActive === 'function' ? t.iconActive(22, t.color) : t.iconActive)
                : (typeof t.icon === 'function' ? t.icon(22, 'currentColor') : t.icon)}
            </div>
            <div style={{ fontSize: 11, fontWeight: isActive ? 800 : 600, letterSpacing: 0.1 }}>{t.label}</div>
          </button>
        );
      })}
    </div>
  );
}

// ─── Wave divider (used inside cards / between sections) ───
function WaveDivider({ color = 'var(--tangerine-soft)', flip = false, height = 24 }) {
  return (
    <svg viewBox="0 0 412 24" preserveAspectRatio="none" style={{ width: '100%', height, display: 'block', transform: flip ? 'scaleY(-1)' : '' }}>
      <path d="M0,12 C100,0 180,24 240,12 C300,0 360,18 412,8 L412,24 L0,24 Z" fill={color}/>
    </svg>
  );
}

// ─── Section header (in-app, with motif accent) ────────────
function SectionTitle({ children, accent = 'var(--tangerine)', right }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, padding: '0 4px 10px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0, flex: 1 }}>
        <div style={{ width: 6, height: 22, borderRadius: 4, background: accent, flexShrink: 0 }}/>
        <h3 style={{ fontSize: 17, fontWeight: 800, color: 'var(--ink-950)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', lineHeight: 1.2 }}>{children}</h3>
      </div>
      {right && <div style={{ flexShrink: 0 }}>{right}</div>}
    </div>
  );
}

// ─── Placeholder image (gradient + monospace label) ─────────
function PlaceholderImg({ label = 'photo', color = 'var(--tangerine)', soft = 'var(--tangerine-soft)', height = 180, r = 24, style, emoji }) {
  return (
    <div style={{
      width: '100%', height, borderRadius: r,
      background: `linear-gradient(135deg, ${soft}, ${color})`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      position: 'relative', overflow: 'hidden',
      ...style,
    }}>
      {emoji && <div style={{ fontSize: height * 0.45, filter: 'drop-shadow(0 6px 18px rgba(0,0,0,0.15))' }}>{emoji}</div>}
      {!emoji && (
        <div style={{
          fontFamily: 'ui-monospace, SFMono-Regular, monospace', fontSize: 11,
          color: 'rgba(255,255,255,0.85)', letterSpacing: 1, textTransform: 'uppercase',
          background: 'rgba(0,0,0,0.18)', padding: '4px 10px', borderRadius: 999,
        }}>{label}</div>
      )}
      {/* subtle paw watermark */}
      <div style={{ position: 'absolute', right: 10, bottom: 10, opacity: 0.18 }}>
        {I.paw(28, '#fff')}
      </div>
    </div>
  );
}

// ─── Confetti element (for celebrations) ───────────────────
function Confetti({ count = 50, colors }) {
  const cs = colors || ['var(--tangerine)','var(--poppy)','var(--mint)','var(--sunny)','var(--lilac)'];
  const items = Array.from({ length: count }).map((_, i) => {
    const x = Math.random() * 100;
    const dx = (Math.random() - 0.5) * 60;
    const rot = Math.random() * 720 + 360;
    const delay = Math.random() * 600;
    const duration = 1800 + Math.random() * 1200;
    const c = cs[i % cs.length];
    const w = 8 + Math.random() * 6;
    const h = 4 + Math.random() * 6;
    return (
      <div key={i} style={{
        position: 'absolute', left: `${x}%`, top: 0, width: w, height: h, borderRadius: 2,
        background: c, '--cx': '0px', '--cdx': `${dx}px`, '--crot': `${rot}deg`,
        animation: `pf-confetti-fall ${duration}ms cubic-bezier(.2,.6,.4,1) forwards`,
        animationDelay: `${delay}ms`,
      }}/>
    );
  });
  return <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'hidden' }}>{items}</div>;
}

// Export to window
Object.assign(window, {
  I, SPECIES, PetAvatar, Pill, IconBtn, WaveHeader, Card, PawToggle, BoneSlider,
  TailWagLoader, ReactionBurst, BottomNav, WaveDivider, SectionTitle, PlaceholderImg, Confetti,
});
