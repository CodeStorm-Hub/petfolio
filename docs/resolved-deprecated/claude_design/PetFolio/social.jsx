// Social Feed — Instagram-style with Stories ring + Memorial variant.
// Design priorities:
//  • Stories ring uses gradient outline for living pets; muted sepia stroke + soft halo for memorials.
//  • Memorial posts: desaturated photo, ivory paper background, "Light a candle" instead of like,
//    "Tributes" instead of comments, no save/share/shop affordances — engagement is mournful, not viral.
//  • Fuzzy location only — never an address, always "Within N miles" buckets.

function SocialFeed({ active, onBack, onOpenSwitcher, onTab, outdoor }) {
  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      background: outdoor ? '#fff' : TOKENS.surface1,
      fontFamily: 'Inter, system-ui, sans-serif', color: TOKENS.ink950,
    }}>
      <SocialHeader active={active} onBack={onBack} onOpenSwitcher={onOpenSwitcher}/>
      <div style={{ flex: 1, overflow: 'auto', paddingBottom: 100 }}>
        <StoriesRow active={active}/>
        <Divider/>
        {FEED_POSTS.map((p, i) => (
          <FeedPost key={i} post={p}/>
        ))}
        <div style={{ padding: '32px 0 8px', textAlign: 'center', fontSize: 12, color: TOKENS.ink500 }}>
          You're all caught up · pull to refresh
        </div>
      </div>
      <TabBarSocial onTab={onTab}/>
    </div>
  );
}

function SocialHeader({ active, onBack, onOpenSwitcher }) {
  return (
    <div style={{ padding: '58px 16px 10px', display: 'flex', alignItems: 'center', gap: 12 }}>
      <button onClick={onBack} aria-label="Back" style={iconBtnStyle()}>
        <svg width="10" height="18" viewBox="0 0 10 18">
          <path d="M9 1L1 9l8 8" stroke={TOKENS.ink700} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </button>
      <div style={{ flex: 1, textAlign: 'center' }}>
        <div style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 19, letterSpacing: '-0.01em' }}>Pack</div>
        <div style={{ fontSize: 11, color: TOKENS.ink500, letterSpacing: '0.04em' }}>
          {active.name}'s circle · 142 friends
        </div>
      </div>
      <button aria-label="Direct messages" style={iconBtnStyle()}>
        <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
          <path d="M3 4h14v10H8l-4 3v-3H3V4z" stroke={TOKENS.ink700} strokeWidth="1.75" strokeLinejoin="round"/>
        </svg>
      </button>
    </div>
  );
}

function iconBtnStyle() {
  return {
    width: 40, height: 40, borderRadius: '50%', border: 'none', cursor: 'pointer',
    background: TOKENS.surface0, color: TOKENS.ink700,
    boxShadow: '0 1px 2px rgba(11,18,32,0.06), 0 0 0 0.5px ' + TOKENS.line200,
    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
  };
}

function Divider() {
  return <div style={{ height: 0.5, background: TOKENS.line200, margin: '12px 0 0' }}/>;
}

// ─── Stories ────────────────────────────────────────────────────
function StoriesRow({ active }) {
  const stories = [
    { id: 'me', name: 'Your story', pet: active, isYou: true, color: active.accent, viewed: false },
    ...STORIES,
  ];
  return (
    <div style={{ padding: '14px 0 8px', overflowX: 'auto' }}>
      <div style={{ display: 'flex', gap: 14, padding: '0 16px', width: 'max-content' }}>
        {stories.map((s, i) => <StoryItem key={i} s={s}/>)}
      </div>
    </div>
  );
}

