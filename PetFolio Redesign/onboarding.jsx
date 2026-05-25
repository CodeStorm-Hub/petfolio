// onboarding.jsx — 5-step playful pet quiz with species-reactive backgrounds

function Onboarding({ onDone }) {
  const [step, setStep] = React.useState(0);
  const [data, setData] = React.useState({
    species: 'dog',
    name: '',
    age: 24, // months
    personality: [],
    color: 'gold',
  });

  const sp = SPECIES.find(s => s.id === data.species) || SPECIES[0];

  const total = 5;
  const next = () => setStep(s => Math.min(s + 1, total));
  const back = () => setStep(s => Math.max(s - 1, 0));

  // Step contents
  const Steps = [
    () => <StepHello next={next} sp={sp}/>,
    () => <StepSpecies data={data} setData={setData} next={next}/>,
    () => <StepName data={data} setData={setData} next={next} sp={sp}/>,
    () => <StepAge data={data} setData={setData} next={next} sp={sp}/>,
    () => <StepPersonality data={data} setData={setData} next={() => { next(); setTimeout(onDone, 1400); }} sp={sp}/>,
  ];
  const Step = Steps[step] || (() => <StepDone sp={sp} data={data}/>);

  return (
    <div style={{
      position: 'absolute', inset: 0,
      background: `radial-gradient(circle at 50% 20%, ${sp.soft}, var(--cream))`,
      transition: 'background 600ms cubic-bezier(.3,.7,.4,1)',
      overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* Decorative paws floating */}
      <FloatingPaws species={sp}/>

      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '14px 16px 8px' }}>
        {step > 0 && step < total && (
          <IconBtn onClick={back} size={40}>{I.back(22)}</IconBtn>
        )}
        {step > 0 && step < total && <ProgressDots count={total - 1} active={step - 1}/>}
      </div>

      {/* Step content */}
      <div key={step} style={{
        flex: 1, position: 'relative', padding: '12px 22px 100px',
      }}>
        <Step/>
      </div>
    </div>
  );
}

function ProgressDots({ count, active }) {
  return (
    <div style={{ flex: 1, display: 'flex', gap: 6, paddingRight: 12 }}>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} style={{
          flex: 1, height: 6, borderRadius: 999,
          background: i <= active ? 'var(--ink-950)' : 'rgba(0,0,0,0.08)',
          transition: 'background 300ms',
        }}/>
      ))}
    </div>
  );
}

function FloatingPaws({ species }) {
  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', opacity: 0.16 }}>
      {[[14,18,40,12],[80,22,28,-8],[12,68,32,18],[78,72,46,-12],[42,38,22,4]].map(([x,y,s,r],i) => (
        <div key={i} style={{ position: 'absolute', left: `${x}%`, top: `${y}%`, transform: `rotate(${r}deg)`, animation: `pf-bounce-soft ${2200 + i*200}ms ease-in-out infinite`, animationDelay: `${i*200}ms` }}>
          {I.paw(s, species.color)}
        </div>
      ))}
    </div>
  );
}

// ─── Step 0: hello / welcome ───
function StepHello({ next, sp }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', alignItems: 'center', textAlign: 'center', paddingTop: 30 }}>
      <div style={{
        width: 160, height: 160, borderRadius: '50%',
        background: `conic-gradient(from 200deg, var(--tangerine), var(--poppy), var(--sunny), var(--mint), var(--tangerine))`,
        padding: 6, marginBottom: 28,
        animation: 'pf-pop-in 600ms cubic-bezier(.3,1.7,.4,1)',
        filter: 'drop-shadow(0 12px 24px rgba(255,138,76,0.4))',
      }}>
        <div style={{
          width: '100%', height: '100%', borderRadius: '50%',
          background: 'var(--surface)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 80,
        }}>🐾</div>
      </div>
      <h1 className="display" style={{ fontSize: 44, lineHeight: 1.05, marginBottom: 12, color: 'var(--ink-950)' }}>
        Hi! I'm <span style={{ color: 'var(--tangerine)' }}>PetFolio</span>.
      </h1>
      <p style={{ fontSize: 17, color: 'var(--ink-700)', lineHeight: 1.45, maxWidth: 300, marginBottom: 28 }}>
        Your pet's whole life — feeds, friends, health, treats — in one cozy place.
      </p>
      <div style={{ marginTop: 'auto', width: '100%', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <Pill full size="lg" onClick={next} iconRight={I.chevron(18,'#fff')}>Start the tail-wag</Pill>
        <button style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          color: 'var(--ink-700)', fontWeight: 700, fontSize: 14, padding: '10px',
        }}>I already have an account</button>
      </div>
    </div>
  );
}

