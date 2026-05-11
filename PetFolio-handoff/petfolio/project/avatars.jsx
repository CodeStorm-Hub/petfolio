// PetAvatar — tinted gradient disc with monogram. Sleek, intentional placeholder.
// When a real photo URL is supplied (from onboarding image-slot), renders that instead.

function PetAvatar({ pet, size = 56, ring = null, photoUrl = null, dark = false }) {
  const initial = (pet?.name || '?').charAt(0).toUpperCase();
  const accent = pet?.accent || '#94A3B8';
  const tint = pet?.tint || '#E2E8F0';
  const ringPx = ring ? 3 : 0;
  const inner = size - ringPx * 2;
  const speciesGlyph = SPECIES_GLYPHS[pet?.species] || null;

  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      padding: ringPx, boxSizing: 'border-box',
      background: ring || 'transparent',
      flexShrink: 0,
      boxShadow: ring ? '0 4px 14px -2px rgba(11,18,32,0.18)' : 'none',
    }}>
      <div style={{
        width: inner, height: inner, borderRadius: '50%',
        background: photoUrl
          ? `url(${photoUrl}) center/cover no-repeat`
          : `radial-gradient(circle at 30% 25%, ${lighten(accent, 0.35)} 0%, ${accent} 55%, ${darken(accent, 0.15)} 100%)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: '#fff', overflow: 'hidden',
        fontFamily: 'Sora, system-ui, sans-serif', fontWeight: 600,
        fontSize: inner * 0.42, letterSpacing: '-0.02em',
        position: 'relative',
        boxShadow: 'inset 0 -8px 18px -8px rgba(0,0,0,0.25), inset 0 1px 0 rgba(255,255,255,0.25)',
      }}>
        {!photoUrl && (
          <>
            <span style={{
              textShadow: '0 1px 2px rgba(0,0,0,0.15)',
              opacity: 0.95,
            }}>{initial}</span>
            {speciesGlyph && (
              <div style={{
                position: 'absolute', bottom: inner * 0.05, right: inner * 0.05,
                width: inner * 0.32, height: inner * 0.32, borderRadius: '50%',
                background: 'rgba(255,255,255,0.92)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 1px 3px rgba(0,0,0,0.15)',
              }}>
                <svg width={inner * 0.2} height={inner * 0.2} viewBox="0 0 16 16" fill={accent}>
                  {speciesGlyph}
                </svg>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}

// Tiny species pictograms — circles + dots only, no anatomical drawings.
const SPECIES_GLYPHS = {
  dog:     <><circle cx="8" cy="9" r="4"/><circle cx="4" cy="5" r="1.6"/><circle cx="12" cy="5" r="1.6"/></>,
  cat:     <><circle cx="8" cy="10" r="4"/><path d="M3.5 4l2 4 1.8-1z"/><path d="M12.5 4l-2 4-1.8-1z"/></>,
  rabbit:  <><circle cx="8" cy="11" r="3.5"/><ellipse cx="6" cy="5" rx="1.2" ry="3"/><ellipse cx="10" cy="5" rx="1.2" ry="3"/></>,
  bird:    <><circle cx="8" cy="9" r="3.5"/><path d="M5 6l-2-2 2.5 .5z"/><path d="M11 11l3 1-1-2z"/></>,
  fish:    <><ellipse cx="7" cy="8" rx="4" ry="2.5"/><path d="M11 8l3-2v4z"/></>,
  reptile: <><ellipse cx="8" cy="9" rx="4.5" ry="2.2"/><circle cx="11.5" cy="8" r="0.6" fill="#fff"/></>,
};

function lighten(hex, amt) {
  const c = hex.replace('#','');
  const r = parseInt(c.slice(0,2),16), g = parseInt(c.slice(2,4),16), b = parseInt(c.slice(4,6),16);
  const m = (v) => Math.round(v + (255 - v) * amt);
  return `rgb(${m(r)}, ${m(g)}, ${m(b)})`;
}
function darken(hex, amt) {
  const c = hex.replace('#','');
  const r = parseInt(c.slice(0,2),16), g = parseInt(c.slice(2,4),16), b = parseInt(c.slice(4,6),16);
  const m = (v) => Math.round(v * (1 - amt));
  return `rgb(${m(r)}, ${m(g)}, ${m(b)})`;
}

Object.assign(window, { PetAvatar, SPECIES_GLYPHS, lighten, darken });
