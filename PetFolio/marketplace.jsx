// Marketplace — shop landing + frictionless single-page checkout.
//
// Two surfaces in one file:
//   • Shop (route 'shop'):  greeting → search → sticky category chips → reorder strip
//                           → Subscribe & Save row → top picks for active pet → tab bar
//   • Checkout (route 'checkout'): single page. Product header, Subscribe & Save card
//                                   with frequency chips, address, delivery, payment,
//                                   summary, sticky bottom Pay CTA with biometric.
//
// Pricing model is centralized: SUBSCRIBE_DISCOUNT = 0.12 (12% off recurring consumables).

const SUBSCRIBE_DISCOUNT = 0.12;

function Shop({ active, onBack, onOpenSwitcher, onTab, onOpenProduct, outdoor }) {
  const [cat, setCat] = React.useState('all');
  const filtered = cat === 'all' ? PRODUCTS : PRODUCTS.filter(p => p.cat === cat);

  return (
    <div style={{
      height: '100%', display: 'flex', flexDirection: 'column',
      background: outdoor ? '#fff' : TOKENS.surface1,
      fontFamily: 'Inter, system-ui, sans-serif', color: TOKENS.ink950,
    }}>
      <ShopHeader active={active} onBack={onBack} onOpenSwitcher={onOpenSwitcher}/>
      <SearchBar/>
      <CategoryChips cat={cat} setCat={setCat}/>

      <div style={{ flex: 1, overflow: 'auto', paddingBottom: 100 }}>
        {cat === 'all' && <ReorderStrip active={active} onOpenProduct={onOpenProduct}/>}
        {cat === 'all' && (
          <>
            <SectionRow title="Subscribe & Save" sub="Recurring consumables · 12% off"
                        accent={TOKENS.meadow}>
              <BadgeRow>
                <SaveBadge/>
                <span style={{ fontSize: 11, color: TOKENS.ink500 }}>Cancel anytime</span>
              </BadgeRow>
            </SectionRow>
            <HorizontalProducts products={PRODUCTS.filter(p => p.subscribable)} onOpenProduct={onOpenProduct}/>

            <SectionRow title={`Top picks for ${active.name}`} sub={active.breed + ' · curated weekly'}/>
            <ProductGrid products={PRODUCTS.slice(0,6)} onOpenProduct={onOpenProduct}/>
          </>
        )}
        {cat !== 'all' && (
          <>
            <div style={{ padding: '14px 16px 6px', fontFamily: 'Sora', fontSize: 18, fontWeight: 700 }}>
              {CATS.find(c => c.id === cat)?.label}
              <span style={{ marginLeft: 8, fontSize: 13, fontWeight: 500, color: TOKENS.ink500 }}>
                {filtered.length} items
              </span>
            </div>
            <ProductGrid products={filtered} onOpenProduct={onOpenProduct}/>
          </>
        )}
      </div>
      <SharedTabBar active="shop" onTab={onTab}/>
    </div>
  );
}

function ShopHeader({ active, onBack, onOpenSwitcher }) {
  return (
    <div style={{ padding: '58px 16px 10px', display: 'flex', alignItems: 'center', gap: 12 }}>
      <button onClick={onBack} aria-label="Back" style={shopIconBtn()}>
        <svg width="10" height="18" viewBox="0 0 10 18">
          <path d="M9 1L1 9l8 8" stroke={TOKENS.ink700} strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </button>
      <button onClick={onOpenSwitcher} style={{
        flex: 1, background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', textAlign: 'left',
      }}>
        <div style={{ fontSize: 11, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: TOKENS.ink500 }}>
          Shop for
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
          <span style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 22, letterSpacing: '-0.01em' }}>
            {active.name}
          </span>
          <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
            <path d="M3 6l5 5 5-5" stroke={TOKENS.ink500} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      </button>
      <button aria-label="Basket" style={{ ...shopIconBtn(), position: 'relative' }}>
        <svg width="20" height="20" viewBox="0 0 22 22" fill="none" stroke={TOKENS.ink700} strokeWidth="1.75" strokeLinejoin="round">
          <path d="M5 7h14l-1.5 12a2 2 0 01-2 1.7h-7a2 2 0 01-2-1.7L5 7zM9 7V5a3 3 0 016 0v2"/>
        </svg>
        <span style={{
          position: 'absolute', top: 2, right: 2, minWidth: 16, height: 16, borderRadius: 8,
          background: TOKENS.coral, color: '#fff',
          fontSize: 10, fontWeight: 700, padding: '0 4px',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          border: '1.5px solid #fff',
        }}>2</span>
      </button>
    </div>
  );
}

