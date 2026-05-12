// Home screen + Active Pet Switcher bottom sheet.

function Home({ pets, activeId, onOpenSwitcher, onOpenAdd, onOutdoor, outdoor, onTab }) {
  const active = pets.find(p => p.id === activeId) || pets[0];
  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      background: outdoor ? '#fff' : TOKENS.surface1,
      fontFamily: 'Inter, system-ui, sans-serif',
      color: TOKENS.ink950,
    }}>
      <HomeHeader active={active} pets={pets} onOpenSwitcher={onOpenSwitcher} outdoor={outdoor} onOutdoor={onOutdoor} />
      <div style={{ flex: 1, overflow: 'auto', padding: '8px 20px 100px', display: 'flex', flexDirection: 'column', gap: 16 }}>
        <HeroCard active={active} outdoor={outdoor} />
        <SectionLabel>Today</SectionLabel>
        <ReminderCard accent={active.accent} icon="pill" title="Heartworm tablet" sub="9:00 AM · Daily" cta="Mark done" />
        <ReminderCard accent={TOKENS.meadow} icon="walk" title={`Evening walk with ${active.name}`} sub="2 / 3 walks today · 38 min" cta="Start walk" primary />
        <SectionLabel>From the feed</SectionLabel>
        <FeedCard active={active} />
      </div>
      <TabBar onTab={onTab} />
    </div>
  );
}

function HomeHeader({ active, pets, onOpenSwitcher, outdoor, onOutdoor }) {
  return (
    <div style={{
      padding: '14px 20px 12px', display: 'flex', alignItems: 'center', gap: 14,
      paddingTop: 58,
    }}>
      <button onClick={onOpenSwitcher} aria-label={`Switch pet — currently ${active.name}`} style={{
        display: 'flex', alignItems: 'center', gap: 12,
        background: 'transparent', border: 'none', padding: 0, cursor: 'pointer',
        flex: 1, textAlign: 'left',
      }}>
        <PetAvatar pet={active} size={48} ring={`linear-gradient(135deg, ${active.accent}, ${lighten(active.accent, 0.3)})`} />
        <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: TOKENS.ink500 }}>
            Active pet
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 1 }}>
            <span style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 22, color: TOKENS.ink950, letterSpacing: '-0.01em' }}>
              {active.name}
            </span>
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
              <path d="M3 6l5 5 5-5" stroke={TOKENS.ink500} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </div>
      </button>
      <button onClick={onOutdoor} aria-label="Toggle outdoor mode" style={chipBtn(outdoor ? TOKENS.ink950 : TOKENS.surface0, outdoor ? '#fff' : TOKENS.ink700)}>
        <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
          <circle cx="9" cy="9" r="3.5" stroke="currentColor" strokeWidth="1.75"/>
          <g stroke="currentColor" strokeWidth="1.75" strokeLinecap="round">
            <path d="M9 1.5v2M9 14.5v2M1.5 9h2M14.5 9h2M3.7 3.7l1.4 1.4M12.9 12.9l1.4 1.4M3.7 14.3l1.4-1.4M12.9 5.1l1.4-1.4"/>
          </g>
        </svg>
      </button>
      <button aria-label="Notifications" style={chipBtn(TOKENS.surface0, TOKENS.ink700)}>
        <svg width="18" height="20" viewBox="0 0 18 20" fill="none">
          <path d="M3 8a6 6 0 1112 0v3l2 3H1l2-3V8z" stroke="currentColor" strokeWidth="1.75" strokeLinejoin="round"/>
          <path d="M7 17a2 2 0 004 0" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round"/>
        </svg>
        <span style={{
          position: 'absolute', top: 8, right: 8, width: 9, height: 9, borderRadius: '50%',
          background: TOKENS.coral, boxShadow: '0 0 0 2px ' + TOKENS.surface1,
        }}/>
      </button>
    </div>
  );
}

function chipBtn(bg, color) {
  return {
    width: 44, height: 44, borderRadius: '50%', border: 'none', cursor: 'pointer',
    background: bg, color,
    boxShadow: '0 1px 2px rgba(11,18,32,0.06), 0 0 0 0.5px ' + TOKENS.line200,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    position: 'relative', flexShrink: 0,
  };
}

