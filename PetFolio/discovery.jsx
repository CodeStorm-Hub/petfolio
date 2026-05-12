// Discovery — Tinder-style playdate matching.
// - Top card is a swipeable stack, 70% of screen reserved for imagery.
// - Bio condensed to: name+age, breed, fuzzy distance, play-style chips, 1-line bio.
// - Distance is ALWAYS fuzzy ("Within 2 miles") — never address, never lat/lng readout.
// - Pass / Greet / Match are 64dp, with optional Super-paw (vet-verified).

function Discovery({ active, onBack, onOpenSwitcher, onTab, outdoor }) {
  const [idx, setIdx] = React.useState(0);
  const [exitDir, setExitDir] = React.useState(null);
  const [expanded, setExpanded] = React.useState(false);

  const candidates = DISCOVERY_DECK;
  const top = candidates[idx % candidates.length];
  const next = candidates[(idx + 1) % candidates.length];
  const after = candidates[(idx + 2) % candidates.length];

  const advance = (dir) => {
    setExitDir(dir);
    setTimeout(() => { setIdx(i => i + 1); setExitDir(null); setExpanded(false); }, 280);
  };

  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      background: outdoor ? '#fff' : TOKENS.surface1,
      fontFamily: 'Inter, system-ui, sans-serif', color: TOKENS.ink950,
      position: 'relative', overflow: 'hidden',
    }}>
      <DiscoveryHeader active={active} onBack={onBack} onOpenSwitcher={onOpenSwitcher}/>

      <div style={{
        flex: 1, position: 'relative', padding: '4px 16px 6px',
        display: 'flex', flexDirection: 'column', minHeight: 0,
      }}>
        <div style={{ position: 'relative', flex: 1, minHeight: 0 }}>
          {/* Stack: 2 background cards, 1 top */}
          <StackCard candidate={after}  depth={2}/>
          <StackCard candidate={next}   depth={1}/>
          <SwipeCard candidate={top}    expanded={expanded} onToggleExpand={() => setExpanded(e => !e)} exitDir={exitDir}/>
        </div>

        <ActionDock onPass={() => advance('left')} onGreet={() => advance('up')} onMatch={() => advance('right')}/>
      </div>

      <TabBarDiscovery onTab={onTab}/>
    </div>
  );
}

function DiscoveryHeader({ active, onBack, onOpenSwitcher }) {
  return (
    <div style={{ padding: '58px 16px 8px', display: 'flex', alignItems: 'center', gap: 12 }}>
      <button onClick={onBack} aria-label="Back" style={{
        width: 40, height: 40, borderRadius: '50%', border: 'none', cursor: 'pointer',
        background: TOKENS.surface0, color: TOKENS.ink700,
        boxShadow: '0 1px 2px rgba(11,18,32,0.06), 0 0 0 0.5px ' + TOKENS.line200,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="10" height="18" viewBox="0 0 10 18">
          <path d="M9 1L1 9l8 8" stroke={TOKENS.ink700} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </button>
      <div style={{ flex: 1, textAlign: 'center' }}>
        <div style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 19, letterSpacing: '-0.01em' }}>Playdates</div>
        <div style={{ fontSize: 11, color: TOKENS.ink500, letterSpacing: '0.04em', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5 }}>
          <FuzzyPin/>
          <span>Within 3 miles · {active.name}'s area</span>
        </div>
      </div>
      <button aria-label="Filters" style={{
        width: 40, height: 40, borderRadius: '50%', border: 'none', cursor: 'pointer',
        background: TOKENS.surface0, color: TOKENS.ink700,
        boxShadow: '0 1px 2px rgba(11,18,32,0.06), 0 0 0 0.5px ' + TOKENS.line200,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke={TOKENS.ink700} strokeWidth="1.75" strokeLinecap="round">
          <path d="M2 4h14M4 9h10M6 14h6"/>
        </svg>
      </button>
    </div>
  );
}

// Static back-of-stack card
function StackCard({ candidate, depth }) {
  const scale = 1 - depth * 0.04;
  const offsetY = depth * 8;
  return (
    <div style={{
      position: 'absolute', inset: 0,
      transform: `translateY(${offsetY}px) scale(${scale})`,
      opacity: 1 - depth * 0.15, zIndex: 10 - depth,
      pointerEvents: 'none', transition: 'all 280ms cubic-bezier(0.2,0.8,0.2,1)',
    }}>
      <CardSurface candidate={candidate} ghost/>
    </div>
  );
}

function SwipeCard({ candidate, expanded, onToggleExpand, exitDir }) {
  const exitTransform =
    exitDir === 'left'  ? 'translate(-130%, 8%) rotate(-18deg)' :
    exitDir === 'right' ? 'translate(130%, 8%) rotate(18deg)'   :
    exitDir === 'up'    ? 'translate(0, -120%) rotate(0)'       : 'none';
  const exitOpacity = exitDir ? 0 : 1;
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 20,
      transform: exitTransform, opacity: exitOpacity,
      transition: 'all 280ms cubic-bezier(0.2,0.8,0.2,1)',
    }}>
      <CardSurface candidate={candidate} expanded={expanded} onToggleExpand={onToggleExpand}/>
    </div>
  );
}

