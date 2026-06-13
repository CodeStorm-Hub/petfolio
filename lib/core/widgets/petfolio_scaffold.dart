import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shell_scroll_provider.dart';
import '../theme/app_theme.dart';

// ── Layout constants ──────────────────────────────────────────────────────────

/// Height of the collapsed app bar (below the device status bar).
/// Matches the legacy AppShellHeader height (topPad + 76 total) so that
/// screens transitioning from the floating header keep consistent sizing.
const kPetfolioToolbarHeight = 76.0;

/// Bottom padding added automatically to clear the floating nav pill.
const kPetfolioNavClearance = 92.0;

// ── PetfolioScaffold ──────────────────────────────────────────────────────────

/// Global layout for all Petfolio core-module screens.
///
/// Two construction modes:
///
/// **Slivers mode** (default) — for screens that already render a
/// [CustomScrollView]. Provides a pinned M3 [SliverAppBar] that can expand
/// into a wave/hero section, followed by [slivers].
///
/// ```dart
/// PetfolioScaffold(
///   accentColor: AppColors.sunny,
///   expandedHeight: kPetfolioToolbarHeight + 144,
///   heroContent: WaveHeader(color: AppColors.sunny, child: greeting),
///   leading: _ModuleLeading(label: 'CARE'),
///   actions: [IconButton(...)],
///   slivers: [SliverToBoxAdapter(child: body)],
/// )
/// ```
///
/// **Body mode** — for screens with an existing [ListView] / [Column] body.
/// Renders a standard [AppBar] (M3-compliant, `scrolledUnderElevation` wired)
/// with the existing body unchanged.
///
/// ```dart
/// PetfolioScaffold.withBody(
///   accentColor: AppColors.mint,
///   leading: _ModuleLeading(label: 'MARKET'),
///   actions: [_CartButton()],
///   body: ListView(children: [...]),
/// )
/// ```
///
/// In both modes the widget signals [shellHeaderVisibleProvider] = false while
/// mounted, hiding [AppShellHeader] in [AppShell] to prevent a double header.
class PetfolioScaffold extends ConsumerStatefulWidget {
  /// Slivers mode: [CustomScrollView] + [SliverAppBar].
  const PetfolioScaffold({
    super.key,
    required List<Widget> slivers,
    this.accentColor,
    this.expandedHeight,
    this.heroContent,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.scrollController,
    this.floatingActionButton,
    this.onRefresh,
    this.physics,
  })  : _slivers = slivers,
        _body = null;

  /// Body mode: standard [Scaffold] + [AppBar].
  const PetfolioScaffold.withBody({
    super.key,
    required Widget body,
    this.accentColor,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.floatingActionButton,
    this.onRefresh,
  })  : _body = body,
        _slivers = null,
        expandedHeight = null,
        heroContent = null,
        scrollController = null,
        physics = null;

  // ── common ──────────────────────────────────────────────────────────────────

  /// Background color for the app bar (expanded + collapsed states).
  /// Defaults to [ColorScheme.primary].
  final Color? accentColor;

  /// Page title shown in the collapsed app bar.
  final Widget? title;

  /// Leading action widget. Should be at least 48×48 dp.
  /// Defaults to nothing (no automatic back button in shell screens).
  final Widget? leading;

  /// Trailing action widgets. Each should be an [IconButton] (≥48 dp).
  final List<Widget>? actions;

  /// [Scaffold] background. Defaults to [PetfolioThemeExtension.surface1].
  final Color? backgroundColor;

  /// Optional FAB forwarded to [Scaffold.floatingActionButton].
  final Widget? floatingActionButton;

  /// Pull-to-refresh callback. Wraps the scroll view in [RefreshIndicator].
  final Future<void> Function()? onRefresh;

  // ── slivers mode ────────────────────────────────────────────────────────────

  /// Height of the fully-expanded [SliverAppBar] **excluding** the device
  /// status bar (Flutter adds that automatically).
  ///
  /// When null or ≤ [kPetfolioToolbarHeight] no expansion occurs and the bar
  /// is a standard small pinned bar.
  final double? expandedHeight;

  /// Widget rendered as [FlexibleSpaceBar.background] when [expandedHeight] is
  /// set. Typically a [WaveHeader] containing greeting content.
  ///
  /// The widget fills the full [expandedHeight] area (including behind the
  /// toolbar). Offset content by [kPetfolioToolbarHeight] + status-bar padding
  /// to place it below the toolbar row.
  final Widget? heroContent;

  /// External [ScrollController] — pass when the parent needs scroll events.
  final ScrollController? scrollController;

  /// Scroll physics for the [CustomScrollView]. Defaults to
  /// [BouncingScrollPhysics] on all platforms (Petfolio brand feel).
  final ScrollPhysics? physics;

  // ── private ─────────────────────────────────────────────────────────────────

  final List<Widget>? _slivers;
  final Widget? _body;

