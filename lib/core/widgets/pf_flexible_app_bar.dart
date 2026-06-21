import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// M3 Expressive large-flexible app bar — a [SliverAppBar] preconfigured
/// with a large collapsing title, an optional subtitle shown only while
/// expanded, and the app's standard back affordance.
///
/// Drop into the `slivers` list of a [CustomScrollView] in place of a plain
/// [AppBar] on detail screens (pet profile, vet clinic, product detail).
class PfFlexibleAppBar extends StatelessWidget {
  const PfFlexibleAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.background,
    this.expandedHeight = 140,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final Widget? background;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;

    return SliverAppBar(
      pinned: true,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: expandedHeight,
      leading: IconButton(
        tooltip: 'Back',
        icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      ),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16, end: 16),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        background: background ??
            (subtitle == null
                ? null
                : Padding(
                    padding: const EdgeInsetsDirectional.only(start: 56, end: 56, top: 56),
                    child: Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 48),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pt.ink500),
                        ),
                      ),
                    ),
                  )),
      ),
    );
  }
}
