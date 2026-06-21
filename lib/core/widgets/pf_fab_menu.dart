import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme/theme.dart';

/// M3 Expressive FAB menu — replaces the deprecated speed-dial / stacked
/// small-FAB pattern. A single FAB expands into a vertical column of labeled
/// action items with a spring-driven reveal, then a contrasting close button
/// takes its place while open.
///
/// Use whenever a surface needs more than one creation/logging action behind
/// one entry point (e.g. Care: log weight / medical / walk / reminder).
class PfFabMenu extends StatefulWidget {
  const PfFabMenu({
    super.key,
    required this.items,
    this.icon = Icons.add_rounded,
    this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
  });

  final List<PfFabMenuItem> items;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Object? heroTag;

  @override
  State<PfFabMenu> createState() => _PfFabMenuState();
}

class PfFabMenuItem {
  const PfFabMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
}

class _PfFabMenuState extends State<PfFabMenu> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PetfolioThemeExtension.durationLg,
  );
  bool _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.animateWith(
        SpringSimulation(PetfolioThemeExtension.spring, _controller.value, 1.0, 0.0),
      );
    } else {
      _controller.reverse();
    }
  }

  void _select(PfFabMenuItem item) {
    _toggle();
    item.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.backgroundColor ?? cs.primary;
    final fg = widget.foregroundColor ?? cs.onPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: _controller.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _controller.value.clamp(0.0, 1.2),
                  alignment: Alignment.bottomRight,
                  child: child,
                ),
              ),
              child: _MenuList(items: widget.items, onSelect: _select),
            ),
          ),
        AnimatedScale(
          scale: 1,
          duration: PetfolioThemeExtension.durationMd,
          curve: PetfolioThemeExtension.curveSpring,
          child: FloatingActionButton(
            heroTag: widget.heroTag,
            backgroundColor: bg,
            foregroundColor: fg,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(
                _open
                    ? PetfolioThemeExtension.radiusPill
                    : PetfolioThemeExtension.radius2xl,
              ),
            ),
            onPressed: _toggle,
            child: AnimatedRotation(
              turns: _open ? 0.125 : 0,
              duration: PetfolioThemeExtension.durationMd,
              curve: PetfolioThemeExtension.curveEmphasis,
              child: Icon(_open ? Icons.close_rounded : widget.icon),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList({required this.items, required this.onSelect});

  final List<PfFabMenuItem> items;
  final void Function(PfFabMenuItem item) onSelect;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _MenuRow(item: items[i], pt: pt, cs: cs, onSelect: onSelect),
        ],
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.pt,
    required this.cs,
    required this.onSelect,
  });

  final PfFabMenuItem item;
  final PetfolioThemeExtension pt;
  final ColorScheme cs;
  final void Function(PfFabMenuItem item) onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = item.color ?? cs.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(item),
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusPill),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: ShapeDecoration(
                  color: cs.surface,
                  shadows: pt.shadowE2,
                  shape: RoundedSuperellipseBorder(
                    borderRadius:
                        BorderRadius.circular(PetfolioThemeExtension.radiusPill),
                    side: BorderSide(color: pt.line),
                  ),
                ),
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: pt.ink950,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: ShapeDecoration(
                  color: accent,
                  shadows: pt.shadowE2,
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(PetfolioThemeExtension.radius2xl),
                    ),
                  ),
                ),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