// ─── Step 1: species select (reactive bg) ───
function StepSpecies({ data, setData, next }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <h2 className="display" style={{ fontSize: 32, lineHeight: 1.1, marginBottom: 6, color: 'var(--ink-950)' }}>
        Who are we<br/>welcoming home?
      </h2>
      <p style={{ fontSize: 15, color: 'var(--ink-700)', marginBottom: 22 }}>Pick your pet — the app will dress up to match.</p>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 12 }}>
        {SPECIES.map(s => {
          const selected = data.species === s.id;
          return (
            <button key={s.id} onClick={() => setData(d => ({ ...d, species: s.id }))} style={{
              background: selected ? s.color : 'var(--surface)',
              borderRadius: 24, border: 'none', cursor: 'pointer',
              padding: '20px 8px 14px',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
              boxShadow: selected ? `0 10px 24px -10px ${s.color}` : 'var(--shadow-soft)',
              transform: selected ? 'translateY(-2px) scale(1.02)' : 'none',
              transition: 'all 240ms cubic-bezier(.5,1.7,.5,1)',
              border: `2px solid ${selected ? s.color : 'transparent'}`,
            }}>
              <div style={{
                width: 60, height: 60, borderRadius: '50%',
                background: selected ? 'rgba(255,255,255,0.3)' : s.soft,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 36,
              }}>{s.emoji}</div>
              <div style={{
                fontSize: 14, fontWeight: 800,
                color: selected ? '#fff' : 'var(--ink-950)',
              }}>{s.label}</div>
            </button>
          );
        })}
      </div>

      <div style={{ marginTop: 'auto', paddingTop: 20 }}>
        <Pill full size="lg" onClick={next} iconRight={I.chevron(18,'#fff')}>Continue</Pill>
      </div>
    </div>
  );
}

// ─── Step 2: name ───
function StepName({ data, setData, next, sp }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <h2 className="display" style={{ fontSize: 32, lineHeight: 1.1, marginBottom: 6 }}>
        What's <span style={{ color: sp.color }}>their name</span>?
      </h2>
      <p style={{ fontSize: 15, color: 'var(--ink-700)', marginBottom: 24 }}>The one you whisper when no one's watching.</p>

      <div style={{
        background: 'var(--surface)', borderRadius: 24, padding: 4, border: '2px solid var(--line-2)',
        boxShadow: 'var(--shadow-soft)',
      }}>
        <input value={data.name} onChange={e => setData(d => ({ ...d, name: e.target.value }))} placeholder="e.g. Mochi, Biscuit, Mr Whiskers" style={{
          width: '100%', border: 'none', outline: 'none',
          padding: '20px 22px', fontSize: 22, fontWeight: 700, color: 'var(--ink-950)',
          fontFamily: 'inherit', background: 'transparent', borderRadius: 22,
        }}/>
      </div>

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 14 }}>
        {['Mochi','Biscuit','Pepper','Luna','Coco','Tofu'].map(n => (
          <button key={n} onClick={() => setData(d => ({ ...d, name: n }))} style={{
            padding: '8px 14px', borderRadius: 999, border: '1.5px solid var(--line-2)',
            background: 'var(--surface)', fontSize: 13, fontWeight: 700, color: 'var(--ink-700)',
            cursor: 'pointer',
          }}>{n}</button>
        ))}
      </div>

      <div style={{ marginTop: 'auto' }}>
        <Pill full size="lg" onClick={next} disabled={!data.name.trim()} iconRight={I.chevron(18,'#fff')}>Lovely name</Pill>
      </div>
    </div>
  );
}

