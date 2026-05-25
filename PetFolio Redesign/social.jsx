// social.jsx — Social feed with reaction bursts

const DEMO_POSTS = [
  {
    id: 'p1', user: 'Tommy', species: 'dog', when: '2h', loc: 'Riverside Park',
    text: 'Found my new favorite stick. Will not be sharing. 🌳',
    photo: { color: 'var(--mint)', soft: 'var(--mint-soft)', emoji: '🌲' },
    likes: 142, comments: 24, reaction: 'paw',
  },
  {
    id: 'p2', user: 'Goldy', species: 'fish', when: '5h', loc: 'Kitchen Tank',
    text: 'New plant came today. 10/10 would nibble again. Thanks @PetfolioMarket 💚',
    photo: { color: 'var(--sky)', soft: 'var(--sky-soft)', emoji: '🪴' },
    likes: 38, comments: 6, reaction: 'heart',
  },
  {
    id: 'p3', user: 'Rex', species: 'reptile', when: '1d', loc: 'Sun Rock',
    text: 'POV: you are warm.',
    photo: { color: 'var(--sunny)', soft: 'var(--sunny-soft)', emoji: '☀️' },
    likes: 211, comments: 41, reaction: 'star',
  },
];

const REACTION_KINDS = [
  { id: 'paw',   emoji: '🐾', color: 'var(--tangerine)' },
  { id: 'heart', emoji: '❤️', color: 'var(--poppy)' },
  { id: 'treat', emoji: '🦴', color: 'var(--sunny)' },
  { id: 'star',  emoji: '⭐', color: 'var(--lilac)' },
];

function SocialScreen({ navigate, motif }) {
  const [bursts, setBursts] = React.useState({}); // postId -> array of {id,x,y,kind}
  const [reacted, setReacted] = React.useState({});
  const [pickerOpen, setPickerOpen] = React.useState(null);

  function fireBurst(postId, kind, x, y) {
    const count = 8 + Math.floor(Math.random() * 4);
    const items = Array.from({ length: count }).map((_, i) => ({
      id: Date.now() + i, x: x + (Math.random()-0.5)*40, y, kind,
    }));
    setBursts(b => ({ ...b, [postId]: [...(b[postId] || []), ...items] }));
    setTimeout(() => {
      setBursts(b => {
        const cur = b[postId] || [];
        const ids = items.map(i => i.id);
        return { ...b, [postId]: cur.filter(c => !ids.includes(c.id)) };
      });
    }, 1100);
    setReacted(r => ({ ...r, [postId]: kind }));
    setPickerOpen(null);
  }

  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 100, background: 'var(--cream)' }}>
      {/* Sticky header */}
      <div style={{
        position: 'sticky', top: 0, zIndex: 10,
        background: 'var(--cream)',
        padding: '14px 18px 10px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        boxShadow: '0 8px 8px -8px rgba(120,60,20,0.10)',
      }}>
        <div>
          <h1 className="display" style={{ fontSize: 28, color: 'var(--ink-950)' }}>Pawsfeed</h1>
          <div style={{ fontSize: 12, color: 'var(--ink-500)', fontWeight: 700 }}>Your pack · 124 new posts today</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <IconBtn>{I.search(20)}</IconBtn>
          <IconBtn bg="var(--tangerine)" color="#fff">{I.send(20, '#fff')}</IconBtn>
        </div>
      </div>

      {/* Story bar */}
      <div style={{ display: 'flex', gap: 12, overflowX: 'auto', padding: '8px 18px 12px' }}>
        <StoryAdd/>
        {DEMO_PETS.slice(0,5).map(p => (
          <div key={p.id} style={{ flex: '0 0 auto', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
            <PetAvatar species={p.species} size={62} ring/>
            <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--ink-950)' }}>{p.name}</div>
          </div>
        ))}
      </div>

      {/* Posts */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18, padding: '0 14px' }}>
        {DEMO_POSTS.map(post => (
          <PostCard
            key={post.id}
            post={post}
            bursts={bursts[post.id]}
            picker={pickerOpen === post.id}
            reacted={reacted[post.id]}
            onOpenPicker={() => setPickerOpen(o => o === post.id ? null : post.id)}
            onFire={(kind, x, y) => fireBurst(post.id, kind, x, y)}
          />
        ))}
        <div style={{ textAlign: 'center', padding: '16px 0', color: 'var(--ink-500)', fontSize: 13, fontWeight: 700 }}>You're all caught up 🐾</div>
      </div>
    </div>
  );
}