function StoryItem({ s }) {
  const isMemorial = s.memorial;
  const memorialColor = '#9CA3AF';
  // ring style: gradient for live; muted sepia w/ halo for memorial; subtle grey for viewed
  let ringStyle;
  if (isMemorial) {
    ringStyle = {
      background: `radial-gradient(circle at 50% 50%, #F6E9D7 0%, #E7D9C2 60%, #C9B79A 100%)`,
      padding: 2.5,
    };
  } else if (s.isYou) {
    ringStyle = { background: TOKENS.line200, padding: 2.5 };
  } else if (s.viewed) {
    ringStyle = { background: TOKENS.line200, padding: 2.5 };
  } else {
    ringStyle = {
      background: `conic-gradient(from 200deg, ${s.color}, ${TOKENS.blue500}, ${TOKENS.mulberry}, ${s.color})`,
      padding: 2.5,
    };
  }
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, width: 68 }}>
      <div style={{ position: 'relative', borderRadius: '50%', ...ringStyle }}>
        <div style={{ background: '#fff', padding: 2, borderRadius: '50%' }}>
          <FakePhotoCircle pet={s.pet} size={56} sepia={isMemorial}/>
        </div>
        {s.isYou && (
          <div style={{
            position: 'absolute', bottom: -2, right: -2, width: 22, height: 22, borderRadius: '50%',
            background: TOKENS.blue500, color: '#fff', border: '2px solid #fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 16, fontWeight: 500, lineHeight: 1,
          }}>+</div>
        )}
        {isMemorial && (
          <div title="In memory of" style={{
            position: 'absolute', bottom: -2, right: -2, width: 20, height: 20, borderRadius: '50%',
            background: '#fff', border: '0.5px solid #E7D9C2',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 1px 2px rgba(0,0,0,0.06)',
          }}>
            <CandleGlyph size={10} color="#8A7B5C"/>
          </div>
        )}
      </div>
      <div style={{
        fontSize: 11, fontWeight: 500, textAlign: 'center', maxWidth: 64,
        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        color: isMemorial ? '#7A6D55' : TOKENS.ink700,
        fontStyle: isMemorial ? 'italic' : 'normal',
      }}>{s.label}</div>
    </div>
  );
}

// ─── Feed Post ──────────────────────────────────────────────────
function FeedPost({ post }) {
  if (post.memorial) return <MemorialPost post={post}/>;
  return <RegularPost post={post}/>;
}

function RegularPost({ post }) {
  const [liked, setLiked] = React.useState(post.liked);
  return (
    <article style={{ padding: '14px 0 6px', background: TOKENS.surface0, marginBottom: 8 }}>
      <PostHeader post={post}/>
      <PhotoSurface post={post}/>
      <div style={{ padding: '10px 16px 4px', display: 'flex', alignItems: 'center', gap: 16 }}>
        <ActionIcon active={liked} onClick={() => setLiked(!liked)}
                    activeColor={TOKENS.coral} label={liked ? 'Unlike' : 'Like'}>
          <svg width="26" height="26" viewBox="0 0 26 26" fill={liked ? TOKENS.coral : 'none'}
               stroke={liked ? TOKENS.coral : TOKENS.ink950} strokeWidth="1.75" strokeLinejoin="round" strokeLinecap="round">
            {/* Paw — likes are paws here, not hearts */}
            <ellipse cx="8" cy="11" rx="2.2" ry="2.8"/>
            <ellipse cx="13" cy="8" rx="2.2" ry="2.8"/>
            <ellipse cx="18" cy="11" rx="2.2" ry="2.8"/>
            <path d="M13 13c-3.2 0-5.5 2.2-5.5 4.5C7.5 19.4 9 20.5 13 20.5s5.5-1.1 5.5-3C18.5 15.2 16.2 13 13 13z"/>
          </svg>
        </ActionIcon>
        <ActionIcon label="Comment">
          <svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke={TOKENS.ink950} strokeWidth="1.75" strokeLinejoin="round" strokeLinecap="round">
            <path d="M4 12c0-4 3.5-7 9-7s9 3 9 7-3.5 7-9 7c-1.4 0-2.7-.2-3.9-.6L4 21l1.4-3.7C4.5 16 4 14 4 12z"/>
          </svg>
        </ActionIcon>
        <ActionIcon label="Share">
          <svg width="26" height="26" viewBox="0 0 26 26" fill="none" stroke={TOKENS.ink950} strokeWidth="1.75" strokeLinejoin="round" strokeLinecap="round">
            <path d="M4 12l18-8-7 18-3-7-8-3z"/>
          </svg>
        </ActionIcon>
        <div style={{ flex: 1 }}/>
        <ActionIcon label="Save">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke={TOKENS.ink950} strokeWidth="1.75" strokeLinejoin="round" strokeLinecap="round">
            <path d="M6 4h12v17l-6-4-6 4V4z"/>
          </svg>
        </ActionIcon>
      </div>
      <div style={{ padding: '4px 16px 8px', fontSize: 13, fontWeight: 600 }}>
        <span style={{ fontFamily: 'Sora' }}>{(post.likes + (liked && !post.liked ? 1 : 0) - (!liked && post.liked ? 1 : 0)).toLocaleString()}</span> paws
      </div>
      <div style={{ padding: '0 16px 4px', fontSize: 14, lineHeight: 1.4 }}>
        <span style={{ fontWeight: 700 }}>{post.handle}</span>
        <span style={{ color: TOKENS.ink700 }}> {post.caption}</span>
      </div>
      {post.firstComment && (
        <div style={{ padding: '4px 16px 0', fontSize: 13, color: TOKENS.ink500 }}>
          View all {post.comments} comments
        </div>
      )}
      <div style={{ padding: '4px 16px 4px', fontSize: 11, letterSpacing: '0.04em', color: TOKENS.ink500, textTransform: 'uppercase' }}>
        {post.when}
      </div>
    </article>
  );
}