function shopIconBtn() {
  return {
    width: 40, height: 40, borderRadius: '50%', border: 'none', cursor: 'pointer',
    background: TOKENS.surface0, color: TOKENS.ink700,
    boxShadow: '0 1px 2px rgba(11,18,32,0.06), 0 0 0 0.5px ' + TOKENS.line200,
    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
  };
}

function SearchBar() {
  return (
    <div style={{ padding: '4px 16px 10px' }}>
      <div style={{
        height: 44, borderRadius: 14, background: TOKENS.surface0,
        boxShadow: '0 0 0 0.5px ' + TOKENS.line200,
        display: 'flex', alignItems: 'center', padding: '0 14px', gap: 10,
      }}>
        <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke={TOKENS.ink500} strokeWidth="1.75" strokeLinecap="round">
          <circle cx="8" cy="8" r="5.5"/><path d="M12 12l3.5 3.5"/>
        </svg>
        <span style={{ flex: 1, color: TOKENS.ink500, fontSize: 14 }}>Search food, gear, treats…</span>
        <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke={TOKENS.ink500} strokeWidth="1.75" strokeLinecap="round">
          <path d="M3 5h12M5 9h8M7 13h4"/>
        </svg>
      </div>
    </div>
  );
}

const CATS = [
  { id: 'all',      label: 'All',       icon: '◯' },
  { id: 'food',     label: 'Food',      icon: '◍' },
  { id: 'gear',     label: 'Gear',      icon: '◐' },
  { id: 'toys',     label: 'Toys',      icon: '◑' },
  { id: 'treats',   label: 'Treats',    icon: '◒' },
  { id: 'health',   label: 'Health',    icon: '◓' },
  { id: 'grooming', label: 'Grooming',  icon: '◔' },
];