function CardSurface({ candidate, ghost = false, expanded = false, onToggleExpand }) {
  const c = candidate;
  // Photo takes ~70% of card; info takes the rest. Expanded slides info up over photo.
  return (
    <div style={{
      width: '100%', height: '100%', borderRadius: 28, overflow: 'hidden',
      background: TOKENS.surface0,
      boxShadow: ghost
        ? '0 6px 18px -10px rgba(11,18,32,0.18)'
        : '0 22px 50px -20px rgba(11,18,32,0.32), 0 0 0 0.5px ' + TOKENS.line200,
      display: 'flex', flexDirection: 'column', position: 'relative',
    }}>
      {/* Photo region */}
      <div style={{
        flex: expanded ? '0 0 50%' : '0 0 70%',
        position: 'relative', overflow: 'hidden',
        transition: 'flex-basis 280ms cubic-bezier(0.2,0.8,0.2,1)',
        background: c.gradient,
      }}>
        {/* Photo dots — multi-photo affordance */}
        <div style={{
          position: 'absolute', top: 12, left: 12, right: 12,
          display: 'flex', gap: 4, zIndex: 4,
        }}>
          {[0,1,2,3,4].map(i => (
            <div key={i} style={{
              flex: 1, height: 3, borderRadius: 2,
              background: i === 0 ? 'rgba(255,255,255,0.95)' : 'rgba(255,255,255,0.35)',
            }}/>
          ))}
        </div>

        {/* Vet badge */}
        {c.verified && !ghost && (
          <div style={{
            position: 'absolute', top: 26, right: 12, zIndex: 4,
            background: 'rgba(255,255,255,0.95)', backdropFilter: 'blur(8px)',
            padding: '5px 9px 5px 7px', borderRadius: 999,
            display: 'flex', alignItems: 'center', gap: 5,
            fontSize: 11, fontWeight: 700, color: TOKENS.ink950,
            boxShadow: '0 4px 12px -4px rgba(11,18,32,0.25)',
          }}>
            <svg width="13" height="13" viewBox="0 0 14 14"><path d="M7 1l1.6 3.4L12 5l-2.5 2.6L10 11 7 9.3 4 11l.5-3.4L2 5l3.4-.6L7 1z" fill={TOKENS.success}/></svg>
            Vet verified
          </div>
        )}

        {/* Light + subject */}
        <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle at 30% 25%, rgba(255,255,255,0.32) 0%, transparent 55%)' }}/>
        <div style={{
          position: 'absolute', left: '50%', top: '55%', transform: 'translate(-50%, -50%)',
          width: '52%', aspectRatio: '1 / 1', borderRadius: '50%',
          background: `radial-gradient(circle at 35% 30%, ${lighten(c.subjectColor, 0.22)}, ${c.subjectColor} 58%, ${darken(c.subjectColor, 0.18)} 100%)`,
          boxShadow: '0 22px 38px -14px rgba(0,0,0,0.42)',
        }}/>
        {c.species === 'dog' && (
          <>
            <div style={{
              position: 'absolute', left: '32%', top: '34%', width: '14%', aspectRatio: '1/1.4',
              background: darken(c.subjectColor, 0.22), borderRadius: '50% 50% 30% 30%',
              transform: 'rotate(-18deg)',
            }}/>
            <div style={{
              position: 'absolute', right: '32%', top: '34%', width: '14%', aspectRatio: '1/1.4',
              background: darken(c.subjectColor, 0.22), borderRadius: '50% 50% 30% 30%',
              transform: 'rotate(18deg)',
            }}/>
          </>
        )}
        {c.species === 'cat' && (
          <>
            <div style={{
              position: 'absolute', left: '34%', top: '30%', width: '11%', aspectRatio: '1/1',
              background: darken(c.subjectColor, 0.25), clipPath: 'polygon(0 100%, 50% 0, 100% 100%)',
            }}/>
            <div style={{
              position: 'absolute', right: '34%', top: '30%', width: '11%', aspectRatio: '1/1',
              background: darken(c.subjectColor, 0.25), clipPath: 'polygon(0 100%, 50% 0, 100% 100%)',
            }}/>
          </>
        )}

        {/* Bottom photo gradient */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0, height: '38%',
          background: 'linear-gradient(180deg, rgba(0,0,0,0) 0%, rgba(0,0,0,0.55) 100%)',
        }}/>

        {/* Name + age overlay (always visible on photo) */}
        <div style={{
          position: 'absolute', left: 18, right: 18, bottom: 16, color: '#fff', zIndex: 3,
        }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
            <span style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 32, letterSpacing: '-0.02em', lineHeight: 1 }}>{c.name}</span>
            <span style={{ fontFamily: 'Sora', fontWeight: 500, fontSize: 22, opacity: 0.92, letterSpacing: '-0.01em', lineHeight: 1 }}>{c.age}</span>
          </div>
          <div style={{ marginTop: 4, fontSize: 13, fontWeight: 500, opacity: 0.94 }}>{c.breed}</div>
        </div>
      </div>

      {/* Info region */}
      <div style={{
        flex: 1, padding: '14px 18px 12px',
        display: 'flex', flexDirection: 'column', gap: 10,
        minHeight: 0, overflow: expanded ? 'auto' : 'hidden',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          <FuzzyChip label={c.distance}/>
          <SafetyChip label={`Owner verified · ${c.ownerInitial}.`}/>
          <button onClick={onToggleExpand} aria-label={expanded ? 'Less info' : 'More info'} style={{
            marginLeft: 'auto', width: 32, height: 32, borderRadius: '50%', border: 'none', cursor: 'pointer',
            background: TOKENS.surface2, color: TOKENS.ink700,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14" style={{ transform: expanded ? 'rotate(180deg)' : 'none', transition: 'transform 200ms' }}>
              <path d="M3 9l4-4 4 4" stroke="currentColor" strokeWidth="1.75" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>
        </div>

        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
          {c.traits.map(t => (
            <span key={t} style={{
              fontSize: 12, fontWeight: 600, padding: '4px 10px', borderRadius: 999,
              background: TOKENS.surface2, color: TOKENS.ink700,
            }}>{t}</span>
          ))}
        </div>

        <div style={{ fontSize: 14, lineHeight: 1.45, color: TOKENS.ink700, textWrap: 'pretty' }}>
          {c.bio}
        </div>

        {expanded && (
          <div style={{ marginTop: 4, paddingTop: 12, borderTop: '0.5px solid ' + TOKENS.line200, display: 'flex', flexDirection: 'column', gap: 8 }}>
            <Detail label="Play style"   value={c.playStyle}/>
            <Detail label="Energy"        value={c.energy}/>
            <Detail label="Best with"     value={c.bestWith}/>
            <Detail label="Vaccinated"    value={c.vaccinated ? 'Yes — up to date' : 'No'}/>
          </div>
        )}
      </div>
    </div>
  );
}

function Detail({ label, value }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8, fontSize: 13 }}>
      <span style={{ color: TOKENS.ink500, fontWeight: 500 }}>{label}</span>
      <span style={{ color: TOKENS.ink950, fontWeight: 600 }}>{value}</span>
    </div>
  );
}

