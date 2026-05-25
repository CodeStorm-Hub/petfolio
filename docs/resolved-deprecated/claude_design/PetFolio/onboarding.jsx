// Onboarding — progressive profiling: species → name → breed → photo → done.
// Only collects the minimum needed; rest deferred to "complete later".

function Onboarding({ onComplete, dark }) {
  const [step, setStep] = React.useState(0); // 0=welcome 1=species 2=name 3=breed 4=photo 5=done
  const [draft, setDraft] = React.useState({ species: null, name: '', breed: null, photo: null });
  const total = 4; // visible progress steps (after welcome)

  const next = () => setStep(s => s + 1);
  const back = () => setStep(s => Math.max(0, s - 1));

  const update = (patch) => setDraft(d => ({ ...d, ...patch }));

  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      background: TOKENS.surface1,
      fontFamily: 'Inter, system-ui, sans-serif',
      color: TOKENS.ink950,
    }}>
      {step > 0 && step < 5 && (
        <OnboardingHeader step={step} total={total} onBack={back} />
      )}
      <div style={{ flex: 1, overflow: 'auto', WebkitOverflowScrolling: 'touch' }}>
        {step === 0 && <Welcome onStart={next} />}
        {step === 1 && <ChooseSpecies value={draft.species} onPick={(s) => { update({ species: s, breed: null }); next(); }} />}
        {step === 2 && <ChooseName value={draft.name} species={draft.species} onChange={(v) => update({ name: v })} onNext={next} />}
        {step === 3 && <ChooseBreed value={draft.breed} species={draft.species} onPick={(b) => { update({ breed: b }); next(); }} />}
        {step === 4 && <AddPhoto draft={draft} onSet={(url) => update({ photo: url })} onSkip={next} onNext={next} />}
        {step === 5 && <Done draft={draft} onEnter={() => onComplete(draft)} />}
      </div>
    </div>
  );
}

function OnboardingHeader({ step, total, onBack }) {
  return (
    <div style={{
      padding: '58px 16px 8px', display: 'flex', alignItems: 'center', gap: 14,
    }}>
      <button onClick={onBack} aria-label="Back" style={{
        width: 44, height: 44, borderRadius: '50%', border: 'none',
        background: TOKENS.surface0, color: TOKENS.ink700,
        boxShadow: '0 1px 2px rgba(11,18,32,0.06), 0 0 0 0.5px ' + TOKENS.line200,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0, cursor: 'pointer',
      }}>
        <svg width="10" height="18" viewBox="0 0 10 18"><path d="M9 1L1 9l8 8" stroke={TOKENS.ink700} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
      </button>
      <div style={{ flex: 1, display: 'flex', gap: 6 }}>
        {Array.from({ length: total }).map((_, i) => (
          <div key={i} style={{
            flex: 1, height: 4, borderRadius: 999,
            background: i < step ? TOKENS.blue500 : TOKENS.line200,
            transition: 'background 220ms',
          }} />
        ))}
      </div>
      <div style={{ fontSize: 13, color: TOKENS.ink500, fontVariantNumeric: 'tabular-nums', minWidth: 32 }}>{step}/{total}</div>
    </div>
  );
}

function Welcome({ onStart }) {
  return (
    <div style={{
      padding: '32px 24px 24px', height: '100%', display: 'flex', flexDirection: 'column',
      paddingTop: 96,
    }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', textAlign: 'center', gap: 28 }}>
        <Hero />
        <div>
          <div style={{
            fontFamily: 'Sora, system-ui', fontSize: 36, fontWeight: 700,
            letterSpacing: '-0.02em', lineHeight: 1.05, color: TOKENS.ink950,
          }}>Welcome to<br/>PetFolio</div>
          <div style={{
            marginTop: 14, fontSize: 17, lineHeight: 1.45,
            color: TOKENS.ink700, maxWidth: 300,
          }}>
            One home for every pet in your life — social, health, care, and the marketplace.
          </div>
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12, paddingBottom: 12 }}>
        <PrimaryButton onClick={onStart}>Add your first pet</PrimaryButton>
        <button style={{
          height: 52, borderRadius: 16, border: 'none', background: 'transparent',
          color: TOKENS.blue600, fontWeight: 600, fontSize: 16, cursor: 'pointer',
          fontFamily: 'Inter',
        }}>I'll do this later</button>
        <div style={{ textAlign: 'center', fontSize: 12, color: TOKENS.ink500, marginTop: 4 }}>
          You can add more pets anytime
        </div>
      </div>
    </div>
  );
}