function StoryAdd() {
  return (
    <div style={{ flex: '0 0 auto', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
      <div style={{
        width: 62, height: 62, borderRadius: '50%',
        background: 'var(--surface)', border: '2px dashed var(--tangerine)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative',
      }}>
        <div style={{ position: 'absolute', right: -2, bottom: -2, width: 24, height: 24, borderRadius: '50%', background: 'var(--tangerine)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px solid var(--cream)' }}>
          {I.plus(14, '#fff')}
        </div>
        <span style={{ fontSize: 26 }}>📸</span>
      </div>
      <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--ink-950)' }}>Your story</div>
    </div>
  );
}

function PostCard({ post, bursts, picker, reacted, onOpenPicker, onFire }) {
  const sp = SPECIES.find(s => s.id === post.species) || SPECIES[0];
  const reactionRef = React.useRef(null);

  function handleReact(kind, e) {
    const rect = reactionRef.current?.getBoundingClientRect();
    const parentRect = reactionRef.current?.offsetParent?.getBoundingClientRect();
    const x = rect ? rect.left - (parentRect?.left || 0) + rect.width/2 : 0;
    const y = rect ? rect.top - (parentRect?.top || 0) + 8 : 0;
    onFire(kind, x, y);
  }

  function quickReact(e) {
    if (reacted) return;
    handleReact('paw');
  }

  const totalLikes = post.likes + (reacted ? 1 : 0);

  return (
    <Card pad={0} style={{ overflow: 'visible', position: 'relative' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px 10px' }}>
        <PetAvatar species={post.species} size={44} ring/>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 15, fontWeight: 800, color: 'var(--ink-950)' }}>{post.user}</div>
          <div style={{ fontSize: 11, color: 'var(--ink-500)', display: 'flex', alignItems: 'center', gap: 4, fontWeight: 600 }}>
            {I.location(11, 'var(--ink-500)')} {post.loc} · {post.when}
          </div>
        </div>
        <IconBtn size={36} bg="var(--cream-2)" shadow={false}><div style={{ fontSize: 18, fontWeight: 900 }}>···</div></IconBtn>
      </div>

      {/* Photo */}
      <div style={{ padding: '0 14px 12px' }}>
        <PlaceholderImg
          label={post.text.slice(0,20)}
          color={post.photo.color}
          soft={post.photo.soft}
          emoji={post.photo.emoji}
          height={260}
          r={22}
        />
      </div>

      {/* Text */}
      <div style={{ padding: '0 16px 12px', fontSize: 14, color: 'var(--ink-950)', fontWeight: 600, lineHeight: 1.45 }}>{post.text}</div>

      {/* Reaction stack visualizer */}
      <div style={{ padding: '0 16px 8px', display: 'flex', alignItems: 'center', gap: 6 }}>
        <div style={{ display: 'flex' }}>
          {['🐾','❤️','🦴'].map((e,i) => (
            <div key={i} style={{
              width: 24, height: 24, borderRadius: '50%',
              background: ['var(--tangerine)','var(--poppy)','var(--sunny)'][i],
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 12, marginLeft: i === 0 ? 0 : -6,
              border: '2px solid var(--surface)',
            }}>{e}</div>
          ))}
        </div>
        <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--ink-700)' }}>
          <b>{totalLikes}</b> reacted · {post.comments} comments
        </div>
      </div>

      {/* Actions */}
      <div style={{
        borderTop: '1px solid var(--line)',
        padding: '8px 8px', display: 'flex', alignItems: 'center', justifyContent: 'space-around',
        position: 'relative',
      }}>
        <ReactionButton
          refEl={reactionRef}
          reacted={reacted}
          onClick={quickReact}
          onLongPress={onOpenPicker}
        />
        <ActionBtn icon={I.comment(20)} label="Comment"/>
        <ActionBtn icon={I.share(20)} label="Share"/>
        <ActionBtn icon={I.bookmark(20)} label="Save"/>

        {/* Reaction picker */}
        {picker && (
          <div style={{
            position: 'absolute', bottom: 52, left: 12,
            display: 'flex', gap: 6, padding: 6,
            background: 'var(--surface)', borderRadius: 999,
            boxShadow: '0 16px 32px -10px rgba(120,60,20,0.3), 0 0 0 1px var(--line)',
            animation: 'pf-pop-in 240ms cubic-bezier(.3,1.7,.4,1)',
            zIndex: 5,
          }}>
            {REACTION_KINDS.map(r => (
              <button key={r.id} onClick={() => handleReact(r.id)} style={{
                width: 42, height: 42, borderRadius: '50%', border: 'none', cursor: 'pointer',
                background: 'var(--cream-2)', fontSize: 24,
                transition: 'transform 150ms cubic-bezier(.5,1.7,.5,1)',
                fontFamily: 'inherit',
              }}
                onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.18)'}
                onMouseLeave={e => e.currentTarget.style.transform = 'scale(1)'}
              >{r.emoji}</button>
            ))}
          </div>
        )}

        {/* Bursts */}
        {bursts && bursts.length > 0 && <ReactionBurst items={bursts}/>}
      </div>
    </Card>
  );
}

function ReactionButton({ reacted, onClick, onLongPress, refEl }) {
  const timer = React.useRef(null);
  function down() {
    timer.current = setTimeout(() => { onLongPress(); timer.current = null; }, 280);
  }
  function up(e) {
    if (timer.current) {
      clearTimeout(timer.current);
      timer.current = null;
      onClick(e);
    }
  }
  const r = REACTION_KINDS.find(x => x.id === reacted);
  return (
    <button ref={refEl} onPointerDown={down} onPointerUp={up} onPointerLeave={() => { if (timer.current) { clearTimeout(timer.current); timer.current = null; } }} style={{
      flex: 1, height: 44, border: 'none', background: 'transparent', cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
      borderRadius: 14, color: r ? r.color : 'var(--ink-700)',
      fontWeight: 800, fontSize: 13,
      fontFamily: 'inherit',
    }}>
      {r ? <span style={{ fontSize: 20 }}>{r.emoji}</span> : I.pawOutline(20)}
      <span>{r ? r.id[0].toUpperCase() + r.id.slice(1) : 'React'}</span>
    </button>
  );
}

function ActionBtn({ icon, label }) {
  return (
    <button style={{
      flex: 1, height: 44, border: 'none', background: 'transparent', cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
      borderRadius: 14, color: 'var(--ink-700)',
      fontWeight: 800, fontSize: 13,
      fontFamily: 'inherit',
    }}>
      {icon} <span>{label}</span>
    </button>
  );
}

Object.assign(window, { SocialScreen });
