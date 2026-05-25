// match.jsx — Pet Dating swipe stack + Mutual Match overlay

const DEMO_MATCHES = [
  { id: 'm1', name: 'Biscuit', age: 3, breed: 'Corgi',     species: 'dog', dist: '0.4 km', bio: "Snuffle pro. Will trade belly rubs for treats.", color: 'var(--tangerine)', soft: 'var(--tangerine-soft)' },
  { id: 'm2', name: 'Pepper',  age: 2, breed: 'Tabby',     species: 'cat', dist: '0.8 km', bio: 'Window watcher. Aspiring hat model.', color: 'var(--poppy)', soft: 'var(--poppy-soft)' },
  { id: 'm3', name: 'Beans',   age: 5, breed: 'Husky',     species: 'dog', dist: '1.2 km', bio: 'Snow enthusiast. Dramatic singer.', color: 'var(--sky)', soft: 'var(--sky-soft)' },
  { id: 'm4', name: 'Sushi',   age: 1, breed: 'Holland Lop', species: 'rabbit', dist: '1.5 km', bio: 'Vegetable connoisseur. Loaf 24/7.', color: 'var(--lilac)', soft: 'var(--lilac-soft)' },
];

function MatchScreen({ navigate, openSwitcher, activePet, motif }) {
  const [stack, setStack] = React.useState(DEMO_MATCHES);
  const [dir, setDir] = React.useState(null); // {id, x, rot}
  const [matched, setMatched] = React.useState(null);
  const [drag, setDrag] = React.useState(null); // {id, dx, dy}

  function swipe(card, direction) {
    setDir({ id: card.id, dir: direction });
    setTimeout(() => {
      setStack(s => s.filter(x => x.id !== card.id));
      setDir(null);
      setDrag(null);
      if (direction === 'right' && card.id === 'm1') {
        setTimeout(() => setMatched(card), 250);
      }
    }, 340);
  }

  const pet = DEMO_PETS.find(p => p.id === activePet) || DEMO_PETS[0];

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: 'var(--cream)' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 18px 8px' }}>
        <button onClick={openSwitcher} style={{
          display: 'flex', alignItems: 'center', gap: 8, background: 'transparent', border: 'none', cursor: 'pointer',
        }}>
          <PetAvatar species={pet.species} size={36} ring/>
          <div style={{ textAlign: 'left' }}>
            <div style={{ fontSize: 10, color: 'var(--ink-500)', fontWeight: 700, letterSpacing: 0.6 }}>MATCH AS</div>
            <div style={{ fontSize: 15, fontWeight: 800, color: 'var(--ink-950)', display: 'flex', alignItems: 'center', gap: 4 }}>
              {pet.name} {I.chevronDown(14)}
            </div>
          </div>
        </button>
        <div style={{ display: 'flex', gap: 8 }}>
          <IconBtn>{I.comment(20)}</IconBtn>
          <IconBtn>{I.filter(20)}</IconBtn>
        </div>
      </div>

      <div style={{ padding: '4px 18px 6px', display: 'flex', alignItems: 'center', gap: 8 }}>
        <span style={{ fontSize: 12, fontWeight: 800, color: 'var(--poppy-700)', background: 'var(--poppy-soft)', padding: '4px 10px', borderRadius: 999 }}>
          🔥 Within 5 km
        </span>
        <span style={{ fontSize: 12, fontWeight: 800, color: 'var(--mint-700)', background: 'var(--mint-soft)', padding: '4px 10px', borderRadius: 999 }}>
          Playdates ON
        </span>
      </div>

      {/* Stack */}
      <div style={{ flex: 1, position: 'relative', padding: '8px 16px 12px' }}>
        {stack.length === 0 && (
          <EmptyStack onReset={() => setStack(DEMO_MATCHES)}/>
        )}
        {stack.slice(0, 3).reverse().map((c, idxFromTop) => {
          const i = 2 - idxFromTop; // 0 = back, 2 = front
          const isFront = i === 0;
          const isSwiping = dir && dir.id === c.id;
          const d = drag && drag.id === c.id ? drag : null;
          const tx = isSwiping ? (dir.dir === 'right' ? 600 : -600) : (d ? d.dx : 0);
          const rot = isSwiping ? (dir.dir === 'right' ? 22 : -22) : (d ? d.dx / 14 : 0);
          const liked = d ? d.dx > 60 : (isSwiping && dir.dir === 'right');
          const disliked = d ? d.dx < -60 : (isSwiping && dir.dir === 'left');
          return (
            <SwipeCard
              key={c.id}
              card={c}
              depth={i}
              tx={tx}
              rot={rot}
              liked={liked}
              disliked={disliked}
              swiping={!!isSwiping}
              onStart={(x,y) => isFront && setDrag({ id: c.id, dx: 0, dy: 0, ox: x, oy: y })}
              onMove={(x,y) => isFront && drag && drag.id === c.id && setDrag({ ...drag, dx: x - drag.ox, dy: y - drag.oy })}
              onEnd={() => {
                if (!isFront || !drag) return;
                if (drag.dx > 100) swipe(c, 'right');
                else if (drag.dx < -100) swipe(c, 'left');
                else setDrag(null);
              }}
            />
          );
        })}
      </div>

      {/* Actions */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16, padding: '0 18px 18px' }}>
        <RoundAction color="var(--ink-500)" bg="var(--surface)" onClick={() => stack[0] && swipe(stack[0], 'left')} size={56}>✕</RoundAction>
        <RoundAction color="#fff" bg="var(--lilac)" onClick={() => stack[0] && swipe(stack[0], 'right')} size={48}>⭐</RoundAction>
        <RoundAction color="#fff" bg="var(--poppy)" onClick={() => stack[0] && swipe(stack[0], 'right')} size={72}>
          <span style={{ fontSize: 32 }}>🐾</span>
        </RoundAction>
        <RoundAction color="#fff" bg="var(--sunny)" size={48}>🦴</RoundAction>
        <RoundAction color="#fff" bg="var(--mint)" size={56}>↺</RoundAction>
      </div>

      {/* Mutual match overlay */}
      {matched && <MutualMatch other={matched} self={pet} onClose={() => setMatched(null)}/>}
    </div>
  );
}

