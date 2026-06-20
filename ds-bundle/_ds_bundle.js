/* @ds-bundle petfolio 1.0.0
 * sourceHash: petfolio-2026-06-19
 * Components: PfCard, GlassCard, PrimaryPillButton, PawToggle,
 *             PetAvatar, SectionHeader, PfStatTile, PfBadgeTile,
 *             PfDailyQuestRow, SkeletonLoader, PetfolioEmptyState,
 *             TailWagLoader
 */
(function (exports) {
  'use strict';
  var R = window.React;
  var h = R.createElement;

  // ── PfCard ───────────────────────────────────────────────────────────────
  function PfCard(props) {
    var p = props.padding !== undefined ? props.padding : 16;
    var r = props.borderRadius !== undefined ? props.borderRadius : 24;
    var elevated = props.elevated;
    var flat = props.flat;
    var cls = 'pf-card' +
      (elevated ? ' pf-card--elevated' : '') +
      (flat ? ' pf-card--flat' : '') +
      (props.className ? ' ' + props.className : '');
    return h('div', {
      className: cls,
      style: Object.assign({
        backgroundColor: props.backgroundColor,
        padding: typeof p === 'number' ? p + 'px' : p,
        borderRadius: typeof r === 'number' ? r + 'px' : r,
      }, props.style),
      'aria-label': props.semanticLabel,
    }, props.children);
  }

  // ── GlassCard ────────────────────────────────────────────────────────────
  function GlassCard(props) {
    var r = props.borderRadius !== undefined ? props.borderRadius : 20;
    return h('div', {
      className: 'pf-glass-card' + (props.className ? ' ' + props.className : ''),
      style: Object.assign({ borderRadius: r + 'px' }, props.style),
      'aria-label': props.semanticLabel,
    }, props.children);
  }

  // ── PrimaryPillButton ────────────────────────────────────────────────────
  function PrimaryPillButton(props) {
    var size = props.size || 'lg';
    var variant = props.variant || 'primary';
    var isLoading = props.isLoading;
    var isFullWidth = props.isFullWidth;
    var cls = [
      'pf-btn',
      'pf-btn--' + size,
      'pf-btn--' + variant,
      isFullWidth ? 'pf-btn--full' : '',
      props.className || '',
    ].filter(Boolean).join(' ');

    var customStyle = {};
    if (props.color) {
      customStyle.backgroundColor = props.color;
      customStyle.color = '#fff';
    }

    return h('button', {
      className: cls,
      disabled: !props.onPress && !isLoading,
      onClick: props.onPress,
      style: Object.assign(customStyle, props.style),
      'aria-label': props.label,
      'aria-busy': isLoading || undefined,
    },
      isLoading
        ? h('span', { className: 'pf-btn__spinner' })
        : [
            props.leadingIcon && h('span', { key: 'li', className: 'pf-btn__icon' }, props.leadingIcon),
            h('span', { key: 'lbl' }, props.label),
            props.trailingIcon && h('span', { key: 'ti', className: 'pf-btn__icon' }, props.trailingIcon),
          ]
    );
  }

  // ── PawToggle ────────────────────────────────────────────────────────────
  function PawToggle(props) {
    var active = !!props.value;
    return h('div', {
      className: 'pf-toggle' + (active ? ' pf-toggle--on' : ''),
      role: 'switch',
      'aria-checked': active,
      'aria-label': props.semanticLabel || 'Toggle',
      tabIndex: 0,
      onClick: function () { if (props.onChanged) props.onChanged(!active); },
      onKeyDown: function (e) {
        if (e.key === ' ' || e.key === 'Enter') {
          e.preventDefault();
          if (props.onChanged) props.onChanged(!active);
        }
      },
      style: props.activeColor ? { '--pf-toggle-color': props.activeColor } : undefined,
    },
      h('div', { className: 'pf-toggle__thumb' }, '🐾')
    );
  }

  // ── PetAvatar ────────────────────────────────────────────────────────────
  var SPECIES_CLASS = {
    dog:    'pf-avatar__disc--dog',
    cat:    'pf-avatar__disc--cat',
    bird:   'pf-avatar__disc--bird',
    rabbit: 'pf-avatar__disc--rabbit',
  };
  var SPECIES_EMOJI = {
    dog: '🐶', cat: '🐱', bird: '🐦', rabbit: '🐰',
  };

  function PetAvatar(props) {
    var size = props.size || 'md';
    var species = props.species || 'dog';
    var showRing = props.showRing;
    var isOnline = props.isOnline;

    var innerContent;
    if (props.imageUrl) {
      innerContent = h('img', {
        src: props.imageUrl,
        alt: props.semanticLabel || '',
        className: 'pf-avatar__img',
      });
    } else {
      var emoji = SPECIES_EMOJI[species] || '🐾';
      if (props.initials) {
        innerContent = h('div', {
          className: 'pf-avatar__disc ' + (SPECIES_CLASS[species] || 'pf-avatar__disc--other'),
          style: { fontSize: 'calc(var(--avatar-d, 40px) * 0.35)', fontWeight: 800, color: '#fff' },
        }, props.initials.substring(0, 2).toUpperCase());
      } else {
        innerContent = h('div', {
          className: 'pf-avatar__disc ' + (SPECIES_CLASS[species] || 'pf-avatar__disc--other'),
        }, emoji);
      }
    }

    var statusDot = isOnline !== undefined
      ? h('span', {
          key: 'dot',
          className: 'pf-avatar__status ' + (isOnline ? 'pf-avatar__status--online' : 'pf-avatar__status--offline'),
          style: { width: '25%', height: '25%', bottom: 0, right: 0 },
        })
      : null;

    var avatarEl = h('div', {
      className: 'pf-avatar pf-avatar--' + size + (props.className ? ' ' + props.className : ''),
      style: props.style,
      'aria-label': props.semanticLabel,
    }, innerContent, statusDot);

    if (showRing) {
      return h('div', { className: 'pf-avatar--ring', style: { display: 'inline-flex', borderRadius: '50%' } },
        h('div', { className: 'pf-avatar__inner' }, avatarEl)
      );
    }
    return avatarEl;
  }

  // ── SectionHeader ────────────────────────────────────────────────────────
  function SectionHeader(props) {
    return h('div', { className: 'pf-section-header' + (props.className ? ' ' + props.className : '') },
      h('span', { className: 'pf-section-header__label' }, props.label),
      props.action || null
    );
  }

  // ── PfStatTile ───────────────────────────────────────────────────────────
  function PfStatTile(props) {
    return h('div', {
      className: 'pf-stat-tile' + (props.className ? ' ' + props.className : ''),
      style: Object.assign({ backgroundColor: props.backgroundColor }, props.style),
    },
      h('div', { className: 'pf-stat-tile__icon', style: { color: props.textColor } }, props.icon),
      h('div', { className: 'pf-stat-tile__value' }, props.value),
      h('div', { className: 'pf-stat-tile__label', style: { color: props.textColor } }, props.label)
    );
  }

  // ── PfBadgeTile ──────────────────────────────────────────────────────────
  function PfBadgeTile(props) {
    var owned = props.owned !== false;
    return h('div', { className: 'pf-badge-tile' + (props.className ? ' ' + props.className : '') },
      h('div', {
        className: 'pf-badge-tile__icon' + (owned ? ' pf-badge-tile__icon--owned' : ' pf-badge-tile__icon--locked'),
        style: owned ? {
          background: 'linear-gradient(135deg, ' + (props.color || '#FF8A4C') + ', ' + lighten(props.color || '#FF8A4C', 0.3) + ')',
          '--badge-color': props.color || '#FF8A4C',
        } : {},
      }, props.emoji),
      h('div', { className: 'pf-badge-tile__label' }, props.label)
    );
  }
  function lighten(hex, amount) {
    var r = parseInt(hex.slice(1,3),16);
    var g = parseInt(hex.slice(3,5),16);
    var b = parseInt(hex.slice(5,7),16);
    r = Math.min(255, Math.round(r + (255-r)*amount));
    g = Math.min(255, Math.round(g + (255-g)*amount));
    b = Math.min(255, Math.round(b + (255-b)*amount));
    return '#' + [r,g,b].map(function(v){return v.toString(16).padStart(2,'0');}).join('');
  }

  // ── PfDailyQuestRow ──────────────────────────────────────────────────────
  function PfDailyQuestRow(props) {
    var done = !!props.done;
    var due = !!props.due;
    var iconBg = done ? 'var(--pf-mint-soft)' : due ? 'var(--pf-poppy-soft)' : 'var(--pf-cream2)';
    return h('div', { className: 'pf-quest-row' + (props.className ? ' ' + props.className : '') },
      h('div', { className: 'pf-quest-row__icon-box', style: { backgroundColor: iconBg } },
        done ? '✅' : props.icon
      ),
      h('div', { style: { flex: 1 } },
        h('div', { className: 'pf-quest-row__label' + (done ? ' pf-quest-row__label--done' : '') }, props.label),
        h('div', { className: 'pf-quest-row__time' + (due ? ' pf-quest-row__time--due' : '') },
          due ? 'Due ' + props.time : props.time
        )
      ),
      h('div', {
        className: 'pf-quest-row__xp',
        style: {
          backgroundColor: done ? 'var(--pf-mint-soft)' : 'var(--pf-sunny-soft)',
          color: done ? 'var(--pf-mint-700)' : 'var(--pf-sunny-700)',
        },
      }, '+' + props.xp, ' ⭐')
    );
  }

  // ── SkeletonLoader ────────────────────────────────────────────────────────
  function SkeletonLoader(props) {
    var shape = props.shape || 'rect';
    var cls = 'pf-skeleton' + (shape === 'circle' ? ' pf-skeleton--circle' : '');
    return h('div', {
      className: cls + (props.className ? ' ' + props.className : ''),
      style: Object.assign({
        width: props.width === 'full' ? '100%' : (typeof props.width === 'number' ? props.width + 'px' : props.width),
        height: typeof props.height === 'number' ? props.height + 'px' : props.height,
        borderRadius: props.borderRadius !== undefined
          ? (typeof props.borderRadius === 'number' ? props.borderRadius + 'px' : props.borderRadius)
          : undefined,
      }, props.style),
      'aria-hidden': 'true',
    });
  }

  // ── PetfolioEmptyState ───────────────────────────────────────────────────
  function PetfolioEmptyState(props) {
    return h('div', {
      className: 'pf-empty-state' + (props.className ? ' ' + props.className : ''),
      role: 'status',
      'aria-label': props.subtitle ? props.title + '. ' + props.subtitle : props.title,
    },
      h('div', { className: 'pf-empty-state__icon', 'aria-hidden': 'true' },
        props.icon || '🐾'
      ),
      h('div', { className: 'pf-empty-state__title' }, props.title),
      props.subtitle && h('div', { className: 'pf-empty-state__subtitle' }, props.subtitle),
      props.action && h('div', { className: 'pf-empty-state__action', style: { marginTop: '20px' } }, props.action)
    );
  }

  // ── TailWagLoader ─────────────────────────────────────────────────────────
  function TailWagLoader(props) {
    var size = props.size || 64;
    var color = props.color || '#FF8A4C';
    return h('div', { className: 'pf-tail-loader' + (props.className ? ' ' + props.className : '') },
      h('svg', {
        width: size, height: size, viewBox: '0 0 64 64',
        'aria-label': props.label || 'Loading',
        role: 'img',
      },
        // Body
        h('ellipse', { cx: 32, cy: 36, rx: 14, ry: 9.5, fill: color }),
        // Head
        h('circle', { cx: 43.5, cy: 26.5, r: 11, fill: color }),
        // Left ear
        h('path', { d: 'M36 20 Q33 10 37 8 Q40 10 39 20Z', fill: color, opacity: 0.85 }),
        // Right ear
        h('path', { d: 'M51 20 Q54 10 50 8 Q47 10 48 20Z', fill: color, opacity: 0.85 }),
        // Eye
        h('circle', { cx: 47.5, cy: 25, r: 1.8, fill: '#1a1a1a' }),
        h('circle', { cx: 48, cy: 24.5, r: 0.6, fill: '#fff' }),
        // Nose
        h('ellipse', { cx: 52.5, cy: 29, rx: 2, ry: 1.4, fill: '#1a1a1a' }),
        // Legs
        h('rect', { x: 20, y: 43, width: 5, height: 10, rx: 2.5, fill: color }),
        h('rect', { x: 27, y: 43, width: 5, height: 10, rx: 2.5, fill: color }),
        h('rect', { x: 34, y: 43, width: 5, height: 10, rx: 2.5, fill: color }),
        h('rect', { x: 41, y: 43, width: 5, height: 10, rx: 2.5, fill: color }),
        // Tail (animated via CSS)
        h('g', { style: { transformOrigin: '18px 34px', animation: 'pf-tail-wag 500ms ease-in-out infinite alternate' } },
          h('path', { d: 'M19 34 Q14 24 16 18 Q18 12 19.5 18 Q17 24 21 34Z', fill: color })
        ),
        // Belly patch
        h('ellipse', { cx: 33, cy: 39, rx: 8, ry: 4.5, fill: color, opacity: 0.25 })
      ),
      props.label && h('div', { className: 'pf-tail-loader__label', style: { color: color } }, props.label)
    );
  }

  // ── Exports ───────────────────────────────────────────────────────────────
  exports.PfCard             = PfCard;
  exports.GlassCard          = GlassCard;
  exports.PrimaryPillButton  = PrimaryPillButton;
  exports.PawToggle          = PawToggle;
  exports.PetAvatar          = PetAvatar;
  exports.SectionHeader      = SectionHeader;
  exports.PfStatTile         = PfStatTile;
  exports.PfBadgeTile        = PfBadgeTile;
  exports.PfDailyQuestRow    = PfDailyQuestRow;
  exports.SkeletonLoader     = SkeletonLoader;
  exports.PetfolioEmptyState = PetfolioEmptyState;
  exports.TailWagLoader      = TailWagLoader;

})(window.petfolio = window.petfolio || {});
