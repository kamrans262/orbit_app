import 'package:flutter/services.dart';
import 'package:location/location.dart' as location;

class CurrentLocation {
  const CurrentLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
}

class LocationAccessException implements Exception {
  const LocationAccessException(this.message);

  final String message;
}

abstract interface class CurrentLocationReader {
  Future<CurrentLocation> read();
}

class LocationCurrentLocationReader implements CurrentLocationReader {
  const LocationCurrentLocationReader();

  @override
  Future<CurrentLocation> read() async {
    final client = location.Location.instance;

    try {
      final servicesEnabled = await client.serviceEnabled();
      if (!servicesEnabled) {
        throw const LocationAccessException(
          'Turn on location services to share your current location.',
        );
      }

      var permission = await client.hasPermission();
      if (permission == location.PermissionStatus.denied) {
        permission = await client.requestPermission();
      }

      if (permission == location.PermissionStatus.denied) {
        throw const LocationAccessException(
          'Location permission is required only when you choose to share your location.',
        );
      }

      if (permission == location.PermissionStatus.deniedForever) {
        throw const LocationAccessException(
          'Location permission is disabled in system settings. Enable it to share location.',
        );
      }

      await client.changeSettings(accuracy: location.LocationAccuracy.high);
      final result = await client.getLocation();
      final latitude = result.latitude;
      final longitude = result.longitude;

      if (!latitude.isFinite ||
          !longitude.isFinite ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        throw const LocationAccessException(
          'Orbit could not get a valid current location. Try again.',
        );
      }

      final accuracy = result.accuracy;
      return CurrentLocation(
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracy != null && accuracy.isFinite && accuracy >= 0
            ? accuracy
            : null,
      );
    } on PlatformException catch (error) {
      if (error.code == 'PERMISSION_DENIED') {
        throw const LocationAccessException(
          'Location permission is required only when you choose to share your location.',
        );
      }
      throw const LocationAccessException(
        'Orbit could not get your current location. Check location services and try again.',
      );
    }
  }
}