function MemorialPost({ post }) {
  // Subdued: ivory paper, warm grey ink, sepia photo, no like/share/save — only "Light a candle"
  const paper = '#FAF6EE';
  const ink   = '#3F3829';
  const muted = '#7A6D55';
  const accent= '#A88B5C';
  const [lit, setLit] = React.useState(false);

  return (
    <article style={{
      margin: '12px 12px 14px', padding: '16px 0 12px',
      background: paper, borderRadius: 20,
      boxShadow: '0 0 0 0.5px #E7DEC9, 0 1px 2px rgba(80,60,20,0.04)',
      color: ink, fontFamily: 'Inter',
    }}>
      <div style={{
        padding: '0 16px 4px', display: 'flex', alignItems: 'center', gap: 6,
        fontSize: 10, fontWeight: 700, letterSpacing: '0.14em', textTransform: 'uppercase', color: muted,
      }}>
        <CandleGlyph size={11} color={muted}/>
        <span>In loving memory</span>
      </div>
      <div style={{ padding: '6px 16px 10px', display: 'flex', alignItems: 'center', gap: 11 }}>
        <div style={{
          padding: 2, borderRadius: '50%',
          background: `radial-gradient(circle, #F6E9D7 0%, #E7D9C2 60%, #C9B79A 100%)`,
        }}>
          <FakePhotoCircle pet={post.pet} size={42} sepia/>
        </div>
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 15 }}>{post.handle}</div>
          <div style={{ fontSize: 11, color: muted, marginTop: 2, display: 'flex', alignItems: 'center', gap: 6 }}>
            <span>{post.pet.breed}</span>
            <span style={{ color: '#D3C6A8' }}>·</span>
            <span style={{ fontVariantNumeric: 'tabular-nums' }}>{post.dates}</span>
          </div>
        </div>
      </div>
      <PhotoSurface post={post}/>
      <div style={{ padding: '12px 16px 4px', fontSize: 14, lineHeight: 1.55, fontStyle: 'italic', color: ink }}>
        “{post.caption}”
      </div>
      <div style={{ padding: '8px 16px 0', fontSize: 11, color: muted, letterSpacing: '0.04em', display: 'flex', alignItems: 'center', gap: 8 }}>
        <FuzzyPin color={muted}/>
        <span>Last home · {post.fuzzy}</span>
      </div>

      <div style={{ padding: '12px 16px 0', display: 'flex', alignItems: 'center', gap: 10 }}>
        <button onClick={() => setLit(!lit)} style={{
          height: 40, padding: '0 14px', borderRadius: 999, border: 'none', cursor: 'pointer',
          background: lit ? '#3F3829' : '#fff',
          color: lit ? '#FAF6EE' : ink,
          boxShadow: lit ? 'none' : '0 0 0 1px #E7DEC9',
          fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <CandleGlyph size={14} color={lit ? '#F5C56F' : accent} flame={lit}/>
          {lit ? 'Candle lit' : 'Light a candle'}
          <span style={{ fontVariantNumeric: 'tabular-nums', opacity: 0.8 }}>
            · {post.candles + (lit ? 1 : 0)}
          </span>
        </button>
        <button style={{
          height: 40, padding: '0 14px', borderRadius: 999, cursor: 'pointer',
          background: '#fff', color: ink, border: 'none',
          boxShadow: '0 0 0 1px #E7DEC9',
          fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
        }}>Leave a tribute</button>
      </div>

      <div style={{ padding: '14px 16px 0', fontSize: 12, color: muted, fontStyle: 'italic' }}>
        {post.tributes} tributes · sharing & saves are disabled out of respect
      </div>
    </article>
  );
}

