import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:petfolio/core/errors/app_exception.dart';

import 'lat_lng.dart';

class LocationService {
  Future<LatLng> acquireCurrentLatLng() async {
    if (kIsWeb) {
      throw const ValidationException(
        message:
            'Device location is not available in this environment. Matching uses your pet profile location.',
      );
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const ValidationException(
        message:
            'Location services are turned off. Turn them on in system settings to match using your current position.',
      );
    }

    final status = await Permission.locationWhenInUse.request();
    if (status.isPermanentlyDenied) {
      throw const ValidationException(
        message:
            'Location is blocked for this app. Open Settings to allow location, or discovery will use your pet profile location.',
      );
    }
    if (status.isDenied) {
      throw const ValidationException(
        message:
            'Location permission was denied. Discovery will use your pet profile location until you allow access.',
      );
    }
    if (!status.isGranted) {
      throw const ValidationException(
        message:
            'Location is not available. Discovery will use your pet profile location.',
      );
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return LatLng(latitude: pos.latitude, longitude: pos.longitude);
    } on ValidationException {
      rethrow;
    } catch (_) {
      throw const ValidationException(
        message:
            'Could not read your position. Try again, or discovery will use your pet profile location.',
      );
    }
  }
}