function FuzzyChip({ label }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      fontSize: 12, fontWeight: 700, padding: '5px 10px', borderRadius: 999,
      background: TOKENS.blue50, color: TOKENS.blue700,
    }}>
      <FuzzyPin color={TOKENS.blue700}/>
      {label}
    </span>
  );
}

function SafetyChip({ label }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      fontSize: 12, fontWeight: 600, padding: '5px 10px', borderRadius: 999,
      background: TOKENS.meadowT, color: TOKENS.success,
    }}>
      <svg width="11" height="11" viewBox="0 0 12 12"><path d="M6 1l4 1.5v3.5c0 2.5-2 4-4 5-2-1-4-2.5-4-5V2.5L6 1z" stroke={TOKENS.success} strokeWidth="1.2" fill="none"/></svg>
      {label}
    </span>
  );
}

function ActionDock({ onPass, onGreet, onMatch }) {
  return (
    <div style={{
      padding: '14px 4px 6px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 22,
    }}>
      <DockButton size={56} bg="#fff" stroke={TOKENS.line200} color={TOKENS.ink500} onClick={onPass} label="Pass">
        <svg width="20" height="20" viewBox="0 0 20 20"><path d="M5 5l10 10M15 5L5 15" stroke="currentColor" strokeWidth="2.3" strokeLinecap="round"/></svg>
      </DockButton>
      <DockButton size={48} bg="#fff" stroke={TOKENS.line200} color={TOKENS.blue500} onClick={onGreet} label="Wave hello">
        <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
          <path d="M10 3v10M5 8l5 5 5-5" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" transform="rotate(180 10 10)"/>
        </svg>
      </DockButton>
      <DockButton size={64} bg={TOKENS.coral} stroke={TOKENS.coral} color="#fff" onClick={onMatch} label="Match" glow>
        <svg width="26" height="26" viewBox="0 0 26 26" fill="currentColor">
          <ellipse cx="8" cy="11" rx="2.2" ry="2.8"/>
          <ellipse cx="13" cy="8" rx="2.2" ry="2.8"/>
          <ellipse cx="18" cy="11" rx="2.2" ry="2.8"/>
          <path d="M13 13c-3.2 0-5.5 2.2-5.5 4.5C7.5 19.4 9 20.5 13 20.5s5.5-1.1 5.5-3C18.5 15.2 16.2 13 13 13z"/>
        </svg>
      </DockButton>
      <DockButton size={48} bg="#fff" stroke={TOKENS.line200} color={TOKENS.mulberry} onClick={onMatch} label="Super paw">
        <svg width="20" height="20" viewBox="0 0 20 20"><path d="M10 2l2.4 5 5.6.6-4.2 3.8L15 17l-5-3-5 3 1.2-5.6L2 7.6 7.6 7 10 2z" fill="currentColor"/></svg>
      </DockButton>
      <DockButton size={56} bg="#fff" stroke={TOKENS.line200} color={TOKENS.warning} onClick={() => {}} label="Boost">
        <svg width="20" height="20" viewBox="0 0 20 20"><path d="M11 2L3 11h5l-1 7 8-9h-5l1-7z" stroke="currentColor" strokeWidth="2" fill="none" strokeLinejoin="round"/></svg>
      </DockButton>
    </div>
  );
}