function PostHeader({ post }) {
  return (
    <div style={{ padding: '0 16px 10px', display: 'flex', alignItems: 'center', gap: 11 }}>
      <div style={{
        padding: 2, borderRadius: '50%',
        background: `conic-gradient(from 200deg, ${post.pet.accent}, ${TOKENS.blue500}, ${TOKENS.mulberry})`,
      }}>
        <FakePhotoCircle pet={post.pet} size={36}/>
      </div>
      <div style={{ minWidth: 0, flex: 1 }}>
        <div style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 14 }}>{post.handle}</div>
        <div style={{ fontSize: 11, color: TOKENS.ink500, marginTop: 1, display: 'flex', alignItems: 'center', gap: 5 }}>
          <FuzzyPin/>
          <span>{post.fuzzy}</span>
          {post.tag && (<><span style={{ color: TOKENS.ink300 }}>·</span><span>{post.tag}</span></>)}
        </div>
      </div>
      <button aria-label="Post options" style={{ background: 'none', border: 'none', cursor: 'pointer', color: TOKENS.ink500, padding: 4 }}>
        <svg width="20" height="6" viewBox="0 0 20 6"><circle cx="3" cy="3" r="1.5" fill="currentColor"/><circle cx="10" cy="3" r="1.5" fill="currentColor"/><circle cx="17" cy="3" r="1.5" fill="currentColor"/></svg>
      </button>
    </div>
  );
}

function PhotoSurface({ post }) {
  const sepia = post.memorial;
  return (
    <div style={{
      position: 'relative', width: post.memorial ? 'calc(100% - 24px)' : '100%',
      margin: post.memorial ? '0 12px' : 0,
      aspectRatio: '1 / 1',
      borderRadius: post.memorial ? 14 : 0,
      overflow: 'hidden',
      background: post.gradient,
      filter: sepia ? 'saturate(0.55) sepia(0.15) brightness(0.96)' : 'none',
    }}>
      {/* Soft directional light */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'radial-gradient(circle at 30% 25%, rgba(255,255,255,0.35) 0%, transparent 55%)',
      }}/>
      {/* Big out-of-focus subject blob */}
      <div style={{
        position: 'absolute', left: '50%', top: '54%', transform: 'translate(-50%, -50%)',
        width: '46%', aspectRatio: '1 / 1', borderRadius: '50%',
        background: `radial-gradient(circle at 35% 30%, ${lighten(post.subjectColor, 0.25)}, ${post.subjectColor} 60%, ${darken(post.subjectColor, 0.18)} 100%)`,
        boxShadow: '0 18px 32px -10px rgba(0,0,0,0.35)',
      }}/>
      {/* Ear silhouettes */}
      {post.pet.species === 'dog' && (
        <>
          <div style={{
            position: 'absolute', left: '32%', top: '36%', width: '14%', aspectRatio: '1/1.4',
            background: darken(post.subjectColor, 0.2), borderRadius: '50% 50% 30% 30%',
            transform: 'rotate(-18deg)',
          }}/>
          <div style={{
            position: 'absolute', right: '32%', top: '36%', width: '14%', aspectRatio: '1/1.4',
            background: darken(post.subjectColor, 0.2), borderRadius: '50% 50% 30% 30%',
            transform: 'rotate(18deg)',
          }}/>
        </>
      )}
      {post.pet.species === 'cat' && (
        <>
          <div style={{
            position: 'absolute', left: '34%', top: '32%', width: '10%', aspectRatio: '1/1',
            background: darken(post.subjectColor, 0.25), clipPath: 'polygon(0 100%, 50% 0, 100% 100%)',
          }}/>
          <div style={{
            position: 'absolute', right: '34%', top: '32%', width: '10%', aspectRatio: '1/1',
            background: darken(post.subjectColor, 0.25), clipPath: 'polygon(0 100%, 50% 0, 100% 100%)',
          }}/>
        </>
      )}
      {/* Multi-photo dots */}
      {post.carousel && (
        <div style={{
          position: 'absolute', bottom: 12, left: '50%', transform: 'translateX(-50%)',
          display: 'flex', gap: 5,
        }}>
          {[0,1,2,3].map(i => (
            <div key={i} style={{
              width: 6, height: 6, borderRadius: '50%',
              background: i === 0 ? '#fff' : 'rgba(255,255,255,0.55)',
            }}/>
          ))}
        </div>
      )}
    </div>
  );
}