function Hero() {
  // Soft staggered blobs in our secondary palette — no anatomical drawing.
  return (
    <div style={{ position: 'relative', width: 220, height: 160 }}>
      <div style={blob(TOKENS.coral,    8,   12, 100)}>L</div>
      <div style={blob(TOKENS.sunset,   100, 36, 84)}>M</div>
      <div style={blob(TOKENS.meadow,   58,  90, 72)}>H</div>
      <div style={blob(TOKENS.blue500,  140, 96, 60)}>+</div>
    </div>
  );
  function blob(color, x, y, size) {
    return {
      position: 'absolute', left: x, top: y, width: size, height: size,
      borderRadius: '50%',
      background: `radial-gradient(circle at 30% 25%, ${lighten(color, 0.4)} 0%, ${color} 55%, ${darken(color, 0.18)} 100%)`,
      boxShadow: '0 10px 30px -10px rgba(11,18,32,0.35), inset 0 1px 0 rgba(255,255,255,0.3)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: '#fff', fontFamily: 'Sora', fontWeight: 700, fontSize: size * 0.4,
      textShadow: '0 1px 3px rgba(0,0,0,0.2)',
    };
  }
}

function ChooseSpecies({ value, onPick }) {
  return (
    <StepFrame
      eyebrow="Step 1 of 4"
      title="What kind of pet?"
      sub="Pick one. You can add more pets later."
    >
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, padding: '0 4px' }}>
        {SPECIES.map(s => {
          const selected = value === s.id;
          return (
            <button key={s.id} onClick={() => onPick(s.id)} style={{
              border: 'none', cursor: 'pointer',
              background: selected ? s.tint : TOKENS.surface0,
              borderRadius: 20, padding: '20px 16px',
              display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 12,
              boxShadow: selected
                ? `0 0 0 2px ${s.accent}, 0 6px 18px -6px ${s.accent}55`
                : '0 0 0 0.5px ' + TOKENS.line200 + ', 0 1px 2px rgba(11,18,32,0.04)',
              minHeight: 124, textAlign: 'left',
              transition: 'box-shadow 180ms, background 180ms',
            }}>
              <div style={{
                width: 44, height: 44, borderRadius: 12, background: s.accent,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 4px 12px -4px ' + s.accent + 'aa, inset 0 1px 0 rgba(255,255,255,0.25)',
              }}>
                <svg width="22" height="22" viewBox="0 0 16 16" fill="#fff">
                  {SPECIES_GLYPHS[s.id]}
                </svg>
              </div>
              <div style={{
                fontFamily: 'Sora', fontWeight: 600, fontSize: 20,
                color: TOKENS.ink950, letterSpacing: '-0.01em',
              }}>{s.label}</div>
            </button>
          );
        })}
      </div>
    </StepFrame>
  );
}

