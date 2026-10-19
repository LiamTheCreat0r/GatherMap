import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Whether the app may read the device's location.
enum LocationAccess {
  /// The user can still be asked again (initial state, or declined once).
  denied,

  /// Permanently declined: only the system settings can restore it.
  deniedForever,

  /// Reading the location is allowed.
  granted,

  /// The platform cannot tell yet. Web browsers without the Permissions API
  /// report this until the app actually asks for a fix, which is what raises
  /// the browser's own prompt.
  unknown,
}

/// A single position fix, in WGS 84 degrees.
class UserLocation {
  const UserLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum LocationFailure {
  /// Location services are switched off at the device/browser level.
  serviceDisabled,

  /// The user declined the permission prompt.
  permissionDenied,

  /// The permission was permanently declined; only the settings can restore it.
  permissionDeniedForever,

  /// The platform could not produce a fix (timeout, no signal, …).
  unavailable,
}

class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  @override
  String toString() => 'LocationException: $failure';
}

class LocationResult {
  const LocationResult.success(this.location) : failure = null;
  const LocationResult.failure(this.failure) : location = null;
  final UserLocation? location;
  final LocationFailure? failure;
  bool get isSuccess => location != null;
}

/// Thin seam over the geolocation plugin.
///
/// [LocationService] drives the permission dance through this interface, so it
/// can be exercised with a hand-written fake — no platform channel, no device.
abstract class LocationProvider {
  /// True when location services are enabled on the device/browser.
  Future<bool> isServiceEnabled();

  /// The current permission, without prompting the user.
  Future<LocationAccess> checkAccess();

  /// Asks the user for permission, prompting if the platform allows it.
  Future<LocationAccess> requestAccess();

  /// Waits for a fresh position fix.
  ///
  /// Throws [LocationException] when the platform refuses or fails.
  Future<UserLocation> currentLocation();

  /// Opens the app's settings page so a permanent denial can be undone.
  Future<bool> openAppSettings();

  /// Opens the device's location settings so a disabled service can be enabled.
  Future<bool> openLocationSettings();
}

/// [LocationProvider] backed by `package:geolocator`.
///
/// The plugin owns the platform plumbing: on Android it raises the runtime
/// permission dialog, on iOS the `NSLocationWhenInUseUsageDescription` prompt,
/// and on web the browser's own geolocation prompt.
class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider();

  /// Long enough for a cold GPS fix, short enough that the locate button does
  /// not spin forever when there is no signal.
  static const Duration _timeout = Duration(seconds: 15);

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationAccess> checkAccess() async =>
      _access(await Geolocator.checkPermission());

  @override
  Future<LocationAccess> requestAccess() async =>
      _access(await Geolocator.requestPermission());

  @override
  Future<UserLocation> currentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        ),
      );
      return UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on PermissionDeniedException {
      throw const LocationException(LocationFailure.permissionDenied);
    } on LocationServiceDisabledException {
      throw const LocationException(LocationFailure.serviceDisabled);
    } on TimeoutException {
      throw const LocationException(LocationFailure.unavailable);
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Collapses the plugin's five permission states onto [LocationAccess].
  static LocationAccess _access(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccess.granted;
      case LocationPermission.deniedForever:
        return LocationAccess.deniedForever;
      case LocationPermission.denied:
        return LocationAccess.denied;
      case LocationPermission.unableToDetermine:
        return LocationAccess.unknown;
    }
  }
}

/// Resolves the device's position, asking for permission when needed.
///
/// [locate] never throws: every outcome is folded into a [LocationResult] the
/// caller can render, mirroring the controllers' `status`/`error` approach.
class LocationService {
  const LocationService({this.provider = const GeolocatorLocationProvider()});

  /// The platform seam; tests inject a fake.
  final LocationProvider provider;

  /// Returns the current position, prompting for permission first.
  Future<LocationResult> locate() async {
    try {
      if (!await provider.isServiceEnabled()) {
        return const LocationResult.failure(LocationFailure.serviceDisabled);
      }

      var access = await provider.checkAccess();
      if (access == LocationAccess.denied) {
        access = await provider.requestAccess();
      }

      switch (access) {
        case LocationAccess.deniedForever:
          return const LocationResult.failure(
            LocationFailure.permissionDeniedForever,
          );
        case LocationAccess.denied:
          return const LocationResult.failure(LocationFailure.permissionDenied);
        case LocationAccess.granted:
        case LocationAccess.unknown:
          return LocationResult.success(await provider.currentLocation());
      }
    } on LocationException catch (error) {
      return LocationResult.failure(error.failure);
    } on Object {
      return const LocationResult.failure(LocationFailure.unavailable);
    }
  }

  /// Opens the app's settings page (used after a permanent denial).
  Future<bool> openAppSettings() => provider.openAppSettings();

  /// Opens the device's location settings (used when the service is off).
  Future<bool> openLocationSettings() => provider.openLocationSettings();
}
