// home.jsx — Home dashboard (Pets tab) + Pet switcher sheet

const DEMO_PETS = [
  { id: 'mochi', name: 'Mochi', species: 'cat', breed: 'Persian', age: '3y', xp: 482, streak: 7, color: 'var(--poppy)' },
  { id: 'tommy', name: 'Tommy', species: 'dog', breed: 'Golden Retriever', age: '5y', xp: 1240, streak: 12, color: 'var(--tangerine)' },
  { id: 'goldy', name: 'Goldy', species: 'fish', breed: 'Goldfish', age: '1y', xp: 88, streak: 2, color: 'var(--mint)' },
  { id: 'nori',  name: 'Nori',  species: 'fish', breed: 'Betta',  age: '8m', xp: 42, streak: 0, color: 'var(--mint)' },
  { id: 'rex',   name: 'Rex',   species: 'reptile', breed: 'Bearded Dragon', age: '2y', xp: 220, streak: 3, color: 'var(--sunny)' },
];

function HomeScreen({ activePet, setActivePet, openPetSwitcher, navigate, motif }) {
  const pet = DEMO_PETS.find(p => p.id === activePet) || DEMO_PETS[0];
  const sp = SPECIES.find(s => s.id === pet.species) || SPECIES[0];

  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 100 }}>
      {/* Wave header with pet hero */}
      <div style={{ position: 'relative', background: sp.color, paddingBottom: 50, transition: 'background 400ms' }}>
        {/* Status row */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 18px 6px' }}>
          <button onClick={openPetSwitcher} style={{
            display: 'flex', alignItems: 'center', gap: 10,
            background: 'rgba(255,255,255,0.22)', border: 'none', cursor: 'pointer',
            padding: '6px 14px 6px 6px', borderRadius: 999, color: '#fff',
          }}>
            <PetAvatar species={pet.species} size={36} ring/>
            <div style={{ textAlign: 'left' }}>
              <div style={{ fontSize: 10, opacity: 0.85, fontWeight: 700, letterSpacing: 0.6 }}>ACTIVE PET</div>
              <div style={{ fontSize: 15, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 4 }}>
                {pet.name} {I.chevronDown(14, '#fff')}
              </div>
            </div>
          </button>
          <div style={{ display: 'flex', gap: 8 }}>
            <IconBtn size={40} bg="rgba(255,255,255,0.22)" color="#fff" shadow={false}>{I.bell(20, '#fff')}</IconBtn>
            <IconBtn size={40} bg="rgba(255,255,255,0.22)" color="#fff" shadow={false} onClick={() => navigate('settings')}>{I.settings(20, '#fff')}</IconBtn>
          </div>
        </div>

        {/* Big hero greeting */}
        <div style={{ padding: '20px 22px 0', color: '#fff' }}>
          <div style={{ fontSize: 14, opacity: 0.85, fontWeight: 700 }}>Good morning, mama 💛</div>
          <h1 className="display" style={{ fontSize: 34, lineHeight: 1.05, marginTop: 4 }}>
            {pet.name} is feeling<br/><span style={{ fontStyle: 'italic' }}>cuddly today.</span>
          </h1>
        </div>

        {/* Pet card peeking on header */}
        <div style={{ display: 'flex', justifyContent: 'center', marginTop: 18 }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 16,
            background: 'var(--surface)', borderRadius: 28,
            padding: '14px 18px 14px 14px',
            boxShadow: '0 16px 30px -12px rgba(0,0,0,0.25)',
            width: 'calc(100% - 36px)',
          }}>
            <PetAvatar species={pet.species} size={62} ring/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 18, fontWeight: 800, color: 'var(--ink-950)' }}>{pet.name}</div>
              <div style={{ fontSize: 13, color: 'var(--ink-500)', fontWeight: 600 }}>{pet.breed} · {pet.age}</div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, background: 'var(--sunny-soft)', padding: '6px 10px', borderRadius: 999 }}>
              {I.flame(16)} <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--sunny-700)' }}>{pet.streak}</span>
            </div>
          </div>
        </div>

        {/* Wave bottom */}
        <svg viewBox="0 0 412 60" preserveAspectRatio="none" style={{ position: 'absolute', bottom: -1, left: 0, width: '100%', height: 56, display: 'block' }}>
          <path d="M0,40 C90,10 160,70 220,40 C280,15 340,60 412,30 L412,60 L0,60 Z" fill="var(--cream)"/>
        </svg>
      </div>

      {/* Body */}
      <div style={{ padding: '18px 16px 24px' }}>
        {/* Quick stats trio */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginBottom: 18 }}>
          <StatTile color="var(--sunny-soft)" textColor="var(--sunny-700)" icon={I.flame(20)} value={pet.streak} label="day streak"/>
          <StatTile color="var(--lilac-soft)" textColor="var(--lilac-700)" icon={I.star(20, 'var(--lilac-700)')} value={pet.xp} label="XP earned"/>
          <StatTile color="var(--mint-soft)" textColor="var(--mint-700)" icon={I.check(20, 'var(--mint-700)')} value={34} label="care logs"/>
        </div>

        {/* Today's care preview */}
        <SectionTitle accent="var(--sunny)" right={
          <button onClick={() => navigate('care')} style={{ background: 'transparent', border: 'none', color: 'var(--tangerine-700)', fontWeight: 800, fontSize: 13, cursor: 'pointer' }}>See all →</button>
        }>Today's quests</SectionTitle>

        <Card pad={16} style={{ marginBottom: 18 }}>
          <DailyQuestRow icon="🦴" label="Morning meal" done time="8:00 AM" xp={10}/>
          <Divider/>
          <DailyQuestRow icon="💊" label="Heartworm pill" time="12:00 PM" xp={20} due/>
          <Divider/>
          <DailyQuestRow icon="🚶" label="Evening walk" time="5:30 PM" xp={15}/>
        </Card>

        {/* Recent moments */}
        <SectionTitle accent="var(--poppy)" right={<button style={{ background: 'transparent', border: 'none', color: 'var(--poppy-700)', fontWeight: 800, fontSize: 13, cursor: 'pointer' }}>Gallery →</button>}>
          Recent moments
        </SectionTitle>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 18 }}>
          <PlaceholderImg label="bath day" color="var(--poppy)" soft="var(--poppy-soft)" height={100} r={20} emoji="🛁"/>
          <PlaceholderImg label="napping" color="var(--lilac)" soft="var(--lilac-soft)" height={100} r={20} emoji="💤"/>
          <PlaceholderImg label="park run" color="var(--mint)" soft="var(--mint-soft)" height={100} r={20} emoji="🌳"/>
        </div>

        {/* Recent badges */}
        <SectionTitle accent="var(--lilac)">Recent achievements</SectionTitle>
        <div style={{ display: 'flex', gap: 10, overflowX: 'auto', paddingBottom: 4, marginLeft: -16, paddingLeft: 16, marginRight: -16, paddingRight: 16 }}>
          {[
            { color: 'var(--sunny)', emoji: '🔥', label: '7-Day Hero' },
            { color: 'var(--mint)', emoji: '🏥', label: 'Vet Visit' },
            { color: 'var(--poppy)', emoji: '💖', label: '100 Likes' },
            { color: 'var(--lilac)', emoji: '🎓', label: 'Trained' },
            { color: 'var(--tangerine)', emoji: '🦴', label: 'Treat Master' },
          ].map((b, i) => (
            <div key={i} style={{
              flex: '0 0 86px',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
            }}>
              <div style={{
                width: 76, height: 76, borderRadius: 24,
                background: `linear-gradient(135deg, ${b.color}, color-mix(in oklab, ${b.color} 70%, white))`,
                boxShadow: `inset 0 -8px 16px rgba(0,0,0,0.18), inset 0 8px 14px rgba(255,255,255,0.4), 0 8px 18px -8px ${b.color}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 36,
                transform: `rotate(${i % 2 ? -3 : 3}deg)`,
              }}>{b.emoji}</div>
              <div style={{ fontSize: 11, fontWeight: 800, color: 'var(--ink-950)', textAlign: 'center', lineHeight: 1.2 }}>{b.label}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function StatTile({ icon, value, label, color, textColor }) {
  return (
    <div style={{
      background: color, borderRadius: 22, padding: '14px 12px',
      display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 4,
      boxShadow: '0 1px 0 0 rgba(255,255,255,0.4) inset',
    }}>
      <div style={{ marginBottom: 2 }}>{icon}</div>
      <div style={{ fontSize: 22, fontWeight: 900, color: 'var(--ink-950)', lineHeight: 1 }}>{value}</div>
      <div style={{ fontSize: 11, color: textColor, fontWeight: 700 }}>{label}</div>
    </div>
  );
}

function DailyQuestRow({ icon, label, time, xp, done, due }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '10px 4px' }}>
      <div style={{
        width: 42, height: 42, borderRadius: 14,
        background: done ? 'var(--mint-soft)' : due ? 'var(--poppy-soft)' : 'var(--cream-2)',
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 22,
      }}>{done ? '✅' : icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 15, fontWeight: 800, color: 'var(--ink-950)', textDecoration: done ? 'line-through' : 'none', opacity: done ? 0.55 : 1 }}>{label}</div>
        <div style={{ fontSize: 12, color: due ? 'var(--poppy-700)' : 'var(--ink-500)', fontWeight: 700 }}>
          {due ? `Due ${time}` : time}
        </div>
      </div>
      <div style={{
        background: done ? 'var(--mint-soft)' : 'var(--sunny-soft)',
        color: done ? 'var(--mint-700)' : 'var(--sunny-700)',
        padding: '5px 10px', borderRadius: 999, fontSize: 12, fontWeight: 900,
        display: 'inline-flex', alignItems: 'center', gap: 4,
      }}>+{xp} {I.star(12, done ? 'var(--mint-700)' : 'var(--sunny-700)')}</div>
    </div>
  );
}

function Divider() {
  return <div style={{ height: 1, background: 'var(--line)', margin: '0 4px' }}/>;
}

// ─── Pet Switcher (bottom sheet) ────────────────────────────
function PetSwitcher({ open, onClose, active, setActive, navigate }) {
  const [phase, setPhase] = React.useState('closed'); // closed / opening / open / closing
  React.useEffect(() => {
    if (open) {
      setPhase('opening');
      requestAnimationFrame(() => setPhase('open'));
    } else if (phase !== 'closed') {
      setPhase('closing');
      setTimeout(() => setPhase('closed'), 250);
    }
  }, [open]);

  if (phase === 'closed') return null;
  const visible = phase === 'open';

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 50, display: 'flex', flexDirection: 'column' }}>
      {/* Scrim */}
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0,
        background: 'rgba(38, 19, 8, 0.45)',
        opacity: visible ? 1 : 0, transition: 'opacity 240ms',
      }}/>
      {/* Sheet */}
      <div style={{
        marginTop: 'auto', background: 'var(--cream)',
        borderTopLeftRadius: 32, borderTopRightRadius: 32,
        padding: '16px 18px 28px', maxHeight: '82%', overflowY: 'auto',
        transform: visible ? 'translateY(0)' : 'translateY(110%)',
        transition: 'transform 320ms cubic-bezier(.3,.7,.4,1)',
        position: 'relative', zIndex: 1,
        boxShadow: '0 -20px 40px -10px rgba(0,0,0,0.2)',
      }}>
        <div style={{ width: 48, height: 5, borderRadius: 3, background: 'var(--line-2)', margin: '0 auto 18px' }}/>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 18 }}>
          <div>
            <h2 className="display" style={{ fontSize: 28, color: 'var(--ink-950)' }}>Your pack</h2>
            <div style={{ fontSize: 13, color: 'var(--ink-500)', fontWeight: 600 }}>{DEMO_PETS.length} pets · tap to switch</div>
          </div>
          <IconBtn onClick={onClose} size={36}>{I.close(18)}</IconBtn>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {DEMO_PETS.map(p => {
            const isActive = p.id === active;
            const sp = SPECIES.find(s => s.id === p.species) || SPECIES[0];
            return (
              <button key={p.id} onClick={() => { setActive(p.id); onClose(); }} style={{
                background: isActive ? sp.soft : 'var(--surface)',
                borderRadius: 22, border: `2px solid ${isActive ? sp.color : 'var(--line)'}`,
                padding: '12px 14px', cursor: 'pointer',
                display: 'flex', alignItems: 'center', gap: 14,
                boxShadow: 'var(--shadow-soft)',
              }}>
                <PetAvatar species={p.species} size={52} ring={isActive}/>
                <div style={{ flex: 1, textAlign: 'left' }}>
                  <div style={{ fontSize: 17, fontWeight: 800, color: 'var(--ink-950)' }}>{p.name}</div>
                  <div style={{ fontSize: 12, color: 'var(--ink-500)', fontWeight: 600 }}>{p.breed} · {p.age}</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <span style={{ fontSize: 12, fontWeight: 800, color: 'var(--sunny-700)' }}>{I.flame(14)}</span>
                  <span style={{ fontSize: 12, fontWeight: 800, color: 'var(--sunny-700)' }}>{p.streak}</span>
                </div>
                {isActive && <div style={{ width: 28, height: 28, borderRadius: '50%', background: sp.color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{I.check(16, '#fff')}</div>}
              </button>
            );
          })}
        </div>

        <button style={{
          marginTop: 14, padding: 14, borderRadius: 22, border: '2px dashed var(--tangerine)',
          background: 'transparent', display: 'flex', alignItems: 'center', gap: 12, width: '100%',
          cursor: 'pointer', textAlign: 'left',
        }}>
          <div style={{ width: 44, height: 44, borderRadius: '50%', background: 'var(--tangerine)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            {I.plus(22, '#fff')}
          </div>
          <div>
            <div style={{ fontSize: 16, fontWeight: 800, color: 'var(--tangerine-700)' }}>Add another pet</div>
            <div style={{ fontSize: 12, color: 'var(--ink-500)', fontWeight: 600 }}>Name, breed, photo — 30 seconds</div>
          </div>
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { HomeScreen, PetSwitcher, DEMO_PETS });
