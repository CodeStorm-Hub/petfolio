// health.jsx — Medical vault (warm but trustworthy)

function HealthScreen({ activePet, navigate, motif }) {
  const pet = DEMO_PETS.find(p => p.id === activePet) || DEMO_PETS[0];

  return (
    <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 100, background: 'var(--cream)' }}>
      {/* Header with mint pillar tint */}
      <div style={{
        background: 'linear-gradient(180deg, var(--mint-soft), var(--cream))',
        padding: '14px 18px 28px',
        position: 'relative',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
          <IconBtn onClick={() => navigate('care')} size={40}>{I.back(22)}</IconBtn>
          <div style={{ flex: 1, fontSize: 10, color: 'var(--mint-700)', fontWeight: 800, letterSpacing: 0.8 }}>
            {pet.name.toUpperCase()} · MEDICAL VAULT
          </div>
          <IconBtn bg="var(--mint)" color="#fff" shadow={true}>{I.plus(22, '#fff')}</IconBtn>
        </div>

        <h1 className="display" style={{ fontSize: 36, lineHeight: 1.05, marginBottom: 8, color: 'var(--ink-950)' }}>
          Everything <span style={{ color: 'var(--mint-700)' }}>healthy</span>,<br/>in one cozy spot.
        </h1>
        <p style={{ fontSize: 14, color: 'var(--ink-700)', fontWeight: 600 }}>
          Vaccines, meds, and vet visits — synced live from {pet.name}'s clinic.
        </p>

        {/* Health pulse summary */}
        <div style={{ display: 'flex', gap: 8, marginTop: 18 }}>
          <HealthPill icon="💚" label="Vitals" value="Strong" tone="var(--mint)"/>
          <HealthPill icon="💉" label="Vaccines" value="Up to date" tone="var(--mint)"/>
          <HealthPill icon="📅" label="Next visit" value="14 Jun" tone="var(--sunny)"/>
        </div>
      </div>

      {/* Body */}
      <div style={{ padding: '4px 16px 0' }}>
        {/* Vaccines */}
        <VaultSection title="Vaccines" accent="var(--mint)" icon="💉" count={4}>
          <RecordRow color="var(--mint)" icon={I.syringe(20)}
            title="Rabies" date="Mar 12, 2026" tag="Annual"
            status={{ label: 'Up to date', color: 'var(--mint-700)', bg: 'var(--mint-soft)' }}
            note="Next due Mar 2027"/>
          <RecordRow color="var(--mint)" icon={I.syringe(20)}
            title="DHPP" date="Jan 04, 2026" tag="Booster"
            status={{ label: 'Up to date', color: 'var(--mint-700)', bg: 'var(--mint-soft)' }}/>
          <RecordRow color="var(--sunny)" icon={I.syringe(20)}
            title="Bordetella" date="Sep 02, 2025" tag="Kennel cough"
            status={{ label: 'Due in 22 days', color: 'var(--sunny-700)', bg: 'var(--sunny-soft)' }}/>
        </VaultSection>

        {/* Medications */}
        <VaultSection title="Medications" accent="var(--poppy)" icon="💊" count={2}>
          <RecordRow color="var(--poppy)" icon={I.pill(20)}
            title="NexGard" date="Monthly" tag="Heartworm"
            status={{ label: 'Next dose today', color: 'var(--poppy-700)', bg: 'var(--poppy-soft)' }}
            note="0.5 tablet / morning"/>
          <RecordRow color="var(--lilac)" icon={I.pill(20)}
            title="Apoquel" date="2× daily" tag="Allergies"
            status={{ label: 'Active', color: 'var(--lilac-700)', bg: 'var(--lilac-soft)' }}/>
        </VaultSection>

        {/* Vet visits */}
        <VaultSection title="Vet visits" accent="var(--tangerine)" icon="🏥" count={3}>
          <RecordRow color="var(--tangerine)" icon={I.stethoscope(20)}
            title="Spring check-up" date="May 18, 2026" tag="Dr. Patel"
            status={{ label: 'Complete', color: 'var(--mint-700)', bg: 'var(--mint-soft)' }}
            note="Weight: 4.8 kg · Heart: normal"/>
          <RecordRow color="var(--tangerine)" icon={I.stethoscope(20)}
            title="Dental cleaning" date="Feb 02, 2026" tag="Dr. Patel"
            status={{ label: 'Complete', color: 'var(--mint-700)', bg: 'var(--mint-soft)' }}/>
        </VaultSection>

        {/* Share with vet card */}
        <Card pad={18} style={{
          marginTop: 16, marginBottom: 16,
          background: 'linear-gradient(135deg, var(--mint-soft), var(--surface))',
          border: '2px dashed var(--mint)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ fontSize: 36 }}>🩺</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontWeight: 800, color: 'var(--ink-950)' }}>Share with your vet</div>
              <div style={{ fontSize: 12, color: 'var(--ink-500)', fontWeight: 700 }}>Generate a temporary QR — expires in 24h</div>
            </div>
            <Pill size="sm" color="var(--mint)">Share</Pill>
          </div>
        </Card>
      </div>
    </div>
  );
}

function HealthPill({ icon, label, value, tone }) {
  return (
    <div style={{
      flex: 1, background: 'var(--surface)', borderRadius: 18,
      padding: '10px 12px',
      border: `1.5px solid var(--line)`,
      boxShadow: 'var(--shadow-soft)',
      display: 'flex', flexDirection: 'column', gap: 2,
    }}>
      <div style={{ fontSize: 18, lineHeight: 1 }}>{icon}</div>
      <div style={{ fontSize: 10, fontWeight: 800, color: 'var(--ink-500)', letterSpacing: 0.4, textTransform: 'uppercase' }}>{label}</div>
      <div style={{ fontSize: 13, fontWeight: 800, color: 'var(--ink-950)' }}>{value}</div>
    </div>
  );
}

function VaultSection({ title, accent, icon, count, children }) {
  return (
    <div style={{ marginTop: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '0 4px 10px' }}>
        <div style={{
          width: 36, height: 36, borderRadius: 12,
          background: `color-mix(in oklab, ${accent} 22%, var(--surface))`,
          display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18,
        }}>{icon}</div>
        <h3 style={{ fontSize: 18, fontWeight: 800, color: 'var(--ink-950)' }}>{title}</h3>
        <div style={{
          background: `color-mix(in oklab, ${accent} 18%, var(--surface))`,
          color: 'var(--ink-700)', padding: '2px 10px', borderRadius: 999,
          fontSize: 12, fontWeight: 800,
        }}>{count}</div>
      </div>
      <Card pad={0} style={{ overflow: 'hidden' }}>
        {children}
      </Card>
    </div>
  );
}

function RecordRow({ color, icon, title, date, tag, status, note }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, padding: '14px 14px', borderBottom: '1px solid var(--line)' }}>
      <div style={{
        width: 42, height: 42, borderRadius: 14, flexShrink: 0,
        background: `color-mix(in oklab, ${color} 18%, var(--surface))`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 15, fontWeight: 800, color: 'var(--ink-950)' }}>{title}</span>
          {tag && <span style={{ fontSize: 10, padding: '2px 8px', borderRadius: 999, background: 'var(--cream-2)', color: 'var(--ink-700)', fontWeight: 800 }}>{tag}</span>}
        </div>
        <div style={{ fontSize: 12, color: 'var(--ink-500)', fontWeight: 700, marginTop: 2 }}>{date}</div>
        {note && <div style={{ fontSize: 12, color: 'var(--ink-700)', marginTop: 4, fontFamily: 'ui-monospace, monospace' }}>{note}</div>}
      </div>
      <div style={{
        background: status.bg, color: status.color,
        fontSize: 11, fontWeight: 900, padding: '4px 10px', borderRadius: 999,
        whiteSpace: 'nowrap',
      }}>{status.label}</div>
    </div>
  );
}

Object.assign(window, { HealthScreen });
