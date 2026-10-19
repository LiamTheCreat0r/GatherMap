import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/services/location_service.dart';

/// Hand-written [LocationProvider] that drives every branch of
/// [LocationService] without a platform channel or a device.
class _FakeLocationProvider implements LocationProvider {
  _FakeLocationProvider({
    this.serviceEnabled = true,
    this.checkedAccess = LocationAccess.granted,
    this.requestedAccess = LocationAccess.granted,
    this.positionError,
  });

  bool serviceEnabled;
  LocationAccess checkedAccess;
  LocationAccess requestedAccess;
  UserLocation position = const UserLocation(latitude: 43.6, longitude: 1.44);
  LocationException? positionError;

  int checkCalls = 0;
  int requestCalls = 0;
  int positionCalls = 0;
  int appSettingsCalls = 0;
  int locationSettingsCalls = 0;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationAccess> checkAccess() async {
    checkCalls++;
    return checkedAccess;
  }

  @override
  Future<LocationAccess> requestAccess() async {
    requestCalls++;
    return requestedAccess;
  }

  @override
  Future<UserLocation> currentLocation() async {
    positionCalls++;
    final error = positionError;
    if (error != null) throw error;
    return position;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsCalls++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsCalls++;
    return true;
  }
}

void main() {
  group('LocationService.locate', () {
    test('an already-granted permission resolves without prompting', () async {
      final provider = _FakeLocationProvider(
        checkedAccess: LocationAccess.granted,
      );

      final result = await LocationService(provider: provider).locate();

      expect(result.isSuccess, isTrue);
      expect(result.location!.latitude, 43.6);
      expect(result.location!.longitude, 1.44);
      expect(result.failure, isNull);
      expect(provider.requestCalls, 0);
      expect(provider.positionCalls, 1);
    });

    test('a denied permission prompts, and succeeds when granted', () async {
      final provider = _FakeLocationProvider(
        checkedAccess: LocationAccess.denied,
        requestedAccess: LocationAccess.granted,
      );

      final result = await LocationService(provider: provider).locate();

      expect(result.isSuccess, isTrue);
      expect(provider.requestCalls, 1);
      expect(provider.positionCalls, 1);
    });

    test('a still-denied permission reports permissionDenied', () async {
      final provider = _FakeLocationProvider(
        checkedAccess: LocationAccess.denied,
        requestedAccess: LocationAccess.denied,
      );

      final result = await LocationService(provider: provider).locate();

      expect(result.isSuccess, isFalse);
      expect(result.failure, LocationFailure.permissionDenied);
      expect(provider.positionCalls, 0);
    });

    test('a permanently denied permission never prompts', () async {
      final provider = _FakeLocationProvider(
        checkedAccess: LocationAccess.deniedForever,
      );

      final result = await LocationService(provider: provider).locate();

      expect(result.failure, LocationFailure.permissionDeniedForever);
      expect(provider.requestCalls, 0);
    });

    test('an unknown permission still attempts a fix (web prompt)', () async {
      final provider = _FakeLocationProvider(
        checkedAccess: LocationAccess.unknown,
      );

      final result = await LocationService(provider: provider).locate();

      expect(result.isSuccess, isTrue);
      expect(provider.positionCalls, 1);
    });

    test(
      'a disabled service short-circuits before any permission check',
      () async {
        final provider = _FakeLocationProvider(
          serviceEnabled: false,
          checkedAccess: LocationAccess.granted,
        );

        final result = await LocationService(provider: provider).locate();

        expect(result.failure, LocationFailure.serviceDisabled);
        expect(provider.checkCalls, 0);
        expect(provider.positionCalls, 0);
      },
    );

    test('a provider failure is folded into a result, not thrown', () async {
      final provider = _FakeLocationProvider(
        positionError: const LocationException(LocationFailure.unavailable),
      );

      final result = await LocationService(provider: provider).locate();

      expect(result.failure, LocationFailure.unavailable);
    });

    test('an unexpected platform error becomes unavailable', () async {
      // A lookup that blows up with something other than a [LocationException]
      // still resolves to a result rather than escaping to the caller.
      final provider = _ExplodingProvider(_FakeLocationProvider());

      final result = await LocationService(provider: provider).locate();

      expect(result.failure, LocationFailure.unavailable);
    });
  });

  group('LocationService settings shortcuts', () {
    test('delegate to the provider', () async {
      final provider = _FakeLocationProvider();
      final service = LocationService(provider: provider);

      expect(await service.openAppSettings(), isTrue);
      expect(await service.openLocationSettings(), isTrue);
      expect(provider.appSettingsCalls, 1);
      expect(provider.locationSettingsCalls, 1);
    });
  });
}

/// Wraps a [_FakeLocationProvider] and makes the position lookup throw a plain
/// [StateError], exercising the catch-all branch.
class _ExplodingProvider implements LocationProvider {
  _ExplodingProvider(this._inner);

  final _FakeLocationProvider _inner;

  @override
  Future<bool> isServiceEnabled() => _inner.isServiceEnabled();

  @override
  Future<LocationAccess> checkAccess() => _inner.checkAccess();

  @override
  Future<LocationAccess> requestAccess() => _inner.requestAccess();

  @override
  Future<UserLocation> currentLocation() async => throw StateError('boom');

  @override
  Future<bool> openAppSettings() => _inner.openAppSettings();

  @override
  Future<bool> openLocationSettings() => _inner.openLocationSettings();
}