function CategoryChips({ cat, setCat }) {
  return (
    <div style={{ overflowX: 'auto', padding: '4px 0 12px' }}>
      <div style={{ display: 'flex', gap: 8, padding: '0 16px', width: 'max-content' }}>
        {CATS.map(c => {
          const a = c.id === cat;
          return (
            <button key={c.id} onClick={() => setCat(c.id)} style={{
              height: 36, padding: '0 16px', borderRadius: 999, border: 'none', cursor: 'pointer',
              background: a ? TOKENS.ink950 : TOKENS.surface0,
              color: a ? '#fff' : TOKENS.ink700,
              fontFamily: 'Inter', fontWeight: 600, fontSize: 13,
              boxShadow: a ? 'none' : '0 0 0 0.5px ' + TOKENS.line200,
              display: 'flex', alignItems: 'center', gap: 7,
              whiteSpace: 'nowrap', flexShrink: 0,
              letterSpacing: '0.01em',
            }}>
              <CategoryGlyph id={c.id} color={a ? '#fff' : TOKENS.ink500}/>
              {c.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}

function CategoryGlyph({ id, color }) {
  const s = { stroke: color, strokeWidth: 1.6, fill: 'none', strokeLinecap: 'round', strokeLinejoin: 'round' };
  if (id === 'all')      return <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="7" cy="7" r="5" {...s}/><circle cx="7" cy="7" r="1.5" fill={color} stroke="none"/></svg>;
  if (id === 'food')     return <svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 4h8l-.5 7a1 1 0 01-1 1H4.5a1 1 0 01-1-1L3 4zM5 4V2.5C5 2 5.5 1.5 6 1.5h2c.5 0 1 .5 1 1V4" {...s}/></svg>;
  if (id === 'gear')     return <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 6l5-3 5 3v5L7 13 2 11V6z" {...s}/><circle cx="7" cy="8" r="1.5" {...s}/></svg>;
  if (id === 'toys')     return <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="7" cy="7" r="5" {...s}/><path d="M2 7c5 0 5-5 10-5M2 7c5 0 5 5 10 5" {...s}/></svg>;
  if (id === 'treats')   return <svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 6l4-3 4 3-2 5H5L3 6z" {...s}/></svg>;
  if (id === 'health')   return <svg width="14" height="14" viewBox="0 0 14 14"><path d="M7 12s-5-3-5-7a3 3 0 015-2 3 3 0 015 2c0 4-5 7-5 7z" {...s}/></svg>;
  if (id === 'grooming') return <svg width="14" height="14" viewBox="0 0 14 14"><path d="M9 1l3 3-7 7-3-3 7-7zM6 4l3 3" {...s}/></svg>;
  return null;
}

// ─── Reorder strip ──────────────────────────────────────────────
function ReorderStrip({ active, onOpenProduct }) {
  const item = PRODUCTS[0]; // Luna's kibble
  return (
    <div style={{ padding: '4px 16px 10px' }}>
      <div onClick={() => onOpenProduct(item)} style={{
        background: 'linear-gradient(135deg, ' + lighten(TOKENS.meadow, 0.25) + ' 0%, ' + TOKENS.meadow + ' 100%)',
        borderRadius: 18, padding: 14, display: 'flex', alignItems: 'center', gap: 12,
        cursor: 'pointer',
      }}>
        <div style={{
          width: 56, height: 56, borderRadius: 12, background: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <ProductGlyph product={item} size={36}/>
        </div>
        <div style={{ flex: 1, color: '#fff', minWidth: 0 }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase', opacity: 0.9 }}>
            Running low · arriving Friday
          </div>
          <div style={{ fontFamily: 'Sora', fontSize: 15, fontWeight: 600, marginTop: 2,
                        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {item.name}
          </div>
          <div style={{ fontSize: 12, opacity: 0.9, marginTop: 2 }}>
            Subscription · 12% off · next in 5 days
          </div>
        </div>
        <button style={{
          height: 36, padding: '0 14px', borderRadius: 999, border: 'none', cursor: 'pointer',
          background: '#fff', color: TOKENS.meadow,
          fontFamily: 'Inter', fontWeight: 700, fontSize: 13,
        }}>Manage</button>
      </div>
    </div>
  );
}

// ─── Section row + product cards ────────────────────────────────
function SectionRow({ title, sub, accent, children }) {
  return (
    <div style={{ padding: '14px 16px 6px', display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12 }}>
      <div>
        <div style={{ fontFamily: 'Sora', fontSize: 18, fontWeight: 700, letterSpacing: '-0.01em',
                      display: 'flex', alignItems: 'center', gap: 8 }}>
          {accent && <span style={{ width: 6, height: 6, borderRadius: '50%', background: accent }}/>}
          {title}
        </div>
        {sub && <div style={{ fontSize: 12, color: TOKENS.ink500, marginTop: 2 }}>{sub}</div>}
      </div>
      {children}
    </div>
  );
}

function BadgeRow({ children }) {
  return <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>{children}</div>;
}

function SaveBadge() {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '4px 8px', borderRadius: 6,
      background: TOKENS.meadowT, color: TOKENS.success,
      fontSize: 11, fontWeight: 700, letterSpacing: '0.02em',
    }}>
      <svg width="10" height="10" viewBox="0 0 10 10"><path d="M5 1l5 4-5 4-5-4 5-4z" fill={TOKENS.success}/></svg>
      Save 12%
    </span>
  );
}

function HorizontalProducts({ products, onOpenProduct }) {
  return (
    <div style={{ overflowX: 'auto', padding: '6px 0 8px' }}>
      <div style={{ display: 'flex', gap: 12, padding: '0 16px', width: 'max-content' }}>
        {products.map(p => (
          <div key={p.id} onClick={() => onOpenProduct(p)} style={{ width: 156, cursor: 'pointer' }}>
            <ProductTile product={p} size={156}/>
            <ProductMeta product={p} compact/>
          </div>
        ))}
      </div>
    </div>
  );
}

function ProductGrid({ products, onOpenProduct }) {
  return (
    <div style={{ padding: '6px 16px 8px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
      {products.map(p => (
        <div key={p.id} onClick={() => onOpenProduct(p)} style={{ cursor: 'pointer' }}>
          <ProductTile product={p}/>
          <ProductMeta product={p}/>
        </div>
      ))}
    </div>
  );
}

function ProductTile({ product, size }) {
  return (
    <div style={{
      width: '100%', aspectRatio: '1 / 1', borderRadius: 16, position: 'relative', overflow: 'hidden',
      background: product.gradient,
      boxShadow: '0 0 0 0.5px ' + TOKENS.line200,
    }}>
      <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle at 30% 25%, rgba(255,255,255,0.32) 0%, transparent 55%)' }}/>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <ProductGlyph product={product} size={(size || 156) * 0.42}/>
      </div>
      {product.subscribable && (
        <div style={{
          position: 'absolute', top: 8, left: 8,
          padding: '3px 7px', borderRadius: 6,
          background: 'rgba(255,255,255,0.95)', color: TOKENS.success,
          fontSize: 10, fontWeight: 700, letterSpacing: '0.04em',
        }}>SUB · SAVE 12%</div>
      )}
      <button aria-label="Save" style={{
        position: 'absolute', top: 8, right: 8, width: 28, height: 28, borderRadius: '50%',
        border: 'none', cursor: 'pointer',
        background: 'rgba(255,255,255,0.92)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke={TOKENS.ink700} strokeWidth="1.6" strokeLinejoin="round" strokeLinecap="round">
          <path d="M7 12s-5-3-5-7a2.5 2.5 0 015-1.5A2.5 2.5 0 0112 5c0 4-5 7-5 7z"/>
        </svg>
      </button>
    </div>
  );
}

function ProductMeta({ product, compact }) {
  return (
    <div style={{ padding: '8px 2px 0' }}>
      <div style={{ fontSize: 11, color: TOKENS.ink500, fontWeight: 500 }}>{product.brand}</div>
      <div style={{ fontFamily: 'Sora', fontWeight: 600, fontSize: compact ? 13 : 14, lineHeight: 1.25, marginTop: 1,
                    display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>
        {product.name}
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 4 }}>
        <span style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 14, fontVariantNumeric: 'tabular-nums' }}>£{product.price.toFixed(2)}</span>
        {product.subscribable && (
          <span style={{ fontSize: 11, color: TOKENS.success, fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>
            £{(product.price * (1 - SUBSCRIBE_DISCOUNT)).toFixed(2)} sub
          </span>
        )}
      </div>
    </div>
  );
}

// Product glyphs (placeholder imagery)
function ProductGlyph({ product, size = 48 }) {
  const s = { stroke: '#fff', strokeWidth: 1.4, fill: 'none', strokeLinecap: 'round', strokeLinejoin: 'round' };
  const fs = { fill: '#fff' };
  const t = product.glyph;
  const v = '0 0 40 40';
  if (t === 'bag')    return <svg width={size} height={size} viewBox={v}><path d="M10 12h20l-2 22a2 2 0 01-2 2H14a2 2 0 01-2-2l-2-22zM14 12V8a6 6 0 0112 0v4" {...s} strokeWidth="1.8"/><circle cx="20" cy="22" r="3" {...fs}/></svg>;
  if (t === 'ball')   return <svg width={size} height={size} viewBox={v}><circle cx="20" cy="20" r="13" {...s} strokeWidth="1.8"/><path d="M7 20c10 0 10-13 26-13M7 20c10 0 10 13 26 13M20 7v26" {...s} strokeWidth="1.8"/></svg>;
  if (t === 'leash')  return <svg width={size} height={size} viewBox={v}><path d="M10 8c4 0 4 6 10 6s6-6 10-6c0 12-6 16-10 22s-2 4-4 4M22 14h6v3a3 3 0 01-3 3h0a3 3 0 01-3-3v-3z" {...s} strokeWidth="1.8"/></svg>;
  if (t === 'bone')   return <svg width={size} height={size} viewBox={v}><path d="M8 14a4 4 0 117 3l16 10a4 4 0 11-3 5l-10-16a4 4 0 11-3-5l-7 3z" {...s} strokeWidth="1.8" fill="rgba(255,255,255,0.15)"/></svg>;
  if (t === 'pill')   return <svg width={size} height={size} viewBox={v}><rect x="6" y="14" width="28" height="12" rx="6" {...s} strokeWidth="1.8" transform="rotate(-25 20 20)"/><path d="M14 9l12 22" {...s} strokeWidth="1.8"/></svg>;
  if (t === 'brush')  return <svg width={size} height={size} viewBox={v}><rect x="10" y="8" width="20" height="14" rx="3" {...s} strokeWidth="1.8"/><path d="M14 22v8M18 22v10M22 22v9M26 22v7M30 22v8" {...s} strokeWidth="1.8"/></svg>;
  if (t === 'bowl')   return <svg width={size} height={size} viewBox={v}><path d="M6 18h28l-3 12a3 3 0 01-3 2.5H12a3 3 0 01-3-2.5L6 18zM6 18c0-3 6-5 14-5s14 2 14 5" {...s} strokeWidth="1.8"/></svg>;
  if (t === 'rope')   return <svg width={size} height={size} viewBox={v}><path d="M6 20c4-3 4 3 8 0s4 3 8 0 4 3 8 0M6 24c4-3 4 3 8 0s4 3 8 0 4 3 8 0M9 16l-3-4M31 16l3-4M9 28l-3 4M31 28l3 4" {...s} strokeWidth="1.8"/></svg>;
  return <svg width={size} height={size} viewBox={v}><rect x="8" y="8" width="24" height="24" rx="4" {...s}/></svg>;
}

// ────────────────────────────────────────────────────────────────
// CHECKOUT
// ────────────────────────────────────────────────────────────────

function Checkout({ product, active, onClose, outdoor }) {
  const [subscribe, setSubscribe] = React.useState(product.subscribable);
  const [freq, setFreq] = React.useState(4); // weeks
  const [delivery, setDelivery] = React.useState('standard'); // 'standard' | 'sameday'

  const base = product.price;
  const sub = subscribe && product.subscribable ? base * (1 - SUBSCRIBE_DISCOUNT) : base;
  const savings = base - sub;
  const deliveryFee = delivery === 'sameday' ? 4.95 : (sub >= 25 ? 0 : 3.95);
  const total = sub + deliveryFee;

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 50,
      background: outdoor ? '#fff' : TOKENS.surface1,
      display: 'flex', flexDirection: 'column',
      animation: 'sheetUp 280ms cubic-bezier(0.2,0.8,0.2,1)',
    }}>
      <style>{`@keyframes sheetUp { from { transform: translateY(12%); opacity: 0; } to { transform: translateY(0); opacity: 1; } }`}</style>

      <CheckoutHeader onClose={onClose}/>

      <div style={{ flex: 1, overflow: 'auto', padding: '4px 16px 130px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <ProductSummary product={product} active={active}/>

        {product.subscribable && (
          <SubscribeCard subscribe={subscribe} setSubscribe={setSubscribe} freq={freq} setFreq={setFreq}
                         base={base} sub={sub} active={active}/>
        )}

        <AddressBlock active={active}/>
        <DeliveryBlock delivery={delivery} setDelivery={setDelivery}/>
        <PaymentBlock/>

        <OrderSummary base={base} sub={sub} savings={savings} delivery={deliveryFee} total={total} subscribe={subscribe}/>

        <div style={{ fontSize: 11, color: TOKENS.ink500, padding: '0 4px', lineHeight: 1.5 }}>
          By placing this order you agree to PetFolio's Terms and the recurring subscription terms if applicable.
          You can pause, change frequency, or cancel anytime from Settings → Subscriptions.
        </div>
      </div>

      <PayBar total={total} subscribe={subscribe} freq={freq} outdoor={outdoor}/>
    </div>
  );
}

function CheckoutHeader({ onClose }) {
  return (
    <div style={{ padding: '58px 16px 8px', display: 'flex', alignItems: 'center', gap: 12 }}>
      <button onClick={onClose} aria-label="Close" style={shopIconBtn()}>
        <svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 3l8 8M11 3l-8 8" stroke={TOKENS.ink700} strokeWidth="2" strokeLinecap="round"/></svg>
      </button>
      <div style={{ flex: 1, textAlign: 'center' }}>
        <div style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 19 }}>Checkout</div>
        <div style={{ fontSize: 11, color: TOKENS.ink500, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 5 }}>
          <svg width="11" height="11" viewBox="0 0 12 12"><path d="M6 1l4 1.5v3.5c0 2.5-2 4-4 5-2-1-4-2.5-4-5V2.5L6 1z" stroke={TOKENS.success} strokeWidth="1.2" fill="none"/></svg>
          Secure · single page · no account jump
        </div>
      </div>
      <div style={{ width: 40 }}/>
    </div>
  );
}

function ProductSummary({ product, active }) {
  return (
    <div style={cardStyle()}>
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <div style={{ width: 64, height: 64, borderRadius: 12, background: product.gradient, position: 'relative', overflow: 'hidden', flexShrink: 0 }}>
          <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle at 30% 25%, rgba(255,255,255,0.32) 0%, transparent 55%)' }}/>
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <ProductGlyph product={product} size={36}/>
          </div>
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 11, color: TOKENS.ink500, fontWeight: 500 }}>{product.brand}</div>
          <div style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 15, lineHeight: 1.3, marginTop: 1 }}>{product.name}</div>
          <div style={{ fontSize: 11, color: TOKENS.ink500, marginTop: 3 }}>For {active.name} · {product.variant}</div>
        </div>
        <Stepper/>
      </div>
    </div>
  );
}

function Stepper() {
  const [n, setN] = React.useState(1);
  return (
    <div style={{
      display: 'flex', alignItems: 'center', height: 36, borderRadius: 999,
      background: TOKENS.surface2,
    }}>
      <button onClick={() => setN(Math.max(1, n - 1))} aria-label="Decrease" style={stepperBtn()}>−</button>
      <span style={{ minWidth: 24, textAlign: 'center', fontFamily: 'Sora', fontWeight: 700, fontSize: 14 }}>{n}</span>
      <button onClick={() => setN(n + 1)} aria-label="Increase" style={stepperBtn()}>+</button>
    </div>
  );
}
function stepperBtn() {
  return {
    width: 36, height: 36, border: 'none', background: 'transparent', cursor: 'pointer',
    fontSize: 18, fontWeight: 600, color: TOKENS.ink700,
  };
}

function SubscribeCard({ subscribe, setSubscribe, freq, setFreq, base, sub, active }) {
  const FREQS = [2, 4, 6, 8];
  const monthly = subscribe ? sub * (4 / freq) : null;
  return (
    <div style={{
      ...cardStyle(),
      background: subscribe ? `linear-gradient(135deg, ${TOKENS.meadowT} 0%, #fff 60%)` : TOKENS.surface0,
      transition: 'background 220ms',
    }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
        <div style={{
          width: 40, height: 40, borderRadius: 12,
          background: subscribe ? TOKENS.meadow : TOKENS.surface2,
          color: subscribe ? '#fff' : TOKENS.ink500,
          display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
        }}>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <path d="M3 10a7 7 0 0112-5l2-2v6h-6l2-2A5 5 0 005 10M17 10a7 7 0 01-12 5l-2 2v-6h6l-2 2a5 5 0 0010 0"/>
          </svg>
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 15 }}>Subscribe & Save</span>
            <SaveBadge/>
          </div>
          <div style={{ fontSize: 12, color: TOKENS.ink500, marginTop: 3 }}>
            {subscribe
              ? <>Auto-delivers every <strong style={{ color: TOKENS.ink950 }}>{freq} weeks</strong> · save £{(base - sub).toFixed(2)}</>
              : <>Save 12% on every refill · cancel anytime</>}
          </div>
        </div>
        <Toggle on={subscribe} onChange={setSubscribe}/>
      </div>

      <div style={{
        maxHeight: subscribe ? 200 : 0, overflow: 'hidden',
        transition: 'max-height 280ms cubic-bezier(0.2,0.8,0.2,1)',
      }}>
        <div style={{ paddingTop: 14, display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: TOKENS.ink500 }}>
            Delivery frequency
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            {FREQS.map(f => {
              const a = f === freq;
              return (
                <button key={f} onClick={() => setFreq(f)} style={{
                  flex: 1, height: 44, borderRadius: 12, border: 'none', cursor: 'pointer',
                  background: a ? TOKENS.ink950 : '#fff',
                  color: a ? '#fff' : TOKENS.ink700,
                  fontFamily: 'Sora', fontWeight: 700, fontSize: 14,
                  boxShadow: a ? 'none' : '0 0 0 0.5px ' + TOKENS.line200,
                }}>{f}<span style={{ fontSize: 10, fontWeight: 500, marginLeft: 2, opacity: 0.7 }}>wk</span></button>
              );
            })}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 12 }}>
            <span style={{ color: TOKENS.ink500 }}>Next delivery</span>
            <span style={{ fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>
              {nextDeliveryDate()} · est. £{monthly ? monthly.toFixed(2) : '—'}/mo
            </span>
          </div>
          <div style={{ fontSize: 11, color: TOKENS.ink500, display: 'flex', alignItems: 'center', gap: 5 }}>
            <svg width="11" height="11" viewBox="0 0 12 12"><path d="M6 1l4 1.5v3.5c0 2.5-2 4-4 5-2-1-4-2.5-4-5V2.5L6 1z" stroke={TOKENS.success} strokeWidth="1.2" fill="none"/></svg>
            Skip, swap, or cancel anytime — we'll remind {active.name} 3 days before each delivery.
          </div>
        </div>
      </div>
    </div>
  );
}

function nextDeliveryDate() {
  const d = new Date();
  d.setDate(d.getDate() + 4);
  return d.toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short' });
}

function Toggle({ on, onChange }) {
  return (
    <button onClick={() => onChange(!on)} role="switch" aria-checked={on} style={{
      width: 52, height: 32, borderRadius: 999, border: 'none', cursor: 'pointer',
      background: on ? TOKENS.meadow : TOKENS.surface2,
      position: 'relative', padding: 0, flexShrink: 0,
      transition: 'background 200ms',
    }}>
      <span style={{
        position: 'absolute', top: 3, left: on ? 23 : 3, width: 26, height: 26, borderRadius: '50%',
        background: '#fff', boxShadow: '0 2px 5px rgba(0,0,0,0.15)',
        transition: 'left 200ms cubic-bezier(0.2,0.8,0.2,1)',
      }}/>
    </button>
  );
}

function AddressBlock({ active }) {
  return (
    <div style={cardStyle()}>
      <RowLabel>Deliver to</RowLabel>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 8 }}>
        <div style={{ width: 36, height: 36, borderRadius: 10, background: TOKENS.blue50, color: TOKENS.blue600, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" strokeWidth="1.75"><path d="M9 16s-6-5-6-10a6 6 0 1112 0c0 5-6 10-6 10z"/><circle cx="9" cy="6" r="2"/></svg>
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: 'Sora', fontWeight: 600, fontSize: 14 }}>Home · Highbury</div>
          <div style={{ fontSize: 12, color: TOKENS.ink500, marginTop: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            14 Aberdeen Lane, London N5 · {active.name} will be home Tue–Thu
          </div>
        </div>
        <button style={textBtn()}>Change</button>
      </div>
    </div>
  );
}

function DeliveryBlock({ delivery, setDelivery }) {
  const OPTIONS = [
    { id: 'standard', label: 'Standard',    sub: 'Fri 7 Jun · free over £25', price: '£3.95' },
    { id: 'sameday',  label: 'Same-day',    sub: 'Today before 9 pm',        price: '£4.95' },
  ];
  return (
    <div style={cardStyle()}>
      <RowLabel>Delivery</RowLabel>
      <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
        {OPTIONS.map(o => {
          const a = o.id === delivery;
          return (
            <button key={o.id} onClick={() => setDelivery(o.id)} style={{
              flex: 1, padding: '10px 12px', borderRadius: 12, border: 'none', cursor: 'pointer',
              background: a ? TOKENS.blue50 : '#fff', textAlign: 'left',
              boxShadow: a ? '0 0 0 2px ' + TOKENS.blue500 : '0 0 0 0.5px ' + TOKENS.line200,
              fontFamily: 'Inter',
            }}>
              <div style={{ fontWeight: 700, fontSize: 13, color: TOKENS.ink950 }}>{o.label}</div>
              <div style={{ fontSize: 11, color: TOKENS.ink500, marginTop: 2 }}>{o.sub}</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: a ? TOKENS.blue700 : TOKENS.ink700, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{o.price}</div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function PaymentBlock() {
  return (
    <div style={cardStyle()}>
      <RowLabel>Payment</RowLabel>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 8 }}>
        <div style={{
          width: 44, height: 30, borderRadius: 6,
          background: 'linear-gradient(135deg, #1a1a2e 0%, #16213e 100%)',
          color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: 'Sora', fontSize: 9, fontWeight: 700, letterSpacing: '0.08em',
          flexShrink: 0,
        }}>VISA</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: 'Sora', fontWeight: 600, fontSize: 14 }}>Visa · 4242</div>
          <div style={{ fontSize: 11, color: TOKENS.ink500, marginTop: 1 }}>Expires 06/27 · default</div>
        </div>
        <button style={textBtn()}>Change</button>
      </div>
    </div>
  );
}

function OrderSummary({ base, sub, savings, delivery, total, subscribe }) {
  return (
    <div style={cardStyle()}>
      <RowLabel>Order summary</RowLabel>
      <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 8, fontVariantNumeric: 'tabular-nums' }}>
        <SumLine label="Subtotal" value={`£${base.toFixed(2)}`}/>
        {subscribe && <SumLine label="Subscribe & Save (12%)" value={`− £${savings.toFixed(2)}`} accent={TOKENS.success}/>}
        <SumLine label="Delivery" value={delivery === 0 ? 'Free' : `£${delivery.toFixed(2)}`}/>
        <div style={{ height: 1, background: TOKENS.line200, margin: '4px 0' }}/>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <span style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 15 }}>Total today</span>
          <span style={{ fontFamily: 'Sora', fontWeight: 700, fontSize: 22, letterSpacing: '-0.01em' }}>£{total.toFixed(2)}</span>
        </div>
      </div>
    </div>
  );
}

