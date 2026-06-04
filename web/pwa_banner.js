(function () {
  'use strict';

  // Only show on iOS Safari that is NOT already installed as a PWA
  var isIos = /iphone|ipad|ipod/i.test(navigator.userAgent);
  var isInStandalone = ('standalone' in navigator) && navigator.standalone;
  var dismissed = localStorage.getItem('pwa_banner_dismissed');

  if (!isIos || isInStandalone || dismissed) return;

  // Inject styles
  var style = document.createElement('style');
  style.textContent = [
    '#pwa-banner{',
      'position:fixed;bottom:0;left:0;right:0;z-index:99999;',
      'background:#fff;color:#1a1014;',
      'border-radius:20px 20px 0 0;',
      'box-shadow:0 -4px 24px rgba(0,0,0,.15);',
      'padding:16px 20px 32px;',
      'font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;',
      'display:flex;align-items:flex-start;gap:14px;',
      'animation:slideUp .35s cubic-bezier(.16,1,.3,1) both;',
    '}',
    '@keyframes slideUp{from{transform:translateY(100%)}to{transform:translateY(0)}}',
    '#pwa-banner img{width:56px;height:56px;border-radius:13px;flex-shrink:0;box-shadow:0 2px 8px rgba(0,0,0,.18);}',
    '#pwa-banner-body{flex:1;}',
    '#pwa-banner-title{font-size:15px;font-weight:700;margin:0 0 4px;}',
    '#pwa-banner-desc{font-size:13px;color:#555;margin:0 0 12px;line-height:1.45;}',
    '#pwa-banner-steps{font-size:12.5px;color:#333;line-height:1.6;margin:0;}',
    '#pwa-banner-steps span{background:#f0f0f0;border-radius:6px;padding:1px 6px;font-weight:600;}',
    '#pwa-banner-close{',
      'position:absolute;top:14px;right:16px;',
      'background:none;border:none;cursor:pointer;',
      'font-size:20px;color:#999;line-height:1;padding:4px;',
    '}',
    '@media(prefers-color-scheme:dark){',
      '#pwa-banner{background:#1a1014;color:#fff;}',
      '#pwa-banner-desc{color:#aaa;}',
      '#pwa-banner-steps{color:#ddd;}',
      '#pwa-banner-steps span{background:#333;}',
      '#pwa-banner-close{color:#666;}',
    '}',
  ].join('');
  document.head.appendChild(style);

  // Build banner HTML
  var banner = document.createElement('div');
  banner.id = 'pwa-banner';
  banner.setAttribute('role', 'banner');
  banner.innerHTML = [
    '<img src="icons/Icon-192.png" alt="PetFolio icon">',
    '<div id="pwa-banner-body">',
      '<p id="pwa-banner-title">Install PetFolio</p>',
      '<p id="pwa-banner-desc">Add to your Home Screen for the full app experience — works offline too.</p>',
      '<p id="pwa-banner-steps">',
        'Tap <span>Share ↑</span> then <span>Add to Home Screen</span>',
      '</p>',
    '</div>',
    '<button id="pwa-banner-close" aria-label="Dismiss">✕</button>',
  ].join('');

  document.body.appendChild(banner);

  document.getElementById('pwa-banner-close').addEventListener('click', function () {
    try { localStorage.setItem('pwa_banner_dismissed', '1'); } catch (_) {}
    banner.style.animation = 'slideUp .25s cubic-bezier(.16,1,.3,1) reverse both';
    setTimeout(function () { banner.remove(); }, 280);
  });
}());