function ChooseName({ value, species, onChange, onNext }) {
  const sp = SPECIES.find(s => s.id === species);
  const ready = value.trim().length >= 1;
  const inputRef = React.useRef(null);
  React.useEffect(() => { setTimeout(() => inputRef.current && inputRef.current.focus(), 100); }, []);
  return (
    <StepFrame
      eyebrow="Step 2 of 4"
      title={`What's your ${sp?.label.toLowerCase() || 'pet'}'s name?`}
      sub="Just a name for now — you can fill in the rest later."
      cta={<PrimaryButton disabled={!ready} onClick={onNext}>Continue</PrimaryButton>}
    >
      <div style={{ padding: '8px 4px 0' }}>
        <input
          ref={inputRef}
          value={value}
          onChange={e => onChange(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter' && ready) onNext(); }}
          placeholder="e.g. Luna"
          aria-label="Pet name"
          style={{
            width: '100%', boxSizing: 'border-box',
            height: 64, padding: '0 20px',
            border: 'none', borderRadius: 16,
            background: TOKENS.surface0,
            boxShadow: '0 0 0 1.5px ' + (ready ? TOKENS.blue500 : TOKENS.line200) + ', 0 1px 2px rgba(11,18,32,0.04)',
            fontSize: 22, fontFamily: 'Sora', fontWeight: 600,
            color: TOKENS.ink950, letterSpacing: '-0.01em', outline: 'none',
            transition: 'box-shadow 160ms',
          }}
        />
        <div style={{ marginTop: 12, fontSize: 13, color: TOKENS.ink500, paddingLeft: 4 }}>
          {value.length} / 24
        </div>
      </div>
    </StepFrame>
  );
}

function ChooseBreed({ value, species, onPick }) {
  const sp = SPECIES.find(s => s.id === species);
  const [q, setQ] = React.useState('');
  const breeds = sp ? sp.breeds : [];
  const filtered = q ? breeds.filter(b => b.toLowerCase().includes(q.toLowerCase())) : breeds;
  return (
    <StepFrame
      eyebrow="Step 3 of 4"
      title="Breed?"
      sub={`Pick one or tap "Don't know yet" — you can change this anytime.`}
    >
      <div style={{ padding: '0 4px' }}>
        <div style={{
          height: 52, borderRadius: 14, background: TOKENS.surface0,
          boxShadow: '0 0 0 0.5px ' + TOKENS.line200,
          display: 'flex', alignItems: 'center', padding: '0 16px', gap: 10,
        }}>
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
            <circle cx="8" cy="8" r="6" stroke={TOKENS.ink500} strokeWidth="1.75"/>
            <path d="M13 13l4 4" stroke={TOKENS.ink500} strokeWidth="1.75" strokeLinecap="round"/>
          </svg>
          <input
            value={q} onChange={e => setQ(e.target.value)}
            placeholder="Search breeds"
            style={{
              flex: 1, height: '100%', border: 'none', background: 'transparent',
              outline: 'none', fontSize: 16, color: TOKENS.ink950,
              fontFamily: 'Inter',
            }}
          />
        </div>
        <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
          {filtered.map(b => {
            const selected = value === b;
            const isUnknown = b.startsWith("Don't");
            return (
              <button key={b} onClick={() => onPick(b)} style={{
                height: 56, borderRadius: 14, border: 'none', cursor: 'pointer',
                background: selected ? sp.tint : (isUnknown ? TOKENS.surface2 : TOKENS.surface0),
                boxShadow: selected
                  ? `0 0 0 2px ${sp.accent}`
                  : '0 0 0 0.5px ' + TOKENS.line200,
                padding: '0 18px', textAlign: 'left',
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                fontFamily: 'Inter', fontWeight: 500, fontSize: 16,
                color: isUnknown ? TOKENS.ink700 : TOKENS.ink950,
                fontStyle: isUnknown ? 'italic' : 'normal',
              }}>
                <span>{b}</span>
                {selected && (
                  <svg width="22" height="22" viewBox="0 0 22 22"><circle cx="11" cy="11" r="11" fill={sp.accent}/><path d="M6 11.5l3.5 3.5L16 8" stroke="#fff" strokeWidth="2.2" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
                )}
              </button>
            );
          })}
          {filtered.length === 0 && (
            <div style={{ padding: 24, textAlign: 'center', color: TOKENS.ink500, fontSize: 14 }}>
              No breeds match "{q}". Tap "Don't know yet" — you can always edit later.
            </div>
          )}
        </div>
      </div>
    </StepFrame>
  );
}

function AddPhoto({ draft, onSet, onSkip, onNext }) {
  const sp = SPECIES.find(s => s.id === draft.species);
  const inputRef = React.useRef(null);
  const handleFile = (e) => {
    const file = e.target.files && e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => onSet(ev.target.result);
    reader.readAsDataURL(file);
  };
  return (
    <StepFrame
      eyebrow="Step 4 of 4"
      title={`A photo of ${draft.name || 'your pet'}?`}
      sub="Optional — gives your feed a face. You can add one later."
      cta={
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <PrimaryButton onClick={onNext}>{draft.photo ? 'Continue' : 'Skip for now'}</PrimaryButton>
          {!draft.photo && (
            <button onClick={() => inputRef.current && inputRef.current.click()} style={{
              height: 44, borderRadius: 14, border: 'none', cursor: 'pointer',
              background: 'transparent', color: TOKENS.blue600,
              fontFamily: 'Inter', fontWeight: 600, fontSize: 15,
            }}>Choose from library</button>
          )}
        </div>
      }
    >
      <input ref={inputRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleFile} />
      <div style={{ padding: '8px 4px 0', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18 }}>
        <button
          onClick={() => inputRef.current && inputRef.current.click()}
          style={{
            width: 220, height: 220, borderRadius: 36, border: 'none',
            background: draft.photo ? `url(${draft.photo}) center/cover` : sp?.tint || TOKENS.surface2,
            cursor: 'pointer', position: 'relative', overflow: 'hidden',
            boxShadow: draft.photo
              ? `0 18px 40px -12px ${sp?.accent || '#000'}55, 0 0 0 4px ${sp?.tint || TOKENS.line200}`
              : `0 0 0 2px dashed ${sp?.accent || TOKENS.line200}`,
            outline: draft.photo ? 'none' : `2px dashed ${sp?.accent || TOKENS.ink300}`,
            outlineOffset: -10,
          }}
        >
          {!draft.photo && (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12 }}>
              <div style={{
                width: 56, height: 56, borderRadius: '50%',
                background: sp?.accent || TOKENS.blue500,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.3)',
              }}>
                <svg width="26" height="26" viewBox="0 0 26 26" fill="none">
                  <path d="M13 5v16M5 13h16" stroke="#fff" strokeWidth="2.5" strokeLinecap="round"/>
                </svg>
              </div>
              <div style={{ fontFamily: 'Sora', fontWeight: 600, fontSize: 16, color: sp?.accent || TOKENS.ink700 }}>
                Tap to add photo
              </div>
            </div>
          )}
        </button>
        <div style={{ fontSize: 13, color: TOKENS.ink500, textAlign: 'center', maxWidth: 280, lineHeight: 1.45 }}>
          We'll never share photos without your permission. EXIF location data is stripped on upload.
        </div>
      </div>
    </StepFrame>
  );
}