function RoundAction({ children, onClick, bg, color, size = 56 }) {
  return (
    <button onClick={onClick} style={{
      width: size, height: size, borderRadius: '50%', border: 'none', cursor: 'pointer',
      background: bg, color, fontSize: size * 0.4, fontWeight: 900,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: `0 6px 0 0 color-mix(in oklab, ${bg} 60%, black), 0 14px 24px -10px ${bg}`,
      transition: 'transform 120ms',
    }}
      onPointerDown={e => e.currentTarget.style.transform = 'translateY(3px)'}
      onPointerUp={e => e.currentTarget.style.transform = ''}
      onPointerLeave={e => e.currentTarget.style.transform = ''}
    >{children}</button>
  );
}

function SwipeCard({ card, depth, tx, rot, liked, disliked, swiping, onStart, onMove, onEnd }) {
  const scale = 1 - depth * 0.05;
  const ty = depth * 12;
  return (
    <div
      onPointerDown={e => { e.target.setPointerCapture && e.target.setPointerCapture(e.pointerId); onStart(e.clientX, e.clientY); }}
      onPointerMove={e => onMove(e.clientX, e.clientY)}
      onPointerUp={onEnd}
      onPointerCancel={onEnd}
      style={{
        position: 'absolute', inset: 0,
        transform: `translate(${tx}px, ${ty}px) scale(${scale}) rotate(${rot}deg)`,
        transition: swiping ? 'transform 320ms cubic-bezier(.4,0,.6,1)' : (tx === 0 ? 'transform 280ms cubic-bezier(.3,1.4,.5,1)' : 'none'),
        borderRadius: 32, overflow: 'hidden',
        background: `linear-gradient(135deg, ${card.soft}, ${card.color})`,
        boxShadow: '0 24px 50px -20px rgba(0,0,0,0.3)',
        display: 'flex', flexDirection: 'column',
        touchAction: 'none',
        cursor: depth === 0 ? 'grab' : 'default',
      }}
    >
      {/* Photo block */}
      <div style={{
        flex: 1, position: 'relative',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: `radial-gradient(circle at 30% 30%, ${card.soft}, ${card.color} 110%)`,
      }}>
        <div style={{ fontSize: 160, filter: 'drop-shadow(0 12px 28px rgba(0,0,0,0.2))' }}>
          {SPECIES.find(s => s.id === card.species)?.emoji}
        </div>

        {/* Like/Nope stamps */}
        {liked && <Stamp color="var(--mint)" rotate={-12} label="WOOF YES"/>}
        {disliked && <Stamp color="var(--ink-500)" rotate={12} label="NEXT" right/>}

        {/* Distance pill */}
        <div style={{
          position: 'absolute', top: 14, right: 14,
          background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(8px)',
          color: '#fff', padding: '6px 12px', borderRadius: 999,
          fontSize: 12, fontWeight: 800,
          display: 'flex', alignItems: 'center', gap: 4,
        }}>
          {I.location(12, '#fff')} {card.dist}
        </div>

        {/* Info gradient */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          padding: '40px 20px 20px',
          background: 'linear-gradient(to top, rgba(0,0,0,0.7), transparent)',
          color: '#fff',
        }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginBottom: 4 }}>
            <h2 className="display" style={{ fontSize: 32, color: '#fff' }}>{card.name},</h2>
            <span style={{ fontSize: 24, fontWeight: 700, opacity: 0.9 }}>{card.age}</span>
          </div>
          <div style={{ fontSize: 13, opacity: 0.9, fontWeight: 700, marginBottom: 8 }}>{card.breed}</div>
          <div style={{ fontSize: 14, lineHeight: 1.4, fontWeight: 600 }}>{card.bio}</div>

          {/* Trait chips */}
          <div style={{ display: 'flex', gap: 6, marginTop: 12, flexWrap: 'wrap' }}>
            {['🦴 Treat fiend', '🎾 Playful', '🤗 Cuddly'].map((t,i) => (
              <span key={i} style={{
                background: 'rgba(255,255,255,0.22)', backdropFilter: 'blur(6px)',
                padding: '4px 10px', borderRadius: 999, fontSize: 11, fontWeight: 700,
              }}>{t}</span>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function Stamp({ color, rotate, label, right }) {
  return (
    <div style={{
      position: 'absolute', top: 28, [right ? 'right' : 'left']: 28,
      transform: `rotate(${rotate}deg)`,
      border: `4px solid ${color}`, borderRadius: 14,
      padding: '6px 12px', fontWeight: 900, color, fontSize: 22, letterSpacing: 1,
      background: 'rgba(255,255,255,0.85)',
    }}>{label}</div>
  );
}

function EmptyStack({ onReset }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100%', textAlign: 'center', gap: 16 }}>
      <div style={{ fontSize: 72 }}>🐾</div>
      <h3 className="display" style={{ fontSize: 24 }}>That's the pack near you!</h3>
      <p style={{ fontSize: 14, color: 'var(--ink-500)', fontWeight: 600, maxWidth: 260 }}>Widen your radius or check back later — new pups join every day.</p>
      <Pill onClick={onReset}>Start over</Pill>
    </div>
  );
}

// ─── Mutual match overlay ──────────────────────────────────
function MutualMatch({ other, self, onClose }) {
  const selfSp = SPECIES.find(s => s.id === self.species);
  const otherSp = SPECIES.find(s => s.id === other.species);

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 60,
      background: `radial-gradient(circle at 50% 35%, ${other.color}, var(--poppy) 70%, var(--lilac) 100%)`,
      overflow: 'hidden',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      animation: 'pf-fade-up 320ms ease-out',
    }}>
      {/* Confetti */}
      <Confetti count={60} colors={['#fff','var(--sunny)','var(--mint)','var(--lilac)','var(--tangerine)']}/>

      {/* Floating paws bg */}
      <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none', opacity: 0.2 }}>
        {[[10,10,38,-10],[80,18,30,15],[15,72,42,-20],[78,80,36,18],[50,30,28,8]].map(([x,y,s,r],i) => (
          <div key={i} style={{ position: 'absolute', left: `${x}%`, top: `${y}%`, transform: `rotate(${r}deg)`, animation: `pf-bounce-soft ${1800+i*150}ms ease-in-out infinite` }}>
            {I.paw(s, '#fff')}
          </div>
        ))}
      </div>

      {/* Headline */}
      <div style={{ textAlign: 'center', marginTop: -40, position: 'relative', zIndex: 2 }}>
        <div style={{ display: 'inline-block', animation: 'pf-pop-in 700ms cubic-bezier(.3,1.7,.4,1)' }}>
          <div style={{ fontSize: 80, filter: 'drop-shadow(0 8px 22px rgba(0,0,0,0.3))', animation: 'pf-wiggle 1.2s ease-in-out infinite' }}>🐾💕🐾</div>
        </div>
        <h1 className="display" style={{ fontSize: 56, color: '#fff', textShadow: '0 6px 22px rgba(0,0,0,0.3)', lineHeight: 1, marginTop: 12 }}>
          It's a<br/><span style={{ fontStyle: 'italic' }}>Pawfect Match!</span>
        </h1>
        <p style={{ color: '#fff', fontSize: 16, fontWeight: 700, marginTop: 12, opacity: 0.92 }}>
          {self.name} & {other.name} both said WOOF
        </p>
      </div>

      {/* The two avatars pressing paws */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', marginTop: 36, gap: 0, position: 'relative', zIndex: 2 }}>
        <div style={{ animation: 'pf-pop-in 600ms cubic-bezier(.3,1.7,.4,1) 100ms both' }}>
          <div style={{
            width: 134, height: 134, borderRadius: '50%',
            background: 'rgba(255,255,255,0.25)', padding: 8,
            boxShadow: '0 16px 40px -10px rgba(0,0,0,0.3)',
            transform: 'rotate(-8deg)',
          }}>
            <div style={{ width: '100%', height: '100%', borderRadius: '50%', background: 'var(--surface)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 70 }}>
              {selfSp.emoji}
            </div>
          </div>
        </div>
        {/* Connecting paw */}
        <div style={{
          width: 70, height: 70, borderRadius: '50%',
          background: 'var(--sunny)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          margin: '0 -18px', zIndex: 3,
          boxShadow: '0 0 0 6px var(--surface), 0 12px 28px -8px rgba(0,0,0,0.3)',
          animation: 'pf-pop-in 500ms cubic-bezier(.3,1.7,.4,1) 400ms both',
        }}>
          {I.paw(36, 'var(--ink-950)')}
        </div>
        <div style={{ animation: 'pf-pop-in 600ms cubic-bezier(.3,1.7,.4,1) 250ms both' }}>
          <div style={{
            width: 134, height: 134, borderRadius: '50%',
            background: 'rgba(255,255,255,0.25)', padding: 8,
            boxShadow: '0 16px 40px -10px rgba(0,0,0,0.3)',
            transform: 'rotate(8deg)',
          }}>
            <div style={{ width: '100%', height: '100%', borderRadius: '50%', background: 'var(--surface)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 70 }}>
              {otherSp.emoji}
            </div>
          </div>
        </div>
      </div>

      {/* Actions */}
      <div style={{ width: '100%', padding: '32px 24px 32px', display: 'flex', flexDirection: 'column', gap: 10, position: 'relative', zIndex: 2, marginTop: 'auto' }}>
        <Pill full size="lg" variant="primary" color="var(--surface)" style={{ color: 'var(--poppy-700)' }}>
          Send a tail wag 🐾
        </Pill>
        <button onClick={onClose} style={{
          background: 'transparent', border: 'none', color: '#fff', fontWeight: 800, fontSize: 14, padding: 12, cursor: 'pointer', opacity: 0.9,
        }}>Keep swiping</button>
      </div>
    </div>
  );
}

Object.assign(window, { MatchScreen });
