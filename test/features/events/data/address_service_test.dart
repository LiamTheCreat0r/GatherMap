import 'package:flutter_test/flutter_test.dart';
import 'package:gathermap/features/events/data/address_service.dart';
import 'package:gathermap/features/events/domain/address_search.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The create-event form depends on the [AddressSearch] contract, so the
/// MapTiler implementation has to satisfy it and parse the provider's GeoJSON.
void main() {
  group('AddressService', () {
    test('is usable wherever an AddressSearch is expected', () {
      final AddressSearch search = AddressService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(search, isA<AddressService>());
    });

    test('maps GeoJSON features to labelled suggestions', () async {
      final service = AddressService(
        client: MockClient(
          (_) async => http.Response(
            '{"features": [{"place_name": "Café de la Gare, Paris",'
            ' "center": [2.35, 48.85]}]}',
            200,
          ),
        ),
      );

      final results = await service.search('café');

      expect(results, hasLength(1));
      expect(results.single.placeName, 'Café de la Gare, Paris');
      expect(results.single.longitude, 2.35);
      expect(results.single.latitude, 48.85);
    });

    test('skips features with no usable label', () async {
      final service = AddressService(
        client: MockClient(
          (_) async => http.Response(
            '{"features": [{"center": [2.35, 48.85]}]}',
            200,
          ),
        ),
      );

      expect(await service.search('nowhere'), isEmpty);
    });

    test('a blank query does not hit the network', () async {
      var calls = 0;
      final service = AddressService(
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );

      expect(await service.search('   '), isEmpty);
      expect(calls, 0);
    });

    test('a non-200 response throws AddressException', () async {
      final service = AddressService(
        client: MockClient((_) async => http.Response('nope', 500)),
      );

      expect(
        () => service.search('café'),
        throwsA(isA<AddressException>()),
      );
    });
  });
}