function HeroCard({ active, outdoor }) {
  return (
    <div style={{
      borderRadius: 24, overflow: 'hidden', position: 'relative',
      background: `linear-gradient(135deg, ${active.accent} 0%, ${darken(active.accent, 0.18)} 100%)`,
      padding: '20px 20px 18px',
      boxShadow: outdoor ? 'none' : '0 18px 36px -16px ' + active.accent + '88',
      color: '#fff',
    }}>
      <div style={{
        position: 'absolute', top: -40, right: -30, width: 200, height: 200, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(255,255,255,0.2) 0%, transparent 65%)',
      }}/>
      <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontSize: 12, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase', opacity: 0.9 }}>
            Health streak
          </div>
          <div style={{
            fontSize: 11, fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase',
            background: 'rgba(255,255,255,0.18)', padding: '4px 10px', borderRadius: 999,
            backdropFilter: 'blur(8px)',
          }}>
            {active.lastSeen}
          </div>
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
          <span style={{ fontFamily: 'Sora', fontSize: 56, fontWeight: 700, letterSpacing: '-0.03em', lineHeight: 1 }}>
            {active.healthStreak}
          </span>
          <span style={{ fontSize: 16, opacity: 0.9 }}>days on track</span>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          {Array.from({ length: 7 }).map((_, i) => (
            <div key={i} style={{
              flex: 1, height: 28, borderRadius: 6,
              background: i < 6 ? 'rgba(255,255,255,0.85)' : 'rgba(255,255,255,0.25)',
            }}/>
          ))}
        </div>
        <div style={{ display: 'flex', gap: 8, fontSize: 11, fontWeight: 500, opacity: 0.85, justifyContent: 'space-between' }}>
          {['M','T','W','T','F','S','S'].map((d, i) => <span key={i} style={{ flex: 1, textAlign: 'center' }}>{d}</span>)}
        </div>
      </div>
    </div>
  );
}

function ReminderCard({ accent, icon, title, sub, cta, primary }) {
  return (
    <div style={{
      background: TOKENS.surface0, borderRadius: 18, padding: '14px 16px',
      display: 'flex', alignItems: 'center', gap: 14,
      boxShadow: '0 0 0 0.5px ' + TOKENS.line200 + ', 0 1px 2px rgba(11,18,32,0.04)',
    }}>
      <div style={{
        width: 44, height: 44, borderRadius: 12, background: accent + '22', color: accent,
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
      }}>
        {icon === 'pill' && (
          <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
            <rect x="2" y="8" width="18" height="6" rx="3" stroke="currentColor" strokeWidth="1.75" transform="rotate(-30 11 11)"/>
            <path d="M7.5 5.5l8.5 8.5" stroke="currentColor" strokeWidth="1.75"/>
          </svg>
        )}
        {icon === 'walk' && (
          <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="13" cy="4" r="2"/>
            <path d="M11 7l-3 5 3 2-1 5M14 12l3 2-2 4"/>
          </svg>
        )}
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontFamily: 'Sora', fontWeight: 600, fontSize: 16, color: TOKENS.ink950 }}>{title}</div>
        <div style={{ fontSize: 13, color: TOKENS.ink500, marginTop: 2 }}>{sub}</div>
      </div>
      <button style={{
        height: 36, padding: '0 14px', borderRadius: 10, border: 'none',
        background: primary ? accent : TOKENS.surface2,
        color: primary ? '#fff' : TOKENS.ink950,
        fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
        cursor: 'pointer', flexShrink: 0,
        boxShadow: primary ? '0 4px 12px -4px ' + accent + 'aa' : 'none',
      }}>{cta}</button>
    </div>
  );
}

