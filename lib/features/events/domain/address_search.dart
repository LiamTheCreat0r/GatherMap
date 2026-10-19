/// One address suggestion returned by a place-search provider.
///
/// [placeName] is the human-readable label shown in the list and stored in the
/// event's `location`; the coordinates are kept for callers that want to place
/// the event on the map.
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

/// Address autocomplete, as the events feature uses it.
///
/// Declared in the domain so the create-event form depends on this contract
/// rather than on the MapTiler implementation in `data/`.
abstract interface class AddressSearch {
  /// Looks up addresses matching [query], best match first.
  ///
  /// Returns an empty list for a blank query. Throws when the provider fails;
  /// callers treat a failure as "no suggestions".
  Future<List<AddressSuggestion>> search(String query, {int limit = 6});
}
