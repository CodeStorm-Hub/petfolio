// care.jsx — Gamified daily care (Duolingo-style) + badge vault

function CareScreen({ activePet, openSwitcher, navigate, motif }) {
  const pet = DEMO_PETS.find(p => p.id === activePet) || DEMO_PETS[0];
  const sp = SPECIES.find(s => s.id === pet.species) || SPECIES[0];
  const [tasks, setTasks] = React.useState([
    { id: 't1', icon: '🦴', label: 'Breakfast',     time: '8:00 AM',  xp: 10, done: true,  color: 'var(--tangerine)' },
    { id: 't2', icon: '💊', label: 'Heartworm pill', time: '12:00 PM', xp: 20, done: false, color: 'var(--poppy)', due: true },
    { id: 't3', icon: '🚶', label: 'Evening walk',   time: '5:30 PM',  xp: 15, done: false, color: 'var(--mint)' },
    { id: 't4', icon: '🍖', label: 'Dinner',         time: '6:30 PM',  xp: 10, done: false, color: 'var(--sunny)' },
    { id: 't5', icon: '🪥', label: 'Tooth brush',    time: 'Bedtime',  xp: 25, done: false, color: 'var(--lilac)', weekly: true },
  ]);
  const [burst, setBurst] = React.useState(null);

  const completed = tasks.filter(t => t.done).length;
  const totalXP = tasks.filter(t => t.done).reduce((s, t) => s + t.xp, 0);
  const progress = (completed / tasks.length) * 100;

  function toggle(id, e) {
    setTasks(ts => ts.map(t => t.id === id ? { ...t, done: !t.done } : t));
    if (e) {
      const t = tasks.find(x => x.id === id);
      if (t && !t.done) {
        const rect = e.currentTarget.getBoundingClientRect();
        const parentRect = e.currentTarget.offsetParent?.getBoundingClientRect();
        setBurst({
          x: rect.left - (parentRect?.left||0) + rect.width/2,
          y: rect.top - (parentRect?.top||0) + rect.height/2,
          xp: t.xp,
        });
        setTimeout(() => setBurst(null), 1200);
      }
    }
  }

  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 100, background: 'var(--cream)', position: 'relative' }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(180deg, var(--sunny-soft), var(--cream))',
        padding: '14px 18px 0',
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 }}>
          <button onClick={openSwitcher} style={{
            display: 'flex', alignItems: 'center', gap: 10, background: 'transparent', border: 'none', cursor: 'pointer',
          }}>
            <PetAvatar species={pet.species} size={36} ring/>
            <div style={{ textAlign: 'left' }}>
              <div style={{ fontSize: 10, color: 'var(--ink-500)', fontWeight: 700, letterSpacing: 0.6 }}>CARING FOR</div>
              <div style={{ fontSize: 15, fontWeight: 800, color: 'var(--ink-950)', display: 'flex', alignItems: 'center', gap: 4 }}>{pet.name} {I.chevronDown(14)}</div>
            </div>
          </button>
          <IconBtn onClick={() => navigate('health')} bg="var(--mint-soft)" color="var(--mint-700)" shadow={false}>{I.stethoscope(22)}</IconBtn>
        </div>

        {/* Big streak + XP ring */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 18, padding: '12px 4px 22px' }}>
          {/* Streak flame */}
          <div style={{ position: 'relative', width: 110, height: 110, flexShrink: 0 }}>
            <div style={{
              position: 'absolute', inset: 0, borderRadius: '50%',
              background: 'radial-gradient(circle at 50% 60%, var(--sunny), var(--tangerine) 70%)',
              boxShadow: '0 14px 28px -8px var(--tangerine)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              animation: 'pf-bounce-soft 2.4s ease-in-out infinite',
            }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 36, lineHeight: 1 }}>🔥</div>
                <div className="display" style={{ fontSize: 28, color: '#fff', lineHeight: 1, marginTop: 2 }}>{pet.streak}</div>
                <div style={{ fontSize: 10, color: '#fff', fontWeight: 800, letterSpacing: 0.6 }}>DAY STREAK</div>
              </div>
            </div>
            {/* Pulse ring */}
            <div style={{ position: 'absolute', inset: -4, borderRadius: '50%', border: '3px solid var(--tangerine)', animation: 'pf-pulse-ring 2s ease-out infinite' }}/>
          </div>

          {/* XP & level */}
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, flexWrap: 'wrap' }}>
              <span style={{ fontSize: 24, fontWeight: 900, color: 'var(--ink-950)', lineHeight: 1 }}>Lv 7</span>
              <span style={{ fontSize: 13, color: 'var(--ink-500)', fontWeight: 800 }}>Caretaker</span>
            </div>
            <div style={{ fontSize: 12, color: 'var(--ink-700)', fontWeight: 700, marginTop: 4, marginBottom: 8 }}>{pet.xp + totalXP} / 600 XP</div>
            <div style={{ height: 12, borderRadius: 999, background: 'rgba(255,255,255,0.7)', position: 'relative', overflow: 'hidden', border: '1.5px solid var(--line-2)' }}>
              <div style={{
                height: '100%', width: `${Math.min(100, ((pet.xp + totalXP) / 600) * 100)}%`,
                background: 'linear-gradient(90deg, var(--sunny), var(--tangerine), var(--poppy))',
                borderRadius: 999, position: 'relative',
              }}>
                <div style={{ position: 'absolute', inset: 0, borderRadius: 999, background: 'linear-gradient(180deg, rgba(255,255,255,0.4), transparent)' }}/>
              </div>
            </div>
            <div style={{ fontSize: 11, color: 'var(--ink-500)', fontWeight: 700, marginTop: 6 }}>118 XP to <b>Lv 8 · Pet Whisperer</b></div>
          </div>
        </div>
      </div>

      {/* Today's quests */}
      <div style={{ padding: '16px 16px 0', position: 'relative' }}>
        <SectionTitle accent="var(--tangerine)" right={
          <div style={{ fontSize: 12, fontWeight: 800, color: 'var(--ink-500)' }}>{completed}/{tasks.length} done</div>
        }>Today's quests</SectionTitle>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {tasks.map(t => (
            <TaskRow key={t.id} task={t} onToggle={(e) => toggle(t.id, e)}/>
          ))}
        </div>

        {/* XP burst */}
        {burst && (
          <div style={{ position: 'absolute', left: burst.x, top: burst.y, pointerEvents: 'none' }}>
            <div style={{
              fontSize: 26, fontWeight: 900, color: 'var(--sunny-700)',
              animation: 'pf-float-up 1100ms cubic-bezier(.2,.8,.2,1) forwards',
              textShadow: '0 4px 12px rgba(255,197,61,0.6)',
              '--dx': '0px', '--rot': '0deg',
            }}>+{burst.xp} XP ⭐</div>
          </div>
        )}
      </div>

      {/* Weekly chart */}
      <div style={{ padding: '20px 16px 0' }}>
        <SectionTitle accent="var(--mint)">This week</SectionTitle>
        <Card pad={18}>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10, height: 110 }}>
            {[
              { d: 'M', h: 86, c: 'var(--tangerine)' },
              { d: 'T', h: 94, c: 'var(--poppy)' },
              { d: 'W', h: 70, c: 'var(--mint)' },
              { d: 'T', h: 100, c: 'var(--sunny)' },
              { d: 'F', h: 88, c: 'var(--lilac)' },
              { d: 'S', h: 60, c: 'var(--tangerine)' },
              { d: 'S', h: Math.max(20, progress), c: 'var(--poppy)', today: true },
            ].map((b, i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                <div style={{
                  width: '100%', height: `${b.h}%`,
                  background: `linear-gradient(180deg, ${b.c}, color-mix(in oklab, ${b.c} 70%, white))`,
                  borderRadius: 12,
                  border: b.today ? `2px solid var(--ink-950)` : 'none',
                  position: 'relative',
                  boxShadow: b.today ? '0 8px 16px -4px ' + b.c : 'none',
                }}>
                  {b.today && <div style={{ position: 'absolute', top: -16, left: '50%', transform: 'translateX(-50%)', fontSize: 12 }}>🐾</div>}
                </div>
                <div style={{ fontSize: 11, fontWeight: 800, color: b.today ? 'var(--ink-950)' : 'var(--ink-500)' }}>{b.d}</div>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Badge vault */}
      <div style={{ padding: '20px 16px 0' }}>
        <SectionTitle accent="var(--lilac)" right={<button style={{ background: 'transparent', border: 'none', color: 'var(--lilac-700)', fontWeight: 800, fontSize: 13, cursor: 'pointer' }}>Vault →</button>}>
          Trophy room
        </SectionTitle>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {[
            { e: '🔥', c: 'var(--sunny)',     l: '7-Day',     own: true },
            { e: '💯', c: 'var(--poppy)', l: '100 XP',    own: true },
            { e: '🦴', c: 'var(--tangerine)', l: 'Treat Pro', own: true },
            { e: '💉', c: 'var(--mint)',      l: 'Vaccinated',own: true },
            { e: '🎓', c: 'var(--lilac)',     l: 'Trained',   own: false },
            { e: '🏆', c: 'var(--sunny)',     l: '30-Day',    own: false },
            { e: '🌟', c: 'var(--poppy)', l: 'Lv 10',     own: false },
            { e: '👑', c: 'var(--tangerine)', l: 'Top 1%',    own: false },
          ].map((b, i) => (
            <BadgeTile key={i} {...b}/>
          ))}
        </div>
      </div>
    </div>
  );
}

