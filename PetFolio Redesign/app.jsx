// app.jsx — Top-level PetFolio app: routing, tweaks, frame wrapper

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "dark": false,
  "primary": "#FF8A4C",
  "palette": ["#FF8A4C","#FF3D3D","#2FCBA0","#FFC53D","#A98BFF"],
  "showFrame": true,
  "motif": "confident",
  "startScreen": "home"
}/*EDITMODE-END*/;

const PALETTES = [
  // [tangerine, bubblegum, mint, sunny, lilac]
  { id: 'warm',    label: 'Warm pop',      colors: ['#FF8A4C','#FF3D3D','#2FCBA0','#FFC53D','#A98BFF'] },
  { id: 'pastel',  label: 'Soft pastel',   colors: ['#FFA37A','#FF9090','#7EE4C5','#FFD771','#C9B3FF'] },
  { id: 'bold',    label: 'Bold Pop',     colors: ['#FF3D3D','#FF8A4C','#5BD9F8','#FFD93C','#9C6BFF'] },
  { id: 'meadow',  label: 'Meadow',        colors: ['#34C29B','#FFB347','#FF5050','#FFE066','#7BB7FF'] },
];

function applyPalette(p, dark) {
  const root = document.documentElement;
  const [tangerine, bubblegum, mint, sunny, lilac] = p;
  root.style.setProperty('--tangerine', tangerine);
  root.style.setProperty('--bubblegum', bubblegum);
  root.style.setProperty('--mint', mint);
  root.style.setProperty('--sunny', sunny);
  root.style.setProperty('--lilac', lilac);
  // Soft tints — mix toward white in light mode, toward dark surface in dark mode.
  // Dark mode soft surfaces should still be dark so foreground cream text stays readable.
  const softBase = dark ? '#1A1014' : 'white';
  const softPct  = dark ? 28 : 22;
  function soft(hex) { return `color-mix(in oklab, ${hex} ${softPct}%, ${softBase})`; }
  // -700 = darker accent for "on tint" text. In dark mode we want a LIGHTER accent
  // (so colored text reads against dark soft surfaces).
  function strong(hex) { return dark
    ? `color-mix(in oklab, ${hex} 65%, white)`
    : `color-mix(in oklab, ${hex} 60%, black)`; }
  root.style.setProperty('--tangerine-soft', soft(tangerine));
  root.style.setProperty('--bubblegum-soft', soft(bubblegum));
  root.style.setProperty('--mint-soft', soft(mint));
  root.style.setProperty('--sunny-soft', soft(sunny));
  root.style.setProperty('--lilac-soft', soft(lilac));
  root.style.setProperty('--tangerine-700', strong(tangerine));
  root.style.setProperty('--bubblegum-700', strong(bubblegum));
  root.style.setProperty('--mint-700', strong(mint));
  root.style.setProperty('--sunny-700', strong(sunny));
  root.style.setProperty('--lilac-700', strong(lilac));
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  // Apply theme/dark mode + repaint palette
  React.useEffect(() => {
    document.documentElement.setAttribute('data-theme', t.dark ? 'dark' : 'light');
    if (Array.isArray(t.palette)) applyPalette(t.palette, !!t.dark);
  }, [t.dark, t.palette]);

  // App state
  const [route, setRoute] = React.useState('onboarding'); // onboarding | home | care | social | match | market | health
  const [activePet, setActivePet] = React.useState('mochi');
  const [switcherOpen, setSwitcherOpen] = React.useState(false);

  React.useEffect(() => {
    // After mount, also accept startScreen tweak to jump directly
    if (t.startScreen && t.startScreen !== 'onboarding') {
      setRoute(t.startScreen);
    }
  }, []);

  function navigate(screen) {
    setRoute(screen);
  }

  const isTab = ['home','care','social','match','market'].includes(route);

  return (
    <React.Fragment>
      <div style={{ display: 'inline-block', filter: t.dark ? 'none' : 'none' }}>
        {t.showFrame ? (
          <AndroidDevice width={412} height={892} dark={t.dark}>
            <AppShell
              route={route}
              navigate={navigate}
              activePet={activePet}
              setActivePet={setActivePet}
              switcherOpen={switcherOpen}
              setSwitcherOpen={setSwitcherOpen}
              motif={t.motif}
              isTab={isTab}
            />
          </AndroidDevice>
        ) : (
          <div style={{
            width: 412, height: 892, borderRadius: 28, overflow: 'hidden',
            background: 'var(--cream)', boxShadow: '0 30px 80px rgba(0,0,0,0.2)',
            position: 'relative', border: '1px solid var(--line)',
          }}>
            <AppShell
              route={route}
              navigate={navigate}
              activePet={activePet}
              setActivePet={setActivePet}
              switcherOpen={switcherOpen}
              setSwitcherOpen={setSwitcherOpen}
              motif={t.motif}
              isTab={isTab}
              noStatus
            />
          </div>
        )}
      </div>

      <TweaksPanel title="PetFolio · Tweaks">
        <TweakSection label="Tour"/>
        <TweakSelect label="Jump to screen" value={route}
          options={[
            { value: 'onboarding', label: 'Onboarding quiz' },
            { value: 'home', label: 'Home / Pet profile' },
            { value: 'care', label: 'Care · gamified' },
            { value: 'social', label: 'Social feed' },
            { value: 'match', label: 'Match · swipe' },
            { value: 'market', label: 'Marketplace' },
            { value: 'health', label: 'Medical vault' },
          ]}
          onChange={v => setRoute(v)}/>

        <TweakSection label="Theme"/>
        <TweakToggle label="Dark mode" value={t.dark} onChange={v => setTweak('dark', v)}/>
        <TweakColor label="Accent palette" value={t.palette}
          options={PALETTES.map(p => p.colors)}
          onChange={v => setTweak('palette', v)}/>

        <TweakSection label="Personality"/>
        <TweakRadio label="Motifs" value={t.motif}
          options={[
            { value: 'subtle', label: 'Subtle' },
            { value: 'confident', label: 'Confident' },
            { value: 'maximal', label: 'Maximal' },
          ]}
          onChange={v => setTweak('motif', v)}/>

        <TweakSection label="Frame"/>
        <TweakToggle label="Android frame" value={t.showFrame} onChange={v => setTweak('showFrame', v)}/>
      </TweaksPanel>
    </React.Fragment>
  );
}