function DockButton({ size, bg, stroke, color, onClick, children, label, glow }) {
  return (
    <button onClick={onClick} aria-label={label} style={{
      width: size, height: size, borderRadius: '50%', border: 'none', cursor: 'pointer',
      background: bg, color,
      boxShadow: (stroke && bg === '#fff' ? '0 0 0 1px ' + stroke + ', ' : '') +
                 '0 8px 18px -8px rgba(11,18,32,0.22)' +
                 (glow ? ', 0 0 0 6px ' + bg + '22' : ''),
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>{children}</button>
  );
}

function TabBarDiscovery({ onTab }) {
  return <SharedTabBar active="match" onTab={onTab}/>;
}

// ─── Data ───────────────────────────────────────────────────────
const DISCOVERY_DECK = [
  { name: 'Pixel',  age: '3 yr', species: 'dog', breed: 'Australian Shepherd',
    distance: 'Within 2 miles',
    ownerInitial: 'J', verified: true,
    traits: ['Loves fetch', 'Calm energy', 'Good with cats'],
    bio: 'Trail buddy who collapses in a heap after 4pm. Sniff-walks always welcome.',
    playStyle: 'Parallel — likes side-by-side hikes',
    energy: 'Medium · 60 min daily',
    bestWith: 'Calm, similar-size dogs',
    vaccinated: true,
    gradient: 'linear-gradient(150deg, #F4B57A 0%, #E89669 45%, #BC6249 100%)',
    subjectColor: '#6B3F2A',
  },
  { name: 'Juniper', age: '5 yr', species: 'dog', breed: 'Cavalier Spaniel',
    distance: 'Within 1 mile',
    ownerInitial: 'A', verified: true,
    traits: ['Loves cuddles', 'Park days', 'Low energy'],
    bio: 'Senior softie. Will accept all the gentle ear scratches you have.',
    playStyle: 'Loose lead pottering, no zoomies',
    energy: 'Low · 30 min strolls',
    bestWith: 'Calm pups, kids welcome',
    vaccinated: true,
    gradient: 'linear-gradient(150deg, #E9C9A5 0%, #C99B6F 50%, #8B6442 100%)',
    subjectColor: '#7A4E2F',
  },
  { name: 'Mochi', age: '2 yr', species: 'cat', breed: 'Domestic Shorthair',
    distance: 'Within 3 miles',
    ownerInitial: 'M', verified: false,
    traits: ['Indoor', 'Window adventures', 'Treat-motivated'],
    bio: 'Looking for a chill cat-cam pen-pal. Naps loudly.',
    playStyle: 'Wand toys, gentle chase',
    energy: 'Low',
    bestWith: 'Other cats via video',
    vaccinated: true,
    gradient: 'linear-gradient(150deg, #DDD3C3 0%, #B8A78F 50%, #7C6750 100%)',
    subjectColor: '#5C4A36',
  },
];

Object.assign(window, { Discovery, DISCOVERY_DECK });
