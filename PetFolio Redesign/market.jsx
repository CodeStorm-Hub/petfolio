// market.jsx — Marketplace + Product detail + Cart drawer

const DEMO_PRODUCTS = [
  { id: 'pr1', name: 'Salmon Crunchies', sub: 'Treat · 200g', price: 12.50, vendor: 'WoofKitchen', emoji: '🦴', color: 'var(--tangerine)', soft: 'var(--tangerine-soft)', rating: 4.9 },
  { id: 'pr2', name: 'Floofy Bed', sub: 'Medium', price: 48.00, vendor: 'CloudPet', emoji: '🛏️', color: 'var(--poppy)', soft: 'var(--poppy-soft)', rating: 4.8 },
  { id: 'pr3', name: 'Bouncy Ball', sub: '6-pack', price: 7.20, vendor: 'PawPlay', emoji: '🎾', color: 'var(--mint)', soft: 'var(--mint-soft)', rating: 4.7 },
  { id: 'pr4', name: 'Catnip Mouse', sub: 'Set of 3', price: 9.90, vendor: 'PurrLab', emoji: '🐭', color: 'var(--lilac)', soft: 'var(--lilac-soft)', rating: 4.6 },
  { id: 'pr5', name: 'Wet Food Pack', sub: '12 × 85g', price: 24.00, vendor: 'WoofKitchen', emoji: '🥫', color: 'var(--sunny)', soft: 'var(--sunny-soft)', rating: 4.9 },
  { id: 'pr6', name: 'Cozy Sweater', sub: 'Sz S', price: 18.00, vendor: 'YarnPaws', emoji: '🧶', color: 'var(--sky)', soft: 'var(--sky-soft)', rating: 4.8 },
];

const CATEGORIES = [
  { id: 'food',  label: 'Food',     emoji: '🍖', color: 'var(--tangerine)' },
  { id: 'treats',label: 'Treats',   emoji: '🦴', color: 'var(--sunny)' },
  { id: 'toys',  label: 'Toys',     emoji: '🎾', color: 'var(--mint)' },
  { id: 'beds',  label: 'Beds',     emoji: '🛏️', color: 'var(--poppy)' },
  { id: 'apparel',label: 'Apparel', emoji: '🧶', color: 'var(--lilac)' },
  { id: 'care',  label: 'Grooming', emoji: '🛁', color: 'var(--sky)' },
];

function MarketScreen({ navigate, motif }) {
  const [view, setView] = React.useState({ kind: 'home' });
  const [cart, setCart] = React.useState([
    { id: 'pr3', qty: 1 },
  ]);
  const [drawer, setDrawer] = React.useState(false);
  const [flying, setFlying] = React.useState(null);

  function addToCart(product, fromRect) {
    const existing = cart.find(c => c.id === product.id);
    if (existing) {
      setCart(c => c.map(x => x.id === product.id ? { ...x, qty: x.qty + 1 } : x));
    } else {
      setCart(c => [...c, { id: product.id, qty: 1 }]);
    }
    if (fromRect) {
      setFlying({ rect: fromRect, product, id: Date.now() });
      setTimeout(() => setFlying(null), 850);
    }
  }

  const cartCount = cart.reduce((s, c) => s + c.qty, 0);
  const cartItems = cart.map(c => ({ ...DEMO_PRODUCTS.find(p => p.id === c.id), qty: c.qty }));
  const subtotal = cartItems.reduce((s, c) => s + c.price * c.qty, 0);

  return (
    <div style={{ height: '100%', overflow: 'hidden', position: 'relative', background: 'var(--cream)' }}>
      {view.kind === 'home' && <MarketHome
        navigate={navigate}
        onCart={() => setDrawer(true)}
        cartCount={cartCount}
        onProduct={(p) => setView({ kind: 'product', product: p })}
        onAdd={addToCart}
      />}
      {view.kind === 'product' && <ProductDetail
        product={view.product}
        onBack={() => setView({ kind: 'home' })}
        onCart={() => setDrawer(true)}
        onAdd={addToCart}
        cartCount={cartCount}
      />}

      {/* Cart drawer */}
      <CartDrawer
        open={drawer}
        onClose={() => setDrawer(false)}
        items={cartItems}
        subtotal={subtotal}
        onQty={(id, q) => setCart(c => q === 0 ? c.filter(x => x.id !== id) : c.map(x => x.id === id ? { ...x, qty: q } : x))}
      />

      {/* Flying-to-cart pellet */}
      {flying && <FlyToCart from={flying.rect} product={flying.product}/>}
    </div>
  );
}

