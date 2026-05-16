import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lat_lng.dart';
import 'location_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final deviceLatLngProvider =
    AsyncNotifierProvider<DeviceLatLngNotifier, LatLng>(
  DeviceLatLngNotifier.new,
);

class DeviceLatLngNotifier extends AsyncNotifier<LatLng> {
  @override
  Future<LatLng> build() =>
      ref.read(locationServiceProvider).acquireCurrentLatLng();
}