function SumLine({ label, value, accent }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13 }}>
      <span style={{ color: TOKENS.ink500 }}>{label}</span>
      <span style={{ fontWeight: 600, color: accent || TOKENS.ink950 }}>{value}</span>
    </div>
  );
}

function RowLabel({ children }) {
  return (
    <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.08em', textTransform: 'uppercase', color: TOKENS.ink500 }}>
      {children}
    </div>
  );
}

function cardStyle() {
  return {
    background: TOKENS.surface0, borderRadius: 18, padding: '14px 16px',
    boxShadow: '0 0 0 0.5px ' + TOKENS.line200 + ', 0 1px 2px rgba(11,18,32,0.04)',
  };
}

function textBtn() {
  return {
    background: 'transparent', border: 'none', cursor: 'pointer',
    fontFamily: 'Inter', fontWeight: 600, fontSize: 13, color: TOKENS.blue600,
    padding: '6px 8px',
  };
}

function PayBar({ total, subscribe, freq, outdoor }) {
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      paddingBottom: 30, paddingTop: 14, padding: '14px 16px 30px',
      background: outdoor ? '#fff' : 'rgba(250,251,253,0.92)',
      backdropFilter: outdoor ? 'none' : 'blur(20px) saturate(140%)',
      WebkitBackdropFilter: outdoor ? 'none' : 'blur(20px) saturate(140%)',
      boxShadow: '0 -0.5px 0 ' + TOKENS.line200,
    }}>
      <button style={{
        width: '100%', height: 56, borderRadius: 16, border: 'none', cursor: 'pointer',
        background: TOKENS.ink950, color: '#fff',
        fontFamily: 'Sora', fontWeight: 700, fontSize: 16,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
        boxShadow: '0 12px 28px -10px rgba(11,18,32,0.5)',
      }}>
        <FaceIDGlyph/>
        <span>{subscribe ? `Subscribe · pay £${total.toFixed(2)}` : `Pay £${total.toFixed(2)}`}</span>
      </button>
      {subscribe && (
        <div style={{ textAlign: 'center', fontSize: 11, color: TOKENS.ink500, marginTop: 8 }}>
          Then £{total.toFixed(2)} every {freq} weeks · pause anytime
        </div>
      )}
    </div>
  );
}

