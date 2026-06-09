import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/platform/web_image_cache.dart';
import '../../../../core/services/lat_lng.dart';
import '../../../../core/services/location_providers.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../pet_profile/data/models/pet.dart';
import '../../../pet_profile/presentation/controllers/active_pet_controller.dart';
import '../../../pet_profile/presentation/controllers/edit_profile_controller.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';

import '../../data/models/discovery_candidate.dart';
import '../../data/models/pet_mutual_match.dart';
import '../controllers/discovery_candidates_controller.dart';
import '../controllers/discovery_controller.dart';
import '../controllers/mutual_match_realtime_provider.dart';
import '../matching_navigation.dart';
import '../widgets/match_celebration_overlay.dart';




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

bool _isDiscoveryLocationBlocked({
  required LocationAccessState? access,
  required bool actorPetHasStoredLocation,
}) {
  if (kIsWeb &&
      actorPetHasStoredLocation &&
      (access == LocationAccessState.unavailable ||
          access == LocationAccessState.denied)) {
    return false;
  }
  return _isLocationBlocked(access);
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

String _discoveryErrorMessage(Object error) {
  if (error is DatabaseException) {
    final lower = error.message.toLowerCase();
    if (lower.contains('404') || lower.contains('not found')) {
      return 'Matching is unavailable. Try again in a moment.';
    }
    return error.message;
  }
  return 'Could not load profiles';
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
          loading: () => const TailWagLoader(),
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
          data: (_) => const TailWagLoader(),
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
  Timer? _refreshDebounce;

  // Track the last known access state so we only reload candidates when it
  // transitions from blocked → granted (H-4 fix).
  LocationAccessState? _lastKnownAccess;

  String get petId => widget.petId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLocationState());
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(locationAccessProvider);
    ref.invalidate(deviceLatLngProvider);
    final current = ref.read(locationAccessProvider).asData?.value;
    // Full candidate reload only when access changes from blocked → granted.
    final wasBlocked = _isLocationBlocked(_lastKnownAccess);
    final nowGranted = current == LocationAccessState.granted;
    if (wasBlocked && nowGranted) {
      ref.invalidate(discoveryCandidatesControllerProvider);
    }
    _lastKnownAccess = current;
  }

  // Debounced so rapid lifecycle transitions (e.g. debug-VM attach, permission
  // dialogs) collapse into a single invalidation instead of a request storm.
  void _refreshLocationState() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      ref.invalidate(locationAccessProvider);
      ref.invalidate(deviceLatLngProvider);
      ref.invalidate(discoveryCandidatesControllerProvider);
      _lastKnownAccess = ref.read(locationAccessProvider).asData?.value;
    });
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

    ref.listen(
      locationSyncErrorProvider,
      (_, error) {
        if (error != null) AppSnackBar.showError(error);
      },
    );

    ref.listen<String?>(
      swipeErrorProvider,
      (_, message) {
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 3),
            ),
          );
        }
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
    final actorPetHasStoredLocation =
        ref.watch(petMatchLocationProvider(petId)).value == true;
    final locationBlocked = _isDiscoveryLocationBlocked(
      access: locationAccess,
      actorPetHasStoredLocation: actorPetHasStoredLocation,
    );

    Future<void> enableLocation() async {
      final access = locationAccess ?? await ref.read(locationServiceProvider).readAccessState();
      if (!kIsWeb &&
          (access == LocationAccessState.permanentlyDenied ||
              access == LocationAccessState.servicesDisabled)) {
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
        loading: () => const Center(child: TailWagLoader()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: pt.ink300),
              const SizedBox(height: 12),
              Text(
                _discoveryErrorMessage(error),
                style: TextStyle(fontSize: 15, color: pt.ink500),
                textAlign: TextAlign.center,
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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= ResponsiveLayout.mobileMax;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color headerColor = AppColors.lilac; // default lilac match accent
    if (activePet != null) {
      headerColor = activePet.speciesEnum.resolvedAccent(isDark);
      final dbAccent = activePet.accentColor;
      if (dbAccent != null && dbAccent.isNotEmpty && dbAccent != '#FF6B9D') {
        try {
          final hex = dbAccent.replaceAll('#', '');
          if (hex.length == 6) {
            headerColor = Color(int.parse('FF$hex', radix: 16));
          } else if (hex.length == 8) {
            headerColor = Color(int.parse(hex, radix: 16));
          }
        } catch (_) {}
      }
    }

    Widget mainContent = Column(
      children: [
        SizedBox(
          height: MediaQuery.paddingOf(context).top + 92.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: WaveHeader(
                  color: headerColor,
                  height: MediaQuery.paddingOf(context).top + 100.0,
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: IgnorePointer(
              ignoring: overlayActive,
              child: locationAccessAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: TailWagLoader()),
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
        SizedBox(height: isWide ? 16 : (92 + MediaQuery.paddingOf(context).bottom)),
      ],
    );

    if (isWide) {
      mainContent = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: mainContent,
        ),
      );
    }

    return Scaffold(
      backgroundColor: pt.surface1,
      body: Stack(
        children: [
          mainContent,
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

class _SwipeCard extends StatefulWidget {
  const _SwipeCard({
    required this.state,
    required this.notifier,
    required this.interactiveTop,
  });
  final DiscoveryState state;
  final DiscoveryNotifier notifier;
  final DiscoveryCandidate? interactiveTop;

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  // 0 = neutral, 1 = right (match), -1 = left (pass), 2 = up (greet)
  int _lastHapticZone = 0;

  static const double _hapticThreshold = 80.0;

  void _checkHaptic(Offset dragOffset) {
    final dx = dragOffset.dx;
    final dy = dragOffset.dy;
    final int zone;
    if (dx > _hapticThreshold) {
      zone = 1;
    } else if (dx < -_hapticThreshold) {
      zone = -1;
    } else if (dy < -_hapticThreshold) {
      zone = 2;
    } else {
      zone = 0;
    }
    if (zone != _lastHapticZone) {
      _lastHapticZone = zone;
      if (zone != 0) HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final layoutWidth = math.min(size.width, 480.0);
    if (widget.state.isExiting && widget.state.exitingCard != null) {
      return _buildExitAnimation(
        context,
        widget.state.exitingCard!,
        size,
        layoutWidth,
        widget.state.exitAction!,
        widget.state.exitDurationMs,
      );
    }
    final top = widget.interactiveTop!;
    return _buildDraggable(context, top, size, layoutWidth);
  }

  Widget _buildDraggable(
    BuildContext context,
    DiscoveryCandidate top,
    Size size,
    double layoutWidth,
  ) {
    final dxNorm = widget.state.dragOffset.dx / (layoutWidth * 0.75);
    final dyTilt = widget.state.dragOffset.dy / (size.height * 1.2);
    final angle = (dxNorm + dyTilt * 0.12).clamp(-0.44, 0.44);

    final matchOpacity = (widget.state.dragOffset.dx / 80).clamp(0.0, 1.0);
    final passOpacity = (-widget.state.dragOffset.dx / 80).clamp(0.0, 1.0);
    final greetOpacity = (-widget.state.dragOffset.dy / 80).clamp(0.0, 1.0);

    return Transform.translate(
      offset: widget.state.dragOffset,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onPanUpdate: (d) {
            widget.notifier.onDragUpdate(d.delta);
            _checkHaptic(widget.state.dragOffset + d.delta);
          },
          onPanEnd: (_) {
            final zone = _lastHapticZone;
            _lastHapticZone = 0;
            if (zone != 0) HapticFeedback.mediumImpact();
            widget.notifier.onDragEnd();
          },
          onPanCancel: () {
            _lastHapticZone = 0;
            widget.notifier.onDragCancel();
          },
          child: Stack(
            children: [
              _CardSurface(
                candidate: top,
                isExpanded: widget.state.isExpanded,
                onToggleExpand: widget.notifier.toggleExpand,
              ),
              if (matchOpacity > 0.05)
                Positioned(
                  top: 36,
                  left: 20,
                  child: Opacity(
                    opacity: matchOpacity,
                    child: _SwipeLabel(
                      label: 'MATCH',
                      color: AppColors.poppy,
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
                        color: AppColors.lilac,
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
    double layoutWidth,
    SwipeAction action,
    int durationMs,
  ) {
    final (exitOffset, exitAngle) = _exitParams(action, size, layoutWidth);
    // Spring-physics exit: accelerates quickly off-screen like a card throw
    final curve = PetfolioThemeExtension.curveSpring;
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

  static (Offset, double) _exitParams(SwipeAction action, Size size, double layoutWidth) {
    return switch (action) {
      SwipeAction.pass => (
          Offset(-layoutWidth * 1.45, size.height * 0.06),
          -math.pi / 10,
        ),
      SwipeAction.match => (
          Offset(layoutWidth * 1.45, size.height * 0.06),
          math.pi / 10,
        ),
      SwipeAction.greet => (
          Offset(0, -size.height * 1.2),
          0.0,
        ),
      SwipeAction.superPaw => (
          Offset(layoutWidth * 0.4, -size.height * 1.2),
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
    final softColor = colors.isNotEmpty ? colors.first.withAlpha(120) : AppColors.tangerine.withAlpha(120);
    final mainColor = colors.isNotEmpty ? colors.last : AppColors.tangerine;

    final emoji = switch (candidate.species) {
      'cat' => '🐱',
      'rabbit' => '🐰',
      'bird' => '🦜',
      'reptile' => '🦎',
      _ => '🐶',
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.4, -0.4),
            radius: 1.2,
            colors: [softColor, mainColor],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 50,
              offset: Offset(0, 24),
              spreadRadius: -20,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (candidate.avatarUrl != null && candidate.avatarUrl!.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: candidate.avatarUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: networkImageMemCacheWidth(
                    context,
                    MediaQuery.sizeOf(context).width,
                    maxPixels: webNetworkImageMemCacheMax,
                  ),
                  maxWidthDiskCache: networkImageMaxDiskCacheWidth(
                    context,
                    MediaQuery.sizeOf(context).width,
                    maxPixels: webNetworkImageMemCacheMax,
                  ),
                  placeholder: (context, url) => Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 60),
                      child: Text(
                        emoji,
                        style: const TextStyle(
                          fontSize: 160,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 28,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 60),
                      child: Text(
                        emoji,
                        style: const TextStyle(
                          fontSize: 160,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 28,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              // Emoji blob
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 60),
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 160,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Distance Pill
            Positioned(
              top: 14,
              right: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  color: Colors.black.withAlpha(100),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        candidate.distance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Info Gradient
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            '${candidate.name},',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          candidate.age,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      candidate.breed,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      candidate.bio,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: candidate.traits.take(3).map((t) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            color: Colors.white.withAlpha(56),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _DockButton(
            size: 56,
            color: AppColors.ink500,
            bgColor: Theme.of(context).colorScheme.surface,
            label: '✕',
            fontSize: 22,
            onTap: disabled ? null : () => notifier.swipe(SwipeAction.pass),
          ),
          const SizedBox(width: 16),
          _DockButton(
            size: 48,
            color: Colors.white,
            bgColor: AppColors.lilac,
            label: '⭐',
            fontSize: 19,
            onTap: disabled ? null : () => notifier.swipe(SwipeAction.superPaw),
          ),
          const SizedBox(width: 16),
          _DockButton(
            size: 72,
            color: Colors.white,
            bgColor: AppColors.poppy,
            label: '🐾',
            fontSize: 32,
            onTap: disabled ? null : () => notifier.swipe(SwipeAction.match),
          ),

        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.size,
    required this.color,
    required this.bgColor,
    required this.label,
    required this.fontSize,
    required this.onTap,
  });
  final double size;
  final Color color;
  final Color bgColor;
  final String label;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: PetfolioThemeExtension.durationSm,
        opacity: isDisabled ? 0.38 : 1.0,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: bgColor.withAlpha(153), // ~60%
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: bgColor.withAlpha(255),
                blurRadius: 24,
                spreadRadius: -10,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

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
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

