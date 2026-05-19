import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/lat_lng.dart';
import '../../../../core/services/location_providers.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../pet_profile/presentation/widgets/pet_switcher_sheet.dart';
import '../../data/models/discovery_candidate.dart';
import '../../data/models/pet_mutual_match.dart';
import '../controllers/discovery_candidates_controller.dart';
import '../controllers/discovery_controller.dart';
import '../controllers/mutual_match_realtime_provider.dart';
import '../matching_navigation.dart';
import '../widgets/match_celebration_overlay.dart';
import '../widgets/match_preferences_sheet.dart';

String _speciesLabel(String species) {
  return switch (species.toLowerCase()) {
    'cat' => 'Cat',
    'rabbit' => 'Rabbit',
    'bird' => 'Bird',
    'reptile' => 'Reptile',
    _ => 'Dog',
  };
}

bool _isLocationBlocked(LocationAccessState? access) {
  return switch (access) {
    LocationAccessState.denied ||
    LocationAccessState.permanentlyDenied ||
    LocationAccessState.servicesDisabled ||
    LocationAccessState.unavailable =>
      true,
    LocationAccessState.granted => false,
    null => true,
  };
}

LocationAccessState? _accessFromDeviceError(AsyncValue<LatLng> deviceLocation) {
  if (!deviceLocation.hasError) return null;
  final message = deviceLocation.error.toString().toLowerCase();
  if (message.contains('blocked') || message.contains('permanently')) {
    return LocationAccessState.permanentlyDenied;
  }
  if (message.contains('turned off') || message.contains('services')) {
    return LocationAccessState.servicesDisabled;
  }
  return LocationAccessState.denied;
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class MatchingScreen extends ConsumerWidget {
  const MatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetControllerProvider);
    if (pet != null) return _DiscoveryView(petId: pet.id);

    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final petsAsync = ref.watch(petListProvider);
    return Scaffold(
      backgroundColor: pt.surface1,
      body: Center(
        child: petsAsync.when(
          skipLoadingOnReload: true,
          loading: () => const CircularProgressIndicator.adaptive(),
          error: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
              const SizedBox(height: 12),
              Text('Connection error',
                  style: TextStyle(fontSize: 15, color: pt.ink500)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(petListProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
          data: (_) => const CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main view
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoveryView extends ConsumerStatefulWidget {
  const _DiscoveryView({required this.petId});
  final String petId;

  @override
  ConsumerState<_DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends ConsumerState<_DiscoveryView>
    with WidgetsBindingObserver {
  final Set<String> _shownMatchIds = {};
  PetMutualMatch? _celebrationMatch;

  String get petId => widget.petId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLocationState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocationState();
    }
  }

  void _refreshLocationState() {
    ref.invalidate(locationAccessProvider);
    ref.invalidate(deviceLatLngProvider);
    ref.invalidate(discoveryCandidatesControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PetMutualMatch>>(
      mutualMatchInsertStreamProvider(petId),
      (previous, next) {
        next.whenData((match) {
          if (_shownMatchIds.contains(match.id)) return;
          if (_celebrationMatch != null) return;
          _shownMatchIds.add(match.id);
          setState(() => _celebrationMatch = match);
        });
      },
    );

    ref.listen<AppException?>(
      locationSyncErrorProvider,
      (_, error) {
        if (error != null) AppSnackBar.showError(error);
      },
    );

    final bufferAsync = ref.watch(discoveryCandidatesControllerProvider);
    final locationAccessAsync = ref.watch(locationAccessProvider);
    final deviceLocationAsync = ref.watch(deviceLatLngProvider);
    final state = ref.watch(discoveryControllerProvider(petId));
    final notifier = ref.read(discoveryControllerProvider(petId).notifier);
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final activePet = ref.watch(activePetControllerProvider);
    final overlayActive = _celebrationMatch != null && activePet != null;

    final locationAccess = locationAccessAsync.asData?.value;
    final locationBlocked = _isLocationBlocked(locationAccess);

    Future<void> enableLocation() async {
      final access = locationAccess ?? await ref.read(locationServiceProvider).readAccessState();
      if (access == LocationAccessState.permanentlyDenied ||
          access == LocationAccessState.servicesDisabled) {
        await openAppSettings();
      } else {
        await ref.read(locationServiceProvider).requestWhenInUseAccess();
      }
      _refreshLocationState();
    }

    Widget buildDiscoveryContent() {
      if (locationBlocked) {
        return _LocationAccessEmpty(
          access: locationAccess ??
              _accessFromDeviceError(deviceLocationAsync) ??
              LocationAccessState.denied,
          onEnable: overlayActive ? null : enableLocation,
        );
      }

      return bufferAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
              const SizedBox(height: 12),
              Text(
                'Could not load profiles',
                style: TextStyle(fontSize: 15, color: pt.ink500),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: overlayActive
                    ? null
                    : () => ref.invalidate(
                          discoveryCandidatesControllerProvider,
                        ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (buf) {
          final deck = buf.candidates;
          final visible = state.isExiting && state.exitingCard != null;
          if (deck.isEmpty && !visible) {
            return _EmptyDeck(
              locationReady: locationAccess == LocationAccessState.granted,
            );
          }
          return _DiscoveryStack(
            buffer: deck,
            state: state,
            notifier: notifier,
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: pt.surface1,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                AppHeader(
                  eyebrow: 'Match · Nearby',
                  onOpenSwitcher: () => PetSwitcherSheet.show(context),
                  dense: true,
                  actions: [
                    AppHeaderAction(
                      iconKey: const ValueKey<String>('match_action_inbox'),
                      icon: Icons.chat_bubble_outline_rounded,
                      tooltip: 'Matches & messages',
                      onTap: overlayActive
                          ? () {}
                          : () => openMatchesInbox(context),
                    ),
                    AppHeaderAction(
                      iconKey: const ValueKey<String>('match_action_filter'),
                      icon: Icons.tune_rounded,
                      tooltip: 'Filters',
                      onTap: overlayActive
                          ? () {}
                          : () => MatchPreferencesSheet.show(context),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: IgnorePointer(
                      ignoring: overlayActive,
                      child: locationAccessAsync.when(
                        skipLoadingOnReload: true,
                        loading: () => const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                        error: (_, _) => buildDiscoveryContent(),
                        data: (_) => buildDiscoveryContent(),
                      ),
                    ),
                  ),
                ),
                if (!locationBlocked)
                  IgnorePointer(
                    ignoring: overlayActive,
                    child: _ActionDock(
                      state: state,
                      notifier: notifier,
                      bufferAsync: bufferAsync,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
            if (overlayActive)
              MatchCelebrationOverlay(
                activePet: activePet,
                matchedPetName: _matchedPetLabel(ref, _celebrationMatch!),
                matchedPetAvatarUrl:
                    _matchedPetAvatarUrl(ref, _celebrationMatch!),
                onSendMessage: () {
                  final match = _celebrationMatch!;
                  final label = _matchedPetLabel(ref, match);
                  setState(() => _celebrationMatch = null);
                  openMatchChat(
                    context,
                    ref,
                    matchId: match.id,
                    actorPetId: petId,
                    otherPetName: label,
                  );
                },
                onKeepSwiping: () => setState(() => _celebrationMatch = null),
              ),
          ],
        ),
      ),
    );
  }

  String _matchedPetLabel(WidgetRef ref, PetMutualMatch match) {
    final otherId =
        match.petAId == petId ? match.petBId : match.petAId;
    final deck = ref
        .read(discoveryCandidatesControllerProvider)
        .asData
        ?.value
        .candidates;
    if (deck != null) {
      for (final c in deck) {
        if (c.petId == otherId) return c.name;
      }
    }
    final pets = ref.read(petListProvider).asData?.value ?? const <Pet>[];
    for (final p in pets) {
      if (p.id == otherId) return p.name;
    }
    return 'your match';
  }

  String? _matchedPetAvatarUrl(WidgetRef ref, PetMutualMatch match) {
    final otherId =
        match.petAId == petId ? match.petBId : match.petAId;
    final deck = ref
        .read(discoveryCandidatesControllerProvider)
        .asData
        ?.value
        .candidates;
    if (deck != null) {
      for (final c in deck) {
        if (c.petId == otherId) return c.avatarUrl;
      }
    }
    final pets = ref.read(petListProvider).asData?.value ?? const <Pet>[];
    for (final p in pets) {
      if (p.id == otherId) return p.avatarUrl;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card stack
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoveryStack extends StatelessWidget {
  const _DiscoveryStack({
    required this.buffer,
    required this.state,
    required this.notifier,
  });
  final List<DiscoveryCandidate> buffer;
  final DiscoveryState state;
  final DiscoveryNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final hasFlying = state.isExiting && state.exitingCard != null;
    if (!hasFlying && buffer.isEmpty) return const _EmptyDeck();

    final dragProgress =
        (state.dragOffset.dx.abs().clamp(0.0, 90.0)) / 90.0;

    final afterCard = buffer.length >= 3 ? buffer[2] : null;
    final nextCard = buffer.length >= 2 ? buffer[1] : null;
    final peekTop = hasFlying && buffer.isNotEmpty ? buffer.first : null;
    final topLive = !hasFlying && buffer.isNotEmpty ? buffer.first : null;

    final layers = <Widget>[
      if (afterCard != null)
        _StackCard(
          candidate: afterCard,
          scale: 0.88,
          offsetY: 24,
        ),
      if (nextCard != null)
        _StackCard(
          candidate: nextCard,
          scale: 0.94 + 0.06 * dragProgress,
          offsetY: 12.0 - 12.0 * dragProgress,
        ),
      if (peekTop != null)
        _StackCard(
          candidate: peekTop,
          scale: 0.94 + 0.06 * dragProgress,
          offsetY: 12.0 - 12.0 * dragProgress,
        ),
      if (hasFlying)
        _SwipeCard(
          state: state,
          notifier: notifier,
          interactiveTop: null,
        )
      else if (topLive != null)
        _SwipeCard(
          state: state,
          notifier: notifier,
          interactiveTop: topLive,
        ),
    ];

    if (layers.isEmpty) return const _EmptyDeck(locationReady: true);

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: layers,
    );
  }
}

class _LocationAccessEmpty extends StatelessWidget {
  const _LocationAccessEmpty({
    required this.access,
    required this.onEnable,
  });

  final LocationAccessState access;
  final VoidCallback? onEnable;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final permanentlyDenied =
        access == LocationAccessState.permanentlyDenied;
    final servicesDisabled = access == LocationAccessState.servicesDisabled;

    final title = servicesDisabled
        ? 'Turn on location services'
        : permanentlyDenied
            ? 'Location access is off'
            : 'Location needed for nearby matches';
    final subtitle = servicesDisabled
        ? 'Enable location in your device settings so we can show pets near you.'
        : permanentlyDenied
            ? 'Allow location for PetFolio in Settings to discover pets around you.'
            : 'We use your location to find playmates, breeding partners, and adoption matches nearby.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded, size: 64, color: pt.ink300),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: pt.ink500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(
                color: pt.ink300,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(
              label: 'Enable Location Services',
              isFullWidth: true,
              leadingIcon: const Icon(
                Icons.location_on_rounded,
                size: 20,
                color: Colors.white,
              ),
              onPressed: onEnable,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({this.locationReady = false});

  final bool locationReady;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final tt = Theme.of(context).textTheme;
    final title = locationReady
        ? 'No pets nearby yet'
        : 'No more profiles nearby';
    final subtitle = locationReady
        ? 'Turn on Match Discovery for your pet and ask nearby owners to do the same. '
            'Pets also need a saved location—open Match after allowing location access.'
        : 'Check back soon!';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets_rounded, size: 64, color: pt.ink300),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tt.titleMedium?.copyWith(color: pt.ink500),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: pt.ink300, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _StackCard extends StatelessWidget {
  const _StackCard({
    required this.candidate,
    required this.scale,
    required this.offsetY,
  });
  final DiscoveryCandidate candidate;
  final double scale;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: _CardSurface(candidate: candidate),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe card — top of stack, handles gestures and exit animation
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({
    required this.state,
    required this.notifier,
    required this.interactiveTop,
  });
  final DiscoveryState state;
  final DiscoveryNotifier notifier;
  final DiscoveryCandidate? interactiveTop;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (state.isExiting && state.exitingCard != null) {
      return _buildExitAnimation(
        context,
        state.exitingCard!,
        size,
        state.exitAction!,
        state.exitDurationMs,
      );
    }
    final top = interactiveTop!;
    return _buildDraggable(context, top, size);
  }

  Widget _buildDraggable(
    BuildContext context,
    DiscoveryCandidate top,
    Size size,
  ) {
    final dxNorm = state.dragOffset.dx / (size.width * 0.75);
    final dyTilt = state.dragOffset.dy / (size.height * 1.2);
    final angle = (dxNorm + dyTilt * 0.12).clamp(-0.44, 0.44);

    final matchOpacity = (state.dragOffset.dx / 80).clamp(0.0, 1.0);
    final passOpacity = (-state.dragOffset.dx / 80).clamp(0.0, 1.0);
    final greetOpacity = (-state.dragOffset.dy / 80).clamp(0.0, 1.0);

    return Transform.translate(
      offset: state.dragOffset,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onPanUpdate: (d) => notifier.onDragUpdate(d.delta),
          onPanEnd: (_) => notifier.onDragEnd(),
          onPanCancel: notifier.onDragCancel,
          child: Stack(
            children: [
              _CardSurface(
                candidate: top,
                isExpanded: state.isExpanded,
                onToggleExpand: notifier.toggleExpand,
              ),
              if (matchOpacity > 0.05)
                Positioned(
                  top: 36,
                  left: 20,
                  child: Opacity(
                    opacity: matchOpacity,
                    child: _SwipeLabel(
                      label: 'MATCH',
                      color: AppColors.coral500,
                    ),
                  ),
                ),
              if (passOpacity > 0.05)
                Positioned(
                  top: 36,
                  right: 20,
                  child: Opacity(
                    opacity: passOpacity,
                    child: _SwipeLabel(
                      label: 'PASS',
                      color: AppColors.ink500,
                    ),
                  ),
                ),
              if (greetOpacity > 0.05)
                Positioned(
                  top: 36,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: greetOpacity,
                      child: _SwipeLabel(
                        label: 'WAVE  👋',
                        color: AppColors.blue500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExitAnimation(
    BuildContext context,
    DiscoveryCandidate top,
    Size size,
    SwipeAction action,
    int durationMs,
  ) {
    final (exitOffset, exitAngle) = _exitParams(action, size);
    final curve = const Cubic(0.4, 0, 1, 1);
    final fast = MediaQuery.disableAnimationsOf(context);

    if (fast) {
      return TweenAnimationBuilder<double>(
        key: ValueKey<Object>(top.petId),
        tween: Tween(begin: 1, end: 0),
        duration: PetfolioThemeExtension.durationXs,
        curve: curve,
        builder: (ctx, t, child) => Opacity(
          opacity: t,
          child: child,
        ),
        child: _CardSurface(candidate: top),
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey<Object>(top.petId),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: durationMs),
      curve: curve,
      builder: (ctx, t, child) => Transform.translate(
        offset: exitOffset * t,
        child: Transform.rotate(
          angle: exitAngle * t,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: _CardSurface(candidate: top),
    );
  }

  static (Offset, double) _exitParams(SwipeAction action, Size size) {
    return switch (action) {
      SwipeAction.pass => (
          Offset(-size.width * 1.45, size.height * 0.06),
          -math.pi / 10,
        ),
      SwipeAction.match => (
          Offset(size.width * 1.45, size.height * 0.06),
          math.pi / 10,
        ),
      SwipeAction.greet => (
          Offset(0, -size.height * 1.2),
          0.0,
        ),
      SwipeAction.superPaw => (
          Offset(size.width * 0.4, -size.height * 1.2),
          math.pi / 20,
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card surface — gradient photo + blob illustration + info panel
// ─────────────────────────────────────────────────────────────────────────────

class _CardSurface extends StatelessWidget {
  const _CardSurface({
    required this.candidate,
    this.isExpanded = false,
    this.onToggleExpand,
  });
  final DiscoveryCandidate candidate;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final colors = candidate.gradientColors;
    final gradColors = [
      if (colors.isNotEmpty) colors[0],
      if (colors.length > 1) colors[1],
      if (colors.length > 2) colors[2] else if (colors.isNotEmpty) colors.last,
    ];
    final resolvedGradColors = gradColors.isEmpty
        ? [
            AppColors.sunset500.withValues(alpha: 0.45),
            AppColors.coral500.withValues(alpha: 0.72),
            AppColors.coral500,
          ]
        : gradColors;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(PetfolioThemeExtension.radius2xl),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: resolvedGradColors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pet blob (centred in the upper portion)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              bottom: 160,
              child: Center(child: _PetBlob(candidate: candidate)),
            ),
            // Scrim — fade to black for info readability
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1.0],
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            // Info panel pinned to the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _InfoPanel(
                candidate: candidate,
                isExpanded: isExpanded,
                onToggle: onToggleExpand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pet blob illustration
// ─────────────────────────────────────────────────────────────────────────────

class _PetBlob extends StatelessWidget {
  const _PetBlob({required this.candidate});
  final DiscoveryCandidate candidate;

  static const _blobRadius = BorderRadius.only(
    topLeft: Radius.circular(120),
    topRight: Radius.circular(100),
    bottomLeft: Radius.circular(80),
    bottomRight: Radius.circular(140),
  );

  @override
  Widget build(BuildContext context) {
    final emoji = switch (candidate.species) {
      'cat' => '🐱',
      'rabbit' => '🐰',
      _ => '🐶',
    };

    return Semantics(
      label: '${candidate.name}, ${_speciesLabel(candidate.species)}',
      child: LayoutBuilder(
        builder: (_, constraints) {
        // Scale the blob with the available area, clamped for small/large screens.
        final w = (constraints.maxWidth * 0.52).clamp(120.0, 220.0);
        final h = w * 1.1;
        final emojiSize = w * 0.44;

        final blobDecoration = BoxDecoration(
          color: candidate.subjectColor.withAlpha(180),
          borderRadius: _blobRadius,
        );

        // When a real pet photo is available, show it inside the blob shape.
        // Fall back to the emoji illustration on network error or absence.
        final hasPhoto = candidate.avatarUrl != null &&
            candidate.avatarUrl!.isNotEmpty;

        if (hasPhoto) {
          return ClipRRect(
            borderRadius: _blobRadius,
            child: CachedNetworkImage(
              imageUrl: candidate.avatarUrl!,
              width: w,
              height: h,
              fit: BoxFit.cover,
              // Placeholder: show the coloured blob while the image loads.
              placeholder: (_, _) => Container(
                width: w,
                height: h,
                decoration: blobDecoration,
                alignment: Alignment.center,
                child: Text(emoji,
                    style: TextStyle(fontSize: emojiSize)),
              ),
              // Error: fall back to emoji blob — never a broken-image icon.
              errorWidget: (_, _, _) => Container(
                width: w,
                height: h,
                decoration: blobDecoration,
                alignment: Alignment.center,
                child: Text(emoji,
                    style: TextStyle(fontSize: emojiSize)),
              ),
            ),
          );
        }

        return Container(
          width: w,
          height: h,
          decoration: blobDecoration,
          alignment: Alignment.center,
          child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
        );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info panel
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.candidate,
    required this.isExpanded,
    this.onToggle,
  });
  final DiscoveryCandidate candidate;
  final bool isExpanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: PetfolioThemeExtension.durationMd,
      curve: Curves.easeInOut,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Name + age + expand toggle ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    candidate.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  candidate.age,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white.withAlpha(190),
                  ),
                ),
                if (candidate.verified) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
                const Spacer(),
                if (onToggle != null)
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(60),
                        ),
                      ),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 13,
                  color: Colors.white.withAlpha(180),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    candidate.distance,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withAlpha(180),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MatchMetaChip(
                  label: _speciesLabel(candidate.species),
                  foreground: Colors.white,
                  background: AppColors.blue500.withValues(alpha: 0.34),
                  borderColor: Colors.white.withValues(alpha: 0.42),
                ),
                _MatchMetaChip(
                  label: candidate.breed,
                  foreground: Colors.white,
                  background: AppColors.mulberry500.withValues(alpha: 0.42),
                  borderColor: Colors.white.withValues(alpha: 0.45),
                ),
                _MatchMetaChip(
                  label: candidate.energy,
                  foreground: Colors.white,
                  background: AppColors.sunset500.withValues(alpha: 0.88),
                  borderColor: Colors.white.withValues(alpha: 0.48),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Traits ──────────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final trait in candidate.traits) _TraitChip(label: trait),
              ],
            ),
            // ── Expanded bio ─────────────────────────────────────────────
            if (isExpanded) ...[
              const SizedBox(height: 14),
              Text(
                candidate.bio,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withAlpha(215),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.directions_walk_rounded,
                label: 'Play style',
                value: candidate.playStyle,
              ),
              const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.bolt_rounded,
                label: 'Energy',
                value: candidate.energy,
              ),
              const SizedBox(height: 6),
              _DetailRow(
                icon: Icons.people_outline_rounded,
                label: 'Best with',
                value: candidate.bestWith,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action dock — 5 buttons from the design spec
// ─────────────────────────────────────────────────────────────────────────────

class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.state,
    required this.notifier,
    required this.bufferAsync,
  });
  final DiscoveryState state;
  final DiscoveryNotifier notifier;
  final AsyncValue<DiscoveryCandidatesBuffer> bufferAsync;

  @override
  Widget build(BuildContext context) {
    final deck = bufferAsync.asData?.value.candidates ?? const <DiscoveryCandidate>[];
    final disabled = state.isExiting || deck.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _DockButton(
            key: const ValueKey<String>('match_action_pass'),
            size: 56,
            color: AppColors.ink300,
            icon: Icons.close_rounded,
            iconSize: 26,
            onTap: disabled ? null : () => notifier.swipe(SwipeAction.pass),
          ),
          _DockButton(
            key: const ValueKey<String>('match_action_greet'),
            size: 48,
            color: AppColors.blue500,
            icon: Icons.waving_hand_rounded,
            iconSize: 22,
            onTap: disabled ? null : () => notifier.swipe(SwipeAction.greet),
          ),
          _DockButton(
            key: const ValueKey<String>('match_action_like'),
            size: 64,
            color: AppColors.coral500,
            icon: Icons.pets_rounded,
            iconSize: 30,
            elevated: true,
            onTap: disabled ? null : () => notifier.swipe(SwipeAction.match),
          ),
          _DockButton(
            key: const ValueKey<String>('match_action_super'),
            size: 48,
            color: AppColors.mulberry500,
            icon: Icons.star_rounded,
            iconSize: 22,
            onTap: disabled
                ? null
                : () => notifier.swipe(SwipeAction.superPaw),
          ),
          _DockButton(
            size: 56,
            color: AppColors.sunset500,
            icon: Icons.bolt_rounded,
            iconSize: 26,
            onTap: null, // Boost — premium feature placeholder
          ),
        ],
      ),
    );
  }
}

class _MatchMetaChip extends StatelessWidget {
  const _MatchMetaChip({
    required this.label,
    required this.foreground,
    required this.background,
    required this.borderColor,
  });
  final String label;
  final Color foreground;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(PetfolioThemeExtension.radiusSm),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: foreground,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeLabel extends StatelessWidget {
  const _SwipeLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2.5),
        borderRadius:
            BorderRadius.circular(PetfolioThemeExtension.radiusSm),
        color: color.withAlpha(25),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _TraitChip extends StatelessWidget {
  const _TraitChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius:
            BorderRadius.circular(PetfolioThemeExtension.radiusPill),
        border: Border.all(color: Colors.white.withAlpha(70)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white.withAlpha(150)),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withAlpha(180),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withAlpha(215),
            ),
          ),
        ),
      ],
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    super.key,
    required this.size,
    required this.color,
    required this.icon,
    required this.iconSize,
    required this.onTap,
    this.elevated = false,
  });
  final double size;
  final Color color;
  final IconData icon;
  final double iconSize;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: PetfolioThemeExtension.durationSm,
        opacity: isDisabled ? 0.38 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: elevated
                ? color
                : (isDark ? AppColors.surface0D : AppColors.surface0),
            border: elevated
                ? null
                : Border.all(color: color.withAlpha(90), width: 1.5),
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: color.withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: elevated ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
