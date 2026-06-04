import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:petfolio/core/errors/app_exception.dart';

import 'lat_lng.dart';

enum LocationAccessState {
  granted,
  denied,
  permanentlyDenied,
  servicesDisabled,
  unavailable,
}

class LocationService {
  Future<LocationAccessState> readAccessState() async {
    try {
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        return LocationAccessState.servicesDisabled;
      }
      return _mapGeolocatorPermission(await Geolocator.checkPermission());
    } catch (_) {
      return LocationAccessState.unavailable;
    }
  }

  Future<LocationAccessState> requestWhenInUseAccess() async {
    try {
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        return LocationAccessState.servicesDisabled;
      }
      return _mapGeolocatorPermission(await Geolocator.requestPermission());
    } catch (_) {
      return LocationAccessState.unavailable;
    }
  }

  LocationAccessState _mapGeolocatorPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccessState.granted;
      case LocationPermission.denied:
        return LocationAccessState.denied;
      case LocationPermission.deniedForever:
        return LocationAccessState.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return LocationAccessState.denied;
    }
  }

  Future<LatLng> acquireCurrentLatLng() async {
    var access = await readAccessState();

    if (access == LocationAccessState.denied) {
      access = await requestWhenInUseAccess();
    }

    switch (access) {
      case LocationAccessState.servicesDisabled:
        throw const ValidationException(
          message:
              'Location services are turned off. Turn them on in system settings to match using your current position.',
        );
      case LocationAccessState.permanentlyDenied:
        throw const ValidationException(
          message:
              'Location is blocked for this app. Open Settings to allow location, or discovery will use your pet profile location.',
        );
      case LocationAccessState.denied:
        throw const ValidationException(
          message:
              'Location permission was denied. Discovery will use your pet profile location until you allow access.',
        );
      case LocationAccessState.unavailable:
        throw const ValidationException(
          message:
              'Location is not available. Discovery will use your pet profile location.',
        );
      case LocationAccessState.granted:
        break;
    }

    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LatLng(latitude: last.latitude, longitude: last.longitude);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: kIsWeb ? 15 : 20),
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