// ─── Step 3: age (bone slider!) ───
function StepAge({ data, setData, next, sp }) {
  const years = (data.age / 12);
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <h2 className="display" style={{ fontSize: 32, lineHeight: 1.1, marginBottom: 6 }}>
        How old is <span style={{ color: sp.color }}>{data.name || 'they'}</span>?
      </h2>
      <p style={{ fontSize: 15, color: 'var(--ink-700)', marginBottom: 24 }}>Slide the bone — it's about right, no need to be exact.</p>

      <Card pad={26} style={{ marginBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 18 }}>
          <span className="display" style={{ fontSize: 56, color: 'var(--ink-950)' }}>{years < 1 ? data.age : Math.floor(years)}</span>
          <span style={{ fontSize: 18, fontWeight: 700, color: 'var(--ink-500)' }}>
            {years < 1 ? (data.age === 1 ? 'month' : 'months') : (Math.floor(years) === 1 ? 'year young' : 'years young')}
          </span>
        </div>
        <BoneSlider value={data.age} onChange={v => setData(d => ({ ...d, age: v }))} min={1} max={216} color={sp.color}/>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--ink-500)', marginTop: 14, fontWeight: 700, letterSpacing: 0.5 }}>
          <span>PUPPY</span><span>ADULT</span><span>SENIOR</span>
        </div>
      </Card>

      <div style={{ marginTop: 'auto' }}>
        <Pill full size="lg" onClick={next} iconRight={I.chevron(18,'#fff')}>Continue</Pill>
      </div>
    </div>
  );
}

// ─── Step 4: personality chips ───
const PERSONALITY_TRAITS = [
  { id: 'cuddly', label: 'Cuddly', emoji: '🤗' },
  { id: 'playful', label: 'Playful', emoji: '🎾' },
  { id: 'shy', label: 'Shy', emoji: '🙈' },
  { id: 'chaotic', label: 'Chaos goblin', emoji: '😈' },
  { id: 'foodie', label: 'Treat fiend', emoji: '🦴' },
  { id: 'adventurer', label: 'Adventurer', emoji: '🏕️' },
  { id: 'lazy', label: 'Couch potato', emoji: '🛋️' },
  { id: 'chatty', label: 'Chatty', emoji: '💬' },
  { id: 'protective', label: 'Loyal guard', emoji: '🛡️' },
];

function StepPersonality({ data, setData, next, sp }) {
  const toggle = id => setData(d => ({
    ...d,
    personality: d.personality.includes(id)
      ? d.personality.filter(x => x !== id)
      : [...d.personality, id],
  }));
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <h2 className="display" style={{ fontSize: 32, lineHeight: 1.1, marginBottom: 6 }}>
        How would you describe their<br/><span style={{ color: sp.color }}>vibe</span>?
      </h2>
      <p style={{ fontSize: 15, color: 'var(--ink-700)', marginBottom: 22 }}>Pick a few. We won't tell anyone.</p>

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
        {PERSONALITY_TRAITS.map(t => {
          const on = data.personality.includes(t.id);
          return (
            <button key={t.id} onClick={() => toggle(t.id)} style={{
              padding: '12px 18px', borderRadius: 999,
              border: `2px solid ${on ? sp.color : 'var(--line-2)'}`,
              background: on ? sp.color : 'var(--surface)',
              color: on ? '#fff' : 'var(--ink-950)',
              fontSize: 14, fontWeight: 800, cursor: 'pointer',
              display: 'inline-flex', alignItems: 'center', gap: 8,
              transition: 'all 200ms cubic-bezier(.5,1.7,.5,1)',
              transform: on ? 'scale(1.04)' : 'scale(1)',
              boxShadow: on ? `0 6px 14px -6px ${sp.color}` : 'none',
              fontFamily: 'inherit',
            }}>
              <span style={{ fontSize: 16 }}>{t.emoji}</span> {t.label}
            </button>
          );
        })}
      </div>

      <div style={{ marginTop: 'auto' }}>
        <Pill full size="lg" onClick={next} color={sp.color} iconRight={I.paw(18,'#fff')}>Meet {data.name || 'them'}</Pill>
      </div>
    </div>
  );
}

function StepDone({ sp, data }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', paddingTop: 50, height: '100%' }}>
      <div style={{ animation: 'pf-pop-in 600ms cubic-bezier(.3,1.7,.4,1)' }}>
        <PetAvatar species={data.species} size={140} ring glow/>
      </div>
      <h2 className="display" style={{ fontSize: 38, lineHeight: 1.05, marginTop: 24, color: 'var(--ink-950)' }}>
        Welcome, {data.name}!
      </h2>
      <p style={{ fontSize: 16, color: 'var(--ink-700)', marginTop: 8 }}>Let's set up their world…</p>
      <TailWagLoader size={90} label="Loading"/>
    </div>
  );
}

Object.assign(window, { Onboarding });