function FaceIDGlyph() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="#fff" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 6V3a1 1 0 011-1h3M16 6V3a1 1 0 00-1-1h-3M2 12v3a1 1 0 001 1h3M16 12v3a1 1 0 01-1 1h-3"/>
      <path d="M6 7v1.5M12 7v1.5M9 7v3.5L8 11M7 13s.7 1 2 1 2-1 2-1"/>
    </svg>
  );
}

// ─── Product data ───────────────────────────────────────────────
const PRODUCTS = [
  { id: 'p1', cat: 'food',  name: 'Wild Salmon & Sweet Potato Kibble', brand: 'Wholepack', variant: '12 kg bag',
    price: 48.00, subscribable: true, glyph: 'bag',
    gradient: 'linear-gradient(135deg, #F4B57A 0%, #C46A4F 100%)' },
  { id: 'p2', cat: 'toys',  name: 'Tug-of-War Rope Twist', brand: 'Pawhaus', variant: 'Medium',
    price: 14.50, subscribable: false, glyph: 'rope',
    gradient: 'linear-gradient(135deg, #9BB59A 0%, #485F4F 100%)' },
  { id: 'p3', cat: 'gear',  name: 'Reflective Trail Harness', brand: 'Highline', variant: 'M · Slate',
    price: 38.00, subscribable: false, glyph: 'leash',
    gradient: 'linear-gradient(135deg, #4B7DFA 0%, #173FA3 100%)' },
  { id: 'p4', cat: 'treats',name: 'Single-Source Beef Liver Treats', brand: 'Wholepack', variant: '200 g jar',
    price: 9.20, subscribable: true, glyph: 'bone',
    gradient: 'linear-gradient(135deg, #E76F51 0%, #B14530 100%)' },
  { id: 'p5', cat: 'health',name: 'Joint Support Chews · Glucosamine', brand: 'Vitavet', variant: '60 chews',
    price: 24.00, subscribable: true, glyph: 'pill',
    gradient: 'linear-gradient(135deg, #9B5C8A 0%, #5E3354 100%)' },
  { id: 'p6', cat: 'grooming', name: 'Slicker Brush · Self-Cleaning', brand: 'Pawhaus', variant: 'Long-haired',
    price: 19.50, subscribable: false, glyph: 'brush',
    gradient: 'linear-gradient(135deg, #F5C49B 0%, #C49370 100%)' },
  { id: 'p7', cat: 'food',  name: 'Pumpkin Digestive Wet Food', brand: 'Wholepack', variant: '12 × 400g',
    price: 32.00, subscribable: true, glyph: 'bowl',
    gradient: 'linear-gradient(135deg, #F4A261 0%, #B86E2C 100%)' },
  { id: 'p8', cat: 'toys',  name: 'Bouncing Squeaker Ball', brand: 'Pawhaus', variant: 'Two-pack',
    price: 8.00, subscribable: false, glyph: 'ball',
    gradient: 'linear-gradient(135deg, #6BAF92 0%, #2F6A4D 100%)' },
];

Object.assign(window, { Shop, Checkout, PRODUCTS });
