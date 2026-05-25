// Root App — owns navigation state between onboarding and home, plus the switcher sheet.

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  // Start in onboarding if no pets yet; once a pet is added, go to home.
  const [pets, setPets] = React.useState(t.startInApp ? SEED_PETS : []);
  const [activeId, setActiveId] = React.useState(t.startInApp ? SEED_PETS[0].id : null);
  const [route, setRoute] = React.useState(t.startInApp ? 'home' : 'onboarding');
  const [switcherOpen, setSwitcherOpen] = React.useState(false);

  // React to startInApp tweak changes
  React.useEffect(() => {
    if (t.startInApp && route === 'onboarding') {
      setPets(SEED_PETS);
      setActiveId(SEED_PETS[0].id);
      setRoute('home');
    } else if (!t.startInApp && route === 'home' && pets.length === SEED_PETS.length && pets[0].id === 'luna') {
      setPets([]);
      setActiveId(null);
      setRoute('onboarding');
    }
  }, [t.startInApp]);

  const handleOnboardingComplete = (draft) => {
    const sp = SPECIES.find(s => s.id === draft.species);
    const newPet = {
      id: 'new_' + Date.now(),
      name: draft.name || 'My pet',
      species: draft.species,
      breed: (draft.breed && !draft.breed.startsWith("Don't")) ? draft.breed : sp?.label || 'Pet',
      accent: sp?.accent || TOKENS.blue500,
      tint: sp?.tint || TOKENS.blue50,
      age: 'New',
      healthStreak: 1,
      lastSeen: 'just joined',
      badge: 'Complete profile',
      photoUrl: draft.photo,
    };
    const combined = [newPet, ...SEED_PETS];
    setPets(combined);
    setActiveId(newPet.id);
    setRoute('home');
  };

  const openSwitcher = () => setSwitcherOpen(true);
  const closeSwitcher = () => setSwitcherOpen(false);
  const pickPet = (id) => { setActiveId(id); setTimeout(closeSwitcher, 220); };
  const addPet = () => { closeSwitcher(); setTimeout(() => setRoute('add'), 240); };

  const screen = (
    <div style={{ position: 'relative', height: '100%', width: '100%', overflow: 'hidden' }}>
      {route === 'onboarding' && <Onboarding onComplete={handleOnboardingComplete} />}
      {route === 'add' && (
        <Onboarding onComplete={(draft) => {
          const sp = SPECIES.find(s => s.id === draft.species);
          const newPet = {
            id: 'new_' + Date.now(),
            name: draft.name || 'My pet',
            species: draft.species,
            breed: (draft.breed && !draft.breed.startsWith("Don't")) ? draft.breed : sp?.label || 'Pet',
            accent: sp?.accent || TOKENS.blue500,
            tint: sp?.tint || TOKENS.blue50,
            age: 'New', healthStreak: 1, lastSeen: 'just joined',
            badge: 'Complete profile', photoUrl: draft.photo,
          };
          setPets(p => [newPet, ...p]);
          setActiveId(newPet.id);
          setRoute('home');
        }} />
      )}
      {route === 'shop' && (
        <>
          <Shop
            active={pets.find(p => p.id === activeId) || pets[0]}
            onBack={() => setRoute('home')}
            onOpenSwitcher={openSwitcher}
            onOpenProduct={(p) => { window.__checkoutProduct = p; setRoute('checkout'); }}
            outdoor={t.outdoor}
            onTab={(id) => {
              if (id === 'home') setRoute('home');
              else if (id === 'health') setRoute('health');
              else if (id === 'feed') setRoute('social');
              else if (id === 'match') setRoute('discovery');
            }}
          />
          <PetSwitcher open={switcherOpen} pets={pets} activeId={activeId}
            onClose={closeSwitcher} onPick={pickPet} onAdd={addPet}
            glass={t.glass} outdoor={t.outdoor} sheetHeight={t.sheetHeight + '%'}/>
        </>
      )}
      {route === 'checkout' && (
        <>
          <Shop
            active={pets.find(p => p.id === activeId) || pets[0]}
            onBack={() => setRoute('home')}
            onOpenSwitcher={openSwitcher}
            onOpenProduct={() => {}}
            outdoor={t.outdoor}
            onTab={() => {}}
          />
          <Checkout
            product={window.__checkoutProduct || PRODUCTS[0]}
            active={pets.find(p => p.id === activeId) || pets[0]}
            onClose={() => setRoute('shop')}
            outdoor={t.outdoor}
          />
        </>
      )}
      {route === 'social' && (
        <>
          <SocialFeed
            active={pets.find(p => p.id === activeId) || pets[0]}
            onBack={() => setRoute('home')}
            onOpenSwitcher={openSwitcher}
            outdoor={t.outdoor}
            onTab={(id) => {
              if (id === 'home') setRoute('home');
              else if (id === 'health') setRoute('health');
              else if (id === 'match') setRoute('discovery');
              else if (id !== 'feed') setRoute('home');
            }}
          />
          <PetSwitcher open={switcherOpen} pets={pets} activeId={activeId}
            onClose={closeSwitcher} onPick={pickPet} onAdd={addPet}
            glass={t.glass} outdoor={t.outdoor} sheetHeight={t.sheetHeight + '%'}/>
        </>
      )}
      {route === 'discovery' && (
        <>
          <Discovery
            active={pets.find(p => p.id === activeId) || pets[0]}
            onBack={() => setRoute('home')}
            onOpenSwitcher={openSwitcher}
            outdoor={t.outdoor}
            onTab={(id) => {
              if (id === 'home') setRoute('home');
              else if (id === 'health') setRoute('health');
              else if (id === 'feed') setRoute('social');
              else if (id !== 'match') setRoute('home');
              if (id === 'shop') setRoute('shop');
            }}
          />
          <PetSwitcher open={switcherOpen} pets={pets} activeId={activeId}
            onClose={closeSwitcher} onPick={pickPet} onAdd={addPet}
            glass={t.glass} outdoor={t.outdoor} sheetHeight={t.sheetHeight + '%'}/>
        </>
      )}
      {route === 'health' && (
        <>
          <HealthDashboard
            active={pets.find(p => p.id === activeId) || pets[0]}
            onBack={() => setRoute('home')}
            onOpenSwitcher={openSwitcher}
            outdoor={t.outdoor}
            onOutdoor={() => setTweak('outdoor', !t.outdoor)}
            onTab={(id) => {
              if (id === 'home') setRoute('home');
              else if (id === 'feed') setRoute('social');
              else if (id === 'match') setRoute('discovery');
              else if (id !== 'health') setRoute('home');
            }}
          />
          <PetSwitcher
            open={switcherOpen} pets={pets} activeId={activeId}
            onClose={closeSwitcher} onPick={pickPet} onAdd={addPet}
            glass={t.glass} outdoor={t.outdoor}
            sheetHeight={t.sheetHeight + '%'}
          />
        </>
      )}
      {route === 'home' && (
        <>
          <Home
            pets={pets} activeId={activeId}
            onOpenSwitcher={openSwitcher}
            onOpenAdd={addPet}
            outdoor={t.outdoor}
            onOutdoor={() => setTweak('outdoor', !t.outdoor)}
            onTab={(id) => {
              if (id === 'health') setRoute('health');
              else if (id === 'feed') setRoute('social');
              else if (id === 'match') setRoute('discovery');
              else if (id === 'shop') setRoute('shop');
            }}
          />
          <PetSwitcher
            open={switcherOpen} pets={pets} activeId={activeId}
            onClose={closeSwitcher} onPick={pickPet} onAdd={addPet}
            glass={t.glass} outdoor={t.outdoor}
            sheetHeight={t.sheetHeight + '%'}
          />
        </>
      )}
    </div>
  );

  return (
    <div style={{
      minHeight: '100vh', width: '100%',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      background: 'radial-gradient(ellipse at 50% 0%, #E8EEF7 0%, #DFE6F1 100%)',
      padding: '24px 0',
      fontFamily: 'Inter, system-ui, sans-serif',
    }}>
      <IOSDevice width={390} height={844}>
        {screen}
      </IOSDevice>

      <TweaksPanel>
        <TweakSection label="Flow" />
        <TweakToggle label="Skip onboarding" value={t.startInApp}
                     onChange={(v) => setTweak('startInApp', v)} />
        <TweakButton label="Restart onboarding" onClick={() => {
          setPets([]); setActiveId(null); setRoute('onboarding');
          setTweak('startInApp', false);
        }} />
        <TweakButton label="Open pet switcher" onClick={openSwitcher} />
        <TweakButton label="Open Health dashboard" onClick={() => { if (pets.length === 0) { setPets(SEED_PETS); setActiveId(SEED_PETS[0].id); } if (!t.startInApp) setTweak('startInApp', true); setRoute('health'); }} />
        <TweakButton label="Open Social feed" onClick={() => { if (pets.length === 0) { setPets(SEED_PETS); setActiveId(SEED_PETS[0].id); } if (!t.startInApp) setTweak('startInApp', true); setRoute('social'); }} />
        <TweakButton label="Open Discovery" onClick={() => { if (pets.length === 0) { setPets(SEED_PETS); setActiveId(SEED_PETS[0].id); } if (!t.startInApp) setTweak('startInApp', true); setRoute('discovery'); }} />
        <TweakButton label="Open Marketplace" onClick={() => { if (pets.length === 0) { setPets(SEED_PETS); setActiveId(SEED_PETS[0].id); } if (!t.startInApp) setTweak('startInApp', true); setRoute('shop'); }} />
        <TweakButton label="Open Checkout" onClick={() => { if (pets.length === 0) { setPets(SEED_PETS); setActiveId(SEED_PETS[0].id); } if (!t.startInApp) setTweak('startInApp', true); window.__checkoutProduct = PRODUCTS[0]; setRoute('checkout'); }} />
        <TweakButton label="Back to Home" onClick={() => setRoute('home')} />

        <TweakSection label="Pet switcher" />
        <TweakToggle label="Glassmorphism" value={t.glass}
                     onChange={(v) => setTweak('glass', v)} />
        <TweakSlider label="Sheet height" value={t.sheetHeight} min={55} max={92} unit="%"
                     onChange={(v) => setTweak('sheetHeight', v)} />

        <TweakSection label="Accessibility" />
        <TweakToggle label="Outdoor mode" value={t.outdoor}
                     onChange={(v) => setTweak('outdoor', v)} />
      </TweaksPanel>
    </div>
  );
}

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "startInApp": false,
  "glass": true,
  "sheetHeight": 78,
  "outdoor": false
}/*EDITMODE-END*/;

Object.assign(window, { App, TWEAK_DEFAULTS });

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
