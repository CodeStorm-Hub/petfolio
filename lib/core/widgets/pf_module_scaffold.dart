import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petfolio/core/providers/shell_scroll_provider.dart';
import 'package:petfolio/core/theme/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Layout constants
// ─────────────────────────────────────────────────────────────────────────────

/// Height of the [AppShellHeader] overlay (below the status bar).
const double kShellHeaderHeight = 76.0;

/// Computes the full [SliverAppBar] expandedHeight for a module hero.
///
/// Pass [contentHeight] as the visible hero area *below* the AppShellHeader.
/// Adds the status-bar inset automatically.
double pfHeroHeight(BuildContext context, double contentHeight) =>
    MediaQuery.paddingOf(context).top + kShellHeaderHeight + contentHeight;

// ─────────────────────────────────────────────────────────────────────────────
// PfModuleScaffold
// ─────────────────────────────────────────────────────────────────────────────

/// Global layout scaffold shared by all core module home screens.
///
/// Wraps content in a [CustomScrollView] with:
/// - A collapsing [SliverAppBar] hero (wave / greeting / stat strip).
/// - An optional pinned sticky bar (tab bar or chip row).
/// - Caller-supplied body slivers.
/// - Responsive max-width centering (640dp on medium, 960dp on expanded).
/// - Automatic scroll-progress forwarding to [homeScrollProgressProvider] so
///   [AppShellHeader] animates its blur and background colour on every screen.
///
/// Compute [expandedHeight] using the [pfHeroHeight] helper:
/// ```dart
/// expandedHeight: pfHeroHeight(context, 140),
/// ```
class PfModuleScaffold extends ConsumerStatefulWidget {
  const PfModuleScaffold({
    super.key,
    this.heroContent,
    this.expandedHeight,
    required this.slivers,
    this.stickyBar,
    this.backgroundColor,
    this.scrollController,
    this.onScrollProgress,
    this.floatingActionButton,
    this.scrollThreshold = 90.0,
    this.physics,
  }) : assert(
          (heroContent == null) == (expandedHeight == null),
          'Provide both heroContent and expandedHeight, or neither.',
        );

  /// Self-contained hero widget rendered inside the collapsing [SliverAppBar].
  /// Must include its own top-padding for the AppShellHeader area.
  /// When null, no [SliverAppBar] is added — include the hero as the first
  /// entry in [slivers] instead (for heroes with dynamic / intrinsic heights).
  final Widget? heroContent;

  /// Body slivers placed below the hero (and optional sticky bar).
  final List<Widget> slivers;

  /// Full [SliverAppBar.expandedHeight] — use [pfHeroHeight] to compute.
  /// Required when [heroContent] is provided; must be null otherwise.
  final double? expandedHeight;

  /// Optional [PreferredSizeWidget] pinned between the collapsed hero and the
  /// body — ideal for module tab bars and filter chip rows.
  final PreferredSizeWidget? stickyBar;

  /// Scaffold background color. Defaults to [PetfolioThemeExtension.surface1].
  final Color? backgroundColor;

  /// External scroll controller. A new one is created internally when null.
  final ScrollController? scrollController;

  /// Called with scroll progress [0.0–1.0] on every frame while scrolling.
  final ValueChanged<double>? onScrollProgress;

  final Widget? floatingActionButton;

  /// Pixel offset at which scroll progress reaches 1.0.
  /// Matches the threshold used by [HubHomeScreen] (90dp).
  final double scrollThreshold;

  final ScrollPhysics? physics;

  @override
  ConsumerState<PfModuleScaffold> createState() => _PfModuleScaffoldState();
}

class _PfModuleScaffoldState extends ConsumerState<PfModuleScaffold> {
  late final ScrollController _scrollCtrl;
  late final bool _owns;

  @override
  void initState() {
    super.initState();
    _owns = widget.scrollController == null;
    _scrollCtrl =
        _owns ? ScrollController() : widget.scrollController!;
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final progress =
        (_scrollCtrl.offset / widget.scrollThreshold).clamp(0.0, 1.0);
    ref.read(homeScrollProgressProvider.notifier).set(progress);
    widget.onScrollProgress?.call(progress);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    if (_owns) _scrollCtrl.dispose();
    ref.read(homeScrollProgressProvider.notifier).set(0.0);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;
    final isExpanded = width >= 840;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    // Slightly taller hero on larger screens for better proportions.
    final base = widget.expandedHeight;
    final effectiveExpandedHeight = base == null
        ? null
        : isExpanded
            ? base + 40
            : isWide
                ? base + 20
                : base;

    final bgColor = widget.backgroundColor ?? pt.surface1;

    Widget scrollView = CustomScrollView(
      controller: _scrollCtrl,
      physics: widget.physics ??
          const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
      slivers: [
        // ── Collapsing hero (optional) ───────────────────────────────────
        // toolbarHeight: 0 means the bar fully disappears on collapse,
        // leaving only the AppShellHeader overlay visible.
        // When heroContent is null the caller places the hero in [slivers].
        if (widget.heroContent != null)
          SliverAppBar(
            pinned: false,
            floating: false,
            snap: false,
            toolbarHeight: 0,
            expandedHeight: effectiveExpandedHeight!,
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            automaticallyImplyLeading: false,
            clipBehavior: Clip.none,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.heroContent,
              collapseMode: CollapseMode.parallax,
              stretchModes: const [],
            ),
          ),

        // ── Optional sticky bar (tabs / filter chips) ────────────────────
        if (widget.stickyBar != null)
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyBarDelegate(
              bar: widget.stickyBar!,
              bgColor: bgColor,
            ),
          ),

        // ── Module body slivers ──────────────────────────────────────────
        ...widget.slivers,

        // ── Bottom clearance: floating nav (68) + padding + buffer ───────
        SliverToBoxAdapter(
          child: SizedBox(height: 100 + bottomPad),
        ),
      ],
    );

    // Centre content with max-width on medium / expanded screens.
    if (isWide) {
      scrollView = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isExpanded ? 960.0 : 640.0),
          child: scrollView,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: widget.floatingActionButton,
      body: scrollView,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StickyBarDelegate
// ─────────────────────────────────────────────────────────────────────────────

class _StickyBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyBarDelegate({
    required this.bar,
    required this.bgColor,
  });

  final PreferredSizeWidget bar;
  final Color bgColor;

  @override
  double get minExtent => bar.preferredSize.height + 0.5;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: bgColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bar,
          const Divider(height: 0.5, thickness: 0.5),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyBarDelegate old) =>
      old.bar != bar || old.bgColor != bgColor;
}
