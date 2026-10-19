import 'event.dart';

/// Which slice of the event table a [EventRepository.fetch] should load.
enum EventScope {
  /// Every event the caller's RLS policies allow.
  all,

  /// Events scheduled at or after now, soonest first.
  upcoming,

  /// Events already in the past, most recent first.
  past,
}

/// An event that has not been inserted yet, so it carries no id or timestamp.
///
/// Building one here rather than passing named arguments down a use case keeps
/// the creation contract in a single place the repository can rely on.
class NewEvent {
  const NewEvent({
    required this.ownerId,
    required this.scheduledAt,
    required this.location,
    required this.name,
    required this.emojiIcon,
    this.color,
    required this.isPublic,
    this.latitude,
    this.longitude,
  });

  final String ownerId;
  final DateTime scheduledAt;
  final String location;
  final String name;
  final String emojiIcon;
  final String? color;
  final bool isPublic;
  final double? latitude;
  final double? longitude;
}

/// The editable fields of an event. Every one is optional, so only the values
/// that are set get patched onto the row.
class EventPatch {
  const EventPatch({
    this.scheduledAt,
    this.location,
    this.name,
    this.emojiIcon,
    this.color,
    this.isPublic,
  });

  final DateTime? scheduledAt;
  final String? location;
  final String? name;
  final String? emojiIcon;
  final String? color;
  final bool? isPublic;
}

/// How the events feature reads and writes the `event` table.
///
/// Declared in the domain layer and implemented in `data/`, so presentation
/// code depends on this contract and never on Supabase. Tests substitute a
/// hand-written fake.
abstract interface class EventRepository {
  /// Loads the events matching [scope].
  Future<List<Event>> fetch({EventScope scope = EventScope.all});

  /// Loads one event, or `null` when the id matches no row.
  Future<Event?> fetchById(String id);

  /// Inserts [draft] and returns the row as stored.
  Future<Event> create(NewEvent draft);

  /// Patches the event with [id]; fields left unset keep their stored value.
  ///
  /// Returns the updated row, or `null` when the id matches no row.
  Future<Event?> update(String id, EventPatch patch);

  /// Deletes the event with [id].
  Future<void> delete(String id);

  /// Follows the whole event table over realtime, newest first.
  Stream<List<Event>> watch();
}