function FlyToCart({ from, product }) {
  // animate from rect to top-right cart icon (approx top 22, right 22)
  return (
    <div style={{
      position: 'absolute', left: from.x - 24, top: from.y - 24, zIndex: 100, pointerEvents: 'none',
      animation: 'pf-fly-to-cart 800ms cubic-bezier(.5,-0.2,.8,.3) forwards',
    }}>
      <style>{`
        @keyframes pf-fly-to-cart {
          0% { transform: translate(0,0) scale(1); opacity: 1; }
          70% { opacity: 1; }
          100% { transform: translate(calc(380px - ${from.x}px), calc(70px - ${from.y}px)) scale(0.2); opacity: 0; }
        }
      `}</style>
      <div style={{
        width: 48, height: 48, borderRadius: 16,
        background: product.color, display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 26, boxShadow: '0 12px 24px -8px ' + product.color,
      }}>{product.emoji}</div>
    </div>
  );
}

// ─── Marketplace Home ──────────────────────────────────────
function MarketHome({ navigate, onCart, cartCount, onProduct, onAdd }) {
  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 100 }}>
      {/* Header */}
      <div style={{
        background: 'linear-gradient(180deg, var(--sunny-soft), var(--cream))',
        padding: '14px 18px 18px', position: 'relative',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <div>
            <div style={{ fontSize: 11, color: 'var(--ink-500)', fontWeight: 800, letterSpacing: 0.6 }}>SHIP TO MOCHI'S HOUSE</div>
            <div style={{ fontSize: 16, fontWeight: 800, color: 'var(--ink-950)', display: 'flex', alignItems: 'center', gap: 4 }}>
              {I.location(16, 'var(--tangerine)')} Brooklyn, NY {I.chevronDown(14)}
            </div>
          </div>
          <button onClick={onCart} style={{
            position: 'relative', width: 44, height: 44, borderRadius: '50%',
            background: 'var(--tangerine)', border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 6px 0 0 var(--tangerine-700)',
          }}>
            {I.cart(20, '#fff')}
            {cartCount > 0 && (
              <span style={{
                position: 'absolute', top: -4, right: -4,
                background: 'var(--poppy)', color: '#fff',
                borderRadius: '50%', width: 22, height: 22,
                fontSize: 11, fontWeight: 900, display: 'flex',
                alignItems: 'center', justifyContent: 'center',
                border: '2px solid var(--cream)',
              }}>{cartCount}</span>
            )}
          </button>
        </div>

        {/* Search */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          background: 'var(--surface)', borderRadius: 999, padding: '12px 16px',
          border: '1.5px solid var(--line-2)', boxShadow: 'var(--shadow-soft)',
        }}>
          {I.search(20, 'var(--ink-500)')}
          <input placeholder="Search treats, beds, toys…" style={{
            flex: 1, border: 'none', outline: 'none', fontSize: 14, fontWeight: 600,
            color: 'var(--ink-950)', background: 'transparent', fontFamily: 'inherit',
          }}/>
        </div>
      </div>

      {/* Categories */}
      <div style={{ padding: '14px 0 6px' }}>
        <div style={{ display: 'flex', gap: 12, overflowX: 'auto', padding: '4px 16px' }}>
          {CATEGORIES.map(c => (
            <div key={c.id} style={{ flex: '0 0 auto', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <div style={{
                width: 64, height: 64, borderRadius: 22,
                background: `color-mix(in oklab, ${c.color} 18%, var(--surface))`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 30,
                boxShadow: 'var(--shadow-soft)',
                border: '1.5px solid var(--line)',
              }}>{c.emoji}</div>
              <div style={{ fontSize: 11, fontWeight: 800, color: 'var(--ink-950)' }}>{c.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Hero banner */}
      <div style={{ padding: '8px 16px 8px' }}>
        <div style={{
          background: `linear-gradient(135deg, var(--poppy), var(--tangerine))`,
          borderRadius: 28, padding: '18px 18px', color: '#fff',
          display: 'flex', alignItems: 'center', gap: 10,
          boxShadow: '0 14px 30px -12px var(--poppy)',
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, fontWeight: 800, opacity: 0.85, letterSpacing: 0.5 }}>FOR MEMBERS</div>
            <div className="display" style={{ fontSize: 24, lineHeight: 1.1, marginTop: 4 }}>20% off treats<br/>this week 🦴</div>
            <Pill size="sm" variant="primary" color="var(--surface)" style={{ color: 'var(--poppy-700)', marginTop: 12 }}>Claim</Pill>
          </div>
          <div style={{ fontSize: 96, transform: 'rotate(-12deg)', filter: 'drop-shadow(0 8px 16px rgba(0,0,0,0.2))' }}>🦴</div>
          <div style={{ position: 'absolute', right: -20, top: -20, fontSize: 50, opacity: 0.18 }}>🐾</div>
        </div>
      </div>

      {/* Trending */}
      <div style={{ padding: '12px 16px 0' }}>
        <SectionTitle accent="var(--tangerine)" right={<span style={{ fontSize: 12, color: 'var(--ink-500)', fontWeight: 700 }}>40+ items</span>}>
          Trending in your pack
        </SectionTitle>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          {DEMO_PRODUCTS.map(p => (
            <ProductTile key={p.id} product={p} onTap={() => onProduct(p)} onAdd={onAdd}/>
          ))}
        </div>
      </div>
    </div>
  );
}

function ProductTile({ product, onTap, onAdd }) {
  const btnRef = React.useRef(null);
  const [popping, setPopping] = React.useState(false);

  function handleAdd(e) {
    e.stopPropagation();
    const rect = btnRef.current?.getBoundingClientRect();
    const parentRect = btnRef.current?.offsetParent?.getBoundingClientRect();
    if (rect && parentRect) {
      onAdd(product, { x: rect.left - parentRect.left + rect.width/2, y: rect.top - parentRect.top + rect.height/2 });
    }
    setPopping(true);
    setTimeout(() => setPopping(false), 400);
  }

  return (
    <div onClick={onTap} style={{
      background: 'var(--surface)', borderRadius: 24, overflow: 'hidden',
      border: '1px solid var(--line)', cursor: 'pointer',
      boxShadow: 'var(--shadow-soft)',
    }}>
      <div style={{
        height: 130, position: 'relative',
        background: `linear-gradient(135deg, ${product.soft}, color-mix(in oklab, ${product.color} 50%, white))`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{ fontSize: 60, filter: 'drop-shadow(0 6px 12px rgba(0,0,0,0.15))', transform: popping ? 'scale(1.2) rotate(-8deg)' : 'scale(1)', transition: 'transform 280ms cubic-bezier(.3,1.7,.4,1)' }}>{product.emoji}</div>
        <div style={{
          position: 'absolute', top: 8, left: 8,
          background: 'var(--surface)', borderRadius: 999, padding: '4px 8px',
          fontSize: 11, fontWeight: 800, color: 'var(--ink-950)',
          display: 'flex', alignItems: 'center', gap: 3,
        }}>{I.star(12)} {product.rating}</div>
      </div>
      <div style={{ padding: '12px 12px 12px', display: 'flex', flexDirection: 'column', gap: 4 }}>
        <div style={{ fontSize: 14, fontWeight: 800, color: 'var(--ink-950)', lineHeight: 1.2 }}>{product.name}</div>
        <div style={{ fontSize: 11, color: 'var(--ink-500)', fontWeight: 700 }}>{product.sub}</div>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 6 }}>
          <span className="display" style={{ fontSize: 18, color: 'var(--ink-950)' }}>${product.price.toFixed(2)}</span>
          <button ref={btnRef} onClick={handleAdd} style={{
            width: 36, height: 36, borderRadius: '50%', border: 'none', cursor: 'pointer',
            background: product.color, color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 4px 0 0 color-mix(in oklab, ${product.color} 50%, black)`,
            transform: popping ? 'scale(1.15)' : 'scale(1)', transition: 'transform 280ms cubic-bezier(.5,1.7,.5,1)',
          }}>{I.plus(20, '#fff')}</button>
        </div>
      </div>
    </div>
  );
}

// ─── Product Detail ────────────────────────────────────────
function ProductDetail({ product, onBack, onCart, onAdd, cartCount }) {
  const [qty, setQty] = React.useState(1);
  const [popping, setPopping] = React.useState(false);
  const heroRef = React.useRef(null);

  function handleAdd() {
    const rect = heroRef.current?.getBoundingClientRect();
    const parentRect = heroRef.current?.offsetParent?.getBoundingClientRect();
    for (let i = 0; i < qty; i++) {
      setTimeout(() => onAdd(product, rect && parentRect ? { x: rect.left - parentRect.left + rect.width/2, y: rect.top - parentRect.top + 70 } : null), i * 90);
    }
    setPopping(true);
    setTimeout(() => setPopping(false), 600);
  }

  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 120, background: 'var(--cream)' }}>
      {/* Big photo */}
      <div ref={heroRef} style={{
        position: 'relative', height: 320,
        background: `linear-gradient(135deg, ${product.soft}, ${product.color})`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{ position: 'absolute', top: 14, left: 14, right: 14, display: 'flex', justifyContent: 'space-between' }}>
          <IconBtn onClick={onBack} bg="rgba(255,255,255,0.92)">{I.back(22)}</IconBtn>
          <div style={{ display: 'flex', gap: 8 }}>
            <IconBtn bg="rgba(255,255,255,0.92)">{I.bookmark(20)}</IconBtn>
            <button onClick={onCart} style={{
              position: 'relative', width: 44, height: 44, borderRadius: '50%',
              background: 'rgba(255,255,255,0.92)', border: 'none', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: 'var(--shadow-soft)',
            }}>
              {I.cart(20)}
              {cartCount > 0 && <span style={{ position: 'absolute', top: -2, right: -2, background: 'var(--poppy)', color: '#fff', borderRadius: '50%', width: 20, height: 20, fontSize: 11, fontWeight: 900, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{cartCount}</span>}
            </button>
          </div>
        </div>
        <div style={{ fontSize: 180, filter: 'drop-shadow(0 14px 30px rgba(0,0,0,0.2))', transform: popping ? 'scale(1.18) rotate(-8deg)' : 'scale(1)', transition: 'transform 400ms cubic-bezier(.3,1.7,.4,1)' }}>{product.emoji}</div>

        {/* Wave bottom */}
        <svg viewBox="0 0 412 60" preserveAspectRatio="none" style={{ position: 'absolute', bottom: -1, left: 0, width: '100%', height: 40, display: 'block' }}>
          <path d="M0,40 C90,10 160,70 220,40 C280,15 340,60 412,30 L412,60 L0,60 Z" fill="var(--cream)"/>
        </svg>
      </div>

      {/* Info */}
      <div style={{ padding: '12px 18px 0' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
          <span style={{ background: 'var(--sunny-soft)', color: 'var(--sunny-700)', fontSize: 11, fontWeight: 800, padding: '4px 10px', borderRadius: 999, display: 'inline-flex', gap: 4, alignItems: 'center' }}>{I.star(12)} {product.rating} · 421 reviews</span>
          <span style={{ background: 'var(--mint-soft)', color: 'var(--mint-700)', fontSize: 11, fontWeight: 800, padding: '4px 10px', borderRadius: 999 }}>Free delivery</span>
        </div>
        <h1 className="display" style={{ fontSize: 30, lineHeight: 1.1, color: 'var(--ink-950)' }}>{product.name}</h1>
        <div style={{ fontSize: 13, color: 'var(--ink-500)', fontWeight: 700, marginTop: 4 }}>by <b style={{ color: 'var(--tangerine-700)' }}>{product.vendor}</b> · {product.sub}</div>

        <p style={{ fontSize: 14, color: 'var(--ink-700)', lineHeight: 1.5, marginTop: 14, fontWeight: 500 }}>
          Crispy little bites baked with fresh salmon and a dusting of parsley. Single-protein, grain-free, and the very official taste-tester (Mochi) gives a 9.6/10.
        </p>

        {/* Highlights */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 18 }}>
          {[
            { e: '🐟', l: 'Single protein' },
            { e: '🌾', l: 'Grain free' },
            { e: '🇺🇸', l: 'Made in USA' },
            { e: '🩺', l: 'Vet approved' },
          ].map((h, i) => (
            <div key={i} style={{
              background: 'var(--surface)', borderRadius: 18, padding: '10px 12px',
              border: '1px solid var(--line)', display: 'flex', alignItems: 'center', gap: 10,
            }}>
              <span style={{ fontSize: 22 }}>{h.e}</span>
              <span style={{ fontSize: 13, fontWeight: 800, color: 'var(--ink-950)' }}>{h.l}</span>
            </div>
          ))}
        </div>

        {/* Qty + add */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 24 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, background: 'var(--surface)', borderRadius: 999, padding: 4, border: '1.5px solid var(--line-2)' }}>
            <button onClick={() => setQty(q => Math.max(1, q - 1))} style={{ width: 36, height: 36, borderRadius: '50%', border: 'none', background: 'var(--cream-2)', cursor: 'pointer', fontSize: 18, fontWeight: 900 }}>−</button>
            <span style={{ fontSize: 16, fontWeight: 900, color: 'var(--ink-950)', minWidth: 24, textAlign: 'center' }}>{qty}</span>
            <button onClick={() => setQty(q => q + 1)} style={{ width: 36, height: 36, borderRadius: '50%', border: 'none', background: 'var(--cream-2)', cursor: 'pointer', fontSize: 18, fontWeight: 900 }}>+</button>
          </div>
          <Pill onClick={handleAdd} size="lg" full style={{ flex: 1 }} iconRight={<span style={{ fontSize: 14 }}>${(product.price * qty).toFixed(2)}</span>}>
            Add to cart
          </Pill>
        </div>
      </div>
    </div>
  );
}

// ─── Cart Drawer ───────────────────────────────────────────
function CartDrawer({ open, onClose, items, subtotal, onQty }) {
  const [phase, setPhase] = React.useState('closed');
  React.useEffect(() => {
    if (open) { setPhase('opening'); requestAnimationFrame(() => setPhase('open')); }
    else if (phase !== 'closed') { setPhase('closing'); setTimeout(() => setPhase('closed'), 280); }
  }, [open]);
  if (phase === 'closed') return null;
  const visible = phase === 'open';
  const shipping = items.length > 0 ? 4.50 : 0;
  const total = subtotal + shipping;

  return (
    <div style={{ position: 'absolute', inset: 0, zIndex: 50 }}>
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0, background: 'rgba(38,19,8,0.5)',
        opacity: visible ? 1 : 0, transition: 'opacity 240ms',
      }}/>
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        background: 'var(--cream)', borderTopLeftRadius: 36, borderTopRightRadius: 36,
        maxHeight: '88%', display: 'flex', flexDirection: 'column',
        transform: visible ? 'translateY(0)' : 'translateY(110%)',
        transition: 'transform 320ms cubic-bezier(.3,.7,.4,1)',
        boxShadow: '0 -20px 40px -10px rgba(0,0,0,0.25)',
      }}>
        <div style={{ width: 48, height: 5, borderRadius: 3, background: 'var(--line-2)', margin: '12px auto 0' }}/>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 22px 14px' }}>
          <div>
            <h2 className="display" style={{ fontSize: 26, color: 'var(--ink-950)' }}>Your basket</h2>
            <div style={{ fontSize: 13, color: 'var(--ink-500)', fontWeight: 700 }}>{items.length} item{items.length === 1 ? '' : 's'} · ships to Brooklyn</div>
          </div>
          <IconBtn onClick={onClose} size={36}>{I.close(18)}</IconBtn>
        </div>

        {/* Items list */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '0 18px', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {items.length === 0 && (
            <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--ink-500)' }}>
              <div style={{ fontSize: 60, marginBottom: 10 }}>🛒</div>
              <div style={{ fontSize: 16, fontWeight: 800, color: 'var(--ink-950)' }}>Cart is empty</div>
              <div style={{ fontSize: 13, fontWeight: 600, marginTop: 4 }}>Tap a paw + to add treats</div>
            </div>
          )}
          {items.map(it => (
            <div key={it.id} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              background: 'var(--surface)', borderRadius: 22, padding: '10px 14px 10px 10px',
              border: '1px solid var(--line)',
            }}>
              <div style={{
                width: 60, height: 60, borderRadius: 18,
                background: `linear-gradient(135deg, ${it.soft}, ${it.color})`,
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 30,
                flexShrink: 0,
              }}>{it.emoji}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 800, color: 'var(--ink-950)' }}>{it.name}</div>
                <div style={{ fontSize: 11, color: 'var(--ink-500)', fontWeight: 700 }}>{it.sub}</div>
                <div className="display" style={{ fontSize: 16, color: 'var(--ink-950)', marginTop: 2 }}>${(it.price * it.qty).toFixed(2)}</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 2, background: 'var(--cream-2)', borderRadius: 999, padding: 3 }}>
                <button onClick={() => onQty(it.id, it.qty - 1)} style={{ width: 26, height: 26, borderRadius: '50%', border: 'none', background: 'var(--surface)', cursor: 'pointer', fontWeight: 900 }}>−</button>
                <span style={{ fontSize: 13, fontWeight: 900, minWidth: 18, textAlign: 'center' }}>{it.qty}</span>
                <button onClick={() => onQty(it.id, it.qty + 1)} style={{ width: 26, height: 26, borderRadius: '50%', border: 'none', background: 'var(--surface)', cursor: 'pointer', fontWeight: 900 }}>+</button>
              </div>
            </div>
          ))}

          {/* Suggested add-on */}
          {items.length > 0 && (
            <div style={{
              marginTop: 6, padding: '12px 14px', borderRadius: 22,
              background: 'linear-gradient(135deg, var(--sunny-soft), var(--surface))',
              border: '2px dashed var(--sunny)', display: 'flex', alignItems: 'center', gap: 12,
            }}>
              <div style={{ fontSize: 30 }}>🦴</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, fontWeight: 800, color: 'var(--ink-950)' }}>Add a treat for $4 more</div>
                <div style={{ fontSize: 11, color: 'var(--ink-500)', fontWeight: 700 }}>Unlock free shipping</div>
              </div>
              <Pill size="sm" color="var(--sunny)" style={{ color: 'var(--ink-950)' }}>Add</Pill>
            </div>
          )}
        </div>

        {/* Summary + checkout */}
        {items.length > 0 && (
          <div style={{ padding: '14px 22px 22px', borderTop: '1px solid var(--line)', marginTop: 12 }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 4, fontSize: 13, fontWeight: 700, color: 'var(--ink-700)' }}>
              <Row label="Subtotal" value={`$${subtotal.toFixed(2)}`}/>
              <Row label="Shipping" value={`$${shipping.toFixed(2)}`}/>
              <Row label="Total"   value={`$${total.toFixed(2)}`} big/>
            </div>
            <Pill full size="lg" iconRight={I.chevron(18,'#fff')} style={{ marginTop: 16 }}>Checkout · ${total.toFixed(2)}</Pill>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, marginTop: 10, fontSize: 11, color: 'var(--ink-500)', fontWeight: 700 }}>
              🐾 Earn <b style={{ color: 'var(--tangerine-700)' }}>+{Math.floor(total * 4)} XP</b> when you check out
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function Row({ label, value, big }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: big ? '6px 0 0' : '2px 0', borderTop: big ? '1px solid var(--line)' : 'none', marginTop: big ? 6 : 0 }}>
      <span style={{ fontSize: big ? 16 : 13, fontWeight: big ? 800 : 700, color: big ? 'var(--ink-950)' : 'var(--ink-700)' }}>{label}</span>
      <span style={{ fontSize: big ? 18 : 13, fontWeight: big ? 900 : 700, color: big ? 'var(--ink-950)' : 'var(--ink-700)', fontFamily: big ? 'Fraunces, serif' : 'inherit' }}>{value}</span>
    </div>
  );
}

Object.assign(window, { MarketScreen });
