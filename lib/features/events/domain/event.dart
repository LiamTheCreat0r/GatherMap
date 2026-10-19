/// An event as the app reasons about it, independent of Supabase.
///
/// This is the type every other layer talks to. The generated row class in
/// `lib/models/event.dart` never leaves the data layer: [EventMapper] converts
/// between the two, so a schema regen can only ripple through the mapper.
class Event {
  const Event({
    required this.id,
    required this.ownerId,
    required this.scheduledAt,
    required this.location,
    required this.createdAt,
    required this.name,
    required this.emojiIcon,
    required this.color,
    required this.isPublic,
    required this.latitude,
    required this.longitude,
  });

  /// Row id; empty until the insert lands and the database assigns one.
  final String id;

  /// The user who created the event.
  final String ownerId;

  /// When the event starts.
  final DateTime scheduledAt;

  /// Human-readable place label, as typed or picked from the geocoder.
  final String location;

  /// When the row was inserted, if the database reported it.
  final DateTime? createdAt;

  /// Event title, e.g. "Apéro des voisins".
  final String name;

  /// Emoji shown as the event's icon.
  final String emojiIcon;

  /// Hex colour, e.g. `#FF5A1F`.
  final String color;

  /// Whether the event is visible beyond the organiser's circles.
  final bool isPublic;

  /// Latitude of the pinned position, or `null` for a free-typed location.
  final double? latitude;

  /// Longitude of the pinned position, or `null` for a free-typed location.
  final double? longitude;

  /// Whether this event has coordinates to pin on the map.
  bool get isPinnable => latitude != null && longitude != null && id.isNotEmpty;
}