function ActionIcon({ children, onClick, label }) {
  return (
    <button onClick={onClick} aria-label={label} style={{
      background: 'transparent', border: 'none', cursor: 'pointer', padding: 4,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>{children}</button>
  );
}

function FakePhotoCircle({ pet, size = 40, sepia = false }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%', position: 'relative', overflow: 'hidden',
      background: `radial-gradient(circle at 30% 25%, ${lighten(pet.accent, 0.32)}, ${pet.accent} 60%, ${darken(pet.accent, 0.18)} 100%)`,
      filter: sepia ? 'saturate(0.45) sepia(0.2) brightness(0.96)' : 'none',
      flexShrink: 0,
    }}>
      <div style={{
        position: 'absolute', left: '50%', top: '60%', transform: 'translate(-50%, -50%)',
        width: '60%', aspectRatio: '1/1', borderRadius: '50%',
        background: darken(pet.accent, 0.1),
      }}/>
    </div>
  );
}

function FuzzyPin({ color }) {
  const c = color || TOKENS.ink500;
  return (
    <svg width="11" height="13" viewBox="0 0 11 13" fill="none">
      <path d="M5.5 12s4.5-4.6 4.5-7.5a4.5 4.5 0 10-9 0C1 7.4 5.5 12 5.5 12z" stroke={c} strokeWidth="1.3"/>
      <circle cx="5.5" cy="4.5" r="1.4" fill={c}/>
    </svg>
  );
}

function CandleGlyph({ size = 14, color = '#8A7B5C', flame = false }) {
  return (
    <svg width={size} height={size} viewBox="0 0 14 14" fill="none">
      {flame && (
        <path d="M7 1.5c1.5 1.5 2 2.6 2 3.7 0 1.1-.9 2-2 2s-2-.9-2-2c0-1.1.5-2.2 2-3.7z" fill="#F5C56F"/>
      )}
      {!flame && <path d="M7 2v3" stroke={color} strokeWidth="1.4" strokeLinecap="round"/>}
      <rect x="4.5" y="5.5" width="5" height="7" rx="1" stroke={color} strokeWidth="1.3" fill={flame ? 'rgba(168,139,92,0.15)' : 'none'}/>
    </svg>
  );
}

// ─── Tab bar (Social active) ────────────────────────────────────
function TabBarSocial({ onTab }) {
  return <SharedTabBar active="feed" onTab={onTab}/>;
}