function Done({ draft, onEnter }) {
  const sp = SPECIES.find(s => s.id === draft.species);
  return (
    <div style={{
      padding: '88px 24px 24px', height: '100%', display: 'flex', flexDirection: 'column',
      background: `linear-gradient(180deg, ${sp?.tint || TOKENS.blue50} 0%, ${TOKENS.surface1} 60%)`,
    }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', gap: 28, textAlign: 'center' }}>
        <PetAvatar
          pet={{ name: draft.name, accent: sp?.accent, tint: sp?.tint, species: draft.species }}
          photoUrl={draft.photo}
          size={140}
          ring={`linear-gradient(135deg, ${sp?.accent}, ${lighten(sp?.accent || '#888', 0.3)})`}
        />
        <div>
          <div style={{
            fontFamily: 'Sora', fontSize: 32, fontWeight: 700,
            letterSpacing: '-0.02em', color: TOKENS.ink950, lineHeight: 1.1,
          }}>
            Hi, {draft.name || 'friend'}.
          </div>
          <div style={{ marginTop: 12, fontSize: 16, lineHeight: 1.45, color: TOKENS.ink700, maxWidth: 280 }}>
            {draft.breed && !draft.breed.startsWith("Don't") ? `${draft.breed} · ` : ''}
            Profile created. You can fill in age, weight, vet info anytime from Health.
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'center', fontSize: 13, color: TOKENS.ink500 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Dot color={TOKENS.success}/> Basic profile
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, opacity: 0.6 }}>
            <Dot color={TOKENS.ink300}/> Health & vaccinations · later
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, opacity: 0.6 }}>
            <Dot color={TOKENS.ink300}/> Daily care routine · later
          </div>
        </div>
      </div>
      <PrimaryButton onClick={onEnter}>Enter PetFolio</PrimaryButton>
    </div>
  );
}

function Dot({ color }) {
  return <span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: '50%', background: color }}/>;
}

function StepFrame({ eyebrow, title, sub, children, cta }) {
  return (
    <div style={{ padding: '20px 20px 24px', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <div style={{ marginBottom: 24 }}>
        {eyebrow && (
          <div style={{
            fontSize: 12, fontWeight: 600, letterSpacing: '0.08em',
            textTransform: 'uppercase', color: TOKENS.blue600, marginBottom: 8,
          }}>{eyebrow}</div>
        )}
        <div style={{
          fontFamily: 'Sora', fontSize: 30, fontWeight: 700,
          letterSpacing: '-0.02em', lineHeight: 1.1, color: TOKENS.ink950,
        }}>{title}</div>
        {sub && (
          <div style={{ marginTop: 10, fontSize: 15, lineHeight: 1.45, color: TOKENS.ink700 }}>
            {sub}
          </div>
        )}
      </div>
      <div style={{ flex: 1, minHeight: 0 }}>{children}</div>
      {cta && <div style={{ paddingTop: 16 }}>{cta}</div>}
    </div>
  );
}

function PrimaryButton({ children, onClick, disabled }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      width: '100%', height: 56, borderRadius: 16, border: 'none',
      background: disabled ? TOKENS.blue200 : TOKENS.blue500,
      color: '#fff', fontFamily: 'Inter', fontWeight: 600, fontSize: 17,
      letterSpacing: '-0.01em',
      boxShadow: disabled ? 'none' : '0 8px 24px -8px ' + TOKENS.blue500 + 'aa, 0 1px 2px rgba(11,18,32,0.08)',
      cursor: disabled ? 'not-allowed' : 'pointer',
      transition: 'transform 80ms ease-out, box-shadow 160ms',
    }}
    onMouseDown={(e) => !disabled && (e.currentTarget.style.transform = 'scale(0.97)')}
    onMouseUp={(e) => (e.currentTarget.style.transform = 'scale(1)')}
    onMouseLeave={(e) => (e.currentTarget.style.transform = 'scale(1)')}
    >{children}</button>
  );
}

Object.assign(window, { Onboarding, PrimaryButton });