function AppShell({ route, navigate, activePet, setActivePet, switcherOpen, setSwitcherOpen, motif, isTab, noStatus }) {
  // Map screen labels for comment context
  const screenLabel = {
    onboarding: '01 Onboarding',
    home:       '02 Home',
    care:       '03 Care',
    social:     '04 Social',
    match:      '05 Match',
    market:     '06 Market',
    health:     '07 Health Vault',
  }[route];

  return (
    <div className="app" style={{ position: 'absolute', inset: 0, background: 'var(--cream)', overflow: 'hidden' }} data-screen-label={screenLabel}>
      {/* Screen */}
      {route === 'onboarding' && <Onboarding onDone={() => navigate('home')}/>}
      {route === 'home'    && <HomeScreen activePet={activePet} setActivePet={setActivePet} openPetSwitcher={() => setSwitcherOpen(true)} navigate={navigate} motif={motif}/>}
      {route === 'care'    && <CareScreen activePet={activePet} openSwitcher={() => setSwitcherOpen(true)} navigate={navigate} motif={motif}/>}
      {route === 'social'  && <SocialScreen navigate={navigate} motif={motif}/>}
      {route === 'match'   && <MatchScreen navigate={navigate} openSwitcher={() => setSwitcherOpen(true)} activePet={activePet} motif={motif}/>}
      {route === 'market'  && <MarketScreen navigate={navigate} motif={motif}/>}
      {route === 'health'  && <HealthScreen activePet={activePet} navigate={navigate} motif={motif}/>}

      {/* Bottom nav (only on tab screens) */}
      {isTab && <BottomNav active={route} onChange={navigate} motif={motif}/>}

      {/* Pet switcher sheet — overlays anywhere */}
      <PetSwitcher
        open={switcherOpen}
        onClose={() => setSwitcherOpen(false)}
        active={activePet}
        setActive={setActivePet}
        navigate={navigate}
      />
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