function FeedCard({ active }) {
  return (
    <div style={{
      background: TOKENS.surface0, borderRadius: 20, overflow: 'hidden',
      boxShadow: '0 0 0 0.5px ' + TOKENS.line200 + ', 0 1px 2px rgba(11,18,32,0.04)',
    }}>
      <div style={{ padding: '12px 14px 10px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 36, height: 36, borderRadius: '50%',
          background: `radial-gradient(circle at 30% 25%, ${lighten(TOKENS.mulberry, 0.3)}, ${TOKENS.mulberry})`,
        }}/>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 600, fontSize: 14, color: TOKENS.ink950 }}>@parkside_corgi_club</div>
          <div style={{ fontSize: 12, color: TOKENS.ink500 }}>0.4 km · 2 hr ago</div>
        </div>
        <div style={{
          padding: '4px 10px', borderRadius: 999, fontSize: 11, fontWeight: 600,
          background: TOKENS.coralT, color: TOKENS.coral,
        }}>Nearby</div>
      </div>
      <div style={{
        height: 180, position: 'relative',
        background: `repeating-linear-gradient(45deg, ${TOKENS.surface2}, ${TOKENS.surface2} 12px, ${TOKENS.line100} 12px, ${TOKENS.line100} 24px)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 11, color: TOKENS.ink500,
          background: TOKENS.surface0, padding: '4px 10px', borderRadius: 6,
          boxShadow: '0 0 0 0.5px ' + TOKENS.line200,
        }}>[feed photo placeholder]</div>
      </div>
      <div style={{ padding: '12px 14px' }}>
        <div style={{ fontSize: 14, color: TOKENS.ink950, lineHeight: 1.45 }}>
          <b>Sunday meetup</b> at Highbury — 6 corgis confirmed. Bring water 💧 (just kidding — bring real water)
        </div>
      </div>
    </div>
  );
}

function SectionLabel({ children }) {
  return (
    <div style={{
      marginTop: 8, paddingLeft: 4,
      fontSize: 12, fontWeight: 600, letterSpacing: '0.08em',
      textTransform: 'uppercase', color: TOKENS.ink500,
    }}>{children}</div>
  );
}

function TabBar({ onTab }) {
  const tabs = [
    { id: 'home', label: 'Home', icon: (c) => <path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-5v-7h-6v7H4a1 1 0 01-1-1V11z" stroke={c} strokeWidth="1.75" strokeLinejoin="round" fill="none"/> },
    { id: 'feed', label: 'Social', icon: (c) => <><circle cx="12" cy="12" r="9" stroke={c} strokeWidth="1.75" fill="none"/><circle cx="12" cy="9" r="2.5" stroke={c} strokeWidth="1.75" fill="none"/><path d="M6 18c1-3 3-4 6-4s5 1 6 4" stroke={c} strokeWidth="1.75" fill="none"/></> },
    { id: 'match', label: 'Match', icon: (c) => <path d="M12 21s-8-5-8-11a5 5 0 019-3 5 5 0 019 3c0 6-8 11-8 11z" stroke={c} strokeWidth="1.75" fill="none" strokeLinejoin="round"/> },
    { id: 'health', label: 'Health', icon: (c) => <><path d="M4 12l3 6 5-13 4 8h4" stroke={c} strokeWidth="1.75" fill="none" strokeLinejoin="round"/></> },
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
        {tabs.map((t, i) => {
          const active = i === 0;
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

// ───────────────────────────────────────────────────────────────────
// Pet Switcher Bottom Sheet
// ───────────────────────────────────────────────────────────────────

function PetSwitcher({ open, pets, activeId, onClose, onPick, onAdd, glass, outdoor, sheetHeight }) {
  const sheetRef = React.useRef(null);
  const [dragY, setDragY] = React.useState(0);
  const startY = React.useRef(null);

  // Disable glass when outdoor mode is on (per spec)
  const useGlass = glass && !outdoor;

  const onTouchStart = (e) => { startY.current = (e.touches ? e.touches[0].clientY : e.clientY); };
  const onTouchMove = (e) => {
    if (startY.current == null) return;
    const cur = (e.touches ? e.touches[0].clientY : e.clientY);
    const dy = Math.max(0, cur - startY.current);
    setDragY(dy);
  };
  const onTouchEnd = () => {
    if (dragY > 100) onClose();
    startY.current = null;
    setDragY(0);
  };

  return (
    <>
      {/* Scrim */}
      <div
        onClick={onClose}
        style={{
          position: 'absolute', inset: 0, zIndex: 100,
          background: open ? 'rgba(11,18,32,0.42)' : 'transparent',
          opacity: open ? 1 : 0, pointerEvents: open ? 'auto' : 'none',
          transition: 'opacity 220ms cubic-bezier(0.2, 0, 0, 1)',
          backdropFilter: open ? 'blur(2px)' : 'none',
        }}
      />
      {/* Sheet */}
      <div
        ref={sheetRef}
        style={{
          position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 101,
          transform: open ? `translateY(${dragY}px)` : 'translateY(100%)',
          transition: dragY === 0 ? 'transform 380ms cubic-bezier(0.2, 0.9, 0.25, 1)' : 'none',
          maxHeight: sheetHeight || '78%',
          display: 'flex', flexDirection: 'column',
          borderTopLeftRadius: 28, borderTopRightRadius: 28,
          overflow: 'hidden',
          background: useGlass ? 'rgba(255,255,255,0.78)' : TOKENS.surface0,
          backdropFilter: useGlass ? 'blur(28px) saturate(160%)' : 'none',
          WebkitBackdropFilter: useGlass ? 'blur(28px) saturate(160%)' : 'none',
          boxShadow: '0 -20px 60px -10px rgba(11,18,32,0.28), 0 -1px 0 rgba(255,255,255,0.6) inset',
          border: useGlass ? '0.5px solid rgba(255,255,255,0.55)' : '0.5px solid ' + TOKENS.line200,
          borderBottom: 'none',
        }}
      >
        {/* Drag handle area */}
        <div
          onMouseDown={onTouchStart} onMouseMove={(e) => startY.current != null && onTouchMove(e)}
          onMouseUp={onTouchEnd} onMouseLeave={onTouchEnd}
          onTouchStart={onTouchStart} onTouchMove={onTouchMove} onTouchEnd={onTouchEnd}
          style={{ padding: '10px 0 6px', display: 'flex', justifyContent: 'center', cursor: 'grab', flexShrink: 0 }}
        >
          <div style={{ width: 44, height: 5, borderRadius: 999, background: 'rgba(11,18,32,0.18)' }}/>
        </div>
        <div style={{ padding: '4px 20px 8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
          <div>
            <div style={{ fontFamily: 'Sora', fontSize: 22, fontWeight: 700, letterSpacing: '-0.01em', color: TOKENS.ink950 }}>
              Your pets
            </div>
            <div style={{ fontSize: 13, color: TOKENS.ink500, marginTop: 2 }}>
              {pets.length} pet{pets.length === 1 ? '' : 's'} · tap to switch
            </div>
          </div>
          <button onClick={onClose} aria-label="Close" style={{
            width: 36, height: 36, borderRadius: '50%', border: 'none', cursor: 'pointer',
            background: 'rgba(11,18,32,0.06)', color: TOKENS.ink700,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 2l10 10M12 2L2 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round"/></svg>
          </button>
        </div>

        <div style={{ flex: 1, overflow: 'auto', padding: '8px 16px 12px', WebkitOverflowScrolling: 'touch' }}>
          {/* Active pet — featured */}
          {pets.filter(p => p.id === activeId).map(p => (
            <PetSwitcherRow key={p.id} pet={p} active onPick={() => onClose()} />
          ))}
          {/* Others */}
          <div style={{ marginTop: 16, marginBottom: 8, paddingLeft: 8, fontSize: 11, fontWeight: 600, color: TOKENS.ink500, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
            Switch to
          </div>
          {pets.filter(p => p.id !== activeId).map(p => (
            <PetSwitcherRow key={p.id} pet={p} onPick={() => onPick(p.id)} />
          ))}
          {/* Add pet */}
          <button onClick={onAdd} style={{
            marginTop: 8, width: '100%', minHeight: 64, borderRadius: 18,
            border: '1.5px dashed ' + TOKENS.blue400, cursor: 'pointer',
            background: TOKENS.blue50, color: TOKENS.blue700,
            display: 'flex', alignItems: 'center', gap: 14, padding: '0 16px',
            fontFamily: 'Inter',
          }}>
            <div style={{
              width: 48, height: 48, borderRadius: '50%', background: TOKENS.blue500,
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <svg width="22" height="22" viewBox="0 0 22 22"><path d="M11 3v16M3 11h16" stroke="#fff" strokeWidth="2.5" strokeLinecap="round"/></svg>
            </div>
            <div style={{ textAlign: 'left' }}>
              <div style={{ fontFamily: 'Sora', fontWeight: 600, fontSize: 16, color: TOKENS.ink950 }}>Add another pet</div>
              <div style={{ fontSize: 13, color: TOKENS.ink500, marginTop: 1 }}>Name, breed, photo — 30 seconds</div>
            </div>
          </button>

          {/* Manage row */}
          <div style={{
            marginTop: 14, padding: '12px 16px', borderRadius: 14,
            background: 'rgba(11,18,32,0.04)',
            display: 'flex', alignItems: 'center', gap: 12,
            fontSize: 13, color: TOKENS.ink700,
          }}>
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke={TOKENS.ink500} strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="9" cy="9" r="2.5"/>
              <path d="M15 9a6 6 0 00-.1-1l1.5-1.2-1.5-2.6-1.8.7a6 6 0 00-1.8-1L11 2H7l-.3 1.9a6 6 0 00-1.8 1l-1.8-.7-1.5 2.6L3.1 8a6 6 0 000 2l-1.5 1.2 1.5 2.6 1.8-.7a6 6 0 001.8 1L7 16h4l.3-1.9a6 6 0 001.8-1l1.8.7 1.5-2.6L14.9 10c.07-.32.1-.66.1-1z"/>
            </svg>
            <span style={{ flex: 1 }}>Reorder, share access, archive a pet</span>
            <button style={{
              fontFamily: 'Inter', fontWeight: 600, fontSize: 13, color: TOKENS.blue600,
              background: 'transparent', border: 'none', cursor: 'pointer',
            }}>Manage</button>
          </div>
        </div>
      </div>
    </>
  );
}

function PetSwitcherRow({ pet, active, onPick }) {
  return (
    <button onClick={onPick} aria-label={`${active ? 'Currently active: ' : 'Switch to '}${pet.name}`} style={{
      width: '100%', minHeight: 76, borderRadius: 18, border: 'none', cursor: 'pointer',
      background: active ? pet.tint : TOKENS.surface0,
      boxShadow: active
        ? `0 0 0 2px ${pet.accent}, 0 8px 22px -10px ${pet.accent}88`
        : '0 0 0 0.5px ' + TOKENS.line200,
      display: 'flex', alignItems: 'center', gap: 14, padding: '12px 16px',
      marginBottom: 10, textAlign: 'left',
      transition: 'box-shadow 180ms, background 180ms',
      fontFamily: 'Inter',
    }}>
      <PetAvatar pet={pet} size={56} ring={active ? `linear-gradient(135deg, ${pet.accent}, ${lighten(pet.accent, 0.3)})` : null} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontFamily: 'Sora', fontWeight: 600, fontSize: 18, color: TOKENS.ink950, letterSpacing: '-0.01em' }}>
            {pet.name}
          </span>
          {active && (
            <span style={{
              fontSize: 10, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase',
              color: pet.accent, background: '#fff',
              padding: '3px 8px', borderRadius: 999,
              boxShadow: '0 0 0 0.5px ' + pet.accent + '55',
            }}>Active</span>
          )}
        </div>
        <div style={{ fontSize: 13, color: TOKENS.ink500, marginTop: 2, display: 'flex', alignItems: 'center', gap: 8 }}>
          <span>{pet.breed}</span>
          <span style={{ width: 3, height: 3, borderRadius: '50%', background: TOKENS.ink300 }}/>
          <span>{pet.age}</span>
        </div>
        {pet.badge && (
          <div style={{
            marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 5,
            fontSize: 12, fontWeight: 600,
            color: pet.badge.includes('reminder') ? TOKENS.warning : TOKENS.ink700,
          }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: pet.badge.includes('reminder') ? TOKENS.warning : TOKENS.meadow }}/>
            {pet.badge}
          </div>
        )}
      </div>
      {active ? (
        <svg width="24" height="24" viewBox="0 0 24 24" style={{ flexShrink: 0 }}>
          <circle cx="12" cy="12" r="12" fill={pet.accent}/>
          <path d="M7 12.5l3.5 3.5L17 9.5" stroke="#fff" strokeWidth="2.4" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      ) : (
        <svg width="10" height="18" viewBox="0 0 10 18" style={{ flexShrink: 0 }}>
          <path d="M1 1l8 8-8 8" stroke={TOKENS.ink300} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      )}
    </button>
  );
}

Object.assign(window, { Home, PetSwitcher });