function SharedTabBar({ active, onTab }) {
  const tabs = [
    { id: 'home', label: 'Home', icon: (c) => <path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-5v-7h-6v7H4a1 1 0 01-1-1V11z" stroke={c} strokeWidth="1.75" strokeLinejoin="round" fill="none"/> },
    { id: 'feed', label: 'Social', icon: (c) => <><circle cx="12" cy="12" r="9" stroke={c} strokeWidth="1.75" fill="none"/><circle cx="12" cy="9" r="2.5" stroke={c} strokeWidth="1.75" fill="none"/><path d="M6 18c1-3 3-4 6-4s5 1 6 4" stroke={c} strokeWidth="1.75" fill="none"/></> },
    { id: 'match', label: 'Match', icon: (c) => <path d="M12 21s-8-5-8-11a5 5 0 019-3 5 5 0 019 3c0 6-8 11-8 11z" stroke={c} strokeWidth="1.75" fill="none" strokeLinejoin="round"/> },
    { id: 'health', label: 'Health', icon: (c) => <path d="M4 12l3 6 5-13 4 8h4" stroke={c} strokeWidth="1.75" fill="none" strokeLinejoin="round"/> },
    { id: 'shop', label: 'Shop', icon: (c) => <path d="M5 7h14l-1.5 12a2 2 0 01-2 1.7h-7a2 2 0 01-2-1.7L5 7zM9 7V5a3 3 0 016 0v2" stroke={c} strokeWidth="1.75" fill="none" strokeLinejoin="round"/> },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0, paddingBottom: 26,
      background: 'linear-gradient(180deg, rgba(250,251,253,0) 0%, rgba(250,251,253,0.92) 40%, ' + TOKENS.surface1 + ' 100%)',
    }}>
      <div style={{
        margin: '0 12px', height: 64, borderRadius: 24, background: TOKENS.surface0,
        boxShadow: '0 0 0 0.5px ' + TOKENS.line200 + ', 0 12px 28px -10px rgba(11,18,32,0.14)',
        display: 'flex', alignItems: 'center', padding: '0 4px',
      }}>
        {tabs.map(t => {
          const a = t.id === active;
          const c = a ? TOKENS.blue500 : TOKENS.ink500;
          return (
            <button key={t.id} onClick={() => onTab && onTab(t.id)} aria-label={t.label} style={{
              flex: 1, height: '100%', border: 'none', background: 'transparent', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2, padding: '8px 0',
            }}>
              <svg width="24" height="24" viewBox="0 0 24 24">{t.icon(c)}</svg>
              <span style={{ fontSize: 10, fontWeight: 600, color: c }}>{t.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// ─── Data ───────────────────────────────────────────────────────
const STORIES = [
  { label: 'Buddy',  pet: { name: 'Buddy',  accent: TOKENS.coral,    species: 'dog' }, color: TOKENS.coral,    viewed: false, memorial: false },
  { label: 'Mia',    pet: { name: 'Mia',    accent: TOKENS.sunset,   species: 'cat' }, memorial: true },
  { label: 'Pixel',  pet: { name: 'Pixel',  accent: TOKENS.coral,    species: 'dog' }, color: TOKENS.coral,    viewed: false },
  { label: 'Bean',   pet: { name: 'Bean',   accent: TOKENS.meadow,   species: 'rabbit' }, color: TOKENS.meadow, viewed: false },
  { label: 'Olive',  pet: { name: 'Olive',  accent: TOKENS.sunset,   species: 'cat' }, color: TOKENS.sunset,   viewed: true },
  { label: 'Rex',    pet: { name: 'Rex',    accent: TOKENS.apricot,  species: 'dog' }, color: TOKENS.apricot,  viewed: false },
  { label: 'Theo',   pet: { name: 'Theo',   accent: TOKENS.mulberry, species: 'cat' }, memorial: true },
  { label: 'Daisy',  pet: { name: 'Daisy',  accent: TOKENS.coral,    species: 'dog' }, color: TOKENS.coral,    viewed: true },
];

const FEED_POSTS = [
  {
    handle: 'buddy.the.collie',
    pet: { name: 'Buddy', breed: 'Border Collie', species: 'dog', accent: TOKENS.coral },
    fuzzy: 'Within 1 mile · Highbury',
    tag: 'Sunday cove',
    gradient: 'linear-gradient(135deg, #F4B57A 0%, #E89669 50%, #C46A4F 100%)',
    subjectColor: '#6B3F2A',
    caption: 'first dip of the season — would not come out of the water for thirty minutes 🌊',
    likes: 1284, comments: 41, when: '2 hours ago', liked: false, firstComment: true,
  },
  {
    memorial: true,
    handle: "mia's_garden",
    pet: { name: 'Mia', breed: 'Maine Coon', species: 'cat', accent: TOKENS.sunset },
    dates: '2009 — 2024',
    fuzzy: 'Within 5 miles',
    gradient: 'linear-gradient(135deg, #E8D5B5 0%, #C9B796 50%, #A8946F 100%)',
    subjectColor: '#8B6F4D',
    caption: 'One year today. The patch of sunlight on the kitchen floor is still warm at 4 pm — I think she taught it to wait for me.',
    candles: 384, tributes: 92,
  },
  {
    handle: 'rex.does.agility',
    pet: { name: 'Rex', breed: 'Aussie Shepherd', species: 'dog', accent: TOKENS.apricot },
    fuzzy: 'Within 2 miles · Hackney',
    tag: 'agility class',
    gradient: 'linear-gradient(135deg, #9BB59A 0%, #6E8E72 50%, #485F4F 100%)',
    subjectColor: '#5C4633',
    carousel: true,
    caption: 'first clean weave run! 12 poles, no faults, very large smile 🐾',
    likes: 612, comments: 18, when: '5 hours ago', liked: true, firstComment: true,
  },
];

Object.assign(window, { SocialFeed, SharedTabBar });
