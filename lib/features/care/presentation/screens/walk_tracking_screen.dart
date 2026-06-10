import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class _WalkState {
  const _WalkState({
    this.points = const [],
    this.distanceMeters = 0.0,
    this.elapsedSeconds = 0,
    this.isTracking = false,
    this.error,
  });
  final List<LatLng> points;
  final double distanceMeters;
  final int elapsedSeconds;
  final bool isTracking;
  final String? error;

  _WalkState copyWith({
    List<LatLng>? points,
    double? distanceMeters,
    int? elapsedSeconds,
    bool? isTracking,
    String? error,
  }) =>
      _WalkState(
        points: points ?? this.points,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        isTracking: isTracking ?? this.isTracking,
        error: error ?? this.error,
      );
}

class _WalkNotifier extends Notifier<_WalkState> {
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  final _distance = const Distance();

  @override
  _WalkState build() => const _WalkState();

  Future<void> start() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      state = state.copyWith(
          error: 'Location permission is required for walk tracking.');
      return;
    }

    state = _WalkState(isTracking: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
      final newPoint = LatLng(pos.latitude, pos.longitude);
      final updatedPoints = [...state.points, newPoint];
      double dist = state.distanceMeters;
      if (state.points.isNotEmpty) {
        dist += _distance(state.points.last, newPoint);
      }
      state = state.copyWith(points: updatedPoints, distanceMeters: dist);
    });

    ref.onDispose(_cleanup);
  }

  void stop() {
    _cleanup();
    state = state.copyWith(isTracking: false);
  }

  void _cleanup() {
    _positionSub?.cancel();
    _timer?.cancel();
  }
}

final _walkProvider =
    NotifierProvider.autoDispose<_WalkNotifier, _WalkState>(_WalkNotifier.new);

class WalkTrackingScreen extends ConsumerWidget {
  const WalkTrackingScreen({super.key});

  static const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walk = ref.watch(_walkProvider);
    final cs = Theme.of(context).colorScheme;
    final center = walk.points.isNotEmpty
        ? walk.points.last
        : const LatLng(23.8103, 90.4125);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk Tracker'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 16),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                userAgentPackageName: 'app.petfolio.petfolio',
              ),
              if (walk.points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: walk.points,
                      strokeWidth: 4,
                      color: AppColors.tangerine,
                    ),
                  ],
                ),
              if (walk.points.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: walk.points.last,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.tangerine,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _StatsCard(
              distance: _formatDistance(walk.distanceMeters),
              duration: _formatDuration(walk.elapsedSeconds),
            ),
          ),
          if (walk.error != null)
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: cs.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(walk.error!,
                      style: TextStyle(color: cs.onErrorContainer)),
                ),
              ),
            ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(child: _WalkButton(walk: walk)),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.distance, required this.duration});
  final String distance;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final pt = Theme.of(context).extension<PetfolioThemeExtension>()!;
    final cs = Theme.of(context).colorScheme;
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: cs.surface.withValues(alpha: 0.95),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(label: 'Distance', value: distance, pt: pt),
            Container(width: 1, height: 36, color: pt.line),
            _Stat(label: 'Duration', value: duration, pt: pt),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.pt});
  final String label;
  final String value;
  final PetfolioThemeExtension pt;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: tt.labelSmall?.copyWith(color: pt.ink500)),
      ],
    );
  }
}

class _WalkButton extends ConsumerWidget {
  const _WalkButton({required this.walk});
  final _WalkState walk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(_walkProvider.notifier);
    return FloatingActionButton.extended(
      key: const ValueKey('walk_toggle'),
      onPressed: walk.isTracking ? notifier.stop : notifier.start,
      backgroundColor:
          walk.isTracking ? AppColors.poppy : AppColors.tangerine,
      foregroundColor: Colors.white,
      icon: Icon(walk.isTracking
          ? Icons.stop_rounded
          : Icons.directions_walk_rounded),
      label: Text(walk.isTracking ? 'Stop Walk' : 'Start Walk'),
    );
  }
}