  @override
  ConsumerState<PetfolioScaffold> createState() => _PetfolioScaffoldState();
}

class _PetfolioScaffoldState extends ConsumerState<PetfolioScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(shellHeaderVisibleProvider.notifier).set(false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(shellHeaderVisibleProvider.notifier).set(true);
      } catch (_) {}
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? cs.primary;
    final bg = widget.backgroundColor ?? pt.surface1;

    return widget._slivers != null
        ? _buildSliverMode(context, accent, bg)
        : _buildBodyMode(context, accent, bg);
  }

  // ── Slivers mode ────────────────────────────────────────────────────────────

  Widget _buildSliverMode(BuildContext context, Color accent, Color bg) {
    final isExpanding = widget.expandedHeight != null &&
        widget.expandedHeight! > kPetfolioToolbarHeight;

    Widget scrollView = CustomScrollView(
      controller: widget.scrollController,
      physics: widget.physics ??
          // Brand decision: BouncingScrollPhysics on all platforms (including
          // Android) for a premium, consistent feel. M3 default on Android is
          // ClampingScrollPhysics but this is an intentional brand deviation.
          const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
      slivers: [
        _buildSliverAppBar(accent, isExpanding),
        ...widget._slivers!,
        SliverToBoxAdapter(
          child: SizedBox(
            height:
                kPetfolioNavClearance + MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );

    if (widget.onRefresh != null) {
      scrollView = RefreshIndicator.adaptive(
        onRefresh: widget.onRefresh!,
        child: scrollView,
      );
    }

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: widget.floatingActionButton,
      body: scrollView,
    );
  }

  SliverAppBar _buildSliverAppBar(Color accent, bool isExpanding) {
    return SliverAppBar(
      pinned: true,
      stretch: isExpanding,
      floating: false,
      snap: false,
      toolbarHeight: kPetfolioToolbarHeight,
      expandedHeight: isExpanding ? widget.expandedHeight : null,
      // M3: elevation 0 at rest, 3dp shadow when scrolled under
      elevation: 0,
      scrolledUnderElevation: 3.0,
      shadowColor: Colors.black.withAlpha(40),
      backgroundColor: accent,
      foregroundColor: Colors.white,
      // Custom accent — no M3 surface tint overlay
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      leading: widget.leading != null
          ? Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: widget.leading,
            )
          : null,
      leadingWidth: widget.leading != null ? 180 : 0,
      title: widget.title,
      actions: widget.actions != null
          ? [...widget.actions!, const SizedBox(width: 6)]
          : null,
      flexibleSpace: isExpanding
          ? FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              stretchModes: const [StretchMode.zoomBackground],
              background: widget.heroContent,
            )
          : FlexibleSpaceBar(
              background: ColoredBox(color: accent),
            ),
    );
  }

  // ── Body mode ────────────────────────────────────────────────────────────────

  Widget _buildBodyMode(BuildContext context, Color accent, Color bg) {
    Widget body = widget._body!;

    if (widget.onRefresh != null) {
      body = RefreshIndicator.adaptive(
        onRefresh: widget.onRefresh!,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: widget.floatingActionButton,
      appBar: _PetfolioAppBar(
        accent: accent,
        leading: widget.leading,
        title: widget.title,
        actions: widget.actions,
      ),
      body: body,
    );
  }
}

// ── AppBar for body mode ──────────────────────────────────────────────────────

class _PetfolioAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PetfolioAppBar({
    required this.accent,
    this.leading,
    this.title,
    this.actions,
  });

  final Color accent;
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kPetfolioToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: kPetfolioToolbarHeight,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 3.0,
      shadowColor: Colors.black.withAlpha(40),
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      leadingWidth: leading != null ? 180 : 0,
      leading: leading != null
          ? Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: leading,
            )
          : null,
      title: title,
      actions: actions != null ? [...actions!, const SizedBox(width: 6)] : null,
    );
  }
}

// ── Shared leading widgets ────────────────────────────────────────────────────

/// Back-to-home breadcrumb for module screens (Care, Social, Matching, Market).
/// Shows "HOME" eyebrow + module name, taps navigate to /home.
class PfModuleLeading extends StatelessWidget {
  const PfModuleLeading({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'HOME',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon button for the app bar that respects the M3 48 dp minimum touch target.
class PfAppBarIconBtn extends StatelessWidget {
  const PfAppBarIconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  /// Optional badge count. Renders a [Badge] when > 0.
  final int? badge;

  @override
  Widget build(BuildContext context) {
    Widget btn = IconButton(
      icon: Icon(icon, color: Colors.white, size: 20),
      onPressed: onTap,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withAlpha(48),
        shape: const CircleBorder(),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );

    if (badge != null && badge! > 0) {
      btn = Badge(
        label: Text(badge! > 99 ? '99+' : '$badge'),
        child: btn,
      );
    }

    return btn;
  }
}