function TaskRow({ task, onToggle }) {
  return (
    <div style={{
      background: task.done ? 'color-mix(in oklab, ' + task.color + ' 14%, var(--surface))' : 'var(--surface)',
      borderRadius: 22,
      padding: '14px 16px',
      display: 'flex', alignItems: 'center', gap: 14,
      border: `2px solid ${task.done ? task.color : 'var(--line)'}`,
      transition: 'all 240ms',
      opacity: task.done ? 0.85 : 1,
      boxShadow: task.due && !task.done ? '0 0 0 4px color-mix(in oklab, var(--poppy) 25%, transparent)' : 'var(--shadow-soft)',
    }}>
      <div style={{
        width: 52, height: 52, borderRadius: 18,
        background: task.done ? task.color : `color-mix(in oklab, ${task.color} 22%, var(--surface))`,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 26,
        flexShrink: 0,
      }}>{task.done ? '✅' : task.icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 15, fontWeight: 800, color: 'var(--ink-950)', textDecoration: task.done ? 'line-through' : 'none' }}>{task.label}</span>
          {task.weekly && <span style={{ background: 'var(--lilac-soft)', color: 'var(--lilac-700)', fontSize: 10, padding: '2px 8px', borderRadius: 999, fontWeight: 900 }}>WEEKLY</span>}
        </div>
        <div style={{ fontSize: 12, color: task.due ? 'var(--poppy-700)' : 'var(--ink-500)', fontWeight: 700 }}>{task.due ? `Due ${task.time}` : task.time}</div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{
          background: task.done ? 'var(--mint-soft)' : 'var(--sunny-soft)',
          color: task.done ? 'var(--mint-700)' : 'var(--sunny-700)',
          padding: '5px 10px', borderRadius: 999, fontSize: 12, fontWeight: 900,
          display: 'inline-flex', alignItems: 'center', gap: 4,
        }}>+{task.xp} XP</div>
        <button onClick={onToggle} style={{
          width: 34, height: 34, borderRadius: '50%', border: `2px solid ${task.done ? task.color : 'var(--line-2)'}`,
          background: task.done ? task.color : 'var(--surface)', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {task.done && I.check(18, '#fff')}
        </button>
      </div>
    </div>
  );
}

function BadgeTile({ e, c, l, own }) {
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
      opacity: own ? 1 : 0.45,
    }}>
      <div style={{
        width: '100%', aspectRatio: '1', borderRadius: 22,
        background: own ? `linear-gradient(135deg, ${c}, color-mix(in oklab, ${c} 60%, white))` : 'var(--line)',
        boxShadow: own ? `inset 0 -10px 18px rgba(0,0,0,0.18), inset 0 8px 14px rgba(255,255,255,0.4), 0 8px 18px -8px ${c}` : 'inset 0 -4px 8px rgba(0,0,0,0.08)',
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 36,
        filter: own ? 'none' : 'grayscale(0.7)',
      }}>{e}</div>
      <div style={{ fontSize: 11, fontWeight: 800, color: 'var(--ink-950)', textAlign: 'center', lineHeight: 1.2 }}>{l}</div>
    </div>
  );
}

Object.assign(window, { CareScreen });
