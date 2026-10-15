import 'dart:convert';

import 'package:http/http.dart' as http;

/// One address suggestion returned by the geocoding provider.
///
/// [placeName] is the human-readable label shown in the list and stored in the
/// event's `location`; the coordinates are kept for callers that want to place
/// the event on the map later.
class AddressSuggestion {
  const AddressSuggestion({
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });

  /// Full label, e.g. "Café de la Gare, 1 Place ..., Paris, France".
  final String placeName;

  final double latitude;
  final double longitude;
}

/// Thrown when the geocoding provider answers with a non-200 status.
class AddressException implements Exception {
  const AddressException(this.message);

  final String message;

  @override
  String toString() => 'AddressException: $message';
}

/// Address autocomplete backed by the MapTiler Geocoding API.
///
/// The [client] and [apiKey] are injectable so tests can stub the network; the
/// defaults reuse the same MapTiler key the map already uses.
class AddressService {
  AddressService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? defaultApiKey;

  /// MapTiler key shared with the map widget in `views/widgets/map_widget.dart`.
  static const String defaultApiKey = 'nHhdC9Q6mdTwQ6qo9eiV';

  static const String _endpoint = 'https://api.maptiler.com/geocoding';

  final http.Client _client;
  final String _apiKey;

  /// Looks up addresses matching [query], best match first.
  ///
  /// Returns an empty list for a blank query. Throws [AddressException] when
  /// the provider answers with a non-200 status.
  Future<List<AddressSuggestion>> search(String query, {int limit = 6}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(
      '$_endpoint/${Uri.encodeComponent(trimmed)}.json',
    ).replace(
      queryParameters: {
        'key': _apiKey,
        'language': 'fr',
        'limit': '$limit',
        'autocomplete': 'true',
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw AddressException('Geocoding failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>? ?? const [];

    return features
        .whereType<Map<String, dynamic>>()
        .map(_toSuggestion)
        .whereType<AddressSuggestion>()
        .toList();
  }

  /// Maps one GeoJSON feature to an [AddressSuggestion], or `null` when it has
  /// no usable label.
  static AddressSuggestion? _toSuggestion(Map<String, dynamic> feature) {
    final placeName = (feature['place_name'] ?? feature['text'] ?? '')
        .toString();
    if (placeName.isEmpty) return null;

    var latitude = 0.0;
    var longitude = 0.0;
    final center = feature['center'];
    if (center is List && center.length >= 2) {
      final lng = center[0];
      final lat = center[1];
      if (lng is num && lat is num) {
        longitude = lng.toDouble();
        latitude = lat.toDouble();
      }
    }

    return AddressSuggestion(
      placeName: placeName,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
