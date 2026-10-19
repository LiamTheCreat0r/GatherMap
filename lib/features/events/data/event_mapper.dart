import '../../../../models/event.dart' as row;
import '../domain/event.dart';
import '../domain/event_repository.dart';

/// Converts between the generated `event` row class and the domain [Event].
///
/// The single bridge between `lib/models/` and the events feature: everything
/// on the Supabase side of this class is invisible to the rest of the feature,
/// so a schema regen only ever ripples through this file.
class EventMapper {
  const EventMapper();

  /// Domain [Event] from one generated row.
  Event toEntity(row.Event source) => Event(
    id: source.id ?? '',
    ownerId: source.ownerId,
    scheduledAt: source.scheduledAt,
    location: source.location,
    createdAt: source.createdAt,
    name: source.name,
    emojiIcon: source.emojiIcon,
    color: source.color,
    isPublic: source.isPublic,
    latitude: source.latitude,
    longitude: source.longitude,
  );

  /// Insert payload for [draft], ready for `client.event.insert(...)`.
  Map<String, dynamic> toInsert(NewEvent draft) => row.Event.insert(
    ownerId: draft.ownerId,
    scheduledAt: draft.scheduledAt,
    location: draft.location,
    name: draft.name,
    emojiIcon: draft.emojiIcon,
    color: draft.color,
    isPublic: draft.isPublic,
    latitude: draft.latitude,
    longitude: draft.longitude,
  );

  /// Update payload for [patch], ready for `client.event.update(...)`.
  Map<String, dynamic> toUpdate(EventPatch patch) => row.Event.update(
    scheduledAt: patch.scheduledAt,
    location: patch.location,
    name: patch.name,
    emojiIcon: patch.emojiIcon,
    color: patch.color,
    isPublic: patch.isPublic,
  );
}
